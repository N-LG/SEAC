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



;initialise la mémoire
mov ecx,sdata2
mov edx,ad_objet-8
@@:
add edx,8
mov [edx],ecx
add ecx,[edx+4]
cmp edx,ad_tempo
jne @b
mov [edx],ecx
add ecx,[edx+4]
mov dx,sel_dat1
mov eax,8
int 61h
cmp eax,0
jne erreur_mem



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


;récupère les icones
mov al,5   
mov ah,"i"   ;numéros de l'option de commande a lire
mov cl,16   
mov edx,fichier_icones
int 61h




;recupère l'image de fond
mov al,5   
mov ah,"f"   ;numéros de l'option de commande a lire
mov cl,16   
mov edx,fichier_fond
int 61h



;recupère les data 
mov al,5   
mov ah,"b"   ;numéros de l'option de commande a lire
mov cl,16   
mov edx,fichier_objets
int 61h



;initialise les objets

;ouvre le fichier
mov al,0
mov ebx,1
mov edx,fichier_objets
cmp byte[edx],0
jne @f
mov edx,fichier_objets_def
@@:
int 64h
cmp eax,0
jne objet_de_base
mov [handle_fichier],ebx


;lit la taille
mov al,6
mov ah,1
mov ebx,[handle_fichier]
mov edx,tempo
int 64h
cmp eax,0
jne erreur_objet


;agrandit la zone tampon pour l'acceuillir
mov ecx,[tempo]
mov edx,ad_objet
call redim_mem


;lit les objets
mov al,4
mov ebx,[handle_fichier]
mov ecx,[tempo]
xor edx,edx
mov edi,[ad_objet]
int 64h
cmp eax,0
jne erreur_objet

;ferme le fichier
mov eax,1
mov ebx,[handle_fichier]
int 64h
jmp @f



objet_de_base:
mov ecx,fin_objet_base-tempo
mov edx,ad_objet
call redim_mem

mov esi,tempo
mov edi,[ad_objet]
cld
rep movsb
@@:





call charge_icones

redim_ecran:
call charge_ecran




;************************************************************************************************
affichage:
call affiche_ecran


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
je clique_droit

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
call sauvegarde_objets
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





;************************************************
clique_droit:
call recherche_objet
cmp esi,0
je menu_param

menu_fichier:
mov edx,texte_menu_fichier
push esi
call menu
pop esi
cmp eax,0
je menu_fichier0
cmp eax,1
je menu_fichier1
cmp eax,3
je menu_fichier3
jmp affichage

menu_fichier0:
inc byte[esi+5]
jmp affichage

menu_fichier1:
dec byte[esi+5]
jmp affichage

menu_fichier3:
call supprime_icone
jmp affichage



;************************************************
menu_param:
mov edx,texte_menu_param
call menu

cmp eax,0
je menu_param0

cmp eax,3
je touche_esc

jmp affichage



menu_param0:
;ajouter une icone
mov esi,[to_objet]
mov ecx,[to_objet]
add ecx,25
mov edx,ad_objet
call redim_mem

add esi,[ad_objet]
sub esi,4

mov dword[esi],25
mov dword[esi+4],0
mov eax,[Xmenu]
mov ebx,[Ymenu]
mov [esi+8],eax
mov [esi+12],ebx
mov dword[esi+16],"Nouv"
mov dword[esi+20],"eau"
mov byte[esi+24],0
mov dword[esi+25],0

call sauvegarde_objets
jmp affichage














;*************************************************
erreur_mode:
mov al,6
mov edx,msg_ereur_mdv
call ajuste_langue
int 61h
int 60h

erreur_icone:
mov al,6
mov edx,msg_ereur_ico
call ajuste_langue
int 61h
int 60h

erreur_mem:
mov al,6
mov edx,msg_ereur_mem
call ajuste_langue
int 61h
int 60h

erreur_fond:
mov al,6
mov edx,msg_ereur_fde
call ajuste_langue
int 61h
int 60h

erreur_objet:
mov al,6
mov edx,msg_ereur_ldo
call ajuste_langue
int 61h
int 60h



