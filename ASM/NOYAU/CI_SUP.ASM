cmdsup_nom_dossier equ 0
cmdsup_filtre equ 512
cmdsup_handle_dossier equ 1020
cmdsup_zone_tampon equ 1024
cmdsup_zone_dossier equ 2048
cmdsup_taille equ 4096


;change la taille de mémoire
mov al,8
mov dx,sel_dat1
mov ecx,cmdsup_zone_dossier+cmdsup_taille
int 61h
cmp eax,0
je @f
call erreur_autres_cmdsup
int 60h
@@:
mov ax,sel_dat1
mov ds,ax
mov es,ax


;recupere le dossier actuel
mov edx,cmdsup_nom_dossier
mov eax,18
int 61h


;recupère le nom du fichier/filtre a supprimer
mov al,4
mov ah,0
mov cl,0
mov edx,cmdsup_filtre
int 61h


;cherche la fin du nom de dossier
mov ebx,cmdsup_nom_dossier
@@:
cmp byte[ebx],0
je @f
inc ebx
jmp @b
@@:


;ajoute un / a la fin du dossier si il n'y en as pas déjà 1
dec ebx
cmp byte[ebx],"/"
je @f
cmp byte[ebx],"\"
je @f
inc ebx
mov word[ebx],"/"
@@:
inc ebx


;si le filtre est une adresse absolue, on ignore l'adresse de base
cmp byte[cmdsup_filtre],"#"
jne @f
mov ebx,cmdsup_nom_dossier
@@:
mov byte[ebx],0  ;ebx=fin de l'adresse du dossier


;si le filtre commence par un / on le supprime
cmp byte[cmdsup_filtre],"/"
je @f
cmp byte[cmdsup_filtre],"\"
jne boucle_separation_cmdsup
@@:
mov esi,cmdsup_filtre+1
mov edi,cmdsup_filtre
mov ecx,64
cld
rep movsd


;sépare l'adresse et le filtre de supression
boucle_separation_cmdsup:
mov eax,[cmdsup_filtre]
and eax,0FFFFFFh
cmp eax,"../"
je dossier_prec_cmdsup
cmp eax,"..\"
je dossier_prec_cmdsup


mov edx,cmdsup_filtre
@@:
cmp word[edx],"//"
je cmdsup_erreuradresse
cmp word[edx],"\\"
je cmdsup_erreuradresse
cmp word[edx],"/\"
je cmdsup_erreuradresse
cmp word[edx],"\/"
je cmdsup_erreuradresse

cmp byte[edx],"/"
je ajdossier_cmdsup
cmp byte[edx],"\"
je ajdossier_cmdsup
cmp byte[edx],0
je finseparation_cmdsup
inc edx
jmp @b

dossier_prec_cmdsup:
cmp ebx,cmdsup_nom_dossier
je cmdsup_erreuradresse
dec ebx
cmp ebx,cmdsup_nom_dossier
je cmdsup_erreuradresse
dec ebx
@@:
cmp byte[ebx],"/"
je @f
cmp byte[ebx],"\"
je @f
cmp ebx,cmdsup_nom_dossier
je cmdsup_erreuradresse
dec ebx
jmp @b

@@:
mov edx,cmdsup_filtre+3
inc ebx
jmp @f


ajdossier_cmdsup:
inc edx
mov ecx,edx
mov esi,cmdsup_filtre
mov edi,ebx
sub ecx,esi
cld
rep movsb
mov ebx,edi

@@:
mov byte[ebx],0
mov esi,edx
mov edi,cmdsup_filtre
mov ecx,64
cld
rep movsd
jmp boucle_separation_cmdsup


finseparation_cmdsup:
;ouvre le dossier
xor eax,eax         ;ouvre le dossier qui contiens les fichier a supprimer
xor ebx,ebx
mov edx,cmdsup_nom_dossier
int 64h
cmp eax,12
jne cmdsup_erreurdossier
mov [cmdsup_handle_dossier],ebx


;test si le nom de l'entée contient des *,<,>,|, ou des ?
mov esi,cmdsup_filtre
@@:
cmp byte[esi],"*"
je cmdsup_multifichier
cmp byte[esi],"<"
je cmdsup_multifichier
cmp byte[esi],">"
je cmdsup_multifichier
cmp byte[esi],"|"
je cmdsup_multifichier
cmp byte[esi],"?"
je cmdsup_multifichier
cmp byte[esi],0
je cmdsup_monofichier 
inc esi
jmp @b


