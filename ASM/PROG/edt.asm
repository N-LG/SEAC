edt:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "editeur de fichier texte"
scode:
org 0

mov dx,sel_dat3
mov ah,5   ;option=mode texte et souris
mov al,0   ;création console     
int 63h

mov dx,sel_dat1    ;variable du programme
mov ds,dx
mov dx,sel_dat2    ;zone tampon de taille variable pour les données du fichier
mov es,dx
mov dx,sel_dat3    ;écran video
mov fs,dx

mov edx,bitpp
mov al,2   ;information video     
int 63h

mov eax,[resyt]
sub eax,1
mov [resyt_correc],eax

mov edx,nom_fichier
mov cl,0   ;256 octet du coup
mov ax,4   ;0eme argument
int 61h


cmp byte[nom_fichier],0
je affiche_menu
cmp byte[nom_fichier],"#"
je arg_nom_fichier_ok

call precharge_nomdossier

mov ecx,nom_temporaire+512
sub ecx,edx
mov ax,4   ;0eme argument
int 61h

push es
mov ax,ds
mov es,ax
mov esi,nom_temporaire
mov edi,nom_fichier
mov ecx,64
cld
rep movsd
pop es

arg_nom_fichier_ok:
call charge_fichier
cmp byte[nom_fichier],0
jne affichage







;**********************************************************
affiche_menu:
call raz_ecr
cmp byte[nom_fichier],0
jne affiche_menu_complet

mov edx,msg_menur
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,msg_menua
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h

mov bl,0
mov al,13
mov bh,7 ;couleur
mov cl,0
mov ch,3
int 63h

cmp bl,0
je nouveau_fichier
dec bl
jz ouvrir_fichier
jmp fin


;***************
affiche_menu_complet:
mov edx,msg_menuc
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,msg_menua
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h

rey_menu_complet:
mov bl,0
mov al,13
mov bh,7 ;couleur
mov cl,0
mov ch,11
int 63h
cmp bh,1
je rey_menu_complet 

cmp bl,0
je affichage
dec bl
jz ferme_fichier
dec bl
jz nouveau_fichier
dec bl
jz ouvrir_fichier
dec bl
jz sauvegarder_fichier
dec bl
jz touche_enregistrer_sous
dec bl
jz aller_ligne
dec bl
jz rechercher_doc
dec bl
jz remplacer_chaine
dec bl
jz config
jmp fin





;***********************************************************
ferme_fichier:
mov edx,msg_modif_fer
call ajuste_langue
call sauvegarde_conditionnelle

mov dword[taille_fichier],0
mov byte[nom_fichier],0
mov byte[data_modif],0 
jmp affiche_menu





;************************************************************
nouveau_fichier:
mov edx,msg_modif_ouv
call ajuste_langue
call sauvegarde_conditionnelle

call raz_ecr

mov dword[taille_fichier],0
mov ecx,2048
mov dx,sel_dat2
mov al,8
mov [taille_zone],ecx
int 61h

call precharge_nomdossier

;demande le nom du fichier que l'on veux créer 
mov edx,msg_nvf1
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h 

rey_demande_nouveau:
mov ah,07h
mov edx,nom_temporaire
mov ecx,512
mov al,6
int 63h
cmp al,1
je ferme_fichier
cmp al,44
jne rey_demande_nouveau

rey_cree_fichier:
;cree le fichier
mov al,2 
mov bx,0
mov edx,nom_temporaire
int 64h
cmp eax,0
jne echec_nouveau_fichier

mov al,1
int 64h

push es
mov ax,ds
mov es,ax
mov esi,nom_temporaire
mov edi,nom_fichier
mov ecx,64
cld
rep movsd
pop es
jmp affichage



echec_nouveau_fichier:
push eax
call raz_ecr
pop eax
cmp eax,cer_nfr
je nouveau_fichier_dejaexistant

mov edx,msg_nvf_er1
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h 

rey_err_nf1:
mov al,13
mov cl,1
mov ch,3
mov bl,0
mov bh,7
int 63h
cmp bh,1
je rey_err_nf1 


cmp bl,0
je rey_cree_fichier
cmp bl,1
je nouveau_fichier
jmp ferme_fichier



nouveau_fichier_dejaexistant:
mov edx,msg_nvf_er2
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h 

rey_err_nf2:
mov al,13
mov cl,1
mov ch,3
mov bl,0
mov bh,7
int 63h
cmp bh,1
je rey_err_nf2 


cmp bl,0
je nouveau_fichier
cmp bl,1
je affichage
push es
mov ax,ds
mov es,ax
mov esi,nom_temporaire
mov edi,nom_fichier
mov ecx,64
cld
rep movsd
pop es
call charge_fichier
cmp byte[nom_fichier],0
je affiche_menu
jmp affichage




;****************************************************************************
ouvrir_fichier:
mov edx,msg_modif_ouv
call ajuste_langue
call sauvegarde_conditionnelle

call raz_ecr

call precharge_nomdossier

;demande le nom du fichier que l'on veux ouvrir
mov edx,msg3
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h 

mov ah,07h
mov edx,nom_temporaire
mov ecx,512
mov al,6
int 63h

push es
mov ax,ds
mov es,ax
mov esi,nom_temporaire
mov edi,nom_fichier
mov ecx,64
cld
rep movsd
pop es

call charge_fichier

cmp byte[nom_fichier],0
je affiche_menu










;*************************************************************************************************************************************
affichage:
;met a jour le descriptif de tache
mov eax,7
mov edx,descriptif2
int 61h

mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne

mov ebx,[offset_colonne]
add ebx,[curseur_colonne]

boucle_cherche_adresse:     ;cherche l'adresse du caractère qui correspond au curseur          
cmp ebx,0
je fin_cherche_adresse
dec bx
inc esi

test_cherche_adresse:
es
mov al,[esi]
cmp al,10
je fin_cherche_adresse
cmp al,13
je fin_cherche_adresse
cmp al,0
je fin_cherche_adresse
and al,0C0h
cmp al,080h
jne boucle_cherche_adresse
inc esi
jmp test_cherche_adresse

fin_cherche_adresse:
cmp esi,[taille_fichier]
jbe fin2_cherche_adresse
mov esi,[taille_fichier]
fin2_cherche_adresse:
mov [seleccurseur],esi


;ajuste selecorigine si besoin 
test byte[options],010h
jnz def_selecorigine
test byte[options],00Ch
jnz findef_selecorigine
def_selecorigine:
mov eax,[seleccurseur]
mov [selecorigine],eax
findef_selecorigine:
and byte[options],0E7h  ;remet a zéro le bit 3 et 4


;recalcul les valeur pour selecmax et selecmin 
mov eax,[seleccurseur]
mov edx,[selecorigine]
cmp edx,eax
je egale_precalcule_selecminmax
ja inverse_precalcule_selecminmax

mov [selecmax],eax
mov [selecmin],edx
jmp fin_precalcule_selecminmax

inverse_precalcule_selecminmax:
mov [selecmin],eax
mov [selecmax],edx
jmp fin_precalcule_selecminmax

egale_precalcule_selecminmax:
mov dword[selecmin],0FFFFFFFFh
mov dword[selecmax],0FFFFFFFFh
fin_precalcule_selecminmax:



call raz_ecr
mov edx,nom_fichier    ;affiche le nom du fichier dans l'en tête
cmp byte[nom_fichier],0
jne nom_fichierpvide
mov edx,msg1 
call ajuste_langue  
nom_fichierpvide:
mov al,10
mov ah,7 ;couleur
mov ebx,0
mov ecx,0
int 63h

mov edx,msg2   ;affiche l'en tête
call ajuste_langue
mov al,10
mov ah,7 ;couleur
mov ebx,[resxt]
mov ecx,0
sub ebx,7
int 63h

fs
mov ebx,[ad_texte]  ;met la couleur de l'en tête
mov ecx,[resxt]
add ebx,3
boucle_ent:
fs
mov byte[ebx],070h 
add ebx,4
dec ecx
jnz boucle_ent

mov ecx,[resxt]
mov [resxt_correc],ecx
mov dword[start_ligne],0

test word[options],1 ;affichage du numéros de ligne
jz fin_calc_xcorrect

pushad
mov eax,[offset_ligne]  ;calcul le décalage lors de l'affichage du numéros de ligne
add eax,[resyt]
xor ebx,ebx
mov ecx,10

boucle_compte_num_ligne:
inc ebx
xor edx,edx
div ecx
cmp eax,0
jne boucle_compte_num_ligne

sub [resxt_correc],ebx
shl ebx,2
mov [start_ligne],ebx

mov edi,[offset_ligne]
mov esi,1

boucle_affnumligne:
mov al,102
mov ecx,edi
inc ecx
mov edx,chaineligne
int 61h

mov al,10
mov ah,0Ah
mov ebx,0
mov ecx,esi
mov edx,chaineligne
int 63h 

inc esi
inc edi
cmp esi,[resyt]
jne boucle_affnumligne

popad
fin_calc_xcorrect:


mov dword[rechmin],0FFFFFFFFh
mov dword[rechmax],0FFFFFFFFh

mov ecx,[resxt]
shl ecx,2    ;ecx contient le nombre d'octet par ligne
mov esi,[adresse_ligne0]
fs
mov edi,[ad_texte]
add edi,ecx


boucle_ligne:
mov ebx,[start_ligne]

;compte le nombre de caractère pour arriver au premier caractère a afficher de la ligne
mov edx,[offset_colonne]
cmp edx,0
je ignore_determine_debut
determine_debut:
call charge_carac
cmp eax,13        ;caractère = saut de ligne?
je affiche_saut
cmp eax,10        ;caractère = saut de ligne?
je affiche_saut
cmp eax,0         ;caractère = fin de document
je affiche_fin
dec edx
jnz determine_debut
ignore_determine_debut:



;affiche la partie texte
boucle_carac:
call charge_carac
cmp eax,13        ;caractère = saut de ligne?
je affiche_saut
cmp eax,10        ;caractère = saut de ligne?
je affiche_saut
cmp eax,0        ;caractère = fin de document
je affiche_fin


cmp ebx,ecx
je cherche_ligne

and eax,00FFFFFFh
fs
mov [ebx+edi],eax

;choisis la couleur
add ebx,3
mov al,007h    ;couleur de base

cmp esi,[rechmin]
jb pas_coul_rech
cmp esi,[rechmax]
ja pas_coul_rech
mov al,009h        ;texte recherché
pas_coul_rech:

cmp esi,[selecmin]
jbe pas_coul_selec
cmp esi,[selecmax]
ja pas_coul_selec
mov al,070h        ;texte selectionné
pas_coul_selec:

fs
mov [ebx+edi],al
inc ebx
jmp boucle_carac


cherche_ligne:
sub ebx,4
fs
mov dword[ebx+edi],0A00003Eh    ;caractère chevron en vert
boucle_cherche_ligne:
call charge_carac
cmp eax,0
je affiche_fin
cmp eax,13        ;caractère = saut de ligne?
jne boucle_cherche_ligne

add edi,ecx
xor ebx,ebx
mov edx,edi
fs
sub edx,[ad_texte]
fs
cmp edx,[to_texte]
jb boucle_ligne
jmp touche_boucle





affiche_saut:
cmp ebx,ecx
je fin_affiche_saut
fs
mov dword[ebx+edi],07000020h   ;caractère espace en gris clair
add ebx,4
jmp affiche_saut

fin_affiche_saut:

add edi,ecx
xor ebx,ebx
mov edx,edi
fs
sub edx,[ad_texte]
fs
cmp edx,[to_texte]
jb boucle_ligne
jmp touche_boucle
 

affiche_fin:
add ebx,edi
fs
mov edi,[ad_texte]
sub ebx,edi
boucle_affiche_fin:
fs
mov dword[ebx+edi],07000020h   ;caractère espace en gris clair
add ebx,4
fs
cmp ebx,[to_texte]
jb boucle_affiche_fin






;******************************************************************************************
touche_boucle:
mov ebx,[curseur_colonne]
mov ecx,[curseur_ligne]
inc ecx  ;une ligne est reservé
mov eax,[resxt]          ;ajoute l'éventuel décalage du nombre de ligne 
sub eax,[resxt_correc]
add ebx,eax
mov al,12
int 63h     ;place le curseur

boucle_touche:
fs
test byte[at_console],20h
jnz redim_ecran
mov al,5
int 63h
mov[touche_importante],ah   ;0=majG 1=majD 2=CtrlG 3=CtrlD 4=Alt 5=AltGr
cmp al,0F0h
je clique_souris
cmp al,0F1h
je declique_souris
cmp al,0F2h
jae boucle_touche

test ah,0Ch
jnz touche_ctrl

cmp al,1
je fin
cmp al,2
je affiche_menu

cmp al,44
je touche_entree
cmp al,100
je touche_entree
cmp al,30
je touche_backsp
cmp al,79
je touche_suppr

cmp al,77
je touche_debut
cmp al,80
je touche_fin
cmp al,78
je touche_pageup
cmp al,81
je touche_pagedown

cmp al,82
je moin1l
cmp al,83
je moin1c
cmp al,84
je plus1l
cmp al,85
je plus1c

cmp ecx,0
jne insertion_carac
test byte[options],04h
jz  boucle_touche 
positionne_souris:
xor ebx,ebx
xor ecx,ecx
fs
mov bx,[posx_souris]
fs
mov cx,[posy_souris]
shr ebx,3
shr ecx,4
cmp ecx,0
je boucle_touche
dec ecx
mov eax,[resxt]
sub eax,[resxt_correc]
cmp ebx,eax
jb boucle_touche
sub ebx,eax
mov [curseur_colonne],ebx
mov [curseur_ligne],ecx
jmp affichage


touche_ctrl:
test ecx,0FFFFFF00h
jnz boucle_touche
cmp cl,"A"
jb @f
cmp cl,"Z"
ja @f
add cl,20h
@@:

cmp cl,"s"
je touche_sauvegarder
cmp cl,"o"
je ouvrir_fichier
cmp cl,"p"
;je imprimer
cmp cl,"q"
je fin
cmp cl,"z"
;je annuler

cmp cl,"f"
je rechercher_doc
cmp cl,"b"
je aller_rech_prec
cmp cl,"n"
je aller_rech_suiv
cmp cl,"r"
je remplacer_chaine

cmp cl,"g"
je aller_mot_prec
cmp cl,"h"
je aller_mot_suiv
cmp cl,"d"
je aller_mot_deb
cmp cl,"e"
je aller_mot_fin

cmp cl,"a"
je select_tout
cmp cl,"l"
je select_ligne
cmp cl,"w"
je select_mot
cmp cl,"j"
je select_debligne
cmp cl,"k"
je select_finligne

cmp cl,"x"
je couper
cmp cl,"c"
je copier
cmp cl,"v"
je coller

jmp boucle_touche


