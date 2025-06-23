jn2:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "sorte de snake"
scode:
org 0


bord equ 30


;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax
mov fs,ax

redim_ecran:
mov al,0
mov ah,2   ;option=mode video
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
fs
or byte[at_console],8h


;calcul des parametres d'affichage
mov ecx,bord
xor eax,eax
xor edx,edx
fs
mov ax,[resy_ecran]
div ecx
mov [carre],eax
push edx
shr edx,1
mov [oy],edx
pop edx
xor eax,eax
fs
mov ax,[resy_ecran]
sub eax,edx
xor edx,edx
fs
mov dx,[resx_ecran]
sub edx,eax
shr edx,1
mov [ox],edx


;réinitialisation apres avoir perdu
perdu:
mov dword[score],16
mov word[zt_serpent],bord/2
mov word[zt_serpent+2],bord/2-2
mov word[zt_serpent+4],bord/2
mov word[zt_serpent+6],bord/2-1
mov word[zt_serpent+8],bord/2
mov word[zt_serpent+10],bord/2
mov word[zt_serpent+12],bord/2
mov word[zt_serpent+14],bord/2+1
mov word[zt_serpent+16],bord/2
mov word[zt_serpent+18],bord/2+2
mov byte[sens],3


;nouvelle pomme pseudo aléatoire
nv_pomme:
mov al,12
int 61h
xor eax,edx
xor eax,5A2E91D7h
mov ecx,bord-2
xor edx,edx
div ecx
inc edx
mov [px],edx
xor edx,edx
div ecx
inc edx
mov [py],edx

;*******************
boucle:

;calcule le déplacement de la tête
mov esi,[score]
mov bx,[esi+zt_serpent]
mov cx,[esi+zt_serpent+2]
cmp byte[sens],0
jne @f
inc bx
@@:
cmp byte[sens],1
jne @f
dec cx
@@:
cmp byte[sens],2
jne @f
dec bx
@@:
cmp byte[sens],3
jne @f
inc cx
@@:

;test si débordement = perdu
cmp bx,-1
je perdu
cmp cx,-1
je perdu
cmp cx,-1
je perdu
cmp bx,bord
je perdu
cmp cx,bord
je perdu

;test si contacte avec le serpent
mov esi,[score]
add esi,zt_serpent-4

test_serpent:
cmp [esi],bx
jne @f
cmp [esi+2],cx
je perdu
@@:

cmp esi,zt_serpent
je @f
sub esi,4
jmp test_serpent
@@:



;test si présence pomme
cmp bx,[px]
jne @f
cmp cx,[py]
jne @f
add dword[score],4
mov esi,[score]
mov [esi+zt_serpent],bx
mov [esi+zt_serpent+2],cx
jmp nv_pomme
@@:

;avance le serpent
push ecx
mov edi,zt_serpent
mov esi,zt_serpent+4
mov ecx,[score]
cld
rep movsb
pop ecx
mov esi,[score]
mov [esi+zt_serpent],bx
mov [esi+zt_serpent+2],cx


;efface l'ecran
xor esi,esi
xor edi,edi
xor ebx,ebx
xor ecx,ecx
xor edx,edx
fs
mov si,[resx_ecran]
fs
mov di,[resy_ecran]
mov al,22
mov ah,8
int 63h                                      


;affiche le plateau de jeu
mov eax,[carre]
mov ecx,bord
mul ecx
mov esi,eax
mov edi,eax
mov ebx,[ox]
mov ecx,[oy]
add esi,ebx
add edi,ecx
mov al,22
mov ah,8
mov edx,191  ;vert dégeux
int 63h


;affiche la pomme
mov ecx,[carre]
mov eax,[px]
mul ecx
mov ebx,eax
mov eax,[py]
mul ecx
mov ecx,eax
add ebx,[ox]
add ecx,[oy]
mov esi,ebx
mov edi,ecx
add esi,[carre]
add edi,[carre]
mov al,22
mov ah,8
mov edx,40  ;rouge vif
int 63h


;affiche le serpent
mov esi,[score]
add esi,zt_serpent-4

boucle_serpent:
mov ecx,[carre]
xor eax,eax
mov ax,[esi]
mul ecx
mov ebx,eax
xor eax,eax
mov ax,[esi+2]
mul ecx
mov ecx,eax
add ebx,[ox]
add ecx,[oy]
push esi
mov esi,ebx
mov edi,ecx
add esi,[carre]
add edi,[carre]
mov al,22
mov ah,8
mov edx,15  ;blanc
int 63h
pop esi

cmp esi,zt_serpent
je @f
sub esi,4
jmp boucle_serpent
@@:



;affiche le score
mov ecx,[score]
shr ecx,2
sub ecx,4
mov al,102
mov edx,texte
int 61h

mov al,25
mov ah,15
xor ebx,ebx
xor ecx,ecx
int 63h

mov eax,7  ;demande la mise a jour ecran
int 63h


;attent 75ms
mov al,1
mov ecx,30
int 61h


mov al,5
int 63h
cmp al,1
je fin
cmp al,82
je haut
cmp al,84
je bas
cmp al,85
je droite
cmp al,83
je gauche
jmp boucle

haut:
cmp byte[sens],3
je boucle
mov byte[sens],1
jmp boucle

bas:
cmp byte[sens],1
je boucle
mov byte[sens],3
jmp boucle

droite:
cmp byte[sens],2
je boucle
mov byte[sens],0
jmp boucle

gauche:
cmp byte[sens],0
je boucle
mov byte[sens],2
jmp boucle

fin:
int 60h


;******************************************************************************************
sdata1:
org 0

sens:
db 3  ;0=droite 1=haut 2=gauche 3=bas 

;position de la pomme
px:
dd 0
py:
dd 0

;origine du plateau de jeu
ox:
dd 0
oy:
dd 0



score:
dd 16

carre:
dd 32

texte:
dd 0,0,0,0,0,0,0,0

msg:
db "uniquement en mode video",13,0


zt_serpent:
dw 32,30
dw 32,31
dw 32,32
dw 32,33
dw 32,34
rb 2048

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