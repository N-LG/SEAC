;include standard pour les pilotes IP pour carte réseau (code)
;
;fonction nécessaire: init_carte    rec_trame     env_trame



;reste a faire:

;gestion des trame reçu en avance ou en retard (a controler)
;réemission des paquets perdus (a controler)
;gerer les autres protocoles ethernet (a controler)
;gerer le multi adresse ethernet (a controler)


;ajouter verif conformité param adresse carte
;adresse de broadcast/multicast
;fenetre d'emission variable
;fragmentation IPv4
;ipv6

 
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

dhcp_op         equ 0
dhcp_htype      equ 1
dhcp_hlen       equ 2
dhcp_hops       equ 3
dhcp_xid        equ 4
dhcp_secs       equ 8
dhcp_flags      equ 10
dhcp_ciaddr     equ 12
dhcp_yiaddr     equ 16
dhcp_siaddr     equ 20
dhcp_giaddr     equ 24
dhcp_chaddr     equ 28
dhcp_sname      equ 44
dhcp_file       equ 108
dhcp_options    equ 236


;**********************************************************************************************
zone_attente_type equ 0         ;0=vide 
				;1=trame ipv4 en attente d'adresse physique 
				;2=trame ipv6 en attente d'adresse physique  
				;3=trame ip fragmenté  
				;4=trame tcp en attente de validation de reception  
				;5=trame tcp reçu trop tôt
zone_attente_taille equ 2       ;2 octet


;pour type 1 & 2
zone_attente_tcp_descr       equ 4   ;adresse du descripteur de connexion
zone_attente_tcp_compteur    equ 8   ;valeur compteur minimum pour conserver la trame (64bit)
zone_attente_adresse_rech    equ 16  ;adresse recherché


;pour type 4
;zone_attente_tcp_descr       equ 4    ;adresse du descripteur de connexion
;zone_attente_tcp_compteur    equ 8    ;valeur compteur minimum pour réexpédier la trame (64bit
zone_attente_tcp_ack_attendu equ 16   ;numéros d'acquittement qui validera la reception de la trame

zone_attente_tcp_delais      equ 24   ;délais entre chaque réexpédition de trame
zone_attente_tcp_nb          equ 28   ;nombre de réexpédions maximum restante


;pour type 5
;zone_attente_tcp_descr       equ 6   ;adresse du descripteur de connexion
zone_attente_tcp_seq_trame   equ 10   ;numéros d'acquittement de la trame
;zone_attente_tcp_compteur    equ 16   ;valeur compteur maximum durant laquelle conserver la trame


zone_attente_trame equ 32


;***************************************************
zone_arp_nds_masque_ipv4 equ 0
zone_arp_nds_masque_ipv6 equ 1
zone_arp_nds_ethernet equ 2
zone_arp_nds_adresse_ipv4 equ 8
zone_arp_nds_tempo equ 12
zone_arp_nds_adresse_ipv6 equ 16


;***************************************** descripteur de connexions ouverte udp ou tcp
cnx_port_serveur    equ 0
cnx_id equ 02h
cnx_adresse_com equ 4


;uniquement tcp
cnx_etat      equ 08h
cnx_nbmax equ 0Ah
cnx_tozt equ 0Ch
;10o
cnx_port_client equ 1Ah
cnx_adresse_ipv4_client equ 1Ch
cnx_adresse_ipv6_client equ 20h
cnx_seq_serveur_suivante equ 30h         ;le numéros de séquence des prochaines données a envoyer
cnx_seq_client_attendue  equ 34h         ;le numéros de séquence des prochaines données a recevoir
cnx_seq_serveur_max equ 38h              ;le numéros de séquence maximum que l'on peut envoyer au client sans attendre d'aquitement 
;4o




;valeur de cnx_etat:
;0=port entrant ouvert
;1=connexion sortante en phase de connexion
;2=connexion entrante en phase de synchronisation
;3=connexion établit
;4=connexion en phase d'arret (initiative serveur) attend ack par client
;5=connexion en phase d'arret (initiative serveur) attend fin par client
;6=connexion en phase d'arret (initiative client) envoie fin vers client
;7=connexion en phase d'arret (initiative client) attente ack par client




;*****************************
;trappe de débogage
macro trappe val
{
pushad
mov byte[msg_trappe],val
mov byte[msg_trappe+1],13
mov byte[msg_trappe+2],0
mov eax,6
mov edx,msg_trappe
int 61h
popad
}







;****************************************************************
mov ax,sel_dat1
mov ds,ax
mov es,ax

call change_taille_mem     ;initialise la bonne taille de mémoire

;le programme se déclare comme étant un service reseau ethernet
mov al,10
mov ah,6
int 61h


;récupère l'adresse du périphérique
mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,16
mov edx,arg_0
int 61h

call init_carte
cmp eax,0
je suite_start_carte

;affiche un message comme quoi aucune carte n'as été détecté
mov edx,msgnok
call message_console
int 60h

suite_start_carte:
;affiche un message comme quoi la carte est ok
mov edx,msgok1
call message_console

mov al,111
mov ecx,adresse_mac
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov edx,msgok2
call message_console

jmp suite_reinit_carte





;***************************
message_console:  ;affiche un message dans la console en fonction de la langue ds:edx=adresses des message
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

boucle_message_console:
cmp ecx,0
je ok_message_console
cmp byte[edx],0
jne @f
dec ecx
@@:
inc edx
jmp boucle_message_console

ok_message_console:
mov al,6
int 61h
ret









;********************************************************************************************************************
;********************************************************************************************************************
boucle_principale:
mov eax,12          ;lit le compteur temp
int 61h
mov[cptsf],eax
mov[cptsf+4],edx

;verifie que l'adresse ipv4 est toujours valide
cmp byte[dhcp_phase],10
jne ignore_tempo_dhcp

mov edx,dhcp_t3
call comp64
jb stop_dhcp
mov edx,dhcp_t2
call comp64
jb @f
mov edx,dhcp_t1
call comp64
ja ignore_tempo_dhcp

@@:
mov dword[edx],0FFFFFFFFh
mov dword[edx+4],0FFFFFFFFh
jmp envoie_dhcp_request  ;sinon il faut la redemander au serveur dhcp

stop_dhcp:
mov byte[dhcp_phase],0
mov dword[adresse_ipv4],0
mov dword[masque_ipv4],0
mov dword[passerelle_ipv4],0

ignore_tempo_dhcp:



;********************************************************************************************************************
;********************************************************************************************************************
;recherche si il y as une nouvelle connexion interne
mov al,2
int 65h
cmp eax,cer_ddi
jne lire_nouvelle_trame

mov al,4
mov ecx,34h
mov esi,0
mov edi,zt_decod
int 65h

cmp byte[zt_decod],0
je lire_nouvelle_trame
cmp byte[zt_decod],1
je reinit_carte
cmp byte[zt_decod],2
je lire_config
cmp byte[zt_decod],3
je ecrire_config
cmp byte[zt_decod],4
je ethernet_toutestrames
cmp byte[zt_decod],5
je ethernet_autresprotocoles
cmp byte[zt_decod],6
je ethernet_autresadresses
cmp byte[zt_decod],7
je ouverture_portudp
cmp byte[zt_decod],8
je ouverture_porttcp
cmp byte[zt_decod],9
je acces_icmp
cmp byte[zt_decod],10
je config_dhcp


mov word[zt_decod],00FFh  ;on signale que la commande est inconnue
mov al,5
mov ecx,34h
mov edi,0
mov esi,info_adresse_carte
int 65h
jmp lire_nouvelle_trame 






;******************************************
reinit_carte:
call init_carte
cmp eax,0
je suite_reinit_carte
int 60h

suite_reinit_carte:     ;complete l'adresse local de lien avec l'adresse MAC suivant la méthode MAC-EUI64
mov eax,[adresse_mac]
mov edx,[adresse_mac+3]
and eax,0FFFFFFh
and edx,0FFFFFFh
xor eax,02h
shl edx,8
or eax,0FF000000h
or edx,0FEh
mov [adresse_ipv6_lien+8],eax
mov [adresse_ipv6_lien+12],edx 
jmp boucle_principale



;*************************************
lire_config:
mov word[info_adresse_carte],0082h
mov al,5
mov ecx,34h
mov edi,0
mov esi,info_adresse_carte
int 65h
jmp lire_nouvelle_trame 


;*****************************************
ecrire_config:
mov al,4
mov ecx,34h
mov esi,0
mov edi,info_adresse_carte
int 65h

mov byte[dhcp_phase],0   ;on désactive le dhcp

mov eax,[adresse_mac]     ;complete l'adresse local de lien avec l'adresse MAC suivant la méthode MAC-EUI64
mov edx,[adresse_mac+3]
and eax,0FFFFFFh
and edx,0FFFFFFh
xor eax,02h
shl edx,8
or eax,0FF000000h
or edx,0FEh
mov [adresse_ipv6_lien+8],eax
mov [adresse_ipv6_lien+12],edx 


mov word[info_adresse_carte],0083h
mov al,5
mov ecx,2h
mov edi,0
mov esi,info_adresse_carte
int 65h
jmp lire_nouvelle_trame 



;**************************************
ethernet_toutestrames:
mov [tout_ethernet],ebx
mov word[zt_decod],0084h
mov al,5
mov ecx,2h
mov edi,0
mov esi,zt_decod
int 65h
jmp lire_nouvelle_trame 



;**************************************
ethernet_autresprotocoles:
mov esi,table_ethernet_protocole

boucle_ethernet_autresprotocoles:
cmp dword[esi+2],0FFFFFFFFh
je suite_ethernet_autresprotocoles
add esi,6
cmp esi,table_ethernet_protocole+16*6
jne boucle_ethernet_autresprotocoles
jmp lire_nouvelle_trame 

suite_ethernet_autresprotocoles:
mov ax,[zt_decod+2]
mov [esi],ax
mov [esi+2],ebx

mov word[zt_decod],0085h
mov al,5
mov ecx,8h
mov edi,0
mov esi,zt_decod
int 65h
jmp lire_nouvelle_trame 


;**************************************
ethernet_autresadresses:
mov esi,table_ethernet_virtuel

boucle_ethernet_autresadresses:
cmp dword[esi+6],0FFFFFFFFh
je suite_ethernet_autresadresses
add esi,10
cmp esi,table_ethernet_virtuel+8*10
jne boucle_ethernet_autresadresses
jmp lire_nouvelle_trame 

suite_ethernet_autresadresses:
mov eax,[zt_decod+2]
mov [esi],eax
mov ax,[zt_decod+6]
mov [esi+4],ax
mov [esi+6],ebx

mov word[zt_decod],0086h
mov al,5
mov ecx,8h
mov edi,0
mov esi,zt_decod
int 65h
jmp lire_nouvelle_trame 



;**************************************
ouverture_portudp:
mov ax,[zt_decod+2]

;verifie d'abord que le port n'est pas déja ouvert
mov esi,[ad_table_udp]
mov ecx,[nb_table_udp]
ouverture_portudp_verification:
cmp [esi+cnx_port_serveur],ax
je ouverture_portudp_dejaouvert
add esi,8
dec ecx
jnz ouverture_portudp_verification

;recherche une zone libre
mov esi,[ad_table_udp]
mov ecx,[nb_table_udp]
ouverture_portudp_libre:
cmp byte[esi+cnx_port_serveur],0
je ouverture_portudp_trouve
add esi,8
dec ecx
jnz ouverture_portudp_libre


ouverture_portudp_dejaouvert:
mov word[zt_decod],00C0h         ;code erreur port déjà ouvert
mov al,5
mov ecx,2h
mov edi,0
mov esi,zt_decod
int 65h
jmp lire_nouvelle_trame 

ouverture_portudp_trouve:
mov [esi+cnx_port_serveur],ax
mov [esi+cnx_adresse_com],ebx
push ebx
push esi
mov al,10
int 65h
pop esi
mov [esi+cnx_id],bx
pop ebx

mov word[zt_decod],0087h
mov al,5
mov ecx,2h
mov edi,0
mov esi,zt_decod
int 65h
jmp lire_nouvelle_trame 




;**************************************
ouverture_porttcp:
mov ax,[zt_decod+2]

;verifie d'abord que le port n'est pas déja ouvert
mov esi,[ad_table_tcp]
mov ecx,[nb_table_tcp]
ouverture_porttcp_verification:
cmp byte[esi+cnx_etat],4
je ignore_ouverture_porttcp_verification  ;on ignore le descripteur si il est dans une phase d'arret
cmp byte[esi+cnx_etat],5
je ignore_ouverture_porttcp_verification
cmp byte[esi+cnx_etat],6
je ignore_ouverture_porttcp_verification
cmp byte[esi+cnx_etat],7
je ignore_ouverture_porttcp_verification
cmp [esi+cnx_port_serveur],ax
je ouverture_porttcp_dejaouvert
ignore_ouverture_porttcp_verification:
add esi,64
dec ecx
jnz ouverture_porttcp_verification

;recherche une zone libre
mov esi,[ad_table_tcp]
mov ecx,[nb_table_tcp]
ouverture_porttcp_libre:
cmp byte[esi+cnx_port_serveur],0
je ouverture_porttcp_trouve
add esi,64
dec ecx
jnz ouverture_porttcp_libre

ouverture_porttcp_dejaouvert:
mov word[zt_decod],0C0h     ;code erreur port déjà ouvert
mov al,5
mov ecx,2h
mov edi,0
mov esi,zt_decod
int 65h
jmp lire_nouvelle_trame 

ouverture_porttcp_trouve:

;création du descripteur de connexion
mov [esi+cnx_port_serveur],ax
mov [esi+cnx_adresse_com],ebx
;attribut
xor ah,ah
mov al,[zt_decod+1]
mov [esi+cnx_etat],ax

push ebx
push esi ;recupère l'ID de la tache qui as demandé la connexion
mov al,10
int 65h
pop esi
mov [esi+cnx_id],bx 
pop ebx

mov ax,[zt_decod+4]
mov [esi+cnx_nbmax],ax

mov eax,[zt_decod+6]
mov [esi+cnx_tozt],eax
;coord destination
mov ax,[zt_decod+0Ah]
mov edx,[zt_decod+0Ch]
mov [esi+cnx_port_client],ax
mov [esi+cnx_adresse_ipv4_client],edx
mov eax,[zt_decod+10h]
mov edx,[zt_decod+14h]
mov [esi+cnx_adresse_ipv6_client],eax
mov [esi+cnx_adresse_ipv6_client+4],edx
mov eax,[zt_decod+18h]
mov edx,[zt_decod+1Ch]
mov [esi+cnx_adresse_ipv6_client+8],eax
mov [esi+cnx_adresse_ipv6_client+12],edx
mov dword[esi+cnx_seq_serveur_suivante],0
mov dword[esi+cnx_seq_client_attendue],0
mov dword[esi+cnx_seq_serveur_max],0



;confirmation que la connexion est accepté
push esi
mov word[zt_decod],0088h
mov al,5
mov ecx,2h
mov edi,0
mov esi,zt_decod
int 65h
pop edi



;si c'est une ouverture de port sans destination précise, on ne fait rien de plus
cmp byte[edi+cnx_etat],0
je lire_nouvelle_trame


;si c'est une connexion vers l'extérieur on choisi le numéros de séquence
mov eax,12
int 61h
xor eax,058CAh ;on xor le compteur temp avec un nombre au pif   
and eax,0FFFFh ;et on troque le résultat pour avoir un numéros de séquence pseudo aléatoirement
inc eax
mov [edi+cnx_seq_serveur_suivante],eax


;on envoie la première trame de synchronisation
mov esi,zt_decod+64
mov [offset_ip],esi 

mov ax,[edi+cnx_port_serveur]  ;port
mov bx,[edi+cnx_port_client]
xchg al,ah
xchg bl,bh
mov [esi+tcp_port_sour],ax
mov [esi+tcp_port_dest],bx

mov eax,[edi+cnx_seq_serveur_suivante]
mov ebx,[edi+cnx_seq_client_attendue]
dec eax
bswap eax
bswap ebx
mov [esi+tcp_seq],eax
mov [esi+tcp_ack],ebx

mov word[esi+tcp_flag],0250h   ;SYN a 1 + en-tête de 5dword

mov word[esi+tcp_fenetre],0040h ;fenêtre d'envoie 16Ko 
mov word[esi+tcp_cheksum],0
mov word[esi+tcp_pointeur],0

mov dword[taille_niv_sup],20

mov eax,[edi+cnx_adresse_ipv4_client]
mov [adresse_ipv4_destination],eax
mov eax,[edi+cnx_adresse_ipv6_client]
mov [adresse_ipv6_destination],eax
mov eax,[edi+cnx_adresse_ipv4_client+4]
mov [adresse_ipv6_destination+4],eax
mov eax,[edi+cnx_adresse_ipv4_client+8]
mov [adresse_ipv6_destination+8],eax
mov eax,[edi+cnx_adresse_ipv4_client+12]
mov [adresse_ipv6_destination+12],eax


;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],06
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+tcp_cheksum],ax

call envoie_trame_ip
call sauvegarde_trame_tcp    ;sauvegarde trame pour réexpédition
jmp reception_interne



;**************************************
acces_icmp:
mov esi,table_acces_icmp

boucle_acces_icmp:
cmp dword[esi],0FFFFFFFFh
je suite_acces_icmp
add esi,4
cmp esi,table_acces_icmp+8*4
jne boucle_acces_icmp

mov word[zt_decod],00FFh
mov al,5
mov ecx,8h
mov edi,0
mov esi,zt_decod
int 65h
jmp lire_nouvelle_trame 

suite_acces_icmp:
mov [esi],ebx

mov word[zt_decod],0089h
mov al,5
mov ecx,8h
mov edi,0
mov esi,zt_decod
int 65h
jmp lire_nouvelle_trame




;****************************
config_dhcp:
mov [dhcp_demande],ebx
mov byte[dhcp_phase],1
mov dword[adresse_ipv4],0
mov dword[masque_ipv4],0
mov dword[passerelle_ipv4],0

;envoie une demande dhcp discover
mov eax,12
int 61h
xor eax,ecx
xor eax,063538263h ;génère un numéros de séquence a partir du numéros de séquence du client et du compteur temp
mov [dhcp_id],eax

;prépare la trame bootp
mov esi,zt_decod+80h
mov byte[esi+dhcp_op],1
mov byte[esi+dhcp_htype],1
mov byte[esi+dhcp_hlen],6
mov byte[esi+dhcp_hops],0
mov dword[esi+dhcp_xid],eax
mov word[esi+dhcp_secs],0
mov word[esi+dhcp_flags],0
mov dword[esi+dhcp_ciaddr],0
mov dword[esi+dhcp_yiaddr],0
mov dword[esi+dhcp_siaddr],0
mov dword[esi+dhcp_giaddr],0
xor edx,edx
mov eax,[adresse_mac]
mov dx,[adresse_mac+4]
mov dword[esi+dhcp_chaddr],eax
mov dword[esi+dhcp_chaddr+4],edx
mov dword[esi+dhcp_chaddr+8],0
mov dword[esi+dhcp_chaddr+12],0
;efface sname et file
mov ebx,esi
mov ecx,dhcp_options-dhcp_sname
add ebx,dhcp_sname
@@:
mov byte[ebx],0
inc ebx
dec ecx
jnz @b



;ajoute les options dhcp
push esi
add esi,dhcp_options
mov dword[esi],063538263h   ;ajoute le double mot magique (voir RFC1497)
add esi,4

mov word[esi],0135h       ;ajoute l'option de requête dhcp
mov byte[esi+2],1         ;dhcp discover
add esi,3 

mov word[esi],073Dh       ;ajoute l'option  ID du client
mov eax,[adresse_mac]
mov dx,[adresse_mac+4]
mov byte[esi+2],1
mov [esi+3],eax
mov [esi+7],dx
add esi,9 

mov byte[esi],255        ;marque la fin des options 
inc esi
mov ecx,esi
pop esi
sub esi,8
sub ecx,esi
mov [taille_niv_sup],ecx



;remplit les données de l'en tête udp
mov ax,68
mov bx,67
xchg al,ah
xchg bl,bh
xchg cl,ch
mov [esi+udp_port_sour],ax
mov [esi+udp_port_dest],bx
mov [esi+udp_longueur],cx
mov word[esi+udp_cheksum],0
mov [offset_ip],esi 

;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],17
mov dword[adresse_ipv4_destination],0FFFFFFFFh
mov dword[adresse_ipv6_destination],0
mov dword[adresse_ipv6_destination+4],0
mov dword[adresse_ipv6_destination+8],0
mov dword[adresse_ipv6_destination+12],0
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+udp_cheksum],ax

call envoie_trame_ip
jmp reception_interne




;*********************************************************************************************************************************************
;*********************************************************************************************************************************************
lire_nouvelle_trame:
mov edi,zt_decod
mov ecx,2048
call rec_trame             ;entrée es:edi=adresse ou ecrire la trame  sortie: ecx=taille de la trame eax=code d'erreur
cmp eax,0
je ok_reception
mov edx,msgerec
mov al,6        
int 61h
int 60h

reception_interne:
xor ecx,ecx
xchg ecx,[to_decod]

ok_reception:
cmp ecx,0
je verifie_trame_attente
mov [taille_trame],ecx

;envoie de toutes les trames reçu
cmp dword[tout_ethernet],0FFFFFFFFh
je ignore_envoie_toutes_trames
mov al,7
mov ebx,[tout_ethernet]
mov ecx,[taille_trame]
mov esi,zt_decod
int 65h
ignore_envoie_toutes_trames:

;on vérifie que ce n'est pas une autre adresse ethernet
mov eax,[zt_decod+eth_mac_dest]
mov dx,[zt_decod+eth_mac_dest+4]
cmp [adresse_mac],eax
jne nok_destinataire_ethernet
cmp [adresse_mac+4],dx
je ok_destinataire_ethernet 

nok_destinataire_ethernet:
cmp ax,3333h
je ok_broadcast  ;multicast
cmp eax,0FFFFFFFFh
jne nok_broadcast
cmp dx,0FFFFh
je ok_broadcast


nok_broadcast:  ;recherche une correspondance d'adresse dans la liste des cartes virtuelles
mov ebx,table_ethernet_virtuel
boucle_recherche_autre_adresse:
cmp dword[ebx+6],0FFFFFFFFh
je pastrouve_autre_adresse
cmp [ebx],eax
jne pastrouve_autre_adresse
cmp [ebx+4],dx
je trouve_autre_adresse
pastrouve_autre_adresse:
add ebx,10
cmp ebx,table_ethernet_virtuel+80
jne boucle_recherche_autre_adresse
jmp boucle_principale

trouve_autre_adresse:
mov eax,[ebx+6]
mov ebx,eax
mov al,7
mov ecx,[taille_trame]
mov esi,zt_decod
int 65h
jmp boucle_principale


ok_broadcast:   ;diffuse a toutes les cartes virtuelles
mov edi,table_ethernet_virtuel+6
boucle_ok_broadcast:
mov ebx,[edi]
cmp ebx,0FFFFFFFFh
je ok_destinataire_ethernet
mov al,7
mov ecx,[taille_trame]
mov esi,zt_decod
int 65h
add edi,10
cmp edi,table_ethernet_virtuel+86
jne boucle_ok_broadcast


ok_destinataire_ethernet:
mov dword[offset_ethernet],zt_decod+14
cmp word[zt_decod+eth_type1],00008h     ;ipv4
je trame_ipv4
cmp word[zt_decod+eth_type1],00608h     ;ARP
je trame_arp
cmp word[zt_decod+eth_type1],0DD86h    ;ipv6
je trame_ipv6
cmp word[zt_decod+eth_type1],00081h     ;Vlan
je trame_vlan
jmp boucle_principale

trame_vlan:
mov dword[offset_ethernet],zt_decod+18
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§  test si on est sur le bon Vlan?
cmp word[zt_decod+eth_type2],00008h     ;ipv4
je trame_ipv4
cmp word[zt_decod+eth_type2],00608h     ;ARP
je trame_arp
cmp word[zt_decod+eth_type2],0DD86h    ;ipv6
je trame_ipv6
jmp boucle_principale



;******************************************************************************************
trame_arp:
mov esi,[offset_ethernet]

;verifie que le format est correct sinon on ignore la trame
cmp word[esi+arp_netype],0100h  ;type de réseau (ethernet)
jne boucle_principale              
cmp word[esi+arp_protype],0008h  ;type de protocole(ip)
jne boucle_principale
cmp word[esi+arp_lg_mac],0406h  ;taille des adresses
jne boucle_principale
cmp word[esi+arp_op],0200h    ;réponse arp?
je reponse_arp
cmp word[esi+arp_op],0100h    ;demande arp?
jne boucle_principale

mov eax,[adresse_ipv4]      ;est ce que c'est notre adresse?        
cmp [esi+arp_ip_dest],eax
jne boucle_principale                 

mov word[esi+arp_op],0200h       ;code réponse arp

mov eax,[esi+arp_mac_sour]    ;mettre l'expéditeur dans le destinataire
mov dx,[esi+arp_mac_sour+4]
mov ebx,[esi+arp_ip_sour]
mov [zt_decod+eth_mac_dest],eax     ;dans la trame ethernet
mov [zt_decod+eth_mac_dest+4],dx
mov [esi+arp_mac_dest],eax    ;dans la trame arp
mov [esi+arp_mac_dest+4],dx
mov [esi+arp_ip_dest],ebx

mov eax,[adresse_mac]   ;mettre ses coordonnées dans l'expéditeur
mov dx,[adresse_mac+4]
mov ebx,[adresse_ipv4]
mov [zt_decod+eth_mac_sour],eax     ;dans la trame ethernet
mov [zt_decod+eth_mac_sour+4],dx
mov [esi+arp_mac_sour],eax    ;dans la trame arp
mov [esi+arp_mac_sour+4],dx
mov [esi+arp_ip_sour],ebx

xor eax,eax        ;bourrage
mov [esi+arp_ip_dest+4],eax
mov [esi+arp_ip_dest+8],eax
mov [esi+arp_ip_dest+12],eax
mov [esi+arp_ip_dest+16],eax
mov [esi+arp_ip_dest+20],eax

mov esi,zt_decod
mov ecx,[offset_ethernet]
sub ecx,zt_decod
add ecx,28
call envoie_trame_ethernet
jmp boucle_principale 


reponse_arp:    ;recherche dans la zone arp nds si il y as une demande pour cette adresse
mov eax,[esi+arp_ip_sour]
mov edi,[ad_table_arp_nds]
mov ecx,[nb_table_arp_nds]

boucle_reponse_arp:
cmp [edi+zone_arp_nds_adresse_ipv4],eax
je reponse_arp_ok
add edi,32
dec ecx
jnz boucle_reponse_arp
jmp boucle_principale      


reponse_arp_ok:
mov [adresse_ipv4_destination],eax
mov eax,[esi+arp_mac_sour]          ;place la réponse dans la table ARP NDS
mov dx,[esi+arp_mac_sour+4]
mov [adresse_ethernet_destination],eax
mov [adresse_ethernet_destination+4],dx
mov byte[edi+zone_arp_nds_masque_ipv4],32
mov [edi+zone_arp_nds_ethernet],eax
mov [edi+zone_arp_nds_ethernet+4],dx

;verifie qu'il n'existe pas déja une adresse ipv6 qui correspondent a cette adresse ipv4
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
;si oui fusionne les entrées
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

;recherche dans les trame en attente ipv4 si il n'existe pas une trame qui a besoin de cette adresse
mov eax,[adresse_ipv4_destination]
mov ebx,[ad_zone_attente]
mov ecx,[nb_zone_attente]

boucle_verifie_trame_attente_ipv4:
cmp byte[ebx+zone_attente_type],1
jne suite_verifie_trame_attente_ipv4
cmp [ebx+zone_attente_adresse_rech],eax
jne suite_verifie_trame_attente_ipv4

