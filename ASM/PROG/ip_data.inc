;include standard pour les pilotes IP pour carte réseau (données)


info_adresse_carte:
dw 0
adresse_mac:
dw 0,0,0
adresse_ipv4:
dd 0
masque_ipv4:
dd 0
passerelle_ipv4:
dd 0
adresse_ipv6_lien:
dd 80FEh,0,0,0
adresse_ipv6_local:
dd 0,0,0,0
adresse_ipv6_global:
dd 0,0,0,0



dhcp_demande:
dd 0
dhcp_phase:
db 0
dhcp_id:
dd 0
dhcp_serveur:
dd 0
dhcp_adresse:
dd 0
dhcp_masque:
dd 0
dhcp_passerelle:
dd 0




taille_trame_max:
dd 1500
taille_trame:
dd 0
offset_ethernet:
dd 0
offset_ip:
dd 0
taille_niv_sup:
dd 0
ttl_niv_sup:
db 0
type_niv_sup:
db 0
somme_pseudo_entete:
dd 0

adresse_ethernet_destination:
dw 0,0,0
adresse_ipv4_destination:
dd 0
adresse_ipv6_destination:
dd 0,0,0,0
type_ip:
dw 0



ad_table_arp_nds:
dd 0
ad_table_tcp:    
dd 0
ad_table_udp:    
dd 0
ad_zone_attente: 
dd 0
nb_table_arp_nds:
dd 256 
nb_table_tcp:    
dd 256
nb_table_udp:    
dd 256
nb_zone_attente:
dd 256

cptsf:
dd 0,0

msgerec:
db "il y as eu une erreur lors de la reception de la trame",13,0

msg_trappe:
dd 0,0

tempo:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


tout_ethernet:
dd 0FFFFFFFFh

table_acces_icmp:
dd 0FFFFFFFFh
dd 0FFFFFFFFh
dd 0FFFFFFFFh
dd 0FFFFFFFFh
dd 0FFFFFFFFh
dd 0FFFFFFFFh
dd 0FFFFFFFFh
dd 0FFFFFFFFh

table_ethernet_virtuel:
dw 0,0,0,0FFFFh,0FFFFh             ;adresse mac + adresse canal de communication  8x
dw 0,0,0,0FFFFh,0FFFFh
dw 0,0,0,0FFFFh,0FFFFh
dw 0,0,0,0FFFFh,0FFFFh
dw 0,0,0,0FFFFh,0FFFFh
dw 0,0,0,0FFFFh,0FFFFh
dw 0,0,0,0FFFFh,0FFFFh
dw 0,0,0,0FFFFh,0FFFFh


table_ethernet_protocole:
dw 0,0FFFFh,0FFFFh          ;protocole + adresse canal de communication      16x
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh
dw 0,0FFFFh,0FFFFh


zt_decod:

 
