;fonction système
;al=0   envoyer une commande au système
;al=1   mettre en veille la tache
;al=2   obtenir ID
;al=3   obtenir commande
;al=4   obtenir option dans commande (par n°)
;al=5   obtenir option dans commande (par lettre)
;al=6   ecrire une ligne dans le journal
;al=7   modifier descriptif de la tache
;al=8   modifier taille d'un segment de la tache
;al=9   lire la date et l'heure actuelle
;al=10  déclarer son type de service
;al=11  rechercher un service


;*****************************************************************************************
;fonctions "pratique"
;al=100 convertir chaine decimale asciiz en entier 32bits
;al=101 convertir chaine hexadecimale en entier 32bits
;al=102 convertir entier 32bits en chaine decimale asciiz
;al=103 convertir entier 32bits en chaine hexadecimale asciiz
;al=104 convertir entier 16bits en chaine hexadecimale asciiz
;al=105 convertir entier 8bits en chaine hexadecimale asciiz


cmp al,0
je sfs_envoie_cmd
cmp al,1
je sfs_pause
cmp al,2
je sfs_obt_id
cmp al,3
je sfs_obt_cmd
cmp al,4
je sfs_obt_optn
cmp al,5
je sfs_obt_optl
cmp al,6
je sfs_ecr_j
cmp al,7
je sfs_mod_des_t
cmp al,8
je sfs_mod_seg
cmp al,9
je sfs_lire_date_heure
cmp al,10
je sfs_set_service
cmp al,11
je sfs_rech_service


cmp al,100
je conv_cdeci_reg
cmp al,101
je conv_chex_reg
cmp al,102
je conv_reg_deci32
cmp al,103
je conv_reg_hexa32
cmp al,104
je conv_reg_hexa16
cmp al,105
je conv_reg_hexa8

mov eax,cer_parami
iret

;*******************************************************************************************
sfs_envoie_cmd:    ;envoie une commande pointé par ds:edx (chaine utf8z) au système

push ebx
push ecx
push esi
push edi
push es

mov ax,seldat
mov es,ax

;verifie qu'il y ait suffisament de place dans la ZT de traitement des commandes

;calcul la taille de la chaine
mov esi,edx
cld
boucle1_sfs_envoie_cmd:
lodsb
cmp al,0
jne boucle1_sfs_envoie_cmd
mov ecx,esi
sub ecx,edx




sti
boucle2_sfs_envoie_cmd:
xor eax,eax
es
mov ax,[to_ztcmd]
add eax,ecx
add eax,2
cmp eax,8000h
ja boucle2_sfs_envoie_cmd
cli




;copie l'ID de la tache
xor edi,edi
es
mov di,[to_ztcmd]
add edi,ad_ztcmd
es
mov ax,[id_tache_exec]
es
mov [edi],ax
add edi,2

;copie la commande
mov esi,edx
cld
rep movsb       ;recopie la commande dans la fifo de traitement

;sauvegarde la taille occupé par la ZT des commandes
sub edi,ad_ztcmd
es
mov [to_ztcmd],di

pop es
pop edi
pop esi
pop ecx
pop ebx
xor eax,eax
iret


;*******************************************************************************************
sfs_pause:         ;met en veille la tache durant ecx * 2.5 milliseconde
push ebx
push ecx
push ds
push es
mov ax,seldat
mov ds,ax
mov ax,selramh
mov es,ax
mov ebx,[ad_tache_exec]
add ecx,[cptsf]
es
mov [ebx+cpt_pause],ecx
mov byte[cpttc],1 
sti
boucle_sfs_pause:
int 62h
cmp [cptsf],ecx 
jb boucle_sfs_pause
pop es
pop ds
pop ecx
pop ebx
xor eax,eax
iret


;*******************************************************************************************
sfs_obt_id:        ;renvoie l'ID dans bx
push ebx
push ds
push es
mov ax,seldat
mov ds,ax
mov ax,selramh
mov es,ax
mov ebx,[ad_tache_exec]
es
mov ax,[ebx+8]
pop es
pop ds
pop ebx
mov bx,ax
xor eax,eax
iret


;*******************************************************************************************
sfs_obt_cmd:       ;ecrit la commande qui a créer la tache dans ds:edx (512 octets)
push ecx
push esi
push edi
push ds
push es
mov ax,ds
mov es,ax
mov ax,seldat
mov ds,ax
mov esi,[ad_tache_exec]
add esi,recop_commande
mov ax,selramh
mov ds,ax
mov edi,edx
mov ecx,512
cld
rep movsb
pop es
pop ds
pop edi
pop esi
pop ecx
xor eax,eax
iret


;*******************************************************************************************
sfs_obt_optn:     ;ecrit l'option numéros ah (commence a zéro) de la commande qui a créer la tache dans ds:edx cl=taille maximum (0=256octet)
push ebx
push ecx
push edx
push esi
push ds
push es
mov si,ds
mov es,si
mov si,seldat
mov ds,si
mov ebx,[ad_tache_exec]
add ebx,recop_commande
mov si,selramh
mov ds,si
mov esi,ebx
add esi,200h

boucle1_sfs_obt_optn:
cmp byte[ebx]," "
jne suite_sfs_obt_optn
cmp byte[ebx+1]," "
je suite_sfs_obt_optn
cmp ah,0
je opt_sfs_obt_optn
dec ah
suite_sfs_obt_optn:
inc ebx
cmp ebx,esi
jne boucle1_sfs_obt_optn
pop es
pop ds
pop esi
pop edx
pop ecx
pop ebx
mov eax,cer_parami
iret

opt_sfs_obt_optn:
mov esi,edx
inc ebx
dec cl

boucle2_sfs_obt_optn:
mov al,[ebx]
cmp al,0
je fin__sfs_obt_optn
cmp al," "
je fin__sfs_obt_optn
es
mov [esi],al
inc ebx
inc esi
dec cl
jnz boucle2_sfs_obt_optn

fin__sfs_obt_optn:
es
mov byte[esi],0
pop es
pop ds
pop esi
pop edx
pop ecx
pop ebx
xor eax,eax
iret


;*******************************************************************************************
sfs_obt_optl:    ;ecrit l'option avec la lettre ah de la commande qui a créer la tache dans ds:edx cl=taille maximum (0=256octet)

push ebx
push ecx
push edx
push esi
push ds
push es
mov si,ds
mov es,si
mov si,seldat
mov ds,si
mov ebx,[ad_tache_exec]
add ebx,recop_commande
mov si,selramh
mov ds,si
mov esi,ebx
add esi,200h
mov al,"-"

boucle1_sfs_obt_optl:
cmp [ebx],ax
je opt_sfs_obt_optl
inc ebx
cmp ebx,esi
jne boucle1_sfs_obt_optl
erreur_sfs_obt_optl:
pop es
pop ds
pop esi
pop edx
pop ecx
pop ebx
xor eax,eax
iret

opt_sfs_obt_optl:
add ebx,2
cmp byte[ebx],0
je fin_sfs_obt_optl
cmp byte[ebx]," "
je fin_sfs_obt_optl
cmp byte[ebx],":"
jne erreur_sfs_obt_optl

boucle2_sfs_obt_optl:
mov al,[ebx]
cmp al,0
je fin_sfs_obt_optl
cmp al," "
je fin_sfs_obt_optl
es
mov [edx],al
inc ebx
inc edx
dec cl
jnz boucle2_sfs_obt_optl

fin_sfs_obt_optl:
es
mov byte[edx],0
pop es
pop ds
pop esi
pop edx
pop ecx
pop ebx
xor eax,eax
iret




;*******************************************************************************************
sfs_ecr_j:       ;ajoute la chaine asciiz ds:edx dans le journal
call affjournal
xor eax,eax
iret




;*******************************************************************************************
sfs_mod_des_t:      ;modification du descripteur de tache
iret


;*******************************************************************************************
sfs_mod_seg:        ;modification de la taille d'un segment dx=selecteur du segment a modifier ecx=nouvelle taille
;sauvegarde les selecteur de segment
push ds
push es
push fs
push gs
push ebx
push ecx
push edx
push esi
push edi
push ebp

;determine que est la zone a modifier
mov ax,seldat
mov fs,ax
mov gs,ax
mov ax,selramh
mov ds,ax
mov es,ax
fs
mov ebx,[ad_tache_exec]

cmp dx,17h
je sfs_mod_seg_dat1
cmp dx,1Fh
je sfs_mod_seg_dat2
cmp dx,27h
je sfs_mod_seg_dat3
cmp dx,2Fh
je sfs_mod_seg_dat4
jmp sfs_mod_seg_erparami

;modifie la taille et adresse des zones
sfs_mod_seg_dat1:
mov edx,[ebx+tt_data1_dt]
mov [ebx+tt_data1_dt],ecx    ;change la taille de la zone de donnée 1
sub ecx,edx               ;calcul la différence de taille
mov esi,[ebx+ad_data2_dt]    ;sauvegarde la position des données a deplacer
add [ebx+ad_data2_dt],ecx    ;décale d'autant l'adresse de la zone 2
add [ebx+ad_data3_dt],ecx    ;décale d'autant l'adresse de la zone 3
add [ebx+ad_data4_dt],ecx    ;décale d'autant l'adresse de la zone 4 

mov ebp,[ebx+tt_data4_dt]
add ebp,[ebx+tt_data3_dt]
add ebp,[ebx+tt_data2_dt]    ;calcul la taille des données a deplacer
jmp sfs_mod_seg_deplace

sfs_mod_seg_dat2:
mov edx,[ebx+tt_data2_dt]
mov [ebx+tt_data2_dt],ecx    ;change la taille de la zone de donnée 2
sub ecx,edx               ;calcul la différence de taille
mov esi,[ebx+ad_data3_dt]    ;sauvegarde la position des données a deplacer
add [ebx+ad_data3_dt],ecx    ;décale d'autant l'adresse de la zone 3
add [ebx+ad_data4_dt],ecx    ;décale d'autant l'adresse de la zone 4 

mov ebp,[ebx+tt_data4_dt]
add ebp,[ebx+tt_data3_dt]   ;calcul la taille des données a deplacer
jmp sfs_mod_seg_deplace

sfs_mod_seg_dat3:
mov edx,[ebx+tt_data3_dt]
mov [ebx+tt_data3_dt],ecx    ;change la taille de la zone de donnée 3
sub ecx,edx               ;calcul la différence de taille
mov esi,[ebx+ad_data4_dt]    ;sauvegarde la position des données a deplacer
add [ebx+ad_data4_dt],ecx    ;décale d'autant l'adresse de la zone 4 

mov ebp,[ebx+tt_data4_dt]    ;calcul la taille des données a deplacer
jmp sfs_mod_seg_deplace

sfs_mod_seg_dat4:
mov [ebx+tt_data4_dt],ecx    ;change la taille de la zone de donnée 4
jmp sfs_mod_seg_chgt

sfs_mod_seg_deplace:  ;esi=debut des données a deplacer ;ecx=sens des donnes a deplacer ;ebp=quantité a deplacer
;+ ou -?  
cmp ebp,0
je sfs_mod_seg_chgt
test ecx,80000000h
jnz sfs_mod_seg_diminue

;agrandit la zone
push ecx
mov ecx,[ebx+ad_data4_dt]
add ecx,[ebx+tt_data4_dt]
and ecx,0FFFFFFF0h
add ecx,10h       ;pour avoir une granularité de 16octets
call modtm
pop ecx
jc sfs_mod_seg_erpasm
fs
mov [ad_tache_exec],ebx

;déplace les données
add esi,ebx
add esi,ebp
dec esi
mov edi,esi
add edi,ecx
mov ecx,ebp
std  ;-
rep movsb 
jmp sfs_mod_seg_majldt


sfs_mod_seg_diminue:
;déplace les données
add esi,ebx
mov edi,esi
add edi,ecx
mov ecx,ebp
cld ;+
rep movsb  

sfs_mod_seg_chgt:       ;change la taille de la zone
mov ecx,[ebx+ad_data4_dt]
add ecx,[ebx+tt_data4_dt]
and ecx,0FFFFFFF0h
add ecx,10h       ;pour avoir une granularité de 16octets
call modtm
jc sfs_mod_seg_erpasm
fs
mov [ad_tache_exec],ebx

sfs_mod_seg_majldt:  
fs
mov esi,[ad_tache_exec]
call maj_ldtache

lldt [esi+sel_ldt_tache] ;on recharge la bonne LDT

mov ax,sel_pilet ;on recharge le segment de la pile pour mettre a jour les données 
mov ss,ax


fin_sfs_mod_seg: ;restaure les selecteur de segment
pop ebp
pop edi
pop esi
pop edx
pop ecx
pop ebx
pop gs
pop fs
pop es
pop ds
xor eax,eax
iret

sfs_mod_seg_erparami:    ;parametre d'appel de fonction incorrecte
pop ebp
pop edi
pop esi
pop edx
pop ecx
pop ebx
pop gs
pop fs
pop es
pop ds
mov eax,cer_parami
iret

sfs_mod_seg_erpasm:    ;pas assez de mémoire
pop ebp
pop edi
pop esi
pop edx
pop ecx
pop ebx
pop gs
pop fs
pop es
pop ds
mov eax,cer_pasm
iret

;**********************************************************************************************
sfs_lire_date_heure:
call lire_date_heure
iret


lire_date_heure:
;sortie:
;al=heure ah=minute bx=seconde (en millième)
;dl=jour dh=mois cx=année

mov dx,70h
mov al,04h   ;heures
out dx,al
inc dx
in al,dx
mov cl,al
mov ah,al
and ecx,0Fh
and ax,0F0F0h
shr al,1     ;/16 *8 =/2
shr ah,3     ;/16 *2 =/8
add cl,al
add cl,ah
mov bl,cl

mov dx,70h
mov al,02h   ;minutes
out dx,al
inc dx
in al,dx
mov cl,al
mov ah,al
and ecx,0Fh
and ax,0F0F0h
shr al,1     ;/16 *8 =/2
shr ah,3     ;/16 *2 =/8
add cl,al
add cl,ah
mov bh,cl
push ebx

mov dx,70h
mov al,00h    ;secondes
out dx,al
inc dx
in al,dx
mov cl,al
mov ah,al
and ecx,0Fh
and ax,0F0F0h
shr al,1     ;/16 *8 =/2
shr ah,3     ;/16 *2 =/8
add cl,al
add cl,ah
xor edx,edx
mov eax,1000
mul ecx
push eax

mov dx,70h
mov al,32h    ;siècles
out dx,al
inc dx
in al,dx
mov cl,al
mov ah,al
and ecx,0Fh
and ax,0F0F0h
shr al,1     ;/16 *8 =/2
shr ah,3     ;/16 *2 =/8
add cl,al
add cl,ah
xor edx,edx
mov eax,100
mul ecx
push eax
mov dx,70h
mov al,09h    ;années
out dx,al
inc dx
in al,dx
mov cl,al
mov ah,al
and ecx,0Fh
and ax,0F0F0h
shr al,1     ;/16 *8 =/2
shr ah,3     ;/16 *2 =/8
add cl,al
add cl,ah
pop eax
add ecx,eax
push ecx

mov dx,70h
mov al,07h     ;jour
out dx,al
inc dx
in al,dx
mov cl,al
mov ah,al
and ecx,0Fh
and ax,0F0F0h
shr al,1     ;/16 *8 =/2
shr ah,3     ;/16 *2 =/8
add cl,al
add cl,ah
mov bl,cl

mov dx,70h
mov al,08h     ;n° du mois
out dx,al
inc dx
in al,dx
mov cl,al
mov ah,al
and ecx,0Fh
and ax,0F0F0h
shr al,1     ;/16 *8 =/2
shr ah,3     ;/16 *2 =/8
add cl,al
add cl,ah
mov bh,cl
push ebx

pop edx
pop ecx
pop ebx
pop eax
ret





;**********************
sfs_set_service:   ; fixe le code de service de la tache, ah=code souhaité
pushad
push ds

mov dx,seldat
mov ds,dx
mov ebx,[ad_tache_exec]

mov dx,selramh
mov ds,dx
mov [ebx+code_service],ah

pop ds
popad
iret








;**********************
sfs_rech_service:
pushad              ;ah=code de service a rechercher cl=nombre de service a rechercher ds:edx=adresse ou ecrire la liste des services
push es

mov al,cl
mov bx,selramh
mov es,bx
xor ebx,ebx

boucle_sfs_rech_service:
es
cmp byte [ebx+type_dm],'F'
je fin_sfs_rech_service
es
cmp byte [ebx+type_dm],'T'
je ignore_sfs_rech_service
es
cmp byte [ebx+code_service],ah
jne ignore_sfs_rech_service

es
mov cx,[ebx+id_tache]
mov [edx],cx
dec al
jz fin_sfs_rech_service
add edx,2

ignore_sfs_rech_service:
es
mov ecx,[ebx+to_tache]
add ebx,ecx
jmp boucle_sfs_rech_service

fin_sfs_rech_service:
pop es
popad
iret






;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

;*******************************************************************************************
conv_cdeci_reg:    ;convertit la chaine décimal pointé par DS:EDX en nombre dans ECX
push ebx
push edx
push esi
xor eax,eax
xor ebx,ebx
mov ecx,10
mov esi,edx

boucle_conv_cdeci_reg:
mov bl,[esi]
cmp bl,"0"
jb fin_conv_cdeci_reg
cmp bl,"9"
ja fin_conv_cdeci_reg
sub bl,"0"
mul ecx
add eax,ebx
inc esi
jmp boucle_conv_cdeci_reg

fin_conv_cdeci_reg:
mov ecx,eax
pop esi
pop edx
pop ebx
xor eax,eax
iret



;*******************************************************************************************
conv_chex_reg:    ;convertit la chaine hexadécimal pointé par DS:EDX en nombre dans ECX
push edx
xor ecx,ecx

boucle_conv_chex_reg:
mov al,[edx]
cmp al,"0"
jb fin_conv_chex_reg
cmp al,"9"
jbe deci_conv_chex_reg
cmp al,"A"
jb fin_conv_chex_reg
cmp al,"F"
jbe max_conv_chex_reg
cmp al,"a"
jb fin_conv_chex_reg
cmp al,"f"
jbe min_conv_chex_reg
jmp fin_conv_chex_reg

deci_conv_chex_reg:
sub al,"0"
jmp suite_conv_chex_reg 

max_conv_chex_reg:
sub al,"A"-10
jmp suite_conv_chex_reg

min_conv_chex_reg:
sub al,"a"-10

suite_conv_chex_reg:
and eax,0Fh
shl ecx,4
add ecx,eax
inc edx
jmp boucle_conv_chex_reg

fin_conv_chex_reg:
pop edx
xor eax,eax
iret


conv_reg_deci32: ;convertit le nombre dans ecx en chaine décimal en ds:edx
push ecx
push edx
push esi
mov eax,ecx
mov esi,edx
mov ecx,10
mov dx,"$"
push dx

boucle1_conv_reg_deci32:
xor edx,edx
div ecx
add dl,"0"
push dx
cmp eax,0
jne boucle1_conv_reg_deci32

boucle2_conv_reg_deci32:
pop dx
cmp dx,"$"
je fin_conv_reg_deci32
mov [esi],dl
inc esi
jmp boucle2_conv_reg_deci32

fin_conv_reg_deci32:
mov byte[esi],0
pop esi
pop edx
pop ecx
xor eax,eax
iret

conv_reg_hexa32:
push edx
push ecx
shr ecx,24
call reg_hexa
pop ecx
add edx,2
push ecx
shr ecx,16
call reg_hexa
pop ecx
add edx,2
push ecx
shr ecx,8
call reg_hexa
pop ecx
add edx,2
call reg_hexa
pop edx
iret

conv_reg_hexa16:
push edx
push ecx
shr ecx,8
call reg_hexa
pop ecx
add edx,2
call reg_hexa
pop edx
iret

conv_reg_hexa8:
call reg_hexa
iret

reg_hexa:
push ecx
mov al,cl
shr al,4
and cl,0Fh
and al,0Fh
add cl,"0"
add al,"0"
cmp cl,"9"
jbe nccl_conv_reg_hexa8
add cl,7
nccl_conv_reg_hexa8:
cmp al,"9"
jbe ncal_conv_reg_hexa8
add al,7
ncal_conv_reg_hexa8:
mov [edx],al
mov [edx+1],cl
mov byte[edx+2],0
pop ecx
xor eax,eax
ret


