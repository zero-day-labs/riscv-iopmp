// Author:      Luís Cunha
// Description: IOPMP draft5

module rv_iopmp_transaction_logic #(
    // width of address bus in bits
    parameter int unsigned ADDR_WIDTH     = 64,
    // width of the data bus in bits
    parameter int unsigned DATA_WIDTH     = 64,
    // width of sid signal
    parameter int unsigned SID_WIDTH       = 8,
    // Implementation specific parameters
    parameter int unsigned ENTRY_ADDR_LEN = 32,
    parameter int unsigned NUMBER_MDS = 2,
    parameter int unsigned NUMBER_ENTRIES = 8,
    parameter int unsigned NUMBER_MASTERS = 2
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
    input rv_iopmp_pkg::access_t                          access_type_i,

    output logic                           allow_transaction_o,

    // Error interface
    output rv_iopmp_pkg::error_capture_t err_interface_o
);

// IOPMP Logic signals
logic [NUMBER_ENTRIES-1:0]            entry_match;
logic [NUMBER_ENTRIES-1:0]            entry_allow;
logic                                 allow_transaction;
logic [2:0] entry_access;

// IOPMP Error signals
logic        err_transaction;
logic [2:0]  err_type;
logic [15:0] err_entry_index;

logic                            transaction_en;
logic [ADDR_WIDTH - 1 : 0]       addr_to_check;
logic [$clog2(DATA_WIDTH/8) :0]  num_bytes;
logic [SID_WIDTH - 1:0]          sid;
rv_iopmp_pkg::access_t                         access_type;

assign allow_transaction_o = allow_transaction;

assign transaction_en = transaction_en_i;
assign addr_to_check  = addr_i;
assign num_bytes      = num_bytes_i;
assign sid            = sid_i;
assign access_type    = access_type_i;

// Generate block for instantiating iopmp_entry instances and entry logic
generate
    for (genvar i = 0; i < NUMBER_ENTRIES; i++) begin : gen_entries
        automatic logic [ENTRY_ADDR_LEN-1:0] previous_entry_addr; // Get previous config
        automatic logic [ENTRY_ADDR_LEN-1:0] previous_entry_addrh; // Get previous config

        assign previous_entry_addr  = (i == 0) ? '0 : entry_table_i[0+i-1].addr;
        assign previous_entry_addrh = (i == 0) ? '0 : entry_table_i[0+i-1].addrh;

        rv_iopmp_entry #(
            .LEN    ( ENTRY_ADDR_LEN ),
            .ADDR_WIDTH ( ADDR_WIDTH )
        ) i_rv_iopmp_entry(
            .addr_to_check_i        ( addr_to_check                       ),
            .num_bytes_i            ( num_bytes                           ),
            .addr_i                 ( entry_table_i[i].addr  ),
            .addrh_i                ( entry_table_i[i].addrh ),
            .previous_entry_addr_i  ( previous_entry_addr                 ),
            .previous_entry_addrh_i ( previous_entry_addrh                ),
            .mode_i                 ( entry_table_i[i].cfg.a ),
            .match_o                ( entry_match[i]                            ),
            .allow_o                ( entry_allow[i]                      )
        );

    end
endgenerate

/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
rv_iopmp_dl_wrapper #(
    .NUMBER_MDS(NUMBER_MDS),
    .NUMBER_ENTRIES(NUMBER_ENTRIES),
    .NUMBER_MASTERS(NUMBER_MASTERS)
) i_rv_iopmp_dl_wrapper (
    .enable_i(iopmp_enabled_i & transaction_en),
    .entry_match_i(entry_match),
    .entry_allow_i(entry_allow),

    .sid_i(sid),
    .srcmd_table_i(srcmd_table_i),
    .mdcfg_table_i(mdcfg_table_i),
    .entry_table_i(entry_table_i),

    // Transaction
    .access_type_i(access_type),
    .allow_transaction_o(allow_transaction),

    // IOPMP Error signals
    .err_transaction_o(err_transaction),
    .err_type_o(err_type),
    .err_entry_index_o(err_entry_index)
);

// Error capture logic
always_comb begin
    err_interface_o.error_detected = 0;
    err_interface_o.ttype = 0;
    err_interface_o.etype = 0;
    err_interface_o.err_reqid.sid = 0;
    err_interface_o.err_reqid.eid = 0;
    err_interface_o.err_reqaddr   = 0;
    err_interface_o.err_reqaddrh  = 0;

    if(err_transaction) begin
        // Record transaction type
        case(access_type)
            rv_iopmp_pkg::ACCESS_READ, rv_iopmp_pkg::ACCESS_WRITE:
                err_interface_o.ttype = access_type[1:0]; // Eliminate possible truncate errors
            rv_iopmp_pkg::ACCESS_EXECUTION:
                err_interface_o.ttype = 2'h3;
            default:
                err_interface_o.ttype = 2'h1; // Unlikely to reach here, but use some type of transaction as 0 is reserved
        endcase
        err_interface_o.error_detected = 1;
        err_interface_o.etype = err_type;
        err_interface_o.err_reqid.sid = sid;
        err_interface_o.err_reqid.eid = err_entry_index;

        err_interface_o.err_reqaddr   = addr_to_check[31:0];
        err_interface_o.err_reqaddrh  = addr_to_check[63:32];
    end
end
/* verilator lint_on WIDTHTRUNC */
/* verilator lint_on WIDTHEXPAND */


endmodule
