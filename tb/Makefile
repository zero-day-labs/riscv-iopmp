# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

# Makefile

# defaults
SIM ?= verilator
EXTRA_ARGS += --trace --trace-structs -Wno-CASEINCOMPLETE -Wno-UNOPTFLAT -Wno-UNSIGNED -Wno-CMPCONST
WAVES ?= 1
TOPLEVEL_LANG ?= verilog

VERILOG_INCLUDE_DIRS += $(PWD)/../packages/dependencies/
VERILOG_INCLUDE_DIRS += $(PWD)/../include/
VERILOG_INCLUDE_DIRS += $(PWD)/../include/common_cells
VERILOG_INCLUDE_DIRS += $(PWD)/../include/register_interface

VERILOG_SOURCES += $(PWD)/../packages/dependencies/cf_math_pkg.sv
VERILOG_SOURCES += $(PWD)/../packages/dependencies/axi_pkg.sv
VERILOG_SOURCES += $(PWD)/../packages/dependencies/ariane_pkg.sv
VERILOG_SOURCES += $(PWD)/../packages/rv_iopmp/rv_iopmp_reg_pkg.sv
VERILOG_SOURCES += $(PWD)/../packages/rv_iopmp/rv_iopmp_pkg.sv
VERILOG_SOURCES += $(PWD)/../vendor/*.sv
VERILOG_SOURCES += $(PWD)/../vendor/connector/*.sv
VERILOG_SOURCES += $(PWD)/../rtl/matching_logic/decision_logic/*.sv
VERILOG_SOURCES += $(PWD)/../rtl/matching_logic/*.sv
VERILOG_SOURCES += $(PWD)/../rtl/interfaces/axi_support/*.sv
VERILOG_SOURCES += $(PWD)/../rtl/interfaces/*.sv
VERILOG_SOURCES += $(PWD)/../rtl/*.sv
VERILOG_SOURCES += $(PWD)/dut_iopmp.sv
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = dut_iopmp

# MODULE is the basename of the Python test file
MODULE = test_rv_iopmp

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
