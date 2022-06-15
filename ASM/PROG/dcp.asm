dcp:

;a faire: pkzip utilisant la fonction de deflate le fichier directement


macro trappe val
{
pushad

mov byte[msgtrappe],val
mov byte[msgtrappe+1],13
mov byte[msgtrappe+2],0
mov edx,msgtrappe
mov al,6
int 61h
popad
}


pile equ 4096 ;definition de la taille de la pile
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
mov ah,"o"   ;lettre de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,nom_1
int 61h
cmp eax,0
jne @f
mov edx,nom_1
xor ebx,ebx
mov al,0
int 64h
cmp eax,0
jne @f
mov [handle_0],ebx
@@:




;lit l'option 0 (fichier archive)
mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,nom_1
int 61h
cmp eax,0
jne @f
mov edx,nom_1
xor ebx,ebx
mov al,0
int 64h
cmp eax,0
jne erreur_ouverture_archive
mov [handle_1],ebx


;lit la taille du fichier
mov ebx,[handle_1]
mov al,6
mov ah,1
mov edx,taille_1
int 64h
cmp eax,0
jne erreur_ouverture_archive


;lit l'extension fichier
mov edx,nom_1
@@:
inc edx
cmp byte[edx],0
jne @b

xor eax,eax
mov cl,4
@@:
dec edx
cmp byte[edx],"."
je ok_extension
dec cl
jz @f
shl eax,8
mov al,[edx]
cmp al,"a"
jb @b
cmp al,"z"
ja @b
sub al,"a"-"A"
jmp @b

@@:
xor eax,eax
ok_extension:
mov [extension],eax





mov ebx,[handle_1]  ;lit les 512 premier octets 
mov ecx,512
mov edx,0
mov edi,chaine_temporaire
mov al,4
int 64h
cmp eax,0
jne erreur_lecture_archive

cmp dword[chaine_temporaire],04034B50h
je pkzip
cmp word[chaine_temporaire],8B1Fh
je gzip
cmp dword[chaine_temporaire+257],"usta"
jne @f
cmp dword[chaine_temporaire+261],"r  "
je tar
@@:
cmp dword[extension],"TAR"
je tar

mov edx,msg_erreur_format_inconnue
mov al,6
int 61h
int 60h






;**********************************************************************************************************
pkzip:
mov dword[index_fichier],0
call signal_debut

boucle_pkzip:
mov ebx,[handle_1]  ;lit les 32 premier octets 
mov ecx,32
mov edx,[index_fichier]
mov edi,chaine_temporaire
mov al,4
int 64h
cmp eax,0
jne erreur_lecture_archive

cmp dword[chaine_temporaire],04034B50h
jne fin_ok



mov ebx,[handle_1]  ;lit le nom
xor ecx,ecx
mov cx,[chaine_temporaire+1Ah]
mov edx,[index_fichier]
add edx,1Eh
mov edi,nom_2
mov al,4
int 64h
cmp eax,0
jne erreur_lecture_archive
xor ebx,ebx
mov bx,[chaine_temporaire+1Ah]  ;taille du nom
mov byte[nom_2+ebx],0


;réserve une ZT suffisante
mov ecx,[chaine_temporaire+12h]
add ecx,[chaine_temporaire+16h]
add ecx,4
cmp ecx,0
je suite2_boucle_pkzip
cmp ecx,[taille_zt]
jbe @f
mov [taille_zt],ecx
mov al,8   ;agrandit la zone de transfert si besoin
add ecx,zt_transfert
mov dx,sel_dat1
int 61h
cmp eax,0
jne erreur_manque_mem
@@:

mov dword[taille_2],0
mov dword[taille_2+4],0
call cree_fichier
cmp eax,0
jne  pkzip_err_cre

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
mov al,4
int 64h
cmp eax,0
jne pkzip_err_lec


cmp word[chaine_temporaire+8],0   ;sans compression
je pkzip_type0
cmp word[chaine_temporaire+8],8   ;compression deflate (rfc1951)
je pkzip_type8


mov edx,msg_erreur_deco1  ;type de compression non reconnu
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_erreur_deco2
mov al,6
int 61h
xor ecx,ecx
mov eax,102
mov cx,[chaine_temporaire+8]
mov edx,zt_transfert
int 61h
mov edx,zt_transfert
mov al,6
int 61h
mov edx,msg_erreur_deco3
mov al,6
int 61h
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

mov esi,zt_transfert
add esi,[chaine_temporaire+12h]


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
mov al,1
int 64h

call signal_decomp_ok

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
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_erreur_cre2
mov al,6
int 61h
jmp suite2_boucle_pkzip

pkzip_err_lec:
mov edx,msg_erreur_lec1
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_erreur_lec2
mov al,6
int 61h
jmp suite2_boucle_pkzip


pkzip_err_dec:
mov edx,msg_erreur_dec1
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_erreur_dec2
mov al,6
int 61h
jmp suite2_boucle_pkzip


pkzip_err_ecr:
mov edx,msg_erreur_ecr1
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_erreur_ecr2
mov al,6
int 61h
jmp suite2_boucle_pkzip



;**********************************************************************************************************
gzip:
mov dword[offset_1],0
call signal_debut

gzip_boucle1:
cmp byte[chaine_temporaire+2],8
jne erreur_format_inconnue
mov al,[chaine_temporaire+3]
mov esi,chaine_temporaire+10


;passe les différents champs
test al,4   ;si FEXTRA = 1
jz gzip_FEXTRA
xor ecx,ecx
mov cx,[esi]
add esi,ecx
add esi,2
gzip_FEXTRA:


test al,8   ;si FNAME = 1
jz gzip_FNAME
;récupère le nom du fichier de destination
mov edi,nom_2
@@:
mov ah,[esi]
mov [edi],ah
inc esi
inc edi
cmp ah,0
jnz @b
jmp gzip_FNAME_fin


gzip_FNAME:
pushad
;si pas de nom on prend le nom de l'archive moins la dernière extension
mov esi,nom_1
mov edi,nom_2
@@:
mov al,[esi]
mov [edi],al
inc esi
inc edi
cmp al,0
jne @b

mov esi,edi

@@:
dec edi
cmp edi,nom_2
je @f
cmp byte[edi],"."
jne @b


cmp dword[extension],"TGZ" ;si l'extension était TGZ on passe a l'extension TAR
jne gzip_sup_ext
inc edi
mov dword[edi],"TAR"
popad
jmp gzip_FNAME_fin

gzip_sup_ext:
mov byte[edi],0
popad
jmp gzip_FNAME_fin

@@:     ;et si pas d'extension on rajoute l'extencion .DCP
dec esi
mov dword[esi],".DCP"
mov byte[esi+4],0
popad



gzip_FNAME_fin:



test al,10h   ;si FCOMMENT = 1
jz gzip_FCOMMENT
@@:
mov ah,[esi]
inc esi
cmp ah,0
jnz @b
gzip_FCOMMENT:

test al,2   ;si FHCRC = 1
jz gzip_FHCRC
add esi,2
gzip_FHCRC:

sub esi,chaine_temporaire
add [offset_1],esi


;crée ou écrase le fichier
mov dword[taille_2],0
mov dword[taille_2+4],0
call cree_fichier
cmp eax,0
jne  gzip_err_cre
mov [handle_2],ebx


mov eax,153
mov esi,[handle_1]
mov edi,[handle_2]
mov edx,[offset_1]
int 61h
cmp eax,0
jne gzip_err_dec

call signal_decomp_ok

add esi,8
add [offset_1],esi

mov eax,[taille_1]
cmp [offset_1],eax
jae fin_ok

mov ebx,[handle_1]  ;lit les 512 premier octets 
mov ecx,512
mov edx,[offset_1]
mov edi,chaine_temporaire
mov al,4
int 64h
cmp eax,0
jne erreur_lecture_archive


cmp word[chaine_temporaire],8B1Fh
je gzip_boucle1
jmp erreur_structure_archive



