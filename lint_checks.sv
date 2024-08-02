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
// Date: 27/03/2024
//
// Description: Top module to instance riscv_iopmp module, 
//				defining parameters and types for lint checks.

`include "common_cells/assertions.svh"
`include "register_interface/typedef.svh"
`include "lint_wrapper_pkg.sv"
`include "rv_iopmp_reg_pkg.sv"
`include "rv_iopmp_pkg.sv"

module lint_checks (

	input  logic clk_i,
	input  logic rst_ni,

	// AXI Bus between IOPMP Memory IF (Mst) and System Interconnect (Slv)
    output  lint_wrapper::req_t        axi_iopmp_ip_req,
    input   lint_wrapper::resp_t       axi_iopmp_ip_rsp,

    // AXI Bus between System Interconnect (Mst) and iopmp Programming IF (Slv)
    input  lint_wrapper::req_slv_t  axi_iopmp_cp_req,
    output lint_wrapper::resp_slv_t axi_iopmp_cp_rsp,

    // AXI Bus between DMA-device (Mst) and iopmp rp IF (Slv)
    // Extended with iopmp-specific signals
    input  lint_wrapper::req_nsaid_t axi_iopmp_rp_req,
    output lint_wrapper::resp_t      axi_iopmp_rp_rsp,

	output logic  wsi_wires_o
);
    //Memory-mapped Register IF types name, addr_t, data_t, strb_t
    `REG_BUS_TYPEDEF_ALL(iopmp_reg, logic[13:0], logic[31:0], logic[3:0])

    riscv_iopmp #(
        // AXI specific parameters
        .ADDR_WIDTH			( 64				        ),
        .DATA_WIDTH			( 64				        ),
        .ID_WIDTH			( lint_wrapper::IdWidth		),
        .ID_SLV_WIDTH		( lint_wrapper::IdWidthSlv	),
        .USER_WIDTH			( 1				            ),

        // AXI request/response
        .axi_req_nsaid_t    ( lint_wrapper::req_nsaid_t     ),
        .axi_req_t          ( lint_wrapper::req_t     ),
        .axi_rsp_t			( lint_wrapper::resp_t	),
        .axi_req_slv_t		( lint_wrapper::req_slv_t	),
        .axi_rsp_slv_t		( lint_wrapper::resp_slv_t),
        // AXI channel structs
        .axi_aw_chan_t      ( lint_wrapper::aw_chan_t   ),
        .axi_w_chan_t       ( lint_wrapper::w_chan_t	),
        .axi_b_chan_t       ( lint_wrapper::b_chan_t	),
        .axi_ar_chan_t      ( lint_wrapper::ar_chan_t   ),
        .axi_r_chan_t       ( lint_wrapper::r_chan_t	),

        // Register Interface parameters
        .reg_req_t		    ( iopmp_reg_req_t			),
        .reg_rsp_t		    ( iopmp_reg_rsp_t			),

        // Implementation specific
        .NUMBER_MDS             ( 16                    ),
        .NUMBER_ENTRIES         ( 32                    ),
        .NUMBER_MASTERS         ( 1                     )
    ) i_riscv_iopmp (
        .clk_i				( clk_i						),
        .rst_ni				( rst_ni					),

        // AXI Config Slave port
        .control_req_i      ( axi_iopmp_cp_req          ),
        .control_rsp_o      ( axi_iopmp_cp_rsp          ),

        // AXI Bus Slave port
        .receiver_req_i     ( axi_iopmp_rp_req          ),
        .receiver_rsp_o     ( axi_iopmp_rp_rsp          ),

        // AXI Bus Master port
        .initiator_req_o    ( axi_iopmp_ip_req          ),
        .initiator_rsp_i    ( axi_iopmp_ip_rsp          ),

        .wsi_wire_o         ( wsi_wires_o               )
    );

endmodule