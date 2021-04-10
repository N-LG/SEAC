edh:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "editeur de fichier de définition"
scode:
org 0

mov dx,sel_dat1
mov ds,dx
mov es,dx

mov dx,sel_dat2
mov ah,7   ;option=mode graphique+texte+souris
mov al,0   ;création console     
int 63h
cmp eax,0
je suite1_init

mov edx,msg_err_init
mov al,6
int 61h
int 60h

suite1_init:
mov dx,sel_dat2
mov fs,dx

mov edx,bitpp
mov al,2   ;information video     
int 63h



cmp dword[resx],700
jb erreur_resolution 
cmp dword[resy],500
jae suite2_init

erreur_resolution:
mov edx,msg_err_resol
mov al,6
int 61h
int 60h

suite2_init:
mov al,8                 ;redimensionne la zone de donné pour avoir une zt de 32ko
mov ecx,zone_tampon
add ecx,8020h
mov dx,sel_dat1
int 61h

;récupère le nom du fichier a modifier
mov edx,nom_fichier
mov cl,0   ;256 octet du coup
mov ax,4   ;0eme argument
int 61h

call chargement
cmp eax,0
je aff_table


menubase:
;affiche le menu pour le cas ou aucun fichier n'est ouvert
call raz_txt
mov edx,msg_menu2
mov al,11
mov ah,07h ;couleur
int 63h

mov bl,0
boucle_affichage_menu_base:
mov al,13
mov bh,7 ;couleur
mov cl,0
mov ch,3
int 63h

cmp bl,0
je nouveau
cmp bl,1
je ouvrir
jmp fin





;************************************
menu:  ;affiche le menu
call raz_txt
mov edx,msg_menu1
mov al,11
mov ah,07h ;couleur
int 63h

mov bl,0
boucle_affichage_menu:
mov al,13
mov bh,7 ;couleur
mov cl,0
mov ch,7
int 63h

cmp bl,0
je aff_table
cmp bl,1
je nouveau
cmp bl,2
je ouvrir
cmp bl,3
je enregistrer
cmp bl,4
je enregistrer_sous
cmp bl,5
je convertir
jmp fin



nouveau:
call raz_txt
;demande le nom du fichier a ouvrir
mov edx,msg_nouv1
mov al,11
mov ah,07h ;couleur
int 63h 

mov ah,07h
mov edx,nom_fichier
mov ecx,256
mov al,6
int 63h

mov eax,2
mov ebx,0
mov edx,nom_fichier
int 64h
cmp eax,0
;je suite1_nouveau



call eff_fichier

;demande le numéros du premier caractère de la table


;demande la largeur du caractère


;demande la hauteur du caractère


jmp menu


ouvrir:
call raz_txt
;demande le nom du fichier a ouvrir
mov edx,msg_ouv1
mov al,11
mov ah,07h ;couleur
int 63h 

mov ah,07h
mov edx,nom_fichier
mov ecx,256
mov al,6
int 63h

call eff_fichier

call chargement
cmp eax,0
je aff_table

;%%%%%%%%%%%%%%%%%%%%%%% gestion des erreurs

jmp menubase



;****************************
enregistrer_sous:
;demande le nom du fichier sur lequel enregistrer
mov edx,msg_sav1
mov al,11
mov ah,07h ;couleur
int 63h 

mov ah,07h
mov edx,nom_fichier
mov ecx,256
mov al,6
int 63h



;****************************
enregistrer:
call sauvegarder
jmp menu



;****************************
convertir:
;%%%%%%%%%%%%%%%%%%%%%%%
jmp menu




;****************************
fin:
cmp byte[modif],0    ;check si le secteur a été modifié  
je fin_abs


call raz_ecr
mov edx,msg_modif
mov al,11
mov ah,07h ;couleur
int 63h              ;demande si il faut le sauvegarder


mov al,13
mov cl,1
mov ch,2
mov bl,0
mov bh,7
int 63h

cmp bl,0
jne fin_abs
call sauvegarder


fin_abs:
int 60h




;**********************************
sauvegarder:
;essaye d'ouvrir le fichier
xor eax,eax
mov ebx,0
mov edx,nom_fichier
int 64h
cmp eax,0
je suite1_sauvegarder
ret

suite1_sauvegarder:
;remet la taille de fichier a zéro
mov dword[zt_nombre],0
mov dword[zt_nombre+4],0
mov al,7
mov ah,1
mov ebx,[num_fichier]
mov edx,zt_nombre
int 64h
cmp eax,0
je suite2_sauvegarder
ret

