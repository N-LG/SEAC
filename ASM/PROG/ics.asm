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
mov [couleur_fond],ecx
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
mov [couleur_texte],cl
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







call charge_icones


redim_ecran:
call charge_ecran




;************************************************************************************************
affichage:
call affiche_ecran


;************************************************************
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
je menu_fichier_nom
cmp eax,1
je menu_fichier_icone
cmp eax,2
je menu_fichier_commande
cmp eax,3
je menu_fichier_suppr
jmp affichage


;**********
menu_fichier_nom:
push esi
push esi
push esi
add esi,16
mov edi,zt_saisie_texte
@@:
mov al,[esi]
mov [edi],al
cmp al,0
je @f
inc esi
inc edi
cmp edi,zt_saisie_texte+256
jne @b
@@:
pop esi
call affiche_ecran
pop esi
mov edx, texte_nom
mov ebx,[esi+8]
mov ecx,[esi+12]

call saisie_texte
pop ebx
cmp  al,44
jne menu_fichier_fin

;calcul la position chaine et la taille actuelle
mov edi,ebx
add edi,16
push edi
@@:
cmp byte[edi],0
je @f
inc edi
jmp @b
@@:
mov eax,edi
pop edi
sub eax,edi
jmp modification_nom_cmd




;**********
menu_fichier_icone:
mov edx, texte_icone
mov ebx,[esi+8]
mov ecx,[esi+12]

call saisie_icone
cmp  al,44
jne menu_fichier_fin
mov [esi+5],ah
jmp menu_fichier_fin




;**********
menu_fichier_commande:
push esi
push esi
push esi
add esi,16
@@:
cmp byte[esi],0
je @f
inc esi
jmp @b
@@:
inc esi
mov edi,zt_saisie_texte
@@:
mov al,[esi]
mov [edi],al
cmp al,0
je @f
inc esi
inc edi
cmp edi,zt_saisie_texte+256
jne @b
@@:
pop esi
call affiche_ecran
pop esi
mov edx, texte_nom
mov ebx,[esi+8]
mov ecx,[esi+12]

call saisie_texte
pop ebx
cmp  al,44
jne menu_fichier_fin


;calcul la position chaine et la taille actuelle
mov edi,ebx
add edi,16
@@:
cmp byte[edi],0
je @f
inc edi
jmp @b
@@:
inc edi
push edi
@@:
cmp byte[edi],0
je @f
inc edi
jmp @b
@@:
mov eax,edi
pop edi
sub eax,edi



modification_nom_cmd:
;décale les données au besoin
cmp eax,[max_chaine_saisie]
jb t_plusgrand
je t_identique

;plus petit
push edi
mov esi,edi
add esi,eax
sub esi,[max_chaine_saisie]

mov ecx,[ad_objet]
add ecx,[to_objet]
sub ecx,esi

cld
rep movsb
pop edi

mov ecx,[to_objet]
add ecx,[max_chaine_saisie]
sub ecx,eax
mov edx,ad_objet
call redim_mem

mov ecx,[max_chaine_saisie]
sub ecx,eax
add [ebx],ecx

jmp t_identique




t_plusgrand:
mov ecx,[to_objet]
add ecx,[max_chaine_saisie]
sub ecx,eax
mov edx,ad_objet
call redim_mem

push edi
mov edx,edi

mov edi,[ad_objet]
add edi,[to_objet]
dec edi

mov esi,edi
sub esi,[max_chaine_saisie]
add esi,eax

mov ecx,esi
sub ecx,edx
inc ecx

std
rep movsb
pop edi


mov ecx,[max_chaine_saisie]
sub ecx,eax
add [ebx],ecx





t_identique:
;et recopie la nouvelle chaine
mov esi,zt_saisie_texte
mov ecx,[max_chaine_saisie]
cld
rep movsb
jmp menu_fichier_fin



;**********
menu_fichier_suppr:
call supprime_icone



menu_fichier_fin:
call sauvegarde_objets
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
;*********************************************************************
affiche_ecran:

;attend que les précédentes modif d'ecran ait été effectué
@@:
fs
test byte[at_console],90h
jz @f
int 62h
jmp @b 
@@:

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






;***********************************************************
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
mov edx,[couleur_fond]
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
mov edx,[couleur_fond]
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
mov edx,[couleur_fond]
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
push edx
mov [taille_icone],ebx
xor edx,edx
mov eax,ecx
div ebx
dec eax
mov [nb_icones],eax
pop edx
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
mov edx,[couleur_fond]
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
;attend que les précédentes modif d'ecran ait été effectué
@@:
fs
test byte[at_console],90h
jz @f
int 62h
jmp @b 
@@:


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












;********************************
saisie_texte:
mov [Xmenu],ebx
mov [Ymenu],ecx
call ajuste_langue
mov [Tmenu],edx

mov dword[Cmenu],256+10
mov dword[Lmenu],128+10+32+7


;verifie que la fenetre ne déborde pas de l'ecran et corrige si besoin
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


;affiche le fond
mov ebx,[Xmenu]
mov ecx,[Ymenu]
mov esi,[Cmenu]
mov edi,[Lmenu]
add esi,[Xmenu]
add edi,[Ymenu]
call bouton


;affiche le texte
mov al,26
mov ah,0
mov ebx,[Xmenu]
mov ecx,[Ymenu]
add ebx,5
add ecx,5
mov edx,[Tmenu]
mov esi,32
int 63h


;affiche le bouton ok
mov ebx,[Xmenu]
mov ecx,[Ymenu]
add ebx,5
add ecx,128+16+10
mov esi,ebx
mov edi,ecx
add esi,100
add edi,18
call bouton

mov edx,texte_ok
call ajuste_langue
inc ebx
inc ecx
mov al,25
mov ah,0
int 63h





;affiche le bouton annuler
mov ebx,[Xmenu]
mov ecx,[Ymenu]
add ebx,256+5-100  
add ecx,128+16+10
mov esi,ebx
mov edi,ecx
add esi,100
add edi,18
call bouton


mov edx,texte_annuler
call ajuste_langue
inc ebx
inc ecx
mov al,25
mov ah,0
int 63h





;calcule les position max et le curseur 
mov esi,zt_saisie_texte
saisie_texte_mesure:
cmp byte[esi],13
jne  @f
mov byte[esi]," "
@@:

cmp byte[esi],0
je  @f
inc esi
jmp saisie_texte_mesure
@@:
sub esi,zt_saisie_texte
mov [adr_chaine_saisie],esi
mov [max_chaine_saisie],esi






saisie_texte_affichage: ;la partie a mettre a jour lors de la modif texte

mov al,22   
mov ah,24
mov edx,0FFFFFFh ;afficher un carré blanc
mov ebx,[Xmenu]
mov ecx,[Ymenu]
add ebx,5
add ecx,21
mov esi,ebx
mov edi,ecx
add esi,256
add edi,128
int 63h


;affiche le texte saisie
mov al,26
mov ah,0
mov ebx,[Xmenu]
mov ecx,[Ymenu]
add ebx,5
add ecx,21
mov edx,zt_saisie_texte
mov esi,32
int 63h


;affiche le curseur
mov edi,[adr_chaine_saisie]
add edi,zt_saisie_texte
xor ecx,ecx
@@:
cmp edi,zt_saisie_texte
je @f
mov dh,[edi]
dec edi
and dh,11000000b
cmp dh,80h
je @b
inc eax
jmp @b
@@:

xor edx,edx
mov ecx,32
div ecx

mov ebx,edx
mov ecx,eax
shl ebx,3
shl ecx,4

mov al,22   
mov ah,24
mov edx,0808080h
add ebx,[Xmenu]
add ecx,[Ymenu]
add ebx,5
add ecx,21+12
mov esi,ebx
mov edi,ecx
add esi,8
int 63h



mov eax,7  ;demande la mise a jour ecran
int 63h






saisie_texte_touche:
mov al,5
int 63h
cmp al,0  
je saisie_texte_touche
cmp al,1  
je saisie_texte_sortie
cmp al,44  
je saisie_texte_sortie
cmp al,100 
je saisie_texte_sortie
cmp al,30 
je saisie_texte_back
cmp al,79 
je saisie_texte_suppr
cmp al,85
je saisie_texte_av
cmp al,83
je saisie_texte_rc
cmp al,77
je saisie_texte_retdebut
cmp al,80
je saisie_texte_retfin


cmp al,0F0h
je texte_clique
ja saisie_texte_touche
test ecx,0FFFFFFE0h
jz saisie_texte_touche