;************************************
redim_ecran:
mov dx,sel_dat3
mov ah,5   ;option=mode texte et souris
mov al,0   ;création console     
int 63h

mov dx,sel_dat1    ;variable du programme
mov ds,dx
mov dx,sel_dat2    ;zone tampon de taille variable pour les données du fichier
mov es,dx
mov dx,sel_dat3    ;écran video
mov fs,dx

mov edx,bitpp
mov al,2   ;information video     
int 63h

mov eax,[resyt]
sub eax,1
mov [resyt_correc],eax
jmp affichage






;**************************************************************************
;insertion de nouveaux caractère dans le texte
insertion_carac:
push ecx
call supprime_zone
call ajoute_manques
pop edx

cmp edx,80h   ;-de 7 bit
jb insert1carac
cmp edx,800h  ;-de 11 bits
jb insert2carac
cmp edx,10000h  ;-de 16 bits
jb insert3carac
cmp edx,200000h   ;-de 21 bits
jb insert4carac
jmp affichage

insert1carac:
push esi
push edi
push ds
mov ecx,[taille_fichier]
sub ecx,esi
cmp ecx,0
je ignore_insert1carac
mov edi,[taille_fichier]
mov esi,edi
dec esi
mov ax,sel_dat2
mov ds,ax
std  ;-
rep movsb
ignore_insert1carac:
pop ds
pop edi
pop esi
es
mov [esi],dl
add dword[taille_fichier],1
mov byte[data_modif],1  
inc esi
mov [seleccurseur],esi

call verif_zt
call replace_cur
jmp affichage


insert2carac:
push esi
push edi
push ds
mov ecx,[taille_fichier]
sub ecx,esi
cmp ecx,0
je ignore_insert2carac
mov edi,[taille_fichier]
mov esi,edi
dec esi
inc edi
mov ax,sel_dat2
mov ds,ax
std  ;-
rep movsb
ignore_insert2carac:
pop ds
pop edi
pop esi

mov ecx,edx
and dl,3Fh
or dl,80h
es
mov [esi+1],dl
shr ecx,6
mov dl,cl
and dl,01Fh
or dl,0C0h
es
mov [esi],dl
add dword[taille_fichier],2
mov byte[data_modif],1     
add esi,2
mov [seleccurseur],esi

call verif_zt
call replace_cur
jmp affichage


insert3carac:
push esi
push edi
push ds
mov ecx,[taille_fichier]
sub ecx,esi
cmp ecx,0
je ignore_insert3carac
mov edi,[taille_fichier]
mov esi,edi
dec esi
add edi,2
mov ax,sel_dat2
mov ds,ax
std  ;-
rep movsb
ignore_insert3carac:
pop ds
pop edi
pop esi

mov ecx,edx
and dl,3Fh
or dl,80h
es
mov [esi+2],dl
shr ecx,6
mov dl,cl
and dl,3Fh
or dl,80h
es
mov [esi+1],dl
shr ecx,6
mov dl,cl
and dl,0Fh
or dl,0E0h
es
mov [esi],dl
add dword[taille_fichier],3
mov byte[data_modif],1   
add esi,3
mov [seleccurseur],esi

call verif_zt
call replace_cur
jmp affichage



insert4carac:
push esi
push edi
push ds
mov ecx,[taille_fichier]
sub ecx,esi
cmp ecx,0
je ignore_insert4carac
mov edi,[taille_fichier]
mov esi,edi
dec esi
add edi,3
mov ax,sel_dat2
mov ds,ax
std  ;-
rep movsb
ignore_insert4carac:
pop ds
pop edi
pop esi

mov ecx,edx
and dl,3Fh
or dl,80h
es
mov [esi+3],dl
shr ecx,6
mov dl,cl
and dl,3Fh
or dl,80h
es
mov [esi+2],dl
shr ecx,6
mov dl,cl
and dl,3Fh
or dl,80h
es
mov [esi+1],dl
shr ecx,6
mov dl,cl
and dl,07h
or dl,0F0h
es
mov [esi],dl
add dword[taille_fichier],4    
mov byte[data_modif],1 
add esi,4
mov [seleccurseur],esi

call verif_zt
call replace_cur
jmp affichage














;****************************************************************************
charge_carac:  ;lit le caractère utf8 en es:esi et le copie dans eax, incrémente esi pour passer au caractère suivant
push cx
cmp esi,[taille_fichier]
jae caracz_lireutf8

debut_lireutf8:
es
mov al,[esi]
cmp al,[motrecherche]
jne pasrecherche
push eax
push edx
push esi
push edi
mov edi,motrecherche
mov edx,esi

boucle_recherche_carac:
mov al,[edi]
cmp al,0
je recherche_carac_trouve
es
cmp al,[esi]
jne recherche_carac_ntrouve
inc esi
inc edi
jmp boucle_recherche_carac

recherche_carac_trouve:
mov [rechmin],edx
mov [rechmax],esi
recherche_carac_ntrouve:
pop edi
pop esi
pop edx
pop eax
pasrecherche:
cmp al,0
je caracz_lireutf8
cmp al,10
je fin1ligne_lireutf8
cmp al,13
je fin2ligne_lireutf8
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

caracz_lireutf8:
xor eax,eax
mov esi,[taille_fichier]
jmp fin_lireutf8

fin1ligne_lireutf8:
mov eax,13
inc esi
cmp esi,[taille_zone]
jae fin_lireutf8
es
cmp byte[esi],13
jne fin_lireutf8
inc esi
jmp fin_lireutf8

fin2ligne_lireutf8:
mov eax,13
inc esi
cmp esi,[taille_zone]
jae fin_lireutf8
es
cmp byte[esi],10
jne fin_lireutf8
inc esi
jmp fin_lireutf8

lutf2ch:
es
mov eax,[esi]
and eax,0C0E0h
cmp eax,080C0h
jne lutf0ch
xor eax,eax
es
mov al,[esi]
and al,1Fh
shl eax,6
es
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
pop cx
ret


;***************************************************
touche_entree:
call supprime_zone

mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne

mov ebx,[offset_colonne]
add ebx,[curseur_colonne]

boucle_entree:  ;recherche la position du curseur dans la ligne 
cmp ebx,0
je insert_entree
mov edi,esi
call charge_carac
cmp eax,13
je insert_entree
cmp eax,0
je insert_entree
dec ebx
jmp boucle_entree

insert_entree:
push ecx
push esi
push edi
push ds
mov ecx,[taille_fichier]
sub ecx,esi
cmp ecx,0
je ignore_insertentre
mov edi,[taille_fichier]
mov esi,edi
dec esi
inc edi
mov ax,sel_dat2
mov ds,ax
std  ;-
rep movsb
ignore_insertentre:
pop ds
pop edi
pop esi
pop ecx
es
mov word[esi],0A0Dh         
add dword[taille_fichier],2
call verif_zt
mov byte[data_modif],1   


mov dword[curseur_colonne],0 
mov dword[offset_colonne],0
jmp plus1l







;***************************************************
touche_backsp:
mov ecx,[selecmax] 
cmp ecx,[selecmin]
jne efface_zone

mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne

mov ebx,[offset_colonne]
add ebx,[curseur_colonne]

boucle_backsp:  ;recherche la position du curseur dans la ligne 
cmp ebx,0
je ok_touche_backsp
mov edi,esi
call charge_carac
cmp eax,13
je moin1c
cmp eax,0
je moin1c
dec ebx
jmp boucle_backsp

ok_touche_backsp:
cmp esi,0
je touche_boucle
call mvmt_ar


