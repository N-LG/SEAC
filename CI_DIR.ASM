;commande integré pour visualiser les fichier du dossier courant


mov cl,70
call affmsgsyst
mov edx,ad_repertoire
call affjournal
mov al,13
call affcj

mov ebx,[ad_ficho] ;adresse du descripteur de fichier ouvert
push ds
mov ax,selramh
mov ds,ax
mov al,[ebx]
pop ds
and al,00111100b
cmp al,10000b
je dirtypefat
cmp al,10100b
je dirtypefat
cmp al,11000b
je dirtypefat
cmp al,100b
je dirtypeiso9660

jmp pascommande

dirtypeiso9660:
xor edx,edx
boucle_dir_cd:
mov ax,seldat
mov es,ax
mov edi,ad_chaine_travail
xor ebx,ebx
mov ecx,255  ;ecx=quantité a lire
mov al,4
push edx
int 64h
cmp al,0
jne cmddirerr1

test byte[ad_chaine_travail+25],02h
jz pasdossierdircd
mov al,19h
call affcj
pasdossierdircd:

xor ebx,ebx
mov bl,[ad_chaine_travail+32]
add ebx,33
mov byte[ad_chaine_travail+ebx],0

mov ebx,ad_chaine_travail+33
boucledireffacever:
cmp byte[ebx],0
je findireffacever
cmp byte[ebx],";"
je findireffacever
inc ebx
jmp boucledireffacever
findireffacever:
mov byte[ebx],0

mov edx,ad_chaine_travail+33
call affjournal

mov al,17h
call affcj
mov al,13
call affcj
pop edx
xor eax,eax
mov al,[ad_chaine_travail]
cmp eax,0
je pascommande
add edx,eax
mov eax,edx
jmp boucle_dir_cd


dirtypefat:
mov ax,seldat
mov ds,ax
mov fs,ax
mov ax,selramh
mov es,ax

mov ecx,20000h
call resmem
jc cmddirerr2
mov ebp,ebx
add ebp,10h
xor edx,edx
xor ebx,ebx

recharge_dir_fat:
mov edi,ebp
add edx,ebx
xor ebx,ebx
mov ecx,20000h
mov al,4
int 64h
cmp eax,0
jne cmddirerr1
xor ebx,ebx

boucle_dir_fat:
mov esi,ebp

cmp ebx,20000h
jae recharge_dir_fat
es
cmp byte[ebx+esi],0
je findirfat
es
cmp byte[ebx+esi],02Eh
je suivant_dir_fat
es
cmp byte[ebx+esi],0E5h
je suivant_dir_fat
es
cmp byte[ebx+esi+0Bh],0Fh
je dir_vfat

es                            ;FAT Standard
test byte[ebx+esi+0Bh],010h
jz pasdossierdirfat
mov al,19h                ;couleur pour un dossier
call affcj
pasdossierdirfat:

mov edi,ad_chaine_travail
boucle1_dir_fat:
es
mov al,[ebx+esi]
cmp al," "
je finboucle1_dir_fat
mov [edi],al
inc esi
inc edi
cmp edi,ad_chaine_travail+8
jb boucle1_dir_fat

finboucle1_dir_fat:
mov esi,ebp
es
mov eax,[ebx+esi+8]
and eax,0FFFFFFh
cmp eax,202020h
je aff_dir_fat

mov byte[edi],"."
inc edi

mov [edi],al
inc edi
shr eax,8
cmp al," "
je aff_dir_fat
mov [edi],al
inc edi
shr eax,8
cmp al," "
je aff_dir_fat
mov [edi],al
inc edi

aff_dir_fat:                            
mov byte[edi],0


mov edx,ad_chaine_travail
call affjournal

mov al,17h
call affcj
mov al,13
call affcj

suivant_dir_fat:
add ebx,32
jmp boucle_dir_fat


dir_vfat:                    ;Vfat
es
mov cl,[ebx+esi]
test cl,40h    ;on test si c'est bien le marqueur de début de descripteur de nom long
je suivant_dir_fat
and ecx,3Fh
shl ecx,5
add esi,ecx
add ecx,32

es
test byte[ebx+esi+0Bh],010h
jz pasdossierdirvfat
mov al,19h                ;couleur pour un dossier
call affcj
pasdossierdirvfat:
;calcul du checksum  §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

mov edi,ad_chaine_travail
boucle_dir_vfat:
sub esi,32
;verification du checksum§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
xor eax,eax
es
mov ax,[ebx+esi+01h]
call utf8_vfat
es
mov ax,[ebx+esi+03h]
call utf8_vfat
es
mov ax,[ebx+esi+05h]
call utf8_vfat
es
mov ax,[ebx+esi+07h]
call utf8_vfat
es
mov ax,[ebx+esi+09h]
call utf8_vfat
es
mov ax,[ebx+esi+0Eh]
call utf8_vfat
es
mov ax,[ebx+esi+10h]
call utf8_vfat
es
mov ax,[ebx+esi+12h]
call utf8_vfat
es
mov ax,[ebx+esi+14h]
call utf8_vfat
es
mov ax,[ebx+esi+16h]
call utf8_vfat
es
mov ax,[ebx+esi+18h]
call utf8_vfat
es
mov ax,[ebx+esi+1Ch]
call utf8_vfat
es
mov ax,[ebx+esi+1Eh]
call utf8_vfat
cmp esi,ebp
jne boucle_dir_vfat
fs
mov byte[edi],0

mov edx,ad_chaine_travail
call affjournal

mov al,17h
call affcj
mov al,13
call affcj

add ebx,ecx
jmp boucle_dir_fat


findirfat:
mov ebx,ebp
sub ebx,10h
call libmem
jmp pascommande

cmddirerr1:   ;erreur de lecture
mov ebx,ebp
sub ebx,10h
call libmem
mov cl,3
call affmsgsyst
jmp pascommande

cmddirerr2:    ;erreur de mémoire
mov cl,5
call affmsgsyst
jmp pascommande
















