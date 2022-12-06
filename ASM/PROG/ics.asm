ics:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Interface de Commande Simplifié"
scode:
org 0

;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax
mov fs,ax

redim_ecran:
mov dx,sel_dat2
mov ah,6   ;option=mode video + souris
mov al,0   ;création console     
int 63h
cmp eax,0
jne erreur_mode

;récupère le curseur basique (ou alors faut il directement l'integrer?)
mov ax,sel_dat1
mov es,ax
mov ax,sel_dat2
mov ds,ax
mov edi,curnorm
mov esi,[ad_curseur]
mov ecx,64
rep movsd


mov ax,sel_dat1
mov ds,ax
mov es,ax
mov ax,sel_dat2
mov fs,ax
fs
or byte[at_console],8  ;met a 1 le bit de non mise a jour de l'ecran apres int 63h





;test si il faut une couleur de fond spéciale
mov al,5   
mov ah,"c"   ;numéros de l'option de commande a lire
mov cl,16   
mov edx,tempo
int 61h
cmp eax,0
jne @f
mov al,101
mov edx,tempo
int 61h
or ecx,0FF000000h
mov [couleur],ecx
@@:


;test si il faut une couleur de texte spéciale
mov al,5   
mov ah,"t"   ;numéros de l'option de commande a lire
mov cl,16   
mov edx,tempo
int 61h
cmp eax,0
jne @f
mov al,101
mov edx,tempo
int 61h
mov [texte],ecx
@@:



;************************************************
;récupère les icones
mov al,5   
mov ah,"i"   ;numéros de l'option de commande a lire
mov cl,16   
mov edx,tempo
int 61h
mov edx,fichier_icone
cmp eax,0
jne @f
cmp byte[tempo],0
je @f
mov edx,tempo
@@:

;ouvre le fichier
mov al,0
xor ebx,ebx
int 64h
cmp eax,0
jne erreur_icone
mov [handle_fichier],ebx


;lit les carac de l'image
mov ebx,[handle_fichier]
mov al,51
int 63h
cmp eax,0
jne erreur_icone
mov [taille_icone],ebx



;aggrandit la zone pour pouvoir y charger l'image et la zone de traitement icone
xor eax,eax
mov al,dl
shr edx,8 
add edx,14
shr eax,3
mov ecx,sdata2
mov [reserve_icone],ecx
add ecx,edx
mov [travail_icone],ecx


push edx
xor edx,edx
mov ebx,[taille_icone]
mul ebx
mul ebx
add eax,14 ;eax=taille de la zone consacré au travail de l'icone
add ecx,eax
mov [fond_ecran],ecx


mov dx,sel_dat1
mov eax,8
int 61h
cmp eax,0
jne erreur_mem


;lit l'image
mov ebx,[handle_fichier]
mov edi,[reserve_icone]
mov al,52
int 63h
cmp eax,0
jne erreur_icone


;ferme le fichier
mov al,1
mov ebx,[handle_fichier]
int 64h


;crée l'icone vide
mov ebx,[taille_icone] 
mov ecx,[taille_icone]
mov edi,[reserve_icone]
mov ah,[edi+objimage_bpp]
mov edx,[couleur]
mov edi,[travail_icone]
mov al,50
int 63h
cmp eax,0
jne erreur_icone



;*****************************************
;récupère l'image de fond
mov al,5   
mov ah,"f"   ;numéros de l'option de commande a lire
mov cl,16   
mov edx,tempo
int 61h
mov edx,fichier_fond
cmp eax,0
jne @f
cmp byte[tempo],0
je @f
mov edx,tempo
@@:


;ouvre le fichier
mov al,0
xor ebx,ebx
int 64h
cmp eax,0
jne pas_de_fond
mov [handle_fichier],ebx


;lit les carac de l'image
mov ebx,[handle_fichier]
mov al,51
int 63h
cmp eax,0
jne erreur_fond


;calcule la taille de l'image de fond
pushad
xor ecx,ecx
mov cl,dl
shr ecx,3
xor eax,eax
xor ebx,ebx
xor edx,edx
fs
mov ax,[resx_ecran]
fs
mov bx,[resy_ecran]
mul ecx
mul ebx
add eax,14 ;eax=taille de l'image
add eax,[fond_ecran]
mov [fin_mem],eax
popad



;aggrandit la zone pour pouvoir y charger l'image de fond et la version brute
shr edx,8 
mov [taille_fond],edx
shl edx,1
mov ecx,[fin_mem]
add ecx,edx
mov dx,sel_dat1
mov eax,8
int 61h
cmp eax,0
jne erreur_mem


;lit l'image
mov ebx,[handle_fichier]
mov edi,[fin_mem]
mov al,52
int 63h
cmp eax,0
jne erreur_fond


;ferme le fichier
mov al,1
mov ebx,[handle_fichier]
int 64h


;cree  l'image de fond vide
xor ebx,ebx
xor ecx,ecx
fs
mov bx,[resx_ecran] 
fs
mov cx,[resy_ecran]
mov edi,[fin_mem]
mov ah,[edi+objimage_bpp]
mov edx,[couleur]
mov edi,[fond_ecran]
mov al,50
int 63h


;calcul la taille intermédiaire
xor eax,eax
xor ecx,ecx
mov esi,[fond_ecran]
mov edi,[fin_mem]
mov ax,[esi+objimage_x]
mov cx,[edi+objimage_y]
mul ecx
mov cx,[esi+objimage_y]
div ecx
cmp ax,[edi+objimage_x]
ja autre_carac_base

xor ebx,ebx
xor ecx,ecx
mov edi,[fin_mem]
mov cx,[edi+objimage_y]
mov bx,ax
mov ah,[edi+objimage_bpp]
mov edx,[couleur]
mov edi,[fin_mem]
add edi,[taille_fond]
mov al,50
int 63h
jmp fin_calcul_intermediaire


autre_carac_base:
xor eax,eax
xor ecx,ecx
mov esi,[fond_ecran]
mov edi,[fin_mem]
mov ax,[esi+objimage_y]
mov cx,[edi+objimage_x]
mul ecx
mov cx,[esi+objimage_x]
div ecx
cmp ax,[edi+objimage_y]
ja autre_carac_base

xor ebx,ebx
xor ecx,ecx
mov edi,[fin_mem]
mov bx,[edi+objimage_x]
mov cx,ax
mov ah,[edi+objimage_bpp]
mov edx,[couleur]
mov edi,[fin_mem]
add edi,[taille_fond]
mov al,50
int 63h
fin_calcul_intermediaire:


;extrait le fragment
mov esi,[fin_mem]
mov edi,[fin_mem]
add edi,[taille_fond]
xor ebx,ebx
xor ecx,ecx
mov bx,[esi+objimage_x]
mov cx,[esi+objimage_y]
sub bx,[edi+objimage_x]
sub cx,[edi+objimage_y]
shr ebx,1
shr ecx,1
mov al,54
int 63h


;remet a niveau
mov esi,[fin_mem]
add esi,[taille_fond]
mov edi,[fond_ecran]
mov al,53
int 63h


;libère mémoire
mov ecx,[fin_mem]
mov dx,sel_dat1
mov eax,8
int 61h
cmp eax,0
jne erreur_mem
jmp affichage



pas_de_fond:
;calcule la taille de l'image de fond
xor ecx,ecx
mov cl,dl
shr ecx,3
xor eax,eax
xor ebx,ebx
xor edx,edx
fs
mov ax,[resx_ecran]
fs
mov bx,[resy_ecran]
mul ecx
mul ebx
add eax,14 ;eax=taille de l'image
add eax,[fond_ecran]
mov [fin_mem],eax


;aggrandit la zone pour pouvoir y charger l'image de fond
mov ecx,[fin_mem]
mov dx,sel_dat1
mov eax,8
int 61h
cmp eax,0
jne erreur_mem


;cree  l'image de fond vide
xor ebx,ebx
xor ecx,ecx
fs
mov bx,[resx_ecran] 
fs
mov cx,[resy_ecran]
mov ah,24
mov edx,[couleur]
mov edi,[fond_ecran]
mov al,50
int 63h





;************************************************************************************************
affichage:
;affiche le fond
xor ebx,ebx
xor ecx,ecx
mov edx,[fond_ecran]
mov al,27   ;afficher image    
int 63h


;affiche les icones
mov esi,objetsgraf
@@:
cmp dword[esi],0
je @f
call affiche_icone
mov eax,[esi]
add esi,eax
jmp @b
@@:


mov eax,7  ;demande la mise a jour ecran
int 63h


;****************************************************************************************
attend_touche:
fs
test byte[at_console],20h
jnz redim_ecran 



mov al,5
int 63h
cmp al,1  ;echap on quitte
je touche_esc
cmp al,0F0h
je clique
cmp al,0F1h
je declique
cmp al,0F2h
;je clique_droit

cmp byte[mode],0
je attend_touche
mov esi,[adresse_objet_deplace]
xor eax,eax
xor ebx,ebx
fs
mov ax,[posx_souris]
fs
mov bx,[posy_souris]
sub eax,[decalx_objet_deplace]
sub ebx,[decaly_objet_deplace]

mov edx,[taille_icone]
shr edx,1
cmp eax,edx
jb @f
test eax,80000000h
jnz @f
mov [esi+8],eax
@@:
cmp ebx,16
jb affichage
test ebx,80000000h
jnz affichage
mov [esi+12],ebx
jmp affichage




touche_esc:
int 60h






declique:
mov byte[mode],0
call aff_curseur_normal
jmp attend_touche






;**************************
clique:
mov al,12
int 61h
cmp eax,[dernier_clique]
jb double_clique
add eax,150
mov [dernier_clique],eax

mov ebp,eax
@@:
mov al,5
push ebx
push ecx
int 63h
pop ecx
pop ebx
cmp al,1  ;echap on quitte
je touche_esc
cmp al,0F1h
je attend_touche
mov al,12
int 61h
cmp eax,ebp
jb @b



call recherche_objet
cmp esi,0
je attend_touche

mov byte[mode],1   ;passe en mode déplacement d'objet
call aff_curseur_croix
sub ebx,[esi+8]
sub ecx,[esi+12]
mov [adresse_objet_deplace],esi
mov [decalx_objet_deplace],ebx
mov [decaly_objet_deplace],ecx
jmp affichage




double_clique:
call recherche_objet
cmp esi,0
je attend_touche 

lea edx,[esi+16]
@@:
cmp byte[edx],0
je @f
inc edx
jmp @b

@@:
inc edx
cmp byte[edx],0
je @f
xor eax,eax   ;envoie la commande
int 61h
@@:
mov eax,3   ;affichage du tecop
xor edx,edx
int 63h
jmp attend_touche



;*************************************************
erreur_mode:
mov al,6
mov edx,msg_ereur_mdv
int 61h
int 60h

erreur_icone:
mov al,6
mov edx,msg_ereur_ico
int 61h
int 60h

erreur_mem:
mov al,6
mov edx,msg_ereur_fde
int 61h
int 60h


erreur_fond:
mov al,6
mov edx,msg_ereur_fde
int 61h
int 60h






recherche_objet:
mov esi,objetsgraf
boucle_recherche_objet:
cmp dword[esi],0
je recherche_objet_pastrouve
push ebx
push ecx
cmp ebx,[esi+8]
jb recherche_objet_suivant
sub ebx,[taille_icone]
jb @f
cmp ebx,[esi+8]
jae recherche_objet_suivant
@@:

cmp ecx,[esi+12]
jb recherche_objet_suivant
sub ecx,[taille_icone]
jb recherche_objet_trouve
cmp ecx,[esi+12]
jb recherche_objet_trouve

recherche_objet_suivant:
pop ecx
pop ebx
mov eax,[esi]
add esi,eax
jmp boucle_recherche_objet

recherche_objet_pastrouve:
xor esi,esi
ret

recherche_objet_trouve:
pop ecx
pop ebx
ret










affiche_icone:
xor eax,eax
mov al,[esi+5]
mov ecx,[taille_icone]
mul ecx
mov ecx,eax
xor ebx,ebx
push esi
mov esi,[reserve_icone]
mov edi,[travail_icone]
mov al,54
int 63h
pop esi

mov ebx,[esi+8]
mov ecx,[esi+12]
mov edx,[travail_icone]
mov al,27
int 63h


mov eax,[taille_icone]
mov ebx,[esi+8]
mov ecx,[esi+12]
lea edx,[esi+16]
push esi
add ecx,eax
shr eax,1
add ebx,eax
shr eax,1
mov esi,eax
push ecx
push edx
push esi

mov esi,edx
mov edi,edx
;convertit  les CR en espace
@@:
cmp byte[esi],0
je @f
cmp byte[esi],13
jne pasdecr
mov byte[esi]," "
pasdecr:
inc esi
jmp @b
@@:

;rajoute des CR bien placé
mov esi,edx
mov edx,[taille_icone]
shr edx,2 ;div par 8 mul par 2
xor eax,eax
xor ecx,ecx
xor ebp,ebp

boucle3_affiche_icone:
mov dh,[esi]
cmp dh," "
jne @f 
mov ebp,esi
@@:
cmp dh,0
je fin3_affiche_icone
and dh,0C0h
cmp dh,80h
je @f
inc cl
cmp cl,dl
jne @f
mov esi,ebp
mov byte[esi],13
xor ecx,ecx
@@:
inc esi
jmp boucle3_affiche_icone


fin3_affiche_icone:


;compte la largeur max
mov esi,edi
xor edx,edx
xor eax,eax
boucle4_affiche_icone:
mov dh,[esi]
cmp dh,13
je enregmax_affiche_icone
cmp dh,0
je fin4_affiche_icone
and dh,0C0h
cmp dh,80h
je @f
inc dl
@@:
inc esi
jmp boucle4_affiche_icone

enregmax_affiche_icone:
cmp dl,al
jbe @f
mov al,dl
xor edx,edx
@@:
inc esi
jmp boucle4_affiche_icone

fin4_affiche_icone:
cmp dl,al
jbe @f
mov al,dl
@@:
shl eax,2 ;mul par 8 div par 2 
pop esi
pop edx
pop ecx
sub ebx,eax
mov ah,[texte]
mov al,26
int 63h
pop esi

ret


;*********************
aff_curseur_normal:
pushad
push es
push fs
pop es
mov esi,curnorm
es
mov edi,[ad_curseur]
mov ecx,64
cld
rep movsd
pop es
popad
ret


;*********************
aff_curseur_croix:
pushad
push es
push fs
pop es
mov esi,curcrx
es
mov edi,[ad_curseur]
mov ecx,64
cld
rep movsd
pop es
popad
ret







bouton:
pushad
mov edx,0777777h
mov ebp,edx
mov edx,esi
mov ebx,[edx+8]
mov ecx,[edx+12]
mov esi,[edx+16]
mov edi,[edx+20]

mov edx,ebp
sub edx,0606060h ;afficher un carré (contour tres sombre)
mov al,22   
mov ah,24
int 63h

dec esi
dec edi

mov edx,ebp
add edx,0606060h ;afficher un carré (contour tres clair)
mov al,22   
mov ah,24
int 63h

inc ebx
inc ecx

mov edx,ebp
sub edx,0505050h ;afficher un carré (contour sombre)
mov al,22   
mov ah,24
int 63h

dec esi
dec edi

mov edx,ebp
add edx,0505050h ;afficher un carré (contour clair)
mov al,22   
mov ah,24
int 63h

inc ebx
inc ecx

mov edx,ebp
sub edx,0282828h ;afficher un carré (contour sombre)
mov al,22   
mov ah,24
int 63h

dec esi
dec edi

mov edx,ebp
add edx,0282828h ;afficher un carré (contour clair)
mov al,22   
mov ah,24
int 63h

inc ebx
inc ecx

mov edx,ebp  ;afficher un carré (centre)
mov al,22   
mov ah,24
int 63h
popad
ret







sdata1:
org 0

msg_ereur_mdv:
db "ICS: impossible de démarrer en mode texte",13,0
msg_ereur_ico:
db "ICS: erreur lors de la lecture du fichier des icones",13,0
msg_ereur_mem:
db "ICS: erreur de reservation mémoire",13,0
msg_ereur_fde:
db "ICS: erreur lors de la lecture du fichier de fond d'ecran",13,0


dernier_clique:
dd 0

mode:
db 0
adresse_objet_deplace:
dd 0
decalx_objet_deplace:
dd 0
decaly_objet_deplace:
dd 0


handle_fichier:
dd 0

taille_icone:   ;largeur icone
dd 0


taille_fond:   ;taille prise par le fichier image du fond
dd 0


;adresses des zones mémoire
reserve_icone:
dd 0
travail_icone:
dd 0
fond_ecran:
dd 0
fin_mem:
dd 0


;informations par défaut
fichier_fond:
db "fond.png",0
;db "#dd5/CPCDOS/OS/MEDIA/ABS_BLUE.PNG",0
fichier_icone:
db "icones.png",0
couleur:
dd 0FF007070h ;bleu/vert moche de win95
texte:
dd 0Fh      ;code 16 couleurs blanc







objetsgraf:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 1        ;numéros de l'icone
dw 0        ;vide
dd 32,16    ;coordonné coin supérieur gauche
db "explorateur de fichier",0  ;texte de l'icone
db "expl #",0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 0        ;numéros de l'icone
dw 0        ;vide
dd 32,128   ;coordonné coin supérieur gauche
db "console de commande",0  ;texte de l'icone
db 0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 5        ;numéros de l'icone
dw 0        ;vide
dd 32,240    ;coordonné coin supérieur gauche
db "terminal série et TCP",0  ;texte de l'icone
db "term",0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 2        ;numéros de l'icone
dw 0        ;vide
dd 32,352    ;coordonné coin supérieur gauche
db "partitionneur",0  ;texte de l'icone
db "partd",0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 8        ;numéros de l'icone
dw 0        ;vide
dd 144,128    ;coordonné coin supérieur gauche
db "jeu N°1",0  ;texte de l'icone
db "jn1",0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 3        ;numéros de l'icone
dw 0        ;vide
dd 144,16    ;coordonné coin supérieur gauche
db "calculatrice",0  ;texte de l'icone
db "calc",0  ;commande de l'icone
@@:

dd 0







curcrx:
include "../PROG/curs_crx.inc"

curnorm:
rb 256

tempo:
rb 256



sdata2:
org 0
;donnÃ©es du segment ES
sdata3:
org 0
;donnÃ©es du segment FS
sdata4:
org 0
;donnÃ©es du segment GS
findata: