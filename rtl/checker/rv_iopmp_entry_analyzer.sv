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
    parameter int unsigned ADDR_WIDTH     = 64
) (
    input logic [ADDR_WIDTH - 1: 0]         addr_to_check_i,
    input logic [ADDR_WIDTH - 1: 0]         final_addr_to_check_i,

    input logic [31: 0]                     addr_i,
    input logic [31: 0]                     addrh_i,
    input logic [31: 0]                     previous_entry_addr_i,
    input logic [31: 0]                     previous_entry_addrh_i,
    input logic [1:0]                       mode_i,

    output logic                            match_o,
    output logic                            partial_match_o
);

typedef enum logic [1:0] {
    OFF   = 2'b00,
    TOR   = 2'b01,
    NA4   = 2'b10,
    NAPOT = 2'b11
} mode_t;

logic [63:0] entry_addr;
logic [63:0] previous_entry_addr;

logic [65:0] entry_addr_n; // This has two plus bits
logic [$clog2(66) - 1:0] trail_ones;

// Concatenate entry addresses
assign entry_addr = {addrh_i, addr_i};
assign previous_entry_addr = {previous_entry_addrh_i, previous_entry_addr_i};

// Negate, for use in the leading zero counter - Refer to PMP enconding
assign entry_addr_n = {2'b11, ~entry_addr};

logic [65 - 1:0] base;
logic [65    :0] final_address; // The supported addresses can reach 2^(65) 
logic [65 - 1:0] mask;
logic [$clog2(66) :0] size; // Can be trail ones + 3

// Leading zero counter - Refer to PMP enconding
lzc #(
    .WIDTH(66),
    .MODE (1'b0)
) i_lzc (
    .in_i   (entry_addr_n),
    .cnt_o  (trail_ones),
    .empty_o()
);

always_comb begin
    match_o = 0;
    partial_match_o = 0;

    base = 0;
    final_address = 0;
    mask = 0;
    size = 0;

    case (mode_i)
        TOR: begin
            // check that the requested address is in between the two
            // configuration addresses
            if (addr_to_check_i >= ({2'b0, previous_entry_addr} << 2) && addr_to_check_i < ({2'b0, entry_addr} << 2)) begin
                // If every address is allowed, continue
                if (final_addr_to_check_i >= ({2'b0, previous_entry_addr} << 2) && final_addr_to_check_i < ({2'b0, entry_addr} << 2)) begin
                    match_o = 1'b1;
                end else begin
                    partial_match_o = 1'b1;
                end
            end
        end
        NA4, NAPOT: begin
            if (mode_i == NA4)
                size = 2;
            else begin
                // use the extracted trailing ones
                size = trail_ones + 3;
            end

            // Mask that allows the extraction of the base address for the entry and transaction
            mask = '1 << size;
            base = ({2'b0, entry_addr} << 2) & mask; // Calculate base to compare with lower addr_to_check
            final_address = (base + (2 << (size - 1))) - 1; // Calculate final permited address for this entry

            // If both base addresses are equal, match
            if((addr_to_check_i & mask) == base) begin
                // The final address to check fits in this entry? Full match
                if(final_addr_to_check_i <= final_address) begin
                    match_o = 1;
                end else begin
                    partial_match_o = 1;
                end
            end
        end
        OFF: match_o = 1'b0;
        default:    match_o = 0;
    endcase
end

endmodule
/* verilator lint_on WIDTH */