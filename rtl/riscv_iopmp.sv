// Author: Luís Cunha <luisccunha8@gmail.com>
// Date: 14/02/2024
// Acknowledges:
//
// Description: RISC-V IOPMP TOP module.
//              Top module for the RISCV IOPMP.

module riscv_iopmp #(
    // AXI specific parameters
    // width of data bus in bits
    parameter int unsigned DATA_WIDTH     = 64,
    // width of addr bus in bits
    parameter int unsigned ADDR_WIDTH     = 64,
    // width of axuser signal
    parameter int unsigned USER_WIDTH     = 2,
    // width of id signal
    parameter int unsigned ID_WIDTH       = 8,
    // AXI request/response
    parameter type         axi_req_nsaid_t  = logic,
    parameter type         axi_rsp_t        = logic,

    /// AXI Full Slave request struct type
    parameter type         axi_req_slv_t   = logic,
    /// AXI Full Slave response struct type
    parameter type         axi_rsp_slv_t   = logic,

    // AXI channel structs
    parameter type         axi_aw_chan_t  = logic,
    parameter type         axi_w_chan_t   = logic,
    parameter type         axi_b_chan_t   = logic,
    parameter type         axi_ar_chan_t  = logic,
    parameter type         axi_r_chan_t   = logic,

    // Register Interface parameters
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic,

    // Implementation specific
    parameter int unsigned NUMBER_MDS      = 2,
    parameter int unsigned NUMBER_ENTRIES  = 8,
    parameter int unsigned NUMBER_MASTERS  = 2,
    parameter int unsigned NUMBER_TL_INSTANCES = 1,
    parameter int unsigned NUMBER_ENTRY_ANALYZERS = 8
) (
    input logic clk_i,
    input logic rst_ni,

    // AXI Config Slave port
    input  axi_req_slv_t control_req_i,
    output axi_rsp_slv_t control_rsp_o,

    // AXI Bus Slave port
    input  axi_req_nsaid_t receiver_req_i,
    output axi_rsp_t receiver_rsp_o,

    // AXI Bus Master port
    output  axi_req_nsaid_t initiator_req_o,
    input   axi_rsp_t initiator_rsp_i,

    output logic  wsi_wire_o
);

localparam int unsigned NumberMds = (NUMBER_MASTERS == 1) ? 1 : NUMBER_MDS;
localparam int unsigned SidWidth  = (NUMBER_MASTERS == 1) ? 1 : $clog2(NUMBER_MASTERS);

reg_req_t cfg_reg_req;
reg_rsp_t cfg_reg_rsp;

logic iopmp_enabled;
rv_iopmp_pkg::mdcfg_entry_t [NumberMds - 1:0]      mdcfg_table;
rv_iopmp_pkg::srcmd_entry_t [NUMBER_MASTERS - 1:0] srcmd_table;
rv_iopmp_pkg::iopmp_entry_t [NUMBER_ENTRIES - 1:0] entry_table;

// Transaction logic
logic                                  ready[NUMBER_TL_INSTANCES];
logic                                  valid[NUMBER_TL_INSTANCES];
logic                         transaction_en[NUMBER_TL_INSTANCES];
logic [ADDR_WIDTH - 1:0]                addr[NUMBER_TL_INSTANCES];
logic [$clog2(DATA_WIDTH/8) :0]    num_bytes[NUMBER_TL_INSTANCES];
logic [SidWidth     - 1:0]               sid[NUMBER_TL_INSTANCES];
rv_iopmp_pkg::access_t           access_type[NUMBER_TL_INSTANCES];

logic [NUMBER_TL_INSTANCES - 1:0]           allow_transaction_arr;
rv_iopmp_pkg::error_capture_t       [NUMBER_TL_INSTANCES - 1:0] err_interface;

rv_iopmp_cfg_abstractor_axi #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH),
    .REG_DATA_WIDTH(32),

    .reg_req_t(reg_req_t),
    .reg_rsp_t(reg_rsp_t),
    // AXI request/response
    .axi_req_t(axi_req_slv_t),
    .axi_rsp_t(axi_rsp_slv_t)
) i_rv_iopmp_cfg_abstractor_axi (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    // slave port
    .slv_req_i(control_req_i),
    .slv_rsp_o(control_rsp_o),

    .cfg_req_o(cfg_reg_req),
    .cfg_rsp_i(cfg_reg_rsp)
);

