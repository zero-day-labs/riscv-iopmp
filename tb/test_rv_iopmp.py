import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.clock import Clock
from cocotbext.axi import AxiBus, AxiMaster, AxiRam, AxiSlave, AxiResp

import os
import re
import logging
import random
import copy
from enum import Enum
from bitarray import bitarray
from bitarray.util import int2ba, ba2int

IOPMP_ENTRIES = 32
MEM_DOMAINS   = 4
SIDS          = 4

class PMPMode(Enum):
    OFF   = bitarray("00")
    TOR   = bitarray("01")
    NA4   = bitarray("10")
    NAPOT = bitarray("11")

class PMPAccess(Enum):
    ACCESS_NONE  = bitarray("000")
    ACCESS_READ  = bitarray("001")
    ACCESS_WRITE = bitarray("010")
    ACCESS_EXEC  = bitarray("100")

class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        # connect simulation axi master
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, "in_axi"), dut.clk, dut.rst)

        # connect a simulation axi ram (slave)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, "out_axi"), dut.clk, dut.rst, size=2 ** 16)

        # connect simulation axi master
        self.axi_cfg = AxiMaster(AxiBus.from_prefix(dut, "cfg_axi"), dut.clk, dut.rst)

        cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    async def cycle_reset(self):
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
         
def get_addr_offsets():
    # extract address offset from auto-generated pmp header
    file = os.path.abspath(os.path.join(os.path.abspath(os.path.dirname(__file__)), '../include/rv_iopmp.h'))

    params = dict()
    with open(file, 'r') as file:
        for line in file:
            if re.search(".*_REG_OFFSET", line) != None:
                tmp = line.split(" ")
                params[tmp[1]] = tmp[2]

    return params

# ENTRY Functions

async def set_entry_config(tb, access: bitarray, mode: bitarray, entry_no: int):
    params = get_addr_offsets()

    conf: bitarray = mode + access

    cfg_offset = int(params[f"RV_IOPMP_ENTRY_CFG{entry_no}_REG_OFFSET"], 16)
    await tb.axi_cfg.write(cfg_offset, ba2int(conf).to_bytes(4, byteorder='little'), size=2)

async def set_entry_napot(tb, base: int, length: int, access: bitarray, entry_no: int):
    ''' TODO: ASSERT the lenght and base are power of two'''
    params = get_addr_offsets()
    napot_addr = int2ba(int(base + (length/2 - 1)), 64)

    # config
    if length < 8:
        mode = PMPMode.NA4.value
    else:
        mode = PMPMode.NAPOT.value
    conf: bitarray = mode + access
    tb.log.debug(f"Configuring PMP Entry {entry_no} with:")
    tb.log.debug(f"PMP cfg: {hex(ba2int(conf))}")
    tb.log.debug(f"PMP NAPOT addr: {hex(ba2int(napot_addr))}")

    addr_offset = int(params[f"RV_IOPMP_ENTRY_ADDR{entry_no}_REG_OFFSET"], 16)
    addrh_offset = int(params[f"RV_IOPMP_ENTRY_ADDRH{entry_no}_REG_OFFSET"], 16)
    

    napot_addr_mod = napot_addr >> 2;
    await tb.axi_cfg.write(addr_offset, ba2int(napot_addr_mod[32:]).to_bytes(4, byteorder='little'), size=2)
    await tb.axi_cfg.write(addrh_offset, ba2int(napot_addr_mod[:32]).to_bytes(4, byteorder='little'), size=2)
    await set_entry_config(tb, access, mode, entry_no)

