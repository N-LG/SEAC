;commande integré pour visualiser les fichier du dossier courant


mov cl,70
call affmsgsyst
mov edx,ad_repertoire
call affjournal
mov al,13
call affcj

taille_ztdir equ 2048

mov ecx,taille_ztdir+40h
call resmem
jc pascommande 
mov edi,ebx
add edi,50h

mov ax,selramh
mov ds,ax
mov edx,0
boucle1_cmd_dir:
mov eax,16        ;lire liste fichier
xor ebx,ebx
mov ecx,taille_ztdir
int 64h
pushad

mov ebx,edi
mov edx,ebx

boucle2_cmd_dir:
cmp byte[ebx],"|"
je affiche_cmd_dir 
cmp byte[ebx],0
je fin_cmd_dir 
inc ebx
jmp boucle2_cmd_dir


affiche_cmd_dir:
mov byte[ebx],0
inc ebx
call affiche_ligne_dir
mov edx,ebx
jmp boucle2_cmd_dir


fin_cmd_dir:
call affiche_ligne_dir
popad

add edx,ebx
cmp eax,cer_pasm
je boucle1_cmd_dir
cmp eax,0
jne err_cmddir

mov ebx,edi
sub ebx,10h
call libmem
jmp pascommande



err_cmddir:
mov ebx,edi
sub ebx,50h
call libmem
jmp fin_commande_erreur





affiche_ligne_dir:
pushad

xor eax,eax
xor ebx,ebx
int 64h             ;ouvre le fichier
cmp eax,cer_dov
je affiche_ligne_dir_dossier
cmp eax,0
jne affiche_ligne_dir_ouvert


push edx;lit la taille
mov al,6
mov ah,1
mov edx,edi
sub edx,40h
int 64h


mov eax,1   ;ferme le fichier
int 64h

pop edx
call affjournal   ;affiche le nom

mov al," "
call affcj
mov al,"-"
call affcj
mov al," "
call affcj
mov edx,edi
sub edx,40h
mov ecx,[edx]
mov eax,102
int 61h
call affjournal  ;affiche la taille
mov cl,78
call affmsgsyst

popad
ret





affiche_ligne_dir_dossier:
mov eax,1
int 64h

mov al,19h
call affcj
call affjournal
mov al,17h
call affcj
mov al,13
call affcj
popad
ret


affiche_ligne_dir_ouvert:
mov al,1Ch
call affcj
call affjournal
mov al,17h
call affcj
mov al,13
call affcj
popad
ret
