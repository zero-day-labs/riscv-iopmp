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
// Acknowledges: Manuel Rodriguez
//
// Description: RISC-V IOPMP WSI Interrupt Generation Module.

module rv_iopmp_wsi_ig(
    // fctl.wsi
    input  logic        wsi_en_i,

    // Interrupt pending bit
    input  logic intp_i,

    // Interrupt vectors
    input  logic [1:0] intv_i,

    // interrupt wires
    output logic wsi_wire_o
);

    always_comb begin : wsi_support
        wsi_wire_o = '0;

        // If WSI generation supported and enabled
        if (wsi_en_i & intv_i > 0 & intp_i)
            wsi_wire_o = 1;
    end

endmodule
