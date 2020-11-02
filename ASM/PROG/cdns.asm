bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Client DNS"
scode:
org 0

;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax



;lit le nom du destinataire a rechercher
mov al,4   
mov ah,1   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,recherche
int 61h


;génère un numéros de port local pseudo aléatoirement
mov eax,9
int 61h
xor ax,bx
xor ax,cx
xor ax,dx
xor ax,0CA71h
mov [local_port],ax

xor ax,0803Ch
mov [requete_dns],ax   ;et un numéros de requete


;**************************************************************
;determine l'id du service ethernet
mov byte[data_dns],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,data_dns
int 61h

cmp byte[data_dns],0
je erreur_ouv_port

mov al,100  
mov edx,data_dns
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,data_dns
int 61h

shl ebx,1
mov ax,[data_dns+ebx]
cmp ax,0
je erreur_ouv_port
mov [id_tache],ax



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

;configure en écoute pour un port UDP 
mov ax,[local_port]
mov byte[data_dns],7
mov [data_dns+2],ax

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,data_dns
mov edi,0
int 65h
cmp eax,0
jne erreur_ouv_port

;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne erreur_ouv_port

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,0
mov edi,data_dns
int 65h
cmp eax,0
jne erreur_ouv_port

cmp byte[data_dns],87h
jne erreur_ouv_port


;créer une requete DNS
mov dword[index_serveur],serveurs_dns
boucle_test_different_serveur:

mov word[port_out],53
mov ebx,[index_serveur]
mov eax,[ebx]
mov [ipv4_out],eax


;mov word[requete_dns],????
mov byte[qropcode],1  
mov byte[razrcode],0
mov word[qdcount],100h   ;1 ordre inversé
mov word[ancount],0
mov word[nscount],0
mov word[arcount],0

mov esi,recherche
mov edi,data_dns+1
mov ecx,64
rep movsd

;transforme le nom en chaine valide pour le serveur
mov esi,data_dns
mov edi,data_dns+1

boucle_conversion_nom:
cmp byte[edi],0
je fin_conversion_nom
cmp byte[edi],"."
jne point_conversion_nom
mov eax,edi
sub eax,esi
mov [esi],al
mov esi,edi

point_conversion_nom:
inc edi
jmp boucle_conversion_nom 


fin_conversion_nom:
mov eax,edi
sub eax,esi
mov [esi],al
mov byte[edi],0
inc edi

mov byte[edi],0       ;type
mov byte[edi+1],1     ;classe
mov word[edi+2],100h  ;ttl (ordre inversé)
mov byte[edi+4],0     ;longeur

 
 

;envoie la requete dns




;attend serveur réponse





;si temps écoulé renvoie la demande a un autre serveur

add dword[index_serveur],4
cmp dword[index_serveur],fin_serveurs_dns
jne boucle_test_different_serveur

;si tout serveur passé fin
mov edx,msg_err2
mov al,6        
int 61h
int 60h



erreur_ouv_port:
mov edx,msg_err1
mov al,6        
int 61h
int 60h



;lecture et affichage info réponse



int 60h





sdata1:
org 0
id_tache:
dw 0
adresse_canal:
dd 0
index_serveur:
dd 0
local_port:
dw 0


msg_err1:
db "CDNS: erreur lors de l'ouverture du port UDP",13,0
msg_err2:
db "CDNS: pas de réponse des serveurs DNS",13,0

msg_rep1:
db "CDNS: Réponse du serveur DNS "
msg_rep2:
db ":",13,0







serveurs_dns:
;verisign
db 64,6,64,6
db 64,6,65,6
;fdn
db 80,67,169,12
db 80,67,169,40
;google
db 8,8,8,8
db 8,8,4,4
fin_serveurs_dns:








;**********************trame udp
port_out:
dw 0
ipv4_out:
dd 0 
ipv6_out:
dd 0,0,0,0 

requete_dns:
dw 0
qropcode:
db 0
razrcode:
db 0
qdcount:
dw 0
ancount:
dw 0
nscount:
dw 0
arcount:
dw 0
data_dns:
rb 500

recherche:
rb 255
db 0











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