pushad      ;trame correspondante trouvé, on met a jour l'adresse Ethernet et on l'envoie
mov esi,ebx
xor ecx,ecx
mov cx,[ebx+zone_attente_taille]
add esi,zone_attente_trame
mov eax,[adresse_ethernet_destination]
mov dx,[adresse_ethernet_destination+4]
mov dword[esi+eth_mac_dest],eax
mov word[esi+eth_mac_dest+4],dx
call envoie_trame_ethernet
popad 
mov word[ebx+zone_attente_type],0 ;et libère la zone ????????????ou si c'est du tcp on passe en mode 4

suite_verifie_trame_attente_ipv4:
add ebx,2048
dec ecx
jnz boucle_verifie_trame_attente_ipv4
jmp boucle_principale 




;***************************************************************************************
trame_ipv4:
;verifier le cheksum
xor ax,ax
mov esi,[offset_ethernet]
xchg [esi+ipv4_checksum],ax 
call chkip
mov esi,[offset_ethernet]
cmp [esi+ipv4_checksum],ax 
jne boucle_principale

;verifie l'adresse
mov eax,[esi+ipv4_ip_dest]
mov edx,[adresse_ipv4]
cmp eax,0FFFFFFFFh
je @f

cmp edx,0
je @f
cmp eax,edx
je @f

cmp eax,0100007fh
jne boucle_principale
cmp dword[esi+ipv4_ip_sour],0100007fh
jne boucle_principale


@@:

;test si la trame est un fragment d'une trame plus grande
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ on ignore cette étape pour le moment

;calculer la position du début des données dans la trame et la taille de celles ci
mov bl,[esi+ipv4_ihl]
and ebx,0Fh
shl ebx,2       ;ebx=taille de l'entête IP    
xor eax,eax
mov ax,[esi+ipv4_longueur]
xchg al,ah
sub eax,ebx
mov [taille_niv_sup],eax
add ebx,esi   
mov [offset_ip],ebx

call calc_pseudo_entete 

;orienter le paquet vers le bon protocole
mov al,[esi+ipv4_protocole] 
cmp al,1   ;le datagramme est il ICMP?
je trame_icmp_v4
;cmp al,2   ;le datagramme est il IGMP?
;je trame_igmp
cmp al,17   ;le datagramme est il UDP?
je trame_udp_v4
cmp al,6   ;le datagramme est il TCP?
je trame_tcp
jmp boucle_principale


;*************************************************************************
trame_ipv6:
mov esi,[offset_ethernet]
cmp byte[esi+ipv6_ip_dest],0FFh ;test si c'est une trame de multicast
je multicast_trame_ipv6

add esi,ipv6_ip_dest

;test l'adresse local de lien
mov edi,adresse_ipv6_lien
call cmp_adresse_ipv6
jc ok_dest_trame_ipv6


;test l'adresse réseau privée
mov edi,adresse_ipv6_local
call cmp_adresse_ipv6
jc ok_dest_trame_ipv6


;test l'adresse globale
mov edi,adresse_ipv6_global
call cmp_adresse_ipv6
jc ok_dest_trame_ipv6

jmp boucle_principale



multicast_trame_ipv6:
;§§§§§§§§§§§§§§§§§§§§§§§pour le moment on accepte toutes les trames envoyé en multicast IPv6

ok_dest_trame_ipv6:

;determine l'offset des donnés du niveau supérieur
mov esi,[offset_ethernet]
mov al,[esi+ipv6_type_suiv] 
add esi,ipv6_suite
mov [offset_ip],esi

boucle_determination_offset_ip:
mov [type_niv_sup],al


;cmp al,2   ;le datagramme est il IGMP?
;je offset_ip_determine
cmp al,17   ;le datagramme est il UDP?
je offset_ip_determine
cmp al,6   ;le datagramme est il TCP?
je offset_ip_determine
cmp al,58   ;le datagramme est il ICMPv6?
je offset_ip_determine

cmp al,0   ;l'option suivante est elle le Sauts après sauts?
je option_ipv6
cmp al,43   ;l'option suivante est elle le routage?
je option_ipv6
cmp al,44   ;l'option suivante est elle la fragmentation?
je option_ipv6
cmp al,60   ;l'option suivante est elle la destination?
je option_ipv6
cmp al,51   ;l'option suivante est elle l'authentification?
je option_ipv6
;cmp al,50   ;l'option suivante est elle l'ESP?
;je option_ipv6_ignore2


jmp boucle_principale ;si c'est une option ou un type inconnu, on ignore la trame

option_ipv6: ;on ignore ces options je ne sais pas si c'est une bonne idée pour le moment)
xor eax,eax
mov esi,[offset_ip]
mov al,[esi+1]
inc eax
shl eax,3
add [offset_ip],eax
mov al,[esi]
jmp boucle_determination_offset_ip

offset_ip_determine:

;determine la taille des données du type supérieur
xor eax,eax
mov ecx,[offset_ip]
mov esi,[offset_ethernet]
mov ax,[esi+ipv6_taille]
xchg al,ah
add eax,ipv6_suite
sub ecx,esi ;ecx=taille de l'en tête ipv6
sub eax,ecx
mov [taille_niv_sup],eax

call calc_pseudo_entete 

mov al,[type_niv_sup]
;cmp al,2   ;le datagramme est il IGMP?
;je trame_igmp
cmp al,17   ;le datagramme est il UDP?
je trame_udp_v6
cmp al,6   ;le datagramme est il TCP?
je trame_tcp
cmp al,58   ;le datagramme est il ICMPv6?
je trame_icmp_v6

jne boucle_principale

;**************************************************************************
;datagramme ICMPv4
trame_icmp_v4:
mov dword[somme_pseudo_entete],0 ;on n'utilise pas le pseudo entête en ICMPv4
call chk_gen
cmp ax,0
jne boucle_principale

mov esi,[offset_ip]
cmp byte[esi+icmp_type],8     ;est ce une demande d'écho?
jne autres_trame_icmp_v4

mov word[esi+icmp_type],0    ;réponse a un demande d'écho

mov esi,[offset_ethernet]
mov eax,[esi+ipv4_ip_sour]
xchg [esi+ipv4_ip_dest],eax     ;source devient destination
mov [esi+ipv4_ip_sour],eax      ;met son adresse ip dans source
mov word[esi+ipv4_checksum],0

mov eax,[zt_decod+eth_mac_sour]      ;idem avec les adresses MAC
mov dx,[zt_decod+eth_mac_sour+4]
xchg [zt_decod+eth_mac_dest],eax
xchg [zt_decod+eth_mac_dest+4],dx
mov [zt_decod+eth_mac_sour],eax
mov [zt_decod+eth_mac_sour+4],dx

mov esi,[offset_ethernet]
call chkip   ;calcul du cheksum ip

mov esi,[offset_ip]
mov dword[somme_pseudo_entete],0 ;on n'utilise pas le pseudo entête en ICMPv4
mov word[esi+icmp_cheksum],0
call chk_gen
mov [esi+icmp_cheksum],ax


mov esi,zt_decod
mov ecx,[offset_ip]
sub ecx,zt_decod
add ecx,[taille_niv_sup]

call envoie_trame_ethernet
jmp reception_interne 


autres_trame_icmp_v4:
mov esi,[offset_ip]
sub esi,22      ;prépare l'en tête
mov edi,[offset_ethernet]
xor eax,eax
mov al,[edi+ipv4_ttl]
mov [esi],ax
mov edx,[edi+ipv4_ip_sour]
mov [esi+2],edx
mov dword[esi+6],0
mov dword[esi+10],0
mov dword[esi+14],0
mov dword[esi+18],0

mov edi,table_acces_icmp             ;envoie a tout les réceptionnaire des paquets icmp
mov ecx,[taille_trame]

boucle_autres_trame_icmp_v4:
mov ebx,[edi]
cmp ebx,0FFFFFFFFh
je suite_autres_trame_icmp_v4

mov al,7
int 65h

suite_autres_trame_icmp_v4:
add edi,4
cmp edi,table_acces_icmp+8*4
jne boucle_autres_trame_icmp_v4
jmp boucle_principale







;**************************************************************************
;datagramme ICMP v6
trame_icmp_v6:
call chk_gen

cmp ax,0
jne boucle_principale



mov esi,[offset_ip]
cmp byte[esi+icmp_type],128     ;est ce une demande d'écho?
je demande_echo_icmpv6 
cmp byte[esi+icmp_type],134     ;annonce de routeur
je annonce_routeur_icmpv6 
cmp byte[esi+icmp_type],135     ;sollicitation de voisin
je sollicitation_icmpv6 
cmp byte[esi+icmp_type],136     ;annonce de voisin
je annonce_voisin_icmpv6 
cmp byte[esi+icmp_type],137     ;redirection
je redirection_icmpv6 
jmp boucle_principale


demande_echo_icmpv6:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp boucle_principale  

annonce_routeur_icmpv6:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp boucle_principale  

sollicitation_icmpv6:
mov word[esi+icmp_type],136    ;annonce de voisin


call dep_adresse_ipv6


mov eax,[zt_decod+eth_mac_sour]      ;idem avec les adresses MAC
mov dx,[zt_decod+eth_mac_sour+4]
mov [zt_decod+eth_mac_dest],eax
mov [zt_decod+eth_mac_dest+4],dx
mov eax,[adresse_mac]
mov dx,[adresse_mac+4]
mov [zt_decod+eth_mac_sour],eax
mov [zt_decod+eth_mac_sour+4],dx





jmp boucle_principale


annonce_voisin_icmpv6:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp boucle_principale  

redirection_icmpv6:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp boucle_principale  



;**************************************************************************
;datagramme UDP
trame_udp_v4:
trame_udp_v6:
call chk_gen
cmp ax,0 
jne boucle_principale


;recherche si le port a été ouvert
mov esi,[offset_ip]
mov ax,[esi+udp_port_dest]   
xchg al,ah
cmp ax,68
je client_dhcp    ;envoie au client dhcp intégré
mov edi,[ad_table_udp]
mov ecx,[nb_table_udp]
trame_udp_verification:
cmp [edi+cnx_port_serveur],ax
je trame_udp_ok
add edi,8
dec ecx
jnz trame_udp_verification
jmp boucle_principale


trame_udp_ok:
mov ebx,[edi+cnx_adresse_com ]
mov ax,[esi+udp_port_sour]   
xchg al,ah
sub esi,14   ;+8 -22
mov [esi],ax



mov edi,[offset_ethernet]
mov al,[edi]
and al,0F0h

cmp al,40h
jne test_udp_ipv6

mov eax,[edi+ipv4_ip_sour]
mov [esi+2],eax
mov dword[esi+6],0
mov dword[esi+10],0
mov dword[esi+14],0
mov dword[esi+18],0

mov al,7
mov ecx,[taille_niv_sup]
add ecx,14     ;+22-8
int 65h
jmp boucle_principale


test_udp_ipv6:
cmp al,60h
jne boucle_principale

mov dword[esi+2],0
mov eax,[edi+ipv6_ip_sour]
mov [esi+6],eax
mov eax,[edi+ipv6_ip_sour+4]
mov [esi+10],eax
mov eax,[edi+ipv6_ip_sour+8]
mov [esi+14],eax
mov eax,[edi+ipv6_ip_sour+12]
mov [esi+18],eax


mov al,7
mov ecx,[taille_trame]
add ecx,4
int 65h
jmp boucle_principale






;*******************************
client_dhcp:
mov ax,[esi+udp_port_sour]   
xchg al,ah
cmp ax,67
jne boucle_principale
add esi,8
mov eax,[dhcp_id]
cmp [esi+dhcp_xid],eax
jne boucle_principale 

cmp byte[dhcp_phase],1
je client_dhcp_reponse_discover
cmp byte[dhcp_phase],5
je client_dhcp_reponse_request
jmp boucle_principale


;****************************
client_dhcp_reponse_discover:  ;on as reçu une offre, envoyons une requête

;enregistrement des info de la partie bootp
mov eax,[esi+dhcp_yiaddr]
mov ebx,[esi+dhcp_siaddr]
mov ecx,[esi+dhcp_giaddr]
mov [dhcp_adresse],eax
mov [dhcp_serveur],ebx
mov [dhcp_passerelle],ecx
mov dword[dhcp_masque],0FFFFFFh ;masque par défaut: 255.255.255.0


;test si on est sur du dhcp ou du bootp
cmp dword[esi+dhcp_options],063538263h
jne ok_dhcpbootp

;si ce n'est pas une offre dhcp,on abandonne
mov al,35h
call cherche_opt_dhcp
cmp ebx,0
je ok_dhcpbootp 
cmp byte[ebx+2],2
jne boucle_principale


;enregistrement de la partie dhcp
mov al,1
call cherche_opt_dhcp
cmp ebx,0
je @f
mov eax,[ebx+2]
mov [dhcp_masque],eax
@@:

mov al,3
call cherche_opt_dhcp
cmp ebx,0
je @f
mov eax,[ebx+2]
mov [dhcp_passerelle],eax
@@:


;************
envoie_dhcp_request:    ;envoie une demande dhcp request (pour demander ou confirmer une adresse)
mov byte[dhcp_phase],5
mov eax,12
int 61h
xor eax,ecx
xor eax,06D73B2E3h ;génère un numéros de séquence a partir du numéros de séquence du client et du compteur temp
mov [dhcp_id],eax

;prépare la trame bootp
mov esi,zt_decod+80h
mov byte[esi+dhcp_op],1
mov byte[esi+dhcp_htype],1
mov byte[esi+dhcp_hlen],6
mov byte[esi+dhcp_hops],0
mov dword[esi+dhcp_xid],eax
mov word[esi+dhcp_secs],0
mov word[esi+dhcp_flags],0
mov dword[esi+dhcp_ciaddr],0
mov dword[esi+dhcp_yiaddr],0
mov dword[esi+dhcp_siaddr],0
mov dword[esi+dhcp_giaddr],0
xor edx,edx
mov eax,[adresse_mac]
mov dx,[adresse_mac+4]
mov dword[esi+dhcp_chaddr],eax
mov dword[esi+dhcp_chaddr+4],edx
mov dword[esi+dhcp_chaddr+8],0
mov dword[esi+dhcp_chaddr+12],0
;efface sname et file
mov ebx,esi
mov ecx,dhcp_options-dhcp_sname
add ebx,dhcp_sname
@@:
mov byte[ebx],0
inc ebx
dec ecx
jnz @b


