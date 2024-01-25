// Generated register defines for rv_iopmp

#ifndef _RV_IOPMP_REG_DEFS_
#define _RV_IOPMP_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define RV_IOPMP_PARAM_REG_WIDTH 32

// Indicates the IP version and other vendor details.
#define RV_IOPMP_VERSION_REG_OFFSET 0x0
#define RV_IOPMP_VERSION_VENDOR_MASK 0xffffff
#define RV_IOPMP_VERSION_VENDOR_OFFSET 0
#define RV_IOPMP_VERSION_VENDOR_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_VERSION_VENDOR_MASK, .index = RV_IOPMP_VERSION_VENDOR_OFFSET })
#define RV_IOPMP_VERSION_SPECVER_MASK 0xff
#define RV_IOPMP_VERSION_SPECVER_OFFSET 24
#define RV_IOPMP_VERSION_SPECVER_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_VERSION_SPECVER_MASK, .index = RV_IOPMP_VERSION_SPECVER_OFFSET })

// The implementation ID
#define RV_IOPMP_IMP_REG_OFFSET 0x4

// Indicates the configurations of current IOPMP instance
#define RV_IOPMP_HWCFG0_REG_OFFSET 0x8
#define RV_IOPMP_HWCFG0_MODEL_MASK 0xf
#define RV_IOPMP_HWCFG0_MODEL_OFFSET 0
#define RV_IOPMP_HWCFG0_MODEL_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_HWCFG0_MODEL_MASK, .index = RV_IOPMP_HWCFG0_MODEL_OFFSET })
#define RV_IOPMP_HWCFG0_MODEL_VALUE_FULL 0x0
#define RV_IOPMP_HWCFG0_MODEL_VALUE_RAPID_K 0x1
#define RV_IOPMP_HWCFG0_MODEL_VALUE_DYNAMIC_K 0x2
#define RV_IOPMP_HWCFG0_MODEL_VALUE_ISOLATION 0x3
#define RV_IOPMP_HWCFG0_MODEL_VALUE_COMPACT_K 0x4
#define RV_IOPMP_HWCFG0_TOR_EN_BIT 4
#define RV_IOPMP_HWCFG0_SPS_EN_BIT 5
#define RV_IOPMP_HWCFG0_USER_CFG_EN_BIT 6
#define RV_IOPMP_HWCFG0_PRIENT_PROG_BIT 7
#define RV_IOPMP_HWCFG0_SID_TRANSL_EN_BIT 8
#define RV_IOPMP_HWCFG0_SID_TRANSL_PROG_BIT 9
#define RV_IOPMP_HWCFG0_CHK_X_BIT 10
#define RV_IOPMP_HWCFG0_NO_X_BIT 11
#define RV_IOPMP_HWCFG0_NO_W_BIT 12
#define RV_IOPMP_HWCFG0_STALL_EN_BIT 13
#define RV_IOPMP_HWCFG0_MD_NUM_MASK 0x7f
#define RV_IOPMP_HWCFG0_MD_NUM_OFFSET 24
#define RV_IOPMP_HWCFG0_MD_NUM_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_HWCFG0_MD_NUM_MASK, .index = RV_IOPMP_HWCFG0_MD_NUM_OFFSET })
#define RV_IOPMP_HWCFG0_ENABLE_BIT 31

// Indicates the configurations of current IOPMP instance
#define RV_IOPMP_HWCFG1_REG_OFFSET 0xc
#define RV_IOPMP_HWCFG1_SID_NUM_MASK 0xffff
#define RV_IOPMP_HWCFG1_SID_NUM_OFFSET 0
#define RV_IOPMP_HWCFG1_SID_NUM_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_HWCFG1_SID_NUM_MASK, .index = RV_IOPMP_HWCFG1_SID_NUM_OFFSET })
#define RV_IOPMP_HWCFG1_ENTRY_NUM_MASK 0xffff
#define RV_IOPMP_HWCFG1_ENTRY_NUM_OFFSET 16
#define RV_IOPMP_HWCFG1_ENTRY_NUM_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_HWCFG1_ENTRY_NUM_MASK, .index = RV_IOPMP_HWCFG1_ENTRY_NUM_OFFSET })

// Indicates the configurations of current IOPMP instance
#define RV_IOPMP_HWCFG2_REG_OFFSET 0x10
#define RV_IOPMP_HWCFG2_PRIO_ENTRY_MASK 0xffff
#define RV_IOPMP_HWCFG2_PRIO_ENTRY_OFFSET 0
#define RV_IOPMP_HWCFG2_PRIO_ENTRY_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_HWCFG2_PRIO_ENTRY_MASK, .index = RV_IOPMP_HWCFG2_PRIO_ENTRY_OFFSET })
#define RV_IOPMP_HWCFG2_SID_TRANSL_MASK 0xffff
#define RV_IOPMP_HWCFG2_SID_TRANSL_OFFSET 16
#define RV_IOPMP_HWCFG2_SID_TRANSL_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_HWCFG2_SID_TRANSL_MASK, .index = RV_IOPMP_HWCFG2_SID_TRANSL_OFFSET })

// Indicates the internal address offsets of each table.
#define RV_IOPMP_ENTRY_OFFSET_REG_OFFSET 0x14

// Indicates errors events in the IOPMP IP.
#define RV_IOPMP_ERRREACT_REG_OFFSET 0x18
#define RV_IOPMP_ERRREACT_L_BIT 0
#define RV_IOPMP_ERRREACT_IE_BIT 1
#define RV_IOPMP_ERRREACT_IRE_BIT 4
#define RV_IOPMP_ERRREACT_RRE_MASK 0x7
#define RV_IOPMP_ERRREACT_RRE_OFFSET 5
#define RV_IOPMP_ERRREACT_RRE_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ERRREACT_RRE_MASK, .index = RV_IOPMP_ERRREACT_RRE_OFFSET })
#define RV_IOPMP_ERRREACT_IWE_BIT 8
#define RV_IOPMP_ERRREACT_RWE_MASK 0x7
#define RV_IOPMP_ERRREACT_RWE_OFFSET 9
#define RV_IOPMP_ERRREACT_RWE_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ERRREACT_RWE_MASK, .index = RV_IOPMP_ERRREACT_RWE_OFFSET })
#define RV_IOPMP_ERRREACT_PEE_BIT 28
#define RV_IOPMP_ERRREACT_RPE_MASK 0x7
#define RV_IOPMP_ERRREACT_RPE_OFFSET 29
#define RV_IOPMP_ERRREACT_RPE_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ERRREACT_RPE_MASK, .index = RV_IOPMP_ERRREACT_RPE_OFFSET })

// Lock Register for MDCFG table.
#define RV_IOPMP_MDCFGLCK_REG_OFFSET 0x48
#define RV_IOPMP_MDCFGLCK_L_BIT 0
#define RV_IOPMP_MDCFGLCK_F_MASK 0x7f
#define RV_IOPMP_MDCFGLCK_F_OFFSET 1
#define RV_IOPMP_MDCFGLCK_F_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFGLCK_F_MASK, .index = RV_IOPMP_MDCFGLCK_F_OFFSET })

// Lock register for entry array.
#define RV_IOPMP_ENTRYLCK_REG_OFFSET 0x4c
#define RV_IOPMP_ENTRYLCK_L_BIT 0
#define RV_IOPMP_ENTRYLCK_F_MASK 0xffff
#define RV_IOPMP_ENTRYLCK_F_OFFSET 1
#define RV_IOPMP_ENTRYLCK_F_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRYLCK_F_MASK, .index = RV_IOPMP_ENTRYLCK_F_OFFSET })

// Captures more detailed error infomation.
#define RV_IOPMP_ERR_REQINFO_REG_OFFSET 0x60
#define RV_IOPMP_ERR_REQINFO_IP_BIT 0
#define RV_IOPMP_ERR_REQINFO_TTYPE_MASK 0x3
#define RV_IOPMP_ERR_REQINFO_TTYPE_OFFSET 1
#define RV_IOPMP_ERR_REQINFO_TTYPE_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ERR_REQINFO_TTYPE_MASK, .index = RV_IOPMP_ERR_REQINFO_TTYPE_OFFSET })
#define RV_IOPMP_ERR_REQINFO_ETYPE_MASK 0x7
#define RV_IOPMP_ERR_REQINFO_ETYPE_OFFSET 4
#define RV_IOPMP_ERR_REQINFO_ETYPE_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ERR_REQINFO_ETYPE_MASK, .index = RV_IOPMP_ERR_REQINFO_ETYPE_OFFSET })

// Indicate the errored SID and entry index.
#define RV_IOPMP_ERR_REQID_REG_OFFSET 0x64
#define RV_IOPMP_ERR_REQID_SID_MASK 0xffff
#define RV_IOPMP_ERR_REQID_SID_OFFSET 0
#define RV_IOPMP_ERR_REQID_SID_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ERR_REQID_SID_MASK, .index = RV_IOPMP_ERR_REQID_SID_OFFSET })
#define RV_IOPMP_ERR_REQID_EID_MASK 0xffff
#define RV_IOPMP_ERR_REQID_EID_OFFSET 16
#define RV_IOPMP_ERR_REQID_EID_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ERR_REQID_EID_MASK, .index = RV_IOPMP_ERR_REQID_EID_OFFSET })

// Indicate the errored request address low bits.
#define RV_IOPMP_ERR_REQADDR_REG_OFFSET 0x68

// Indicate the errored request address low bits.
#define RV_IOPMP_ERR_REQADDRH_REG_OFFSET 0x6c

// MDCFG table is a lookup to specify the number of IOPMP entries that is
// associated with each MD. (common parameters)
// MDCFG table is a lookup to specify the number of IOPMP entries that is
// associated with each MD.
#define RV_IOPMP_MDCFG_0_REG_OFFSET 0x800
#define RV_IOPMP_MDCFG_0_T_0_MASK 0xffff
#define RV_IOPMP_MDCFG_0_T_0_OFFSET 0
#define RV_IOPMP_MDCFG_0_T_0_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_0_T_0_MASK, .index = RV_IOPMP_MDCFG_0_T_0_OFFSET })
#define RV_IOPMP_MDCFG_0_RES_0_MASK 0xffff
#define RV_IOPMP_MDCFG_0_RES_0_OFFSET 16
#define RV_IOPMP_MDCFG_0_RES_0_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_0_RES_0_MASK, .index = RV_IOPMP_MDCFG_0_RES_0_OFFSET })

// MDCFG table is a lookup to specify the number of IOPMP entries that is
// associated with each MD.
#define RV_IOPMP_MDCFG_1_REG_OFFSET 0x804
#define RV_IOPMP_MDCFG_1_T_1_MASK 0xffff
#define RV_IOPMP_MDCFG_1_T_1_OFFSET 0
#define RV_IOPMP_MDCFG_1_T_1_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_1_T_1_MASK, .index = RV_IOPMP_MDCFG_1_T_1_OFFSET })
#define RV_IOPMP_MDCFG_1_RES_1_MASK 0xffff
#define RV_IOPMP_MDCFG_1_RES_1_OFFSET 16
#define RV_IOPMP_MDCFG_1_RES_1_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_1_RES_1_MASK, .index = RV_IOPMP_MDCFG_1_RES_1_OFFSET })

// MDCFG table is a lookup to specify the number of IOPMP entries that is
// associated with each MD.
#define RV_IOPMP_MDCFG_2_REG_OFFSET 0x808
#define RV_IOPMP_MDCFG_2_T_2_MASK 0xffff
#define RV_IOPMP_MDCFG_2_T_2_OFFSET 0
#define RV_IOPMP_MDCFG_2_T_2_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_2_T_2_MASK, .index = RV_IOPMP_MDCFG_2_T_2_OFFSET })
#define RV_IOPMP_MDCFG_2_RES_2_MASK 0xffff
#define RV_IOPMP_MDCFG_2_RES_2_OFFSET 16
#define RV_IOPMP_MDCFG_2_RES_2_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_2_RES_2_MASK, .index = RV_IOPMP_MDCFG_2_RES_2_OFFSET })

// MDCFG table is a lookup to specify the number of IOPMP entries that is
// associated with each MD.
#define RV_IOPMP_MDCFG_3_REG_OFFSET 0x80c
#define RV_IOPMP_MDCFG_3_T_3_MASK 0xffff
#define RV_IOPMP_MDCFG_3_T_3_OFFSET 0
#define RV_IOPMP_MDCFG_3_T_3_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_3_T_3_MASK, .index = RV_IOPMP_MDCFG_3_T_3_OFFSET })
#define RV_IOPMP_MDCFG_3_RES_3_MASK 0xffff
#define RV_IOPMP_MDCFG_3_RES_3_OFFSET 16
#define RV_IOPMP_MDCFG_3_RES_3_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_3_RES_3_MASK, .index = RV_IOPMP_MDCFG_3_RES_3_OFFSET })

// MDCFG table is a lookup to specify the number of IOPMP entries that is
// associated with each MD.
#define RV_IOPMP_MDCFG_4_REG_OFFSET 0x810
#define RV_IOPMP_MDCFG_4_T_4_MASK 0xffff
#define RV_IOPMP_MDCFG_4_T_4_OFFSET 0
#define RV_IOPMP_MDCFG_4_T_4_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_4_T_4_MASK, .index = RV_IOPMP_MDCFG_4_T_4_OFFSET })
#define RV_IOPMP_MDCFG_4_RES_4_MASK 0xffff
#define RV_IOPMP_MDCFG_4_RES_4_OFFSET 16
#define RV_IOPMP_MDCFG_4_RES_4_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_4_RES_4_MASK, .index = RV_IOPMP_MDCFG_4_RES_4_OFFSET })

// MDCFG table is a lookup to specify the number of IOPMP entries that is
// associated with each MD.
#define RV_IOPMP_MDCFG_5_REG_OFFSET 0x814
#define RV_IOPMP_MDCFG_5_T_5_MASK 0xffff
#define RV_IOPMP_MDCFG_5_T_5_OFFSET 0
#define RV_IOPMP_MDCFG_5_T_5_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_5_T_5_MASK, .index = RV_IOPMP_MDCFG_5_T_5_OFFSET })
#define RV_IOPMP_MDCFG_5_RES_5_MASK 0xffff
#define RV_IOPMP_MDCFG_5_RES_5_OFFSET 16
#define RV_IOPMP_MDCFG_5_RES_5_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_5_RES_5_MASK, .index = RV_IOPMP_MDCFG_5_RES_5_OFFSET })

// MDCFG table is a lookup to specify the number of IOPMP entries that is
// associated with each MD.
#define RV_IOPMP_MDCFG_6_REG_OFFSET 0x818
#define RV_IOPMP_MDCFG_6_T_6_MASK 0xffff
#define RV_IOPMP_MDCFG_6_T_6_OFFSET 0
#define RV_IOPMP_MDCFG_6_T_6_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_6_T_6_MASK, .index = RV_IOPMP_MDCFG_6_T_6_OFFSET })
#define RV_IOPMP_MDCFG_6_RES_6_MASK 0xffff
#define RV_IOPMP_MDCFG_6_RES_6_OFFSET 16
#define RV_IOPMP_MDCFG_6_RES_6_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_6_RES_6_MASK, .index = RV_IOPMP_MDCFG_6_RES_6_OFFSET })

// MDCFG table is a lookup to specify the number of IOPMP entries that is
// associated with each MD.
#define RV_IOPMP_MDCFG_7_REG_OFFSET 0x81c
#define RV_IOPMP_MDCFG_7_T_7_MASK 0xffff
#define RV_IOPMP_MDCFG_7_T_7_OFFSET 0
#define RV_IOPMP_MDCFG_7_T_7_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_7_T_7_MASK, .index = RV_IOPMP_MDCFG_7_T_7_OFFSET })
#define RV_IOPMP_MDCFG_7_RES_7_MASK 0xffff
#define RV_IOPMP_MDCFG_7_RES_7_OFFSET 16
#define RV_IOPMP_MDCFG_7_RES_7_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_MDCFG_7_RES_7_MASK, .index = RV_IOPMP_MDCFG_7_RES_7_OFFSET })

// Bitmapped MD enable register low bits for source 0.
#define RV_IOPMP_SRCMD_EN0_REG_OFFSET 0x1000
#define RV_IOPMP_SRCMD_EN0_L_BIT 0
#define RV_IOPMP_SRCMD_EN0_MD_MASK 0x7fffffff
#define RV_IOPMP_SRCMD_EN0_MD_OFFSET 1
#define RV_IOPMP_SRCMD_EN0_MD_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_SRCMD_EN0_MD_MASK, .index = RV_IOPMP_SRCMD_EN0_MD_OFFSET })

