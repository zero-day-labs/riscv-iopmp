// Combinational Module to implement the SE design
// Spec does not reference this, but in source enforcement mode, it does not make sense to have memory domains

module rv_iopmp_dl_se #(
    parameter int unsigned NUMBER_ENTRIES   = 8,
    parameter int unsigned NUMBER_INSTANCES = 8
) (
    input logic                                enable_i,
    input logic [NUMBER_INSTANCES-1:0]         entry_match_i,
    input logic [NUMBER_INSTANCES-1:0]         entry_allow_i,
    input logic [ 8 : 0 ]                      entry_offset_i,

    // Transaction
    input rv_iopmp_pkg::access_t           access_type_i,
    output logic                           allow_transaction_o,

    // Error interface
    // IOPMP Error signals
    output logic        err_transaction_o,
    output logic [2:0]  err_type_o,
    output logic [15:0] err_entry_index_o
);

// Disabled verilator lint_off WIDTHTRUNC
// Disabled verilator lint_off WIDTHEXPAND
always_comb begin
    allow_transaction_o = 0;

    err_transaction_o = 0;
    err_type_o = 0;
    err_entry_index_o = 0;

    // If a transaction is occorring and the iopmp is enabled
    if(enable_i) begin
        if ((entry_offset_i == NUMBER_ENTRIES - NUMBER_INSTANCES) & entry_match_i == 0) begin // If match is equal to 0, there are no entries matching the transaction. Signal not hit any rule error.
            allow_transaction_o = 0;
            err_transaction_o = 1'b1;
            err_type_o = 3'h5;
        end
        else begin
            // Go trough every memory domain and entries possible
            for(integer j = 0; j < NUMBER_ENTRIES; j++) begin
                // Check if current entry has a match
                if(entry_match_i[j]) begin
                    if(!entry_allow_i[j]) begin
                        allow_transaction_o = 0;
                        err_transaction_o = 1'b1;
                        err_entry_index_o = j + entry_offset_i;
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
// Disabled verilator lint_on WIDTHTRUNC
// Disabled verilator lint_on WIDTHEXPAND

endmodule
