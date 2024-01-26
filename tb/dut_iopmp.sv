`include "typedef_global.svh"
import rv_iopmp_reg_pkg::*;
import rv_iopmp_pkg::*;


module dut_iopmp #( 
    // width of data bus in bits
    parameter int unsigned DATA_WIDTH     = 64,
    // width of address bus in bits
    parameter int unsigned ADDR_WIDTH     = 64,
    // width of strobe (width of data bus in words)
    parameter int unsigned STRB_WIDTH     = (DATA_WIDTH / 8),
    // width of awuser signal
    parameter int unsigned USER_WIDTH     = 3,
    // width of id signal
    parameter int unsigned ID_WIDTH       = 8,
    // propagate awuser signal
    parameter int unsigned AWUSER_ENABLE  = 0,
    // width of awuser signal
    parameter int unsigned AWUSER_WIDTH   = USER_WIDTH,
    // propagate wuser signal
    parameter int unsigned WUSER_ENABLE   = 0,
    // width of wuser signal
    parameter int unsigned WUSER_WIDTH    = USER_WIDTH,
    // propagate buser signal
    parameter int unsigned BUSER_ENABLE   = 0,
    // width of buser signal
    parameter int unsigned BUSER_WIDTH    = USER_WIDTH,
    // propagate aruser signal
    parameter int unsigned ARUSER_ENABLE  = 0,
    // width of aruser signal
    parameter int unsigned ARUSER_WIDTH   = USER_WIDTH,
    // propagate ruser signal
    parameter int unsigned RUSER_ENABLE   = 0,
    // width of ruser signal
    parameter int unsigned RUSER_WIDTH    = USER_WIDTH,

    // width of id signal
    parameter int unsigned REG_ADDR_WIDTH       = 14,
    // width of id signal
    parameter int unsigned REG_DATA_WIDTH       = 32,
    // width of id signal
    parameter int unsigned REG_STRB_WIDTH       = (REG_DATA_WIDTH / 8),

    // Implementation specific parameters
    parameter int unsigned NUMBER_MDS     = 4,
    parameter int unsigned NUMBER_ENTRIES = 32,
    parameter int unsigned NUMBER_MASTERS = 4,
    parameter int unsigned NUMBER_TL_INSTANCES = 1
) (
    input  logic                      clk,
    input  logic                      rst,

    //
    // AXI master interface
    //
    // Write address channel
    output logic [      ID_WIDTH-1:0] out_axi_awid,
    output logic [    ADDR_WIDTH-1:0] out_axi_awaddr,
    output logic [               7:0] out_axi_awlen,
    output logic [               2:0] out_axi_awsize,
    output logic [               1:0] out_axi_awburst,
    output logic                      out_axi_awlock,
    output logic [               3:0] out_axi_awcache,
    output logic [               2:0] out_axi_awprot,
    output logic [               3:0] out_axi_awqos,
    output logic [               3:0] out_axi_awregion,
    output logic [  AWUSER_WIDTH-1:0] out_axi_awuser,
    output logic                      out_axi_awvalid,
    input  logic                      out_axi_awready,
    // Write data channel
    output logic [    DATA_WIDTH-1:0] out_axi_wdata,
    output logic [    STRB_WIDTH-1:0] out_axi_wstrb,
    output logic                      out_axi_wlast,
    output logic [   WUSER_WIDTH-1:0] out_axi_wuser,
    output logic                      out_axi_wvalid,
    input  logic                      out_axi_wready,
    // Write response channel
    input  logic [      ID_WIDTH-1:0] out_axi_bid,
    input  logic [               1:0] out_axi_bresp,
    input  logic [   BUSER_WIDTH-1:0] out_axi_buser,
    input  logic                      out_axi_bvalid,
    output logic                      out_axi_bready,
    // Read address channel
    output logic [      ID_WIDTH-1:0] out_axi_arid,
    output logic [    ADDR_WIDTH-1:0] out_axi_araddr,
    output logic [               7:0] out_axi_arlen,
    output logic [               2:0] out_axi_arsize,
    output logic [               1:0] out_axi_arburst,
    output logic                      out_axi_arlock,
    output logic [               3:0] out_axi_arcache,
    output logic [               2:0] out_axi_arprot,
    output logic [               3:0] out_axi_arqos,
    output logic [               3:0] out_axi_arregion,
    output logic [  ARUSER_WIDTH-1:0] out_axi_aruser,
    output logic                      out_axi_arvalid,
    input  logic                      out_axi_arready,
    // Read data channel
    input  logic [      ID_WIDTH-1:0] out_axi_rid,
    input  logic [    DATA_WIDTH-1:0] out_axi_rdata,
    input  logic [               1:0] out_axi_rresp,
    input  logic                      out_axi_rlast,
    input  logic [   RUSER_WIDTH-1:0] out_axi_ruser,
    input  logic                      out_axi_rvalid,
    output logic                      out_axi_rready,

    //
    // AXI slave interface
    //
    // Write address channel
    input  logic [      ID_WIDTH-1:0] in_axi_awid,
    input  logic [    ADDR_WIDTH-1:0] in_axi_awaddr,
    input  logic [               7:0] in_axi_awlen,
    input  logic [               2:0] in_axi_awsize,
    input  logic [               1:0] in_axi_awburst,
    input  logic                      in_axi_awlock,
    input  logic [               3:0] in_axi_awcache,
    input  logic [               2:0] in_axi_awprot,
    input  logic [               3:0] in_axi_awqos,
    input  logic [               3:0] in_axi_awregion,
    input  logic [  AWUSER_WIDTH-1:0] in_axi_awuser,
    input  logic                      in_axi_awvalid,
    output logic                      in_axi_awready,
    // Write data channel
    input  logic [    DATA_WIDTH-1:0] in_axi_wdata,
    input  logic [    STRB_WIDTH-1:0] in_axi_wstrb,
    input  logic                      in_axi_wlast,
    input  logic [   WUSER_WIDTH-1:0] in_axi_wuser,
    input  logic                      in_axi_wvalid,
    output logic                      in_axi_wready,
    // Write response channel
    output logic [      ID_WIDTH-1:0] in_axi_bid,
    output logic [               1:0] in_axi_bresp,
    output logic [   BUSER_WIDTH-1:0] in_axi_buser,
    output logic                      in_axi_bvalid,
    input  logic                      in_axi_bready,
    // Read address channel
    input  logic [      ID_WIDTH-1:0] in_axi_arid,
    input  logic [    ADDR_WIDTH-1:0] in_axi_araddr,
    input  logic [               7:0] in_axi_arlen,
    input  logic [               2:0] in_axi_arsize,
    input  logic [               1:0] in_axi_arburst,
    input  logic                      in_axi_arlock,
    input  logic [               3:0] in_axi_arcache,
    input  logic [               2:0] in_axi_arprot,
    input  logic [               3:0] in_axi_arqos,
    input  logic [               3:0] in_axi_arregion,
    input  logic [  ARUSER_WIDTH-1:0] in_axi_aruser,
    input  logic                      in_axi_arvalid,
    output logic                      in_axi_arready,
    // Read data channel
    output logic [      ID_WIDTH-1:0] in_axi_rid,
    output logic [    DATA_WIDTH-1:0] in_axi_rdata,
    output logic [               1:0] in_axi_rresp,
    output logic                      in_axi_rlast,
    output logic [   RUSER_WIDTH-1:0] in_axi_ruser,
    output logic                      in_axi_rvalid,
    input  logic                      in_axi_rready,

    //
    // AXI cfg slave interface
    //
    // Write address channel
    input  logic [      ID_WIDTH-1:0] cfg_axi_awid,
    input  logic [    ADDR_WIDTH-1:0] cfg_axi_awaddr,
    input  logic [               7:0] cfg_axi_awlen,
    input  logic [               2:0] cfg_axi_awsize,
    input  logic [               1:0] cfg_axi_awburst,
    input  logic                      cfg_axi_awlock,
    input  logic [               3:0] cfg_axi_awcache,
    input  logic [               2:0] cfg_axi_awprot,
    input  logic [               3:0] cfg_axi_awqos,
    input  logic [               3:0] cfg_axi_awregion,
    input  logic [  AWUSER_WIDTH-1:0] cfg_axi_awuser,
    input  logic                      cfg_axi_awvalid,
    output logic                      cfg_axi_awready,
    // Write data channel
    input  logic [    DATA_WIDTH-1:0] cfg_axi_wdata,
    input  logic [    STRB_WIDTH-1:0] cfg_axi_wstrb,
    input  logic                      cfg_axi_wlast,
    input  logic [   WUSER_WIDTH-1:0] cfg_axi_wuser,
    input  logic                      cfg_axi_wvalid,
    output logic                      cfg_axi_wready,
    // Write response channel
    output logic [      ID_WIDTH-1:0] cfg_axi_bid,
    output logic [               1:0] cfg_axi_bresp,
    output logic [   BUSER_WIDTH-1:0] cfg_axi_buser,
    output logic                      cfg_axi_bvalid,
    input  logic                      cfg_axi_bready,
    // Read address channel
    input  logic [      ID_WIDTH-1:0] cfg_axi_arid,
    input  logic [    ADDR_WIDTH-1:0] cfg_axi_araddr,
    input  logic [               7:0] cfg_axi_arlen,
    input  logic [               2:0] cfg_axi_arsize,
    input  logic [               1:0] cfg_axi_arburst,
    input  logic                      cfg_axi_arlock,
    input  logic [               3:0] cfg_axi_arcache,
    input  logic [               2:0] cfg_axi_arprot,
    input  logic [               3:0] cfg_axi_arqos,
    input  logic [               3:0] cfg_axi_arregion,
    input  logic [  ARUSER_WIDTH-1:0] cfg_axi_aruser,
    input  logic                      cfg_axi_arvalid,
    output logic                      cfg_axi_arready,
    // Read data channel
    output logic [      ID_WIDTH-1:0] cfg_axi_rid,
    output logic [    DATA_WIDTH-1:0] cfg_axi_rdata,
    output logic [               1:0] cfg_axi_rresp,
    output logic                      cfg_axi_rlast,
    output logic [   RUSER_WIDTH-1:0] cfg_axi_ruser,
    output logic                      cfg_axi_rvalid,
    input  logic                      cfg_axi_rready,

    output logic    wsi_wire
);

`AXI_TYPEDEF_AW_CHAN_T(iopmp_axi_aw_chan_t, logic[ADDR_WIDTH-1:0], logic[ID_WIDTH-1:0],
                         logic[AWUSER_WIDTH-1:0])
