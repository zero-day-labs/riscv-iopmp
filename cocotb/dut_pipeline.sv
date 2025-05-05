
module dut_pipeline #(

) (
    input logic clk_i,
    input logic rst_ni,

    input   logic           valid_i,
    input   logic           ttype_i,
    input   logic [3:0]     rrid_i,
    input   logic [63:0]    address_i,
    input   logic [63:0]    final_address_i,
    output  logic           ready_o
);

    typedef struct packed {
        logic [2:0]   ttype;
        logic [15:0]  rrid;
        logic [63:0]  address;
        logic [63:0]  final_address;
    } checker_data_t;
    
    typedef struct packed {
        logic access;
        logic error;
        logic rw;
    } checker_rslt_t;

    typedef struct packed {
        logic [ 1:0]    ttype;
        logic [ 3:0]    etype;
        logic [15:0]    rrid, eid;
        logic           interrupt, error;
        logic [63:0]    address;
    } error_t;

    typedef struct packed {
        logic [15:0] t;
    } mdcfg_t;
    typedef struct packed {
        logic [62:0] md;
    } srcmd_t;

    typedef struct packed {
        struct packed {
        logic        q;
        } r;
        struct packed {
        logic        q;
        } w;
        struct packed {
        logic        q;
        } x;
        struct packed {
        logic [1:0]  q;
        } a;
        struct packed {
        logic        q;
        } sire;
        struct packed {
        logic        q;
        } siwe;
        struct packed {
        logic        q;
        } sixe;
        struct packed {
        logic        q;
        } sere;
        struct packed {
        logic        q;
        } sewe;
        struct packed {
        logic        q;
        } sexe;
    } entry_cfg_t;
    typedef struct packed {
        logic [31:0] addrl;
        logic [31:0] addrh;
        entry_cfg_t  cfg;
    } entry_t;

    checker_data_t   data;
    assign data.ttype = ttype_i;
    assign data.rrid  = rrid_i;
    assign data.address = address_i;
    assign data.final_address = final_address_i;

    mdcfg_t [8     - 1:0] mdcfg_data;
    srcmd_t [8     - 1:0] srcmd_data;
    entry_t [32    - 1:0] entry_data;

    assign mdcfg_data[0].t = 16'h0002;
    assign mdcfg_data[1].t = 16'h00013;
    assign srcmd_data[0].md = 63'h00000000000003;

    assign entry_data[11].addrl = 32'h0000021F;
    assign entry_data[11].addrh = 32'h00000000;
    assign entry_data[11].cfg.r.q = 1'b1;
    assign entry_data[11].cfg.w.q = 1'b1;
    assign entry_data[11].cfg.x.q = 1'b1;
    assign entry_data[11].cfg.a.q = 2'b11;

    rv_iopmp_checker #(
        .ADDR_WIDTH (64),
        .N_MDS (8),
        .N_RRID(8),
        .N_ENTRIES (32),
        .N_ENTRY_ANALYZERS (8),

        .mdcfg_t (mdcfg_t),       
        .srcmd_t (srcmd_t),       
        .entry_t (entry_t),

        .checker_data_t (checker_data_t),
        .checker_rslt_t (checker_rslt_t),
        .error_t        (error_t)
    ) i_rv_iopmp_checker (
        .clk_i,
        .rst_ni,

        .valid_i,
        .data_i (data),
        .ready_o,

        .rslt_valid_o (),
        .rslt_o (),
        .rslt_ready_i (1'b1),

        .error_o (),
        .error_valid_o (),
        
        .mdcfg_data_i (mdcfg_data),
        .srcmd_data_i (srcmd_data),
        .entry_data_i (entry_data),
        .prio_entry_i (16),

        .global_error_suppressed_i (1'b1)
    );

endmodule
