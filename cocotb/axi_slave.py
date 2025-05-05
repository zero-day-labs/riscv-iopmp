import cocotb
from cocotb.triggers import RisingEdge
from collections import deque, namedtuple


RMsg  = namedtuple('RMsg', ['data', 'resp', 'len', 'id'])

class Slave:
    def __init__(self, dut, prefix, clk, log):
        self.dut = dut
        self.clk = clk
        self.prefix = prefix
        self.log = log

        self.ar_channel = ARChannel(dut, prefix, clk, log)
        self.aw_channel = AWChannel(dut, prefix, clk, log)
        self.w_channel  = WChannel(dut, prefix, clk, log)
        self.r_channel  = RChannel(dut, prefix, clk, log)
        self.b_channel  = BChannel(dut, prefix, clk, log)
    
    async def init(self):
        await cocotb.start(self.aw_channel.rscv_msg())
        await cocotb.start(self.ar_channel.rscv_msg())
        await cocotb.start(self.w_channel.rscv_msg())
        await cocotb.start(self.b_channel_ctrl())
        await cocotb.start(self.r_channel_ctrl())

    async def r_channel_ctrl(self):
        while 1:
            if self.ar_channel.queue:
                info = self.ar_channel.queue.popleft()
                msg = RMsg([0], [0], info[0], info[1])
                await self.r_channel.send_msg(msg)
            else:
                await RisingEdge(self.clk)
            
    async def b_channel_ctrl(self):
        while 1:
            if self.w_channel.queue:
                self.w_channel.queue.popleft()
                id = self.aw_channel.queue.popleft()
                await self.b_channel.send_msg(id)
            else:
                await RisingEdge(self.clk)
                


class AWChannel:
    def __init__(self, dut, prefix, clk, log):
        self.dut = dut
        self.clk = clk
        self.queue = deque()
        self.queue.clear()
        self.log = log
        
        prefix = f"{prefix}_aw"
        self.prefix = prefix

        self.valid = getattr(dut, f"{prefix}_valid_o")  # Sets self.valid = dut.entry_valid
        self.addr  = getattr(dut, f"{prefix}_addr_o")
        self.len   = getattr(dut, f"{prefix}_len_o")
        self.size  = getattr(dut, f"{prefix}_size_o")
        self.id    = getattr(dut, f"{prefix}_id_o")

        self.ready = getattr(dut, f"{prefix}_ready_i")

    async def wait_valid(self):
        await RisingEdge(self.clk)

        while self.valid.value == 0:
            await RisingEdge(self.clk)

    async def rscv_msg(self):
        while 1:
            await self.wait_valid()

            self.ready.value = 1
            if self.log:
                print(f"Receiving trans {self.prefix} Channel: addr - {hex(int(self.addr.value))}, len - {int(self.len.value)}, id - {int(self.id.value)}")
            self.queue.append(self.id.value)

            await RisingEdge(self.clk)
            self.ready.value = 0

class ARChannel:
    def __init__(self, dut, prefix, clk, log):
        self.dut = dut
        self.clk = clk
        self.queue = deque()
        self.queue.clear()
        self.log = log
        
        prefix = f"{prefix}_ar"
        self.prefix = prefix

        self.valid = getattr(dut, f"{prefix}_valid_o")  # Sets self.valid = dut.entry_valid
        self.addr  = getattr(dut, f"{prefix}_addr_o")
        self.len   = getattr(dut, f"{prefix}_len_o")
        self.size  = getattr(dut, f"{prefix}_size_o")
        self.id    = getattr(dut, f"{prefix}_id_o")

        self.ready = getattr(dut, f"{prefix}_ready_i")

    async def wait_valid(self):
        await RisingEdge(self.clk)

        while self.valid.value == 0:
            await RisingEdge(self.clk)

    async def rscv_msg(self):
        while 1:
            await self.wait_valid()

            self.ready.value = 1
            if self.log:
                print(f"Receiving trans {self.prefix} Channel: addr - {hex(int(self.addr.value))}, len - {int(self.len.value)}, id - {int(self.id.value)}")
            self.queue.append([self.len.value, self.id.value])
            
            await RisingEdge(self.clk)
            self.ready.value = 0

class WChannel:
    def __init__(self, dut, prefix, clk, log):
        self.dut = dut
        self.clk = clk
        self.prefix = prefix
        self.queue = deque()
        self.queue.clear()
        self.log = log
        
        self.valid          = getattr(dut, f"{prefix}_w_valid_o")
        self.ready          = getattr(dut, f"{prefix}_w_ready_i")
        self.strb           = getattr(dut, f"{prefix}_w_strb_o")
        self.last           = getattr(dut, f"{prefix}_w_last_o")
        self.data           = getattr(dut, f"{prefix}_w_data_o")

    async def wait_valid(self):
        await RisingEdge(self.clk)

        while self.valid.value == 0:
            await RisingEdge(self.clk)

    async def rscv_msg(self):
        self.ready.value = 1
        
        while 1:
            await self.wait_valid()
            
            if self.log:
                print(f"Receiving data {self.prefix} WChannel: data - {int(self.data.value)}, strb - {self.strb.value}, last - {self.last.value}")
            if self.last.value == 1:
                self.queue.append(True)

class RChannel:
    def __init__(self, dut, prefix, clk, log):
        self.dut = dut
        self.clk = clk
        self.prefix = prefix
        self.log = log
        
        self.valid          = getattr(dut, f"{prefix}_r_valid_i")
        self.ready          = getattr(dut, f"{prefix}_r_ready_o")
        self.resp           = getattr(dut, f"{prefix}_r_resp_i")
        self.last           = getattr(dut, f"{prefix}_r_last_i")
        self.data           = getattr(dut, f"{prefix}_r_data_i")
        self.id             = getattr(dut, f"{prefix}_r_id_i")

    async def wait_ready(self):
        await RisingEdge(self.clk)

        while self.ready.value == 0:
            await RisingEdge(self.clk)

    async def send_msg(self, msg):
        await RisingEdge(self.clk)

        for i in range(msg.len + 1):
            self.valid.value = 1
            self.data.value  = 7 # msg.data[i]
            self.resp.value  = 0 # msg.resp[i]
            self.id.value    = msg.id

            if self.log:
                print(f"Sending data {self.prefix} RChannel: data - {int(self.data.value)}, resp - {self.resp.value}, last - {self.last.value}, id - {int(self.id.value)}")

            if i == msg.len:
                self.last.value = 1
            else:
                self.last.value = 0

            await self.wait_ready()

        self.valid.value = 0

class BChannel:
    def __init__(self, dut, prefix, clk, log):
        self.dut = dut
        self.clk = clk
        self.prefix = prefix
        self.log = log
        
        self.valid          = getattr(dut, f"{prefix}_b_valid_i")
        self.ready          = getattr(dut, f"{prefix}_b_ready_o")
        self.resp           = getattr(dut, f"{prefix}_b_resp_i")
        self.id             = getattr(dut, f"{prefix}_b_id_i")

    async def wait_ready(self):
        await RisingEdge(self.clk)

        while self.ready.value == 0:
            await RisingEdge(self.clk)

    async def send_msg(self, id):
        await RisingEdge(self.clk)

        self.valid.value = 1
        self.resp.value = 0
        self.id.value = id

        if self.log:
            print(f"Sending data {self.prefix} BChannel: resp - {self.resp.value}, id - {int(self.id.value)}")

        await self.wait_ready()
        self.valid.value = 0