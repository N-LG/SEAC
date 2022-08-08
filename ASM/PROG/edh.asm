edh:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "editeur hexadécimal de disques"
scode:
org 0


;revoir l'affichage
;saut automatique
;sauvegarde

;limite fin de fichier





mov dx,sel_dat2
mov ah,5   ;option=mode texte+souris
mov al,0   ;création console     
int 63h



mov dx,sel_dat1
mov ds,dx
mov es,dx
mov dx,sel_dat2
mov fs,dx

mov edx,bitpp
mov al,2   ;information video     
int 63h

mov eax,[resyt]   ;calcul la quantité de donnée affichable en un seul écran
sub eax,3
shl eax,4
mov [max_affichable],eax

mov al,8                 ;redimensionne la zone de donné pour avoir une zt de 128ko
mov ecx,zone_tampon
add ecx,20003h
mov dx,sel_dat1
int 61h


mov edx,nom_fichier
mov cl,0   ;256 octet du coup
mov ax,4   ;0eme argument
int 61h

cmp byte[nom_fichier],0
je affichage_menu
cmp byte[nom_fichier],"#"
jne ouvre_fichier



;*****************************************************
choix_disque:
call raz_ecr

mov esi,petite_zt

mov edx,msg_choix_disque1
mov al,11
mov ah,07h ;couleur
int 63h

mov byte[esi],01
inc esi

;listing des disques présent
mov ch,8h
boucle_ldp:
mov al,10
mov edi,zone_tampon
int 64h
cmp eax,0
jne suite_ldp

mov [esi],ch ;sauvegarde le numéros de disque
inc esi

;convertit le nom
mov ebx,zone_tampon+36h
boucle_convn:
mov ax,[ebx]
xchg al,ah
mov[ebx],ax
add ebx,2
cmp ebx,zone_tampon+5Eh
jne boucle_convn

;affiche le nom
mov edx,zone_tampon+36h
mov byte[zone_tampon+5Eh],0
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,msg_choix_disque2
mov al,11
mov ah,07h ;couleur
int 63h

;affiche la capacité
push ecx
mov al,18
int 64h
cmp eax,0
jne ldp_erreur_taille

mov ecx,ebx
shr ecx,1
mov edx,saisienum
mov al,102
int 61h

mov edx,saisienum
mov al,11
mov ah,07h ;couleur
int 63h

pop ecx
mov edx,msg_choix_disque3
mov al,11
mov ah,07h ;couleur
int 63h
jmp suite_ldp

ldp_erreur_taille:
pop ecx
mov edx,msg_choix_disque4
mov al,11
mov ah,07h ;couleur
int 63h

suite_ldp:
inc ch
cmp ch,80h
jne boucle_ldp




;****************************
sub esi,petite_zt
mov ecx,esi
shl ecx,8

mov bl,0
mov al,13
mov bh,7 ;couleur
mov cl,1
int 63h

and ebx,0FFh
mov dl,[petite_zt+ebx]
mov [num_disque],dl

mov dword[adresse_base],0
mov dword[adresse_base+4],0
mov dword[num_secteur],0
mov dword[offset_affichage],0
mov dword[offset_curseur],0
jmp chargement_partie





;********************************************
choix_fichier:
call raz_ecr
mov edx,msg_choix_fichier
mov al,11
mov ah,07h ;couleur
int 63h

saisie_nom_fichier:
mov ah,07h
mov edx,nom_fichier
mov ecx,400
mov al,6
int 63h
cmp al,1
je affichage_menu
cmp al,82
je saisie_nom_fichier
cmp al,84
je saisie_nom_fichier

ouvre_fichier:
xor eax,eax
mov bx,0
mov edx,nom_fichier
int 64h
cmp eax,12
je ok
cmp eax,0
jne choix_fichier
ok:
mov [num_fichier],ebx
mov byte[num_disque],0

;lit taille du fichier
mov al,6
mov ah,1 ;fichier
mov ebx,[num_fichier]
mov edx,taille_fichier
int 64h
cmp eax,0
jne choix_fichier

