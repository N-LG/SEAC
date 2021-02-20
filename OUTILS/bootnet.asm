;
;enregistrer au format ANSI

format	PE console

stack 10000h    ;taille de la pile souhaité

section '.text' code readable executable

start:

;chargement de la table des adresses



call net_init
cmp eax,0
jne erreur

mov bx,67
mov ebp,[ip_serveur]
call net_ouvre_port_udp
cmp eax,0
jne erreur
mov [handle_port_bootp],ebx

mov bx,69
mov ebp,[ip_serveur]
call net_ouvre_port_udp
cmp eax,0
jne erreur
mov [handle_port_tftp],ebx

mov bx,386
mov ebp,[ip_serveur]
call net_ouvre_port_udp
cmp eax,0
jne erreur
mov [handle_port_tftp_envoie],ebx

mov edx,initok
call affmsg



boucle:
mov edi,zt_bootp
mov ecx,640
mov ebx,[handle_port_bootp]
call net_lire_port_udp
cmp eax,0
jne erreur
cmp ecx,0
je part_tftp



cmp byte[zt_bootp],01  ;bootrequest
jne autre_type
cmp byte[htype],01 ;type de réseau
jne part_tftp
cmp byte[hlen],06  ;adresse materielle
jne part_tftp


mov al,[chaddr]
and al,0F0h
shr al,4
call ajhex
mov [chaine_adresse_mac],al
mov al,[chaddr]
and al,0Fh
call ajhex
mov [chaine_adresse_mac+1],al

mov al,[chaddr+1]
and al,0F0h
shr al,4
call ajhex
mov [chaine_adresse_mac+3],al
mov al,[chaddr+1]
and al,0Fh
call ajhex
mov [chaine_adresse_mac+4],al

mov al,[chaddr+2]
and al,0F0h
shr al,4
call ajhex
mov [chaine_adresse_mac+6],al
mov al,[chaddr+2]
and al,0Fh
call ajhex
mov [chaine_adresse_mac+7],al

mov al,[chaddr+3]
and al,0F0h
shr al,4
call ajhex
mov [chaine_adresse_mac+9],al
mov al,[chaddr+3]
and al,0Fh
call ajhex
mov [chaine_adresse_mac+10],al

mov al,[chaddr+4]
and al,0F0h
shr al,4
call ajhex
mov [chaine_adresse_mac+12],al
mov al,[chaddr+4]
and al,0Fh
call ajhex
mov [chaine_adresse_mac+13],al

mov al,[chaddr+5]
and al,0F0h
shr al,4
call ajhex
mov [chaine_adresse_mac+15],al
mov al,[chaddr+5]
and al,0Fh
call ajhex
mov [chaine_adresse_mac+16],al

mov edx,reception
call affmsg





mov ebx,table_adresse_mac
mov eax,[chaddr]
mov dx,[chaddr+4]
boucle_recherche_correspondance:
cmp eax,[ebx]
jne suite
cmp dx,[ebx+4]
je correspondance_ok 

suite:
add ebx,32
cmp ebx,table_adresse_mac + 2048
jne boucle_recherche_correspondance

mov edx,impossible
call affmsg
jmp part_tftp

correspondance_ok:
mov byte[zt_bootp],02  ;bootreply

mov eax,[ip_serveur]
mov [siaddr],eax

mov eax,[ebx+6]
mov [yiaddr],eax

mov esi,ebx
add esi,10
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
mov byte[edi+2],2
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


mov byte[edi],255        ;marque la fin des options   


mov dx,68
mov ebp,[ip_diffusion]
mov esi,zt_bootp
mov ecx,300
mov ebx,[handle_port_bootp]
call net_ecrire_port_udp
cmp eax,0
jne erreur
jmp part_tftp



autre_type:
mov ebx,autres
call affmsg

;************************************************************************************
part_tftp:
cmp byte[mode_tftp],1
je envoie_tftp


mov edi,zt_tftp
mov ecx,512
mov ebx,[handle_port_tftp]
call net_lire_port_udp
cmp eax,0
jne erreur
cmp ecx,0
je pauseunpeu
cmp word[zt_tftp],0500h   
je erreur_tftp

mov [port_client_tftp],dx
mov [ip_client_tftp],ebp

cmp word[zt_tftp],0100h
je lire_fichier_tftp
cmp word[zt_tftp],0200h
je ecrire_fichier_tftp
jmp boucle


lire_fichier_tftp:
;verifie que le mode de transmission demandé soit bien "octet"
mov ebx,zt_tftp+2
boucle_verif_octet:
cmp byte[ebx],0
je verif_octet
inc ebx
jmp boucle_verif_octet

