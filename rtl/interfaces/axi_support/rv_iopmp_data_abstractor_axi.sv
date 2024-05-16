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
// Description: RISC-V IOPMP AXI Data abstractor.
//              Module responsible for abstracting the rest of the logic from the data bus protocol.
//              It calculates every address the transaction passes trough and passes it to the matching logic.

/* verilator lint_off WIDTH */
module rv_iopmp_data_abstractor_axi #(
    parameter int unsigned SID_WIDTH      = 8,
    // width of data bus in bits
    parameter int unsigned DATA_WIDTH     = 64,
    // width of addr bus in bits
    parameter int unsigned ADDR_WIDTH     = 64,
    // width of id signal
    parameter int unsigned ID_WIDTH       = 8,

    // AXI request/response
    parameter type         axi_req_nsaid_t  = logic,
    parameter type         axi_req_t        = logic,
    parameter type         axi_rsp_t        = logic,
    // AXI channel structs
    parameter type         axi_aw_chan_t  = logic,
    parameter type         axi_w_chan_t   = logic,
    parameter type         axi_b_chan_t   = logic,
    parameter type         axi_ar_chan_t  = logic,
    parameter type         axi_r_chan_t   = logic
) (
    input logic clk_i,
    input logic rst_ni,

    // slave port
    input  axi_req_nsaid_t slv_req_i,
    output axi_rsp_t       slv_rsp_o,
    // master port
    output axi_req_t       mst_req_o,
    input  axi_rsp_t       mst_rsp_i,

    output logic                                   transaction_en_o,
    output logic [ADDR_WIDTH - 1:0]                addr_o,
    output logic [ADDR_WIDTH - 1:0]         total_length_o,
    output logic [$clog2(DATA_WIDTH/8) :0]         num_bytes_o,
    output logic [SID_WIDTH     - 1:0]             sid_o,
    output rv_iopmp_pkg::access_t                  access_type_o,

    input  logic                 iopmp_allow_transaction_i,
    input  logic                                   ready_i,
    input  logic                                   valid_i
);

typedef enum logic [1:0] {
    IDLE            = 2'b00,
    VERIFICATION    = 2'b01,
    WAIT_IOPMP      = 2'b10,
    AXI_HANDSHAKE   = 2'b11
} state_t;


logic enable_checking;
logic allow_transaction;
logic transaction_allowed_n, transaction_allowed_q;
logic aw_request_n, aw_request_q;
logic ar_request_n, ar_request_q;

// AxADDR
logic [ADDR_WIDTH-1:0]             addr_n, addr_q;
logic [ADDR_WIDTH - 1:0]           total_length_n, total_length_q;
logic [ADDR_WIDTH-1:0]             addr_to_check_n, addr_to_check_q;
logic [$clog2(DATA_WIDTH/8) :0]    num_bytes_n, num_bytes_q;
// AxBURST
axi_pkg::burst_t         burst_type_n, burst_type_q;
// AxLEN
axi_pkg::len_t           burst_length_n, burst_length_q;
// AxSIZE
axi_pkg::size_t          size_n, size_q;

// Boundary checking
logic bc_allow_request;
logic bc_bound_violation;
logic [ADDR_WIDTH-1:0]  wrap_boundary;

// State register
state_t state_n, state_q;

// AXI request bus used to intercept AxADDR and AxVALID parameters, and connect to the demux slave port
axi_req_t   axi_aux_req;

// Helper wire
assign allow_transaction = iopmp_allow_transaction_i & bc_allow_request;

// Prevent another from starting when an invalidation already occurred

assign addr_o           = addr_to_check_q;
assign num_bytes_o      = num_bytes_q;
assign sid_o            = (aw_request_q)? slv_req_i.aw.nsaid : slv_req_i.ar.nsaid;
assign access_type_o    = (aw_request_q)? rv_iopmp_pkg::ACCESS_WRITE : rv_iopmp_pkg::ACCESS_READ;
assign total_length_o   = total_length_q;


// Connect the aux AXI bus to the translation request interface
// AW
assign axi_aux_req.aw_valid     = (state_q == AXI_HANDSHAKE) ? slv_req_i.aw_valid : 0;