async def set_entry_tor(tb, addr: int, access: bitarray, entry_no: int):
    params = get_addr_offsets()
    addr_mod = int2ba(addr, 64)

    # config
    mode = PMPMode.TOR.value

    conf: bitarray = mode + access
    tb.log.debug(f"Configuring PMP Entry {entry_no} with:")
    tb.log.debug(f"PMP cfg: {hex(ba2int(conf))}")
    tb.log.debug(f"PMP TOR addr: {hex(ba2int(addr_mod))}")

    addr_offset = int(params[f"RV_IOPMP_ENTRY_ADDR{entry_no}_REG_OFFSET"], 16)
    addrh_offset = int(params[f"RV_IOPMP_ENTRY_ADDRH{entry_no}_REG_OFFSET"], 16)
    
    addr_mod = addr_mod >> 2
    await tb.axi_cfg.write(addr_offset, ba2int(addr_mod[32:]).to_bytes(4, byteorder='little'), size=2)
    await tb.axi_cfg.write(addrh_offset, ba2int(addr_mod[:32]).to_bytes(4, byteorder='little'), size=2)
    await set_entry_config(tb, access, mode, entry_no)

async def set_entry_off(tb, addr: int, access: bitarray, entry_no: int):
    params = get_addr_offsets()
    addr_mod = int2ba(addr, 64)

    # config
    mode = PMPMode.OFF.value

    conf: bitarray = mode + access
    tb.log.debug(f"Configuring PMP Entry {entry_no} with:")
    tb.log.debug(f"PMP cfg: {hex(ba2int(conf))}")
    tb.log.debug(f"PMP OFF addr: {hex(ba2int(addr_mod))}")

    addr_offset = int(params[f"RV_IOPMP_ENTRY_ADDR{entry_no}_REG_OFFSET"], 16)
    addrh_offset = int(params[f"RV_IOPMP_ENTRY_ADDRH{entry_no}_REG_OFFSET"], 16)
    
    addr_mod = addr_mod >> 2
    await tb.axi_cfg.write(addr_offset, ba2int(addr_mod[32:]).to_bytes(4, byteorder='little'), size=2)
    await tb.axi_cfg.write(addrh_offset, ba2int(addr_mod[:32]).to_bytes(4, byteorder='little'), size=2)
    await set_entry_config(tb, access, mode, entry_no)

async def read_entry(tb, entry_no: int):
    params = get_addr_offsets()

    # config
    tb.log.debug(f"Reading ENTRY {entry_no}")
    addr_offset = int(params[f"RV_IOPMP_ENTRY_ADDR{entry_no}_REG_OFFSET"], 16)
    addrh_offset = int(params[f"RV_IOPMP_ENTRY_ADDRH{entry_no}_REG_OFFSET"], 16)
    
    resp = await tb.axi_cfg.read(addr_offset, 1, size=2)
    resph = await tb.axi_cfg.read(addrh_offset, 1, size=2)
    return int.from_bytes(resp.data, 'little'), int.from_bytes(resph.data, 'little')

async def clean_entry(tb, entry_no: int):
    tb.log.debug(f"Clearing PMP entry {entry_no}:")
    await set_entry_napot(tb, 0, 4, PMPAccess.ACCESS_NONE.value, entry_no)

async def clean_all_entries(tb, stop_entry: int, start_entry = 0):
    for i in range(start_entry, stop_entry):
        clean_entry(tb, i)
# ----------------------------

# SRCMD
async def set_srcmd_entry(tb, entry_no: int, md_list):
    params = get_addr_offsets()

    md = bitarray(63)
    md.setall(0)
    for element in md_list:  # Set bits of the wanted mds to 1
        md[62 - element] = 1
    
    # config
    lock = bitarray('0')
    en: bitarray = md + lock
    tb.log.debug(f"Configuring SRCMD{entry_no} with:")
    tb.log.debug(f"EN: {hex(ba2int(en))}")

    en_offset = int(params[f"RV_IOPMP_SRCMD_EN{entry_no}_REG_OFFSET"], 16)
    enh_offset = int(params[f"RV_IOPMP_SRCMD_ENH{entry_no}_REG_OFFSET"], 16)
    
    await tb.axi_cfg.write(en_offset, ba2int(en[32:]).to_bytes(4, byteorder='little'), size=2)
    await tb.axi_cfg.write(enh_offset, ba2int(en[:32]).to_bytes(4, byteorder='little'), size=2)
# ----------------------------

