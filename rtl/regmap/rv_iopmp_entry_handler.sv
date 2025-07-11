module rv_iopmp_entry_handler #(
    parameter type         entry_t   = logic,
    parameter int unsigned N_ENTRIES   = 8
) (
    input logic clk_i,
    input logic rst_ni,
    
    input   logic[$clog2(N_ENTRIES) - 1: 0] entry_idx_i,
    input   entry_t                         entry_data_i,
    input   logic                           valid_i,

    output  entry_t                         entry_data_o[N_ENTRIES - 1:0]
);

    logic   stage_1, stage_2;
    entry_t entry_data_q, entry_data2_q;
    logic [$clog2(N_ENTRIES) - 1: 0]   entry_idx_q, entry_idx2_q;
    
    logic [65:0] entry_addr_n; // This has two plus bits
    logic [$clog2(66) - 1:0] trail_ones;

    logic [65 - 1:0] mask;
    logic [$clog2(66) :0] size; // Can be trail ones + 3
    logic [63:0] base_addr_d, base_addr_q, end_addr_d, end_addr_q;

    // Negate, for use in the leading zero counter - Refer to PMP enconding
    assign entry_addr_n = {2'b11, ~entry_data_q.addr.base_addr};

    // Leading zero counter - Refer to PMP enconding
    lzc #(
        .WIDTH(66),
        .MODE (1'b0)
    ) i_lzc (
        .in_i   (entry_addr_n),
        .cnt_o  (trail_ones),
        .empty_o()
    );

    always_comb begin
        base_addr_d = base_addr_q;
        end_addr_d  = end_addr_q;
        size        = 0;
        mask        = '0;

        if(stage_1) begin
            if(entry_data_q.cfg.a.q == rv_iopmp_reg_pkg::NA4 || entry_data_q.cfg.a.q == rv_iopmp_reg_pkg::NAPOT) begin
                size = (entry_data_q.cfg.a.q == rv_iopmp_reg_pkg::NA4) ? 2 : trail_ones + 3;

                // Mask that allows the extraction of the base address for the entry and transaction
                mask = '1 << size;
                base_addr_d = (entry_data_q.addr.base_addr << 2) & mask; // Calculate base to compare with lower addr_to_check
                end_addr_d  = (base_addr_d + (2 << (size - 1))) - 1; // Calculate final permited address for this entry
            end

            else begin
                base_addr_d = entry_data_q.addr.base_addr;
                end_addr_d  = entry_data_q.addr.end_addr;
            end
        end
    end

    // workaround for verilator
    entry_t tmp;

    assign tmp.addr.base_addr   = base_addr_q;
    assign tmp.addr.end_addr    = end_addr_q;
    assign tmp.cfg              = entry_data2_q.cfg;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            entry_data_q <= '{default: '0};
            entry_data2_q <= '{default: '0};
            
            entry_idx_q <= 0;
            entry_idx2_q <= 0;

            stage_1 <= 1'b0;
            stage_2 <= 1'b0;

            base_addr_q <= '0;
            end_addr_q <= '0;

            for(int i = 0; i < N_ENTRIES; i++) begin
                entry_data_o[i] <= '{default: '0};
            end
        end else begin
            base_addr_q <= base_addr_d;
            end_addr_q <= end_addr_d;

            stage_1 <= valid_i;
            stage_2 <= stage_1;

            if (valid_i) begin
                entry_data_q <= entry_data_i;
                entry_idx_q <= entry_idx_i;
            end

            if (stage_1) begin
                entry_data2_q <= entry_data_q;
                entry_idx2_q <= entry_idx_q;
            end

            if(stage_2) begin
                entry_data_o[entry_idx2_q] <= tmp;
            end
        end
    end

endmodule