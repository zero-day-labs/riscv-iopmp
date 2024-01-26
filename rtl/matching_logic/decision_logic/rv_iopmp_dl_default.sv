// Combinational Module to implement the default design

module rv_iopmp_dl_default #(
    parameter int unsigned SID_WIDTH      = 8,
    parameter int unsigned NUMBER_MDS     = 2,
    parameter int unsigned NUMBER_ENTRIES = 8,
    parameter int unsigned NUMBER_MASTERS = 2
) (
    input logic                                enable_i,
    input logic [NUMBER_ENTRIES-1:0]           entry_match_i,
    input logic [NUMBER_ENTRIES-1:0]           entry_allow_i,
    input logic [SID_WIDTH - 1:0]              sid_i,

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

logic [2:0] entry_access;

// Disabled verilator lint_off WIDTHTRUNC
// Disabled verilator lint_off WIDTHEXPAND
always_comb begin
    allow_transaction_o = 0;
    entry_access = 0;

    err_transaction_o = 0;
    err_type_o = 0;
    err_entry_index_o = 0;

    // If a transaction is occorring and the iopmp is enabled
    if(enable_i) begin
        if (entry_match_i == 0) begin // If match is equal to 0, there are no entries matching the transaction. Signal not hit any rule error.
            allow_transaction_o = 0;
            err_transaction_o = 1'b1;
            err_type_o = 3'h5;
        end
        else begin
            // we can reach this point if the SID is "invalid", just check it isn't unknown, i.e., if SID isnt higher than the number of masters
            if(sid_i > NUMBER_MASTERS) begin
                err_type_o = 3'h6;
                allow_transaction_o = 0;
                err_transaction_o = 1'b1;
            end
            else begin
                // Go trough every memory domain and entries possible
                for(integer i = 0; i < NUMBER_MDS; i++) begin
                    // Check if current MD belongs to SID, only belonging entries should report errors
                    if({srcmd_table_i[sid_i].enh, srcmd_table_i[sid_i].en.md}[i]) begin
                        for(integer j = 0; j < NUMBER_ENTRIES; j++) begin
                            // Check if current entry belongs to MD j
                            if((i == 0 & j < mdcfg_table_i[i]) | (j < mdcfg_table_i[i] & j >= mdcfg_table_i[i-1])) begin 
                                // Check if current entry has a match
                                if(entry_match_i[j]) begin
                                    entry_access = {entry_table_i[j].cfg.x, entry_table_i[j].cfg.w, entry_table_i[j].cfg.r};
                                    if(!entry_allow_i[j] | (access_type_i & entry_access) != access_type_i ) begin
                                        allow_transaction_o = 0;
                                        err_transaction_o = 1'b1;
                                        err_entry_index_o = j;
                                        case(access_type_i)
                                            rv_iopmp_pkg::ACCESS_READ, rv_iopmp_pkg::ACCESS_WRITE:
                                                err_type_o = access_type_i;
                                            rv_iopmp_pkg::ACCESS_EXECUTION:
                                                err_type_o = 3'h3;
                                            default:
                                                err_type_o = 3'h7; // Use some kind of error
                                        endcase
                                    end else
                                        allow_transaction_o = 1;
                                    break;
                                end
                            end
                        end
                    end
                end
            end

            // We can reach this if there were entries that signaled match, but do not belong to any MD from the current SID
            // It means although there was a match, per spec there was no match
            if (!allow_transaction_o & !err_transaction_o) begin
                allow_transaction_o = 0;
                err_transaction_o = 1'b1;
                err_type_o = 3'h5;
            end
        end
    end
end
// Disabled verilator lint_on WIDTHTRUNC 
// Disabled verilator lint_on WIDTHEXPAND 

endmodule
