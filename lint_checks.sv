// Author: Luís Cunha <luisccunha8@gmail.com>
// Date: 27/03/2024
//
// Description: Top module to instance riscv_iopmp module, 
//				defining parameters and types for lint checks.

`include "common_cells/assertions.svh"
`include "ariane_axi_soc_pkg.sv"
`include "typedef_global.svh"
`include "rv_iopmp_reg_pkg.sv"
`include "rv_iopmp_pkg.sv"

module lint_checks (

	input  logic clk_i,
	input  logic rst_ni,

	// AXI Bus between IOPMP Memory IF (Mst) and System Interconnect (Slv)
    output  ariane_axi_soc::req_nsaid_t  axi_iopmp_ip_req,
    input   ariane_axi_soc::resp_t       axi_iopmp_ip_rsp,

    // AXI Bus between System Interconnect (Mst) and iopmp Programming IF (Slv)
    input  ariane_axi_soc::req_slv_t  axi_iopmp_cp_req,
    output ariane_axi_soc::resp_slv_t axi_iopmp_cp_rsp,

    // AXI Bus between DMA-device (Mst) and iopmp rp IF (Slv)
    // Extended with iopmp-specific signals
    input  ariane_axi_soc::req_nsaid_t axi_iopmp_rp_req,
    output ariane_axi_soc::resp_t      axi_iopmp_rp_rsp,

	output logic  wsi_wires_o
);

    riscv_iopmp #(
        // AXI specific parameters
        .ADDR_WIDTH			( 64				        ),
        .DATA_WIDTH			( 64				        ),
        .ID_WIDTH			( ariane_soc::IdWidth		),
        .USER_WIDTH			( 1				            ),

        // AXI request/response
        .axi_req_nsaid_t    ( ariane_axi_soc::req_nsaid_t     ),
        .axi_rsp_t			( ariane_axi_soc::resp_t	),
        .axi_req_slv_t		( ariane_axi_soc::req_slv_t	),
        .axi_rsp_slv_t		( ariane_axi_soc::resp_slv_t),
        // AXI channel structs
        .axi_aw_chan_t      (ariane_axi_soc::aw_chan_nsaid_t  ),
        .axi_w_chan_t       (ariane_axi_soc::w_chan_t	),
        .axi_b_chan_t       (ariane_axi_soc::b_chan_t	),
        .axi_ar_chan_t      (ariane_axi_soc::ar_chan_nsaid_t  ),
        .axi_r_chan_t       (ariane_axi_soc::r_chan_t	),

        // Register Interface parameters
        .reg_req_t		    ( iopmp_reg_req_t			),
        .reg_rsp_t		    ( iopmp_reg_rsp_t			),

        // Implementation specific
        .NUMBER_MDS             ( 16                    ),
        .NUMBER_ENTRIES         ( 32                    ),
        .NUMBER_MASTERS         ( 1                     ),
        .NUMBER_ENTRY_ANALYZERS ( 8                     )
    ) i_riscv_iopmp (
        .clk_i				( clk_i						),
        .rst_ni				( rst_ni					),

        // AXI Config Slave port
        .control_req_i      ( axi_iopmp_cp_req          ),
        .control_rsp_o      ( axi_iopmp_cp_rsp          ),

        // AXI Bus Slave port
        .receiver_req_i     ( axi_iopmp_rp_req          ),
        .receiver_rsp_o     ( axi_iopmp_rp_rsp          ),

        // AXI Bus Master port
        .initiator_req_o    ( axi_iopmp_ip_req          ),
        .initiator_rsp_i    ( axi_iopmp_ip_rsp          ),

        .wsi_wire_o         ( wsi_wires_o          )
    );

endmodule