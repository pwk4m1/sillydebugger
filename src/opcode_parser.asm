; This file implements instruction parsing, we'll fetch and
; parse legacy/x87 prefix bytes, then opcode bytes, modr/m and
; immediate as it is.
;
; TODO: 
;   - SIB parsing, etc. 
;   - Just make this less hacky
; 

; ------------------------------------------------------------
; Helper to check if byte is within byte-group.
; Requires:
;   al = byte to check
;   esi = pointer to list of bytes to compare against
;   cx = list size
; Returns:
;   carry flag set if byte in al is present in list at esi
;
byte_is_in_group:
    push    esi
    push    ax
    push    bx
    push    cx

    mov     bl, al
    .loop:
        lodsb
        cmp     al, bl
        je      .found
        loop    .loop
        clc
    .ret:
        pop     cx
        pop     bx
        pop     ax
        pop     esi
        ret
    .found:
        stc
        jmp     .ret

; ------------------------------------------------------------
; Check if current opcode requires immediate in addition to ModR/M
;
; This is somewhat simple since all opcodes that have immediate
; value have 1st opcode byte ending with 3, 4, 0c, or 0d.
;
; Requires:
;   al = 1st byte of current opcode
; Returns:
;   Carry flag set if this instruction makes use of immediate value,
;   clear otherwise
;
identify_imm_needed:
    clc
    push    ax

    and     al, 0x0f
    cmp     al, 3
    jl      .ret
    cmp     al, 4
    jle      .imm

    cmp     al, 0x0c
    jl      .ret
    cmp     al, 0x0d
    jle      .imm
.ret:
    pop     ax
    ret
.imm:
    stc
    jmp     .ret

; ------------------------------------------------------------
; Check if current opcode has no operand bytes
;
; Requires:
;   al = 1st byte of current opcode
; Returns:
;   Carry flag set if this is no-operand opcode, clear otherwise
;
identify_no_operand_instruction:
    push    ds
    push    esi
    push    cx

    and     esi, 0x0000FFFF
    push    cs
    pop     ds
    mov     si, no_operand_opcode_list
    mov     cx, no_operand_opcode_list.len
    call    byte_is_in_group

    pop     cx
    pop     esi
    pop     ds
    ret

; ------------------------------------------------------------
; Start parsing opcodes and dynamically load from cache 
; instead of static 2-byte blocks.
;
; Helper to check if byte given in matches legacy prefix bytes.
; If the byte matches, return carry flag clear, otherwise set carry
;
;
identify_legacy_prefix_byte:
    clc
    push    ds
    push    esi
    push    cx

    and     esi, 0x0000FFFF
    push    cs
    pop     ds
    mov     si, legacy_prefix_opcode_list
    mov     cx, legacy_prefix_opcode_list.len 
    call    byte_is_in_group

    pop     cx
    pop     esi
    pop     ds
    ret

; ------------------------------------------------------------
; Requires: 
;       - esi pointing to current offset at cache
;       - es:di pointing to where we'll store the executable code 
; Returns: size of byte-sequence to execute in dx
;
load_operation:
    xor     dx, dx
    push    di
    push    esi
    push    ax
    push    bx
    push    cx

    clc

    ; backup di to dx so that we can refer to whole opcode
    ; sequence as we go.
    ;
    mov     bx, di

    ; ------------------------------------------------------------
    ; Load 1st byte of instruction, and check if it's legacy-prefix
    ; byte. If it is, parse legacy prefix before continuing.
    ;
    mov     cx, 4
    .parse_legacy:
        lodsb
        call    identify_legacy_prefix_byte
        jnc     .parse_opcode
        stosb
        inc     dx
        inc     bx
        dec     cx
        jnz     .parse_legacy

    ; ------------------------------------------------------------
    ; There were legacy prefix bytes, but those are now parsed,
    ; load one more byte which'll be 1st byte of opcode, and
    ; then continue to .parse_opcode label
    ;
        lodsb
    
    ; ------------------------------------------------------------
    ; we're done parsing legacy prefix byte(s), next comes 1-4 
    ; bytes of actual opcode, parse that next.
    ;
    .parse_opcode:
        ; we've got 1st byte of opcode loaded, regardless of
        ; if legacy prefix bytes were present.
        ;
        stosb
        inc     dx

        ; Check if this is a legacy / x87 opcode
        cmp     al, 0x0F
        je      .parse_legacy_multibyte_opcode

        ; I don't think I want to support VEX or XOP quite yet
        jmp     .parse_modrm

    ; ------------------------------------------------------------
    ; Parse legacy/x87 multibyte opcode
    ;
    .parse_legacy_multibyte_opcode:
        ; Check if 2nd byte is 38 or 3a, if it isn't we're done
        ;
        lodsb
        stosb
        inc     dx
        cmp     al, 0x38
        jl      .parse_modrm
        cmp     al, 0x3A
        jne     .parse_modrm

        ; Fetch the last byte for this opcode, store it, and
        ; we're done
        movsb
        inc     dx

    ; ------------------------------------------------------------
    ; We're done with prefix and opcode, now what's left is
    ; ModR/M, SIB, Displacement, and Immediate bytes.
    ; this'll be Fun
    ;
    .parse_modrm:
        ; Get the 1st opcode byte to al, and proceed to check
        ; how many operands does this one use
        ;
        mov     al, byte [bx]

        ; if this opcode takes no operands/there's no follow
        ; up bytes to load, we can return already
        ;
        call    identify_no_operand_instruction
        jc      .done

        ; there's at Least modrm byte present with this opcode
        ;
        movsb
        inc     dx

        ; Check if there's immediate present
        ;
        mov     al, byte [bx]
        call    identify_imm_needed
        jnc     .done
        movsb
        inc     dx

    ; ------------------------------------------------------------
    ; we're done, we're so so done
    ;
    .done:
        pop     cx
        pop     bx
        pop     ax
        pop     esi
        pop     di
        ret

