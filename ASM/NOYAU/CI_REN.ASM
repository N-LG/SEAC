cmdren_nom_initial equ 0
cmdren_nom_final equ 512
cmdren_zone_tampon equ 1024
cmdren_mem equ 2048





;change la taille de la zt
mov al,8
mov dx,sel_dat1
mov ecx,cmdren_mem
int 61h
cmp eax,0
jne erreur_autres_cmdren

mov ax,sel_dat1
mov ds,ax
mov es,ax

;recupère le nom du fichier
mov al,4
mov ah,0
mov cl,0
mov edx,cmdren_nom_initial
int 61h

;récupère le nouveau nom du fichier
mov al,4
mov ah,1
mov cl,0
mov edx,cmdren_nom_final
int 61h

mov eax,cer_parami
cmp byte[cmdren_nom_final],0
je erreur_autres_cmdren 


xor eax,eax         ;ouvre le fichier
xor ebx,ebx
mov edx,cmdren_nom_initial
int 64h
cmp eax,0       
je suite_cmdren
cmp eax,12       
je suite_cmdren
jmp erreur_autres_cmdren

suite_cmdren:
mov al,7   ;modifie les données du nom de fichier
mov ah,0
mov edx,cmdren_nom_final
int 64h
cmp eax,0       
jne erreur_autres_cmdren

finok_cmdren:
mov al,13
mov ah,0
mov cl,98
mov ch,0
mov edx,cmdren_zone_tampon
int 61h
mov al,6
int 61h

mov al,6
mov edx,cmdren_nom_initial
int 61h

mov al,13
mov ah,0
mov cl,97
mov ch,0
mov edx,cmdren_zone_tampon
int 61h
mov al,6
int 61h

mov al,6
mov edx,cmdren_nom_final
int 61h

mov word[cmdren_zone_tampon],13
mov al,6
mov edx,cmdren_zone_tampon
int 61h

int 60h



erreur_autres_cmdren:
push eax

mov al,13
mov ah,0
mov cl,3
mov ch,0
mov edx,cmdren_zone_tampon
int 61h
mov al,6
int 61h


mov al,3
mov edx,cmdren_zone_tampon
int 61h
mov al,6
int 61h

mov word[cmdren_zone_tampon],0D22h  ;" puis CR

pop ecx
mov al,13
mov ah,1
mov ch,0
mov edx,cmdren_zone_tampon+2
int 61h
mov al,6
mov edx,cmdren_zone_tampon
int 61h

mov word[cmdren_zone_tampon],0017h  ;fin de couleur
mov al,6
mov edx,cmdren_zone_tampon
int 61h

int 60h