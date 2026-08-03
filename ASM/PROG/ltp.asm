cdg:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "liste les taches en cours d'execution"
scode:
org 0

;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax

;recupère le listing des taches
mov al,21
mov cx,2048
mov edx,liste_tache
mov ebx,commande_vide
int 61h

mov esi,liste_tache
boucle:
cmp word[esi],0
jne @f
int 60h
@@:

;id de la tache
mov al,104
mov cx,[esi]
mov edx,zt_conv
int 61h
mov al,6
mov edx,zt_conv
int 61h
mov al,6
mov edx,espace
int 61h

;description de la tache
mov al,24
mov bx,[esi]
mov ecx,512
mov edx,zt_info
int 61h
mov al,6
mov edx,zt_info
int 61h
mov al,6
mov edx,crlf
int 61h

;commande de la tache
mov al,23
mov bx,[esi]
mov ecx,512
mov edx,zt_info
int 61h
mov al,6
mov edx,zt_info
int 61h

;info de la tache
mov al,25
mov bx,[esi]
mov edx,zt_info
int 61h

;adresse
mov al,6
mov edx,msg_adresse
call ajuste_langue
int 61h
mov ecx,[zt_info]
mov al,103
mov edx,zt_conv
int 61h
mov al,6
mov edx,zt_conv
int 61h


;tailles
mov al,6
mov edx,msg_taille
call ajuste_langue
int 61h
mov ecx,[zt_info+4]
call affiche_taille_octet

;code
mov al,6
mov edx,msg_tcode
call ajuste_langue
int 61h
mov ecx,[zt_info+8]
call affiche_taille_octet

;données
mov al,6
mov edx,msg_tdata
call ajuste_langue
int 61h
mov ecx,[zt_info+12]
call affiche_taille_octet

;pile
mov al,6
mov edx,msg_tpile
call ajuste_langue
int 61h
mov ecx,[zt_info+16]
call affiche_taille_octet

;service
mov al,6
mov edx,msg_service
call ajuste_langue
int 61h
xor ecx,ecx
mov al,102 
mov cl,[zt_info+20]
mov edx,zt_conv
int 61h
mov al,6
mov edx,zt_conv
int 61h

;cycle
mov al,6
mov edx,msg_cycle
call ajuste_langue
int 61h
xor ecx,ecx
mov al,102
mov cl,[zt_info+21]
mov edx,zt_conv
int 61h
mov al,6
mov edx,zt_conv
int 61h

;tache parente
mov al,6
mov edx,msg_tachep
call ajuste_langue
int 61h
mov al,104
mov cx,[zt_info+22]
mov edx,zt_conv
int 61h
mov al,6
mov edx,zt_conv
int 61h

mov al,6
mov edx,crlf_double
int 61h

add esi,2
jmp boucle


;************************************
affiche_taille_octet:
mov al,102
mov edx,zt_conv
int 61h
mov al,6
mov edx,zt_conv
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



sdata1:
org 0

msg_adresse:
db 10,13,"Adresse: ",0
db 10,13,"Adresse: ",0
msg_taille:
db 10,13,"taille en mémoire: ",0
db 10,13,"taille en mémoire: ",0
msg_tcode:
db 10,13,"      code: ",0
db 10,13,"      code: ",0
msg_tdata:
db 10,13,"   données: ",0
db 10,13,"   données: ",0
msg_tpile:
db 10,13,"     piles: ",0
db 10,13,"     piles: ",0
msg_service:
db 10,13,"type de service: ",0
db 10,13,"type de service: ",0
msg_cycle:
db 10,13,"cycle alloué: ",0
db 10,13,"cycle alloué: ",0
msg_tachep:
db 10,13,"tâche parente: ",0
db 10,13,"tâche parente: ",0

commande_vide:
db 0

crlf_double:
db 10,13
crlf:
db 10,13,0
espace:
db " ",0

liste_tache:
rb 4096
zt_conv:
rb 64
zt_info:
rb 512



sdata2:
org 0
;données du segment ES
sdata3:
org 0
;données du segment FS
sdata4:
org 0
;données du segment GS
findata:
