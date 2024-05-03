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
// Date: 23/02/2024
//
// Description: RISC-V IOPMP SV package.

package rv_iopmp_pkg;

//  IOPMP Mode
typedef enum logic [1:0] {
    OFF   = 2'b00,
    TOR   = 2'b01,
    NA4   = 2'b10,
    NAPOT = 2'b11
} mode_t;

// IOPMP Access Type
typedef enum logic [2:0] {
    ACCESS_NONE         = 3'b000,
    ACCESS_READ         = 3'b001,
    ACCESS_WRITE        = 3'b010,
    ACCESS_EXECUTION    = 3'b100
} access_t;

// IOPMP error Type
typedef struct packed {
    logic                               error_detected;
    logic [1:0]                         ttype;
    logic [2:0]                         etype;

    rv_iopmp_reg_pkg::iopmp_reg2hw_err_reqid_reg_t     err_reqid;
    rv_iopmp_reg_pkg::iopmp_reg2hw_err_reqaddr_reg_t   err_reqaddr;
    rv_iopmp_reg_pkg::iopmp_reg2hw_err_reqaddrh_reg_t  err_reqaddrh;
} error_capture_t;


// Entry definition
typedef struct packed {
    logic [31:0] q;
} entry_addr_t;

typedef struct packed {
    logic [31:0] q;
} entry_addrh_t;

typedef struct packed {
    struct packed {
        logic        q;
    } r;
    struct packed {
        logic        q;
    } w;
    struct packed {
        logic        q;
    } x;
    struct packed {
        logic [1:0]  q;
    } a;
} entry_cfg_t;

typedef struct packed {
    entry_addr_t addr;
    entry_addrh_t addrh;
    entry_cfg_t cfg;
} iopmp_entry_t;

// srcmd definition
typedef struct packed {
  struct packed {
    logic        q;
  } l;
  struct packed {
    logic [30:0] q;
  } md;
} srcmd_en_t;

typedef struct packed {
  logic [31:0] q;
} srcmd_enh_t;

typedef struct packed {
  srcmd_en_t en;
  srcmd_enh_t enh;
} srcmd_entry_t;

// mdcfg
typedef struct packed {
    logic [15:0] q;
} mdcfg_entry_t;

endpackage

/// An AXI4 NSAID Enabled interface.
interface AXI_BUS_NSAID #(
  parameter AXI_ADDR_WIDTH = -1,
  parameter AXI_DATA_WIDTH = -1,
  parameter AXI_ID_WIDTH   = -1,
  parameter AXI_USER_WIDTH = -1
);

  import axi_pkg::*;

  localparam AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;

  typedef logic [AXI_ID_WIDTH-1:0]   id_t;
  typedef logic [AXI_ADDR_WIDTH-1:0] addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0] data_t;
  typedef logic [AXI_STRB_WIDTH-1:0] strb_t;
  typedef logic [AXI_USER_WIDTH-1:0] user_t;
  typedef logic [5:0] atop_t;

  // AXI NSAID signal - 4 bits per spec
  typedef logic [3:0] nsaid_t;

  id_t        aw_id;
  addr_t      aw_addr;
  logic [7:0] aw_len;
  logic [2:0] aw_size;
  burst_t     aw_burst;
  logic       aw_lock;
  cache_t     aw_cache;
  prot_t      aw_prot;
  qos_t       aw_qos;
  atop_t      aw_atop;
  region_t    aw_region;
  user_t      aw_user;
  nsaid_t     aw_nsaid;
  logic       aw_valid;
  logic       aw_ready;

  data_t      w_data;
  strb_t      w_strb;
  logic       w_last;
  user_t      w_user;
  logic       w_valid;
  logic       w_ready;

  id_t        b_id;
  resp_t      b_resp;
  user_t      b_user;
  logic       b_valid;
  logic       b_ready;

  id_t        ar_id;
  addr_t      ar_addr;
  logic [7:0] ar_len;
  logic [2:0] ar_size;
  burst_t     ar_burst;
  logic       ar_lock;
  cache_t     ar_cache;
  prot_t      ar_prot;
  qos_t       ar_qos;
  region_t    ar_region;
  user_t      ar_user;
  nsaid_t     ar_nsaid;
  logic       ar_valid;
  logic       ar_ready;

  id_t        r_id;
  data_t      r_data;
  resp_t      r_resp;
  logic       r_last;
  user_t      r_user;
  logic       r_valid;
  logic       r_ready;

  modport Master (
    output aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_atop, aw_region, aw_user, aw_nsaid, aw_valid, input aw_ready,
    output w_data, w_strb, w_last, w_user, w_valid, input w_ready,
    input b_id, b_resp, b_user, b_valid, output b_ready,
    output ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_nsaid, ar_valid, input ar_ready,
    input r_id, r_data, r_resp, r_last, r_user, r_valid, output r_ready
  );

  modport Slave (
    input aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_atop, aw_region, aw_user, aw_nsaid, aw_valid, output aw_ready,
    input w_data, w_strb, w_last, w_user, w_valid, output w_ready,
    output b_id, b_resp, b_user, b_valid, input b_ready,
    input ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_nsaid, ar_valid, output ar_ready,
    output r_id, r_data, r_resp, r_last, r_user, r_valid, input r_ready
  );

endinterface