rv_iopmp_regmap_wrapper #(
    .reg_req_t(reg_req_t),
    .reg_rsp_t(reg_rsp_t),

    // Implementation specific parameters
    .NUMBER_MDS(NumberMds),
    .NUMBER_ENTRIES(NUMBER_ENTRIES),
    .NUMBER_MASTERS(NUMBER_MASTERS),
    .NUMBER_IOPMP_INSTANCES(NUMBER_TL_INSTANCES)
) i_rv_iopmp_regmap_wrapper (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .devmode_i(1'b0),  // if 1, explicit error return for unmapped register access
    // register interface
    .cfg_reg_req_i(cfg_reg_req),
    .cfg_reg_rsp_o(cfg_reg_rsp),

    .err_interface_i(err_interface),

    .iopmp_enabled_o(iopmp_enabled),
    .mdcfg_table_o ( mdcfg_table ),
    .srcmd_table_o ( srcmd_table ),
    .entry_table_o ( entry_table ),

    .wsi_wire_o(wsi_wire_o)
);

genvar i;
generate
    for (i = 0; i < NUMBER_TL_INSTANCES; i++) begin : gen_iopmp
        rv_iopmp_transaction_logic #(
            .ADDR_WIDTH(ADDR_WIDTH),
            .SID_WIDTH (SidWidth),  // The signal which connects to the SID is the user field
            .NUMBER_MDS(NumberMds),
            .NUMBER_ENTRIES(NUMBER_ENTRIES),
            .NUMBER_MASTERS(NUMBER_MASTERS),
            .NUMBER_ENTRY_ANALYZERS(NUMBER_ENTRY_ANALYZERS)
        ) i_rv_iopmp_transaction_logic(
            // rising-edge clock
            .clk_i(clk_i),
            // asynchronous reset, active low
            .rst_ni(rst_ni),

            .iopmp_enabled_i(iopmp_enabled),
            .mdcfg_table_i ( mdcfg_table ),
            .srcmd_table_i ( srcmd_table ),
            .entry_table_i ( entry_table ),

            // Input
            .transaction_en_i(transaction_en[i]),
            .addr_i(addr[i]),
            .num_bytes_i(num_bytes[i]),
            .sid_i(sid[i]),
            .access_type_i(access_type[i]),
            .allow_transaction_o(allow_transaction_arr[i]),
            .ready_o(ready[i]),
            .valid_o(valid[i]),

            .err_interface_o(err_interface[i])
        );
    end
endgenerate

rv_iopmp_data_abstractor_axi #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .SID_WIDTH (SidWidth),
    .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    // AXI request/response
    .axi_req_nsaid_t(axi_req_nsaid_t),
    .axi_rsp_t(axi_rsp_t),
    // AXI channel structs
    .axi_aw_chan_t(axi_aw_chan_t),
    .axi_w_chan_t(axi_w_chan_t),
    .axi_b_chan_t(axi_b_chan_t),
    .axi_ar_chan_t(axi_ar_chan_t),
    .axi_r_chan_t(axi_r_chan_t)
) i_rv_iopmp_data_abstractor_axi(
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    // slave port
    .slv_req_i(receiver_req_i),
    .slv_rsp_o(receiver_rsp_o),
    // master port
    .mst_req_o(initiator_req_o),
    .mst_rsp_i(initiator_rsp_i),

    .transaction_en_o(transaction_en[0]),
    .addr_o(addr[0]),
    .num_bytes_o(num_bytes[0]),
    .sid_o(sid[0]),
    .access_type_o(access_type[0]),

    .iopmp_allow_transaction_i(allow_transaction_arr[0]),
    .ready_i(ready[0]),
    .valid_i(valid[0])
);

sram #(
    .DATA_WIDTH(64),
    .NUM_WORDS(NUMBER_ENTRIES)
) i_rv_iopmp_sram (
   input  logic                          .clk_i(clk_i),
   input  logic                          .rst_ni(rst_ni),
   input  logic                          .req_i(),
   input  logic                          .we_i(),
   input  logic [$clog2(NUM_WORDS)-1:0]  .addr_i(),
   input  logic [USER_WIDTH-1:0]         .wuser_i(),
   input  logic [DATA_WIDTH-1:0]         .wdata_i(),
   input  logic [(DATA_WIDTH+7)/8-1:0]   .be_i(),
   output logic [USER_WIDTH-1:0]         .ruser_o(),
   output logic [DATA_WIDTH-1:0]         .rdata_o()
);


endmodule
