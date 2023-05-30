expl:


;structure de dossier ouvert
do_ts equ 0   ;taille de la structure
do_tn equ 4   ;taille de la zone des nom
do_nb_nom equ 8    ;nombre de fichier
do_handle equ 16 ;numéro d'ouverture du dossier
do_to_zn equ 20
do_to_zi equ 24
do_dern_sel equ 28

do_adresse equ 32
do_adresse_max equ 512+32
do_ad_zn equ 1024+32


;structure de l'index fichier
if_nom equ    0  ;pointeur vers le nom
if_ext equ    4  ;pointeur ver l'extension
if_taille equ 8  ;taille
if_att equ    16 ;attribut b0=taille et type valide b1=type(1=dossier) b2=fichier selectionné


taille_zt_base equ 40000h ;taille des nouvelles zone de base


pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "explorateur de fichier"
scode:
org 0
mov ax,sel_dat1
mov ds,ax
mov es,ax


;chargement base de definition actions par type
xor eax,eax
mov ebx,1
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
mov ecx,[taille_bdd]
add ecx,actions_bdd
mov al,8
int 61h
cmp eax,0
jne fin_erreur_memoire
mov [adresse_max],ecx


;lecture du fichier brut
mov al,4
mov ecx,[taille_bdd]
xor edx,edx
mov edi,actions_bdd
int 64h

;fermeture fichier
mov al,1
int 64h



;transformation des éventuel LF en CR
mov ebx,actions_bdd
mov ecx,[taille_bdd]
add ecx,ebx
boucle_lfcr:
cmp byte[ebx],10
jne @f
mov byte[ebx],13
@@:
inc ebx
cmp ebx,ecx
jne boucle_lfcr 


;enregistre la position des actions pour les fichier inconnue
;??????????????

;et les actions communes
;????????????????

ignore_bdd:


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

xor ecx,ecx
fs
mov cx,[resy_texte]
sub ecx,5
mov [ligne_aff],ecx


;lit le nom du dossier de base dans les argument
mov edx,dossier_ouvert
mov cl,0   ;256 octet du coup
mov ax,4   ;0eme argument
int 61h

;sinon, prend le nom du dossier de travail actuel
mov edx,dossier_ouvert
cmp byte[edx],0
jne dossier_param
mov eax,18
int 61h
dossier_param:

cmp word[dossier_ouvert],23h
jne @f
mov byte[dossier_ouvert],0
xor ebx,ebx
jmp ouvreongletdirect
@@:


;recopie le dossier ouvert dans le dossier max
mov esi,dossier_ouvert
mov edi,dossier_max
mov ecx,128
cld
rep movsd



;ouvre le dossier
xor eax,eax
xor edx,edx
mov edx,dossier_ouvert
int 64h             ;ouvre le fichier
cmp eax,cer_dov
jne fin_erreur_ouverture


;charge le dossier de base
ouvreongletdirect:
call ouvre_onglet
cmp eax,0
jne fin_erreur_memoire


;***************************************************************************************
affichage_ecran:
mov edx,[no_onglet]
shl edx,2
mov ebx,[edx+table_onglet]
mov [ad_onglet],ebx

mov dword[ligne_max],0
mov ecx,[ebx+do_nb_nom]
cmp ecx,[ligne_aff]
jbe @f
sub ecx,[ligne_aff]
mov [ligne_max],ecx
@@:


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


xor ebx,ebx
mov ecx,2
mov al,12
int 63h     ;place le curseur en 0.2

;affiche le bouton racine
mov al,11
mov ah,0Ah ;couleur
mov edx,racine
int 63h

;affichage de l'adresse du dossier maximum
mov edx,do_adresse_max
add edx,[ad_onglet]
cmp byte[edx],0
je @f
mov al,11
mov ah,02h ;couleur
int 63h
@@:

mov ebx,7
mov ecx,2
mov al,12
int 63h     ;place le curseur en 7.2

;affichage de l'adresse du dossier actuel
mov edx,do_adresse
add edx,[ad_onglet]
cmp byte[edx],0
je @f

mov al,11
mov ah,0Ah ;couleur
int 63h
@@:

;met a jour le descriptif
mov edx,descriptif
mov eax,7
int 61h

xor ebx,ebx
mov ecx,4
mov al,12
int 63h     ;place le curseur en 0.4



;affiche chaque fichier
mov edx,[ad_onglet]

mov ebx,[ligne_zero]
shl ebx,5
add ebx,edx
add ebx,do_ad_zn
add ebx,[edx+do_to_zn]


mov ecx,[ligne_aff]
cmp ecx,[edx+do_nb_nom]
jb @f
mov ecx,[edx+do_nb_nom]
@@:


boucle_affichage_fichier:
test byte[ebx+if_att],1
jnz @f
call sf_charge_taille_type
@@:

mov eax,[ebx+if_att]
and eax,7
cmp eax,1
je affichage_fichier
cmp eax,3
je affichage_dossier
cmp eax,5
je affichage_fichier_s
cmp eax,7
je affichage_dossier_s

;erreur dans la lecture du type et de la taille	
mov edx,[ebx+if_nom]
add edx,[ad_onglet]
mov al,11
mov ah,0Ch ;couleur
int 63h

mov edx,findeligne
mov al,11
mov ah,07h ;couleur
int 63h
jmp fichier_suivant


affichage_fichier:
mov edx,[ebx+if_nom]
add edx,[ad_onglet]
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,interval
mov al,11
mov ah,07h ;couleur
int 63h

push ecx
mov eax,102
mov ecx,[ebx+if_taille]
mov edx,zt_travail
int 61h
pop ecx

mov edx,zt_travail
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,octets
mov al,11
mov ah,07h ;couleur
int 63h
jmp fichier_suivant
jmp fichier_suivant


affichage_fichier_s:
mov edx,[ebx+if_nom]
add edx,[ad_onglet]
mov al,11
mov ah,070h ;couleur
int 63h

mov edx,interval
mov al,11
mov ah,070h ;couleur
int 63h

push ecx
mov eax,102
mov ecx,[ebx+if_taille]
mov edx,zt_travail
int 61h
pop ecx

mov edx,zt_travail
mov al,11
mov ah,070h ;couleur
int 63h

mov edx,octets
mov al,11
mov ah,070h ;couleur
int 63h
jmp fichier_suivant


affichage_dossier:
mov edx,[ebx+if_nom]
add edx,[ad_onglet]
mov al,11
mov ah,09h ;couleur
int 63h

mov edx,findeligne
mov al,11
mov ah,09h ;couleur
int 63h
jmp fichier_suivant



affichage_dossier_s:
mov edx,[ebx+if_nom]
add edx,[ad_onglet]
mov al,11
mov ah,01Fh ;couleur
int 63h

mov edx,findeligne
mov al,11
mov ah,01Fh ;couleur
int 63h



fichier_suivant:
add ebx,32
dec ecx
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
fs
test byte[at_console],20h
jnz redim_ecran 


mov al,5
int 63h
mov[touche_importante],ah   ;0=majG 1=majD 2=CtrlG 3=CtrlD 4=Alt 5=AltGr
cmp al,0F0h
je clique_g
cmp al,0F2h
je clique_d

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


redim_ecran:
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

xor ecx,ecx
fs
mov cx,[resy_texte]
sub ecx,5
mov [ligne_aff],ecx
jmp affichage_ecran




;******************
fin_erreur_memoire:
mov al,6
mov edx,msg_erreur_mem
int 61h

mov eax,3   ;affichage du tecop
xor edx,edx
int 63h

int 60h


fin_erreur_ouverture:
mov al,6
mov edx,msg_erreur_ouv
int 61h

mov al,6
mov edx,dossier_ouvert
int 61h

mov al,6
mov edx,findeligne
int 61h

mov eax,3   ;affichage du tecop
xor edx,edx
int 63h

int 60h





;***********************************
clique_g:
mov al,12
int 61h
cmp eax,[dernier_clique]
jb double_clique
add eax,150
mov [dernier_clique],eax


;*************************************
;simple clique
shr ecx,4
cmp ecx,0
je clique_bouton
dec ecx
cmp ecx,0
je clique_onglet
dec ecx
cmp ecx,2
jb clique_adresse
sub ecx,2
mov edx,[ad_onglet]
cmp ecx,[ligne_aff]
jae attent_clav
cmp ecx,[edx+do_nb_nom]
jae attent_clav


add ecx,[ligne_zero]
shl ecx,5
add ecx,do_ad_zn
add ecx,[edx+do_to_zn]
add ecx,edx

;déselectionne tout
test byte[touche_importante],0Ch
jnz ignore_deselection
mov esi,edx
mov edi,[edx+do_nb_nom]
add esi,do_ad_zn
add esi,[edx+do_to_zn]
boucle_deselection:
cmp ecx,esi
je @f
and byte[esi+if_att],0FBh
@@:
add esi,32
dec edi
jnz boucle_deselection
ignore_deselection:


test byte[touche_importante],03h
jnz selection_multiple

;selectionne un seul fichier
xor byte[ecx+if_att],4
sub ecx,edx
mov [edx+do_dern_sel],ecx
jmp affichage_ecran


selection_multiple:
mov esi,[edx+do_dern_sel]
add esi,edx

cmp ecx,esi
je affichage_ecran
jb @f
xchg ecx,esi
@@:
or byte[ecx+if_att],4
add ecx,32
cmp esi,ecx
jne @b
or byte[ecx+if_att],4
jmp affichage_ecran




;*******************
double_clique:
shr ecx,4
cmp ecx,4
jb attent_clav
sub ecx,4
mov edx,[ad_onglet]
cmp ecx,[ligne_aff]
jae attent_clav
cmp ecx,[edx+do_nb_nom]
jae attent_clav


;double clique sur un fichier/dossier
add ecx,[ligne_zero]
shl ecx,5
mov ebx,[ad_onglet]
add ecx,do_ad_zn
add ecx,[ebx+do_to_zn]
add ebx,ecx

mov al,[ebx+if_att]
and al,3
cmp al,1
je double_clique_fichier 
cmp al,3
je double_clique_dossier
jmp attent_clav


;**************
double_clique_fichier:
mov edx,[ebx+if_ext]
add edx,[ad_onglet]
call recherche_ext
cmp eax,0
jne attent_clav 
mov ecx,0
call action_fichier
jmp attent_clav 


;***************
double_clique_dossier:   ;???????????????????????????,,a mettre au point pour liberer d'abord la zone mémoire reservé par le précédent onglet
mov edi,dossier_ouvert


call insert_dossier
cmp edi,dossier_ouvert+511
je fin_double_clique_dossier

mov esi,[ebx+if_nom]
add esi,[ad_onglet]
boucle_double_clique_dossier:
lodsb
stosb
cmp al,0
je fin_double_clique_dossier
cmp edi,dossier_ouvert+511
je fin_commande
jmp boucle_double_clique_dossier

fin_double_clique_dossier:

;determine l'adresse maximum visité
mov esi,[ad_onglet]
add esi,do_adresse_max
mov edx,dossier_ouvert
mov edi,dossier_max
@@:
lodsb
cmp al,[edx]
jne @f
stosb
cmp al,0
je fin_deter_adresse_max
inc edx
jmp @b

@@:
dec esi
cmp byte[edx],0
je @f
mov esi,edx

@@:
lodsb
stosb
cmp al,0
jne @b

fin_deter_adresse_max:



;ouvre le dossier
xor eax,eax
xor ebx,ebx
mov edx,dossier_ouvert
cmp byte[edx],0
je @f
int 64h             ;ouvre le fichier
cmp eax,cer_dov
jne affichage_ecran   ;fin_erreur_ouverture
@@:

;charge le dossier de base
call ouvre_onglet
cmp eax,0
jne fin_erreur_memoire
jmp affichage_ecran





;***************************************
clique_bouton:
shr ebx,3
cmp ebx,bouton2-bouton1-2
jb quitter
cmp ebx,bouton2-bouton1
jb attent_clav

cmp ebx,bouton3-bouton1-2
jb nv_onglet
cmp ebx,bouton3-bouton1
jb attent_clav

cmp ebx,bouton4-bouton1-2
jb nv_fenetre
cmp ebx,bouton4-bouton1
jb attent_clav

cmp ebx,entrebouton-bouton1-2
jb af_tecop

jmp attent_clav




;**********
clique_onglet:
;?????????????????????
jmp attent_clav









;********
af_tecop:
mov dword[zt_travail],"CD  "