mov dword[adresse_base],0
mov dword[adresse_base+4],0
mov dword[num_secteur],0
mov dword[offset_affichage],0
mov dword[offset_curseur],0

;***************************************
chargement_partie:     ;charge la zt par 128ko de données
cmp byte[num_disque],0
je chargement_partie_fichier

mov eax,18
mov ch,[num_disque]
int 64h
call erreur_lecture
cmp eax,1
je chargement_partie 
cmp eax,2
je affichage_menu

xor al,al
mov ebx,ecx

@@:
cmp ebx,0
je affichage_menu
cmp ebx,1
je @f
shr ebx,1
inc al
jmp @b
@@:

mov byte[decalage],al
dec ecx
mov [masque_affichage],ecx
mov dword[masque_affichage+4],0
mov byte[secteur_modif],0




mov ebx,[num_secteur]
mov eax,20000h
mov cl,[decalage]
shr eax,cl
mov cl,al
mov eax,8
mov ch,[num_disque]
mov edi,zone_tampon
int 64h
call erreur_lecture
cmp eax,1
je chargement_partie 
cmp eax,2
je affichage_menu
jmp affichage


chargement_partie_fichier:
mov eax,4
mov ebx,[num_fichier]
mov ecx,20000h
mov edx,[adresse_base]
mov edi,zone_tampon
int 64h
call erreur_lecture
cmp eax,1
je chargement_partie_fichier 
cmp eax,2
je affichage_menu
mov byte[secteur_modif],0
mov byte[decalage],0
mov dword[masque_affichage],0FFFFFFFFh
mov dword[masque_affichage+4],0FFFFFFFFh
;jmp affichage

;************************************************************
affichage:
call raz_ecr

mov edx,msg_ligne_haut1
mov al,11
mov ah,07h ;couleur
int 63h

mov esi,[offset_affichage]
mov ebp,[resyt]
sub ebp,3

boucle_affichage:
mov eax,[adresse_base]
mov edx,[adresse_base+4]
mov [affichage_adresse],eax
mov [affichage_adresse+4],edx
add [affichage_adresse],esi
adc dword[affichage_adresse+4],0
mov eax,[masque_affichage]
mov edx,[masque_affichage+4]
and [affichage_adresse],eax
and [affichage_adresse+4],edx

mov byte[ligne],13
mov al,104
mov ecx,[affichage_adresse+4]
mov edx,ligne+1
int 61h
mov al,103
mov ecx,[affichage_adresse]
mov edx,ligne+5
int 61h
mov byte[ligne+13]," "
mov byte[ligne+14]," "


;supprime les zéros inutile en débur d'adresse
mov edi,ligne+1
boucle_supzero:
cmp byte[edi],"0"
jne fin_supzero
mov byte[edi],20h
inc edi
cmp edi,ligne+12
jne boucle_supzero
fin_supzero:

;affiche les valeur hexa
push esi
mov edi,ligne+15
mov ch,16
boucle_affichage_hexa:
mov al,105
mov cl,[esi+zone_tampon]
mov edx,edi
int 61h
mov byte[edi+2],20h
add edi,3
inc esi
dec ch
jnz boucle_affichage_hexa
pop esi
mov word[edi],020h


;affiche l'adresse et les données
mov edx,ligne
mov al,11
mov ah,07h ;couleur
int 63h

;affiche les caractère
push esi 
fs
mov edi,[ad_curseur_texte]
mov eax,07000000h
mov ch,16
boucle_affichage_carac:
mov al,[esi+zone_tampon]
fs
mov [edi],eax
inc esi
add edi,4
dec ch
jnz boucle_affichage_carac
pop esi

add esi,10h
dec ebp
jnz boucle_affichage


mov eax,[offset_curseur]     ;affichage des couleurs en vue de visualiser la position
mov ecx,eax
and ecx,0Fh    ;cl=numéros de colonne
shr eax,4
add eax,2      ;eax=numéros de ligne

push ecx
mov ecx,[resxt]
shl ecx,2         
mul ecx
fs
add eax,[ad_texte]
mov ecx,[resxt]

