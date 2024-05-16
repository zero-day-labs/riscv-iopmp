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
// Description: IOPMP memory-mapped register interface module.
//              This module was developed using LowRISC `reggen` tool.

`include "common_cells/assertions.svh"

module rv_iopmp_regmap #(
  parameter type reg_req_t = logic,
  parameter type reg_rsp_t = logic,
  parameter int AW = 14,

  // Implementation specific parameters
  parameter int unsigned NUMBER_MDS = 2,
  parameter int unsigned NUMBER_ENTRIES = 8,
  parameter int unsigned NUMBER_MASTERS = 2,
  parameter int unsigned NUMBER_PRIO_ENTRIES = 4,

  parameter int unsigned NO_W = 0
) (
  input logic clk_i,
  input logic rst_ni,
  input  reg_req_t reg_req_i,
  output reg_rsp_t reg_rsp_o,
  // To HW
  output rv_iopmp_reg_pkg::iopmp_reg2hw_t reg2hw, // Write
  input  rv_iopmp_reg_pkg::iopmp_hw2reg_t hw2reg, // Read

  output rv_iopmp_pkg::mdcfg_entry_t [NUMBER_MDS - 1    :0] mdcfg_table_o,
  output rv_iopmp_pkg::srcmd_entry_t [NUMBER_MASTERS - 1:0] srcmd_table_o,

  // Config
  input devmode_i, // If 1, explicit error return for unmapped register access

  // Entry Config
  output logic bram_we_o,
  output logic bram_en_o,
  output logic [$clog2(NUMBER_ENTRIES* 4) - 1:0] bram_addr_o,
  output logic [32 - 1 : 0]  bram_din_o,

  input logic [32 - 1 : 0] bram_dout_i,

  // Control dwidth_converter
  input logic bram_ready_i,
  input logic bram_valid_i
);

  localparam int DW = 32;
  localparam int DBW = DW/8;                    // Byte Width

  localparam int ADDR_HIT_SRCMD_EN_OFFSET   = 13 + NUMBER_MDS;
  localparam int ADDR_HIT_SRCMD_ENH_OFFSET  = ADDR_HIT_SRCMD_EN_OFFSET + NUMBER_MASTERS;

  localparam int ADDR_HIT_ENTRY_ADDR_OFFSET  = ADDR_HIT_SRCMD_ENH_OFFSET   + NUMBER_MASTERS;
  localparam int ADDR_HIT_ENTRY_ADDRH_OFFSET = ADDR_HIT_ENTRY_ADDR_OFFSET  + NUMBER_ENTRIES;
  localparam int ADDR_HIT_ENTRY_CFG_OFFSET   = ADDR_HIT_ENTRY_ADDRH_OFFSET + NUMBER_ENTRIES;

  localparam int ADDR_HIT_SIZE = ADDR_HIT_ENTRY_CFG_OFFSET + NUMBER_ENTRIES;

  // register signals
  logic           reg_we;
  logic           reg_re;
  logic [rv_iopmp_reg_pkg::BlockAw-1:0]  reg_addr;
  logic [DW-1:0]  reg_wdata;
  logic [DBW-1:0] reg_be;
  logic [DW-1:0]  reg_rdata;
  logic           reg_error;

  logic          [ADDR_HIT_SIZE - 1 : 0] wr_err_array;
  logic          addrmiss, wr_err;

  logic [DW-1:0] reg_rdata_next;

  // Below register interface can be changed
  reg_req_t  reg_intf_req;
  reg_rsp_t  reg_intf_rsp;

  logic read_from_bram;

  assign reg_intf_req = reg_req_i;
  assign reg_rsp_o = reg_intf_rsp;


  assign reg_we = reg_intf_req.valid & reg_intf_req.write;
  assign reg_re = reg_intf_req.valid & ~reg_intf_req.write;
  assign reg_addr = reg_intf_req.addr[rv_iopmp_reg_pkg::BlockAw-1:0];
  assign reg_wdata = reg_intf_req.wdata;
  assign reg_be = reg_intf_req.wstrb;
  assign reg_intf_rsp.rdata = reg_rdata;
  assign reg_intf_rsp.error = reg_error;

  // Are we reading from BRAM? Connect to valid, are we writing? Connect to ready
  // No problem here, because ready is always at one, only comes to 0 when we write to the BRAM
  assign reg_intf_rsp.ready = read_from_bram? bram_valid_i : bram_ready_i;

  assign reg_rdata = reg_rdata_next ;
  assign reg_error = (devmode_i & addrmiss) | wr_err;


  // Define SW related signals
  // Format: <reg>_<field>_{wd|we|qs}
  //        or <reg>_{wd|we|qs} if field == 1 or 0
  logic [23:0] version_vendor_qs;
  logic [7:0] version_specver_qs;
  logic [31:0] imp_qs;
  logic [3:0] hwcfg0_model_qs;
  logic hwcfg0_tor_en_qs;
  logic hwcfg0_sps_en_qs;
  logic hwcfg0_user_cfg_en_qs;
  logic hwcfg0_prient_prog_qs;
  logic hwcfg0_prient_prog_wd;
  logic hwcfg0_prient_prog_we;
  logic hwcfg0_sid_transl_en_qs;
  logic hwcfg0_sid_transl_prog_qs;
  logic hwcfg0_chk_x_qs;
  logic hwcfg0_no_x_qs;
  logic hwcfg0_no_w_qs;
  logic hwcfg0_stall_en_qs;
  logic [6:0] hwcfg0_md_num_qs;
  logic hwcfg0_enable_qs;
  logic hwcfg0_enable_wd;
  logic hwcfg0_enable_we;
  logic [15:0] hwcfg1_sid_num_qs;
  logic [15:0] hwcfg1_entry_num_qs;
  logic [15:0] hwcfg2_prio_entry_qs;
  logic [15:0] hwcfg2_prio_entry_wd;
  logic hwcfg2_prio_entry_we;
  logic [15:0] hwcfg2_sid_transl_qs;
  logic [15:0] hwcfg2_sid_transl_wd;
  logic hwcfg2_sid_transl_we;
  logic [31:0] entry_offset_qs;
  logic errreact_l_qs;
  logic errreact_l_wd;
  logic errreact_l_we;
  logic errreact_ie_qs;
  logic errreact_ie_wd;
  logic errreact_ie_we;
  logic errreact_ire_qs;
  logic errreact_ire_wd;
  logic errreact_ire_we;
  logic [2:0] errreact_rre_qs;
  logic [2:0] errreact_rre_wd;
  logic errreact_rre_we;
  logic errreact_iwe_qs;
  logic errreact_iwe_wd;
  logic errreact_iwe_we;
  logic [2:0] errreact_rwe_qs;
  logic [2:0] errreact_rwe_wd;
  logic errreact_rwe_we;
  logic errreact_pee_qs;
  logic errreact_pee_wd;
  logic errreact_pee_we;
  logic [2:0] errreact_rpe_qs;
  logic [2:0] errreact_rpe_wd;
  logic errreact_rpe_we;
  logic mdcfglck_l_qs;
  logic mdcfglck_l_wd;
  logic mdcfglck_l_we;
  logic [6:0] mdcfglck_f_qs;
  logic [6:0] mdcfglck_f_wd;
  logic mdcfglck_f_we;
  logic entrylck_l_qs;
  logic entrylck_l_wd;
  logic entrylck_l_we;
  logic [15:0] entrylck_f_qs;
  logic [15:0] entrylck_f_wd;
  logic entrylck_f_we;
  logic err_reqinfo_ip_qs;
  logic err_reqinfo_ip_wd;
  logic err_reqinfo_ip_we;
  logic [1:0] err_reqinfo_ttype_qs;
  logic [2:0] err_reqinfo_etype_qs;
  logic [15:0] err_reqid_sid_qs;
  logic [15:0] err_reqid_eid_qs;
  logic [31:0] err_reqaddr_qs;
  logic [31:0] err_reqaddrh_qs;

  // Actual tables
  rv_iopmp_pkg::mdcfg_entry_t [NUMBER_MDS     - 1: 0] mdcfg_table;
  rv_iopmp_pkg::srcmd_entry_t [NUMBER_MASTERS - 1: 0] srcmd_table;
  //rv_iopmp_pkg::iopmp_entry_t [NUMBER_ENTRIES - 1: 0] entry_table;

  assign mdcfg_table_o = mdcfg_table;
  assign srcmd_table_o = srcmd_table;
  //assign entry_table_o = entry_table;

// mdcfg signals
  logic [15:0] mdcfg_t_qs [NUMBER_MDS];
  logic [15:0] mdcfg_t_wd [NUMBER_MDS];
  logic mdcfg_t_we        [NUMBER_MDS];

// srcmd signals
  logic srcmd_en_l_qs  [NUMBER_MDS];
  logic srcmd_en_l_wd  [NUMBER_MDS];
  logic srcmd_en_l_we  [NUMBER_MDS];

  logic [30:0] srcmd_en_md_qs  [NUMBER_MDS];
  logic [30:0] srcmd_en_md_wd  [NUMBER_MDS];
  logic srcmd_en_md_we         [NUMBER_MDS];

  logic [31:0] srcmd_enh_qs  [NUMBER_MDS];
  logic [31:0] srcmd_enh_wd  [NUMBER_MDS];
  logic srcmd_enh_we         [NUMBER_MDS];

// --------------------------------

  // Register instances
  // R[version]: V(False)

  //   F[vendor]: 23:0
  // constant-only read
  assign version_vendor_qs = 24'h0;


  //   F[specver]: 31:24
  // constant-only read
  assign version_specver_qs = 8'h0;


  // R[imp]: V(False)

  // constant-only read
  assign imp_qs = 32'h0;


  // R[hwcfg0]: V(False)

  //   F[model]: 3:0
  // constant-only read
  assign hwcfg0_model_qs = 4'h0;


  //   F[tor_en]: 4:4
  // constant-only read
  assign hwcfg0_tor_en_qs = 1'h1;


  //   F[sps_en]: 5:5
  // constant-only read
  assign hwcfg0_sps_en_qs = 1'h0;


  //   F[user_cfg_en]: 6:6
  // constant-only read
  assign hwcfg0_user_cfg_en_qs = 1'h0;


  //   F[prient_prog]: 7:7
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("W1CS"),
    .RESVAL  (1'h1)
  ) u_hwcfg0_prient_prog (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (hwcfg0_prient_prog_we),
    .wd     (hwcfg0_prient_prog_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hwcfg0.prient_prog.q),

    // to register interface (read)
    .qs     (hwcfg0_prient_prog_qs)
  );


  //   F[sid_transl_en]: 8:8
  // constant-only read
  assign hwcfg0_sid_transl_en_qs = 1'h0;


  //   F[sid_transl_prog]: 9:9
  // constant-only read
  assign hwcfg0_sid_transl_prog_qs = 1'h0;


  //   F[chk_x]: 10:10
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("RO"),
    .RESVAL  (1'h0)
  ) u_hwcfg0_chk_x (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hwcfg0.chk_x.q ),

    // to register interface (read)
    .qs     (hwcfg0_chk_x_qs)
  );


  //   F[no_x]: 11:11
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("RO"),
    .RESVAL  (1'h0)
  ) u_hwcfg0_no_x (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hwcfg0.no_x.q ),

    // to register interface (read)
    .qs     (hwcfg0_no_x_qs)
  );


  //   F[no_w]: 12:12
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("RO"),
    .RESVAL  (NO_W)
  ) u_hwcfg0_no_w (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hwcfg0.no_w.q ),

    // to register interface (read)
    .qs     (hwcfg0_no_w_qs)
  );


  //   F[stall_en]: 13:13
  // constant-only read
  assign hwcfg0_stall_en_qs = 1'h0;

  /* verilator lint_off WIDTH */
  //   F[md_num]: 30:24
  // constant-only read
  assign hwcfg0_md_num_qs = NUMBER_MDS;
  /* verilator lint_on WIDTH */

  //   F[enable]: 31:31
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("W1SS"),
    .RESVAL  (1'h0)
  ) u_hwcfg0_enable (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (hwcfg0_enable_we),
    .wd     (hwcfg0_enable_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hwcfg0.enable.q ),

    // to register interface (read)
    .qs     (hwcfg0_enable_qs)
  );


  // R[hwcfg1]: V(False)

  /* verilator lint_off WIDTH */
  //   F[sid_num]: 15:0
  // constant-only read
  assign hwcfg1_sid_num_qs = NUMBER_MASTERS;


  //   F[entry_num]: 31:16
  // constant-only read
  assign hwcfg1_entry_num_qs = NUMBER_ENTRIES;
  /* verilator lint_on WIDTH */

  // R[hwcfg2]: V(False)

  //   F[prio_entry]: 15:0
  rv_iopmp_subreg #(
    .DW      (16),
    .SWACCESS("RW"),
    .RESVAL  (NUMBER_PRIO_ENTRIES)
  ) u_hwcfg2_prio_entry (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (hwcfg2_prio_entry_we),
    .wd     (hwcfg2_prio_entry_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hwcfg2.prio_entry.q ),

    // to register interface (read)
    .qs     (hwcfg2_prio_entry_qs)
  );
/* Script Modified */

  //   F[sid_transl]: 31:16
  rv_iopmp_subreg #(
    .DW      (16),
    .SWACCESS("RW"),
    .RESVAL  (16'h0)
  ) u_hwcfg2_sid_transl (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (hwcfg2_sid_transl_we),
    .wd     (hwcfg2_sid_transl_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hwcfg2.sid_transl.q ),

    // to register interface (read)
    .qs     (hwcfg2_sid_transl_qs)
  );


  // R[entry_offset]: V(False)

  rv_iopmp_subreg #(
    .DW      (32),
    .SWACCESS("RO"),
    .RESVAL  (32'h2000)
  ) u_entry_offset (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.entry_offset.q ),

    // to register interface (read)
    .qs     (entry_offset_qs)
  );


  // R[errreact]: V(False)

  //   F[l]: 0:0
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("W1SS"),
    .RESVAL  (1'h0)
  ) u_errreact_l (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (errreact_l_we),
    .wd     (errreact_l_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.errreact.l.q ),

    // to register interface (read)
    .qs     (errreact_l_qs)
  );


  //   F[ie]: 1:1
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_errreact_ie (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (errreact_ie_we),
    .wd     (errreact_ie_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.errreact.ie.q ),

    // to register interface (read)
    .qs     (errreact_ie_qs)
  );
/* Script Modified */

  //   F[ire]: 4:4
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_errreact_ire (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (errreact_ire_we),
    .wd     (errreact_ire_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.errreact.ire.q ),

    // to register interface (read)
    .qs     (errreact_ire_qs)
  );
/* Script Modified */

  //   F[rre]: 7:5
  rv_iopmp_subreg #(
    .DW      (3),
    .SWACCESS("RW"),
    .RESVAL  (3'h0)
  ) u_errreact_rre (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (errreact_rre_we),
    .wd     (errreact_rre_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.errreact.rre.q ),

    // to register interface (read)
    .qs     (errreact_rre_qs)
  );
/* Script Modified */

  //   F[iwe]: 8:8
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_errreact_iwe (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (errreact_iwe_we),
    .wd     (errreact_iwe_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.errreact.iwe.q ),

    // to register interface (read)
    .qs     (errreact_iwe_qs)
  );
/* Script Modified */

  //   F[rwe]: 11:9
  rv_iopmp_subreg #(
    .DW      (3),
    .SWACCESS("RW"),
    .RESVAL  (3'h0)
  ) u_errreact_rwe (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (errreact_rwe_we),
    .wd     (errreact_rwe_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.errreact.rwe.q ),

    // to register interface (read)
    .qs     (errreact_rwe_qs)
  );
/* Script Modified */

  //   F[pee]: 28:28
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_errreact_pee (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (errreact_pee_we),
    .wd     (errreact_pee_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.errreact.pee.q ),

    // to register interface (read)
    .qs     (errreact_pee_qs)
  );
/* Script Modified */

  //   F[rpe]: 31:29
  rv_iopmp_subreg #(
    .DW      (3),
    .SWACCESS("RW"),
    .RESVAL  (3'h0)
  ) u_errreact_rpe (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (errreact_rpe_we),
    .wd     (errreact_rpe_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.errreact.rpe.q ),

    // to register interface (read)
    .qs     (errreact_rpe_qs)
  );
/* Script Modified */

  // R[mdcfglck]: V(False)

  //   F[l]: 0:0
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("W1SS"),
    .RESVAL  (1'h0)
  ) u_mdcfglck_l (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (mdcfglck_l_we),
    .wd     (mdcfglck_l_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.mdcfglck.l.q ),

    // to register interface (read)
    .qs     (mdcfglck_l_qs)
  );


  //   F[f]: 7:1
  rv_iopmp_subreg #(
    .DW      (7),
    .SWACCESS("RW"),
    .RESVAL  (7'h0)
  ) u_mdcfglck_f (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we (mdcfglck_f_we),
    .wd (mdcfglck_f_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.mdcfglck.f.q ),

    // to register interface (read)
    .qs     (mdcfglck_f_qs)
  );
/* Script Modified */

  // R[entrylck]: V(False)

  //   F[l]: 0:0
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("W1SS"),
    .RESVAL  (1'h0)
  ) u_entrylck_l (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (entrylck_l_we),
    .wd     (entrylck_l_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.entrylck.l.q ),

    // to register interface (read)
    .qs     (entrylck_l_qs)
  );


  //   F[f]: 16:1
  rv_iopmp_subreg #(
    .DW      (16),
    .SWACCESS("RW"),
    .RESVAL  (16'h0)
  ) u_entrylck_f (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we (entrylck_f_we),
    .wd (entrylck_f_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.entrylck.f.q ),

    // to register interface (read)
    .qs     (entrylck_f_qs)
  );
/* Script Modified */

  // R[err_reqinfo]: V(False)

  //   F[ip]: 0:0
  rv_iopmp_subreg #(
    .DW      (1),
    .SWACCESS("W1C"),
    .RESVAL  (1'h0)
  ) u_err_reqinfo_ip (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (err_reqinfo_ip_we),
    .wd     (err_reqinfo_ip_wd),

    // from internal hardware
    .de     (hw2reg.err_reqinfo.ip.de),
    .d      (hw2reg.err_reqinfo.ip.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.err_reqinfo.ip.q ),

    // to register interface (read)
    .qs     (err_reqinfo_ip_qs)
  );


  //   F[ttype]: 2:1
  rv_iopmp_subreg #(
    .DW      (2),
    .SWACCESS("RO"),
    .RESVAL  (2'h0)
  ) u_err_reqinfo_ttype (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.err_reqinfo.ttype.de),
    .d      (hw2reg.err_reqinfo.ttype.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.err_reqinfo.ttype.q ),

    // to register interface (read)
    .qs     (err_reqinfo_ttype_qs)
  );


  //   F[etype]: 6:4
  rv_iopmp_subreg #(
    .DW      (3),
    .SWACCESS("RO"),
    .RESVAL  (3'h0)
  ) u_err_reqinfo_etype (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.err_reqinfo.etype.de),
    .d      (hw2reg.err_reqinfo.etype.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.err_reqinfo.etype.q ),

    // to register interface (read)
    .qs     (err_reqinfo_etype_qs)
  );


  // R[err_reqid]: V(False)

  //   F[sid]: 15:0
  rv_iopmp_subreg #(
    .DW      (16),
    .SWACCESS("RO"),
    .RESVAL  (16'h0)
  ) u_err_reqid_sid (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.err_reqid.sid.de),
    .d      (hw2reg.err_reqid.sid.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.err_reqid.sid.q ),

    // to register interface (read)
    .qs     (err_reqid_sid_qs)
  );


  //   F[eid]: 31:16
  rv_iopmp_subreg #(
    .DW      (16),
    .SWACCESS("RO"),
    .RESVAL  (16'h0)
  ) u_err_reqid_eid (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.err_reqid.eid.de),
    .d      (hw2reg.err_reqid.eid.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.err_reqid.eid.q ),

    // to register interface (read)
    .qs     (err_reqid_eid_qs)
  );


  // R[err_reqaddr]: V(False)

  rv_iopmp_subreg #(
    .DW      (32),
    .SWACCESS("RO"),
    .RESVAL  (32'h0)
  ) u_err_reqaddr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.err_reqaddr.de),
    .d      (hw2reg.err_reqaddr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.err_reqaddr.q ),

    // to register interface (read)
    .qs     (err_reqaddr_qs)
  );


  // R[err_reqaddrh]: V(False)

  rv_iopmp_subreg #(
    .DW      (32),
    .SWACCESS("RO"),
    .RESVAL  (32'h0)
  ) u_err_reqaddrh (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.err_reqaddrh.de),
    .d      (hw2reg.err_reqaddrh.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.err_reqaddrh.q ),

    // to register interface (read)
    .qs     (err_reqaddrh_qs)
  );


  //generate gen_mdcfg_entries
  for (genvar i = 0; i < NUMBER_MDS; i++) begin
      // F[t_0]: 15:0
    rv_iopmp_subreg #(
      .DW      (16),
      .SWACCESS("RW"),
      .RESVAL  (16'h0)
    ) u_mdcfg_t (
      .clk_i   (clk_i    ),
      .rst_ni  (rst_ni  ),

      // from register interface
      .we     (mdcfg_t_we[i]),
      .wd     (mdcfg_t_wd[i]),

      // from internal hardware
      .de     (1'b0),
      .d      ('0  ),

      // to internal hardware
      .qe     (),
      .q      (mdcfg_table[i].q ),

      // to register interface (read)
      .qs     (mdcfg_t_qs[i])
    );
  end
  //endgenerate

  //generate gen_srcmd_entries
  for (genvar i = 0; i < NUMBER_MASTERS; i++) begin
    // R[srcmd_en0]: V(False)
    //   F[l]: 0:0
    rv_iopmp_subreg #(
      .DW      (1),
      .SWACCESS("W1SS"),
      .RESVAL  (1'h0)
    ) u_srcmd_en_l (
      .clk_i   (clk_i    ),
      .rst_ni  (rst_ni  ),

      // from register interface
      .we     (srcmd_en_l_we[i]),
      .wd     (srcmd_en_l_wd[i]),

      // from internal hardware
      .de     (1'b0),
      .d      ('0  ),

      // to internal hardware
      .qe     (),
      .q      (srcmd_table[i].en.l.q),

      // to register interface (read)
      .qs     (srcmd_en_l_qs[i])
    );
    /* Script Modified */

    //   F[md]: 31:1
    rv_iopmp_subreg #(
      .DW      (31),
      .SWACCESS("RW"),
      .RESVAL  (31'h0)
    ) u_srcmd_en_md (
      .clk_i   (clk_i    ),
      .rst_ni  (rst_ni  ),

      // from register interface
      .we     (srcmd_en_md_we[i]),// ((reg2hw.srcmd_table[0].en.l.q == 1)? 0: srcmd_en0_md_we),
      .wd     (srcmd_en_md_wd[i]),

      // from internal hardware
      .de     (1'b0),
      .d      ('0  ),

      // to internal hardware
      .qe     (),
      .q      (srcmd_table[i].en.md.q),

      // to register interface (read)
      .qs     (srcmd_en_md_qs[i])
    );
    /* Script Modified */

    // R[srcmd_enh0]: V(False)

    rv_iopmp_subreg #(
      .DW      (32),
      .SWACCESS("RW"),
      .RESVAL  (32'h0)
    ) u_srcmd_enh (
      .clk_i   (clk_i    ),
      .rst_ni  (rst_ni  ),

      // from register interface
      .we     (srcmd_enh_we[i]),// ((reg2hw.srcmd_table[0].en.l.q == 1)? 0: srcmd_enh0_we),
      .wd     (srcmd_enh_wd[i]),

      // from internal hardware
      .de     (1'b0),
      .d      ('0  ),

      // to internal hardware
      .qe     (),
      .q      (srcmd_table[i].enh.q),

      // to register interface (read)
      .qs     (srcmd_enh_qs[i])
    );
    /* Script Modified */
  end
  //endgenerate

 logic [ADDR_HIT_SIZE - 1 : 0] addr_hit;
  // Mandatory registers
  assign addr_hit[  0] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_VERSION_OFFSET);
  assign addr_hit[  1] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_IMP_OFFSET);
  assign addr_hit[  2] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_HWCFG0_OFFSET);
  assign addr_hit[  3] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_HWCFG1_OFFSET);
  assign addr_hit[  4] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_HWCFG2_OFFSET);
  assign addr_hit[  5] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_ENTRY_OFFSET_OFFSET);
  assign addr_hit[  6] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_ERRREACT_OFFSET);
  assign addr_hit[  7] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_MDCFGLCK_OFFSET);
  assign addr_hit[  8] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_ENTRYLCK_OFFSET);
  assign addr_hit[  9] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_ERR_REQINFO_OFFSET);
  assign addr_hit[ 10] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_ERR_REQID_OFFSET);
  assign addr_hit[ 11] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_ERR_REQADDR_OFFSET);
  assign addr_hit[ 12] = (reg_addr == rv_iopmp_reg_pkg::IOPMP_ERR_REQADDRH_OFFSET);

  //generate
  for (genvar i = 0; i < NUMBER_MDS; i++) begin
    assign addr_hit[13+i]   = (reg_addr == (rv_iopmp_reg_pkg::IOPMP_MDCFG_OFFSET + i*4)); // 4 bytes
  end

  // En low
  for (genvar i = 0; i < NUMBER_MASTERS; i++)
    assign addr_hit[ADDR_HIT_SRCMD_EN_OFFSET + i] = (reg_addr == (rv_iopmp_reg_pkg::IOPMP_SRCMD_EN_OFFSET + i * 32));     // 32 bytes as per spec

  // En high
  for (genvar i = 0; i < NUMBER_MASTERS; i++)
    assign addr_hit[ADDR_HIT_SRCMD_ENH_OFFSET + i] = (reg_addr == (rv_iopmp_reg_pkg::IOPMP_SRCMD_EN_OFFSET + i * 32 + 4)); // 4 bytes


  for (genvar i = 0; i < NUMBER_ENTRIES; i++)
    assign addr_hit[ADDR_HIT_ENTRY_ADDR_OFFSET + i] = (reg_addr == (rv_iopmp_reg_pkg::IOPMP_ENTRY_ADDR_OFFSET + i * 16)); // 16 bytes as per spec

  for (genvar i = 0; i < NUMBER_ENTRIES; i++)
    assign addr_hit[ADDR_HIT_ENTRY_ADDRH_OFFSET + i] = (reg_addr == (rv_iopmp_reg_pkg::IOPMP_ENTRY_ADDR_OFFSET + i * 16 + 4)); // 4 bytes

  for (genvar i = 0; i < NUMBER_ENTRIES; i++)
    assign addr_hit[ADDR_HIT_ENTRY_CFG_OFFSET + i] = (reg_addr == (rv_iopmp_reg_pkg::IOPMP_ENTRY_ADDR_OFFSET + i * 16 + 8)); // 4 bytes

  //endgenerate

  assign addrmiss = (reg_re || reg_we) ? ~|addr_hit : 1'b0 ;

  assign wr_err = (|wr_err_array[(ADDR_HIT_SIZE- 1) : 0]);

  // Check sub-word write is permitted
  //generate gen_wr_err_array
  // Mandatory registers
  for (genvar i = 0; i < 13; i++) begin
    assign wr_err_array[i] = (addr_hit[i] & (|(rv_iopmp_reg_pkg::IOPMP_PERMIT[i] & ~reg_be)));
  end

  for (genvar i = 13; i < NUMBER_MDS; i++) begin
    assign wr_err_array[i] = (addr_hit[i] & (|(rv_iopmp_reg_pkg::IOPMP_PERMIT[13] & ~reg_be)));
  end

  for (genvar i = ADDR_HIT_SRCMD_EN_OFFSET; i < NUMBER_MASTERS; i++) begin
    assign wr_err_array[i] = (addr_hit[i] & (|(rv_iopmp_reg_pkg::IOPMP_PERMIT[14] & ~reg_be)));
  end

  for (genvar i = ADDR_HIT_SRCMD_ENH_OFFSET; i < NUMBER_MASTERS; i++) begin
    assign wr_err_array[i] = (addr_hit[i] & (|(rv_iopmp_reg_pkg::IOPMP_PERMIT[15] & ~reg_be)));
  end

  for (genvar i = ADDR_HIT_ENTRY_ADDR_OFFSET; i < NUMBER_ENTRIES; i++) begin
    assign wr_err_array[i] = (addr_hit[i] & (|(rv_iopmp_reg_pkg::IOPMP_PERMIT[16] & ~reg_be)));
  end

  for (genvar i = ADDR_HIT_ENTRY_ADDRH_OFFSET; i < NUMBER_ENTRIES; i++) begin
    assign wr_err_array[i] = (addr_hit[i] & (|(rv_iopmp_reg_pkg::IOPMP_PERMIT[17] & ~reg_be)));
  end

  for (genvar i = ADDR_HIT_ENTRY_CFG_OFFSET; i < NUMBER_ENTRIES; i++) begin
    assign wr_err_array[i] = (addr_hit[i] & (|(rv_iopmp_reg_pkg::IOPMP_PERMIT[18] & ~reg_be)));
  end

  //endgenerate


  assign hwcfg0_prient_prog_we = addr_hit[2] & reg_we & !reg_error;
  assign hwcfg0_prient_prog_wd = reg_wdata[7];

  assign hwcfg0_enable_we = addr_hit[2] & reg_we & !reg_error;
  assign hwcfg0_enable_wd = reg_wdata[31];

  /* verilator lint_off WIDTH */
  // if reg2hw.hwcfg0.prient_prog.q is not clear, we can still program the priority from entries
  assign hwcfg2_prio_entry_we = reg2hw.hwcfg0.prient_prog.q? addr_hit[4] & reg_we & !reg_error : '0;
  assign hwcfg2_prio_entry_wd = (reg_wdata[15:0] > NUMBER_ENTRIES - 1)? reg2hw.hwcfg2.prio_entry.q: reg_wdata[15:0];
  /* verilator lint_on WIDTH */

  assign hwcfg2_sid_transl_we = addr_hit[4] & reg_we & !reg_error;
  assign hwcfg2_sid_transl_wd = reg_wdata[31:16];

  assign errreact_l_we = addr_hit[6] & reg_we & !reg_error;
  assign errreact_l_wd = reg_wdata[0];

  assign errreact_ie_we = (reg2hw.errreact.l.q == 1)? 0 : addr_hit[6] & reg_we & !reg_error;
  assign errreact_ie_wd = reg_wdata[1];

  assign errreact_ire_we = (reg2hw.errreact.l.q == 1)? 0 : addr_hit[6] & reg_we & !reg_error;
  assign errreact_ire_wd = reg_wdata[4];

  assign errreact_rre_we = (reg2hw.errreact.l.q == 1)? 0 : addr_hit[6] & reg_we & !reg_error;
  assign errreact_rre_wd = reg_wdata[7:5];

  assign errreact_iwe_we = (reg2hw.errreact.l.q == 1)? 0 : addr_hit[6] & reg_we & !reg_error;
  assign errreact_iwe_wd = reg_wdata[8];

  assign errreact_rwe_we = (reg2hw.errreact.l.q == 1)? 0 : addr_hit[6] & reg_we & !reg_error;
  assign errreact_rwe_wd = reg_wdata[11:9];

  assign errreact_pee_we = (reg2hw.errreact.l.q == 1)? 0 : addr_hit[6] & reg_we & !reg_error;
  assign errreact_pee_wd = reg_wdata[28];

  assign errreact_rpe_we = (reg2hw.errreact.l.q == 1)? 0 : addr_hit[6] & reg_we & !reg_error;
  assign errreact_rpe_wd = reg_wdata[31:29];

  assign mdcfglck_l_we = addr_hit[7] & reg_we & !reg_error;
  assign mdcfglck_l_wd = reg_wdata[0];

  /* verilator lint_off WIDTH */
  assign mdcfglck_f_we = (reg2hw.mdcfglck.l.q == 1)? 0: addr_hit[7] & reg_we & !reg_error;
  assign mdcfglck_f_wd = (reg_wdata[7:1] < reg2hw.mdcfglck.f.q | reg_wdata[7:1] > NUMBER_MDS)? reg2hw.mdcfglck.f.q: reg_wdata[7:1];
  /* verilator lint_on WIDTH */

  assign entrylck_l_we = addr_hit[8] & reg_we & !reg_error;
  assign entrylck_l_wd = reg_wdata[0];

  /* verilator lint_off WIDTH */
  assign entrylck_f_we = (reg2hw.entrylck.l.q == 1)? 0: addr_hit[8] & reg_we & !reg_error;
  assign entrylck_f_wd = (reg_wdata[16:1] < reg2hw.entrylck.f.q | reg_wdata[16:1] > NUMBER_ENTRIES) ?
                            reg2hw.entrylck.f.q: reg_wdata[16:1];
  /* verilator lint_on WIDTH */

  assign err_reqinfo_ip_we = addr_hit[9] & reg_we & !reg_error;
  assign err_reqinfo_ip_wd = reg_wdata[0];

  /* verilator lint_off WIDTH */
  //generate gen_mdcfg_write_signals
  for(genvar i = 0; i < NUMBER_MDS; i++) begin 
    // If locked, do not accept writes
    assign mdcfg_t_we[i] = reg2hw.mdcfglck.f.q > 0 ? 0: addr_hit[13 + i] & reg_we & !reg_error;

    // If bigger than NUMBER_ENTRIES, or smaller than previous MD, block
    if(i == 0)
      assign mdcfg_t_wd[i] = reg_wdata[15:0] > NUMBER_ENTRIES ? mdcfg_table[i].q: reg_wdata[15:0];
    else
      assign mdcfg_t_wd[i] = reg_wdata[15:0] > NUMBER_ENTRIES | reg_wdata[15:0] < mdcfg_table[i - 1].q
                  ? mdcfg_table[i].q: reg_wdata[15:0];
  end
  //endgenerate
  /* verilator lint_on WIDTH */

  //generate gen_srcmd_write_signals
  for(genvar i = 0; i < NUMBER_MASTERS; i++) begin 
    assign srcmd_en_l_we[i] = addr_hit[ADDR_HIT_SRCMD_EN_OFFSET + i] & reg_we & !reg_error;
    assign srcmd_en_l_wd[i] = reg_wdata[0];

    assign srcmd_en_md_we[i] = (srcmd_table[i].en.l.q == 1)? 0: addr_hit[ADDR_HIT_SRCMD_EN_OFFSET + i] & reg_we & !reg_error;
    assign srcmd_en_md_wd[i] = reg_wdata[31:1];

    assign srcmd_enh_we[i] = (srcmd_table[i].en.l.q == 1)? 0: addr_hit[ADDR_HIT_SRCMD_ENH_OFFSET + i] & reg_we & !reg_error;
    assign srcmd_enh_wd[i] = reg_wdata[31:0];
  end
  //endgenerate

  logic   mdcfg_hit_vector;
  assign  mdcfg_hit_vector = (|addr_hit[(13 + NUMBER_MDS - 1):13]);

  logic   srcmd_en_hit_vector;
  assign  srcmd_en_hit_vector = (|addr_hit[(ADDR_HIT_SRCMD_EN_OFFSET + NUMBER_MASTERS - 1) : ADDR_HIT_SRCMD_EN_OFFSET]);

  logic   srcmd_enh_hit_vector;
  assign  srcmd_enh_hit_vector = (|addr_hit[(ADDR_HIT_SRCMD_ENH_OFFSET + NUMBER_MASTERS - 1) : ADDR_HIT_SRCMD_ENH_OFFSET]);

  logic   entry_addr_hit_vector;
  assign  entry_addr_hit_vector = (|addr_hit[(ADDR_HIT_ENTRY_ADDR_OFFSET + NUMBER_ENTRIES - 1) : ADDR_HIT_ENTRY_ADDR_OFFSET]);

  logic   entry_addrh_hit_vector;
  assign  entry_addrh_hit_vector = (|addr_hit[(ADDR_HIT_ENTRY_ADDRH_OFFSET + NUMBER_ENTRIES - 1) : ADDR_HIT_ENTRY_ADDRH_OFFSET]);

  logic   entry_cfg_hit_vector;
  assign  entry_cfg_hit_vector = (|addr_hit[(ADDR_HIT_ENTRY_CFG_OFFSET + NUMBER_ENTRIES - 1) : ADDR_HIT_ENTRY_CFG_OFFSET]);

  /* verilator lint_off WIDTH */
  //generate gen_entries_write_signals
  always_comb begin
    bram_we_o = 0;
    bram_en_o = 0;
    bram_din_o = '0;
    bram_addr_o = '0;

    unique case (1'b1)
      (entry_addr_hit_vector): begin
        // Enable BRAM
        bram_en_o = 1;

        for(integer i = 0; i < NUMBER_ENTRIES; i++) begin
          if(reg_we & !reg_error) begin // Writing?
            if (addr_hit[ADDR_HIT_ENTRY_ADDR_OFFSET + i] & ((reg2hw.entrylck.f.q < i) |
                (reg2hw.entrylck.f.q == 0))) begin

              // Enable writing
              bram_we_o = 1;
              bram_din_o[31:0] = reg_wdata[31:0];
            end
          end

          if (addr_hit[ADDR_HIT_ENTRY_ADDR_OFFSET + i]) // Enters both in writing and reading
            bram_addr_o = i << 2; // Put correct address
        end
      end

      (entry_addrh_hit_vector): begin
        // Enable BRAM
        bram_en_o = 1;

        for(integer i = 0; i < NUMBER_ENTRIES; i++) begin
          if(reg_we & !reg_error) begin // Writing?
            if (addr_hit[ADDR_HIT_ENTRY_ADDRH_OFFSET + i] & ((reg2hw.entrylck.f.q < i) | 
                (reg2hw.entrylck.f.q == 0))) begin

              // Enable writing
              bram_we_o = 1;
              bram_din_o[31:0] = reg_wdata[31:0];
            end
          end
          if (addr_hit[ADDR_HIT_ENTRY_ADDRH_OFFSET + i]) // Enters both in writing and reading
            bram_addr_o = (i << 2) + 1; // Put correct address
        end
      end

      (entry_cfg_hit_vector): begin
        // Enable BRAM
        bram_en_o = 1;

        for(integer i = 0; i < NUMBER_ENTRIES; i++) begin
          if(reg_we & !reg_error) begin // Writing?
            if (addr_hit[ADDR_HIT_ENTRY_CFG_OFFSET + i] & ((reg2hw.entrylck.f.q < i) | 
                (reg2hw.entrylck.f.q == 0))) begin

              // Enable writing
              bram_we_o = 1;
              bram_din_o[0] = reg_wdata[0];
              bram_din_o[1] = reg_wdata[1];
              bram_din_o[2] = reg_wdata[2];
              bram_din_o[4:3] = reg_wdata[4:3];
            end
          end

          if (addr_hit[ADDR_HIT_ENTRY_CFG_OFFSET + i]) // Enters both in writing and reading
            bram_addr_o = (i << 2) + 2; // Put correct address
        end
      end
      default: ;
    endcase
  end
  /* verilator lint_on WIDTH */

  // Read data return
  always_comb begin
    reg_rdata_next = '0;

    read_from_bram = 0;
    unique case (1'b1)
      addr_hit[0]: begin
        reg_rdata_next[23:0] = version_vendor_qs;
        reg_rdata_next[31:24] = version_specver_qs;
      end

      addr_hit[1]: begin
        reg_rdata_next[31:0] = imp_qs;
      end

      addr_hit[2]: begin
        reg_rdata_next[3:0] = hwcfg0_model_qs;
        reg_rdata_next[4] = hwcfg0_tor_en_qs;
        reg_rdata_next[5] = hwcfg0_sps_en_qs;
        reg_rdata_next[6] = hwcfg0_user_cfg_en_qs;
        reg_rdata_next[7] = hwcfg0_prient_prog_qs;
        reg_rdata_next[8] = hwcfg0_sid_transl_en_qs;
        reg_rdata_next[9] = hwcfg0_sid_transl_prog_qs;
        reg_rdata_next[10] = hwcfg0_chk_x_qs;
        reg_rdata_next[11] = hwcfg0_no_x_qs;
        reg_rdata_next[12] = hwcfg0_no_w_qs;
        reg_rdata_next[13] = hwcfg0_stall_en_qs;
        reg_rdata_next[30:24] = hwcfg0_md_num_qs;
        reg_rdata_next[31] = hwcfg0_enable_qs;
      end

      addr_hit[3]: begin
        reg_rdata_next[15:0] = hwcfg1_sid_num_qs;
        reg_rdata_next[31:16] = hwcfg1_entry_num_qs;
      end

      addr_hit[4]: begin
        reg_rdata_next[15:0] = hwcfg2_prio_entry_qs;
        reg_rdata_next[31:16] = hwcfg2_sid_transl_qs;
      end

      addr_hit[5]: begin
        reg_rdata_next[31:0] = entry_offset_qs;
      end

      addr_hit[6]: begin
        reg_rdata_next[0] = errreact_l_qs;
        reg_rdata_next[1] = errreact_ie_qs;
        reg_rdata_next[4] = errreact_ire_qs;
        reg_rdata_next[7:5] = errreact_rre_qs;
        reg_rdata_next[8] = errreact_iwe_qs;
        reg_rdata_next[11:9] = errreact_rwe_qs;
        reg_rdata_next[28] = errreact_pee_qs;
        reg_rdata_next[31:29] = errreact_rpe_qs;
      end

      addr_hit[7]: begin
        reg_rdata_next[0] = mdcfglck_l_qs;
        reg_rdata_next[7:1] = mdcfglck_f_qs;
      end

      addr_hit[8]: begin
        reg_rdata_next[0] = entrylck_l_qs;
        reg_rdata_next[16:1] = entrylck_f_qs;
      end

      addr_hit[9]: begin
        reg_rdata_next[0] = err_reqinfo_ip_qs;
        reg_rdata_next[2:1] = err_reqinfo_ttype_qs;
        reg_rdata_next[6:4] = err_reqinfo_etype_qs;
      end

      addr_hit[10]: begin
        reg_rdata_next[15:0] = err_reqid_sid_qs;
        reg_rdata_next[31:16] = err_reqid_eid_qs;
      end

      addr_hit[11]: begin
        reg_rdata_next[31:0] = err_reqaddr_qs;
      end

      addr_hit[12]: begin
        reg_rdata_next[31:0] = err_reqaddrh_qs;
      end

      (mdcfg_hit_vector): begin
        for(integer i = 0; i < NUMBER_MDS; i++) begin
          if (addr_hit[13 + i]) begin
            reg_rdata_next[15:0] = mdcfg_t_qs[i];
            reg_rdata_next[31:16] = '0;
          end
        end
      end

      (srcmd_en_hit_vector): begin
        for(integer i = 0; i < NUMBER_MASTERS; i++) begin
          if (addr_hit[ADDR_HIT_SRCMD_EN_OFFSET + i]) begin
            reg_rdata_next[0] = srcmd_en_l_qs[i];
            reg_rdata_next[31:1] = srcmd_en_md_qs[i];
          end
        end
      end

      (srcmd_enh_hit_vector): begin
        for(integer i = 0; i < NUMBER_MASTERS; i++) begin
          if (addr_hit[ADDR_HIT_SRCMD_ENH_OFFSET + i]) begin
            reg_rdata_next[31:0] = srcmd_enh_qs[i];
          end
        end
      end

      (entry_addr_hit_vector): begin
        read_from_bram = reg_re; // Are we actually reading?

        for(integer i = 0; i < NUMBER_ENTRIES; i++) begin
          if (addr_hit[ADDR_HIT_ENTRY_ADDR_OFFSET + i]) begin
            reg_rdata_next[31:0] = bram_dout_i;
          end
        end
      end

      (entry_addrh_hit_vector): begin
        read_from_bram = reg_re; // Are we actually reading?

        for(integer i = 0; i < NUMBER_ENTRIES; i++) begin
          if (addr_hit[ADDR_HIT_ENTRY_ADDRH_OFFSET + i]) begin
            reg_rdata_next[31:0] = bram_dout_i;
          end
        end
      end

      (entry_cfg_hit_vector): begin
        read_from_bram = reg_re; // Are we actually reading?

        for(integer i = 0; i < NUMBER_ENTRIES; i++) begin
          if (addr_hit[ADDR_HIT_ENTRY_CFG_OFFSET + i]) begin
            reg_rdata_next[0] = bram_dout_i[0];
            reg_rdata_next[1] = bram_dout_i[1];
            reg_rdata_next[2] = bram_dout_i[2];
            reg_rdata_next[4:3] = bram_dout_i[4:3];
          end
        end
      end

      default: begin
        reg_rdata_next = '1;
      end
    endcase
  end

  // Unused signal tieoff

  // wdata / byte enable are not always fully used
  // add a blanket unused statement to handle lint waivers
  logic unused_wdata;
  logic unused_be;
  assign unused_wdata = ^reg_wdata;
  assign unused_be = ^reg_be;

  // Assertions for Register Interface
  `ASSERT(en2addrHit, (reg_we || reg_re) |-> $onehot0(addr_hit))

endmodule
