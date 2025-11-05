cmdcop_dossier_entree equ 0
cmdcop_dossier_sortie equ 200h
cmdcop_nom_entree equ 400h
cmdcop_nom_sortie equ 600h
cmdcop_handle_dossier_entree equ 800h
cmdcop_handle_dossier_sortie equ 804h
cmdcop_handle_entree equ 808h
cmdcop_handle_sortie equ 80Ch
cmdcop_taille_entree equ 810h
cmdcop_offset_transfert equ 818h
cmdcop_options equ 81Ch
cmdcop_zone_tampon equ 820h
cmdcop_taille_tampon equ 200000h
cmdcop_zone_dossier equ cmdcop_zone_tampon + cmdcop_taille_tampon


;change la taille de la zt
mov al,8
mov dx,sel_dat1
mov ecx,cmdcop_zone_tampon+cmdcop_taille_tampon
int 61h
cmp eax,0
jne erreur_memoire_cmdcop

mov ax,sel_dat1
mov ds,ax
mov es,ax


;recupère le nom du dossier 
mov edx,cmdcop_dossier_entree
mov eax,18
int 61h



;recupère le nom du fichier a copier
mov al,4
mov ah,0
mov cl,0
mov edx,cmdcop_nom_entree
int 61h




;cherche la fin du nom de dossier
mov ebx,cmdcop_dossier_entree
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
cmp byte[cmdcop_nom_entree],"#"
jne @f
mov ebx,cmdcop_dossier_entree
@@:
mov byte[ebx],0  ;ebx=fin de l'adresse du dossier


;si le filtre commence par un / on le supprime
cmp byte[cmdcop_nom_entree],"/"
je @f
cmp byte[cmdcop_nom_entree],"\"
jne boucle_separation_cmdcop
@@:
mov esi,cmdcop_nom_entree+1
mov edi,cmdcop_nom_entree
mov ecx,64
cld
rep movsd


;sépare l'adresse et le filtre de supression
boucle_separation_cmdcop:
mov eax,[cmdcop_nom_entree]
and eax,0FFFFFFh
cmp eax,"../"
je dossier_prec_cmdcop
cmp eax,"..\"
je dossier_prec_cmdcop


mov edx,cmdcop_nom_entree
@@:
cmp word[edx],"//"
je erreur_param_cmdcop
cmp word[edx],"\\"
je erreur_param_cmdcop
cmp word[edx],"/\"
je erreur_param_cmdcop
cmp word[edx],"\/"
je erreur_param_cmdcop

cmp byte[edx],"/"
je ajdossier_cmdcop
cmp byte[edx],"\"
je ajdossier_cmdcop
cmp byte[edx],0
je finseparation_cmdcop
inc edx
jmp @b

dossier_prec_cmdcop:
cmp ebx,cmdcop_dossier_entree
je erreur_param_cmdcop
dec ebx
cmp ebx,cmdcop_dossier_entree
je erreur_param_cmdcop
dec ebx
@@:
cmp byte[ebx],"/"
je @f
cmp byte[ebx],"\"
je @f
cmp ebx,cmdcop_dossier_entree
je erreur_param_cmdcop
dec ebx
jmp @b

@@:
mov edx,cmdcop_nom_entree+3
inc ebx
jmp @f


ajdossier_cmdcop:
inc edx
mov ecx,edx
mov esi,cmdcop_nom_entree
mov edi,ebx
sub ecx,esi
cld
rep movsb
mov ebx,edi

@@:
mov byte[ebx],0
mov esi,edx
mov edi,cmdcop_nom_entree
mov ecx,64
cld
rep movsd
jmp boucle_separation_cmdcop


finseparation_cmdcop:

;recupère le nom du dossier 
mov edx,cmdcop_dossier_sortie
mov eax,18
int 61h


;cherche la fin du nom de dossier
mov ebx,cmdcop_dossier_sortie
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

;récupère la destination
mov al,4
mov ah,1
mov cl,0
mov edx,ebx
int 61h

 
;si ça commence par un / on le supprime
cmp byte[ebx],"/"
je @f
cmp byte[ebx],"\"
jne cmdcop_supslash  
@@:
mov esi,ebx
mov edi,ebx
inc esi
mov ecx,64
cld
rep movsd
cmdcop_supslash:

;gestion des retours dossier
boucle_retour_dossier_cmdcop:
mov eax,[ebx]
and eax,0FFFFFFh
cmp eax,"../"
je @f
cmp eax,"..\"
jne fin_retour_dossier_cmdcop

@@:
mov esi,ebx
mov edi,ebx
add esi,3
mov ecx,64
cmp edi,cmdcop_dossier_sortie
je erreur_param_cmdcop
dec edi
@@:
cmp edi,cmdcop_dossier_sortie
je erreur_param_cmdcop
dec edi
cmp byte[edi],"/"
je @f
cmp byte[edi],"\"
je @f
jmp @b

@@:
inc edi
mov ebx,edi
cld
rep movsd
jmp boucle_retour_dossier_cmdcop

fin_retour_dossier_cmdcop:


;si la destination commence par un #, on ignore le dossier actuel
cmp byte[ebx],"#"
jne cmdcop_ignrdm
mov esi,ebx
mov edi,cmdcop_dossier_sortie
mov ecx,64
cld
rep movsd

;ajoute un / a la fin du dossier si il n'y en as pas déjà 1
mov ebx,cmdcop_dossier_sortie
@@:
cmp byte[ebx],0
je @f
inc ebx
jmp @b
@@:
dec ebx
cmp byte[ebx],"/"
je @f
cmp byte[ebx],"\"
je @f
inc ebx
mov word[ebx],"/"
@@:
inc ebx
cmdcop_ignrdm:



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


;récupère les options
mov al,5   
mov ah,"n"   ;lettre de l'option de commande a lire
mov cl,1 ;0=256 octet max
mov edx,cmdcop_zone_tampon
int 61h
cmp eax,0
jne @f
or byte[cmdcop_options],1
@@:

mov al,5   
mov ah,"e"   ;lettre de l'option de commande a lire
mov cl,1 ;0=256 octet max
mov edx,cmdcop_zone_tampon
int 61h
cmp eax,0
jne @f
or byte[cmdcop_options],2
@@:

mov al,5   
mov ah,"f"   ;lettre de l'option de commande a lire
mov cl,1 ;0=256 octet max
mov edx,cmdcop_zone_tampon
int 61h
cmp eax,0
jne @f
or byte[cmdcop_options],4
@@:

mov al,5   
mov ah,"d"   ;lettre de l'option de commande a lire
mov cl,1 ;0=256 octet max
mov edx,cmdcop_zone_tampon
int 61h
cmp eax,0
jne @f
or byte[cmdcop_options],8
@@:




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



;ouvre ou cree le dossier de sortie
xor eax,eax
xor ebx,ebx
mov edx,cmdcop_dossier_sortie
cmp byte[edx],0
je cmdcop_ok_ouverture_dossier_sortie
cmp byte[edx],"-"
je cmdcop_ok_ouverture_dossier_sortie
int 64h
cmp eax,cer_dov
je cmdcop_ok_ouverture_dossier_sortie
bt word[cmdcop_options],0
jnc  erreur_sortie1_cmdcop


;si le dossier ne peut pas être ouvert et si on a l'option, on créer le dossier

;on rajoute une cotice et point a la fin du nom de dossier
mov edx,cmdcop_dossier_sortie
@@:     
inc edx
cmp byte[edx],0
jne @b

@@:  
dec edx
cmp byte[edx]," "
je @b
cmp byte[edx],"\"
je @b
cmp byte[edx],"/"
je @b
inc edx
mov dword[edx],002E2Fh  
push edx
mov eax,2
xor ebx,ebx
mov edx,cmdcop_dossier_sortie
int 64h
pop edx
mov byte[edx],0  
cmp eax,cer_dov
jne erreur_sortie2_cmdcop


cmdcop_ok_ouverture_dossier_sortie:
mov [cmdcop_handle_dossier_sortie],ebx

;test si le nom de l'entée contien des *,<,>,|, ou des ?
mov esi,cmdcop_nom_entree
@@:
cmp byte[esi],"*"
je cmdcop_multifichier
cmp byte[esi],"<"
je cmdcop_multifichier
cmp byte[esi],">"
je cmdcop_multifichier
cmp byte[esi],"|"
je cmdcop_multifichier
cmp byte[esi],"?"
je cmdcop_multifichier
cmp byte[esi],0
je cmdcop_monofichier 
inc esi
jmp @b



cmdcop_multifichier:

;change la taille de la zt
mov al,8
mov dx,sel_dat1
mov ecx,cmdcop_zone_dossier+cmdcop_taille_tampon
int 61h
cmp eax,0
jne erreur_memoire_cmdcop


;lit le contenu du dossier
mov eax,16        ;lire partie liste fichier
mov ebx,[cmdcop_handle_dossier_entree]
mov ecx,cmdcop_taille_tampon
mov edx,0
mov edi,cmdcop_zone_dossier
int 64h
cmp eax,0
jne erreur_entree_cmdcop




;filtre le dossier
mov al,160
mov esi,cmdcop_nom_entree
mov edi,cmdcop_zone_dossier
int 61h


mov edx,cmdcop_zone_dossier
cmp byte[edx],0
je fin_multifichier_cmdcop

boucle_multifichier_cmdcop:
mov esi,cmdcop_nom_entree
mov edi,cmdcop_nom_sortie

@@:
mov al,[edx]
cmp al,0
je @f
cmp al,"|"
je @f
mov byte[esi],al
mov byte[edi],al
inc edx
inc esi
inc edi
jmp @b


@@:
mov byte[esi],0
mov byte[edi],0


call copiefichier_cmdcop
cmp byte[edx],0
je fin_multifichier_cmdcop
inc edx
jmp boucle_multifichier_cmdcop


fin_multifichier_cmdcop:
int 60h



cmdcop_monofichier: ;un seul fichier
call copiefichier_cmdcop
int 60h


erreur_memoire_cmdcop:
call message_erreur_cmdcop
int 60h


erreur_param_cmdcop:
mov eax,cer_parami
call message_erreur_cmdcop
int 60h


erreur_entree_cmdcop:
mov ebx,112
call message_erreur2_cmdcop
int 60h


erreur_sortie1_cmdcop:
mov ebx,113
call message_erreur2_cmdcop
int 60h


erreur_sortie2_cmdcop:
mov ebx,117
call message_erreur2_cmdcop
int 60h

;*************************************
copiefichier_cmdcop:
pushad
xor eax,eax         ;ouvre le fichier source
mov ebx,[cmdcop_handle_dossier_entree]
mov edx,cmdcop_nom_entree
cmp byte[edx],0
jne @f
popad
ret
@@:
int 64h
cmp eax,cer_dov
je copiedossier_cmdcop
cmp eax,0
jne erreur_oe_cmdcop
mov [cmdcop_handle_entree],ebx

bt word[cmdcop_options],3
jc ignore_element_cmdcop


mov eax,2         ;crée le fichier de destination
mov ebx,[cmdcop_handle_dossier_sortie]
mov edx,cmdcop_nom_sortie
int 64h
cmp eax,0
je @f
bt word[cmdcop_options],1
jnc erreur_cs_cmdcop 

mov eax,0         ;ouvre le fichier de destination
mov ebx,[cmdcop_handle_dossier_sortie]
mov edx,cmdcop_nom_sortie
int 64h
cmp eax,0
jne erreur_os_cmdcop
@@:
mov [cmdcop_handle_sortie],ebx



;lit la taille du fichier
mov eax,6
mov ah,1
mov ebx,[cmdcop_handle_entree]
mov edx,cmdcop_zone_tampon
int 64h
cmp eax,0
jne erreur_le_cmdcop
mov ecx,[cmdcop_zone_tampon]
mov [cmdcop_taille_entree],ecx


;réserver un espace pour le nouveau fichier
mov eax,15       
mov ebx,[cmdcop_handle_sortie]
mov ecx,[cmdcop_taille_entree]
int 64h
cmp eax,0
jne erreur_es_cmdcop

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
jne erreur_le_cmdcop

mov eax,5         ;ecrit dans le fichier
mov ebx,[cmdcop_handle_sortie]
mov ecx,cmdcop_taille_tampon
mov edx,[cmdcop_offset_transfert]
mov esi,cmdcop_zone_tampon 
int 64h
cmp eax,0
jne erreur_es_cmdcop

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
jne erreur_le_cmdcop

mov eax,5         ;ecrit dans le fichier
mov ebx,[cmdcop_handle_sortie]
mov ecx,[cmdcop_taille_entree]
mov edx,[cmdcop_offset_transfert]
mov esi,cmdcop_zone_tampon 
int 64h
cmp eax,0
jne erreur_es_cmdcop



