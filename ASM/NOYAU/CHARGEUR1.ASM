org 10000h ;le programme sera chargé dans le deuxième Mo
use32

;extrait de https://ftp.gnu.org/old-gnu/Manuals/grub-0.92/html_mono/multiboot.html
;`magic' The field `magic' is the magic number identifying the header, which must be the hexadecimal value 0x1BADB002. 
;`flags' The field `flags' specifies features that the OS image requests or requires of an boot loader. Bits 0-15 indicate requirements; if the boot loader sees any of these bits set but doesn't understand the flag or can't fulfill the requirements it indicates for some reason, it must notify the user and fail to load the OS image. Bits 16-31 indicate optional features; if any bits in this range are set but the boot loader doesn't understand them, it may simply ignore them and proceed as usual. Naturally, all as-yet-undefined bits in the `flags' word must be set to zero in OS images. This way, the `flags' fields serves for version control as well as simple feature selection. 
;If bit 0 in the `flags' word is set, then all boot modules loaded along with the operating system must be aligned on page (4KB) boundaries. Some operating systems expect to be able to map the pages containing boot modules directly into a paged address space during startup, and thus need the boot modules to be page-aligned. 
;If bit 1 in the `flags' word is set, then information on available memory via at least the `mem_*' fields of the Multiboot information structure (see section 3.3 Boot information format) must be included. If the boot loader is capable of passing a memory map (the `mmap_*' fields) and one exists, then it may be included as well. 
;If bit 2 in the `flags' word is set, information about the video mode table (see section 3.3 Boot information format) must be available to the kernel. 
;If bit 16 in the `flags' word is set, then the fields at offsets 8-24 in the Multiboot header are valid, and the boot loader should use them instead of the fields in the actual executable header to calculate where to load the OS image. This information does not need to be provided if the kernel image is in ELF format, but it must be provided if the images is in a.out format or in some other format. Compliant boot loaders must be able to load images that either are in ELF format or contain the load address information embedded in the Multiboot header; they may also directly support other executable formats, such as particular a.out variants, but are not required to. 
;`checksum' The field `checksum' is a 32-bit unsigned value which, when added to the other magic fields (i.e. `magic' and `flags'), must have a 32-bit unsigned sum of zero. 

;header_addr Contains the address corresponding to the beginning of the Multiboot header -- the physical memory location at which the magic value is supposed to be loaded. This field serves to synchronize the mapping between OS image offsets and physical memory addresses. 
;load_addr Contains the physical address of the beginning of the text segment. The offset in the OS image file at which to start loading is defined by the offset at which the header was found, minus (header_addr - load_addr). load_addr must be less than or equal to header_addr. 
;load_end_addr Contains the physical address of the end of the data segment. (load_end_addr - load_addr) specifies how much data to load. This implies that the text and data segments must be consecutive in the OS image; this is true for existing a.out executable formats. If this field is zero, the boot loader assumes that the text and data segments occupy the whole OS image file. 
;bss_end_addr Contains the physical address of the end of the bss segment. The boot loader initializes this area to zero, and reserves the memory it occupies to avoid placing boot modules and other data relevant to the operating system in that area. If this field is zero, the boot loader assumes that no bss segment is present. 
;entry_addr The physical address to which the boot loader should jump in order to start running the operating system. 


debut:
nombre_magique equ 1BADB002h
flags equ 10003h


dd nombre_magique         ;`magic'          nombre magique de l'en tête multiboot
dd flags                  ;`flags'
dd -nombre_magique-flags  ;`checksum'
dd debut                  ;'header_addr'    adresse de l'en tête
dd debut                  ;'load_addr'      adresse de chargement
dd fin_copie              ;'load_end_addr'  fin de la zone recopié en mémoire
dd fin_absolue            ;'bss_end_addr'
dd debut_programme        ;'entry_addr'     position première instruction executé



debut_programme:
mov esp,fin_absolue      ;définis la pile

;affiche un message pour patienter l'utilisateur
mov edi, 0B8000h+0F00h ;adresse dernière ligne mémoire video texte
mov esi,msg
mov ah,0Ah
boucle_message:
lodsb
stosw
cmp al,0
jne boucle_message


;copie la structure du noyau au bon emplacement
mov esi,noyau
mov edi,50000h
mov ecx,fin_noyau-noyau
rep movsb


;charge une GDT avec un selecteur de segment de code en 16bit
lgdt[pointeur_gdt]

;bloque toutes irq
cli
mov dx,21h             
mov al,0FFh            
out dx,al
mov dx,0A1h
mov al,0FFh 
out dx,al


;passe en mode protégé 16 bit
jmp 0008h:mode_protege_16b-10000h


;***********************************partie du code executé en mode protége 16bit
use16
mode_protege_16b:

;recharge les selecteur de segment avec les limite de 64Ko du mode réel
mov ax,16
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ss,ax

;passe en mode réel
mov eax,cr0
and eax,0FFFFFFFEh
mov cr0,eax
jmp 1000h:mode_reel-10000h



;*********************************partie du code executé en mode réel
mode_reel:
;restaure des segment de donnée du mode réel
mov ax,1000h
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ax,9000h
mov ss,ax
mov sp,0FFF0h

;restaure le pointeur de la table d'interruption en mode réel
lidt[pointeur_idt-10000h]

;saute sur le code
jmp 5000h:0000h


;************************************données
pointeur_idt:
dw 3FFh
dd 0

pointeur_gdt:
dw 0FFFFh
dd table_gdt 

table_gdt:
dd 0,0   ;descripteur nul
;descripteur de code en 16bit a l'adresse 10000h
dw 0000Fh ;lsb de la limite
dw 0      ;lsb de l'adresse de base
db 01h    ;millieu de l'adresse de base
db 09Ah   ;type
db 080H   ;limite et type
db 0      ;msb de l'adresse de base
;descripteur de data a l'adresse 90000h
dw 0000Fh ;lsb de la limite
dw 0      ;lsb de l'adresse de base
db 09h    ;millieu de l'adresse de base
db 092h   ;type
db 080H   ;limite et type
db 0      ;msb de l'adresse de base


msg db 'Chargement du noyau en cours, veuillez patienter...',0


noyau:
file "../../BIN/SYST1.BAZ"
fin_noyau:





fin_copie:



rb 1000h  ;réserve 64ko de pile


fin_absolue: