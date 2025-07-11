package rv_iopmp_pkg;

    typedef rv_iopmp_reg_pkg::rv_iopmp_reg2hw_mdcfg_reg_t mdcfg_t;

    typedef struct packed {
        logic [62:0] md;
    } srcmd_t;

    typedef rv_iopmp_reg_pkg::rv_iopmp_reg2hw_entry_cfg_reg_t entry_cfg_t;

    typedef struct {
        logic[63:0] base_addr, end_addr;
    } base_end_addr_t;

    typedef struct {
        base_end_addr_t addr;
        entry_cfg_t  cfg;
    } entry_t;

endpackage