cmp ecx,80h   ;-de 7 bit
jb insert1_saisie_texte
cmp ecx,800h  ;-de 11 bits
jb insert2_saisie_texte
cmp ecx,10000h  ;-de 16 bits
jb insert3_saisie_texte
cmp ecx,200000h   ;-de 21 bits
jb insert4_saisie_texte
jmp saisie_texte_touche


insert1_saisie_texte:
mov eax,[max_chaine_saisie]
inc eax
cmp eax,256
jae saisie_texte_touche     ;verifie que la chaine n'est pas pleine

push ecx
mov ecx,[max_chaine_saisie] 
sub ecx,[adr_chaine_saisie]
inc ecx
mov edi,[max_chaine_saisie]
add edi,zt_saisie_texte
mov esi,edi
inc edi
std
rep movsb          ;décale les données
pop ecx


mov esi,[adr_chaine_saisie]
and ecx,7Fh      ;transformation du caractre
mov [esi+zt_saisie_texte],cl     ;écrit le caractre

inc dword[max_chaine_saisie]  ;maj du dernier octet utilisé
inc dword[adr_chaine_saisie]  ;maj de la position curseur
jmp saisie_texte_affichage


insert2_saisie_texte:
mov eax,[max_chaine_saisie]
add eax,2
cmp eax,256
jae saisie_texte_touche     ;verifie que la chaine n'est pas pleine

push ecx
mov ecx,[max_chaine_saisie] 
sub ecx,[adr_chaine_saisie]
inc ecx
mov edi,[max_chaine_saisie]
add edi,zt_saisie_texte
mov esi,edi
add edi,2
std
rep movsb          ;décale les données
pop ecx

mov esi,[adr_chaine_saisie]
mov eax,ecx
and al,3Fh
or al,80h
mov [esi+zt_saisie_texte+1],al
shr ecx,6
mov al,cl
and al,01Fh
or al,0C0h
mov [esi+zt_saisie_texte],al


add dword[max_chaine_saisie],2  ;maj du dernier octet utilisé
add dword[adr_chaine_saisie],2  ;maj de la position curseur
jmp saisie_texte_affichage


insert3_saisie_texte:
mov eax,[max_chaine_saisie]
add eax,3
cmp eax,256
jae saisie_texte_touche     ;verifie que la chaine n'est pas pleine

push ecx
mov ecx,[max_chaine_saisie] 
sub ecx,[adr_chaine_saisie]
inc ecx
mov edi,[max_chaine_saisie]
add edi,zt_saisie_texte
mov esi,edi
add edi,3
std
rep movsb          ;décale les données
pop ecx

mov esi,[adr_chaine_saisie]
mov eax,ecx
and al,3Fh
or al,80h
mov [esi+zt_saisie_texte+2],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [esi+zt_saisie_texte+1],al
shr ecx,6
mov al,cl
and al,0Fh
or al,0E0h
mov [esi+zt_saisie_texte],al

add dword[max_chaine_saisie],3  ;maj du dernier octet utilisé
add dword[adr_chaine_saisie],3  ;maj de la position curseur
jmp saisie_texte_affichage


insert4_saisie_texte:
mov eax,[max_chaine_saisie]
add eax,4
cmp eax,256
jae saisie_texte_touche     ;verifie que la chaine n'est pas pleine


push ecx
mov ecx,[max_chaine_saisie] 
sub ecx,[adr_chaine_saisie]
inc ecx
mov edi,[max_chaine_saisie]
add edi,zt_saisie_texte
mov esi,edi
add edi,4
std
rep movsb          ;décale les données
pop ecx

mov esi,[adr_chaine_saisie]
mov eax,ecx
and al,3Fh
or al,80h
mov [esi+zt_saisie_texte+3],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [esi+zt_saisie_texte+2],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [esi+zt_saisie_texte+1],al
shr ecx,6
mov al,cl
and al,07h
or al,0F0h
mov [esi+zt_saisie_texte],al

add dword[max_chaine_saisie],4  ;maj du dernier octet utilisé
add dword[adr_chaine_saisie],4  ;maj de la position curseur
jmp saisie_texte_affichage


saisie_texte_av:
mov eax,[max_chaine_saisie]
cmp [adr_chaine_saisie],eax
je saisie_texte_touche

inc dword[adr_chaine_saisie]

mov edi,[adr_chaine_saisie]
add edi,zt_saisie_texte
mov ah,[edi]
and ah,11000000b
cmp ah,80h
je saisie_texte_av
jmp saisie_texte_affichage


