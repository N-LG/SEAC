bidon:
pile equ 4960 ;definition de la taille de la pile
include "fe.inc"
db "manuel en ligne de motclef"
scode:
org 0

mov ax,sel_dat1  ;choisi le segment de donnée, ici le segment de données N°1
mov ds,ax
mov es,ax


;rendre propre les labels
;ameliorer l'affichage de la liste des labels

;**************************************************************
;determine le nom de la motclef a rechercher
mov byte[motclef],0

mov al,4   
mov ah,0   ;numéros de l'option de motclef a lire
mov cl,128 ;0=256 octet max
mov edx,motclef
int 61h

cmp byte[motclef],0
je aff_err_param


;**************************************************************
;determine le nom du fichier ou se trouve les informations
mov byte[zt_recep],0

mov al,4   
mov ah,1   ;numéros de l'option de motclef a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h



;***********************************
;ouvre le fichier
mov edx,zt_recep
mov ebx,0
cmp byte[edx],0
jne ok_ouvrir
mov edx,fichier
mov ebx,1
ok_ouvrir:
xor eax,eax
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


;agrandit la zone mémoire pour pouvoir contenir le fichier
mov dx,sel_dat1
mov ecx,[taille]
add ecx,zt_recep+1
mov al,8
int 61h


;charge fichier
mov ebx,[handle]
mov ecx,[taille]
mov edx,0   ;offset dans le fichier
mov edi,zt_recep   ;offset dans le segment
mov al,4
int 64h
cmp eax,0
jne aff_err_fichier


add dword[taille],zt_recep


;transforme cr et lf en zéros et ~ en marque de liens
mov ecx,[taille]
mov ebx,zt_recep
mov al,13h
;add ecx,ebx

boucle_transf:
cmp byte[ebx],10
je transf_zero
cmp byte[ebx],13
je transf_zero
cmp word[ebx],7E7Eh      ;~~
je doubletidle
cmp byte[ebx],"~"
je transf_tidle
jmp ignore_transf

doubletidle:
mov word[ebx],177Eh
jmp ignore_transf


transf_tidle:
mov byte[ebx],al
cmp al,17h
je transf_tidle2
mov al,17h
jmp ignore_transf

transf_tidle2:
mov al,13h
jmp ignore_transf

transf_zero:
mov byte[ebx],0
mov al,13h

ignore_transf:
inc ebx
cmp ebx,ecx
jne boucle_transf


;si c'est * le mot clef, on affiche la liste des mots clefs
cmp word[motclef],"*"
je liste_motclef


;*******************************************
;passe le mot clef en minuscule
mov ebx,motclef
boucle_minuscule:
cmp byte[ebx],"A"
jb suite_minuscule
cmp byte[ebx],"Z"
ja suite_minuscule
add byte[ebx],20h
suite_minuscule:
inc ebx
cmp ebx,motclef+128
jne boucle_minuscule



;***********************************************
;recherche
mov ebx,zt_recep
boucle_recherche:
cmp byte[ebx],":"
jne suite_recherche 

mov edi,ebx
inc edi
mov esi,motclef

boucle_test_nom:
mov al,[edi]
mov ah,[esi]

cmp ax,0
je nom_ok
cmp ax,":"
je nom_ok
cmp al,0
je suite_recherche 
cmp al,ah
jne autrenom
inc edi
inc esi
jmp boucle_test_nom 
 
autrenom:
cmp byte[edi],0
je suite_recherche 
cmp byte[edi],":"
je continue_recherche
inc edi
jmp autrenom

continue_recherche:
inc edi
mov esi,motclef
jmp boucle_test_nom

suite_recherche:
call atteint_ligne_suivante
cmp ebx,[taille]
jb boucle_recherche
jmp aff_err_motclef


nom_ok:
call atteint_ligne_suivante
mov al,6
mov edx,msg5
int 61h
mov al,6
mov edx,motclef
int 61h
mov al,6
mov edx,msg2
int 61h

afficheligne:
cmp byte[ebx],"%"
je coul_blanc
cmp byte[ebx],"^"
jne suite_affligne

mov al,6
mov edx,vert
int 61h
jmp suite_affligne

coul_blanc:
mov al,6
mov edx,blanc
int 61h

suite_affligne:
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



;******************************************************************************************
liste_motclef:
mov al,6
mov edx,msg6
int 61h

mov ebx,zt_recep

boucle_liste:
cmp byte[ebx],":"
jne suite_liste

mov al,6
mov edx,ebx
int 61h

suite_liste:
call atteint_ligne_suivante
cmp ebx,[taille]
jb boucle_liste

mov al,6
mov edx,msg_crlf
int 61h
int 60h








;*****************************************************************************************
aff_err_motclef:
mov al,6        ;fonction n°6: ecriture d'une chaine dans le journal
mov edx,msg1    ;adresse du message a afficher
int 61h         ;appel fonction systeme générales
mov al,6
mov edx,motclef
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
db 13,"MAN: erreur dans les parametres de la motclef",13,0
msg4:
db 13,"MAN: erreur d'acces au fichier du manuel",13,0
msg5:
db 13,"MAN: contenu de la rubrique ",22h,0
msg6:
db 13,"MAN: liste des rubriques disponibles:",13,0
msg7:
db " ",0

msg_crlf:
db 13,17h,0

blanc:
db 1Fh,0
vert:
db 1Ah,0


fichier:
db "MANUEL.TXT",0
handle:
dd 0
taille:
dd 0,0

motclef:
rb 128
zt_recep:
rb 512

sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
