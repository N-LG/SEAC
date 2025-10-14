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
;al=12  lire compteur temps
;al=13  obtenir message systeme
;al=14  lire le journal
;al=15  copier des données dans la zone de copier/coller
;al=16  lire les données dans la zone de copier/coller
;al=17  effacer la zone de copier/coller
;al=18  lire le dossier de travail en cours
;al=19  recherche les taches que l'on as créer
;al=20  lire langue actuellement uttilisé

;*****************************************************************************************
;fonctions "pratique"
;al=100 convertir chaine decimale asciiz en entier 32bits
;al=101 convertir chaine hexadecimale en entier 32bits
;al=102 convertir entier 32bits en chaine decimale asciiz
;al=103 convertir entier 32bits en chaine hexadecimale asciiz
;al=104 convertir entier 16bits en chaine hexadecimale asciiz
;al=105 convertir entier 8bits en chaine hexadecimale asciiz

;al=108 convertir chaine asciiz en adresse ethernet 
;al=109 convertir chaine asciiz en adresse ipv4 
;al=110 convertir chaine asciiz en adresse ipv6 
;al=111 convertir adresse ethernet en chaine asciiz
;al=112 convertir adresse ipv4 en chaine asciiz
;al=113 convertir adresse ipv6 en chaine asciiz

;al=114 convertir chaine asciiz en GUID/UUID
;al=115 convertir GUID/UUID en chaine asciiz
;al=116 convertir données base64 en données binaires
;al=117 convertir données binaires en base64 
;al=118 convertir données binaires en base64url
;al=119 convertir temps unix vers date et heure
;al=120 convertir date et heure vers temps unix 

;al=150 calcul un crc16
;al=151 calcul un crc32
;al=152 décompresse une zone compressé par deflate
;al=153 décompresse un fichier compressé par deflate

;al=160 filtre une liste de nom


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
cmp al,12
je sfs_lire_cptsf
cmp al,13
je sfs_obt_msg
cmp al,14
je sfs_lire_journal
cmp al,15
je sfs_copier
cmp al,16
je sfs_coller
cmp al,17
je sfs_sup_copiercoller
cmp al,18
je sfs_lire_dossier
cmp al,19
je sfs_rech_cree
cmp al,20
je sfs_langue


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


cmp al,108
je conv_asciiz_ethernet
cmp al,109
je conv_asciiz_ipv4
cmp al,110
je conv_asciiz_ipv6
cmp al,111
je conv_ethernet_asciiz
cmp al,112
je conv_ipv4_asciiz
cmp al,113
je conv_ipv6_asciiz

cmp al,114
je conv_asciiz_guid
cmp al,115
je conv_guid_asciiz
cmp al,116
je conv_b64_bin
cmp al,117
je conv_bin_b64
cmp al,118
je conv_bin_b64url
cmp al,119
je conv_tunix_date
cmp al,120
je conv_date_tunix

cmp al,150
je sfs_crc16
cmp al,151
je sfs_crc32
cmp al,152
je sfs_inflate
cmp al,153
je sfs_inflate_fichier

cmp al,160
je sfs_filtre_liste

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
mov ax,seldat
mov ds,ax
add ecx,[cptsf]
boucle_sfs_pause:
int 62h
cmp [cptsf],ecx 
jb boucle_sfs_pause
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
cmp byte[ebx+1],0
je erprm__sfs_obt_optn
cmp byte[ebx+1]," "
je suite_sfs_obt_optn
cmp byte[ebx+1],34  ;code ascii du "
je suite2_sfs_obt_optn
cmp byte[ebx+1],"-"
je suite3_sfs_obt_optn
cmp ah,0
je opt_sfs_obt_optn
dec ah
suite_sfs_obt_optn:
inc ebx
cmp ebx,esi
jne boucle1_sfs_obt_optn
erprm__sfs_obt_optn:
es
mov byte[edx],0
pop es
pop ds
pop esi
pop edx
pop ecx
pop ebx
mov eax,cer_parami
iret


suite2_sfs_obt_optn:
cmp ah,0
je opt_sfs_obt_optn
dec ah
add ebx,2
boucle4_sfs_obt_optn:
cmp byte[ebx],34  ;code ascii du "
je suite_sfs_obt_optn
cmp byte[ebx],0
je erprm__sfs_obt_optn
inc ebx
jmp boucle4_sfs_obt_optn


suite3_sfs_obt_optn:
cmp ah,0
je opt_sfs_obt_optn
dec ah
cmp byte[ebx+2]," "
je suite_sfs_obt_optn
cmp word[ebx+3],223Ah   ;code ascii du :"
jne suite_sfs_obt_optn
add ebx,5
jmp boucle4_sfs_obt_optn


opt_sfs_obt_optn:
inc ebx
dec cl
cmp byte[ebx],34  ;code ascii du "
je apost_sfs_obt_optn
cmp byte[ebx],"-"
jne boucle2_sfs_obt_optn
cmp byte[ebx+1]," "
je boucle2_sfs_obt_optn
cmp word[ebx+2],223Ah   ;code ascii du :"
je lettre_sfs_obt_optn

boucle2_sfs_obt_optn:
mov al,[ebx]
cmp al,0
je fin_sfs_obt_optn
cmp al," "
je fin_sfs_obt_optn
es
mov [edx],al
inc ebx
inc edx
dec cl
jnz boucle2_sfs_obt_optn

fin_sfs_obt_optn:
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


apost_sfs_obt_optn:   ;option entre guillement
inc ebx
boucle3_sfs_obt_optn:
mov al,[ebx]
cmp al,0
je fin_sfs_obt_optn
cmp al,22h
je fin_sfs_obt_optn
es
mov [edx],al
inc ebx
inc edx
dec cl
jnz boucle3_sfs_obt_optn
jmp fin_sfs_obt_optn 



lettre_sfs_obt_optn:   ;option avec lettre et entre guillement
mov eax,[ebx]
es
mov [edx],eax
add ebx,4
add edx,4
boucle5_sfs_obt_optn:
mov al,[ebx]
cmp al,0
je fin_sfs_obt_optn
es
mov [edx],al
inc ebx
inc edx
cmp al,22h
je fin_sfs_obt_optn
dec cl
jnz boucle5_sfs_obt_optn
jmp fin_sfs_obt_optn 





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
cmp byte[ebx],34  ;code ascci du "
je ignore_sfs_obt_optl
cmp byte[ebx]," "
jne @f
cmp [ebx+1],ax
je opt_sfs_obt_optl
@@:
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
mov eax,cer_parami
iret

ignore_sfs_obt_optl:
inc ebx
cmp byte[ebx],0
je erreur_sfs_obt_optl
cmp byte[ebx],34  ;code ascci du "
jne ignore_sfs_obt_optl
inc ebx
jmp boucle1_sfs_obt_optl


opt_sfs_obt_optl:
add ebx,3
cmp byte[ebx],0
je fin_sfs_obt_optl
cmp byte[ebx]," "
je fin_sfs_obt_optl
cmp byte[ebx],":"
jne erreur_sfs_obt_optl
inc ebx
cmp byte[ebx],34   ;code ascii du "
jne boucle3_sfs_obt_optl
inc ebx

boucle2_sfs_obt_optl:
mov al,[ebx]
cmp al,0
je fin_sfs_obt_optl
cmp al,34  ;code ascci du "
je fin_sfs_obt_optl
es
mov [edx],al
inc ebx
inc edx
dec cl
jnz boucle2_sfs_obt_optl
jmp fin_sfs_obt_optl


boucle3_sfs_obt_optl:
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
jnz boucle3_sfs_obt_optl

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
pushad
push es
mov ax,seldat
mov es,ax
es
or byte[at_csl],1
es
mov ebx,[ad_tache_exec]
mov ax,selramh
mov es,ax
mov ecx,100h
add ebx,descriptif_tache
add ecx,ebx

sfs_mod_des_t_boucle:
mov al,[edx]
cmp al,0
je sfs_mod_des_t_fin
es
mov [ebx],al
inc ebx
inc edx
cmp ebx,ecx
jne sfs_mod_des_t_boucle

dec ebx
es
mov byte[ebx],0
pop es
popad
iret


sfs_mod_des_t_fin:
es
mov [ebx],al
inc ebx
cmp ebx,ecx
jne sfs_mod_des_t_fin
pop es
popad
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

;ajuste la granularité au besoin
test ecx,0FFF00000h
jz @f
add ecx,0FFFh
and ecx,0FFFFF000h
@@:

attent_sfs_mod_seg: ;attent que la tache principale ait finis de mettre a jour l'écran
int 62h
fs
test byte[at_vid],08h
jnz attent_sfs_mod_seg

fs
mov ebx,[ad_tache_exec]

cmp dx,sel_dat1
je sfs_mod_seg_dat1
cmp dx,sel_dat2
je sfs_mod_seg_dat2
cmp dx,sel_dat3
je sfs_mod_seg_dat3
cmp dx,sel_dat4
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





fs                      ;met a jour l'adresse dans la table d'execution
mov dx,[id_tache_exec]
xor ebx,ebx
boucle_majtable_exec:
fs
cmp dx,[ebx+table_exec_id]
je ok_majtable_exec
add ebx,16
fs
cmp ebx,[max_table_exec]
jne boucle_majtable_exec
;jmp fin_sfs_mod_seg

ok_majtable_exec:
fs
mov eax,[ad_tache_exec]
fs
mov [ebx+table_exec_ad],eax


fs
mov esi,[ad_tache_exec]
call maj_ldtache

lldt [esi+sel_ldt_tache] ;on recharge la bonne LDT

mov ax,sel_pilet0 ;on recharge le segment de la pile pour mettre a jour les données 
mov ss,ax


