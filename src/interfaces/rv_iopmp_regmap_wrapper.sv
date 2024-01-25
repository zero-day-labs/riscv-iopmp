`include "common_cells/assertions.svh"

module rv_iopmp_regmap_wrapper #(
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic,

    // Implementation specific parameters
    parameter int unsigned NUMBER_MDS = 2,
    parameter int unsigned NUMBER_ENTRIES = 8,
    parameter int unsigned NUMBER_MASTERS = 2,
    parameter int unsigned NUMBER_IOPMP_INSTANCES = 1
) (
    input logic clk_i,
    input logic rst_ni,

    input  reg_req_t cfg_reg_req_i,
    output reg_rsp_t cfg_reg_rsp_o,

    input error_capture_t [NUMBER_IOPMP_INSTANCES - 1 : 0] err_interface_i,

    output logic iopmp_enabled_o,
    output rv_iopmp_pkg::mdcfg_entry_t [NUMBER_MDS     - 1:0] mdcfg_table_o,
    output rv_iopmp_pkg::srcmd_entry_t [NUMBER_MASTERS - 1:0] srcmd_table_o,
    output rv_iopmp_pkg::iopmp_entry_t [NUMBER_ENTRIES - 1:0] entry_table_o,

    output logic wsi_wire_o,
    // Config
    input devmode_i // If 1, explicit error return for unmapped register access
);

import rv_iopmp_reg_pkg::*;

// Device configuration and status registers
iopmp_reg2hw_t reg2hw;
iopmp_hw2reg_t hw2reg;

assign iopmp_enabled_o = reg2hw.hwcfg0.enable.q;

reg_req_t cfg_req_mod;
reg_rsp_t cfg_rsp_mod;

assign cfg_req_mod = cfg_reg_req_i;
assign cfg_reg_rsp_o = cfg_rsp_mod;

// Register interface instantiation
rv_iopmp_regmap #(
    .reg_req_t(reg_req_t),
    .reg_rsp_t(reg_rsp_t),

    .NUMBER_MDS(NUMBER_MDS),
    .NUMBER_ENTRIES(NUMBER_ENTRIES),
    .NUMBER_MASTERS(NUMBER_MASTERS)
) i_rv_iopmp_regmap (
    .clk_i,
    .rst_ni,
    .devmode_i(1'b0),  // if 1, explicit error return for unmapped register access

    // register interface
    .reg_req_i(cfg_req_mod),
    .reg_rsp_o(cfg_rsp_mod),

    .mdcfg_table_o(mdcfg_table_o),
    .srcmd_table_o(srcmd_table_o),
    .entry_table_o(entry_table_o),

    // from registers to hardware
    .hw2reg   (hw2reg),
    .reg2hw   (reg2hw)
);

rv_iopmp_error_capture #(
    // Implementation specific parameters
    .NUMBER_IOPMP_INSTANCES(NUMBER_IOPMP_INSTANCES)
) i_rv_iopmp_error_capture (
    .reg2hw_err_reqinfo_i  ( reg2hw.err_reqinfo  ),
    .reg2hw_err_reqid_i    ( reg2hw.err_reqid    ),
    .reg2hw_err_reqaddr_i  ( reg2hw.err_reqaddr  ),
    .reg2hw_err_reqaddrh_i ( reg2hw.err_reqaddrh ),

    .hw2reg_err_reqinfo_o  ( hw2reg.err_reqinfo  ),
    .hw2reg_err_reqid_o    ( hw2reg.err_reqid    ),
    .hw2reg_err_reqaddr_o  ( hw2reg.err_reqaddr  ),
    .hw2reg_err_reqaddrh_o ( hw2reg.err_reqaddrh ),

    .err_interface_i(err_interface_i)
);

rv_iopmp_wsi_ig i_rv_iopmp_wsi_ig(
    // Enabled interrupts
    .wsi_en_i(reg2hw.errreact.ie.q),

    // Interrupt pending bits
    .intp_i(reg2hw.err_reqinfo.ip.q),

    // Interrupt vectors
    .intv_i ({reg2hw.errreact.ire.q & reg2hw.err_reqinfo.ttype == 1, reg2hw.errreact.iwe.q & reg2hw.err_reqinfo.ttype == 2}),  // Read: 1, Write : 0

    // interrupt wires
    .wsi_wire_o(wsi_wire_o)
);

endmodule
