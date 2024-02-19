; This file implements debugger user interface
;

%macro print_register 2
    mov     si, %1
    call    serial_print
    mov     ax, %2
    call    serial_printh
%endmacro

; ------------------------------------------------------------
; Handle user provided command
; 
ui_prompt:
    cmp     byte [UI_ADDR_STEP_CNT], 0
    jne     .ret_continue_steps

    push    ax
    push    dx
    push    edi
    push    esi
    push    cx
    push    es
    push    ds

    and     esi, 0x0000FFFF
    and     edi, 0x0000FFFF

    xor     ax, ax
    mov     es, ax
    mov     ds, ax


.start:
    mov     si, .prompt
    call    serial_print

    mov     cx, 64
    mov     di, USER_PROMPT_INPUT
    rep     stosb
    sub     di, 64
    mov     cx, 64

    .readloop:
        call    ui_wait_keypress
        cmp     al, 0x0d
        je      .exec_start
        stosb
        loop    .readloop

    .exec_start:
        sub     di, 64
        add     di, cx
        mov     si, di
        call    strlen
        cmp     cx, 0 
        je      .exec_previous

    ; we have non-zero length input, back it up
        push    di
        push    cx
        mov     cx, 64
        mov     di, USER_PROMPT_PREVIOUS_INPUT
        rep     stosb
        pop     cx
        mov     di, USER_PROMPT_PREVIOUS_INPUT
        rep     movsb
        pop     di

    .do_exec:
        cmp     byte [di], 0x72         ; r
        je      do_reset
        cmp     byte [di], 0x3f         ; ?
        je      .usage
        cmp     byte [di], 0x73         ; s
        je      .step

        ; Command not recognized
        jmp     .usage

    .exec_previous:
        mov     si, USER_PROMPT_PREVIOUS_INPUT
        call    strlen
        cmp     cx, 0
        je      .readloop
        mov     di, USER_PROMPT_PREVIOUS_INPUT
        jmp     .do_exec

    ; step single or multiple instructions
    .step:
        mov     si, di
        call    strlen
        cmp     cx, 3 
        jne      .ret
        mov     al, byte [si+2]
        and     al, 0x0F
        mov     byte [UI_ADDR_STEP_CNT], al
        jmp     .ret

    .ret:
        pop     ds
        pop     es
        pop     cx
        pop     esi
        pop     edi
        pop     dx
        pop     ax
        ret
    .ret_continue_steps:
        dec     byte [UI_ADDR_STEP_CNT]
        ret

.usage:
    mov     si, .msg_usage
    call    serial_print
    jmp     .start

.msg_usage:
    db 0x0a, 0x0d
    db "Usage: ", 0x0a, 0x0d
    db "    ?:          Show this help window", 0x0a, 0x0d
    db "    r:          Reset the target program", 0x0a, 0x0d
    db "    s:          Execute single step of program OR", 0x0a, 0x0d
    db "    s <n>:      Execute n steps where n: 1-9", 0x0a, 0x0d

    db 0

.prompt:
    db 0x0a, 0x0d, "> ", 0
    db 0x0a, 0x0d, 0


; ------------------------------------------------------------
; Read user input over serial
;
ui_wait_keypress:
    push    dx
    .waitkey:
        .waitloop:
            mov     dx, 0x03f8 + 5
            in      al, dx
            and     al, 1
            test    al, al
            jz      .waitloop
        sub     dx, 5 
        in      al, dx 
        call    serial_wait_tx_empty
        out     dx, al
.ret:
    pop     dx
    ret

; ------------------------------------------------------------
; Trigger CPU reset in case our debugged program has reached
; it's end.
;
do_reset:
    mov     si, .msg_reset
    call    serial_print
    mov     dx, 0x64
    mov     al, 0xfe
    out     dx, al
    cli
    hlt
    jmp     $ - 2
.msg_reset:
    db ">>> CPU Reset <<<", 0x0A, 0x0D, 0x0A, 0x0D, 0

; ------------------------------------------------------------
; Print state of debugged process
; Requires: 
;   registers at ebp
; 
print_registers:
    pushad

    ; ------------------------------------------------------------
    ; First print current cycle 
    ;
    mov     si, .msg_cycle_count
    call    serial_print
    mov     ax, word [CYCLES_EXECUTED]
    call    serial_printh

    ; ------------------------------------------------------------
    ; Print register dump
    ;
    mov     si, .msg_register_dump
    call    serial_print

    mov     dword [BACKUP_STACKPTR], esp
    mov     esp, ebp
    popad
    mov     esp, dword [BACKUP_STACKPTR]

    print_register .msg_ax, ax
    print_register .msg_cx, cx
    print_register .msg_dx, dx
    print_register .msg_bx, bx
    print_register .msg_si, si
    print_register .msg_di, di

    popad
    ret

.msg_cycle_count:
    db 0x0a, 0x0d 
    db "-------------------------------------------", 0x0a, 0x0d
    db "Executing cycle: ", 0

.msg_register_dump:
    db "Register dump: ", 0xA, 0x0D, 0

.msg_ax: db "ax: ", 0
.msg_cx: db "cx: ", 0
.msg_dx: db "dx: ", 0
.msg_bx: db "bx: ", 0
.msg_si: db "si: ", 0
.msg_di: db "di: ", 0

%include "src/serial.asm"
