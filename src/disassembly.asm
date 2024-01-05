;
; This file implements disassembling operations
; executed by the guest, as well as some other opcode checks

; ------------------------------------------------------------
; Requires:
;   al - 1st opcode byte 
; Returns:
;   Carry flag set if this is a branching operation
;   Clear otherwise
;
opcode_is_branching:
    clc
    push    ax
    and     al, 0xF0
    cmp     al, 0x70
    je      .branches
.ret:
    pop     ax
    ret
.branches:
    stc
    jmp     .ret
    
    