`AXI_TYPEDEF_W_CHAN_T(iopmp_axi_w_chan_t, logic[DATA_WIDTH-1:0], logic[STRB_WIDTH-1:0],
                    logic[WUSER_WIDTH-1:0])
`AXI_TYPEDEF_B_CHAN_T(iopmp_axi_b_chan_t, logic[ID_WIDTH-1:0], logic[BUSER_WIDTH-1:0])
`AXI_TYPEDEF_AR_CHAN_T(iopmp_axi_ar_chan_t, logic[ADDR_WIDTH-1:0], logic[ID_WIDTH-1:0],
                        logic[ARUSER_WIDTH-1:0])
`AXI_TYPEDEF_R_CHAN_T(iopmp_axi_r_chan_t, logic[DATA_WIDTH-1:0], logic[ID_WIDTH-1:0],
                    logic[RUSER_WIDTH-1:0])
`AXI_TYPEDEF_REQ_T(iopmp_axi_req_t, iopmp_axi_aw_chan_t, iopmp_axi_w_chan_t, iopmp_axi_ar_chan_t)
`AXI_TYPEDEF_RESP_T(iopmp_axi_rsp_t, iopmp_axi_b_chan_t, iopmp_axi_r_chan_t)

iopmp_axi_req_t s_axi_req;
iopmp_axi_rsp_t s_axi_rsp;

