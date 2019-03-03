
mov edx,ad_zdc

boucle1_cmdcop:     ;trouve le debut du nom du fichier
cmp byte[edx],0
je fin_commande_erreur_param         ;si on arrive a la fin de la chaine c'est une erreur
inc edx
cmp byte[edx]," "
jne boucle1_cmdcop
cmp byte[edx+1]," "
je boucle1_cmdcop          

inc edx
mov esi,edx

boucle2_cmdcop:     ;trouve le debut du nouveau nom du fichier
cmp byte[edx],0
je fin_commande_erreur_param         ;si on arrive a la fin de la chaine c'est une erreur
inc edx
cmp byte[edx]," "
jne boucle2_cmdcop   

mov byte[edx],0
inc edx
mov edi,edx

mov [ad_chaine_travail],esi
mov [ad_chaine_travail+4],edi

xor eax,eax         ;ouvre le fichier source
xor ebx,ebx
mov edx,esi
int 64h
cmp eax,0
jne fin_commande_erreur
mov esi,ebx

mov eax,2         ;crée le fichier de destination
xor ebx,ebx
mov edx,edi
int 64h
cmp eax,0
jne fin_commande_erreur
mov edi,ebx

;lit la taille du fichier
mov eax,6
mov ah,1
mov ebx,esi
mov edx,ad_chaine_travail+8
int 64h
cmp eax,0
jne fin_commande_erreur
mov ecx,[ad_chaine_travail+8]

taille_zt_cop equ 40000h ;taille de la zt employé
;réserve une ZT
mov ecx,taille_zt_cop
call resmem
jc erreur_mem_cmdcop
add ebx,10h
mov ebp,ebx

;copie les données dans la destination
mov ax,selramh
mov ds,ax
mov es,ax
xor edx,edx

boucle_cmd_cop:
cmp ecx,taille_zt_cop
jb suite3_cmdcop 

push ecx
push edi
mov eax,4         ;lit dans le fichier
mov ebx,esi
mov ecx,taille_zt_cop
mov edi,ebp
int 64h
pop edi
pop ecx
cmp eax,0
jne erreur_autres_cmdcop


push ecx
push esi
mov eax,5         ;ecrit dans le fichier
mov ebx,edi
mov ecx,taille_zt_cop
mov esi,ebp
int 64h
pop esi
pop ecx
cmp eax,0
jne erreur_autres_cmdcop

add edx,taille_zt_cop
sub ecx,taille_zt_cop
jmp boucle_cmd_cop

suite3_cmdcop:
cmp ecx,0
je suite4_cmdcop

push ecx
push edi
mov eax,4         ;lit dans le fichier
mov ebx,esi
mov edi,ebp
int 64h
pop edi
pop ecx
cmp eax,0
jne erreur_autres_cmdcop

push ecx
push esi
mov eax,5         ;ecrit dans le fichier
mov ebx,edi
mov esi,ebp
int 64h
pop esi
pop ecx
cmp eax,0
jne erreur_autres_cmdcop

suite4_cmdcop:
mov ebx,ebp ;libère la ZT
sub ebx,10h
call libmem

mov eax,1    ;ferme les fichiers
mov ebx,esi
int 64h
cmp eax,0
jne fin_commande_erreur
mov eax,1
mov ebx,edi
int 64h
cmp eax,0
jne fin_commande_erreur

mov ax,seldat
mov ds,ax
mov cl,98   
call affmsgsyst
mov edx,[ad_chaine_travail]
call affjournal
mov cl,95   
mov edx,[ad_chaine_travail+4]
call affmsgsyst
call affjournal
mov al,13
call affcj
jmp pascommande

erreur_mem_cmdcop:
mov cl,11   
call affmsgsyst
jmp pascommande


erreur_autres_cmdcop:
mov ebx,ebp ;libère la ZT
sub ebx,10h
call libmem
jmp fin_commande_erreur
