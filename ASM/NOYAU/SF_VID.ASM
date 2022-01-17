sf_vid_asm:
;fonction console 
;0=création console
;1=suppression console
;2=obtenir information ecran
;3=change la console affiché

;5=obtient le caractère+touche de la fifo de reception clavier
;6=aquisition d'une chaine de caractère validé par entrée
;7=demande la mise a jour complete de l'écran
;8=demande la mise a jour partielle de l'écran

;10=ecrire une chaine asciiz a une position défini
;11=ecrire une chaine a la position du curseur
;12=definir la position du curseur
;13=systeme de choix par menu
;14=barre de progression mode texte

;21=dessine un pixel a la postion x y avec une couleur prédéterminé
;22=dessiner un carré de couleur avec une couleur prédéterminé
;23=dessiner un segment avec une couleur prédéterminé
;24=dessiner un disque avec une couleur prédéterminé
;25=ecrire une chaine a la position x y
;26=ecrire une chaine a la position x y suivant une largeur maximale
;27=ecrire une image a la position x y 

;50=crée une image vide
;51=lit les carac d'un fichier image
;52=lit l'image d'un fichier image
;53=déplace une image ave réadaptation de la taille
;54=déplace un fragment d'image
;55=insère une image dans une autre



cmp al,0
je sfv_ouvre_console
cmp al,1
je sfv_ferme_console
cmp al,2
je sfv_info_ecran
cmp al,3
je sfv_choix_console

cmp al,5
je sfv_obt_clav
cmp al,6
je sfv_aqui_chaine
cmp al,7
je sfv_majecr
cmp al,8
je sfv_majecr_part


cmp al,10
je sfv_chaine_pos
cmp al,11
je sfv_chaine_cur
cmp al,12
je sfv_place_cur
cmp al,13
je sfv_menu
cmp al,14
je sfv_barre


cmp al,21
je sfv_dessine_pix
cmp al,22
je sfv_dessine_rec
cmp al,23
je sfv_dessine_seg
cmp al,24
je sfv_dessine_disq
cmp al,25
je sfv_chaine_pix
cmp al,26
je sfv_chaine_pix2
cmp al,27
je sfv_aff_img


cmp al,50
je sfv_cre_img
cmp al,51
je sfv_carac_image
cmp al,52
je sfv_lire_image
cmp al,53
je sfv_chgtaille
cmp al,54
je sfv_lit_frag
cmp al,55
je sfv_ecrit_frag


mov eax,cer_parami
iret

;*******************************************************************************************
sfv_ouvre_console:    ;ouvre une nouvelle console dans le systeme dx=segment de la mémoire utilisé pour la console ah=options
push ebx
push ecx
push edx
push ds
push es
push fs

mov bx,seldat
mov fs,bx
mov bx,selramh
mov es,bx

mov bl,ah
and bl,0Fh
test bl,3
mov eax,cer_parami
jz fin_sfv_ouvre_console

test bl,10b          ;vérifie que l'on est en mode graphique si on demande un écran graphique
jz pasmodegraf_sfv_ouvre_console 
fs
cmp byte[bitpp],0
jne pasmodegraf_sfv_ouvre_console 
mov eax,cer_eabs
jmp fin_sfv_ouvre_console 
pasmodegraf_sfv_ouvre_console:

mov ecx,100 ;redimensionne le segment
mov al,8
int 61h
cmp eax,0
jne fin_sfv_ouvre_console

mov ds,dx
mov [at_console],bl

xor eax,eax       ;calcule la taille des différentes zones
bt word[at_console],0
jnc ig_texte_sfv_ouvre_console
xor ecx,ecx
xor edx,edx
fs
mov ax,[resxt]
fs
mov cx,[resyt]

fs
cmp byte[bitpp],0
je noaj_ouvre_console
fs
test word[resy],0Fh ;test si on a pas un multiple de 16 en resolution verticale
jz noaj_ouvre_console
inc cx             ;si oui rajoute une ligne de texte
noaj_ouvre_console:

mul ecx
shl eax,2 
ig_texte_sfv_ouvre_console:   
mov [to_texte],eax     ;calcul de la taille occupé par la zone texte

xor eax,eax
bt word[at_console],1
jnc ig_graf_sfv_ouvre_console
xor ecx,ecx
xor edx,edx
fs
mov ax,[resy]
fs
mov cx,[octpl]
mul ecx
ig_graf_sfv_ouvre_console:    
mov [to_graf],eax     ;calcul de la taille occupé par la zone image

mov dword[to_curseur],256  ;zone curseur de 256 octets

mov ecx,ad_res_console     ;calcule de l'adresse des zones
mov [ad_texte],ecx
mov [ad_curseur_texte],ecx
add ecx,[to_texte]
mov [ad_graf],ecx
add ecx,[to_graf]
mov [ad_curseur],ecx
add ecx,[to_curseur]

mov dx,ds
mov al,8
int 61h
cmp eax,0
jne fin_sfv_ouvre_console

sti
fs
mov ebx,[ad_tache_exec]
es
mov [ebx+sel_ecranv],ds

fs               ;ecrit les infos de base
mov eax,[resx]
fs
mov ecx,[resxt]
fs
mov edx,[octpl]
mov [resx_ecran],eax
mov [resx_texte],ecx 
mov [octet_ligne],edx 

xor al,al               ;vide l'ecran
mov esi,[ad_texte]
mov ecx,[to_texte]
add ecx,[to_graf]
boucle_sfv_ouvre_console:
mov [esi],al
inc esi
dec ecx
jnz boucle_sfv_ouvre_console


;copie la souris par défaut
mov edi,[ad_curseur]
mov esi,ad_curseur_defaut
push ds
push es
mov ax,seldat
mov cx,ds
mov ds,ax
mov es,cx
mov ecx,256
cld
rep movsb
pop es
pop ds



es                     ;active l'ecran
mov ax,[ebx+id_tache]
fs
mov [id_tache_af],ax
fs
mov [ad_tache_af],ebx
fs
or byte[at_vid],1      ;met a 1 le bit de mise a jour affichage
fs
mov byte[nb_zrc],0    ;efface la zt de reception souris
fs
or byte[at_csl],03h   ;signale que la liste et le journal doit etre mis jour
cli
xor eax,eax

fin_sfv_ouvre_console:
pop fs
pop es
pop ds
pop edx
pop ecx
pop ebx
iret



;*******************************************************************************************
sfv_ferme_console:    ;ferme la console
push ebp
push ds
push es
mov bx,seldat
mov ds,bx
mov bx,selramh
mov es,bx
mov ebp,[ad_tache_exec]
or byte[at_csl],03h      ;signale que la liste et le journal doit etre mis jour
es
mov dword[ebp+sel_ecranv],0
pop es
pop ds
pop ebp
iret

;*******************************************************************************************
sfv_info_ecran:       ;renvoie les information de dimension et de nombre de couleur dans un tableau en ds:edx (40 octets)
push fs
mov ax,seldat
mov fs,ax

xor eax,eax
fs
mov al,[bitpp]
mov [edx],eax
fs
mov ax,[resx]
mov [edx+04h],eax
fs
mov ax,[resy]
mov [edx+08h],eax
fs
mov ax,[resxt]
mov [edx+0Ch],eax
fs
mov ax,[resyt]
mov [edx+10h],eax
fs
mov ax,[xs1]
mov [edx+14h],eax
fs
mov ax,[ys1]
mov [edx+18h],eax
fs
mov ax,[octpl]
mov [edx+24h],eax

pop fs
xor eax,eax
iret





;****************************************************************
sfv_choix_console:
pushad
push ds
push fs
mov ax,selramh
mov ds,ax
mov ax,seldat
mov fs,ax
xor ebx,ebx
cmp dx,0
je sfv_choix_console0

boucle_sfv_choix_console:
cmp byte[ebx+type_dm],"F"
je fin_sfv_choix_console
cmp byte[ebx+type_dm],"T"
jne suite_sfv_choix_console
cmp word[ebx+sel_ecranv],0
je suite_sfv_choix_console
cmp [ebx+id_tache],dx
jne suite_sfv_choix_console

sfv_choix_console0:
fs
mov [id_tache_af],dx
fs
mov [ad_tache_af],ebx
fs
or byte[at_vid],1      ;met a 1 le bit de mise a jour affichage complet
fs
mov byte[nb_zrc],0    ;efface la zt de reception souris
fin_sfv_choix_console:
pop fs
pop ds
popad
xor eax,eax
iret

suite_sfv_choix_console:
mov eax,[ebx+to_tache]
add ebx,eax
jmp boucle_sfv_choix_console



;*******************************************************************************************
sfv_obt_clav:      ;renvoie la touche dans al, les caractère important pressé a ce moment dans ah 
                   ;et le caractère dans ecx ou (si le carctère est superieur a 127, renvoie les coordonné de la souris x=ebx y=ecx)
call fc_obt_clav

iret


fc_obt_clav:
cli
push edx
push esi
push edi
push ds
push es
mov ax,seldat
mov ds,ax
mov es,ax
xor eax,eax          ;est ce que c'est la tache active qui demande la dernière touche?
mov cx,[id_tache_af]
cmp [id_tache_exec],cx
jne nul_obt_clav

cmp byte[nb_zrc],0     ;y'a t'il une touche dans la ZT?
je nul_obt_clav

xor ecx,ecx
mov cl,[nb_zrc]
dec byte[nb_zrc]

mov eax,ecx ;mul ecx par 6
shl ecx,2
shl eax,1
add ecx,eax

mov ax,[zt_rcl] ;code touche et touches importante
mov edx,[zt_rcl+2] ;caractère ou coordonné souris
xor ebx,ebx

mov esi,zt_rcl
mov edi,zt_rcl
add esi,6
cld
rep movsb
mov ecx,edx

cmp al,0F0h
jb fin_obt_clav

mov ebx,ecx
shr ecx,16
and ebx,0FFFFh
and ecx,0FFFFh
jmp fin_obt_clav

nul_obt_clav:
xor eax,eax
xor ebx,ebx
xor ecx,ecx
int 62h

fin_obt_clav:
and eax,0FFFFh
pop es
pop ds
pop edi
pop esi
pop edx
sti
ret


;*******************************************************************************************
sfv_aqui_chaine:       ;aquisition d'une chaine de caractère 
		       ;entrée: ds:edx=adresse ou sera ecrit la chaine (avec chaine de pré remplissage obligatoire) ecx= nombre d'octet max ah=couleur
                       ;sortie: al touche qui a validé la chaine
pushad
push ds
push es
push fs
push eax  ;sauvegarde de la couleur

mov ax,seldat
mov fs,ax
fs
mov ebx,[ad_tache_exec]
mov ax,selramh
mov es,ax
es
mov ax,[ebx+sel_ecranv]
mov es,ax

                     ;test si il n'y as pas de débordement
testdecal_sfv_aqui_chaine:
pushad 
es
mov ebx,[ad_curseur_texte]
shl ecx,2
add ebx,ecx
es
mov eax,[ad_texte]
es
add eax,[to_texte]
cmp ebx,eax
jb pasdecal_sfv_aqui_chaine

;décalage de l'écran vers le haut
push ds

mov cx,es
mov ds,cx
xor esi,esi
fs
mov si,[resxt]
shl esi,2
es
sub [ad_curseur_texte],esi ;décale le curseur
es
mov edi,[ad_texte]
es
mov ecx,[to_texte]
sub ecx,esi
add esi,edi
cld
rep movsb

xor ecx,ecx     ;et efface la dernière ligne
fs
mov cx,[resxt]
es
mov edi,[ad_texte]
es
add edi,[to_texte]
mov eax,ecx
shl eax,2
es
sub edi,eax
xor eax,eax
cld
rep stosd

pop ds
popad
jmp testdecal_sfv_aqui_chaine


pasdecal_sfv_aqui_chaine:

popad

es
mov ebx,[ad_curseur_texte]  ;ebx=position du premier caractère a ecrire
add ecx,edx  ;edx=adresse min 
mov esi,edx  ;esi=pointeur/curseur
mov ebp,ecx ;ebp=adresse max

;recherche le dernier octet utillisé
mov edi,esi
docut_sfv_aqui_chaine:
cmp byte[edi],0
je retfin_sfv_aqui_chaine
inc edi
cmp edi,ebp
jne docut_sfv_aqui_chaine
mov edi,edx                 ;si aucun marqueur de fin de chaine n'as été trouvé, met un marqueur au debut de la zone
mov byte[edi],0
jmp retfin_sfv_aqui_chaine
 

boucle_sfv_aqui_chaine:
push ebx
call fc_obt_clav         
pop ebx
cmp al,0F0h
jae boucle_sfv_aqui_chaine

passouris_sfv_aqui_chaine:
cmp al,01
je fin0_sfv_aqui_chaine
cmp al,44
je fin1_sfv_aqui_chaine
cmp al,100
je fin1_sfv_aqui_chaine
cmp al,82
je fin2_sfv_aqui_chaine
cmp al,84
je fin3_sfv_aqui_chaine

cmp al,79
je suppr_sfv_aqui_chaine
cmp al,30
je back_sfv_aqui_chaine

cmp al,85
je av_sfv_aqui_chaine
cmp al,83
je rc_sfv_aqui_chaine
cmp al,77
je retdebut_sfv_aqui_chaine
cmp al,80
je retfin_sfv_aqui_chaine

test ecx,0FFFFFFE0h
jz boucle_sfv_aqui_chaine

cmp ecx,80h   ;-de 7 bit
jb insert1_sfv_aqui_chaine
cmp ecx,800h  ;-de 11 bits
jb insert2_sfv_aqui_chaine
cmp ecx,10000h  ;-de 16 bits
jb insert3_sfv_aqui_chaine
cmp ecx,200000h   ;-de 21 bits
jb insert4_sfv_aqui_chaine
jmp boucle_sfv_aqui_chaine

insert1_sfv_aqui_chaine:
mov eax,edi
inc eax
cmp eax,ebp
jae boucle_sfv_aqui_chaine     ;verifie que la chaine n'est pas pleine

push ecx
push esi
push edi
push es
mov ax,ds
mov es,ax
mov ecx,edi
sub ecx,esi
inc ecx
mov esi,edi
inc edi
std
rep movsb          ;décale les donnes
pop es
pop edi
pop esi
pop ecx

and ecx,7Fh      ;transformation du caractre
mov [esi],cl     ;crit le caractre

inc edi  ;maj du dernier octet utilisé
inc esi  ;maj de la position curseur
jmp majaf_sfv_aqui_chaine

insert2_sfv_aqui_chaine:
mov eax,edi
add eax,2
cmp eax,ebp
jae boucle_sfv_aqui_chaine     ;verifie que la chaine n'est pas pleine

push ecx
push esi
push edi
push es
mov ax,ds
mov es,ax
mov ecx,edi
sub ecx,esi
inc ecx
mov esi,edi
add edi,2
std
rep movsb          ;décale les donnes
pop es
pop edi
pop esi
pop ecx

