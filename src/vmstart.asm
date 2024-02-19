; Implement main debugger logic on this file.
;
; F000:vmstart -- 0x08000000 - 0x08001FFF
; is set as usable memory in cache for us
;
;
; SECONDARY_CODEMEM:
;   - 'secondary' program code is to be stored here
;
; SECONDARY_STACKMEM
;   - Beginning of 'secondary' stack / cache region
;
%include "src/memory_map.asm"

; ------------------------------------------------------------
; Temporary/test secondary program to execute
;
secondary_program:
    add     ax, 4
    add     bx, 4
    sub     bx, 2
    mov     cx, bx
    dec     cx
    add     cx, 7
    cli
    hlt
    hlt
    times   16 db 0xf4
.end:
SECONDARY_PROGRAM_SIZE equ (secondary_program.end - secondary_program) 

%define CYCLES_EXECUTED 0x100

; ------------------------------------------------------------
; The program to debug has been halted, loop here until
; reset happens.
;
program_halted:
    mov     si, .msg_program_halted
    call    serial_print
    call    ui_wait_keypress
    cmp     al, 0x72
    je      do_reset
    jmp     program_halted

.msg_program_halted:
    db "Debugged program called halt, press r to restart"
    db 0x0A, 0x0D, 0

; ------------------------------------------------------------
; Handle branching instructions 
;
program_branched:
    mov     si, .msg_branch_encountered
    call    serial_print
    call    ui_wait_keypress
    jmp     program_branched

.msg_branch_encountered:
    db "Program branching is not supported yet", 0x0A, 0x0D, 0

; ------------------------------------------------------------
; Beginning of our weird context hopping program.
;
vmstart:
    ; ------------------------------------------------------------
    ; Set the initial cache pointer
    ;
    mov     dword [SECONDARY_STACKPTR], SECONDARY_STACKMEM

    ; ------------------------------------------------------------
    ; Set single step counter to 0
    ;
    mov     byte [UI_ADDR_STEP_CNT], 0

    ; ------------------------------------------------------------
    ; Init cycle exec counter
    ;
    mov     word [CYCLES_EXECUTED], 1

    ; ------------------------------------------------------------
    ; Set segments for relocating code to segment 0
    ;
    mov     ax, cs
    mov     ds, ax
    xor     ax, ax
    mov     es, ax
    mov     word [CODE_CYCLE_COUNT], ax

    ; ------------------------------------------------------------
    ; copy secondary code and return trampoline to low memory
    ;
    mov     di, SECONDARY_EXECPTR+2
    mov     si, return_trampoline
    mov     cx, (return_trampoline.end - return_trampoline)
    rep     movsb 

    ; ------------------------------------------------------------
    ; copy secondary code/test program into cache
    ;
    and     eax, 0x0000FFFF
    and     esi, 0x0000FFFF
    mov     si, secondary_program
    mov     cx, SECONDARY_PROGRAM_SIZE
    xor     ax, ax
    mov     es, ax
    mov     edi, SECONDARY_CODEMEM
    rep     movsb

    xor     ax, ax
    mov     ds, ax
    and     edi, 0x0000FFFF
    mov     cx, SECONDARY_PROGRAM_SIZE
    mov     esi, SECONDARY_CODEMEM
   
; ------------------------------------------------------------
; Setup complete, we can start executing code from
; cache now
;
.exec_loop:
    ; ------------------------------------------------------------
    ; Fetch next instruction to execute 
    ; to SECONDARY_EXECPTR
    ; 
    mov     di, SECONDARY_EXECPTR
    mov     cx, 16
    mov     ax, 0x90
    rep     stosb
    mov     di, SECONDARY_EXECPTR
    call    load_operation
    add     si, dx

    ; ------------------------------------------------------------
    ; Check if we've encountered halt or branching instructions.
    ;
    push    ax
    mov     al, byte [SECONDARY_EXECPTR]

    cmp     al, 0xf4
    je      program_halted

    call    opcode_is_branching
    jc      program_branched

    ; ------------------------------------------------------------
    ; Store primary register values
    ;
    mov     esp, PRIMARY_REGPTR
    pushad

    ; ------------------------------------------------------------
    ; Invoke debugger user interface and increment cycle counter 
    ;
    mov     ebp, SECONDARY_REGPTR - (8 * 4)
    call    ui_prompt
    call    print_registers
    inc     word [CYCLES_EXECUTED]

    ; ------------------------------------------------------------
    ; Restore secondary register values off cache and
    ; continue execution
    ;
    mov     esp, SECONDARY_REGPTR - (8 * 4)
    popad
    mov     esp, dword [SECONDARY_STACKPTR]

    ; ------------------------------------------------------------
    ; Execute next debuggee instruction
    ;
    jmp     0x0000:SECONDARY_EXECPTR

; ------------------------------------------------------------
; Return here after executing one cycle of code has been
; executed. 
;
; Backup debuggee state, restore debugger state, and 
; loop back to beginning.
;
.exec_loop_cycle_done:
    mov     dword [SECONDARY_STACKPTR], esp

    ; ------------------------------------------------------------
    ; Store secondary register values to cache
    ;
    mov     esp, SECONDARY_REGPTR
    pushad

    ; ------------------------------------------------------------
    ; Restore primary register values
    ;
    mov     esp, PRIMARY_REGPTR - (8 * 4)
    popad

    jmp     .exec_loop

return_trampoline:
    times   16 db 0x90
    jmp     0xF000:vmstart.exec_loop_cycle_done
.end:

%include "src/opcode_list.asm"
%include "src/opcode_parser.asm"
%include "src/debugger_ui.asm"
%include "src/disassembly.asm"
%include "src/str.asm"