;***************************************************
touche_suppr:
mov ecx,[selecmax] 
cmp ecx,[selecmin]
jne efface_zone

mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne

mov ebx,[offset_colonne]
add ebx,[curseur_colonne]

boucle_suppr:  ;recherche la position du curseur dans la ligne 
cmp ebx,0
je deplace_suppr
call charge_carac
cmp eax,13
je touche_boucle
cmp eax,0
je touche_boucle
dec ebx
jmp boucle_suppr

deplace_suppr:
es
mov ah,[esi]
cmp ah,0
je touche_boucle
recommence_deplace_suppr:
push esi
push edi
push ds
mov ecx,[taille_fichier]
mov di,sel_dat2
mov ds,di
sub ecx,esi
mov edi,esi
inc esi
cld  ;+
rep movsb
pop ds
pop edi
pop esi
dec dword[taille_fichier]
mov byte[data_modif],1  

es
mov al,[esi]
cmp ax,0D0Ah
je recommence_deplace_suppr
cmp ax,0A0Dh
je recommence_deplace_suppr
and al,0C0h
cmp al,080h
je recommence_deplace_suppr
jmp affichage


;*************************************************
efface_zone:
call supprime_zone
jmp affichage

;***************************************************
touche_sauvegarder:    ;enregistrement simple
call sauvegarder_fichier
jmp affichage


;***************************************************
touche_enregistrer_sous:    ;enregistrer sous
call raz_ecr


;demande le nom du fichier sous lequel enregistrer le fichier
mov edx,msg7
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h 

rey_demande_enregsous:
mov ah,07h
mov edx,nom_temporaire
mov ecx,512
mov al,6
int 63h
cmp al,1
je ferme_fichier
cmp al,44
jne rey_demande_enregsous

rey_enregsous_fichier:
;cree le fichier
mov al,2 
mov bx,0
mov edx,nom_temporaire
int 64h
cmp eax,0
jne echec_enregistre_sous

mov al,1
int 64h

push es
mov ax,ds
mov es,ax
mov esi,nom_temporaire
mov edi,nom_fichier
mov ecx,64
cld
rep movsd
pop es
call sauvegarder_fichier
jmp affichage



echec_enregistre_sous:
push eax
call raz_ecr
pop eax
cmp eax,cer_nfr
je enregsous_dejaexistant

mov edx,msg_ens_er1
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h 

rey_err_es1:
mov al,13
mov cl,1
mov ch,3
mov bl,0
mov bh,7
int 63h
cmp bh,1
je rey_err_es1 


cmp bl,0
je rey_enregsous_fichier
cmp bl,1
je touche_enregistrer_sous
jmp affichage             




enregsous_dejaexistant:
mov edx,msg_ens_er2
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h 

rey_err_es2:
mov al,13
mov cl,1
mov ch,3
mov bl,0
mov bh,7
int 63h
cmp bh,1
je rey_err_es2 


cmp bl,0
je touche_enregistrer_sous
push es
mov ax,ds
mov es,ax
mov esi,nom_temporaire
mov edi,nom_fichier
mov ecx,64
cld
rep movsd
pop es
call sauvegarder_fichier
jmp affichage


;***************************************************
rechercher_doc:
call raz_ecr
mov edx,msg15
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h

mov ah,07h
mov edx,motrecherche
mov ecx,256
mov al,6
int 63h

jmp affichage

;***************************************************
aller_ligne:
call raz_ecr
mov edx,msg5
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h

mov byte[numeros],0
mov ah,07h
mov edx,numeros
mov ecx,15
mov al,6
int 63h

;convertie en nombre
mov al,100
mov edx,numeros
int 61h

mov dword[curseur_ligne],0 
mov [offset_ligne],ecx
mov dword[curseur_colonne],0 
mov dword[offset_colonne],0
call recalcule_ligne0
jmp affichage


;***************************************************
remplacer_chaine:
jmp affichage


;***************************************************
clique_souris:
test ecx,0FFFFFFF0h
jz affiche_menu
or byte[options],014h
jmp positionne_souris


declique_souris:
and byte[options],0FBh
or byte[options],08h
jmp affichage



;***************************************************
config:
mov bl,0

affiche_config:
push ebx
call raz_ecr
mov edx,msg16a
call ajuste_langue
test word[options],1
jz ecrit_msg16
mov edx,msg16b
call ajuste_langue
ecrit_msg16:
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,msg17a
call ajuste_langue
test word[options],2
jz ecrit_msg17
mov edx,msg17b
call ajuste_langue
ecrit_msg17:
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,msg18
call ajuste_langue
mov al,11
mov ah,07h ;couleur
int 63h
pop ebx

mov al,13
mov cl,0
mov ch,3
mov bh,7
int 63h

cmp bl,0
je config_option_numligne
cmp bl,1
je config_option_retour
jmp affichage


config_option_numligne:
btc word[options],0
jnz affiche_config
btr word[options],1
jmp affiche_config


config_option_retour:
btc word[options],1
jnz affiche_config
btr word[options],0
jmp affiche_config

;*****************************************************************************touches selection
select_tout:
mov ecx,[taille_fichier]
mov dword[curseur_colonne],0 
mov dword[offset_colonne],0
mov dword[curseur_ligne],0 
mov dword[offset_ligne],0
mov [selecorigine],ecx 
or byte[options],08h
jmp affichage


;********************
select_ligne:
mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne
mov [selecorigine],esi
call mvmt_fin
or byte[options],08h
jmp affichage


;****************
select_mot:
mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne
mov edi,[seleccurseur]

;recherche le debut du mot
@@:
es
cmp byte[edi]," "
je @f
es
cmp byte[edi],","
je @f
es
cmp byte[edi],";"
je @f
es
cmp byte[edi],"."
je @f
es
cmp byte[edi],":"
je @f
cmp esi,edi
je selec_mot_debligne
dec edi
jmp @b

@@:
inc edi
selec_mot_debligne:
mov [selecorigine],edi
call mvmt_finm
or byte[options],08h
jmp affichage



;************************
select_debligne:
mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne
mov [selecorigine],esi
or byte[options],08h
jmp affichage

;***********************
select_finligne:
mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne
@@:
call charge_carac
cmp eax,0
je @f
cmp eax,13
je @f
jmp @b
@@:
dec esi
mov [selecorigine],esi
or byte[options],08h
jmp affichage






;*****************************************************************************touches mouvements
touche_debut:
mov dword[curseur_colonne],0 
mov dword[offset_colonne],0
jmp affichage

;****************************************************
touche_fin:
call mvmt_fin
jmp affichage

mvmt_fin:
mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne

;compte le nombre de caractère de la ligne
xor ecx,ecx
boucle_touche_fin:
call charge_carac
cmp eax,0
je fin_touche_fin
cmp eax,13
je fin_touche_fin
inc ecx
jmp boucle_touche_fin

fin_touche_fin:
mov eax,[resxt_correc]
dec eax

cmp ecx,eax
ja decalage_touche_fin
mov [curseur_colonne],ecx
mov dword[offset_colonne],0
ret

decalage_touche_fin:
mov [curseur_colonne],eax
sub ecx,eax
mov [offset_colonne],ecx
ret


;*****************************************************
aller_mot_deb:
mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne
mov edi,[seleccurseur]

;recherche le debut du mot
@@:
cmp esi,edi
je touche_debut
dec edi
es
cmp byte[edi]," "
je @f
es
cmp byte[edi],","
je @f
es
cmp byte[edi],";"
je @f
es
cmp byte[edi],"."
je @f
es
cmp byte[edi],":"
je @f
jmp @b

