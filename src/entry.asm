; entrypoint for the program, we'll get here from
; reset vector.

bits	16
%include "src/cache.asm"

setup_entry:
	; clear interrupt and direction flag and disable tlb
	cld
	cli
	xor 	eax, eax
	mov 	cr3, eax

	mov 	eax, 0xfffffff
	mov 	ebx, dword [eax]

	; clear our memory, and setup cpu cache to act as ram
	; for us. 
    xor     ax, ax
	mov 	cx, ax
	mov 	dx, ax
	mov 	bp, ax
	mov 	sp, ax
	mov 	es, ax
	mov 	ds, ax
	mov 	ss, ax
	mov 	gs, ax
	mov 	fs, ax
	enable_cache_as_ram

    mov     esp, CACHE_AS_RAM_BASE

    mov     cx, 12 
    mov     ebx, cache_code
    and     ebx, 0x0000FFFF
    .loop:
        mov     ax, word [bx]
        push    ax
        add     bx, 2
        loop    .loop

    xor     ax, ax
    mov     es, ax
    mov     ax, cs
    mov     ds, ax
    call    enable_unreal

cache_code:
    times   12 db 0xf4

%include "src/unreal.asm"
