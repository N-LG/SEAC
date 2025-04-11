help.asm:
pile equ 4960 ;definition de la taille de la pile
include "fe.inc"
db "navigateur de fichier d'aide"
scode:
org 0


;ajouter un controle de débordement de l'historique

;ajouter gestion des images
;ajouter gestion des tableaux


;*****************************************
;active le mode video
mov dx,sel_dat2
mov ah,5   ;option=mode texte+souris
mov al,0   ;création console     
int 63h


mov dx,sel_dat1
mov ds,dx
mov es,dx
mov dx,sel_dat2
mov fs,dx




;**************************************************************
;lit l'adresse de la rubrique
mov byte[zt_recep],0

mov al,4   
mov ah,0   ;numéros de l'option de motclef a lire
mov cl,0 ;0=256 octet max
mov edx,adresse
int 61h




;*****************************************************
;extrait la rubrique et le fichier
ouvre_rubrique:
mov esi,adresse
mov edi,rubrique

boucle_extrait:
mov al,[esi]
cmp al,"|"
jne @f
mov edi,rubrique
inc esi
jmp boucle_extrait
@@:
cmp al,"@"
jne @f
mov byte[edi],0
mov edi,fichier
inc esi
jmp boucle_extrait

@@:
mov [edi],al
cmp al,0
je @f
inc esi
inc edi
jmp boucle_extrait

@@:



;*******************************
;si le nom de la rubrique ou le fichier est absent, on charge les valeurs par defaut
cmp byte[rubrique],0
jne @f
mov edx,rubriquepardefaut
call ajuste_langue
mov esi,edx
mov edi,rubrique
mov ecx,64
cld
rep movsb
@@:


cmp byte[fichier],0
jne @f
mov edx,fichierpardefaut
call ajuste_langue
mov esi,edx
mov edi,fichier
mov ecx,64
cld
rep movsb
@@:





;*******************************************
;passe la rubrique en minuscule
mov ebx,rubrique
boucle_minuscule:
cmp byte[ebx],"A"
jb suite_minuscule
cmp byte[ebx],"Z"
ja suite_minuscule
add byte[ebx],20h
suite_minuscule:
inc ebx
cmp ebx,rubrique+256
jne boucle_minuscule



;***********************************
;enregistre la rubrique dans l'historique
mov esi,rubrique
mov edi,[fin_historique]
@@:
mov al,[esi]
cmp al,0
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:
mov byte[edi],"@"
mov esi,fichier
inc edi
@@:
mov al,[esi]
cmp al,0
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:
mov byte[edi],"|"
inc edi
mov [fin_historique],edi



;***********************************
;test si le fichier en mémoire est le fichier a lire
mov esi,fichier
mov edi,fichier_mem
@@:
mov al,[esi]
cmp al,[edi]
jne @f
cmp al,0
je recherche_rubrique
inc esi
inc edi
jmp @b

@@:

;***********************************
;ouvre le fichier
mov edx,fichier
xor eax,eax
xor ebx,ebx
int 64h
cmp eax,0
je @f
xor eax,eax
mov ebx,1
int 64h
cmp eax,0
jne aff_err_fichier
@@:
mov [handle],ebx


;lit taille fichier
mov ebx,[handle]
mov edx,taille
mov al,6
mov ah,1 ;fichier
int 64h
cmp eax,0
jne aff_err_fichier


;agrandit la zone mémoire pour pouvoir contenir 2 fois le fichier pour rajouter le listing des mots clefs
mov dx,sel_dat1
mov ecx,[taille]
shl ecx,2
add ecx,zt_recep
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


;ferme le fichier
mov al,1
mov ebx,[handle]
int 64h

;enregistre le fichier comme étant celui en mémoire
mov esi,fichier
mov edi,fichier_mem
mov ecx,64
cld
rep movsd


;*************************************************
;transforme cr et lf en zéros
mov ecx,[taille]
mov ebx,zt_recep
add ecx,ebx

boucle_transf:
cmp byte[ebx],10
je transf_zero
cmp byte[ebx],13
je transf_zero
jmp ignore_transf

transf_zero:
mov byte[ebx],0

ignore_transf:
inc ebx
cmp ebx,ecx
jne boucle_transf



;***************************************************
;fait une liste des mots clefs
mov ebx,zt_recep
mov eax,[taille]
mov ecx,[taille]
mov esi,[taille]
shr eax,1
add ecx,zt_recep
add esi,eax
add esi,ebx


mov ebp,esi
dec esi

