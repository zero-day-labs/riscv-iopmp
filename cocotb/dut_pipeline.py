import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.clock import Clock
import random

from collections import deque, namedtuple

import os
import re
import logging
import random
from enum import Enum

InsertBuffer = namedtuple('InsertBuffer', ['ttype', 'rrid', 'address', 'final_address'])
queue = deque()

class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.INFO)

        cocotb.start_soon(Clock(dut.clk_i, 10, units="ns").start())

    async def cycle_reset(self):
        self.dut.rst_ni.setimmediatevalue(1)
        await RisingEdge(self.dut.clk_i)
        await RisingEdge(self.dut.clk_i)
        self.dut.rst_ni.value = 0
        await RisingEdge(self.dut.clk_i)
        await RisingEdge(self.dut.clk_i)
        self.dut.rst_ni.value = 1
        await RisingEdge(self.dut.clk_i)
        await RisingEdge(self.dut.clk_i)

class InsertItf:
    def __init__(self, dut):
        self.dut = dut

        self.valid          = dut.valid_i
        self.ttype          = dut.ttype_i
        self.rrid           = dut.rrid_i
        self.address        = dut.address_i
        self.final_address  = dut.final_address_i
        self.ready          = dut.ready_o

    async def wait_ready(self):
        await RisingEdge(self.dut.clk_i)

        while self.ready.value == 0:
            await RisingEdge(self.dut.clk_i)

    async def insert_data(self):
        for i in range(10):
            await RisingEdge(self.dut.clk_i)
            self.valid.value = 1

            self.ttype.value = 1
            self.rrid.value = 0
            self.address.value = 0x800
            self.final_address.value = 0xA00

            # queue.append(InsertBuffer(rw, id, wid))
            print(f"Sent: {self.ttype.value} {self.rrid.value}")

            await self.wait_ready()
            # self.valid.value = 0
        
        self.valid.value = 0

@cocotb.test()
async def test(dut):
    tb = TB(dut)

    insert_itf = InsertItf(dut)

    await tb.cycle_reset()

    # dut.pipeline_ready_i.value = 1

    await cocotb.start(insert_itf.insert_data())
    
    await Timer(500, units='ns')

    