mov eax,ecx
and al,3Fh
or al,80h
mov [esi+1],al
shr ecx,6
mov al,cl
and al,01Fh
or al,0C0h
mov [esi],al

add edi,2  ;maj du dernier octet utilisé
add esi,2  ;maj de la position curseur
jmp majaf_sfv_aqui_chaine


insert3_sfv_aqui_chaine:
mov eax,edi
add eax,3
cmp eax,ebp
jae boucle_sfv_aqui_chaine     ;verifie que la chaine n'est pas pleine

push ecx
push esi
push edi
push es
mov ax,ds
mov es,ax
mov ecx,edi
sub ecx,esi
inc ecx
mov esi,edi
add edi,3
std
rep movsb          ;décale les donnes
pop es
pop edi
pop esi
pop ecx

mov eax,ecx
and al,3Fh
or al,80h
mov [esi+2],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [esi+1],al
shr ecx,6
mov al,cl
and al,0Fh
or al,0E0h
mov [esi],al

add edi,3  ;maj du dernier octet utilisé
add esi,3  ;maj de la position curseur
jmp majaf_sfv_aqui_chaine

insert4_sfv_aqui_chaine:
mov eax,edi
add eax,4
cmp eax,ebp
jae boucle_sfv_aqui_chaine     ;verifie que la chaine n'est pas pleine

push ecx
push esi
push edi
push es
mov ax,ds
mov es,ax
mov ecx,edi
sub ecx,esi
inc ecx
mov esi,edi
add edi,4
std
rep movsb          ;décale les donnes
pop es
pop edi
pop esi
pop ecx

mov eax,ecx
and al,3Fh
or al,80h
mov [esi+3],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [esi+2],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [esi+1],al
shr ecx,6
mov al,cl
and al,07h
or al,0F0h
mov [esi],al

add edi,4  ;maj du dernier octet utilisé
add esi,4  ;maj de la position curseur

majaf_sfv_aqui_chaine:
pop ecx
es
test byte[at_console],1
jz majafv_sfv_aqui_chaine

push ebx
push edx

cmp edx,esi
jne boucle_majaft_sfv_aqui_chaine 
es
mov [ad_curseur_texte],ebx

boucle_majaft_sfv_aqui_chaine:
call lireutf8

cmp eax,0
je vide_majaft_sfv_aqui_chaine
es
mov [ebx],eax
es
mov [ebx+3],ch
add ebx,4

cmp edx,esi
jne boucle_majaft_sfv_aqui_chaine 
es
mov [ad_curseur_texte],ebx
jmp boucle_majaft_sfv_aqui_chaine

vide_majaft_sfv_aqui_chaine:
es
mov dword[ebx],20h   ;caractère espace
es
mov [ebx+3],ch
add ebx,4
inc edx
cmp edx,ebp
jbe vide_majaft_sfv_aqui_chaine

pop edx
pop ebx
push ecx
call sigmajv
jmp boucle_sfv_aqui_chaine


majafv_sfv_aqui_chaine:
;????????????????????????????????????????????????????????????????????

;call place_carac       ;ecrit le caractère en eax a la position de x=ebx y=ecx dl=couleur(256)
jmp boucle_sfv_aqui_chaine


av_sfv_aqui_chaine:
cmp byte[esi],0
je boucle_sfv_aqui_chaine
inc esi
mov ah,[esi]
and ah,11000000b
cmp ah,80h
je av_sfv_aqui_chaine
jmp majaf_sfv_aqui_chaine

rc_sfv_aqui_chaine:
cmp esi,edx
je boucle_sfv_aqui_chaine
dec esi
mov ah,[esi]
and ah,11000000b
cmp ah,80h
je rc_sfv_aqui_chaine
jmp majaf_sfv_aqui_chaine

retdebut_sfv_aqui_chaine:
mov esi,edx
jmp majaf_sfv_aqui_chaine

retfin_sfv_aqui_chaine:
mov esi,edi
jmp majaf_sfv_aqui_chaine

back_sfv_aqui_chaine:
cmp esi,edx
je boucle_sfv_aqui_chaine
dec esi
mov ah,[esi]
and ah,11000000b
cmp ah,80h
je back_sfv_aqui_chaine


suppr_sfv_aqui_chaine:
cmp esi,edi
je boucle_sfv_aqui_chaine
push ecx
push esi
push edi
push es
mov ax,ds
mov es,ax
mov ecx,edi
sub ecx,esi
inc ecx
mov edi,esi
inc esi
cld
rep movsb          ;décale les donnes
pop es
pop edi
pop esi
pop ecx

dec edi
mov ah,[esi]
and ah,11000000b
cmp ah,80h
je suppr_sfv_aqui_chaine
jmp majaf_sfv_aqui_chaine


fin0_sfv_aqui_chaine:
pop ecx
call fin_sfv_aqui_chaine
pop fs
pop es
pop ds
popad
mov eax,01
iret

fin1_sfv_aqui_chaine:
pop ecx
call fin_sfv_aqui_chaine
pop fs
pop es
pop ds
popad
mov eax,44
iret

fin2_sfv_aqui_chaine:
pop ecx
call fin_sfv_aqui_chaine
pop fs
pop es
pop ds
popad
mov eax,82
iret

fin3_sfv_aqui_chaine:
pop ecx
call fin_sfv_aqui_chaine
pop fs
pop es
pop ds
popad
mov eax,84
iret


fin_sfv_aqui_chaine:
es
mov [ad_curseur_texte],ebx
ret

;*******************************************************************************************
sfv_chaine_pos:       ;ecrit la chaine de caractère utf8z en ds:edx a partir de la position x=ebx y=ecx ah=couleur
push ebx
push ecx
push edx
push esi
push fs
push es
push ds

push eax
push edx
mov ax,seldat
mov fs,ax
xor esi,esi
fs
mov edx,[ad_tache_exec]
fs
mov si,[resxt]

mov ax,selramh
mov es,ax
es
mov ax,[edx+sel_ecranv]
mov es,ax


mov eax,esi
xor edx,edx
mul ecx
add ebx,eax
shl ebx,2    
es
add ebx,[ad_texte]  ;ebx=position du premier caractère a ecrire
pop edx
pop ecx

boucle_sfv_chaine_pos:
call lireutf8
cmp eax,0
je fin_sfv_chaine_pos
cmp eax,13
jne ok_sfv_chaine_pos

push ecx
push edx
es                    ;va au debut de la ligne suivante
sub ebx,[ad_texte]
shr ebx,2   
xor edx,edx 
mov eax,ebx
mov ecx,esi
div ecx
inc eax
xor edx,edx
mul ecx
mov ebx,eax
shl ebx,2
es
add ebx,[ad_texte]  
pop edx
pop ecx
jmp boucle_sfv_chaine_pos


ok_sfv_chaine_pos:
es
mov [ebx],eax
es
mov [ebx+3],ch
add ebx,4
jmp boucle_sfv_chaine_pos

fin_sfv_chaine_pos:
call sigmajv
pop ds
pop es
pop fs
pop esi
pop edx
pop ecx
pop ebx
xor eax,eax
iret

;*******************************************************************************************
sfv_chaine_cur:       ;ecrit la chaine de caractère utf8z en ds:edx a partir de la position actuel du curseur ah=couleur 

pushad
push ds
push es
push fs

mov ch,ah
mov ax,seldat
mov fs,ax

fs
mov ebx,[ad_tache_exec]
mov ax,selramh
mov es,ax
es
mov ax,[ebx+sel_ecranv]
mov es,ax

es
mov ebx,[ad_curseur_texte]  ;ebx=position du premier caractère a ecrire
es
mov edi,[ad_texte]
es
add edi,[to_texte]   ;edi=adresse max de la zone texte
sub edi,4

boucle_sfv_chaine_cur:
call lireutf8
cmp eax,0
je fin_sfv_chaine_cur
cmp eax,13
jne ok_sfv_chaine_cur

push ecx
push edx
es                    ;va au debut de la ligne suivante
sub ebx,[ad_texte]
shr ebx,2   
xor edx,edx 
mov eax,ebx
xor ecx,ecx
fs
mov cx,[resxt]
div ecx
inc eax
xor edx,edx
mul ecx
mov ebx,eax
shl ebx,2
es
add ebx,[ad_texte]  
pop edx
pop ecx
jmp suite_sfv_chaine_cur


ok_sfv_chaine_cur:
es
mov [ebx],eax
es
mov [ebx+3],ch
add ebx,4
suite_sfv_chaine_cur:
cmp ebx,edi
jbe boucle_sfv_chaine_cur

;décale le texte vers le haut si le curseur déborde en bas de l'écran
push ecx
push esi
push edi
push ds

mov cx,es
mov ds,cx
xor esi,esi
fs
mov si,[resxt]
shl esi,2
sub ebx,esi
es
mov edi,[ad_texte]
es
mov ecx,[to_texte]
sub ecx,esi
add esi,edi
rep movsb

xor ecx,ecx     ;et efface la dernière ligne
fs
mov cx,[resxt]
es
mov edi,[ad_texte]
es
add edi,[to_texte]
mov eax,ecx
shl eax,2
es
sub edi,eax
xor eax,eax
rep stosd

pop ds
pop edi
pop esi
pop ecx
jmp suite_sfv_chaine_cur

fin_sfv_chaine_cur:
es                    ;enregistrement de la nouvelle position du curseur
mov [ad_curseur_texte],ebx
call sigmajv
pop fs
pop es
pop ds
popad
xor eax,eax
iret

;*******************************************************************************************
sfv_place_cur:        ;place le curseur a la position x=ebx y=ecx

push edx
push ds
push es
push fs
mov ax,seldat
mov fs,ax
fs
mov edx,[ad_tache_exec]
mov ax,selramh
mov ds,ax
mov ax,[edx+sel_ecranv]
cmp ax,0
je err_place_cur
mov es,ax

xor eax,eax
xor edx,edx
fs
mov ax,[resxt]
mul ecx
add ebx,eax

shl ebx,2
es
add ebx,[ad_texte]
es
mov [ad_curseur_texte],ebx
call sigmajv
pop fs
pop es
pop ds
pop edx
xor eax,eax
iret

err_place_cur:
pop fs
pop es
pop ds
pop edx
mov eax,cer_eabs 
iret



;*******************************************************************************************
sfv_menu:       ;met en surbrillance certaine ligne pour faire un choix par menu
		;entrée cl=première ligne du menu ch=nombre de ligne  bh=couleur de base (3bits) bl=ligne preselectionné 
                ;retour: bl=ligne selectionné bh=touche qui as validé

push ecx
push edx
push ebp
push esi
push edi
push ds
push fs

mov ax,seldat
mov fs,ax
fs
mov edx,[ad_tache_exec]
xor edi,edi
fs
mov di,[resxt]
shl edi,2
mov ax,selramh
mov ds,ax
mov ax,[edx+sel_ecranv]
cmp ax,0
je sfv_menu_err
mov ds,ax

cmp ch,0
je sfv_menu_err
dec ch
add ch,cl      ;cl=ligne min   ch=ligne max
mov al,cl
add al,bl
mov ah,bh

sfv_menu_maj:
push eax
push ecx
push edi

push eax
push ecx
push ecx

and eax,0FFh
mov ecx,edi
xor edx,edx
mul ecx
mov esi,eax    ;esi=début ligne

pop ecx
mov cl,ch
and ecx,0FFh
mov eax,edi
xor edx,edx
mul ecx
add eax,edi
mov ebp,eax   ;ebp=fin

pop ecx
and ecx,0FFh
mov eax,edi
xor edx,edx
mul ecx
mov ebx,eax   ;ebx=début 

add edi,esi   ;edi=fin ligne
mov eax,[ad_texte]
add eax,3
add ebx,eax
add ebp,eax
add esi,eax
add edi,eax

pop eax
and ah,07h
mov al,ah
shl ah,4

boucle_menu_maj:
cmp ebx,esi
jb sfv_menu_maj_ligne
cmp ebx,edi
jae sfv_menu_maj_ligne
mov [ebx],ah
jmp sfv_menu_maj_autres 

sfv_menu_maj_ligne:
mov [ebx],al
sfv_menu_maj_autres:
add ebx,4
cmp ebx,ebp
jne boucle_menu_maj
fs
or byte[at_vid],1

pop edi
pop ecx
pop eax


sfv_menu_clavier:
push eax
push ebx
push ecx
call fc_obt_clav
cmp al,0F0h
jne sfv_menu_ignore_souris
shr ecx,4
mov edx,ecx
pop ecx
push ecx
cmp dl,cl
jb sfv_menu_ignore_souris 
cmp dl,ch
ja sfv_menu_ignore_souris 
pop ecx
pop ebx
pop eax
mov al,dl
mov dl,44
jmp sfv_menu_validation

sfv_menu_ignore_souris:
mov dl,al
pop ecx
pop ebx
pop eax

cmp dl,82
je sfv_menu_moins
cmp dl,84
je sfv_menu_plus
cmp dl,44
je sfv_menu_validation
cmp dl,100
je sfv_menu_validation
cmp dl,78
je sfv_menu_validation
cmp dl,81
je sfv_menu_validation
cmp dl,01
je sfv_menu_validation
jmp sfv_menu_clavier



sfv_menu_moins:
cmp al,cl
je sfv_menu_moinp
dec al
jmp sfv_menu_maj
sfv_menu_moinp:
mov al,ch
jmp sfv_menu_maj


sfv_menu_plus:
cmp al,ch
je sfv_menu_plusm
inc al
jmp sfv_menu_maj
sfv_menu_plusm:
mov al,cl
jmp sfv_menu_maj



sfv_menu_validation:
push eax
push ecx
push edx

push eax
push ecx

mov cl,ch
and ecx,0FFh
mov eax,edi
xor edx,edx
mul ecx
add eax,edi
mov ebp,eax   ;ebp=fin

pop ecx
and ecx,0FFh
mov eax,edi
xor edx,edx
mul ecx
mov ebx,eax   ;ebx=début 

add edi,esi   ;edi=fin ligne
mov eax,[ad_texte]
add eax,3
add ebx,eax
add ebp,eax
add esi,eax
add edi,eax

pop eax
and ah,07h
mov al,ah
shl ah,4


boucle_menu_entree:
mov [ebx],al
add ebx,4
cmp ebx,ebp
jne boucle_menu_entree
fs
or byte[at_vid],1

pop edx
pop ecx
pop eax

mov bl,al
sub bl,cl
mov bh,dl


pop fs
pop ds
pop edi
pop esi
pop ebp
pop edx
pop ecx
xor eax,eax
iret


sfv_menu_err:
pop fs
pop ds
pop edi
pop esi
pop ebp
pop edx
pop ecx
mov eax,cer_eabs
xor ebx,ebx 
iret





