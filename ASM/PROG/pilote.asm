pilote.fe:
pile equ 40960 ;definition de la taille de la pile
include "fe.inc"
db "cherche le bon pilote d'un périphérique"
scode:
org 0

mov ax,sel_dat1
mov ds,ax
mov es,ax

;récupère l'adresse du périphérique
mov al,4   
mov ah,1   ;numéros de l'option de commande a lire
mov cl,16
mov edx,adresse
int 61h

;récupère le type de périphérique
mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,8
mov edx,nom_type
int 61h


cmp dword[nom_type],"pci"
je type_pci
;cmp dword[nom_type],"usb"
;je type_usb


mov edx,msg_type
call ajuste_langue
mov al,6
int 61h
int 60h

type_pci:
mov edx,bdd_pci
;jmp @f

;type_usb:
;mov edx,bdd_usb
;jmp @f

@@:






;ouvre le fichier de base de donnée des classe
xor eax,eax
mov ebx,1
int 64h
cmp eax,0
jne erreur_bdd
mov [handle_bdd],ebx


;lit taille fichier
mov ebx,[handle_bdd]
mov edx,taille_bdd
mov al,6
mov ah,1 ;fichier
int 64h
cmp eax,0
jne erreur_bdd

;agrandit la zone mémoire pour pouvoir contenir les fichiers
mov dx,sel_dat1
mov ecx,[taille_bdd]
add ecx,bdd+1
mov al,8
int 61h
cmp eax,0
jne erreur_bdd


;charge fichier de base de donnée des classe
mov ebx,[handle_bdd]
mov ecx,[taille_bdd]
mov edx,0   ;offset dans le fichier
mov edi,bdd   ;offset dans le segment
mov al,4
int 64h
cmp eax,0
jne erreur_bdd


;transforme les caractère de fin de ligne
mov edi,bdd
mov esi,bdd
add edi,[taille_bdd]
boucle_prep:
cmp byte[esi],20h
jae @f
mov byte[esi],0
@@:
inc esi
cmp esi,edi
jne boucle_prep




cmp dword[nom_type],"pci"
je rech_pci_simple
;cmp dword[nom_type],"usb"
;je rech_usb_simple
int 60h




;rech_usb_simple:
;?????????????
;int 60h


rech_pci_simple:
cmp byte[adresse],0
je rech_pci_multiple
cmp byte[adresse],"-"
je rech_pci_multiple


cmp byte[adresse+2],":"
jne erreur_add
cmp byte[adresse+5],"."
jne erreur_add




mov ebx,80000000h

mov edx,adresse
mov eax,101
int 61h
shl ecx,16
or ebx,ecx

mov edx,adresse+3
mov eax,101
int 61h
shl ecx,11
or ebx,ecx

mov edx,adresse+6
mov eax,101
int 61h
shl ecx,8
or ebx,ecx



mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx ;MSB(eax)=id LSB(eax)=vendor
call cherche_base
int 60h


rech_pci_multiple:
mov byte[silence],1
mov ebx,80000000h
boucle_rech_pci:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx ;MSB(eax)=id LSB(eax)=vendor
cmp eax,0FFFFFFFFh
je @f
call cherche_base
@@:


test ebx,0700h
jnz simplefonction 

mov eax,ebx
mov dx,0CF8h
add eax,0Ch
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,00800000h
jz simplefonction

add ebx,100h          ;on passe a la fonction suivante
test ebx,7F000000h
jz boucle_rech_pci
int 60h


simplefonction:
add ebx,800h          ;on passe au device suivant
and ebx,0FFFFF800h
test ebx,7F000000h
jz boucle_rech_pci
int 60h








erreur_bdd:
mov edx,msg_bdd
call ajuste_langue
mov al,6
int 61h
int 60h


erreur_add:
mov edx,msg_add
call ajuste_langue
mov al,6
int 61h
int 60h

;***************************
cherche_base:
pushad
;converti les id en chaines
push eax
xor ecx,ecx
mov cx,ax
mov eax,104
mov edx,clef
int 61h
pop ecx
shr ecx,16
mov eax,104
mov edx,clef+5
int 61h

mov byte[clef+4]," "
mov byte[clef+9],13
mov byte[clef+10],0

mov edi,bdd
mov esi,bdd
add edi,[taille_bdd]

boucle_cherche:
mov eax,[clef]
mov edx,[clef+5]
cmp [esi],eax
jne suite_cherche 
cmp byte[esi+4]," "
jne suite_cherche 
cmp [esi+5],edx
jne suite_cherche 
cmp byte[esi+9]," "
jne suite_cherche 


;copie le debut de la commande
add esi,10
mov edi,commande
@@:
lodsb
cmp al,0
je @f
stosb
jmp @b

@@:
;ajoute l'adresse pci
;bus
mov ecx,ebx
shr ecx,16
and ecx,0FFh
mov edx,edi
inc edx
mov eax,105
int 61h

;carte
mov ecx,ebx
shr ecx,11
and ecx,1Fh
mov edx,edi
add edx,4
mov eax,105
int 61h

;fonction
mov ecx,ebx
shr ecx,8
and ecx,0Fh
mov edx,edi
add edx,7
mov eax,105
int 61h

mov byte[edi]," "
mov byte[edi+3],":"
mov byte[edi+6],"."
mov byte[edi+8],0


;envoie la commande
mov al,0
mov edx,commande
int 61h

popad
ret





suite_cherche:
inc esi
cmp esi,edi
jae nt_cherche

cmp byte[esi],0
jne suite_cherche 
cmp byte[esi+1],0
je suite_cherche 
inc esi
cmp esi,edi
jb boucle_cherche

nt_cherche:
cmp byte[silence],0
jne @f
mov edx,msg_nt
call ajuste_langue
mov al,6
int 61h
@@:
popad
ret





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


bdd_pci:
db "PILOTEPCI.CFG",0
;bdd_usb:
;db "PILOTEUSB.CFG",0

msg_type:
db "PILOTE: unknown device type",13,0
db "PILOTE: type de périphérique inconnue",13,0


msg_bdd:
db "PILOTE: error loading the database",13,0
db "PILOTE: erreur lors du chargement de la base de donnée",13,0

msg_add:
db "PILOTE: error in address format",13,0
db "PILOTE: erreur dans le format de l'adresse",13,0

msg_nt:
db "PILOTE: no driver was found for the device",13,0
db "PILOTE: aucuns pilote n'a été trouvé pour le périphérique",13,0

silence:
db 0
nom_type:
dd 0,0
adresse:
rb 16

clef:
rb 12


handle_bdd:
dd 0
taille_bdd:
dd 0,0

commande:
rb 256

bdd:




sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
