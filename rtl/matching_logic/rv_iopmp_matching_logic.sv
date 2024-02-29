// Author: Luís Cunha <luisccunha8@gmail.com>
// Date: 29/02/2024
// Acknowledges:
//
// Description: RISC-V IOPMP Transaction Logic.
//              Module responsible for encapsulating all of the logic responsible for assessing transactions

module rv_iopmp_matching_logic #(
    // width of address bus in bits
    parameter int unsigned ADDR_WIDTH      = 64,
    // width of the data bus in bits
    parameter int unsigned DATA_WIDTH      = 64,
    // width of sid signal
    parameter int unsigned SID_WIDTH       = 8,
    // Implementation specific parameters
    parameter int unsigned ENTRY_ADDR_LEN = 32,
    parameter int unsigned NUMBER_MDS     = 2,
    parameter int unsigned NUMBER_ENTRIES = 8,
    parameter int unsigned NUMBER_MASTERS = 2,

    parameter int unsigned NUMBER_ENTRY_ANALYZERS= 32
) (
    // rising-edge clock
    input  logic     clk_i,
    // asynchronous reset, active low
    input  logic     rst_ni,

    input logic iopmp_enabled_i,
    input rv_iopmp_pkg::mdcfg_entry_t [NUMBER_MDS - 1:0]     mdcfg_table_i,
    input rv_iopmp_pkg::srcmd_entry_t [NUMBER_MASTERS - 1:0] srcmd_table_i,

    // Transaction
    input logic                          transaction_en_i,
    input logic [ADDR_WIDTH - 1:0]                 addr_i,
    input logic [ADDR_WIDTH - 1:0]           final_addr_i,
    input logic [ADDR_WIDTH - 1:0]         total_length_i,
    input logic [$clog2(DATA_WIDTH/8) :0]     num_bytes_i,
    input logic [SID_WIDTH     - 1:0]               sid_i,
    input rv_iopmp_pkg::access_t            access_type_i,

    output logic                       allow_transaction_o,
    output logic                                   ready_o,
    output logic                                   valid_o,

    // Error interface
    output rv_iopmp_pkg::error_capture_t   err_interface_o,

    // Entry interface
    output logic                                read_enable_o,
    output logic [$clog2(NUMBER_ENTRIES) - 1 : 0] read_addr_o,
    input  logic [64 - 1 : 0]                    entry_data_i
);

// TL States
typedef enum logic[2:0] {
    IDLE,                    // 0
    NORMAL_OP,                // 1
    CHECK_END,               // 2
    ERROR,
    PIPELINE_OPT             // 3
} state_t;

// State Machine variables
state_t                          state_n, state_q;
logic [ADDR_WIDTH - 1 : 0]       addr_to_check_n, addr_to_check_q;
logic [ADDR_WIDTH - 1 : 0]       previous_addr_to_check_n, previous_addr_to_check_q;
logic [ADDR_WIDTH - 1 : 0]       final_addr_to_check_n, final_addr_to_check_q;
logic [$clog2(DATA_WIDTH/8) :0]  num_bytes_n, num_bytes_q;
logic [SID_WIDTH - 1:0]          sid_n, sid_q;
rv_iopmp_pkg::access_t           access_type_n, access_type_q;
logic [2:0]                      err_type_n, err_type_q;
logic                            stop_entry_calculation;

logic [$clog2(NUMBER_ENTRIES) - 1 : 0]       current_entry_n, current_entry_q;
logic [7 - 1 : 0]                current_md_n, current_md_q;
logic [7 - 1 : 0]                next_md_n, next_md_q;
logic [7 - 1 : 0]                initial_md_n, initial_md_q;

logic last_md, get_next_md, reset_md, err_transaction;

// Helper for the srcmd_en register - Eliminates VERILATOR errors
logic [63:0] srcmd_en;
assign srcmd_en = {srcmd_table_i[sid_i].enh, srcmd_table_i[sid_i].en.md};

always_comb begin
    state_n                  = state_q;
    current_entry_n          = current_entry_q;
    addr_to_check_n          = addr_to_check_q;
    previous_addr_to_check_n = previous_addr_to_check_q;
    final_addr_to_check_n    = final_addr_to_check_q;
    num_bytes_n              = num_bytes_q;
    sid_n                    = sid_q;
    access_type_n            = access_type_q;
    err_type_n               = err_type_q;

    reset_md                = 0;
    get_next_md             = 0;

    case (state_q)
        IDLE: begin
            // Register the input values to assure signal stability during verification
            addr_to_check_n       = addr_i;
            final_addr_to_check_n = final_addr_i;
            num_bytes_n           = num_bytes_i;
            sid_n                 = sid_i;
            access_type_n         = access_type_i;

            if(transaction_en_i) begin
                if(!iopmp_enabled_i) begin    // IOPMP Not enabled, reject
                    state_n     = ERROR;
                    err_type_n  = 0;
                end
                else if (sid_i > NUMBER_MASTERS) begin
                    err_type_n  = 3'h6;
                    state_n     = ERROR;
                end else
                    state_n     = SETUP;
            end
        end

        SETUP: begin
            if(initial_md_q == 0)
                current_entry_n = 0;
            else
                current_entry_n = mdcfg_table_i[initial_md_q - 1];

            reset_md = 1;
            state_n  = NORMAL_OP;
        end

        NORMAL_OP: begin
            // Decision taking
            if(entry_match) begin  // We have a match with the current entry
                if(entry_allow) begin
                    if(addr_to_check_q == final_address_q) // Are we at the end?
                        state_n     = VALID;
                    else begin                             // As it is a new entry, check final again 
                        state_n                  = CHECK_END;
                        addr_to_check_n          = final_address_q;          // Prepare next address to check, to save a clock cycle
                        previous_addr_to_check_n = addr_to_check_q; // Store the current address
                    end
                end else begin
                    state_n = ERROR;

                    // Error type
                    case(access_type_q)
                        rv_iopmp_pkg::ACCESS_READ, rv_iopmp_pkg::ACCESS_WRITE:
                            err_type_n = access_type_q;
                        rv_iopmp_pkg::ACCESS_EXECUTION:
                            err_type_n = 3'h3;
                        default:
                            err_type_n = 3'h7; // Use some kind of error
                    endcase
                end

                // Dont get new entry in next iteration
            end
            else begin
                // Entry address calculation
                if(current_entry_q == mdcfg_table_i[current_md_q] - 1) begin // Check if it is necessary to change MD
                    if(last_md) begin
                        state_n = ERROR;
                        err_type_n = 3'h5;
                    end
                    else begin
                        current_entry_n = mdcfg_table_i[next_md_q - 1];          // Use next_md value directly so we do not stop
                        get_next_md     = 1;
                    end
                end
                else
                    current_entry_n = current_entry_q + 1;
            end
        end

        OPT_OP: begin
            // Decision taking
            if(entry_match) begin  // We have a match with the current entry
                if(entry_allow) begin
                    if(addr_to_check_q == final_address_q) // Are we at the end?
                        state_n     = VALID;
                    else begin  // If we are not at the end, just get new addr ready
                        // In optimal operation, no entry is calculated, just validate the addresses as quickly as possible
                        addr_to_check_n = addr_to_check_q + num_bytes_q;
                        previous_addr_to_check_n = addr_to_check_q;
                    end
                end else
                    state_n = ERROR;
            end
            else // We reached the limit of the current entry, we have to start over!
                state_n = SETUP;
        end

        CHECK_END: begin
            // If we have a match here, with the current entry, it means all of the transaction is approved
            if(entry_match) begin  // We have a match with the current entry
                if(entry_allow) begin
                    state_n = VALID;
                end else
                    state_n = ERROR;
            end
            else begin
                state_n = OPT_OP;
                addr_to_check_n = previous_addr_to_check_q + num_bytes_q;
            end
        end

        VALID: begin
            valid_o = 1;
            allow_transaction_o = 1;
        end

        ERROR: begin
            err_transaction = 1;
        end

        default:;
    endcase
end

// Sequential process
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        state_q                     <= IDLE;
        addr_to_check_q             <= 0;
        previous_addr_to_check_q    <= 0;
        final_addr_to_check_q       <= 0;
        current_entry_q             <= 0;
        num_bytes_q                 <= 0;
        sid_q                       <= 0;
        access_type_q               <= rv_iopmp_pkg::ACCESS_NONE;

        valid_q                     <= 0;
        allow_transaction_q         <= 0;
    end else begin
        state_q                     <= state_n;
        addr_to_check_q             <= addr_to_check_n;
        previous_addr_to_check_q    <= previous_addr_to_check_n;
        final_addr_to_check_q       <= final_addr_to_check_n;
        current_entry_q             <= current_entry_n;
        num_bytes_q                 <= num_bytes_n;
        sid_q                       <= sid_n;
        access_type_q               <= access_type_n;
        err_type_q                  <= err_type_n;

        valid_q                     <= valid_n;
        allow_transaction_q         <= allow_transaction_n;
    end
