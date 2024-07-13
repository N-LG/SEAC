cdg:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "chien de garde"
scode:
org 0

;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax

mov al,8
mov ecx,zt
add ecx,20000h
mov dx,sel_dat1
int 61h


;enregistre les taches en cours d'execution
mov al,11
mov ah,0
mov edx,tache
mov cl,128
int 61h

;signal le démarrage
mov al,6
mov edx,message_on
call ajuste_langue
int 61h

;****************************************
boucle:

;attend 30secondes
mov al,1
mov ecx,400*30
int 61h


;lit les taches en cours d'execution
mov al,11
mov ah,0
mov edx,zt
mov cl,128
int 61h


;cherche si il en manque
mov esi,tache
mov edi,zt
@@:
mov ax,[esi]
cmp ax,0
je boucle
cmp ax,[edi]
jne detection
add esi,2
add edi,2
jmp @b



;************************************
detection:

;signale qu'un défaut as été detecté
mov al,6
mov edx,message_off
call ajuste_langue
int 61h

;attend 3 secondes
mov al,1
mov ecx,400*3
int 61h


;récupère le dossier des fichier log
mov al,4
mov ah,0
mov edx,zt
xor ecx,ecx
int 61h


;créer le nom du fichier de log
xor ecx,ecx
mov al,9
int 61h

xor eax,eax
mov al,bl
push eax
mov al,bh
push eax
mov al,dl
push eax
mov al,dh
push eax
mov ax,cx
push eax

mov edx,zt
@@:
cmp byte[edx],0
je @f
inc edx
jmp @b
@@:
mov byte[edx],"/"
inc edx
mov al,102
pop ecx
int 61h

mov edx,zt
@@:
cmp byte[edx],0
je @f
inc edx
jmp @b
@@:
mov byte[edx],"-"
inc edx
mov al,102
pop ecx
int 61h

mov edx,zt
@@:
cmp byte[edx],0
je @f
inc edx
jmp @b
@@:
mov byte[edx],"-"
inc edx
mov al,102
pop ecx
int 61h

mov edx,zt
@@:
cmp byte[edx],0
je @f
inc edx
jmp @b
@@:
mov byte[edx],"."
inc edx
mov al,102
pop ecx
int 61h

mov edx,zt
@@:
cmp byte[edx],0
je @f
inc edx
jmp @b
@@:
mov byte[edx],"h"
inc edx
mov al,102
pop ecx
int 61h

mov edx,zt
@@:
cmp byte[edx],0
je @f
inc edx
jmp @b
@@:
mov dword[edx],".log"
mov byte[edx+4],0


;creer le fichier
mov al,2
xor ebx,ebx
mov edx,zt
int 64h
cmp eax,0
jne ignore_enregistrement


;lit le journal
mov al,14
mov edx,zt
mov ecx,20000h
int 61h


;et l'enregistre dans le fichier de log
mov esi,zt
mov ecx,zt
@@:
cmp byte[ecx],0
je @f
inc ecx
jmp @b
@@:
sub ecx,esi
mov al,5
xor edx,edx
int 64h

ignore_enregistrement:


;demande le reboot
xor eax,eax
mov edx,commande
int 61h

int 60h


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


message_on:
db "CDG: watchdog start",13,0
db "CDG: démarrage du chien de garde",13,0

message_off:
db "CDG: detection of a failure, restart...",13,0
db "CDG: detection d'une défaillance, redémarrage...",13,0


commande:
db "pwr -r",0

taillejournal:
dd 100000h

tache:
rb 258

zt:




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