verif_octet:
inc ebx
cmp byte[ebx],"O"
je ok_lettre1
cmp byte[ebx],"o"
jne erreur_mode
ok_lettre1:
inc ebx
cmp byte[ebx],"C"
je ok_lettre2
cmp byte[ebx],"c"
jne erreur_mode
ok_lettre2:
inc ebx
cmp byte[ebx],"T"
je ok_lettre3
cmp byte[ebx],"t"
jne erreur_mode
ok_lettre3:
inc ebx
cmp byte[ebx],"E"
je ok_lettre4
cmp byte[ebx],"e"
jne erreur_mode
ok_lettre4:
inc ebx
cmp byte[ebx],"T"
je ok_lettre5
cmp byte[ebx],"t"
jne erreur_mode
ok_lettre5:
inc ebx
cmp byte[ebx],0
jne erreur_mode


;ouvre le fichier
mov edx,zt_tftp+2
call ouvre_fichier
cmp eax,0
jne erreur_fichier_nt
mov [handle_fichier],ebx

;determine la taille du fichier
mov ebx,[handle_fichier]
call taillef
mov [to_fichier],ecx

mov edx,msg_envoie_tftp1
call affmsg

mov edx,zt_tftp+2
call affmsg

mov edx,msg_envoie_tftp2
call affmsg


mov byte[nombre-1],"."

xor ecx,ecx
mov cl,[ip_client_tftp]
mov esi,nombre
call conv_nombre
mov edx,nombre
call affmsg

xor ecx,ecx
mov cl,[ip_client_tftp+1]
mov esi,nombre
call conv_nombre
mov edx,nombre-1
call affmsg

xor ecx,ecx
mov cl,[ip_client_tftp+2]
mov esi,nombre
call conv_nombre
mov edx,nombre-1
call affmsg

xor ecx,ecx
mov cl,[ip_client_tftp+3]
mov esi,nombre
call conv_nombre
mov edx,nombre-1
call affmsg

mov byte[nombre-1]," "

xor ecx,ecx
mov cx,[port_client_tftp]
mov esi,nombre
call conv_nombre
mov edx,nombre-1
call affmsg

mov byte[mode_tftp],1 ;passe en mode envoie
mov dword[dernier_bloc],1
mov dword[nb_envoie],0
jmp env_bloc


erreur_fichier_nt:          ;erreur: fichier non trouvé
mov esi,tftp_erreur_1
mov ecx,tftp_erreur_2-tftp_erreur_2
mov dx,[port_client_tftp]
mov ebp,[ip_client_tftp]
mov ebx,[handle_port_tftp]
call net_ecrire_port_udp
jmp boucle




erreur_mode:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


ecrire_fichier_tftp:          ;erreur: l'ecriture est interdite
mov esi,tftp_erreur_4
mov ecx,tftp_erreur_5-tftp_erreur_4
mov dx,[port_client_tftp]
mov ebp,[ip_client_tftp]
mov ebx,[handle_port_tftp]
call net_ecrire_port_udp
jmp boucle








envoie_tftp:
mov edi,zt_tftp
mov ecx,512
mov ebx,[handle_port_tftp_envoie]
call net_lire_port_udp
cmp eax,0
jne erreur
cmp ecx,0
je env_bloc
cmp word[zt_tftp],0500h   
je erreur_tftp



cmp [port_client_tftp],dx  ;verifie la provenance de la trame 
jne boucle
cmp [ip_client_tftp],ebp
jne boucle




cmp word[zt_tftp],0400h    
je ack_tftp
jmp env_bloc













ack_tftp:
xor eax,eax             ;compare si l'ack correspond au dernier bloc envoyé si non erreur
mov ah,[zt_tftp+2]
mov al,[zt_tftp+3]
cmp eax,[dernier_bloc]
jne boucle

inc dword[dernier_bloc]
mov dword[nb_envoie],0


env_bloc:     ;si oui envoie le bloc suivant
inc dword[nb_envoie]
cmp dword[nb_envoie],80
jae fin_erreur_envoie


mov edx,[dernier_bloc]
dec edx
shl edx,9
mov ecx,[to_fichier]
cmp edx,ecx
ja fin_envoie_fichier

sub ecx,edx
cmp ecx,512
jb taille_bloc_inf
mov ecx,512
taille_bloc_inf:


mov ebx,[handle_fichier]
mov edi,zt_tftp+4
push ecx
call lit_fichier
pop ecx

mov word[zt_tftp],0300h
mov dx,[dernier_bloc]
mov [zt_tftp+2],dh
mov [zt_tftp+3],dl


mov dx,[port_client_tftp]
mov ebp,[ip_client_tftp]
mov esi,zt_tftp
add ecx,4
mov ebx,[handle_port_tftp_envoie]
call net_ecrire_port_udp
jne erreur
jmp boucle



fin_erreur_envoie:     ;la transmission ne s'est pas effectué correctement
mov byte[mode_tftp],0

mov ebx,[handle_fichier]
call ferme_fichier

mov edx,msg_envoie_tftp4
call affmsg
jmp boucle


fin_envoie_fichier:    ;le fichier a été envoyé on se remet a écouter les requetes 
mov byte[mode_tftp],0

mov ebx,[handle_fichier]
call ferme_fichier