;*****************
gzip_err_cre:
mov edx,msg_erreur_cre1
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_erreur_cre2
mov al,6
int 61h
int 60h



;*****************
gzip_err_dec:
mov edx,msg_erreur_dec1
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_erreur_dec2
mov al,6
int 61h
int 60h


;**********************************************************************************************************
tar:
;agrandit la ZT pour avoir 1Mo
mov al,8
mov ecx,zt_transfert+100000h
mov dx,sel_dat1
int 61h
cmp eax,0
jne erreur_manque_mem

call signal_debut

mov edx,512

;**********************
tar_boucle1:


;lit la taille
mov esi,chaine_temporaire+124
xor ecx,ecx
@@:
mov al,[esi]
cmp al,"0"
jb @f
cmp al,"7"
ja @f
shl ecx,3
sub al,"0"
or cl,al
inc esi
jmp @b
@@:


;test si c'est bien un fichier
cmp byte[chaine_temporaire+156],"0"
jne tar_fichier_suivant
;et que ce n'est pas un fichier vide
cmp ecx,0
je tar_fichier_suivant


;lit le nom
push ecx
mov esi,chaine_temporaire
mov edi,nom_2
mov ecx,25
cld
rep movsd


;lit le suffixe si on est au format ustar
cmp dword[chaine_temporaire+257],"usta"
jne tar_pas_nom_ustar
cmp dword[chaine_temporaire+261],"r  "
jne tar_pas_nom_ustar

mov esi,chaine_temporaire+345
mov edi,nom_2
@@:
cmp byte[edi],0
je @f
inc edi
jmp @b

@@:
mov ecx,155
cld
rep movsb
tar_pas_nom_ustar:


mov dword[taille_2],0
mov dword[taille_2+4],0
call cree_fichier
pop ecx
cmp eax,0
jne tar_erreur_creation

xor ebp,ebp ;ecx=taille du fichier edx=pointeur dans l'archive ebp=pointeur dans le fichier


;*******************************
tar_boucle2:
;test si il rest moin d'un MO a ecrire
cmp ecx,100000h
jbe tar_fin_fichier


;lit 1MO
push ecx
mov al,4
mov ebx,[handle_1]
mov ecx,100000h
mov edi,zt_transfert
int 64h
pop ecx
cmp eax,0
jne tar_erreur_lecture


;copie dans la destination ce MO
push ecx
push edx
mov al,5
mov ebx,[handle_2]
mov ecx,100000h
mov edx,ebp
mov esi,zt_transfert
int 64h
pop edx
pop ecx
cmp eax,0
jne tar_erreur_ecriture


add edx,100000h
add ebp,100000h
sub ecx,100000h
jmp tar_boucle2



tar_fin_fichier:
;lit le reste du fichier
mov al,4
mov ebx,[handle_1]
mov edi,zt_transfert
int 64h
cmp eax,0
jne tar_erreur_lecture


;ecrire les données
push edx
mov al,5
mov ebx,[handle_2]
mov edx,ebp
mov esi,zt_transfert
int 64h
pop edx
cmp eax,0
jne tar_erreur_ecriture



;fermer le fichier
mov ebx,[handle_2]
mov al,1
int 64h
call signal_decomp_ok


;passe au fichier suivant
tar_fichier_suivant:
add ecx,511
and ecx,0FFFFFE00h
add edx,ecx



;copie le descripteur de fichier
mov al,4
mov ebx,[handle_1]
mov ecx,512
mov edi,chaine_temporaire
int 64h
cmp eax,0
jne erreur_lecture_archive
cmp ecx,0
je fin_ok

add edx,512
cmp byte[chaine_temporaire],0
jne tar_boucle1


jmp fin_ok


tar_erreur_creation:
push edx
mov edx,msg_erreur_cre1
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_erreur_cre2
mov al,6
int 61h
pop edx
jmp tar_fichier_suivant


tar_erreur_ecriture:
push edx
mov edx,msg_erreur_ecr1
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_erreur_ecr2
mov al,6
int 61h
pop edx
jmp tar_fichier_suivant




