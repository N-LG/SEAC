cmdex_nom_script equ 0
cmdex_taches_attente equ 512
cmdex_handle_script equ 1024
cmdex_taille_script equ 1028
cmdex_option_exec equ 1036
cmdex_zone_tampon equ 1040

;change la taille de la zone m�moire
mov al,8
mov dx,sel_dat1
mov ecx,cmdex_zone_tampon+1024
int 61h
cmp eax,0
jne erreur_autres_cmdex

mov ax,sel_dat1
mov ds,ax
mov es,ax

;recup�re le nom du fichier de script
mov al,4
mov ah,0
mov cl,0
mov edx,cmdex_nom_script
int 61h

xor eax,eax         ;ouvre le fichier de script
xor ebx,ebx
mov edx,cmdex_nom_script
int 64h
cmp eax,0
jne erreur_autres_cmdex
mov [cmdex_handle_script],ebx


mov al,5       ;test si la commande vrac est activ�
mov ah,"v"
mov cl,0 ;0=256 octet max
mov edx,cmdex_zone_tampon
int 61h
cmp eax,0
jne @f
or byte[cmdex_option_exec],1
@@:


;lit la taille du fichier
mov al,6
mov ah,1
mov ebx,[cmdex_handle_script]
mov edx,cmdex_taille_script
int 64h
cmp eax,0
jne fin_commande_erreur

;change la taille de la zone m�moire si besoin
mov ecx,[cmdex_taille_script]
cmp ecx,1024
jb ignore_agr_mem_cmdex
mov al,8
mov dx,sel_dat1
add ecx,cmdex_zone_tampon+16
int 61h
cmp eax,0
jne erreur_autres_cmdex
ignore_agr_mem_cmdex:

;lit le fichier
mov al,4
mov ebx,[cmdex_handle_script]
mov ecx,[cmdex_taille_script]
mov edx,0
mov edi,cmdex_zone_tampon
int 64h
cmp eax,0
jne fin_commande_erreur

;convertit toute les caract�re <20h en caract�re NULL
mov edi,cmdex_zone_tampon
mov esi,[cmdex_taille_script]
add esi,edi

boucle2_cmpex:
cmp byte[edi],20h
jae cmdex_flnd
mov byte[edi],0
cmdex_flnd:
inc edi
cmp edi,esi
jne boucle2_cmpex

;envoie les commandes
mov edi,cmdex_zone_tampon
mov esi,[cmdex_taille_script]
add esi,edi

cmp word[edi],"#!"
je script_externe
script_interne:

call execute_ligne_script

boucle3_cmdex:
cmp byte[edi],0
jne passe_cmdex
cmp byte[edi+1],0
je passe_cmdex
inc edi

call execute_ligne_script

passe_cmdex:
inc edi
cmp edi,esi
jne boucle3_cmdex

int 60h



;****************************************
script_externe:
cmp byte[edi+4],0    ;v�rifie que ce n'est pas un script basique
jne script_externe_ok 
cmp word[edi+2],"ex"
je script_interne
script_externe_ok:

;trouve la fin du nom de l'executable
add edi,2
boucle1_script_externe:
cmp byte[edi],0
je suite_script_externe
inc edi
jmp boucle1_script_externe
suite_script_externe:

;recopie la commande originale
mov al,3
mov edx,edi
int 61h

;remplace le "ex" de la commande originale
mov esi,edi
inc edi
dec esi
boucle2_script_externe:
std
movsb
cmp esi,cmdex_zone_tampon+1
jne boucle2_script_externe

;envoie la commande
mov edx,edi
inc edx
mov al,0
int 61h

int 60h



;******************************************
execute_ligne_script:
cmp byte[edi],"#"
je ignore_ligne_script
cmp byte[edi],"!"
je ignore_ligne_script
cmp byte[edi],"*"
je attente_ligne_script

mov edx,edi ;envoie la commande au systeme
mov al,0
int 61h


test byte[cmdex_option_exec],01h
jnz ignore_ligne_script

@@:
int 62h
mov al,19
mov cl,128
mov edx,cmdex_taches_attente
mov word[edx],0
int 61h
cmp word[cmdex_taches_attente],0
je ignore_ligne_script
jmp @b


ignore_ligne_script:
ret

attente_ligne_script:   ;interpr�te la commande sp�cifique
mov eax,1
mov ecx,400
int 61h
ret





;****************************************************
erreur_autres_cmdex:
push eax

mov al,13
mov ah,0
mov cl,3
mov ch,0
mov edx,cmdex_zone_tampon
int 61h
mov al,6
int 61h

mov al,3
mov edx,cmdex_zone_tampon
int 61h
mov al,6
int 61h

mov word[cmdex_zone_tampon],0D22h  ;" puis CR

pop ecx
mov al,13
mov ah,1
mov ch,0
mov edx,cmdex_zone_tampon+2
int 61h
mov al,6
mov edx,cmdex_zone_tampon
int 61h

mov word[cmdex_zone_tampon],0017h  ;fin de couleur
mov al,6
mov edx,cmdex_zone_tampon
int 61h


int 60h



















