lc:   
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "liste les informations de base sur les cartes branché sur les bus pci et agp"
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
cmp ecx,0
je @f
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
@@:


mov al,6        
mov edx,msg1
call ajuste_langue
int 61h


mov ebx,80000000h
bouclecmdlc:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx
cmp ax,0FFFFh
je passecarte

mov ebp,eax
;écrit les données de la carte dans la ligne pré formatté
mov ecx,ebx
shr ecx,16
and ecx,0FFh
mov edx,bus
mov al,105
int 61h
mov byte[edx+2]," "
mov ax,[bus]
mov [bus2],ax

mov ecx,ebx
shr ecx,11
and ecx,01Fh
mov edx,carte
mov al,105
int 61h
mov byte[edx+2]," "
mov ax,[carte]
mov [carte2],ax


mov ecx,ebx
shr ecx,8
and ecx,07h
mov edx,fonction
mov al,105
int 61h
mov byte[edx+2]," "
mov eax,[fonction]
mov [fonction2],eax

mov ecx,ebp
and ecx,0FFFFh
mov edx,vendor
mov al,104
int 61h
mov byte[edx+4]," "
mov eax,[vendor]
mov [vendor2],eax

mov ecx,ebp
shr ecx,16
and ecx,0FFFFh
mov edx,id
mov al,104
int 61h
mov byte[edx+4]," "
mov eax,[id]
mov [id2],eax

mov dx,0CF8h
mov eax,ebx
add eax,8
out dx,eax
mov dx,0CFCh
in eax,dx
mov ebp,eax

mov ecx,ebp
shr ecx,24
and ecx,0FFh
mov edx,classe
mov al,105
int 61h
mov byte[edx+2],"."
mov ax,[classe]
mov [classe2],ax

mov ecx,ebp
shr ecx,16
and ecx,0FFh
mov edx,sousclasse
mov al,105
int 61h
mov byte[edx+2],"."
mov ax,[sousclasse]
mov [sousclasse2],ax

mov ecx,ebp
shr ecx,8
and ecx,0FFh
mov edx,progif
mov al,105
int 61h
mov byte[edx+2],13
mov ax,[progif]
mov [progif2],ax



;affiche la ligne des données
mov eax,6  
mov edx,desciption
call ajuste_langue
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


;recherche progif
mov eax,20h
shl eax,16
mov ax,[progif]
shl eax,8
mov al,"-"

boucle_recherche_progif:
cmp [ebx],eax
je affiche_progif
cmp word[ebx],02E00h
je findeligne
cmp word[ebx],02B00h
je findeligne
inc ebx
cmp ebx,ecx
je findeligne
jmp boucle_recherche_progif


affiche_progif:
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






mov edx,desciption
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





passecarte:
test ebx,0700h
jnz @f

mov eax,ebx
mov dx,0CF8h
add eax,0Ch
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,00800000h
jz simplefonction

@@:
add ebx,100h          ;on passe a la fonction suivante
test ebx,7F000000h
jz bouclecmdlc
int 60h

simplefonction:
add ebx,800h          ;on passe au device suivant
test ebx,7F000000h
jz bouclecmdlc
int 60h








;***************************
ajuste_langue:  ;selectionne le message adapté a la langue employé par le système
push eax
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
pop eax
ret








sdata1:
org 0


msg1:
db 13,"list of detected PCI and AGP devices:",13,0 
db 13,"liste des périphériques PCI et AGP détecté:",13,0 

desciption:
db "Bus:"
bus2:
dw 0   
db " Card:"
carte2:
dw 0
db " Function:"
fonction2:
dw 0
db " Vendor:"
vendor2:
dd 0
db " ID:"
id2:
dd 0
db " Classe:"
classe2:
dw 0
db "."
sousclasse2:
dw 0
db "."
progif2:
dw 0
db 13,0

db "Bus:"
bus:
dw 0   
db " Carte:"
carte:
dw 0
db " Fonction:"
fonction:
dw 0
db " Vendor:"
vendor:
dd 0
db " ID:"
id:
dd 0
db " Classe:"
classe:
dw 0
db "."
sousclasse:
dw 0
db "."
progif:
dw 0
db 13,0







DEB:
db 18h,0
VIRG:
db ",",0
CRLF:
db 17h,13,0




nom_bdd1:
db "LSPCI.CFG",0
handle_bdd1:
dd 0
taille_bdd1:
dd 0,0


nom_bdd2:
db "pci.ids",0     ;téléchargé depuis https://pci-ids.ucw.cz/v2.2/pci.ids
handle_bdd2:
dd 0
taille_bdd2:
dd 0,0

bdd2:
dd 0

bdd1:



sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