// Bitmapped MD enable register high bits for source 0.
#define RV_IOPMP_SRCMD_ENH0_REG_OFFSET 0x1004

// Bitmapped MD enable register low bits for source 1.
#define RV_IOPMP_SRCMD_EN1_REG_OFFSET 0x1020
#define RV_IOPMP_SRCMD_EN1_L_BIT 0
#define RV_IOPMP_SRCMD_EN1_MD_MASK 0x7fffffff
#define RV_IOPMP_SRCMD_EN1_MD_OFFSET 1
#define RV_IOPMP_SRCMD_EN1_MD_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_SRCMD_EN1_MD_MASK, .index = RV_IOPMP_SRCMD_EN1_MD_OFFSET })

// Bitmapped MD enable register high bits for source 1.
#define RV_IOPMP_SRCMD_ENH1_REG_OFFSET 0x1024

// Bitmapped MD enable register low bits for source 2.
#define RV_IOPMP_SRCMD_EN2_REG_OFFSET 0x1040
#define RV_IOPMP_SRCMD_EN2_L_BIT 0
#define RV_IOPMP_SRCMD_EN2_MD_MASK 0x7fffffff
#define RV_IOPMP_SRCMD_EN2_MD_OFFSET 1
#define RV_IOPMP_SRCMD_EN2_MD_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_SRCMD_EN2_MD_MASK, .index = RV_IOPMP_SRCMD_EN2_MD_OFFSET })

// Bitmapped MD enable register high bits for source 2.
#define RV_IOPMP_SRCMD_ENH2_REG_OFFSET 0x1044

// Bitmapped MD enable register low bits for source 3.
#define RV_IOPMP_SRCMD_EN3_REG_OFFSET 0x1060
#define RV_IOPMP_SRCMD_EN3_L_BIT 0
#define RV_IOPMP_SRCMD_EN3_MD_MASK 0x7fffffff
#define RV_IOPMP_SRCMD_EN3_MD_OFFSET 1
#define RV_IOPMP_SRCMD_EN3_MD_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_SRCMD_EN3_MD_MASK, .index = RV_IOPMP_SRCMD_EN3_MD_OFFSET })

// Bitmapped MD enable register high bits for source 3.
#define RV_IOPMP_SRCMD_ENH3_REG_OFFSET 0x1064

// Bitmapped MD enable register low bits for source 4.
#define RV_IOPMP_SRCMD_EN4_REG_OFFSET 0x1080
#define RV_IOPMP_SRCMD_EN4_L_BIT 0
#define RV_IOPMP_SRCMD_EN4_MD_MASK 0x7fffffff
#define RV_IOPMP_SRCMD_EN4_MD_OFFSET 1
#define RV_IOPMP_SRCMD_EN4_MD_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_SRCMD_EN4_MD_MASK, .index = RV_IOPMP_SRCMD_EN4_MD_OFFSET })

// Bitmapped MD enable register high bits for source 4.
#define RV_IOPMP_SRCMD_ENH4_REG_OFFSET 0x1084

// Bitmapped MD enable register low bits for source 5.
#define RV_IOPMP_SRCMD_EN5_REG_OFFSET 0x10a0
#define RV_IOPMP_SRCMD_EN5_L_BIT 0
#define RV_IOPMP_SRCMD_EN5_MD_MASK 0x7fffffff
#define RV_IOPMP_SRCMD_EN5_MD_OFFSET 1
#define RV_IOPMP_SRCMD_EN5_MD_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_SRCMD_EN5_MD_MASK, .index = RV_IOPMP_SRCMD_EN5_MD_OFFSET })

// Bitmapped MD enable register high bits for source 5.
#define RV_IOPMP_SRCMD_ENH5_REG_OFFSET 0x10a4

// Bitmapped MD enable register low bits for source 6.
#define RV_IOPMP_SRCMD_EN6_REG_OFFSET 0x10c0
#define RV_IOPMP_SRCMD_EN6_L_BIT 0
#define RV_IOPMP_SRCMD_EN6_MD_MASK 0x7fffffff
#define RV_IOPMP_SRCMD_EN6_MD_OFFSET 1
#define RV_IOPMP_SRCMD_EN6_MD_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_SRCMD_EN6_MD_MASK, .index = RV_IOPMP_SRCMD_EN6_MD_OFFSET })

// Bitmapped MD enable register high bits for source 6.
#define RV_IOPMP_SRCMD_ENH6_REG_OFFSET 0x10c4

// Bitmapped MD enable register low bits for source 7.
#define RV_IOPMP_SRCMD_EN7_REG_OFFSET 0x10e0
#define RV_IOPMP_SRCMD_EN7_L_BIT 0
#define RV_IOPMP_SRCMD_EN7_MD_MASK 0x7fffffff
#define RV_IOPMP_SRCMD_EN7_MD_OFFSET 1
#define RV_IOPMP_SRCMD_EN7_MD_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_SRCMD_EN7_MD_MASK, .index = RV_IOPMP_SRCMD_EN7_MD_OFFSET })

// Bitmapped MD enable register high bits for source 7.
#define RV_IOPMP_SRCMD_ENH7_REG_OFFSET 0x10e4

// IOPMP entrie number 0 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR0_REG_OFFSET 0x2000

// IOPMP entrie number 0 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH0_REG_OFFSET 0x2004

// IOPMP entrie number 0 configuration register.
#define RV_IOPMP_ENTRY_CFG0_REG_OFFSET 0x2008
#define RV_IOPMP_ENTRY_CFG0_R_BIT 0
#define RV_IOPMP_ENTRY_CFG0_W_BIT 1
#define RV_IOPMP_ENTRY_CFG0_X_BIT 2
#define RV_IOPMP_ENTRY_CFG0_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG0_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG0_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG0_A_MASK, .index = RV_IOPMP_ENTRY_CFG0_A_OFFSET })

// IOPMP entrie number 1 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR1_REG_OFFSET 0x2010

// IOPMP entrie number 1 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH1_REG_OFFSET 0x2014

// IOPMP entrie number 1 configuration register.
#define RV_IOPMP_ENTRY_CFG1_REG_OFFSET 0x2018
#define RV_IOPMP_ENTRY_CFG1_R_BIT 0
#define RV_IOPMP_ENTRY_CFG1_W_BIT 1
#define RV_IOPMP_ENTRY_CFG1_X_BIT 2
#define RV_IOPMP_ENTRY_CFG1_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG1_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG1_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG1_A_MASK, .index = RV_IOPMP_ENTRY_CFG1_A_OFFSET })

// IOPMP entrie number 2 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR2_REG_OFFSET 0x2020

// IOPMP entrie number 2 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH2_REG_OFFSET 0x2024

// IOPMP entrie number 2 configuration register.
#define RV_IOPMP_ENTRY_CFG2_REG_OFFSET 0x2028
#define RV_IOPMP_ENTRY_CFG2_R_BIT 0
#define RV_IOPMP_ENTRY_CFG2_W_BIT 1
#define RV_IOPMP_ENTRY_CFG2_X_BIT 2
#define RV_IOPMP_ENTRY_CFG2_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG2_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG2_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG2_A_MASK, .index = RV_IOPMP_ENTRY_CFG2_A_OFFSET })

// IOPMP entrie number 3 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR3_REG_OFFSET 0x2030

// IOPMP entrie number 3 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH3_REG_OFFSET 0x2034

// IOPMP entrie number 3 configuration register.
#define RV_IOPMP_ENTRY_CFG3_REG_OFFSET 0x2038
#define RV_IOPMP_ENTRY_CFG3_R_BIT 0
#define RV_IOPMP_ENTRY_CFG3_W_BIT 1
#define RV_IOPMP_ENTRY_CFG3_X_BIT 2
#define RV_IOPMP_ENTRY_CFG3_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG3_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG3_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG3_A_MASK, .index = RV_IOPMP_ENTRY_CFG3_A_OFFSET })

// IOPMP entrie number 4 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR4_REG_OFFSET 0x2040

// IOPMP entrie number 4 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH4_REG_OFFSET 0x2044

// IOPMP entrie number 4 configuration register.
#define RV_IOPMP_ENTRY_CFG4_REG_OFFSET 0x2048
#define RV_IOPMP_ENTRY_CFG4_R_BIT 0
#define RV_IOPMP_ENTRY_CFG4_W_BIT 1
#define RV_IOPMP_ENTRY_CFG4_X_BIT 2
#define RV_IOPMP_ENTRY_CFG4_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG4_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG4_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG4_A_MASK, .index = RV_IOPMP_ENTRY_CFG4_A_OFFSET })

// IOPMP entrie number 5 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR5_REG_OFFSET 0x2050

// IOPMP entrie number 5 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH5_REG_OFFSET 0x2054

// IOPMP entrie number 5 configuration register.
#define RV_IOPMP_ENTRY_CFG5_REG_OFFSET 0x2058
#define RV_IOPMP_ENTRY_CFG5_R_BIT 0
#define RV_IOPMP_ENTRY_CFG5_W_BIT 1
#define RV_IOPMP_ENTRY_CFG5_X_BIT 2
#define RV_IOPMP_ENTRY_CFG5_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG5_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG5_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG5_A_MASK, .index = RV_IOPMP_ENTRY_CFG5_A_OFFSET })

// IOPMP entrie number 6 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR6_REG_OFFSET 0x2060

// IOPMP entrie number 6 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH6_REG_OFFSET 0x2064

// IOPMP entrie number 6 configuration register.
#define RV_IOPMP_ENTRY_CFG6_REG_OFFSET 0x2068
#define RV_IOPMP_ENTRY_CFG6_R_BIT 0
#define RV_IOPMP_ENTRY_CFG6_W_BIT 1
#define RV_IOPMP_ENTRY_CFG6_X_BIT 2
#define RV_IOPMP_ENTRY_CFG6_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG6_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG6_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG6_A_MASK, .index = RV_IOPMP_ENTRY_CFG6_A_OFFSET })

// IOPMP entrie number 7 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR7_REG_OFFSET 0x2070

// IOPMP entrie number 7 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH7_REG_OFFSET 0x2074

// IOPMP entrie number 7 configuration register.
#define RV_IOPMP_ENTRY_CFG7_REG_OFFSET 0x2078
#define RV_IOPMP_ENTRY_CFG7_R_BIT 0
#define RV_IOPMP_ENTRY_CFG7_W_BIT 1
#define RV_IOPMP_ENTRY_CFG7_X_BIT 2
#define RV_IOPMP_ENTRY_CFG7_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG7_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG7_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG7_A_MASK, .index = RV_IOPMP_ENTRY_CFG7_A_OFFSET })

// IOPMP entrie number 8 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR8_REG_OFFSET 0x2080

// IOPMP entrie number 8 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH8_REG_OFFSET 0x2084

// IOPMP entrie number 8 configuration register.
#define RV_IOPMP_ENTRY_CFG8_REG_OFFSET 0x2088
#define RV_IOPMP_ENTRY_CFG8_R_BIT 0
#define RV_IOPMP_ENTRY_CFG8_W_BIT 1
#define RV_IOPMP_ENTRY_CFG8_X_BIT 2
#define RV_IOPMP_ENTRY_CFG8_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG8_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG8_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG8_A_MASK, .index = RV_IOPMP_ENTRY_CFG8_A_OFFSET })

// IOPMP entrie number 9 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR9_REG_OFFSET 0x2090

// IOPMP entrie number 9 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH9_REG_OFFSET 0x2094

// IOPMP entrie number 9 configuration register.
#define RV_IOPMP_ENTRY_CFG9_REG_OFFSET 0x2098
#define RV_IOPMP_ENTRY_CFG9_R_BIT 0
#define RV_IOPMP_ENTRY_CFG9_W_BIT 1
#define RV_IOPMP_ENTRY_CFG9_X_BIT 2
#define RV_IOPMP_ENTRY_CFG9_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG9_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG9_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG9_A_MASK, .index = RV_IOPMP_ENTRY_CFG9_A_OFFSET })

// IOPMP entrie number 10 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR10_REG_OFFSET 0x20a0

// IOPMP entrie number 10 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH10_REG_OFFSET 0x20a4

// IOPMP entrie number 10 configuration register.
#define RV_IOPMP_ENTRY_CFG10_REG_OFFSET 0x20a8
#define RV_IOPMP_ENTRY_CFG10_R_BIT 0
#define RV_IOPMP_ENTRY_CFG10_W_BIT 1
#define RV_IOPMP_ENTRY_CFG10_X_BIT 2
#define RV_IOPMP_ENTRY_CFG10_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG10_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG10_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG10_A_MASK, .index = RV_IOPMP_ENTRY_CFG10_A_OFFSET })

// IOPMP entrie number 11 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR11_REG_OFFSET 0x20b0

// IOPMP entrie number 11 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH11_REG_OFFSET 0x20b4

// IOPMP entrie number 11 configuration register.
#define RV_IOPMP_ENTRY_CFG11_REG_OFFSET 0x20b8
#define RV_IOPMP_ENTRY_CFG11_R_BIT 0
#define RV_IOPMP_ENTRY_CFG11_W_BIT 1
#define RV_IOPMP_ENTRY_CFG11_X_BIT 2
#define RV_IOPMP_ENTRY_CFG11_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG11_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG11_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG11_A_MASK, .index = RV_IOPMP_ENTRY_CFG11_A_OFFSET })

// IOPMP entrie number 12 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR12_REG_OFFSET 0x20c0

// IOPMP entrie number 12 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH12_REG_OFFSET 0x20c4

// IOPMP entrie number 12 configuration register.
#define RV_IOPMP_ENTRY_CFG12_REG_OFFSET 0x20c8
#define RV_IOPMP_ENTRY_CFG12_R_BIT 0
#define RV_IOPMP_ENTRY_CFG12_W_BIT 1
#define RV_IOPMP_ENTRY_CFG12_X_BIT 2
#define RV_IOPMP_ENTRY_CFG12_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG12_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG12_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG12_A_MASK, .index = RV_IOPMP_ENTRY_CFG12_A_OFFSET })

// IOPMP entrie number 13 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR13_REG_OFFSET 0x20d0

// IOPMP entrie number 13 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH13_REG_OFFSET 0x20d4

// IOPMP entrie number 13 configuration register.
#define RV_IOPMP_ENTRY_CFG13_REG_OFFSET 0x20d8
#define RV_IOPMP_ENTRY_CFG13_R_BIT 0
#define RV_IOPMP_ENTRY_CFG13_W_BIT 1
#define RV_IOPMP_ENTRY_CFG13_X_BIT 2
#define RV_IOPMP_ENTRY_CFG13_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG13_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG13_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG13_A_MASK, .index = RV_IOPMP_ENTRY_CFG13_A_OFFSET })

// IOPMP entrie number 14 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR14_REG_OFFSET 0x20e0

// IOPMP entrie number 14 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH14_REG_OFFSET 0x20e4

// IOPMP entrie number 14 configuration register.
#define RV_IOPMP_ENTRY_CFG14_REG_OFFSET 0x20e8
#define RV_IOPMP_ENTRY_CFG14_R_BIT 0
#define RV_IOPMP_ENTRY_CFG14_W_BIT 1
#define RV_IOPMP_ENTRY_CFG14_X_BIT 2
#define RV_IOPMP_ENTRY_CFG14_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG14_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG14_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG14_A_MASK, .index = RV_IOPMP_ENTRY_CFG14_A_OFFSET })

// IOPMP entrie number 15 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR15_REG_OFFSET 0x20f0

// IOPMP entrie number 15 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH15_REG_OFFSET 0x20f4

// IOPMP entrie number 15 configuration register.
#define RV_IOPMP_ENTRY_CFG15_REG_OFFSET 0x20f8
#define RV_IOPMP_ENTRY_CFG15_R_BIT 0
#define RV_IOPMP_ENTRY_CFG15_W_BIT 1
#define RV_IOPMP_ENTRY_CFG15_X_BIT 2
#define RV_IOPMP_ENTRY_CFG15_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG15_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG15_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG15_A_MASK, .index = RV_IOPMP_ENTRY_CFG15_A_OFFSET })

// IOPMP entrie number 16 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR16_REG_OFFSET 0x2100

// IOPMP entrie number 16 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH16_REG_OFFSET 0x2104