;******************************************************************************************
sfv_barre:
;esi=progression
;edi=total
;ebx=x
;ecx=y
;edx=nombre de carac

pushad
push ds

push edx
mov ax,seldat
mov ds,ax

;determination position debut
xor eax,eax
xor edx,edx
mov ax,[resxt]
shl ebx,2
shl eax,2
mul ecx
add ebx,eax

mov edx,[ad_tache_exec]
mov ax,selramh
mov ds,ax
mov ax,[edx+sel_ecranv]
pop ecx
cmp ax,0
je sfv_barre_err1
mov ds,ax
add ebx,[ad_texte]

cmp ecx,4
jbe sfv_barre_err2
sub ecx,4
push edi
push esi

;calcul intervalles
push ecx
xor edx,edx
mov eax,esi
mul ecx
mov ecx,edi
div ecx
pop ecx
mov esi,eax
mov edi,ecx
shl esi,2
shl edi,2
add esi,ebx
add edi,ebx


;affiche progression
cmp ebx,esi
je ignore_boucle1_sfv_barre
boucle1_sfv_barre:
mov dword[ebx],070000020h
add ebx,4
cmp ebx,esi
jne boucle1_sfv_barre
ignore_boucle1_sfv_barre:

cmp ebx,edi
je ignore_boucle2_sfv_barre
boucle2_sfv_barre:
mov dword[ebx],07000020h
add ebx,4
cmp ebx,edi
jne boucle2_sfv_barre
ignore_boucle2_sfv_barre:

;calcul pourcentage
pop eax
xor edx,edx
mov ecx,100
mul ecx
pop ecx
div ecx

;affiche le pourcentage
mov dword[ebx],07000020h
mov dword[ebx+4],07000020h
mov ecx,10
xor edx,edx
div ecx
add edx,07000030h
mov [ebx+8],edx
cmp eax,0
je fin_sfv_barre
xor edx,edx
div ecx
add edx,07000030h
mov [ebx+4],edx
cmp eax,0
je fin_sfv_barre
xor edx,edx
div ecx
add edx,07000030h
mov [ebx],edx

fin_sfv_barre:
mov dword[ebx+12],07000025h

mov ax,seldat
mov ds,ax
or byte[at_vid],1

pop ds
popad
xor eax,eax
iret

sfv_barre_err1:
pop ds
popad
mov eax,cer_eabs
iret


sfv_barre_err2:
pop ds
popad
mov eax,cer_parami
iret

;*******************************************************************************************
sfv_majecr:     ;effectue la mise a jour complete de l'ecran
push ds
mov ax,seldat
mov ds,ax
mov ax,[id_tache_exec]
cmp ax,[id_tache_af]
jne fin_sfv_majecr    ;on ne demande pas de mise a jour ecran si on est pas la tache affiché
or byte[at_vid],1
fin_sfv_majecr:
xor eax,eax
pop ds
iret


;*********************
sfv_majecr_part:     ;effectue la mise a jour partielle de l'ecran
		     ;ebx,ecx=coordonnée coin sup gauche
 		     ;esi,edi=coordonné coin inf droite

push ds
mov ax,seldat
mov ds,ax
mov ax,[id_tache_exec]
cmp ax,[id_tache_af]
jne fin_sfv_majecr    ;on ne demande pas de mise a jour ecran si on est pas la tache affiché
or byte[at_vid],2
mov dword[majv_xdeb],ebx
mov dword[majv_ydeb],ecx
mov dword[majv_xfin],esi
mov dword[majv_yfin],edi

xor eax,eax
pop ds
iret



sigmajv:
push eax
es
test byte[at_console],08h
jnz fin_sigmajv
fs
mov ax,[id_tache_exec]
fs
cmp ax,[id_tache_af]
jne fin_sigmajv     ;on ne demande pas de mise a jour ecran si on est pas la tache affiché
fs
or byte[at_vid],1

fin_sigmajv:
pop eax
ret


;*******************************************************************************************
sfv_dessine_pix:     ;dessine un segment x0=bx y0=cx edx=couleur ah=bit par pixel de la couleur
pushad
push es
push fs

;initialise les selecteurs de segments
push eax
push ebx
mov bx,seldat
mov fs,bx
mov bx,selramh
mov es,bx
fs
mov ebx,[ad_tache_exec]
es
mov ax,[ebx+sel_ecranv]
mov es,ax
pop ebx      ;fs=seldat es=ecran virtuelle
pop eax
call conv_univ

call place_pix

fin_sfv_dessine_pix:
call sigmajv
pop fs
pop es
popad
xor eax,eax
iret



place_pix:
;verifie que les coordonnées de départ sont bien dans l'image existante
push eax
push ebx
push ecx
push edx
fs
cmp [resx],bx
jbe fin_place_pix
fs
cmp [resy],cx
jbe fin_place_pix

;calcul de l'adresse du pixel
push edx
xor eax,eax
fs
mov ax,[octpp]
xor edx,edx
mul ebx
mov ebx,eax

xor eax,eax
fs
mov ax,[octpl]
xor edx,edx
mul ecx
add ebx,eax
es
add ebx,[ad_graf]
pop edx

fs
cmp byte[bitpp],8
je place_pix_8
fs
cmp byte[bitpp],15
je place_pix_16
fs
cmp byte[bitpp],16
je place_pix_16
fs
cmp byte[bitpp],24
je place_pix_24
fs
cmp byte[bitpp],32
je place_pix_24
fin_place_pix:
pop edx
pop ecx
pop ebx
pop eax
ret

place_pix_8:
es
mov [ebx],dl
jmp fin_place_pix

place_pix_16:
es
mov [ebx],dx
jmp fin_place_pix

place_pix_24:
es
mov [ebx],dx
shr edx,16
es
mov [ebx+2],dl
jmp fin_place_pix


;*******************************************************************************************
sfv_dessine_rec:     ;dessine un rectangle x0=bx y0=cx xF=si yF=di edx=couleur ah=bit par pixel de la couleur
pushad
push es
push fs

;initialise les selecteurs de segments
push eax
push ebx
mov bx,seldat
mov fs,bx
mov bx,selramh
mov es,bx
fs
mov ebx,[ad_tache_exec]
es
mov ax,[ebx+sel_ecranv]
mov es,ax
pop ebx      ;fs=seldat es=ecran virtuelle
pop eax
call conv_univ

;ajustement des coordonné du rectangle
test ebx,0FFFF8000h
jnz parami_sfv_dessine_rec
test ecx,0FFFF8000h
jnz parami_sfv_dessine_rec
test esi,0FFFF8000h
jnz parami_sfv_dessine_rec
test edi,0FFFF8000h
jnz parami_sfv_dessine_rec

cmp ebx,esi
jb ajx_sfv_dessine_rec
xchg ebx,esi
ajx_sfv_dessine_rec:

cmp ecx,edi
jb ajy_sfv_dessine_rec
xchg ecx,edi
ajy_sfv_dessine_rec:

;verifie que les coordonnées de départ sont bien dans l'image existante
fs
cmp [resx],bx
jbe parami_sfv_dessine_rec
fs
cmp [resy],cx
jbe parami_sfv_dessine_rec


;controle si les marges exterieurs sont comprit dans l'image existante
fs
cmp si,[resx]
jb ajxl_sfv_dessine_rec
fs
mov si,[resx]
dec esi
ajxl_sfv_dessine_rec:
fs
cmp di,[resy]
jb ajyl_sfv_dessine_rec
fs
mov di,[resy]
dec edi
ajyl_sfv_dessine_rec:

;calcul les dimension du rectangle
sub esi,ebx
sub edi,ecx
inc esi
inc edi

;calcul de l'adresse du premier octet de l'image

push edx
xor eax,eax
fs
mov ax,[octpp]
xor edx,edx
mul ebx
mov ebx,eax

xor eax,eax
fs
mov ax,[octpl]
xor edx,edx
mul ecx
add ebx,eax
es
add ebx,[ad_graf]
pop edx

fs
cmp byte[bitpp],4
je boucle_sfv_dessine_rec_4
fs
cmp byte[bitpp],8
je boucle_sfv_dessine_rec_8
fs
cmp byte[bitpp],15
je boucle_sfv_dessine_rec_16
fs
cmp byte[bitpp],16
je boucle_sfv_dessine_rec_16
fs
cmp byte[bitpp],24
je boucle_sfv_dessine_rec_24
fs
cmp byte[bitpp],32
je boucle_sfv_dessine_rec_32
pop fs
pop es
popad
mov eax,cer_nci
iret


boucle_sfv_dessine_rec_4:
push ebx
push esi
boucle2_sfv_dessine_rec_4:
mov al,dl
shl al,4
or al,dl
es
mov [ebx],al
inc ebx
sub esi,2
cmp esi,1
jne suite_sfv_dessine_rec_4
es
and byte[ebx],0F0h
es
or [ebx],dl
pop esi
pop ebx
xor eax,eax
fs
mov ax,[octpl]
add ebx,eax
dec edi
jnz boucle_sfv_dessine_rec_4
jmp fin_sfv_dessine_rec



suite_sfv_dessine_rec_4: 
cmp esi,0
jne boucle2_sfv_dessine_rec_4
pop esi
pop ebx
xor eax,eax
fs
mov ax,[octpl]
add ebx,eax
dec edi
jnz boucle_sfv_dessine_rec_4
jmp fin_sfv_dessine_rec

boucle_sfv_dessine_rec_8:
push ebx
push esi
boucle2_sfv_dessine_rec_8:
es
mov [ebx],dl
inc ebx
dec esi
jnz boucle2_sfv_dessine_rec_8
pop esi
pop ebx
xor eax,eax
fs
mov ax,[octpl]
add ebx,eax
dec edi
jnz boucle_sfv_dessine_rec_8
jmp fin_sfv_dessine_rec

boucle_sfv_dessine_rec_16:
push ebx
push esi
boucle2_sfv_dessine_rec_16:
es
mov [ebx],dx
add ebx,2
dec esi
jnz boucle2_sfv_dessine_rec_16
pop esi
pop ebx
xor eax,eax
fs
mov ax,[octpl]
add ebx,eax
dec edi
jnz boucle_sfv_dessine_rec_16
jmp fin_sfv_dessine_rec

boucle_sfv_dessine_rec_24:
push ebx
push esi
boucle2_sfv_dessine_rec_24:
es
mov [ebx],dx
mov eax,edx
shr eax,16
es
mov [ebx+2],al
add ebx,3
dec esi
jnz boucle2_sfv_dessine_rec_24
pop esi
pop ebx
xor eax,eax
fs
mov ax,[octpl]
add ebx,eax
dec edi
jnz boucle_sfv_dessine_rec_24
jmp fin_sfv_dessine_rec

boucle_sfv_dessine_rec_32:
push ebx
push esi
boucle2_sfv_dessine_rec_32:
es
mov [ebx],edx
add ebx,4
dec esi
jnz boucle2_sfv_dessine_rec_32
pop esi
pop ebx
xor eax,eax
fs
mov ax,[octpl]
add ebx,eax
dec edi
jnz boucle_sfv_dessine_rec_32
;jmp fin_sfv_dessine_rec


fin_sfv_dessine_rec:
call sigmajv
pop fs
pop es
popad
xor eax,eax
iret

parami_sfv_dessine_rec:   ;erreur parametre incorecte
pop fs
pop es
popad
mov eax,cer_parami
iret

;*******************************************************************************************
sfv_dessine_seg:     ;dessine un segment x0=bx y0=cx xF=si yF=di edx=couleur
cmp ebx,esi
je sfv_dessine_rec   ;si c'est une ligne verticale, utilise la fonction de dessin d'un rectangle
cmp ecx,edi
je sfv_dessine_rec   ;si c'est une ligne horizontale, utilise la fonction de dessin d'un rectangle

pushad
push es
push fs


;vérifie si les coordonné sont acceptables
test ebx,0FFFF8000h
jnz parami_sfv_dessine_rec
test ecx,0FFFF8000h
jnz parami_sfv_dessine_rec
test esi,0FFFF8000h
jnz parami_sfv_dessine_rec
test edi,0FFFF8000h
jnz parami_sfv_dessine_rec

;initialise les selecteurs de segments
push eax
push ebx
mov bx,seldat
mov fs,bx
mov bx,selramh
mov es,bx
fs
mov ebx,[ad_tache_exec]
es
mov ax,[ebx+sel_ecranv]
mov es,ax
pop ebx      ;fs=seldat es=ecran virtuelle
pop eax
call conv_univ

cmp ebx,esi          ;corrige pour que esi>ebx
jb aj1_dessine_seg
xchg ebx,esi
xchg ecx,edi
aj1_dessine_seg:

cmp ecx,edi
ja quadrant12
mov eax,esi
sub eax,ebx
mov ebp,edi
sub ebp,ecx
cmp eax,ebp
ja quadrant3_dessine_seg
jmp quadrant4_dessine_seg

quadrant12:
mov eax,esi
sub eax,ebx
mov ebp,ecx
sub ebp,edi
cmp eax,ebp
ja quadrant2_dessine_seg
jmp quadrant1_dessine_seg


quadrant1_dessine_seg:
push ecx
push edx
mov eax,esi
sub eax,ebx
shl eax,16
sub ecx,edi
xor edx,edx
div ecx
mov ebp,eax
pop edx
pop ecx
xor eax,eax

boucle_quadrant1_dessine_seg:
call place_pix
add eax,ebp
test eax,0FFFF0000h
jz suite_quadrant1_dessine_seg 
inc ebx
and eax,0FFFFh
suite_quadrant1_dessine_seg:
dec ecx
cmp ecx,edi
jne boucle_quadrant1_dessine_seg
call place_pix
jmp fin_sfv_dessine_seg

quadrant2_dessine_seg:
push ecx
push edx
mov eax,ecx
sub eax,edi
shl eax,16
mov ecx,esi
sub ecx,ebx
xor edx,edx
div ecx
mov ebp,eax
pop edx
pop ecx
xor eax,eax

boucle_quadrant2_dessine_seg:
call place_pix
add eax,ebp
test eax,0FFFF0000h
jz suite_quadrant2_dessine_seg 
dec ecx
and eax,0FFFFh
suite_quadrant2_dessine_seg:
inc ebx
cmp ebx,esi
jne boucle_quadrant2_dessine_seg
call place_pix
jmp fin_sfv_dessine_seg

quadrant3_dessine_seg:
push ecx
push edx
mov eax,edi
sub eax,ecx
shl eax,16
xor edx,edx
mov ecx,esi
sub ecx,ebx
xor edx,edx
div ecx
mov ebp,eax
pop edx
pop ecx
xor eax,eax

boucle_quadrant3_dessine_seg:
call place_pix
add eax,ebp
test eax,0FFFF0000h
jz suite_quadrant3_dessine_seg 
inc ecx
and eax,0FFFFh
suite_quadrant3_dessine_seg:
inc ebx
cmp ebx,esi
jne boucle_quadrant3_dessine_seg
call place_pix
jmp fin_sfv_dessine_seg