# MDCFG
async def set_mdcfg_entry(tb, entry_no: int, t : int):
    params = get_addr_offsets()

    # config
    tb.log.debug(f"Configuring MDCFG{entry_no} with:")
    tb.log.debug(f"t: {hex(t)}")

    t_offset = int(params[f"RV_IOPMP_MDCFG_{entry_no}_REG_OFFSET"], 16)
    
    # await tb.register_interface._write(t_offset, t, 0xF)
    await tb.axi_cfg.write(t_offset, t.to_bytes(4, byteorder='little'), size=2)

async def read_mdcfg_entry(tb, entry_no: int):
    params = get_addr_offsets()

    # config
    tb.log.debug(f"Reading MDCFG{entry_no}")
    t_offset = int(params[f"RV_IOPMP_MDCFG_{entry_no}_REG_OFFSET"], 16)
    
    resp = await tb.axi_cfg.read(t_offset, 1, size=1)
    return resp.data

async def clear_mdcfg_entry(tb, entry_no):
    await set_mdcfg_entry(tb, entry_no, 0)
# ----------------------------

# LCK Registers
async def set_mdcfglck(tb, f:int, lock:bitarray):
    params = get_addr_offsets()

    data = int2ba(f, 7) + lock
    mdcfglck_offset = int(params[f"RV_IOPMP_MDCFGLCK_REG_OFFSET"], 16)
    await tb.axi_cfg.write(mdcfglck_offset, ba2int(data).to_bytes(1, byteorder='little'), size=0)

async def read_mdcfglck(tb):
    params = get_addr_offsets()

    tb.log.debug(f"Reading MDCFGLCK")

    mdcfglck_offset = int(params[f"RV_IOPMP_MDCFGLCK_REG_OFFSET"], 16)
    resp = await tb.axi_cfg.read(mdcfglck_offset, 1, size=0)

    return int.from_bytes(resp.data, 'little') >> 1, int.from_bytes(resp.data, 'little') & 0x1

async def set_entrylck(tb, f:int, lock:bitarray):
    params = get_addr_offsets()

    data = int2ba(f, 16) + lock
    entrylck_offset = int(params[f"RV_IOPMP_ENTRYLCK_REG_OFFSET"], 16)
    await tb.axi_cfg.write(entrylck_offset, ba2int(data).to_bytes(4, byteorder='little'), size=2)

async def read_entrylck(tb):
    params = get_addr_offsets()

    tb.log.debug(f"Reading MDCFGLCK")

    entrylck_offset = int(params[f"RV_IOPMP_ENTRYLCK_REG_OFFSET"], 16)
    resp = await tb.axi_cfg.read(entrylck_offset, 1, size=0)

    return int.from_bytes(resp.data, 'little') >> 1, int.from_bytes(resp.data, 'little') & 0x1
# ----------------------------
async def set_errreact(tb, lock:bitarray, ie:bitarray, ire:bitarray, iwe:bitarray):
    params = get_addr_offsets()

    data = int2ba(0, 23) + iwe + int2ba(0, 3) + ire + int2ba(0, 2) + ie + lock
    errreact_offset = int(params[f"RV_IOPMP_ERRREACT_REG_OFFSET"], 16)
    await tb.axi_cfg.write(errreact_offset, ba2int(data).to_bytes(4, byteorder='little'), size=2)

async def read_errreact(tb):
    params = get_addr_offsets()

    errreact_offset = int(params[f"RV_IOPMP_ERRREACT_REG_OFFSET"], 16)
    resp = await tb.axi_cfg.read(errreact_offset, 1, size=1)
    resp = await tb.axi_cfg.read(errreact_offset, 1, size=1)

    return int.from_bytes(resp.data, 'little') & 0x1, int.from_bytes(resp.data, 'little') >> 1 & 0x1, int.from_bytes(resp.data, 'little') >> 4 & 0x1, int.from_bytes(resp.data, 'little') >> 8 & 0x1

async def enable_iopmp(tb):
    params = get_addr_offsets()

    config = 0x80000000 # Current spec the enable bit is the last bit of the HWCFG0
    # config
    tb.log.debug(f"Enabling IOPMP")

    HCFG0_offset = int(params[f"RV_IOPMP_HWCFG0_REG_OFFSET"], 16)

    # await tb.register_interface._write(HCFG0_offset, ba2int(config), 0xF)
    await tb.axi_cfg.write(HCFG0_offset, config.to_bytes(4, byteorder='little'), size=2)

