# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

# Makefile

# defaults
SIM ?= verilator
EXTRA_ARGS += --trace --trace-structs
WAVES ?= 1
TOPLEVEL_LANG ?= verilog

# VERILOG_SOURCES += $(PWD)/pkgs/*_pkg.sv
# VERILOG_SOURCES += $(PWD)/register_interface/src/*.sv
# VERILOG_SOURCES += $(PWD)/dut.sv
# VERILOG_SOURCES += $(PWD)/wg_checker_txn_buffer.sv
VERILOG_INCLUDE_DIRS += $(PWD)/../packages/dependencies/
VERILOG_INCLUDE_DIRS += $(PWD)/../include/
VERILOG_SOURCES += $(PWD)/../packages/dependencies/cf_math_pkg.sv
VERILOG_SOURCES += $(PWD)/../packages/rv_iopmp/rv_iopmp_reg_pkg.sv
VERILOG_SOURCES += $(PWD)/../packages/rv_iopmp/rv_iopmp_pkg.sv
VERILOG_SOURCES += $(PWD)/../packages/dependencies/axi_pkg.sv
VERILOG_SOURCES += $(PWD)/../packages/dependencies/ariane_axi_pkg.sv
VERILOG_SOURCES += $(PWD)/../vendor/*.sv
VERILOG_SOURCES += $(PWD)/../rtl/bridge/*.sv
VERILOG_SOURCES += $(PWD)/../rtl/regmap/*.sv
VERILOG_SOURCES += $(PWD)/../rtl/checker/rv_iopmp_entry_analyzer.sv
VERILOG_SOURCES += $(PWD)/../rtl/checker/rv_iopmp_checker.sv
VERILOG_SOURCES += $(PWD)/../rtl/rv_iopmp_top.sv
VERILOG_SOURCES += $(PWD)/dut_top.sv

# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = dut_top

# MODULE is the basename of the Python test file
MODULE = dut_top

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