suite2_sauvegarder:
;calcul la taille du fichier
mov eax,[resx_carac]
mov ecx,[resy_carac]
xor edx,edx
mul ecx
mov ecx,eax
shl ecx,5
add ecx,16

mov eax,5
mov ebx,[num_fichier]
mov edx,0   ;offset dans le fichier
mov esi,zone_tampon
int 64h
cmp eax,0
je suite3_sauvegarder
ret

suite3_sauvegarder:
;ferme le fichier
mov eax,1
mov ebx,[num_fichier]
int 64h
ret


;***************************************
chargement:
;essaye d'ouvrir le fichier
xor eax,eax
mov ebx,0
mov edx,nom_fichier
int 64h
cmp eax,0
je suite1_chargement
ret

suite1_chargement:
mov [num_fichier],ebx

;charge le fichier
mov eax,4
mov ebx,[num_fichier]
mov ecx,8010h
mov edx,0   ;offset dans le fichier
mov edi,zone_tampon
int 64h
cmp eax,0
je suite2_chargement
ret

suite2_chargement:
;ferme le fichier
mov eax,1
mov ebx,[num_fichier]
int 64h
cmp eax,0
je suite3_chargement
ret

suite3_chargement:
;verifie que la structure du fichier est correcte
cmp dword[zone_tampon],"DEFG"
jne chargement_erreur
cmp byte[larg_carac],8
je ok_larg_carac
cmp byte[larg_carac],16
je ok_larg_carac
cmp byte[larg_carac],32
jne chargement_erreur
ok_larg_carac:
cmp byte[haut_carac],16
je ok_haut_carac
cmp byte[haut_carac],32
jne chargement_erreur
ok_haut_carac:
cmp byte[num_1er_carac],0
jne chargement_erreur

;charge les info de base
xor eax,eax
xor ecx,ecx
xor edx,edx
mov al,[larg_carac]
mov cl,[haut_carac]
mov [resx_carac],eax
mov [resy_carac],ecx
shr eax,3
mul ecx
mov eax,1
mov [octet_par_ligne],eax

mov byte[etat],1
xor eax,eax
ret

chargement_erreur:
mov eax,cer_ers
ret



;*****************************
aff_table:    ;affiche la table de caractère
call raz_ecr

mov ebx,39
mov ecx,40
add ebx,[resx_carac]
mov esi,data_carac
mov dword[num_carac],0

boucle_lignecarac:
mov eax,[resy_carac]
mov [ligne_carac],eax

boucle_carac:
mov eax,[resx_carac]
mov [pixel_ligne],eax
mov edx,[esi]

boucle_ligne:
test edx,1
jz pas_pixel
push edx
mov edx,7
mov eax,0815h
int 63h
pop edx
pas_pixel:
dec ebx
shr edx,1
dec dword[pixel_ligne]
jnz boucle_ligne

add ebx,[resx_carac]
inc ecx
add esi,[octet_par_ligne]
dec dword[ligne_carac]
jnz boucle_carac

add ebx,[resx_carac]
sub ecx,[resy_carac]
inc dword[num_carac]
test dword[num_carac],0Fh
jnz boucle_lignecarac
mov ebx,39
add ebx,[resx_carac]
add ecx,[resy_carac]
cmp dword[num_carac],256
jne boucle_lignecarac 


;affiche le numéros du caractère
mov ecx,[cury]
shl ecx,4
add ecx,[curx]
add ecx,[num_1er_carac]
mov edx,zt_nombre
mov eax,103
int 61h
mov ebx,0
mov ecx,0
mov edx,zt_nombre
mov eax,0A19h
int 63h


;affiche le caractère en grand
mov esi,data_carac
mov eax,[cury]
shl eax,4
add eax,[curx]
xor edx,edx
mov ecx,[resx_carac]
shr ecx,3
mul ecx
xor edx,edx
mov ecx,[resy_carac]
mul ecx
add esi,eax


mov ebx,[resx_carac]
shl ebx,5
add ebx,24
mov ecx,40

mov eax,[resy_carac]
mov [ligne_carac],eax

boucle_carac2:
mov eax,[resx_carac]
mov [pixel_ligne],eax
mov edx,[esi]

boucle_ligne2:
test edx,1
jz pas_pixel2
push edx
push esi
push edi
mov edx,7
mov eax,0816h
mov esi,ebx
mov edi,ecx
add esi,16
add edi,16
int 63h
pop edi
pop esi
pop edx
pas_pixel2:
sub ebx,16
shr edx,1
dec dword[pixel_ligne]
jnz boucle_ligne2