async def read_err_reqinfo(tb):
    params = get_addr_offsets()
    
    tb.log.debug(f"Reading ERR_REQINFO")
    REQINFO_offset = int(params[f"RV_IOPMP_ERR_REQINFO_REG_OFFSET"], 16)
    info_resp = await tb.axi_cfg.read(REQINFO_offset, 1, size=2)

    data = int.from_bytes(info_resp.data, 'little')

    return data & 0x1, data >> 1 & 0x3, data >> 4 & 0x7 # ip, ttype, etype

async def read_err_reqid(tb):
    params = get_addr_offsets()
    
    tb.log.debug(f"Reading ERR_REQID")
    REQID_offset = int(params[f"RV_IOPMP_ERR_REQID_REG_OFFSET"], 16)
    id_resp = await tb.axi_cfg.read(REQID_offset, 1, size=2)

    data = int.from_bytes(id_resp.data, 'little')

    return data & 0xFFFF, data >> 16 & 0xFFFF  # sid, eid

async def read_err_reqaddr(tb):
    params = get_addr_offsets()
    
    tb.log.debug(f"Reading ERR_REQADDR")
    REQADDR_offset = int(params[f"RV_IOPMP_ERR_REQADDR_REG_OFFSET"], 16)
    addr_resp = await tb.axi_cfg.read(REQADDR_offset, 1, size=2)

    data = int.from_bytes(addr_resp.data, 'little')

    return data

async def read_err_reqaddrh(tb):
    params = get_addr_offsets()
    
    tb.log.debug(f"Reading ERR_REQADDR")
    REQADDRH_offset = int(params[f"RV_IOPMP_ERR_REQADDRH_REG_OFFSET"], 16)
    addr_resp = await tb.axi_cfg.read(REQADDRH_offset, 1, size=2)

    data = int.from_bytes(addr_resp.data, 'little')

    return data

async def clean_error_reg(tb):
    params = get_addr_offsets()

    REQINFO_offset = int(params[f"RV_IOPMP_ERR_REQINFO_REG_OFFSET"], 16)
    await tb.axi_cfg.write(REQINFO_offset, int(1).to_bytes(4, byteorder='little'))

def calculate_axi_lenght_size(num_bytes, data_width):
    # define and extract bus information
    byte_lanes = data_width // 8
    max_size = (byte_lanes - 1).bit_length()
    # Can't read 4k, so read a little less, as we still want to make sure we can read at least within the axi4 boundary
    if num_bytes == 4096: num_bytes - 1

    # Random reading size, never bigger than the width bus, as per AXI spec
    if num_bytes < byte_lanes: size = random.randint(0, 2) 
    else: size = random.randint(0, max_size)

    length = int(num_bytes / (1 << size))

    return length, size

async def error_assessment(tb):
    ip, ttype, etype = await read_err_reqinfo(tb)
    tb.log.info(f"ip: {ip}, ttype: {ttype}, etype: {etype}")
    
    esid, eid = await read_err_reqid(tb)
    tb.log.info(f"esid: {esid}, eid: {eid}")

    addr = await read_err_reqaddr(tb)
    tb.log.info(f"addr: {addr}")

    assert tb.dut.wsi_wire.value == 1, "Error, interrupt not set"
    await clean_error_reg(tb)
    assert tb.dut.wsi_wire.value == 0, "Error, interrupt not cleared"