boucle_affichage_ligne:
fs
mov byte[eax+3],70h
add eax,4
dec ecx
jnz boucle_affichage_ligne
pop ecx

mov ebx,[resxt]
shl ebx,2       
fs
add ebx,[ad_texte]

mov eax,12    ;3 caractère occupe 12 octet
mul ecx
add eax,59   ;14 caractère +3      

shl ecx,2
add ecx,255  ;63 caractère +3

mov ebp,[resxt]
shl ebp,2
mov edx,[resyt]
sub edx,2

boucle_affichage_colonne:
push eax
push ecx
add eax,ebx
add ecx,ebx
fs
mov byte[eax],70h
fs
mov byte[eax+4],70h
fs
mov byte[ecx],70h
pop ecx
pop eax
add ebx,ebp
dec edx
jnz boucle_affichage_colonne


;affiche ligne bas
mov esi,zone_tampon
add esi,[offset_affichage]
add esi,[offset_curseur]

mov edx,msg_ligne_bas1
mov al,11
mov ah,07h ;couleur
int 63h

mov al,102
xor ecx,ecx
mov cl,[esi]
mov edx,petite_zt
int 61h
mov edx,petite_zt
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,msg_ligne_bas2
mov al,11
mov ah,07h ;couleur
int 63h

mov al,102
xor ecx,ecx
mov cx,[esi]
mov edx,petite_zt
int 61h
mov edx,petite_zt
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,msg_ligne_bas3
mov al,11
mov ah,07h ;couleur
int 63h

mov al,102
mov ecx,[esi]
mov edx,petite_zt
int 61h
mov edx,petite_zt
mov al,11
mov ah,07h ;couleur
int 63h


;***************************
;affichage numéro secteur
cmp byte[num_disque],0
je touche_boucle

mov eax,[offset_affichage]
add eax,[offset_curseur]
mov cl,[decalage]
shr eax,cl
add eax,[num_secteur]
mov ecx,eax
mov al,103
mov edx,saisienum
int 61h

mov al,10
mov ah,07h ;couleur
mov ebx,65
mov ecx,0
mov edx,msg_ligne_haut2
int 63h

mov al,10
mov ah,07h ;couleur
mov ebx,72
mov ecx,0
mov edx,saisienum
int 63h



;*******************************************
touche_boucle:          ;attente touche
mov al,5
int 63h
cmp al,1
je fin
cmp al,2
je affichage_menu
cmp al,3
je bouton_sauvegarde
;cmp al,4
;je recherche
cmp al,5
je choix
cmp al,10
je affichage_aide
cmp al,44
je modifdata
cmp al,100
je modifdata
cmp al,78
je moinmoin
cmp al,81
je plusplus
cmp al,82
je moin16
cmp al,83
je moin1
cmp al,84
je plus16
cmp al,85
je plus1
cmp al,0F0h
je souris1
cmp al,0F2h
je souris2
jmp touche_boucle


;***************************************************
moin1:
cmp dword[offset_curseur],0
je moin1_decal
dec dword[offset_curseur]
jmp affichage

moin1_decal:
mov eax,1
cmp dword[offset_affichage],0h
je moinmoin_decal
sub dword[offset_affichage],10h
add dword[offset_curseur],0Fh
jmp affichage



;****************************************************
moin16:
cmp dword[offset_curseur],10h
jb moin16_decal
sub dword[offset_curseur],10h
jmp affichage

moin16_decal:
mov eax,10h
cmp dword[offset_affichage],0h
je moinmoin_decal
sub dword[offset_affichage],10h
jmp affichage


;*************************************************
moinmoin:
mov eax,[max_affichable]
cmp dword[offset_affichage],eax
jb moinmoin_decal
sub dword[offset_affichage],eax
jmp affichage


moinmoin_decal:
cmp dword[adresse_base],10000h
jb moinmoin_zero

push eax
call sauvegarde
pop eax
mov edx,[offset_affichage]
add edx,10000h
sub edx,eax
mov eax,edx
and edx,0FFFFFFF0h
and eax,0Fh
mov [offset_affichage],edx
add [offset_curseur],eax
sub dword[adresse_base],10000h
sbb dword[adresse_base+4],0       
jmp chargement_partie


