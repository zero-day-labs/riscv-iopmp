// Module to abstract the MD behaviour
//md_config_t(io_pmp_reg2hw_srcmd_entry_t)

// Disabled verilator lint_off WIDTHEXPAND
module rv_iopmp_entry #(
    parameter int LEN = 32,
    parameter int CHECK_LEN = 66, // In the spec the entry registers hold data for the 65:2, so 66 bits
    parameter int unsigned ADDR_WIDTH     = 64,
    parameter int unsigned DATA_WIDTH     = 64
) (
    input logic [ADDR_WIDTH - 1: 0]          addr_to_check_i,
    input logic [$clog2(DATA_WIDTH/8) :0]    num_bytes_i, // The requested_size width only depends on the width of the bus

    input logic [LEN-1: 0] addr_i,
    input logic [LEN-1: 0] addrh_i,
    input logic [LEN-1: 0] previous_entry_addr_i,
    input logic [LEN-1: 0] previous_entry_addrh_i,
    input rv_iopmp_pkg::mode_t mode_i,

    output logic match_o,
    output logic allow_o            // The requested transaction matches all the bytes of the entry?
);

logic [LEN*2-1:0] entry_addr;
logic [LEN*2-1:0] previous_entry_addr;

logic [CHECK_LEN - 1:0] entry_addr_n;
logic [$clog2(CHECK_LEN) - 1:0] trail_ones;

assign entry_addr = {addrh_i, addr_i};
assign previous_entry_addr = {previous_entry_addrh_i, previous_entry_addr_i};
assign entry_addr_n = {2'b11, ~entry_addr};   // Negate, and count the trailing zeros

logic [CHECK_LEN - 1:0] base;
logic [CHECK_LEN    :0] final_address; // The supported addresses can reach 2^(67) 
logic [CHECK_LEN - 1:0] mask;
logic [$clog2(CHECK_LEN) :0] size; // Can be trail ones + 3, which needs at least one more bit

lzc #(
    .WIDTH(CHECK_LEN),
    .MODE (1'b0)
) i_lzc (
    .in_i   (entry_addr_n),
    .cnt_o  (trail_ones),
    .empty_o()
);

always_comb begin
    match_o = 0;
    allow_o = 0;
    base = 0;
    final_address = 0;
    mask = 0;
    size = 0;

    case (mode_i)
        rv_iopmp_pkg::TOR: begin
            // check that the requested address is in between the two
            // configuration addresses
            if (addr_to_check_i >= ({2'b0, previous_entry_addr} << 2) &&
                    addr_to_check_i < ({2'b0, entry_addr} << 2)) begin
                match_o = 1'b1;
                allow_o = ((addr_to_check_i + num_bytes_i - 1) < ({2'b0, entry_addr} << 2))? 1'b1 : 1'b0;
            end else match_o = 1'b0;
        end
        rv_iopmp_pkg::NA4, rv_iopmp_pkg::NAPOT: begin
            if (mode_i == rv_iopmp_pkg::NA4)
                size = 2;
            else begin
                // use the extracted trailing ones
                size = trail_ones + 3;
            end

            mask = '1 << size;
            base = ({2'b0, entry_addr} << 2) & mask; // Calculate base to compare with lower addr_to_check
            final_address = (base + (2 << (size - 1))) - 1; // Calculate final permited address for this entry

            match_o = (addr_to_check_i & mask) == base ? 1'b1 : 1'b0;
            // Is the final requested address smaller than the final permited address of the entry?
            allow_o = (addr_to_check_i + num_bytes_i - 1 <= final_address) ? 1'b1 : 1'b0;

        end
        rv_iopmp_pkg::OFF: match_o = 1'b0;
        default:    match_o = 0;
    endcase
end


endmodule
// Disabled verilator lint_on WIDTHEXPAND