;recopie l'adresse actuelle
mov esi,[ad_onglet]
add esi,do_adresse
mov edi,zt_travail+3
mov ecx,64
cld
rep movsd

xor eax,eax      ;envoie commande
mov edx,zt_travail
int 61h

mov eax,3   ;affichage du tecop
xor edx,edx
int 63h
jmp attent_clav




;**********
nv_fenetre:
mov dword[zt_travail],"EXPL"
mov byte[zt_travail+4]," "

;recopie l'adresse actuelle
mov esi,[ad_onglet]
add esi,do_adresse
mov edi,zt_travail+5
mov ecx,64
cld
rep movsd

xor eax,eax      ;envoie commande
mov edx,zt_travail
int 61h
jmp attent_clav



;**********
nv_onglet:
;?????????????????????
jmp attent_clav








;***************************************
clique_adresse:
shr ebx,3
cmp ecx,0
je clique_adresse0
xor eax,eax
fs
mov ax,[resx_texte]
add ebx,eax
clique_adresse0:


;vas a la racine si besoin
cmp ebx,6
jb racine_clique_adresse
sub ebx,6


;recopie l'adresse actuelle
mov esi,[ad_onglet]
add esi,do_adresse_max
mov edi,dossier_ouvert
mov ecx,64
cld
rep movsd

mov esi,dossier_ouvert
boucle1_clique_adresse:
cmp ebx,0
je boucle2_clique_adresse
mov al,[esi]
and al,0C0h
cmp al,80h
je @f
dec ebx
@@:
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

racine_clique_adresse:
mov byte[dossier_ouvert],0
jmp fin_double_clique_dossier

fin_clique_adresse:
mov byte[esi],0
jmp fin_double_clique_dossier




;************************************
clique_d:
;?????????????????
jmp attent_clav








;***********************************
retour:



;recopie l'adresse actuelle
mov esi,[ad_onglet]
add esi,do_adresse
mov edi,dossier_ouvert
mov ecx,64
cld
rep movsd

mov ebx,dossier_ouvert
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
mov byte[edx],0


jmp fin_double_clique_dossier











;************************
recherche_ext:

;convertit l'extension en majuscule
mov edi,zt_travail
boucle1_recherche_ext:
mov al,[edx]
cmp al,"a"
jb @f
cmp al,"z"
ja @f
sub al,"a"-"A"
@@:
mov [edi],al
inc edx
inc edi
cmp al,0
jne boucle1_recherche_ext



;recherche la ligne de l'extension
mov edx,actions_bdd
recherche_ext_boucle1:
mov esi,edx
mov edi,zt_travail
@@:
mov al,[esi]
cmp [edi],al
jne @f 
inc esi
inc edi
jmp @b

@@:
cmp byte[edi],0
jne recherche_ext_suite 
cmp al,"|"
je recherche_ext_trouve 
cmp al,13
je recherche_ext_trouve
cmp al,0
je recherche_ext_nontrouve

recherche_ext_suite:
call ligne_suivante
cmp byte[edx],0
je recherche_ext_nontrouve
jmp recherche_ext_boucle1

recherche_ext_trouve:
call ligne_suivante
cmp byte[edx],0
je recherche_ext_nontrouve
cmp byte[edx]," "
jne recherche_ext_trouve
xor eax,eax
ret

recherche_ext_nontrouve:
mov eax,1
ret





;passe a la ligne suivante
ligne_suivante:
cmp byte[edx],0
jne @f
ret
@@:
cmp byte[edx],13
jne @f
cmp byte[edx+1],13
je @f
inc edx
ret
@@:
inc edx
jmp ligne_suivante



;***************************
action_fichier:
cmp byte[edx]," "
jne action_fichier_erreur
cmp ecx,0
je action_fichier_ok
dec ecx
call ligne_suivante
jmp action_fichier

action_fichier_erreur:
mov eax,1
ret

;va au descriptif de la commande
action_fichier_ok:
inc edx
cmp byte[edx],13
je action_fichier_erreur
cmp byte[edx],0
je action_fichier_erreur
cmp byte[edx],"|"
jne action_fichier_ok 
inc edx