fs                      ;met a jour l'adresse dans la table des fenetres
mov ax,[id_tache_exec]
mov ebx,table_ecran_id
fs
mov cx,[nb_ecran]
fs
mov edx,[ad_tache_exec]

@@:
fs
cmp [ebx],ax
je @f
add ebx,32
dec cx
jnz @b
jmp fin_sfs_mod_seg 

@@:
fs
mov [ebx+table_ecran_ad-table_ecran_id],edx




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
;bh=heure bl=minute si=seconde (en millième)
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
mov bh,cl

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
mov bl,cl
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

mov edx,ebx
pop ecx
pop esi
pop ebx
xor eax,eax
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
pushad              ;ah=code de service a rechercher (0=liste toutes les applications) cl=nombre de service a rechercher ds:edx=adresse ou ecrire la liste des services
push es

mov al,cl
mov bx,selramh
mov es,bx
xor ebx,ebx

push edx
boucle_sfs_rech_service:
es
cmp byte [ebx+type_dm],'F'
je fin_sfs_rech_service
es
cmp byte [ebx+type_dm],'T'
jne ignore_sfs_rech_service
cmp ah,0
je @f
es
cmp byte [ebx+code_service],ah
jne ignore_sfs_rech_service
@@:

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
;remet les taches dans l'ordre
pop esi
mov edi,esi
add edi,2
cmp esi,edx
je fin2_sfs_rech_service 
cmp edi,edx
je fin2_sfs_rech_service 

boucle2_sfs_rech_service:
mov ax,[esi]
cmp ax,[edi]
jb @f
xchg [edi],ax
mov [esi],ax
@@:
add edi,2
cmp edi,edx
jne boucle2_sfs_rech_service
add esi,2
mov edi,esi
add edi,2
cmp edi,edx
jne boucle2_sfs_rech_service



fin2_sfs_rech_service:
pop es
popad
iret



;**************************
sfs_lire_cptsf:   ;compteur temps 64 bit (32 effectif pour le moment)
push ds
mov ax,seldat
mov ds,ax
mov eax,[cptsf]
xor edx,edx
pop ds
iret



;****************************
sfs_obt_msg:    ;lire la chaine qui correspond au message ah=type de message (0=systeme 1=erreur)  cl=numéros de message  ds:edx=zone ou copier le texte   ch=nombre d'octet max 0=256
pushad
push es
mov bx,seldat
mov es,bx

cmp ah,0
je sfs_obt_msg0
cmp ah,1
je sfs_obt_msg1
jmp sfs_obt_msgparami

sfs_obt_msg0:
mov ebx,ad_msg_syst
jmp boucle1_sfs_obt_msg

sfs_obt_msg1:
mov ebx,ad_msg_erreur


boucle1_sfs_obt_msg:
cmp cl,0
je boucle2_sfs_obt_msg
es
cmp byte[ebx],0
jne pazero_sfs_obt_msg
dec cl
pazero_sfs_obt_msg:
inc ebx
jmp boucle1_sfs_obt_msg

boucle2_sfs_obt_msg:
es
mov al,[ebx]
mov [edx],al
cmp al,0
je fin_sfs_obt_msg
inc ebx
inc edx
dec ch
jnz boucle2_sfs_obt_msg

fin_sfs_obt_msg:
pop es
popad
xor eax,eax
iret

sfs_obt_msgparami:
pop es
popad
mov eax,cer_parami
iret

;********************************************************
sfs_lire_journal:    ;es:edx ecx max
push esi
push edi
push ds
mov ax,seldat
mov ds,ax
mov esi,[ad_jcsl]
mov eax,[to_jcsl]

cmp eax,ecx
ja erreur_sfs_lire_journal

mov cx,selramh
mov ds,cx
mov ecx,eax
mov edi,edx
cld
rep movsb

pop ds
pop edi
pop esi
mov ecx,eax
xor eax,eax
iret

erreur_sfs_lire_journal:
pop ds
pop edi
pop esi
mov ecx,eax
mov eax,cer_pasm
iret



;***************************************************
;copier    ;es:edx ecx
sfs_copier:
pushad
push ds
push es
push fs
mov ax,es
mov ds,ax
mov ax,selramh
mov es,ax
mov ax,seldat
mov fs,ax

fs
mov ebx,[ad_copiercoller]
cmp ebx,0
jne pascreerzone_sfs_copier
push ecx  ;si la zone de copier coller n'existe pas on la créer
add ecx,15
and ecx,0FFFFFFF0h
call resmem
pop ecx
jc erreur_sfs_copier    
fs
mov [ad_copiercoller],ebx
es
mov dword[ebx+8],czm_cc    ;code zone mémoire copier-coller

pascreerzone_sfs_copier:
es
mov eax,[ebx+4]
sub eax,10h
cmp eax,ecx
jae ok_sfs_copier 
call libmem    ;si la zone est trop petite on la supprime 
;jc erreur_sfs_copier   
push ecx
add ecx,15
and ecx,0FFFFFFF0h
call resmem          ;et on en créer une autre
pop ecx
jc erreur_sfs_copier  
fs
mov [ad_copiercoller],ebx
es
mov dword[ebx+8],czm_cc    ;code zone mémoire copier-coller

ok_sfs_copier:   
es
mov [ebx+12],ecx    ;on enregistre la taille exacte des données
mov esi,edx
mov edi,ebx
add edi,10h
cld              ;et on copie les données
rep movsb
pop fs
pop es
pop ds
popad
xor eax,eax
iret

erreur_sfs_copier:
pop fs
pop es
pop ds
popad
mov eax,cer_pasm
iret






;************************************************
;coller
sfs_coller:
push ebx
push esi
push edi
push ds
push fs
mov ax,selramh
mov ds,ax
mov ax,seldat
mov fs,ax

fs
mov ebx,[ad_copiercoller]
cmp ebx,0
je rac_sfs_coller
cmp [ebx+12],ecx
ja erreur_sfs_coller

mov ecx,[ebx+12]
mov esi,ebx
add esi,10h
mov edi,edx
cld              ;et on copie les données
rep movsb
mov ecx,[ebx+12]

pop fs
pop ds
pop edi
pop esi
pop ebx
xor eax,eax
iret

rac_sfs_coller: ;rien a coller
pop fs
pop ds
pop edi
pop esi
pop ebx
xor eax,eax
xor ecx,ecx
iret

erreur_sfs_coller:
mov ecx,[ebx+12]
pop fs
pop ds
pop edi
pop esi
pop ebx
mov eax,cer_pasm
iret



;*******************************************
;suppression données coper coller
sfs_sup_copiercoller:
pushad
push ds
mov ax,seldat
mov ds,ax
mov ebx,[ad_copiercoller]
cmp ebx,0
je fin_sfs_sup_copiercoller 
call libmem
mov dword[ad_copiercoller],0
fin_sfs_sup_copiercoller:
pop ds
popad
iret



;*********************************************
sfs_lire_dossier:       ;ecrit l'adresse du dossier de travail dans ds:edx (512 octets)
push ecx
push esi
push edi
push ds
push es
mov ax,ds
mov es,ax
mov ax,seldat
mov ds,ax
mov esi,ad_repertoire
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



;**********************
sfs_rech_cree:      ;recherche toutes les tache que l'on a créer
pushad              ;cl=nombre de tache a rechercher ds:edx=adresse ou ecrire la liste des taches
push es

mov esi,edx

;attend que toutes les taches ait été créer
mov bx,seldat
mov es,bx
@@:
int 62h
es
cmp word[to_ztcmd],0
jne @b
es
test byte[at_csl],10h
jnz @b
es
mov dx,[id_tache_exec]

mov bx,selramh
mov es,bx
xor ebx,ebx

boucle_sfs_rech_cree:
es
cmp byte [ebx+type_dm],'F'
je fin_sfs_rech_cree
es
cmp byte [ebx+type_dm],'T'
jne ignore_sfs_rech_cree
es
cmp [ebx+id_maitre],dx
jne ignore_sfs_rech_cree
es
mov ax,[ebx+id_tache]
mov [esi],ax
dec cl
jz fin_sfs_rech_cree
add esi,2

ignore_sfs_rech_cree:
es
mov eax,[ebx+to_tache]
add ebx,eax
jmp boucle_sfs_rech_cree

fin_sfs_rech_cree:
pop es
popad
iret



;*********************************************
sfs_langue:       ;récupère le code de la langue actuellement employé
push ds
mov ax,seldat
mov ds,ax
mov eax,[code_langue]
pop ds
iret






;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§



;*******************************************************************************************
conv_cdeci_reg:    ;convertit la chaine décimal pointé par DS:EDX en nombre dans ECX
call sf_conv_cdeci_reg
iret

sf_conv_cdeci_reg:
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
ret



;*******************************************************************************************
conv_chex_reg:    ;convertit la chaine hexadécimal pointé par DS:EDX en nombre dans ECX
call sf_conv_chex_reg
iret

sf_conv_chex_reg:
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
ret

;***************************************************************************
conv_reg_deci32: ;convertit le nombre dans ecx en chaine décimal en ds:edx
call sf_conv_reg_deci32
iret

sf_conv_reg_deci32:
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
ret


;***************************
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




;******************************************
erreur_conv_adresse:
popad
mov eax,cer_parami
iret


;********************************************
conv_asciiz_ethernet:   ;ds:ecx vers ds:edx
pushad

mov esi,edx
mov al,[esi]
boucle0_conv_asciiz_ethernet:
cmp al,"0"
jb erreur_conv_adresse
cmp al,"9"
jbe ok_conv_asciiz_ethernet
cmp al,"A"
jb erreur_conv_adresse
cmp al,"F"
jbe ok_conv_asciiz_ethernet
cmp al,"a"
jb erreur_conv_adresse
cmp al,"f"
jbe ok_conv_asciiz_ethernet
inc esi
mov al,[esi]
cmp al,0
jne boucle0_conv_asciiz_ethernet
ok_conv_asciiz_ethernet:

mov esi,edx
mov edi,ecx

mov edx,esi
call sf_conv_chex_reg
mov [edi],cl
inc edi

boucle1_conv_asciiz_ethernet:
cmp byte[esi],"-"
je point1_conv_asciiz_ethernet
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle1_conv_asciiz_ethernet

point1_conv_asciiz_ethernet:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFFFF00h
jnz erreur_conv_adresse
mov [edi],cl
inc edi

boucle2_conv_asciiz_ethernet:
cmp byte[esi],"-"
je point2_conv_asciiz_ethernet
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle2_conv_asciiz_ethernet

point2_conv_asciiz_ethernet:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFFFF00h
jnz erreur_conv_adresse
mov [edi],cl
inc edi

boucle3_conv_asciiz_ethernet:
cmp byte[esi],"-"
je point3_conv_asciiz_ethernet
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle3_conv_asciiz_ethernet

point3_conv_asciiz_ethernet:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFFFF00h
jnz erreur_conv_adresse
mov [edi],cl
inc edi

boucle4_conv_asciiz_ethernet:
cmp byte[esi],"-"
je point4_conv_asciiz_ethernet
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle4_conv_asciiz_ethernet

point4_conv_asciiz_ethernet:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFFFF00h
jnz erreur_conv_adresse
mov [edi],cl
inc edi

boucle5_conv_asciiz_ethernet:
cmp byte[esi],"-"
je point5_conv_asciiz_ethernet
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle5_conv_asciiz_ethernet

point5_conv_asciiz_ethernet:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFFFF00h
jnz erreur_conv_adresse
mov [edi],cl


popad
xor eax,eax
iret





;******************************************
conv_asciiz_ipv4:
pushad
mov esi,edx
boucle0_conv_asciiz_ipv4:
cmp byte[esi],"."
je @f
cmp byte[esi],0
je ok_conv_asciiz_ipv4
cmp byte[esi],"0"
jb conv_asciiz_ipv4_dns
cmp byte[esi],"9"
ja conv_asciiz_ipv4_dns
@@:
inc esi
jmp boucle0_conv_asciiz_ipv4

ok_conv_asciiz_ipv4:
mov esi,edx
mov edi,ecx

mov edx,esi
call sf_conv_cdeci_reg
mov [edi],cl


boucle1_conv_asciiz_ipv4:
cmp byte[esi],"."
je point1_conv_asciiz_ipv4
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle1_conv_asciiz_ipv4

point1_conv_asciiz_ipv4:
inc esi
mov edx,esi
call sf_conv_cdeci_reg
test ecx,0FFFFFF00h
jnz erreur_conv_adresse
mov [edi+1],cl


boucle2_conv_asciiz_ipv4:
cmp byte[esi],"."
je point2_conv_asciiz_ipv4
cmp byte[esi],0
je conv_asciiz_ipv4_dns
inc esi
jmp boucle2_conv_asciiz_ipv4

point2_conv_asciiz_ipv4:
inc esi
mov edx,esi
call sf_conv_cdeci_reg
test ecx,0FFFFFF00h
jnz erreur_conv_adresse
mov [edi+2],cl


boucle3_conv_asciiz_ipv4:
cmp byte[esi],"."
je point3_conv_asciiz_ipv4
cmp byte[esi],0
je conv_asciiz_ipv4_dns
inc esi
jmp boucle3_conv_asciiz_ipv4

point3_conv_asciiz_ipv4:
inc esi
mov edx,esi
call sf_conv_cdeci_reg
test ecx,0FFFFFF00h
jnz erreur_conv_adresse
mov [edi+3],cl

popad
xor eax,eax
iret

conv_asciiz_ipv4_dns:
popad
pushad

;reserve une petite zone de mémoire
push ecx
mov ecx,1024
call resmem
pop ecx
jc erreur_conv_adresse
mov ebp,ebx
add ebp,20h


;sauvegarde les param d'entrée
push ds
push es
push ds
mov ax,selramh
mov ds,ax
mov es,ax
pop eax
mov [ebx+10h],edx  ;chaine d'entrée
mov [ebx+14h],ecx  ;sortie
mov [ebx+18h],ax   ;selecteur


;cherche s'il y as un serveur dns
mov al,11
mov ah,8     ;code service 
mov cl,16
mov edx,ebp
int 61h
cmp word[edx],0
je erreur_conv_adresse2


;etablire une connexion
mov al,0
mov bx,[edx]
mov ecx,1024
mov edx,1
mov esi,0
mov edi,0
int 65h
cmp eax,0
jne erreur_conv_adresse2


;crée la requete
push ds
mov edi,ebp
sub edi,10h
mov esi,[edi]
mov ax,[edi+8]
mov ds,ax
add  edi,10h

mov ecx,esi
@@:
mov al,[ecx]
inc ecx
cmp al,0
jne @b
sub ecx,esi

es
mov byte[edi],1 ;code pour demander un RR
es
mov word[edi+2],1 ;type de RR souhaité
es
mov [edi+4],ecx  ;taille du nom
add edi,8
push ecx
cld
rep movsb  ;nom
pop ecx
pop ds

;envoie une requete
mov al,5
add ecx,8
mov esi,ebp
mov edi,0
int 65h
cmp eax,0
jne erreur_conv_adresse2


;attend la réponse
mov al,8
mov ecx,8000  ;20s
int 65h
cmp eax,cer_ddi
jne erreur_conv_adresse2


;lit la réponse du programme
mov al,4
mov ecx,20h
mov esi,0
mov edi,ebp
int 65h
cmp eax,0
jne erreur_conv_adresse2

;ferme la connexion
mov al,1
int 65h

;décode la réponse
cmp byte[edi],81h
jne erreur_conv_adresse2
cmp word[edi+1],100h
jne erreur_conv_adresse2

mov eax,[edi+11]
sub edi,10h
mov esi,[edi+4]
pop es
pop ds
mov [esi],eax


;libère la mémoire
mov ebx,ebp
sub ebx,20h
call libmem
popad
xor eax,eax
iret


erreur_conv_adresse2:
mov ebx,ebp
sub ebx,20h
call libmem
pop es
pop ds
jmp erreur_conv_adresse 

;******************************************
conv_asciiz_ipv6:
pushad

mov esi,edx
mov al,[esi]
boucle0_conv_asciiz_ipv6:
cmp al,"0"
jb erreur_conv_adresse
cmp al,"9"
jbe ok_conv_asciiz_ipv6
cmp al,"A"
jb erreur_conv_adresse
cmp al,"F"
jbe ok_conv_asciiz_ipv6
cmp al,"a"
jb erreur_conv_adresse
cmp al,"f"
jbe ok_conv_asciiz_ipv6
inc esi
mov al,[esi]
cmp al,0
jne boucle0_conv_asciiz_ipv6
ok_conv_asciiz_ipv6:

mov esi,edx
mov edi,ecx

mov edx,esi
call sf_conv_chex_reg
mov [edi],ch
mov [edi+1],cl
add edi,2

boucle1_conv_asciiz_ipv6:
cmp byte[esi],":"
je point1_conv_asciiz_ipv6
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle1_conv_asciiz_ipv6

point1_conv_asciiz_ipv6:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFF0000h
jnz erreur_conv_adresse
mov [edi],ch
mov [edi+1],cl
add edi,2

boucle2_conv_asciiz_ipv6:
cmp byte[esi],":"
je point2_conv_asciiz_ipv6
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle2_conv_asciiz_ipv6

point2_conv_asciiz_ipv6:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFF0000h
jnz erreur_conv_adresse
mov [edi],ch
mov [edi+1],cl
add edi,2

boucle3_conv_asciiz_ipv6:
cmp byte[esi],":"
je point3_conv_asciiz_ipv6
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle3_conv_asciiz_ipv6

point3_conv_asciiz_ipv6:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFF0000h
jnz erreur_conv_adresse
mov [edi],ch
mov [edi+1],cl
add edi,2

boucle4_conv_asciiz_ipv6:
cmp byte[esi],":"
je point4_conv_asciiz_ipv6
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle4_conv_asciiz_ipv6

point4_conv_asciiz_ipv6:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFF0000h
jnz erreur_conv_adresse
mov [edi],ch
mov [edi+1],cl
add edi,2

boucle5_conv_asciiz_ipv6:
cmp byte[esi],":"
je point5_conv_asciiz_ipv6
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle5_conv_asciiz_ipv6

point5_conv_asciiz_ipv6:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFF0000h
jnz erreur_conv_adresse
mov [edi],ch
mov [edi+1],cl
add edi,2

boucle6_conv_asciiz_ipv6:
cmp byte[esi],":"
je point6_conv_asciiz_ipv6
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle6_conv_asciiz_ipv6

point6_conv_asciiz_ipv6:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFF0000h
jnz erreur_conv_adresse
mov [edi],ch
mov [edi+1],cl
add edi,2

boucle7_conv_asciiz_ipv6:
cmp byte[esi],":"
je point7_conv_asciiz_ipv6
cmp byte[esi],0
je erreur_conv_adresse
inc esi
jmp boucle7_conv_asciiz_ipv6

point7_conv_asciiz_ipv6:
inc esi
mov edx,esi
call sf_conv_chex_reg
test ecx,0FFFF0000h
jnz erreur_conv_adresse
mov [edi],ch
mov [edi+1],cl

popad
xor eax,eax
iret


