%define CACHE_AS_RAM_BASE 	        0x08000000
%define CACHE_AS_RAM_SIZE 	        0x2000
%define MEMORY_TYPE_WRITETHROUGH    0x04
%define MEMORY_TYPE_WRITEBACK 	    0x06
%define MTRR_PAIR_VALID 	        0x800

; base
%define MTRR_PHYB_LO 		(CACHE_AS_RAM_BASE | \
					            MEMORY_TYPE_WRITEBACK)
%define MTRR_PHYB_REG0 		0x200
%define MTRR_PHYB_HI 		0x00

; mask
%define MTRR_PHYM_LO 		((~((CACHE_AS_RAM_SIZE) - 1)) | \
					            MTRR_PAIR_VALID)

%define MTRR_PHYM_HI 		0xF
%define MTRR_PHYM_REG0 		0x201

%define MTRR_DEFTYPE_REG0 	0x2FF
%define MTRR_ENABLE 		0x800

%macro enable_cache_as_ram 0
	; setup MTRR base 
	mov 	eax, MTRR_PHYB_LO	; mtrr phybase low
	mov 	ecx, MTRR_PHYB_REG0	; ia32 mtrr phybase reg0
	xor 	edx, edx
	wrmsr

	; setup MTRR mask
	mov 	eax, MTRR_PHYM_LO
	mov 	ecx, MTRR_PHYM_REG0
	mov 	edx, MTRR_PHYM_HI
	wrmsr

	; enable MTRR subsystem
	mov 	ecx, MTRR_DEFTYPE_REG0
	rdmsr
	or 	eax, MTRR_ENABLE
	wrmsr

	; enter normal cache mode
	mov 	eax, cr0
	and 	eax, 0x9fffffff
	invd
	mov 	cr0, eax

	; establish tags for cache-as-ram region in cache
	mov 	esi, CACHE_AS_RAM_BASE
	mov 	ecx, (CACHE_AS_RAM_SIZE / 2)
	rep 	lodsw

    ; Change to no-fill mode
    mov     eax, cr0
    or      eax, 0x40000000
    mov     cr0, eax

	; clear cache memory region
	xor 	ax, ax
	mov 	edi, CACHE_AS_RAM_BASE
	mov 	ecx, (CACHE_AS_RAM_SIZE / 2)
	rep 	stosw

	mov 	ss, ax
	mov 	esp, (CACHE_AS_RAM_BASE + CACHE_AS_RAM_SIZE)

%endmacro