'''
    Can be used to test multiple entries or single entry with napot mode.
    Configures the entries and then performs a validation on it according to the allow function parameter.
'''
async def napot_entry_test(tb, sid : int, access: bitarray, allow: bool, stop_entry: int, start_entry = 0, special = False):
    # define and extract bus information
    data_width = len(cocotb.top.in_axi_wdata)

    base   = 0x100
    length = 4

    for i in range(start_entry, stop_entry):
        tb.log.debug(f"Testing PMP entry {i}:")
        tb.log.debug(f"Base: {hex(base)}; length: {hex(length)}")

        # The special case, its the transmission failing because of addresses
        if allow or special: await set_entry_napot(tb, base, length, access, i)
        else: await set_entry_off(tb, base, access, i)

        axi_length, size = calculate_axi_lenght_size(length, data_width)

        resp = None
        tb.log.debug(f"AXI length: {axi_length}, Num Bytes: {length}, Size: {(1 << size)}")
        if access == PMPAccess.ACCESS_READ.value:
            resp = await tb.axi_master.read(base, axi_length, size=size, user = sid)
        else:
            test_data = bytearray([x % 256 for x in range(length)])
            resp = await tb.axi_master.write(base, test_data, size=size, user = sid)
        
        # If we expect the system to not allow a transaction, clean error register
        if allow:
            assert resp.resp == AxiResp.OKAY
        else:
            assert resp.resp == AxiResp.SLVERR
            await error_assessment(tb)
            

        # Reset back as its bound violation
        if length >= 2048 : length = 8  
        else: length *= 2
        base *= 2

        await clean_entry(tb, i) # This way, we make sure no other entry interfers

'''
    Can be used to test multiple entries or single entry with tor mode.
    Configures the entries and then performs a validation on it according to the allow function parameter.
'''
async def tor_entry_test(tb, sid : int, access: bitarray, allow: bool, stop_entry: int, start_entry = 1, special = False):
    # define and extract bus information
    data_width = len(cocotb.top.in_axi_wdata)

    base_current = 0x100
    length       = 8

    if(start_entry == 0): start_entry = 1 # Assert the value of start_entry, as the first one is a special case
    for i in range(start_entry, stop_entry):
        base_prev    = base_current - length
        tb.log.debug(f"Testing PMP entry {i}:")
        tb.log.debug(f"Base: {hex(base_current)}; length: {hex(length)}")

        # The special case, its the transmission failing because of addresses
        # Non special is, the entry matches, but transaction is still not allowed per permissions
        if allow or special: 
            await set_entry_off(tb, base_prev, access, i - 1)
            await set_entry_tor(tb, base_current, access, i)
        else: 
            await set_entry_off(tb, base_current, access, i - 1)
            await set_entry_off(tb, base_current, access, i - 1)

        axi_length, size = calculate_axi_lenght_size(length, data_width)

        resp = None
        if access == PMPAccess.ACCESS_READ.value:
            resp = await tb.axi_master.read(base_prev, axi_length, size = size, user = sid)
        else:
            test_data = bytearray([x % 256 for x in range(length)])
            resp = await tb.axi_master.write(base_prev, test_data, size = size, user = sid)
        
        # If we expect the system to not allow a transaction, clean error register
        if allow:
            assert resp.resp == AxiResp.OKAY
        else:
            assert resp.resp == AxiResp.SLVERR
            await error_assessment(tb)

        length += 8  # Dont need napot addresses
        # Reset back as to be safe from bound violations AXI
        base_current *= 2
        if (base_current & 0xfff + length) > 0xfff:
            base_current = 0x100


        await clean_entry(tb, i) # This way, we make sure no other entry interfers
        await clean_entry(tb, i - 1) # This way, we make sure no other entry interfers

async def set_random_mds(tb):
    md_entries_list = []
    t = random.randint(1, 4)
    for i in range(MEM_DOMAINS - 1):
        await set_mdcfg_entry(tb, i, t)
        md_entries_list.append(t)
        step = random.randint(1, 4)
        t += step
    
    # Configure last md, with missing entries
    await set_mdcfg_entry(tb, MEM_DOMAINS - 1, IOPMP_ENTRIES)
    md_entries_list.append(IOPMP_ENTRIES)

    return md_entries_list

async def set_random_sids(tb):
    sid_md_list = []

    for i in range(SIDS):
        md_list = []
        for _ in range(random.randint(1, MEM_DOMAINS-2)):
            md_list.append(random.randint(0, MEM_DOMAINS -1))
        
        md_list = list(set(md_list)) # Remove repeated entries
        await set_srcmd_entry(tb, i, md_list)
        sid_md_list.append(copy.deepcopy(md_list))
    
    return sid_md_list