@@:
inc edi
xor ecx,ecx

@@:
cmp esi,edi
jae @f
call charge_carac
inc ecx
jmp @b

@@:
mov eax,[resxt_correc]
dec eax

cmp ecx,eax
ja @f
mov [curseur_colonne],ecx
mov dword[offset_colonne],0
jmp affichage

@@:
mov [curseur_colonne],eax
sub ecx,eax
mov [offset_colonne],ecx
jmp affichage


;*****************************************************
aller_mot_fin:
call mvmt_finm
jmp affichage


;*****************
mvmt_finm:
mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne

;compte le nombre de caractère de la ligne
xor ecx,ecx
boucle_touche_finm:
call charge_carac
cmp eax,0
je fin_touche_finm
cmp eax,13
je fin_touche_finm
cmp eax," "
je fin_touche_finm2
cmp eax,","
je fin_touche_finm2
cmp eax,";"
je fin_touche_finm2
cmp eax,"."
je fin_touche_finm2
cmp eax,":"
je fin_touche_finm2
inc ecx
jmp boucle_touche_finm


fin_touche_finm2:
cmp esi,[seleccurseur]
ja fin_touche_finm
inc ecx
jmp boucle_touche_finm
 

fin_touche_finm:
mov eax,[resxt_correc]
dec eax

cmp ecx,eax
ja decalage_touche_finm
mov [curseur_colonne],ecx
mov dword[offset_colonne],0
ret

decalage_touche_finm:
mov [curseur_colonne],eax
sub ecx,eax
mov [offset_colonne],ecx
ret




;***************************************************
aller_mot_prec:
mov edi,[seleccurseur]
cmp edi,0
jz fin_aller_mot_prec

;recherche le debut du mot
@@:
dec edi
jz fin_aller_mot_prec
es
mov al,[edi]
cmp al," "
je @f
cmp al,","
je @f
cmp al,";"
je @f
cmp al,"."
je @f
cmp al,":"
je @f
cmp al,10
je @f
cmp al,13
je @f
jmp @b

;recherche la fin du mot précédent
@@:
dec edi
jz fin_aller_mot_prec
es
mov al,[edi]
cmp al," "
je @b
cmp al,","
je @b
cmp al,";"
je @b
cmp al,"."
je @b
cmp al,":"
je @b
cmp al,10
je @b
cmp al,13
je @b

;recherche le debut du mot précédent
@@:
dec edi
jz fin_aller_mot_prec
es
mov al,[edi]
cmp al," "
je @f
cmp al,","
je @f
cmp al,";"
je @f
cmp al,"."
je @f
cmp al,":"
je @f
cmp al,10
je @f
cmp al,13
je @f
jmp @b

@@:
inc edi
fin_aller_mot_prec:
mov [seleccurseur],edi
call replace_cur
jmp affichage



;****************************************
aller_mot_suiv:
mov edi,[seleccurseur]
cmp edi,[taille_fichier]
je fin_aller_mot_suiv

;recherche la fin du mot
@@:
inc edi
cmp edi,[taille_fichier]
je fin_aller_mot_suiv
es
mov al,[edi]
cmp al," "
je @f
cmp al,","
je @f
cmp al,";"
je @f
cmp al,"."
je @f
cmp al,":"
je @f
cmp al,10
je @f
cmp al,13
je @f
jmp @b

;recherche le début du suivant
@@:
inc edi
cmp edi,[taille_fichier]
je fin_aller_mot_suiv
es
mov al,[edi]
cmp al," "
je @b
cmp al,","
je @b
cmp al,";"
je @b
cmp al,"."
je @b
cmp al,":"
je @b
cmp al,10
je @b
cmp al,13
je @b

fin_aller_mot_suiv:
mov [seleccurseur],edi
call replace_cur
jmp affichage
 

;*********************************
aller_rech_prec:
mov edi,[seleccurseur]
cmp edi,0
je fin_aller_rech_prec
mov esi,motrecherche
mov al,[esi]
cmp al,0
je fin_aller_rech_prec

boucle_aller_rech_prec:
dec edi
jz fin_aller_rech_prec
es
cmp al,[edi]
jne boucle_aller_rech_prec
mov ebx,edi

@@:
inc esi
inc ebx
mov al,[esi]
cmp al,0
je fin_aller_rech_prec
es
cmp al,[ebx]
je @b
mov esi,motrecherche
mov al,[esi]
jmp boucle_aller_rech_prec

fin_aller_rech_prec:
mov [seleccurseur],edi
call replace_cur
jmp affichage

;*********************************
aller_rech_suiv:
mov edi,[seleccurseur]
cmp edi,[taille_fichier]
je fin_aller_rech_suiv
mov esi,motrecherche
mov al,[esi]
cmp al,0
je fin_aller_rech_suiv

boucle_aller_rech_suiv:
inc edi
cmp edi,[taille_fichier]
je fin_aller_rech_suiv
es
cmp al,[edi]
jne boucle_aller_rech_suiv
mov ebx,edi

@@:
inc esi
inc ebx
mov al,[esi]
cmp al,0
je fin_aller_rech_suiv
es
cmp al,[ebx]
je @b
mov esi,motrecherche
mov al,[esi]
jmp boucle_aller_rech_suiv

fin_aller_rech_suiv:
mov [seleccurseur],edi
call replace_cur
jmp affichage




;****************************************************
touche_pageup:
mov eax,[resyt]
dec eax
cmp [offset_ligne],eax
jb touche_pageup_plus
sub [offset_ligne],eax
call recalcule_ligne0
jmp suite_mvmt_curseur


touche_pageup_plus:
mov dword[offset_ligne],0
mov dword[curseur_ligne],0
call recalcule_ligne0
jmp suite_mvmt_curseur


;****************************************************
touche_pagedown:
mov eax,[resyt]
dec eax
add [offset_ligne],eax
call recalcule_ligne0
jmp suite_mvmt_curseur

;****************************************************
moin1c:
call mvmt_ar
jmp suite_mvmt_curseur

mvmt_ar:
cmp dword[curseur_colonne],0
je mvmt_ar_plus
dec dword[curseur_colonne] 
ret

mvmt_ar_plus:
cmp dword[offset_colonne],0
je mvmt_ar_remonte
dec dword[offset_colonne] 
ret

mvmt_ar_remonte:
cmp dword[offset_ligne],0
jne ok_mvmt_ar_remonte
cmp dword[curseur_ligne],0
jne ok_mvmt_ar_remonte
ret

ok_mvmt_ar_remonte:
call mvmt_ht
call mvmt_fin
call recalcule_ligne0
ret

;***************************************************
moin1l:
call mvmt_ht
call recalcule_ligne0
jmp suite_mvmt_curseur

mvmt_ht:
cmp dword[curseur_ligne],0
je moin1lplus
dec dword[curseur_ligne] 
ret
moin1lplus:
cmp dword[offset_ligne],0
je fin_mvmt_ht
dec dword[offset_ligne] 
fin_mvmt_ht:
ret


recalcule_ligne0:     ;recalcul l'adresse de la première ligne affiché dans le document
mov ecx,[offset_ligne]
call rech_ligne
mov [adresse_ligne0],esi
cmp ecx,0
jne def_lignemax
ret

def_lignemax:
mov [offset_ligne],edx
ret

;*************************************************
plus1c:
call mvmt_av
jmp suite_mvmt_curseur

mvmt_av:
mov eax,[resxt_correc]
dec eax
cmp [curseur_colonne],eax
je plus1cplus
inc dword[curseur_colonne]
ret

