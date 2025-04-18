palette:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "affichage palette 256 couleurs"
scode:
org 0

;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax
mov fs,ax

redim_ecran:
mov al,0
mov ah,6   ;option=mode video + souris
mov dx,sel_dat2
int 63h
cmp eax,0
je @f
mov al,6
mov edx,msg
int 61h
int 60h
@@:
mov ax,sel_dat2
mov fs,ax
xor ecx,ecx
fs
mov cx,[resy_ecran]
shr ecx,4
mov [carre],ecx


mov ebx,0
mov ecx,0
mov esi,[carre]
mov edi,[carre]
xor edx,edx

boucle:

mov al,22
mov ah,8
int 63h
add ebx,[carre]
add esi,[carre]
inc edx
cmp edx,256
je touche
test edx,0Fh
jnz boucle
mov ebx,0
add ecx,[carre]
mov esi,[carre]
add edi,[carre]
jmp boucle

touche:
fs
test byte[at_console],20h
jnz redim_ecran
fs
test byte[at_console],90h
jz @f
int 62h
jmp touche 
@@:



mov ebp,[carre]
shl ebp,4

mov ebx,ebp
mov ecx,0
inc ebx
mov esi,40
mov edi,16
add esi,ebp
xor edx,edx
mov al,22
mov ah,8
int 63h

fs
cmp [posx_souris],bp
jae @f
fs
cmp [posy_souris],bp
jae @f

xor eax,eax
xor edx,edx
mov ecx,[carre]
fs
mov ax,[posx_souris]
div ecx
push eax
xor eax,eax
xor edx,edx
fs
mov ax,[posy_souris]
div ecx
shl eax,4
pop ecx
add ecx,eax

mov al,102
mov edx,texte
int 61h

mov al,25
mov ah,15
mov ebx,ebp
mov ecx,0
inc ebx
int 63h


@@:
mov al,5
int 63h
cmp al,1
jne touche
int 60h


;******************************************************************************************
sdata1:
org 0

carre:
dd 32

texte:
dd 0,0,0,0,0,0,0,0

msg:
db "uniquement en mode video",13,0

sdata2:
org 0
;donnÃ©es du segment ES
sdata3:
org 0
;donnÃ©es du segment FS
sdata4:
org 0
;donnÃ©es du segment GS
findata:
