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

build: tpl subsystem

tpl:
	$(PYTHON) tpl_scripts/rv_iopmp_template.py

subsystem:
	$(MAKE) -C ./regmap_scripts

update_srcs:
	$(MAKE) transfer -C ./regmap_scripts

clean:
	rm -rf *.sv *.html *.h