quadrant4_dessine_seg:
push ecx
push edx
push edi
mov eax,esi
sub eax,ebx
shl eax,16
xor edx,edx
sub edi,ecx
mov ecx,edi
xor edx,edx
div ecx
mov ebp,eax
pop edi
pop edx
pop ecx
xor eax,eax


boucle_quadrant4_dessine_seg:
call place_pix
add eax,ebp
test eax,0FFFF0000h
jz suite_quadrant4_dessine_seg 
inc ebx
and eax,0FFFFh
suite_quadrant4_dessine_seg:
inc ecx
cmp ecx,edi
jne boucle_quadrant4_dessine_seg
call place_pix
;jmp fin_sfv_dessine_seg



fin_sfv_dessine_seg:
call sigmajv
pop fs
pop es
popad
xor eax,eax
iret

;*******************************************************************************************
sfv_dessine_disq:   ;dessine un disque plein de rayon esi et a la position x=ebx y=ecx edx=couleur ah=bit par pixel de la couleur 
pushad
push es
push fs

and ebx,07FFFh
and ecx,07FFFh
and esi,07FFh

;initialise les selecteurs de segments
push eax
push ebx
mov bx,seldat
mov fs,bx
mov bx,selramh
mov es,bx
fs
mov ebx,[ad_tache_exec]
es
mov ax,[ebx+sel_ecranv]
mov es,ax
pop ebx      ;fs=seldat es=ecran virtuelle
pop eax
call conv_univ

mov ebp,esi
mov esi,ebx
mov edi,ecx

sub ebx,ebp
sub ecx,ebp

push edx     ;mise au carré de ebp
xor edx,edx
mov eax,ebp
mul ebp
mov ebp,eax
inc ebp
pop edx

boucley_sfv_dessine_disq:
push ebx
bouclex_sfv_dessine_disq:

push edx     ;calcul le carré de la distance dans eax
push ebp
xor edx,edx
mov eax,esi
sub eax,ebx
mul eax
mov ebp,eax
xor edx,edx
mov eax,edi
sub eax,ecx
mul eax
add eax,ebp
pop ebp
pop edx

cmp eax,ebp
ja troploin_sfv_dessine_disq

push ecx    ;place les quatres coté correspondant
push ebx
mov eax,esi
sub eax,ebx
shl eax,1
add ebx,eax
call place_pix

mov eax,edi
sub eax,ecx
shl eax,1
add ecx,eax
call place_pix

pop ebx
call place_pix

pop ecx
call place_pix 

troploin_sfv_dessine_disq:

inc ebx
cmp ebx,esi
jbe bouclex_sfv_dessine_disq

pop ebx
inc ecx
cmp ecx,edi
jbe boucley_sfv_dessine_disq

call sigmajv
pop fs
pop es
popad
xor eax,eax
iret

;*******************************************************************************************
sfv_chaine_pix:   ;ecrit la chaine de caractère utf8z en ds:edx a partir de la position x=ebx y=ecx ah=couleur
pushad
push ds
push es
push fs

push eax
push ebx
push edx
mov ax,seldat
mov fs,ax
xor esi,esi
fs
mov ebx,[ad_tache_exec]
fs
mov si,[resxt]

mov ax,selramh
mov es,ax
es
mov ax,[ebx+sel_ecranv]
mov es,ax

pop edx
pop ebx
pop eax

shr eax,8    ;couleur dans edi
and eax,0FFh
mov edi,eax

boucle_sfv_chaine_pix:
mov eax,ebx
add eax,8
fs
cmp [resx],ax
jbe fin_sfv_chaine_pix
mov eax,ecx
add eax,16
fs
cmp [resy],ax
jbe fin_sfv_chaine_pix
call lireutf8
cmp eax,0
je fin_sfv_chaine_pix
cmp eax,13
je fin_sfv_chaine_pix
push edx
mov edx,edi
call place_carac
pop edx
add ebx,8
jmp boucle_sfv_chaine_pix

fin_sfv_chaine_pix:
call sigmajv
pop fs
pop es
pop ds
popad
xor eax,eax
iret



;*******************************************************************************************
sfv_chaine_pix2:   ;ecrit la chaine de caractère utf8z en ds:edx a partir de la position x=ebx y=ecx ah=couleur esi=nombre de caractère max en largeur
pushad
push ds
push es
push fs

push eax
push ebx
push edx
mov ax,seldat
mov fs,ax
fs
mov ebx,[ad_tache_exec]

mov ax,selramh
mov es,ax
es
mov ax,[ebx+sel_ecranv]
mov es,ax
pop edx
pop ebx
pop eax

shr eax,8    ;couleur dans edi
and eax,0FFh
mov edi,eax

shl esi,3    ;position min et max
add esi,ebx
mov ebp,ebx

mov eax,ebx
add eax,8
fs
cmp [resx],ax
jbe fin_sfv_chaine_pix2

boucle_sfv_chaine_pix2:
mov eax,ecx
add eax,16
fs
cmp [resy],ax
jbe fin_sfv_chaine_pix2
mov eax,ebx
add eax,8
fs
cmp [resx],ax
jbe ig_sfv_chaine_pix2
cmp esi,ebx
jbe ls_sfv_chaine_pix2
call lireutf8
cmp eax,0
je fin_sfv_chaine_pix2
cmp eax,13
je ls_sfv_chaine_pix2
push edx
mov edx,edi
call place_carac
pop edx
add ebx,8
jmp boucle_sfv_chaine_pix2

ls_sfv_chaine_pix2:
add ecx,16
mov ebx,ebp
jmp boucle_sfv_chaine_pix2

ig_sfv_chaine_pix2:
call lireutf8
cmp eax,0
je fin_sfv_chaine_pix2
cmp eax,13
je ls_sfv_chaine_pix2
add ebx,8
jmp boucle_sfv_chaine_pix2


fin_sfv_chaine_pix2:
call sigmajv
pop fs
pop es
pop ds
popad
xor eax,eax
iret








;*************************************
place_carac:          ;ecrit le caractère en eax a la position de x=ebx y=ecx dl=couleur
pushad
push gs
mov si,selramh
mov gs,si

;cherche  la table de caractère correspondant a la page
push eax
and eax,0FFFF00h
mov esi,index_tabcar
boucle_place_carac:
fs
cmp eax,[esi]
je place_carac_tabcar_trouve
add esi,8
cmp esi,index_tabcar+512
jne boucle_place_carac

pop eax     ;charge les caractères par défaut si aucune table de carractès correspond a la page
and eax,0FFFFFFh
call ajuste_carac
fs
mov esi,[index_tabcar+4]
jmp suite_place_carac

place_carac_tabcar_trouve: ;lit la position de la table des caractère correspondant a la page
fs
mov eax,[esi+4]
mov esi,eax
pop eax
and eax,0FFh

suite_place_carac:
shl eax,4
add esi,eax

;calcul de l'adresse du premier octet de l'image
push ebx
push ecx
push edx
xor eax,eax
fs
mov ax,[octpl]
xor edx,edx
mul ecx
mov edi,eax

mov eax,ebx
xor ecx,ecx
fs
mov cx,[octpp]
xor edx,edx
mul ecx
add edi,eax
es
add edi,[ad_graf]
pop edx
pop ecx
pop ebx

fs
cmp byte[bitpp],8
je boucle_place_carac8

mov eax,edx
call conv8_24
mov edx,eax
fs
cmp byte[bitpp],24
je boucle_place_carac24
fs
cmp byte[bitpp],32
je boucle_place_carac32

fs
cmp byte[bitpp],15
je place_carac15
fs
cmp byte[bitpp],16
je place_carac16
jmp fin_place_carac



boucle_place_carac8:
gs
bt word[esi],7
jnc place_carac8_b0
es
mov [edi],dl
place_carac8_b0:
gs
bt word[esi],6
jnc place_carac8_b1
es
mov [edi+1],dl
place_carac8_b1:
gs
bt word[esi],5
jnc place_carac8_b2
es
mov [edi+2],dl
place_carac8_b2:
gs
bt word[esi],4
jnc place_carac8_b3
es
mov [edi+3],dl
place_carac8_b3:
gs
bt word[esi],3
jnc place_carac8_b4
es
mov [edi+4],dl
place_carac8_b4:
gs
bt word[esi],2
jnc place_carac8_b5
es
mov [edi+5],dl
place_carac8_b5:
gs
bt word[esi],1
jnc place_carac8_b6
es
mov [edi+6],dl
place_carac8_b6:
gs
bt word[esi],0
jnc place_carac8_b7
es
mov [edi+7],dl
place_carac8_b7:

xor eax,eax
fs
mov ax,[octpl]
add edi,eax
inc esi
test esi,0Fh
jnz boucle_place_carac8
jmp fin_place_carac 


place_carac15:
call conv24_15
mov edx,eax
jmp boucle_place_carac16

place_carac16:
call conv24_16
mov edx,eax

boucle_place_carac16:
gs
bt word[esi],7
jnc place_carac16_b0
es
mov [edi],dx
place_carac16_b0:
gs
bt word[esi],6
jnc place_carac16_b1
es
mov [edi+2],dx
place_carac16_b1:
gs
bt word[esi],5
jnc place_carac16_b2
es
mov [edi+4],dx
place_carac16_b2:
gs
bt word[esi],4
jnc place_carac16_b3
es
mov [edi+6],dx
place_carac16_b3:
gs
bt word[esi],3
jnc place_carac16_b4
es
mov [edi+8],dx
place_carac16_b4:
gs
bt word[esi],2
jnc place_carac16_b5
es
mov [edi+10],dx
place_carac16_b5:
gs
bt word[esi],1
jnc place_carac16_b6
es
mov [edi+12],dx
place_carac16_b6:
gs
bt word[esi],0
jnc place_carac16_b7
es
mov [edi+14],dx
place_carac16_b7:
fs
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
inc esi
test esi,0Fh
jnz boucle_place_carac16
jmp fin_place_carac 

boucle_place_carac24:
gs
bt word[esi],7
jnc place_carac24_b0
es
mov [edi],edx
place_carac24_b0:
gs
bt word[esi],6
jnc place_carac24_b1
es
mov [edi+3],edx
place_carac24_b1:
gs
bt word[esi],5
jnc place_carac24_b2
es
mov [edi+6],edx
place_carac24_b2:
gs
bt word[esi],4
jnc place_carac24_b3
es
mov [edi+9],edx
place_carac24_b3:
gs
bt word[esi],3
jnc place_carac24_b4
es
mov [edi+12],edx
place_carac24_b4:
gs
bt word[esi],2
jnc place_carac24_b5
es
mov [edi+15],edx
place_carac24_b5:
gs
bt word[esi],1
jnc place_carac24_b6
es
mov [edi+18],edx
place_carac24_b6:
gs
bt word[esi],0
jnc place_carac24_b7
es
mov [edi+21],dx
mov eax,edx
shl eax,16
es
mov [edi+23],al
place_carac24_b7:
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
inc esi
test esi,0Fh
jnz boucle_place_carac24
jmp fin_place_carac 


boucle_place_carac32:
gs
bt word[esi],7
jnc place_carac32_b0
es
mov [edi],edx
place_carac32_b0:
gs
bt word[esi],6
jnc place_carac32_b1
es
mov [edi+4],edx
place_carac32_b1:
gs
bt word[esi],5
jnc place_carac32_b2
es
mov [edi+8],edx
place_carac32_b2:
gs
bt word[esi],4
jnc place_carac32_b3
es
mov [edi+12],edx
place_carac32_b3:
gs
bt word[esi],3
jnc place_carac32_b4
es
mov [edi+16],edx
place_carac32_b4:
gs
bt word[esi],2
jnc place_carac32_b5
es
mov [edi+20],edx
place_carac32_b5:
gs
bt word[esi],1
jnc place_carac32_b6
es
mov [edi+24],edx
place_carac32_b6:
gs
bt word[esi],0
jnc place_carac32_b7
es
mov [edi+28],edx
place_carac32_b7:

xor eax,eax
fs
mov ax,[octpl]
add edi,eax
inc esi
test esi,0Fh
jnz boucle_place_carac32

fin_place_carac:
pop gs
popad
ret





;*******************************************************************************************
sfv_aff_img:       ;ecrit l'image en ds:edx (format BMS) a partir de la position x=bx y=cx
pushad
push es
push fs

;initialise les selecteurs de segments
push ebx
mov bx,seldat
mov fs,bx
mov bx,selramh
mov es,bx
fs
mov ebx,[ad_tache_exec]
es
mov ax,[ebx+sel_ecranv]
mov es,ax
pop ebx      ;fs=seldat es=ecran virtuelle

;met a zéro les MSB des coordonnées
and ebx,07FFFh
and ecx,07FFFh

;verifie que les coordonnées de départ sont bien dans l'image existante
fs
cmp [resx],bx
jb parami_sfv_aff_img
fs
cmp [resy],cx
jb parami_sfv_aff_img


;calcul de l'adresse du premier octet de l'image
push ebx
push ecx
push edx
xor eax,eax
fs
mov ax,[octpl]
xor edx,edx
mul ecx
mov edi,eax

mov eax,ebx
xor ecx,ecx
fs
mov cx,[octpp]
xor edx,edx
mul ecx
add edi,eax
es
add edi,[ad_graf]
pop edx
pop ecx
pop ebx


;calcul du nombre de ligne a afficher (ebp)
xor eax,eax
xor ebp,ebp
fs
mov ax,[resy]
mov bp,[edx+4]
sub eax,ecx     ;eax=pixel entre la position souhaité et le bord de l'écran
cmp ebp,eax
jbe ajy_sfv_aff_img
mov ebp,eax      ;si l'image déborde de l'écran on ne copie que la partie a l'interieur
ajy_sfv_aff_img:



;calcul de la largeur de l'image a copier (ecx)
xor eax,eax
xor ecx,ecx
fs
mov ax,[resx]
mov cx,[edx+2]
sub eax,ebx     ;eax=pixel entre la position souhaité et le bord de l'écran
cmp ecx,eax
jbe ajx_sfv_aff_img
mov ecx,eax      ;si l'image déborde de l'écran on ne copie que la partie a l'interieur
ajx_sfv_aff_img:



;calcul du debut de la zone des données de l'image et du nombre d'octet utilisé par ligne
mov esi,edx
mov edx,[esi+6]
mov al,[esi]
fs
mov ah,[bitpp]
test byte[esi+1],01h
jnz sfv_aff_img_transparence
add esi,14


cmp ax,2020h   ;32->32
je boucle_sfv_aff_img_32_32
cmp al,ah   
je boucle_sfv_aff_img_mc   ;même couleur 