;ajoute les options dhcp
push esi
add esi,dhcp_options
mov dword[esi],063538263h   ;ajoute le double mot magique (voir RFC1497)
add esi,4

mov word[esi],0135h       ;ajoute l'option de requête dhcp
mov byte[esi+2],3         ;dhcp request
add esi,3 

mov word[esi],073Dh       ;ajoute l'option  ID du client
mov eax,[adresse_mac]
mov dx,[adresse_mac+4]
mov byte[esi+2],1
mov [esi+3],eax
mov [esi+7],dx
add esi,9 

mov word[esi],0432h     ;ajoute l'adresse demandé
mov eax,[dhcp_adresse]
mov [esi+2],eax
add esi,6

mov word[esi],0436h     ;ajoute l'ip serveur
mov eax,[dhcp_serveur]
mov [esi+2],eax
add esi,6

mov word[esi],0337h     ;ajoute les options demandé
mov byte[esi+2],1       ;masque
mov byte[esi+3],3       ;routeur
mov byte[esi+4],6       ;serveur dns
add esi,5

mov byte[esi],255        ;marque la fin des options 
inc esi
mov ecx,esi
pop esi
sub esi,8
sub ecx,esi
mov [taille_niv_sup],ecx


;remplit les données de l'en tête udp
mov ax,68
mov bx,67
xchg al,ah
xchg bl,bh
xchg cl,ch
mov [esi+udp_port_sour],ax
mov [esi+udp_port_dest],bx
mov [esi+udp_longueur],cx
mov word[esi+udp_cheksum],0
mov [offset_ip],esi 

;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],17
mov dword[adresse_ipv4_destination],0FFFFFFFFh
mov dword[adresse_ipv6_destination],0
mov dword[adresse_ipv6_destination+4],0
mov dword[adresse_ipv6_destination+8],0
mov dword[adresse_ipv6_destination+12],0
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+udp_cheksum],ax

call envoie_trame_ip
jmp reception_interne

;******************************
client_dhcp_reponse_request:
;enregistrement des info de la partie bootp
mov eax,[esi+dhcp_yiaddr]
mov ebx,[esi+dhcp_siaddr]
mov ecx,[esi+dhcp_giaddr]
mov [dhcp_adresse],eax
mov [dhcp_serveur],ebx
mov [dhcp_passerelle],ecx
mov dword[dhcp_masque],0FFFFFFh ;masque par défaut: 255.255.255.0

;test si on est sur du dhcp ou du bootp
cmp dword[esi+dhcp_options],063538263h
jne ok_dhcpbootp

;si ce n'est pas une ack dhcp,on abandonne
mov al,35h
call cherche_opt_dhcp
cmp ebx,0
je ok_dhcpbootp 
cmp byte[ebx+2],5
jne boucle_principale

;enregistrement de la partie dhcp
mov al,1
call cherche_opt_dhcp
cmp ebx,0
je @f
mov eax,[ebx+2]
mov [dhcp_masque],eax
@@:

mov al,3
call cherche_opt_dhcp
cmp ebx,0
je @f
mov eax,[ebx+2]
mov [dhcp_passerelle],eax
@@:


mov al,58        ;temps pour la première relance
call cherche_opt_dhcp
cmp ebx,0
je @f
mov eax,[ebx+2]
mov ecx,400
bswap eax
mul ecx
add eax,[cptsf]
adc edx,[cptsf+4]
mov [dhcp_t1],eax
mov [dhcp_t1+4],edx
@@:

mov al,59       ;temps pour la seconde relance
call cherche_opt_dhcp
cmp ebx,0
je @f
mov eax,[ebx+2]
mov ecx,400
bswap eax
mul ecx
add eax,[cptsf]
adc edx,[cptsf+4]
mov [dhcp_t2],eax
mov [dhcp_t2+4],edx
@@:

mov al,51       ;temps d'attribution de l'adresse
call cherche_opt_dhcp
cmp ebx,0
je @f
mov eax,[ebx+2]
mov ecx,400
bswap eax
mul ecx
add eax,[cptsf]
adc edx,[cptsf+4]
mov [dhcp_t3],eax
mov [dhcp_t3+4],edx
@@:

ok_dhcpbootp:   ;valide la configuration reçu
mov eax,[dhcp_adresse]
mov ebx,[dhcp_passerelle]
mov ecx,[dhcp_masque]
mov [adresse_ipv4],eax
mov [passerelle_ipv4],ebx
mov [masque_ipv4],ecx
mov byte[dhcp_phase],10

mov ebx,[dhcp_demande]
cmp ebx,0
je boucle_principale
mov word[zt_decod],008Ah
mov al,5
mov ecx,8h
mov edi,0
mov esi,zt_decod
int 65h
mov dword[dhcp_demande],0
jmp boucle_principale




;**************************************************************************
;datagramme TCP
trame_tcp:
call chk_gen
cmp ax,0 
jne boucle_principale

;recherche si la connexion avec ce client/port as déjà été ouverte
mov esi,[offset_ip]
mov ax,[esi+tcp_port_dest]   
xchg al,ah
mov bx,[esi+tcp_port_sour]   
xchg bl,bh
mov edi,[ad_table_tcp]
mov ecx,[nb_table_tcp]
mov esi,[offset_ethernet]
mov dl,[esi]
and dl,0F0h
cmp dl,40h
jne trame_tcp_ipv6_verification1

trame_tcp_ipv4_verification1:         ;si c'est du ipv4
cmp [edi+cnx_port_serveur],ax
jne connex_tcp_ipv4_suivante
cmp [edi+cnx_port_client],bx
jne connex_tcp_ipv4_suivante
mov edx,[esi+ipv4_ip_sour]
cmp edx,[edi+cnx_adresse_ipv4_client]
je trame_tcp_ouverte
connex_tcp_ipv4_suivante:
add edi,64
dec ecx
jnz trame_tcp_ipv4_verification1
jmp test_tcp_syncro

trame_tcp_ipv6_verification1:         ;ou du ipv6
cmp [edi+cnx_port_serveur],ax
jne connex_tcp_ipv6_suivante
cmp [edi+cnx_port_client],bx
jne connex_tcp_ipv6_suivante
mov edx,[esi+ipv6_ip_sour]
cmp edx,[edi+cnx_adresse_ipv6_client]
jne connex_tcp_ipv6_suivante
mov edx,[esi+ipv6_ip_sour+4]
cmp edx,[edi+cnx_adresse_ipv6_client+4]
jne connex_tcp_ipv6_suivante
mov edx,[esi+ipv6_ip_sour+8]
cmp edx,[edi+cnx_adresse_ipv6_client+8]
jne connex_tcp_ipv6_suivante
mov edx,[esi+ipv6_ip_sour+12]
cmp edx,[edi+cnx_adresse_ipv6_client+12]
je trame_tcp_ouverte
connex_tcp_ipv6_suivante:
add edi,64
dec ecx
jnz trame_tcp_ipv6_verification1


test_tcp_syncro:          ;test si la trame est une trame de synchro
mov esi,[offset_ip]
test word[esi+tcp_flag],00200h
jz boucle_principale


;si oui test si il y as la possibilité de créer une nouvelle connexion
mov esi,[offset_ip]
mov ax,[esi+tcp_port_dest]   
xchg al,ah
mov edi,[ad_table_tcp]
mov ecx,[nb_table_tcp]

trame_tcp_verification2:
cmp [edi+cnx_port_serveur],ax
jne connex_tcp_suivante
cmp byte[edi+cnx_etat],0
jne connex_tcp_suivante
cmp word[edi+cnx_nbmax],0
jne cree_cnx_tcp

connex_tcp_suivante:
add edi,64
dec ecx
jnz trame_tcp_verification2
jmp boucle_principale



;crée l'entrée dans la liste des connexion TCP
cree_cnx_tcp:
dec word[edi+cnx_nbmax] ;décrémente nb connexion possible
mov bx,[edi+cnx_id]    ;récupère id de la tache associé au port
mov edx,[edi+cnx_tozt]
mov edi,[ad_table_tcp]
mov ecx,[nb_table_tcp]

boucle_cree_cnx_tcp:         ;cherche descripteur vide
cmp word[edi+cnx_port_serveur],0
je suite_cree_cnx_tcp
add edi,64
dec ecx
jnz boucle_cree_cnx_tcp
jmp boucle_principale

suite_cree_cnx_tcp:        
push ebx
push edi
mov al,0          ;crée nouveau canal de communication
mov ecx,64
mov esi,edx
mov edi,edx
mov edx,0
int 65h
pop edi
pop edx
cmp eax,0
jne boucle_principale 


;remplit le descripteur de canal
push edx
push edi
mov word[tempo],0088h
mov dword[tempo+2],0
mov dword[tempo+6],0

mov esi,[offset_ip]
mov ax,[esi+tcp_port_sour]
xchg al,ah
mov [tempo+0Ah],ax

mov esi,[offset_ethernet]
mov dl,[esi]
and dl,0F0h
cmp dl,40h
jne remplissage_descr_canal_tcp_ipv6

mov eax,[esi+ipv4_ip_sour]
mov [tempo+0Ch],eax
mov dword[tempo+10h],0
mov dword[tempo+14h],0
mov dword[tempo+18h],0
mov dword[tempo+1Ch],0
jmp fin_remplissage_descr_canal_tcp

remplissage_descr_canal_tcp_ipv6:
mov dword[tempo+0Ch],0
mov eax,[esi+ipv6_ip_sour]
mov edx,[esi+ipv6_ip_sour+4]
mov [tempo+10h],eax
mov [tempo+14h],edx
mov eax,[esi+ipv6_ip_sour+8]
mov edx,[esi+ipv6_ip_sour+12]
mov [tempo+18h],eax
mov [tempo+1Ch],edx

fin_remplissage_descr_canal_tcp:
mov al,5
mov ecx,64
mov edi,0
mov esi,tempo
int 65h
pop edi
pop edx

;remplit le descripteur de port tcp
mov [edi+cnx_adresse_com],ebx

mov word[edi+cnx_etat],2  ;connexion entrante en phase de synchro
mov [edi+cnx_id],dx
mov word[edi+cnx_nbmax],0


mov esi,[offset_ip]
mov ax,[esi+tcp_port_dest]
mov dx,[esi+tcp_port_sour]
xchg al,ah
xchg dl,dh
mov [edi+cnx_port_serveur],ax 
mov [edi+cnx_port_client],dx


mov ecx,[esi+tcp_seq]
bswap ecx
inc ecx
mov [edi+cnx_seq_client_attendue],ecx  ;récupère le numéros de séquence et l'incrémente

mov eax,12
int 61h
xor ecx,eax
and ecx,0FFFFh ;génère un numéros de séquence a partir du numéros de séquence du client et du compteur temp
inc ecx
mov [edi+cnx_seq_serveur_suivante],ecx   

xor eax,eax
mov ax,[esi+tcp_fenetre]
xchg al,ah
add ecx,eax
mov [edi+cnx_seq_serveur_max],ecx   ;calcul la fenêtre d'emission max

mov esi,[offset_ethernet]
mov dl,[esi]
and dl,0F0h
cmp dl,40h
jne cree_cnx_tcp_ipv6

mov eax,[esi+ipv4_ip_sour]
mov [edi+cnx_adresse_ipv4_client],eax
mov dword[edi+cnx_adresse_ipv6_client],0
mov dword[edi+cnx_adresse_ipv6_client+4],0
mov dword[edi+cnx_adresse_ipv6_client+8],0
mov dword[edi+cnx_adresse_ipv6_client+12],0
jmp envoie_reponse_syncro

cree_cnx_tcp_ipv6:
mov dword[edi+cnx_adresse_ipv4_client],0
mov eax,[esi+ipv6_ip_sour]
mov edx,[esi+ipv6_ip_sour+4]
mov [edi+cnx_adresse_ipv6_client],eax
mov [edi+cnx_adresse_ipv6_client+4],edx
mov eax,[esi+ipv6_ip_sour+8]
mov edx,[esi+ipv6_ip_sour+12]
mov [edi+cnx_adresse_ipv6_client+8],eax
mov [edi+cnx_adresse_ipv6_client+12],edx



;envoie la réponse a la trame de synchro
envoie_reponse_syncro:

;créer la trame TCP
mov esi,zt_decod+64
mov [offset_ip],esi 

mov ax,[edi+cnx_port_serveur]  ;port
mov bx,[edi+cnx_port_client]
xchg al,ah
xchg bl,bh
mov [esi+tcp_port_sour],ax
mov [esi+tcp_port_dest],bx

mov eax,[edi+cnx_seq_serveur_suivante]
mov ebx,[edi+cnx_seq_client_attendue]
dec eax
bswap eax
bswap ebx
mov [esi+tcp_seq],eax
mov [esi+tcp_ack],ebx

mov word[esi+tcp_flag],1250h   ;SYN et ACK a 1 + en-tête de 5dword

mov word[esi+tcp_fenetre],0040h ;fenêtre d'envoie 16Ko
mov word[esi+tcp_cheksum],0
mov word[esi+tcp_pointeur],0

mov dword[taille_niv_sup],20

mov eax,[edi+cnx_adresse_ipv4_client]
mov [adresse_ipv4_destination],eax
mov eax,[edi+cnx_adresse_ipv6_client]
mov [adresse_ipv6_destination],eax
mov eax,[edi+cnx_adresse_ipv4_client+4]
mov [adresse_ipv6_destination+4],eax
mov eax,[edi+cnx_adresse_ipv4_client+8]
mov [adresse_ipv6_destination+8],eax
mov eax,[edi+cnx_adresse_ipv4_client+12]
mov [adresse_ipv6_destination+12],eax