iopmp_axi_req_t s_axi_cfg_req;
iopmp_axi_rsp_t s_axi_cfg_rsp;

iopmp_axi_req_t mq_axi_req;
iopmp_axi_rsp_t mq_axi_rsp;

typedef logic [rv_iopmp_reg_pkg::BlockAw-1:0] reg_addr_t;
typedef logic [32-1:0] reg_data_t;
typedef logic [4-1:0] reg_strb_t;
`REG_BUS_TYPEDEF_ALL(iopmp_reg, reg_addr_t, reg_data_t, reg_strb_t)
iopmp_reg_req_t cfg_reg_req;
iopmp_reg_rsp_t cfg_reg_rsp;

riscv_iopmp #(
    // AXI specific parameters
    // width of data bus in bits
    .DATA_WIDTH(DATA_WIDTH),
    // width of addr bus in bits
    .ADDR_WIDTH(ADDR_WIDTH),
    // width of awuser signal
    .USER_WIDTH(USER_WIDTH),
    // width of id signal
    .ID_WIDTH(ID_WIDTH),
    // AXI request/response
    .axi_req_t(iopmp_axi_req_t),
    .axi_rsp_t(iopmp_axi_rsp_t),
    // AXI channel structs
    .axi_aw_chan_t (iopmp_axi_aw_chan_t),
    .axi_w_chan_t  (iopmp_axi_w_chan_t),
    .axi_b_chan_t  (iopmp_axi_b_chan_t),
    .axi_ar_chan_t (iopmp_axi_ar_chan_t),
    .axi_r_chan_t  (iopmp_axi_r_chan_t),

    // Register Interface parameters
    .reg_req_t (iopmp_reg_req_t),
    .reg_rsp_t (iopmp_reg_rsp_t),

    // Implementation Specific
    .NUMBER_MDS(NUMBER_MDS    ),
    .NUMBER_ENTRIES(NUMBER_ENTRIES),
    .NUMBER_MASTERS(NUMBER_MASTERS),
    .NUMBER_TL_INSTANCES(NUMBER_TL_INSTANCES)
) i_riscv_iopmp (
    .clk_i (clk),
    .rst_ni(!rst),

    // AXI Config Slave port
    .control_req_i(s_axi_cfg_req),
    .control_rsp_o(s_axi_cfg_rsp),

    // AXI Bus Slave port
    .receiver_req_i(s_axi_req),
    .receiver_rsp_o(s_axi_rsp),

    // AXI Bus Master port
    .initiator_req_o(mq_axi_req),
    .initiator_rsp_i(mq_axi_rsp),

    .wsi_wire_o(wsi_wire)
);


//
// Traditional AXI slave signal to (req/resp) pair conversion
//
axi_slave_connector #(
    .DATA_WIDTH  (DATA_WIDTH),
    .ADDR_WIDTH  (ADDR_WIDTH),
    .STRB_WIDTH  (STRB_WIDTH),
    .ID_WIDTH    (ID_WIDTH),
    .AWUSER_WIDTH(AWUSER_WIDTH),
    .WUSER_WIDTH (WUSER_WIDTH),
    .BUSER_WIDTH (BUSER_WIDTH),
    .ARUSER_WIDTH(ARUSER_WIDTH),
    .RUSER_WIDTH (RUSER_WIDTH),
    .axi_req_t   (iopmp_axi_req_t),
    .axi_rsp_t   (iopmp_axi_rsp_t)
) i_in_axi_slave_connector (
    //
    // AXI signals
    //
    .s_axi_awid    (in_axi_awid),
    .s_axi_awaddr  (in_axi_awaddr),
    .s_axi_awlen   (in_axi_awlen),
    .s_axi_awsize  (in_axi_awsize),
    .s_axi_awburst (in_axi_awburst),
    .s_axi_awlock  (in_axi_awlock),
    .s_axi_awcache (in_axi_awcache),
    .s_axi_awprot  (in_axi_awprot),
    .s_axi_awqos   (in_axi_awqos),
    .s_axi_awregion(in_axi_awregion),
    .s_axi_awuser  (in_axi_awuser),
    .s_axi_awvalid (in_axi_awvalid),
    .s_axi_awready (in_axi_awready),
    .s_axi_wdata   (in_axi_wdata),
    .s_axi_wstrb   (in_axi_wstrb),
    .s_axi_wlast   (in_axi_wlast),
    .s_axi_wuser   (in_axi_wuser),
    .s_axi_wvalid  (in_axi_wvalid),
    .s_axi_wready  (in_axi_wready),
    .s_axi_bid     (in_axi_bid),
    .s_axi_bresp   (in_axi_bresp),
    .s_axi_buser   (in_axi_buser),
    .s_axi_bvalid  (in_axi_bvalid),
    .s_axi_bready  (in_axi_bready),
    .s_axi_arid    (in_axi_arid),
    .s_axi_araddr  (in_axi_araddr),
    .s_axi_arlen   (in_axi_arlen),
    .s_axi_arsize  (in_axi_arsize),
    .s_axi_arburst (in_axi_arburst),
    .s_axi_arlock  (in_axi_arlock),
    .s_axi_arcache (in_axi_arcache),
    .s_axi_arprot  (in_axi_arprot),
    .s_axi_arqos   (in_axi_arqos),
    .s_axi_arregion(in_axi_arregion),
    .s_axi_aruser  (in_axi_aruser),
    .s_axi_arvalid (in_axi_arvalid),
    .s_axi_arready (in_axi_arready),
    .s_axi_rid     (in_axi_rid),
    .s_axi_rdata   (in_axi_rdata),
    .s_axi_rresp   (in_axi_rresp),
    .s_axi_rlast   (in_axi_rlast),
    .s_axi_ruser   (in_axi_ruser),
    .s_axi_rvalid  (in_axi_rvalid),
    .s_axi_rready  (in_axi_rready),
    //
    // AXI request/response pair
    //
    .axi_req_o     (s_axi_req),
    .axi_rsp_i     (s_axi_rsp)
);

//
// Traditional AXI slave signal to (req/resp) pair conversion
//
axi_slave_connector #(
    .DATA_WIDTH  (DATA_WIDTH),
    .ADDR_WIDTH  (ADDR_WIDTH),
    .STRB_WIDTH  (STRB_WIDTH),
    .ID_WIDTH    (ID_WIDTH),
    .AWUSER_WIDTH(AWUSER_WIDTH),
    .WUSER_WIDTH (WUSER_WIDTH),
    .BUSER_WIDTH (BUSER_WIDTH),
    .ARUSER_WIDTH(ARUSER_WIDTH),
    .RUSER_WIDTH (RUSER_WIDTH),
    .axi_req_t   (iopmp_axi_req_t),
    .axi_rsp_t   (iopmp_axi_rsp_t)
) i_in_axi_cfg_slave_connector (
    //
    // AXI signals
    //
    .s_axi_awid    (cfg_axi_awid),
    .s_axi_awaddr  (cfg_axi_awaddr),
    .s_axi_awlen   (cfg_axi_awlen),
    .s_axi_awsize  (cfg_axi_awsize),
    .s_axi_awburst (cfg_axi_awburst),
    .s_axi_awlock  (cfg_axi_awlock),
    .s_axi_awcache (cfg_axi_awcache),
    .s_axi_awprot  (cfg_axi_awprot),
    .s_axi_awqos   (cfg_axi_awqos),
    .s_axi_awregion(cfg_axi_awregion),
    .s_axi_awuser  (cfg_axi_awuser),
    .s_axi_awvalid (cfg_axi_awvalid),
    .s_axi_awready (cfg_axi_awready),
    .s_axi_wdata   (cfg_axi_wdata),
    .s_axi_wstrb   (cfg_axi_wstrb),
    .s_axi_wlast   (cfg_axi_wlast),
    .s_axi_wuser   (cfg_axi_wuser),
    .s_axi_wvalid  (cfg_axi_wvalid),
    .s_axi_wready  (cfg_axi_wready),
    .s_axi_bid     (cfg_axi_bid),
    .s_axi_bresp   (cfg_axi_bresp),
    .s_axi_buser   (cfg_axi_buser),
    .s_axi_bvalid  (cfg_axi_bvalid),
    .s_axi_bready  (cfg_axi_bready),
    .s_axi_arid    (cfg_axi_arid),
    .s_axi_araddr  (cfg_axi_araddr),
    .s_axi_arlen   (cfg_axi_arlen),
    .s_axi_arsize  (cfg_axi_arsize),
    .s_axi_arburst (cfg_axi_arburst),
    .s_axi_arlock  (cfg_axi_arlock),
    .s_axi_arcache (cfg_axi_arcache),
    .s_axi_arprot  (cfg_axi_arprot),
    .s_axi_arqos   (cfg_axi_arqos),
    .s_axi_arregion(cfg_axi_arregion),
    .s_axi_aruser  (cfg_axi_aruser),
    .s_axi_arvalid (cfg_axi_arvalid),
    .s_axi_arready (cfg_axi_arready),
    .s_axi_rid     (cfg_axi_rid),
    .s_axi_rdata   (cfg_axi_rdata),
    .s_axi_rresp   (cfg_axi_rresp),
    .s_axi_rlast   (cfg_axi_rlast),
    .s_axi_ruser   (cfg_axi_ruser),
    .s_axi_rvalid  (cfg_axi_rvalid),
    .s_axi_rready  (cfg_axi_rready),
    //
    // AXI request/response pair
    //
    .axi_req_o     (s_axi_cfg_req),
    .axi_rsp_i     (s_axi_cfg_rsp)
);

//
// Traditional AXI master signal to (req/resp) pair conversion
//
axi_master_connector #(
    .DATA_WIDTH  (DATA_WIDTH),
    .ADDR_WIDTH  (ADDR_WIDTH),
    .STRB_WIDTH  (STRB_WIDTH),
    .ID_WIDTH    (ID_WIDTH),
    .AWUSER_WIDTH(AWUSER_WIDTH),
    .WUSER_WIDTH (WUSER_WIDTH),
    .BUSER_WIDTH (BUSER_WIDTH),
    .ARUSER_WIDTH(ARUSER_WIDTH),
    .RUSER_WIDTH (RUSER_WIDTH),
    .axi_req_t   (iopmp_axi_req_t),
    .axi_rsp_t   (iopmp_axi_rsp_t)
) i_out_axi_master_connector (
    //
    // AXI signals
    //
    .m_axi_awid    (out_axi_awid),
    .m_axi_awaddr  (out_axi_awaddr),
    .m_axi_awlen   (out_axi_awlen),
    .m_axi_awsize  (out_axi_awsize),
    .m_axi_awburst (out_axi_awburst),
    .m_axi_awlock  (out_axi_awlock),
    .m_axi_awcache (out_axi_awcache),
    .m_axi_awprot  (out_axi_awprot),
    .m_axi_awqos   (out_axi_awqos),
    .m_axi_awregion(out_axi_awregion),
    .m_axi_awuser  (out_axi_awuser),
    .m_axi_awvalid (out_axi_awvalid),
    .m_axi_awready (out_axi_awready),
    .m_axi_wdata   (out_axi_wdata),
    .m_axi_wstrb   (out_axi_wstrb),
    .m_axi_wlast   (out_axi_wlast),
    .m_axi_wuser   (out_axi_wuser),
    .m_axi_wvalid  (out_axi_wvalid),
    .m_axi_wready  (out_axi_wready),
    .m_axi_bid     (out_axi_bid),
    .m_axi_bresp   (out_axi_bresp),
    .m_axi_buser   (out_axi_buser),
    .m_axi_bvalid  (out_axi_bvalid),
    .m_axi_bready  (out_axi_bready),
    .m_axi_arid    (out_axi_arid),
    .m_axi_araddr  (out_axi_araddr),
    .m_axi_arlen   (out_axi_arlen),
    .m_axi_arsize  (out_axi_arsize),
    .m_axi_arburst (out_axi_arburst),
    .m_axi_arlock  (out_axi_arlock),
    .m_axi_arcache (out_axi_arcache),
    .m_axi_arprot  (out_axi_arprot),
    .m_axi_arqos   (out_axi_arqos),
    .m_axi_arregion(out_axi_arregion),
    .m_axi_aruser  (out_axi_aruser),
    .m_axi_arvalid (out_axi_arvalid),
    .m_axi_arready (out_axi_arready),
    .m_axi_rid     (out_axi_rid),
    .m_axi_rdata   (out_axi_rdata),
    .m_axi_rresp   (out_axi_rresp),
    .m_axi_rlast   (out_axi_rlast),
    .m_axi_ruser   (out_axi_ruser),
    .m_axi_rvalid  (out_axi_rvalid),
    .m_axi_rready  (out_axi_rready),
    //
    // AXI request/response pair
    //
    .axi_req_i     (mq_axi_req),
    .axi_rsp_o     (mq_axi_rsp)
);


initial begin
    $dumpfile("dump.vcd");
end

endmodule