cmp ax,0804h   ;4->8
je boucle_sfv_aff_img_4_8 
cmp ax,0F04h   ;4->15
je boucle_sfv_aff_img_4_15 
cmp ax,1004h   ;4->16
je boucle_sfv_aff_img_4_16  
cmp ax,1804h   ;4->24
je boucle_sfv_aff_img_4_24  
cmp ax,2004h   ;4->32
je boucle_sfv_aff_img_4_32 


cmp ax,0818h   ;24->8
je boucle_sfv_aff_img_24_8
cmp ax,0F18h   ;24->15
je boucle_sfv_aff_img_24_15
cmp ax,1018h   ;24->16
je boucle_sfv_aff_img_24_16
cmp ax,2018h   ;24->32
je boucle_sfv_aff_img_24_32


cmp ax,0820h   ;32->8
je boucle_sfv_aff_img_32_8
cmp ax,0F20h   ;32->15
je boucle_sfv_aff_img_32_15
cmp ax,1020h   ;32->16
je boucle_sfv_aff_img_32_16
cmp ax,1820h   ;32->24
je boucle_sfv_aff_img_32_24


call sigmajv
pop fs
pop es
popad
mov eax,cer_nci
iret

sfv_aff_img_transparence:
add esi,14

;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

call sigmajv
pop fs
pop es
popad
mov eax,cer_nci
iret


;ds:esi= pointeur dans l'image
;es:edi=pointeur dans la zone console
;ecx=nombre de pixel/octet de l'image
;edx=nombre d'octet pour passer d'une ligne a l'autre dans l'image
;ebp=nombre de ligne a afficher


boucle_sfv_aff_img_mc:
push ecx
push edx
push esi
push edi
xor eax,eax
xor edx,edx
fs
mov ax,[octpp]
mul ecx
mov ecx,eax    ;on multiplie ecx par le nombre d'octet par pixel pour avoir le nombre d'octet 
rep movsb
pop edi
pop esi
pop edx
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_mc
jmp fin_sfv_aff_img


boucle_sfv_aff_img_4_8:
push ecx
push esi
push edi

boucle2_sfv_aff_img_4_8:
mov al,[esi]
and al,0Fh
es
mov [edi],al
inc edi
dec ecx
jz finboucle_sfv_aff_img_4_8

mov al,[esi]
and al,0F0h
shr al,4
es
mov [edi],al
inc edi
inc esi
dec ecx
jnz boucle2_sfv_aff_img_4_8

finboucle_sfv_aff_img_4_8:
pop edi
pop esi
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_4_8
jmp fin_sfv_aff_img

boucle_sfv_aff_img_4_15:
push ecx
push esi
push edi

boucle2_sfv_aff_img_4_15:
mov bl,[esi]
and ebx,0Fh
shl ebx,2
fs
mov eax,[ebx+ad_tabcoul]
call conv24_15
es
mov [edi],ax
add edi,2
dec ecx
jz finboucle_sfv_aff_img_4_15

mov bl,[esi]
and ebx,0F0h
shr ebx,2
fs
mov eax,[ebx+ad_tabcoul]
call conv24_15
es
mov [edi],ax
add edi,2
inc esi
dec ecx
jnz boucle2_sfv_aff_img_4_15

finboucle_sfv_aff_img_4_15:
pop edi
pop esi
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_4_15
jmp fin_sfv_aff_img

boucle_sfv_aff_img_4_16:
push ecx
push esi
push edi

boucle2_sfv_aff_img_4_16:
mov bl,[esi]
and ebx,0Fh
shl ebx,2
fs
mov eax,[ebx+ad_tabcoul]
call conv24_16
es
mov [edi],ax
add edi,2
dec ecx
jz finboucle_sfv_aff_img_4_16

mov bl,[esi]
and ebx,0F0h
shr ebx,2
fs
mov eax,[ebx+ad_tabcoul]
call conv24_16
es
mov [edi],ax
add edi,2
inc esi
dec ecx
jnz boucle2_sfv_aff_img_4_16

finboucle_sfv_aff_img_4_16:
pop edi
pop esi
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_4_16
jmp fin_sfv_aff_img

boucle_sfv_aff_img_4_24:
push ecx
push esi
push edi

boucle2_sfv_aff_img_4_24:
mov bl,[esi]
and ebx,0Fh
shl ebx,2
fs
mov eax,[ebx+ad_tabcoul]
es
mov [edi],ax
shr eax,16
es
mov [edi+2],al
add edi,3
dec ecx
jz finboucle_sfv_aff_img_4_24

mov bl,[esi]
and ebx,0F0h
shr ebx,2
fs
mov eax,[ebx+ad_tabcoul]
es
mov [edi],ax
shr eax,16
es
mov [edi+2],al
add edi,3
inc esi
dec ecx
jnz boucle2_sfv_aff_img_4_24

finboucle_sfv_aff_img_4_24:
pop edi
pop esi
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_4_24
jmp fin_sfv_aff_img

boucle_sfv_aff_img_4_32:
push ecx
push esi
push edi

boucle2_sfv_aff_img_4_32:
mov bl,[esi]
and ebx,0Fh
shl ebx,2
fs
mov eax,[ebx+ad_tabcoul]
and eax,0FFFFFFh
es
mov [edi],eax
add edi,4
dec ecx
jz finboucle_sfv_aff_img_4_32

mov bl,[esi]
and ebx,0F0h
shr ebx,2
fs
mov eax,[ebx+ad_tabcoul]
and eax,0FFFFFFh
es
mov [edi],eax
add edi,4
inc esi
dec ecx
jnz boucle2_sfv_aff_img_4_32

finboucle_sfv_aff_img_4_32:
pop edi
pop esi
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_4_32
jmp fin_sfv_aff_img


boucle_sfv_aff_img_24_8:
push ecx
push esi
push edi

boucle2_sfv_aff_img_24_8:
mov al,[esi+2]
shl eax,16
mov ax,[esi]
and eax,0FFFFFFh
call conv24_8
es
mov [edi],al
add esi,3
inc edi
dec ecx
jnz boucle2_sfv_aff_img_24_8

pop edi
pop esi
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_24_8
jmp fin_sfv_aff_img


boucle_sfv_aff_img_24_15:
push ecx
push esi
push edi

boucle2_sfv_aff_img_24_15:
mov al,[esi+2]
shl eax,16
mov ax,[esi]
and eax,0FFFFFFh
call conv24_15
es
mov [edi],ax
add esi,3
add edi,2
dec ecx
jnz boucle2_sfv_aff_img_24_15

pop edi
pop esi
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_24_15
jmp fin_sfv_aff_img


boucle_sfv_aff_img_24_16:
push ecx
push esi
push edi

boucle2_sfv_aff_img_24_16:
mov al,[esi+2]
shl eax,16
mov ax,[esi]
and eax,0FFFFFFh
call conv24_16
es
mov [edi],ax
add esi,3
add edi,2
dec ecx
jnz boucle2_sfv_aff_img_24_16

pop edi
pop esi
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_24_16
jmp fin_sfv_aff_img


boucle_sfv_aff_img_24_32:
push ecx
push esi
push edi

boucle2_sfv_aff_img_24_32:
mov al,[esi+2]
shl eax,16
mov ax,[esi]
and eax,0FFFFFFh
es
mov [edi],eax
add esi,3
add edi,4
dec ecx
jnz boucle2_sfv_aff_img_24_32

pop edi
pop esi
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_24_32
jmp fin_sfv_aff_img


boucle_sfv_aff_img_32_8:
push ecx
push edx
push esi
push edi


boucle2_sfv_aff_img_32_8:
es
mov al,[edi]
call conv8_24
mov edx,eax
mov eax,[esi]
call conv32_24
call conv24_8
es
mov [edi],al
add esi,4
add edi,1
dec ecx
jnz boucle2_sfv_aff_img_32_8

pop edi
pop esi
pop edx
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_32_8
jmp fin_sfv_aff_img



boucle_sfv_aff_img_32_15:
push ecx
push edx
push esi
push edi


boucle2_sfv_aff_img_32_15:
es
mov ax,[edi]
call conv15_24
mov edx,eax
mov eax,[esi]
call conv32_24
call conv24_15
es
mov [edi],ax
add esi,4
add edi,2
dec ecx
jnz boucle2_sfv_aff_img_32_15

pop edi
pop esi
pop edx
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_32_15
jmp fin_sfv_aff_img


boucle_sfv_aff_img_32_16:
push ecx
push edx
push esi
push edi


boucle2_sfv_aff_img_32_16:
es
mov ax,[edi]
call conv16_24
mov edx,eax
mov eax,[esi]
call conv32_24
call conv24_16
es
mov [edi],ax
add esi,4
add edi,2
dec ecx
jnz boucle2_sfv_aff_img_32_16

pop edi
pop esi
pop edx
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_32_16
jmp fin_sfv_aff_img



boucle_sfv_aff_img_32_24:
push ecx
push edx
push esi
push edi

boucle2_sfv_aff_img_32_24:
mov eax,[esi]
es
mov edx,[edi]
call conv32_24
es
mov [edi],ax
shr eax,16
es
mov [edi+2],al
add esi,4
add edi,3
dec ecx
jnz boucle2_sfv_aff_img_32_24

pop edi
pop esi
pop edx
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_32_24
jmp fin_sfv_aff_img


boucle_sfv_aff_img_32_32:
push ecx
push edx
push esi
push edi

boucle2_sfv_aff_img_32_32:
mov eax,[esi]
es
mov edx,[edi]
call conv32_24
es
mov [edi],eax
add esi,4
add edi,4
dec ecx
jnz boucle2_sfv_aff_img_32_32

pop edi
pop esi
pop edx
pop ecx
add esi,edx
xor eax,eax
fs
mov ax,[octpl]
add edi,eax
dec ebp
jnz boucle_sfv_aff_img_32_32



fin_sfv_aff_img:
call sigmajv
pop fs
pop es
popad
xor eax,eax
iret


parami_sfv_aff_img:   ;erreur parametre incorecte
pop fs
pop es
popad
mov eax,cer_parami
iret


;********************************************************
;fonction de conversion de la couleur dans eax, fs doit pointer sur le selecteur de segment des données système


conv8_24:
push ebx
mov ebx,eax
and ebx,0FFh
shl ebx,2
fs
mov eax,[ebx+ad_tabcoul]
pop ebx
ret

conv24_4:
push ebx
push ecx
push edx
push ebp
and eax,0FFFFFFh
mov ebx,16
mov cl,00h
mov bp,0FFFFh
jmp boucle_conv24_8

conv24_8:
push ebx
push ecx
push edx
push ebp
and eax,0FFFFFFh
mov ebx,256
mov bp,0000h
mov cx,0FFFFh


boucle_conv24_8:
xor dx,dx
push eax
fs
cmp eax,[ebx*4+ad_tabcoul-4]
je trouve_conv24_8
fs
sub al,[ebx*4+ad_tabcoul-4]
jae adj1_conv24_8
neg al
adj1_conv24_8:
mov dl,al      ;ecart valeur absolue
jc pastrouve_conv24_8

fs
sub ah,[ebx*4+ad_tabcoul-3]
jae adj2_conv24_8
neg ah
adj2_conv24_8:
add dl,ah
jc pastrouve_conv24_8

shr eax,16
fs
sub al,[ebx*4+ad_tabcoul-2]
jae adj3_conv24_8
neg al
adj3_conv24_8:
add dl,al
jc pastrouve_conv24_8

cmp dx,cx
jae pastrouve_conv24_8
mov cx,dx
mov bp,bx

pastrouve_conv24_8:
pop eax
dec ebx
jnz boucle_conv24_8

mov ax,bp
dec ax
and eax,0FFh
pop ebp
pop edx
pop ecx
pop ebx
ret

trouve_conv24_8:
pop eax
mov al,bl
and eax,0FFh
pop ebp
pop edx
pop ecx
pop ebx
ret

conv24_16:
push ebx
push edx
mov edx,eax
shr edx,8    ;dh=bleu dl=green
and eax,0F8h
shr al,3     
mov bl,dl
and ebx,0FCh
shl ebx,3  
or eax,ebx
mov bl,dh
and ebx,0F8h
shl ebx,8   
or eax,ebx
and eax,0FFFFh
pop edx
pop ebx
ret

conv16_24:
push ebx
push edx
mov edx,eax
xor eax,eax
mov ebx,edx ;rouge
and ebx,1Fh
shl bl,3
or eax,ebx
mov ebx,edx ;vert
and ebx,7E0h
shl ebx,5   ;16-11
or eax,ebx
mov ebx,edx ;bleu
and ebx,0F800h
shl ebx,8   ;24-16
or eax,ebx
pop edx
pop ebx
ret


conv24_15:
push ebx
push edx
mov edx,eax
shr edx,8    ;dh=bleu dl=green
shr al,3     ;0-3
mov bl,dl
and ebx,0F8h
shl ebx,2    ;5-3  
or eax,ebx
mov bl,dh
and ebx,0F8h
shl ebx,7   ;10-3
or eax,ebx
and eax,07FFFh
pop edx
pop ebx
ret

conv15_24:
push ebx
push edx
mov edx,eax
xor eax,eax
mov ebx,edx ;rouge
and ebx,1Fh
shl bl,3   ;8-5
or eax,ebx
mov ebx,edx ;vert
and ebx,3E0h
shl ebx,6   ;16-10
or eax,ebx
mov ebx,edx ;bleu
and ebx,07C00h
shl ebx,9   ;24-15
or eax,ebx
and eax,0FFFFFFh
pop edx
pop ebx
ret


conv32_24:   ;gère la transparence edx=couleur du fond (24bit)
push ebx
push ecx
push edx
push esi
push edi
push ebp
mov esi,edx   ;couleur de fond (24bit)
mov edi,eax   ;couleur de l'image

mov ecx,eax
shr ecx,24    ;coefficient image
mov ebx,0FFh
sub ebx,ecx   ;coefficient fond 

and eax,0FFh
mul ecx
mov ebp,eax
mov eax,esi
and eax,0FFh
mul ebx
add ebp,eax
push ebp      ;calcule couleur Rouge

shr esi,8
shr edi,8
mov eax,edi
and eax,0FFh
mul ecx
mov ebp,eax
mov eax,esi
and eax,0FFh
mul ebx
add ebp,eax
push ebp    ;calcule couleur Verte

shr esi,8
shr edi,8
mov eax,edi
and eax,0FFh
mul ecx
mov ebp,eax
mov eax,esi
and eax,0FFh
mul ebx
add eax,ebp   ;calcule couleur Bleu

              ;réassemble les 3 couleurs
shr eax,8     ;divise par 256
cmp eax,0FFh  ;écrète si la valeur dépasse 255
jbe @f
mov eax,0FFh
@@:
shl eax,8
pop ebx
shr ebx,8
cmp ebx,0FFh
jbe @f
mov ebx,0FFh
@@:
mov al,bl
shl eax,8
pop ebx
shr ebx,8
cmp ebx,0FFh
jbe @f
mov ebx,0FFh
@@:
mov al,bl