assign axi_aux_req.aw.id        = slv_req_i.aw.id;
assign axi_aux_req.aw.addr      = slv_req_i.aw.addr;
assign axi_aux_req.aw.len       = slv_req_i.aw.len;
assign axi_aux_req.aw.size      = slv_req_i.aw.size;
assign axi_aux_req.aw.burst     = slv_req_i.aw.burst;
assign axi_aux_req.aw.lock      = slv_req_i.aw.lock;
assign axi_aux_req.aw.cache     = slv_req_i.aw.cache;
assign axi_aux_req.aw.prot      = slv_req_i.aw.prot;
assign axi_aux_req.aw.qos       = slv_req_i.aw.qos;
assign axi_aux_req.aw.region    = slv_req_i.aw.region;
assign axi_aux_req.aw.atop      = slv_req_i.aw.atop;
assign axi_aux_req.aw.user      = slv_req_i.aw.user;

// W
assign axi_aux_req.w            = slv_req_i.w;
assign axi_aux_req.w_valid      = slv_req_i.w_valid;

// B
assign axi_aux_req.b_ready      = slv_req_i.b_ready;

// AR
assign axi_aux_req.ar_valid     = (state_q == AXI_HANDSHAKE) ? slv_req_i.ar_valid : 0;

assign axi_aux_req.ar.id        = slv_req_i.ar.id;
assign axi_aux_req.ar.addr      = slv_req_i.ar.addr;
assign axi_aux_req.ar.len       = slv_req_i.ar.len;
assign axi_aux_req.ar.size      = slv_req_i.ar.size;
assign axi_aux_req.ar.burst     = slv_req_i.ar.burst;
assign axi_aux_req.ar.lock      = slv_req_i.ar.lock;
assign axi_aux_req.ar.cache     = slv_req_i.ar.cache;
assign axi_aux_req.ar.prot      = slv_req_i.ar.prot;
assign axi_aux_req.ar.qos       = slv_req_i.ar.qos;
assign axi_aux_req.ar.region    = slv_req_i.ar.region;
assign axi_aux_req.ar.user      = slv_req_i.ar.user;

// R
assign axi_aux_req.r_ready      = slv_req_i.r_ready;


always_comb begin
    state_n                 = state_q;
    transaction_allowed_n   = transaction_allowed_q;
    transaction_en_o        = 0;

    aw_request_n      = aw_request_q;
    ar_request_n      = ar_request_q;

    num_bytes_n       = num_bytes_q;
    addr_n            = addr_q;
    addr_to_check_n   = addr_to_check_q;
    size_n            = size_q;
    burst_type_n      = burst_type_q;
    burst_length_n    = burst_length_q;
    total_length_n    = total_length_q;

    case (state_q)
        IDLE: begin
            state_n = (slv_req_i.aw_valid | slv_req_i.ar_valid)? VERIFICATION : IDLE;

            transaction_allowed_n   = 0;

            // Registering this variables assures stability during operation
            aw_request_n    = slv_req_i.aw_valid? 1'b1 : '0;
            ar_request_n    = slv_req_i.aw_valid? '0 : slv_req_i.ar_valid? 1'b1 : 0;

            num_bytes_n       = slv_req_i.aw_valid ? axi_pkg::num_bytes(slv_req_i.aw.size): axi_pkg::num_bytes(slv_req_i.ar.size);
            addr_n            = slv_req_i.aw_valid ? slv_req_i.aw.addr : slv_req_i.ar.addr;
            addr_to_check_n   = slv_req_i.aw_valid ? slv_req_i.aw.addr : slv_req_i.ar.addr;
            size_n            = slv_req_i.aw_valid ? slv_req_i.aw.size : slv_req_i.ar.size;
            burst_type_n      = slv_req_i.aw_valid ? slv_req_i.aw.burst: slv_req_i.ar.burst;
            burst_length_n    = slv_req_i.aw_valid ? slv_req_i.aw.len  : slv_req_i.ar.len;
            total_length_n    = num_bytes_n * (burst_length_n + 1);
        end

        VERIFICATION: begin
            if(ready_i) begin
                transaction_en_o = 1;
                state_n          = WAIT_IOPMP;
            end
        end

        // Everything was accepted until now, so just wait and record the last permission and pass it on
        WAIT_IOPMP: begin
            // Wait for IOPMP to signal it has ended
            state_n = valid_i? AXI_HANDSHAKE: WAIT_IOPMP;

            transaction_allowed_n = iopmp_allow_transaction_i & bc_allow_request;
        end

        // Wait for the AXI_HANDSHAKE, that happens when ax_valid is asserted to 0
        AXI_HANDSHAKE:  state_n = (slv_rsp_o.ar_ready) |
                                    (slv_rsp_o.aw_ready)? IDLE: AXI_HANDSHAKE;

        default: ;
    endcase
