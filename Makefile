# Copyright © 2024 Luís Cunha & Zero-Day Labs, Lda.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author:   Luís Cunha <luisccunha8@gmail.com>
# Date:     27/03/2024
#
# Description:  Makefile to perform lint checks in the RISC-V IOPMP IP using verilator

WARN_FLAGS += -Wno-MULTITOP
WARN_FLAGS += -Wno-UNOPTFLAT
WARN_FLAGS += -Wno-CASEINCOMPLETE
WARN_FLAGS += -Wno-UNSIGNED
WARN_FLAGS += -Wno-CMPCONST
WARN_FLAGS += -Wno-SYMRSVDWORD
WARN_FLAGS += -Wno-LATCH

INC += -I./packages/dependencies
INC += -I./packages/rv_iopmp
INC += -I./vendor
INC += -I./include
INC += -I./rtl
INC += -I./rtl/matching_logic
INC += -I./rtl/interfaces
INC += -I./rtl/interfaces/axi_support
INC += -I./rtl/interfaces/regmap

all: lint

lint:
	verilator --lint-only lint_checks.sv ${INC} ${WARN_FLAGS}

lint_less:
	verilator --lint-only lint_checks.sv -${INC} ${WARN_FLAGS} | less

lint_log:
	verilator --lint-only lint_checks.sv ${INC} ${WARN_FLAGS} 2> verilator_log.txt