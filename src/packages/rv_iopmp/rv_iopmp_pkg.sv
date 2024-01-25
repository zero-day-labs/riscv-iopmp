package rv_iopmp_pkg;

import rv_iopmp_reg_pkg::*;

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

    iopmp_reg2hw_err_reqid_reg_t     err_reqid;
    iopmp_reg2hw_err_reqaddr_reg_t   err_reqaddr;
    iopmp_reg2hw_err_reqaddrh_reg_t  err_reqaddrh;
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