mov eax,[resx_carac]
shl eax,4
add ebx,eax
add ecx,16
add esi,[octet_par_ligne]
dec dword[ligne_carac]
jnz boucle_carac2


;*****************************************
cmp byte[mode],1
je edition


;affiche le curseur de selection en vert
mov eax,[curx]
mov ecx,[resx_carac]
xor edx,edx
mul ecx
add eax,39
mov ebx,eax
mov eax,[cury]
mov ecx,[resy_carac]
xor edx,edx
mul ecx
add eax,39
mov ecx,eax

mov esi,ebx
mov edi,ecx
add esi,[resx_carac]
mov edx,0Ah
mov eax,0817h
int 63h
mov esi,ebx
mov edi,ecx
add edi,[resy_carac]
mov edx,0Ah
mov eax,0817h
int 63h

add ebx,[resx_carac]
add ecx,[resy_carac]
inc ebx
inc ecx


mov esi,ebx
mov edi,ecx
sub esi,[resx_carac]
dec esi
mov edx,0Ah
mov eax,0817h
int 63h
mov esi,ebx
mov edi,ecx
sub edi,[resy_carac]
dec edi
mov edx,0Ah
mov eax,0817h
int 63h



touche_boucle:          ;attente touche
mov al,5
int 63h
test ah,0Ch
jz pas_touche_ctrl
cmp al,47
je touche_sauvegarder
cmp al,61
je couper
cmp al,62
je copier
cmp al,63
je coller
pas_touche_ctrl:


cmp al,1
je menu
cmp al,79
je touche_suppr
cmp al,82
je thaut
cmp al,83
je tgauche
cmp al,84
je tbas
cmp al,85
je tdroit

cmp al,44
je edition
cmp al,100
je edition

cmp al,0F0h
je clique_souris

jmp touche_boucle



;************************
thaut:
cmp dword[cury],0
je touche_boucle
dec dword[cury]
jmp aff_table

tbas:
cmp dword[cury],15
je touche_boucle
inc dword[cury]
jmp aff_table

tgauche:
cmp dword[curx],0
je touche_boucle
dec dword[curx]
jmp aff_table

tdroit:
cmp dword[curx],15
je touche_boucle
inc dword[curx]
jmp aff_table


touche_sauvegarder:
call sauvegarder
jmp touche_boucle

couper:
mov esi,data_carac
mov eax,[cury]
shl eax,4
add eax,[curx]
push eax
mov eax,[resx_carac]
shr eax,3
xor edx,edx
mov ecx,[resy_carac]
mul ecx
mov ecx,eax ;ecx=taille carac
pop eax
xor edx,edx
mul ecx
add esi,eax ;esi=pos carac

push ecx
push esi
mov eax,15
mov edx,esi
int 61h
pop esi
pop ecx 

boucle_touche_couper:
mov dword[esi],0
add esi,4
sub ecx,4
jnz boucle_touche_couper

jmp aff_table


copier:
mov esi,data_carac
mov eax,[cury]
shl eax,4
add eax,[curx]
push eax
mov eax,[resx_carac]
shr eax,3
xor edx,edx
mov ecx,[resy_carac]
mul ecx
mov ecx,eax ;ecx=taille carac
pop eax
xor edx,edx
mul ecx
add esi,eax ;esi=pos carac

mov eax,15
mov edx,esi
int 61h 
jmp aff_table



coller:
mov esi,data_carac
mov eax,[cury]
shl eax,4
add eax,[curx]
push eax
mov eax,[resx_carac]
shr eax,3
xor edx,edx
mov ecx,[resy_carac]
mul ecx
mov ecx,eax ;ecx=taille carac
pop eax
xor edx,edx
mul ecx
add esi,eax ;esi=pos carac

mov eax,16
mov edx,esi
int 61h 
jmp aff_table


touche_suppr:
mov esi,data_carac
mov eax,[cury]
shl eax,4
add eax,[curx]
push eax
mov eax,[resx_carac]
shr eax,3
xor edx,edx
mov ecx,[resy_carac]
mul ecx
mov ecx,eax ;ecx=taille carac
pop eax
xor edx,edx
mul ecx
add esi,eax ;esi=pos cara 

boucle_touche_suppr:
mov dword[esi],0
add esi,4
sub ecx,4
jnz boucle_touche_suppr 

