;commande integré pour visualiser les fichier du dossier courant

cmddir_nom_dossier equ 0
cmddir_zt_affichage equ 512
cmddir_filtre equ 1024
cmddir_handle_dossier equ 1536
cmddir_zone_tampon equ 1540
cmddir_taille equ 4096


;change la taille de la zone mémoire
mov al,8
mov dx,sel_dat1
mov ecx,cmddir_zone_tampon+cmddir_taille
int 61h
cmp eax,0
jne erreur_autres_cmddir

mov ax,sel_dat1
mov ds,ax
mov es,ax

;recupère le nom du dossier 
mov edx,cmddir_nom_dossier
mov eax,18
int 61h


;récupère le filtre
mov al,4
mov ah,0
mov edx,cmddir_filtre
mov cl,0
int 61h



;cherche la fin du nom de dossier
mov ebx,cmddir_nom_dossier
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
cmp byte[cmddir_filtre],"#"
jne @f
mov ebx,cmddir_nom_dossier
@@:
mov byte[ebx],0  ;ebx=fin de l'adresse du dossier


;si le filtre commence par un / on le supprime
cmp byte[cmddir_filtre],"/"
je @f
cmp byte[cmddir_filtre],"\"
jne boucle_separation_cmddir
@@:
mov esi,cmddir_filtre+1
mov edi,cmddir_filtre
mov ecx,64
cld
rep movsd


;sépare l'adresse et le filtre de supression
boucle_separation_cmddir:
mov eax,[cmddir_filtre]
and eax,0FFFFFFh
cmp eax,"../"
je dossier_prec_cmddir
cmp eax,"..\"
je dossier_prec_cmddir


mov edx,cmddir_filtre
@@:
cmp word[edx],"//"
je cmddir_erreuradresse
cmp word[edx],"\\"
je cmddir_erreuradresse
cmp word[edx],"/\"
je cmddir_erreuradresse
cmp word[edx],"\/"
je cmddir_erreuradresse

cmp byte[edx],"/"
je ajdossier_cmddir
cmp byte[edx],"\"
je ajdossier_cmddir
cmp byte[edx],0
je finseparation_cmddir
inc edx
jmp @b

dossier_prec_cmddir:
cmp ebx,cmddir_nom_dossier
je cmddir_erreuradresse
dec ebx
cmp ebx,cmddir_nom_dossier
je cmddir_erreuradresse
dec ebx
@@:
cmp byte[ebx],"/"
je @f
cmp byte[ebx],"\"
je @f
cmp ebx,cmddir_nom_dossier
je cmddir_erreuradresse
dec ebx
jmp @b

@@:
mov edx,cmddir_filtre+3
inc ebx
jmp @f


ajdossier_cmddir:
inc edx
mov ecx,edx
mov esi,cmddir_filtre
mov edi,ebx
sub ecx,esi
cld
rep movsb
mov ebx,edi

@@:
mov byte[ebx],0
mov esi,edx
mov edi,cmddir_filtre
mov ecx,64
cld
rep movsd
jmp boucle_separation_cmddir


finseparation_cmddir:
;si il n'y as pas de caractère spéciaux dans le filtre, c'est qu'il s'agit d'un nom
mov esi,cmddir_filtre
@@:
cmp byte[esi],"*"
je cmddir_nomfiltreok
cmp byte[esi],"<"
je cmddir_nomfiltreok
cmp byte[esi],">"
je cmddir_nomfiltreok
cmp byte[esi],"|"
je cmddir_nomfiltreok
cmp byte[esi],"?"
je cmddir_nomfiltreok
cmp byte[esi],0
je @f
inc esi
jmp @b

@@:
mov ecx,esi
mov esi,cmddir_filtre
mov edi,ebx
sub ecx,esi
cld
rep movsb
mov byte[cmddir_filtre],0
cmddir_nomfiltreok:

;ouvre le dossier
xor eax,eax
xor ebx,ebx
mov edx,cmddir_nom_dossier
int 64h
cmp eax,cer_dov
jne erreur_autres_cmddir
mov [cmddir_handle_dossier],ebx


