import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.clock import Clock
import random
import axi_master
import axi_slave

from collections import deque, namedtuple

import os
import re
import logging
import random
from enum import Enum

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

async def config_entry_msg(master, entry, addr, len, r=0, w=0, x=0):
    entry_base_addr = (entry * 16) + 0x2000
    
    cfg_addr = (addr >> 2) + (len >> 3) - 1
    
    # Start trans
    cfg = (0x3 << 3) | (x << 2) | (w << 1) | r;
    attr = axi_master.AxMsg(entry_base_addr, 1, 3, 0)
    msg = axi_master.WMsg([cfg_addr, cfg], [0xFF, 0xF], 1)

    await master.write(attr, msg)

async def config_mdcfg_msg(master, entry, t, t2):
    md_base_addr = (entry * 4) + 0x800
    
    # Start trans
    attr = axi_master.AxMsg(md_base_addr, 0, 3, 0)
    msg = axi_master.WMsg([t | t2 << 32], [0xFF], 0)

    await master.write(attr, msg)

async def config_srcmd_msg(master, entry, mds):
    srcmd_base_addr = (entry * 32) + 0x1000
    data = 0
    # Start trans
    for md in mds:
        data |= 1 << md

    data = data << 1;
    attr = axi_master.AxMsg(srcmd_base_addr, 0, 3, 0)
    msg = axi_master.WMsg([data], [0xFF], 0)

    await master.write(attr, msg)

@cocotb.test()
async def test(dut):
    tb = TB(dut)

    config_intf = axi_master.Master(dut, "config", dut.clk_i, False)
    slv_intf    = axi_master.Master(dut, "slv", dut.clk_i, True)
    mst_intf    = axi_slave.Slave(dut, "mst", dut.clk_i, False)

    await tb.cycle_reset()
    await config_intf.init()
    await mst_intf.init()
    await slv_intf.init()
    
    await config_entry_msg(config_intf, 13, 0x800, 0x100, 1, 1, 1)
    await config_mdcfg_msg(config_intf, 0, 3, 9)
    await config_mdcfg_msg(config_intf, 2, 16, 0)
    await config_srcmd_msg(config_intf, 3, [0, 1])

    for _ in range(20):
        await RisingEdge(dut.clk_i)

    dut.slv_aw_wid_i.value = 3;
    # attr = axi_master.AxMsg(0x8F8, 2, 3, 1)
    # msg = axi_master.WMsg([2, 6, 9], [0xFF, 0xFF, 0xFF], 2)
    # # await cocotb.start(slv_intf.write(attr, msg))
    # await slv_intf.write(attr, msg)

    attr = axi_master.AxMsg(0x800, 2, 3, 2)
    msg  = axi_master.WMsg([2, 6, 9], [0xFF, 0xFF, 0xFF], 2)
    await slv_intf.write(attr, msg)

    # attr = axi_master.AxMsg(0x800, 2, 3, 3)
    # await slv_intf.read(attr)

    # attr = axi_master.AxMsg(0x1000, 2, 3, 4)
    # msg  = axi_master.WMsg([2, 6, 9], [0xFF, 0xFF, 0xFF], 2)
    # await slv_intf.write(attr, msg)
    
    await RisingEdge(dut.clk_i)
    # dut.slv_ar_wid_i.value = 3;
    # attr = axi_master.AxMsg(0x800, 2, 3, 5)
    # await slv_intf.read(attr)

    await Timer(500, units='ns')