ok_cmdcop:
;ferme les fichiers
mov eax,1
mov ebx,[cmdcop_handle_entree]
int 64h
mov eax,1
mov ebx,[cmdcop_handle_sortie]
int 64h


mov al,13
mov ah,0
mov cl,98
mov ch,0
mov edx,cmdcop_zone_tampon
int 61h
mov al,6
int 61h


mov al,6
mov edx,cmdcop_dossier_entree
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
mov edx,cmdcop_dossier_sortie
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





copiedossier_cmdcop:
bt word[cmdcop_options],2
jc ignore_element_cmdcop

mov edi,cmdcop_zone_tampon
mov dword[edi],"cop "
add edi,4

mov esi,cmdcop_dossier_entree
@@:
mov al,[esi]
cmp al,0
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:

mov byte[edi],"/"
inc edi

mov esi,cmdcop_nom_entree
@@:
mov al,[esi]
cmp al,0
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:


mov dword[edi],"/*.*"
mov byte[edi+4]," "
add edi,5

mov esi,cmdcop_dossier_sortie
@@:
mov al,[esi]
cmp al,0
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:

mov byte[edi],"/"
inc edi

mov esi,cmdcop_nom_sortie
@@:
mov al,[esi]
cmp al,0
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:

mov dword[edi]," -n"
add edi,3

;ajouter les options
bt word[cmdcop_options],1
jnc @f 
mov dword[edi]," -e"
add edi,3
@@:

bt word[cmdcop_options],2
jnc @f 
mov dword[edi]," -f"
add edi,3
@@:

bt word[cmdcop_options],3
jnc @f 
mov dword[edi]," -d"
add edi,3
@@:



mov al,0    ;envoie la commande au systeme
mov edx,cmdcop_zone_tampon 
int 61h

@@:          ;et attend que celle ci soit executé
int 62h
mov al,19
mov cl,128
mov edx,cmdcop_zone_tampon
mov word[edx],0
int 61h
cmp word[cmdcop_zone_tampon],0
jne @b



ignore_element_cmdcop:
mov eax,1
mov ebx,[cmdcop_handle_entree]
int 64h

popad
ret



erreur_oe_cmdcop:
mov ebx,110
call message_erreur2_cmdcop
popad
ret

erreur_os_cmdcop:
mov ebx,111
call message_erreur2_cmdcop
popad
ret

erreur_cs_cmdcop:
mov ebx,115
call message_erreur2_cmdcop
popad
ret

erreur_le_cmdcop:
mov ebx,118
call message_erreur2_cmdcop
popad
ret

erreur_es_cmdcop:
mov ebx,123
call message_erreur2_cmdcop
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


;mov al,3
;mov edx,cmdcop_zone_tampon
;int 61h
;mov al,6
;int 61h


mov al,6
mov edx,cmdcop_zone_tampon
mov dword[edx],"cop "
mov byte[edx+4],0
int 61h
mov al,6
mov edx,cmdcop_dossier_entree
int 61h
mov al,6
mov edx,cmdcop_nom_entree
int 61h
mov al,6
mov edx,cmdcop_zone_tampon
mov word[edx]," "
int 61h
mov al,6
mov edx,cmdcop_dossier_sortie
int 61h
mov al,6
mov edx,cmdcop_nom_sortie
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


;****************************************
message_erreur2_cmdcop:
push eax
push ebx

mov al,13
mov ah,0
mov cl,3
mov ch,0
mov edx,cmdcop_zone_tampon
int 61h
mov al,6
int 61h

mov al,6
mov edx,cmdcop_zone_tampon
mov dword[edx],"cop "
mov byte[edx+4],0
int 61h
mov al,6
mov edx,cmdcop_dossier_entree
int 61h
mov al,6
mov edx,cmdcop_nom_entree
int 61h
mov al,6
mov edx,cmdcop_zone_tampon
mov word[edx]," "
int 61h
mov al,6
mov edx,cmdcop_dossier_sortie
int 61h
mov al,6
mov edx,cmdcop_nom_sortie
int 61h

mov word[cmdcop_zone_tampon],0D22h  ;" puis CR

pop ecx
mov al,13
mov ah,0
mov ch,0
mov edx,cmdcop_zone_tampon+2
int 61h
mov al,6
mov edx,cmdcop_zone_tampon
int 61h


mov word[cmdcop_zone_tampon],": "  

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