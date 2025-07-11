// Module: rv_iopmp_checker
// Description: Entry permission checker for IOPMP mechanism.

module rv_iopmp_checker #(
    parameter int ADDR_WIDTH  = 64,
    parameter int N_MDS       = 1,
    parameter int N_RRID      = 1,
    parameter int N_ENTRIES   = 1,
    parameter int N_ENTRY_ANALYZERS = 1,
    parameter int SRCMD_FMT   = 1,
    parameter int MDCFG_FMT   = 1,

    parameter type mdcfg_t     = logic,       
    parameter type srcmd_t     = logic,       
    parameter type entry_t     = logic,
    parameter type base_end_addr_t = logic,
    parameter type checker_data_t  = logic,
    parameter type checker_rslt_t  = logic,
    parameter type error_t         = logic
) (
    input  logic clk_i,
    input  logic rst_ni,

    input  logic            valid_i,
    input  checker_data_t   data_i,
    output logic            ready_o,

    output logic            rslt_valid_o,
    output checker_rslt_t   rslt_o,
    input  logic            rslt_ready_i,

    output error_t          error_o,
    output logic            error_valid_o,

    input mdcfg_t [N_MDS     - 1:0] mdcfg_data_i,
    input srcmd_t [N_RRID    - 1:0] srcmd_data_i,
    input entry_t           entry_data_i[N_ENTRIES - 1:0],

    input logic [$clog2(N_ENTRIES) - 1:0] prio_entry_i,
    input logic                           global_error_suppressed_i,

    input logic [6:0]                md_entry_num_i
);

    typedef enum logic [2:0] {
        ACCESS_NONE      = 3'b000,
        ACCESS_READ      = 3'b001,
        ACCESS_WRITE     = 3'b010,
        ACCESS_EXECUTION = 3'b100
    } access_t;

    typedef enum logic [7:0] {
        ERR_NONE            = 8'h00,
        ERR_READ_ILLEGAL    = 8'h01,
        ERR_WRITE_ILLEGAL   = 8'h02,
        ERR_PARTIAL_PRIORITY= 8'h04,
        ERR_NO_MATCH        = 8'h05
    } error_code_t;

    typedef struct packed{
        checker_data_t data_to_analyze;
        logic error;
        error_t error_data;
        checker_rslt_t rslt;
        logic [$clog2(N_MDS) - 1: 0] current_md;
    } payload_2nd_stage_t;

    error_t error_d;
    checker_rslt_t rslt_d;

    logic [$clog2(N_ENTRIES)-1:0] n_entries_offset_d, n_entries_offset_q;
    logic [$clog2(N_ENTRIES)-1:0] n_entries_md, md_base;

    logic [N_ENTRY_ANALYZERS-1:0] match_array;
    logic [N_ENTRY_ANALYZERS-1:0] partial_match_array;
    logic [N_ENTRY_ANALYZERS-1:0] allow_array;
    logic [N_ENTRY_ANALYZERS-1:0] error_supr_array;

    logic priority_match, priority_error_supr, priority_partial_hit;
    logic last_md, entries_left_md, had_match, had_match_q;
    logic [15:0] match_eid, match_eid_q;

    logic en_1stage, en_2stage;
    logic [62:0] srcmd_1_stage, srcmd_2_stage; // Workaround to avoid Verilator index warnings

    payload_2nd_stage_t payload_1_to_2_stage, payload_sr_2nd_stage, payload_2nd_stage, payload_2nd_stage_stall_q, payload_2nd_stage_stall_d;
    logic payload_1_to_2_stage_ready, payload_1_to_2_stage_valid;
    logic payload_sr_2nd_stage_ready, payload_sr_2nd_stage_valid;
    logic stall_d, stall_q;

    // Compute MD enable mask based on current FSM state
    if (SRCMD_FMT == 0) begin
        assign srcmd_1_stage = srcmd_data_i[data_i.rrid].md;
        assign srcmd_2_stage = srcmd_data_i[payload_2nd_stage.data_to_analyze.rrid].md;
    end else if (SRCMD_FMT == 1) begin
        // Hardwire to zero, as the MD is selected by the RRID
        assign srcmd_1_stage = '0;
        assign srcmd_2_stage = '0;
    end

    // 1st stage 
    assign en_1stage = payload_1_to_2_stage_ready && valid_i;

    logic [$clog2(N_MDS) - 1: 0] next_md;

    // 1st stage
    always_comb begin
        ready_o         = 1'b0;
        payload_1_to_2_stage_valid = 1'b0;
        payload_1_to_2_stage = '{default:'0};
        
        if (en_1stage) begin
            ready_o         = 1'b1;
            payload_1_to_2_stage_valid = 1'b1;

            payload_1_to_2_stage.data_to_analyze = data_i;
            payload_1_to_2_stage.error = 1'b0;
            payload_1_to_2_stage.rslt = '{default:'0};
            payload_1_to_2_stage.error_data = '{default:'0};
            payload_1_to_2_stage.current_md = '0;
            
            // No MDs enabled, error
            // This does not occur for the SRCMD_FMT == 1 
            if (SRCMD_FMT == 0 && !(|srcmd_1_stage)) begin
                logic suppressed = global_error_suppressed_i;

                payload_1_to_2_stage.rslt.access = 1'b0;
                payload_1_to_2_stage.rslt.rw     = data_i.ttype[1];
                
                // Build error report
                payload_1_to_2_stage.rslt.error  = !suppressed;
                payload_1_to_2_stage.error_data.error = !suppressed;

                payload_1_to_2_stage.error_data.rrid    = data_i.rrid;
                payload_1_to_2_stage.error_data.eid     = match_eid;
                payload_1_to_2_stage.error_data.address = data_i.address;
                payload_1_to_2_stage.error_data.ttype   = data_i.ttype;
                payload_1_to_2_stage.error_data.etype   = ERR_NO_MATCH;
            end
            else begin
                if (SRCMD_FMT == 0) begin
                    // Search the srcmd entry for the first corresponding MD
                    for(int i = 0; i < N_MDS; i++) begin
                        // Setup base value, according to lowest MD
                        if(srcmd_1_stage[i]) begin
                            payload_1_to_2_stage.current_md = i;
                            break;
                        end
                    end
                end
                else if (SRCMD_FMT == 1) begin
                    // In this FMT the RRID is used to select the MD directly
                    payload_1_to_2_stage.current_md = data_i.rrid;
                end
            end
        end
    end

    spill_register #(
        .T  (payload_2nd_stage_t)
    ) i_between_stage_payload_reg (
        .clk_i   ,
        .rst_ni  ,

        .valid_i (payload_1_to_2_stage_valid),
        .ready_o (payload_1_to_2_stage_ready),
        .data_i  (payload_1_to_2_stage      ),

        .valid_o (payload_sr_2nd_stage_valid),
        .ready_i (payload_sr_2nd_stage_ready),
        .data_o  (payload_sr_2nd_stage      )
    );

    // 2nd stage
    if(MDCFG_FMT == 0) begin
        assign md_base = payload_2nd_stage.current_md == 0? 0 : mdcfg_data_i[payload_2nd_stage.current_md - 1];
        assign n_entries_md = payload_2nd_stage.current_md == 0?  mdcfg_data_i[payload_2nd_stage.current_md] : 
                            mdcfg_data_i[payload_2nd_stage.current_md] - mdcfg_data_i[payload_2nd_stage.current_md - 1];
    end else begin
        // The base is given by the previous md index and the number of entries
        assign md_base = payload_2nd_stage.current_md * (md_entry_num_i + 1);
        assign n_entries_md = md_entry_num_i + 1;
    end

    assign entries_left_md = (n_entries_md > N_ENTRY_ANALYZERS) &&
                             ((n_entries_offset_q + N_ENTRY_ANALYZERS) < n_entries_md);

    assign last_md = next_md == payload_2nd_stage.current_md;
    always_comb begin
        payload_2nd_stage_stall_d = payload_2nd_stage;
        next_md = payload_2nd_stage.current_md;

        if (SRCMD_FMT == 0) begin
            // Get next_md address ready for use
            for(int i = 0; i < N_MDS; i++) begin
                // If the MD belongs to the current SID, and it is a higher value MD than the current one
                if(srcmd_2_stage[i] && i > payload_2nd_stage.current_md) begin
                    next_md = i;
                    break;
                end
            end

            if(!entries_left_md)
                payload_2nd_stage_stall_d.current_md = next_md;
        end
    end

    assign en_2stage = stall_q | payload_sr_2nd_stage_valid;
    assign payload_2nd_stage = stall_q? payload_2nd_stage_stall_q : 
                               payload_sr_2nd_stage;
    assign payload_sr_2nd_stage_ready = stall_q? 1'b0 : 1'b1;

    always_comb begin
        rslt_valid_o = 1'b0;
        error_valid_o = 1'b0;

        rslt_d  = '{default:'0};
        error_d = '{default:'0};
        rslt_o  = '{default:'0};
        error_o = '{default:'0};

        stall_d = 1'b0;
        n_entries_offset_d = n_entries_offset_q;

        if (en_2stage) begin
            if (payload_2nd_stage.error) begin
                rslt_valid_o = 1'b1;
                rslt_o = payload_2nd_stage.rslt;
                error_valid_o = 1'b1;
                error_o = payload_2nd_stage.error_data;
            end
            else begin
                // Default: No access granted
                rslt_d.access = 1'b0;
                rslt_d.rw     = payload_2nd_stage.data_to_analyze.ttype[1];
                rslt_d.error  = 1'b0;

                // Result for valid match + allow
                if ((|(match_array & allow_array)) && !priority_match) begin
                    rslt_d.access = 1'b1;
                end else begin
                    // Build error report
                    logic suppressed = global_error_suppressed_i;

                    rslt_d.error  = !suppressed && !(priority_match ? priority_error_supr : (|(error_supr_array) ));
                    error_d.error = rslt_d.error;

                    error_d.rrid    = payload_2nd_stage.data_to_analyze.rrid;
                    error_d.eid     = match_eid;
                    error_d.address = payload_2nd_stage.data_to_analyze.address;
                    error_d.ttype   = payload_2nd_stage.data_to_analyze.ttype;

                    if (last_md && !entries_left_md && !had_match)
                        error_d.etype = ERR_NO_MATCH;
                    else if (priority_match && priority_partial_hit)
                        error_d.etype = ERR_PARTIAL_PRIORITY;
                    else
                        error_d.etype = payload_2nd_stage.data_to_analyze.ttype[1] ? ERR_WRITE_ILLEGAL : ERR_READ_ILLEGAL;
                end

                // Done when: any match allows access, a priority match exists,
                // or we're at the last MD and all entries are checked
                if ((|(match_array & allow_array)) ||
                        priority_match || (last_md && !entries_left_md)) begin
                    rslt_valid_o = 1'b1;
                    rslt_o = rslt_d;
                    error_valid_o = rslt_ready_i;
                    error_o = error_d;

                    if (rslt_ready_i) // can reset, otherwise no
                        n_entries_offset_d = '0;

                    stall_d = ~rslt_ready_i;
                end
                else begin
                    stall_d = 1'b1;

                    // Handle entry paging
                    if (entries_left_md)
                        n_entries_offset_d = n_entries_offset_q + N_ENTRY_ANALYZERS;
                end
            end
        end
    end

    always_comb begin
        // Default assignments
        priority_match       = 1'b0;
        priority_error_supr  = 1'b0;
        priority_partial_hit = 1'b0;

        if (en_2stage) begin
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

    // TODO: With the pipeline design this no longer works as intended
    always_comb begin
        had_match = had_match_q;
        match_eid = match_eid_q;

        if (en_2stage && !had_match_q) begin
            for (int i = 0; i < N_ENTRY_ANALYZERS; i++) begin
                if (match_array[i] || (priority_match && partial_match_array[i])) begin
                    had_match = 1'b1;
                    match_eid = i + n_entries_offset_q + md_base;
                    break;
                end
            end
        end else begin
            had_match = 1'b0;
            match_eid = '0;
        end
    end

    for (genvar i = 0; i < N_ENTRY_ANALYZERS; i++) begin : gen_entry_analyzer
        logic [$clog2(N_ENTRIES)-1:0] index;
        logic [63:0] previous_entry_addr;

        // Calculate absolute entry index
        assign index = i + n_entries_offset_q + md_base;

        // Get previous entry full address
        assign previous_entry_addr = index == 0? '0 : entry_data_i[index - 1].addr.base_addr;

        // Instantiate entry analyzer
        rv_iopmp_entry_analyzer #(
            .base_end_addr_t ( base_end_addr_t ),
            .ADDR_WIDTH (ADDR_WIDTH)
        ) i_entry_analyzer (
            .addr_to_check_i        ( payload_2nd_stage.data_to_analyze.address        ),
            .final_addr_to_check_i  ( payload_2nd_stage.data_to_analyze.final_address  ),

            .addr_i                 ( entry_data_i[index].addr  ),
            .previous_entry_addr_i  ( previous_entry_addr   ),
            .mode_i                 ( entry_data_i[index].cfg.a ),

            .match_o                ( match_array[i] ),
            .partial_match_o        ( partial_match_array[i] )
        );

        // Access type logic (READ, WRITE, EXECUTE)
        assign allow_array[i] = |(payload_2nd_stage.data_to_analyze.ttype & {
            entry_data_i[index].cfg.x,
            entry_data_i[index].cfg.w,
            entry_data_i[index].cfg.r
        });

        // Helper
        logic is_read    = (payload_2nd_stage.data_to_analyze.ttype == ACCESS_READ);
        logic is_write   = (payload_2nd_stage.data_to_analyze.ttype == ACCESS_WRITE);
        logic is_exec    = (payload_2nd_stage.data_to_analyze.ttype == ACCESS_EXECUTION);

        logic error_suppression =
            is_read  ? entry_data_i[index].cfg.sere :
            is_write ? entry_data_i[index].cfg.sewe :
            is_exec  ? entry_data_i[index].cfg.sexe : 1'b0;

        assign error_supr_array[i] = match_array[i] & error_suppression;

        // Optionally: interrupt logic
        // assign interrupt_array[i] = match_array[i] & (payload_2nd_stage.data_to_analyze.rw ? entry_data_i[i].cfg.iw : entry_data_i[i].cfg.ir);
    end

    // Sequential Logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            n_entries_offset_q <= '0;

            had_match_q <= 1'b0;
            match_eid_q <= '0;

            stall_q     <= 1'b0;
            payload_2nd_stage_stall_q <= '{default:'0};
        end else begin
            n_entries_offset_q <= n_entries_offset_d;

            had_match_q <= had_match;
            match_eid_q <= match_eid;

            stall_q     <= stall_d;
            payload_2nd_stage_stall_q <= payload_2nd_stage_stall_d;
        end
    end

endmodule