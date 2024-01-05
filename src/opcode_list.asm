; This file holds lists for various special opcode
; stuff, such as legacy prefixes and whatnot, all those
; awful awful things I have to identify...
;

; ------------------------------------------------------------
; Opcodes that take no operands and stuff
no_operand_opcode_list:
    db 0x50
    db 0x58
    db 0x90
    db 0x9b
    db 0x9c
    db 0x9d
    db 0xc3
    db 0xce
    db 0xcf
    db 0xd9
    db 0xf4
    db 0xf5
    db 0xf8
    db 0xf9
    db 0xfa
    db 0xfb
    db 0xfc
    db 0xfd
    .len: equ $ - no_operand_opcode_list

; ------------------------------------------------------------
; Legacy prefixes:
;     Prefix group 1
;        0xF0: LOCK prefix
;        0xF2: REPNE/REPNZ prefix
;        0xF3: REP or REPE/REPZ prefix 
;    Prefix group 2
;        0x2E: CS segment override
;        0x36: SS segment override
;        0x3E: DS segment override
;        0x26: ES segment override
;        0x64: FS segment override
;        0x65: GS segment override
;        0x2E: Branch not taken
;        0x3E: Branch taken 
;    Prefix group 3
;        0x66: Operand-size override prefix 
;    Prefix group 4
;        0x67: Address-size override prefix 
;
legacy_prefix_opcode_list:
    db 0xf0
    db 0xf2
    db 0xf3
    db 0x2e
    db 0x36
    db 0x3e
    db 0x26
    db 0x64
    db 0x65
    db 0x2e
    db 0x3e
    db 0x66
    db 0x67
.len: equ $ - legacy_prefix_opcode_list

