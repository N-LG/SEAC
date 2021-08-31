﻿scanip:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "scanner par ping ICMP"
scode:
org 0

;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax


;génère un numéros de port local pseudo aléatoirement
mov eax,9
int 61h
xor ax,bx
xor ax,cx
xor ax,dx
xor ax,07CB3h
mov [sequence],ax



;**************************************************************
;determine l'id du service ethernet
mov byte[zt_recep],0

mov al,5   
mov ah,"c"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h
xor ebx,ebx
cmp eax,0
je @f

mov al,100  
mov edx,zt_recep
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

@@:
mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,zt_recep
int 61h

shl ebx,1
mov ax,[zt_recep+ebx]
cmp ax,0
je err_param
mov [id_tache],ax



;**************************************************************
;determine ip cible debut
mov byte[zt_recep],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h

cmp byte[zt_recep],0
je err_param


mov al,109  
mov edx,zt_recep
mov ecx,adresse_cible_debut
int 61h

cmp dword[adresse_cible_debut],0
je err_param



;**************************************************************
;determine ip cible fin
mov byte[zt_recep],0

mov al,4   
mov ah,1   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h

cmp byte[zt_recep],0
je err_param


mov al,109  
mov edx,zt_recep
mov ecx,adresse_cible_fin
int 61h

cmp dword[adresse_cible_fin],0
je err_param



;**************************************************************
;determine nombre de ping
mov byte[zt_recep],0

mov al,5   
mov ah,"t"   ;lettre de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h
cmp eax,0
jne ignore_param2

mov al,100  
mov edx,zt_recep
int 61h

cmp ecx,0
je err_param
test ecx,0FFFFFF00h
jnz err_param

mov [nb_ping],cl

ignore_param2:

;***********************************************************
;etablire une connexion
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,2000
mov edi,2000
int 65h
mov [adresse_canal],ebx

;configure 69
mov byte[zt_recep],9

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,zt_recep
mov edi,0
int 65h
cmp eax,0
jne err_cnx


;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne err_cnx

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,0
mov edi,zt_recep
int 65h
cmp eax,0
jne err_cnx

cmp byte[zt_recep],89h
jne err_cnx


;signal le début du test
mov al,6
mov edx,msg0a
int 61h

mov al,112
mov ecx,adresse_cible_debut
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6
mov edx,msg0b
int 61h

mov al,112
mov ecx,adresse_cible_fin
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6
mov edx,msg0c
int 61h




mov eax,[adresse_cible_debut]
mov [adresse_actuelle],eax









;**************************************************************
;envoie un ping a l'adresse
boucle_principale:

;prépare commande
mov word[zt_recep],128        ;ttl
mov eax,[adresse_actuelle]
mov [zt_recep+2],eax           ;adresse ipv4
mov dword[zt_recep+6],0        ;adresse ipv6
mov dword[zt_recep+10],0
mov dword[zt_recep+14],0
mov dword[zt_recep+18],0
mov byte[zt_recep+22],8        ;type 
mov byte[zt_recep+23],0        ;code
mov word[zt_recep+24],0        ;cheksum
mov ax,[sequence]
mov word[zt_recep+26],ax       ;identifiant
inc ax
mov word[zt_recep+28],ax       ;numeros de séquence
mov dword[zt_recep+30],"SALU"  ;data bidon (un ptit message a la noix)
mov dword[zt_recep+34],"T DU"
mov dword[zt_recep+38]," SYS"
mov dword[zt_recep+42],"TEME"
mov dword[zt_recep+46]," D'E"
mov dword[zt_recep+50],"XPLO"
mov dword[zt_recep+54],"ITAT"
mov dword[zt_recep+58],"ION "
mov dword[zt_recep+62],"SEaC"

;envoie le message
mov al,7
mov ebx,[adresse_canal]
mov ecx,66
mov esi,zt_recep
int 65h



;attend la réponse
mov ecx,25
mov al,9
mov ebx,[adresse_canal]
int 65h
cmp eax,cer_ddi
jne suite_boucle


;lit la réponse
mov al,6
mov ebx,[adresse_canal]
mov ecx,512
mov edi,zt_recep
int 65h


;vérifie validité du résultat
cmp word[zt_recep+22],0
jne suite_boucle


;affiche le résultat
mov al,6
mov edx,msg1a
int 61h

mov al,112
mov ecx,zt_recep+2
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6
mov edx,msg1b
int 61h






suite_boucle:
mov al,[nb_ping]
inc byte[ping_effectue]
inc word[sequence]
cmp byte[ping_effectue],al
jne boucle_principale
mov eax,[adresse_actuelle]
cmp eax,[adresse_cible_fin]
je suite_operation 
mov eax,[adresse_actuelle]
bswap eax
inc eax
bswap eax
mov [adresse_actuelle],eax
mov byte[ping_effectue],0
jmp boucle_principale


suite_operation:
mov eax,12          
int 61h
add eax,800
mov [cptsf],eax


boucle_secondaire:



;affiche la synthèse
mov al,6
mov edx,msg2a
int 61h

int 60h



;**************************************************************
err_param:
mov al,6
mov edx,msg_err1
int 61h
int 60h


err_cnx:
mov al,6
mov edx,msg_err2
int 61h
int 60h

sdata1:
org 0
id_tache:
dw 0
adresse_canal:
dd 0
adresse_cible_debut:
dd 0
adresse_cible_fin:
dd 0
adresse_actuelle:
dd 0

sequence:
dw 0
cptsf:
dd 0

nb_ping:
db 1
ping_effectue:
db 0


msg0a:
db 13,"SCANIP: début du balayage de l'adresse ",0
msg0b:
db " à l'adresse ",0
msg0c:
db 13,0

msg1a:
db "Réponse de l'adresse ",0
msg1b:
db 13,0

msg2a:
db "SCANIP: fin du balayage",13,0




msg_err1:
db "SCANIP: erreur de parametres, syntaxe correcte: scanip [nom] [-c:X] [-s:X] [-t:X] ",13
db "[adresse debut]  adresse du début de la plage d'adresse a tester",13
db "[adresse fin]  adresse de la fin de la plage d'adresse a tester",13 
db "[-c:X] numéros de l'interface réseau (champ optionnel, 0 par défaut)",13
db "[-t:X] nombre de tentative par étape (champ optionnel, 4 par défaut)",13,0  



msg_err2:
db "SCANIP: erreur lors de la communication avec l'interface réseau",13,0

tempo:
dd 0,0,0,0,0,0,0,0,0,0,0,0

zt_recep:
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