pop ebp
pop edi
pop esi
pop edx
pop ecx
pop ebx
ret




;************************************************
conv_univ:    ;convertiseur de couleur en fonction de ah (nombre de bit par couleur en entrée)
	      ;et la resolution actuelle de l'écran. edx contient la couleur
push eax
fs
mov al,[bitpp]

cmp ax,040Fh
je conv_univ_8_15
cmp ax,0410h
je conv_univ_8_16
cmp ax,0418h
je conv_univ_8_24
cmp ax,0420h
je conv_univ_8_24

cmp ax,080Fh
je conv_univ_8_15
cmp ax,0810h
je conv_univ_8_16
cmp ax,0818h
je conv_univ_8_24
cmp ax,0820h
je conv_univ_8_24

cmp ax,0F08h
je conv_univ_15_8
cmp ax,0F04h
je conv_univ_15_8
cmp ax,0F10h
je conv_univ_15_16
cmp ax,0F18h
je conv_univ_15_24
cmp ax,0F20h
je conv_univ_15_24

cmp ax,1008h
je conv_univ_16_8
cmp ax,1004h
je conv_univ_16_8
cmp ax,100Fh
je conv_univ_16_15
cmp ax,1018h
je conv_univ_16_24
cmp ax,1020h
je conv_univ_16_24

cmp ax,1804h
je conv_univ_24_8
cmp ax,1808h
je conv_univ_24_8
cmp ax,180Fh
je conv_univ_24_15
cmp ax,1810h
je conv_univ_24_16


cmp ax,2004h
je conv_univ_24_8
cmp ax,2008h
je conv_univ_24_8
cmp ax,200Fh
je conv_univ_24_15
cmp ax,2010h
je conv_univ_24_16


pop eax
ret

conv_univ_8_15:
mov eax,edx
call conv8_24
call conv24_15
mov edx,eax
pop eax
ret

conv_univ_8_16:
mov eax,edx
call conv8_24
call conv24_16
mov edx,eax
pop eax
ret

conv_univ_8_24:
mov eax,edx
call conv8_24
mov edx,eax
pop eax
ret

conv_univ_15_8:
mov eax,edx
call conv15_24
call conv24_8
mov edx,eax
pop eax
ret

conv_univ_15_16:
mov eax,edx
call conv15_24
call conv24_16
mov edx,eax
pop eax
ret

conv_univ_15_24:
mov eax,edx
call conv15_24
mov edx,eax
pop eax
ret

conv_univ_16_8:
mov eax,edx
call conv16_24
call conv24_8
mov edx,eax
pop eax
ret

conv_univ_16_15:
mov eax,edx
call conv16_24
call conv24_15
mov edx,eax
pop eax
ret

conv_univ_16_24:
mov eax,edx
call conv16_24
mov edx,eax
pop eax
ret

conv_univ_24_8:
mov eax,edx
call conv24_8
mov edx,eax
pop eax
ret

conv_univ_24_15:
mov eax,edx
call conv24_15
mov edx,eax
pop eax
ret

conv_univ_24_16:
mov eax,edx
call conv24_16
mov edx,eax
pop eax
ret






;*************************************************************************************************************
sfv_cre_img:
;ah=nombre de bit par couleur
;ebx=largeur de l'image
;ecx=hauteur de l'image
;edx=couleur de l'image
;ds:edi=position de l'image

test ebx,0FFFF0000h
jnz @f
test ecx,0FFFF0000h
jnz @f
cmp ah,8
je sfv_cre_img8
cmp ah,15
je sfv_cre_img16
cmp ah,16
je sfv_cre_img16
cmp ah,24
je sfv_cre_img24
cmp ah,32
je sfv_cre_img32
@@:
mov eax,cer_parami
iret




sfv_cre_img8:
pushad
;enregistrement parm de base
mov [edi+objimage_bpp],ah
mov byte[edi+objimage_att],0
mov [edi+objimage_x],bx
mov [edi+objimage_y],cx
mov [edi+objimage_ctp],edx
;calcul taille ligne 
add ebx,3
and ebx,0FFFFFFFCh
mov [edi+objimage_opl],ebx

;remplissage de la zone
shr ebx,2
add edi,objimage_dat

and edx,0FFh
mov eax,edx
shl eax,8
or  eax,edx
shl eax,8
or  eax,edx
shl eax,8
or  eax,edx

push eax
xor edx,edx
mov eax,edx
mul ecx
mov ecx,eax
pop eax

push es
mov dx,ds
mov es,dx
cld
rep stosd
pop es

popad
xor eax,eax
iret


sfv_cre_img16:
pushad
;enregistrement parm de base
mov [edi+objimage_bpp],ah
mov byte[edi+objimage_att],0
mov [edi+objimage_x],bx
mov [edi+objimage_y],cx
mov [edi+objimage_ctp],edx
;calcul taille ligne 
shl ebx,1
mov [edi+objimage_opl],ebx

;remplissage de la zone
push edx
xor edx,edx
mov eax,ebx
mul ecx
mov ecx,eax
pop eax
shr ecx,1
add edi,objimage_dat

push es
mov dx,ds
mov es,dx
cld
rep stosw
pop es

popad
xor eax,eax
iret


sfv_cre_img24:
pushad
;enregistrement parm de base
mov [edi+objimage_bpp],ah
mov byte[edi+objimage_att],0
mov [edi+objimage_x],bx
mov [edi+objimage_y],cx
mov [edi+objimage_ctp],edx
;calcul taille ligne 
mov [edi+objimage_opl],ebx
add [edi+objimage_opl],ebx
add [edi+objimage_opl],ebx

;remplissage de la zone
push edx
xor edx,edx
mov eax,ebx
mul ecx
mov ecx,eax
pop eax
add edi,objimage_dat
dec ecx

@@:
mov [edi],eax
add edi,3
dec ecx
jnz @b
mov [edi],ax
shr eax,16
mov [edi+2],al

popad
xor eax,eax
iret



sfv_cre_img32:
pushad
;enregistrement parm de base
mov [edi+objimage_bpp],ah
mov byte[edi+objimage_att],0
mov [edi+objimage_x],bx
mov [edi+objimage_y],cx
mov [edi+objimage_ctp],edx
;calcul taille ligne 
shl ebx,2
mov [edi+objimage_opl],ebx
shr ebx,2

;remplissage de la zone
push edx
xor edx,edx
mov eax,ebx
mul ecx
mov ecx,eax
pop eax
add edi,objimage_dat

push es
mov dx,ds
mov es,dx
cld
rep stosd
pop es

popad
xor eax,eax
iret


;***********************************************
sfv_carac_image:
call sfv_carac_image2
iret

sfv_carac_image2:
push ds
push es
push edi
mov ax,selramh
mov ds,ax
mov es,ax
mov fs,ax
push ebx
mov ecx,20000h
call resmem
mov edx,ebx
pop ebx
jc ermem_sfv_carac_image2
mov word[edx+8],czm_fli


push edx
mov edi,edx
add edi,10h
xor edx,edx
mov edx,0
mov ecx,20000h
mov eax,4
int 64h
pop edx
cmp eax,0
je @f
pop edi
pop es
pop ds
ret
@@:


cmp dword[edx+10h],474E5089h
jne @f
cmp dword[edx+14h],0A1A0A0Dh ;signature PNG
je sfv_carac_image_png 
@@:
mov eax,[edx+10h]
and eax,0FFFFFFh
cmp eax,0FFD8FFh
je sfv_carac_image_jpeg

 
sfv_carac_image_erreur:
mov ebx,edx
call libmem
pop edi
pop es
pop ds
xor ebx,ebx
xor ecx,ecx
xor edx,edx
mov eax,cer_parami
ret



ermem_sfv_carac_image2:
pop edi
pop es
pop ds
xor ebx,ebx
xor ecx,ecx
xor edx,edx
mov eax,cer_pasm
ret


sfv_carac_image_png:
cmp dword[edx+1Ch],"IHDR"
jne sfv_carac_image_erreur
cmp word[edx+2Ah],0    ;méthode de compression et filtrage a zéro
jne sfv_carac_image_erreur

;calcul du nombre de bit par pixel au final
cmp word[edx+28h],610h ;4 canaux 16bit
je sfv_carac_image_png64
cmp word[edx+28h],608h ;4 canaux 8bit
je sfv_carac_image_png32
cmp word[edx+28h],210h ;3 canaux 16bit
je sfv_carac_image_png48
cmp word[edx+28h],208h ;3 canaux 8bit
je sfv_carac_image_png24
cmp word[edx+28h],410h ;2 canal 16bit
je sfv_carac_image_png64
cmp word[edx+28h],408h ;2 canal 8bit
je sfv_carac_image_png32
cmp word[edx+28h],010h ;1 canal 16bit
je sfv_carac_image_png24
cmp word[edx+28h],008h ;1 canal 8bit
je sfv_carac_image_png24
cmp word[edx+28h],004h ;1 canal 4bit
je sfv_carac_image_png24
cmp word[edx+28h],002h ;1 canal 2bit
je sfv_carac_image_png24
cmp word[edx+28h],001h ;1 canal 1bit
je sfv_carac_image_png24
;cmp word[edx+28h],301h ;palette 1bit
;je sfv_carac_image_png24
;cmp word[edx+28h],302h ;palette 2bit
;je sfv_carac_image_png24
;cmp word[edx+28h],304h ;palette 4bit
;je sfv_carac_image_png24
;cmp word[edx+28h],308h ;palette 8bit
;je sfv_carac_image_png24
jmp sfv_carac_image_erreur

sfv_carac_image_png64:
mov al,64
jmp @f
sfv_carac_image_png48:
mov al,48
jmp @f
sfv_carac_image_png32:
mov al,32
jmp @f
sfv_carac_image_png24:
mov al,24
@@:


mov ebx,[edx+20h]
mov ecx,[edx+24h]
bswap ebx
bswap ecx

push ebx
mov ebx,edx
call libmem
pop ebx

;calcul du nombre d'octet occupé par l'image
push eax
and eax,0FFh
mul ecx
mul ebx
mov edx,eax
add edx,7
shr edx,3  ;calcul du nomre d'octet pour l'image
add edx,14 ;et rajoute l'en tête
shl edx,8 
pop eax
mov dl,al

pop edi
pop es
pop ds
xor eax,eax
ret


sfv_carac_image_jpeg:
mov edi,edx
add  edi,10h

@@:
cmp byte[edi+1],0D9h
je sfv_carac_image_erreur
cmp byte[edi+1],0C0h
je @f
call bloc_jpeg
jmp @b

@@:
push edx
xor eax,eax
xor ecx,ecx
mov al,[edi+4]
mov cl,[edi+9]
mul ecx
pop edx

xor ebx,ebx
xor ecx,ecx
mov bx,[edi+7]
mov cx,[edi+5]
xchg cl,ch
xchg bl,bh



push ebx
mov ebx,edx
call libmem
pop ebx

;calcul du nombre d'octet occupé par l'image
push eax
and eax,0FFh
mul ecx
mul ebx
mov edx,eax
add edx,7
shr edx,3  ;calcul du nomre d'octet pour l'image
add edx,14 ;et rajoute l'en tête
shl edx,8 
pop eax
mov dl,al

pop edi
pop es
pop ds
xor eax,eax
ret



;****************************************
;passage d'un bloc jpeg a l'autre
bloc_jpeg:
cmp byte[edi],0FFh
jne bloc_jpeg_e
cmp byte[edi+1],01h
je bloc_jpeg_2o
cmp byte[edi+1],0C0h
jb bloc_jpeg_e
cmp byte[edi+1],0DDh
je bloc_jpeg_2o
cmp byte[edi+1],0D0h
jb bloc_jpeg_Mo
cmp byte[edi+1],0DAh
jb bloc_jpeg_0o
cmp byte[edi+1],0FEh
jb bloc_jpeg_Mo

bloc_jpeg_e:
mov word[edi],0D9FFh
ret

bloc_jpeg_0o:
add edi,2
ret

bloc_jpeg_2o:
add edi,4
ret

bloc_jpeg_Mo:
add edi,2
xor eax,eax
mov ax,[edi]
xchg al,ah
add edi,eax
ret



;structure de la mémoire utilisé par "sfv_lire_image"
sfv_lire_image_bpp    equ 10h
sfv_lire_image_to     equ 14h
sfv_lire_image_tx     equ 18h
sfv_lire_image_ty     equ 1Ch
sfv_lire_image_handle equ 20h
sfv_lire_image_dest   equ 24h ;offset+seg
sfv_lire_image_zone1  equ 2Ch
sfv_lire_image_zone2  equ 30h
sfv_lire_image_filtre equ 34h
sfv_lire_image_prof   equ 35h
sfv_lire_image_opp    equ 37h
sfv_lire_image_data   equ 40h

sfv_lire_image:
push ebx
push ecx
push edx
push esi
push edi
push ebp
push ds
push es
push es
push ebx
call sfv_carac_image2
cmp eax,0
je @f
pop ebx
pop es
jmp sfv_lire_image_erreur

@@:
mov eax,edx
push eax
push ebx
push ecx
mov ax,selramh
mov ds,ax
mov es,ax
mov fs,ax
mov ecx,edx
shr ecx,5   ;decal de 8 bit et multliplie par 4
add ecx,sfv_lire_image_data+15
and ecx,0FFFFFFF0h
call resmem
mov edx,ebx
pop ecx
pop ebx
pop eax
jc ermem_sfv_lire_image
mov word[edx+8],czm_fli

mov [edx+sfv_lire_image_bpp],al
shr eax,8
mov [edx+sfv_lire_image_to],eax
mov [edx+sfv_lire_image_tx],ebx
mov [edx+sfv_lire_image_ty],ecx
pop ebx
mov [edx+sfv_lire_image_handle],ebx
mov [edx+sfv_lire_image_dest],edi
pop eax
mov [edx+sfv_lire_image_dest+4],ax

mov eax,edx
add eax,sfv_lire_image_data
mov [edx+sfv_lire_image_zone1],eax
add eax,[edx+sfv_lire_image_to]
add eax,[edx+sfv_lire_image_to]
mov [edx+sfv_lire_image_zone2],eax


;charge le contenu du fichier dans la zt
push edx
mov edi,[edx+sfv_lire_image_zone1]
mov ecx,[edx+sfv_lire_image_to]
xor edx,edx
mov eax,4
int 64h
pop edx
cmp eax,0
jne sfv_lire_image_erreur

mov esi,[edx+sfv_lire_image_zone1]
cmp dword[esi],474E5089h
je sfv_lire_image_png
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
mov eax,cer_parami
jmp sfv_lire_image_erreur



sfv_lire_image_png:
mov al,[esi+1Ch]  ;type d'entrelacement
mov [edx+sfv_lire_image_filtre],al
mov ax,[esi+18h]  ;type de couleur du fichier
mov [edx+sfv_lire_image_prof],ax

