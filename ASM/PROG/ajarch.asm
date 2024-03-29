pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "ajout de fichier a l'executable syst�me"
scode:
org 0
mov ax,sel_dat1
mov ds,ax


mov cl,0
mov edx,nom_fichier
call lire_arg


mov cl,1
mov edx,nom_archive
call lire_arg

;mov edx,nom_fichier
;call affmsg


;mov edx,nom_archive
;call affmsg

reessaye:
mov edx,nom_archive     ;ouvre l'archive
call ouvre_fichier
cmp eax,cer_fdo
je reessaye

cmp eax,0
jne erreur_ouverture_archive




mov [handle_archive],ebx
call taillef
sub ecx,16
mov [taille_archive],ecx


mov ebx,[handle_archive]  ;lit les 16 derniers octets pour verifier que c'est bien un descripteur final
mov ecx,16
mov edx,[taille_archive]
mov edi,zt_transfert
call lit_fichier
cmp eax,0
jne erreur_ouverture_archive ;erreur_format_archive
cmp word[zt_transfert],"DM"
jne erreur_format_archive
cmp byte[zt_transfert+2],"F"
jne erreur_format_archive


mov edx,nom_fichier     ;ouvre le fichier
call ouvre_fichier
cmp eax,0
jne erreur_ouverture_fichier
mov [handle_fichier],ebx
call taillef
mov [taille_fichier],ecx
add ecx,1AFh
and ecx,0FFFFFFF0h
mov [taille_zone],ecx


mov ebx,[handle_archive]  ;ecrit le descripteur du fichier a ajouter
mov ecx,416
mov edx,[taille_archive]
mov esi,descripteur_fichier
call ecr_fichier
cmp eax,0
jne erreur_ecriture_archive
add dword[taille_archive],416


cmp dword[taille_fichier],512
jbe petit_fichier

;*************************************************************
boucle_principale:
mov ebx,[handle_fichier]
mov ecx,512
mov edx,[donnee_transf]
mov edi,zt_transfert
call lit_fichier
cmp eax,0
jne erreur_lecture_fichier
add dword[donnee_transf],512

mov ebx,[handle_archive]  
mov ecx,512
mov edx,[taille_archive]
mov esi,zt_transfert
call ecr_fichier
cmp eax,0
jne erreur_ecriture_archive
add dword[taille_archive],512

mov eax,[donnee_transf]
add eax, 512
cmp eax,[taille_fichier]
jb boucle_principale


petit_fichier:
mov ecx,[taille_fichier]
sub ecx,[donnee_transf]
mov ebx,[handle_fichier]
mov edx,[donnee_transf]
mov edi,zt_transfert
call lit_fichier
cmp eax,0
jne erreur_lecture_fichier

mov ecx,[taille_fichier]
sub ecx,[donnee_transf]
mov ebx,[handle_archive]  
mov edx,[taille_archive]
mov esi,zt_transfert
call ecr_fichier
cmp eax,0
jne erreur_ecriture_archive

mov ecx,[taille_fichier]
sub ecx,[donnee_transf]
add [taille_archive],ecx

mov esi,[taille_fichier]
and esi,0Fh
cmp esi,0
jne ok_descripteur
mov esi,10h
ok_descripteur:
mov ecx,32
sub ecx,esi
add esi,descripteur_final

mov ebx,[handle_archive]  ;ecrit le nouveau descripteur final
mov edx,[taille_archive]
call ecr_fichier
jnc fin

erreur_ecriture_archive:
call coderr
mov edx,msg_erreur_ecriture_archive
call ajuste_langue
call affmsg
jmp fin


;***************************
ajuste_langue:  ;selectionne le message adapt� a la langue employ� par le syst�me
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





coderr:
mov ecx,eax
mov esi,chaine_temporaire
call conv_nombre
mov edx,chaine_temporaire
call affmsg
ret



erreur_ouverture_archive:
call coderr
mov edx,msg_erreur_ouverture_archive
call ajuste_langue
call affmsg
jmp fin

erreur_format_archive:
call coderr
mov edx,msg_erreur_format_archive
call ajuste_langue
call affmsg
jmp fin

erreur_ouverture_fichier:
call coderr
mov edx,msg_erreur_ouverture_fichier
call ajuste_langue
call affmsg
jmp fin

erreur_lecture_fichier:
call coderr
mov edx,msg_erreur_lecture_fichier
call ajuste_langue
call affmsg

fin:
;mov ebx,[handle_fichier]
;call ferme_fichier

;mov ebx,[handle_archive]
;call ferme_fichier

include "nlg_se.inc"


msg_erreur_ecriture_archive:
db "AJARCH: error writing archive",13,0
db "AJARCH: erreur lors de l'ecriture de l'archive",13,0

msg_erreur_ouverture_archive:
db "AJARCH: unable to open archive",13,0
db "AJARCH: impossible d'ouvrir l'archive",13,0

msg_erreur_format_archive:
db "AJARCH: error in archive format",13,0
db "AJARCH: erreur dans le format de l'archive",13,0

msg_erreur_ouverture_fichier:
db "AJARCH: cannot open file",13,0
db "AJARCH: impossible d'ouvrir le fichier",13,0

msg_erreur_lecture_fichier:
db "AJARCH: error while reading file",13,0
db "AJARCH: erreur lors de la lecture du fichier",13,0

donnee_transf:
dd 0

chaine_temporaire:
dd 0,0,0,0,0,0,0,0,0

descripteur_final:
dd 0,0,0,0
db "DMF",0
dd 0,0,0



nom_archive:   ;400 octets
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

taille_archive:
dd 0
handle_archive:
dd 0

handle_fichier:
dd 0

descripteur_fichier:
db "DMX",0
taille_zone:
dd 0
taille_fichier:
dd 0
dd 0 ;bourrage
nom_fichier:   ;400 octets
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


zt_transfert: ;512 octets
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128



sdata2:
org 0
db 0;donn�es du segment ES
sdata3:
org 0
;donn�es du segment FS
sdata4:
org 0
;donn�es du segment GS
findata:

