
; ======================================================================== ;
; This file handles the reset vector 
; ======================================================================== ;
bits	16
org	0xFFFE0000
align	4

times	0x10000 - ($-$$) db 0
entry:

%include 'src/entry.asm'
	cli
	hlt

times	0x20000 - 0x10 - ($-$$) db 0xFF
__reset:
	; disable all interrupts, currently any exception and/or interrupt
	; will shutdown the CPU. 
	; (
	;  Interrupt will modify CS register, which would mean that we cant
	;  return back here.
	; )

	cli
;	db	0xe9
;	dd	entry - ($ + 2)
	jmp 	entry - ($ + 2)

	times	12 db 0xff

