;
;compiler avec la commande "fasm ajarch.asm ajarch.elf"





format ELF executable 3 ;executable i386 pour linux
entry _start


segment readable executable

 _start:

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


mov edx,nom_archive     ;ouvre l'archive
call ouvre_fichier
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
jc erreur_format_archive
mov eax,[zt_transfert]
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
jc erreur_ecriture_archive
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
jc erreur_lecture_fichier
add dword[donnee_transf],512

mov ebx,[handle_archive]  
mov ecx,512
mov edx,[taille_archive]
mov esi,zt_transfert
call ecr_fichier
jc erreur_ecriture_archive
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
jc erreur_lecture_fichier

mov ecx,[taille_fichier]
sub ecx,[donnee_transf]
mov ebx,[handle_archive]  
mov edx,[taille_archive]
mov esi,zt_transfert
call ecr_fichier
jc erreur_ecriture_archive

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
call affmsg
jmp fin

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
call affmsg
jmp fin

erreur_format_archive:
call coderr
mov edx,msg_erreur_format_archive
call affmsg
jmp fin

erreur_ouverture_fichier:
call coderr
mov edx,msg_erreur_ouverture_fichier
call affmsg
jmp fin

erreur_lecture_fichier:
call coderr
mov edx,msg_erreur_lecture_fichier
call affmsg

fin:
mov ebx,[handle_fichier]
call ferme_fichier

mov ebx,[handle_archive]
call ferme_fichier

include "nlg_linux.inc"


msg_erreur_ecriture_archive:
db "erreur lors de l'ecriture de l'archive",13,10,0

msg_erreur_ouverture_archive:
db "impossible d'ouvrir l'archive",13,10,0

msg_erreur_format_archive:
db "erreur dans le format de l'archive",13,10,0

msg_erreur_ouverture_fichier:
db "impossible d'ouvrir le fichier",13,10,0

msg_erreur_lecture_fichier:
db "erreur lors de la lecture du fichier",13,10,0

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





