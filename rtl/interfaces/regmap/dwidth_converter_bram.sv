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
// Date: 02/03/2024
//
// Description: Converts between different widths BRAM.

// When inside a snd_stage the module is not ready to receive new data -> ready = 0
// When output data is valid -> valid = 1

/* verilator lint_off WIDTH */

module dwidth_converter_bram #(
    parameter int unsigned BRAM_DWIDTH  = 128,
    parameter int unsigned OUT_WIDTH    = 32,
    parameter int unsigned CONVERSION_RATIO = BRAM_DWIDTH/OUT_WIDTH,

    parameter int unsigned DEPTH           = 32,
    parameter int unsigned ADDR_WIDTH      = $clog2(DEPTH)
) (
    input  logic clk_i,
    input  logic rst_ni,

    input  logic we_i,
    output logic we_bram_o,

    input  logic en_i,
    output logic en_bram_o,

    input  logic [(ADDR_WIDTH * CONVERSION_RATIO) - 1 : 0] addr_i,
    output logic [ADDR_WIDTH-1:0] addr_bram_o,

    input  logic [OUT_WIDTH - 1 : 0]   din_i,
    output logic [BRAM_DWIDTH - 1 : 0] din_bram_o,

    output logic [OUT_WIDTH - 1 : 0]   dout_o,
    input  logic [BRAM_DWIDTH - 1 : 0] dout_bram_i,

    output logic [(BRAM_DWIDTH / 8) - 1 : 0] be_bram_o,

    // Info
    output logic                       valid_o,
    output logic                       ready_o
);

// How many out_width fit into BRAM_width. 2^n divide by 2 to get the amount to shift
localparam int unsigned ShiftAmount = (BRAM_DWIDTH/OUT_WIDTH) / 2;
// How many bits are necessary for the bit width of the shift quantity
localparam int unsigned BitWidthShift = $clog2(CONVERSION_RATIO);

logic [BitWidthShift - 1 : 0] shift_qtty_n, shift_qtty_q;
logic [7:0] data_shift_qtty;  // For improved Verilatr compatibility
logic [7:0] byte_en_shift_qtty;  // For improved Verilatr compatibility

logic [ADDR_WIDTH-1:0] pipeline_addr_n, pipeline_addr_q;
logic [OUT_WIDTH-1:0]  pipeline_data_n, pipeline_data_q;

logic   read_snd_stage_en_n, read_snd_stage_en_q;

always_comb begin
    en_bram_o = 0;
    we_bram_o = 0;

    addr_bram_o = 0;
    din_bram_o  = 0;
    dout_o      = 0;

    read_snd_stage_en_n  = 0;

    shift_qtty_n    = shift_qtty_q;
    pipeline_addr_n = pipeline_addr_q;
    pipeline_data_n = pipeline_data_q;

    valid_o = 0;
    ready_o = 1;
    data_shift_qtty = 0;
    byte_en_shift_qtty = 0;

    if(read_snd_stage_en_q) begin
        // Verilatr does not like making the expression into one
        data_shift_qtty = (shift_qtty_q << $clog2(OUT_WIDTH));

        dout_o  = dout_bram_i >> data_shift_qtty;
        valid_o = 1;
        ready_o = 0;
    end else if(en_i) begin
        en_bram_o = 1; // Enable BRAM

        // Get correct BRAM address
        addr_bram_o = addr_i >> ShiftAmount;
        shift_qtty_n  = addr_i[(BitWidthShift - 1) :0];

        if(we_i) begin
            // Replace the correct bits and write to the BRAM
            // Verilatr does not like making the expression into one
            data_shift_qtty = (shift_qtty_n << $clog2(OUT_WIDTH));
            din_bram_o[data_shift_qtty +: OUT_WIDTH] = din_i;

            // Put the byte enable bits into the right place
            byte_en_shift_qtty = (shift_qtty_n << $clog2(OUT_WIDTH / 8));
            be_bram_o = {(OUT_WIDTH / 8){1'b1}} << byte_en_shift_qtty;

            we_bram_o = 1;
        end
        else
            read_snd_stage_en_n = 1;
    end
end

// Sequential process
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        pipeline_addr_q         <= 0;
        pipeline_data_q         <= 0;
        read_snd_stage_en_q     <= 0;
        shift_qtty_q            <= 0;
    end else begin
        pipeline_addr_q         <= pipeline_addr_n;
        pipeline_data_q         <= pipeline_data_n;
        read_snd_stage_en_q     <= read_snd_stage_en_n;
        shift_qtty_q            <= shift_qtty_n;
    end
end

endmodule

/* verilator lint_on WIDTH */