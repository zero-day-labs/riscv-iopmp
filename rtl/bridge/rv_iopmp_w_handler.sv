

module rv_iopmp_w_handler #(
    parameter type  w_channel_t = logic,
    parameter type  checker_rslt_t = logic
) (
    input   logic clk_i,
    input   logic rst_ni,

    // Input data from the slave Ax Channel
    input   logic            w_inp_valid_i,
    input   w_channel_t      w_inp_data_i,
    output  logic            w_inp_ready_o,

    // To the master Ax Channel
    output  logic            w_allow_valid_o,
    output  w_channel_t      w_allow_data_o,
    input   logic            w_allow_ready_i,

    // To the error interface
    output  logic            w_block_valid_o,
    output  w_channel_t      w_block_data_o,
    input   logic            w_block_ready_i,

    // Results from the checker
    input   logic            checker_rslt_valid_i,
    input   checker_rslt_t   checker_rslt_i,
    output  logic            checker_rslt_ready_o
);

    enum logic [1:0] {
        FETCH_RSLT,
        PASSTHROUGH
    } state_q, state_d;

    w_channel_t      w_fifo_data;
    logic            w_fifo_valid;
    logic            w_fifo_ready;
    stream_fifo #(
        .DEPTH  (8),
        .T      (w_channel_t)
    ) i_w_fifo (
        .clk_i,      // Clock
        .rst_ni,     // Asynchronous reset active low

        .flush_i    (1'b0),    // flush the fifo
        .testmode_i (1'b0),    // test_mode to bypass clock gating
        .usage_o    (),        // fill pointer

        // input interface
        .data_i         (w_inp_data_i),     // data to push into the fifo
        .valid_i        (w_inp_valid_i),    // input data valid
        .ready_o        (w_inp_ready_o),    // fifo is not full

        // output interface
        .data_o         (w_fifo_data ),     // output data
        .valid_o        (w_fifo_valid),    // fifo is not empty
        .ready_i        (w_fifo_ready & (state_q == PASSTHROUGH))     // pop head from fifo
    );

    checker_rslt_t   rslt_fifo_data, rslt_fifo_data_d, rslt_fifo_data_q;
    logic            rslt_fifo_valid;
    logic            rslt_fifo_ready;
    stream_fifo #(
        .DEPTH  (8),
        .T      (checker_rslt_t)
    ) i_rslt_fifo (
        .clk_i,      // Clock
        .rst_ni,     // Asynchronous reset active low

        .flush_i    (1'b0),    // flush the fifo
        .testmode_i (1'b0),    // test_mode to bypass clock gating
        .usage_o    (),        // fill pointer

        // input interface
        .data_i         (checker_rslt_i),          // data to push into the fifo
        .valid_i        (checker_rslt_valid_i),    // input data valid
        .ready_o        (checker_rslt_ready_o),    // fifo is not full

        // output interface
        .data_o         (rslt_fifo_data ),     // output data
        .valid_o        (rslt_fifo_valid),     // fifo is not empty
        .ready_i        (rslt_fifo_ready)      // pop head from fifo
    );

    always_comb begin
        rslt_fifo_ready = 1'b0;

        rslt_fifo_data_d = rslt_fifo_data_q;

        case (state_q)
            // Fetch the result
            FETCH_RSLT: begin
                rslt_fifo_ready = 1'b1;

                if (rslt_fifo_valid) rslt_fifo_data_d = rslt_fifo_data;
            end
            default: ;
        endcase
    end

    always_comb begin
        state_d = state_q;

        case (state_q)
            FETCH_RSLT: begin
                if (rslt_fifo_valid) state_d = PASSTHROUGH;
            end
            PASSTHROUGH: begin
                // On the last beat, go to fetch another result
                if (w_fifo_valid && w_fifo_ready && w_fifo_data.last) 
                    state_d = FETCH_RSLT;
            end
            default: begin
                state_d = FETCH_RSLT;
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
            state_q             <= FETCH_RSLT;
            rslt_fifo_data_q    <= '{default:0};
        end else begin
            state_q             <= state_d;
            rslt_fifo_data_q    <= rslt_fifo_data_d;
        end
    end

    // Demux based on the checker result
    stream_demux #(
        /// Number of connected outputs.
        .N_OUP (2)
    ) i_stream_demux (
        .inp_valid_i    (w_fifo_valid & (state_q == PASSTHROUGH)),
        .inp_ready_o    (w_fifo_ready),

        .oup_sel_i      (~rslt_fifo_data_q.access), // If allow = 1

        .oup_valid_o    ({w_block_valid_o, w_allow_valid_o}),
        .oup_ready_i    ({w_block_ready_i, w_allow_ready_i})
    );

    // Only the control signals are demuxed
    // Nonetheless, the user signal must be manipulated regarding the block interface
    always_comb begin
        w_allow_data_o = w_fifo_data;
        w_block_data_o = w_fifo_data;
    end

endmodule