moinmoin_zero:
mov dword[offset_curseur],0
mov dword[offset_affichage],0
jmp affichage



;***********************************************
plus1:
mov eax,[max_affichable]
dec eax
cmp dword[offset_curseur],eax
je plus1_decal
inc dword[offset_curseur]
jmp affichage
plus1_decal:
mov eax,20000h
sub eax,[max_affichable]
cmp [offset_affichage],eax
je touche_boucle  
add dword[offset_affichage],10h
sub dword[offset_curseur],0Fh
jmp affichage

;*************************************************
plus16:
mov eax,[max_affichable]
sub eax,11h
cmp dword[offset_curseur],eax
ja plus16_decal
add dword[offset_curseur],10h
jmp affichage
plus16_decal:
mov eax,20000h
sub eax,[max_affichable]
cmp [offset_affichage],eax
je touche_boucle  
add dword[offset_affichage],10h
jmp affichage


;*************************************************
plusplus:
mov eax,[max_affichable]
add eax,[offset_affichage]
mov edx,eax
add edx,[max_affichable]
cmp edx,20000h
ja touche_boucle
mov [offset_affichage],eax
jmp affichage





;***************************************************
affichage_menu:
call sauvegarde
call raz_ecr
mov edx,msg_menu
mov al,11
mov ah,07h ;couleur
int 63h


mov bl,0
boucle_affichage_menu:
mov al,13
mov bh,7 ;couleur
mov cl,1
mov ch,3
int 63h


cmp bl,0
je choix_disque
cmp bl,1
je choix_fichier
cmp bl,2
je fin
jmp boucle_affichage_menu




;***************************************************
affichage_aide:
call raz_ecr
mov edx,msg_aide
mov al,11
mov ah,07h ;couleur
int 63h

attouche: ;attend qu'une touche soit pressé
mov al,5
int 63h
cmp al,0
je attouche
jmp affichage


;****************************************************
bouton_sauvegarde:
call ok_sauvegarde
jmp affichage



;*****************************************************
choix:
call sauvegarde
cmp byte[num_disque],0
jne choixsecteur


;***********
choixadresse:
call raz_ecr

mov al,103
mov ecx,[adresse_base]
add ecx,[offset_affichage]
add ecx,[offset_curseur]
mov edx,saisienum
int 61h

mov edx,msg_choix_adresse
mov al,11
mov ah,07h ;couleur
int 63h

saisie1:
mov ah,07h
mov edx,saisienum
mov ecx,16
mov al,6
int 63h
cmp al,82
je saisie1
cmp al,84
je saisie1

mov al,101
mov edx,saisienum
int 61h
mov [adresse_base],ecx
mov [offset_affichage],ecx
mov [offset_curseur],ecx
and dword[adresse_base],0FFFE0000h
and dword[offset_affichage],1FFF0h
and dword[offset_curseur],0Fh
xor ecx,ecx
mov [num_secteur],ecx
jmp chargement_partie


;************
choixsecteur:
call raz_ecr
mov eax,[offset_affichage]
add eax,[offset_curseur]
mov cl,[decalage]
shr eax,cl
add eax,[num_secteur]
mov ecx,eax
mov al,103
mov edx,saisienum
int 61h

mov edx,msg_choix_secteur
mov al,11
mov ah,07h ;couleur
int 63h

saisie2:
mov ah,07h
mov edx,saisienum
mov ecx,16
mov al,6
int 63h
cmp al,82
je saisie2
cmp al,84
je saisie2

mov al,101
mov edx,saisienum
int 61h
mov [num_secteur],ecx
xor ecx,ecx
mov [adresse_base],ecx
mov [offset_affichage],ecx
mov [offset_curseur],ecx
jmp chargement_partie



;**********************************************
modifdata:
mov ebx,[offset_affichage]
add ebx,[offset_curseur]
mov eax,[ebx+zone_tampon]
mov [valeur],eax
mov [ancienne_valeur],eax

