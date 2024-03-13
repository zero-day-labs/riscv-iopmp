// Adapted from: https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/RAM-Inference-True-Dual-Port-Structure-SystemVerilog

module rams_tdp_struct #(
    parameter int unsigned DATA_WIDTH      = 128,
    parameter int unsigned DEPTH           = 32,

    // DO NOT CHANGE
    parameter int unsigned ADDR_WIDTH      = $clog2(DEPTH)
) (
    input clka_i,
    input clkb_i,

    input wea_i,
    input web_i,
    input ena_i,
    input enb_i,

    input logic [ADDR_WIDTH-1:0] addra_i,
    input logic [ADDR_WIDTH-1:0] addrb_i,

    input logic [DATA_WIDTH - 1 : 0] dina_i,
    input logic [DATA_WIDTH - 1 : 0] dinb_i,

    output logic [DATA_WIDTH - 1 : 0] douta_o,
    output logic [DATA_WIDTH - 1 : 0] doutb_o
);

logic [DATA_WIDTH - 1 : 0] mem [DEPTH];

// Port A
always_ff @(posedge clka_i) begin
    if (ena_i) begin
        douta_o <= mem[addra_i];

        if(wea_i)
            mem[addra_i] <= dina_i;
    end
end

// Port B
always_ff @(posedge clkb_i) begin
    if (enb_i) begin
        doutb_o <= mem[addrb_i];

        if(web_i)
            mem[addrb_i] <= dinb_i;
    end
end

endmodule
