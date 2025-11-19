iff:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "lit les informations d'un fichier"
scode:
org 0
mov ax,sel_dat1
mov ds,ax
mov es,ax


;*********lire le premier argument
mov al,4
mov ah,0
mov cl,0
mov edx,zt
int 61h

;********ouvrir le fichier
mov al,0
xor ebx,ebx
mov edx,zt
int 64h
cmp eax,0
je @f

mov al,6
mov edx,msg_erreur_ouverture
call ajuste_langue
int 61h

mov al,6
mov edx,zt
int 61h
mov word[edx],13
int 61h
int 60h

@@:
mov [handle_fichier],ebx


;*******lire le nom du fichier
mov al,6
mov ah,0
mov ebx,[handle_fichier]
mov edx,zt
int 64h
cmp eax,0
jne @f
mov al,6
mov edx,zt
int 61h
mov word[edx],13
mov al,6
int 61h
@@:




;********lire la taille
mov al,6
mov ah,1
mov ebx,[handle_fichier]
mov edx,zt
int 64h
cmp eax,0
jne @f

mov al,6
mov edx,msg_taille
call ajuste_langue
int 61h

mov al,102
mov ecx,[zt]
mov edx,zt
int 61h
mov al,6
int 61h

mov al,6
mov edx,msg_octet
call ajuste_langue
int 61h
@@:


;********lire les attributs
mov al,6
mov ah,2
mov ebx,[handle_fichier]
mov edx,zt
int 64h
cmp eax,0
jne pas_attributs

mov al,6
mov edx,msg_attribut
call ajuste_langue
int 61h


test byte[zt],1
jz @f
mov al,6
mov edx,msg_dossier
call ajuste_langue
int 61h
@@:

test byte[zt],2
jz @f
mov al,6
mov edx,msg_lecturseule
call ajuste_langue
int 61h
@@:

test byte[zt],4
jz @f
mov al,6
mov edx,msg_cache
call ajuste_langue
int 61h
@@:

test byte[zt],8
jz @f
mov al,6
mov edx,msg_systeme
call ajuste_langue
int 61h
@@:


pas_attributs:

;********lire date de création
mov al,6
mov ah,10
mov ebx,[handle_fichier]
mov edx,zt
int 64h
cmp eax,0
jne @f

mov al,6
mov edx,msg_dcreation
call ajuste_langue
int 61h

call affiche_date
@@:


;********lire date de dernière modification
mov al,6
mov ah,11
mov ebx,[handle_fichier]
mov edx,zt
int 64h
cmp eax,0
jne @f

mov al,6
mov edx,msg_dmodif
call ajuste_langue
int 61h

call affiche_date
@@:


;********lire date de dernier acces
mov al,6
mov ah,12
mov ebx,[handle_fichier]
mov edx,zt
int 64h
cmp eax,0
jne @f

mov al,6
mov edx,msg_dacces
call ajuste_langue
int 61h

call affiche_date
@@:






;************************
affiche_date:

mov al,102
xor ecx,ecx
mov cl,[zt+4]
mov edx,zt+8
int 61h
mov al,6
int 61h

mov al,6
mov edx,msg_slash
int 61h

mov al,102
xor ecx,ecx
mov cl,[zt+5]
mov edx,zt+8
int 61h
mov al,6
int 61h

mov al,6
mov edx,msg_slash
int 61h

mov al,102
xor ecx,ecx
mov cx,[zt+6]
mov edx,zt+8
int 61h
mov al,6
int 61h

cmp dword[zt],0FFFFFFFFh
jne @f
ret
@@:

mov al,6
mov edx,msg_espace
int 61h

mov al,102
xor ecx,ecx
mov cl,[zt+3]
mov edx,zt+8
int 61h
mov al,6
int 61h

mov al,6
mov edx,msg_heure
int 61h

mov al,102
xor ecx,ecx
mov cl,[zt+2]
mov edx,zt+8
int 61h
mov al,6
int 61h

mov al,6
mov edx,msg_min
int 61h

xor eax,eax
mov ecx,1000
mov ax,[zt]
div ecx
mov ecx,eax
mov al,102
mov edx,zt+8
int 61h
mov al,6
int 61h

mov al,6
mov edx,msg_seconde
int 61h
ret

;***************************
ajuste_langue:  ;selectionne le message adapté a la langue employé par le système
push eax
mov eax,20
int 61h
xor ecx,ecx
cmp eax,"eng "
je @f
inc ecx
cmp eax,"fra "
je @f
xor ecx,ecx
@@:

boucle_ajuste_langue:
cmp ecx,0
je ok_ajuste_langue
cmp byte[edx],0
jne @f
dec ecx
@@:
inc edx
jmp boucle_ajuste_langue

ok_ajuste_langue:
pop eax
ret



;***************************************************
sdata1:
org 0


msg_erreur_ouverture:
db "IFF: erreur d'ouverure du fichier ",0

msg_attribut:
db "Attributs: ",0
msg_dossier:
db "dossier,",0
msg_lecturseule:
db "lecture seule,",0
msg_cache:
db "chaché,",0
msg_systeme:
db "système,",0

msg_taille:
db "Taille: ",0
msg_octet:
db " Octets",13

msg_dcreation:
db "Date de création du fichier: ",0

msg_dmodif:
db "Date de dernière modification: ",0

msg_dacces:
db "Date du dernier acces: ",0


msg_espace:
db " ",0
msg_slash:
db "/",0
msg_heure:
db "h",0
msg_min:
db "min",0
msg_seconde:
db "s"
msg_ligne:
db 13,0


handle_fichier:
dd 0

zt:
rb 512



sdata2:
org 0
db 0;données du segment ES
sdata3:
org 0
;données du segment FS
sdata4:
org 0
;données du segment GS
findata:

