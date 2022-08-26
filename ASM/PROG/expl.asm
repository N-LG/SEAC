expl:


;structure de dossier ouvert
do_ts equ 0   ;taille de la structure
do_tn equ 4   ;taille de la zone des nom
do_adresse equ 8
do_adresse_max equ 16
do_znom equ 32



;structure de l'index fichier
if_nom equ 0    ;pointeur vers le nom
if_ext equ 4    ;pointeur ver l'extension
if_taille equ 8 ;taille
if_att equ 16   ;attribut b0=taille et type valide b1=type(1=dossier) b2=fichier selectionné



pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "explorateur de fichier"
scode:
org 0
mov ax,sel_dat1
mov ds,ax



;chargement base de definition actions par type
xor eax,eax
mov edx,nom_bdd
int 64h             ;ouvre le fichier
cmp eax,0
jne ignore_bdd

;lit la taille
mov al,6
mov ah,1
mov edx,taille_bdd
int 64h
cmp eax,0
jne ignore_bdd

;reservation mémoire pour la bdd
mov dx,sel_dat1
mov ecx,[taille_zt]
shl ecx,1
add ecx,zt_lecture
mov al,8
int 61h
cmp eax,0
;jne erreur_memoire

;lecture du fichier brut


;fermeture fichier
mov al,1
int 64h

;transformation des éventuel LF en CR
mov ebx,actions_bdd
mov ecx,taille_bdd
add ecx,ebx
boucle_lfcr:
cmp byte[ebx],10
jne @f
mov byte[ebx],13
@@:
inc ebx
cmp ebx,ecx
jne boucle_lfcr 


;


ignore_bdd:


;reservation mémoire de travail
mov dx,sel_dat1
mov ecx,[taille_zt]
shl ecx,1
add ecx,zt_lecture
mov al,8
int 61h


;crée ecran
mov dx,sel_dat2
mov ah,5   ;option=mode texte+souris
mov al,0   ;création console     
int 63h

mov dx,sel_dat1
mov ds,dx
mov es,dx
mov dx,sel_dat2
mov fs,dx

fs
or byte[at_console],8  ;met a 1 le bit de non mise a jour de l'ecran apres int 63h


mov edx,nom_dossier
mov cl,0   ;256 octet du coup
mov ax,4   ;0eme argument
int 61h


;lit le nom du dossier de travail actuel
mov edx,nom_dossier
cmp byte[edx],0
jne dossier_param
mov eax,18
int 61h
dossier_param:

;ouvre le dossier
xor eax,eax
xor edx,edx
mov edx,nom_dossier
int 64h             ;ouvre le fichier
;cmp eax,cer_dov
;jne erreur_non_dossier
mov [num_dossier],ebx

mov esi,nom_dossier
mov edi,nom_dossier_max
mov ecx,64
cld
rep movsd

;charge la liste des fichier du dossier
charge_liste:
xor ebx,ebx
xor ecx,ecx
fs
mov cx,[resy_texte]
dec ecx
mov al,12
int 63h     ;place le curseur sur la dernière ligne
mov edx,patientez
mov al,11
mov ah,0Fh ;couleur
int 63h
mov eax,7  ;demande la mise a jour ecran
int 63h

int 62h

mov eax,16
mov ebx,[num_dossier]
mov ecx,[taille_zt]
dec ecx
xor edx,edx
mov edi,zt_lecture
int 64h
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
cmp eax,0
je charge_tailles

;on double la taille de la zt
shl dword[taille_zt],1
mov dx,sel_dat1
mov ecx,[taille_zt]
shl ecx,1
add ecx,zt_lecture
mov al,8
int 61h

charge_tailles:
;lit la taille de chaque fichier et en determine le type
mov ebx,zt_lecture
mov edx,zt_lecture
mov edi,zt_lecture
add edi,[taille_zt]

boucle_charge_tailles:
cmp byte[ebx],"|"
je ok_charge_taille 
cmp byte[ebx],0
je fin_charge_taille
inc ebx 
jmp boucle_charge_tailles


ok_charge_taille: 
mov byte[ebx],0
mov [edi+8],edx
mov dword[edi+12],0
inc ebx
mov edx,ebx
add edi,16
jmp boucle_charge_tailles

fin_charge_taille:
mov [edi+8],edx
mov dword[edi+12],0
add edi,16
mov dword[edi],0    ;taille du fichier
mov dword[edi+4],0   
mov dword[edi+8],0  ;adresse du nom
mov dword[edi+12],0 ;attribut  ;b0-b2= type  b3=selectionné

sub edi,zt_lecture
sub edi,[taille_zt]
shr edi,4
dec edi
mov dword[ligne_max],0
xor ecx,ecx
fs
mov cx,[resy_texte]
sub ecx,4
cmp edi,ecx
jb tttt
sub edi,ecx
mov [ligne_max],edi
tttt:



mov dword[ligne_affiche],0


;***************************************************************************************
affichage_ecran:
;effacement de l'écran
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


;affichage des boutons de base
mov edx,bouton1
mov al,11
mov ah,70h ;couleur
int 63h

mov edx,entrebouton
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,bouton2
mov al,11
mov ah,70h ;couleur
int 63h

mov edx,entrebouton
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,bouton3
mov al,11
mov ah,70h ;couleur
int 63h

mov edx,entrebouton
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,bouton4
mov al,11
mov ah,70h ;couleur
int 63h

;affichage de l'adresse du dossier maximum
mov edx,nom_dossier_max
cmp byte[edx],0
jne ok_nom_dossier
mov edx,selection
ok_nom_dossier:
mov al,11
mov ah,02h ;couleur
int 63h

xor ebx,ebx
mov ecx,1
mov al,12
int 63h     ;place le curseur en 0.1

;affichage de l'adresse du dossier actuel
mov edx,nom_dossier
cmp byte[edx],0
jne ok_nom_dossier2
mov edx,selection
ok_nom_dossier2:
mov al,11
mov ah,0Ah ;couleur
int 63h

;met a jour le descriptif
mov edx,descriptif
mov eax,7
int 61h

xor ebx,ebx
mov ecx,3
mov al,12
int 63h     ;place le curseur en 0.3



;affiche chaque fichier
mov ebx,[ligne_affiche]
shl ebx,4
add ebx,[taille_zt]
add ebx,zt_lecture
fs
mov cx,[resy_texte]
sub cx,4


boucle_affichage_fichier:
mov edx,[ebx+8]
cmp edx,0
je fin_affiche

mov eax,[ebx+12]
and eax,7
cmp eax,1
je affichage_fichier
cmp eax,2
je affichage_dossier
cmp eax,7
je affichage_erreur
call sf_charge_taille
mov eax,[ebx+12]
and eax,7
cmp eax,1
je affichage_fichier
cmp eax,2
je affichage_dossier
jmp affichage_erreur


affichage_fichier:
mov al,11
mov ah,07h ;couleur
int 63h

push ecx
push edx
mov edx,interval
mov al,11
mov ah,07h ;couleur
int 63h

mov eax,102
mov ecx,[ebx]
mov edx,chaine_taille
int 61h

mov edx,chaine_taille
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,octets
mov al,11
mov ah,07h ;couleur
int 63h
pop edx
pop ecx
jmp fichier_suivant


affichage_dossier:
mov al,11
mov ah,09h ;couleur
int 63h

push edx
mov edx,findeligne
mov al,11
mov ah,07h ;couleur
int 63h
pop edx
jmp fichier_suivant

affichage_erreur:
mov al,11
mov ah,0Ch ;couleur
int 63h

push edx
mov edx,findeligne
mov al,11
mov ah,07h ;couleur
int 63h
pop edx


fichier_suivant:
add ebx,16
dec cx
jnz boucle_affichage_fichier




fin_affiche:

xor ebx,ebx
xor ecx,ecx
fs
mov cx,[resy_texte]
dec ecx
mov al,12
int 63h     ;place le curseur sur la dernière ligne

mov edx,aide
mov al,11
mov ah,0Fh ;couleur
int 63h

mov eax,7  ;demande la mise a jour ecran
int 63h

;attend l'entréee clavier/souris
attent_clav:
mov al,5
int 63h
;mov[touche_importante],ah   ;0=majG 1=majD 2=CtrlG 3=CtrlD 4=Alt 5=AltGr
cmp al,0F0h
je clique
cmp al,0F2h
je clique2

cmp al,30
je retour
cmp al,82
je touche_haut
cmp al,84
je touche_bas
cmp al,78
je touche_pageup
cmp al,81
je touche_pagedown
cmp al,1
jne attent_clav
quitter:
int 60h


;***********************************
clique:
;recopie l'adresse actuelle
push ecx
mov esi,nom_dossier
mov edi,nom_suivant
mov ecx,64
cld
rep movsd
pop ecx

shr ecx,4
cmp ecx,0
je clique_bouton
cmp ecx,3
jb clique_adresse
sub ecx,3
xor eax,eax
fs
mov ax,[resy_texte]
sub eax,4
cmp ecx,eax
ja attent_clav

add ecx,[ligne_affiche]
shl ecx,4
mov ebx,[taille_zt]
add ebx,zt_lecture
add ebx,ecx
mov esi,[ebx+8]
mov edi,nom_suivant
cmp byte[edi],0
je boucle2_clique

boucle1_clique:
cmp byte[edi],0
je sss
inc edi
jmp boucle1_clique

sss:
mov byte[edi],"/"
inc edi
boucle2_clique:
lodsb
stosb
cmp al,0
jne boucle2_clique

jmp ouvre_nouveau_dossier






;***************************************
clique_bouton:
shr ebx,3
cmp ebx,bouton2-bouton1-2
jb quitter
cmp ebx,bouton2-bouton1
jb attent_clav

cmp ebx,bouton3-bouton1-2
jb nv_fenetre
cmp ebx,bouton3-bouton1
jb attent_clav

cmp ebx,bouton4-bouton1-2
jb ouvre_disque
cmp ebx,bouton4-bouton1
jb attent_clav

cmp ebx,entrebouton-bouton1-2
jb af_tecop

jmp attent_clav


;********
af_tecop:

;recopie l'adresse actuelle
mov esi,nom_dossier
mov edi,nom_suivant
mov ecx,64
cld
rep movsd

mov dword[nom_suivant-4]," CD "
xor eax,eax
mov edx,nom_suivant-3
int 61h

mov eax,3   ;affichage du tecop
xor edx,edx
int 63h
jmp attent_clav




;**********
nv_fenetre:
;recopie l'adresse actuelle
mov esi,nom_dossier
mov edi,nom_suivant
mov ecx,64
cld
rep movsd


;extrait extension fichier
mov esi,nom_suivant
boucle_nv_fenetre:
cmp byte[esi],0
je fin_nv_fenetre
inc esi
jmp boucle_nv_fenetre

fin_nv_fenetre:
mov dword[esi],22h
mov dword[nom_suivant-6],"EXPL"
mov word[nom_suivant-2],2220h
xor eax,eax
mov edx,nom_suivant-6
int 61h

jmp attent_clav











;***************************************
clique_adresse:
dec ecx
shr ebx,3
cmp ecx,0
je clique_adresse0
xor eax,eax
fs
mov ax,[resx_texte]
add ebx,eax
clique_adresse0:

;recopie l'adresse actuelle
mov esi,nom_dossier_max
mov edi,nom_suivant
mov ecx,64
cld
rep movsd

mov esi,nom_suivant

boucle1_clique_adresse:
cmp ebx,0
je boucle2_clique_adresse
mov al,[esi]
and al,0C0h
cmp al,80h
je kkkk
dec ebx
kkkk:
inc esi
jmp boucle1_clique_adresse



boucle2_clique_adresse:
cmp byte[esi],"/"
je fin_clique_adresse
cmp byte[esi],"\"
je fin_clique_adresse
cmp byte[esi],0
je fin_clique_adresse
inc esi
jmp boucle2_clique_adresse


fin_clique_adresse:
mov byte[esi],0
jmp ouvre_nouveau_dossier




;************************************
clique2:



shr ecx,4
cmp ecx,3
jb attent_clav

sub ecx,3

xor eax,eax
fs
mov ax,[resy_texte]
sub eax,1
cmp ecx,eax
ja attent_clav




mov eax,7  ;demande la mise a jour ecran
int 63h

jmp attent_clav








;***********************************
retour:
;recopie l'adresse actuelle
mov esi,nom_dossier
mov edi,nom_suivant
mov ecx,64
cld
rep movsd

mov ebx,nom_suivant
xor edx,edx
boucle_retour:
cmp byte[ebx],0
je suite_retour
cmp byte[ebx],"\"
jne ccotice
mov byte[ebx],"/"
ccotice:
cmp byte[ebx],"/"
jne cotice
mov edx,ebx
cotice:
inc ebx
jmp boucle_retour

suite_retour:
cmp edx,0
je ouvre_disque
mov byte[edx],0



ouvre_nouveau_dossier:
xor eax,eax
xor ebx,ebx
mov edx,nom_suivant
int 64h             ;ouvre le fichier
cmp eax,0
je ouvre_un_fichier
cmp eax,cer_dov
jne attent_clav
xchg [num_dossier],ebx

mov eax,1 ;et ferme l'ancien dossier
int 64h

mov esi,nom_suivant
mov edi,nom_dossier
mov ecx,64
cld
rep movsd


;test si le nouveau dossier et le dossier max partagent le même début
mov esi,nom_dossier
mov edi,nom_dossier_max
boucle_test_dossiermax:
lodsb
mov ah,[edi]
inc edi
cmp ah,al
jne erreur_dosier_max
cmp edi,nom_dossier_max+512
jne boucle_test_dossiermax
jmp charge_liste

erreur_dosier_max:
cmp ah,"/"
jne maj_dossier_max
cmp al,0
je charge_liste

maj_dossier_max:
mov esi,nom_dossier
mov edi,nom_dossier_max
mov ecx,64
cld
rep movsd
jmp charge_liste







;*********************************
ouvre_un_fichier:
mov eax,1    ;ferme le fichier
int 64h

;extrait extension fichier
mov esi,nom_suivant
boucle_nom_suivant_trouve:
cmp byte[esi],0
je fin_nom_suivant_trouve
inc esi
jmp boucle_nom_suivant_trouve

fin_nom_suivant_trouve:
mov edi,esi
mov dword[esi],0
sub esi,2
cmp byte[esi],"."
je ext_nom_suivant_trouve
dec esi
cmp byte[esi],"."
je ext_nom_suivant_trouve
dec esi
cmp byte[esi],"."
je ext_nom_suivant_trouve
dec esi
cmp byte[esi],"."
jne attent_clav
ext_nom_suivant_trouve:


;selectionne action suivante 
mov eax,[esi+1]
cmp eax,"FE"
je action_exe


;passe l'extension en majuscule
mov ebx,eax             
shr ebx,16
cmp al,"a"
jb ext1ok
cmp al,"z"
ja ext1ok
sub eax,20h
ext1ok:
cmp ah,"a"
jb ext2ok
cmp ah,"z"
ja ext2ok
sub eax,2000h
ext2ok:
cmp bl,"a"
jb ext3ok
cmp bl,"z"
ja ext3ok
sub eax,200000h
ext3ok:
cmp bh,"a"
jb ext4ok
cmp bh,"z"
ja ext4ok
sub eax,20000000h
ext4ok:



cmp eax,"HTM"
je action_texte
cmp eax,"HTML"
je action_texte
cmp eax,"CFG"
je action_texte
cmp eax,"CPC"
je action_texte
cmp eax,"TXT"
je action_texte
cmp eax,"ASM"
je action_texte
cmp eax,"SH"
je action_texte
cmp eax,"INI"
je action_texte
cmp eax,"DEF"
je action_def
cmp eax,"PNG"
je action_png
jmp attent_clav


action_texte:
mov cl,0
jmp effectue_action



action_def:
mov cl,2
jmp effectue_action


action_png:
mov cl,4
jmp effectue_action


action_exe:
mov byte[esi],0

xor eax,eax
mov edx,nom_suivant
int 61h

mov eax,3   ;affichage du tecop
xor edx,edx
int 63h

jmp attent_clav










;***********************************
effectue_action:
;cl= numéros action a effectuer
mov esi,actions
boucle_recherche_action:
cmp cl,0
je boucle_recherche_action2
cmp byte[esi],0
je aucunes_actions
cmp byte[esi],"|"
jne rrrr
dec cl
rrrr:
inc esi
cmp esi,actions+512
jne boucle_recherche_action

aucunes_actions:  ;aucunes action disponible
jmp attent_clav

boucle_recherche_action2:
cmp byte[esi],0
je aucunes_actions
cmp byte[esi],"|"
je aucunes_actions
cmp byte[esi],"="
je action_trouve
inc esi
cmp esi,actions+512
jne boucle_recherche_action2
jmp aucunes_actions

action_trouve:
inc esi
mov edi,commande
boucle_prepcommande:
lodsb
cmp al,0
je fin_commande
cmp al,"|"
je fin_commande
cmp al,"$"
je inser_nom
stosb
cmp edi,commande+511
jne boucle_prepcommande


fin_commande:
xor eax,eax
stosb

xor eax,eax
mov edx,commande
int 61h

jmp attent_clav



inser_nom:
push esi
mov esi,nom_suivant
boucle_insertonm:
lodsb
cmp al,0
je fin_insert_nom
stosb
cmp edi,commande+511
jne boucle_insertonm

