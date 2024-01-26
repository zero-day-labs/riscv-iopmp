
module rv_iopmp_dl_wrapper #(
    parameter int unsigned SID_WIDTH       = 8,
    parameter int unsigned NUMBER_MDS      = 2,
    parameter int unsigned NUMBER_ENTRIES  = 8,
    parameter int unsigned NUMBER_MASTERS  = 2
) (
    input logic                                enable_i,
    input logic [SID_WIDTH - 1:0]              sid_i,
    input logic [NUMBER_ENTRIES-1:0]           entry_match_i,
    input logic [NUMBER_ENTRIES-1:0]           entry_allow_i,

    input rv_iopmp_pkg::srcmd_entry_t [NUMBER_MASTERS - 1:0] srcmd_table_i,
    input rv_iopmp_pkg::mdcfg_entry_t [NUMBER_MDS     - 1:0] mdcfg_table_i,
    input rv_iopmp_pkg::iopmp_entry_t [NUMBER_ENTRIES - 1:0] entry_table_i,

    // Transaction
    input rv_iopmp_pkg::access_t           access_type_i,
    output logic                           allow_transaction_o,

    // Error interface
    // IOPMP Error signals
    output logic        err_transaction_o,
    output logic [2:0]  err_type_o,
    output logic [15:0] err_entry_index_o
);

generate
    if(NUMBER_MASTERS == 1) begin
        rv_iopmp_dl_se #(
            .NUMBER_ENTRIES(NUMBER_ENTRIES)
        ) i_rv_iopmp_dl_se (
            .enable_i(enable_i),
            .entry_match_i(entry_match_i),
            .entry_allow_i(entry_allow_i),

            .entry_table_i(entry_table_i),

            // Transaction
            .access_type_i(access_type_i),
            .allow_transaction_o(allow_transaction_o),

            // Error interface
            // IOPMP Error signals
            .err_transaction_o(err_transaction_o),
            .err_type_o(err_type_o),
            .err_entry_index_o(err_entry_index_o)
        );
    end
    else begin
        rv_iopmp_dl_default #(
            .SID_WIDTH(SID_WIDTH),
            .NUMBER_MDS(NUMBER_MDS),
            .NUMBER_ENTRIES(NUMBER_ENTRIES),
            .NUMBER_MASTERS(NUMBER_MASTERS)
        ) i_rv_iopmp_dl_default (
            .enable_i(enable_i),
            .entry_match_i(entry_match_i),
            .entry_allow_i(entry_allow_i),
            .sid_i(sid_i),

            .srcmd_table_i(srcmd_table_i),
            .mdcfg_table_i(mdcfg_table_i),
            .entry_table_i(entry_table_i),

            // Transaction
            .access_type_i(access_type_i),
            .allow_transaction_o(allow_transaction_o),

            // Error interface
            // IOPMP Error signals
            .err_transaction_o(err_transaction_o),
            .err_type_o(err_type_o),
            .err_entry_index_o(err_entry_index_o)
        );
    end

endgenerate

endmodule