modif_deci8b:
call maj_modif

;place le curseur
mov ebx,26
mov ecx,0
mov al,12
int 63h     

;aquisition de chaine
mov ah,07h
mov edx,deci8b
mov ecx,20
mov al,6
int 63h

;converion et maj valeur
push eax
mov al,100
mov edx,deci8b
int 61h
mov byte[deci8b],0
pop eax
test ecx,0FFFFFF00h
jnz modif_deci8b
mov [valeur],cl

;choix du déplacement
cmp al,82
je modif_deci8b
cmp al,44
je modif_annule

modif_deci16b:
call maj_modif

;place le curseur
mov ebx,26
mov ecx,1
mov al,12
int 63h     

;aquisition de chaine
mov ah,07h
mov edx,deci16b
mov ecx,20
mov al,6
int 63h

;converion et maj valeur
push eax
mov al,100
mov edx,deci16b
int 61h
mov byte[deci8b],0
pop eax
test ecx,0FFFF0000h
jnz modif_deci16b
mov [valeur],cx

;choix du déplacement
cmp al,82
je modif_deci8b
cmp al,44
je modif_annule

modif_deci32b:
call maj_modif

;place le curseur
mov ebx,26
mov ecx,2
mov al,12
int 63h     

;aquisition de chaine
mov ah,07h
mov edx,deci32b
mov ecx,20
mov al,6
int 63h

;converion et maj valeur
push eax
mov al,100
mov edx,deci32b
int 61h
pop eax
mov [valeur],ecx

;choix du déplacement
cmp al,82
je modif_deci16b
cmp al,44
je modif_annule

modif_hexa8b:
call maj_modif

;place le curseur
mov ebx,26
mov ecx,3
mov al,12
int 63h     

;aquisition de chaine
mov ah,07h
mov edx,hexa8b
mov ecx,20
mov al,6
int 63h

;converion et maj valeur
push eax
mov al,101
mov edx,hexa8b
int 61h
mov byte[hexa8b],0
pop eax
test ecx,0FFFFFF00h
jnz modif_hexa8b
mov [valeur],cl

;choix du déplacement
cmp al,82
je modif_deci32b
cmp al,44
je modif_annule

modif_hexa16b:
call maj_modif

;place le curseur
mov ebx,26
mov ecx,4
mov al,12
int 63h     

;aquisition de chaine
mov ah,07h
mov edx,hexa16b
mov ecx,20
mov al,6
int 63h

;converion et maj valeur
push eax
mov al,101
mov edx,hexa16b
int 61h
mov byte[hexa16b],0
pop eax
test ecx,0FFFF0000h
jnz modif_hexa16b
mov [valeur],cx

;choix du déplacement
cmp al,82
je modif_hexa8b
cmp al,44
je modif_annule

modif_hexa32b:
call maj_modif

;place le curseur
mov ebx,26
mov ecx,5
mov al,12
int 63h     

;aquisition de chaine
mov ah,07h
mov edx,hexa32b
mov ecx,20
mov al,6
int 63h

;converion et maj valeur
push eax
mov al,101
mov edx,hexa32b
int 61h
pop eax
mov [valeur],ecx

;choix du déplacement
cmp al,82
je modif_hexa16b
cmp al,44
je modif_annule


modif_annule:
call maj_modif

mov eax,7        ;met en subrillance la ligne
mov ecx,[resxt]
mul ecx
mov ebx,eax
shl ebx,2
add ebx,3
fs
add ebx,[ad_texte]
mov ecx,[resxt]

boucle_modif_annule:
fs
mov byte[ebx],070h
add ebx,4
dec ecx
jnz boucle_modif_annule

touche_modif_annule:
mov al,5
int 63h
cmp al,82
je modif_hexa32b
cmp al,84
je modif_valide
cmp al,44
je affichage
cmp al,100
je affichage
jmp touche_modif_annule

modif_valide:
call maj_modif

