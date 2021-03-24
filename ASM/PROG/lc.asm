lc:   
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "liste les informations de base sur les cartes branché sur les bus pci et agp"
scode:
org 0
mov ax,sel_dat1
mov ds,ax
mov es,ax

;ouvre le fichier
xor eax,eax
mov ebx,1
mov edx,nom_bdd
int 64h
cmp eax,0
jne pas_de_fichier
mov [handle_bdd],ebx


;lit taille fichier
mov ebx,[handle_bdd]
mov edx,taille_bdd
mov al,6
mov ah,1 ;fichier
int 64h
cmp eax,0
jne pas_de_fichier


;agrandit la zone mémoire pour pouvoir contenir le fichier
mov dx,sel_dat1
mov ecx,[taille_bdd]
add ecx,bdd+4
mov al,8
int 61h


;charge fichier
mov ebx,[handle_bdd]
mov ecx,[taille_bdd]
mov edx,0   ;offset dans le fichier
mov edi,bdd   ;offset dans le segment
mov al,4
int 64h
cmp eax,0
jne pas_de_fichier


mov ebx,bdd
mov ecx,[taille_bdd]
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
jmp liste_carte

pas_de_fichier:
mov dword[taille_bdd],0
mov dword[taille_bdd+4],0
liste_carte:


mov al,6        
mov edx,msg1
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

mov ecx,ebx
shr ecx,11
and ecx,01Fh
mov edx,carte
mov al,105
int 61h
mov byte[edx+2]," "

mov ecx,ebx
shr ecx,8
and ecx,07h
mov edx,fonction
mov al,105
int 61h
mov byte[edx+2]," "

mov ecx,ebp
and ecx,0FFFFh
mov edx,vendor
mov al,104
int 61h
mov byte[edx+4]," "

mov ecx,ebp
shr ecx,16
and ecx,0FFFFh
mov edx,id
mov al,104
int 61h
mov byte[edx+4]," "

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

mov ecx,ebp
shr ecx,16
and ecx,0FFh
mov edx,sousclasse
mov al,105
int 61h
mov byte[edx+2],"."

mov ecx,ebp
shr ecx,8
and ecx,0FFh
mov edx,progif
mov al,105
int 61h
mov byte[edx+2],13

;affiche la ligne des données
mov eax,6  
mov edx,desciption
int 61h

cmp dword[taille_bdd],0
je passecarte

;affiche le nom de la classe si on as accès a la base de donnée
pushad
mov ebx,bdd
add ecx,[taille_bdd]
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


passecarte:
mov dx,0CF8h
mov eax,ebx
add eax,0Ch
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,00800000h
;jz simplefonction

add ebx,100h          ;on passe a la fonction suivante
test ebx,7F000000h
jz bouclecmdlc
int 60h


simplefonction:
add ebx,800h          ;on passe au device suivant
and ebx,0FFFFF800h
test ebx,7F000000h
jz bouclecmdlc
int 60h



sdata1:
org 0


msg1:
db 13,"liste des périphériques PCI et AGP détecté:",13,0 

desciption:
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




nom_bdd:
db "PCICLASS.TXT",0
handle_bdd:
dd 0
taille_bdd:
dd 0,0

bdd:



sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
