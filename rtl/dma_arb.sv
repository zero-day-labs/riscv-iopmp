// Copyright © 2023 Manuel Rodríguez & Zero-Day Labs, Lda.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// Licensed under the Solderpad Hardware License v 2.1 (the “License”); 
// you may not use this file except in compliance with the License, 
// or, at your option, the Apache License version 2.0. 
// You may obtain a copy of the License at https://solderpad.org/licenses/SHL-2.1/.
// Unless required by applicable law or agreed to in writing, 
// any work distributed under the License is distributed on an “AS IS” BASIS, 
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
// See the License for the specific language governing permissions and limitations under the License.

/*
    Author: Manuel Rodríguez, University of Minho <manuel.cederog@gmail.com>
    Date:   01/06/2023

    Description:    Interconnect for platform master DMA-capable devices.
                    Used to connect multiple devices to the IOMMU TR IF.
                    Routes responses (B and R) based on the ID of the device
                        that initiated the transaction.

    !NOTE:  The AXI ID of all slaves devices connected to the IOMMU through 
    !       this interconnect MUST be unique. Otherwise, responses may be 
    !       routed wrongly. 
    !       AXI IDs must start in 1, and the index of the slave port to which
    !       a device is connected to MUST match with the ID of the device - 1

    ! Changes luisccc: Change to AXI_BUS_NSAID dma_arb_intf
*/

module dma_arb #(
    
    /// AXI AW Channel struct type
    parameter type aw_chan_t        = logic,
    /// AXI W Channel struct type
    parameter type w_chan_t         = logic,
    /// AXI B Channel struct type
    parameter type b_chan_t         = logic,
    /// AXI AR Channel struct type
    parameter type ar_chan_t        = logic,
    /// AXI R Channel struct type
    parameter type r_chan_t         = logic,
    /// AXI Full request struct type
    parameter type  axi_req_t       = logic,
    /// AXI Full response struct type
    parameter type  axi_rsp_t       = logic,

    /// Number of Master DMA devices attached (Number of slave ports)
    parameter int unsigned NrDMAs   = 1,
    /// Do NOT modify manually
    parameter int unsigned log2NrDMAs   = $clog2(NrDMAs)
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,

    input  axi_req_t [NrDMAs-1:0]   slv_reqs_i,
    output axi_rsp_t [NrDMAs-1:0]   slv_resps_o,
    output axi_req_t                mst_req_o,
    input  axi_rsp_t                mst_resp_i
);

    logic [3:0] w_select_fifo;

    // Concatenate AR valid, ready and channel
    logic [NrDMAs-1:0]      ar_valid_group;
    logic [NrDMAs-1:0]      ar_ready_group;
    ar_chan_t [NrDMAs-1:0]  ar_group;

    // Concatenate AW valid, ready and channel
    logic [NrDMAs-1:0]      aw_valid_group;
    logic [NrDMAs-1:0]      aw_ready_group;
    aw_chan_t [NrDMAs-1:0]  aw_group;

    // Concatenate W valid, ready and channel
    logic [NrDMAs-1:0]      w_valid_group;
    logic [NrDMAs-1:0]      w_ready_group;
    w_chan_t [NrDMAs-1:0]   w_group;

    // Concatenate R valid and ready
    logic [NrDMAs-1:0] r_valid_group;
    logic [NrDMAs-1:0] r_ready_group;

    // Concatenate B valid and ready
    logic [NrDMAs-1:0] b_valid_group;
    logic [NrDMAs-1:0] b_ready_group;

    for (genvar i = 0; i < NrDMAs; i++) begin
        // AR
        assign ar_valid_group[i]        = slv_reqs_i[i].ar_valid;
        assign slv_resps_o[i].ar_ready  = ar_ready_group[i];
        assign ar_group[i]              = slv_reqs_i[i].ar;

        // AW
        assign aw_valid_group[i]        = slv_reqs_i[i].aw_valid;
        assign slv_resps_o[i].aw_ready  = aw_ready_group[i];
        assign aw_group[i]              = slv_reqs_i[i].aw;

        // W
        assign w_valid_group[i]         = slv_reqs_i[i].w_valid;
        assign slv_resps_o[i].w_ready   = w_ready_group[i];
        assign w_group[i]               = slv_reqs_i[i].w;

        // R
        assign slv_resps_o[i].r         = mst_resp_i.r;
        assign slv_resps_o[i].r_valid   = r_valid_group[i];
        assign r_ready_group[i]         = slv_reqs_i[i].r_ready;

        // B
        assign slv_resps_o[i].b         = mst_resp_i.b;
        assign slv_resps_o[i].b_valid   = b_valid_group[i];
        assign b_ready_group[i]         = slv_reqs_i[i].b_ready;
    end

    //# AR Channel
    stream_arbiter #(
        .DATA_T ( ar_chan_t ),
        .N_INP  ( NrDMAs    )
    ) i_stream_arbiter_ar (
        .clk_i          ( clk_i  ),
        .rst_ni         ( rst_ni ),
        .inp_data_i     ( ar_group ),
        .inp_valid_i    ( ar_valid_group ),
        .inp_ready_o    ( ar_ready_group ),
        .oup_data_o     ( mst_req_o.ar        ),
        .oup_valid_o    ( mst_req_o.ar_valid  ),
        .oup_ready_i    ( mst_resp_i.ar_ready )
    );

    //# AW Channel
    stream_arbiter #(
        .DATA_T ( aw_chan_t ),
        .N_INP  ( NrDMAs    )
    ) i_stream_arbiter_aw (
        .clk_i          ( clk_i),
        .rst_ni         ( rst_ni),
        .inp_data_i     ( aw_group ),
        .inp_valid_i    ( aw_valid_group ),
        .inp_ready_o    ( aw_ready_group ),
        .oup_data_o     ( mst_req_o.aw        ),
        .oup_valid_o    ( mst_req_o.aw_valid  ),
        .oup_ready_i    ( mst_resp_i.aw_ready )
    );

    //# W Channel

    // Save AWID whenever a transaction is accepted in AW Channel.
    // While writing data to W Channel, another AW transaction may be accepted, so we need to queue the AWIDs
    fifo_v3 #(
      .DATA_WIDTH ( 4 ),
      // we can have a maximum of (NrDMAs) oustanding transactions
      .DEPTH      ( NrDMAs )
    ) i_fifo_w_channel (
      .clk_i      ( clk_i           ),
      .rst_ni     ( rst_ni          ),
      .flush_i    ( 1'b0            ),
      .testmode_i ( 1'b0            ),
      .full_o     (                 ),
      .empty_o    (                 ),
      .usage_o    (                 ),
      .data_i     ( mst_req_o.aw.id - 1),
      .push_i     ( mst_req_o.aw_valid & mst_resp_i.aw_ready ),                 // a new AW transaction was requested and granted
      .data_o     ( w_select_fifo   ),                                          // WID to select the W MUX
      .pop_i      ( mst_req_o.w_valid & mst_resp_i.w_ready & mst_req_o.w.last ) // W transaction has finished
    );

    stream_mux #(
        .DATA_T ( w_chan_t ),
        .N_INP  ( NrDMAs   )
    ) i_stream_mux_w (
        .inp_data_i  ( w_group ),
        .inp_valid_i ( w_valid_group ),
        .inp_ready_o ( w_ready_group ),
        .inp_sel_i   ( w_select_fifo        ),
        .oup_data_o  ( mst_req_o.w          ),
        .oup_valid_o ( mst_req_o.w_valid    ),
        .oup_ready_i ( mst_resp_i.w_ready   )
    );

    //# Route responses based on AXI ID

    //# R Channel: We only demux RVALID/RREADY signals
    stream_demux #(
        .N_OUP ( NrDMAs )
    ) i_stream_demux_r (
        .inp_valid_i ( mst_resp_i.r_valid ),
        .inp_ready_o ( mst_req_o.r_ready  ),
        .oup_sel_i   ( mst_resp_i.r.id - 1),
        .oup_valid_o ( r_valid_group ),
        .oup_ready_i ( r_ready_group )
    );

    //# B Channel: We only demux BVALID/BREADY signals
    stream_demux #(
        .N_OUP ( NrDMAs )
    ) i_stream_demux_b (
        .inp_valid_i ( mst_resp_i.b_valid ),
        .inp_ready_o ( mst_req_o.b_ready  ),
        .oup_sel_i   ( mst_resp_i.b.id - 1),
        .oup_valid_o ( b_valid_group ),
        .oup_ready_i ( b_ready_group )
    );
    