jmp aff_table



clique_souris:
mov byte[mode],0

cmp ebx,40
jb aff_table
cmp ecx,40
jb aff_table


mov eax,[resx_carac]
shl eax,5
add eax,40
cmp ebx,eax
jae aff_table
mov eax,[resy_carac]
shl eax,4
add eax,40
cmp ecx,eax
jae aff_table

mov eax,[resx_carac]
shl eax,4
add eax,40
cmp ebx,eax
jae pix_souris


selec_souris:
sub ebx,40
sub ecx,40
shr ebx,3
shr ecx,4
mov [curx],ebx
mov [cury],ecx
jmp aff_table


pix_souris:
sub ebx,40
mov eax,[resx_carac]
shl eax,4
sub ebx,eax
sub ecx,40
shr ebx,4
shr ecx,4
push ebx
push ecx

mov esi,data_carac
mov eax,[cury]
shl eax,4
add eax,[curx]
xor edx,edx
mov ecx,[resx_carac]
shr ecx,3
mul ecx
xor edx,edx
mov ecx,[resy_carac]
mul ecx
add esi,eax

pop eax
mov ecx,[octet_par_ligne]
xor edx,edx
mul ecx
add esi,eax

mov edx,1
mov cl,[resx_carac]
pop eax
sub cl,al
dec cl
shl edx,cl
xor [esi],edx
jmp aff_table



;***************************************
edition:
mov byte[mode],1


;affiche le curseur de selection en rouge
mov eax,[curx]
mov ecx,[resx_carac]
xor edx,edx
mul ecx
add eax,39
mov ebx,eax
mov eax,[cury]
mov ecx,[resy_carac]
xor edx,edx
mul ecx
add eax,39
mov ecx,eax

mov esi,ebx
mov edi,ecx
add esi,[resx_carac]
mov edx,0Ch
mov eax,0817h
int 63h
mov esi,ebx
mov edi,ecx
add edi,[resy_carac]
mov edx,0Ch
mov eax,0817h
int 63h

add ebx,[resx_carac]
add ecx,[resy_carac]
inc ebx
inc ecx


mov esi,ebx
mov edi,ecx
sub esi,[resx_carac]
dec esi
mov edx,0Ch
mov eax,0817h
int 63h
mov esi,ebx
mov edi,ecx
sub edi,[resy_carac]
dec edi
mov edx,0Ch
mov eax,0817h
int 63h





;affiche le curseur d'édition
mov ebx,[curx2]
shl ebx,4
mov eax,[resx_carac]
shl eax,4
add ebx,eax
add ebx,43
mov ecx,[cury2]
shl ecx,4
add ecx,43
mov edx,0Ah
mov eax,0816h
mov esi,ebx
mov edi,ecx
add esi,10
add edi,10
int 63h


touche_boucle2:          ;attente touche
mov al,5
int 63h
cmp al,1
je navigation
cmp al,2
je menu
cmp al,82
je thaut2
cmp al,83
je tgauche2
cmp al,84
je tbas2
cmp al,85
je tdroit2

cmp al,44
je modif_pix
cmp al,100
je modif_pix

cmp al,0F0h
je clique_souris

jmp touche_boucle2




navigation:
mov byte[mode],0
jmp aff_table

thaut2:
cmp dword[cury2],0
je touche_boucle2
dec dword[cury2]
jmp aff_table

tbas2:
mov eax,[resy_carac]
dec eax
cmp dword[cury2],eax
je touche_boucle2
inc dword[cury2]
jmp aff_table

tgauche2:
cmp dword[curx2],0
je touche_boucle2
dec dword[curx2]
jmp aff_table

tdroit2:
mov eax,[resx_carac]
dec eax
cmp dword[curx2],eax
je touche_boucle2
inc dword[curx2]
jmp aff_table


modif_pix:
mov esi,data_carac
mov eax,[cury]
shl eax,4
add eax,[curx]
xor edx,edx
mov ecx,[resx_carac]
shr ecx,3
mul ecx
xor edx,edx
mov ecx,[resy_carac]
mul ecx
add esi,eax

mov eax,[cury2]
mov ecx,[octet_par_ligne]
xor edx,edx
mul ecx
add esi,eax

mov edx,1
mov cl,[resx_carac]
sub cl,[curx2]
dec cl
shl edx,cl
xor [esi],edx
jmp aff_table





;***********************************
raz_ecr:
push ebx
push ecx
fs
mov ebx,[ad_graf]
fs
mov ecx,[to_graf]
shr ecx,2

boucle_raz_ecr:
fs
mov dword[ebx],0
add ebx,4
dec ecx
jnz boucle_raz_ecr
fs 
and byte[at_console],0FCh
fs
or byte[at_console],2 
pop ecx
pop ebx
ret




raz_txt:
push eax
push ebx
push ecx
fs
mov ebx,[ad_texte]
fs
mov ecx,[to_texte]
shr ecx,2

boucle_raz_txt:
fs
mov dword[ebx],0
add ebx,4
dec ecx
jnz boucle_raz_txt
fs 
and byte[at_console],0FCh
fs
or byte[at_console],1 

xor ebx,ebx
xor ecx,ecx
mov al,12
int 63h     ;place le curseur en 0.0

pop ecx
pop ebx
pop eax
ret






eff_fichier:
push ebx
mov ebx,zone_tampon
boucle_eff_fichier:
mov dword[ebx],0
add ebx,4
cmp ebx,zone_tampon+8020h
jne boucle_eff_fichier
pop ebx
ret

;*******************************************
sdata1:
org 0

bitpp:   ;structure d'info pour le mode video en cours
dd 0
resx:
dd 0
resy:
dd 0
resxt:
dd 0
resyt:
dd 0
xs1:
dd 0
ys1:
dd 0
xs2:
dd 0
ys2:
dd 0
octpl:
dd 0


num_fichier:
dd 0
taille_fichier:
dd 0,0

mode:
db 0   ;0=selection caractère 1=édition caractère
etat:
db 0   ;0=aucun fichier chargé 1= fichier chargé
modif:
db 0   ;0=fichier ouver sans modification 1=fichier ouvert a été modifié

curx:
dd 0
cury:
dd 0
curx2:
dd 0
cury2:
dd 0

resx_carac:
dd 0
resy_carac:
dd 0
octet_par_ligne:
dd 0
pixel_ligne:
dd 0
ligne_carac:
dd 0
num_carac:
dd 0

msg_err_init:
db "EDG: impossible de démarrer, vous devez être en mode graphique",13,0
msg_err_resol:
db "EDG: impossible de démarrer, vous devez avoir une résolution d'au moins 700*500",13,0
msg_err_mem:
db "EDG: impossible de réserver la mémoire nécessaire pour poursuivre l'execution du programme",13,0





msg_menu1:
db "continuer l'édition",13
db "nouveau",13
db "ouvrir",13
db "sauvegarder",13
db "sauvegarder sous",13
db "convertir",13
db "quitter",0
msg_menu2:
db "nouveau",13
db "ouvrir",13
db "quitter",0








msg_nouv1:
db "quel est le nom du fichier que vous souhaitez créer?",13,0

msg_nouv2:
db "la création de fichier a échoué",13


msg_ouv1:
db "quel fichier souhaitez vous ouvrir?",13,0

msg_ouv2:
db "erreur lors de la lecture du fichier",0

msg_ouv3:
db "impossible d'ouvrir le fichier, il est déja en cours d'utilisation",0


msg_sav1:
db "sous quel nom voulez vous enregistrer le fichier?",13,0

msg_sav2:
db "erreur lors de l'écriture du fichier",0



msg_choix:
db ", voulez vous:",13
db "reéssayer? (R)",13
db "choisir un autre fichier? (F)",13
db "annuler? (A)",13,0




msg_aide:
db "esc    - quitter",13
db "F1     - menu",13
db "F9     - aide",13
db "entrée - selection caractère",13
db "espace - modification pixel",13
db "Ctrl+X - couper",13
db "Ctrl+C - copier",13
db "Ctrl+V - coller",13
db 13,"appuyez sur une touche pour effacer cet aide",0












msg_modif:
db "le fichier a été modifié, voulez vous",13
db "enregister les modifications avant de continuer?",13
db "continuer sans enregistrer?",13,0







zt_nombre:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


nom_fichier:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0



zone_tampon:
dd 0
larg_carac:     ;largeur caractère (valeur possible: 8, 16, et 32)
db 0     
haut_carac:     ;hauteur caractère (valeur possible: 16 et 32)
db 0    
dw 0     
num_1er_carac:  ;numéros du premier caractère (doit etre aligné sur 256)
dd 0,0
data_carac:


sdata2:
org 0
;données du segment ES
sdata3:
org 0
;données du segment FS
sdata4:
org 0
;données du segment GS
findata:
