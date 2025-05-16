//============================================================
// Module: rv_iopmp_checker
// Description: Entry permission checker for IOPMP mechanism.
//============================================================

module rv_iopmp_checker #(
    //============================================================
    // Parameters - Configuration
    //============================================================
    parameter int ADDR_WIDTH  = 64,
    parameter int N_MDS       = 1,
    parameter int N_RRID      = 1,
    parameter int N_ENTRIES   = 1,
    parameter int N_ENTRY_ANALYZERS = 1,
    parameter int SRCMD_FMT   = 0,
    parameter int MDCFG_FMT   = 1,

    //============================================================
    // Parameters - Types
    //============================================================
    parameter type mdcfg_t     = logic,       
    parameter type srcmd_t     = logic,       
    parameter type entry_t     = logic,
    parameter type checker_data_t  = logic,
    parameter type checker_rslt_t  = logic,
    parameter type error_t         = logic
) (
    //============================================================
    // Clock and Reset
    //============================================================
    input  logic clk_i,
    input  logic rst_ni,

    //============================================================
    // Data Flow Interfaces
    //============================================================
    input  logic            valid_i,
    input  checker_data_t   data_i,
    output logic            ready_o,

    output logic            rslt_valid_o,
    output checker_rslt_t   rslt_o,
    input  logic            rslt_ready_i,

    output error_t          error_o,
    output logic            error_valid_o,

    //============================================================
    // Configuration Inputs
    //============================================================
    input mdcfg_t  [N_MDS     - 1:0] mdcfg_data_i,
    input srcmd_t  [N_RRID    - 1:0] srcmd_data_i,
    input entry_t  [N_ENTRIES - 1:0] entry_data_i,

    input logic [$clog2(N_ENTRIES) - 1:0] prio_entry_i,
    input logic                           global_error_suppressed_i,

    input logic [6:0]                md_entry_num_i
);

    //============================================================
    // Typedefs
    //============================================================

    typedef enum logic [2:0] {
        ACCESS_NONE      = 3'b000,
        ACCESS_READ      = 3'b001,
        ACCESS_WRITE     = 3'b010,
        ACCESS_EXECUTION = 3'b100
    } access_t;

    typedef enum logic [1:0] {
        IDLE,
        CHECK,
        ISSUE_RESULT
    } state_t;

    typedef enum logic [7:0] {
        ERR_NONE            = 8'h00,
        ERR_READ_ILLEGAL    = 8'h01,
        ERR_WRITE_ILLEGAL   = 8'h02,
        ERR_PARTIAL_PRIORITY= 8'h04,
        ERR_NO_MATCH        = 8'h05
    } error_code_t;

    //============================================================
    // FSM State Registers
    //============================================================

    state_t state_q, state_d;

    //============================================================
    // Internal State and Data Registers
    //============================================================

    checker_data_t  data_to_analyze_d, data_to_analyze_q;
    checker_rslt_t  rslt_d, rslt_q;
    error_t         error_d, error_q;

    logic [$clog2(N_ENTRIES)-1:0] n_entries_offset_d, n_entries_offset_q;
    logic [$clog2(N_ENTRIES)-1:0] n_entries_md, md_base;

    //============================================================
    // Analyzer Results
    //============================================================

    logic [N_ENTRY_ANALYZERS-1:0] match_array;
    logic [N_ENTRY_ANALYZERS-1:0] partial_match_array;
    logic [N_ENTRY_ANALYZERS-1:0] allow_array;
    logic [N_ENTRY_ANALYZERS-1:0] error_supr_array;

    logic get_next_md;
    logic priority_match, priority_error_supr, priority_partial_hit;
    logic last_md, entries_left_md, had_match, had_match_q;
    logic [15:0] match_eid, match_eid_q;

    logic [62:0] srcmd_en; // Workaround to avoid Verilator index warnings

    // Compute MD enable mask based on current FSM state
    if (SRCMD_FMT == 0) begin
        assign srcmd_en = (state_q == IDLE)
                        ? srcmd_data_i[data_to_analyze_d.rrid].md
                        : srcmd_data_i[data_to_analyze_q.rrid].md;
    end else if (SRCMD_FMT == 1) begin
        assign srcmd_en = '0; // Hardwire to zero, as the MD is selected by the RRID
    end

    assign entries_left_md = (n_entries_md > N_ENTRY_ANALYZERS) &&
                             ((n_entries_offset_q + N_ENTRY_ANALYZERS) < n_entries_md);

    //============================================================
    // Output & Data Control Logic
    //============================================================
    always_comb begin
        // Default assignments
        ready_o         = 1'b0;
        rslt_valid_o    = 1'b0;
        error_valid_o   = 1'b0;

        data_to_analyze_d = data_to_analyze_q;
        rslt_d            = rslt_q;
        error_d           = error_q;
        n_entries_offset_d = n_entries_offset_q;
        get_next_md       = 1'b0;

        case (state_q)
            IDLE: begin
                ready_o = 1'b1;
                n_entries_offset_d = '0;
                data_to_analyze_d = data_i;

                // No MDs enabled, error
                // This does not occur for the SRCMD_FMT == 1 
                if (SRCMD_FMT == 0 && !(|srcmd_en)) begin
                    logic suppressed = global_error_suppressed_i;

                    rslt_d.access = 1'b0;
                    rslt_d.rw     = data_i.ttype[1];
                    
                    // Build error report
                    rslt_d.error  = !suppressed;
                    error_d.error = rslt_d.error;

                    error_d.rrid    = data_i.rrid;
                    error_d.eid     = match_eid;
                    error_d.address = data_i.address;
                    error_d.ttype   = data_i.ttype;
                    error_d.etype   = ERR_NO_MATCH;
                end
            end

            CHECK: begin
                // Handle entry paging
                if (entries_left_md)
                    n_entries_offset_d = n_entries_offset_q + N_ENTRY_ANALYZERS;
                else
                    get_next_md = 1'b1;

                // Default: No access granted
                rslt_d.access = 1'b0;
                rslt_d.rw     = data_to_analyze_q.ttype[1];
                rslt_d.error  = 1'b0;

                // Result for valid match + allow
                if ((|(match_array & allow_array)) && !priority_match) begin
                    rslt_d.access = 1'b1;
                end else begin
                    // Build error report
                    logic suppressed = global_error_suppressed_i;

                    rslt_d.error  = !suppressed && !(priority_match ? priority_error_supr : (|(error_supr_array) ));
                    error_d.error = rslt_d.error;

                    error_d.rrid    = data_to_analyze_q.rrid;
                    error_d.eid     = match_eid;
                    error_d.address = data_to_analyze_q.address;
                    error_d.ttype   = data_to_analyze_q.ttype;

                    if (last_md && !entries_left_md && !had_match)
                        error_d.etype = ERR_NO_MATCH;
                    else if (priority_match && priority_partial_hit)
                        error_d.etype = ERR_PARTIAL_PRIORITY;
                    else
                        error_d.etype = data_to_analyze_q.ttype[1] ? ERR_WRITE_ILLEGAL : ERR_READ_ILLEGAL;
                end
            end

            // Insert FIFO in here, will allow us to remove this state as we are garanteed to always have an output to this fifos
            // Only start if the FIFO is empty
            ISSUE_RESULT: begin
                rslt_valid_o  = 1'b1;
                rslt_o        = rslt_q;

                error_valid_o = 1'b1;
                error_o       = error_q;
            end

            default: ;
        endcase
    end

    //============================================================
    // FSM: Next-State Logic
    //============================================================
    always_comb begin
        state_d = state_q;

        case (state_q)
            IDLE: begin
                if (valid_i) begin
                    // Transition to CHECK if at least one MD is enabled
                    if (SRCMD_FMT == 0) state_d = (|srcmd_en) ? CHECK : ISSUE_RESULT;
                    else state_d = CHECK;
                end
            end

            CHECK: begin
                // Done when: any match allows access, a priority match exists,
                // or we're at the last MD and all entries are checked
                if ((|(match_array & allow_array)) ||
                    priority_match ||
                    (last_md && !entries_left_md)) begin
                    state_d = ISSUE_RESULT;
                end
            end

            ISSUE_RESULT: begin
                // Wait for consumer to accept result
                if (rslt_ready_i)
                    state_d = IDLE;
            end

            default: state_d = IDLE;
        endcase
    end

    //============================================================
    // Priority Match Logic
    //============================================================
    always_comb begin
        // Default assignments
        priority_match       = 1'b0;
        priority_error_supr  = 1'b0;
        priority_partial_hit = 1'b0;

        if (state_q == CHECK) begin
            for (int i = 0; i < N_ENTRY_ANALYZERS; i++) begin
                // Allow takes priority, stop early if granted
                if (match_array[i] && allow_array[i])
                    break;

                // Priority match = entry index is lower than current prio_entry_i
                if (match_array[i] || partial_match_array[i]) begin
                    if (prio_entry_i > i + n_entries_offset_q + md_base) begin
                        priority_match       = 1'b1;
                        priority_error_supr  = error_supr_array[i];
                        priority_partial_hit = partial_match_array[i];
                        break;
                    end
                end
            end
        end
    end

    //============================================================
    // Match Tracking Logic
    //============================================================
    always_comb begin
        had_match = had_match_q;
        match_eid = match_eid_q;

        if (state_q == CHECK && !had_match_q) begin
            for (int i = 0; i < N_ENTRY_ANALYZERS; i++) begin
                if (match_array[i] || (priority_match && partial_match_array[i])) begin
                    had_match = 1'b1;
                    match_eid = i + n_entries_offset_q + md_base;
                    break;
                end
            end
        end else if (state_q == IDLE) begin
            had_match = 1'b0;
            match_eid = '0;
        end
    end

    //============================================================
    // Entry Analyzer Generation
    //============================================================
    for (genvar i = 0; i < N_ENTRY_ANALYZERS; i++) begin : gen_entry_analyzer
        logic [$clog2(N_ENTRIES)-1:0] index;
        logic [63:0] previous_entry_addr;

        // Calculate absolute entry index
        assign index = i + n_entries_offset_q + md_base;

        // Get previous entry full address
        assign previous_entry_addr = {
            entry_data_i[index - 1].addrh,
            entry_data_i[index - 1].addrl
        };

        // Instantiate entry analyzer
        rv_iopmp_entry_analyzer #(
            .ADDR_WIDTH (ADDR_WIDTH)
        ) i_entry_analyzer (
            .addr_to_check_i         (data_to_analyze_q.address),
            .final_addr_to_check_i   (data_to_analyze_q.final_address),
            .addr_i                  (entry_data_i[index].addrl),
            .addrh_i                 (entry_data_i[index].addrh),
            .previous_entry_addr_i   (previous_entry_addr[31:0]),
            .previous_entry_addrh_i  (previous_entry_addr[63:32]),
            .mode_i                  (entry_data_i[index].cfg.a),
            .match_o                 (match_array[i]),
            .partial_match_o         (partial_match_array[i])
        );

        // Access type logic (READ, WRITE, EXECUTE)
        assign allow_array[i] = |(data_to_analyze_q.ttype & {
            entry_data_i[index].cfg.x,
            entry_data_i[index].cfg.w,
            entry_data_i[index].cfg.r
        });

        // Helper
        logic is_read    = (data_to_analyze_q.ttype == ACCESS_READ);
        logic is_write   = (data_to_analyze_q.ttype == ACCESS_WRITE);
        logic is_exec    = (data_to_analyze_q.ttype == ACCESS_EXECUTION);

        logic error_suppression =
            is_read  ? entry_data_i[index].cfg.sere :
            is_write ? entry_data_i[index].cfg.sewe :
            is_exec  ? entry_data_i[index].cfg.sexe : 1'b0;

        assign error_supr_array[i] = match_array[i] & error_suppression;

        // Optionally: interrupt logic (commented out)
        // assign interrupt_array[i] = match_array[i] & (data_to_analyze_q.rw ? entry_data_i[i].cfg.iw : entry_data_i[i].cfg.ir);
    end

    //============================================================
    // MD Manipulation Logic
    //============================================================
    logic [$clog2(N_MDS) - 1: 0] current_md_q, current_md_d, next_md;

    if(MDCFG_FMT == 0) begin
        assign md_base = current_md_q == 0? 0 : mdcfg_data_i[current_md_q - 1];
        assign n_entries_md = current_md_q == 0?  mdcfg_data_i[current_md_q] : 
                            mdcfg_data_i[current_md_q] - mdcfg_data_i[current_md_q - 1];
    end else begin
        // The base is given by the previous md index and the number of entries
        assign md_base = current_md_q * (md_entry_num_i + 1);
        assign n_entries_md = md_entry_num_i + 1;
    end

    if (SRCMD_FMT == 0) begin
        always_comb begin
            current_md_d = current_md_q;
            next_md      = current_md_q;
            last_md      = 0;

            case (state_q)
                IDLE: begin
                    // Search the srcmd entry for the first corresponding MD
                    for(int i = 0; i < N_MDS; i++) begin
                        // Setup base value, according to lowest MD
                        if(srcmd_en[i]) begin
                            current_md_d = i;
                            break;
                        end
                    end
                end
                default: begin
                    // Get next_md address ready for use
                    for(int i = 0; i < N_MDS; i++) begin
                        // If the MD belongs to the current SID, and it is a higher value MD than the current one
                        if(srcmd_en[i] && i > current_md_q) begin
                            next_md = i;
                            break;
                        end
                        if( i == N_MDS - 1) begin // If we are here, we are on the last MD
                            last_md = 1;
                            break;
                        end
                    end

                    if(get_next_md) // The FSM has reached the last entry on the MD
                        current_md_d = next_md;
                end
            endcase
        end
    end else if (SRCMD_FMT == 1) begin
        // In this FMT the RRID is used to select the MD directly
        assign current_md_d = (state_q == IDLE)
                            ? data_i.rrid
                            : data_to_analyze_q.rrid;
        assign next_md = '0; // hardwire
        assign last_md = 1'b1; // hardwire - Only one MD per RRID
    end

    // Sequential Logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= IDLE;

            data_to_analyze_q <= '{default:'0};
            rslt_q <= '{default:'0};
            error_q <= '{default:'0};

            n_entries_offset_q <= '0;
            current_md_q <= 0;

            had_match_q <= 1'b0;
            match_eid_q <= '0;
        end else begin
            state_q <= state_d;

            data_to_analyze_q <= data_to_analyze_d;
            rslt_q <= rslt_d;
            error_q <= error_d;

            n_entries_offset_q <= n_entries_offset_d;
            current_md_q <= current_md_d;

            had_match_q <= had_match;
            match_eid_q <= match_eid;
        end
    end

endmodule