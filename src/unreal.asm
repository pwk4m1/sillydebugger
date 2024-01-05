; Implement functionality for us to
;
;   1.) Jump to 0000:0500 
;   2.) Enable protected mode
;   3.) Set segments, and disable protected mode
;   4.) Jump back to ROM:OFFSET in unreal mode
;
; This'll allow us to use 32-bit addressing which should
; be only thing left before we can set IP: Cache region
;
%macro mem_set 2
    mov     al, %1
    mov     cx, %2
    rep     stosb
%endmacro

enable_unreal:
    mov     di, 0x0500
    mov     ax, cs
    mov     ds, ax
    mov     si, relocate_code
    mov     cx, (relocate_code.end - relocate_code)
    rep     movsb

    mov     si, gdt
    mov     di, 0x0600
    mov     cx, (gdt.end - gdt)
    rep     movsb

    xor     ax, ax
    mov     ds, ax
    jmp     0x0000:0x0500

relocate_code:
    lgdt    [0x0600]
    mov     eax, cr0
    or      al, 1
    mov     cr0, eax
    jmp     0x08:(0x0500 + (relocate_code.pmode - relocate_code))
.pmode:
    mov     bx, 0x10
    mov     ds, bx
    mov     eax, cr0
    and     eax, 0x9ffffffe
    mov     cr0, eax
    jmp     0:(0x0500 + (relocate_code.huge_unreal - relocate_code))
.huge_unreal:
    pop     ds
    xor     ax, ax
    mov     ds, ax

    enable_cache_as_ram
    ;
    ; cache as ram in huge unreal mode works here, we're 
    ; at unsegmented low memory. 
    ;
    jmp     0xF000:vmstart

bits    16
    cli
    hlt
    jmp     $ - 2

.end:

gdt:
    dw  (gdt.end - gdt - 1)
    dd  0x00000606
.null:
    dq  0
.flat:
    db 0xff, 0xff, 0, 0, 0, 10011010b, 00000000b, 0
    db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0

.end:

%include "src/vmstart.asm"
