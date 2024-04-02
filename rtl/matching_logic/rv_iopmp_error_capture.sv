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
// Description: RISC-V IOPMP Error capture.
//              Module responsible for logging the received errors in the regmap. It verifies if an error can be logged or not.
//              In the future it may server as an arbiter between multiple matching logics.


module rv_iopmp_error_capture #(
    // Implementation specific parameters
    parameter int unsigned NUMBER_IOPMP_INSTANCES = 1
) (
    input rv_iopmp_reg_pkg::iopmp_reg2hw_err_reqinfo_reg_t  reg2hw_err_reqinfo_i,
    input rv_iopmp_reg_pkg::iopmp_reg2hw_err_reqid_reg_t    reg2hw_err_reqid_i,
    input rv_iopmp_reg_pkg::iopmp_reg2hw_err_reqaddr_reg_t  reg2hw_err_reqaddr_i,
    input rv_iopmp_reg_pkg::iopmp_reg2hw_err_reqaddrh_reg_t reg2hw_err_reqaddrh_i,

    output rv_iopmp_reg_pkg::iopmp_hw2reg_err_reqinfo_reg_t  hw2reg_err_reqinfo_o,
    output rv_iopmp_reg_pkg::iopmp_hw2reg_err_reqid_reg_t    hw2reg_err_reqid_o,
    output rv_iopmp_reg_pkg::iopmp_hw2reg_err_reqaddr_reg_t  hw2reg_err_reqaddr_o,
    output rv_iopmp_reg_pkg::iopmp_hw2reg_err_reqaddrh_reg_t hw2reg_err_reqaddrh_o,

    input rv_iopmp_pkg::error_capture_t [NUMBER_IOPMP_INSTANCES - 1 : 0] err_interface_i
);


always_comb begin
    hw2reg_err_reqinfo_o.ip.de    = 1'b0;
    hw2reg_err_reqinfo_o.ip.d     = reg2hw_err_reqinfo_i.ip.q;
    hw2reg_err_reqinfo_o.ttype.de = 1'b0;
    hw2reg_err_reqinfo_o.ttype.d  = reg2hw_err_reqinfo_i.ttype.q;
    hw2reg_err_reqinfo_o.ttype.de = 1'b0;
    hw2reg_err_reqinfo_o.etype.d  = reg2hw_err_reqinfo_i.etype.q;

    hw2reg_err_reqid_o.sid.de = 1'b0;
    hw2reg_err_reqid_o.sid.d = reg2hw_err_reqid_i.sid.q;
    hw2reg_err_reqid_o.eid.de = 1'b0;
    hw2reg_err_reqid_o.eid.d = reg2hw_err_reqid_i.eid.q;

    hw2reg_err_reqaddr_o.de = 1'b0;
    hw2reg_err_reqaddr_o.d = reg2hw_err_reqaddr_i.q;

    hw2reg_err_reqaddrh_o.de = 1'b0;
    hw2reg_err_reqaddrh_o.d = reg2hw_err_reqaddrh_i.q;

    // If the ip bit is set, no error recording
    if(reg2hw_err_reqinfo_i.ip == 1'b0)
        for(integer i = 0; i < NUMBER_IOPMP_INSTANCES; i++) begin
            // If an error was detected in any of the matching instances
            if(err_interface_i[i].error_detected) begin
                hw2reg_err_reqinfo_o.ip.de = 1'b1; // Enable writing
                hw2reg_err_reqinfo_o.ip.d  = 1'b1; // If we are here, we have to set ip
                hw2reg_err_reqinfo_o.ttype.de = 1'b1; // Enable writing
                hw2reg_err_reqinfo_o.ttype.d  = err_interface_i[i].ttype; // Record transaction type
                hw2reg_err_reqinfo_o.etype.de = 1'b1; // Enable writing
                hw2reg_err_reqinfo_o.etype.d  = err_interface_i[i].etype; // Record transaction type

                hw2reg_err_reqid_o.sid.de = 1'b1;
                hw2reg_err_reqid_o.sid.d = err_interface_i[i].err_reqid.sid;
                hw2reg_err_reqid_o.eid.de = 1'b1;
                hw2reg_err_reqid_o.eid.d = err_interface_i[i].err_reqid.eid;

                hw2reg_err_reqaddr_o.de = 1'b1;
                hw2reg_err_reqaddr_o.d = err_interface_i[i].err_reqaddr;

                hw2reg_err_reqaddrh_o.de = 1'b1;
                hw2reg_err_reqaddrh_o.d = err_interface_i[i].err_reqaddrh;

                // Get out of the for loop, no need to go through the others
                break;
            end
    end
end

endmodule
