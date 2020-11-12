bidon:
pile equ 40960 ;definition de la taille de la pile
include "fe.inc"
db "manuel en ligne de commande"
scode:
org 0

mov ax,sel_dat1  ;choisi le segment de donnée, ici le segment de données N°1
mov ds,ax
mov es,ax



;**************************************************************
;determine le nom de la commande a rechercher
mov byte[commande],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,128 ;0=256 octet max
mov edx,commande
int 61h

cmp byte[commande],0
je aff_err_param


;**************************************************************
;determine le nom du fichier ou se trouve les informations
mov byte[zt_recep],0

mov al,4   
mov ah,1   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h







;***********************************
;ouvre le fichier
mov edx,zt_recep
cmp byte[edx],0
jne ok_ouvrir
mov edx,fichier
ok_ouvrir:
xor eax,eax
mov bx,0
int 64h
cmp eax,0
jne aff_err_fichier
mov [handle],ebx


;lit taille fichier
mov ebx,[handle]
mov edx,taille
mov al,6
mov ah,1 ;fichier
int 64h
cmp eax,0
jne aff_err_fichier


add dword[taille],zt_recep



;charge fichier
mov ebx,[handle]
mov ecx,[taille]
mov edx,0   ;offset dans le fichier
mov edi,zt_recep   ;offset dans le segment
mov al,4
int 64h
cmp eax,0
jne aff_err_fichier




;transforme cr et lf en zéros
mov ebx,zt_recep
boucle_transf_zero:
cmp byte[ebx],10
je transf_zero
cmp byte[ebx],13
jne ntransf_zero
transf_zero:
mov byte[ebx],0
ntransf_zero:
inc ebx
cmp [taille],ebx
jne boucle_transf_zero




;recherche
mov ebx,zt_recep
boucle_recherche:
cmp byte[ebx],":"
jne suite_recherche 

mob edi,ebx
inc edi
mov esi,commande

boucle_test_nom:
mov al,[edi]
cmp al,0
je nom_ok
cmp [esi],al
jne suite_recherche
inc edi
inc esi
jmp boucle_test_nom 
 


suite_recherche:
call atteint_ligne_suivante
cmp ebx,[taille]
jb boucle_recherche
jmp aff_err_commande











nom_ok:
call atteint_ligne_suivante


afficheligne:
mov al,6
mov edx,ebx
inc edx
cmp byte[ebx],":"
je fin
int 61h
mov al,6
mov edx,msg_crlf
int 61h

call atteint_ligne_suivante
cmp ebx,[taille]
jb afficheligne
fin:
int 60h




atteint_ligne_suivante:
cmp word[ebx],0
je fin_ligne_trouve2
cmp byte[ebx],0
je fin_ligne_trouve1
inc ebx
cmp ebx,[taille]
jne atteint_ligne_suivante
ret

fin_ligne_trouve2:
inc ebx
fin_ligne_trouve1:
inc ebx
ret











;*****************************************************************************************
aff_err_commande:
mov al,6        ;fonction n°6: ecriture d'une chaine dans le journal
mov edx,msg1    ;adresse du message a afficher
int 61h         ;appel fonction systeme générales
mov al,6
mov edx,commande
int 61h
mov al,6
mov edx,msg2
int 61h
int 60h


aff_err_param:
mov al,6
mov edx,msg3
int 61h
int 60h  


aff_err_fichier:
mov al,6
mov edx,msg4
int 61h
int 60h  

;*******************************************************
sdata1:   ;données dans le segment de donnée N°1
org 0

msg1:
db 13,"MAN: aucune entrée dans le manuel concernant ",22h,0
msg2:
db 22h,13,0
msg3:
db 13,"MAN: erreur dans les parametres de la commande",13,0
msg4:
db 13,"MAN: erreur d'acces au fichier du manuel",13,0

msg_crlf:
db 13,17h,0

fichier:
db "MANUEL.TXT",0
handle:
dd 0
taille:
dd 0,0

commande:
rb 128
zt_recep:
rb 100000h


sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