@cocotb.test()
async def locking_test(dut):
    tb = TB(dut)
    tb.log.info(f"Test Locking features")
    await tb.cycle_reset()

    # MDCFGLCK TESTS ------------------------------------------------------------
    # Gradually lock the MDS, and test their correct locking
    for i in range(MEM_DOMAINS):
        await set_mdcfglck(tb, i + 1, int2ba(0))
        await set_mdcfg_entry(tb, i, i+1)          # Write a value to t
        data = await read_mdcfg_entry(tb, i)

        assert int.from_bytes(data, 'little') == 0 # If successful locking, the entries should not contain any values
    
    await tb.cycle_reset() # Reset for final locking tests

    await set_mdcfglck(tb, 2, int2ba(0))                               # Set random number into mdcfglck
    initial, _ = await read_mdcfglck(tb)                                # Read the actual result
    assert initial == 2                                                 # Just make sure it wrote the right thing (don't forget the lock bit)

    await set_mdcfglck(tb, initial - 1, int2ba(0))                       # Try writing a smaller value, should not allow
    current, _ = await read_mdcfglck(tb)
    assert initial == current                                            # the value should be equal

    await set_mdcfglck(tb, initial, int2ba(1))      # Lock mdcfglck
    await set_mdcfglck(tb, MEM_DOMAINS, int2ba(0)) # Try writing a "valid" value, should not allow
    _, lock = await read_mdcfglck(tb)
    assert lock == 1           
    

    await set_mdcfglck(tb, initial, int2ba(0))                          # Try clearing the lock 
    _, lock = await read_mdcfglck(tb)
    assert lock == 1                                                   # Once locked, never unlocked
    await set_mdcfglck(tb, initial, int2ba(1))                          # Try setting (can have W1C behaviour) the lock
    _, lock = await read_mdcfglck(tb)
    assert lock == 1                                                   # Once locked, never unlocked
    # ---------------------------------------------------------------------------

    # ENTRYLCK TESTS ------------------------------------------------------------
    # ---------------------------------------------------------------------------
    # Gradually lock the Entries, and test their correct locking
    for i in range(IOPMP_ENTRIES):
        await set_entrylck(tb, i + 1, int2ba(0))
        await set_entry_tor(tb, 0xFFFF105A45, PMPAccess.ACCESS_READ.value, i)   # Write a value to entry
        data, datah = await read_entry(tb, i)

        assert data  == 0 # If successful locking, the entries should not contain any values
        assert datah == 0 # If successful locking, the entries should not contain any values
    
    await tb.cycle_reset() # Reset for final locking tests

    await set_entrylck(tb, 2, int2ba(0))                               # Set random number into entrylck
    initial, _ = await read_entrylck(tb)                                # Read the actual result
    assert initial == 2                                                 # Just make sure it wrote the right thing (don't forget the lock bit)

    await set_entrylck(tb, initial - 1, int2ba(0))                       # Try writing a smaller value, should not allow
    current, _ = await read_entrylck(tb)
    assert initial == current                                            # the value should be equal

    await set_entrylck(tb, initial, int2ba(1))      # Lock mdcfglck
    await set_entrylck(tb, MEM_DOMAINS, int2ba(0)) # Try writing a "valid" value, should not allow
    current, _ = await read_entrylck(tb)
    assert current == initial           
    

    await set_entrylck(tb, initial, int2ba(0))                          # Try clearing the lock 
    _, lock = await read_entrylck(tb)
    assert lock == 1                                                   # Once locked, never unlocked
    await set_entrylck(tb, initial, int2ba(1))                          # Try setting (can have W1C behaviour) the lock
    _, lock = await read_entrylck(tb)
    assert lock == 1                                                   # Once locked, never unlocked

    # ERRREACT locking
    # lock, ie, ire, iwe
    # await set_errreact(tb, int2ba(1), int2ba(1), int2ba(1), int2ba(1))
    # lock, ie, ire, iwe = await read_errreact(tb)
    # await set_errreact(tb, int2ba(0), int2ba(0), int2ba(0), int2ba(0))
    # lock, ie, ire, iwe = await read_errreact(tb)

    # tb.log.info(f"{lock}, {ie}, {ire}, {iwe}")
    # assert lock == ie == ire == iwe == 1 