;affiche le nom du dossier
mov al,13
mov ah,0
mov ecx,70
mov edx,cmddir_zone_tampon
int 61h
mov al,6
int 61h
mov edx,cmddir_nom_dossier
mov al,6
int 61h
mov edx,cmddir_filtre
mov al,6
int 61h
mov word[cmddir_zone_tampon],000Dh  ;fin et CR
mov al,6
mov edx,cmddir_zone_tampon
int 61h










;***********************************************
;boucle principale
mov edx,0
boucle1_cmd_dir:
mov eax,16        ;lire partie liste fichier
mov ebx,[cmddir_handle_dossier]
mov ecx,cmddir_taille
mov edi,cmddir_zone_tampon
int 64h
add edx,ebx

cmp byte[cmddir_filtre],0
je @f
push eax
push esi
push edi
mov al,160
mov esi,cmddir_filtre
mov edi,cmddir_zone_tampon
int 61h
pop edi
pop esi
pop eax
@@:

push eax
push edx
xor ecx,ecx
mov ebx,cmddir_zone_tampon
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
pop edx
pop eax

cmp eax,cer_pasm
je boucle1_cmd_dir
cmp eax,0
jne erreur_autres_cmddir

int 60h



;****************************************************
cmddir_erreuradresse:
mov eax,cer_parami


erreur_autres_cmddir:
push eax

mov al,13
mov ah,0
mov ecx,3
mov edx,cmddir_zone_tampon
int 61h
mov al,6
int 61h

mov al,3
mov edx,cmddir_zone_tampon
int 61h
mov al,6
int 61h

mov word[cmddir_zone_tampon],0D22h  ;" puis CR
pop ecx
mov al,13
mov ah,1
mov edx,cmddir_zone_tampon+2
int 61h
mov al,6
mov edx,cmddir_zone_tampon
int 61h

mov word[cmddir_zone_tampon],0017h  ;fin de couleur
mov al,6
mov edx,cmddir_zone_tampon
int 61h


int 60h














;*******************************************
affiche_ligne_dir:
inc ecx
pushad
;jmp affiche_ligne_dir_ouvert
xor eax,eax
mov ebx,[cmddir_handle_dossier]
int 64h             ;ouvre le fichier
cmp eax,cer_dov
je affiche_ligne_dir_dossier
cmp eax,0
jne affiche_ligne_dir_ouvert

mov al,6
int 61h

;lit la taille
mov al,6
mov ah,1
mov edx,edi
mov edx,cmddir_zt_affichage+64
int 64h

mov eax,1   ;ferme le fichier
int 64h


;affiche la taille
mov dword[cmddir_zt_affichage]," - "
mov edx,cmddir_zt_affichage+3
mov ecx,[cmddir_zt_affichage+64]
mov eax,102
int 61h
mov al,6
mov edx,cmddir_zt_affichage
int 61h

mov al,13
mov ah,0
mov ecx,78
mov edx,cmddir_zt_affichage
int 61h
mov al,6
mov edx,cmddir_zt_affichage
int 61h
popad
ret





affiche_ligne_dir_dossier:
mov eax,1
int 64h

push edx
mov word[cmddir_zt_affichage],019h  ;19h et fin
mov al,6
mov edx,cmddir_zt_affichage
int 61h
mov al,6
pop edx
int 61h
mov dword[cmddir_zt_affichage],000D17h  ;CR, 17h et fin
mov al,6
mov edx,cmddir_zt_affichage
int 61h
popad
ret


affiche_ligne_dir_ouvert:
push edx
mov word[cmddir_zt_affichage],01Ch  ;1Ch et fin
mov al,6
mov edx,cmddir_zt_affichage
int 61h
mov al,6
pop edx
int 61h
mov dword[cmddir_zt_affichage],000D17h  ;CR, 17h et fin
mov al,6
mov edx,cmddir_zt_affichage
int 61h
popad
ret