end

// Sequential part of the state machine
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        state_q                 <= IDLE;
        transaction_allowed_q   <= 0;

        aw_request_q            <= 0;
        ar_request_q            <= 0;

        num_bytes_q             <= 0;
        addr_q                  <= 0;
        addr_to_check_q         <= 0;
        size_q                  <= 0;
        burst_type_q            <= 0;
        burst_length_q          <= 0;
        total_length_q          <= 0;
    end else begin
        state_q                 <= state_n;
        transaction_allowed_q   <= transaction_allowed_n;

        aw_request_q            <= aw_request_n;
        ar_request_q            <= ar_request_n;

        num_bytes_q             <= num_bytes_n;
        addr_q                  <= addr_n;
        addr_to_check_q         <= addr_to_check_n;
        size_q                  <= size_n;
        burst_type_q            <= burst_type_n;
        burst_length_q          <= burst_length_n;
        total_length_q          <= total_length_n;
    end
end

// Check for boundary breaches
rv_iopmp_axi4_bc i_rv_iopmp_axi4_bc(
    // AxVALID
    .request_i(aw_request_q | ar_request_q),
    // AxADDR
    .addr_i(addr_q),
    // AxBURST
    .burst_type_i(burst_type_q),
    // AxLEN
    .burst_length_i(burst_length_q),
    // AxSIZE
    .n_bytes_i(size_q),

    // To indicate valid requests or boundary violations
    .allow_request_o(bc_allow_request),
    .bound_violation_o(bc_bound_violation),
    .wrap_boundary_o(wrap_boundary)
);

//
// Demultiplex between authorized and unauthorized transactions
//
axi_req_t error_req;
axi_rsp_t error_rsp;
axi_demux #(
    .AxiIdWidth (ID_WIDTH),
    .aw_chan_t  (axi_aw_chan_t),
    .w_chan_t   (axi_w_chan_t),
    .b_chan_t   (axi_b_chan_t),
    .ar_chan_t  (axi_ar_chan_t),
    .r_chan_t   (axi_r_chan_t),
    .req_t      (axi_req_t),
    .resp_t     (axi_rsp_t),
    .NoMstPorts (2),
    .AxiLookBits(ID_WIDTH),       // TODO: not sure what this is?
    .FallThrough(1'b0),           // TODO: check what the right value is for them
    .SpillAw    (1'b0),
    .SpillW     (1'b0),
    .SpillB     (1'b0),
    .SpillAr    (1'b0),
    .SpillR     (1'b0)
) i_axi_demux (
    .clk_i,
    .rst_ni,
    .test_i         (1'b0),
    .slv_aw_select_i(transaction_allowed_q),
    .slv_ar_select_i(transaction_allowed_q),
    .slv_req_i      (axi_aux_req),
    .slv_resp_o     (slv_rsp_o),
    .mst_reqs_o     ({mst_req_o, error_req}),  // { 1: mst, 0: error }
    .mst_resps_i    ({mst_rsp_i, error_rsp})   // { 1: mst, 0: error }
);

//
// Respond to unauthorized transactions with slave errors
//
axi_err_slv #(
    .AxiIdWidth(ID_WIDTH),
    .req_t(axi_req_t),
    .resp_t(axi_rsp_t),
    .Resp(axi_pkg::RESP_SLVERR),  // error generated by this slave.
    .RespWidth(DATA_WIDTH),  // data response width, gets zero extended or truncated to r.data.
    .RespData(64'hCA11AB1EBADCAB1E),  // hexvalue for data return value
    .ATOPs(1'b1),
    .MaxTrans(1)
) i_axi_err_slv (
    .clk_i,
    .rst_ni,
    .test_i    (1'b0),
    .slv_req_i (error_req),
    .slv_resp_o(error_rsp)
);

endmodule
/* verilator lint_on WIDTH */
