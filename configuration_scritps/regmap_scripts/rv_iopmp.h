// Generated register defines for iopmp

#ifndef _IOPMP_REG_DEFS_
#define _IOPMP_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define IOPMP_PARAM_REG_WIDTH 32

// Indicates the IP version and other vendor details.
#define IOPMP_VERSION_REG_OFFSET 0x0
#define IOPMP_VERSION_VENDOR_MASK 0xffffff
#define IOPMP_VERSION_VENDOR_OFFSET 0
#define IOPMP_VERSION_VENDOR_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_VERSION_VENDOR_MASK, .index = IOPMP_VERSION_VENDOR_OFFSET })
#define IOPMP_VERSION_SPECVER_MASK 0xff
#define IOPMP_VERSION_SPECVER_OFFSET 24
#define IOPMP_VERSION_SPECVER_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_VERSION_SPECVER_MASK, .index = IOPMP_VERSION_SPECVER_OFFSET })

// The implementation ID
#define IOPMP_IMP_REG_OFFSET 0x4

// Indicates the configurations of current IOPMP instance
#define IOPMP_HWCFG0_REG_OFFSET 0x8
#define IOPMP_HWCFG0_MODEL_MASK 0xf
#define IOPMP_HWCFG0_MODEL_OFFSET 0
#define IOPMP_HWCFG0_MODEL_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_HWCFG0_MODEL_MASK, .index = IOPMP_HWCFG0_MODEL_OFFSET })
#define IOPMP_HWCFG0_MODEL_VALUE_FULL 0x0
#define IOPMP_HWCFG0_MODEL_VALUE_RAPID_K 0x1
#define IOPMP_HWCFG0_MODEL_VALUE_DYNAMIC_K 0x2
#define IOPMP_HWCFG0_MODEL_VALUE_ISOLATION 0x3
#define IOPMP_HWCFG0_MODEL_VALUE_COMPACT_K 0x4
#define IOPMP_HWCFG0_TOR_EN_BIT 4
#define IOPMP_HWCFG0_SPS_EN_BIT 5
#define IOPMP_HWCFG0_USER_CFG_EN_BIT 6
#define IOPMP_HWCFG0_PRIENT_PROG_BIT 7
#define IOPMP_HWCFG0_SID_TRANSL_EN_BIT 8
#define IOPMP_HWCFG0_SID_TRANSL_PROG_BIT 9
#define IOPMP_HWCFG0_CHK_X_BIT 10
#define IOPMP_HWCFG0_NO_X_BIT 11
#define IOPMP_HWCFG0_NO_W_BIT 12
#define IOPMP_HWCFG0_STALL_EN_BIT 13
#define IOPMP_HWCFG0_MD_NUM_MASK 0x7f
#define IOPMP_HWCFG0_MD_NUM_OFFSET 24
#define IOPMP_HWCFG0_MD_NUM_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_HWCFG0_MD_NUM_MASK, .index = IOPMP_HWCFG0_MD_NUM_OFFSET })
#define IOPMP_HWCFG0_ENABLE_BIT 31

// Indicates the configurations of current IOPMP instance
#define IOPMP_HWCFG1_REG_OFFSET 0xc
#define IOPMP_HWCFG1_SID_NUM_MASK 0xffff
#define IOPMP_HWCFG1_SID_NUM_OFFSET 0
#define IOPMP_HWCFG1_SID_NUM_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_HWCFG1_SID_NUM_MASK, .index = IOPMP_HWCFG1_SID_NUM_OFFSET })
#define IOPMP_HWCFG1_ENTRY_NUM_MASK 0xffff
#define IOPMP_HWCFG1_ENTRY_NUM_OFFSET 16
#define IOPMP_HWCFG1_ENTRY_NUM_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_HWCFG1_ENTRY_NUM_MASK, .index = IOPMP_HWCFG1_ENTRY_NUM_OFFSET })

// Indicates the configurations of current IOPMP instance
#define IOPMP_HWCFG2_REG_OFFSET 0x10
#define IOPMP_HWCFG2_PRIO_ENTRY_MASK 0xffff
#define IOPMP_HWCFG2_PRIO_ENTRY_OFFSET 0
#define IOPMP_HWCFG2_PRIO_ENTRY_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_HWCFG2_PRIO_ENTRY_MASK, .index = IOPMP_HWCFG2_PRIO_ENTRY_OFFSET })
#define IOPMP_HWCFG2_SID_TRANSL_MASK 0xffff
#define IOPMP_HWCFG2_SID_TRANSL_OFFSET 16
#define IOPMP_HWCFG2_SID_TRANSL_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_HWCFG2_SID_TRANSL_MASK, .index = IOPMP_HWCFG2_SID_TRANSL_OFFSET })

// Indicates the internal address offsets of each table.
#define IOPMP_ENTRY_OFFSET_REG_OFFSET 0x14

// Indicates errors events in the IOPMP IP.
#define IOPMP_ERRREACT_REG_OFFSET 0x18
#define IOPMP_ERRREACT_L_BIT 0
#define IOPMP_ERRREACT_IE_BIT 1
#define IOPMP_ERRREACT_IRE_BIT 4
#define IOPMP_ERRREACT_RRE_MASK 0x7
#define IOPMP_ERRREACT_RRE_OFFSET 5
#define IOPMP_ERRREACT_RRE_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_ERRREACT_RRE_MASK, .index = IOPMP_ERRREACT_RRE_OFFSET })
#define IOPMP_ERRREACT_IWE_BIT 8
#define IOPMP_ERRREACT_RWE_MASK 0x7
#define IOPMP_ERRREACT_RWE_OFFSET 9
#define IOPMP_ERRREACT_RWE_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_ERRREACT_RWE_MASK, .index = IOPMP_ERRREACT_RWE_OFFSET })
#define IOPMP_ERRREACT_PEE_BIT 28
#define IOPMP_ERRREACT_RPE_MASK 0x7
#define IOPMP_ERRREACT_RPE_OFFSET 29
#define IOPMP_ERRREACT_RPE_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_ERRREACT_RPE_MASK, .index = IOPMP_ERRREACT_RPE_OFFSET })

// Lock Register for MDCFG table.
#define IOPMP_MDCFGLCK_REG_OFFSET 0x48
#define IOPMP_MDCFGLCK_L_BIT 0
#define IOPMP_MDCFGLCK_F_MASK 0x7f
#define IOPMP_MDCFGLCK_F_OFFSET 1
#define IOPMP_MDCFGLCK_F_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_MDCFGLCK_F_MASK, .index = IOPMP_MDCFGLCK_F_OFFSET })

// Lock register for entry array.
#define IOPMP_ENTRYLCK_REG_OFFSET 0x4c
#define IOPMP_ENTRYLCK_L_BIT 0
#define IOPMP_ENTRYLCK_F_MASK 0xffff
#define IOPMP_ENTRYLCK_F_OFFSET 1
#define IOPMP_ENTRYLCK_F_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_ENTRYLCK_F_MASK, .index = IOPMP_ENTRYLCK_F_OFFSET })

// Captures more detailed error infomation.
#define IOPMP_ERR_REQINFO_REG_OFFSET 0x60
#define IOPMP_ERR_REQINFO_IP_BIT 0
#define IOPMP_ERR_REQINFO_TTYPE_MASK 0x3
#define IOPMP_ERR_REQINFO_TTYPE_OFFSET 1
#define IOPMP_ERR_REQINFO_TTYPE_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_ERR_REQINFO_TTYPE_MASK, .index = IOPMP_ERR_REQINFO_TTYPE_OFFSET })
#define IOPMP_ERR_REQINFO_ETYPE_MASK 0x7
#define IOPMP_ERR_REQINFO_ETYPE_OFFSET 4
#define IOPMP_ERR_REQINFO_ETYPE_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_ERR_REQINFO_ETYPE_MASK, .index = IOPMP_ERR_REQINFO_ETYPE_OFFSET })

// Indicate the errored SID and entry index.
#define IOPMP_ERR_REQID_REG_OFFSET 0x64
#define IOPMP_ERR_REQID_SID_MASK 0xffff
#define IOPMP_ERR_REQID_SID_OFFSET 0
#define IOPMP_ERR_REQID_SID_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_ERR_REQID_SID_MASK, .index = IOPMP_ERR_REQID_SID_OFFSET })
#define IOPMP_ERR_REQID_EID_MASK 0xffff
#define IOPMP_ERR_REQID_EID_OFFSET 16
#define IOPMP_ERR_REQID_EID_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_ERR_REQID_EID_MASK, .index = IOPMP_ERR_REQID_EID_OFFSET })

// Indicate the errored request address low bits.
#define IOPMP_ERR_REQADDR_REG_OFFSET 0x68

// Indicate the errored request address low bits.
#define IOPMP_ERR_REQADDRH_REG_OFFSET 0x6c

// MDCFG table is a lookup to specify the number of IOPMP entries that is
// associated with each MD.
#define IOPMP_MDCFG_REG_OFFSET 0x800
#define IOPMP_MDCFG_T_MASK 0xffff
#define IOPMP_MDCFG_T_OFFSET 0
#define IOPMP_MDCFG_T_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_MDCFG_T_MASK, .index = IOPMP_MDCFG_T_OFFSET })

// Bitmapped MD enable register low bits.
#define IOPMP_SRCMD_EN_REG_OFFSET 0x1000
#define IOPMP_SRCMD_EN_L_BIT 0
#define IOPMP_SRCMD_EN_MD_MASK 0x7fffffff
#define IOPMP_SRCMD_EN_MD_OFFSET 1
#define IOPMP_SRCMD_EN_MD_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_SRCMD_EN_MD_MASK, .index = IOPMP_SRCMD_EN_MD_OFFSET })

// Bitmapped MD enable register high bits.
#define IOPMP_SRCMD_ENH_REG_OFFSET 0x1004

// IOPMP entrie number  low bits of physical address of protected memory
// region
#define IOPMP_ENTRY_ADDR_REG_OFFSET 0x2000

// IOPMP entrie number  high bits of physical address of protected memory
// region
#define IOPMP_ENTRY_ADDRH_REG_OFFSET 0x2004

// IOPMP entrie number  configuration register.
#define IOPMP_ENTRY_CFG_REG_OFFSET 0x2008
#define IOPMP_ENTRY_CFG_R_BIT 0
#define IOPMP_ENTRY_CFG_W_BIT 1
#define IOPMP_ENTRY_CFG_X_BIT 2
#define IOPMP_ENTRY_CFG_A_MASK 0x3
#define IOPMP_ENTRY_CFG_A_OFFSET 3
#define IOPMP_ENTRY_CFG_A_FIELD \
  ((bitfield_field32_t) { .mask = IOPMP_ENTRY_CFG_A_MASK, .index = IOPMP_ENTRY_CFG_A_OFFSET })

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _IOPMP_REG_DEFS_
// End generated register defines for iopmp