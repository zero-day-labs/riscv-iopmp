package rv_iopmp_pkg;

    typedef rv_iopmp_reg_pkg::rv_iopmp_reg2hw_mdcfg_reg_t mdcfg_t;

    typedef struct packed {
        logic [62:0] md;
    } srcmd_t;

    typedef rv_iopmp_reg_pkg::rv_iopmp_reg2hw_entry_cfg_reg_t entry_cfg_t;

    typedef struct packed {
        rv_iopmp_reg_pkg::rv_iopmp_reg2hw_entry_addr_reg_t addrl;
        rv_iopmp_reg_pkg::rv_iopmp_reg2hw_entry_addrh_reg_t addrh;
        entry_cfg_t  cfg;
    } entry_t;

    typedef enum logic [1:0] {
        OFF   = 2'b00,
        TOR   = 2'b01,
        NA4   = 2'b10,
        NAPOT = 2'b11
    } mode_t;

endpackage