add al,7   ;determination du nombre d'octet par pixel
shr al,3
cmp ah,4 ;gris+ alpha
jne @f
shl al,1
@@:
cmp ah,6 ;3couleur +alpha
jne @f
shl al,2
@@:
cmp ah,2 ;3 couleur
jne @f
mov ah,al
shl al,1
add al,ah
@@:
mov [edx+sfv_lire_image_opp],al  ;nombre d'octet par pixel

;recherche le premier idat
mov esi,[edx+sfv_lire_image_zone1]
mov edi,[edx+sfv_lire_image_zone2]
add esi,8

boucle1_recheridat:
cmp dword[esi+4],"IDAT"
je @f
cmp dword[esi+4],"IEND"
je sfv_lire_image_erreur
;cmp dword[esi+4],"PLTE"  ;sauvegarde la position de la palette
;jne pas_plte
;??????????????????????????????????
;pas_plte:
mov eax,[esi]
bswap eax
add esi,eax
add esi,12
jmp boucle1_recheridat



@@:
;copie les données du chunk idat 
push esi
mov ecx,[esi]
add esi,8
bswap ecx
rep movsb
pop esi
mov eax,[esi]
bswap eax
add esi,eax
add esi,12




;cherche le prochain idat ou iend
boucle2_recheridat:
cmp dword[esi+4],"IDAT"
je @b
cmp dword[esi+4],"IEND"
je @f
mov eax,[esi]
bswap eax
add esi,eax
add esi,12
jmp boucle2_recheridat
@@:

;décompresse les données
mov esi,[edx+sfv_lire_image_zone2]
mov edi,[edx+sfv_lire_image_zone1]
add esi,2
mov eax,152
int 61h
cmp eax,0
jne sfv_lire_image_erreur

;**************************************
;supprime le filtre de l'image
cmp byte[edx+sfv_lire_image_filtre],0
je filtre_simple
cmp byte[edx+sfv_lire_image_filtre],1
je filtre_adam7
mov eax,cer_parami
jmp sfv_lire_image_erreur





filtre_adam7:       ;défiltre l'image ADAM7
;1 6 4 6 2 6 4 6
;7 7 7 7 7 7 7 7
;5 6 5 6 5 6 5 6
;7 7 7 7 7 7 7 7
;3 6 4 6 3 6 4 6
;7 7 7 7 7 7 7 7
;5 6 5 6 5 6 5 6
;7 7 7 7 7 7 7 7

xor ebx,ebx
mov ebp,[edx+sfv_lire_image_tx]
mov bl,[edx+sfv_lire_image_opp]
mov esi,[edx+sfv_lire_image_zone1]
mov edi,[edx+sfv_lire_image_zone2]
mov ecx,[edx+sfv_lire_image_ty]


push ebx ;1
push ecx
push ebp
add ecx,7       ;+(div-1)-decalage   
add ebp,7
shr ecx,3
shr ebp,3
push edx
mov eax,ebp
mul ebx
mov ebp,eax ;ebp=taille d'une scanline
pop edx
call defiltre_PNG
pop ebp
pop ecx
pop ebx
cmp eax,0
jne sfv_lire_image_erreur


push ebx ;2
push ecx
push ebp
add ecx,7
add ebp,3
shr ecx,3
shr ebp,3
push edx
mov eax,ebp
mul ebx
mov ebp,eax ;ebp=taille d'une scanline
pop edx
call defiltre_PNG
pop ebp
pop ecx
pop ebx
cmp eax,0
jne sfv_lire_image_erreur


push ebx ;3
push ecx
push ebp
add ecx,3
add ebp,3
shr ecx,3
shr ebp,2
push edx
mov eax,ebp
mul ebx
mov ebp,eax ;ebp=taille d'une scanline
pop edx
call defiltre_PNG
pop ebp
pop ecx
pop ebx
cmp eax,0
jne sfv_lire_image_erreur


push ebx ;4
push ecx
push ebp
add ecx,3
inc ebp
shr ecx,2
shr ebp,2
push edx
mov eax,ebp
mul ebx
mov ebp,eax ;ebp=taille d'une scanline
pop edx
call defiltre_PNG
pop ebp
pop ecx
pop ebx
cmp eax,0
jne sfv_lire_image_erreur


push ebx ;5
push ecx
push ebp
inc ecx
inc ebp
shr ecx,2
shr ebp,1
push edx
mov eax,ebp
mul ebx
mov ebp,eax ;ebp=taille d'une scanline
pop edx
call defiltre_PNG
pop ebp
pop ecx
pop ebx
cmp eax,0
jne sfv_lire_image_erreur


push ebx ;6
push ecx
push ebp
inc ecx
;add ebp,0
shr ecx,1
shr ebp,1
push edx
mov eax,ebp
mul ebx
mov ebp,eax ;ebp=taille d'une scanline
pop edx
call defiltre_PNG
pop ebp
pop ecx
pop ebx
cmp eax,0
jne sfv_lire_image_erreur


push ebx ;7
push ecx
push ebp
;add ecx,0
;add ebp,0
shr ecx,1
;shr ebp,0
push edx
mov eax,ebp
mul ebx
mov ebp,eax ;ebp=taille d'une scanline
pop edx
call defiltre_PNG
pop ebp
pop ecx
pop ebx
cmp eax,0
jne sfv_lire_image_erreur



;remet les octet dans l'ordre
mov esi,[edx+sfv_lire_image_zone2]
mov edi,[edx+sfv_lire_image_zone1]
mov ebx,[edx+sfv_lire_image_tx]
mov ecx,[edx+sfv_lire_image_ty]
mov al,[edx+sfv_lire_image_bpp]
and eax,0FFh
shr eax,3
push edx
mov ebp,eax
mul ebx
pop edx

push eax ;1
push ebx
push ecx 
push edi
push ebp
add ebx,7
add ecx,7
shr ebx,3
shr ecx,3
shl eax,3
shl ebp,3
call ordre_sfv_lire_image
pop ebp
pop edi
pop ecx
pop ebx
pop eax


push eax ;2
push ebx
push ecx 
push edi
push ebp
add ebx,3
add ecx,7
shr ebx,3
shr ecx,3
shl eax,3
shl ebp,2
add edi,ebp
shl ebp,1
call ordre_sfv_lire_image
pop ebp
pop edi
pop ecx
pop ebx
pop eax

push eax ;3
push ebx
push ecx 
push edi
push ebp
add ebx,3
add ecx,3
shr ebx,2
shr ecx,3
shl ebp,2
shl eax,2
add edi,eax
shl eax,1
call ordre_sfv_lire_image
pop ebp
pop edi
pop ecx
pop ebx
pop eax

push eax ;4
push ebx
push ecx 
push edi
push ebp
add ebx,1
add ecx,3
shr ebx,2
shr ecx,2
shl ebp,1
add edi,ebp
shl ebp,1
shl eax,2
call ordre_sfv_lire_image
pop ebp
pop edi
pop ecx
pop ebx
pop eax

push eax ;5
push ebx
push ecx 
push edi
push ebp
add ebx,1
add ecx,1
shr ebx,1
shr ecx,2
shl eax,1
add edi,eax
shl eax,1
shl ebp,1
call ordre_sfv_lire_image
pop ebp
pop edi
pop ecx
pop ebx
pop eax

push eax ;6
push ebx
push ecx 
push edi
push ebp
;add ebx,0
add ecx,1
shr ebx,1
shr ecx,1
add edi,ebp
shl eax,1
shl ebp,1
call ordre_sfv_lire_image
pop ebp
pop edi
pop ecx
pop ebx
pop eax

push eax ;7
push ebx
push ecx 
push edi
push ebp
;add ebx,0
;add ecx,0
;shr ebx,0
shr ecx,1
add edi,eax
shl eax,1
call ordre_sfv_lire_image
pop ebp
pop edi
pop ecx
pop ebx
pop eax
jmp finfiltre


;****************************************
filtre_simple:   ;défiltre l'image simple
xor ebx,ebx
mov eax,[edx+sfv_lire_image_tx]
mov bl,[edx+sfv_lire_image_opp]
push edx
mul ebx
pop edx
mov ebp,eax ;ebp=taille d'une scanline
mov esi,[edx+sfv_lire_image_zone1]
mov edi,[edx+sfv_lire_image_zone2]
mov ecx,[edx+sfv_lire_image_ty]
call defiltre_PNG
cmp eax,0
jne sfv_lire_image_erreur

;remet les octet dans l'ordre
mov esi,[edx+sfv_lire_image_zone2]
mov edi,[edx+sfv_lire_image_zone1]
mov ebx,[edx+sfv_lire_image_tx]
mov ecx,[edx+sfv_lire_image_ty]
mov al,[edx+sfv_lire_image_bpp]
and eax,0FFh
shr eax,3
push edx
mov ebp,eax
mul ebx
pop edx
call ordre_sfv_lire_image


finfiltre:
;copie l'image finale
mov cx,[edx+sfv_lire_image_dest+4]
mov edi,[edx+sfv_lire_image_dest]
mov es,cx
mov al,[edx+sfv_lire_image_bpp]
mov ebx,[edx+sfv_lire_image_tx]
mov ecx,[edx+sfv_lire_image_ty]

es
mov [edi+objimage_bpp],al
es
mov byte[edi+objimage_att],0
es
mov [edi+objimage_x],bx
es
mov [edi+objimage_y],cx

and eax,0FFh
push edx
shr eax,3
mul ebx
pop edx
es
mov [edi+objimage_opl],eax
es
mov dword[edi+objimage_ctp],0
add edi,objimage_dat
mov esi,[edx+sfv_lire_image_zone1]
mov ecx,[edx+sfv_lire_image_to]
sub ecx,objimage_dat
cld
rep movsb
xor eax,eax


sfv_lire_image_erreur:
mov ebx,edx
call libmem
pop es
pop ds
pop ebp
pop edi
pop esi
pop edx
pop ecx
pop ebx
iret

ermem_sfv_lire_image:
mov eax,cer_pasm
jmp sfv_lire_image_erreur



;***********************************
;ebp = taille d'un pixel a l'autre
;eax = taille d'une ligne a l'autre
;ebx = pixel par ligne
;ecx = nb de ligne

ordre_sfv_lire_image:
push ebx
push ecx
push edx
push ebp
push eax
mov al,[edx+sfv_lire_image_opp]
cmp al,1
;je ordre1a_sfv_lire_image
;cmp al,1
je ordre1b_sfv_lire_image
cmp al,2
je ordre2_sfv_lire_image
cmp al,3
je ordre3_sfv_lire_image
cmp al,4
je ordre4_sfv_lire_image
pop eax
pop ebp
pop edx
pop ecx
pop ebx
mov eax,cer_parami
ret


ordre1a_sfv_lire_image:             ;palette (a modifier)
pop edx
boucle_ordre1a_sfv_lire_image:
push ebx
push edi
@@:
mov al,[esi]
mov [edi],al
mov [edi+1],al
mov [edi+2],al
inc esi
add edi,ebp
dec ebx
jnz @b
pop edi
pop ebx
add edi,edx
dec ecx
jnz boucle_ordre1a_sfv_lire_image
pop ebp
pop edx
pop ecx
pop ebx
xor eax,eax
ret

ordre1b_sfv_lire_image:             ;niveau de gris
pop edx
boucle_ordre1b_sfv_lire_image:
push ebx
push edi
@@:
mov al,[esi]
mov [edi],al
mov [edi+1],al
mov [edi+2],al
inc esi
add edi,ebp
dec ebx
jnz @b
pop edi
pop ebx
add edi,edx
dec ecx
jnz boucle_ordre1b_sfv_lire_image
pop ebp
pop edx
pop ecx
pop ebx
xor eax,eax
ret


ordre2_sfv_lire_image:             ;niveau de gris et canal alpha
pop edx
boucle_ordre2_sfv_lire_image:
push ebx
push edi
@@:
mov ax,[esi]
mov [edi],al
mov [edi+1],al
mov [edi+2],al
mov [edi+3],ah
add esi,2
add edi,ebp
dec ebx
jnz @b
pop edi
pop ebx
add edi,edx
dec ecx
jnz boucle_ordre2_sfv_lire_image
pop ebp
pop edx
pop ecx
pop ebx
xor eax,eax
ret


ordre3_sfv_lire_image:             ;24bits
pop edx
boucle_ordre3_sfv_lire_image:
push ebx
push edi
@@:
mov eax,[esi]
bswap eax
mov [edi],ah
shr eax,16
mov [edi+1],ax
add esi,3
add edi,ebp
dec ebx
jnz @b
pop edi
pop ebx
add edi,edx
dec ecx
jnz boucle_ordre3_sfv_lire_image
pop ebp
pop edx
pop ecx
pop ebx
xor eax,eax
ret


ordre4_sfv_lire_image:          ;24bits+alpha
pop edx
boucle_ordre4_sfv_lire_image:
push ebx
push edi
@@:
mov eax,[esi]
bswap eax
push eax
shr eax,8
mov [edi],eax
pop eax
mov [edi+3],al
add esi,4
add edi,ebp
dec ebx
jnz @b
pop edi
pop ebx
add edi,edx
dec ecx
jnz boucle_ordre4_sfv_lire_image
pop ebp
pop edx
pop ecx
pop ebx
xor eax,eax
ret








;******************************************************
;defiltre une image PNG
defiltre_PNG:
push ecx  ;cas spéciaux pour la première ligne
mov ecx,ebp
cmp byte[esi],2
je filtre0_sfv_lire_image
cmp byte[esi],3
je filtre3b_sfv_lire_image
cmp byte[esi],4
je filtre4b_sfv_lire_image
pop ecx

bouclefiltre_sfv_lire_image:
push ecx
mov ecx,ebp
cmp byte[esi],0
je filtre0_sfv_lire_image
cmp byte[esi],1
je filtre1_sfv_lire_image
cmp byte[esi],2
je filtre2_sfv_lire_image
cmp byte[esi],3
je filtre3_sfv_lire_image
cmp byte[esi],4
jmp filtre4_sfv_lire_image
mov eax,cer_parami
pop ecx
ret


filtre0_sfv_lire_image:
inc esi
cld
rep movsb
pop ecx
dec ecx
jnz bouclefiltre_sfv_lire_image
xor eax,eax
ret

filtre1_sfv_lire_image:
inc esi
push ebx
@@:
mov al,[esi]
mov [edi],al
inc esi
inc edi
dec ecx
dec ebx
jnz @b
pop ebx

@@:
mov al,[esi]
push edi
sub edi,ebx
add al,[edi]
pop edi
mov [edi],al
inc esi
inc edi
dec ecx
jnz @b
pop ecx
dec ecx
jnz bouclefiltre_sfv_lire_image
xor eax,eax
ret 


filtre2_sfv_lire_image:
inc esi
@@:
mov al,[esi]
push esi
mov esi,edi
sub esi,ebp
add al,[esi]
pop esi
mov [edi],al
inc esi
inc edi
dec ecx
jnz @b
pop ecx
dec ecx
jnz bouclefiltre_sfv_lire_image
xor eax,eax
ret


filtre3_sfv_lire_image:
inc esi
push ebx
@@:
mov al,[esi]
push edi
sub edi,ebp
mov ah,[edi]
shr ah,1
add al,ah
pop edi
mov [edi],al
inc esi
inc edi
dec ecx
dec ebx
jnz @b
pop ebx


@@:
xor eax,eax
mov al,[esi]
mov [edi],al
push edi
push edi
sub edi,ebx
mov al,[edi]
pop edi
sub edi,ebp
add al,[edi]
adc ah,0
shr ax,1
pop edi
add [edi],al
inc esi
inc edi
dec ecx
jnz @b
pop ecx
dec ecx
jnz bouclefiltre_sfv_lire_image
xor eax,eax
ret 


filtre3b_sfv_lire_image:
inc esi
push ebx
@@:
mov al,[esi]
mov [edi],al
inc esi
inc edi
dec ecx
dec ebx
jnz @b
pop ebx

@@:
xor eax,eax
mov al,[esi]
mov [edi],al
push edi
sub edi,ebx
add al,[edi]
adc ah,0
shr ax,1
pop edi
add [edi],al
inc esi
inc edi
dec ecx
jnz @b
pop ecx
dec ecx
jnz bouclefiltre_sfv_lire_image
xor eax,eax
ret


filtre4_sfv_lire_image:
inc esi
push ebx
@@:
push edi
xor eax,eax
sub edi,ebp
mov al,[edi]  ;b 7-0
pop edi
call calc_paeth
add al,[esi]
mov [edi],al
inc esi
inc edi
dec ecx
dec ebx
jnz @b
pop ebx

boucle_filtre4_sfv_lire_image:
push edi
sub edi,ebx
mov al,[edi]  ;a  23-16
sub edi,ebp
shl eax,8
mov al,[edi]   ;c  15-8
add edi,ebx
shl eax,8
mov al,[edi]  ;b 7-0
pop edi
call calc_paeth
add al,[esi]
mov [edi],al
inc esi
inc edi
dec ecx
jnz boucle_filtre4_sfv_lire_image
pop ecx
dec ecx
jnz bouclefiltre_sfv_lire_image
xor eax,eax
ret



filtre4b_sfv_lire_image:
inc esi

push ebx
@@:
xor eax,eax
call calc_paeth
add al,[esi]
mov [edi],al
inc esi
inc edi
dec ecx
dec ebx
jnz @b
pop ebx

boucle_filtre4b_sfv_lire_image:
push edi
sub edi,ebx
mov al,[edi]  ;a  23-16
shl eax,16
xor ax,ax
pop edi
call calc_paeth
add al,[esi]
mov [edi],al
inc esi
inc edi
dec ecx
jnz boucle_filtre4_sfv_lire_image
pop ecx
dec ecx
jnz bouclefiltre_sfv_lire_image
xor eax,eax
ret




;***********************************
;p = a + b - c
;pa = abs(p - a)  =abs(b-c)
;pb = abs(p - b)  =abs(a-c)
;pc = abs(p - c)  =abs(a+b-2c)
;if pa <= pb and pa <= pc then Pr = a
;else if pb <= pc then Pr = b
;else Pr = c
;return Pr (dans al)

calc_paeth:
push ebx
push ecx
push edx
push esi
push edi

xor ebx,ebx
xor ecx,ecx
mov bl,al
mov cl,ah
cmp ebx,ecx
ja @f
xchg ebx,ecx
@@:
sub ebx,ecx
mov esi,ebx ;pa

xor ebx,ebx
xor ecx,ecx
push eax
shr eax,8
mov bl,al
mov cl,ah
pop eax
cmp ebx,ecx
ja @f
xchg ebx,ecx
@@:
sub ebx,ecx
mov edi,ebx ;pb

xor ebx,ebx
xor ecx,ecx
push eax
mov bl,al
shr eax,8
mov cl,ah
pop eax
add ebx,ecx
mov cl,ah
shl ecx,1
cmp ebx,ecx
ja @f
xchg ebx,ecx
@@:
sub ebx,ecx ;pc

cmp esi,ebx
ja @f
cmp esi,edi
jbe a_filtre4_sfv_lire_image
@@:
cmp edi,ebx
jbe b_filtre4_sfv_lire_image
jmp c_filtre4_sfv_lire_image

a_filtre4_sfv_lire_image:
shr eax,8
c_filtre4_sfv_lire_image:
shr eax,8
b_filtre4_sfv_lire_image:
pop edi
pop esi
pop edx
pop ecx
pop ebx
ret



;********************************************************************************************************************************************
sfv_chgtaille_t1x     equ 000h
sfv_chgtaille_t1y     equ 004h
sfv_chgtaille_addr1   equ 008h 
sfv_chgtaille_opl1    equ 00Ch
sfv_chgtaille_t2x     equ 010h
sfv_chgtaille_t2y     equ 014h
sfv_chgtaille_addr2   equ 018h 
sfv_chgtaille_opl2    equ 01Ch
sfv_chgtaille_opp     equ 020h
sfv_chgtaille_adligne equ 024h
sfv_chgtaille_calx    equ 030h 
sfv_chgtaille_caly    equ 070h 
sfv_chgtaille_max     equ 0A0h 


;****************************************************
sfv_chgtaille:  ;ds:esi=image d'origine  ds:edi=image de sortie

;verifie les parametre d'entrée
mov al,[esi+objimage_bpp]
cmp al,[edi+objimage_bpp]
je @f
mov eax,cer_parami 
iret
@@:
cmp byte[edi+objimage_bpp],24
je @f
cmp byte[edi+objimage_bpp],32
je @f
mov eax,cer_parami 
iret

@@:  ;reserve mémoire dans la pile
pushad
push ds
push es
sub esp,sfv_chgtaille_max
mov eax,esp
push esi
mov esi,eax
mov ax,ds
mov es,ax
mov ax,ss
mov ds,ax


;enregistrement donnée image 2
xor ebx,ebx
xor ecx,ecx
xor ebp,ebp
es
mov bx,[edi+objimage_x]
es
mov cx,[edi+objimage_y]
es
mov bp,[edi+objimage_opl]
mov [esi+sfv_chgtaille_t2x],ebx 
mov [esi+sfv_chgtaille_t2y],ecx
mov [esi+sfv_chgtaille_addr2],edi
mov [esi+sfv_chgtaille_opl2],ebp 

pop edi
;enregistrement donnée image 1
xor ebx,ebx
xor ecx,ecx
xor ebp,ebp
es
mov bx,[edi+objimage_x]
es
mov cx,[edi+objimage_y]
es
mov bp,[edi+objimage_opl]
mov [esi+sfv_chgtaille_t1x],ebx 
mov [esi+sfv_chgtaille_t1y],ecx
mov [esi+sfv_chgtaille_addr1],edi
mov [esi+sfv_chgtaille_opl1],ebp 

;calcul autres variables
xor eax,eax
es
mov al,[edi+objimage_bpp]
shr eax,3
mov [esi+sfv_chgtaille_opp],eax


xor ebx,ebx
xor ecx,ecx
@@:
call sfv_chgtaille_calcpix
inc ebx
cmp ebx,[esi+sfv_chgtaille_t2x]
jb @b
xor ebx,ebx
inc ecx
cmp ecx,[esi+sfv_chgtaille_t2y]
jb @b


add esp,sfv_chgtaille_max
pop es
pop ds
popad
xor eax,eax
iret


;calcule la moyenne d'un pixel
sfv_chgtaille_calcpix:
pushad
push ebx
push ecx

;calcul adresse début de ligne
mov eax,ecx
mul dword[esi+sfv_chgtaille_t1y]
div dword[esi+sfv_chgtaille_t2y]  ;eax=numéros du pixel d'origine 
neg edx
add edx,[esi+sfv_chgtaille_t2y]   ;edx=reste inversé
push edx
mul dword[esi+sfv_chgtaille_opl1] 
pop edx
add eax,[esi+sfv_chgtaille_addr1]
add eax,objimage_dat
mov [esi+sfv_chgtaille_adligne],eax


;reset valeur pixel
mov edi,esi
add edi,sfv_chgtaille_caly
mov ebp,[esi+sfv_chgtaille_opp]
@@:
mov dword[edi],0
add edi,4
dec ebp
jnz @b


;addition avec coefficient des lignes
mov ebp,[esi+sfv_chgtaille_t1y]

@@:
cmp ebp,0
je sfv_chgtaille_finy
cmp edx,ebp
ja sfv_chgtaille_derny

mov ecx,edx
call sfv_chgtaille_caligne
sub ebp,ecx
mov edx,[esi+sfv_chgtaille_t2y]
mov eax,[esi+sfv_chgtaille_opl1] 
add [esi+sfv_chgtaille_adligne],eax
jmp @b


sfv_chgtaille_derny:
mov ecx,ebp
call sfv_chgtaille_caligne


;application moyenne des lignes et ecriture final du pixel
sfv_chgtaille_finy:
pop ecx
mov eax,[esi+sfv_chgtaille_opl2]
mul ecx
mov ebx,eax
pop eax
mul dword[esi+sfv_chgtaille_opp] 
add ebx,eax
add ebx,[esi+sfv_chgtaille_addr2]
add ebx,objimage_dat

mov edi,sfv_chgtaille_caly
add edi,esi
mov ecx,[esi+sfv_chgtaille_opp] 

@@:
mov eax,[edi]
xor edx,edx
div dword[esi+sfv_chgtaille_t1y]
es
mov [ebx],al
inc ebx
add edi,4
dec ecx
jnz @b

popad
ret



;************************************
;calcul moyenne de la ligne
sfv_chgtaille_caligne:
pushad
push ecx

;calcul adresse du pixel
mov eax,ebx
mul dword[esi+sfv_chgtaille_t1x]
div dword[esi+sfv_chgtaille_t2x]  ;eax=numéros du pixel d'origine 
neg edx
add edx,[esi+sfv_chgtaille_t2x]   ;edx=reste inversé
push edx
mul dword[esi+sfv_chgtaille_opp] 
mov ebx,eax 
add ebx,[esi+sfv_chgtaille_adligne] ;ebx=adresse du premier pixel
pop edx

;reset valeur de ligne
mov edi,esi
add edi,sfv_chgtaille_calx
mov ebp,[esi+sfv_chgtaille_opp]
@@:
mov dword[edi],0
add edi,4
dec ebp
jnz @b

;addition avec coefficient des pixel
mov ebp,[esi+sfv_chgtaille_t1x]

@@:
cmp ebp,0
je sfv_chgtaille_finx
cmp edx,ebp
ja sfv_chgtaille_dernx

mov ecx,edx
call sfv_chgtaille_ajpix
sub ebp,ecx
mov edx,[esi+sfv_chgtaille_t2x]
jmp @b

sfv_chgtaille_dernx:
mov ecx,ebp
call sfv_chgtaille_ajpix


;calcul de la moyenne de la ligne et ecriture dans le resultat
sfv_chgtaille_finx:
pop ecx
mov ebx,esi
mov edi,esi
add ebx,sfv_chgtaille_calx
add edi,sfv_chgtaille_caly
mov ebp,[esi+sfv_chgtaille_opp]

@@:
mov eax,[ebx]
mul ecx
div dword[esi+sfv_chgtaille_t1x]
add [edi],eax
add ebx,4
add edi,4
dec ebp
jnz @b

popad
ret



;************************
sfv_chgtaille_ajpix:
push ebp
mov edi,esi
add edi,sfv_chgtaille_calx
mov ebp,[esi+sfv_chgtaille_opp]
@@:
xor eax,eax
es
mov al,[ebx]
mul ecx
add [edi],eax
inc ebx
add edi,4
dec ebp
jnz @b
pop ebp
ret




;********************************************************************************************************************************************
sfv_lit_frag:      	;extrait un fragment d'une image
pushad			;ds:esi=adresse de l'image   ds:edi=adresse du fragment  ebx=position x du fragment ecx=position y du fragment


xor eax,eax
mov al,[edi+objimage_bpp]
cmp al,[esi+objimage_bpp]
jne erreur_sfv_frag
add eax,7
shr eax,3

;test si on est bien a l'interieur de l'image
xor edx,edx
mov dx,[esi+objimage_x]
cmp ebx,edx
jae erreur_sfv_frag
mov dx,[esi+objimage_y]
cmp ecx,edx
jae erreur_sfv_frag

call calcul_sfv_cpfrag 

boucle_sfv_frag:  ;ebp=nb d'octet par ligne transfert ;ebx=octet par ligne entrée ;edx=octet par ligne sortie ;ecx=nombre de lignes
push ecx
push esi
push edi
mov ecx,ebp
rep movsb
pop edi
pop esi
pop ecx
add esi,ebx
add edi,edx
dec ecx
jnz boucle_sfv_frag
popad
xor eax,eax
iret 

erreur_sfv_frag:
popad
mov eax,cer_parami
iret



;******************
calcul_sfv_cpfrag:


;calcul l'offset
push eax
mul ebx
push eax
mov eax,[esi+objimage_opl]
mul ecx
pop edx
add edx,eax 
pop eax    ;edx=offset eax=octet par bit


push edx
push eax


;ajuste le x
xor eax,eax
mov ax,[esi+objimage_x]
xor edx,edx
mov dx,[edi+objimage_x]
sub eax,ebx
cmp eax,edx
jb @f
xchg eax,edx
@@:
mov ebx,eax


;ajuste le y
xor eax,eax
mov ax,[esi+objimage_y]
xor edx,edx
mov dx,[edi+objimage_y]
sub eax,ecx
cmp eax,edx
jb @f
xchg eax,edx
@@:
mov ecx,eax

pop eax
mul ebx
mov ebp,eax

mov ebx,[esi+objimage_opl]
mov edx,[edi+objimage_opl]

;calcul les premier octet des images
add esi,objimage_dat
add edi,objimage_dat
pop eax
add esi,eax
ret










;********************************************************************************************************************************************
sfv_ecrit_frag:      	;insère un fragment dans une image
pushad			;ds:esi=adresse du fragment   ds:edi=adresse de l'image   ebx=position x du fragment ecx=position y du fragment

xor eax,eax
mov al,[edi+objimage_bpp]
cmp al,[esi+objimage_bpp]
jne erreur_sfv_frag
add eax,7
shr eax,3

;test si on est bien a l'interieur de l'image
xor edx,edx
mov dx,[edi+objimage_x]
cmp ebx,edx
jae erreur_sfv_frag
mov dx,[edi+objimage_y]
cmp ecx,edx
jae erreur_sfv_frag

xchg esi,edi
call calcul_sfv_cpfrag 
xchg esi,edi
xchg ebx,edx

jmp boucle_sfv_frag









