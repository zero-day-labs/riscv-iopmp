typedef enum logic [2:0] {
    IDLE            = 3'b000,
    SETUP           = 3'b001,
    MULTI_CYCLE_VER = 3'b010,
    WAIT_IOPMP      = 3'b011,
    AXI_HANDSHAKE   = 3'b100
} state_t;

module rv_iopmp_data_abstractor_axi #(
    parameter int unsigned SID_WIDTH      = 8,
    // width of data bus in bits
    parameter int unsigned DATA_WIDTH     = 64,
    // width of addr bus in bits
    parameter int unsigned ADDR_WIDTH     = 64,
    // width of id signal
    parameter int unsigned ID_WIDTH       = 8,

    // AXI request/response
    parameter type         axi_req_nsaid_t  = logic,
    parameter type         axi_rsp_t        = logic,
    // AXI channel structs
    parameter type         axi_aw_chan_t  = logic,
    parameter type         axi_w_chan_t   = logic,
    parameter type         axi_b_chan_t   = logic,
    parameter type         axi_ar_chan_t  = logic,
    parameter type         axi_r_chan_t   = logic,

    // AXI parameters
    // maximum number of AXI bursts outstanding at the same time
    parameter int unsigned MaxTxns        = 32'd2
) (
    input logic clk_i,
    input logic rst_ni,

    // slave port
    input  axi_req_nsaid_t slv_req_i,
    output axi_rsp_t       slv_rsp_o,
    // master port
    output axi_req_nsaid_t mst_req_o,
    input  axi_rsp_t       mst_rsp_i,

    output logic                                   transaction_en_o,
    output logic [ADDR_WIDTH - 1:0]                addr_o,
    output logic [$clog2(DATA_WIDTH/8) :0]         num_bytes_o,
    output logic [SID_WIDTH     - 1:0]             sid_o,
    output rv_iopmp_pkg::access_t                  access_type_o,

    input  logic                 iopmp_allow_transaction_i,
    input  logic                                   ready_i,
    input  logic                                   valid_i
);

logic enable_checking;
logic allow_transaction;
logic transaction_allowed;
logic aw_request;
logic ar_request;
logic detect_pulse;

// AxADDR
logic [ADDR_WIDTH-1:0]             addr;
logic [ADDR_WIDTH-1:0]             addr_to_check;
logic [$clog2(DATA_WIDTH/8) :0]    num_bytes;
// AxBURST
axi_pkg::burst_t         burst_type;
// AxLEN
axi_pkg::len_t           burst_length;
// AxSIZE
axi_pkg::size_t          size;

// Boundary checking
logic bc_allow_request;
logic bc_bound_violation;
logic [ADDR_WIDTH-1:0]  wrap_boundary;

// State register
state_t state_reg;

// Helper wire
assign allow_transaction = iopmp_allow_transaction_i & bc_allow_request;

rv_iopmp_axi4_bc i_rv_iopmp_axi4_bc(
    // AxVALID
    .request_i(aw_request | ar_request),
    // AxADDR
    .addr_i(addr),
    // AxBURST
    .burst_type_i(burst_type),
    // AxLEN
    .burst_length_i(burst_length),
    // AxSIZE
    .n_bytes_i(size),

    // To indicate valid requests or boundary violations
    .allow_request_o(bc_allow_request),
    .bound_violation_o(bc_bound_violation),
    .wrap_boundary_o(wrap_boundary)
);


// AXI request bus used to intercept AxADDR and AxVALID parameters, and connect to the demux slave port
axi_req_nsaid_t   axi_aux_req;

always_comb begin
    axi_aux_req = slv_req_i;

    // Do not perform the handshake, while the checking is ongoing
    axi_aux_req.aw_valid = (state_reg == AXI_HANDSHAKE) ? aw_request : 0;
    axi_aux_req.ar_valid = (state_reg == AXI_HANDSHAKE) ? ar_request : 0;
end

// State transition part of the FSM
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        // Initialization on reset
        state_reg <= IDLE;
    end else begin
        // State transition logic
        case (state_reg)
            IDLE:   state_reg <= (slv_req_i.aw_valid | slv_req_i.ar_valid)? MULTI_CYCLE_VER : IDLE;

            MULTI_CYCLE_VER: begin
                state_reg <= (((burst_type == axi_pkg::BURST_WRAP) & (addr_to_check == wrap_boundary)) |
                                (counter >= burst_length)) & (detect_pulse != ready_i & !ready_i) ?
                                    WAIT_IOPMP : ((!allow_transaction) && valid_i)? AXI_HANDSHAKE :
                                        MULTI_CYCLE_VER;
            end

            WAIT_IOPMP: state_reg <= valid_i? AXI_HANDSHAKE: state_reg;

            // Wait until the handshake has ended
            AXI_HANDSHAKE:  state_reg <= (ar_request & !slv_req_i.ar_valid) |
                                (aw_request & !slv_req_i.aw_valid)? IDLE: AXI_HANDSHAKE;

            default: state_reg <= IDLE;
        endcase
    end
end

logic [8:0] counter;

// Sequential part of the state machine
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        ar_request <= 1'b0;
        aw_request <= 1'b0;
        transaction_allowed <= 0;

        counter <= 0;
        addr <= 0;
        addr_to_check <= 0;
        num_bytes <= 0;
        size <= 0;
        burst_type <= 0;
        burst_length <= 0;
    end else begin
        // Counter increment logic
        case (state_reg)
            IDLE: begin
                counter <= 0;
                transaction_allowed <= 0;
                detect_pulse <= ready_i;

                aw_request      <= slv_req_i.aw_valid? 1'b1 : '0;
                ar_request      <= slv_req_i.aw_valid? '0 : slv_req_i.ar_valid? 1'b1 : 0;

                num_bytes       <= slv_req_i.aw_valid ? axi_pkg::num_bytes(slv_req_i.aw.size): axi_pkg::num_bytes(slv_req_i.ar.size);
                addr            <= slv_req_i.aw_valid ? slv_req_i.aw.addr : slv_req_i.ar.addr;
                addr_to_check   <= slv_req_i.aw_valid ? slv_req_i.aw.addr : slv_req_i.ar.addr;
                size            <= slv_req_i.aw_valid ? slv_req_i.aw.size : slv_req_i.ar.size;
                burst_type      <= slv_req_i.aw_valid ? slv_req_i.aw.burst: slv_req_i.ar.burst;
                burst_length    <= slv_req_i.aw_valid ? slv_req_i.aw.len  : slv_req_i.ar.len;
            end

            MULTI_CYCLE_VER: begin
                if (detect_pulse != ready_i) begin // Detect changes in the state, meaning iopmp has started or ended
                    // Only on the down, as it means the iopmp has started correctly
                    counter <= (!ready_i)? counter + 1: counter;
                    addr_to_check <= (!ready_i)? addr_to_check + num_bytes : addr_to_check;  // Check for the last transition, no need to increment
                end

                transaction_allowed <= (valid_i)? iopmp_allow_transaction_i & bc_allow_request : transaction_allowed;
                detect_pulse <= ready_i;
            end

            WAIT_IOPMP: transaction_allowed <= (valid_i)? iopmp_allow_transaction_i & bc_allow_request : transaction_allowed;

            default: begin
                counter             <= counter;
                ar_request          <= ar_request;
                aw_request          <= aw_request;
                transaction_allowed <= transaction_allowed;
                num_bytes           <= num_bytes;

                addr_to_check       <= addr_to_check;
                addr                <= addr;
                size                <= size;
                burst_type          <= burst_type;
                burst_length        <= burst_length;
            end
        endcase
    end
end

always_comb begin
    // Prevent another from starting when an invalidation already occurred
    transaction_en_o = (state_reg == MULTI_CYCLE_VER && counter == 0) ? 1 : 
                        ((!allow_transaction) && valid_i)? 0: (state_reg == MULTI_CYCLE_VER)? 1 : 0;
    addr_o           = addr_to_check;
    num_bytes_o      = num_bytes;
    sid_o            = (aw_request)? slv_req_i.aw.nsaid : slv_req_i.ar.nsaid;
    access_type_o    = (aw_request)? rv_iopmp_pkg::ACCESS_WRITE : rv_iopmp_pkg::ACCESS_READ;
end

//
// Demultiplex between authorized and unauthorized transactions
//
axi_req_nsaid_t error_req;
axi_rsp_t       error_rsp;
axi_demux #(
    .AxiIdWidth (ID_WIDTH),
    .aw_chan_t  (axi_aw_chan_t),
    .w_chan_t   (axi_w_chan_t),
    .b_chan_t   (axi_b_chan_t),
    .ar_chan_t  (axi_ar_chan_t),
    .r_chan_t   (axi_r_chan_t),
    .req_t      (axi_req_nsaid_t),
    .resp_t     (axi_rsp_t),
    .NoMstPorts (2),
    .MaxTrans   (MaxTxns),
    .AxiLookBits(ID_WIDTH),       // TODO: not sure what this is?
    .FallThrough(1'b0),           // TODO: check what the right value is for them
    .SpillAw    (1'b0),
    .SpillW     (1'b0),
    .SpillB     (1'b0),
    .SpillAr    (1'b0),
    .SpillR     (1'b0)
) i_axi_demux (
    .clk_i,
    .rst_ni,
    .test_i         (1'b0),
    .slv_aw_select_i(transaction_allowed),
    .slv_ar_select_i(transaction_allowed),
    .slv_req_i      (axi_aux_req),
    .slv_resp_o     (slv_rsp_o),
    .mst_reqs_o     ({mst_req_o, error_req}),  // { 1: mst, 0: error }
    .mst_resps_i    ({mst_rsp_i, error_rsp})   // { 1: mst, 0: error }
);

//
// Respond to unauthorized transactions with slave errors
//
axi_err_slv #(
    .AxiIdWidth(ID_WIDTH),
    .req_t(axi_req_nsaid_t),
    .resp_t(axi_rsp_t),
    .Resp(axi_pkg::RESP_SLVERR),  // error generated by this slave.
    .RespWidth(DATA_WIDTH),  // data response width, gets zero extended or truncated to r.data.
    .RespData(64'hCA11AB1EBADCAB1E),  // hexvalue for data return value
    .ATOPs(1'b1),
    .MaxTrans(1)
) i_axi_err_slv (
    .clk_i,
    .rst_ni,
    .test_i    (1'b0),
    .slv_req_i (error_req),
    .slv_resp_o(error_rsp)
);

endmodule
