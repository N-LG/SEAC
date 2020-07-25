;commande integré pour visualiser les fichier du dossier courant

cmddir_nom_dossier equ 0
cmddir_zt_affichage equ 512
cmddir_handle_dossier equ 1024
cmddir_taille_script equ 1028
cmddir_zone_tampon equ 1032
cmddir_taille equ 60 ;512


;change la taille de la zone mémoire
mov al,8
mov dx,sel_dat1
mov ecx,cmddir_zone_tampon+cmddir_taille+1
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

add edx,ecx
cmp eax,cer_pasm
je boucle1_cmd_dir
cmp eax,0
jne erreur_autres_cmddir

int 60h


;****************************************************
erreur_autres_cmddir:
push eax

mov al,13
mov ah,0
mov cl,3
mov ch,0
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
mov ch,0
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
