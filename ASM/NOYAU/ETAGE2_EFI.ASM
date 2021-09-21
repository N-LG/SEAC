format pe64 dll efi
entry main
 
section '.text' code executable readable
 
include 'uefi.inc'
 
main:
    ; initialize UEFI library
    InitializeLib
    jc @f
 
    ; call uefi function to print to screen
    uefi_call_wrapper ConOut, OutputString, ConOut, _hello



		mov			dword [memmapdescsize], 48
		uefi_call_wrapper	BootServices, GetMemoryMap, memmapsize, memmapbuff, memmapkey, memmapdescsize, memmapdescver
		cmp			dword [memmapdescsize], 0
		jnz			@f
		mov			dword [memmapdescsize], 48
@@:		clc
		cmp			rax, EFI_SUCCESS
		je			@f
		stc
@@:
 




@@:		uefi_call_wrapper	ConIn, ReadKeyStroke, ConIn, key
		cmp			dword [key.scancode], 0
		jz			@b
 



 
@@: mov eax, EFI_SUCCESS
    retn
;endless:
;nop
;jmp endless
 
section '.data' data readable writeable
 
_hello                                  du 'appuyez sur une touche pour continuer',13,10,0


key:
key.scancode:	dw 			0
key.unicode:	du			0

MEMMAP_BUFFSIZE equ 512
;data
memmapsize:	dq			MEMMAP_BUFFSIZE
memmapkey:	dq			0
memmapdescsize:	dq			0
memmapdescver:	dq			0
memmapbuff:	rb			MEMMAP_BUFFSIZE
 
section '.reloc' fixups data discardable





