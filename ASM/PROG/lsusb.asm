﻿lc:   
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "liste les informations de base sur les périphérique usb branché"
scode:
org 0
mov ax,sel_dat1
mov ds,ax
mov es,ax


;ouvre le fichier de base de donnée des classe
xor eax,eax
mov ebx,1
mov edx,nom_bdd1
int 64h
cmp eax,0
jne @f
mov [handle_bdd1],ebx


;lit taille fichier
mov ebx,[handle_bdd1]
mov edx,taille_bdd1
mov al,6
mov ah,1 ;fichier
int 64h
cmp eax,0
je @f
mov dword[taille_bdd1],0
mov dword[taille_bdd1+4],0
@@:


;ouvre le fichier de base de donnée des noms
xor eax,eax
mov ebx,1
mov edx,nom_bdd2
int 64h
cmp eax,0
jne @f
mov [handle_bdd2],ebx


;lit taille fichier
mov ebx,[handle_bdd2]
mov edx,taille_bdd2
mov al,6
mov ah,1 ;fichier
int 64h
cmp eax,0
je @f
mov dword[taille_bdd2],0
mov dword[taille_bdd2+4],0
@@:



;agrandit la zone mémoire pour pouvoir contenir les fichiers
mov dx,sel_dat1
mov ecx,[taille_bdd1]
add ecx,bdd1+4
mov [bdd2],ecx ;on en profite pour sauvegarder la position de la bdd des noms
add ecx,[taille_bdd2]
mov al,8
int 61h


;charge fichier de base de donnée des classe
mov ebx,[handle_bdd1]
mov ecx,[taille_bdd1]
mov edx,0   ;offset dans le fichier
mov edi,bdd1   ;offset dans le segment
mov al,4
int 64h
cmp eax,0
je @f
mov dword[taille_bdd1],0
mov dword[taille_bdd1+4],0
@@:

;charge fichier de base de donnée des noms
mov ebx,[handle_bdd2]
mov ecx,[taille_bdd2]
mov edx,0   ;offset dans le fichier
mov edi,[bdd2]   ;offset dans le segment
mov al,4
int 64h
cmp eax,0
je @f
mov dword[taille_bdd2],0
mov dword[taille_bdd2+4],0
@@:


;remplace tout les marqueurs de fin de ligne par des zéro
mov ebx,bdd1
mov ecx,[taille_bdd1]
add ecx,[taille_bdd2]
bc_raz:
cmp byte[ebx],10
je ok_raz
cmp byte[ebx],13
jne nok_raz
ok_raz:
mov byte[ebx],0
nok_raz:
inc ebx
dec ecx
jne bc_raz


;*******************************************************************************
mov al,6        
mov edx,msg2
int 61h



mov byte[adresse_usb],1
bouclecmdlu:


mov eax,2
mov bl,[adresse_usb]
mov bh,0   ;terminaison
mov dl,0   ;index du descripteur
mov dh,1   ;type de descripteur (appareil)
mov edi,descripteur_usb
int 68h
cmp eax,0
jne passeusb


xor ecx,ecx
mov cl,[adresse_usb]
mov edx,adresse
mov dword[edx],0
mov al,102
int 61h
or dword[edx],20202020h


mov ecx,[descripteur_usb+8]
and ecx,0FFFFh
mov edx,vendor
mov al,104
int 61h
mov byte[edx+4]," "


mov ecx,[descripteur_usb+10]
and ecx,0FFFFh
mov edx,id
mov al,104
int 61h
mov byte[edx+4]," "


mov ecx,[descripteur_usb+4]
and ecx,0FFh
mov edx,classe
mov al,105
int 61h
mov byte[edx+2],","


mov ecx,[descripteur_usb+5]
and ecx,0FFh
mov edx,sousclasse
mov al,105
int 61h
mov byte[edx+2],13



mov al,6        
mov edx,description
int 61h





;**************************************************************
;affiche la classe si on as accès a la base de donnée
pushad
mov ebx,bdd1
mov ecx,[taille_bdd1]
cmp ecx,0
je passeligne
add ecx,ebx


;recherche la classe
mov eax,20h
shl eax,16
mov ax,[classe]
shl eax,8
mov al,"+"

boucle_recherche_classe:
cmp [ebx],eax
je affiche_classe
inc ebx
cmp ebx,ecx
je passeligne
jmp boucle_recherche_classe


affiche_classe:
push ebx
push ecx
mov edx,DEB
mov eax,6
int 61h
mov edx,ebx
add edx,4
mov eax,6
int 61h
pop ecx
pop ebx


;recherche la sous classe
mov eax,20h
shl eax,16
mov ax,[sousclasse]
shl eax,8
mov al,"."

boucle_recherche_sousclasse:
cmp [ebx],eax
je affiche_sousclasse
cmp word[ebx],02B00h
je findeligne
inc ebx
cmp ebx,ecx
je findeligne
jmp boucle_recherche_sousclasse


affiche_sousclasse:
push ebx
push ecx
mov edx,VIRG
mov eax,6
int 61h
mov edx,ebx
add edx,4
mov eax,6
int 61h
pop ecx
pop ebx



findeligne:
mov edx,CRLF
mov eax,6
int 61h
passeligne:
popad






;**************************************************************
;affiche le fabriquant/nom si on as accès a la base de donnée


mov edx,description
boucle:
cmp byte[edx],0
je fin

cmp byte[edx],"A"
jb @f
cmp byte[edx],"Z"
ja @f
add byte[edx],20h
@@:
inc edx
jmp boucle 

fin:




pushad
mov ebx,[bdd2]
mov ecx,[taille_bdd2]
cmp ecx,0
je passeligne2
add ecx,ebx



;recherche le vendor
mov eax,[vendor]

boucle_recherche_vendor:
cmp [ebx],eax
je vendor_trouve
@@:
inc ebx
cmp ebx,ecx
je passeligne2
cmp byte[ebx],0
jne @b 
inc ebx
jmp boucle_recherche_vendor

vendor_trouve:
mov edx,DEB
mov eax,6
int 61h
add ebx,6
mov edx,ebx
mov eax,6
int 61h


;recherche le nom
mov eax,[id]

boucle_recherche_nom:
cmp byte[ebx],9
jne @f
inc ebx
cmp [ebx],eax
je nom_trouve
@@:
inc ebx
cmp ebx,ecx
je findeligne2
cmp byte[ebx],0
jne @b 
inc ebx
jmp boucle_recherche_nom

nom_trouve:
mov edx,VIRG
mov eax,6
int 61h
add ebx,6
mov edx,ebx
mov eax,6
int 61h



findeligne2:
mov edx,CRLF
mov eax,6
int 61h

passeligne2:
popad




;**********************************************************
passeusb:
inc byte[adresse_usb]
cmp byte[adresse_usb],128
jne bouclecmdlu
int 60h



sdata1:
org 0


msg2:
db 13,"liste des périphériques USB détecté:",13,0 

description:
db "Adresse:"
adresse:
dd 0
db "Vendor:"
vendor:
dd 0
db " ID:"
id:
dd 0
db " Classe:"
classe:
dw 0
db ",Sous-Classe:"
sousclasse:
dw 0
db 13,0


DEB:
db 18h,0
VIRG:
db ",",0
CRLF:
db 17h,13,0




nom_bdd1:
db "USBCLASS.TXT",0
handle_bdd1:
dd 0
taille_bdd1:
dd 0,0


nom_bdd2:
db "usb.ids",0     ;téléchargé depuis http://www.linux-usb.org/usb.ids
handle_bdd2:
dd 0
taille_bdd2:
dd 0,0

bdd2:
dd 0

adresse_usb:
db 0
descripteur_usb:
rb 1024



bdd1:



sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