end

// MD manipulation
always_comb begin
    current_md_n = current_md_q;
    initial_md_n = initial_md_q;
    next_md_n    = next_md_q;
    last_md      = 0;

    case (state_q)
        IDLE: begin
            for(int i = 0; i < NUMBER_MDS; i++) begin
                // Setup base value, according to lowest MD
                if(srcmd_en[i]) begin
                    current_md_n = i;
                    initial_md_n = i;
                    break;
                end
            end
        end
        default: begin
            for(int i = 0; i < NUMBER_MDS; i++) begin
                // Get next_md address ready for use
                if(srcmd_en[i] && i > current_md_q) begin
                    next_md_n = i;
                    break;
                end
                if( i == NUMBER_MDS - 1) begin // Last MD?
                    last_md = 1;
                    break;
                end
            end

            if(reset_md)
                current_md_n = initial_md_q;
            else if(get_next_md)
                current_md_n = next_md_q;
        end
    endcase
end

// Sequential process MD calculation
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        current_md_q <= 0;
        initial_md_q <= 0;
        next_md_q    <= 0;
    end else begin
        current_md_q <= current_md_n;
        initial_md_q <= initial_md_n;
        next_md_q    <= next_md_n;
    end
end

// Error capture logic
always_ff @(posedge clk_i) begin
    if(err_transaction) begin
        // Record transaction type
        case(access_type_q)
            rv_iopmp_pkg::ACCESS_READ, rv_iopmp_pkg::ACCESS_WRITE:
                err_interface.ttype <= access_type_q[1:0]; // Eliminate possible truncate errors
            rv_iopmp_pkg::ACCESS_EXECUTION:
                err_interface.ttype <= 2'h3;
            default:
                err_interface.ttype <= 2'h1; // Unlikely to reach here, but use some type of transaction as 0 is reserved
        endcase
        err_interface.error_detected <= 1;
        err_interface.etype          <= err_type_q;
        err_interface.err_reqid.sid  <= sid_q;
        err_interface.err_reqid.eid  <= current_entry_q;

        err_interface.err_reqaddr   <= addr_to_check_q[31:0];
        err_interface.err_reqaddrh  <= addr_to_check_q[63:32];
    end
    else begin
        err_interface.error_detected <= 0;
        err_interface.ttype          <= 0;
        err_interface.etype          <= 0;
        err_interface.err_reqid.sid  <= 0;
        err_interface.err_reqid.eid  <= 0;
        err_interface.err_reqaddr    <= 0;
        err_interface.err_reqaddrh   <= 0;
    end
end

endmodule

// module tc_sram_wrapper #(
//   parameter int unsigned NumWords     = 32'd1024, // Number of Words in data array
//   parameter int unsigned DataWidth    = 32'd128,  // Data signal width
//   parameter int unsigned ByteWidth    = 32'd8,    // Width of a data byte
//   parameter int unsigned NumPorts     = 32'd2,    // Number of read and write ports
//   parameter int unsigned Latency      = 32'd1,    // Latency when the read data is available
//   parameter              SimInit      = "none",   // Simulation initialization
//   parameter bit          PrintSimCfg  = 1'b0,     // Print configuration
//   // DEPENDENT PARAMETERS, DO NOT OVERWRITE!
//   parameter int unsigned AddrWidth = (NumWords > 32'd1) ? $clog2(NumWords) : 32'd1,
//   parameter int unsigned BeWidth   = (DataWidth + ByteWidth - 32'd1) / ByteWidth, // ceil_div
//   parameter type         addr_t    = logic [AddrWidth-1:0],
//   parameter type         data_t    = logic [DataWidth-1:0],
//   parameter type         be_t      = logic [BeWidth-1:0]
// ) (
//   input  logic                 clk_i,      // Clock
//   input  logic                 rst_ni,     // Asynchronous reset active low
//   // input ports
//   input  logic  [NumPorts-1:0] req_i,      // request
//   input  logic  [NumPorts-1:0] we_i,       // write enable
//   input  addr_t [NumPorts-1:0] addr_i,     // request address
//   input  data_t [NumPorts-1:0] wdata_i,    // write data
//   input  be_t   [NumPorts-1:0] be_i,       // write byte enable
//   // output ports
//   output data_t [NumPorts-1:0] rdata_o     // read data
// );