;***************************************************************************************************
;**********************************************
affiche_ecran:
;affiche le fond
xor ebx,ebx
xor ecx,ecx
mov edx,[ad_fond]
mov al,27   ;afficher image    
int 63h


;affiche les icones
mov esi,[ad_objet]
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
ret






;*************************************************************************************************************************************
charge_ecran:     ;configure l'ecran et charge l'image de fond
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
cld
rep movsd


mov ax,sel_dat1
mov ds,ax
mov es,ax
mov ax,sel_dat2
mov fs,ax
fs
or byte[at_console],8  ;met a 1 le bit de non mise a jour de l'ecran apres int 63h




;ouvre le fichier
mov al,0
mov ebx,1
mov edx,fichier_fond
cmp byte[edx],0
jne @f
mov edx,fichier_fond_def
@@:
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


;agrandit la zone tampon pour l'acceuillir
push edx
shr edx,7       ;8 pour la taille, -1 pour doubler cette taille
mov ecx,edx
mov edx,ad_tempo
call redim_mem
pop edx

;calcule la taille de l'image de fond et aggrandit la zone
mov ecx,edx
and edx,0FFh
push edx
shr ecx,2
fs
mov ax,[resx_ecran]
fs
mov bx,[resy_ecran]
mul ecx
mul ebx
add eax,14 ;eax=taille de l'image

mov ecx,eax
mov edx,ad_fond
call redim_mem



;cree  l'image de fond vide
xor ebx,ebx
xor ecx,ecx
fs
mov bx,[resx_ecran] 
fs
mov cx,[resy_ecran]
pop eax
mov ah,al
mov edx,[couleur]
mov edi,[ad_fond]
mov al,50
int 63h


;lit l'image
mov ebx,[handle_fichier]
mov edi,[ad_tempo]
mov al,52
int 63h
cmp eax,0
jne erreur_fond


;ferme le fichier
mov al,1
mov ebx,[handle_fichier]
int 64h





;calcul la taille intermédiaire
xor eax,eax
xor ecx,ecx
mov esi,[ad_fond]
mov edi,[ad_tempo]
mov ax,[esi+objimage_x]
mov cx,[edi+objimage_y]
mul ecx
mov cx,[esi+objimage_y]
div ecx
cmp ax,[edi+objimage_x]
jb autre_carac_base

xor ebx,ebx
xor ecx,ecx
mov cx,[edi+objimage_y]
mov bx,ax
jmp fin_calcul_intermediaire


autre_carac_base:
xor eax,eax
xor ecx,ecx
mov ax,[esi+objimage_y]
mov cx,[edi+objimage_x]
mul ecx
mov cx,[esi+objimage_x]
div ecx

;cmp ax,[edi+objimage_y]
;ja autre_carac_base


xor ebx,ebx
xor ecx,ecx
mov bx,[edi+objimage_x]
mov cx,ax


fin_calcul_intermediaire:
;crée l'image intermédiaire
mov ah,[edi+objimage_bpp]
mov edx,[couleur]
mov edi,[to_tempo]
shr edi,1
add edi,[ad_tempo]
mov al,50
int 63h


;extrait le fragment
xor ebx,ebx
xor ecx,ecx
mov edi,[to_tempo]
shr edi,1
mov esi,[ad_tempo]
add edi,[ad_tempo]
mov bx,[esi+objimage_x]
mov cx,[esi+objimage_y]
sub bx,[edi+objimage_x]
sub cx,[edi+objimage_y]
shr ebx,1
shr ecx,1
mov al,54
int 63h


;remet a niveau
mov esi,[to_tempo]
shr esi,1
add esi,[ad_tempo]

mov edi,[ad_fond]
mov al,53
int 63h


;libère mémoire
mov ecx,0
mov edx,ad_tempo
call redim_mem
ret


pas_de_fond:
;calcule la taille de l'image de fond et aggrandit la zone
mov ecx,4
fs
mov ax,[resx_ecran]
fs
mov bx,[resy_ecran]
mul ecx
mul ebx
add eax,14 ;eax=taille de l'image

