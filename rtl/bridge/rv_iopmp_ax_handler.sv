

module rv_iopmp_ax_handler #(
    parameter type  ax_channel_t = logic,
    parameter type  checker_data_t = logic,

    parameter type  checker_rslt_t = logic,

    parameter logic RW = 0,
    parameter int   N_OUTGOING_TRANS = 0,
    // DO NOT OVERWRITE THIS PARAMETER
    parameter int   DEPTH = N_OUTGOING_TRANS/2
) (
    input   logic clk_i,
    input   logic rst_ni,

    // Input data from the slave Ax Channel
    input   logic            ax_inp_valid_i,
    input   ax_channel_t     ax_inp_data_i,
    output  logic            ax_inp_ready_o,

    // To the master Ax Channel
    output  logic            ax_allow_valid_o,
    output  ax_channel_t     ax_allow_data_o,
    input   logic            ax_allow_ready_i,

    // To the error interface
    output  logic            ax_block_valid_o,
    output  ax_channel_t     ax_block_data_o,
    input   logic            ax_block_ready_i,

    // To the checker
    output  logic            checker_valid_o,
    output  checker_data_t   checker_data_o,
    input   logic            checker_ready_i,

    // Results from the checker
    input   logic            checker_rslt_valid_i,
    input   checker_rslt_t   checker_rslt_i,
    output  logic            checker_rslt_ready_o
);

    enum logic [0:0] {
        IDLE,
        STORE
    } state_q, state_d;

    ax_channel_t     ax_data_d, ax_data_q;

    logic            ax_fifo_inp_valid, ax_fifo_inp_ready;
    ax_channel_t     ax_fifo_inp_data;

    logic            ax_fifo_oup_valid, ax_fifo_oup_ready;
    ax_channel_t     ax_fifo_oup_data;

    always_comb begin
        ax_data_d = ax_data_q;
        ax_inp_ready_o = 1'b0;

        checker_valid_o = 1'b0;
        checker_data_o  = '{default:0};

        ax_fifo_inp_valid = 1'b0;
        ax_fifo_inp_data  = '{default:0};

        case (state_q)
            // Cut the transaction
            IDLE: begin
                ax_inp_ready_o = 1'b1;

                if (ax_inp_valid_i) ax_data_d = ax_inp_data_i;
            end
            STORE: begin
                // Store it in the fifo waiting for the checker
                // As we do this first, the fifo automatically controls the ammount of in-flight trans
                ax_fifo_inp_valid = 1'b1;
                ax_fifo_inp_data  = ax_data_q;

                // Send data into the checker
                checker_valid_o = ax_fifo_inp_ready;

                checker_data_o.ttype = RW? 'h2 : 'h1; // Write
                checker_data_o.rrid  = ax_data_q.nsaid;

                checker_data_o.address = ax_data_q.addr;

                checker_data_o.final_address = ax_data_q.addr +
                                (axi_pkg::num_bytes(ax_data_q.size) * (ax_data_q.len + 1));
            end
        endcase
    end

    always_comb begin
        state_d = state_q;

        case (state_q)
            IDLE: begin
                if (ax_inp_valid_i) state_d = STORE;
            end
            STORE: begin
                if (ax_fifo_inp_ready) state_d = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
            state_q     <= IDLE;
            ax_data_q   <= '{default:0};
        end else begin
            state_q     <= state_d;
            ax_data_q   <= ax_data_d;
        end
    end

    stream_fifo #(
        .DEPTH  (DEPTH),
        .T      (ax_channel_t)
    ) i_wait_results_fifo (
        .clk_i,      // Clock
        .rst_ni,     // Asynchronous reset active low

        .flush_i    (1'b0),    // flush the fifo
        .testmode_i (1'b0),    // test_mode to bypass clock gating
        .usage_o    (),        // fill pointer

        // input interface
        .data_i         (ax_fifo_inp_data),     // data to push into the fifo
        .valid_i        (ax_fifo_inp_valid),    // input data valid
        .ready_o        (ax_fifo_inp_ready),    // fifo is not full

        // output interface
        .data_o         (ax_fifo_oup_data ),     // output data
        .valid_o        (ax_fifo_oup_valid),    // fifo is not empty
        .ready_i        (ax_fifo_oup_ready & checker_rslt_valid_i)     // pop head from fifo
    );

    // Demux based on the checker result
    stream_demux #(
        /// Number of connected outputs.
        .N_OUP (2)
    ) i_stream_demux (
        .inp_valid_i    (ax_fifo_oup_valid & checker_rslt_valid_i),
        .inp_ready_o    (ax_fifo_oup_ready),

        .oup_sel_i      (~checker_rslt_i.access), // If allow = 1

        .oup_valid_o    ({ax_block_valid_o, ax_allow_valid_o}),
        .oup_ready_i    ({ax_block_ready_i, ax_allow_ready_i})
    );

    // Only the control signals are demuxed
    // Nonetheless, the user signal must be manipulated regarding the block interface
    always_comb begin
        ax_allow_data_o = ax_fifo_oup_data;
        ax_block_data_o = ax_fifo_oup_data;

        ax_block_data_o.user = checker_rslt_i.error;
    end

    assign checker_rslt_ready_o = ax_fifo_oup_ready; // TODO: Check if this can be the case

endmodule
