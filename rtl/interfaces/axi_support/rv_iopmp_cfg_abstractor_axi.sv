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
    parameter type         axi_req_t      = logic,
    parameter type         axi_rsp_t      = logic
) (
    input logic clk_i,
    input logic rst_ni,

    // slave port
    input  axi_req_t slv_req_i,
    output axi_rsp_t slv_rsp_o,

    output reg_req_t cfg_req_o,
    input  reg_rsp_t cfg_rsp_i
);

id_t  reg_id;
logic busy;

axi_to_reg_v2 #(
    // width of the address
    .AxiAddrWidth(ADDR_WIDTH),
    // width of the data
    .AxiDataWidth(DATA_WIDTH),
    // width of the id.
    .AxiIdWidth(ID_WIDTH),
    // width of the user signal.
    .AxiUserWidth(USER_WIDTH),
    // The data width of the Reg bus
    .RegDataWidth(REG_DATA_WIDTH),
    // AXI request struct type
    .axi_req_t(axi_req_t),
    // AXI response struct type
    .axi_rsp_t(axi_rsp_t),
    // regbus request struct type
    .reg_req_t(reg_req_t),
    // regbus response struct type
    .reg_rsp_t(reg_rsp_t)
) i_cfg_axi_to_reg (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),

    .axi_req_i (slv_req_i),
    .axi_rsp_o (slv_rsp_o),
    .reg_req_o (cfg_req_o),
    .reg_rsp_i (cfg_rsp_i),

    .reg_id_o(reg_id),
    .busy_o(busy)
);

endmodule