;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],06
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+tcp_cheksum],ax

call envoie_trame_ip
jmp reception_interne




;*****************************************************************
trame_tcp_ouverte:
mov esi,[offset_ip]

;test si la trame contient un ack valide
test word[esi+tcp_flag],1000h  ;test si ACK=1
jz trame_tcp_ouverte_sansack

;met a jour la fenetre d'emission disponible
xor ecx,ecx
mov eax,[esi+tcp_ack]
mov cx,[esi+tcp_fenetre]
bswap eax
xchg cl,ch
add ecx,eax
mov [edi+cnx_seq_serveur_max],ecx


;cherche dans la liste des trame, celles qui peuvent être acquitté par ce numéros d'ack
mov ebx,[ad_zone_attente]
mov ecx,[nb_zone_attente]
boucle_ack_trame_tcp:
cmp byte[ebx+zone_attente_type],4
jne ignore_ack_trame_tcp
cmp [ebx+zone_attente_tcp_descr],edi
jne ignore_ack_trame_tcp

mov edx,eax
sub edx,[ebx+zone_attente_tcp_ack_attendu]
jz ok_ack_trame_tcp
test edx,80000000h
jnz ignore_ack_trame_tcp

ok_ack_trame_tcp:
mov byte[ebx+zone_attente_type],0

ignore_ack_trame_tcp:
add ebx,2048
dec ecx
jnz boucle_ack_trame_tcp

trame_tcp_ouverte_sansack:


test word[esi+tcp_flag],0400h  ;test si c'est une demande de reset
jnz trame_tcp_demande_reset


;cherche dans quel mode se trouve la connexion
cmp byte[edi+cnx_etat],3
je trame_tcp_connexion_etablit
cmp byte[edi+cnx_etat],2
je trame_tcp_syncronisation_entrante
cmp byte[edi+cnx_etat],1
je trame_tcp_syncronisation_sortante
cmp byte[edi+cnx_etat],4
je trame_tcp_arret_serveur_attente_ack
cmp byte[edi+cnx_etat],5
je trame_tcp_arret_serveur_attente_fin
cmp byte[edi+cnx_etat],6
je trame_tcp_arret_client_attente_ack
cmp byte[edi+cnx_etat],7
je trame_tcp_arret_client_attente_ack
jmp verifie_trame_attente



;*************************************************
trame_tcp_arret_serveur_attente_ack:    ;connexion en phase d'arret (initiative serveur) attend ack par client
test dword[esi+tcp_flag],1000h  ;ack=1
jz verifie_trame_attente
mov eax,[esi+tcp_ack]
bswap eax
cmp eax,[edi+cnx_seq_serveur_suivante]
jne verifie_trame_attente
mov byte[edi+cnx_etat],5
;jmp verifie_trame_attente

;***************************************************
trame_tcp_arret_serveur_attente_fin:       ;connexion en phase d'arret (initiative serveur) attend fin par client
test dword[esi+tcp_flag],0100h  ;fin=1
jz verifie_trame_attente
inc dword[edi+cnx_seq_client_attendue]


;envoie l'ACK de Réponse
mov esi,zt_decod+64
mov [offset_ip],esi 
mov dword[taille_niv_sup],20

mov ax,[edi+cnx_port_serveur]  ;port
mov bx,[edi+cnx_port_client]
xchg al,ah
xchg bl,bh
mov [esi+tcp_port_sour],ax
mov [esi+tcp_port_dest],bx

mov eax,[edi+cnx_seq_serveur_suivante]
mov ebx,[edi+cnx_seq_client_attendue]
bswap eax
bswap ebx
mov [esi+tcp_seq],eax
mov [esi+tcp_ack],ebx

mov word[esi+tcp_flag],1050h   ;ACK + en-tête de 5dword 

mov word[esi+tcp_fenetre],0040h ;fenetre d'envoie 16Ko
mov word[esi+tcp_cheksum],0
mov word[esi+tcp_pointeur],0

mov eax,[edi+cnx_adresse_ipv4_client]
mov [adresse_ipv4_destination],eax
mov eax,[edi+cnx_adresse_ipv6_client]
mov [adresse_ipv6_destination],eax
mov eax,[edi+cnx_adresse_ipv4_client+4]
mov [adresse_ipv6_destination+4],eax
mov eax,[edi+cnx_adresse_ipv4_client+8]
mov [adresse_ipv6_destination+8],eax
mov eax,[edi+cnx_adresse_ipv4_client+12]
mov [adresse_ipv6_destination+12],eax

mov dword[edi],0  ;effacement descripteur
mov dword[edi+4],0
mov dword[edi+8],0
mov dword[edi+12],0
mov dword[edi+16],0
mov dword[edi+20],0
mov dword[edi+24],0
mov dword[edi+28],0
mov dword[edi+32],0
mov dword[edi+36],0
mov dword[edi+40],0
mov dword[edi+44],0
mov dword[edi+48],0
mov dword[edi+52],0
mov dword[edi+56],0
mov dword[edi+60],0

;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],06
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+tcp_cheksum],ax

call envoie_trame_ip

;call sauvegarde_trame_tcp    ;sauvegarde trame pour réexpédition

jmp reception_interne

;***********************************************
trame_tcp_arret_client_attente_ack:     ;connexion en phase d'arret (initiative client) attente ack par client
test dword[esi+tcp_flag],1000h  ;ack=1
jz verifie_trame_attente
mov eax,[esi+tcp_ack]
bswap eax
cmp eax,[edi+cnx_seq_serveur_suivante]
jne verifie_trame_attente

mov dword[edi],0        ;effacement descripteur
mov dword[edi+4],0
mov dword[edi+8],0
mov dword[edi+12],0
mov dword[edi+16],0
mov dword[edi+20],0
mov dword[edi+24],0
mov dword[edi+28],0
mov dword[edi+32],0
mov dword[edi+36],0
mov dword[edi+40],0
mov dword[edi+44],0
mov dword[edi+48],0
mov dword[edi+52],0
mov dword[edi+56],0
mov dword[edi+60],0
jmp verifie_trame_attente


;***************************************************************
trame_tcp_syncronisation_sortante:
mov ax,[esi+tcp_flag]
and ax,0FF00h
cmp ax,1200h     ;test si c'est un SYN+ACK
jne verifie_trame_attente

mov byte[edi+cnx_etat],3   ;si oui passe la CNX en mode établie

trame_tcp_maj_num_seq: ;enregistre la valeur de la syncro distante
mov eax,[esi+tcp_seq]
bswap eax
inc eax
mov [edi+cnx_seq_client_attendue],eax  

;envoie l'ACK de Réponse
mov esi,zt_decod+64
mov [offset_ip],esi 
mov dword[taille_niv_sup],20

mov ax,[edi+cnx_port_serveur]  ;port
mov bx,[edi+cnx_port_client]
xchg al,ah
xchg bl,bh
mov [esi+tcp_port_sour],ax
mov [esi+tcp_port_dest],bx

mov eax,[edi+cnx_seq_serveur_suivante]
mov ebx,[edi+cnx_seq_client_attendue]
bswap eax
bswap ebx
mov [esi+tcp_seq],eax
mov [esi+tcp_ack],ebx

mov word[esi+tcp_flag],1050h   ;ACK + en-tête de 5dword 

mov word[esi+tcp_fenetre],0040h ;fenetre d'envoie 16Ko
mov word[esi+tcp_cheksum],0
mov word[esi+tcp_pointeur],0

mov eax,[edi+cnx_adresse_ipv4_client]
mov [adresse_ipv4_destination],eax
mov eax,[edi+cnx_adresse_ipv6_client]
mov [adresse_ipv6_destination],eax
mov eax,[edi+cnx_adresse_ipv4_client+4]
mov [adresse_ipv6_destination+4],eax
mov eax,[edi+cnx_adresse_ipv4_client+8]
mov [adresse_ipv6_destination+8],eax
mov eax,[edi+cnx_adresse_ipv4_client+12]
mov [adresse_ipv6_destination+12],eax

;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],06
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+tcp_cheksum],ax

call envoie_trame_ip
jmp reception_interne




;***************************************
trame_tcp_syncronisation_entrante:
mov ax,[esi+tcp_flag]
and ax,0FF00h
cmp ax,0200h
je envoie_reponse_syncro ;si le système redemande une synchro on lui renvoie la trame syn+ack
cmp ax,1000h
jne verifie_trame_attente
mov eax,[esi+tcp_ack]   ;si le système répond a l'ack final on passe en mode de transmission établit
bswap eax
cmp eax,[edi+cnx_seq_serveur_suivante] 
jne verifie_trame_attente
mov byte[edi+cnx_etat],3
jmp verifie_trame_attente




;***********************************************
trame_tcp_demande_reset:
cmp byte[edi+cnx_etat],4   ;si on est dans une phase d'arret il y as pas besoin de d'incrémenter et d'effacer le canal
je trame_tcp_demande_suite
cmp byte[edi+cnx_etat],5
je trame_tcp_demande_suite
cmp byte[edi+cnx_etat],6
je trame_tcp_demande_suite
cmp byte[edi+cnx_etat],7
je trame_tcp_demande_suite

mov ax,[edi+cnx_port_serveur]  ;incrémente le nombre de connexion TCP autorisé
call inc_nb_cnx_tcp
mov eax,1                      ;efface le canal de communication
mov ebx,[edi+cnx_adresse_com]
int 65h

trame_tcp_demande_suite:
mov dword[edi],0  ;effacement descripteur
mov dword[edi+4],0
mov dword[edi+8],0
mov dword[edi+12],0
mov dword[edi+16],0
mov dword[edi+20],0
mov dword[edi+24],0
mov dword[edi+28],0
mov dword[edi+32],0
mov dword[edi+36],0
mov dword[edi+40],0
mov dword[edi+44],0
mov dword[edi+48],0
mov dword[edi+52],0
mov dword[edi+56],0
mov dword[edi+60],0
jmp verifie_trame_attente





;*****************************************
trame_tcp_connexion_etablit: ;vérifie la validité du numéros de séquence
mov eax,[esi+tcp_seq]
bswap eax
cmp [edi+cnx_seq_client_attendue],eax
je trame_tcp_seq_ok
ja trame_tcp_aquitte    ;si on l'as déjà reçu on la ré acquitte (parce que l'ack n'as pas dût être reçu par le destinataire)

;sauvegarde la trame reçu en avance
mov al,5
mov esi,zt_decod
mov ecx,[to_decod]
call trame_attente
cmp esi,0
je verifie_trame_attente
mov ecx,400
mov edx,0
add ecx,[cptsf]
adc edx,0
mov [esi+zone_attente_tcp_seq_trame],eax
mov [esi+zone_attente_tcp_compteur],ecx      ;valeur compteur maximum pour conserver la trame
mov [esi+zone_attente_tcp_compteur+4],edx
mov [esi+zone_attente_tcp_descr],edi        ;adresse du descripteur de la connexion
jmp verifie_trame_attente


trame_tcp_seq_ok:
;calcule la taille des données reçu et offset des données
mov ax,[esi+tcp_flag]
and eax,00F0h
shr eax,2 ;div par  16 mul par 4
mov ecx,[taille_niv_sup]
sub ecx,eax
add [edi+cnx_seq_client_attendue],ecx
cmp ecx,0
je @f

;envoie les données a l'application
push esi
add esi,eax
mov al,7
mov ebx,[edi+cnx_adresse_com]
int 65h
pop esi

;aquitte les données reçu
trame_tcp_aquitte:
call envoie_ack_tcp
jmp reception_interne



@@:
mov ax,[esi+tcp_flag]
test ax,0100h  ;test si c'est une demande de fin de connexion
jnz trame_tcp_demande_fin

mov ax,[esi+tcp_flag]
test ax,0200h ;test si c'est une demande de synchro et met a jour
jnz trame_tcp_maj_num_seq

jmp verifie_trame_attente


;*****************************
trame_tcp_demande_fin:
mov byte[edi+cnx_etat],6
inc dword [edi+cnx_seq_client_attendue]

mov al,1          ;supprime le canal de com
mov ebx,[edi+cnx_adresse_com]
int 65h

mov ax,[edi+cnx_port_serveur]  ;incrémente le nombre de connexion TCP autorisé
call inc_nb_cnx_tcp


mov esi,zt_decod+64
mov [offset_ip],esi 

mov ax,[edi+cnx_port_serveur]  ;port
mov bx,[edi+cnx_port_client]
xchg al,ah
xchg bl,bh
mov [esi+tcp_port_sour],ax
mov [esi+tcp_port_dest],bx

mov eax,[edi+cnx_seq_serveur_suivante]
mov ebx,[edi+cnx_seq_client_attendue]
bswap eax
bswap ebx
mov [esi+tcp_seq],eax
mov [esi+tcp_ack],ebx


mov word[esi+tcp_flag],1050h   ;ACK a 1 + en-tête de 5dword

mov word[esi+tcp_fenetre],0040h ;fenêtre d'envoie 16Ko
mov word[esi+tcp_cheksum],0
mov word[esi+tcp_pointeur],0

mov dword[taille_niv_sup],20

mov eax,[edi+cnx_adresse_ipv4_client]
mov [adresse_ipv4_destination],eax
mov eax,[edi+cnx_adresse_ipv6_client]
mov [adresse_ipv6_destination],eax
mov eax,[edi+cnx_adresse_ipv4_client+4]
mov [adresse_ipv6_destination+4],eax
mov eax,[edi+cnx_adresse_ipv4_client+8]
mov [adresse_ipv6_destination+8],eax
mov eax,[edi+cnx_adresse_ipv4_client+12]
mov [adresse_ipv6_destination+12],eax


;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],06
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+tcp_cheksum],ax

call envoie_trame_ip
call sauvegarde_trame_tcp

jmp reception_interne 




;*********************************************************************************************************************************************
;*********************************************************************************************************************************************
verifie_trame_attente:              ;verifie les trame en attentes

