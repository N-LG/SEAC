;commande integré de listing de la mémoire, des disque et des taches en cours d'execution



;****************************************************************
cmdlm:              ;liste les emplacement mémoires
mov ax,selramh
mov fs,ax
xor ebx,ebx
mov cl,72
call affmsgsyst


boucle_lm:
mov eax,ebx
call affh2j
mov al," "
call affcj
fs
mov al,[ebx+2]
call affcj
mov al," "
call affcj
fs
mov eax,[ebx+4]
call affnje

fs
cmp byte[ebx+2],"S"
jne suite1_lm
mov al," "
call affcj
mov al,"("
call affcj
xor eax,eax
fs
mov ax,[ebx+8]
call affnj
mov al,")"
call affcj
jmp suite3_lm 
suite1_lm:

fs
cmp byte[ebx+2],"T"
jne suite2_lm
mov al," "
call affcj
mov al,"("
call affcj
fs
mov ax,[ebx+8]
call affh1j
mov al,")"
call affcj
jmp suite3_lm 
suite2_lm:

fs
cmp byte[ebx+2],"C"
jne suite3_lm
mov al," "
call affcj
mov al,"("
call affcj
fs
mov ax,[ebx+8]
call affh1j
mov al,">"
call affcj
fs
mov ax,[ebx+0Ah]
call affh1j
mov al,")"
call affcj
suite3_lm:


mov al,13
call affcj
fs
mov eax,[ebx+4]
add ebx,eax
fs
cmp byte[ebx+2],"F"
jne boucle_lm

mov cl,73
call affmsgsyst
mov eax,[taille_mem_vide]
call affnje

mov cl,74
call affmsgsyst
mov eax,[taille_mem_syst]
call affnje

mov cl,75
call affmsgsyst
mov eax,[taille_mem_tache]
call affnje

mov cl,76
call affmsgsyst
mov eax,[taille_mem_com]
call affnje

mov cl,77
call affmsgsyst
mov eax,[taille_mem_vide]
add eax,[taille_mem_syst]
add eax,[taille_mem_tache]
add eax,[taille_mem_com]
call affnje


mov al,13
call affcj
jmp pascommande






;****************************************************************
cmdld:          ;liste les disques et partition ata


;affiche les infos
mov cl,50
call affmsgsyst


test byte[at_fc_fichier],10h
jz cmdld_pasdisquette
mov cl,69
call affmsgsyst
cmdld_pasdisquette:



mov esi,ad_descp+64  ;le descripteur 0 est pour la disquette
boucleldp:        ;boucle d'affichage des partitition de disque
cmp byte[esi],2
jb paspartldp
cmp byte[esi],12
ja paspartldp

mov cl,50
add cl,[esi]
push cx
jmp taillepartldp

partinconnueldp:
mov cl,52
push cx
jmp taillepartldp


taillepartldp: ;affiche le nom 
mov al,"#"
call affcj
mov al,"d"
call affcj
call affcj
mov eax,esi
sub eax,ad_descp
shr eax,6  ;div par 64
call affnje

pop cx
call affmsgsyst
cmp cl,52
jne partpasinconnue
mov al,[esi+2]
call affh0j
mov al,")"
call affcj
mov al," "
call affcj
partpasinconnue:

test dword[esi+20],0FFFFFFF8h
jnz partTebi
test dword[esi+16],0FE000000h
jnz partGibi
test dword[esi+16],0FFFF8000h
jnz partMebi
test dword[esi+16],0FFFFFFE0h
jnz partKibi

mov eax,[esi+16]     ;et la taille de la partition en kibi
shl eax,9
call affnj
mov cl,78
call affmsgsyst
mov al,13
call affcj
jmp paspartldp


partKibi:
mov eax,[esi+16]     ;et la taille de la partition en kibi
shr eax,1
call affnj
mov al,"K"
call affcj
mov al,"i"
call affcj
mov al,"o"
call affcj
mov al,13
call affcj
jmp paspartldp

partMebi:
mov eax,[esi+17]     ;et la taille de la partition en mebi
shr eax,3
call affnj
mov al,"M"
call affcj
mov al,"i"
call affcj
mov al,"o"
call affcj
mov al,13
call affcj
jmp paspartldp

partGibi:
mov eax,[esi+18]     ;et la taille de la partition en gibi
shr eax,5
call affnj
mov al,"G"
call affcj
mov al,"i"
call affcj
mov al,"o"
call affcj
mov al,13
call affcj
jmp paspartldp

