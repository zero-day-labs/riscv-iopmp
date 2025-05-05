import cocotb
from cocotb.triggers import RisingEdge
from collections import deque, namedtuple

# class Master:
#     def __init__(self, dut, valid, ready, addr, len, size):

AxMsg = namedtuple('AxMsg', ['addr', 'len', 'size', 'id'])
WMsg  = namedtuple('WMsg', ['data', 'strb', 'len'])
# BMsg  = namedtuple('BMsg', ['resp', 'id'])

class Master:
    def __init__(self, dut, prefix, clk, log):
        self.dut = dut
        self.clk = clk
        self.prefix = prefix
        self.log = log

        self.ar_channel = AxChannel(dut, prefix, clk, log, 0)
        self.aw_channel = AxChannel(dut, prefix, clk, log, 1)
        self.w_channel  = WChannel(dut, prefix, clk, log)
        self.r_channel  = RChannel(dut, prefix, clk, log)
        self.b_channel  = BChannel(dut, prefix, clk, log)

    async def init(self):
        await cocotb.start(self.b_channel.rscv_msg())
        await cocotb.start(self.r_channel.rscv_msg())
        await cocotb.start(self.w_channel.send_msg())
        await cocotb.start(self.aw_channel.start_trans())
        await cocotb.start(self.ar_channel.start_trans())

    async def write(self, attr, data):
        self.aw_channel.queue.append(attr)
        await RisingEdge(self.clk)
        self.w_channel.queue.append(data)
    
    async def read(self, attr):
        self.ar_channel.queue.append(attr)


class AxChannel:
    def __init__(self, dut, prefix, clk, log, rw = 0):
        self.dut = dut
        self.clk = clk
        self.queue = deque()
        self.queue.clear()
        self.log = log

        prefix = f"{prefix}_ar" if rw == 0 else f"{prefix}_aw"
        self.prefix = prefix

        self.valid = getattr(dut, f"{prefix}_valid_i")  # Sets self.valid = dut.entry_valid
        self.addr  = getattr(dut, f"{prefix}_addr_i")
        self.len   = getattr(dut, f"{prefix}_len_i")
        self.size  = getattr(dut, f"{prefix}_size_i")
        self.id    = getattr(dut, f"{prefix}_id_i")

        self.ready = getattr(dut, f"{prefix}_ready_o")

    async def wait_ready(self):
        await RisingEdge(self.clk)

        while self.ready.value == 0:
            await RisingEdge(self.clk)

    async def start_trans(self):
        if self.queue:
                msg = self.queue.popleft()

        while 1:
            if self.queue:
                msg = self.queue.popleft()

                self.valid.value = 1
                self.addr.value = msg.addr
                self.len.value  = msg.len
                self.size.value = msg.size
                self.id.value   = msg.id

                if self.log:
                    print(f"[{self.prefix} Channel] Starting transaction in: addr - {hex(int(self.addr.value))}, len - {int(self.len.value)}, size - {int(self.size.value)}, id - {int(self.id.value)}")
                
                await self.wait_ready()
                self.valid.value = 0

            else:
                await RisingEdge(self.clk)

class WChannel:
    def __init__(self, dut, prefix, clk, log):
        self.dut = dut
        self.clk = clk
        self.prefix = prefix
        self.queue = deque()
        self.queue.clear()
        self.log = log
        
        self.valid          = getattr(dut, f"{prefix}_w_valid_i")
        self.ready          = getattr(dut, f"{prefix}_w_ready_o")
        self.strb           = getattr(dut, f"{prefix}_w_strb_i")
        self.last           = getattr(dut, f"{prefix}_w_last_i")
        self.data           = getattr(dut, f"{prefix}_w_data_i")

    async def wait_ready(self):
        await RisingEdge(self.clk)

        while self.ready.value == 0:
            await RisingEdge(self.clk)

    async def send_msg(self):
        if self.queue:
                msg = self.queue.popleft()
        while 1:
            if self.queue:
                msg = self.queue.popleft()

                for i in range(msg.len + 1):
                    self.valid.value = 1
                    self.data.value = msg.data[i]
                    self.strb.value = msg.strb[i]

                    if self.log:
                        print(f"[WChannel] Sending data {self.prefix}: data - {int(self.data.value)}, strb - {int(self.strb.value)}, last - {self.last.value}")

                    if i == msg.len:
                        self.last.value = 1
                    else:
                        self.last.value = 0

                    await self.wait_ready()

                self.valid.value = 0
            else:
                await RisingEdge(self.clk)


class RChannel:
    def __init__(self, dut, prefix, clk, log):
        self.dut = dut
        self.clk = clk
        self.prefix = prefix
        self.log = log
        
        self.valid          = getattr(dut, f"{prefix}_r_valid_o")
        self.ready          = getattr(dut, f"{prefix}_r_ready_i")
        self.resp           = getattr(dut, f"{prefix}_r_resp_o")
        self.last           = getattr(dut, f"{prefix}_r_last_o")
        self.data           = getattr(dut, f"{prefix}_r_data_o")
        self.id             = getattr(dut, f"{prefix}_r_id_o")

    async def wait_valid(self):
        await RisingEdge(self.clk)

        while self.valid.value == 0:
            await RisingEdge(self.clk)

    async def rscv_msg(self):
        while 1:
            await self.wait_valid()
            self.ready.value = 1

            if self.log:
                print(f"[RChannel] Receiving data {self.prefix}: data - {int(self.data.value)}, resp - {self.resp.value}, last - {self.last.value}, id - {int(self.id.value)}")
            
            await RisingEdge(self.clk)
            self.ready.value = 0

class BChannel:
    def __init__(self, dut, prefix, clk, log):
        self.dut = dut
        self.clk = clk
        self.prefix = prefix
        self.log = log
        
        self.valid          = getattr(dut, f"{prefix}_b_valid_o")
        self.ready          = getattr(dut, f"{prefix}_b_ready_i")
        self.resp           = getattr(dut, f"{prefix}_b_resp_o")
        self.id             = getattr(dut, f"{prefix}_b_id_o")

    async def wait_valid(self):
        await RisingEdge(self.clk)

        while self.valid.value == 0:
            await RisingEdge(self.clk)

    async def rscv_msg(self):
        while 1:
            await self.wait_valid()

            self.ready.value = 1
            if self.log:
                print(f"[BChannel] Receiving response {self.prefix}: id - {int(self.id.value)}, resp - {self.resp.value}")
            
            await RisingEdge(self.clk)
            self.ready.value = 0