@cocotb.test()
async def tor_test_multiple_sids_same_mds(dut):
    tb = TB(dut)
    tb.log.info(f"TOR - Test Parameters: {SIDS} sources with the same mds, {MEM_DOMAINS} mds with random t values, {IOPMP_ENTRIES} entries with varying lengths, base addresses, and access types")
    await tb.cycle_reset()
    
    await set_errreact(tb, int2ba(0), int2ba(1), int2ba(1), int2ba(1))
    # Configure MDs
    await set_random_mds(tb)
    for i in range(SIDS):
        await set_srcmd_entry(tb, i, [x for x in range(MEM_DOMAINS)])
    await enable_iopmp(tb)

    # Loop SIDs
    for i in range(SIDS):  
        # Test reading
        await tor_entry_test(tb, i, PMPAccess.ACCESS_READ.value, True,  IOPMP_ENTRIES) # Allow, no need to test all of the entries
        await tor_entry_test(tb, i, PMPAccess.ACCESS_READ.value, False, IOPMP_ENTRIES) # Block, no need to test all of the entries

        # Test writing
        await tor_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, True,  IOPMP_ENTRIES) # Allow, no need to test all of the entries
        await tor_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, False, IOPMP_ENTRIES) # Block, no need to test all of the entries

@cocotb.test()
async def tor_test_multiple_sids(dut):
    tb = TB(dut)
    tb.log.info(f"TOR - Test Parameters: {SIDS} sources with random mds, {MEM_DOMAINS} mds with random t values, {IOPMP_ENTRIES} entries with varying lengths base addresses and access types")
    await tb.cycle_reset()
    
    await set_errreact(tb, int2ba(0), int2ba(1), int2ba(1), int2ba(1))
    # Configure MDs
    md_entries_list = await set_random_mds(tb)
    sid_md_list = await set_random_sids(tb)
    await enable_iopmp(tb)

    for i in range(SIDS):  # SIDs with different MDs
        # Test reading
        tb.log.info(f"Testing the MDs belonging to SID {i}")
        await FallingEdge(dut.clk)
        
        for element in sid_md_list[i]:
            if element == 0: # MD 0 has from 0 to t
                await tor_entry_test(tb, i, PMPAccess.ACCESS_READ.value, True,  0, md_entries_list[element])  # Allow
                await tor_entry_test(tb, i, PMPAccess.ACCESS_READ.value, False,  0, md_entries_list[element]) # Block
            else: # MD x has from x - 1 to x
                await tor_entry_test(tb, i, PMPAccess.ACCESS_READ.value, True, md_entries_list[element], md_entries_list[element - 1]) # Allow
                await tor_entry_test(tb, i, PMPAccess.ACCESS_READ.value, False, md_entries_list[element], md_entries_list[element - 1]) # Block

        # Test writing
        for element in sid_md_list[i]:
            if element == 0: # MD 0 has from 0 to t
                await tor_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, True,  0, md_entries_list[element]) # Allow
                await tor_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, False,  0, md_entries_list[element]) # Block
            else: # MD x has from x - 1 to x
                await tor_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, True, md_entries_list[element], md_entries_list[element - 1]) # Allow
                await tor_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, False, md_entries_list[element], md_entries_list[element - 1]) # Block

        # Test entries from another SID
        tb.log.info(f"Testing MDs from other SIDs")
        for md in range(1, MEM_DOMAINS): # To not be concerned with the entry 0's special case
            if md not in sid_md_list[i]:
                tb.log.info(f"Testing MD {md} - Entries from {md_entries_list[md - 1]} to {md_entries_list[md]}")
                await tor_entry_test(tb, i, PMPAccess.ACCESS_READ.value, False, md_entries_list[md], md_entries_list[md - 1], True)  # Block
                await tor_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, False, md_entries_list[md], md_entries_list[md - 1], True) # Block