cmdsup_monofichier:
mov edx,cmdsup_filtre
call cmdsup_supprime1
int 60h


cmdsup_multifichier:
mov edx,0
boucle1_cmdsup:
mov eax,16        ;lire partie liste fichier
mov ebx,[cmdsup_handle_dossier]
mov ecx,cmdsup_taille
mov edi,cmdsup_zone_dossier
int 64h
add edx,ebx

cmp byte[cmdsup_nom_dossier],0
je @f
push eax
push esi
push edi
mov al,160
mov esi,cmdsup_filtre
mov edi,cmdsup_zone_dossier
int 61h
pop edi
pop esi
pop eax
@@:

push eax
push edx
xor ecx,ecx
mov ebx,cmdsup_zone_dossier
cmp byte[ebx],"|"
jne @f
inc ebx
@@:
mov edx,ebx
boucle2_cmdsup:
cmp byte[ebx],"|"
je affiche_cmdsup 
cmp byte[ebx],0
je fin2_cmdsup 
inc ebx
jmp boucle2_cmdsup

affiche_cmdsup:
mov byte[ebx],0
inc ebx
call cmdsup_supprime1
mov edx,ebx
jmp boucle2_cmdsup

fin2_cmdsup:
call cmdsup_supprime1
pop edx
pop eax

cmp eax,cer_pasm
je boucle1_cmdsup
cmp eax,0
jne erreur_autres_cmdsup
int 60h


cmdsup_erreuradresse:
mov eax,cer_parami
call erreur_autres_cmdsup
int 60h


cmdsup_erreurdossier:
mov eax,cer_lecnt
call erreur_autres_cmdsup
int 60h




cmdsup_supprime1:  ;supprime le fichier/dossier pointé par edx
pushad
xor eax,eax         ;ouvre le fichier/dossier
mov ebx,[cmdsup_handle_dossier]
int 64h
cmp eax,12
je @f
cmp eax,0
jne erreur_autres2_cmdsup
@@:

mov eax,3    ;supprime le fichier/dossier
int 64h
cmp eax,0       
je cmdsup_ok_supprime1
cmp eax,21
jne erreur_autres2_cmdsup

;efface les fichier dans le dossier si celui ci n'est pas vide
mov edi,cmdsup_zone_tampon
mov dword[edi],"sup "
add edi,4

mov esi,cmdsup_nom_dossier
@@:
mov al,[esi]
cmp al,0
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:

mov esi,edx
@@:
mov al,[esi]
cmp al,0
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:

mov dword[edi],"/*"


mov al,0    ;envoie la commande au systeme
mov edx,cmdsup_zone_tampon 
int 61h

@@:         ;et attend que celle ci soit executé
int 62h
mov al,19
mov cl,128
mov edx,cmdsup_zone_tampon
mov word[edx],0
int 61h
cmp word[cmdsup_zone_tampon],0
jne @b










mov eax,3    ;supprime le dossier, normalement il n'y as plus de fichier maintenant
int 64h
cmp eax,0       
jne erreur_autres2_cmdsup

cmdsup_ok_supprime1:
push edx
mov al,13
mov ah,0
mov cl,98
mov ch,0
mov edx,cmdsup_zone_tampon
int 61h
mov al,6
int 61h

mov al,6
mov edx,cmdsup_nom_dossier
int 61h

mov al,6
pop edx
int 61h

mov al,13
mov ah,0
mov cl,96
mov ch,0
mov edx,cmdsup_zone_tampon
int 61h
mov al,6
int 61h

popad
ret

erreur_autres2_cmdsup:
call erreur_autres_cmdsup
popad
ret

erreur_autres_cmdsup:
push eax

mov al,13
mov ah,0
mov cl,3
mov ch,0
mov edx,cmdsup_zone_tampon
int 61h
mov al,6
int 61h


mov al,3
mov edx,cmdsup_zone_tampon
int 61h
mov al,6
int 61h

mov word[cmdsup_zone_tampon],0D22h  ;" puis CR

pop ecx
mov al,13
mov ah,1
mov ch,0
mov edx,cmdsup_zone_tampon+2
int 61h
mov al,6
mov edx,cmdsup_zone_tampon
int 61h

mov word[cmdsup_zone_tampon],0017h  ;fin de couleur
mov al,6
mov edx,cmdsup_zone_tampon
int 61h

ret
