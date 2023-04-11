// Author: Francisco Marques, University of Minho
// Date: 08/06/2022
// Last Modification: 08/06/2022
// Status: Unstable.
// Description: This device aims to be a practical maner to test iopmp device. It is comprised by an AXI Lite
//              interface in orther to configure the device.
//              It is possible to do single writes and single reads.
//              

import iopmp_stimulus_pkg::*;

module iopmp_stimulus #(
    // IOPMP block parameters
    parameter int unsigned PLEN = 34,       // rv64: 56

    //  AXI interface parameters
    parameter int unsigned AXI_ADDR_WIDTH = 32,
    parameter int unsigned AXI_DATA_WIDTH = 32,
    parameter int unsigned AXI_ID_WIDTH   = 10
) (
    // Global signals
    input   logic                       clk_i,
    input   logic                       rst_ni,
    // AXI Slave Interface to AXI XBAR to configure the Stimulus device
    input   ariane_axi::req_t           axi_config_req_i,
    output  ariane_axi::resp_t          axi_config_resp_o,
    // Signals to IOPMP device
    output logic [PLEN-1:0]              addr_o,
    output logic                         sid_o,
    output iopmp_pkg::iopmp_access_t     access_type_o,
    output logic [63:0]                  data_o,
    // Signals from IOPMP device
    input  logic                         tr_i
);

    // signals from AXI 4 Lite
    logic [AXI_ADDR_WIDTH-1:0]  address_cfg;
    logic                       en_cfg;
    logic                       we_cfg;
    logic [7:0]                 be_cfg;
    logic [AXI_DATA_WIDTH-1:0]  wdata_cfg;
    logic [AXI_DATA_WIDTH-1:0]  rdata_cfg;
    // For register selection
    logic [15:0]                register_address_cfg;

    // Registers Implementation
    iopmp_stimulus_pkg::stimulus_cfg_t      stimulus_cfg_d,    stimulus_cfg_q;
    iopmp_stimulus_pkg::stimulus_status_t   stimulus_status_d, stimulus_status_q;
    logic [63:0]                            stimulus_data_d,   stimulus_data_q;   
    logic [PLEN-1:0]                        stimulus_addr_d,   stimulus_addr_q;

    assign register_address_cfg = address_cfg[15:0];
    
    // -----------------------------
    // Output update Logic
    // -----------------------------
    always_comb begin
        if(stimulus_cfg_q.EN) begin
            access_type_o    = stimulus_cfg_q.A;
            sid_o            = stimulus_cfg_q.SID;
            data_o           = stimulus_data_q;
            addr_o           = stimulus_addr_q;        
        end
    end

    // -----------------------------
    // Input update Logic
    // -----------------------------
    assign stimulus_status_d    = {63'b0, tr_i}; 

    // -----------------------------
    // AXI Interface Logic
    // -----------------------------
    axi_lite_interface #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH    )
    ) axi_lite_interface_iopmp_stimulus_i (
        .clk_i      ( clk_i      ),
        .rst_ni     ( rst_ni     ),
        .axi_req_i  ( axi_config_req_i  ),
        .axi_resp_o ( axi_config_resp_o ),
        .address_o  ( address_cfg    ),
        .en_o       ( en_cfg         ),
        .we_o       ( we_cfg         ),
        .be_o       ( be_cfg         ),
        .data_i     ( rdata_cfg      ),
        .data_o     ( wdata_cfg      )
    );

    // -----------------------------
    // Configuration Registers Update Logic
    // -----------------------------
    // APB register write logic
    always_comb begin
        stimulus_cfg_d      = stimulus_cfg_q;
        //stimulus_status_d   = stimulus_status_q;
        stimulus_addr_d     = stimulus_addr_q;
        stimulus_data_d     = stimulus_data_q;

        // written from APB bus - gets priority
        if (en_cfg && we_cfg) begin
            case (register_address_cfg) inside
                STIMULUS_CFG_OFF: begin
                    stimulus_cfg_d = {wdata_cfg[63], 47'b0, wdata_cfg[15:0]};
                end 
                // STIMULUS_STATUS_OFF: begin
                //     stimulus_status_d = {63'b0, wdata_cfg[0]};
                // end
                STIMULUS_DATA_OFF: begin
                    stimulus_data_d = wdata_cfg;
                end
                STIMULUS_ADDR_OFF: begin
                    stimulus_addr_d = wdata_cfg;
                end            
                default:;
            endcase
        end
    end

    // APB register read logic
    always_comb begin
        // Reset
        rdata_cfg = 'b0;
        if (en_cfg && !we_cfg) begin
            case (register_address_cfg) inside
                STIMULUS_CFG_OFF: begin
                    rdata_cfg = stimulus_cfg_q;
                end 
                STIMULUS_STATUS_OFF: begin
                    rdata_cfg = stimulus_status_q;
                end
                STIMULUS_DATA_OFF: begin
                    rdata_cfg = stimulus_data_q;
                end
                STIMULUS_ADDR_OFF: begin
                    rdata_cfg = stimulus_addr_q;
                end            
                default:;
            endcase
        end
    end

    // Sequential circuit
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            stimulus_cfg_q      <= '0;
            stimulus_status_q   <= '0;
            stimulus_data_q     <= '0;
            stimulus_addr_q     <= '0;
        end else begin
            stimulus_cfg_q      <= stimulus_cfg_d;
            stimulus_status_q   <= stimulus_status_d;
            stimulus_data_q     <= stimulus_data_d;
            stimulus_addr_q     <= stimulus_addr_d;
        end
    end

endmodule