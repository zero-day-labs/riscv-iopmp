module rv_iopmp_top #(
    // AXI specific parameters
    // width of data bus in bits
    parameter int unsigned DATA_WIDTH     = 64,
    // width of addr bus in bits
    parameter int unsigned ADDR_WIDTH     = 64,
    // width of axuser signal
    parameter int unsigned USER_WIDTH     = 2,
    // width of id signal
    parameter int unsigned ID_WIDTH       = 8,
    // width of id signal
    parameter int unsigned ID_SLV_WIDTH   = 8,
    // AXI request/response
    parameter type         axi_req_nsaid_t  = logic,
    parameter type         axi_rsp_t        = logic,

    /// AXI Full Slave request struct type
    parameter type         axi_req_slv_t   = logic,
    /// AXI Full Slave response struct type
    parameter type         axi_rsp_slv_t   = logic,

    /// AXI Full Slave request struct type
    parameter type         cfg_axi_req_t   = logic,
    /// AXI Full Slave response struct type
    parameter type         cfg_axi_rsp_t   = logic,

    // AXI channel structs
    parameter type         axi_aw_chan_t  = logic,
    parameter type         axi_w_chan_t   = logic,
    parameter type         axi_b_chan_t   = logic,
    parameter type         axi_ar_chan_t  = logic,
    parameter type         axi_r_chan_t   = logic,

    parameter int          N_MDS       = 8,
    parameter int          N_RRID      = 8,
    parameter int          N_ENTRIES   = 16,
    parameter int          N_ENTRY_ANALYZERS = 8,

    parameter int          N_OUTGOING_TRANS = 8
) (
    input   logic clk_i,
    input   logic rst_ni,

    // // AXI Config Slave port
    input  cfg_axi_req_t control_req_i,
    output cfg_axi_rsp_t control_rsp_o,

    // AXI Bus Slave port
    input   axi_req_nsaid_t slv_req_i,
    output  axi_rsp_t       slv_rsp_o,

    // AXI Bus Master port
    output  axi_req_nsaid_t mst_req_o,
    input   axi_rsp_t       mst_rsp_i

    // output logic  wsi_wire_o
);

    typedef struct packed {
        logic [2:0]   ttype;
        logic [15:0]  rrid;
        logic [63:0]  address;
        logic [63:0]  final_address;
    } checker_data_t;

    typedef struct packed {
        logic access;
        logic error;
        logic rw;
    } checker_rslt_t;

    typedef struct packed {
        logic [ 1:0]    ttype;
        logic [ 3:0]    etype;
        logic [15:0]    rrid, eid;
        logic           interrupt, error;
        logic [63:0]    address;
    } error_t;

    axi_req_nsaid_t axi_block_req, axi_block_req_cut;
    axi_rsp_t       axi_block_rsp, axi_block_rsp_cut;
    rv_iopmp_pkg::mdcfg_t [N_MDS - 1:0] mdcfg_data;
    rv_iopmp_pkg::srcmd_t [N_RRID - 1:0] srcmd_data;
    rv_iopmp_pkg::entry_t [N_ENTRIES - 1:0] entry_data;

    checker_rslt_t  checker_rslt_2_fifo, checker_rslt;
    logic           checker_rslt_2_fifo_valid, checker_rslt_valid, checker_rslt_2_aw_valid, checker_rslt_2_w_valid, checker_rslt_2_ar_valid;
    logic           checker_rslt_2_fifo_ready, checker_rslt_ready, checker_rslt_2_aw_ready, checker_rslt_2_w_ready, checker_rslt_2_ar_ready;

    checker_data_t [1:0]    checker_data;
    logic [1:0]             checker_data_valid, checker_data_ready;

    checker_data_t          checker_arb_data, checker_arb_data_fifo;
    logic                   checker_arb_data_fifo_valid, checker_arb_data_fifo_ready;
    logic                   checker_arb_data_valid, checker_arb_data_ready;

    error_t     checker_error;
    logic       checker_error_valid;

    rv_iopmp_regmap #(
        .AxiAddrWidth (ADDR_WIDTH),
        .AxiDataWidth (DATA_WIDTH),
        .AxiIdWidth   (ID_SLV_WIDTH),
        .AxiUserWidth (USER_WIDTH),

        .axi_req_t    (cfg_axi_req_t),
        .axi_rsp_t    (cfg_axi_rsp_t),

        .mdcfg_t      (rv_iopmp_pkg::mdcfg_t),
        .srcmd_t      (rv_iopmp_pkg::srcmd_t),
        .entry_t      (rv_iopmp_pkg::entry_t),
        .error_t      (error_t),
        
        .N_MDS        (N_MDS),
        .N_RRID       (N_RRID),
        .N_ENTRIES    (N_ENTRIES)
    ) i_rv_iopmp_regmap (
        .clk_i,
        .rst_ni,
    
        .axi_req_i (control_req_i),
        .axi_rsp_o (control_rsp_o),

        .mdcfg_data_o (mdcfg_data),
        .srcmd_data_o (srcmd_data),
        .entry_data_o (entry_data),

        .error_i        (checker_error),
        .error_valid_i  (checker_error_valid)
    );

    rv_iopmp_ax_handler #(
        .ax_channel_t       (axi_aw_chan_t),
        .checker_data_t    (checker_data_t),

        .checker_rslt_t    (checker_rslt_t),

        .RW                 (1),
        .N_OUTGOING_TRANS   (N_OUTGOING_TRANS)
    ) i_rv_iopmp_aw_handler (
        .clk_i,
        .rst_ni,

        // Input data from the slave Ax Channel
        .ax_inp_valid_i         (slv_req_i.aw_valid ),
        .ax_inp_data_i          (slv_req_i.aw       ),
        .ax_inp_ready_o         (slv_rsp_o.aw_ready ),

        // To the master Ax Channel
        .ax_allow_valid_o       (mst_req_o.aw_valid),
        .ax_allow_data_o        (mst_req_o.aw),
        .ax_allow_ready_i       (mst_rsp_i.aw_ready),

        // To the error interface
        .ax_block_valid_o       (axi_block_req.aw_valid),
        .ax_block_data_o        (axi_block_req.aw),
        .ax_block_ready_i       (axi_block_rsp.aw_ready),

        // To the checker
        .checker_valid_o       (checker_data_valid[1]),
        .checker_data_o        (checker_data[1]),
        .checker_ready_i       (checker_data_ready[1]),

        // Results from the checker
        .checker_rslt_valid_i  (checker_rslt_2_aw_valid),
        .checker_rslt_i        (checker_rslt),
        .checker_rslt_ready_o  (checker_rslt_2_aw_ready)
    );

    rv_iopmp_w_handler #(
        .w_channel_t        (axi_w_chan_t),
        .checker_rslt_t    (checker_rslt_t)
    ) i_rv_iopmp_w_handler (
        .clk_i,
        .rst_ni,

        // Input data from the slave Ax Channel
        .w_inp_valid_i  (slv_req_i.w_valid),
        .w_inp_data_i   (slv_req_i.w),
        .w_inp_ready_o  (slv_rsp_o.w_ready),

        // To the master Ax Channel
        .w_allow_valid_o    (mst_req_o.w_valid),
        .w_allow_data_o     (mst_req_o.w),
        .w_allow_ready_i    (mst_rsp_i.w_ready),

        // To the error interface
        .w_block_valid_o    (axi_block_req.w_valid),
        .w_block_data_o     (axi_block_req.w),
        .w_block_ready_i    (axi_block_rsp.w_ready),

        // Results from the checker
        .checker_rslt_valid_i  (checker_rslt_2_w_valid),
        .checker_rslt_i        (checker_rslt),
        .checker_rslt_ready_o  (checker_rslt_2_w_ready)
    );

    rv_iopmp_ax_handler #(
        .ax_channel_t       (axi_ar_chan_t),
        .checker_data_t    (checker_data_t),

        .checker_rslt_t    (checker_rslt_t),

        .RW                 (0),
        .N_OUTGOING_TRANS   (N_OUTGOING_TRANS)
    ) i_rv_iopmp_ar_handler (
        .clk_i,
        .rst_ni,

        // Input data from the slave Ax Channel
        .ax_inp_valid_i         (slv_req_i.ar_valid ),
        .ax_inp_data_i          (slv_req_i.ar       ),
        .ax_inp_ready_o         (slv_rsp_o.ar_ready ),

        // To the master Ax Channel
        .ax_allow_valid_o       (mst_req_o.ar_valid),
        .ax_allow_data_o        (mst_req_o.ar),
        .ax_allow_ready_i       (mst_rsp_i.ar_ready),

        // To the error interface
        .ax_block_valid_o       (axi_block_req.ar_valid),
        .ax_block_data_o        (axi_block_req.ar),
        .ax_block_ready_i       (axi_block_rsp.ar_ready),

        // To the checker
        .checker_valid_o       (checker_data_valid[0]),
        .checker_data_o        (checker_data[0]),
        .checker_ready_i       (checker_data_ready[0]),

        // Results from the checker
        .checker_rslt_valid_i  (checker_rslt_2_ar_valid),
        .checker_rslt_i        (checker_rslt),
        .checker_rslt_ready_o  (checker_rslt_2_ar_ready)
    );

    always_comb begin
        // Only valid when both are ready
        checker_rslt_2_aw_valid = checker_rslt.rw & checker_rslt_valid & checker_rslt_2_w_ready;
        checker_rslt_2_w_valid  = checker_rslt.rw & checker_rslt_valid & checker_rslt_2_aw_ready;

        checker_rslt_ready = checker_rslt.rw? checker_rslt_2_aw_ready & checker_rslt_2_w_ready :
                                checker_rslt_2_ar_ready;

        checker_rslt_2_ar_valid = ~checker_rslt.rw & checker_rslt_valid;
    end

    stream_arbiter #(
        .DATA_T (checker_data_t),  // Vivado requires a default value for type parameters.
        .N_INP  (2)    // Synopsys DC requires a default value for value parameters.
    ) i_checker_data_arb (
        .clk_i,
        .rst_ni,

        .inp_data_i     (checker_data),
        .inp_valid_i    (checker_data_valid),
        .inp_ready_o    (checker_data_ready),

        .oup_data_o     (checker_arb_data),
        .oup_valid_o    (checker_arb_data_valid),
        .oup_ready_i    (checker_arb_data_ready)
    );
    
    stream_fifo #(
        .FALL_THROUGH (1),
        .DEPTH  (N_OUTGOING_TRANS),
        .T      (checker_data_t)
    ) i_checker_inp_fifo (
        .clk_i,      // Clock
        .rst_ni,     // Asynchronous reset active low

        .flush_i    (1'b0),    // flush the fifo
        .testmode_i (1'b0),    // test_mode to bypass clock gating
        .usage_o    (),        // fill pointer

        // input interface
        .data_i         (checker_arb_data),     // data to push into the fifo
        .valid_i        (checker_arb_data_valid),    // input data valid
        .ready_o        (checker_arb_data_ready),    // fifo is not full

        // output interface
        .data_o         (checker_arb_data_fifo),     // output data
        .valid_o        (checker_arb_data_fifo_valid),    // fifo is not empty
        .ready_i        (checker_arb_data_fifo_ready)     // pop head from fifo
    );

    stream_fifo #(
        .FALL_THROUGH (1),
        .DEPTH  (N_OUTGOING_TRANS),
        .T      (checker_rslt_t)
    ) i_checker_oup_fifo (
        .clk_i,      // Clock
        .rst_ni,     // Asynchronous reset active low

        .flush_i    (1'b0),    // flush the fifo
        .testmode_i (1'b0),    // test_mode to bypass clock gating
        .usage_o    (),        // fill pointer

        // input interface
        .data_i         (checker_rslt_2_fifo),     // data to push into the fifo
        .valid_i        (checker_rslt_2_fifo_valid),    // input data valid
        .ready_o        (checker_rslt_2_fifo_ready),    // fifo is not full

        // output interface
        .data_o         (checker_rslt),     // output data
        .valid_o        (checker_rslt_valid),    // fifo is not empty
        .ready_i        (checker_rslt_ready)     // pop head from fifo
    );

    rv_iopmp_checker #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .N_MDS              (N_MDS),
        .N_RRID             (N_RRID),
        .N_ENTRIES          (N_ENTRIES),
        .N_ENTRY_ANALYZERS  (N_ENTRY_ANALYZERS),

        .mdcfg_t        (rv_iopmp_pkg::mdcfg_t),
        .srcmd_t        (rv_iopmp_pkg::srcmd_t),
        .entry_t        (rv_iopmp_pkg::entry_t),
        .checker_data_t (checker_data_t),
        .checker_rslt_t (checker_rslt_t),
        .error_t        (error_t)
    ) i_rv_iopmp_checker (
        .clk_i,
        .rst_ni,

        .valid_i    (checker_arb_data_fifo_valid),
        .data_i     (checker_arb_data_fifo),
        .ready_o    (checker_arb_data_fifo_ready),

        .rslt_valid_o   (checker_rslt_2_fifo_valid),
        .rslt_o         (checker_rslt_2_fifo),
        .rslt_ready_i   (checker_rslt_2_fifo_ready),

        .error_o        (checker_error),
        .error_valid_o  (checker_error_valid),

        .mdcfg_data_i (mdcfg_data),
        .srcmd_data_i (srcmd_data),
        .entry_data_i (entry_data),

        .prio_entry_i               (0),
        .global_error_suppressed_i  (0),
        .md_entry_num_i             (7)
    );

    axi_cut #(
        .Bypass (0),
        // AXI channel structs
        .aw_chan_t  (axi_aw_chan_t),
        .w_chan_t   (axi_w_chan_t),
        .b_chan_t   (axi_b_chan_t),
        .ar_chan_t  (axi_ar_chan_t),
        .r_chan_t   (axi_r_chan_t),

        // AXI request & response structs
        .req_t      (axi_req_nsaid_t),
        .resp_t     (axi_rsp_t)
    ) i_axi_cut_error_path (
        .clk_i,
        .rst_ni,

        // salve port
        .slv_req_i (axi_block_req),
        .slv_resp_o(axi_block_rsp),
        
        // master port
        .mst_req_o  (axi_block_req_cut),
        .mst_resp_i (axi_block_rsp_cut)
    );

    rv_iopmp_axi_err_slv #(
        .AxiIdWidth (ID_WIDTH),                    // AXI ID Width
        .axi_req_t      (axi_req_nsaid_t),                // AXI 4 request struct, with atop field
        .axi_resp_t     (axi_rsp_t),                // AXI 4 response struct
        .Resp       (axi_pkg::RESP_DECERR), // Error generated by this slave.
        .RespWidth  (32'd64),               // Data response width, gets zero extended or truncated to r.data.
        .RespData   ('0),                   // Hexvalue for data return value
        .ATOPs      (1'b1),                 // Activate support for ATOPs.  Set to 1 if this slave could ever get an atomic AXI transaction.
        .MaxTrans   (8)                     // Maximum # of accepted transactions before stalling
    ) i_axi_err_slv (
        .clk_i,   // Clock
        .rst_ni,  // Asynchronous reset active low
        .test_i (1'b0),  // Testmode enable

        // slave port
        .slv_req_i  (axi_block_req_cut),
        .slv_resp_o (axi_block_rsp_cut)
    );

    stream_arbiter #(
        .DATA_T (axi_b_chan_t),  // Vivado requires a default value for type parameters.
        .N_INP  (2)    // Synopsys DC requires a default value for value parameters.
    ) i_b_chan_stream_arbiter (
        .clk_i,
        .rst_ni,

        .inp_data_i     ({axi_block_rsp.b, mst_rsp_i.b}),
        .inp_valid_i    ({axi_block_rsp.b_valid, mst_rsp_i.b_valid}),
        .inp_ready_o    ({axi_block_req.b_ready, mst_req_o.b_ready}),

        .oup_data_o     (slv_rsp_o.b),
        .oup_valid_o    (slv_rsp_o.b_valid),
        .oup_ready_i    (slv_req_i.b_ready)
    );

    stream_arbiter #(
        .DATA_T (axi_r_chan_t),  // Vivado requires a default value for type parameters.
        .N_INP  (2)    // Synopsys DC requires a default value for value parameters.
    ) i_r_chan_stream_arbiter (
        .clk_i,
        .rst_ni,

        .inp_data_i     ({axi_block_rsp.r, mst_rsp_i.r}),
        .inp_valid_i    ({axi_block_rsp.r_valid, mst_rsp_i.r_valid}),
        .inp_ready_o    ({axi_block_req.r_ready, mst_req_o.r_ready}),

        .oup_data_o     (slv_rsp_o.r),
        .oup_valid_o    (slv_rsp_o.r_valid),
        .oup_ready_i    (slv_req_i.r_ready)
    );

endmodule
