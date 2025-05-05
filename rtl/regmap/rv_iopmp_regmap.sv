
`include "register_interface/assign.svh"
`include "register_interface/typedef.svh"

module rv_iopmp_regmap #(
    /// The width of the address.
    parameter int unsigned AxiAddrWidth = 32'd0,
    /// The width of the data.
    parameter int unsigned AxiDataWidth = 32'd0,
    /// The width of the id.
    parameter int unsigned AxiIdWidth   = 32'd0,
    /// The width of the user signal.
    parameter int unsigned AxiUserWidth = 32'd0,

    /// AXI request struct type.
    parameter type         axi_req_t    = logic,
    /// AXI response struct type.
    parameter type         axi_rsp_t    = logic,

    parameter type         mdcfg_t      = logic,       
    parameter type         srcmd_t      = logic,       
    parameter type         entry_t      = logic,
    parameter type         error_t      = logic,

    parameter int          N_MDS        = 1,
    parameter int          N_RRID       = 1,
    parameter int          N_ENTRIES    = 1
) (
    input logic clk_i,
    input logic rst_ni,
  
    input  axi_req_t  axi_req_i,
    output axi_rsp_t  axi_rsp_o,

    output mdcfg_t  [N_MDS     - 1:0] mdcfg_data_o,
    output srcmd_t  [N_RRID    - 1:0] srcmd_data_o,
    output entry_t  [N_ENTRIES - 1:0] entry_data_o,


    input   error_t error_i,
    input   logic   error_valid_i
);

    `REG_BUS_TYPEDEF_ALL(checker_reg, logic[13:0], logic[31:0], logic[3:0])

    checker_reg_req_t reg_req;
    checker_reg_rsp_t reg_rsp;

    rv_iopmp_reg_pkg::rv_iopmp_reg2hw_t reg2hw;
    rv_iopmp_reg_pkg::rv_iopmp_hw2reg_t hw2reg;

    assign hw2reg = '{default:'0};

    axi_to_reg_v2 #(
        .AxiAddrWidth (AxiAddrWidth),
        .AxiDataWidth (AxiDataWidth),
        .AxiIdWidth   (AxiIdWidth  ),
        .AxiUserWidth (AxiUserWidth),
        .RegDataWidth (32),

        .axi_req_t    (axi_req_t),
        .axi_rsp_t    (axi_rsp_t),

        .reg_req_t    (checker_reg_req_t),
        .reg_rsp_t    (checker_reg_rsp_t)

    ) i_axi_to_reg_v2 (
        .clk_i,
        .rst_ni,

        .axi_req_i,
        .axi_rsp_o,

        .reg_req_o      (reg_req),
        .reg_rsp_i      (reg_rsp),

        .reg_id_o       (),
        .busy_o         ()
    );

    rv_iopmp_reg_top #(
        .reg_req_t    (checker_reg_req_t),
        .reg_rsp_t    (checker_reg_rsp_t),

        .N_MDS        (N_MDS),
        .N_RRID       (N_RRID),
        .N_ENTRIES    (N_ENTRIES)
    ) i_rv_iopmp_reg_top (
        .clk_i,
        .rst_ni,
        
        .reg_req_i  (reg_req),
        .reg_rsp_o  (reg_rsp),
        
        // To HW
        .reg2hw, // Write
        .hw2reg, // Read

        // Config
        .devmode_i (0) // If 1, explicit error return for unmapped register access
    );

    for (genvar i = 0; i < N_MDS; i++) begin : gen_populate_mdcfg
        assign mdcfg_data_o[i] = reg2hw.mdcfg[i];
    end

    for (genvar i = 0; i < N_RRID; i++) begin : gen_populate_srcmd
        assign srcmd_data_o[i].md = {reg2hw.srcmd_enh[i], reg2hw.srcmd_en[i].md};
    end

    for (genvar i = 0; i < N_ENTRIES; i++) begin : gen_populate_entry
        assign entry_data_o[i].addrl = reg2hw.entry_addr[i];
        assign entry_data_o[i].addrh = reg2hw.entry_addrh[i];

        assign entry_data_o[i].cfg   = reg2hw.entry_cfg[i];
    end

    // wg_checker_error_handler #(
    //     .error_t (error_t)
    // ) i_wg_checker_error_handler (
    //     .error_i,
    //     .error_valid_i,

    //     .be_i   (reg2hw.errcauseh.be),
    //     .ip_i   (reg2hw.errcauseh.ip),

    //     .addrl_o    (hw2reg.erraddrl.d),
    //     .addrl_de_o (hw2reg.erraddrl.de),

    //     .addrh_o    (hw2reg.erraddrh.d),
    //     .addrh_de_o (hw2reg.erraddrh.de),

    //     .wid_o      (hw2reg.errcausel.wid.d),
    //     .wid_de_o   (hw2reg.errcausel.wid.de),

    //     .r_o        (hw2reg.errcausel.r.d),
    //     .r_de_o     (hw2reg.errcausel.r.de),

    //     .w_o        (hw2reg.errcausel.w.d),
    //     .w_de_o     (hw2reg.errcausel.w.de),

    //     .be_o       (hw2reg.errcauseh.be.d),
    //     .be_de_o    (hw2reg.errcauseh.be.de),

    //     .ip_o       (hw2reg.errcauseh.ip.d),
    //     .ip_de_o    (hw2reg.errcauseh.ip.de)
    // );

endmodule