saisie_texte_rc:
cmp dword[adr_chaine_saisie],0
je saisie_texte_touche

dec dword[adr_chaine_saisie]

mov edi,[adr_chaine_saisie]
add edi,zt_saisie_texte
mov ah,[edi]
and ah,11000000b
cmp ah,80h
je saisie_texte_rc
jmp saisie_texte_affichage


saisie_texte_retdebut:
mov dword[adr_chaine_saisie],0
jmp saisie_texte_affichage


saisie_texte_retfin:
mov eax,[max_chaine_saisie]
mov [adr_chaine_saisie],eax

jmp saisie_texte_affichage


saisie_texte_back:
cmp dword[adr_chaine_saisie],0
je saisie_texte_touche

dec dword[adr_chaine_saisie]

mov edi,[adr_chaine_saisie]
add edi,zt_saisie_texte
mov ah,[edi]
and ah,11000000b
cmp ah,80h
je saisie_texte_back


saisie_texte_suppr:
cmp dword[max_chaine_saisie],0
je saisie_texte_touche

mov ecx,[max_chaine_saisie]
sub ecx,[adr_chaine_saisie]
inc ecx
mov edi,[adr_chaine_saisie]
add edi,zt_saisie_texte
mov esi,edi
inc esi
cld
rep movsb          ;décale les données

dec dword[max_chaine_saisie]

mov edi,[adr_chaine_saisie]
add edi,zt_saisie_texte
mov ah,[edi]
and ah,11000000b
cmp ah,80h
je saisie_texte_suppr
jmp saisie_texte_affichage




texte_clique:

;test si le clique est dans la fenetre
mov esi,[Xmenu]
mov edi,[Ymenu]
inc esi
inc edi
cmp bx,si
jb saisie_texte_sortie_nok
cmp cx,di
jb saisie_texte_sortie_nok
add esi,[Cmenu]
add edi,[Lmenu]
sub esi,2
sub edi,2
cmp bx,si
jae saisie_texte_sortie_nok
cmp cx,di
jae saisie_texte_sortie_nok

;test si le clique est dans la zone de texte
mov esi,[Xmenu]
mov edi,[Ymenu]
add esi,5
add edi,21
cmp bx,si
jb @f
cmp cx,di
jb @f
add esi,256
add edi,128
cmp bx,si
jae @f
cmp cx,di
jae @f
jmp saisie_texte_depl_curseur
@@:

;test si le clique est dans la zone ok
mov esi,[Xmenu]
mov edi,[Ymenu]
add esi,5
add edi,128+16+10
cmp bx,si
jb @f
cmp cx,di
jb @f
add esi,100
add edi,18
cmp bx,si
jae @f
cmp cx,di
jae @f
jmp saisie_texte_sortie_ok
@@:



;test si le clique est dans la zone annuler
mov esi,[Xmenu]
mov edi,[Ymenu]
add esi,256+5-100  
add edi,128+16+10
cmp bx,si
jb @f
cmp cx,di
jb @f
add esi,100
add edi,18
cmp bx,si
jae @f
cmp cx,di
jae @f
jmp saisie_texte_sortie_nok
@@:

jmp saisie_texte_affichage


saisie_texte_depl_curseur:
;on déplace le curseur
sub ebx,[Xmenu]
sub ecx,[Ymenu]
sub ebx,5
sub ecx,21
shr ebx,3
shr ecx,4
shl ecx,5
add ebx,ecx
mov dword[adr_chaine_saisie],0
cmp ebx,0
je saisie_texte_affichage


@@:
mov eax,[max_chaine_saisie]
cmp [adr_chaine_saisie],eax
je saisie_texte_affichage

inc dword[adr_chaine_saisie]

mov edi,[adr_chaine_saisie]
add edi,zt_saisie_texte
mov ah,[edi]
and ah,11000000b
cmp ah,80h
je @b
dec ebx
jnz @b
jmp saisie_texte_affichage


saisie_texte_sortie_ok:
mov eax,44
ret

saisie_texte_sortie_nok:
mov eax,1
ret

saisie_texte_sortie:
ret





;*********************************************
saisie_icone:
push esi
mov al,[esi+5]
mov [zt_saisie_texte],al

mov [Xmenu],ebx
mov [Ymenu],ecx

mov eax,[taille_icone]
mov [Cmenu],eax
mov [Lmenu],eax
add dword[Cmenu],40+32
add dword[Lmenu],20+36



