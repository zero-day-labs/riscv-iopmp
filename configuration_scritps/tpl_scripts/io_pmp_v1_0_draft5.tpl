# I/OPMP register template
# Parameter (given by python tool)
#  - version            :    Version number
#  - enable_tor         :    Enable TOR support
#  - enable_sps         :    Enable Secondary permission settings support
#  - enable_usr_cfg     :    Enable user customized attributes support
#  - enable_prog_prient :    Enable programmable prio_entry support
#  - enable_mdstall     :    Enable optional register MDSTALL - TODO
#  - enable_sidcsp      :    Enable optional register SIDSCP  - TODO
#  - enable_mdlck       :    Enable optional register MDSTALL - TODO
#  - model              :    Indicate the model:
#                             - 0x0: Full model: the number of MDCFG registers is equal to HWCFG.md_num,
#                                    all MDCFG registers are readable and writable.
#                             - 0x1: Rapid-k model: a single MDCFG register to indicate the k value,
#                                    read only.
#                             - 0x2: Dynamic-k model: a single MDCFG register to indicate the k value,
#                                    readable and writable.
#                             - 0x3: Isolation model: the number of MDCFG registers is equal to
#                                    HWCFG.md_num, all MDCFG registers are readable and writable.
#                             - 0x4 Compact-k model: a single MDCFG register to indicate the k value,
#                                   read only.
#  - entry_offset       :    Offset address of the IOPMP array
#  - nr_mds        :    Number of Memory Domains
#  - nr_entries         :    Number of PMP entries per Domain
#  - nr_sources         :    Number of Masters