// IOPMP entrie number 16 configuration register.
#define RV_IOPMP_ENTRY_CFG16_REG_OFFSET 0x2108
#define RV_IOPMP_ENTRY_CFG16_R_BIT 0
#define RV_IOPMP_ENTRY_CFG16_W_BIT 1
#define RV_IOPMP_ENTRY_CFG16_X_BIT 2
#define RV_IOPMP_ENTRY_CFG16_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG16_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG16_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG16_A_MASK, .index = RV_IOPMP_ENTRY_CFG16_A_OFFSET })

// IOPMP entrie number 17 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR17_REG_OFFSET 0x2110

// IOPMP entrie number 17 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH17_REG_OFFSET 0x2114

// IOPMP entrie number 17 configuration register.
#define RV_IOPMP_ENTRY_CFG17_REG_OFFSET 0x2118
#define RV_IOPMP_ENTRY_CFG17_R_BIT 0
#define RV_IOPMP_ENTRY_CFG17_W_BIT 1
#define RV_IOPMP_ENTRY_CFG17_X_BIT 2
#define RV_IOPMP_ENTRY_CFG17_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG17_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG17_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG17_A_MASK, .index = RV_IOPMP_ENTRY_CFG17_A_OFFSET })

// IOPMP entrie number 18 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR18_REG_OFFSET 0x2120

// IOPMP entrie number 18 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH18_REG_OFFSET 0x2124

// IOPMP entrie number 18 configuration register.
#define RV_IOPMP_ENTRY_CFG18_REG_OFFSET 0x2128
#define RV_IOPMP_ENTRY_CFG18_R_BIT 0
#define RV_IOPMP_ENTRY_CFG18_W_BIT 1
#define RV_IOPMP_ENTRY_CFG18_X_BIT 2
#define RV_IOPMP_ENTRY_CFG18_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG18_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG18_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG18_A_MASK, .index = RV_IOPMP_ENTRY_CFG18_A_OFFSET })

// IOPMP entrie number 19 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR19_REG_OFFSET 0x2130

// IOPMP entrie number 19 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH19_REG_OFFSET 0x2134

// IOPMP entrie number 19 configuration register.
#define RV_IOPMP_ENTRY_CFG19_REG_OFFSET 0x2138
#define RV_IOPMP_ENTRY_CFG19_R_BIT 0
#define RV_IOPMP_ENTRY_CFG19_W_BIT 1
#define RV_IOPMP_ENTRY_CFG19_X_BIT 2
#define RV_IOPMP_ENTRY_CFG19_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG19_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG19_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG19_A_MASK, .index = RV_IOPMP_ENTRY_CFG19_A_OFFSET })

// IOPMP entrie number 20 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR20_REG_OFFSET 0x2140

// IOPMP entrie number 20 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH20_REG_OFFSET 0x2144

// IOPMP entrie number 20 configuration register.
#define RV_IOPMP_ENTRY_CFG20_REG_OFFSET 0x2148
#define RV_IOPMP_ENTRY_CFG20_R_BIT 0
#define RV_IOPMP_ENTRY_CFG20_W_BIT 1
#define RV_IOPMP_ENTRY_CFG20_X_BIT 2
#define RV_IOPMP_ENTRY_CFG20_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG20_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG20_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG20_A_MASK, .index = RV_IOPMP_ENTRY_CFG20_A_OFFSET })

// IOPMP entrie number 21 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR21_REG_OFFSET 0x2150

// IOPMP entrie number 21 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH21_REG_OFFSET 0x2154

// IOPMP entrie number 21 configuration register.
#define RV_IOPMP_ENTRY_CFG21_REG_OFFSET 0x2158
#define RV_IOPMP_ENTRY_CFG21_R_BIT 0
#define RV_IOPMP_ENTRY_CFG21_W_BIT 1
#define RV_IOPMP_ENTRY_CFG21_X_BIT 2
#define RV_IOPMP_ENTRY_CFG21_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG21_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG21_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG21_A_MASK, .index = RV_IOPMP_ENTRY_CFG21_A_OFFSET })

// IOPMP entrie number 22 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR22_REG_OFFSET 0x2160

// IOPMP entrie number 22 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH22_REG_OFFSET 0x2164

// IOPMP entrie number 22 configuration register.
#define RV_IOPMP_ENTRY_CFG22_REG_OFFSET 0x2168
#define RV_IOPMP_ENTRY_CFG22_R_BIT 0
#define RV_IOPMP_ENTRY_CFG22_W_BIT 1
#define RV_IOPMP_ENTRY_CFG22_X_BIT 2
#define RV_IOPMP_ENTRY_CFG22_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG22_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG22_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG22_A_MASK, .index = RV_IOPMP_ENTRY_CFG22_A_OFFSET })

// IOPMP entrie number 23 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR23_REG_OFFSET 0x2170

// IOPMP entrie number 23 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH23_REG_OFFSET 0x2174

// IOPMP entrie number 23 configuration register.
#define RV_IOPMP_ENTRY_CFG23_REG_OFFSET 0x2178
#define RV_IOPMP_ENTRY_CFG23_R_BIT 0
#define RV_IOPMP_ENTRY_CFG23_W_BIT 1
#define RV_IOPMP_ENTRY_CFG23_X_BIT 2
#define RV_IOPMP_ENTRY_CFG23_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG23_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG23_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG23_A_MASK, .index = RV_IOPMP_ENTRY_CFG23_A_OFFSET })

// IOPMP entrie number 24 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR24_REG_OFFSET 0x2180

// IOPMP entrie number 24 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH24_REG_OFFSET 0x2184

// IOPMP entrie number 24 configuration register.
#define RV_IOPMP_ENTRY_CFG24_REG_OFFSET 0x2188
#define RV_IOPMP_ENTRY_CFG24_R_BIT 0
#define RV_IOPMP_ENTRY_CFG24_W_BIT 1
#define RV_IOPMP_ENTRY_CFG24_X_BIT 2
#define RV_IOPMP_ENTRY_CFG24_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG24_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG24_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG24_A_MASK, .index = RV_IOPMP_ENTRY_CFG24_A_OFFSET })

// IOPMP entrie number 25 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR25_REG_OFFSET 0x2190

// IOPMP entrie number 25 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH25_REG_OFFSET 0x2194

// IOPMP entrie number 25 configuration register.
#define RV_IOPMP_ENTRY_CFG25_REG_OFFSET 0x2198
#define RV_IOPMP_ENTRY_CFG25_R_BIT 0
#define RV_IOPMP_ENTRY_CFG25_W_BIT 1
#define RV_IOPMP_ENTRY_CFG25_X_BIT 2
#define RV_IOPMP_ENTRY_CFG25_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG25_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG25_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG25_A_MASK, .index = RV_IOPMP_ENTRY_CFG25_A_OFFSET })

// IOPMP entrie number 26 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR26_REG_OFFSET 0x21a0

// IOPMP entrie number 26 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH26_REG_OFFSET 0x21a4

// IOPMP entrie number 26 configuration register.
#define RV_IOPMP_ENTRY_CFG26_REG_OFFSET 0x21a8
#define RV_IOPMP_ENTRY_CFG26_R_BIT 0
#define RV_IOPMP_ENTRY_CFG26_W_BIT 1
#define RV_IOPMP_ENTRY_CFG26_X_BIT 2
#define RV_IOPMP_ENTRY_CFG26_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG26_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG26_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG26_A_MASK, .index = RV_IOPMP_ENTRY_CFG26_A_OFFSET })

// IOPMP entrie number 27 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR27_REG_OFFSET 0x21b0

// IOPMP entrie number 27 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH27_REG_OFFSET 0x21b4

// IOPMP entrie number 27 configuration register.
#define RV_IOPMP_ENTRY_CFG27_REG_OFFSET 0x21b8
#define RV_IOPMP_ENTRY_CFG27_R_BIT 0
#define RV_IOPMP_ENTRY_CFG27_W_BIT 1
#define RV_IOPMP_ENTRY_CFG27_X_BIT 2
#define RV_IOPMP_ENTRY_CFG27_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG27_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG27_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG27_A_MASK, .index = RV_IOPMP_ENTRY_CFG27_A_OFFSET })

// IOPMP entrie number 28 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR28_REG_OFFSET 0x21c0

// IOPMP entrie number 28 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH28_REG_OFFSET 0x21c4

// IOPMP entrie number 28 configuration register.
#define RV_IOPMP_ENTRY_CFG28_REG_OFFSET 0x21c8
#define RV_IOPMP_ENTRY_CFG28_R_BIT 0
#define RV_IOPMP_ENTRY_CFG28_W_BIT 1
#define RV_IOPMP_ENTRY_CFG28_X_BIT 2
#define RV_IOPMP_ENTRY_CFG28_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG28_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG28_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG28_A_MASK, .index = RV_IOPMP_ENTRY_CFG28_A_OFFSET })

// IOPMP entrie number 29 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR29_REG_OFFSET 0x21d0

// IOPMP entrie number 29 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH29_REG_OFFSET 0x21d4

// IOPMP entrie number 29 configuration register.
#define RV_IOPMP_ENTRY_CFG29_REG_OFFSET 0x21d8
#define RV_IOPMP_ENTRY_CFG29_R_BIT 0
#define RV_IOPMP_ENTRY_CFG29_W_BIT 1
#define RV_IOPMP_ENTRY_CFG29_X_BIT 2
#define RV_IOPMP_ENTRY_CFG29_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG29_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG29_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG29_A_MASK, .index = RV_IOPMP_ENTRY_CFG29_A_OFFSET })

// IOPMP entrie number 30 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR30_REG_OFFSET 0x21e0

// IOPMP entrie number 30 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH30_REG_OFFSET 0x21e4

// IOPMP entrie number 30 configuration register.
#define RV_IOPMP_ENTRY_CFG30_REG_OFFSET 0x21e8
#define RV_IOPMP_ENTRY_CFG30_R_BIT 0
#define RV_IOPMP_ENTRY_CFG30_W_BIT 1
#define RV_IOPMP_ENTRY_CFG30_X_BIT 2
#define RV_IOPMP_ENTRY_CFG30_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG30_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG30_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG30_A_MASK, .index = RV_IOPMP_ENTRY_CFG30_A_OFFSET })

// IOPMP entrie number 31 low bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDR31_REG_OFFSET 0x21f0

// IOPMP entrie number 31 high bits of physical address of protected memory
// region
#define RV_IOPMP_ENTRY_ADDRH31_REG_OFFSET 0x21f4

// IOPMP entrie number 31 configuration register.
#define RV_IOPMP_ENTRY_CFG31_REG_OFFSET 0x21f8
#define RV_IOPMP_ENTRY_CFG31_R_BIT 0
#define RV_IOPMP_ENTRY_CFG31_W_BIT 1
#define RV_IOPMP_ENTRY_CFG31_X_BIT 2
#define RV_IOPMP_ENTRY_CFG31_A_MASK 0x3
#define RV_IOPMP_ENTRY_CFG31_A_OFFSET 3
#define RV_IOPMP_ENTRY_CFG31_A_FIELD \
  ((bitfield_field32_t) { .mask = RV_IOPMP_ENTRY_CFG31_A_MASK, .index = RV_IOPMP_ENTRY_CFG31_A_OFFSET })

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _RV_IOPMP_REG_DEFS_
// End generated register defines for rv_iopmp