;recopie la bonne commande
mov esi,edx
mov edi,zt_travail
boucle_prepcommande:
lodsb
cmp al,0
je fin_commande
cmp al,13
je fin_commande
cmp al,"$"
je inser_nomext
cmp al,"&"
je inser_nom
stosb
cmp edi,zt_travail+1023
jne boucle_prepcommande


fin_commande:
xor eax,eax
stosb
mov edx,zt_travail
int 61h

mov eax,3   ;affichage du tecop
xor edx,edx
int 63h
xor eax,eax
ret


inser_nomext:
call insert_dossier
cmp edi,zt_travail+1023
je fin_commande
push esi
mov esi,[ebx+if_nom]
add esi,[ad_onglet]
boucle_insertnomext:
lodsb
cmp al,0
je fin_insert_nomext
stosb
cmp edi,zt_travail+1023
je fin_commande
jmp boucle_insertnomext

fin_insert_nomext:
pop esi
jmp boucle_prepcommande


inser_nom:
call insert_dossier
cmp edi,zt_travail+1023
je fin_commande
push esi
mov esi,[ebx+if_nom]
add esi,[ad_onglet]
mov ebp,[ebx+if_ext]
add ebp,[ad_onglet]
boucle_insertnom:
lodsb
cmp esi,ebp
je fin_insert_nom
stosb
cmp edi,zt_travail+1023
je fin_commande
jmp boucle_insertnom

fin_insert_nom:
pop esi
jmp boucle_prepcommande



insert_dossier:
push esi
mov esi,[ad_onglet]
add esi,do_adresse
cmp byte[esi],0
je fin2_insert_dossier

boucle_insert_dossier:
lodsb
cmp al,0
je fin_insert_dossier
stosb
cmp edi,zt_travail+1023
jne boucle_insert_dossier

pop esi
ret

fin_insert_dossier:
mov al,"/"
stosb

fin2_insert_dossier:
pop esi
ret

;***********************************
touche_haut:
cmp dword[ligne_zero],0
je attent_clav
dec dword[ligne_zero]
jmp affichage_ecran



;***********************************
touche_bas:
mov eax,[ligne_max]
cmp [ligne_zero],eax
je attent_clav
inc dword[ligne_zero]
jmp affichage_ecran


;***********************************
touche_pageup:
mov ecx,[ligne_aff]
cmp dword[ligne_zero],ecx
jb touche_pageupp
sub dword[ligne_zero],ecx
jmp affichage_ecran
touche_pageupp:
mov dword[ligne_zero],0
jmp affichage_ecran


;***********************************
touche_pagedown:
mov ecx,[ligne_aff]
mov eax,[ligne_zero]
add eax,ecx
cmp eax,[ligne_max]
ja touche_pagedownn
add dword[ligne_zero],ecx
jmp affichage_ecran
touche_pagedownn:
mov eax,[ligne_max]
mov [ligne_zero],eax
jmp affichage_ecran





;********************************************************************************************************************************************



;******************************************************************
;ouvre un nouvel onglet
ouvre_onglet:    ;ebx=numéros du dossier ouvert dossier_ouvert et dossier_max=nom du dossier max et adresse max


;reservation mémoire
mov dx,sel_dat1
mov ecx,[adresse_max]
add ecx,taille_zt_base
mov al,8
int 61h
cmp eax,0
jne ouvre_onglet_erreur_memoire 

mov edx,[adresse_max]
add dword[adresse_max],taille_zt_base


;enregistrement info base
mov dword[edx+do_ts],taille_zt_base
mov dword[edx+do_to_zn],taille_zt_base-do_ad_zn
mov [edx+do_handle],ebx
mov dword[edx+do_nb_nom],0

;recopie adresses dossier
mov esi,dossier_ouvert
lea edi,[edx+do_adresse]
mov edi,edx
add edi,do_adresse
mov ecx,256
cld
rep movsd

;si on est a la racine, on va charger une liste des disques accesible
cmp byte[edx+do_adresse],0
je ouvre_onglet_racine

;chargement dossier
ouvre_onglet_chdos:
mov eax,16
mov ebx,[edx+do_handle]
mov ecx,[edx+do_to_zn]
lea edi,[edx+do_ad_zn]
push edx
xor edx,edx
int 64h
pop edx
cmp eax,0
je charge_tailles

;si pas assez de mémoire on agandit
mov ecx,[edx+do_to_zn]
add [edx+do_to_zn],ecx
add [edx+do_ts],ecx
add [adresse_max],ecx
push edx
mov dx,sel_dat1
mov al,8
int 61h
pop edx
cmp eax,0
jne ouvre_onglet_erreur_memoire 
jmp ouvre_onglet_chdos


;agrandissement mémoire pour index
charge_tailles:
mov ecx,[edx+do_to_zn]
mov [edx+do_to_zi],ecx
add [edx+do_ts],ecx
add [adresse_max],ecx
mov ecx,[adresse_max]
push edx
mov dx,sel_dat1
mov al,8
int 61h
pop edx
cmp eax,0
jne ouvre_onglet_erreur_memoire 

;extraction nom ext
lea esi,[edx+do_ad_zn]
mov edi,esi
add edi,[edx+do_to_zn]
mov ebx,esi
mov ebp,esi

boucle_comptage:
cmp byte[esi],"|"
je comptage_nom
cmp byte[esi],"."
je comptage_ext
cmp byte[esi],0
je dernier_nom
inc esi
jmp boucle_comptage

comptage_ext:
inc esi
mov ebp,esi
jmp boucle_comptage

comptage_nom:
inc dword[edx+do_nb_nom]
mov [edi+if_nom],ebx
mov [edi+if_ext],ebp
mov dword[edi+if_taille],0
mov dword[edi+if_taille+4],0
mov dword[edi+if_att],0
sub [edi+if_nom],edx
sub [edi+if_ext],edx
add edi,32

mov byte[esi],0
inc esi
mov ebx,esi
mov ebp,esi
jmp boucle_comptage


dernier_nom:
inc dword[edx+do_nb_nom]
mov [edi+if_nom],ebx
mov [edi+if_ext],ebp
mov dword[edi+if_taille],0
mov dword[edi+if_taille+4],0
mov dword[edi+if_att],0
sub [edi+if_nom],edx
sub [edi+if_ext],edx


ouvre_onglet_ajustements:
;ajustement taille mémoire
mov ecx,[edx+do_nb_nom]
shl ecx,5
mov [edx+do_to_zi],ecx
add ecx,[edx+do_to_zn]
add ecx,do_ad_zn
add ecx,edx

push edx
mov dx,sel_dat1
mov [adresse_max],ecx
mov al,8
int 61h
pop edx
cmp eax,0
jne ouvre_onglet_erreur_memoire2 


;incrémente le nombre d'onglet et enregistre 
mov eax,[nb_onglet]
lea ebx,[eax*4+table_onglet]
mov [ebx],edx
mov [no_onglet],eax
inc eax
mov [nb_onglet],eax
mov dword[ligne_zero],0

xor eax,eax
ret



;erreur reservation: on supprime la zone
ouvre_onglet_erreur_memoire2:
;????????????????


ouvre_onglet_erreur_memoire:
mov eax,cer_pasm
ret


ouvre_onglet_racine:

;lit les disques actif
push edx
mov eax,17
mov edx,zt_travail
int 64h
pop edx


mov dword[edx+do_to_zn],4096
lea edi,[edx+do_ad_zn]
mov esi,edi
add esi,[edx+do_to_zn]


mov dword[edi],"#dm"
call ajdisque
add edi,3
xor al,al
stosb


;test si la disquette est disponible
test byte[zt_travail+29],80h
jz ouvre_disque_pasdi
mov dword[edi],"#di"
call ajdisque
add edi,3
xor al,al
stosb
ouvre_disque_pasdi:


mov ch,[zt_travail+30]
mov cl,1
ouvre_disque_bouclecd:
test ch,1
jz ouvre_disque_pascd
mov dword[edi],"#cd"
call ajdisque
add edi,3
mov al,cl
add al,"0"
stosb
xor al,al
stosb

ouvre_disque_pascd:
inc cl
shr ch,1
cmp cl,8
jne ouvre_disque_bouclecd



mov ch,[zt_travail] ;!!!!!!!!!!!!!!!!!!!!!!!ne tient compte que des 8 premières partition!!!!!!
mov cl,1
ouvre_disque_bouclepart:
test ch,1
jz ouvre_disque_paspart
mov dword[edi],"#dd"
call ajdisque
add edi,3
mov al,cl
add al,"0"
stosb
xor al,al
stosb

ouvre_disque_paspart:
inc cl
shr ch,1
cmp cl,8
jne ouvre_disque_bouclepart


jmp ouvre_onglet_ajustements





;**********************
ajdisque:
mov eax,edi
sub eax,edx
mov [esi+if_nom],eax
mov [esi+if_ext],eax
mov dword[esi+if_taille],0
mov dword[esi+if_taille+4],0
mov dword[esi+if_att],3
inc dword[edx+do_nb_nom]
add esi,32
ret





;******************************************
;lib_onglet:   ;ecx=numéros de l'onglet





ret



;******************************************
;ferme_onglet:   ;ecx=numéros de l'onglet

;décale données (si besoin)
mov eax,ecx
inc eax
cmp eax,[nb_onglet]
je ignore
mov edx,[nb_onglet]
sub edx,eax
shl ecx,2
shl eax,2
mov esi,[eax+table_onglet]
mov edi,[ecx+table_onglet]
mov ebp,esi
sub ebp,edi
lea ebx,[eax+table_onglet]
mov ecx,[adresse_max]
sub ecx,esi
cld
rep movsb

;décale index avec correction de l'offset
boucle:
mov eax,[ebx+4]
sub eax,ebp
mov[ebx],eax
add ebx,4
dec edx
jnz boucle

sub [adresse_max],ebp
;?????????????????réserve moins de mémoire?

ignore:
dec dword[nb_onglet]
ret








;***********************************
sf_charge_taille_type:      
pushad

mov edi,ebx
mov esi,[ad_onglet]


xor eax,eax
mov ebx,[esi+do_handle]
mov edx,[edi+if_nom]
add edx,esi
int 64h             ;ouvre le fichier
cmp eax,cer_dov
je sfd_charge_taille
cmp eax,0
jne sfe_charge_taille


;lit la taille
mov al,6
mov ah,1
mov edx,edi
add edx,if_taille
int 64h

mov al,1   ;et ferme le fichier
int 64h

mov dword[edi+if_att],1
popad
ret


sfd_charge_taille:   ;le fichier est un dossier
mov al,1   ;et ferme le fichier
int 64h
sfr_charge_taille:
mov dword[edi+if_taille],0
mov dword[edi+if_taille+4],0
mov dword[edi+if_att],3
popad
ret


sfe_charge_taille:   ;erreur lors sde l'ouverture fichier
mov dword[edi+if_taille],0
mov dword[edi+if_taille+4],0
mov dword[edi+if_att],0
popad
ret












;********************************************************************************************************************************************
sdata1:
org 0

bouton1:
db "ESC:Quitter",0,0
bouton2:
db "F1:Nouvel onglet",0,0
bouton3:
db "F2:Nouvelle fenetre",0,0
bouton4:
db "F3:Ouvrir dans le TECOP",13,0
entrebouton:
db "~~",0

aide:
db "echap=quitter backspace=retour dossier précédent",0

selection:
db "veuillez selectionner le disque a parcourir",0

patientez:
db "veuillez patienter durant le chargement du contenu du dossier",0


menudossier:
db "ouvrir dans une nouvelle fenetre",13
db "ouvrir dans un nouvel onglet",13,0


racine:
db "Racine/",0


msg_erreur_mem:
db "EXPL: pas assez de mémoire pour continuer",13,0
msg_erreur_ouv:
db "EXPL: erreur lors de l'ouverture du dossier ",0


octets:
db " Octets"

findeligne:
db 13,0

interval:
db " - ",0

dernier_clique:
dd 0
ligne_zero:
dd 0
ligne_aff:
dd 0
ligne_max:
dd 0
adresse_max:
dd actions_bdd

touche_importante:
db 0




nb_onglet:
dd 0
no_onglet:
dd 0
ad_onglet:
dd 0

nom_bdd:
db "EXPL.CFG",0
taille_bdd:
dd 0,0

descriptif:
db "Explorateur dossier "


dossier_ouvert:
rb 512
dossier_max:
rb 512
table_onglet:
rb 256

zt_travail:
rb 1024

actions_bdd:






sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
