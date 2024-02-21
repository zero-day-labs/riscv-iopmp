// Author: Luís Cunha <luisccunha8@gmail.com>
// Date: 14/02/2024
// Acknowledges:
//
// Description: RISC-V IOPMP Transaction Logic.
//              Module responsible for encapsulating all of the logic responsible for assessing transactions

module rv_iopmp_transaction_logic #(
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
    input rv_iopmp_pkg::iopmp_entry_t [NUMBER_ENTRIES - 1:0] entry_table_i,

    // Transaction
    input logic                          transaction_en_i,
    input logic [ADDR_WIDTH - 1:0]                 addr_i,
    input logic [$clog2(DATA_WIDTH/8) :0]     num_bytes_i,
    input logic [SID_WIDTH     - 1:0]               sid_i,
    input rv_iopmp_pkg::access_t            access_type_i,

    output logic                       allow_transaction_o,
    output logic                                   ready_o,
    output logic                                   valid_o,

    // Error interface
    output rv_iopmp_pkg::error_capture_t    err_interface_o
);

localparam int unsigned NumberOfIterations = NUMBER_ENTRIES/NUMBER_ENTRY_ANALYZERS - 1;

// TL States
typedef enum logic[1:0] {
    IDLE,                    // 0
    VERIFICATION             // 1
} state_t;

// IOPMP Logic signals
logic [NUMBER_ENTRY_ANALYZERS-1:0] entry_match;
logic [NUMBER_ENTRY_ANALYZERS-1:0] entry_allow;
logic                              dl_allow;
logic                              allow_transaction_n, allow_transaction_q;
logic                              valid_n, valid_q;

rv_iopmp_pkg::iopmp_entry_t [NUMBER_ENTRY_ANALYZERS - 1:0] entry_table;
rv_iopmp_pkg::mdcfg_entry_t [NUMBER_MDS - 1:0]     mdcfg_table;

// IOPMP Error signals
logic        err_transaction;
logic [2:0]  err_type;
logic [15:0] err_entry_index;
rv_iopmp_pkg::error_capture_t err_interface;

// State Machine variables
state_t     state_n, state_q;
logic [8:0] iteration_counter_n, iteration_counter_q;
logic [8:0] entry_offset_n, entry_offset_q;

// Helper logic - propagate signals into downstream modules
logic                            transaction_en;
logic [ADDR_WIDTH - 1 : 0]       addr_to_check_n, addr_to_check_q;
logic [$clog2(DATA_WIDTH/8) :0]  num_bytes_n, num_bytes_q;
logic [SID_WIDTH - 1:0]          sid_n, sid_q;
rv_iopmp_pkg::access_t           access_type_n, access_type_q;

assign allow_transaction_o = allow_transaction_q;

// Signal for the decision logic modules, go to 1 when in verification
assign transaction_en = (state_q == VERIFICATION)? 1 : 0;
// Module is only ready to receive another request when in IDLE
assign ready_o        = (state_q == IDLE)? 1 : 0;
// Make sure the valid signal is pulled to 0 when in verification
assign valid_o        = (state_q == VERIFICATION)? 0 : valid_q;
// Output error_capture
assign err_interface_o = err_interface;

// Register entries and mds to break long wires
always_ff @(posedge clk_i) begin
    for(integer i = 0; i < NUMBER_ENTRY_ANALYZERS; i++) begin
        if(state_q == VERIFICATION)
            entry_table[i] <= entry_table_i[i + entry_offset_n];
        else
            entry_table[i] <= entry_table_i[i];
    end
    for(integer i = 0; i < NUMBER_MDS; i++) begin
        mdcfg_table[i] <= mdcfg_table_i[i];
    end
end

always_comb begin
    state_n                 = state_q;
    iteration_counter_n     = iteration_counter_q;
    entry_offset_n          = entry_offset_q;
    addr_to_check_n         = addr_to_check_q;
    num_bytes_n             = num_bytes_q;
    sid_n                   = sid_q;
    access_type_n           = access_type_q;

    valid_n                 = valid_q;
    allow_transaction_n     = allow_transaction_q;

    case (state_q)
        IDLE: begin
            iteration_counter_n       = 0;
            entry_offset_n  = 0;

            // Register the input values to assure signal stability during verification
            addr_to_check_n = addr_i;
            num_bytes_n     = num_bytes_i;
            sid_n           = sid_i;
            access_type_n   = access_type_i;

            // Assure the valid does not stay 1 for more than one cycle
            // TODO: Maybe only when any entry is changed it activates a procedure to "reset"
            valid_n         = 0;

            state_n     = transaction_en_i? VERIFICATION : IDLE;
        end

        VERIFICATION: begin
            // If the iopmp is off, or we are on the last set of entries, or the transaction was already allowed or dismissed, proceed
            state_n = !iopmp_enabled_i | (iteration_counter_q == NumberOfIterations) | dl_allow |
                            err_transaction? IDLE : VERIFICATION;

            // Increment counter which indicates how many iterations have passed
            iteration_counter_n           = iteration_counter_q + 1;
            // Increment entry_offset to load different entries into the entry_analizers
            entry_offset_n      = entry_offset_q + NUMBER_ENTRY_ANALYZERS;
            // Register the allow_transaction for signal stability on the output
            allow_transaction_n = dl_allow & iopmp_enabled_i;

            // If the transaction isn't allowed, an error occurs, if allowed dl_allow at 1.
            // Either way, valid will be at one in next cycle. If the IOPMP isn't enabled, say instantly
            // that the transaction is not allowed
            valid_n             = !iopmp_enabled_i? 1 : dl_allow | err_transaction;
        end

        default:;
    endcase