;******************************************
conv_ethernet_asciiz:
pushad
mov ebx,ecx
mov cl,[ebx]
call reg_hexa
mov byte[edx+2],"-"
add edx,3
mov cl,[ebx+1]
call reg_hexa
mov byte[edx+2],"-"
add edx,3
mov cl,[ebx+2]
call reg_hexa
mov byte[edx+2],"-"
add edx,3
mov cl,[ebx+3]
call reg_hexa
mov byte[edx+2],"-"
add edx,3
mov cl,[ebx+4]
call reg_hexa
mov byte[edx+2],"-"
add edx,3
mov cl,[ebx+5]
call reg_hexa
popad
iret


;***************************************
conv_ipv4_asciiz:
pushad
mov esi,ecx
mov edi,edx

xor ecx,ecx
mov cl,[esi]
mov edx,edi
call sf_conv_reg_deci32

boucle1_conv_ipv4_asciiz:
cmp byte[edi],0
je point1_conv_ipv4_asciiz
inc edi
jmp boucle1_conv_ipv4_asciiz

point1_conv_ipv4_asciiz:
mov byte[edi],"."
inc edi
xor ecx,ecx
mov cl,[esi+1]
mov edx,edi
call sf_conv_reg_deci32

boucle2_conv_ipv4_asciiz:
cmp byte[edi],0
je point2_conv_ipv4_asciiz
inc edi
jmp boucle2_conv_ipv4_asciiz

point2_conv_ipv4_asciiz:
mov byte[edi],"."
inc edi
xor ecx,ecx
mov cl,[esi+2]
mov edx,edi
call sf_conv_reg_deci32

boucle3_conv_ipv4_asciiz:
cmp byte[edi],0
je point3_conv_ipv4_asciiz
inc edi
jmp boucle3_conv_ipv4_asciiz

point3_conv_ipv4_asciiz:
mov byte[edi],"."
inc edi
xor ecx,ecx
mov cl,[esi+3]
mov edx,edi
call sf_conv_reg_deci32

popad
xor eax,eax
iret




;**********************************************
conv_ipv6_asciiz:
pushad
mov ebx,ecx
mov cl,[ebx]
call reg_hexa
add edx,2
mov cl,[ebx+1]
call reg_hexa
mov byte[edx+2],":"
add edx,3
mov cl,[ebx+2]
call reg_hexa
add edx,2
mov cl,[ebx+3]
call reg_hexa
mov byte[edx+2],":"
add edx,3
mov cl,[ebx+4]
call reg_hexa
add edx,2
mov cl,[ebx+5]
call reg_hexa
mov byte[edx+2],":"
add edx,3
mov cl,[ebx+6]
call reg_hexa
add edx,2
mov cl,[ebx+7]
call reg_hexa
mov byte[edx+2],":"
add edx,3
mov cl,[ebx+8]
call reg_hexa
add edx,2
mov cl,[ebx+9]
call reg_hexa
mov byte[edx+2],":"
add edx,3
mov cl,[ebx+10]
call reg_hexa
add edx,2
mov cl,[ebx+11]
call reg_hexa
mov byte[edx+2],":"
add edx,3
mov cl,[ebx+12]
call reg_hexa
add edx,2
mov cl,[ebx+13]
call reg_hexa
mov byte[edx+2],":"
add edx,3
mov cl,[ebx+14]
call reg_hexa
add edx,2
mov cl,[ebx+15]
call reg_hexa
popad
iret










;***************************************
conv_asciiz_guid:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
iret


;***************************************
conv_guid_asciiz:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
iret








;***************************************
conv_b64_bin:
pushad
cmp ecx,0
je erreur_base64_bin
xor edx,edx
boucle_base64_bin:
mov al,[esi]
cmp al,"+"
je sp1_base64_bin
cmp al,"-"
je sp1_base64_bin
cmp al,"/"
je sp2_base64_bin
cmp al,"0"
jb erreur_base64_bin
cmp al,"9"
jbe num_base64_bin
cmp al,"="
je fin_base64_bin
cmp al,"A"
jb erreur_base64_bin
cmp al,"Z"
jbe maj_base64_bin
cmp al,"_"
je sp2_base64_bin
cmp al,"a"
jb erreur_base64_bin
cmp al,"z"
jbe min_base64_bin

erreur_base64_bin:
popad
mov eax,cer_parami
iret

num_base64_bin:
add al,4 ;sub al,"0"(48) add al,52
jmp suite1_base64_bin 

maj_base64_bin:
sub al,"A" ;65
jmp suite1_base64_bin 

min_base64_bin:
sub al,71 ;sub al,"a"(97) add al,26
jmp suite1_base64_bin 

sp1_base64_bin:
mov al,62
jmp suite1_base64_bin 

sp2_base64_bin:
mov al,63

suite1_base64_bin:
and eax,3Fh
cmp dl,0
je o1_base64_bin
cmp dl,1
je o2_base64_bin
cmp dl,2
je o3_base64_bin

es  
or [edi+2],al
xor dl,dl 
add edi,3
jmp suite2_base64_bin

o1_base64_bin:
shl al,2
es
mov [edi],al 
inc dl
jmp suite2_base64_bin

o2_base64_bin:
shl eax,4
es  
or [edi],ah
es
mov [edi+1],al
inc dl
jmp suite2_base64_bin

o3_base64_bin:
shl eax,6
es  
or [edi+1],ah
es
mov [edi+2],al
inc dl 

suite2_base64_bin:
inc esi
dec ecx
jnz boucle_base64_bin 

fin_base64_bin:
popad
xor eax,eax
iret


;***************************************
conv_bin_b64:
pushad
mov dl,0
jmp debut_conv_bin_b64


;***************************************
conv_bin_b64url:
pushad
mov dl,1

debut_conv_bin_b64:
cmp ecx,0
je erreur_base64_bin

boucle_bin_base64:
shr eax,2
mov al,[esi]
and al,03Fh
call unite_bin_base64
es
mov [edi],al

mov ax,[esi]
xchg al,ah
shr eax,4
and al,03Fh
call unite_bin_base64
es
mov [edi+1],al

mov ax,[esi+1]
xchg al,ah
shr eax,6
and al,03Fh
call unite_bin_base64
es
mov [edi+2],al

mov al,[esi+2]
and al,03Fh
call unite_bin_base64
es
mov [edi+3],al

add esi,3
add edi,4
sub ecx,3
cmp ecx,3
jae boucle_bin_base64

cmp ecx,1
je fin1_base64_bin
cmp ecx,2
je fin2_base64_bin
popad
xor eax,eax
iret

fin1_base64_bin:
mov al,[esi]
shl al,2
and al,03Fh
call unite_bin_base64
es
mov [edi],al

mov ax,[esi]
xchg al,ah
shr eax,4
and al,03h
call unite_bin_base64
es
mov [edi+1],al

es
mov byte[edi+2],"="
es
mov byte[edi+3],"="
popad
xor eax,eax
iret

fin2_base64_bin:
mov al,[esi]
shr al,2
and al,03Fh
call unite_bin_base64
es
mov [edi],al

mov ax,[esi]
xchg al,ah
shr eax,4
and al,03Fh
call unite_bin_base64
es
mov [edi+1],al

mov al,[esi+1]
xchg al,ah
shr eax,6
and al,0Fh
call unite_bin_base64
es
mov [edi+2],al
es
mov byte[edi+3],"="

popad
xor eax,eax
iret



;****************************** 
unite_bin_base64:
cmp al,26
jb unite_bin_base64_1
cmp al,52
jb unite_bin_base64_2
cmp al,62
jb unite_bin_base64_3
cmp al,62
je unite_bin_base64_sp1
cmp al,63
je unite_bin_base64_sp2

unite_bin_base64_1:
add al,"A"
ret

unite_bin_base64_2:
add al,71
ret

unite_bin_base64_3:
sub al,4
ret

unite_bin_base64_sp1:
cmp dl,0
jne unite_bin_base64_sp3
mov al,"+"
ret

unite_bin_base64_sp2:
cmp dl,0
jne unite_bin_base64_sp4
mov al,"/"
ret

unite_bin_base64_sp3:
mov al,"-"
ret

unite_bin_base64_sp4:
mov al,"_"
ret





;****************************************
conv_tunix_date:     ;conversion compteur temps unix vers date
mov eax,ecx
mov ecx,86400
div ecx
;eax=jours ;edx=secondes

;calcul de l'année
push edx
mov ecx,1970
boucle1_conv_tunix_date:
mov edx,365
call test_bs
jnc @f
inc edx
@@:
cmp eax,edx
jb @f
sub eax,edx
inc ecx
jmp boucle1_conv_tunix_date

@@:    ;ecx=année ;eax=jour


;calcul mois
mov ebx,365-31
call test_bs
jnc @f
inc ebx
@@:
mov dh,12

boucle2_conv_tunix_date:
cmp eax,ebx
jae mois_ok_conv_tunix_date 
dec dh
sub ebx,31

cmp dh,4
je moisp_conv_tunix_date
cmp dh,6
je moisp_conv_tunix_date
cmp dh,9
je moisp_conv_tunix_date
cmp dh,11
je moisp_conv_tunix_date

;mois de fevrier
cmp dh,2
jne boucle2_conv_tunix_date
add ebx,3

;mois de fevrier bisextile
call test_bs
jnc boucle2_conv_tunix_date
dec ebx
jmp boucle2_conv_tunix_date

moisp_conv_tunix_date:
inc ebx
jmp boucle2_conv_tunix_date


mois_ok_conv_tunix_date:
sub eax,ebx
mov dl,al
inc dl
pop eax  ;eax=seconde cx=années dh=mois dl=jours
push ecx
push edx

xor edx,edx
mov ecx,3600
div ecx
push eax ;heures
mov eax,edx
xor edx,edx
mov ecx,60
div ecx
push eax ;minutes

mov eax,edx
xor edx,edx
mov ecx,1000
mul ecx
mov esi,eax ;esi=milisecondes

pop ebx
pop edx
mov bh,dl
pop edx
pop ecx
xor eax,eax
iret


;*********************************
conv_date_tunix:      ;conversion seact epoch
push ecx
push edx
push ebx
push ebx

xor edx,edx
mov eax,esi
mov ecx,1000
div ecx
mov esi,eax
pop eax
mov ecx,60
and eax,0FFh
mul ecx
add esi,eax
pop eax
mov al,ah
mov ecx,3600
and eax,0FFh
mul ecx
add esi,eax
pop edx
pop ecx


xor edi,edi


;calcul du nombre de jour par rapport au mois
boucle1_conv_date_tunix:
cmp dh,1
je boucle2_conv_date_tunix
dec dh
add edi,31

cmp dh,4
je moisp_conv_date_tunix
cmp dh,6
je moisp_conv_date_tunix
cmp dh,9
je moisp_conv_date_tunix
cmp dh,11
je moisp_conv_date_tunix

cmp dh,2
jne boucle1_conv_date_tunix
sub edi,3
call test_bs
jnc boucle1_conv_date_tunix
inc edi
jmp boucle1_conv_date_tunix

moisp_conv_date_tunix:
dec edi
jmp boucle1_conv_date_tunix


;calcul du nomre de jour par rapport a l'année
boucle2_conv_date_tunix:
cmp ecx,1970
je @f
dec ecx
add edi,365
call test_bs
jnc boucle2_conv_date_tunix
inc edi
jmp boucle2_conv_date_tunix

@@:
and edx,0FFh
add edi,edx
dec edi

mov eax,edi
mov ecx,86400
mul ecx
add eax,esi
adc edx,0
iret




;**************************
test_bs:   ;test si l'année dans cx est bisextile cf=1 si bisextile
push eax
push ebx
push edx
xor eax,eax
xor edx,edx
mov ax,cx
mov ebx,400
div ebx
cmp edx,0
je ok_bs

xor eax,eax
xor edx,edx
mov ax,cx
mov ebx,4
div ebx
cmp edx,0
jne non_bs

xor eax,eax
xor edx,edx
mov ax,cx
mov ebx,100
div ebx
cmp edx,0
je non_bs

ok_bs:
stc
pop edx
pop ebx
pop eax
ret

non_bs:
clc
pop edx
pop ebx
pop eax
ret








;***********************************************************************************************
sfs_crc16:
;Les argument ax et dx change suivant le domaine d'uttilisation du crc
;pour l'instant je ne suis sûr que des valeurs uttilisé par 
;modbus: bx=0FFFFh dx=0A001h

;png:  ebx=FFFFFFFF edx=0EDB88320h
;ds:esi=début de la chaine

;ecx=Nb d'octet de la chaine

;bx=valeur initiale du CRC

;dx=polynome sans bit de poid fort avec ordre des bit inversé

;sortie: ax=valeur du CRC


push ecx
push edx
push esi
mov ax,bx

boucle_sfs_crc16:
xor al,[esi]


shr ax,1

jnc @f
xor ax,dx

@@:
shr ax,1

jnc @f
xor ax,dx

@@:
shr ax,1

jnc @f
xor ax,dx

@@:
shr ax,1

jnc @f
xor ax,dx

@@:
shr ax,1

jnc @f
xor ax,dx

@@:
shr ax,1

jnc @f
xor ax,dx

@@:
shr ax,1

jnc @f
xor ax,dx

@@:
shr ax,1

jnc @f
xor ax,dx

@@:
inc esi

dec ecx

jnz boucle_sfs_crc16

not ax
pop esi
pop edx
pop ecx
and eax,0FFFFh
iret







sfs_crc32:
push ecx
push edx
push esi
mov eax,ebx

boucle_sfs_crc32:
xor al,[esi]


shr eax,1

jnc @f
xor eax,edx

@@:
shr eax,1

jnc @f
xor eax,edx

@@:
shr eax,1

jnc @f
xor eax,edx

@@:
shr eax,1

jnc @f
xor eax,edx

@@:
shr eax,1

jnc @f
xor eax,edx

@@:
shr eax,1

jnc @f
xor eax,edx

@@:
shr eax,1

jnc @f
xor eax,edx

@@:
shr eax,1

jnc @f
xor eax,edx

@@:
inc esi

dec ecx

jnz boucle_sfs_crc32

not eax
pop esi
pop edx
pop ecx
iret





;****************************************************************************************************

macro av_bit val
{
add cl,val
test cl,0F8h
jz @f
push ecx
shr ecx,3
and ecx,1Fh
add esi,ecx
pop ecx
@@:
and cl,7 
}


macro sfs_inflate_litarbre val
{
mov eax,[esi]
shr eax,cl
and eax,07h
av_bit 3
fs
mov [ebx+arbre_inflate_tailles+val],al
dec dl
jz sfs_inflate_finpermute
}




arbre_inflate_fichier1 equ 10h
arbre_inflate_adresse1 equ 14h
arbre_inflate_fichier2 equ 18h
arbre_inflate_adresse2 equ 1Ch

arbre_inflate_tailles      equ 20h



arbre_inflate_literal      equ 200h
arbre_inflate_dist         equ 204h
arbre_inflate_bloc         equ 208h
arbre_inflate_HLIT         equ 20Ch
arbre_inflate_HDIST        equ 210h
arbre_inflate_taillechaine equ 214h

arbre_inflate_tables_literal  equ 220h
arbre_inflate_valeurs_literal equ 320h
arbre_inflate_tables_dist     equ 620h
arbre_inflate_valeurs_dist    equ 720h
arbre_inflate_zt1 equ 00A20h
arbre_inflate_zt_to equ 40000h
arbre_inflate_zt2 equ arbre_inflate_zt1 + arbre_inflate_zt_to

arbre_inflate_index equ 4
arbre_inflate_min   equ 8
arbre_inflate_max   equ 12


;**********************************************************************************************************************
sfs_inflate:        ;décompresse déflate ds:esi vers es:edi   
pushad
push fs
mov ax,selramh 
mov fs,ax

mov ecx,arbre_inflate_valeurs_dist+200h
call resmem
jnc @f

pop fs
popad
mov eax,cer_pasm
iret


@@: ;fs:ebx=zone tampon pour l'arbre de décodage
xor ecx,ecx   ;cl=index de bit

sfs_inflate_bloc_suivant:
mov eax,[esi]
shr eax,cl
fs
mov [ebx+arbre_inflate_bloc],eax
and al,6
cmp al,0
je sfs_inflate_bloc_00
cmp al,2
je sfs_inflate_bloc_01
cmp al,4
je sfs_inflate_bloc_10
mov eax,cer_parami

sfs_inflate_erreur:
push eax
call libmem
pop eax
pop fs
ss
mov [esp+28],eax   ;préserve eax
popad
iret





;***********************************
sfs_inflate_bloc_00:   ;sans compression
xor ecx,ecx
mov cx,[esi+1]
add esi,5
cld
rep movsb
xor ecx,ecx
jmp sfs_inflate_bloc_fin

;***********************************
sfs_inflate_bloc_01:    ;arbre de hufman fixe
av_bit 3
call sfs_inflate_gen_table_decodage
call sfs_inflate_gen_arbre
jmp sfs_inflate_parcour_bloc


;***********************************
sfs_inflate_bloc_10:    ;arbre de huffman dynamique
av_bit 3
call sfs_inflate_lit_table_decodage
cmp eax,0
jne sfs_inflate_erreur
call sfs_inflate_gen_arbre



;**************************************
sfs_inflate_parcour_bloc:
call sfs_inflate_decode
jc sfs_inflate_parcour_bloc
cmp eax,0
jne sfs_inflate_erreur


sfs_inflate_bloc_fin:
fs
mov eax,[ebx+arbre_inflate_bloc]
test eax,1      ;si le bit de fin de bloc du bloc précédent n'était pas a 1 on continue
jz sfs_inflate_bloc_suivant


cmp cl,0
je @f
inc esi
@@:

call libmem
pop fs
;calcul la taille des données en sortie et les insères dans la pile
ss
sub esi,[esp+4]
ss
sub edi,[esp]
ss
mov [esp+4],esi ;taille des données compressé
ss
mov [esp],edi  ;taille des données décompressé
popad
xor eax,eax
iret




;************************************************************************************************
sfs_inflate_gen_arbre:          ;génération complet de la table de décodage a partir des suites
push ebx
push ecx
push esi
push edi
push es


mov esi,ebx                    ;trie des point de code par nombre de bit utillisé
mov edi,ebx
mov edx,ebx
add esi,arbre_inflate_tailles          ;taille des points de code
add edi,arbre_inflate_valeurs_literal  ;table des tailles
add edx,arbre_inflate_tables_literal   ;index de la table
mov cl,1
xor eax,eax
fs
mov dword[edx],0
fs
mov dword[edx+4],0
fs
mov dword[edx+8],0
fs
mov dword[edx+12],0


sfs_inflate_gen_arbre_literal1:
fs
cmp [esi],cl
jne @f
fs
mov [edi],ax
add edi,2
fs
inc dword[edx]
@@:
inc ax
inc esi
fs
cmp ax,[ebx+arbre_inflate_literal]
jne sfs_inflate_gen_arbre_literal1

mov esi,ebx
inc cl
add esi,arbre_inflate_tailles
add edx,16

xor eax,eax
cmp cl,16
je @f 


fs
mov dword[edx],0
fs
mov dword[edx+4],0
fs
mov dword[edx+8],0
fs
mov dword[edx+12],0
jmp sfs_inflate_gen_arbre_literal1
 

@@:


fs
cmp dword[ebx+arbre_inflate_dist],0
je sfs_inflate_ignore_distance1
                  


mov esi,ebx                    ;trie des point de code par nombre de bit utillisé
mov edi,ebx
mov edx,ebx
add esi,arbre_inflate_tailles          ;taille des points de code
add edi,arbre_inflate_valeurs_dist  ;table des tailles
add edx,arbre_inflate_tables_dist   ;index de la table
fs
add esi,[ebx+arbre_inflate_literal]
mov cl,1
xor eax,eax
fs
mov dword[edx],0
fs
mov dword[edx+4],0
fs
mov dword[edx+8],0
fs
mov dword[edx+12],0


sfs_inflate_gen_arbre_dist1:
fs
cmp [esi],cl
jne @f
fs
mov [edi],ax
add edi,2
fs
inc word[edx]
@@:
inc ax
inc esi
fs
cmp ax,[ebx+arbre_inflate_dist]
jne sfs_inflate_gen_arbre_dist1

mov esi,ebx
inc cl
add esi,arbre_inflate_tailles
fs
add esi,[ebx+arbre_inflate_literal]
add edx,16

xor eax,eax
cmp cl,16
je @f 


fs
mov dword[edx],0
fs
mov dword[edx+4],0
fs
mov dword[edx+8],0
fs
mov dword[edx+12],0
jmp sfs_inflate_gen_arbre_dist1

@@:


sfs_inflate_ignore_distance1:


xor eax,eax       ;génération des codes et des pointeurs associé aux branches de l'arbre littéral
xor ebp,ebp
mov edx,ebx
mov esi,ebx
add esi,arbre_inflate_tables_literal
add edx,arbre_inflate_tables_literal+100h

sfs_inflate_boucle_arbre_litteral2:
fs
mov ecx,[esi]
cmp ecx,0
je @f

fs
mov [esi+arbre_inflate_index],ebp
add ebp,ecx
fs
mov [esi+arbre_inflate_min],eax
add eax,ecx
dec eax
fs
mov [esi+arbre_inflate_max],eax
inc eax
@@:
shl eax,1
add esi,10h
cmp esi,edx
jne sfs_inflate_boucle_arbre_litteral2




fs
cmp dword[ebx+arbre_inflate_dist],0
je sfs_inflate_ignore_distance2


xor eax,eax       ;génération des codes et des pointeurs associé aux branches de l'arbre des distances
xor ebp,ebp
mov edx,ebx
mov esi,ebx
add esi,arbre_inflate_tables_dist
add edx,arbre_inflate_tables_dist+100h


sfs_inflate_boucle_arbre_distance2:
fs
mov ecx,[esi]
cmp ecx,0
je @f

fs
mov [esi+arbre_inflate_index],ebp
add ebp,ecx
fs
mov [esi+arbre_inflate_min],eax
add eax,ecx
dec eax
fs
mov [esi+arbre_inflate_max],eax
inc eax
@@:
shl eax,1
add esi,10h
cmp esi,edx
jne sfs_inflate_boucle_arbre_distance2


sfs_inflate_ignore_distance2:
pop es
pop edi
pop esi
pop ecx
pop ebx

ret




;***********************************************************************************************************
sfs_inflate_lit_table_decodage:

mov eax,[esi]             ;extrait les valeurs de base
shr eax,cl
and eax,1Fh
add eax,257
av_bit 5
fs
mov [ebx+arbre_inflate_HLIT],eax

mov eax,[esi]
shr eax,cl
and eax,1Fh
inc eax
av_bit 5
fs
mov [ebx+arbre_inflate_HDIST],eax   ;HDIST

mov eax,[esi]
shr eax,cl
and eax,0Fh
add eax,4
av_bit 4
mov dl,al      ;HCLEN


xor eax,eax                    ;efface la table des tailles
fs
mov [ebx+arbre_inflate_tailles],eax
fs
mov [ebx+arbre_inflate_tailles+4],eax
fs
mov [ebx+arbre_inflate_tailles+8],eax
fs
mov [ebx+arbre_inflate_tailles+12],eax
fs
mov [ebx+arbre_inflate_tailles+16],eax


sfs_inflate_litarbre 16         ;lit la valeur des arbres et replace ça suivant la table de permutation
sfs_inflate_litarbre 17
sfs_inflate_litarbre 18
sfs_inflate_litarbre 0 
sfs_inflate_litarbre 8 
sfs_inflate_litarbre 7 
sfs_inflate_litarbre 9 
sfs_inflate_litarbre 6 
sfs_inflate_litarbre 10 
sfs_inflate_litarbre 5 
sfs_inflate_litarbre 11
sfs_inflate_litarbre 4 
sfs_inflate_litarbre 12 
sfs_inflate_litarbre 3 
sfs_inflate_litarbre 13 
sfs_inflate_litarbre 2 
sfs_inflate_litarbre 14 
sfs_inflate_litarbre 1
sfs_inflate_litarbre 15
sfs_inflate_finpermute: 

fs
mov dword[ebx+arbre_inflate_literal],19
fs
mov dword[ebx+arbre_inflate_dist],0   
call sfs_inflate_gen_arbre

fs
mov eax,[ebx+arbre_inflate_HLIT]        
fs
add eax,[ebx+arbre_inflate_HDIST]   ;HLIT+HDIST
fs
mov [ebx+arbre_inflate_literal],eax        


push edi
push es
mov ax,fs
mov es,ax
mov edi,ebx
add edi,arbre_inflate_tailles


sfs_inflate_decomp_arbre: 
fs
cmp dword[ebx+arbre_inflate_literal],0
je sfs_inflate_decomp_arbre_fin
jb sfs_inflate_erreur_arbre  
mov ch,16
mov eax,[esi]
shr eax,cl
mov edx,ebx
add edx,arbre_inflate_tables_literal-10h
xor ebp,ebp


sfs_inflate_boucle_decodage_arbre:
rcr eax,1
rcl ebp,1
av_bit 1
add edx,10h
dec ch
jz sfs_inflate_erreur_arbre
fs
cmp dword[edx],0
jz sfs_inflate_boucle_decodage_arbre
fs
cmp ebp,[edx+arbre_inflate_max]
ja sfs_inflate_boucle_decodage_arbre


fs
sub ebp,[edx+arbre_inflate_min]
fs
mov eax,[edx+arbre_inflate_index]
add ebp,eax
shl ebp,1
push ebx
add ebx,ebp
fs
mov ax,[ebx+arbre_inflate_valeurs_literal]
pop ebx


cmp ax,16
je sfs_inflate_decomp_arbre_suite1
cmp ax,17
je sfs_inflate_decomp_arbre_suite2
cmp ax,18
je sfs_inflate_decomp_arbre_suite3
test ax,0FFF0h
jnz sfs_inflate_erreur_arbre
cld
stosb
fs
dec dword[ebx+arbre_inflate_literal]
jmp sfs_inflate_decomp_arbre   



sfs_inflate_decomp_arbre_suite1:   
dec edi
mov eax,[esi]
shr eax,cl
av_bit 2
push ecx
mov ecx,eax
and ecx,3h
es
mov al,[edi]
add ecx,3
cld
stosb
fs
sub [ebx+arbre_inflate_literal],ecx       
rep stosb
pop ecx
jmp sfs_inflate_decomp_arbre   


sfs_inflate_decomp_arbre_suite2:   
mov eax,[esi]
shr eax,cl
av_bit 3
push ecx
mov ecx,eax
and ecx,07h
mov al,0
add ecx,3
fs
sub [ebx+arbre_inflate_literal],ecx       
cld
rep stosb
pop ecx
jmp sfs_inflate_decomp_arbre   


sfs_inflate_decomp_arbre_suite3:   
mov eax,[esi]
shr eax,cl
av_bit 7
push ecx
mov ecx,eax
and ecx,7Fh
mov al,0
add ecx,11
fs
sub [ebx+arbre_inflate_literal],ecx 
cld      
rep stosb
pop ecx
jmp sfs_inflate_decomp_arbre   


sfs_inflate_decomp_arbre_fin: 
pop es
pop edi


fs
mov eax,[ebx+arbre_inflate_HLIT]
fs
mov edx,[ebx+arbre_inflate_HDIST]
fs
mov [ebx+arbre_inflate_literal],eax
fs
mov [ebx+arbre_inflate_dist],edx
xor eax,eax
ret


sfs_inflate_erreur_arbre:
pop es
pop edi
mov eax,cer_ers
ret


;***************************************************************************************************
sfs_inflate_gen_table_decodage:
push ecx          ;génération de l'arbre fixe (suite de nombre de bit uttilisé pour chaque point de code)
push edi
push es
mov ax,fs
mov es,ax
mov edi,ebx
add edi,arbre_inflate_tailles
cld
mov al,8       ;arbre littéral
mov ecx,144
rep stosb
mov al,9
mov ecx,112
rep stosb
mov al,7
mov ecx,24
rep stosb
mov al,8
mov ecx,8
rep stosb
mov al,5       ;arbre de distance
mov ecx,32
rep stosb
pop es
pop edi
pop ecx


fs
mov dword[ebx+arbre_inflate_literal],288  
fs
mov dword[ebx+arbre_inflate_dist],32
ret




;***************************************************************************************************
sfs_inflate_decode:
mov ch,16
mov eax,[esi]
shr eax,cl
mov edx,ebx
add edx,arbre_inflate_tables_literal-10h
xor ebp,ebp


sfs_inflate_boucle_decodage_litteral:
rcr eax,1
rcl ebp,1
av_bit 1
add edx,10h
dec ch
jz sfs_inflate_decode_erreur
fs
cmp dword[edx],0
jz sfs_inflate_boucle_decodage_litteral
fs
cmp ebp,[edx+arbre_inflate_max]
ja sfs_inflate_boucle_decodage_litteral

fs
sub ebp,[edx+arbre_inflate_min]
fs
add ebp,[edx+arbre_inflate_index]
shl ebp,1
push ebx
add ebx,ebp
fs
mov ax,[ebx+arbre_inflate_valeurs_literal]
pop ebx

cmp ah,0             ;code littéral
jne @f 
cld
stosb
stc
ret

@@:
cmp ax,256            ;fin de bloc 
jne sfs_inflate_longueurs
xor eax,eax
clc
ret

sfs_inflate_decode_erreur:
mov eax,cer_ers
clc
ret

sfs_inflate_longueurs:
cmp ax,265            ;code de longueur
jb sfs_inflate_longueur0
cmp ax,269
jb sfs_inflate_longueur1
cmp ax,273
jb sfs_inflate_longueur2
cmp ax,277
jb sfs_inflate_longueur3
cmp ax,281
jb sfs_inflate_longueur4
cmp ax,285
jb sfs_inflate_longueur5
cmp ax,285
je sfs_inflate_longueur6
jmp sfs_inflate_decode_erreur

sfs_inflate_longueur0:
and eax,0FFFFh
sub eax,254   ;-257+3
jmp suite2_sfs_inflate_longueur

sfs_inflate_longueur1:
xor edx,edx
mov dx,ax
sub edx,265   ;-265
shl edx,1
add edx,11  ;+11
mov eax,[esi]
shr eax,cl
av_bit 1
and eax,1h
add eax,edx
jmp suite2_sfs_inflate_longueur

sfs_inflate_longueur2:
xor edx,edx
mov dx,ax
sub edx,269   ;-269
shl edx,2
add edx,19  ;+19
mov eax,[esi]
shr eax,cl
av_bit 2
and eax,3h
add eax,edx
jmp suite2_sfs_inflate_longueur

sfs_inflate_longueur3:
xor edx,edx
mov dx,ax
sub edx,273   ;-273
shl edx,3
add edx,35  ;+35
mov eax,[esi]
shr eax,cl
av_bit 3
and eax,7h
add eax,edx
jmp suite2_sfs_inflate_longueur

sfs_inflate_longueur4:
xor edx,edx
mov dx,ax
sub edx,277   ;-277
shl edx,4
add edx,67  ;+67
mov eax,[esi]
shr eax,cl
av_bit 4
and eax,0Fh
add eax,edx
jmp suite2_sfs_inflate_longueur

sfs_inflate_longueur5:
xor edx,edx
mov dx,ax
sub edx,281   ;-281
shl edx,5
add edx,131  ;+131
mov eax,[esi]
shr eax,cl
av_bit 5
and eax,1Fh
add eax,edx
jmp suite2_sfs_inflate_longueur

sfs_inflate_longueur6:
mov eax,258

suite2_sfs_inflate_longueur: 
fs
mov [ebx+arbre_inflate_taillechaine],eax



mov ch,16                   ;décodage des distance suivant un arbre spécifique
mov eax,[esi]
shr eax,cl
mov edx,ebx
add edx,arbre_inflate_tables_dist-10h
xor ebp,ebp

sfs_inflate_boucle_decodage_distance:
rcr eax,1
rcl ebp,1
av_bit 1
add edx,10h
dec ch
jz sfs_inflate_decode_erreur
fs
cmp dword[edx],0
jz sfs_inflate_boucle_decodage_distance
fs
cmp ebp,[edx+arbre_inflate_max]
ja sfs_inflate_boucle_decodage_distance

fs
sub ebp,[edx+arbre_inflate_min]
xor eax,eax
fs
mov ax,[edx+arbre_inflate_index]
add ebp,eax
shl ebp,1
push ebx
add ebx,ebp
fs
mov ax,[ebx+arbre_inflate_valeurs_dist]
pop ebx


cmp al,4
jb sfs_inflate_distance0
cmp al,6
jb sfs_inflate_distance1
cmp al,8
jb sfs_inflate_distance2
cmp al,10
jb sfs_inflate_distance3
cmp al,12
jb sfs_inflate_distance4
cmp al,14
jb sfs_inflate_distance5
cmp al,16
jb sfs_inflate_distance6
cmp al,18
jb sfs_inflate_distance7
cmp al,20
jb sfs_inflate_distance8
cmp al,22
jb sfs_inflate_distance9
cmp al,24
jb sfs_inflate_distance10
cmp al,26
jb sfs_inflate_distance11
cmp al,28
jb sfs_inflate_distance12
cmp al,30
jb sfs_inflate_distance13
jmp sfs_inflate_decode_erreur

sfs_inflate_distance0:
and eax,0FFh
inc eax
jmp suite_sfs_inflate_distance

sfs_inflate_distance1:
xor edx,edx
mov dl,al
sub edx,4
shl edx,1
add edx,5
mov eax,[esi]
shr eax,cl
av_bit 1
and eax,1h
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance2:
xor edx,edx
mov dl,al
sub edx,6
shl edx,2
add edx,9
mov eax,[esi]
shr eax,cl
av_bit 2
and eax,3h
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance3:
xor edx,edx
mov dl,al
sub edx,8
shl edx,3
add edx,17
mov eax,[esi]
shr eax,cl
av_bit 3
and eax,7h
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance4:
xor edx,edx
mov dl,al
sub edx,10
shl edx,4
add edx,33
mov eax,[esi]
shr eax,cl
av_bit 4
and eax,0Fh
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance5:
xor edx,edx
mov dl,al
sub edx,12
shl edx,5
add edx,65
mov eax,[esi]
shr eax,cl
av_bit 5
and eax,1Fh
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance6:
xor edx,edx
mov dl,al
sub edx,14
shl edx,6
add edx,129
mov eax,[esi]
shr eax,cl
av_bit 6
and eax,3Fh
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance7:
xor edx,edx
mov dl,al
sub edx,16
shl edx,7
add edx,257
mov eax,[esi]
shr eax,cl
av_bit 7
and eax,7Fh
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance8:
xor edx,edx
mov dl,al
sub edx,18
shl edx,8
add edx,513
mov eax,[esi]
shr eax,cl
av_bit 8
and eax,0FFh
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance9:
xor edx,edx
mov dl,al
sub edx,20
shl edx,9
add edx,1025
mov eax,[esi]
shr eax,cl
av_bit 9
and eax,1FFh
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance10:
xor edx,edx
mov dl,al
sub edx,22
shl edx,10
add edx,2049
mov eax,[esi]
shr eax,cl
av_bit 10
and eax,3FFh
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance11:
xor edx,edx
mov dl,al
sub edx,24
shl edx,11
add edx,4097
mov eax,[esi]
shr eax,cl
av_bit 11
and eax,7FFh
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance12:
xor edx,edx
mov dl,al
sub edx,26
shl edx,12
add edx,8193
mov eax,[esi]
shr eax,cl
av_bit 12
and eax,0FFFh
add eax,edx
jmp suite_sfs_inflate_distance

sfs_inflate_distance13:
xor edx,edx
mov dl,al
sub edx,28
shl edx,13
add edx,16385
mov eax,[esi]
shr eax,cl
av_bit 13
and eax,1FFFh
add eax,edx

suite_sfs_inflate_distance:
push ecx
push esi
push ds
mov dx,es
mov ds,dx
mov esi,edi
sub esi,eax
fs
mov ecx,[ebx+arbre_inflate_taillechaine]
cld
rep movsb
pop ds
pop esi
pop ecx
stc
ret








;**********************************************************************************************************************
sfs_inflate_fichier:        ;décompresse fichier compressé par deflate 
pushad
push ds
push es
push fs
mov ax,selramh 
mov ds,ax
mov es,ax
mov fs,ax

mov ecx,arbre_inflate_zt2 + arbre_inflate_zt_to
call resmem
jnc @f

pop fs
pop es
pop ds
popad
mov eax,cer_pasm
iret


@@:  ;ds/es/fs:ebx=zone tampon pour l'arbre de décodage
;enregistre les numéros de fichier
mov [ebx+arbre_inflate_fichier1],esi
mov [ebx+arbre_inflate_fichier2],edi
mov dword[ebx+arbre_inflate_adresse1],edx
mov dword[ebx+arbre_inflate_adresse2],0
and dword[ebx+arbre_inflate_adresse1],0FFFF0000h
and edx,0FFFFh


;charge le début du fichier a lire dans la ZT d'entrée
push ebx
push ecx
push edx
push edi
mov edi,ebx
mov eax,4
mov ebx,[edi+arbre_inflate_fichier1]
mov ecx,arbre_inflate_zt_to
mov edx,[edi+arbre_inflate_adresse1]
add edi,arbre_inflate_zt1
int 64h
pop edi
pop edx
pop ecx
pop ebx
cmp eax,0
jne sfs_inflate_fichier_erreur

xor ecx,ecx   ;cl=index de bit
mov esi,ebx
mov edi,ebx
add esi,arbre_inflate_zt1
add edi,arbre_inflate_zt2
add esi,edx


sfs_inflate_fichier_bloc_suivant:
mov eax,[esi]
shr eax,cl
fs
mov [ebx+arbre_inflate_bloc],eax
and al,6
cmp al,0
je sfs_inflate_fichier_bloc_00
cmp al,2
je sfs_inflate_fichier_bloc_01
cmp al,4
je sfs_inflate_fichier_bloc_10
mov eax,cer_parami
jmp sfs_inflate_fichier_erreur





;***********************************
sfs_inflate_fichier_bloc_00:   ;sans compression
xor ecx,ecx
mov cx,[esi+1]
add esi,5
cld
rep movsb
xor ecx,ecx

call sfs_inflate_fichier_verifpoint
cmp eax,0
jne sfs_inflate_fichier_erreur
jmp sfs_inflate_fichier_bloc_fin

;***********************************
sfs_inflate_fichier_bloc_01:    ;arbre de hufman fixe
av_bit 3
call sfs_inflate_gen_table_decodage
call sfs_inflate_gen_arbre
jmp sfs_inflate_fichier_parcour_bloc


;***********************************
sfs_inflate_fichier_bloc_10:    ;arbre de huffman dynamique
av_bit 3
call sfs_inflate_lit_table_decodage
cmp eax,0
jne sfs_inflate_fichier_erreur
call sfs_inflate_gen_arbre


;**************************************
sfs_inflate_fichier_parcour_bloc:

call sfs_inflate_decode
jnc sfs_inflate_fichier_fin_bloc



call sfs_inflate_fichier_verifpoint
cmp eax,0
jne sfs_inflate_fichier_erreur
jmp sfs_inflate_fichier_parcour_bloc




;*****************************
sfs_inflate_fichier_fin_bloc:
cmp eax,0
jne sfs_inflate_fichier_erreur


sfs_inflate_fichier_bloc_fin:
fs
mov eax,[ebx+arbre_inflate_bloc]
test eax,1      ;si le bit de fin de bloc du bloc précédent n'était pas a 1 on continue
jz sfs_inflate_fichier_bloc_suivant


;fin du décodage, on calcul l'adresse du dernier octet compressé
and dword[ebx+arbre_inflate_adresse1],0FFFF0000h
cmp cl,0
je @f
inc esi
@@:
sub esi,arbre_inflate_zt1
sub esi,ebx
add [ebx+arbre_inflate_adresse1],esi



;on charge toute la zt de sortie dans le fichier
push ebx
push esi
mov esi,ebx
mov eax,5
mov ebx,[esi+arbre_inflate_fichier2]
mov ecx,edi
mov edx,[esi+arbre_inflate_adresse2]
add esi,arbre_inflate_zt2
sub ecx,esi
int 64h
pop esi
pop ebx
cmp eax,0
jne sfs_inflate_fichier_erreur
add [ebx+arbre_inflate_adresse2],ecx

mov esi,[ebx+arbre_inflate_adresse1]
mov edi,[ebx+arbre_inflate_adresse2]
call libmem
pop fs
pop es
pop ds
ss
mov [esp+4],esi ;taille des données compressé
ss
mov [esp],edi  ;taille des données décompressé
popad
sub esi,edx
xor eax,eax
iret


sfs_inflate_fichier_erreur:
push eax
call libmem
pop eax
pop fs
pop es
pop ds
ss
mov [esp+28],eax   ;préserve eax
popad
iret



;*************************************************
sfs_inflate_fichier_verifpoint:
;vérifie que l'on ne s'approche pas trop de la fin de la ZT d'entrée
mov eax,ebx
add eax,arbre_inflate_zt1+arbre_inflate_zt_to-10000h
cmp esi,eax
jb @f

;si oui on recharge la ZT d'entrée
add dword[ebx+arbre_inflate_adresse1],arbre_inflate_zt_to-10000h
sub esi,arbre_inflate_zt_to-10000h


push ecx
push esi
push edi
mov esi,ebx
mov edi,ebx
mov ecx,10000h/4
add esi,arbre_inflate_zt1+arbre_inflate_zt_to-10000h
add edi,arbre_inflate_zt1
cld
rep movsd
pop edi
pop esi
pop ecx

push ebx
push ecx
push edi
mov edi,ebx
mov eax,4
mov ebx,[edi+arbre_inflate_fichier1]
mov ecx,arbre_inflate_zt_to-10000h
mov edx,[edi+arbre_inflate_adresse1]
add edx,10000h
add edi,arbre_inflate_zt1+10000h
int 64h
pop edi
pop ecx
pop ebx
cmp eax,0
jne sfs_inflate_fichier_verifpoint_erreur

@@:



;verifie que l'on ne s'approche pas trop de la fin de la ZT de sortie
mov eax,ebx
add eax,arbre_inflate_zt2+arbre_inflate_zt_to-10000h
cmp edi,eax
jb sfs_inflate_fichier_verifpoint_ok


;si oui on libère de la place dans la ZT de sortie
mov edx,20000h ;par bloc de 128Ko c'est mieux

;sauvegarde
push ebx
push ecx
push edx
push esi
mov esi,ebx
mov eax,5
mov ebx,[esi+arbre_inflate_fichier2]
mov ecx,edx
mov edx,[esi+arbre_inflate_adresse2]
add esi,arbre_inflate_zt2
int 64h
pop esi
pop edx
pop ecx
pop ebx
cmp eax,0
jne sfs_inflate_fichier_verifpoint_erreur


;décale les données conservé
push ecx
push esi
push edi
mov esi,ebx
mov edi,ebx
add esi,arbre_inflate_zt2 
add edi,arbre_inflate_zt2 
add esi,edx
mov ecx,arbre_inflate_zt_to
sub ecx,edx
cld
rep movsb
pop edi
pop esi
pop ecx

;met a jour les pointeurs
add [ebx+arbre_inflate_adresse2],edx
sub edi,edx

sfs_inflate_fichier_verifpoint_ok:
xor eax,eax
sfs_inflate_fichier_verifpoint_erreur:
ret


;***********************************************
sfs_filtre_liste:  ;ds:esi=filtre ;ds:edi=liste de nom séparé par des | et terminé par 0
pushad
xor edx,edx   ;b0=inversion b1=sensible a la casse ;b3=reccherche etoile en cours
cmp byte[esi],"|"   ;option d'inversion de la liste (pas encore active)
jne @f
mov dl,1
inc esi
@@:

mov ebp,esi
mov ebx,edi

;compte la taille des données a analyser
mov ecx,edi
@@:
cmp byte[ecx],0
je @f
inc ecx
jmp @b
@@:
inc ecx


cmp byte[ebx],"|"
jne @f
inc ebx
@@:

boucle0_sfs_filtre_liste:
and dl,0FBh
mov esi,ebp
mov edi,ebx

boucle1_sfs_filtre_liste:
mov ah,[esi]
mov al,[edi]
cmp ah,"<"
je oncasse1_sfs_filtre_liste
cmp ah,">"
je offcasse1_sfs_filtre_liste
cmp ah,"*"
je etoile_sfs_filtre_liste
cmp ah,"?"
je ignore_sfs_filtre_liste
cmp ax,"|"
je suivant_sfs_filtre_liste
cmp ax,0
je suivant_sfs_filtre_liste
call test_sfs_filtre_liste
jne inexacte_sfs_filtre_liste

ok_sfs_filtre_liste:
inc esi
inc edi
jmp boucle1_sfs_filtre_liste


ignore_sfs_filtre_liste:
inc esi
@@:
inc edi
mov al,[edi]
and al,0C0h
cmp al,080h
je @b
jmp boucle1_sfs_filtre_liste

oncasse1_sfs_filtre_liste:
or dl,2
inc esi
jmp boucle1_sfs_filtre_liste

offcasse1_sfs_filtre_liste:
and dl,0FDh
inc esi
jmp boucle1_sfs_filtre_liste


;efface le fichier de la liste
supprime_sfs_filtre_liste:
test dl,1
jnz suivant2_sfs_filtre_liste
supprime2_sfs_filtre_liste:

mov esi,ebx
mov edi,ebx

@@:
cmp byte[esi],0
je dernier_sfs_filtre_liste
cmp byte[esi],"|"
je @f
inc esi
jmp @b

@@:
inc esi
push ecx
sub ecx,esi
cld
rep movsb
pop ecx
jmp boucle0_sfs_filtre_liste



inexacte_sfs_filtre_liste:
test dl,4
jz supprime_sfs_filtre_liste
@@:
dec esi
cmp byte[esi],"*"
jne @b

etoile_sfs_filtre_liste:
or dl,4
inc esi
mov al,[esi]
cmp al,"*"
je  etoile_sfs_filtre_liste
cmp al,"?"
je  etoile_sfs_filtre_liste
cmp al,"<"
je  oncasse2_sfs_filtre_liste
cmp al,">"
je  offcasse2_sfs_filtre_liste
cmp al,0
je suivant_sfs_filtre_liste

@@:
mov ah,[edi]
call test_sfs_filtre_liste
je boucle1_sfs_filtre_liste
cmp byte[edi],"|"
je supprime_sfs_filtre_liste
cmp byte[edi],0
je supprime_sfs_filtre_liste
inc edi
jmp @b

oncasse2_sfs_filtre_liste:
or dl,2
jmp etoile_sfs_filtre_liste

offcasse2_sfs_filtre_liste:
and dl,0FDh
jmp etoile_sfs_filtre_liste


suivant_sfs_filtre_liste:
test dl,1
jnz supprime2_sfs_filtre_liste
suivant2_sfs_filtre_liste:

cmp byte[ebx],0
je fin_sfs_filtre_liste
inc ebx
cmp byte[ebx],"|"
jne suivant2_sfs_filtre_liste
inc ebx
jmp boucle0_sfs_filtre_liste

dernier_sfs_filtre_liste:
mov byte[ebx],0

fin_sfs_filtre_liste:
popad
iret


test_sfs_filtre_liste:
test dl,2
jnz casse_sfs_filtre_liste
cmp al,"a"
jb @f
cmp al,"z"
ja @f
sub al,20h
@@:
cmp ah,"a"
jb @f
cmp ah,"z"
ja @f
sub ah,20h
@@:
casse_sfs_filtre_liste:
cmp al,ah
ret