endmodule

`include "axi/assign.svh"
`include "axi/typedef.svh"

module dma_arb_intf #(

    /// AXI AW Channel struct type
    parameter type aw_chan_t        = logic,
    /// AXI W Channel struct type
    parameter type w_chan_t         = logic,
    /// AXI B Channel struct type
    parameter type b_chan_t         = logic,
    /// AXI AR Channel struct type
    parameter type ar_chan_t        = logic,
    /// AXI R Channel struct type
    parameter type r_chan_t         = logic,
    /// AXI Full request struct type
    parameter type  axi_req_t       = logic,
    /// AXI Full response struct type
    parameter type  axi_rsp_t       = logic,

    /// Number of Master DMA devices attached (Number of slave ports)
    parameter int unsigned NrDMAs   = 1
) (
    input  logic                                                clk_i,
    input  logic                                                rst_ni,

    AXI_BUS_NSAID.Slave                                        slv_ports [NrDMAs-1:0],
    AXI_BUS_NSAID.Master                                       mst_port
);

    axi_req_t               mst_req;
    axi_rsp_t               mst_resp;
    axi_req_t [NrDMAs-1:0]  slv_reqs;
    axi_rsp_t [NrDMAs-1:0]  slv_resps;

    for (genvar i = 0; i < NrDMAs; i++) begin : gen_assign_dmas
        `AXI_ASSIGN_TO_REQ(slv_reqs[i], slv_ports[i])
        `AXI_ASSIGN_FROM_RESP(slv_ports[i], slv_resps[i])

        // Manually assign nsaid-specific signals
        // AW
        assign slv_reqs[i].aw.nsaid    = slv_ports[i].aw_nsaid;
        // AR
        assign slv_reqs[i].ar.nsaid    = slv_ports[i].ar_nsaid;
    end

    `AXI_ASSIGN_FROM_REQ(mst_port, mst_req)
    `AXI_ASSIGN_TO_RESP(mst_resp, mst_port)

    // Manually assign IOMMU-specific signals
    // AW
    assign mst_port.aw_nsaid     = mst_req.aw.nsaid;
    // AR
    assign mst_port.ar_nsaid     = mst_req.ar.nsaid;

    dma_arb #(
        .aw_chan_t  (aw_chan_t),
        .w_chan_t   (w_chan_t),
        .b_chan_t   (b_chan_t),
        .ar_chan_t  (ar_chan_t),
        .r_chan_t   (r_chan_t),
        .axi_req_t  (axi_req_t),
        .axi_rsp_t  (axi_rsp_t),

        .NrDMAs     (NrDMAs)
    ) i_dma_arb (
        .clk_i              (clk_i      ),
        .rst_ni             (rst_ni     ),

        .slv_reqs_i         (slv_reqs   ),
        .slv_resps_o        (slv_resps  ),
        .mst_req_o          (mst_req    ),
        .mst_resp_i         (mst_resp   )
    );

  endmodule