partTebi:
mov eax,[esi+19]     ;et la taille de la partition en tebi
shr eax,7
call affnj
mov al,"T"
call affcj
mov al,"i"
call affcj
mov al,"o"
call affcj
mov al,13
call affcj
;jmp paspartldp

paspartldp:
add esi,20h
cmp esi,ad_descp+1000h
jne boucleldp

;**********
mov ch,18h
mov esi,ad_descd

boucleldc:      ;affichage des lecteurs de cdrom présent
mov al,[esi+dd_atribut]
and al,07h
cmp al,4
jne pascdldp

mov al,10
mov edi,bootsecteur
int 64h
cmp eax,0
jne pascdldp

push ecx
mov al,"#"
call affcj
mov al,"c"
call affcj
mov al,"d"
call affcj
mov al,ch
and eax,0FFh
sub eax,17h
call affnje
mov al," "
call affcj

;convertit le nom
mov ebx,bootsecteur+36h
boucle_convn:
mov ax,[ebx]
xchg al,ah
mov[ebx],ax
add ebx,2
cmp ebx,bootsecteur+5Eh
jne boucle_convn

;affiche le nom
mov edx,bootsecteur+36h
mov byte[bootsecteur+5Eh],0
call affjournal

mov al,13
call affcj
pop ecx

pascdldp:
inc ch 
add esi,32
cmp ch,20h
jne boucleldc

jmp pascommande


;****************************************************************
cmdlt:                           ;liste les taches
mov ax,selramh
mov ds,ax
xor ebx,ebx
mov cl,71
call affmsgsyst

boucle_cmd_lt:
cmp byte[ebx+type_dm],"F"
je pascommande
cmp byte[ebx+type_dm],"T"
jne ignore_cmd_lt

;affiche l'ID
mov ax,[ebx+id_tache]
call affh1j

;affiche le temp d'execution
;mov al,"["
;call affcj
;xor eax,eax
;mov al,[ebx+temp_exec_tache]
;call affnj
;mov al,"]"
;call affcj

;affiche la commande
;mov edx,recop_commande
;add edx,ebx
;call affjournal
;mov al,13
;call affcj


mov al,20h
call affcj


;affiche (eventuellement) la description texte de la tache
mov edx,descriptif_tache
add edx,ebx
cmp byte[edx],0
je ignore_affichage_decr_lt
call affjournal
ignore_affichage_decr_lt:

mov al,13
call affcj

ignore_cmd_lt:
mov eax,[ebx+to_tache]
add ebx,eax
jmp boucle_cmd_lt




;*****************************************************************
cmdlv:                           ;liste des modes video
mov ax,seldat
mov ds,ax
mov es,ax
mov cl,80
call affmsgsyst

xor ecx,ecx

boucle_cmdlv:
call vesa_infomode
cmp ax,004Fh
jne passe_cmdlv 

;verifie que c'est du mode texte, chainé, ou direct color
cmp byte[infovesa+1Bh],0 ;texte
je ok_mem_lv
cmp byte[infovesa+1Bh],4 ;chainé
je ok_mem_lv
cmp byte[infovesa+1Bh],6 ;couleur directe
je ok_mem_lv
jmp passe_cmdlv
ok_mem_lv:

test dword[infovesa],1h ;on teste si le mode est supporté
jz passe_cmdlv 

mov ax,cx      ;numéros de mode
call affh1j
mov al,":"
call affcj

xor eax,eax             ;résolution
mov ax,[infovesa+18]    ;x
call affnj
mov al,"x"
call affcj
xor eax,eax
mov ax,[infovesa+20]   ;y
call affnj


test dword[infovesa],10h ;on teste si on est un mode texte ou pas
jz modetexte_cmdlv
test dword[infovesa],80h ;on test si le mode accepte la mémoire linéaire
jnz modelineaire_cmdlv


mov al," "          ;bit par pixel
call affcj
xor eax,eax
mov al,[infovesa+25]
call affnj
push cx
mov cl,82
call affmsgsyst
pop cx
jmp passe_cmdlv

modelineaire_cmdlv:
mov al," "          ;bit par pixel
call affcj
xor eax,eax
mov al,[infovesa+25]
call affnj
push cx
mov cl,83
call affmsgsyst
pop cx
jmp passe_cmdlv

modetexte_cmdlv:
push cx
mov cl,81
call affmsgsyst
pop cx

passe_cmdlv:
inc cx
cmp cx,0200h
jne boucle_cmdlv
jmp pascommande





