# Mds can belong to different SIDs, test this
@cocotb.test()
async def napot_test_multiple_sids_same_mds(dut):
    tb = TB(dut)
    tb.log.info(f"NAPOT - Test Parameters: {SIDS} sources with the same mds, {MEM_DOMAINS} mds with random t values, {IOPMP_ENTRIES} entries with varying lengths, base addresses, and access types")
    await tb.cycle_reset()
    
    await set_errreact(tb, int2ba(0), int2ba(1), int2ba(1), int2ba(1))
    # Configure MDs
    await set_random_mds(tb)
    for i in range(SIDS):
        await set_srcmd_entry(tb, i, [x for x in range(MEM_DOMAINS)])
    await enable_iopmp(tb)

    # Loop SIDs
    for i in range(SIDS):  
        # Test reading
        await napot_entry_test(tb, i, PMPAccess.ACCESS_READ.value, True,  IOPMP_ENTRIES) # Allow, no need to test all of the entries
        await napot_entry_test(tb, i, PMPAccess.ACCESS_READ.value, False, IOPMP_ENTRIES) # Block, no need to test all of the entries

        # Test writing
        await napot_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, True,  IOPMP_ENTRIES) # Allow, no need to test all of the entries
        await napot_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, False, IOPMP_ENTRIES) # Block, no need to test all of the entries

@cocotb.test()
async def napot_test_multiple_sids(dut):
    tb = TB(dut)
    tb.log.info(f"NAPOT - Test Parameters: {SIDS} sources with random mds, {MEM_DOMAINS} mds with random t values, {IOPMP_ENTRIES} entries with varying lengths base addresses and access types")
    await tb.cycle_reset()
    
    await set_errreact(tb, int2ba(0), int2ba(1), int2ba(1), int2ba(1))
    # Configure MDs
    md_entries_list = await set_random_mds(tb)
    sid_md_list = await set_random_sids(tb)
    await enable_iopmp(tb)

    for i in range(SIDS):  # SIDs with different MDs
        # Test reading
        tb.log.info(f"Testing the MDs belonging to SID {i}")
        await FallingEdge(dut.clk)
        
        for element in sid_md_list[i]:
            if element == 0: # MD 0 has from 0 to t
                await napot_entry_test(tb, i, PMPAccess.ACCESS_READ.value, True,  0, md_entries_list[element])  # Allow
                await napot_entry_test(tb, i, PMPAccess.ACCESS_READ.value, False,  0, md_entries_list[element]) # Block
            else: # MD x has from x - 1 to x
                await napot_entry_test(tb, i, PMPAccess.ACCESS_READ.value, True, md_entries_list[element], md_entries_list[element - 1]) # Allow
                await napot_entry_test(tb, i, PMPAccess.ACCESS_READ.value, False, md_entries_list[element], md_entries_list[element - 1]) # Block

        # Test writing
        for element in sid_md_list[i]:
            if element == 0: # MD 0 has from 0 to t
                await napot_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, True,  0, md_entries_list[element]) # Allow
                await napot_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, False,  0, md_entries_list[element]) # Block
            else: # MD x has from x - 1 to x
                await napot_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, True, md_entries_list[element], md_entries_list[element - 1]) # Allow
                await napot_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, False, md_entries_list[element], md_entries_list[element - 1]) # Block

        # Test entries from another SID
        tb.log.info(f"Testing MDs from other SIDs")
        for md in range(1, MEM_DOMAINS): # To not be concerned with the entry 0's special case
            if md not in sid_md_list[i]:
                tb.log.info(f"Testing MD {md} - Entries from {md_entries_list[md - 1]} to {md_entries_list[md]}")
                await napot_entry_test(tb, i, PMPAccess.ACCESS_READ.value, False, md_entries_list[md], md_entries_list[md - 1], True)  # Block
                await napot_entry_test(tb, i, PMPAccess.ACCESS_WRITE.value, False, md_entries_list[md], md_entries_list[md - 1], True) # Block