;rexpédie les trame TCP ayant dépassé le délais
mov ebx,[ad_zone_attente]
mov ecx,[nb_zone_attente]

boucle_rexp_trame_nack:
cmp byte[ebx+zone_attente_type],4
je traite_trame_attente_ack
cmp byte[ebx+zone_attente_type],5
je traite_trame_attente_avance

ignore_rexp_trame_nack:
add ebx,2048
dec ecx
jnz boucle_rexp_trame_nack
jmp verification_connexion_active




;*****************
traite_trame_attente_avance:  ;traite trame tcp reçu avec n°de séquence en avance
mov edx,ebx
add edx,zone_attente_tcp_compteur
call comp64
jb traite_trame_attente_avance_efface   ;si temp dépassé efface la trame

mov edi,[ebx+zone_attente_tcp_descr]
mov eax,[edi+cnx_seq_client_attendue]
cmp eax,[ebx+zone_attente_tcp_seq_trame]
jne ignore_rexp_trame_nack     ;si numéros de séquence toujours pas valide ignore la trame

xor ecx,ecx
mov cx,[ebx+zone_attente_taille]
mov esi,ebx
add esi,zone_attente_trame
mov edi,zt_decod
mov [to_decod],ecx
cld
rep movsb
mov byte[ebx+zone_attente_type],0 ;effacement de la trame
jmp reception_interne


traite_trame_attente_avance_efface:
mov byte[ebx+zone_attente_type],0 ;effacement de la trame
jmp ignore_rexp_trame_nack


;******************************
traite_trame_attente_ack:         ;traite trame tcp en attente d'ack
mov edx,ebx
add edx,zone_attente_tcp_compteur
call comp64
ja ignore_rexp_trame_nack

pushad
mov eax,[ebx+zone_attente_tcp_delais]
mov edx,0
add eax,[cptsf]
adc edx,0
mov [ebx+zone_attente_tcp_compteur],eax
mov [ebx+zone_attente_tcp_compteur+4],edx
dec dword[ebx+zone_attente_tcp_nb]
jz traite_trame_attente_ack_efface

mov esi,ebx
add esi,zone_attente_trame
xor ecx,ecx
mov cx,[ebx+zone_attente_taille]
call envoie_trame_ethernet
popad
jmp ignore_rexp_trame_nack




traite_trame_attente_ack_efface:         ;dépassement du nombre d'envoie de trame
mov byte[ebx+zone_attente_type],0 ;effacement de la trame
mov edi,[ebx+zone_attente_tcp_descr]

;envoie d'une trame RST
mov esi,zt_decod+64
mov [offset_ip],esi 
mov dword[taille_niv_sup],20

mov ax,[edi+cnx_port_serveur]  ;port
mov bx,[edi+cnx_port_client]
xchg al,ah
xchg bl,bh
mov [esi+tcp_port_sour],ax
mov [esi+tcp_port_dest],bx

mov eax,[edi+cnx_seq_serveur_suivante]
mov ebx,[edi+cnx_seq_client_attendue]
bswap eax
bswap ebx
mov [esi+tcp_seq],eax
mov [esi+tcp_ack],ebx

mov word[esi+tcp_flag],0450h   ;RST à 1 + en-tête de 5dword
mov word[esi+tcp_cheksum],0

mov word[esi+tcp_fenetre],0040h ;fenêtre d'envoie 16Ko
mov word[esi+tcp_cheksum],0
mov word[esi+tcp_pointeur],0

mov eax,[edi+cnx_adresse_ipv4_client]
mov [adresse_ipv4_destination],eax
mov eax,[edi+cnx_adresse_ipv6_client]
mov [adresse_ipv6_destination],eax
mov eax,[edi+cnx_adresse_ipv4_client+4]
mov [adresse_ipv6_destination+4],eax
mov eax,[edi+cnx_adresse_ipv4_client+8]
mov [adresse_ipv6_destination+8],eax
mov eax,[edi+cnx_adresse_ipv4_client+12]
mov [adresse_ipv6_destination+12],eax

;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],06
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+tcp_cheksum],ax

call envoie_trame_ip


;fermeture du canal de connexion
mov ebx,[edi+cnx_adresse_com]
mov al,1
int 65h


;effacement du descripteur de connexion
mov ax,[edi+cnx_port_serveur]
call inc_nb_cnx_tcp 
mov dword[edi],0
mov dword[edi+4],0
mov dword[edi+8],0
mov dword[edi+12],0
mov dword[edi+16],0
mov dword[edi+20],0
mov dword[edi+24],0
mov dword[edi+28],0
mov dword[edi+32],0
mov dword[edi+36],0
mov dword[edi+40],0
mov dword[edi+44],0
mov dword[edi+48],0
mov dword[edi+52],0
mov dword[edi+56],0
mov dword[edi+60],0

popad
jmp reception_interne





;**************************************************************************************************************************
;**************************************************************************************************************************
verification_connexion_active:   ;vérifie que tout ce qui est enregistré dans les connexion est bien encore actif 



;********************************
;verifie la connexion directe
mov ebx,[tout_ethernet]
cmp ebx,0FFFFFFFFh
je ignore_envoie_directe
mov al,10
int 65h
cmp eax,0
jne supprime_envoie_directe
cmp ebp,0
je ignore_envoie_directe

mov al,6
mov ebx,[tout_ethernet]
mov edi,zt_decod
mov ecx,1500
int 65h

mov esi,zt_decod
call envoie_trame_ethernet
jmp reception_interne

supprime_envoie_directe:
mov dword[tout_ethernet],0FFFFFFFFh
ignore_envoie_directe:



;********************************
;verifie les connexion avec adresse virtuelles
mov esi,table_ethernet_virtuel
mov ecx,8
verification_connexion_active_cartevirtuelles:
mov ebx,[esi+6]
cmp ebx,0FFFFFFFFh
je ignore_verification_connexion_active_cartevirtuelles
mov al,10
push ecx
push esi
int 65h
pop esi
pop ecx
cmp eax,0
jne supprime_verification_connexion_active_cartevirtuelles
cmp ebp,0
je ignore_verification_connexion_active_cartevirtuelles

push ecx
mov al,6
mov ebx,[esi+6]
mov edi,zt_decod
mov ecx,1500
int 65h

mov eax,[esi]
mov dx,[esi+4]
mov [zt_decod+eth_mac_sour],eax
mov [zt_decod+eth_mac_sour+4],dx

push esi
mov esi,zt_decod
call envoie_trame_ethernet
pop esi
pop ecx
jmp reception_interne

supprime_verification_connexion_active_cartevirtuelles:
mov dword[esi+6],0FFFFFFFFh

ignore_verification_connexion_active_cartevirtuelles:
add esi,10
dec ecx
jnz verification_connexion_active_cartevirtuelles



;********************************
;verifie les connexion avec les autres protocoles ethernet
mov esi,table_ethernet_protocole
mov ecx,16
verification_connexion_active_autresprotocole:
mov ebx,[esi+2]
cmp ebx,0FFFFFFFFh
je ignore_verification_connexion_active_autresprotocole
mov al,10
push ecx
push esi
int 65h
pop esi
pop ecx
cmp eax,0
jne supprime_verification_connexion_active_autresprotocole
cmp ebp,0
je ignore_verification_connexion_active_autresprotocole

push ecx
mov al,6
mov ebx,[esi+2]
mov edi,zt_decod
mov ecx,1500
int 65h

mov ax,[esi]
xchg al,ah
mov [zt_decod+eth_type1],ax

push esi
mov esi,zt_decod
call envoie_trame_ethernet
pop esi
pop ecx
jmp reception_interne

supprime_verification_connexion_active_autresprotocole:
mov dword[esi+2],0FFFFFFFFh

ignore_verification_connexion_active_autresprotocole:
add esi,6
dec ecx
jnz verification_connexion_active_autresprotocole



;****************************************************
;verification des connexions udp
mov esi,[ad_table_udp]
mov ecx,[nb_table_udp]
verification_connexion_active_udp:
cmp word[esi+cnx_port_serveur],0
je ignore_verification_connexion_active_udp
mov ebx,[esi+cnx_adresse_com]
mov al,10
push ecx
push esi
int 65h
pop esi
pop ecx

cmp eax,0
jne efface_verification_connexion_active_udp 
cmp bx,[esi+cnx_id]
jne efface_verification_connexion_active_udp 
cmp ebp,0
je ignore_verification_connexion_active_udp

;***************************
;envoie la trame udp
pushad
push esi
mov al,6
mov ebx,[esi+cnx_adresse_com]
mov edi,zt_decod+80h
mov ecx,1500
int 65h        ;lit les données avec une place réservé pour les en-tête
pop edi

;prépare les donnée de la trame
sub ecx,14       ;-22+8     ;taille des données
mov esi,zt_decod+80h
mov bx,[esi]                ;port de destination
mov eax,[esi+2]
mov [adresse_ipv4_destination],eax

mov eax,[esi+6]
mov [adresse_ipv6_destination],eax
mov eax,[esi+10]
mov [adresse_ipv6_destination+4],eax
mov eax,[esi+14]
mov [adresse_ipv6_destination+8],eax
mov eax,[esi+18]
mov [adresse_ipv6_destination+12],eax

mov ax,[edi+cnx_port_serveur]     ;port source

add esi,14    ;+22-8
mov [taille_niv_sup],ecx
mov [offset_ip],esi 

;remplit les données de l'en tête udp
xchg al,ah
xchg bl,bh
xchg cl,ch
mov [esi+udp_port_sour],ax
mov [esi+udp_port_dest],bx
mov [esi+udp_longueur],cx
mov word[esi+udp_cheksum],0


;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],17
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+udp_cheksum],ax

call envoie_trame_ip
popad
jmp reception_interne

efface_verification_connexion_active_udp:
mov dword[esi],0
mov dword[esi+4],0

ignore_verification_connexion_active_udp:
add esi,8
dec ecx
jnz verification_connexion_active_udp


;*******************************************************************************************************
;verification des connexions tcp
mov esi,[ad_table_tcp]
mov ecx,[nb_table_tcp]
verification_connexion_active_tcp:
cmp byte[esi+cnx_etat],6
je trame_tcp_demande_fin2
cmp word[esi+cnx_port_serveur],0
je ignore_verification_connexion_active_tcp
mov ebx,[esi+cnx_adresse_com]
mov al,10
push ecx
push esi
int 65h
pop esi
pop ecx
cmp eax,0
jne arret_connexion_tcp
cmp ebp,0
jne @f
cmp bx,[esi+cnx_id]
jne arret_connexion_tcp
jmp ignore_verification_connexion_active_tcp
@@:
mov eax,[esi+cnx_seq_serveur_max]
sub eax,[esi+cnx_seq_serveur_suivante]     ;eax=nombre max d'octet que l'on peut encore envoyer
jbe ignore_verification_connexion_active_tcp ;s'il est négatif ou nul on n'envoie rien



;**********************************************************************
;envoie la trame tcp
push esi
mov ebx,[esi+cnx_adresse_com]
mov edi,zt_decod+84
mov ecx,[taille_trame_max]
sub ecx,102   ;correspond au nombre d'octet max d'entête a ajouter
cmp ecx,eax
jbe ok_max_envoie_tcp
mov ecx,eax
ok_max_envoie_tcp:
mov al,6
int 65h        ;lit les données avec une place réservé pour les en-tête
pop edi

;pushad
;mov edx,zt_decod+84
;add ecx,edx
;mov byte[ecx],0
;mov al,6
;int 61h
;popad

mov esi,zt_decod+64
mov [offset_ip],esi 
mov dword[taille_niv_sup],20
add [taille_niv_sup],ecx

mov ax,[edi+cnx_port_serveur]  ;port
mov bx,[edi+cnx_port_client]
xchg al,ah
xchg bl,bh
mov [esi+tcp_port_sour],ax
mov [esi+tcp_port_dest],bx

mov eax,[edi+cnx_seq_serveur_suivante]
add [edi+cnx_seq_serveur_suivante],ecx
mov ebx,[edi+cnx_seq_client_attendue]
bswap eax
bswap ebx
mov [esi+tcp_seq],eax
mov [esi+tcp_ack],ebx

mov word[esi+tcp_flag],1050h   ;ACK + en-tête de 5dword

mov word[esi+tcp_fenetre],0040h ;fenêtre d'envoie 16Ko
mov word[esi+tcp_cheksum],0
mov word[esi+tcp_pointeur],0


mov eax,[edi+cnx_adresse_ipv4_client]
mov [adresse_ipv4_destination],eax
mov eax,[edi+cnx_adresse_ipv6_client]
mov [adresse_ipv6_destination],eax
mov eax,[edi+cnx_adresse_ipv4_client+4]
mov [adresse_ipv6_destination+4],eax
mov eax,[edi+cnx_adresse_ipv4_client+8]
mov [adresse_ipv6_destination+8],eax
mov eax,[edi+cnx_adresse_ipv4_client+12]
mov [adresse_ipv6_destination+12],eax


;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],06
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+tcp_cheksum],ax

call envoie_trame_ip

call sauvegarde_trame_tcp    ;sauvegarde trame pour réexpédition
jmp reception_interne



;*************************************
trame_tcp_demande_fin2:     ;envoie la trame de fin au client
mov byte[esi+cnx_etat],7
mov edi,esi

mov esi,zt_decod+64
mov [offset_ip],esi 
mov dword[taille_niv_sup],20

mov ax,[edi+cnx_port_serveur]  ;port
mov bx,[edi+cnx_port_client]
xchg al,ah
xchg bl,bh
mov [esi+tcp_port_sour],ax
mov [esi+tcp_port_dest],bx

mov eax,[edi+cnx_seq_serveur_suivante]
mov ebx,[edi+cnx_seq_client_attendue]
bswap eax
bswap ebx
mov [esi+tcp_seq],eax
mov [esi+tcp_ack],ebx
inc dword[edi+cnx_seq_serveur_suivante]

mov word[esi+tcp_flag],1150h   ;FIN+ACK à 1 + en-tête de 5dword
mov word[esi+tcp_cheksum],0