mov ecx,eax
mov edx,ad_fond
call redim_mem



;cree  l'image de fond vide
xor ebx,ebx
xor ecx,ecx
fs
mov bx,[resx_ecran] 
fs
mov cx,[resy_ecran]
mov ah,32
mov edx,[couleur]
mov edi,[ad_fond]
mov al,50
int 63h
ret













;***************************************************
charge_icones:


;ouvre le fichier
mov al,0
mov ebx,1
mov edx,fichier_icones
cmp byte[edx],0
jne @f
mov edx,fichier_icones_def
@@:
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




;aggrandit la zone pour pouvoir y charger l'image et la zone de traitement icone
mov [taille_icone],ebx
push edx
push ecx
shr edx,8 
mov ecx,edx
mov edx,ad_icones
call redim_mem
xor edx,edx
pop ecx
pop eax
and eax,0FFh
shr eax,3
mul ebx
mul ecx
add eax,14 ;eax=taille de la zone consacré au travail de l'icone
add ecx,eax
mov edx,ad_icone
call redim_mem


;lit l'image
mov ebx,[handle_fichier]
mov edi,[ad_icones]
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
mov edi,[ad_icones]
mov ah,[edi+objimage_bpp]
mov edx,[couleur]
mov edi,[ad_icone]
mov al,50
int 63h
cmp eax,0
jne erreur_icone
ret




;***************************************
redim_mem:
pushad

cmp edx,ad_tempo
jne @f


mov [to_tempo],ecx
add ecx,[ad_tempo]
mov dx,sel_dat1
mov eax,8
int 61h
cmp eax,0
jne erreur_mem
popad
mov [edx+4],ecx
ret


@@:
mov eax,[edx+4]
cmp ecx,eax
ja redim_mem_plus

;la zone est réduite

;décale les données
pushad
mov esi,[edx]
mov edi,[edx]
add esi,eax
add edi,ecx
mov ecx,[ad_tempo]
add ecx,[to_tempo]
sub ecx,esi
cmp ecx,0
je @f
cld 
rep movsb
@@:
popad

;décale les adresses
sub eax,ecx
@@:
add edx,8
sub [edx],eax
cmp edx,ad_tempo
jne @b




;change la taille
mov ecx,[to_tempo]
add ecx,[ad_tempo]
mov dx,sel_dat1
mov eax,8
int 61h
cmp eax,0
jne erreur_mem
popad
mov [edx+4],ecx
ret


;la zone est augmenté
redim_mem_plus:
pushad
;décale les adresses
sub ecx,eax
@@:
add edx,8
add [edx],ecx
cmp edx,ad_tempo
jne @b

;change la taille
mov ecx,[to_tempo]
add ecx,[ad_tempo]
mov dx,sel_dat1
mov eax,8
int 61h
cmp eax,0
jne erreur_mem
popad

;décale les données
mov edi,[ad_tempo]
add edi,[to_tempo]
dec edi
mov esi,edi
sub esi,ecx
add esi,eax
mov ecx,[ad_tempo]
add ecx,[to_tempo]
sub ecx,[edx+8]

cmp ecx,0
je @f
std 
rep movsb
@@:



popad
mov [edx+4],ecx
ret











;********************************
menu:
mov [Xmenu],ebx
mov [Ymenu],ecx
call ajuste_langue
mov [Tmenu],edx


;compte les colonnes et ligne du menu
mov eax,1
xor ecx,ecx
xor ebx,ebx

boucle_menu1:
cmp byte[edx],0
je suite_menu1
inc ecx
cmp byte[edx],13
jne @f
inc eax
xor ecx,ecx
@@:
cmp ebx,ecx
ja @f
mov ebx,ecx
@@:
inc edx
jmp boucle_menu1

suite_menu1:
shl ebx,3
shl eax,4
add ebx,2
add eax,2
mov [Cmenu],ebx
mov [Lmenu],eax


;verifie que le menu ne déborde pas de l'ecran et corrige si besoin
xor eax,eax
mov edx,[Xmenu]
fs
mov ax,[resx_ecran]
add edx,[Cmenu]
cmp edx,eax
jbe @f
sub eax,[Cmenu]
mov [Xmenu],eax
@@:
xor eax,eax
mov edx,[Ymenu]
fs
mov ax,[resy_ecran]
add edx,[Lmenu]
cmp edx,eax
jbe @f
sub eax,[Lmenu]
mov [Ymenu],eax
@@:


menu_affichage:
mov ebx,[Xmenu]
mov ecx,[Ymenu]
mov esi,[Cmenu]
mov edi,[Lmenu]
add esi,[Xmenu]
add edi,[Ymenu]
call bouton

;affiche une surbrillance
pushad
inc ebx
inc ecx
dec esi
dec edi
fs
cmp [posx_souris],bx
jb @f
fs
cmp [posy_souris],cx
jb @f
fs
cmp [posx_souris],si
jae @f
fs
cmp [posy_souris],di
jae @f
xor eax,eax
fs
mov ax,[posy_souris]
sub eax,ecx
and eax,0FFFFFFF0h 
add ecx,eax
mov edi,ecx
add edi,16
call bouton
@@:
popad


mov al,26
mov ah,0
add ebx,1
add ecx,1
mov edx,[Tmenu]
mov edi,40
int 63h


mov eax,7  ;demande la mise a jour ecran
int 63h


menu_touche:
mov al,5
int 63h
cmp al,1  ;echap on quitte
je menu_sortie
cmp al,0F0h
je menu_clique
jmp menu_affichage








menu_clique:

;test si la fenetre est dans la
mov esi,[Xmenu]
mov edi,[Ymenu]
inc esi
inc edi
cmp bx,si
jb menu_sortie
cmp cx,di
jb menu_sortie
add esi,[Cmenu]
add edi,[Lmenu]
sub esi,2
sub edi,2
cmp bx,si
jae menu_sortie
cmp cx,di
jae menu_sortie


sub ecx,[Ymenu]
dec ecx
and ecx,0FFFFFFF0h 
shr ecx,4
mov eax,ecx
ret



menu_sortie:
mov eax,-1
ret






;****************************
recherche_objet:
mov esi,[ad_objet]
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




;***************************************
sauvegarde_objets:
pushad
;ouvre le fichier
mov al,0
mov ebx,1
mov edx,fichier_objets
cmp byte[edx],0
jne @f
mov edx,fichier_objets_def
@@:
int 64h
cmp eax,0
je @f



;ou le créer
mov al,2
int 64h


@@:
mov [handle_fichier],ebx


;redimensionne
mov ecx,[to_objet]
mov dword[tempo+4],0
mov [tempo],ecx
mov ebx,[handle_fichier]
mov edx,tempo
mov al,7
mov ah,1 ;taille fichier
int 64h

;ecrit les objets
mov al,5
mov ebx,[handle_fichier]
mov ecx,[to_objet]
xor edx,edx
mov esi,[ad_objet]
int 64h

;ferme le fichier
mov eax,1
mov ebx,[handle_fichier]
int 64h
popad
ret

sauvegarde_objets_erreur:
mov al,6
mov edx,msg_ereur_svo
call ajuste_langue
int 61h

;ferme le fichier
mov eax,1
mov ebx,[handle_fichier]
int 64h
popad
ret



;***************************************
supprime_icone:
pushad

mov eax,[esi]
mov edi,esi
add esi,eax
mov ecx,[to_objet]
add ecx,[ad_objet]
sub ecx,edi
cld
rep movsb

mov ecx,[to_objet]
mov edx,ad_objet
sub ecx,eax
call redim_mem


call sauvegarde_objets
popad
ret


;********************
affiche_icone:
xor eax,eax
mov al,[esi+5]
mov ecx,[taille_icone]
mul ecx
mov ecx,eax
xor ebx,ebx
push esi
mov esi,[ad_icones]
mov edi,[ad_icone]
mov al,54
int 63h
pop esi

mov ebx,[esi+8]
mov ecx,[esi+12]
mov edx,[ad_icone]
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



;****************
bouton:
pushad
mov edx,0C0C0C0h ;afficher un carré (contour clair)
mov al,22   
mov ah,24
int 63h
inc ecx  
dec esi
mov edx,404040h  ;afficher un carré (contour sombre)
mov al,22   
mov ah,24
int 63h
inc ebx
dec edi
mov edx,808080h  ;afficher un carré (centre)
mov al,22   
mov ah,24
int 63h
popad
ret

;***************************
ajuste_langue:  ;selectionne le message adapté a la langue employé par le système
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





;***********************************************************************************************************************************
sdata1:
org 0

msg_ereur_mdv:
db "ICS: cannot start in text mode",13,0
db "ICS: impossible de démarrer en mode texte",13,0
msg_ereur_ico:
db "ICS: error while reading icon file",13,0
db "ICS: erreur lors de la lecture du fichier des icônes",13,0
msg_ereur_mem:
db "ICS: memory reservation error",13,0
db "ICS: erreur de reservation mémoire",13,0
msg_ereur_fde:
db "ICS: error while reading the wallpaper file",13,0
db "ICS: erreur lors de la lecture du fichier de fond d'ecran",13,0
msg_ereur_ldo:
db "ICS: error loading icon definition",13,0
db "ICS: erreur erreur lors du chargement de la définition des icônes",13,0
msg_ereur_svo:
db "ICS: error saving icon definition",13,0
db "ICS: erreur lors de la sauvegarde de la définition des icônes",13,0


texte_menu_param:
db "add new icon",13
db "change wallpaper",13
db "change icon set",13
db "quit",0

db "ajouter une icônes",13
db "changer fond d'écran",13
db "changer jeu d'icones",13
db "quitter",0



texte_menu_fichier:
db "change icon",13
db "change name",13
db "change command",13
db "delete",0

db "changer icône",13
db "changer nom",13
db "changer commande",13
db "supprimer",0












ad_objet:
dd 0
to_objet:
dd 0

ad_fond:
dd 0
to_fond:
dd 0

ad_icones:
dd 0
to_icones:
dd 0

ad_icone:
dd 0
to_icone:
dd 0

ad_tempo:
dd 0
to_tempo:
dd 8192





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








;variables menu
Xmenu:
dd 0
Ymenu:
dd 0
Lmenu:
dd 0
Cmenu:
dd 0
Tmenu:
dd 0






;informations par défaut
fichier_fond_def:
db "fond.png",0
fichier_icones_def:
db "icones.png",0
fichier_objets_def:
db "ICS.DAT",0


couleur:
dd 0FF007070h ;bleu/vert moche de win95
texte:
dd 0Fh      ;code 16 couleurs blanc







curcrx:
include "../PROG/curs_crx.inc"



tempo:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 1        ;numéros de l'icone
dw 0        ;vide
dd 32,16    ;coordonné coin supérieur gauche
db "Explorateur de fichier",0  ;texte de l'icone
db "expl #",0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 0        ;numéros de l'icone
dw 0        ;vide
dd 160,16   ;coordonné coin supérieur gauche
db "Console de commande",0  ;texte de l'icone
db 0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 9        ;numéros de l'icone
dw 0        ;vide
dd 32,128    ;coordonné coin supérieur gauche
db "Editeur binaire",0  ;texte de l'icone
db "edh",0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 10        ;numéros de l'icone
dw 0        ;vide
dd 160,128    ;coordonné coin supérieur gauche
db "Editeur Texte",0  ;texte de l'icone
db "edt",0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 7        ;numéros de l'icone
dw 0        ;vide
dd 32,240    ;coordonné coin supérieur gauche
db "Installation",0  ;texte de l'icone
db "install",0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 4        ;numéros de l'icone
dw 0        ;vide
dd 160,240    ;coordonné coin supérieur gauche
db "Aide",0  ;texte de l'icone
db "aide",0  ;commande de l'icone
@@:

dd 0
fin_objet_base: 


rb $-tempo+2048






fichier_fond:
rb 512

fichier_icones:
rb 512

fichier_objets:
rb 512

curnorm:
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