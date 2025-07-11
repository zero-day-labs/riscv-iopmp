// Copyright © 2024 Luís Cunha & Zero-Day Labs, Lda.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// Licensed under the Solderpad Hardware License v 2.1 (the “License”);
// you may not use this file except in compliance with the License,
// or, at your option, the Apache License version 2.0.
// You may obtain a copy of the License at https://solderpad.org/licenses/SHL-2.1/.
// Unless required by applicable law or agreed to in writing,
// any work distributed under the License is distributed on an “AS IS” BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and limitations under the License.
//
// Author: Luís Cunha <luisccunha8@gmail.com>
// Date: 14/02/2024
//
// Description: RISC-V IOPMP Entry Analyzer.
//              Module responsible for matching the transaction address with the stored entries,
//              according to the configured entry rules.

/* verilator lint_off WIDTH */
module rv_iopmp_entry_analyzer #(
    parameter type          base_end_addr_t = logic,
    parameter int unsigned ADDR_WIDTH     = 64
) (
    input logic [ADDR_WIDTH - 1: 0]         addr_to_check_i,
    input logic [ADDR_WIDTH - 1: 0]         final_addr_to_check_i,

    input base_end_addr_t                   addr_i,
    input logic [63: 0]                     previous_entry_addr_i,
    input rv_iopmp_reg_pkg::mode_t          mode_i,

    output logic                            match_o,
    output logic                            partial_match_o
);

    always_comb begin
        match_o = 0;
        partial_match_o = 0;

        case (mode_i)
            rv_iopmp_reg_pkg::TOR: begin
                // check that the requested address is in between the two
                // configuration addresses
                if (addr_to_check_i >= previous_entry_addr_i && addr_to_check_i < addr_i.base_addr) begin
                    // If every address is allowed, continue
                    if (final_addr_to_check_i >= previous_entry_addr_i && final_addr_to_check_i < addr_i.base_addr) begin
                        match_o = 1'b1;
                    end else begin
                        partial_match_o = 1'b1;
                    end
                end
            end
            rv_iopmp_reg_pkg::NA4, rv_iopmp_reg_pkg::NAPOT: begin
                // If both base addresses are equal, match
                if (addr_to_check_i >= addr_i.base_addr && addr_to_check_i < addr_i.end_addr) begin
                    // The final address to check fits in this entry? Full match
                    if(final_addr_to_check_i <= addr_i.end_addr) begin
                        match_o = 1;
                    end else begin
                        partial_match_o = 1;
                    end
                end
            end
            rv_iopmp_reg_pkg::OFF: match_o = 1'b0;
            default:    match_o = 0;
        endcase
    end

endmodule
/* verilator lint_on WIDTH */