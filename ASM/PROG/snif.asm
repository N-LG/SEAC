bloub:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "programme de sniffage de trame ethernet"
scode:
org 0

;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax


;extrait l'adresse mac de la carte physique
mov al,4
mov ah,0
mov cl,40
mov edx,zt_tempo
int 61h

mov al,108
mov edx,zt_tempo
mov ecx,mac_physique
int 61h

;liste les service ethernet
mov al,11
mov ah,6     ;code service carte ethernet 
mov cl,16
mov edx,zt_liste
int 61h

;interroge les services pour trouver celui qui correspond a l'adresse mac physique
mov ebp,zt_liste

boucle_cherche_carte:
mov ebx,ebp
mov ax,[ebx]
cmp ax,0
je erreur_init_cpnt

mov bx,ax
mov [id_carte_physique],bx
mov al,0
mov ecx,64
mov edx,0
mov esi,0
mov edi,0
int 65h

mov [adresse_canal],ebx




;envoie la commande de lecture
mov word[zt_tempo],04h
mov al,5
mov ebx,[adresse_canal]
mov ecx,2h
mov edi,0
mov esi,zt_tempo
int 65h
cmp eax,0
jne test_autre 

;regarde si on as une réponse (une modification du descripteur)
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne test_autre 


mov al,4
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,0
mov edi,zt_tempo
int 65h
cmp eax,0
jne test_autre 


cmp byte[zt_tempo],84h
jne test_autre
mov eax,[mac_physique]
cmp [zt_tempo+2],eax
jne test_autre
mov ax,[mac_physique+4]
cmp [zt_tempo+6],ax
je carte_trouve



test_autre:
add ebp,2
;ferme le canal utilisé 
mov al,1    
mov ebx,[adresse_canal]
int 65h
jmp boucle_cherche_carte



carte_trouve:
;ferme le canal utilisé 
mov al,1    
mov ebx,[adresse_canal]
int 65h


;créer le canal de com
mov bx,[id_carte_physique]
mov al,0
mov ecx,64
mov edx,1
mov esi,24000
mov edi,24000
int 65h

mov [adresse_canal],ebx

;configure le canal pour une interception de trame ethernet
mov word[zt_tempo],04h

mov al,5
mov ebx,[adresse_canal]
mov ecx,8h
mov edi,0
mov esi,zt_tempo
int 65h
cmp eax,0
jne erreur_init_cpnr 

mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne erreur_init_cpnr 

mov al,4
mov ebx,[adresse_canal]
mov ecx,8h
mov esi,0
mov edi,zt_tempo
int 65h
cmp eax,0
jne erreur_init_cpnr 

cmp byte[zt_tempo],84h
jne erreur_init_cpnr


mov edx,msg_ok
mov al,6        
int 61h


boucle:
;lit les données reçu

mov al,6
mov ebx,[adresse_canal]
mov ecx,2048
mov edi,zt_decod
int 65h

cmp ecx,0
je boucle
mov [taille_trame],ecx

eth_mac_dest    equ 0
eth_mac_sour    equ 6
eth_type1       equ 12
eth_vlan_id     equ 14
eth_type2       equ 16

arp_netype      equ 0
arp_protype     equ 2
arp_lg_mac      equ 4
arp_lg_ip       equ 5
arp_op          equ 6
arp_mac_sour    equ 8
arp_ip_sour     equ 14
arp_mac_dest    equ 18
arp_ip_dest     equ 24

ipv4_ihl        equ 0
ipv4_service    equ 1
ipv4_longueur   equ 2
ipv4_id         equ 4
ipv4_flag_frag  equ 6 
ipv4_ttl        equ 8
ipv4_protocole  equ 9
ipv4_checksum   equ 10
ipv4_ip_sour    equ 12
ipv4_ip_dest    equ 16
ipv4_options    equ 20

ipv6_classlabel equ 0
ipv6_taille     equ 4
ipv6_type_suiv  equ 6
ipv6_ttl        equ 7
ipv6_ip_sour    equ 8
ipv6_ip_dest    equ 24
ipv6_suite      equ 40

icmp_type       equ 0
icmp_code       equ 1
icmp_cheksum    equ 2
icmp_ident      equ 4
icmp_num_seq    equ 6

udp_port_sour   equ 0
udp_port_dest   equ 2
udp_longueur    equ 4
udp_cheksum     equ 6

tcp_port_sour   equ 0
tcp_port_dest   equ 2
tcp_seq         equ 4
tcp_ack         equ 8
tcp_flag        equ 12
tcp_fenetre     equ 14
tcp_cheksum     equ 16
tcp_pointeur    equ 18
tcp_option      equ 20





;affiche les données reçu
mov al,111
mov ecx,zt_decod+eth_mac_sour
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h   

mov al,6
mov edx,msg1
int 61h      

mov al,111
mov ecx,zt_decod+eth_mac_dest
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h      

mov esi,zt_decod+14     
cmp word[zt_decod+eth_type1],00608h     ;arp
je trame_arp
cmp word[zt_decod+eth_type1],00008h     ;ipv4
je trame_ip
cmp word[zt_decod+eth_type1],0DD86h     ;ipv6
je trame_ip6
cmp word[zt_decod+eth_type1],00081h     ;Vlan
je trame_vlan
jmp ethertype

trame_vlan:
mov esi,zt_decod+18
cmp word[zt_decod+eth_type2],00608h     ;arp
je trame_arp
cmp word[zt_decod+eth_type2],00008h     ;ipv4
je trame_ip
cmp word[zt_decod+eth_type2],0DD86h     ;ipv6
je trame_ip6


;*********************************************
ethertype:
mov al,6
mov edx,msg6
int 61h 