mov eax,8        ;met en subrillance la ligne
mov ecx,[resxt]
mul ecx
mov ebx,eax
shl ebx,2
add ebx,3
fs
add ebx,[ad_texte]
mov ecx,[resxt]

boucle_modif_valide:
fs
mov byte[ebx],070h
add ebx,4
dec ecx
jnz boucle_modif_valide

touche_modif_valide:
mov al,5
int 63h
cmp al,82
je modif_annule
cmp al,84
je modif_valide
cmp al,44
je ok_modif_valide
cmp al,100
je ok_modif_valide
jmp touche_modif_valide

ok_modif_valide:
mov ebx,[offset_affichage]
add ebx,[offset_curseur]
mov eax,[valeur]
cmp [ancienne_valeur],eax
je affichage
mov [ebx+zone_tampon],eax
mov byte[secteur_modif],1 ;signale que le secteur a été modifié
jmp affichage



;*****************************
fin:
call sauvegarde
int 60h




;*********************************************
sauvegarde:      ;vérifie que le secteur dans la zt n'as pas été sauvegardé

cmp byte[secteur_modif],0    ;verif si le secteur a été modifié  
je fin_sauvegarde

call raz_ecr
mov edx,msg_fin_modif
mov al,11
mov ah,07h ;couleur
int 63h              ;demande si il faut le sauvegarder

mov bl,0
boucle_fin_modif:
mov al,13
mov bh,7 ;couleur
mov cl,1
mov ch,2
int 63h

cmp bl,0
je ok_sauvegarde
cmp bl,1
je fin_sauvegarde
jmp boucle_fin_modif



ok_sauvegarde:

;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


fin_sauvegarde:
mov byte[secteur_modif],0
ret








;***********************
erreur_lecture:
cmp eax,0
je fin_erreur_lecture

pushad
call raz_ecr
mov edx,msg_erreur_lecture
mov al,11
mov ah,07h ;couleur
int 63h              ;demande si il faut réessayer ou quitter

mov bl,0
boucle_erreur_lecture:
mov al,13
mov bh,7 ;couleur
mov cl,1
mov ch,3
int 63h

cmp bl,0
je erreur_lecture_retry
cmp bl,1
je erreur_lecture_menu
jmp boucle_erreur_lecture

erreur_lecture_retry:
popad
mov eax,1
ret

erreur_lecture_menu:
popad
mov eax,2
ret

fin_erreur_lecture:
ret


;**********************
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



;**************************
souris1:
call ajuste_souris
jc touche_boucle
jmp affichage


souris2:
call ajuste_souris
jc touche_boucle
jmp modifdata



ajuste_souris:
shr ebx,3
shr ecx,4

mov eax,[resyt]
sub eax,2
cmp ecx,2
jb ajuste_souris_non
cmp ecx,eax
ja ajuste_souris_non
sub ecx,2

cmp ebx,14
jb ajuste_souris_non
cmp ebx,62
jb ajuste_souris1
cmp ebx,63
jb ajuste_souris_non
cmp ebx,79
ja ajuste_souris_non

sub ebx,63
jmp ajuste_souris2

ajuste_souris1:
sub ebx,14
mov eax,ebx
xor edx,edx
mov ebx,3
div ebx
mov ebx,eax
cmp edx,2
je ajuste_souris_non


ajuste_souris2:
shl ecx,4
add ebx,ecx
mov [offset_curseur],ebx
clc
ret

ajuste_souris_non:
stc
ret



;**************************
maj_modif:
call raz_ecr
mov edx,msg_modif
mov al,11
mov ah,07h ;couleur
int 63h

mov al,102
mov ecx,[valeur]
and ecx,0FFh
mov edx,deci8b
int 61h

mov al,102
mov ecx,[valeur]
and ecx,0FFFFh
mov edx,deci16b
int 61h

mov al,102
mov ecx,[valeur]
mov edx,deci32b
int 61h

mov al,105
mov ecx,[valeur]
and ecx,0FFh
mov edx,hexa8b
int 61h

mov al,104
mov ecx,[valeur]
and ecx,0FFFFh
mov edx,hexa16b
int 61h