mov word[esi+tcp_fenetre],0040h ;fenêtre d'envoie 16Ko
mov word[esi+tcp_cheksum],0
mov word[esi+tcp_pointeur],0

mov eax,[edi+cnx_adresse_ipv4_client]
mov [adresse_ipv4_destination],eax
mov eax,[edi+cnx_adresse_ipv6_client]
mov [adresse_ipv6_destination],eax
mov eax,[edi+cnx_adresse_ipv4_client+4]
mov [adresse_ipv6_destination+4],eax
mov eax,[edi+cnx_adresse_ipv4_client+8]
mov [adresse_ipv6_destination+8],eax
mov eax,[edi+cnx_adresse_ipv4_client+12]
mov [adresse_ipv6_destination+12],eax

;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],06
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+tcp_cheksum],ax

call envoie_trame_ip
call sauvegarde_trame_tcp

jmp reception_interne







;*************************************
arret_connexion_tcp:
cmp byte[esi+cnx_etat],0
je purge_verification_connexion_active_tcp
cmp byte[esi+cnx_etat],1
je efface_verification_connexion_active_tcp
cmp byte[esi+cnx_etat],2
je efface_verification_connexion_active_tcp
cmp byte[esi+cnx_etat],3
jne ignore_verification_connexion_active_tcp

changemode_verification_connexion_active_tcp:
call passe_cnx_mode4
mov ax,[esi+cnx_port_serveur]
call inc_nb_cnx_tcp
jmp ignore_verification_connexion_active_tcp

purge_verification_connexion_active_tcp:
mov ax,[esi+cnx_port_serveur]            ;efface le descripteur 
mov dword[esi],0
mov dword[esi+4],0
mov dword[esi+8],0
mov dword[esi+12],0
mov dword[esi+16],0
mov dword[esi+20],0
mov dword[esi+24],0
mov dword[esi+28],0
mov dword[esi+32],0
mov dword[esi+36],0
mov dword[esi+40],0
mov dword[esi+44],0
mov dword[esi+48],0
mov dword[esi+52],0
mov dword[esi+56],0
mov dword[esi+60],0

pushad                     ;et passe tout les connexion sur ce port en mode 4
mov edi,[ad_table_tcp]
mov ecx,[nb_table_tcp]
boucle_purge_connexion_active_tcp:
cmp ax,[esi+cnx_port_serveur] 
jne ignore_purge_connexion_active_tcp
call passe_cnx_mode4
ignore_purge_connexion_active_tcp:
add esi,64
dec ecx
jnz boucle_purge_connexion_active_tcp
popad
jmp ignore_verification_connexion_active_tcp



efface_verification_connexion_active_tcp:
mov ax,[esi+cnx_port_serveur]
call inc_nb_cnx_tcp
mov dword[esi],0
mov dword[esi+4],0
mov dword[esi+8],0
mov dword[esi+12],0
mov dword[esi+16],0
mov dword[esi+20],0
mov dword[esi+24],0
mov dword[esi+28],0
mov dword[esi+32],0
mov dword[esi+36],0
mov dword[esi+40],0
mov dword[esi+44],0
mov dword[esi+48],0
mov dword[esi+52],0
mov dword[esi+56],0
mov dword[esi+60],0



;******************************************
ignore_verification_connexion_active_tcp:
add esi,64
dec ecx
jnz verification_connexion_active_tcp










;****************************************************************************
;verification des messages icmp
mov esi,table_acces_icmp
mov ecx,8
verification_connexion_active_icmp:
mov ebx,[esi]
cmp ebx,0FFFFFFFFh
je ignore_verification_connexion_active_icmp
mov al,10
push ecx
push esi
int 65h
pop esi
pop ecx

cmp eax,0
jne efface_verification_connexion_active_icmp 
cmp ebp,0
je ignore_verification_connexion_active_icmp

;***************************
;envoie la trame icmp
pushad
mov al,6
mov ebx,[esi]
mov edi,zt_decod+80h
mov ecx,1500
int 65h        ;lit les données avec une place réservé pour les en-tête


;prépare les donnée de la trame
sub ecx,14       ;-22+8     ;taille des données
mov esi,zt_decod+80h
mov al,[esi]                ;ttl
mov [ttl_niv_sup],al

mov eax,[esi+2]
mov [adresse_ipv4_destination],eax

mov eax,[esi+6]
mov [adresse_ipv6_destination],eax
mov eax,[esi+10]
mov [adresse_ipv6_destination+4],eax
mov eax,[esi+14]
mov [adresse_ipv6_destination+8],eax
mov eax,[esi+18]
mov [adresse_ipv6_destination+12],eax


add esi,22
sub ecx,22
mov [taille_niv_sup],ecx
mov [offset_ip],esi 

;créer la partie en tête ip
mov byte[type_niv_sup],1
call cree_entete_ip

mov esi,[offset_ip]
mov dword[somme_pseudo_entete],0 ;on n'utilise pas le pseudo entête en ICMPv4
mov word[esi+icmp_cheksum],0
call chk_gen
mov [esi+icmp_cheksum],ax

call envoie_trame_ip
popad
jmp reception_interne

efface_verification_connexion_active_icmp:
mov dword[esi],0FFFFFFFFh

ignore_verification_connexion_active_icmp:
add esi,4
dec ecx
jnz verification_connexion_active_icmp




;**********************************************************************
;fin des étapes actives 
;int 62h
jmp boucle_principale




















;*************************************************************************************************************************
;*************************************************************************************************************************
envoie_trame_ip:                     ;adresse_ipv4_destination ou adresse_ipv6_destination devront contenir des information valide edi=descripteur de connexion
pushad
mov esi,[offset_ethernet]
sub esi,14


mov ax,[type_ip]
mov word[esi+eth_type1],ax


mov eax,[adresse_mac]
mov dx,[adresse_mac+4]
mov [esi+eth_mac_sour],eax
mov [esi+eth_mac_sour+4],dx

mov ecx,[offset_ip]
sub ecx,esi
add ecx,[taille_niv_sup]



;recherche dans la table ARP/NDS si il y as une correspondance entre l'adresse ip et l'adresse ethernet
cmp dword[adresse_ipv4_destination],0
je recherche_nds


recherche_table_arp:
mov eax,[adresse_ipv4]
cmp dword[adresse_ipv4_destination],0FFFFFFFFh
je adresse_broadcast 
cmp dword[adresse_ipv4_destination],0100007Fh
je adresse_localhost
cmp dword[adresse_ipv4_destination],eax
je adresse_localhost


push ecx
push esi
push edi
mov esi,[ad_table_arp_nds]
mov edi,[nb_table_arp_nds]

boucle_recherche_table_arp:
mov cl,32
mov eax,0FFFFFFFFh
sub cl,[esi+zone_arp_nds_masque_ipv4]
shl eax,cl     
bswap eax  ;eax=masque en binaire

mov edx,[esi+zone_arp_nds_adresse_ipv4]
and edx,eax
and eax,[adresse_ipv4_destination]
cmp eax,edx
je adresse_ethernet_trouve

add esi,32
dec edi
jnz boucle_recherche_table_arp


;test si l'adresse appartient au sous réseau
mov eax,[masque_ipv4] 
pop edi
pop esi
pop ecx

mov edx,[adresse_ipv4]
and edx,eax
and eax,[adresse_ipv4_destination]
cmp eax,edx
je envoie_req_arp 

;si pas de routeur de sous réseau trouvé, choisie le routeur par défault
mov eax,[passerelle_ipv4]
mov [adresse_ipv4_destination],eax
jmp recherche_table_arp


envoie_req_arp:
;si aucune correspondances n'as été trouvé on sauvegarde la trame
mov al,1
call trame_attente
mov eax,[adresse_ipv4_destination]
mov [esi+zone_attente_adresse_rech],eax
;???????????????????????????????????????????????????????????????????????????????????sauvegarde les info TCP aussi!
;mov [esi+zone_attente_tcp_descr],edi ;??????????????????????
mov ecx,[cptsf]
mov eax,[cptsf+4]
add ecx,400
adc eax,0
mov [esi+zone_attente_tcp_compteur],ecx
mov [esi+zone_attente_tcp_compteur],eax






;on enregistre que l'on recherche l'adresse
mov eax,[adresse_ipv4_destination]
mov esi,[ad_table_arp_nds]
mov ecx,[nb_table_arp_nds]
boucle_enregistre_req_arp:
cmp dword[esi+zone_arp_nds_adresse_ipv4],0
jne suite_enregistre_req_arp
cmp dword[esi+zone_arp_nds_adresse_ipv6],0
jne suite_enregistre_req_arp
cmp dword[esi+zone_arp_nds_adresse_ipv6+4],0
jne suite_enregistre_req_arp
cmp dword[esi+zone_arp_nds_adresse_ipv6+8],0
jne suite_enregistre_req_arp
cmp dword[esi+zone_arp_nds_adresse_ipv6+12],0
je vide_enregistre_req_arp

suite_enregistre_req_arp:
add esi,32
dec ecx
jnz boucle_enregistre_req_arp
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ plus de place dans la table arp-nds
popad
ret

vide_enregistre_req_arp:
mov[esi+zone_arp_nds_adresse_ipv4],eax 
mov dword[esi+zone_arp_nds_ethernet],0 
mov word[esi+zone_arp_nds_ethernet+4],0 



;et on génère une requete ARP pour connaitre l'adresse
mov esi,zt_decod
mov eax,[adresse_mac]
mov dx,[adresse_mac+4]
mov ebx,[adresse_ipv4_destination]
mov ecx,[adresse_ipv4]

mov dword[esi+eth_mac_dest],0FFFFFFFFh
mov word[esi+eth_mac_dest+4],0FFFFh
mov [esi+eth_mac_sour],eax
mov [esi+eth_mac_sour+4],dx
mov word[esi+eth_type1],0608h
add esi,14
mov word[esi+arp_netype],0100h     
mov word[esi+arp_protype],0008h     
mov byte[esi+arp_lg_mac],6      
mov byte[esi+arp_lg_ip],4       
mov word[esi+arp_op],0100h         
mov [esi+arp_mac_sour],eax    
mov [esi+arp_mac_sour+4],dx
mov [esi+arp_ip_sour],ecx     
mov dword[esi+arp_mac_dest],0    
mov word[esi+arp_mac_dest+4],0
mov [esi+arp_ip_dest],ebx     

mov esi,zt_decod
mov ecx,14+28         ;entete ethernet + trame arp
call envoie_trame_ethernet
popad
ret



;************************************
recherche_nds:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
mov dword[esi+eth_mac_dest],0FFFFFFFFh ;en broadcast avant de pouvoir traiter les determination arp
mov word[esi+eth_mac_dest+4],0FFFFh
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
popad
ret



;**************************************
adresse_broadcast:
mov dword[esi+eth_mac_dest],0FFFFFFFFh ;adresse broadcast 
mov word[esi+eth_mac_dest+4],0FFFFh
call envoie_trame_ethernet
popad
ret

;**************************************
adresse_localhost:
mov eax,[adresse_mac]
mov dx,[adresse_mac+4]
mov dword[esi+eth_mac_dest],eax
mov word[esi+eth_mac_dest+4],dx
call envoie_trame_ethernet
popad
ret

;**************************************
adresse_ethernet_trouve:
mov eax,[esi+zone_arp_nds_ethernet]
mov dx,[esi+zone_arp_nds_ethernet+4]
pop edi
pop esi
pop ecx
mov dword[esi+eth_mac_dest],eax
mov word[esi+eth_mac_dest+4],dx
call envoie_trame_ethernet
popad
ret


;********************************************************************************************************************************************
envoie_trame_ethernet:
pushad
;place la trame dans la zone de décodage
cmp esi,zt_decod
je @f
push ecx
mov edi,zt_decod
cld 
rep movsb
pop ecx
@@:
mov edi,zt_decod
add edi,ecx

cmp ecx,[taille_trame_max]               
ja trame_ethernet_tropgrande

;vérifie que la trame n'est pas trop petite et éventuellement rajoute un bourrage
xor eax,eax
@@:
cmp ecx,64                     
jae @f
stosb
inc ecx
jmp @b
@@:

;test si la trame fait partie des adresses locales?????????????????????????????????????????????????????????????????????
mov [to_decod],ecx ;.........pour l'instant on envoie toutes les trames sur externe et local???????????????????????????

mov esi,zt_decod
call env_trame
popad
xor eax,eax
ret


trame_ethernet_tropgrande:
popad
mov eax,cer_parami 
ret



;********************************
passe_cnx_mode4:
pushad
mov byte[esi+cnx_etat],4

;ferme la communication
mov al,1
mov ebx,[esi+cnx_adresse_com]
int 65h
mov edi,esi

;et envoie trame de fin
mov esi,zt_decod+64
mov [offset_ip],esi 
mov dword[taille_niv_sup],20

mov ax,[edi+cnx_port_serveur]  ;port
mov bx,[edi+cnx_port_client]
xchg al,ah
xchg bl,bh
mov [esi+tcp_port_sour],ax
mov [esi+tcp_port_dest],bx

mov eax,[edi+cnx_seq_serveur_suivante]
mov ebx,[edi+cnx_seq_client_attendue]
bswap eax
bswap ebx
mov [esi+tcp_seq],eax
mov [esi+tcp_ack],ebx
inc dword[edi+cnx_seq_serveur_suivante]

mov word[esi+tcp_flag],1150h   ;FIN+ACK + en-tête de 5dword 

mov word[esi+tcp_fenetre],0040h ;fenetre d'envoie 16Ko
mov word[esi+tcp_cheksum],0
mov word[esi+tcp_pointeur],0

mov eax,[edi+cnx_adresse_ipv4_client]
mov [adresse_ipv4_destination],eax
mov eax,[edi+cnx_adresse_ipv6_client]
mov [adresse_ipv6_destination],eax
mov eax,[edi+cnx_adresse_ipv4_client+4]
mov [adresse_ipv6_destination+4],eax
mov eax,[edi+cnx_adresse_ipv4_client+8]
mov [adresse_ipv6_destination+8],eax
mov eax,[edi+cnx_adresse_ipv4_client+12]
mov [adresse_ipv6_destination+12],eax

