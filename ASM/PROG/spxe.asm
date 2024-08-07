﻿bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Serveur bootp, dhcp, & pxe"



scode:
org 0

;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax




;****************************************************
;récupère le nombre de machine que l'on peut adresser (par défaut 16)
mov al,5   
mov ah,"n"  ;lettre de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,tempo
int 61h
mov ecx,16
cmp eax,0
jne @f
cmp byte[tempo],0
je @f

mov al,100
mov edx,tempo
int 61h
@@:
mov [to_bdd],ecx

;agrandissement de la zone mémoire
shl ecx,4
add ecx,ad_bdd
mov dx,sel_dat1
mov al,8
int 61h







;*************************************************************
;determine l'id du service ethernet et ouvre un canal (par défaut le premier)
mov dword[tempo],0
mov al,5   
mov ah,"c"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,tempo
int 61h
xor ebx,ebx
cmp eax,0
jne @f

mov al,100  
mov edx,tempo
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface
@@:


mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,tempo
int 61h

shl ebx,1
mov ax,[tempo+ebx]
cmp ax,0
je erreur_param


;ouvre le canal
mov bx,ax
mov al,0
mov ecx,64
mov edx,1
mov esi,2000
mov edi,2000
int 65h
mov [adresse_canal],ebx




;**************************************************
;récupère l'adresse ip, mac, passerelle, et masque

;envoie la commande de lecture info carte
mov word[zt_info],02h
mov al,5
mov ebx,[adresse_canal]
mov ecx,2h
mov edi,0
mov esi,zt_info
int 65h
cmp eax,0
jne erreur_ouv_port

;regarde si on as une réponse (une modification du descripteur)
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne erreur_ouv_port

mov al,4
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,0
mov edi,zt_info
int 65h
cmp byte[zt_info],82h
jne erreur_ouv_port




;*********************************************
;remplit les adresse disponible dans la base
mov eax,[ip_serveur]
mov ebx, ad_bdd
mov ecx,[to_bdd]
bswap eax
@@:
inc eax
mov edx,eax
bswap edx
mov [ebx],edx
add ebx,16
dec ecx
jnz @b





;***********************************************************
;ouvre le port udp 67
mov byte[tempo],7
mov word[tempo+2],67

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,tempo
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
mov edi,tempo
int 65h
cmp eax,0
jne erreur_ouv_port

cmp byte[tempo],87h
jne erreur_ouv_port


;****************************************************
;récupère le nom du fichier de base pour le boot pxe
mov al,5   
mov ah,"b"   ;lettre de l'option de commande a lire
mov cl,32 
mov edx,boot
int 61h



mov edx,msg_ok
call ajuste_langue
mov al,6        
int 61h



;*********************************************************************************************************************
boucle_principale:



;***************************************
;test si il y as des données en attente
mov al,9
mov ebx,[adresse_canal]
mov ecx,400
int 65h
cmp eax,cer_ddi
je @f

;si pas de donnée on attend
int 62h
jmp boucle_principale
@@:


;****************************************
;lit la trame reçu
mov al,6
mov ebx,[adresse_canal]
mov ecx,ad_bdd-port_out
mov edi,port_out
int 65h
cmp eax,0
jne boucle_principale;????????????????????????




cmp byte[zt_bootp],01  ;bootrequest
jne boucle_principale
cmp byte[htype],01 ;type de réseau
jne boucle_principale
cmp byte[hlen],06  ;adresse materielle
jne boucle_principale


mov al,6
mov edx,msg_rec1
call ajuste_langue
int 61h

xor ecx,ecx
mov al,105
mov cl,[chaddr]
mov edx,tempo
int 61h

mov byte[tempo+2],"-"

xor ecx,ecx
mov al,105
mov cl,[chaddr+1]
mov edx,tempo+3
int 61h

mov byte[tempo+5],"-"

xor ecx,ecx
mov al,105
mov cl,[chaddr+3]
mov edx,tempo+6
int 61h

mov byte[tempo+8],"-"

xor ecx,ecx
mov al,105
mov cl,[chaddr+3]
mov edx,tempo+9
int 61h

mov byte[tempo+11],"-"

xor ecx,ecx
mov al,105
mov cl,[chaddr+4]
mov edx,tempo+12
int 61h

mov byte[tempo+14],"-"

xor ecx,ecx
mov al,105
mov cl,[chaddr+5]
mov edx,tempo+15
int 61h

mov al,6
mov edx,tempo
int 61h





mov ebx,ad_bdd
mov ecx,[to_bdd]
mov eax,[chaddr]
mov dx,[chaddr+4]
boucle_recherche_correspondance:
cmp eax,[ebx+4]
jne @f
cmp dx,[ebx+8]
jne @f
mov eax,[ciaddr]
cmp eax,0
je correspondance_ok
cmp eax,[ebx]
je correspondance_ok 
jmp ciaddr_incorrect

@@:
add ebx,16
dec ecx
jnz boucle_recherche_correspondance

;sinon recherche une adresse libre
mov ebx,ad_bdd
mov ecx,[to_bdd]
mov eax,[chaddr]
mov dx,[chaddr+4]
boucle_recherche_vide:
cmp dword[ebx+4],0
jne @f
cmp word[ebx+8],0
jne @f 
mov [ebx+4],eax
mov [ebx+8],dx
jmp correspondance_ok

@@:
add ebx,16
dec ecx
jnz boucle_recherche_vide

mov al,6
mov edx,msg_rec3
call ajuste_langue
int 61h
jmp boucle_principale



ciaddr_incorrect:
mov edx,msg_rec4
call ajuste_langue
int 61h
jmp boucle_principale





correspondance_ok:
mov al,6
mov edx,msg_rec2
call ajuste_langue
int 61h

mov al,112
mov ecx,ebx
mov edx,tempo
int 61h
mov al,6
mov edx,tempo
int 61h

mov al,6
mov edx,tempo
mov word[edx],13
int 61h




mov byte[zt_bootp],02  ;bootreply

mov eax,[ip_serveur]
mov [siaddr],eax

mov eax,[ebx]
mov [yiaddr],eax

mov esi,boot
mov edi,fichier_boot
mov ecx,22
rep movsb


;cherche de quel type de demande il s'agit pour renvoyer la bonne réponse


mov dl,2  ;par défaut on envoit un dhcp_offert
cmp dword[vend],063538263h  ;test si c'est un mot magique dhcp
jne fin_select_type_dhcp 
mov ebx,vend+4
boucle_select_type_dhcp:
cmp byte[ebx],0FFh
je fin_select_type_dhcp
cmp byte[ebx],35h
jne @f

;1=dhcp=discover
;2=dhcp_offert
;3=dhcp_request
;5=dhcp_ack

cmp al,1
je fin_select_type_dhcp
cmp byte[ebx+2],3
je type_dhcp_request


@@:
xor eax,eax
mov al,[ebx+1]
add ebx,eax
add ebx,2
jmp boucle_select_type_dhcp

type_dhcp_request:
;test si c'est bien l'adresse qu'on lui as attribué




mov dl,5 ;on répond par un ack

fin_select_type_dhcp:



mov ebx,vend           ;vide le champ option
@@:
mov dword[ebx],0
add ebx,4
cmp ebx,vend+64
jne @b

mov dword[vend],063538263h   ;ajoute le double mot magique (voir RFC1497)


mov edi,vend+4

mov word[edi],0135h       ;ajoute l'option de réponse dhcp
mov byte[edi+2],dl         
add edi,3 


mov word[edi],0401h       ;ajoute l'option de masque reseau
mov eax,[masque]
mov [edi+2],eax
add edi,6 

mov word[edi],0403h      ;ajoute l'option passerelle
mov eax,[ip_serveur]
mov [edi+2],eax
add edi,6

mov word[edi],0406h      ;ajoute l'option serveur DNS
mov eax,[ip_serveur]
mov [edi+2],eax
add edi,6



;on rajoute les options spécifique au dhcp ack
cmp dl,5
jne @f

mov word[edi],0433h       ;ajoute l'option dhcp-lease-time (durée de vie
mov eax,[temp_reservation]
bswap eax
mov [edi+2],eax
add edi,6


mov word[edi],043Ah       ;ajoute l'option temp première relance (moitié de la durée de reservation)
mov eax,[temp_reservation]
shr eax,1
bswap eax
mov [edi+2],eax
add edi,6


mov word[edi],043Bh       ;ajoute l'option temp seconde relance (3/4 de la durée de reservation)
mov eax,[temp_reservation]
shr eax,1
mov ecx,[temp_reservation]
shr ecx,2
add eax,ecx
bswap eax
mov [edi+2],eax
add edi,6

@@:

mov byte[edi],255        ;marque la fin des options   



;envoie trame
mov dword[ipv4_out],0FFFFFFFFh
mov al,7
mov ebx,[adresse_canal]
mov ecx,edi
sub ecx,port_out-1
mov esi,port_out
int 65h
cmp eax,0
je boucle_principale


mov edx,msg_err3
call ajuste_langue
mov al,6        
int 61h
jmp boucle_principale



;***********************
erreur_ouv_port:
mov edx,msg_err1
call ajuste_langue
mov al,6        
int 61h
int 60h

;*****************
erreur_param:
mov edx,msg_err2
call ajuste_langue
mov al,6        
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
adresse_canal:
dd 0


temp_reservation:
dd 28800 ;8 heures en secondes


zt_info:
dw 0
mac_serveur:
dw 0,0,0
ip_serveur:
dd 0
masque:
dd 0
ip_diffusion:
dd 0
adresse_ipv6_lien:
dd 0,0,0,0
boot:
rb 32








msg_err1:
db "SPXE: error when opening UDP port",13,0
db "SPXE: erreur lors de l'ouverture du port UDP",13,0
msg_err2:
db "SPXE: parameter error",13,0
db "SPXE: erreur de paramètre",13,0


msg_err3:
db "SPXE: error when sending a frame",13,0
db "SPXE: erreur lors de l'envoie d'une trame",13,0


msg_ok:
db "SPXE: server started",13,0
db "SPXE: serveur démarré",13,0


msg_rec1:
db "SPXE: receiving an address request frame from the address ",0
db "SPXE: reception d'une trame de demande d'adresse en provenance de l'adresse ",0


msg_rec2:
db " assigned to the address ",0
db " affecté a l'adresse ",0


msg_rec3:
db " but no more address available to assign to it",13,0
db " mais plus d'adresse disponible à lui affecter",13,0


msg_rec4:
db " but the requested address is different from the one assigned",13,0
db " mais l'adresse réclamé est différente de celle attribué",13,0


tempo:
rb 256

to_bdd:
rb 4

;**********************trame udp
port_out:
rb 2
ipv4_out:
rb 4
ipv6_out:
rb 16
zt_bootp:   ;1=bootrequest 2=bootreply
db 0          
htype:      ;type d'adresse materiel
db 0          
hlen:       ;longeur de l'adresse materiel
db 0         
hops:       ;uttilsé par les passerelles intermédiaires
db 0
xid:        ;ID de la requete
dd 0
secs:       ;seconde écoulé depuis le début de la tentative d'amorçage
dw 0
flags:      ;flag divers
dw 0
ciaddr:     ;adresse IP du client si il la connait
dd 0
yiaddr:     ;adresse IP du client determiné par le serveur
dd 0
siaddr:     ;adresse ip du serveur (nous donc)
dd 0
giaddr:     ;adresse ip de la passerelle
dd 0
chaddr:     ;adresse materielle du client
dd 0,0,0,0
sname:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octets, nom du serveur
fichier_boot:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octets, nom du programme d'amorçage
vend:
rb 64   ;64 octets, zone optionnelle determiné par le constructeur
rb 512  ;octets supplémentaire pour pouvoir satisfaire une éventuelle requete DHCP





ad_bdd:


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
