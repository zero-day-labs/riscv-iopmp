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
    input  logic [128 - 1 : 0]                    read_data_i,

    // Stall capabilities
    input logic stall_i
);

// TL States
typedef enum logic[2:0] {
    IDLE,
    NORMAL_OP,
    TOR_OP,
    ERROR,
    VALID,
    SETUP
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
logic                            first_iteration_n, first_iteration_q;
logic                            tor_override_n, tor_override_q;
logic                            new_md_n, new_md_q;
logic                            stop_entry_calculation;

logic [128 - 1 : 0]              cached_entry_n, cached_entry_q;
logic [64 - 1 : 0]               entry_addr, previous_entry_addr, entry_final_addr;
logic [32 - 1 : 0]               entry_cfg;

logic entry_match, partial_entry_match, entry_allow;

assign entry_addr = read_data_i[63 : 0];
assign entry_cfg  = read_data_i[95 : 64];

logic [$clog2(NUMBER_ENTRIES) - 1 : 0]       current_entry_n, current_entry_q;
logic [7 - 1 : 0]                current_md_n, current_md_q;
logic [7 - 1 : 0]                next_md_n, next_md_q;
logic [7 - 1 : 0]                initial_md_n, initial_md_q;

logic has_md_n, has_md_q, last_md, get_next_md, reset_md, err_transaction;

// Error
rv_iopmp_pkg::error_capture_t err_interface;
// Output error_capture
assign err_interface_o = err_interface;

// Helper for the srcmd_en register - Eliminates VERILATOR errors
logic [63:0] srcmd_en;
// This little trick allows us to save one cycle - If interfeers with timings, change later
assign srcmd_en = state_q == IDLE? {srcmd_table_i[sid_i].enh, srcmd_table_i[sid_i].en.md} : {srcmd_table_i[sid_q].enh, srcmd_table_i[sid_q].en.md};

assign ready_o       = (state_q == IDLE)? 1 : 0;
assign read_enable_o = (state_q != IDLE)? 1 : 0;
assign read_addr_o   = current_entry_n;

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
    tor_override_n           = tor_override_q;
    cached_entry_n           = cached_entry_q;
    new_md_n                 = 0;

    err_transaction         = 0;
    first_iteration_n       = 0;
    reset_md                = 0;
    get_next_md             = 0;
    allow_transaction_o     = 0;
    valid_o                 = 0;

    if(!stall_i) begin
        case (state_q)
            IDLE: begin
                // Register the input values to assure signal stability during verification
                addr_to_check_n       = addr_i;
                final_addr_to_check_n = addr_i + total_length_i - 1;
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

                    first_iteration_n = 1;
                end
            end

            SETUP: begin
                if(has_md_q & mdcfg_table_i[initial_md_q] != 0) begin
                    if(initial_md_q == 0)
                        current_entry_n = 0;
                    else
                        current_entry_n = mdcfg_table_i[initial_md_q - 1];

                    state_n  = NORMAL_OP;
                end
                else begin // MD enabled, but poorly configured
                    state_n = ERROR;
                    err_type_n = 3'h5;
                end

                reset_md = 1;
            end

            NORMAL_OP: begin
                cached_entry_n = read_data_i;
                // Current entry is TOR? Or Did we come back from TOR_OP? Or recently changed MD or is the first time we are here? Not cached entry
                if(entry_cfg[4:3] == 2'h1 & !tor_override_q & ((first_iteration_q & current_md_q != 0) | new_md_q )) begin
                    current_entry_n = current_entry_q - 1;
                    state_n         = TOR_OP;
                end
                else begin
                    // we are on the first entry, previous entry_addr = 0
                    if(current_entry_q == 0)
                        previous_entry_addr = 0;
                    else
                        previous_entry_addr = cached_entry_q[63:0];

                    // Decision taking
                    if(entry_match) begin  // We have a full match with the current entry
                        if(entry_allow) begin
                            state_n = VALID;
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
                    end
                    else begin
                        // We hit a partial match, just restart with the new base address, equal to the final address the entry allows
                        if(partial_entry_match) begin
                            // If what was partially matched is allowed
                            if(entry_allow) begin
                                state_n = SETUP;
                                addr_to_check_n = entry_final_addr;
                            end
                            else begin
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
                                    new_md_n        = 1;
                                end
                            end
                            else if(current_entry_q == NUMBER_ENTRIES - 1) begin // Are we on the last entry? Prevents locking up
                                state_n = ERROR;
                                err_type_n = 3'h5;
                            end else
                                current_entry_n = current_entry_q + 1;
                        end
                    end
                end
            end

            TOR_OP: begin
                cached_entry_n  = read_data_i; // Cache the previous entry
                current_entry_n = current_entry_q + 1; // Get back to the correct entry on next cycle
                tor_override_n  = 1;
                state_n         = NORMAL_OP;
            end

            VALID: begin
                valid_o = 1;
                allow_transaction_o = 1;
                state_n = IDLE;
            end

            ERROR: begin
                err_transaction = (err_type_q != 0)? 1 : 0;
                valid_o = 1;
                allow_transaction_o = 0;
                state_n = IDLE;
            end

            default:;
        endcase
    end
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
        err_type_q                  <= 0;
        new_md_q                    <= 0;
        cached_entry_q              <= 0;
        first_iteration_q           <= 0;

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
        tor_override_q              <= tor_override_n;
        new_md_q                    <= new_md_n;
        cached_entry_q              <= cached_entry_n;
        first_iteration_q           <= first_iteration_n;
    end
end

// MD manipulation
always_comb begin
    current_md_n = current_md_q;
    initial_md_n = initial_md_q;
    next_md_n    = next_md_q;
    last_md      = 0;
    has_md_n     = has_md_q;

    case (state_q)
        IDLE: begin
            has_md_n = 0;
            for(int i = 0; i < NUMBER_MDS; i++) begin
                // Setup base value, according to lowest MD
                if(srcmd_en[i]) begin
                    current_md_n = i;
                    initial_md_n = i;
                    has_md_n     = 1;   // Has at least one MD
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
                if( i == NUMBER_MDS - 1) begin // If we are here, we are on the last MD?
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
        has_md_q     <= 0;
    end else begin
        current_md_q <= current_md_n;
        initial_md_q <= initial_md_n;
        next_md_q    <= next_md_n;
        has_md_q     <= has_md_n;
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

rv_iopmp_entry_analyzer #(
    .LEN        ( ENTRY_ADDR_LEN ),
    .ADDR_WIDTH ( ADDR_WIDTH     )
) i_rv_iopmp_entry_analyzer (
    .addr_to_check_i        ( addr_to_check_q                       ),
    .final_addr_to_check_i  ( final_addr_to_check_q                 ),
    .num_bytes_i            ( num_bytes_q                           ),
    .transaction_type_i     ( access_type_q                         ),

    .addr_i                 ( entry_addr[31:0]  ),
    .addrh_i                ( entry_addr[63:32] ),
    .previous_entry_addr_i  ( previous_entry_addr[31:0]                 ),
    .previous_entry_addrh_i ( previous_entry_addr[63:32]                ),
    .mode_i                 ( entry_cfg[4:3] ),
    .access_permissions_i   ( entry_cfg[2:0] ),

    .final_addr_o           ( entry_final_addr ),
    .match_o                ( entry_match ),
    .partial_match_o        ( partial_entry_match ),
    .allow_o                ( entry_allow )
);

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