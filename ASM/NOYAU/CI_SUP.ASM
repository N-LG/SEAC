cmdsup_nom equ 0
cmdsup_zone_tampon equ 1024
cmdsup_mem equ 2048









;change la taille de la zt
mov al,8
mov dx,sel_dat1
mov ecx,cmdsup
int 61h
cmp eax,0
jne erreur_autres_cmdsup

mov ax,sel_dat1
mov ds,ax
mov es,ax

;recupère le nom du fichier a supprimer
mov al,4
mov ah,0
mov cl,0
mov edx,cmdsup_nom
int 61h


xor eax,eax         ;ouvre le fichier
xor ebx,ebx
mov edx,cmdsup_nom
int 64h
cmp eax,0
jne erreur_autres_cmdsup


mov eax,3    ;supprime le fichier
int 64h
cmp eax,0       
jne erreur_autres_cmdsup




mov al,13
mov ah,0
mov cl,98
mov ch,0
mov edx,cmdsup_zone_tampon
int 61h
mov al,6
int 61h

mov al,6
mov edx,cmdsup_nom
int 61h

mov al,13
mov ah,0
mov cl,96
mov ch,0
mov edx,cmdsup_zone_tampon
int 61h
mov al,6
int 61h

int 60h



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

int 60h