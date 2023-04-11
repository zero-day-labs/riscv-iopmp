package iopmp_stimulus_pkg;

import iopmp_pkg::*;

//  Registers OFF 
localparam  int  STIMULUS_CFG_OFF       = 16'h0;
localparam  int  STIMULUS_STATUS_OFF    = 16'h8;
localparam  int  STIMULUS_DATA_OFF      = 16'h10;
localparam  int  STIMULUS_ADDR_OFF      = 16'h18;

// Register specification

typedef struct packed {
    logic                       EN;
    logic   [62:16]             reserved;
    logic   [15:2]              SID;                
    iopmp_pkg::iopmp_access_t   A;
} stimulus_cfg_t;

typedef struct packed {
    logic   [63:1]  reserved;                
    logic           TR;         // Transaction Result
} stimulus_status_t;

endpackage