mov al,104
mov edx,esi
sub edx,2
mov cx,[edx]
xchg cl,ch
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h   

jmp affichage_bloc



;*****************************************
trame_arp:

cmp word[esi+arp_op],200h
je reponse_arp
 

mov al,6
mov edx,msg8
int 61h 
jmp fin_trame_arp



reponse_arp:
mov al,6
mov edx,msg9
int 61h 

fin_trame_arp:
mov al,112
mov ecx,esi
add ecx,arp_ip_sour
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h   

mov al,6
mov edx,msg10
int 61h

mov al,112
mov ecx,esi
add ecx,arp_ip_dest
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h
  
jmp affichage_bloc










;******************************************
trame_ip:
mov al,6
mov edx,msg3
int 61h 

mov al,112
mov ecx,esi
add ecx,ipv4_ip_sour
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h   

mov al,6
mov edx,msg1
int 61h      

mov al,112
mov ecx,esi
add ecx,ipv4_ip_dest
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h  

xor ecx,ecx
mov bl,[esi+ipv4_ihl]
mov cx,[esi+ipv4_longueur]
and ebx,0Fh
xchg cl,ch
shl ebx,2       ;ebx=taille de l'entête IP    
mov al,[esi+ipv4_protocole] 
add esi,ebx
sub ecx,ebx
cmp al,17   ;le datagramme est il UDP?
je affichage_udp
cmp al,6   ;le datagramme est il TCP?
je affichage_tcp
jmp affichage_bloc





;*****************************************
trame_ip6:
mov al,6
mov edx,msg7
int 61h 

mov al,113
mov ecx,esi
add ecx,ipv6_ip_sour
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h   

mov al,6
mov edx,msg1
int 61h      

mov al,113
mov ecx,esi
add ecx,ipv6_ip_dest
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h  
jmp affichage_bloc




;***************************************
affichage_tcp:
push ecx
mov al,6
mov edx,msg4
int 61h 

mov al,102
xor ecx,ecx
mov cx,[esi+tcp_port_sour]
xchg cl,ch
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h   

mov al,6
mov edx,msg1
int 61h      

mov al,102
xor ecx,ecx
mov cx,[esi+tcp_port_dest]
xchg cl,ch
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h  

mov al,6
mov edx,msg11
int 61h      

mov al,102
mov ecx,[esi+tcp_seq]
bswap ecx
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h  

mov al,6
mov edx,msg12
int 61h      

mov al,102
mov ecx,[esi+tcp_ack]
bswap ecx
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h  

mov al,6
mov edx,msg13
int 61h      

mov al,104
mov cx,[esi+tcp_flag]
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h  

mov al,6
mov edx,msg14
int 61h      
pop ecx


mov al,[esi+tcp_flag]
and eax,0F0h
shr eax,2
sub ecx,eax

mov al,102
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h  



;???????????????


jmp affichage_bloc



;***************************************
affichage_udp:
mov al,6
mov edx,msg5
int 61h 

mov al,102
xor ecx,ecx
mov cx,[esi+udp_port_sour]
xchg cl,ch
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h   

mov al,6
mov edx,msg1
int 61h      

mov al,102
xor ecx,ecx
mov cx,[esi+udp_port_dest]
xchg cl,ch
mov edx,zt_tempo
int 61h
mov al,6
mov edx,zt_tempo
int 61h  


cmp byte[esi+udp_port_dest+1],69
je @f
cmp byte[esi+udp_port_dest+1],138
je @f
cmp byte[esi+udp_port_dest+1],137
je @f
cmp byte[esi+udp_port_sour+1],68
je @f
cmp byte[esi+udp_port_dest+1],68
je @f
cmp byte[esi+udp_port_sour+1],67
je @f
cmp byte[esi+udp_port_dest+1],67
jne affichage_bloc 
@@:
mov al,6
mov edx,msg2
int 61h 

xor ebx,ebx
mov bx,[esi+udp_longueur]
xchg bl,bh
add esi,8

@@:
mov eax,105
mov cl,[esi]
mov edx,zt_tempo
int 61h
mov word[zt_tempo+2],20h

mov al,6
mov edx,zt_tempo
int 61h  


inc esi
dec ebx
jnz @b


;*****************************************
affichage_bloc:
mov al,6
mov edx,msg2
int 61h 
jmp boucle



erreur_init_cpnt:  ;erreur carte physique non trouvé
mov al,6
mov edx,msgerr_cpnt
int 61h

int 60h

erreur_init_cpnr:  ;erreur carte physique ne répond pas
mov al,6
mov edx,msgerr_cpnr
int 61h

int 60h

sdata1:
org 0

msg_ok:
db "service de sniffage Ethernet actif",13,0
msgerr_cpnt:
db "erreur lors du démarrage du sniffage, la carte physique n'as pas été trouvé",13,0
msgerr_cpnr:
db "erreur lors du démarrage du sniffage, la carte physique ne répond pas aux commandes",13,0

msg1:
db " > ",0
msg2:
db 13,0

msg3:
db " IP ",0
msg4:
db " TCP ",0
msg5:
db " UDP ",0
msg6:
db " Ethertype:",0
msg7:
db " IPv6",13,0
msg8:
db " Requete ARP de ",0
msg9:
db " Réponse ARP de ",0
msg10:
db " pour ",0
msg11:
db " SEQ:",0
msg12:
db " ACK:",0
msg13:
db " FLAGS:",0
msg14:
db " Taille:",0

id_carte_physique:
dw 0
mac_physique:
dw 0,0,0,0
adresse_canal:
dd 0
taille_trame:
dd 0

optn1:
db 0
optn2:
db 0


zt_tempo:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
zt_liste:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64




zt_decod:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


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
