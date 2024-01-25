# Copyright 2022 ETH Zurich and University of Bologna.
# Copyright and related rights are licensed under the Solderpad Hardware
# License, Version 0.51 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# Author:      Andreas Kuster, <kustera@ethz.ch>
# Description: Generate status and configuration register RTL, C header and html doc

DIR_NAME ?= $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
PYTHON ?= python3

.PHONY: clean

all: rtl header doc

rtl:
	rm -r script_generated/
	mkdir script_generated
	$(PYTHON) $(PULP_PLATFORM_REGUTIL)/regtool.py $(DIR_NAME)rv_iopmp_v1_0.hjson -t $(DIR_NAME) -r
	$(PYTHON) scripts/pkg_editor.py
	rm iopmp_reg_pkg.sv iopmp_reg_top.sv

header:
	$(PYTHON) $(PULP_PLATFORM_REGUTIL)/regtool.py $(DIR_NAME)rv_iopmp_v1_0.hjson -D > $(DIR_NAME)rv_iopmp.h

doc:
	$(PYTHON) $(PULP_PLATFORM_REGUTIL)/regtool.py $(DIR_NAME)rv_iopmp_v1_0.hjson -d > $(DIR_NAME)doc.html

transfer:
	mv script_generated/rv_iopmp_reg_pkg.sv ../../src/packages/rv_iopmp
	# mv script_generated/rv_iopmp_regmap.sv  ../../src/interfaces
	# mv ./rv_iopmp.h  ../../src/include

clean:
	rm -rf *.sv *.html *.h
