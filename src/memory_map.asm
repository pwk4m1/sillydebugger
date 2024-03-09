; This project was about to become yet another define ptr 
; hell, so that's why _all_ new ptrs are to be defined here
;
section .bss
bits    32

; ------------------------------------------------------------
; Low memory pointers
;
; SECONDARY_EXECPTR:
;   - where the current executable codeword from cache is at
; PRIMARY_REGPTR:
;   - where 'primary' register/cpu state is stored to
; CODE_CYCLE_COUNT:
;   - How many cycles we've executed in 'secondary' mode
; SECONDARY_STACKPTR:
;   - current pointer to cache for secondary  
;
%define PRIMARY_REGPTR (PRIMARY_REGMEM + 8 * 4)

absolute 0x0300
SECONDARY_EXECPTR:
    resb    128
PRIMARY_REGMEM:
    resb    8 * 4
BACKUP_STACKPTR:
    resb    4
USER_PROMPT_INPUT:
    resb    70
USER_PROMPT_PREVIOUS_INPUT:
    resb    70

; ------------------------------------------------------------
; Cache region related memory and pointers
;
; SECONDARY_REGPTR:
;   - upon entering/exiting 'secondary' code, we'll store/restore
;     registers to/from here
;
; SECONDARY_CODEMEM:
;   - 'secondary' program code is to be stored here
;
; SECONDARY_STACKMEM
;   - Beginning of 'secondary' stack / cache region
;
%define SECONDARY_REGPTR (SECONDARY_REGMEM + 8 * 4)

absolute 0x08000000
    SECONDARY_REGMEM:
        resb    8 * 4
    SECONDARY_CODEMEM:
        resb    0xeff
    SECONDARY_STACKMEM:
        resb    0x100

    ; Previous low memory stuff
    UI_ADDR_STEP_CNT:
        resb    1
    SECONDARY_STACKPTR:
        resb    4
    CYCLES_EXECUTED:
        resb    4
    CODE_CYCLE_COUNT:
        resb    2

bits    16
section .text