{
	name: "rv_iopmp",
    clock_primary: "clk_i",
	reset_primary: "rst_ni",
	bus_interfaces: [{
	    protocol: "reg_iface",
	    direction: "device"
    }],
    regwidth: "32",
	registers: [
        # Info Registers
        {
            name: "VERSION",
            desc: "Indicates the IP version and other vendor details.",
            swaccess: "ro",
            hwaccess: "none",
            fields: [
                {
                    bits: "23:0",
                    name: "vendor",
                    desc: "The vendor ID.",
                    resval: "0"
                }
                {
                    bits: "31:24",
                    name: "specver",
                    desc: "The specification version.",
                    resval: "${version}"
                }
            ]
        },
        {
            name: "IMP",
            desc: "The implementation ID",
            swaccess: "ro",
            hwaccess: "none",
            fields: [
                {
                    bits: "31:0",
                    name: "impid",
                    desc: "The implementation ID.",
                    resval: "0"
                }
            ]
        },
        {
            name: "HWCFG0",
            desc: "Indicates the configurations of current IOPMP instance",
            swaccess: "rw",
            hwaccess: "hrw",
            fields: [
                {
                    bits: "3:0",
                    name: "model",
                    swaccess: "ro",
                    hwaccess: "none",
                    desc: "Indicate the iopmp instance model",
                    resval: "${model}",
                    enum: [
                        { value: "0",
                          name: "Full",
                          desc: '''
                            The number of MDCFG registers is equal to HWCFG.md_num,
                            all MDCFG registers are readable and writable
                          ''' 
                        },
                        { value: "1",
                          name: "Rapid-k",
                          desc: '''
                            A single MDCFG register to indicate the k value, read only
                          ''' 
                        },
                        { value: "2",
                          name: "Dynamic-k",
                          desc: '''
                            A single MDCFG register to indicate the k value, readable and writable.
                          ''' 
                        },
                        { value: "3",
                          name: "Isolation",
                          desc: '''
                            the number of MDCFG registers is equal to HWCFG.md_num,
                            all MDCFG registers are readable and writable.
                          ''' 
                        },
                        { value: "4",
                          name: "Compact-k",
                          desc: '''
                            a single MDCFG register to indicate the k value, read only.
                          ''' 
                        },
                    ]
                }
                {
                    bits: "4",
                    name: "tor_en",
                    swaccess: "ro",
                    hwaccess: "none",
                    desc: "Indicate if TOR is supported.",
                    resval: "${enable_tor}"
                }
                {
                    bits: "5",
                    name: "sps_en",
                    swaccess: "ro",
                    hwaccess: "none",
                    desc: "Indicate the secondary permission settings is supported.",
                    resval: "${enable_sps}"
                }
                {
                    bits: "6",
                    name: "user_cfg_en",
                    swaccess: "ro",
                    hwaccess: "none",
                    desc: "Indicate the if user customized attributes is supported.",
                    resval: "0"
                }
                {
                    bits: "7",
                    name: "prient_prog",
                    swaccess: "rw1cs",
                    hwaccess: "none",
                    desc: "A sticky bit to indicate if prio_entry is programmable.",
                    resval: "1"
                }
                {
                    bits: "8",
                    name: "sid_transl_en",
                    swaccess: "ro",
                    hwaccess: "none",
                    desc: "Indicate the if tagging a new SID on the initiator port is supported",
                    resval: "0"
                }
                {
                    bits: "9",
                    name: "sid_transl_prog",
                    swaccess: "ro",
                    hwaccess: "none",
                    desc: "A sticky bit to indicate if sid_transl is programmable.",
                    resval: "0"
                }
                {
                    bits: "10",
                    name: "chk_x",
                    swaccess: "ro",
                    hwaccess: "hro",
                    desc: "Indicate if the IOPMP checks execution violations",
                    resval: "0"
                }
                {
                    bits: "11",
                    name: "no_x",
                    swaccess: "ro",
                    hwaccess: "hro",
                    desc: '''For chk_x=1, the IOPMP with no_x=1 always fails 
                        execution transactions; otherwise, it should depend
                        on the per-entry x-bit. For chk_x=0, no_x has no
                        effect.''',
                    resval: "0"
                }
                {
                    bits: "12",
                    name: "no_w",
                    swaccess: "ro",
                    hwaccess: "hro",
                    desc: "Indicate if the IOPMP always fails write transactions",
                    resval: "0"
                }
                {
                    bits: "13",
                    name: "stall_en",
                    swaccess: "ro",
                    hwaccess: "none",
                    desc: '''Indicate if the IOPMP implements stall-related
                        features, which are MDSTALL, MDSTALLH, and
                        SIDSCP registers.''',
                    resval: "0"
                }
                {
                    bits: "30:24",
                    name: "md_num",
                    desc: "Indicate the supported number of MD in the instance.",
                    swaccess: "ro",
                    hwaccess: "none",
                    resval: "${nr_mds}"
                }
                {
                    bits: "31",
                    name: "enable",
                    swaccess: "rw1ss",
                    hwaccess: "hro",
                    desc: '''
                        Indicate if the IOPMP checks transactions. If it is implemented,
                        it should be initial to 0 and sticky to 1. If it is not implemented,
                        it should be wired to 1.
                    ''',
                    resval: "0"
                }
            ]
        },
        {
            name: "HWCFG1",
            desc: "Indicates the configurations of current IOPMP instance",
            swaccess: "ro",
            hwaccess: "none",
            fields: [
                {
                    bits: "15:0",
                    name: "sid_num",
                    swaccess: "ro",
                    hwaccess: "none",
                    desc: "Indicate the supported number of SID in the instance.",
                    resval: "${nr_sources}"
                }
                {
                    bits: "31:16",
                    name: "entry_num",
                    swaccess: "ro",
                    hwaccess: "none",
                    desc: "Indicate the supported number of entries in the instance.",
                    resval: "${nr_entries}"
                }
            ]
        },
        {
            name: "HWCFG2",
            desc: "Indicates the configurations of current IOPMP instance",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "15:0",
                    name: "prio_entry",
                    desc: '''
                        Indicate the number of entries matched with priority.
                        These rules should be placed in the lowest order.
                        Within these rules, the lower order has a higher priority.
                    ''',
                    resval: "0"
                }
                {
                    bits: "31:16",
                    name: "sid_transl",
                    desc: "The SID tagged to outgoing transactions. Support only for sid_transl_en=1.",
                    resval: "0"
                }
            ]
        },
        {
            name: "ENTRY_OFFSET",
            desc: "Indicates the internal address offsets of each table.",
            swaccess: "ro",
            hwaccess: "hro",
            fields: [
                {
                    bits: "31:0",
                    name: "OFFSET",
                    desc: '''
                    Indicate the offset address of the IOPMP array from the base of an IOPMP instance. Can be a signed value.
                    ''',
                    resval: "${entry_offset}"
                }
            ]
        },
        {
            name: "ERRREACT",
            desc: "Indicates errors events in the IOPMP IP.",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "0",
                    name: "l",
                    swaccess: "rw1ss",
                    hwaccess: "hro",
                    desc: "Lock fields to ERRREACT register except ip.",
                    resval: "0"
                }
                {
                    bits: "1",
                    name: "ie",
                    desc: "Enable the interrupt of the IOPMP.",
                    resval: "0"
                }
                {
                    bits: "4",
                    name: "ire",
                    desc: "To trigger the interrupt on illegal read if ie = 1",
                    resval: "0"
                }
                {
                    bits: "7:5",
                    name: "rre",
                    desc: '''
                        Response on read illegal access: 
                        - 0x0: respond a bus error
                        - 0x1: respond a decode error
                        - 0x2: respond a success with data, all of which are zeros.
                        - 0x3: respond a success with data, all of which are ones.
                        - 0x4~0x7: user defined
                    ''',
                    resval: "0"
                }
                {
                    bits: "8",
                    name: "iwe",
                    desc: "To trigger the interrupt on illegal write if ie = 1",
                    resval: "0"
                }
                {
                    bits: "11:9",
                    name: "rwe",
                    desc: '''
                        Response on write illegal access: 
                        - 0x0: respond a bus error
                        - 0x1: respond a decode error
                        - 0x2: respond a success
                        - 0x3~0x7: user defined
                    ''',
                    resval: "0"
                }
                # {
                #     bits: "27:12",
                #     name: "rsv",
                #     swaccess: "ro",
                #     hwaccess: "hro",
                #     desc: "Must be zero, reserved for future",
                #     resval: "0"
                # }
                {
                    bits: "28",
                    name: "pee",
                    desc: "Enable to differentiate between a prefetch access and an illegal access",
                    resval: "0"
                }
                {
                    bits: "31:29",
                    name: "rpe",
                    desc: '''
                        Response on prefetch illegal access: 
                        - 0x0: respond a bus error
                        - 0x1: respond a decode error
                        - 0x2~0x7: user defined
                    ''',
                    resval: "0"
                }
            ]
        },
        # Programming Protection Registers
        % if enable_mdstall == 1 :
        {skipto: "0x30"},
        {
            name: "MDSTALL",
            desc: '''
                The MDSTALL(H) is implemented to support atomicity issue while programming the IOPMP,
                as the IOPMP rule may not be updated in a single transaction.
            ''',
            swaccess: "ro",
            hwaccess: "hrw",
            fields: [
                {
                    bits: "0:0",
                    name: "exempt_is_stalled",
                    desc: '''
                        | Field      | Bit   | R/W |                   Description                      | 
                        | exempt     | 0:0   | W   | 0: query, 1: stall transactions associated with    | 
                        |            |       |     | selected SID, 2: don’t stall transactions          |
                        |            |       |     | associated with selected SID, and 3: reserved      |
                        | stat       | 31:30 | R   | 0: SIDSCP not implemented, 1: transactions         |
                        |            |       |     | associated with selected SID are stalled, 2:       |
                        |            |       |     | transactions associated with selected SID not are  |
                        |            |       |     | stalled, and 3: unimplemented or unselectable SID  |
                    ''',
                    resval: "0"
                }
                {
                    bits: "31:1",
                    name: "md",
                    desc: '''
                        setting MD[i]=1 selects MD i.
                        MD[i]=1 means MD i selected
                    ''',
                    resval: "0"
                }
            ]
        },
        {
            name: "MDSTALLH",
            desc: '''
                The MDSTALL(H) is implemented to support atomicity issue while programming the IOPMP,
                as the IOPMP rule may not be updated in a single transaction.
            ''',
            swaccess: "ro",
            hwaccess: "hrw",
            fields: [
                {
                    bits: "30:0",
                    name: "md",
                    desc: '''
                        setting MD[i]=1 selects MD i.
                        MD[i]=1 means MD i selected.
                    ''',
                    resval: "0"
                }
            ]
        },
        % endif
        % if enable_sidcsp == 1 :
        {skipto: "0x38"},
        {
            name: "SIDSCP",
            desc: '''
                The SIDSCP is implemented to support atomicity issue while programming the IOPMP,
                as the IOPMP rule may not be updated in a single transaction.
            ''',
            swaccess: "ro",
            hwaccess: "hrw",
            fields: [
                {
                    bits: "15:0",
                    name: "sid",
                    desc: "SID to select",
                    resval: "0"
                }
                {
                    bits: "31:30",
                    name: "op_stat",
                    desc: '''
                        | Field      | Bit   | R/W |                   Description                      | 
                        | op         | 31:30 | W   | 0: query, 1: stall transactions associated with    | 
                        |            |       |     | selected SID, 2: don’t stall transactions          |
                        |            |       |     | associated with selected SID, and 3: reserved      |
                        | stat       | 31:30 | R   | 0: SIDSCP not implemented, 1: transactions         |
                        |            |       |     | associated with selected SID are stalled, 2:       |
                        |            |       |     | transactions associated with selected SID not are  |
                        |            |       |     | stalled, and 3: unimplemented or unselectable SID  |
                    ''',
                    resval: "0"
                }
            ]
        },
        %endif

        # Configuration Protection Registers
        % if enable_mdlck == 1 :
        {skipto: "0x40"},
        { 
            name: "MDLCK",
            desc: "Bitmap field register low bits to indicate which MDs are locked.",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "0",
                    name: "l",
                    swaccess: "rw1ss",
                    hwaccess: "hro",
                    desc: "Lock bit to MDLCK and MDLCKH register.",
                    resval: "0"
                }
                {
                    bits: "31:1",
                    name: "md",
                    desc: "md[j] indicates if MD j in SRCiMD is locked for all i.",
                    resval: "0"
                }
            ]
        },
        { 
            name: "MDLCKH",
            desc: "Bitmap field register high bits to indicate which MDs are locked.",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "31:0",
                    name: "mdh",
                    desc: "md[j] indicates if MD j in SRCiMD is locked for all i.",
                    resval: "0"
                }
            ]
        },
        % endif
        {skipto: "0x48"},
        { 
            name: "MDCFGLCK",
            desc: "Lock Register for MDCFG table.",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "0",
                    name: "l",
                    swaccess: "rw1ss",
                    hwaccess: "hro",
                    desc: "Lock bit to MDLCK and MDLCKH register",
                    resval: "0"
                }
                {
                    bits: "7:1",
                    name: "f",
                    swaccess: "rw",
                    hwaccess: "hro",
                    desc: '''
                        Indicate the number of locked MDCFG entries,
                        MDCFG entry[f-1:0] is locked. SW shall write
                        a value that is no smaller than current number.
                        ''',
                    resval: "0"
                }
            ]
        },
        {skipto: "0x4C"},
        { 
            name: "ENTRYLCK",
            desc: "Lock register for entry array.",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "0",
                    name: "l",
                    swaccess: "rw1ss",
                    hwaccess: "hro",
                    desc: "Lock bit to ENTRYLCK register.",
                    resval: "0"
                }
                {
                    bits: "16:1",
                    name: "f",
                    swaccess: "rw",
                    hwaccess: "hro",
                    desc: '''
                        Indicate the number of locked IOPMP entries
                        IOPMP_ENTRY[f-1:0] is locked.
                        SW shall write a value that is no smaller than current number.
                    ''',
                    resval: "0"
                }
            ]
        },
        # Error Capture Registers
        {skipto: "0x60"},
        { 
            name: "ERR_REQINFO",
            desc: "Captures more detailed error infomation.",
            swaccess: "rw",
            hwaccess: "hrw",
            fields: [
                {
                    bits: "0",
                    name: "ip",
                    swaccess: "rw1c",
                    hwaccess: "hrw",
                    desc: '''
                        | Field      | Bit   | R/W |                   Description                       | 
                        | ip         | 31:30 | W   | Write 1 clears the bit and the illegal recorder     |
                        |            |       |     | reactivates. Write 0 causes no effect on the bit.   |
                        | ip         | 31:30 | R   | Indicate if an interrupt is pending on read. for 1, | 
                        |            |       |     |  the illegal capture recorder (ERR_REQID,           |
                        |            |       |     |  ERR_REQADDR, ERR_REQADDRH, and fields in this      |
                        |            |       |     |  register) has valid content and won’t be updated   |
                        |            |       |     |  even on subsequent violations.                     |
                    ''',
                    resval: "0"
                }
                {
                    bits: "2:1",
                    name: "ttype",
                    swaccess: "ro",
                    hwaccess: "hrw",
                    desc: '''Indicated the transaction type
                                • 0x00 = reserved
                                • 0x01 = read
                                • 0x02 = write
                                • 0x03 = execution
                        ''',
                    resval: "0"
                }
                {
                    bits: "6:4",
                    name: "etype",
                    swaccess: "ro",
                    hwaccess: "hrw",
                    desc: '''
                        Indicated if it’s a read, write or user field violation.
                        - 0x0 = read error
                        - 0x1 = write error
                        - 0x3 = user_attr error.
                        - 0x04 = partial hit on a priority rule
                        - 0x05 = not hit any rule
                        - 0x06 = unknown SID
                        - 0x07 = user-defined error
                    ''',
                    resval: "0"
                }
            ]
        },
        { 
            name: "ERR_REQID",
            desc: "Indicate the errored SID and entry index.",
            swaccess: "ro",
            hwaccess: "hrw",
            fields: [
                {
                    bits: "15:0",
                    name: "sid",
                    desc: "Indicate the errored SID.",
                    resval: "0"
                }
                {
                    bits: "31:16",
                    name: "eid",
                    desc: "Indicate the errored entry index.",
                    resval: "0"
                }
            ]
        },
        { 
            name: "ERR_REQADDR",
            desc: "Indicate the errored request address low bits.",
            swaccess: "ro",
            hwaccess: "hrw",
            fields: [
                {
                    bits: "31:0",
                    name: "addr",
                    desc: "Indicate the errored address low bits.",
                    resval: "0"
                }
            ]
        },
        { 
            name: "ERR_REQADDRH",
            desc: "Indicate the errored request address low bits.",
            swaccess: "ro",
            hwaccess: "hrw",
            fields: [
                {
                    bits: "31:0",
                    name: "addrh",
                    desc: "Indicate the errored address high bits.",
                    resval: "0"
                }
            ]
        },
        
        # MDCFG Table
        { skipto: "0x800" },
        % if model == 0 or model == 3 :
        {
            multireg : {
                name: "MDCFG",
                desc: "MDCFG table is a lookup to specify the number of IOPMP entries that is associated with each MD.",
                count: "${nr_mds}",
                cname: "IOPMP",
                swaccess: "rw",
                hwaccess: "hro",
                fields: [
                    {
                        bits: "15:0",
                        name: "t",
                        desc: ''' 
                            - Indicate the top range of memory domain m. An IOPMP entry with index j belongs to MD m
                            - If MDCFG(m-1).t ≤ j < MDCFG(m).t, where m>0. The MD0 owns the IOPMP entries with index j<MD0CFG.t.
                            - If MDCFG(m-1).t >= MDCFG(m).t, then MD m is empty.
                            - For rapid-k, dynamic-k and compact-k models, t indicates the number of IOPMP entries belongs to each MD.
                        ''',
                        resval: "0"
                    }
                    {
                        bits: "31:16",
                        name: "res",
                        desc: "reserved",
                        resval: "0"
                    }
                ]
            }
        },
        % elif model == 1 or model == 4 :
        {
            name: "MDCFG",
            desc: "MDCFG table is a lookup to specify the number of IOPMP entries that is associated with each MD.",
            swaccess: "ro",
            hwaccess: "hro",
            fields: [
                {
                    bits: "15:0",
                    name: "t",
                    desc: ''' 
                        - Indicate the top range of memory domain m. An IOPMP entry with index j belongs to MD m
                        - If MDCFG(m-1).t ≤ j < MDCFG(m).t, where m>0. The MD0 owns the IOPMP entries with index j<MD0CFG.t.
                        - If MDCFG(m-1).t >= MDCFG(m).t, then MD m is empty.
                        - For rapid-k, dynamic-k and compact-k models, t indicates the number of IOPMP entries belongs to each MD.
                    ''',
                    resval: "${nr_mds}"
                }
            ]
        },
        % else :
        {
            name: "MDCFG",
            desc: "MDCFG table is a lookup to specify the number of IOPMP entries that is associated with each MD.",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "15:0",
                    name: "t",
                    desc: ''' 
                        - Indicate the top range of memory domain m. An IOPMP entry with index j belongs to MD m
                        - If MDCFG(m-1).t ≤ j < MDCFG(m).t, where m>0. The MD0 owns the IOPMP entries with index j<MD0CFG.t.
                        - If MDCFG(m-1).t >= MDCFG(m).t, then MD m is empty.
                        - For rapid-k, dynamic-k and compact-k models, t indicates the number of IOPMP entries belongs to each MD.
                    ''',
                    resval: "${nr_mds}"
                }
            ]
        },
        % endif

        # SRCMD Table Registers
        { skipto: "0x1000" },
        % if model == 0 or model == 1 or model == 2 :
        % for i in range(nr_sources):
        { 
            name: "SRCMD_EN${i}",
            desc: "Bitmapped MD enable register low bits for source ${i}.",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "0",
                    name: "l",
                    swaccess: "rw1ss",
                    hwaccess: "hro",
                    desc: "A sticky lock bit. When set, locks SRCMD_EN${i}, SRCMD_R${i} and SRCMD_W${i}",
                    resval: "0"
                }
                {
                    bits: "31:1",
                    name: "md",
                    swaccess: "rw",
                    hwaccess: "hro",
                    desc: "md[j] = 1 indicates md j is associated with SID ${i}.",
                    resval: "0"
                }
            ]
        },
        { 
            name: "SRCMD_ENH${i}",
            desc: "Bitmapped MD enable register high bits for source ${i}.",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "31:0",
                    name: "mdh",
                    desc: "mdh[j] = 1 indicates (md j+31) is associated with SID ${i}.",
                    resval: "0"
                }
            ]
        },
        % if enable_sps == 1 :
        { 
            name: "SRCMD_R${i}",
            desc: '''
                (Optional) Bitmapped MD read enable register low bits for source ${i},
                it indicate source s read permission on MDs.
            ''',
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "31:1",
                    name: "md",
                    desc: "md[j] = 1 indicates SID ${i} has read permission to the corresponding MD[j].",
                    resval: "0"
                }
            ]
        },
        { 
            name: "SRCMD_RH${i}",
            desc: '''
                (Optional)Bitmapped MD read enable register high bits for source ${i},
                it indicate source s read permission on MDs.
            ''',
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "31:0",
                    name: "mdh",
                    desc: "mdh[j] = 1 indicates SID ${i} has read permission to MD([j]+31).",
                    resval: "0"
                }
            ]
        },
        { 
            name: "SRCMD_W${i}",
            desc: '''
                (Optional)Bitmapped MD write enable register low bits for source ${i},
                it indicate source s write permission on MDs.
            ''',
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "31:1",
                    name: "md",
                    desc: "md[j] = 1 indicates SID ${i} has write permission to the corresponding MD[j].",
                    resval: "0"
                }
            ]
        },
        { 
            name: "SRCMD_WH${i}",
            desc: '''
                (Optional)Bitmapped MD write eanble register high bits for source ${i},
                it indicate source s write permission on MDs.
            ''',
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "31:0",
                    name: "mdh",
                    desc: "mdh[j] = 1 indicates SID ${i} has write permission to MD([j]+31).",
                    resval: "0"
                }
            ]
        },
        % else :
        {skipto: "${4096 + (i + 1)*32}"},
        % endif # endif of sps_en
        % endfor
        % endif # endif of SRCMD

        # Entry Array Registers
        {skipto: "${entry_offset}"},
        % for i in range(nr_entries):
        { 
            name: "ENTRY_ADDR${i}",
            desc: "IOPMP entrie number ${i} low bits of physical address of protected memory region",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "31:0",
                    name: "addr",
                    desc: "The low bits physical address of protected memory region entrie ${i}.",
                    resval: "0"
                }
            ]
        },
        { 
            name: "ENTRY_ADDRH${i}",
            desc:  "IOPMP entrie number ${i} high bits of physical address of protected memory region",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "31:0",
                    name: "addrh",
                    desc: "The high bits physical address of protected memory region entrie ${i}.",
                    resval: "0"
                }
            ]
        },
        { 
            name: "ENTRY_CFG${i}",
            desc: "IOPMP entrie number ${i} configuration register.",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "0",
                    name: "r",
                    desc: "The read permission to protected memory region entrie ${i}",
                    resval: "0"
                }
                {
                    bits: "1",
                    name: "w",
                    desc: "The write permission to protected memory region entrie ${i}",
                    resval: "0"
                }
                {
                    bits: "2",
                    name: "x",
                    desc: "The execute permission to protected memory region entrie ${i}",
                    resval: "0"
                }
                {
                    bits: "4:3",
                    name: "a",
                    desc: '''
                        The address mode of the IOPMP entry ${i}: 
                        - 0x0: OFF
                        - 0x1: TOR
                        - 0x2: NA4
                        - 0x3: NAPOT
                    ''',
                    resval: "0"
                }
            ]
        },
        % if enable_usr_cfg == 1 :
        {skipto: "${entry_offset + 0xC + (i)*16}"}
        { 
            name: "ENTRY_USER_CFG${i}",
            desc: "Users defined additional IOPMP check rules entriy ${i}",
            swaccess: "rw",
            hwaccess: "hro",
            fields: [
                {
                    bits: "31:0",
                    name: "im",
                    desc: "User customized permission field entry ${i}",
                    resval: "0"
                }
            ]
        },
        % else :
        {skipto: "${entry_offset + (i + 1)*16}"},
        % endif
        % endfor
    ]
}