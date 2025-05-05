
module dut_regmap #(

) (
    input logic clk_i,
    input logic rst_ni,

    // Req
    input   logic               aw_valid_i,
    input   ariane_axi::addr_t  aw_addr_i,
    input   axi_pkg::len_t      aw_len_i, 
    input   axi_pkg::size_t     aw_size_i,

    input   logic               w_valid_i,
    input   ariane_axi::data_t  w_data_i,
    input   ariane_axi::strb_t  w_strb_i,
    input   logic               w_last_i,

    // Rsp
    output  logic               aw_ready_o,
    output  logic               w_ready_o
);

    ariane_axi::req_t   axi_req;
    ariane_axi::resp_t  axi_rsp;

    always_comb begin
        axi_req = '{default:0};

        axi_req.aw_valid = aw_valid_i;
        axi_req.aw.addr  = aw_addr_i;
        axi_req.aw.len   = aw_len_i;
        axi_req.aw.size  = aw_size_i;
        axi_req.b_ready  = 1'b1;

        axi_req.w_valid  = w_valid_i;
        axi_req.w.data   = w_data_i;
        axi_req.w.strb   = w_strb_i;
        axi_req.w.last   = w_last_i;

        aw_ready_o       = axi_rsp.aw_ready;
        w_ready_o        = axi_rsp.w_ready;
    end

    wg_checker_regmap #(

        .AxiAddrWidth (ariane_axi::AddrWidth),
        .AxiDataWidth (ariane_axi::DataWidth),
        .AxiIdWidth   (ariane_axi::IdWidth),
        .AxiUserWidth (ariane_axi::UserWidth),

        .axi_req_t    (ariane_axi::req_t),
        .axi_rsp_t    (ariane_axi::resp_t)

    ) i_wg_checker_regmap (
        .clk_i,
        .rst_ni,
    
        .axi_req_i (axi_req),
        .axi_rsp_o (axi_rsp)
    );

endmodule
