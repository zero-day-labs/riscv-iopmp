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
// Description: Wrapper module for the RISC-V IOPMP register programming interface.
//              Convertes between AXI and register interface.

`include "register_interface/assign.svh"

/* verilator lint_off WIDTH */
module rv_iopmp_cfg_abstractor_axi #(
    // width of data bus in bits
    parameter int unsigned DATA_WIDTH     = 64,
    // width of addr bus in bits
    parameter int unsigned ADDR_WIDTH     = 64,
    // width of id signal
    parameter int unsigned ID_WIDTH       = 8,
    // width of user signal
    parameter int unsigned USER_WIDTH     = 2,
    // width of user signal
    parameter int unsigned REG_DATA_WIDTH = 32,

    /// Dependent parameter: ID Width
    parameter type         id_t         = logic[ID_WIDTH-1:0],

    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic,
    // AXI request/response
    parameter type axi_req_t      = logic,
    parameter type axi_rsp_t      = logic
) (
    input logic clk_i,
    input logic rst_ni,

    // slave port
    input  axi_req_t slv_req_i,
    output axi_rsp_t slv_rsp_o,

    output reg_req_t cfg_req_o,
    input  reg_rsp_t cfg_rsp_i
);

    REG_BUS #(
        .ADDR_WIDTH ( 14 ),
        .DATA_WIDTH ( 32 )
    ) iopmp_reg_bus (clk_i);

    logic         penable;
    logic         pwrite;
    logic [31:0]  paddr;
    logic         psel;
    logic [31:0]  pwdata;
    logic [31:0]  prdata;
    logic         pready;
    logic         pslverr;

    // AXI4 to APB IF
    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( ADDR_WIDTH  ),
        .AXI4_RDATA_WIDTH   ( DATA_WIDTH  ),
        .AXI4_WDATA_WIDTH   ( DATA_WIDTH  ),
        .AXI4_ID_WIDTH      ( ID_WIDTH    ),
        .AXI4_USER_WIDTH    ( USER_WIDTH  ),
        .BUFF_DEPTH_SLAVE   ( 2           ),
        .APB_ADDR_WIDTH     ( 32          )
    ) i_axi2apb_64_32_iopmp (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        // AW
        .AWID_i    ( slv_req_i.aw.id     ),
        .AWADDR_i  ( slv_req_i.aw.addr   ),
        .AWLEN_i   ( slv_req_i.aw.len    ),
        .AWSIZE_i  ( slv_req_i.aw.size   ),
        .AWBURST_i ( slv_req_i.aw.burst  ),
        .AWLOCK_i  ( slv_req_i.aw.lock   ),
        .AWCACHE_i ( slv_req_i.aw.cache  ),
        .AWPROT_i  ( slv_req_i.aw.prot   ),
        .AWREGION_i( slv_req_i.aw.region ),
        .AWUSER_i  ( slv_req_i.aw.user   ),
        .AWQOS_i   ( slv_req_i.aw.qos    ),
        .AWVALID_i ( slv_req_i.aw_valid  ),
        .AWREADY_o ( slv_rsp_o.aw_ready ),
        // W
        .WDATA_i   ( slv_req_i.w.data    ),
        .WSTRB_i   ( slv_req_i.w.strb    ),
        .WLAST_i   ( slv_req_i.w.last    ),
        .WUSER_i   ( slv_req_i.w.user    ),
        .WVALID_i  ( slv_req_i.w_valid   ),
        .WREADY_o  ( slv_rsp_o.w_ready  ),
        // B
        .BID_o     ( slv_rsp_o.b.id     ),
        .BRESP_o   ( slv_rsp_o.b.resp   ),
        .BUSER_o   ( slv_rsp_o.b.user   ),
        .BVALID_o  ( slv_rsp_o.b_valid  ),
        .BREADY_i  ( slv_req_i.b_ready   ),
        // AR
        .ARID_i    ( slv_req_i.ar.id     ),
        .ARADDR_i  ( slv_req_i.ar.addr   ),
        .ARLEN_i   ( slv_req_i.ar.len    ),
        .ARSIZE_i  ( slv_req_i.ar.size   ),
        .ARBURST_i ( slv_req_i.ar.burst  ),
        .ARLOCK_i  ( slv_req_i.ar.lock   ),
        .ARCACHE_i ( slv_req_i.ar.cache  ),
        .ARPROT_i  ( slv_req_i.ar.prot   ),
        .ARREGION_i( slv_req_i.ar.region ),
        .ARUSER_i  ( slv_req_i.ar.user   ),
        .ARQOS_i   ( slv_req_i.ar.qos    ),
        .ARVALID_i ( slv_req_i.ar_valid  ),
        .ARREADY_o ( slv_rsp_o.ar_ready ),
        // R
        .RID_o     ( slv_rsp_o.r.id     ),
        .RDATA_o   ( slv_rsp_o.r.data   ),
        .RRESP_o   ( slv_rsp_o.r.resp   ),
        .RLAST_o   ( slv_rsp_o.r.last   ),
        .RUSER_o   ( slv_rsp_o.r.user   ),
        .RVALID_o  ( slv_rsp_o.r_valid  ),
        .RREADY_i  ( slv_req_i.r_ready   ),
        // APB IF
        .PENABLE   ( penable              ),
        .PWRITE    ( pwrite               ),
        .PADDR     ( paddr                ),
        .PSEL      ( psel                 ),
        .PWDATA    ( pwdata               ),
        .PRDATA    ( prdata               ),
        .PREADY    ( pready               ),
        .PSLVERR   ( pslverr              )
    );

    // APB to REG IF
    apb_to_reg i_apb_to_reg (
        .clk_i     ( clk_i          ),
        .rst_ni    ( rst_ni         ),
        .penable_i ( penable        ),
        .pwrite_i  ( pwrite         ),
        .paddr_i   ( paddr          ),
        .psel_i    ( psel           ),
        .pwdata_i  ( pwdata         ),
        .prdata_o  ( prdata         ),
        .pready_o  ( pready         ),
        .pslverr_o ( pslverr        ),
        .reg_o     ( iopmp_reg_bus  )
    );

    // assign REG_BUS.out to (req_t, rsp_t) pair
    `REG_BUS_ASSIGN_TO_REQ(cfg_req_o, iopmp_reg_bus)
    `REG_BUS_ASSIGN_FROM_RSP(iopmp_reg_bus, cfg_rsp_i)


endmodule
/* verilator lint_on WIDTH */