end

// Sequential process
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        state_q                 <= IDLE;
        iteration_counter_q     <= 0;
        iteration_counter_q    <= 0;
        entry_offset_q          <= 0;
        addr_to_check_q         <= 0;
        num_bytes_q             <= 0;
        sid_q                   <= 0;
        access_type_q           <= rv_iopmp_pkg::ACCESS_NONE;

        valid_q                 <= 0;
        allow_transaction_q     <= 0;
    end else begin
        state_q                 <= state_n;
        iteration_counter_q     <= iteration_counter_n;
        entry_offset_q          <= entry_offset_n;
        addr_to_check_q         <= addr_to_check_n;
        num_bytes_q             <= num_bytes_n;
        sid_q                   <= sid_n;
        access_type_q           <= access_type_n;

        valid_q                 <= valid_n;
        allow_transaction_q     <= allow_transaction_n;
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
        err_interface.etype          <= err_type;
        err_interface.err_reqid.sid  <= sid_q;
        err_interface.err_reqid.eid  <= err_entry_index;

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

// Generate block for instantiating iopmp_entry instances and entry logic
generate
    for (genvar i = 0; i < NUMBER_ENTRY_ANALYZERS; i++) begin : gen_entry_analyzers
        automatic logic [ENTRY_ADDR_LEN-1:0] previous_entry_addr;  // Get previous config
        automatic logic [ENTRY_ADDR_LEN-1:0] previous_entry_addrh; // Get previous config
        automatic logic [4 : 0] index;                             // Get correct index for the entries to analyze

        assign index = i;// + entry_offset;        // Current entries are allways dependent on the iteration the state machine is on
        assign previous_entry_addr  = (i == 0) ? '0 : entry_table[index - 1].addr.q;
        assign previous_entry_addrh = (i == 0) ? '0 : entry_table[index - 1].addrh.q;

        rv_iopmp_entry_analyzer #(
            .LEN        ( ENTRY_ADDR_LEN ),
            .ADDR_WIDTH ( ADDR_WIDTH     )
        ) i_rv_iopmp_entry_analyzer(
            .addr_to_check_i        ( addr_to_check_q                       ),
            .num_bytes_i            ( num_bytes_q                           ),
            .transaction_type_i     ( access_type_q                         ),

            .addr_i                 ( entry_table[index].addr.q  ),
            .addrh_i                ( entry_table[index].addrh.q ),
            .previous_entry_addr_i  ( previous_entry_addr                 ),
            .previous_entry_addrh_i ( previous_entry_addrh                ),
            .mode_i                 ( entry_table[index].cfg.a.q ),
            .access_permissions_i   ({entry_table[index].cfg.x.q, entry_table[index].cfg.w.q, entry_table[index].cfg.r.q}),

            .match_o                ( entry_match[i]       ),
            .allow_o                ( entry_allow[i]       )
        );
    end
endgenerate

// Disabled verilator lint_off WIDTHEXPAND
// Disabled verilator lint_off WIDTHTRUNC

// Instantiation of the decision logic wrapper, which performs the final checking according to MD and SID
rv_iopmp_dl_wrapper #(
    .NUMBER_MDS(NUMBER_MDS),
    .NUMBER_ENTRIES(NUMBER_ENTRIES),
    .NUMBER_MASTERS(NUMBER_MASTERS),
    .NUMBER_ENTRY_ANALYZERS(NUMBER_ENTRY_ANALYZERS)
) i_rv_iopmp_dl_wrapper (
    .enable_i(iopmp_enabled_i & transaction_en),
    .entry_match_i(entry_match),
    .entry_allow_i(entry_allow),
    .entry_offset_i(entry_offset_q),

    .sid_i(sid_q),
    .srcmd_table_i(srcmd_table_i),
    .mdcfg_table_i(mdcfg_table),

    // Transaction
    .access_type_i(access_type_q),
    .allow_transaction_o(dl_allow),

    // IOPMP Error signals
    .err_transaction_o(err_transaction),
    .err_type_o(err_type),
    .err_entry_index_o(err_entry_index)
);

endmodule