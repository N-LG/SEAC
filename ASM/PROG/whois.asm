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



;determine quel serveur doit être consulté
mov edx,serveur
cmp byte[edx],0
jne serveur_ok
mov ebx,zt_nom


boucle_recherche_fin_nom:
cmp byte[ebx],"."
jne @f
mov eax,ebx
@@:
inc ebx
cmp byte[ebx],0
jne boucle_recherche_fin_nom 

inc eax
mov edx,serveur_base


cmp dword[eax],"io"
je serveurio
cmp dword[eax],"eu"
je serveureu
cmp dword[eax],"uk"
je serveuruk
cmp dword[eax],"de"
je serveurde
cmp dword[eax],"be"
je serveurbe
cmp dword[eax],"fr"
je serveurfr
cmp dword[eax],"com"
je serveurcom
cmp dword[eax],"net"
je serveurnet
cmp dword[eax],"org"
je serveurorg

cmp byte[eax+4],0
jne serveur_ok
cmp dword[eax],"wiki"
je serveurwiki
jmp serveur_ok


serveurwiki:
mov edx,serveur_wiki
jmp serveur_ok
serveurcom:
mov edx,serveur_com
jmp serveur_ok
serveurnet:
mov edx,serveur_net
jmp serveur_ok
serveurfr:
mov edx,serveur_fr
jmp serveur_ok
serveurorg:
mov edx,serveur_org
jmp serveur_ok
serveurio:
mov edx,serveur_io
jmp serveur_ok
serveureu:
mov edx,serveur_eu
jmp serveur_ok
serveuruk:
mov edx,serveur_uk
jmp serveur_ok
serveurde:
mov edx,serveur_de
jmp serveur_ok
serveurbe:
mov edx,serveur_be
;jmp serveur_ok

;récupère l'adresse ip du serveur
serveur_ok:
mov [ad_serveur],edx
mov al,109
mov ecx,ip_serveur
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




;envoyer la requete
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


;informer que l'on as envoyé une demande
mov al,6
mov edx,msg_ok1
call ajuste_langue
int 61h
mov al,6
mov edx,[ad_serveur]
int 61h
mov al,6
mov edx,msg_ok2
call ajuste_langue
int 61h
mov al,6
mov edx,zt_nom
int 61h
mov al,6
mov edx,msg_cr
int 61h



;lire la réponse
boucle_lecture_reponse:
mov al,6
mov ebx,[adresse_canal]
mov ecx,1024
mov edi,zt_reponse
add edi,[offset_reponse]
int 65h
cmp eax,0
jne fin
cmp ecx,0
je boucle_lecture_reponse
add [offset_reponse],ecx
mov al,6
mov edx,msg_point
int 61h
jmp boucle_lecture_reponse



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
mov edx,msg_cr
int 61h
mov al,6
mov edx,zt_reponse
int 61h

int 60h





;*******************************************
aff_err_param:
mov al,6
mov edx,msg_ok_er1
call ajuste_langue
int 61h
int 60h

aff_err_com:
mov al,6
mov edx,msg_ok_er2
call ajuste_langue
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





ad_serveur:
dd 0
id_tache:
dw 0
adresse_canal:
dd 0
offset_reponse:
dd 0

serveur_base:
db "whois.iana.org",0
serveur_com:
serveur_net:
db "whois.verisign-grs.com",0
serveur_fr:
db "whois.nic.fr",0
serveur_org:
db "whois.publicinterestregistry.org",0
serveur_wiki:
db "whois.nic.wiki",0
serveur_io:
db "whois.nic.io",0
serveur_eu:
db "whois.eu",0
serveur_uk:
db "whois.nic.uk",0
serveur_de:
db "whois.denic.de",0
serveur_be:
db "whois.dns.be",0



CRLF:
db 13,10


msg_ok_er1:
db "WHOIS: missing parameter",13,0
db "WHOIS: parametre manquant",13,0
msg_ok_er2:

db "WHOIS: Unable to connect to server",13,0
db "WHOIS: impossible de se connecter au serveur",13,0
msg_ok1:
db "WHOIS: querying server ",0
db "WHOIS: interrogation du serveur ",0
msg_ok2:

db " for the domain ",0
db " pour le domaine ",0

msg_point:
db ".",0
msg_cr:
db 13,0

zt_nom:
rb 256
serveur:
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
