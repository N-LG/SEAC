bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Client whois"
scode:
org 0





;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax


;agrandit la zone mémoire
mov al,8
mov ecx,zt_reponse+40000h
mov dx,sel_dat1
int 61h



;**************************************************************
;lit l'adresse de la ressource souhaité
mov byte[zt_nom],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_nom
int 61h

cmp byte[zt_nom],0
je aff_err_param









;*****************************************************
;test si il faut interroger un serveur directement
mov al,5   
mov ah,"s"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256   
mov edx,serveur
int 61h




;********************************************************
;génère un numéros de port local pseudo aléatoirement
mov eax,9
int 61h
xor ax,bx
xor ax,cx
xor ax,dx
xor ax,05A8Dh
mov [port_local],ax




;**************************************************************
;determine l'id du service ethernet
mov byte[zt_reponse],0

mov al,5   
mov ah,"c"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_reponse
int 61h
xor ebx,ebx
cmp eax,0
jne @f

mov al,100  
mov edx,zt_reponse
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

@@:
mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,zt_reponse
int 61h

shl ebx,1
mov ax,[zt_reponse+ebx]
mov [id_tache],ax



;récupère l'adresse ip du serveur
mov al,109
mov ecx,ip_serveur
mov edx,serveur
int 61h
cmp eax,0
jne aff_err_com



;***********************************************************
;etablire une connexion
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,2000
mov edi,2000
int 65h
cmp eax,0
jne aff_err_com

mov [adresse_canal],ebx


mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,commande_ethernet
mov edi,0
int 65h
cmp eax,0
jne aff_err_com


;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne aff_err_com

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,0
mov edi,zt_reponse
int 65h
cmp eax,0
jne aff_err_com

cmp byte[zt_reponse],88h
jne aff_err_com


;determiner le premier domaine a chercher




;envoyer la requete:

envoyer_requete:
mov esi,zt_nom
mov ecx,zt_nom
@@:
mov al,[ecx]
inc ecx
cmp al,0
jne @b
dec ecx
sub ecx,esi
mov al,7
mov ebx,[adresse_canal]
int 65h
cmp eax,0
jne aff_err_com

mov esi,CRLF
mov ecx,2
mov al,7
mov ebx,[adresse_canal]
int 65h
cmp eax,0
jne aff_err_com





temp:
mov al,6
mov ebx,[adresse_canal]
mov ecx,1024
mov edi,zt_reponse
add edi,[offset_reponse]
int 65h
cmp eax,0
jne fin
cmp ecx,0
je temp
add [offset_reponse],ecx
jmp temp



fin:
mov ecx,[offset_reponse]
mov esi,zt_reponse
mov byte[ecx+zt_reponse],0

boucle_temp:
cmp word[esi],0D0Ah
jne @f
mov word[esi],0D20h
@@:
cmp word[esi],0A0Dh
jne @f
mov word[esi],0D20h
@@:
cmp byte[esi],0Ah
jne @f
mov byte[esi],0Dh
@@:
inc esi
dec ecx
jne boucle_temp

mov al,6
mov edx,zt_reponse
int 61h

int 60h



;attendre connexion fermé ou débordement espace reponse



;est ce que la requete as été traité completement?



;si oui afficher et quitter
reponse_complete:




;si non determiner serveur whois suivant
whois_suivant:


jmp envoyer_requete



;si reception partielle ou impossibilité de determier serveur whois suivant, afficher dernière réponse reçu
reponse_partielle:



int 60h





;*******************************************
aff_err_param:
mov al,6
mov edx,msg_ok_er1
int 61h
int 60h

aff_err_com:
mov al,6
mov edx,msg_ok_er2
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



commande_ethernet:
db 8,1
port_local:
dw 0
cmd_max:
dw 0
cmd_fifo:
dw 20000,20000 
port_serveur:
dw 43
ip_serveur:
dd 0
cmd_ip6:







id_tache:
dw 0
adresse_canal:
dd 0
offset_reponse:
dd 0

serveur:
;db "ianawhois.vip.icann.org",0
db "whois.iana.org",0
rb 256

CRLF:
db 13,10


msg_ok_er1:
db "WHOIS: parametre manquant",13,0
msg_ok_er2:
db "WHOIS: impossible de se connecter au serveur",13,0



zt_nom:
rb 256
zt_reponse:



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