mov edx,msg_envoie_tftp3
call affmsg
jmp boucle





pauseunpeu:
push dword 10
call [Sleep]
jmp boucle

erreur_tftp:    ;affiche que l'on a reçu un message d'erreur
;*****************
jmp boucle


;***********************
ajhex:
add al,"0"
cmp al, "9"
ja ajhex2
ret

ajhex2:
add al,7
ret

;***************************
erreur:
push ebx
mov edx,msgerr
call affmsg
pop ecx
mov esi,nombre
call conv_nombre

mov edx,nombre
call affmsg


fin:


include "nlg_win.inc"


msg_err1:
db "vous devez spécifier l'IP de la carte du réseau sur laquel vous souhaitez uttiliser le serveur",13,10,0

msg_err2:
db "erreur de lecture du fichier de configuration",13,10,0


initok:
db "serveur BOOTP et TFTP activé",10,13,0



reception:
db "reception d'une demande d'adresse par "
chaine_adresse_mac:
db 0,0,":",0,0,":",0,0,":",0,0,":",0,0,":",0,0,13,10,0


impossible:
db "impossible de satisfaire la demande car aucune correspondance n'as été trouvé dans la table",13,10,0

autres:
db "un type de requete non reconnue a été reçu",13,10,0

msg_envoie_tftp1:
db "debut d'envoie du fichier ",0

msg_envoie_tftp2:
db " vers la machine ",0

msg_envoie_tftp3:
db "fin du transfert de fichier",13,10,0

msg_envoie_tftp4:
db "le fichier n'as pas put être envoyé correctement",13,10,0

stop:
db "*",0

msgerr:
db "erreur:",0

db 0
nombre:
dd 0,0,0,0


ip_serveur:
db 192,168,1,40

masque:
db 255,255,255,0

ip_diffusion:
db 255,255,255,255


handle_port_bootp:
dd 0

handle_port_tftp:
dd 0

handle_port_tftp_envoie:
dd 0


mode_tftp:
db 0

ip_client_tftp:
dd 0

port_client_tftp:
dw 0

dernier_bloc:
dd 0

nb_envoie:
dd 0


handle_fichier:
dd 0

to_fichier:
dd 0


fichier_config:
db "bootnet.txt",0






tftp_erreur_0:
db 0,5,0,0,"erreur indéfinis",0
tftp_erreur_1:
db 0,5,0,1,"fichier non trouvé",0
tftp_erreur_2:
db 0,5,0,2,"interdiction d'acces",0
tftp_erreur_3:
db 0,5,0,3,"disque plein",0
tftp_erreur_4:
db 0,5,0,4,"opération TFTP interdite",0
tftp_erreur_5:
db 0,5,0,5,"ID de transfert inconnue",0
tftp_erreur_6:
db 0,5,0,6,"le fichier existe déja",0
tftp_erreur_7:
db 0,5,0,7,"utilisateur inconnue",0
tftp_erreur_8:






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
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octets, zone optionnelle determiné par le constructeur
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128. octets supplémentaire pour pouvoir satisfaire une éventuelle requete DHCP
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


table_adresse_mac:

db 030h,0E1h,071h,038h,070h,044h  ;pc HP amelie
db 192,168,1,210
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0


db 000h,010h,05Ah,0C4h,01Ah,0DDh  ;carte 3Com
db 192,168,1,211
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0


db 0AAh,00Ch,076h,0CDh,08Bh,009h  ;virtualbox
db 192,168,1,212
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0

db 070h,04Dh,07Bh,043h,0EFh,01Ah  ;
db 192,168,1,213
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0

db 000h,001h,002h,0A4h,024h,014h  ;carte 3Com
db 192,168,1,214
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0


db 000h,00Ch,076h,0CDh,08Bh,009h
db 192,168,1,215
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0

db 000h,00Ch,076h,0CDh,08Bh,009h
db 192,168,1,216
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0

db 000h,01Eh,0ECh,06bh,0A3h,0E6h  ;ordinateur portable compac (reseau filaire)
db 192,168,1,217
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0

db 000h,021h,058h,0FFh,0D6h,020h  ;adresse mac d'origine inconnue
db 192,168,1,218
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0

db 08Ch,079h,067h,0F3h,04Bh,0D7h  ;ZTE blade 7
db 192,168,1,219
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0

db 08Ch,089h,0A5h,0CAh,03Bh,0C0h  ;adresse mac pc win7
db 192,168,1,220
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0


db 0C0h,03Fh,0D5h,0EDh,096h,02Dh  ;adresse mac inconnue
db 192,168,1,221
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0

db 000h,023h,069h,07Ah,055h,0F9h  ;routeur wifi
db 192,168,1,222
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0

db 000h,040h,08Ch,05Ah,0B4h,0A4h  ;caméra ip
db 192,168,1,223
db "syst.bin",0,0,0,0,0,0,0,0,0,0,0,0,0,0

dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128


zt_tftp: ;516 octets
dd 0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128





