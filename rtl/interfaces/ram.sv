module ram #(
    parameter int unsigned DATA_WIDTH      = 128,
    parameter int unsigned DEPTH           = 32,

    parameter int unsigned ADDR_WIDTH      = $clog2(DEPTH)
) (
    input clk,
    input ena,
    input [ADDR_WIDTH-1:0] raddr,

    input rv_iopmp_pkg::iopmp_entry_t [DEPTH - 1:0] entry_table_i,

    output logic [DATA_WIDTH - 1 : 0] dout
);

    logic [DATA_WIDTH - 1 : 0] mem [DEPTH];

    always @ (posedge clk) begin
        for(int i = 0; i < DEPTH; i++) begin
            mem[i][63:0] <= {entry_table_i[i].addrh.q, entry_table_i[i].addr.q};
            mem[i][127:64] <= {'0, entry_table_i[i].cfg.a, entry_table_i[i].cfg.x, entry_table_i[i].cfg.w, entry_table_i[i].cfg.r};
        end
    end

    always @ (posedge clk) begin
        if (ena) begin
            dout <= mem[raddr];
        end
    end

endmodule