mov al,103
mov ecx,[valeur]
mov edx,hexa32b
int 61h

mov ebx,26
mov ecx,0
mov edx,deci8b
mov al,10
mov ah,07h ;couleur
int 63h

mov ebx,26
mov ecx,1
mov edx,deci16b
mov al,10
mov ah,07h ;couleur
int 63h

mov ebx,26
mov ecx,2
mov edx,deci32b
mov al,10
mov ah,07h ;couleur
int 63h

mov ebx,26
mov ecx,3
mov edx,hexa8b
mov al,10
mov ah,07h ;couleur
int 63h

mov ebx,26
mov ecx,4
mov edx,hexa16b
mov al,10
mov ah,07h ;couleur
int 63h

mov ebx,26
mov ecx,5
mov edx,hexa32b
mov al,10
mov ah,07h ;couleur
int 63h
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

saisienum:
dd 0,0,0,0


petite_zt:
dd 0,0,0,0,0,0,0,0   ;32 octets

num_disque:
db 0
num_secteur:
dd 0,0
decalage:
db 0

num_fichier:
dd 0
taille_fichier:
dd 0,0

;num_disque_present:
;db 0
;num_secteur_present:
;dd 0,0
adresse_base:
dd 0,0


valeur:
dd 0
ancienne_valeur:
dd 0
secteur_modif:
db 0



offset_zt:
dd 0,0



masque_affichage:
dd 0,0
affichage_adresse:
dd 0,0

offset_affichage:
dd 0
offset_curseur:
dd 0
max_affichable:
dd 0



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

msg_choix_disque1:
db "choisissez le disque auquel vous souhaitez accèder:",13
db "disquette",13,0

msg_choix_disque2:
db " ",0

msg_choix_disque3:
db "kilo-octets"

msg_choix_disque4:
db 13,0

msg_choix_fichier:
db "entrez le nom du fichier que vous voulez ouvrir:",0


msg_ligne_haut1:
db "EDH éditeur Hexadécimal                                                        ",13
db "     ADRESSE  x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 xA xB xC xD xE xF  0123456789ABCDEF",0


msg_ligne_haut2:
db "secteur:",0

ligne:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

msg_ligne_bas1:
db 13,"F9=aide    valeur décimal 8bits:",0
msg_ligne_bas2:
db "     16bits:",0
msg_ligne_bas3:
db "     32bits:",0




msg_menu:
db "EDH éditeur Hexadécimal",13
db "ouvrir un disque",13
db "ouvrir un fichier",13
db "quitter",13
db 0

msg_choix_secteur:
db "entrez le numéros du secteur que vous souhaitez éditer:",0

msg_choix_adresse:
db "entrez l'adresse que vous souhaitez éditer:",0


msg_aide:
db "echap=quitter le programme",13
db "F1=menu",13
db "F2=sauvegarder changement",13
db "F3=rechercher valeur",13
db "F4=selectionner adresse/secteur",13
db "fleche directionnelles=mouvement du curseur",13
db "appuyez sur une touche pour effacer cet aide",0

msg_modif:
db "valeur     décimal  8bits:",13
db "valeur     décimal 16bits:",13
db "valeur     décimal 24bits:",13
db "valeur hexadécimal  8bits:",13
db "valeur hexadécimal 16bits:",13
db "valeur hexadécimal 32bits:",13
db 13
db "annuler modification",13
db "valider modification",13,0

msg_encours_modif:
db "vous avez effectué des modifications, voulez vous:",13
db "sauvegarder et continuer",13
db "ignorer les modifications et continuer",13
db 0

msg_fin_modif:
db "vous avez effectué des modifications, voulez vous:",13
db "sauvegarder et continuer",13
db "ignorer les modifications et continuer",13
db 0

msg_erreur_lecture:
db "erreur de lecture, voulez vous:",13
db "réessayer",13
db "annuler et revenir au menu",13
db 0

msg_erreur_ecriture:
db "erreur d'écriture, voulez vous:",13
db "réessayer",13
db "annuler et revenir au menu",13
db 0



nom_fichier:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 

zone_tampon:



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
