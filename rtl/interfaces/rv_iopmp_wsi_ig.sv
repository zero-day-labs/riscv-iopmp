// Author: Luís Cunha <luisccunha8@gmail.com>
// Date: 14/02/2024
// Acknowledges: Manuel Rodriguez
//
// Description: RISC-V IOPMP WSI Interrupt Generation Module.

module rv_iopmp_wsi_ig(
    // fctl.wsi
    input  logic        wsi_en_i,

    // Interrupt pending bit
    input  logic intp_i,

    // Interrupt vectors
    input  logic [1:0] intv_i,

    // interrupt wires
    output logic wsi_wire_o
);

    always_comb begin : wsi_support
        wsi_wire_o = '0;

        // If WSI generation supported and enabled
        if (wsi_en_i & intv_i > 0 & intp_i)
            wsi_wire_o = 1;
    end

endmodule