plus1cplus:
inc dword[offset_colonne]
ret


;***********************************************
plus1l:
call mvmt_bas
jmp suite_mvmt_curseur


mvmt_bas:
mov eax,[resyt]
sub eax,2
cmp [curseur_ligne],eax
je plus1lplus
inc dword[curseur_ligne]
ret

plus1lplus:
inc dword[offset_ligne]
call recalcule_ligne0
ret

;****************************************************
suite_mvmt_curseur:
test byte[touche_importante],03h
jz affichage
or byte[options],08h
jmp affichage

;**************************************************
couper:
mov edx,[selecmin]
mov ecx,[selecmax] 
sub ecx,edx
cmp ecx,0
je affichage
mov al,15
int 61h
call supprime_zone
mov byte[data_modif],1 
jmp affichage


;**************************************************
copier:
mov edx,[selecmin]
mov ecx,[selecmax] 
sub ecx,edx
cmp ecx,0
je affichage
mov al,15
int 61h
or byte[options],08h
jmp affichage


;**************************************************
coller:
;determine la taille des données a coller
mov eax,16
xor ecx,ecx
int 61h
cmp ecx,0
je affichage

;si il y as des données a coller, efface les données éventuellement selectionné
push ecx
push ecx
call supprime_zone
call ajoute_manques
mov [seleccurseur],esi
pop ecx
call decale_texte
pop ecx



mov esi,[seleccurseur]
mov eax,16
mov edx,esi
int 61h

add [seleccurseur],ecx  ;déplace le curseur
mov byte[data_modif],1 
call replace_cur
jmp affichage



;***********************************************
fin:
mov edx,msg_modif_fin
call ajuste_langue
call sauvegarde_conditionnelle
int 60h

fin_err_mem:
mov al,6        
mov edx,msg12
call ajuste_langue
int 61h
int 60h





;****************************************************
supprime_zone:
mov esi,[selecmax] 
mov edi,[selecmin]
cmp esi,edi
jne ok_suprime_zone
ret


ok_suprime_zone:
mov ecx,[taille_fichier]
sub ecx,esi
cmp ecx,0
je ignore_supprime_zone
push ds
mov ax,sel_dat2
mov ds,ax
cld
rep movsb
pop ds
ignore_supprime_zone:

mov ecx,[selecmax] 
sub ecx,[selecmin]
sub [taille_fichier],ecx
mov ebx,[taille_fichier]
es
mov byte[ebx],0

mov eax,[selecmin]
mov [seleccurseur],eax
mov [selecorigine],eax
mov byte[data_modif],1 



;********************************************************
;replace le curseur a la position de "selectcurseur"
replace_cur:
xor ebx,ebx
xor ecx,ecx
xor edx,edx

boucle_recherche_coord:
cmp ebx,[seleccurseur]
je fin_recherche_coord
es
mov al,[ebx]
cmp al,0
je fin_recherche_coord
cmp al,13
je ligne1_recherche_coord
cmp al,10
je ligne2_recherche_coord
and al,0C0h
cmp al,080h
je passe_recherche_coord
inc ebx
inc edx
jmp boucle_recherche_coord

ligne1_recherche_coord:
inc ebx
es
cmp byte[ebx],10
jne  @f
inc ebx
@@:
inc ecx
xor edx,edx
jmp boucle_recherche_coord

ligne2_recherche_coord:
inc ebx
es
cmp byte[ebx],13
jne  @f
inc ebx
@@:
inc ecx
xor edx,edx
jmp boucle_recherche_coord


passe_recherche_coord:
inc ebx
jmp boucle_recherche_coord


fin_recherche_coord: ;ecx=ligne edx=colonne
cmp ecx,[offset_ligne]
jb reajustement_ligne1

sub ecx,[offset_ligne]
cmp ecx,[resyt_correc]
jae reajustement_ligne2

mov [curseur_ligne],ecx
jmp determine_colonne

reajustement_ligne1:
mov dword[curseur_ligne],0
mov [offset_ligne],ecx
call recalcule_ligne0
jmp determine_colonne

reajustement_ligne2:
add [offset_ligne],ecx
mov eax,[resyt_correc]
dec eax
mov [curseur_ligne],eax
sub [offset_ligne],eax
push edx
call recalcule_ligne0
pop edx

determine_colonne:
cmp edx,[offset_colonne]
jb reajustement_colonne1

sub edx,[offset_colonne]
cmp edx,[resxt_correc]
jae reajustement_colonne2

mov [curseur_colonne],edx
ret

reajustement_colonne1:
mov dword[curseur_colonne],0
mov [offset_colonne],edx
ret

reajustement_colonne2:
add [offset_colonne],edx
mov eax,[resxt_correc]
dec eax
mov [curseur_colonne],eax
sub [offset_colonne],eax
ret










;**************************************************************************************************
raz_ecr:
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
ret





;*************************************************************************************************
ajoute_manques:
;rajoute les marqueur de fin de ligne manquants
mov ecx,[offset_ligne]
add ecx,[curseur_ligne]
call rech_ligne

cmp ecx,0
je ok_ajoute_espace

mov esi,[taille_fichier]
mov eax,ecx
shl eax,1
add [taille_fichier],eax
call verif_zt

boucle_ajoute_crlf:
es
mov word[esi],0A0Dh
add esi,2
dec ecx
jnz boucle_ajoute_crlf
es
mov byte[esi],0


ok_ajoute_espace:
mov ebx,[offset_colonne]
add ebx,[curseur_colonne]

boucle_ajoute_espace:  ;recherche la position du curseur dans la ligne et insère des caractères d'espace pour completer en cas de besoin
cmp ebx,0
je fin_ajoute_manques
mov edi,esi
call charge_carac
cmp eax,13
je ajoute_espace
cmp eax,10
je ajoute_espace
cmp eax,0
je ajoute_espace
dec ebx
jmp boucle_ajoute_espace

ajoute_espace:    ;ajoute un espace pour agrandir la ligne
mov esi,edi
mov ecx,1
call decale_texte   ;décale le texte a partir de esi pour y inserer ecx octet
es
mov byte[esi],20h
inc esi
call verif_zt
dec ebx
jmp boucle_ajoute_espace

fin_ajoute_manques:
ret







;****************************************************************************
charge_fichier:
call raz_ecr


;ouvre le fichier
xor eax,eax
mov bx,0
mov edx,nom_fichier
int 64h
cmp eax,0
jne echec_lecture
mov [num_fichier],ebx


;lit taille fichier
mov ebx,[num_fichier]
mov edx,taille_fichier
mov al,6
mov ah,1 ;fichier
int 64h
cmp eax,0
jne echec_lecture


;determine si la taille du fichier n'est pas trop importante
;???????????????????????????????????

call verif_zt

;lire fichier
mov ebx,[num_fichier]
mov ecx,[taille_zone]
mov edx,0   ;offset dans le fichier
mov edi,0   ;offset dans le segment
mov al,4
int 64h
cmp eax,0
jne echec_lecture


mov byte[data_modif],0  

mov ebx,[taille_fichier]
es
mov byte[ebx],0

mov dword[offset_ligne],0
mov dword[offset_colonne],0
mov dword[curseur_ligne],0
mov dword[curseur_colonne],0
mov dword[adresse_ligne0],0

;ferme le fichier
mov eax,1
mov ebx,[num_fichier]
int 64h

ret



