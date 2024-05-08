cmdcop_dossier_entree equ 0
cmdcop_dossier_sortie equ 200h
cmdcop_nom_entree equ 400h
cmdcop_nom_sortie equ 600h
cmdcop_handle_dossier_entree equ 800h
cmdcop_handle_dossier_sortie equ 804h
cmdcop_handle_entree equ 808h
cmdcop_handle_sortie equ 80Ch
cmdcop_taille_entree equ 810h
cmdcop_offset_transfert equ 814h
cmdcop_taille_dossier equ 818h
cmdcop_zone_tampon equ 81Ch
cmdcop_taille_tampon equ 100000h


;change la taille de la zt
mov al,8
mov dx,sel_dat1
mov ecx,cmdcop_zone_tampon+cmdcop_taille_tampon
int 61h
cmp eax,0
jne erreur_autres_cmdcop

mov ax,sel_dat1
mov ds,ax
mov es,ax

;recupère le nom du fichier a copier
mov al,4
mov ah,0
mov cl,0
mov edx,cmdcop_dossier_entree
int 61h


;extrait le nom du dossier du nom du fichier
xor esi,esi

@@:
cmp byte[edx],"/"
je cmdcop_slash
cmp byte[edx],"\"
je cmdcop_slash
cmp byte[edx],0
je cmdcop_0
inc edx
jmp @b

cmdcop_slash:
mov esi,edx
inc edx
jmp @b

cmdcop_0:
cmp esi,0
je cmdcop_aucun_dossier


mov byte[esi],0
inc esi
mov ecx,edx
sub ecx,esi
mov edi,cmdcop_nom_entree
cld
rep movsb
jmp @f

cmdcop_aucun_dossier:
mov esi,cmdcop_dossier_entree
mov edi,cmdcop_nom_entree
mov ecx,128
cld
rep movsd
mov byte[cmdcop_dossier_entree],0

@@:




;récupère la destination
mov al,4
mov ah,1
mov cl,0
mov edx,cmdcop_dossier_sortie
int 61h

;recupere le renommage eventuel de la destination
mov al,5
mov ah,"r"
mov cl,0
mov edx,cmdcop_nom_sortie
int 61h

;s'il n'y as pas de renommage, on recopie le nom de sortie
cmp byte[cmdcop_nom_sortie],0
jne @f
mov esi,cmdcop_nom_entree
mov edi,cmdcop_nom_sortie
mov ecx,128
cld
rep movsd
@@:


;***********************************************
mov word[cmdcop_zone_tampon],13

mov al,6
mov edx,cmdcop_nom_entree
int 61h

mov al,6
mov edx,cmdcop_zone_tampon
int 61h

mov al,6
mov edx,cmdcop_nom_sortie
int 61h

mov al,6
mov edx,cmdcop_zone_tampon
int 61h

mov al,6
mov edx,cmdcop_dossier_entree
int 61h

mov al,6
mov edx,cmdcop_zone_tampon
int 61h

mov al,6
mov edx,cmdcop_dossier_sortie
int 61h

mov al,6
mov edx,cmdcop_zone_tampon
int 61h
;*********************************



;ouvre le dossier d'entrée
xor eax,eax
xor ebx,ebx
mov edx,cmdcop_dossier_entree
cmp byte[edx],0
je @f
int 64h
cmp eax,cer_dov
jne erreur_entree_cmdcop
@@:
mov [cmdcop_handle_dossier_entree],ebx


;ouvre le dossier de sortie
xor eax,eax
xor ebx,ebx
mov edx,cmdcop_dossier_sortie
cmp byte[edx],0
je @f
cmp byte[edx],"-"
je @f
int 64h
cmp eax,cer_dov
jne erreur_sortie_cmdcop
@@:
mov [cmdcop_handle_dossier_sortie],ebx






;test si le nom de l'entée contien des * ou des ?
mov esi,cmdcop_nom_entree
@@:
cmp byte[esi],"?"
je cmdcop_multifichier
cmp byte[esi],"*"
je cmdcop_multifichier
cmp byte[esi],0
je cmdcop_monofichier 
inc esi
jmp @b



cmdcop_multifichier:
;lit le contenu du dossier


;filtre le dossier



boucle_multifichier_cmdcop:



int 60h



cmdcop_monofichier: ;un seul fichier



call copiefichier_cmdcop



int 60h


erreur_entree_cmdcop:
erreur_sortie_cmdcop:

call message_erreur_cmdcop


int 60h



;*************************************
copiefichier_cmdcop:
pushad
xor eax,eax         ;ouvre le fichier source
mov ebx,[cmdcop_handle_dossier_entree]
mov edx,cmdcop_nom_entree
int 64h
cmp eax,0
jne erreur_autres_cmdcop
mov [cmdcop_handle_entree],ebx

mov eax,2         ;crée le fichier de destination
mov ebx,[cmdcop_handle_dossier_sortie]
mov edx,cmdcop_nom_sortie
int 64h
cmp eax,0
jne erreur_autres_cmdcop
mov [cmdcop_handle_sortie],ebx



;lit la taille du fichier
mov eax,6
mov ah,1
mov ebx,[cmdcop_handle_entree]
mov edx,cmdcop_zone_tampon
int 64h
cmp eax,0
jne erreur_autres_cmdcop
mov ecx,[cmdcop_zone_tampon]
mov [cmdcop_taille_entree],ecx


;réserver un espace pour le nouveau fichier
mov eax,15       
mov ebx,[cmdcop_handle_sortie]
mov ecx,[cmdcop_taille_entree]
int 64h
cmp eax,0
jne erreur_autres_cmdcop

;copie les données dans la destination

boucle_cmd_cop:
cmp dword[cmdcop_taille_entree],cmdcop_taille_tampon
jb suite3_cmdcop 


mov eax,4         ;lit dans le fichier
mov ebx,[cmdcop_handle_entree]
mov ecx,cmdcop_taille_tampon
mov edx,[cmdcop_offset_transfert]
mov edi,cmdcop_zone_tampon 
int 64h
cmp eax,0
jne erreur_autres_cmdcop

mov eax,5         ;ecrit dans le fichier
mov ebx,[cmdcop_handle_sortie]
mov ecx,cmdcop_taille_tampon
mov edx,[cmdcop_offset_transfert]
mov esi,cmdcop_zone_tampon 
int 64h
cmp eax,0
jne erreur_autres_cmdcop

add dword[cmdcop_offset_transfert],cmdcop_taille_tampon
sub dword[cmdcop_taille_entree],cmdcop_taille_tampon
jmp boucle_cmd_cop

suite3_cmdcop:
cmp dword[cmdcop_taille_entree],0
je ok_cmdcop

mov eax,4         ;lit dans le fichier
mov ebx,[cmdcop_handle_entree]
mov ecx,[cmdcop_taille_entree]
mov edx,[cmdcop_offset_transfert]
mov edi,cmdcop_zone_tampon
int 64h
cmp eax,0
jne erreur_autres_cmdcop

mov eax,5         ;ecrit dans le fichier
mov ebx,[cmdcop_handle_sortie]
mov ecx,[cmdcop_taille_entree]
mov edx,[cmdcop_offset_transfert]
mov esi,cmdcop_zone_tampon 
int 64h
cmp eax,0
jne erreur_autres_cmdcop



ok_cmdcop:
mov al,13
mov ah,0
mov cl,98
mov ch,0
mov edx,cmdcop_zone_tampon
int 61h
mov al,6
int 61h

mov al,6
mov edx,cmdcop_nom_entree
int 61h

mov al,13
mov ah,0
mov cl,95
mov ch,0
mov edx,cmdcop_zone_tampon
int 61h
mov al,6
int 61h

mov al,6
mov edx,cmdcop_nom_sortie
int 61h

mov word[cmdcop_zone_tampon],13
mov al,6
mov edx,cmdcop_zone_tampon
int 61h
popad
ret



erreur_autres_cmdcop:
call message_erreur_cmdcop
popad
ret



;****************************************
message_erreur_cmdcop:
push eax

mov al,13
mov ah,0
mov cl,3
mov ch,0
mov edx,cmdcop_zone_tampon
int 61h
mov al,6
int 61h


mov al,3
mov edx,cmdcop_zone_tampon
int 61h
mov al,6
int 61h

mov word[cmdcop_zone_tampon],0D22h  ;" puis CR

pop ecx
mov al,13
mov ah,1
mov ch,0
mov edx,cmdcop_zone_tampon+2
int 61h
mov al,6
mov edx,cmdcop_zone_tampon
int 61h

mov word[cmdcop_zone_tampon],0017h  ;fin de couleur
mov al,6
mov edx,cmdcop_zone_tampon
int 61h

ret