jmp fin_commande


fin_insert_nom:
pop esi
jmp boucle_prepcommande








;***********************************
touche_haut:
cmp dword[ligne_affiche],0
je attent_clav
dec dword[ligne_affiche]
jmp affichage_ecran



;***********************************
touche_bas:
mov eax,[ligne_max]
cmp [ligne_affiche],eax
je attent_clav
inc dword[ligne_affiche]
jmp affichage_ecran


;***********************************
touche_pageup:
xor ecx,ecx
fs
mov cx,[resy_texte]
sub ecx,4
cmp dword[ligne_affiche],ecx
jb touche_pageupp
sub dword[ligne_affiche],ecx
jmp affichage_ecran
touche_pageupp:
mov dword[ligne_affiche],0
jmp affichage_ecran


;***********************************
touche_pagedown:
xor ecx,ecx
fs
mov cx,[resy_texte]
sub ecx,4
mov eax,[ligne_affiche]
add eax,ecx
cmp eax,[ligne_max]
ja touche_pagedownn
add dword[ligne_affiche],ecx
jmp affichage_ecran
touche_pagedownn:
mov eax,[ligne_max]
mov [ligne_affiche],eax
jmp affichage_ecran


;****************************************
ouvre_disque:
;lit les disques actif
mov eax,17
mov edx,nom_suivant
int 64h

mov edi,zt_lecture
mov dword[edi],"#dm"
add edi,3

;test si la disquette est disponible
test byte[nom_suivant+29],80h
jz ouvre_disque_pasdi
mov al,"|"
stosb
mov dword[edi],"#di"
add edi,3
ouvre_disque_pasdi:

mov ch,[nom_suivant+30]
mov cl,1
ouvre_disque_bouclecd:
test ch,1
jz ouvre_disque_pascd
mov al,"|"
stosb
mov dword[edi],"#cd"
add edi,3
mov al,cl
add al,"0"
stosb
ouvre_disque_pascd:
inc cl
shr ch,1
cmp cl,8
jne ouvre_disque_bouclecd




mov ch,[nom_suivant]
mov cl,1
ouvre_disque_bouclepart:
test ch,1
jz ouvre_disque_paspart
mov al,"|"
stosb
mov dword[edi],"#dd"
add edi,3
mov al,cl
add al,"0"
stosb
ouvre_disque_paspart:
inc cl
shr ch,1
cmp cl,8
jne ouvre_disque_bouclepart


mov byte[edi],0
mov byte[nom_dossier],0
jmp charge_tailles


;********************************************************************************************************************************************







;***********************************
sf_charge_taille:
pushad
mov edx,[ebx+8]
mov edi,ebx
cmp byte[nom_dossier],0
je sfr_charge_taille

xor eax,eax

mov ebx,[num_dossier]
int 64h             ;ouvre le fichier
cmp eax,cer_dov
je sfd_charge_taille
cmp eax,0
jne sfe_charge_taille


;lit la taille
mov al,6
mov ah,1
mov edx,edi
int 64h

mov al,1   ;et ferme le fichier
int 64h

mov dword[edi+12],1
popad
ret


sfd_charge_taille:   ;le fichier est un dossier
mov al,1   ;et ferme le fichier
int 64h
sfr_charge_taille:
mov dword[edi],0
mov dword[edi+4],0
mov dword[edi+12],2
popad
ret


sfe_charge_taille:   ;erreur lors sde l'ouverture fichier

mov dword[edi],0
mov dword[edi+4],0
mov dword[edi+12],7
popad
ret













;********************************************************************************************************************************************
sdata1:
org 0

bouton1:
db "Quitter",0,0
bouton2:
db "Nouvelle fenetre",0,0
bouton3:
db "Retour a la racine",0,0
bouton4:
db "Ouvrir dans le TECOP",13,0
entrebouton:
db "~~",0

aide:
db "echap=quitter backspace=retour dossier précédent",0

selection:
db "veuillez selectionner le disque a parcourir",0

patientez:
db "veuillez patienter durant le chargement du contenu du dossier",0


octets:
db " Octets"

findeligne:
db 13,0

interval:
db " - ",0


ligne_affiche:
dd 0
ligne_max:
dd 0







descriptif:
db "Explorateur dossier "
zt_travail:
rb 1024



nom_bdd:
db "EXPL.CFG",0
taille_bdd:
dd 0,0
actions_bdd:






sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
