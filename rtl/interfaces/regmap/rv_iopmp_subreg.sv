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
// Description: IOPMP Register field.
//              This module was developed using LowRISC `reggen` tool.

// Adapted from lowRISC, it adds the W1SS and W1CS behaviour

module rv_iopmp_subreg #(
  parameter int            DW       = 32  ,
  parameter                SWACCESS = "RW",  // {RW, RO, WO, W1C, W1S, W0C, RC}
  parameter logic [DW-1:0] RESVAL   = '0     // Reset value
) (
  input clk_i,
  input rst_ni,

  // From SW: valid for RW, WO, W1C, W1S, W0C, RC
  // In case of RC, Top connects Read Pulse to we
  input          we,
  input [DW-1:0] wd,

  // From HW: valid for HRW, HWO
  input          de,
  input [DW-1:0] d,

  // output to HW and Reg Read
  output logic          qe,
  output logic [DW-1:0] q,
  output logic [DW-1:0] qs
);

  logic          wr_en;
  logic [DW-1:0] wr_data;

  rv_iopmp_subreg_arb #(
    .DW       ( DW       ),
    .SWACCESS ( SWACCESS )
  ) wr_en_data_arb (
    .we,
    .wd,
    .de,
    .d,
    .q,
    .wr_en,
    .wr_data
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      qe <= 1'b0;
    end else begin
      qe <= we;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      q <= RESVAL;
    end else if (wr_en) begin
      q <= wr_data;
    end
  end

  assign qs = q;

endmodule