boucle1_liste:
cmp byte[ebx],":"
jne suite1_liste


boucle2_liste:
mov al,[ebx]
cmp al,0
je suite1_liste
mov[esi],al
inc ebx
inc esi
cmp ebx,ecx
jae fin1_liste
jmp boucle2_liste


suite1_liste:
call atteint_ligne_suivante
cmp ebx,ecx
jb boucle1_liste
fin1_liste:
mov byte[esi],0



;********************************************
;trie les rubriques par ordre alphabetique
mov edx,ebp
mov edi,ebp

sff_lit_dossier_trie_fichier_suivant:
cmp byte[edi],":"
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
call sff_lit_dossier_decale
jmp sff_lit_dossier_trie_fichier_suivant


@@:
cmp byte[esi],":"
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


;****************************************************
;compte les mots clefs et la largeur max d'un mot clef
mov dword[nb_motclef],0
mov dword[taille_colonne],0
mov dword[nb_colonnes],0
mov dword[nb_lignes],0


xor eax,eax
mov ebx,ebp

boucle_comptaille:
cmp byte[ebx],":"
jne @f

inc dword[nb_motclef]
mov ecx,eax
xor eax,eax
cmp ecx,[taille_colonne]
jb @f
add ecx,4 ;espace de 4 caractère entre chaque colonnes
mov [taille_colonne],ecx

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


xor eax,eax
fs
mov ax,[resx_texte]
xor edx,edx
mov ecx,[taille_colonne]
div ecx
mov [nb_colonnes],eax

xor edx,edx
mov ecx,eax
mov eax,[nb_motclef]
div ecx
mov [nb_lignes],eax
cmp edx,0
je @f
inc dword[nb_lignes]
@@:



;***********************************************
;créer une rubrique étoile qui est une liste des rubriques du fichier
mov edi,zt_recep
mov esi,ebp
add edi,[taille]
dec edi
cmp byte[edi],0
je @f
inc edi
mov byte[edi],0
@@:
inc edi
mov dword[edi],":*  "
mov byte[edi+2],0
add edi,4

mov ebx,[nb_lignes]

boucle_rubrique:
mov ebp,[nb_colonnes]
push esi

boucle_ligne_rubrique:
mov ecx,[taille_colonne]

mov byte[edi],"~"
inc edi

boucle_mot_rubrique:
mov al,[esi]
cmp al,0
je fin_mot_rubrique
inc esi
cmp al,":"
je fin_mot_rubrique

mov [edi],al 
inc edi
and al,0C0h
cmp al,80h
je boucle_mot_rubrique
dec ecx
jmp boucle_mot_rubrique


fin_mot_rubrique:
mov byte[edi],"~"
inc edi
cmp al,0
je fin_ligne_rubrique

@@:
mov byte[edi]," "
inc edi
dec ecx
jnz @b

mov ecx,[nb_lignes]
dec ecx
@@:
inc esi
cmp byte[esi],0
je fin_ligne_rubrique
cmp byte[esi],":"
jne @b
dec ecx
jnz @b
inc esi

dec ebp
jnz boucle_ligne_rubrique

fin_ligne_rubrique:
mov word[edi],2000h
add edi,2
pop esi

@@:
inc esi
cmp byte[esi],":"
jne @b
inc esi

dec ebx
jnz boucle_rubrique
dec edi
mov [taille],edi



;***********************************************
;recherche la rubrique
recherche_rubrique:
mov ebx,zt_recep
boucle_recherche:
cmp byte[ebx],":"
jne suite_recherche 

mov edi,ebx
inc edi
mov esi,rubrique

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
je @f
add al,20h
cmp al,ah
jne autrenom
@@:
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
mov esi,rubrique
jmp boucle_test_nom

suite_recherche:
call atteint_ligne_suivante
cmp ebx,[taille]
jb boucle_recherche

;si aucunes rubrique n'as été trouvé, on affiche une erreur
mov edx,msg2
call ajuste_langue
mov [page_encours],edx
jmp affiche_erreur


nom_ok:
call atteint_ligne_suivante
mov [page_encours],ebx
mov word[offsety],0



;***********************************************
affiche_page:
mov ebx,[page_encours]

call raz_ecr
mov dword[fin_cliquable],cliquable
fs
mov edi,[ad_texte]


;affiche le nom de la rubrique
fs
mov cx,[resx_texte]
mov esi,rubrique
@@:
call lirecarac
cmp eax,0
je @f
fs
mov [edi],eax
fs
mov byte[edi+3],70h
add edi,4
dec cx
jnz @b

@@:
mov esi,fichier
fs
mov dword[edi],70000040h
add edi,4
dec cx

@@:
call lirecarac
fs
mov [edi],eax
fs
mov byte[edi+3],70h
add edi,4
dec cx
jnz @b



;atteint la première ligne
mov cx,[offsety]
@@:
cmp cx,0
je @f
dec cx
call atteint_ligne_suivante
jmp @b
@@:


;affiche le texte
fs
mov cx,[resy_texte]
dec cx


affiche_ligne:
push ecx
mov esi,ebx
cmp byte[ebx],":"
je touche_boucle

mov dx,0707h
inc esi


cmp byte[ebx],"%"
jne @f
mov dx,0F0Fh
@@:
cmp byte[ebx],"^"
jne @f
mov dx,0A0Ah
@@:

continue_ligne:
fs
mov cx,[resx_texte]
@@:
call lirecarac
fs
mov [edi],eax
fs
mov [edi+3],dl
add edi,4
dec cx
jnz @b

call lirecarac
cmp byte[esi],0
je @f


pop ecx
dec cx
jz touche_boucle
push ecx
jmp continue_ligne





@@:
call atteint_ligne_suivante
pop ecx

dec cx
jnz affiche_ligne




;*******************************************
touche_boucle:          ;attente touche
fs
test byte[at_console],20h
jnz redim_ecran 
mov al,5
int 63h
cmp al,1
je fin
cmp al,30
je backspace
cmp al,82
je moins
cmp al,84
je plus
cmp al,0F0h
je clique

jmp touche_boucle


fin:
int 60h

;****************************************
moins:
cmp word[offsety],0     
je touche_boucle
dec word[offsety]
jmp affiche_page


plus:
cmp byte[esi],":"
je touche_boucle
inc word[offsety]
jmp affiche_page

;*****************************************
clique:
and ebx,0FFFFh
and ecx,0FFFFh
shr ebx,3  ;div par 8, mul par 4
shr ecx,4  ;div par 16,mul par 4
cmp ecx,0
je selection_manuelle
xor eax,eax
fs
mov ax,[resx_texte]
mul ecx
add ebx,eax
shl ebx,2
fs
add ebx,[ad_texte]

mov esi,cliquable
cmp esi,[fin_cliquable]
je touche_boucle

boucle_clique:
cmp ebx,[esi+4]
jb @f
cmp ebx,[esi+8]
jb trouve_clique

@@:
add esi,12
cmp esi,[fin_cliquable]
jne boucle_clique
jmp touche_boucle


trouve_clique:
mov ebx,[esi]
mov edx,adresse
@@:
mov al,[ebx]
mov [edx],al
inc ebx
inc edx
cmp byte[ebx],"~"
jne @b
mov byte[edx],0
jmp ouvre_rubrique



;****************************************
selection_manuelle:
mov al,6
mov ah,70h
mov edx,adresse
xor ecx,ecx
fs
mov cx,[resx_texte]
int 63h
cmp al,1
je touche_boucle


jmp ouvre_rubrique



;******************************************
backspace:
;remonte au précédent
mov esi,[fin_historique]
cmp esi,historique
je touche_boucle
dec esi

@@:
cmp esi,historique
je touche_boucle
dec esi
cmp byte[esi],"|"
jne @b

@@:
cmp esi,historique
je @f
dec esi
cmp byte[esi],"|"
jne @b
inc esi
@@:
mov [fin_historique],esi


;et la recopie
mov edi,adresse
@@:
mov al,[esi]
cmp al,"|"
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:
mov byte[edi],0
jmp ouvre_rubrique



;*****************************************************************************************
aff_err_mem:
mov edx,msg8
call ajuste_langue
mov al,6
int 61h
int 60h

aff_err_fichier:
mov edx,msg4
call ajuste_langue
mov [page_encours],edx



;***************************************
affiche_erreur:
mov ebx,[page_encours]

call raz_ecr
fs
mov edi,[ad_texte]


;affiche le nom de la rubrique
fs
mov cx,[resx_texte]
mov esi,rubrique
@@:
call lirecarac
fs
mov [edi],eax
fs
mov byte[edi+3],70h
add edi,4
dec cx
jnz @b

;affiche le message d'erreur
fs
mov cx,[resx_texte]
mov esi,ebx
@@:
call lirecarac
fs
mov [edi],eax
fs
mov byte[edi+3],0C0h
add edi,4
dec cx
jnz @b

jmp touche_boucle







