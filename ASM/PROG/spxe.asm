bidon:
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

mov al,100
mov edx,tempo
int 61h
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

mov ebx,[tempo]
cmp ebx,0
je @f

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
je correspondance_ok 

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
int 61h
jmp boucle_principale







correspondance_ok:
mov al,6
mov edx,msg_rec2
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


mov ebx,vend           ;vide le champ option
bouclevidevend:
mov dword[ebx],0
add ebx,4
cmp ebx,vend+64
jne bouclevidevend

mov dword[vend],063538263h   ;ajoute le double mot magique (voir RFC1497)


mov edi,vend+4

mov word[edi],0153h       ;ajoute l'option de réponse dhcp
mov byte[edi+2],2         ;2=DHCPoffer
add edi,3 

;mov word[edi],0451h       ;ajoute l'option dhcp-lease-time (durée de vie
;?????????????????
;mov byte[edi+2],eax
;add edi,6

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
mov al,6        
int 61h
jmp boucle_principale










;***********************
erreur_ouv_port:
mov edx,msg_err1
mov al,6        
int 61h
int 60h

;*****************
erreur_param:
mov edx,msg_err2
mov al,6        
int 61h
int 60h



sdata1:
org 0
adresse_canal:
dd 0





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
db "SPXE: erreur lors de l'ouverture du port UDP",13,0
msg_err2:
db "SPXE: erreur de parametre",13,0

msg_err3:
db "SPXE: erreur lors de l'envoie d'une trame",13,0

msg_ok:
db "SPXE: serveur démarré",13,0

msg_rec1:
db "SPXE: reception d'une trame de demande d'adresse en provenance de l'adresse ",0

msg_rec2:
db " affecté a l'adresse ",0

msg_rec3:
db " mais plus d'adresse disponible a lui affecter",13,0


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