;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],06
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+tcp_cheksum],ax

call envoie_trame_ip

call sauvegarde_trame_tcp    ;sauvegarde trame pour réexpédition
popad
ret



;*******************************************************************
;incrémente le nombre de connexion ouvrable sur le descripteur de port tcp dans ax
inc_nb_cnx_tcp:
pushad
mov esi,[ad_table_tcp]
mov ecx,[nb_table_tcp]
boucle_inc_nb_cnx_tcp:
cmp ax,[esi+cnx_port_serveur]
jne ignore_inc_nb_cnx_tcp
cmp byte[esi+cnx_etat],0
je suite_inc_nb_cnx_tcp
ignore_inc_nb_cnx_tcp:
add esi,64
dec ecx
jnz boucle_inc_nb_cnx_tcp
popad
ret
suite_inc_nb_cnx_tcp:
inc word[esi+cnx_nbmax]
popad
ret





;**************************************************************************
envoie_ack_tcp:             ;envoie un ack a la connexion pointé par edi, detruit la zt_decod
pushad
mov esi,zt_decod+64
mov [offset_ip],esi 

mov ax,[edi+cnx_port_serveur]  ;port
mov bx,[edi+cnx_port_client]
xchg al,ah
xchg bl,bh
mov [esi+tcp_port_sour],ax
mov [esi+tcp_port_dest],bx

mov eax,[edi+cnx_seq_serveur_suivante]
mov ebx,[edi+cnx_seq_client_attendue]
bswap eax
bswap ebx
mov [esi+tcp_seq],eax
mov [esi+tcp_ack],ebx

mov word[esi+tcp_flag],1050h   ;ACK a 1 + en-tête de 5dword

mov word[esi+tcp_fenetre],0040h ;fenêtre d'envoie 16Ko
mov word[esi+tcp_cheksum],0
mov word[esi+tcp_pointeur],0

mov dword[taille_niv_sup],20

mov eax,[edi+cnx_adresse_ipv4_client]
mov [adresse_ipv4_destination],eax
mov eax,[edi+cnx_adresse_ipv6_client]
mov [adresse_ipv6_destination],eax
mov eax,[edi+cnx_adresse_ipv4_client+4]
mov [adresse_ipv6_destination+4],eax
mov eax,[edi+cnx_adresse_ipv4_client+8]
mov [adresse_ipv6_destination+8],eax
mov eax,[edi+cnx_adresse_ipv4_client+12]
mov [adresse_ipv6_destination+12],eax


;créer la partie en tête ip
mov byte[ttl_niv_sup],128
mov byte[type_niv_sup],06
call cree_entete_ip

;calcul le checksum
call chk_gen
mov esi,[offset_ip] 
mov word[esi+tcp_cheksum],ax

call envoie_trame_ip
popad
ret





;**************************************************************************
cree_entete_ip:

mov eax,[adresse_ipv4_destination]
cmp eax,0
je cree_entete_ipv6

mov word[type_ip],00008h    ;ethertype=ipv4

mov esi,[offset_ip]
sub esi,20
mov [offset_ethernet],esi

mov byte[esi+ipv4_ihl],45h
mov byte[esi+ipv4_service],0

mov ecx,[taille_niv_sup]
add ecx,20
xchg cl,ch
mov [esi+ipv4_longueur],cx
xor cx,[cptsf]
mov [esi+ipv4_id],cx   ;peut être changer de méthode pour générer les ID
mov word[esi+ipv4_flag_frag],0
mov dh,[ttl_niv_sup]
mov dl,[type_niv_sup]
mov [esi+ipv4_ttl],dh
mov [esi+ipv4_protocole],dl
mov word[esi+ipv4_checksum],0
mov edx,[adresse_ipv4]
cmp eax,0100007Fh
jne @f
mov edx,0100007Fh
@@:
mov [esi+ipv4_ip_sour],edx
mov [esi+ipv4_ip_dest],eax

call chkip

call calc_pseudo_entete

ret



cree_entete_ipv6:
mov word[type_ip],0DD86h    ;ethertype=ipv6
mov esi,[offset_ip]
sub esi,40
mov [offset_ethernet],esi

;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

ret

;**************************************************************************
;sous fonctions de calcul des cheksum de trame

chkip:
push eax
push ecx
push edx
push esi
mov ecx,[esi]   ;calcul de la taille de l'en-tête
and ecx,0Fh
shl ecx,1       

xor eax,eax
xor edx,edx
calchip:
mov dx,[esi]
add eax,edx
add esi,2
dec ecx
jnz calchip

mov edx,eax
shr edx,16
and eax,0FFFFh
add eax,edx
mov edx,eax
shr edx,16
and eax,0FFFFh
add eax,edx
xor ax,0FFFFh
pop esi
mov [esi+ipv4_checksum],ax
pop edx
pop ecx
pop eax
ret



;**********************************************************************************************
calc_pseudo_entete:                 ;calcul la somme de controle des words de la pseudo en-tête 
pushad
mov esi,[offset_ethernet]
mov al,[esi]
and al,0F0h
cmp al,060h
je calc_pseudo_entete_ipv6

xor eax,eax
xor edx,edx
mov ax,[esi+ipv4_longueur]
xchg al,ah
mov dl,[esi+ipv4_ihl]
and edx,0Fh
shl edx,2
sub eax,edx      ;pour obtenir la longeur des données (sans l'en tête)
xchg al,ah
mov dx,[esi+ipv4_ttl]
and dx,0FF00h  ;on ignore le TTL
add eax,edx
mov dx,[esi+ipv4_ip_sour]
add eax,edx
mov dx,[esi+ipv4_ip_sour+2]
add eax,edx
mov dx,[esi+ipv4_ip_dest]
add eax,edx
mov dx,[esi+ipv4_ip_dest+2]
add eax,edx
mov [somme_pseudo_entete],eax
popad
ret


calc_pseudo_entete_ipv6:
xor edx,edx
mov dx,[esi+ipv6_ip_sour]
mov eax,edx
mov dx,[esi+ipv6_ip_sour+2]
add eax,edx
mov dx,[esi+ipv6_ip_sour+4]
add eax,edx
mov dx,[esi+ipv6_ip_sour+6]
add eax,edx
mov dx,[esi+ipv6_ip_sour+8]
add eax,edx
mov dx,[esi+ipv6_ip_sour+10]
add eax,edx
mov dx,[esi+ipv6_ip_sour+12]
add eax,edx
mov dx,[esi+ipv6_ip_sour+14]
add eax,edx
mov dx,[esi+ipv6_ip_dest]
add eax,edx
mov dx,[esi+ipv6_ip_dest+2]
add eax,edx
mov dx,[esi+ipv6_ip_dest+4]
add eax,edx
mov dx,[esi+ipv6_ip_dest+6]
add eax,edx
mov dx,[esi+ipv6_ip_dest+8]
add eax,edx
mov dx,[esi+ipv6_ip_dest+10]
add eax,edx
mov dx,[esi+ipv6_ip_dest+12]
add eax,edx
mov dx,[esi+ipv6_ip_dest+14]
add eax,edx
mov ecx,[taille_niv_sup]
mov dx,cx
xchg dh,dl
add eax,edx
shr ecx,16
mov dx,cx
xchg dh,dl
add eax,edx
xor edx,edx
mov dh,[type_niv_sup]
add eax,edx
mov [somme_pseudo_entete],eax
popad
ret


;***********************************************************************************
chk_gen:                      ;calcule la somme de controle pour icmp udp et tcp
push ecx
push edx
push esi
mov eax,[somme_pseudo_entete]
xor edx,edx
mov ecx,[taille_niv_sup]
mov esi,[offset_ip]
test ecx,01h
jz chk_gen_paire
mov byte[esi+ecx],0 ;rajoute un bit nul si la taille de la trame est impaire
inc ecx
chk_gen_paire:
shr ecx,1

boucle_chk_gen:
mov dx,[esi]
add eax,edx
add esi,2
dec cx
jnz boucle_chk_gen

mov edx,eax
shr edx,16
and eax,0FFFFh
add eax,edx
mov edx,eax
shr edx,16
and eax,0FFFFh
add eax,edx
not ax

pop esi
pop edx
pop ecx
ret



;*****************************************************
dep_adresse_ipv6:    ;déplace l'adresse ipv6 de esi vers edi
pushad
mov eax,[esi]
mov ebx,[esi+4]
mov ecx,[esi+8]
mov edx,[esi+12]
mov [edi],eax
mov [edi+4],ebx
mov [edi+8],ecx
mov [edi+12],edx
popad
ret



;*****************************************************
cmp_adresse_ipv6:    ;compare  les adresse ipv6 esi edi cf=1 si identique
pushad
mov eax,[esi]
mov ebx,[esi+4]
mov ecx,[esi+8]
mov edx,[esi+12]
cmp [edi],eax
jne cmp_adresse_ipv6_nok
cmp [edi+4],ebx
jne cmp_adresse_ipv6_nok
cmp [edi+8],ecx
jne cmp_adresse_ipv6_nok
cmp [edi+12],edx
jne cmp_adresse_ipv6_nok 
popad
stc
ret

cmp_adresse_ipv6_nok:
popad
clc
ret


;*****************************************************
cmp_masque_ipv6:    ;compare si les adresse ipv6 esi edi appartienne au même sous réseau al (nombre de bit)  cf=1 si identique
pushad

mov edx,esi
add edx,16

boucle_cmp_masque_ipv6:
cmp al,8
jb suite_cmp_masque_ipv6
mov ah,[esi]
cmp ah,[edi]
jne cmp_masque_ipv6_nok 
inc esi
inc edi
cmp esi,edx
je cmp_masque_ipv6_ok 
sub al,8
jnz boucle_cmp_masque_ipv6

cmp_masque_ipv6_ok:
popad
stc
ret

suite_cmp_masque_ipv6:
mov cl,8
mov ch,0FFh
sub cl,al
shl ch,cl    ;ch=masque des derniers bits

mov al,[esi]
mov ah,[edi]
and al,ch
and ah,ch
cmp al,ah
je cmp_masque_ipv6_ok

cmp_masque_ipv6_nok:
popad
clc
ret




;****************************************************
change_taille_mem:
pushad
mov ecx,zt_decod
add ecx,2048

mov [ad_table_arp_nds],ecx
mov eax,[nb_table_arp_nds]
shl eax,5              ;32 octets par élément
add ecx,eax

mov [ad_table_tcp],ecx
mov eax,[nb_table_tcp]
shl eax,6              ;64 octets par élément
add ecx,eax


mov [ad_table_udp],ecx
mov eax,[nb_table_udp]
shl eax,8              ;8 octets par élément
add ecx,eax

mov [ad_zone_attente],ecx
mov eax,[nb_zone_attente]
shl eax,11             ;2048 octet par element
add ecx,eax

mov dx,sel_dat1
mov al,8
int 61h
popad
ret




;*****************************************************
trame_attente:    ;copie la trame de type al et de ecx octet pointé par esi dans la zone d'attente, renvoie dans esi la zone de la trame

cmp ecx,2048-zone_attente_trame  ;vérifie que la trame n'est pas trop grande
jae erreur_trame_attente

push ecx
push edx
push edi

mov edi,[ad_zone_attente]
mov edx,[nb_zone_attente]

boucle1_trame_attente:
cmp byte[edi],0
je trouve_vide_trame_attente
add edi,2048
dec edx
jnz boucle1_trame_attente

add dword[nb_zone_attente],16   ;on as pas trouvé de zone libre alors on en ajoute 16
call change_taille_mem 


trouve_vide_trame_attente:
push edi
mov [edi],al
mov [edi+zone_attente_taille],cx
add edi,zone_attente_trame
cld
rep movsb
pop esi

pop edi
pop edx
pop ecx
ret

erreur_trame_attente:
xor esi,esi
ret









;*************************************************
sauvegarde_trame_tcp:
mov al,4
mov esi,zt_decod
mov ecx,[to_decod]
call trame_attente
cmp esi,0
jne @f
ret

@@:
mov eax,100
mov edx,0
mov [esi+zone_attente_tcp_delais],eax   ;délais entre chaque réexpédition de trame
add eax,[cptsf]
adc edx,[cptsf+4]
mov [esi+zone_attente_tcp_compteur],eax      ;valeur compteur minimum pour rexpédier la trame
mov eax,8
mov [esi+zone_attente_tcp_nb],eax            ;nombre de réexpétion maximum restante
mov [esi+zone_attente_tcp_descr],edi        ;adresse du descripteur de la connexion
mov eax,[edi+cnx_seq_serveur_suivante]
mov [esi+zone_attente_tcp_ack_attendu],eax   ;ack qui validera la reception de la trame
ret





;************************
;cherche l'option al dans la trame dhcp reçu, renvoie l'adresse de cette option dans ebx
cherche_opt_dhcp:
xor ebx,ebx
push ecx
push esi
xor ecx,ecx
add esi,dhcp_options+4

@@:
cmp [esi],al
je trouve_cherche_opt_dhcp
cmp byte[esi],255
je fin_cherche_opt_dhcp
mov cl,[esi+1]
cmp cl,0 
je fin_cherche_opt_dhcp ;si l'option as une taille nulle c'est une erreur
add esi,ecx
add esi,2
cmp esi,zt_decod+2048
ja fin_cherche_opt_dhcp ;si on déborde de la trame c'est une erreur
jmp @b

trouve_cherche_opt_dhcp:
mov ebx,esi
fin_cherche_opt_dhcp:
pop esi
pop ecx
ret

;**********************
comp64:   ;effectue un cmp 64bit de la valeur pointé par edx par rapport au compteur cptsf (equivalent a un "cmp qword[edx],[cptsf]")
push eax
push ebx
mov eax,[cptsf]
mov ebx,[cptsf+4]

cmp [edx+4],ebx
ja @f
jb @f
cmp [edx],eax

@@:
pop ebx
pop eax
ret

