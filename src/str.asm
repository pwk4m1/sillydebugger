; ------------------------------------------------------------
; Some string-related helpers for user-input handling
;

; strcmp:
; Requires:
;   si = 0-terminated str1
;   di = 0-terminated str2
; returns:
;   cx = amount of bytes that differ 
;
strcmp:
    push    si
    push    di
    push    ax

    xor     cx, cx
    .loop:
        lodsb
        cmp     al, byte [di]
        je      .next
        inc     cx
    .next:
        cmp     al, 0
        je      .done
        cmp     byte [di], 0
        je      .done
        inc     di
        jmp     .loop
    .done:
        pop     ax
        pop     di
        pop     si
        ret

; si: pointer to string
; returns cx = strlen
strlen:
    push    si
    push    ax
    xor     cx, cx
    .loop:
        lodsb
        cmp     al, 0
        je      .done
        inc     cx
        jnz     .loop
    ; overflow protection
    .done:
        pop     ax
        pop     si
        ret


