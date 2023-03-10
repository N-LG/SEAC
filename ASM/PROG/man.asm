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
cmp eax,0
jne aff_err_mem


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

;aggrandit la mem pour pouvoir créer une liste de mot clef
mov ecx,[taille]
sub ecx,zt_recep
shr ecx,2  ;1/4 de la taille du fichier devrait être largement suffisant
add ecx,[taille]
mov dx,sel_dat1
mov al,8
int 61h
cmp eax,0
jne aff_err_mem


;fait une liste des mots clefs
mov ebx,zt_recep
mov esi,[taille]

boucle1_liste:
cmp byte[ebx],":"
jne suite1_liste
inc ebx


boucle2_liste:
mov al,[ebx]
cmp al,":"
jne @f
mov al,13
@@:
mov[esi],al
inc ebx
inc esi
cmp ebx,[taille]
je fin1_liste
cmp byte[ebx],0
jne boucle2_liste

mov byte[esi],13
inc esi

suite1_liste:
call atteint_ligne_suivante
cmp ebx,[taille]
jb boucle1_liste
fin1_liste:
mov dword[esi],0D0D0D0Dh
mov dword[esi+4],0D0D0D0Dh
mov byte[esi+8],0





;compte les mots clefs
xor eax,eax
mov ebx,[taille]

boucle_comptaille:
cmp byte[ebx],13
jne @f

inc dword[nb_motclef]
mov ecx,eax
xor eax,eax
cmp ecx,[max]
jb @f
mov [max],ecx

@@:
mov dl,[ebx]
inc ebx
and dl,0C0h
cmp dl,80h
je @f
inc eax
@@:
cmp byte[ebx],0
jne boucle_comptaille
sub dword[nb_motclef],8



mov al,2
mov edx,table_info_vid
int 63h
mov eax,[table_info_vid+0Ch]
mov [largeur],eax



;nb colonne = largeur/(max+4)
;nb_ligne = nb_motclef/nb colonne-1
add dword[max],4
xor eax,eax
mov ax,[largeur]
xor edx,edx
mov ecx,[max]
div ecx
cmp eax,8 ;on limite les collonnes a 8
jb @f
mov eax,8
@@:
mov [nb_collonne],eax
xor edx,edx
mov ecx,eax
mov eax,[nb_motclef]
div ecx
mov [nb_ligne],eax
cmp edx,0
je @f
inc dword[nb_ligne]
@@:


shl dword[nb_collonne],2



jmp sff_lit_dossier_trie_fin ;temp!!!!!!!!!!!!!!!!!!


;trie les par ordre alphabetique
mov esi,[taille]
mov edi,[taille]


sff_lit_dossier_trie_fichier_suivant:
cmp byte[edi],13
je @f
cmp byte[edi],0
je sff_lit_dossier_trie_fin
inc edi
jmp sff_lit_dossier_trie_fichier_suivant
@@:
inc edi

;test si le fichier doit être placé avant et le déplace si nécessaire
mov esi,edx
sff_lit_dossier_trie_boucle:
call sff_lit_dossier_test
jnc @f
;call sff_lit_dossier_decale
jmp sff_lit_dossier_trie_fichier_suivant



@@:
cmp byte[esi],13
je @f
cmp byte[esi],0
je sff_lit_dossier_trie_fichier_suivant
inc esi
jmp @b
@@:
inc esi
cmp esi,edi
je sff_lit_dossier_trie_fichier_suivant
jmp sff_lit_dossier_trie_boucle



sff_lit_dossier_trie_fin: 




;remplit les index
mov esi,[taille]
mov edi,index
mov ecx,[nb_ligne]
mov [edi],esi
add edi,4

boucle_index:
cmp byte[esi],0
je fin_index
cmp byte[esi],13
jne @f
dec ecx
jnz @f
inc esi
mov [edi],esi
add edi,4
mov ecx,[nb_ligne]
jmp boucle_index

@@:
inc esi
jmp boucle_index

fin_index:




;affiche la liste
mov al,6
mov edx,msg6
int 61h


boucle_ligne:
;efface la ligne
mov eax,20202020h
mov edi,ligne_vide
mov ecx,64
rep stosd

;insère les mots clef au bon endroit
xor ebx,ebx
mov edi,ligne_vide

boucle_col:
mov esi,[index+ebx]
push edi
@@:
lodsb
stosb
cmp al,13
jne @b
dec edi
mov byte[edi],20h
pop edi
mov [index+ebx],esi








;passe a la colonne suivante
mov ecx,[max]
boucle_colonne_suiv:
mov al,[edi]
inc edi
and al,0C0h
cmp al,80h
je @f
dec ecx
@@:
cmp ecx,0
jne boucle_colonne_suiv 

add ebx,4
cmp ebx,[nb_collonne]
jne boucle_col



fin_col:
;ajoute fin
dec edi
mov word[edi],13

;ecrit ligne
mov al,6
mov edx,ligne_vide
int 61h

dec dword[nb_ligne]
jnz boucle_ligne

mov al,6
mov edx,blanc
int 61h
mov al,6
mov edx,msg_crlf
int 61h
int 60h




;******************
sff_lit_dossier_test:  ;cf=1 si le fichier en edi doit se placer avant celuis en esi
pushad
sff_lit_dossier_test_boucle:
mov al,[edi]
mov ah,[esi]
cmp al,"a"
jb @f
cmp al,"z"
ja @f
sub al,"a"-"A"
@@:
cmp ah,"a"
jb @f
cmp ah,"z"
ja @f
sub ah,"a"-"A"
@@:
cmp al,ah
jb sff_lit_dossier_test_ok
jne sff_lit_dossier_test_nok
inc edi
inc esi
jmp sff_lit_dossier_test_boucle

sff_lit_dossier_test_ok:
popad
stc
ret

sff_lit_dossier_test_nok:
popad
clc
ret




;***********
sff_lit_dossier_decale:
pushad
;calcul taille a deplacer
mov edx,edi
mov ecx,edi
sub edx,2
sub ecx,esi


;sauvegarde nom a decaler
push word 8000h
xor eax,eax
@@:
mov al,[edi]
cmp al,0
je @f
cmp al,13
je @f
push ax
inc edi
jmp @b
@@:
dec edi

;décale les noms
dec ecx
mov esi,edx
std
rep movsb

;recopie nom sauvegardé
mov byte[edi],13
dec edi
@@:
pop ax
cmp ax,8000h
je @f
mov [edi],al
dec edi
jmp @b
@@:

popad
ret












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


aff_err_mem:
mov al,6
mov edx,msg8
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
db 13,"MAN: erreur dans les parametres du motclef",13,0
msg4:
db 13,"MAN: erreur d'acces au fichier du manuel",13,0
msg5:
db 13,"MAN: contenu de la rubrique ",22h,0
msg6:
db 13,"MAN: liste des rubriques disponibles:",13,13h,0
msg7:
db " ",0
msg8:
db 13,"MAN: erreur de reservation mémoire",13,0

msg_crlf:
db 13,17h,0

blanc:
db 1Fh,0
vert:
db 1Ah,0


largeur:
dd 0
nb_collonne:
dd 0
nb_motclef:
dd 0
max:
dd 0
nb_ligne:
dd 0

index:
rb 256


table_info_vid:
rb 40
ligne_vide:
rb 512


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