tar_erreur_lecture:
mov edx,msg_erreur_lec1
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_erreur_lec2
mov al,6
int 61h
int 60h

















;****************************************************************************************************
cree_fichier:
push ecx
push edx
mov dword[handle_2],0
;créer le fichier
mov al,2
mov ebx,[handle_0]
mov edx,nom_2
int 64h
cmp eax,0
je ok_cree_fichier

;si le fichier existe déja et si l'option -e est active on écrase le fichier
cmp eax,cer_nfr
jne fin_cree_fichier 
cmp byte[option_e],1
jne fin_cree_fichier

;ouvre le fichier
mov al,0 
mov ebx,[handle_0]
mov edx,nom_2
int 64h
cmp eax,0
jne fin_cree_fichier


;fixe la taille du fichier
mov al,7
mov ah,1 ;taille fichier
mov edx,taille_2
int 64h
cmp eax,0
jne fin_cree_fichier

pkzip_okcree:
mov [handle_2],ebx


ok_cree_fichier:
mov [handle_2],ebx
fin_cree_fichier:
pop edx
pop ecx
ret



;******************
signal_debut:
push eax
push edx
mov edx,msg_ok_debut
mov al,6
int 61h
mov edx,nom_1
mov al,6
int 61h
mov edx,msg_ok_deco2
mov al,6
int 61h
pop edx
pop eax
ret





;******************
signal_decomp_ok:
push eax
push edx
mov edx,msg_ok_deco1
mov al,6
int 61h
mov edx,nom_2
mov al,6
int 61h
mov edx,msg_ok_deco2
mov al,6
int 61h
pop edx
pop eax
ret















;****************************************************************************
erreur_ouverture_archive:
mov edx,msg_erreur_ouverture_archive
mov al,6
int 61h
int 60h

erreur_format_inconnue:
mov edx,msg_erreur_format_inconnue
mov al,6
int 61h
int 60h

erreur_lecture_archive:
mov edx,msg_erreur_lec3
mov al,6
int 61h
int 60h

erreur_structure_archive:
mov edx,msg_erreur_structure_archive
mov al,6
int 61h
int 60h

erreur_manque_mem:
mov edx,msg_erreur_manque_mem
mov al,6
int 61h
int 60h

fin_ok:
mov edx,msg_ok_fin
mov al,6
int 61h
int 60h



;*********************************************************************
sdata1:
org 0

msg_erreur_ouverture_archive:
db "DCP: erreur pour ouvrir l'archive",13,0


msg_erreur_format_inconnue:
db "DCP: format de l'archive inconnue",13,0

msg_erreur_structure_archive:
db "DCP: erreur dans la structure de l'archive",13,0

msg_ok_debut:
db "DCP: début de la décompression de l'archive ",0

msg_ok_fin:
db "DCP: fin du parcours de l'archive",13,0

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
msg_erreur_lec3:
db "DCP: erreur lors de la lecture de l'archive",13,0
msg_erreur_ecr1:
db "DCP: erreur lors de la décompression du fichier ",34,0
msg_erreur_ecr2:
db 34," erreur lors de l'écriture du fichier",13,0
msg_erreur_dec1:
db "DCP: erreur lors de la décompression du fichier ",34,0
msg_erreur_dec2:
db 34," erreur dans la sructure",13,0
msg_erreur_manque_mem:
db "DCP: pas assez de mémoire pour poursuivre l'opération",13,0


msgtrappe:
dd 0,0,0,0,0,0,0,0
msgtrappe2:
db ".",0
msgtrappe3:
db "#",0
msgtrappe4:
db ",",0



handle_0:   ;dossier de destination
dd 0
handle_1:   ;fichier archive 
dd 0
taille_1:
dd 0,0
handle_2:   ;fichier décompressé
dd 0
taille_2:
dd 0,0

index_fichier:
dd 0

offset_1:
dd 0

option_e:
db 0

taille_zt:
dd 512
extension:
dd 0

nom_1:
rb 512
nom_2:
rb 512

chaine_temporaire:
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