echec_lecture:
push eax
mov eax,1
mov ebx,[num_fichier]
int 64h
call raz_ecr
pop eax
mov edx,msg_errlec1
call ajuste_langue
cmp eax,cer_fdo
jne pasdejaouvert_echec_lecture
mov edx,msg_errlec2
call ajuste_langue
pasdejaouvert_echec_lecture:
mov al,11
mov ah,07h ;couleur
int 63h 

mov al,13   ;menu
mov cl,1    ;démarre a la ligne
mov ch,2    ;sur ch ligne
mov bl,0    ;
mov bh,7    ;couleur
int 63h

cmp bl,0
je charge_fichier
mov byte[taille_fichier],0
mov byte[nom_fichier],0
ret








;*****************************************
sauvegarde_conditionnelle:


cmp byte[data_modif],0    ;check si le secteur a été modifié  
jne continue_sauvegarde_conditionnelle
ret

continue_sauvegarde_conditionnelle:
call raz_ecr
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
je sauvegarder_fichier
ret





;******************************************
sauvegarder_fichier:


;ouvre le fichier
xor eax,eax
mov bx,0
mov edx,nom_fichier
int 64h
cmp eax,0
jne echec_ecriture


mov [num_fichier],ebx
mov edx,taille_fichier
mov al,7
mov ah,1 ;taille fichier
int 64h
cmp eax,0
jne echec_ecriture

mov ebx,[num_fichier]
mov ecx,[taille_fichier]
mov edx,0   ;offset dans le fichier
mov esi,0   ;offset dans le segment
mov al,5
int 64h
cmp eax,0
jne echec_ecriture

mov byte[data_modif],0  
;ferme le fichier
mov eax,1
mov ebx,[num_fichier]
int 64h

ret


echec_ecriture:
push eax
mov eax,1
mov ebx,[num_fichier]
int 64h
call raz_ecr
pop eax
mov edx,msg_errsauv1
call ajuste_langue
cmp eax,cer_fdo
jne pasdejaouvert_echec_ecriture
mov edx,msg_errsauv2
call ajuste_langue
pasdejaouvert_echec_ecriture:
mov al,11
mov ah,07h ;couleur
int 63h 

mov al,13   ;menu
mov cl,1    ;démarre a la ligne
mov ch,2    ;sur ch ligne
mov bl,0    ;
mov bh,7    ;couleur
int 63h

cmp bl,0
je sauvegarder_fichier
ret






;****************************************
verif_zt:
pushad
mov eax,[taille_fichier]
shr eax,3 ;div par 8
add eax,[taille_fichier]
cmp [taille_zone],eax 
jae fin_verif_zt    

;calcul la taille de la ZT nécessaire (+25% par rapport a la taille du fichier +4Ko)
mov eax,[taille_fichier]
shr eax,2 ;div par 4
add eax,4096
add eax,[taille_fichier]
mov [taille_zone],eax 

mov dx,sel_dat2
mov ecx,[taille_zone]
mov al,8
int 61h

fin_verif_zt:
popad
ret






;******************************************
decale_texte:   ;décale le texte a partir de esi pour y inserer ecx octet (sans les inserer)
push ecx
push edx
push esi
push edi
push ds
mov edx,ecx
mov ecx,[taille_fichier]
inc ecx
sub ecx,esi
cmp ecx,0
jbe ignore_decale_texte
mov edi,[taille_fichier]
add [taille_fichier],edx
call verif_zt
mov esi,edi
add edi,edx
mov ax,sel_dat2
mov ds,ax
std  ;-
rep movsb
ignore_decale_texte:
pop ds
pop edi
pop esi
pop edx
pop ecx
ret



;*********************************
rech_ligne:   ;renvoie l'adresse du debut de la ligne dans esi dont le numéros est dans ecx
xor edx,edx
xor esi,esi
cmp ecx,0
je fin_rech_ligne
boucle_rech_ligne:
es
mov ax,[esi]
inc esi
cmp al,0
je fin_rech_ligne
cmp ax,0D0Ah
je rech_ligne_f2
cmp ax,0A0Dh
je rech_ligne_f2
cmp al,10
je rech_ligne_f1
cmp al,13
je rech_ligne_f1
jmp boucle_rech_ligne
rech_ligne_f2:
inc esi
rech_ligne_f1:
inc edx
dec ecx
jnz boucle_rech_ligne

fin_rech_ligne:
ret




;*********************************************
precharge_nomdossier:
mov edx,nom_temporaire
mov eax,18
int 61h

boucle_rech_finnomdossier:
cmp byte[edx],0
je trouve_rech_finnomdossier
inc edx
cmp edx,nom_temporaire+255
jne boucle_rech_finnomdossier 

trouve_rech_finnomdossier:
mov byte[edx],"/"
inc edx
mov byte[edx],0
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




;****************************************************************************

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


resxt_correc:
dd 0
resyt_correc:
dd 0
start_ligne:
dd 0

saisienum:
dd 0,0,0,0

chaineligne:
dd 0,0,0,0,0,0   ;24 octets
numeros:
dd 0,0,0,0,0,0   ;24 octets




num_fichier:
dd 0
taille_fichier:
dd 0,0
taille_zone:
dd 0

data_modif:
db 0
options:
dw 0        ;b0=affichage numéros de ligne
            ;b1=retour a la ligne automatique 
            ;b2=clique gauche souris enfoncé
            ;b3=pas besoin de remettre a jour la position curseur d'origine la prochaine fois
 	    ;b4=met a jour la position curseur la position curseur d'origine la prochaine fois		



offset_ligne:
dd 0
offset_colonne:
dd 0
curseur_ligne:
dd 0
curseur_colonne:
dd 0
adresse_ligne0:
dd 0


sauvegarde_offset_ligne:
dd 0
sauvegarde_offset_colonne:
dd 0
sauvegarde_curseur_ligne:
dd 0
sauvegarde_curseur_colonne:
dd 0
sauvegarde_adresse_ligne0:
dd 0



touche_importante:
db 0

selecorigine:
dd 0
seleccurseur:
dd 0
selecmin:
dd 5  ;0FFFFFFFFh
selecmax:
dd 5   ;0FFFFFFFFh

rechmin:
dd 0FFFFFFFFh
rechmax:
dd 0FFFFFFFFh


deci8b:
dd 0,0,0,0,0
deci16b:
dd 0,0,0,0,0
deci32b:
dd 0,0,0,0,0
hexa8b:
dd 0,0,0,0,0
hexa16b:
dd 0,0,0,0,0
hexa32b:
dd 0,0,0,0,0




msg1:
db "Text Editor (new file)",0
db "EDiteur Texte (nouveau fichier)",0
msg2:
db "F1=menu",0
db "F1=menu",0


msg3:
db "which file do you want to open? (ESC to cancel)",13,0
db "quel fichier souhaitez vous ouvrir? (ECHAP pour annuler)",13,0

msg_nvf1:
db "what is the name of the file you want to create? (ESC to cancel)",13,0
db "quel est le nom du fichier que vous souhaitez créer? (ECHAP pour annuler)",13,0


msg_nvf_er1:
db "error while creating new file, do you want to:",13
db "try again",13
db "choose a new file name",13
db "cancel",13,0
db "erreur lors de la création de nouveau fichier, voulez vous:",13
db "réessayer",13
db "choisir un nouveau nom de fichier",13
db "annuler",13,0


msg_nvf_er2:
db "the file you want to create already exists, do you want to:",13
db "choose another file name",13
db "overwrite existing file",13
db "open existing file",13,0
db "le fichier que vous voulez créer existe déja, voulez vous:",13
db "choisir un autre nom de fichier",13
db "écraser le fichier existant",13
db "ouvrir le fichier existant",13,0