;******************************************
redim_ecran:
mov dx,sel_dat2
mov ah,5   ;option=mode texte+souris
mov al,0   ;création console     
int 63h

mov dx,sel_dat2
mov fs,dx
jmp affiche_page



;**********************************************************************************************
raz_ecr:
pushad
fs
mov ebx,[ad_texte]
fs
mov ecx,[to_texte]
shr ecx,2

boucle_raz_ecr:
fs
mov dword[ebx],0
add ebx,4
dec ecx
jnz boucle_raz_ecr


xor ebx,ebx
xor ecx,ecx
mov al,12
int 63h     ;place le curseur en 0.0
popad
ret






;************************************
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




;***************
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
cmp al,":"
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
mov byte[edi],":"
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




;***************************
ajuste_langue:  ;selectionne le message adapté a la langue employé par le système
push eax
push ecx
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
pop ecx
pop eax
ret


;*************************************************
lirecarac:
push ecx
mov al,[esi]
test al,080h
jz lutf1ch
test al,040h
jz lutf0ch
test al,020h
jz lutf2ch
test al,010h
jz lutf3ch
test al,08h
jz lutf4ch

lutf0ch:
mov eax,0FFFDh ;caractère de remplacement
inc esi
jmp fin_lireutf8

lutf1ch:
and eax,07Fh
inc esi
jmp fin_lireutf8

lutf2ch:
mov eax,[esi]
and eax,0C0E0h
cmp eax,080C0h
jne lutf0ch
xor eax,eax
mov al,[esi]
and al,1Fh
shl eax,6
mov cl,[esi+1]
and cl,3Fh
or al,cl
add esi,2
jmp fin_lireutf8

lutf3ch:
es
mov eax,[esi]
and eax,0C0C0F0h
cmp eax,08080E0h
jne lutf0ch
xor eax,eax
es
mov al,[esi]
and al,0Fh
shl eax,6
es
mov cl,[esi+1]
and cl,3Fh
or al,cl
shl eax,6
es
mov cl,[esi+2]
and cl,3Fh
or al,cl
add esi,3
jmp fin_lireutf8

lutf4ch:
es
mov eax,[esi]
and eax,0C0C0C0F8h
cmp eax,0808080F0h
jne lutf0ch

xor eax,eax
es
mov al,[esi]
and al,07h
shl eax,6
es
mov cl,[esi+1]
and cl,3Fh
or al,cl
shl eax,6
es
mov cl,[esi+2]
and cl,3Fh
or al,cl
shl eax,6
es
mov cl,[esi+3]
and cl,3Fh
or al,cl
add esi,4

fin_lireutf8:
pop ecx

cmp eax,0
jne @f
dec esi
ret

@@:
cmp eax,"~"
je @f
cmp eax,"|"
je stop_lien
cmp eax,"@"
je stop_lien
ret

@@:
cmp byte[esi],"~"
jne @f
inc esi
ret

@@:
cmp dl,03h
je fin_lien
mov dl,03h
pushad
mov ebx,[fin_cliquable]
mov [ebx],esi
mov [ebx+4],edi
popad
jmp lirecarac

fin_lien:
mov dl,dh
pushad
mov ebx,[fin_cliquable]
mov [ebx+8],edi
add dword[fin_cliquable],12
popad
jmp lirecarac


stop_lien:
cmp dl,03h
je @f
ret

@@:
inc esi
cmp byte[esi],"~"
jne @b
inc esi
jmp fin_lien





;*******************************************************
sdata1:   ;données dans le segment de donnée N°1
org 0

msg2:
db "no topic",0
db "rubrique absente",0
msg4:
db "error accessing manual file",0
db "erreur d'acces au fichier du manuel",0
msg8:
db 13,"AIDE: memory reservation error",13,0
db 13,"AIDE: erreur de reservation mémoire",13,0



nb_motclef:
dd 0
taille_colonne:
dd 0
nb_colonnes:
dd 0
nb_lignes:
dd 0


page_encours:
dd 0

rubriquepardefaut:
db "summary",0
db "sommaire",0
fichierpardefaut:
db "MANUAL.TXT",0
db "MANUEL.TXT",0

handle:
dd 0
taille:
dd 0,0


fin_cliquable:
dd 0
fin_historique:
dd historique



index:
rb 256

offsetx:
dw 0
offsety:
dw 0


ligne_vide:
rb 512
historique:
rb 2048
cliquable:
rb 4096
adresse:
rb 256
fichier:
rb 256
fichier_mem:
rb 256
rubrique:
rb 256

zt_recep:
rb 512

sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
