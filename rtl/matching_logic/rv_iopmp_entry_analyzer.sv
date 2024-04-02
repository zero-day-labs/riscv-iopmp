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
// Acknowledges:
//
// Description: RISC-V IOPMP Entry Analyzer.
//              Module responsible for matching the transaction address with the stored entries,
//              according to the configured entry rules.

/* verilator lint_off WIDTH */
module rv_iopmp_entry_analyzer #(
    parameter int LEN = 32,
    parameter int CHECK_LEN = 66,           // In the spec the entry registers hold data for the 65:2, so 66 bits
    parameter int unsigned ADDR_WIDTH     = 64,
    parameter int unsigned DATA_WIDTH     = 64
) (
    input logic [ADDR_WIDTH - 1: 0]          addr_to_check_i,
    input logic [ADDR_WIDTH - 1: 0]          final_addr_to_check_i,
    input logic [$clog2(DATA_WIDTH/8) :0]    num_bytes_i, // The requested_size width only depends on the width of the bus
    input rv_iopmp_pkg::access_t             transaction_type_i,

    input logic [LEN-1: 0]          addr_i,
    input logic [LEN-1: 0]          addrh_i,
    input logic [LEN-1: 0]          previous_entry_addr_i,
    input logic [LEN-1: 0]          previous_entry_addrh_i,
    input rv_iopmp_pkg::mode_t      mode_i,
    input logic [2:0]               access_permissions_i,

    output logic [ADDR_WIDTH - 1: 0] final_addr_o,
    output logic match_o,
    output logic partial_match_o,
    output logic allow_o            // The requested transaction matches all the bytes of the entry?
);

logic [LEN*2-1:0] entry_addr;
logic [LEN*2-1:0] previous_entry_addr;

logic [CHECK_LEN - 1:0] entry_addr_n;
logic [$clog2(CHECK_LEN) - 1:0] trail_ones;

// Concatenate entry addresses
assign entry_addr = {addrh_i, addr_i};
assign previous_entry_addr = {previous_entry_addrh_i, previous_entry_addr_i};

// Negate, for use in the leading zero counter - Refer to PMP enconding
assign entry_addr_n = {2'b11, ~entry_addr};

logic [CHECK_LEN - 1:0] base;
logic [CHECK_LEN    :0] final_address; // The supported addresses can reach 2^(67) 
logic [CHECK_LEN - 1:0] mask;
logic [$clog2(CHECK_LEN) :0] size; // Can be trail ones + 3
logic allow;

assign allow_o = allow & ((transaction_type_i & access_permissions_i) == transaction_type_i);
assign final_addr_o = final_address;

// Leading zero counter - Refer to PMP enconding
lzc #(
    .WIDTH(CHECK_LEN),
    .MODE (1'b0)
) i_lzc (
    .in_i   (entry_addr_n),
    .cnt_o  (trail_ones),
    .empty_o()
);

always_comb begin
    match_o = 0;
    partial_match_o = 0;
    allow = 0;

    base = 0;
    final_address = 0;
    mask = 0;
    size = 0;

    case (mode_i)
        rv_iopmp_pkg::TOR: begin
            // check that the requested address is in between the two
            // configuration addresses
            if (addr_to_check_i >= ({2'b0, previous_entry_addr} << 2) && addr_to_check_i < ({2'b0, entry_addr} << 2)) begin
                // If every address is allowed, continue
                if (final_addr_to_check_i >= ({2'b0, previous_entry_addr} << 2) && final_addr_to_check_i < ({2'b0, entry_addr} << 2)) begin
                    match_o = 1'b1;
                    allow   = 1'b1;
                end else begin
                    partial_match_o = 1'b1;
                    // Check if at least this is allowed
                    allow = ((addr_to_check_i + num_bytes_i - 1) < ({2'b0, entry_addr} << 2))? 1'b1 : 1'b0;
                end
            end else begin
                match_o = 0;
                partial_match_o = 0;
                allow   = 0;
            end

            final_address = {2'b0, entry_addr} << 2; // Propagate as it might be needed outside the IP
        end
        rv_iopmp_pkg::NA4, rv_iopmp_pkg::NAPOT: begin
            if (mode_i == rv_iopmp_pkg::NA4)
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
                    allow   = 1;
                end else begin
                    partial_match_o = 1;
                    // Check if at least this allows
                    allow = (addr_to_check_i + num_bytes_i - 1 <= final_address) ? 1'b1 : 1'b0;
                end
            end
            else begin
                match_o = 0;
                partial_match_o = 0;
                allow   = 0;
            end
        end
        rv_iopmp_pkg::OFF: match_o = 1'b0;
        default:    match_o = 0;
    endcase
end


endmodule
/* verilator lint_on WIDTH */