msg_cree2:
db "the file you want to create already exists, do you want to:",13
db "overwrite file",13
db "open file",13
db "choose another file",13,0
db "le fichier que vous souhaitez créer existe déjà, voulez vous:",13
db "écraser le fichier",13
db "ouvrir le fichier",13
db "choisir un autre fichier",13,0


msg_menuc:
db "continue editing file",13

db "close file",13

db "new file",13

db "open file",13

db "save file",13

db "save file under another name",13

db "go to line",13

db "search",13

db "replace",13

db "configure",13

db "quit",13,13,13,0
db "continuer l'edition du fichier",13
db "fermer le fichier",13
db "nouveau fichier",13
db "ouvrir fichier",13
db "sauvegarder fichier",13
db "sauvegarder le fichier sous un autre nom",13
db "aller a la ligne",13
db "rechercher",13
db "remplacer",13
db "configurer",13
db "quitter",13,13,13,0


msg_menur:
db "new file",13

db "open file",13
db "quit",13,13,13,13,13,13,13,13,13,13,13,0
db "nouveau fichier",13
db "ouvrir fichier",13
db "quitter",13,13,13,13,13,13,13,13,13,13,13,0






msg_menua:
db "shortcuts available while editing:",13

;db "Ctrl+M or F1 menu",13

db "Ctrl+O open file",13

db "Ctrl+S save file",13

;db "Ctrl+Z abord",13

;db "Ctrl+P print",13

db "Ctrl+Q or Esc quit",13


db "Ctrl+F search in file",13

;db "Ctrl+N go to next search term",13

;db "ctrl+B jump to previous search term",13

;db "Ctrl+R replace",13

db "Ctrl+D goes to the beginning of the word",13
db "Ctrl+E goes to the end of the word",13
db "Ctrl+G goes to the previous word",13
db "Ctrl+H goes to the next word",13

db "Ctrl+A selects all",13
db "Ctrl+W selects the word",13
db "Ctrl+L selects the line",13
db "Ctrl+J selects from the beginning of the line to the cursor",13
db "Ctrl+K selects from the end of the line to the cursor",13

db "Ctrl+X cut",13

db "Ctrl+C copy",13

db "Ctrl+V paste",13,0
;*************************************************************
db "raccourcis disponible durant l'édition:",13
;db "Ctrl+M ou F1 menu",13

db "Ctrl+O ouvrir un fichier",13
db "Ctrl+S enregistrer le fichier",13
;db "Ctrl+Z annuler",13
;db "Ctrl+P imprimer",13
db "Ctrl+Q ou Esc quitter",13


db "Ctrl+F rechercher dans le fichier",13
;db "Ctrl+N passer au terme recherché suivant",13
;db "ctrl+B passer au terme recherché précédent",13
;db "Ctrl+R remplacer",13

db "Ctrl+D va au debut du mot",13

db "Ctrl+E va a la fin du mot",13

db "Ctrl+G va au mot précédent",13
db "Ctrl+H va au mot suivant",13


db "Ctrl+A selectionne tout",13

db "Ctrl+W selectionne le mot",13

db "Ctrl+L selectionne la ligne",13

db "Ctrl+J selectionne du début de la ligne jusqu'au curseur",13

db "Ctrl+K selectionne de la fin de la ligne jusqu'au curseur",13



db "Ctrl+X couper",13
db "Ctrl+C copier",13
db "Ctrl+V coller",13,0




msg5:
db "which line do you want to display?",0
db "quelle ligne souhaitez vous afficher?",0



msg7:
db "what name do you want to save the file as? (ESC to cancel)",13,0
db "sous quel nom voulez vous enregistrer le fichier? (ECHAP pour annuler)",13,0


msg_ens_er1:
db "error while creating new file, do you want to:",13
db "try again?",13
db "choose another file name?",13
db "cancel? ",13,0
db "erreur lors de la création de nouveau fichier, voulez vous:",13
db "réessayer",13
db "choisir un autre nom de fichier",13
db "annuler",13,0


msg_ens_er2:
db "the file you want to create already exists, do you want to:",13
db "choose another file name?",13
db "overwrite existing file?",13,0
db "le fichier que vous voulez créer existe déja, voulez vous:",13
db "choisir un autre nom de fichier?",13
db "écraser le fichier existant?",13,0



msg_errsauv1:
db "error while writing the file, do you want to:",13
db "try again?",13
db "unsave file?",13,0
db "erreur lors de l'écriture du fichier, voulez vous:",13
db "reéssayer?",13
db "annuler l'enregistrement du fichier?",13,0


msg_errsauv2:
db "impossible to write in the file, it is already in use, do you want to:",13
db "try again?",13
db "cancel? ",13,0
db "impossible d'écrire dans le fichier, il est déja en cours d'utilisation, voulez vous:",13
db "reéssayer?",13
db "annuler? ",13,0

msg_errlec1:
db "error while reading the file, do you want to:",13
db "try again?",13
db "cancel? ",13,0
db "erreur lors de la lecture du fichier, voulez vous:",13
db "reéssayer?",13
db "annuler? ",13,0

msg_errlec2:
db "impossible to read the file, it is already in use, do you want to:",13
db "try again?",13
db "cancel? ",13,0
db "impossible de lire le fichier, il est déja en cours d'utilisation, voulez vous:",13
db "reéssayer?",13
db "annuler? ",13,0



msg12:
db "unable to reserve the memory necessary to continue the execution of the program",13,0 
db "impossible de réserver la mémoire nécessaire pour poursuivre l'execution du programme",13,0 


msg_modif_fer:
db "the file has been modified, do you want to",13
db "save changes and close the file?",13
db "close file without saving?",13,0
db "le fichier a été modifié, voulez vous",13
db "enregistrer les modifications et fermer le fichier?",13
db "fermer le fichier sans enregistrer?",13,0


msg_modif_ouv:
db "the file has been modified, do you want to",13
db "save changes before opening another file?",13
db "open another file without saving?",13,0
db "le fichier a été modifié, voulez vous",13
db "enregistrer les modifications avant d'ouvrir un autre fichier?",13
db "ouvrir un autre fichier sans enregistrer?",13,0


msg_modif_nou:
db "the file has been modified, do you want to",13
db "save changes before creating a new file?",13
db "create a new file without saving?",13,0
db "le fichier a été modifié, voulez vous",13
db "enregistrer les modifications avant de créer un nouveau fichier?",13
db "créer un nouveau fichier sans enregistrer?",13,0


msg_modif_fin:
db "the file has been modified, do you want to",13
db "save changes before exiting?",13
db "exit without saving?",13,0
db "le fichier a été modifié, voulez vous",13
db "enregistrer les modifications avant de quitter?",13
db "quitter sans enregistrer?",13,0


msg15:
db "what terms do you want to search for?",13,0
db "quel termes souhaitez vous rechercher?",13,0


msg16a:
db "no display of line numbers",13,0
db "pas d'affichage numéros de la ligne",13,0
msg16b:
db "line number display",13,0
db "affichage numéros de la ligne",13,0


msg17a:
db "end of line not displayed",13,0
db "pas d'affichage de la fin de ligne",13,0
msg17b:
db "automatic word wrap",13,0
db "retour à la ligne automatique",13,0


msg18:
db "return to edit screen",13,0
db "revenir à l'écran d'édition",13,0


descriptif2:
db "EDT: "


nom_fichier:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64


nom_temporaire:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64


motrecherche:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64




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