;verifie que la fenetre ne déborde pas de l'ecran et corrige si besoin
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
call affiche_ecran


affichage_saisie_icone:
;affiche le fond
mov ebx,[Xmenu]
mov ecx,[Ymenu]
mov esi,[Cmenu]
mov edi,[Lmenu]
add esi,[Xmenu]
add edi,[Ymenu]
call bouton




;affiche l'icone
xor eax,eax
mov al,[zt_saisie_texte]
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

mov ebx,[Xmenu]
mov ecx,[Ymenu]
add ebx,36
add ecx,5
mov edx,[ad_icone]
mov al,27
int 63h



;affiche les touche de défilement
mov ebp,[taille_icone]
sub ebp,32
shr ebp,1

mov ebx,[Xmenu]
mov ecx,[Ymenu]
add ebx,15
add ecx,5
mov edx,fleche_gauche
add ecx,ebp
mov al,27
int 63h

mov ebx,[Xmenu]
mov ecx,[Ymenu]
add ebx,41
add ecx,5
add ebx,[taille_icone]
mov edx,fleche_droite
add ecx,ebp
mov al,27
int 63h



;affiche le bouton ok
mov ebx,[Cmenu]
sub ebx,100
shr ebx,1
mov ecx,10
add ebx,[Xmenu]
add ecx,[Ymenu]
add ecx,[taille_icone]
mov esi,ebx
mov edi,ecx
add esi,100
add edi,18
call bouton

mov edx,texte_ok
call ajuste_langue
inc ebx
inc ecx
mov al,25
mov ah,0
int 63h



;affiche le bouton annuler
mov ebx,[Cmenu]
sub ebx,100
shr ebx,1
mov ecx,15+18
add ebx,[Xmenu]
add ecx,[Ymenu]
add ecx,[taille_icone]
mov esi,ebx
mov edi,ecx
add esi,100
add edi,18
call bouton

mov edx,texte_annuler
call ajuste_langue
inc ebx
inc ecx
mov al,25
mov ah,0
int 63h


mov al,7
int 63h



touche_saisie_icone:
mov al,5
int 63h
cmp al,1  
je fin_nok_saisie_icone
cmp al,44  ;entree
je fin_ok_saisie_icone
cmp al,100  ;entree pavnum
je fin_ok_saisie_icone

cmp al,83
je saisie_icone_precedente
cmp al,85
je saisie_icone_suivante
cmp al,0F0h
je clique_saisie_icone
jmp touche_saisie_icone


saisie_icone_precedente:
mov cl,[nb_icones]
cmp byte[zt_saisie_texte],0
je @f
dec byte[zt_saisie_texte]
jmp affichage_saisie_icone
@@:
mov [zt_saisie_texte],cl
jmp affichage_saisie_icone
 

saisie_icone_suivante:
mov cl,[nb_icones]
cmp byte[zt_saisie_texte],cl
je @f
inc byte[zt_saisie_texte]
jmp affichage_saisie_icone
@@:
mov byte[zt_saisie_texte],0
jmp affichage_saisie_icone


clique_saisie_icone:
;test si le clique est dans la fenetre
mov esi,[Xmenu]
mov edi,[Ymenu]
inc esi
inc edi
cmp bx,si
jb fin_nok_saisie_icone
cmp cx,di
jb fin_nok_saisie_icone
add esi,[Cmenu]
add edi,[Lmenu]
sub esi,2
sub edi,2
cmp bx,si
jae fin_nok_saisie_icone
cmp cx,di
jae fin_nok_saisie_icone



mov ebp,[taille_icone]
sub ebp,32
shr ebp,1


;test si le clique est dans la zone def+
mov esi,[Xmenu]
mov edi,[Ymenu]
add esi,41
add edi,5
add esi,[taille_icone]
add edi,ebp
cmp bx,si
jb @f
cmp cx,di
jb @f
add esi,16
add edi,32
cmp bx,si
jae @f
cmp cx,di
jae @f
jmp saisie_icone_suivante
@@:



;test si le clique est dans la zone def-
mov esi,[Xmenu]
mov edi,[Ymenu]
add esi,15
add edi,5
add edi,ebp
cmp bx,si
jb @f
cmp cx,di
jb @f
add esi,16
add edi,32
cmp bx,si
jae @f
cmp cx,di
jae @f
jmp saisie_icone_precedente
@@:




;test si le clique est dans la zone ok
mov esi,[Cmenu]
sub esi,100
shr esi,1
mov edi,10
add esi,[Xmenu]
add edi,[Ymenu]
add edi,[taille_icone]
cmp bx,si
jb @f
cmp cx,di
jb @f
add esi,100
add edi,18
cmp bx,si
jae @f
cmp cx,di
jae @f
jmp fin_ok_saisie_icone
@@:



;test si le clique est dans la zone annuler
mov esi,[Cmenu]
sub esi,100
shr esi,1
mov edi,15+18
add esi,[Xmenu]
add edi,[Ymenu]
add edi,[taille_icone]
cmp bx,si
jb @f
cmp cx,di
jb @f
add esi,100
add edi,18
cmp bx,si
jae @f
cmp cx,di
jae @f
jmp fin_nok_saisie_icone
@@:

jmp touche_saisie_icone




fin_nok_saisie_icone:
pop esi
mov al,1
mov ah,0
ret

fin_ok_saisie_icone:
pop esi
mov al,44
mov ah,[zt_saisie_texte]
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
mov ebx,1
int 64h
cmp eax,0
jne sauvegarde_objets_erreur


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
cmp eax,0
jne sauvegarde_objets_erreur

;ecrit les objets
mov al,5
mov ebx,[handle_fichier]
mov ecx,[to_objet]
xor edx,edx
mov esi,[ad_objet]
int 64h
cmp eax,0
jne sauvegarde_objets_erreur

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
mov ah,[couleur_texte]
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
db "add new shortcut",13
db "change wallpaper",13
db "change icon set",13
db "quit",0

db "ajouter un raccourcis",13
db "changer fond d'écran",13
db "changer jeu d'icones",13
db "quitter",0



texte_menu_fichier:
db "change name",13
db "change icon",13
db "change command",13
db "delete",0

db "changer nom",13
db "changer icône",13
db "changer commande",13
db "supprimer",0


texte_fond:
db "name of wallpaper:",0
db "nom du fond d'ecran:",0


texte_icone:
db "name of icone file:",0
db "nom du fichier d'icones:",0


texte_nom:
db "name of shortcut:",0
db "nom du raccourcis:",0


texte_cmd:
db "command of shortcut:",0
db "commande du raccourcis:",0


texte_ok:
db "     ok",0
db "     ok",0

texte_annuler:
db "    abord",0
db "   annuler",0





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

nb_icones:
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

;variables saisie texte
max_chaine_saisie:
dd 0
adr_chaine_saisie:
dd 0



;informations par défaut
fichier_fond_def:
db "fond.png",0
fichier_icones_def:
db "icones.png",0
fichier_objets_def:
db "ICS.DAT",0


couleur_fond:
dd 0FF007070h ;bleu/vert moche de win95
couleur_texte:
dd 0Fh      ;code 16 couleurs blanc                                     


fleche_gauche:
db 8,0
dw 16,32
dd 16,0
db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,1
db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,  1,1
db 255,255,255,255,255,255,255,255,255,255,255,255,255,  1,255,1
db 255,255,255,255,255,255,255,255,255,255,255,255,  1,255,255,1
db 255,255,255,255,255,255,255,255,255,255,255,  1,255,255,255,1
db 255,255,255,255,255,255,255,255,255,255,  1,255,255,255,255,1
db 255,255,255,255,255,255,255,255,255,  1,255,255,255,255,255,1
db 255,255,255,255,255,255,255,255,  1,255,255,255,255,255,255,1
db 255,255,255,255,255,255,255,  1,255,255,255,255,255,255,255,1
db 255,255,255,255,255,255,  1,255,255,255,255,255,255,255,  1,255
db 255,255,255,255,255,  1,255,255,255,255,255,255,255,  1,255,255
db 255,255,255,255,  1,255,255,255,255,255,255,255,  1,255,255,255
db 255,255,255,  1,255,255,255,255,255,255,255,  1,255,255,255,255
db 255,255,  1,255,255,255,255,255,255,255,  1,255,255,255,255,255
db 255,  1,255,255,255,255,255,255,255,  1,255,255,255,255,255,255
db   1,255,255,255,255,255,255,255,  1,255,255,255,255,255,255,255
db   1,255,255,255,255,255,255,255,  1,255,255,255,255,255,255,255
db 255,  1,255,255,255,255,255,255,255,  1,255,255,255,255,255,255
db 255,255,  1,255,255,255,255,255,255,255,  1,255,255,255,255,255
db 255,255,255,  1,255,255,255,255,255,255,255,  1,255,255,255,255
db 255,255,255,255,  1,255,255,255,255,255,255,255,  1,255,255,255
db 255,255,255,255,255,  1,255,255,255,255,255,255,255,  1,255,255
db 255,255,255,255,255,255,  1,255,255,255,255,255,255,255,  1,255
db 255,255,255,255,255,255,255,  1,255,255,255,255,255,255,255,1
db 255,255,255,255,255,255,255,255,  1,255,255,255,255,255,255,1
db 255,255,255,255,255,255,255,255,255,  1,255,255,255,255,255,1
db 255,255,255,255,255,255,255,255,255,255,  1,255,255,255,255,1
db 255,255,255,255,255,255,255,255,255,255,255,  1,255,255,255,1
db 255,255,255,255,255,255,255,255,255,255,255,255,  1,255,255,1
db 255,255,255,255,255,255,255,255,255,255,255,255,255,  1,255,1
db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,  1,1
db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,1

