// Global include file for register interface
// Created for particular use in development process
//

`include "register_interface/typedef.svh"
`include "axi/typedef.svh"
`include "axi_pkg.sv"

`ifndef GLOBAL_TYPEDEF_SVH
`define GLOBAL_TYPEDEF_SVH


//Memory-mapped Register IF types name, addr_t, data_t, strb_t
`REG_BUS_TYPEDEF_ALL(iopmp_reg, logic[13:0], logic[31:0], logic[3:0])

`endif
