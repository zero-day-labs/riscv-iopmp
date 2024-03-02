// Author: Luís Cunha <luisccunha8@gmail.com>
// Date: 02/03/2024
// Acknowledges:
//
// Description: Converts between different widths BRAM.

// When inside a snd_stage the module is not ready to receive new data -> ready = 0
// When output data is valid -> valid = 0
module dwidth_converter_bram #(
    parameter int unsigned BRAM_DWIDTH  = 128,
    parameter int unsigned OUT_WIDTH    = 32,
    parameter int unsigned CONVERSION_RATIO = BRAM_DWIDTH/OUT_WIDTH,

    parameter int unsigned DEPTH           = 32,
    parameter int unsigned ADDR_WIDTH      = $clog2(DEPTH)
) (
    input  logic clk_i,
    input  logic rst_ni,

    input  logic we_i,
    output logic we_bram_o,

    input  logic en_i,
    output logic en_bram_o,

    input  logic [(ADDR_WIDTH * CONVERSION_RATIO) - 1 : 0] addr_i,
    output logic [ADDR_WIDTH-1:0] addr_bram_o,

    input  logic [OUT_WIDTH - 1 : 0]   din_i,
    output logic [BRAM_DWIDTH - 1 : 0] din_bram_o,

    output logic [OUT_WIDTH - 1 : 0]   dout_o,
    input  logic [BRAM_DWIDTH - 1 : 0] dout_bram_i,

    // Info
    output logic                       valid_o,
    output logic                       ready_o
);

// How many out_width fit into BRAM_width. 2^n divide by 2 to get the amount to shift
localparam int unsigned ShiftAmount = (BRAM_DWIDTH/OUT_WIDTH) / 2;
localparam int unsigned BitWidthShift = $clog2(CONVERSION_RATIO);

logic [BitWidthShift - 1 : 0] shift_qtty_n, shift_qtty_q;
logic [7:0] actual_shift_qtty;  // For improved Verilatr compatibility

logic [ADDR_WIDTH-1:0] pipeline_addr_n, pipeline_addr_q;
logic [OUT_WIDTH-1:0]  pipeline_data_n, pipeline_data_q;

logic write_snd_stage_en_n, write_snd_stage_en_q;
logic   read_snd_stage_en_n, read_snd_stage_en_q;

always_comb begin
    en_bram_o = 0;
    we_bram_o = 0;

    addr_bram_o = 0;
    din_bram_o  = 0;
    dout_o      = 0;

    write_snd_stage_en_n = 0;
    read_snd_stage_en_n  = 0;

    shift_qtty_n    = shift_qtty_q;
    pipeline_addr_n = pipeline_addr_q;
    pipeline_data_n = pipeline_data_q;

    valid_o = 0;
    ready_o = 1;
    actual_shift_qtty = 0;

    if(write_snd_stage_en_q) begin
        // Replace the correct bits and write to the BRAM
        // Verilatr does not like making the expression into one so
        actual_shift_qtty = (shift_qtty_q << $clog2(OUT_WIDTH));

        din_bram_o = dout_bram_i;
        din_bram_o[actual_shift_qtty +: OUT_WIDTH] = pipeline_data_q;
        // Correct address
        addr_bram_o = pipeline_addr_q;

        // Enable write
        en_bram_o = 1;
        we_bram_o = 1;
        ready_o   = 0;
    end else if(read_snd_stage_en_q) begin
        dout_o  = dout_bram_i >> (shift_qtty_q << $clog2(OUT_WIDTH));
        valid_o = 1;
        ready_o = 0;
    end else if(en_i) begin
        en_bram_o = 1; // Enable a read from the BRAM

        if(we_i) begin
            // Get correct BRAM address
            addr_bram_o = addr_i >> ShiftAmount;
            shift_qtty_n  = addr_i[(BitWidthShift - 1) :0];

            pipeline_addr_n = addr_bram_o;
            pipeline_data_n = din_i;
            write_snd_stage_en_n = 1;
        end
        else
            read_snd_stage_en_n = 1;
    end
end

// Sequential process
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        pipeline_addr_q         <= 0;
        pipeline_data_q         <= 0;
        write_snd_stage_en_q    <= 0;
        read_snd_stage_en_q     <= 0;
        shift_qtty_q            <= 0;
    end else begin
        pipeline_addr_q         <= pipeline_addr_n;
        pipeline_data_q         <= pipeline_data_n;
        write_snd_stage_en_q    <= write_snd_stage_en_n;
        read_snd_stage_en_q     <= read_snd_stage_en_n;
        shift_qtty_q            <= shift_qtty_n;
    end
end

endmodule
