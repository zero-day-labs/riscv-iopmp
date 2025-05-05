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

AWMsg = namedtuple('AWMsg', ['addr', 'len', 'size'])
WMsg  = namedtuple('WMsg', ['data', 'strb', 'len'])
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

class AWChannel:
    def __init__(self, dut):
        self.dut = dut

        self.valid          = dut.aw_valid_i
        self.ready          = dut.aw_ready_o
        self.addr           = dut.aw_addr_i
        self.len            = dut.aw_len_i
        self.size           = dut.aw_size_i

    async def wait_ready(self):
        await RisingEdge(self.dut.clk_i)

        while self.ready.value == 0:
            await RisingEdge(self.dut.clk_i)

    async def send_msg(self, msg):
        await RisingEdge(self.dut.clk_i)
        self.valid.value = 1
        self.addr.value = msg.addr
        self.len.value  = msg.len
        self.size.value = msg.size
        
        await self.wait_ready()
        self.valid.value = 0

class WChannel:
    def __init__(self, dut):
        self.dut = dut

        self.valid          = dut.w_valid_i
        self.ready          = dut.w_ready_o
        self.strb           = dut.w_strb_i
        self.last           = dut.w_last_i
        self.data           = dut.w_data_i

    async def wait_ready(self):
        await RisingEdge(self.dut.clk_i)

        while self.ready.value == 0:
            await RisingEdge(self.dut.clk_i)

    async def send_msg(self, msg):
        await RisingEdge(self.dut.clk_i)

        for i in range(msg.len + 1):
            self.valid.value = 1
            self.data.value = msg.data[i]
            self.strb.value = msg.strb[i]

            if i == msg.len:
                self.last.value = 1
            else:
                self.last.value = 0

            await self.wait_ready()

        self.valid.value = 0

async def config_slot_cfg_msg(aw_channel, w_channel, slot, addr, len, rwids, wwids):
    slot_base_addr = (slot * 0x20) + 0x20
    
    # Start trans
    msg = AWMsg(slot_base_addr, 2, 3)
    await aw_channel.send_msg(msg)

    cfg_addr = (addr >> 2) + (len >> 3) - 1
    perm = 0
    for wid in rwids:
        perm |= 1 << wid*2
    for wid in wwids:
        perm |= 2 << wid*2
    
    msg = WMsg([cfg_addr, perm, 3], [0xFF, 0xFF, 0xF], 2)
    await w_channel.send_msg(msg)


@cocotb.test()
async def test(dut):
    tb = TB(dut)

    aw_channel  = AWChannel(dut)
    w_channel   = WChannel(dut)
    await tb.cycle_reset()
    
    await config_slot_cfg_msg(aw_channel, w_channel, 1, 0x800, 0x100, [1, 3], [1, 3, 5])
    
    await Timer(500, units='ns')
