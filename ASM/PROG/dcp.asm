﻿dcp:


macro trappe val
{
pushad

mov byte[msgtrappe],val
mov byte[msgtrappe+1],13
mov byte[msgtrappe+2],0
mov edx,msgtrappe
call affmsg

popad
}


pile equ 24096 ;definition de la taille de la pile
include "fe.inc"
db "Décompression de fichier pkzip gzip et tar"
scode:
org 0
mov al,8
mov ecx,zt_transfert
add ecx,512
mov dx,sel_dat1
int 61h

mov ax,sel_dat1
mov ds,ax
mov es,ax
mov fs,ax



;lit l'option e (ecraser les fichier deja existant)
mov al,5   
mov ah,"e"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,nom_1
int 61h
cmp eax,0
jne @f
mov byte[option_e],1
@@:



;lit l'option o (dossier de destination)
mov al,5   
mov ah,"o"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,nom_1
int 61h
cmp eax,0
jne @f
mov edx,nom_1
call ouvre_fichier
cmp eax,0
jne @f
mov [handle_0],ebx
@@:






mov cl,0
mov edx,nom_1
call lire_arg

mov edx,nom_1
call ouvre_fichier
cmp eax,0
jne erreur_ouverture_archive

mov [handle_1],ebx
call taillef
cmp eax,0
jne erreur_ouverture_archive
sub ecx,16
mov [taille_1],ecx


mov ebx,[handle_1]  ;lit les 16 premier octets 
mov ecx,16
mov edx,0
mov edi,chaine_temporaire
call lit_fichier
cmp eax,0
jne erreur_lecture_archive

cmp dword[chaine_temporaire],04034B50h
je pkzip

mov edx,msg_erreur_format_inconnue
call affmsg
jmp fin






;**********************************************************************************************************
pkzip:
mov dword[index_fichier],0
boucle_pkzip:


mov ebx,[handle_1]  ;lit les 32 premier octets 
mov ecx,32
mov edx,[index_fichier]
mov edi,chaine_temporaire
call lit_fichier
cmp eax,0
jne erreur_lecture_archive

cmp dword[chaine_temporaire],04034B50h
jne fin

mov ebx,[handle_1]  ;lit le nom
xor ecx,ecx
mov cx,[chaine_temporaire+1Ah]
mov edx,[index_fichier]
add edx,1Eh
mov edi,nom_2
call lit_fichier
cmp eax,0
jne erreur_lecture_archive
xor ebx,ebx
mov bx,[chaine_temporaire+1Ah]  ;taille du nom
mov byte[nom_2+ebx],0


;réserve une ZT suffisante
mov ecx,[chaine_temporaire+12h]
add ecx,[chaine_temporaire+16h]
cmp ecx,0
je suite2_boucle_pkzip
cmp ecx,[taille_zt]
jbe @f
mov [taille_zt],ecx
mov al,8   ;agrandit la zone de transfert si besoin
add ecx,zt_transfert
mov dx,sel_dat1
int 61h
@@:

;créer le fichier
mov edx,nom_2
call cree_fichier
cmp eax,0
je pkzip_okcree

;si le fichier existe déja et si l'option -e est active on écrase le fichier
cmp eax,cer_nfr
jne pkzip_err_cre
cmp byte[option_e],1
jne pkzip_err_cre

;ouvre le fichier
mov al,0 
mov bx,[handle_0]
mov edx,nom_2
int 64h
cmp eax,0
jne pkzip_err_cre

;fixe la taille du fichier
mov dword[zt_transfert],0
mov dword[zt_transfert+4],0
mov al,7
mov ah,1 ;taille fichier
mov edx,zt_transfert
int 64h
cmp eax,0
jne pkzip_err_cre

pkzip_okcree:
mov [handle_2],ebx

;lire les données
mov ebx,[handle_1]  
mov ecx,[chaine_temporaire+12h]
xor edx,edx
xor eax,eax
mov dx,[chaine_temporaire+1Ch]  ;taille du champ extra
mov ax,[chaine_temporaire+1Ah]  ;taille du nom
add edx,[index_fichier]
add edx,1Eh
add edx,eax
mov edi,zt_transfert
call lit_fichier
cmp eax,0
jne pkzip_err_lec


cmp word[chaine_temporaire+8],0   ;sans compression
je pkzip_type0
cmp word[chaine_temporaire+8],8   ;compression deflate (rfc1951)
je pkzip_type8


mov edx,msg_erreur_deco1  ;type de compression non reconnu
call affmsg
mov edx,nom_2
call affmsg
mov edx,msg_erreur_deco2
call affmsg
xor ecx,ecx
mov eax,102
mov cx,[chaine_temporaire+8]
mov edx,zt_transfert
int 61h
mov edx,zt_transfert
call affmsg
mov edx,msg_erreur_deco3
call affmsg
jmp suite2_boucle_pkzip


pkzip_type0:
mov esi,zt_transfert
jmp suite_boucle_pkzip


;*********
pkzip_type8:
mov edi,zt_transfert
mov esi,zt_transfert
add edi,[chaine_temporaire+12h]
mov eax,152
int 61h
cmp eax,0
jne pkzip_err_dec

;mov edx,zt_transfert
;add edx,[chaine_temporaire+12h]
;push edx
;add edx,[chaine_temporaire+16h]
;dec edx
;mov byte[edx],0
;pop edx
;mov al,6
;int 61h




mov esi,zt_transfert
add esi,[chaine_temporaire+12h]
;jmp suite_boucle_pkzip



suite_boucle_pkzip:
;ecrire les données
mov ebx,[handle_2]
mov ecx,[chaine_temporaire+16h]
xor edx,edx
mov al,5
int 64h
cmp eax,0
jne pkzip_err_ecr

;fermer le fichier
mov ebx,[handle_2]
call ferme_fichier

mov edx,msg_ok_deco1
call affmsg
mov edx,nom_2
call affmsg
mov edx,msg_ok_deco2
call affmsg

suite2_boucle_pkzip:
mov eax,[chaine_temporaire+12h] ;taille compressé
xor ebx,ebx
xor ecx,ecx
add eax,1Eh
mov bx,[chaine_temporaire+1Ah]  ;taille du nom
mov cx,[chaine_temporaire+1Ch]  ;taille du champ extra
add eax,ebx
add eax,ecx
add [index_fichier],eax
jmp boucle_pkzip 





pkzip_err_cre:
mov edx,msg_erreur_cre1
call affmsg
mov edx,nom_2
call affmsg
mov edx,msg_erreur_cre2
call affmsg
jmp suite2_boucle_pkzip

pkzip_err_lec:
mov edx,msg_erreur_lec1
call affmsg
mov edx,nom_2
call affmsg
mov edx,msg_erreur_lec2
call affmsg
jmp suite2_boucle_pkzip


pkzip_err_dec:
mov edx,msg_erreur_dec1
call affmsg
mov edx,nom_2
call affmsg
mov edx,msg_erreur_dec2
call affmsg
jmp suite2_boucle_pkzip


pkzip_err_ecr:
mov edx,msg_erreur_ecr1
call affmsg
mov edx,nom_2
call affmsg
mov edx,msg_erreur_ecr2
call affmsg
jmp suite2_boucle_pkzip



;**********************************************************************************************************
gzip:
;?????????????????????
jmp fin



;**********************************************************************************************************
tar:
;?????????????????????
jmp fin





pushad
mov ecx,ebx
mov edx,msgtrappe
mov eax,103
int 61h
mov eax,6
int 61h
popad
trappe "B"







;**************************************************************************************************************


erreur_ouverture_archive:
mov edx,msg_erreur_ouverture_archive
call affmsg
jmp fin

erreur_format_inconnue:
mov edx,msg_erreur_format_inconnue
call affmsg
jmp fin

erreur_lecture_archive:
mov edx,msg_erreur_lecture_archive
call affmsg

fin:
include "nlg_se.inc"



msg_erreur_ouverture_archive:
db "DCP: erreur pour ouvrir l'archive",13,0

msg_erreur_lecture_archive:
db "DCP: erreur lors de la lecture de l'archive",13,0

msg_erreur_format_inconnue:
db "DCP: format de l'archive inconnue",13,0


msg_ok_deco1:
db "DCP: decompression de ",0
msg_ok_deco2:
db 13,0

msg_erreur_deco1:
db "DCP: impossible de décompresser le fichier ",22,0
msg_erreur_deco2:
db 22," car le type de compression ",0
msg_erreur_deco3:
db " est inconnue",13,0



msg_erreur_cre1:
db "DCP: erreur lors de la décompression du fichier ",34,0
msg_erreur_cre2:
db 34," impossible de le créer",13,0
msg_erreur_lec1:
db "DCP: erreur lors de la décompression du fichier ",34,0
msg_erreur_lec2:
db 34," erreur de lecture de l'archive",13,0
msg_erreur_ecr1:
db "DCP: erreur lors de la décompression du fichier ",34,0
msg_erreur_ecr2:
db 34," erreur lors de l'écriture du fichier",13,0
msg_erreur_dec1:
db "DCP: erreur lors de la décompression du fichier ",34,0
msg_erreur_dec2:
db 34," erreur dans la sructure",13,0


msgtrappe:
dd 0,0,0,0,0,0,0,0
msgtrappe2:
db ".",0
msgtrappe3:
db "#",0
msgtrappe4:
db ",",0


chaine_temporaire:
dd 0,0,0,0,0,0,0,0


taille_1:
dd 0
handle_0:   ;dossier de destination
dd 0
handle_1:   ;fichier archive 
dd 0
handle_2:   ;fichier décompressé
dd 0

index_fichier:
dd 0


option_e:
db 0

taille_zt:
dd 512


nom_1:
rb 512
nom_2:
rb 512


zt_transfert: 





sdata2:
org 0
db 0;données du segment ES
sdata3:
org 0
;données du segment FS
sdata4:
org 0
;données du segment GS
findata:
