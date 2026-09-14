cube:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "affichage palette de couleurs"
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
sub ecx,16
shr ecx,4
mov [carre],ecx

;affiche le message
mov edx,msg256
call ajuste_langue
mov al,25
mov ah,15
xor ecx,ecx
xor ebx,ebx
fs
mov cx,[resy_ecran]
sub ecx,16
int 63h

mov ebx,0
mov ecx,0
mov esi,[carre]
mov edi,[carre]
xor edx,edx


;affiche 16*16 de carré de couleur
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


;calcul le bord de la palette
mov ebp,[carre]
shl ebp,4

;efface l'affichage du numéros de couleur précédent
mov ebx,ebp
mov ecx,0
inc ebx
mov esi,40
mov edi,32
add esi,ebp
xor edx,edx
mov al,22
mov ah,8
int 63h

;vérifie que l'on est dans le carré
fs
cmp [posx_souris],bp
jae @f
fs
cmp [posy_souris],bp
jae @f

;calcul le numéros de la couleur sous le curseur
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


;affiche un carré de la couleur pointé par le curseur
push ecx
mov edx,ecx
mov al,22
mov ah,8
xor esi,esi
mov ebx,ebp
mov ecx,72
mov si,[resx_ecran]
mov edi,ebp
int 63h
pop ecx


;affiche le numéros de la couleur sous le curseur
push ecx
mov al,102
mov edx,texte
int 61h

mov al,25
mov ah,15
mov ebx,ebp
mov ecx,0
inc ebx
int 63h

;pareil mais en hexadécimal
pop ecx
mov al,105
mov edx,texte
int 61h
mov word[edx+2],"h"

mov al,25
mov ah,15
mov ebx,ebp
mov ecx,16
inc ebx
int 63h


;on boucle tant que personne n'appuie sur echap ou sur entrée pour passer en mode 24bit
@@:
mov al,5
int 63h
cmp al,44
je mode24bit
cmp al,1
jne touche
int 60h



;**************************************************************************************
mode24bit:
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
sub ecx,32
shr ecx,8
mov [carre],ecx

;affiche le message
mov al,26
mov ah,15
xor ecx,ecx
xor ebx,ebx
fs
mov cx,[resy_ecran]
fs
mov si,[resx_ecran]
mov edx,msg24
call ajuste_langue
sub ecx,32
int 63h


mov ebx,0
mov ecx,0
mov esi,[carre]
mov edi,[carre]
mov edx,[couleur24]


;affiche 256*256 de carré de couleur
boucle24:
mov al,22
mov ah,24
push edx
call melange
int 63h
pop edx
add ebx,[carre]
add esi,[carre]
inc edx
cmp dl,0
jne boucle24
cmp dh,0
je touche24
mov ebx,0
add ecx,[carre]
mov esi,[carre]
add edi,[carre]
jmp boucle24


touche24:
fs
test byte[at_console],20h
jnz mode24bit
fs
test byte[at_console],90h
jz @f
int 62h
jmp touche24 
@@:


;calcul le bord de la palette
mov ebp,[carre]
shl ebp,8

;efface l'affichage du numéros de couleur précédent
mov ebx,ebp
mov ecx,0
inc ebx
mov esi,64
mov edi,64
add esi,ebp
xor edx,edx
mov al,22
mov ah,8
int 63h

;vérifie que l'on est dans le carré
fs
cmp [posx_souris],bp
jae @f
fs
cmp [posy_souris],bp
jae @f

;calcul le numéros de la couleur sous le curseur
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
pop ecx

shl eax,8
add ecx,eax
add ecx,[couleur24]
mov edx,ecx
call melange

;affiche un carré de la couleur pointé par le curseur
push edx
mov al,22
mov ah,24
xor esi,esi
mov ebx,ebp
mov ecx,72
mov si,[resx_ecran]
mov edi,ebp
int 63h
pop ecx


;affiche le numéros de la couleur sous le curseur
push ecx
push ecx
push ecx

shr ecx,16
and ecx,0FFh
mov al,102
mov edx,texte+2
int 61h
mov word[texte],"R:"
mov al,25
mov ah,15
mov ebx,ebp
mov ecx,0
inc ebx
mov edx,texte
int 63h

pop ecx
shr ecx,8
and ecx,0FFh
mov al,102
mov edx,texte+2
int 61h
mov word[texte],"G:"
mov al,25
mov ah,15
mov ebx,ebp
mov ecx,16
inc ebx
mov edx,texte
int 63h

pop ecx
and ecx,0FFh
mov al,102
mov edx,texte+2
int 61h
mov word[texte],"B:"
mov al,25
mov ah,15
mov ebx,ebp
mov ecx,32
inc ebx
mov edx,texte
int 63h



;pareil mais en hexadécimal
pop ecx
mov al,103
mov edx,texte
int 61h

mov al,25
mov ah,15
mov ebx,ebp
mov ecx,48
inc ebx
add edx,2
int 63h


;on boucle tant que personne n'appuie sur echap ou sur entrée pour revenir en mode 256 couleur
@@:
mov al,5
int 63h
cmp al,44
je redim_ecran
cmp al,82
je plus
cmp al,84
je moins
cmp al,78
je plusplus
cmp al,81
je moinsmoins
cmp al,0F0h
je choixcouleur
cmp al,1
jne touche24
int 60h


plus:
inc byte[couleur24+2]
jmp mode24bit

moins:
dec byte[couleur24+2]
jmp mode24bit


plusplus:
add byte[couleur24+2],16
jmp mode24bit

moinsmoins:
sub byte[couleur24+2],16
jmp mode24bit


choixcouleur:
inc byte[modemelange]
cmp byte[modemelange],3
jne mode24bit
mov byte[modemelange],0
jmp mode24bit





;*******************
melange:
cmp byte[modemelange],0
jne @f
ret

@@:
cmp byte[modemelange],1
je melange1
cmp byte[modemelange],2
je melange2
ret

melange1:
push eax
mov eax,edx
shl edx,8
shr eax,16
or edx,eax
and edx,0FFFFFFh
pop eax
ret

melange2:
push eax
mov eax,edx
shl edx,16
shr eax,8
or edx,eax
and edx,0FFFFFFh
pop eax
ret






;***************************
ajuste_langue:  ;selectionne le message adapté a la langue employé par le système
push eax
push ecx
mov eax,20
int 61h
xor ecx,ecx
cmp eax,"eng "
je @f
inc ecx
cmp eax,"fra "
je @f
xor ecx,ecx
@@:

boucle_ajuste_langue:
cmp ecx,0
je ok_ajuste_langue
cmp byte[edx],0
jne @f
dec ecx
@@:
inc edx
jmp boucle_ajuste_langue

ok_ajuste_langue:
pop ecx
pop eax
ret












;******************************************************************************************
sdata1:
org 0



carre:
dd 32
modemelange:
db 0
couleur24:
dd 0


texte:
dd 0,0,0,0,0,0,0,0

msg:
db "uniquement en mode video",13,0


msg256:
db "Press Enter to switch to 24bit mode",0
db "appuyez sur entrée pour passer en mode 24bits",0

msg24:
db "Press Enter to switch to 256 colors mode, click to change the axis colors",13
db "Up and down arrows, and Page Up and Page Down, to modify the third color",0
db "Appuyez sur entrée pour passer en mode 256 couleurs, cliquez pour changer les couleurs des axes",13
db "Fleche haut et bas, et Page Up et Down pour modifier la 3eme couleur",0


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