fleche_droite:
db 8,0
dw 16,32
dd 16,0
db   1,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
db   1,  1,255,255,255,255,255,255,255,255,255,255,255,255,255,255
db   1,255,  1,255,255,255,255,255,255,255,255,255,255,255,255,255
db   1,255,255,  1,255,255,255,255,255,255,255,255,255,255,255,255
db   1,255,255,255,  1,255,255,255,255,255,255,255,255,255,255,255
db   1,255,255,255,255,  1,255,255,255,255,255,255,255,255,255,255
db   1,255,255,255,255,255,  1,255,255,255,255,255,255,255,255,255
db   1,255,255,255,255,255,255,  1,255,255,255,255,255,255,255,255
db   1,255,255,255,255,255,255,255,  1,255,255,255,255,255,255,255
db 255,  1,255,255,255,255,255,255,255,  1,255,255,255,255,255,255
db 255,255,  1,255,255,255,255,255,255,255,  1,255,255,255,255,255
db 255,255,255,  1,255,255,255,255,255,255,255,  1,255,255,255,255
db 255,255,255,255,  1,255,255,255,255,255,255,255,  1,255,255,255
db 255,255,255,255,255,  1,255,255,255,255,255,255,255,  1,255,255
db 255,255,255,255,255,255,  1,255,255,255,255,255,255,255,  1,255
db 255,255,255,255,255,255,255,  1,255,255,255,255,255,255,255,  1
db 255,255,255,255,255,255,255,  1,255,255,255,255,255,255,255,  1
db 255,255,255,255,255,255,  1,255,255,255,255,255,255,255,  1,255
db 255,255,255,255,255,  1,255,255,255,255,255,255,255,  1,255,255
db 255,255,255,255,  1,255,255,255,255,255,255,255,  1,255,255,255
db 255,255,255,  1,255,255,255,255,255,255,255,  1,255,255,255,255
db 255,255,  1,255,255,255,255,255,255,255,  1,255,255,255,255,255
db 255,  1,255,255,255,255,255,255,255,  1,255,255,255,255,255,255
db   1,255,255,255,255,255,255,255,  1,255,255,255,255,255,255,255
db   1,255,255,255,255,255,255,  1,255,255,255,255,255,255,255,255
db   1,255,255,255,255,255,  1,255,255,255,255,255,255,255,255,255
db   1,255,255,255,255,  1,255,255,255,255,255,255,255,255,255,255
db   1,255,255,255,  1,255,255,255,255,255,255,255,255,255,255,255
db   1,255,255,  1,255,255,255,255,255,255,255,255,255,255,255,255
db   1,255,  1,255,255,255,255,255,255,255,255,255,255,255,255,255
db   1,  1,255,255,255,255,255,255,255,255,255,255,255,255,255,255
db   1,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255



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
db "man install",0  ;commande de l'icone
@@:

dd @f-$     ;taille de l'objet
db 0        ;attributs b0=visible b1=selectionné
db 4        ;numéros de l'icone
dw 0        ;vide
dd 160,240    ;coordonné coin supérieur gauche
db "Aide",0  ;texte de l'icone
db "help",0  ;commande de l'icone
@@:

dd 0
fin_objet_base: 


rb $-tempo+2048


zt_saisie_texte:
rb 256



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