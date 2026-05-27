ctls:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "surcouche TLS"
scode:
org 0


;objectifs a ateindre avant de réussir a faire fonctionner ce logiciel
;1 faire les procédure d'echange de clef asymetrique de type DHE, ECDHE, et RSA (pas certain mais je pense avoir besoin de la bibliotheque de manip de grand nombre)
;2 faire les HMAC correspondnant aux hachage SHA-2 (ça a l'air plutot simple)
;3 faire le chiffrement chacha20 et poly1305 (totalement inconnu mais on m'as dit que c'était abordable)
;4 faire les chiffrage AES en GCM, CCM et CCM8 (trouver des exemples de chiffrement pour valider les hypothese, je doute avoir bien tout comprit)
;5 finaliser les hachages SHA-2 (SHA256 finis, les autres semblent être des dérivé)



;objectifs optionnels
;sha-1
;SHA-3
;TOTP (faire HMAC d'abord si j'ai bien comprit)


;**********************************************
;caractéristique canaux de communication
nb_canaux equ 16

canal_etat equ 0
;0 canal libre
;communication sortante
;1 client hello envoyé, en attente des réponse serveurs
;2 client key, change cypher et encry handshake envoyé, en attente du change cypher du serveur et du encrypted handshake
;communication entrante
;????
;32 communication chiffé établit
canal_temp equ 1
canal_protocole equ 2
canal_client equ 4
canal_serveur equ 8
canal_taille_recu equ 12
canal_offset_reception equ 16


canal_clef equ 64 ;?????????
canal_iv equ 64 ;?????????
canal_nom_serveur equ 256


canal_client_hello equ 1024
canal_serveur_hello equ 1024
canal_certificate equ 1024
canal_serveur_key_exchange equ 1024
canal_certificate_request equ 1024
canal_serveur_hello_done equ 1024
canal_certificate_verify equ 1024
canal_client_key_exchange equ 1024
canal_zt_reception equ 2048
canal_taille_reception equ 10000h
canal_taille equ (canal_zt_reception+canal_taille_reception)


;************************************
;trames TLS handshake
TTLS_type equ 0
TTLS_version equ 1
TTLS_taille equ 3

TTLSh_type equ 5
TTLSh_taille equ 6

TTLSh_ch_version equ 9
TTLSh_ch_random equ 11

;session id(1) + data
;cypher suite(2) + data
;compression method(1)+data
;extension(2)+data
 ;dans l'extension: 2o type - 2o taille - data

;******************************************************************************
;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax


;se déclare comme un nouveau service TLS
mov al,10
mov ah,9 ;service TLS
int 61h


;agrandit la mémoire
mov al,8
mov dx,sel_dat1
mov ecx,zt_decode+4096
int 61h

;**************************************************************
;determine l'id du service ethernet
mov byte[zt_decode],0

mov al,5   
mov ah,"c"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_decode
int 61h
xor ebx,ebx
cmp eax,0
jne @f

mov al,100  
mov edx,zt_decode
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

@@:
mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,zt_decode
int 61h

shl ebx,1
mov ax,[zt_decode+ebx]
mov [id_tache_ethernet],ax


;***************************************************************************************************************************
;***************************************************************************************************************************
boucle_principale:

;lit si une nouvelle connexion as été ouverte
mov al,2
int 65h
cmp eax,cer_ddi
jne echange_donnee


;lit la requete qui as été envoyé
mov al,4
mov ecx,512
xor esi,esi
mov edi,zt_decode
int 65h
cmp eax,0
;jne ??????????????????????????????????????????????????????


;vérifie que la reque est de type ouverture TCP
cmp byte[zt_decode],8
jne commande_inconnue


;cherche un canal disponible
mov ecx,nb_canaux
mov edx,canaux
@@:
cmp byte[edx+canal_etat],0
je canal_disponible
add edx,canal_taille
dec ecx
jnz @b

mov edx,msg_plus_canaux
call ajuste_langue
mov al,6
int 61h

;rejete la demande de connexion
abandon_cnx:
mov byte[edx+canal_etat],0

commande_inconnue:
mov word[zt_decode],00FFh  ;on signale que la commande est inconnue
mov al,5
mov ecx,34h
mov edi,0
mov esi,zt_decode
int 65h
jmp echange_donnee


;*******************
canal_disponible:
;enregistre les infos
mov byte[edx+canal_etat],1
mov [edx+canal_client],ebx
mov byte[zt_decode+512],0   ;copie le nom du serveur
mov edi,edx
mov esi,zt_decode+32
add edi,canal_nom_serveur
cld
@@:
lodsb
stosb
cmp al,0
jne @b


;etablire une connexion avec le serveur de destination
push edx
mov al,0
mov bx,[id_tache_ethernet]
mov ecx,64
mov edx,1
mov esi,20000h
mov edi,20000h
int 65h
pop edx
cmp eax,0
;jne ????????????????????????????????????????????
mov [edx+canal_serveur],ebx


mov al,5
mov ecx,32
mov esi,zt_decode
mov edi,0
int 65h
cmp eax,0
jne abandon_cnx


;attend que le programme réponde
mov al,8
mov ecx,8200  ;500ms
int 65h
cmp eax,cer_ddi
jne abandon_cnx


;lit la réponse du programme
mov al,4
mov ecx,32
mov esi,0
mov edi,zt_decode
int 65h
cmp eax,0
jne abandon_cnx

cmp byte[zt_decode],88h
jne abandon_cnx


;préparation client helo
mov edi,zt_decode
;en tête TLS
mov byte[edi+TTLS_type],16h ;handshake
mov word[edi+TTLS_version],103h;

;en tête handshake
mov byte[edi+TTLSh_type],1  ;client hello
mov word[edi+TTLSh_ch_version],303h; ;version 1.2 pour des raison de compatibilité
add edi,TTLSh_ch_random
;????????????????????????générer 32 octets random
mov dword[edi]   ,452e58B5h
mov dword[edi+4] ,06fd7236h
mov dword[edi+8] ,7c87ed34h
mov dword[edi+12],92fcd744h
mov dword[edi+16],89eaac78h
mov dword[edi+20],4e1147f8h
mov dword[edi+24],7d7d9912h
mov dword[edi+28],44BEE7a5h
;??????????????????????????génération manuelle pour l'instant
add edi,32

;session id
mov byte[edi],0 ;pas de session ID
inc edi

;cypher suite  voir https://www.iana.org/assignments/tls-parameters/tls-parameters.xhtml#tls-parameters-4
mov word[edi],3400h    ;52 en MSB first 
mov word[edi+2],28C0h  ;TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384
mov word[edi+4],27C0h  ;TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
mov word[edi+6],14C0h  ;TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
mov word[edi+8],13C0h  ;TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
mov word[edi+10],9F00h ;TLS_DHE_RSA_WITH_AES_256_GCM_SHA384
mov word[edi+12],9E00h ;TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
mov word[edi+14],3900h ;TLS_DHE_RSA_WITH_AES_256_CBC_SHA
mov word[edi+16],3300h ;TLS_DHE_RSA_WITH_AES_128_CBC_SHA
mov word[edi+18],9D00h ;TLS_RSA_WITH_AES_256_GCM_SHA384
mov word[edi+20],9C00h ;TLS_RSA_WITH_AES_128_GCM_SHA256
mov word[edi+22],3D00h ;TLS_RSA_WITH_AES_256_CBC_SHA256 
mov word[edi+24],3C00h ;TLS_RSA_WITH_AES_128_CBC_SHA256
mov word[edi+26],3500h ;TLS_RSA_WITH_AES_256_CBC_SHA  
mov word[edi+28],2F00h ;TLS_RSA_WITH_AES_128_CBC_SHA
mov word[edi+30],2C00h ;TLS_PSK_WITH_NULL_SHA
mov word[edi+32],2BC0h ;TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
mov word[edi+34],24C0h ;TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384
mov word[edi+36],23C0h ;TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
mov word[edi+38],0AC0h ;TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
mov word[edi+40],09C0h ;TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
mov word[edi+42],6A00h ;TLS_DHE_DSS_WITH_AES_256_CBC_SHA256
mov word[edi+44],4000h ;TLS_DHE_DSS_WITH_AES_128_CBC_SHA256
mov word[edi+46],3800h ;TLS_DHE_DSS_WITH_AES_256_CBC_SHA
mov word[edi+48],3200h ;TLS_DHE_DSS_WITH_AES_128_CBC_SHA
mov word[edi+50],0A00h ;TLS_RSA_WITH_3DES_EDE_CBC_SHA
mov word[edi+52],1300h ;TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA
add edi,54

;ecdhe dhe rsa psk
;rsa ecdsa dss
;CBC CGM
;sha sha256 sha384





;compression methode
mov byte[edi],1
mov byte[edi+1],0 ;aucune compression
add edi,2


;les extentions**********************voir https://www.iana.org/assignments/tls-extensiontype-values/tls-extensiontype-values.xhtml
mov ebx,edi
add edi,2


;server name        voir RFC6066 ou RFC9261
mov word[edi],0
mov ecx,edx
add ecx,canal_nom_serveur
@@:
cmp byte[ecx],0
je @f
inc ecx
jmp @b
@@:
sub ecx,edx
sub ecx,canal_nom_serveur

push ecx
mov byte[edi+6],0
mov [edi+7],ch
mov [edi+8],cl
add cx,3
mov [edi+4],ch
mov [edi+5],cl
add cx,2
mov [edi+2],ch
mov [edi+3],cl
pop ecx

add edi,9
mov esi,edx
add esi,canal_nom_serveur
cld
rep movsb


;status request voir RFC6066
mov word[edi],0500h  
mov word[edi+2],0500h
mov byte[edi+4],1
mov dword[edi+5],0
add edi,9


;courbe elliptique    voir RFC8422 ou RFC7919
mov word[edi],0A00h
mov word[edi+2],0600h  
mov word[edi+4],0400h    ;elliptic curve length=4 (2 curves)
mov word[edi+6],1700h   ;secp256r1 elliptic curve   (voir https://std.neuromancer.sk/secg/)
mov word[edi+8],1800h   ;secp384r1 elliptic curve
add edi,10


;ec_point_format      voir RFC8422
mov word[edi],0B00h
mov word[edi+2],200h
mov byte[edi+4],1h
mov byte[edi+5],0h
add edi,6


;algo de signature supporté  voir RFC-ietf-tls-rfc8446bis-13
mov word[edi],0D00h
mov word[edi+2],1400h 
mov word[edi+4],1200h  ;9 algo   supporté
mov word[edi+6],106h
mov word[edi+8],306h
mov word[edi+10],104h
mov word[edi+12],105h
mov word[edi+14],102h
mov word[edi+16],304h
mov word[edi+18],305h
mov word[edi+20],302h
mov word[edi+22],202h
add edi,24


mov word[edi],1700h  ;extended_main_secret 	voir RFC7627 ou RFC-ietf-tls-rfc8446bis-13
mov word[edi+2],0
add edi,4


;renegotiation_info    voir RFC5746
mov word[edi],1FFh
mov word[edi+2],100h
mov byte[edi+4],0
add edi,5




;**********************
;application_layer_protocol_negotiation 	voir RFC7301
;mov word[edi],1000h  
;mov word[edi+2],0
;add edi,4

 
;delegated_credential     voir RFC9345
;mov word[edi],2200h  
;mov word[edi+2],0
;add edi,4


;session_ticket       voir RFC5077 ou RFC8447
;mov word[edi],2300h  
;mov word[edi+2],0
;add edi,4


;supported_versions     voir RFC-ietf-tls-rfc8446bis-13
;mov word[edi],2B00h  
;mov word[edi+2],0
;add edi,4


;psk_key_exchange_modes     voir RFC-ietf-tls-rfc8446bis-13
;mov word[edi],2D00h  
;mov word[edi+2],0
;add edi,4


;key_share     voir RFC-ietf-tls-rfc8446bis-13 et RFC Errata 5483
;mov word[edi],3300h  
;mov word[edi+2],0
;add edi,4


;*******************************
;bourrage (voir RFC7685) pour faire une trame de 512 octet (sans compter l'en tête TLS)
mov word[edi],1500h
mov ecx,zt_decode+513 ;512+5(entete tls)-4(entete extension pas encore compté)
sub ecx,edi
mov [edi+2],ch  
mov [edi+3],cl  
add edi,4
xor eax,eax
cld
rep stosb

temp:

;enregistre les tailles
mov ecx,edi
sub ecx,zt_decode
push ecx

sub ecx,5;en tête tls 

mov [zt_decode+TTLS_taille],ch ;taille trame tls
mov [zt_decode+TTLS_taille+1],cl
sub ecx,4;en tête handshake 

mov byte[zt_decode+TTLSh_taille],0
mov [zt_decode+TTLSh_taille+1],ch ;taille trame handshake
mov [zt_decode+TTLSh_taille+2],cl

mov ecx,edi
sub ecx,ebx
sub ecx,2
mov [ebx],ch   ;taille des extensions
mov [ebx+1],cl   
pop ecx


;!!!!!!!!!!!!!!!!!!on affiche les donnée brutes
pushad
mov esi,zt_decode
mov edi,ecx
xor ebx,ebx
grgrgr:
mov cl,[esi]
mov al,105
mov edx,zt_tempo
int 61h
mov word[zt_tempo+2]," "
inc ebx
cmp ebx,16
jne @f
xor ebx,ebx
mov word[zt_tempo+2],13
@@:
mov al,6
mov edx,zt_tempo
int 61h
inc esi
dec edi
jnz grgrgr

mov word[zt_tempo],13
mov al,6
mov edx,zt_tempo
int 61h
popad
;!!!!!!!!!!!!!!!!!!on as fini d'afficher les données brutes










;envoie client hello
mov al,7
mov esi,zt_decode
mov ebx,[edx+canal_serveur]
int 65h
cmp eax,0
;jne ??????????????????????????



;******************************************************************************************************
;**********************************************************************************************************
echange_donnee:
;lit les donné reçu sur chaque canal coté serveur

mov ecx,nb_canaux
mov edx,canaux
boucle_parcours_serveur:
cmp byte[edx+canal_etat],0
jne recept_donnee
suite_parcours_serveur:
add edx,canal_taille
dec ecx
jnz boucle_parcours_serveur
jmp boucle_principale

;*************************
;*************************
recept_donnee:
push ecx
push edx


;reçoit donnée sur le canal
mov edi,edx
add edi,canal_zt_reception
add edi,[edx+canal_offset_reception]
mov ecx,canal_taille_reception
sub ecx,[edx+canal_offset_reception]
mov al,6
mov ebx,[edx+canal_serveur]
int 65h
cmp eax,0
jne erreur_canal
add [edx+canal_offset_reception],ecx

cmp dword[edx+canal_offset_reception],0
je envoie_donnee


;vérifie qu'un paquet tls complet as été reçu
xor ecx,ecx
mov esi,edx
add esi,canal_zt_reception
mov ch,[esi+3]
mov cl,[esi+4]
add ecx,5
cmp ecx,[edx+canal_offset_reception]
ja envoie_donnee


int 3h

;copie la trame tls complete dans la zone de décodage
mov eax,ecx
mov edi,zt_decode
cld
rep movsb


;décale les données dans la zone de reception
mov ecx,[edx+canal_offset_reception]
sub ecx,eax
mov [edx+canal_offset_reception],ecx
cmp ecx,0
je @f
mov edi,edx
add edi,canal_zt_reception
cld
rep movsb
@@:




mov ecx,eax
;décode la trame
cmp byte[zt_decode + TTLS_type],15h
je decode_alert
cmp byte[zt_decode + TTLS_type],16h
je decode_handshake
;cmp byte[zt_decode + TTLS_type],17h
;je decode_application_data
;jmp envoie_donnee

decode_alert:
;?????????????
mov esi,zt_decode
call affiche
;???????????????
jmp envoie_donnee




decode_handshake:
;cmp byte[zt_decode + TTLSh_type],00h
;je decode_hello_request
;cmp byte[zt_decode + TTLSh_type],01h
;je decode_client_hello
cmp byte[zt_decode + TTLSh_type],02h
je decode_server_hello
cmp byte[zt_decode + TTLSh_type],0Bh
je decode_certificate
;cmp byte[zt_decode + TTLSh_type],0Ch
;je decode_server_key_exchange
;cmp byte[zt_decode + TTLSh_type],0Dh
;je decode_certificate_request
cmp byte[zt_decode + TTLSh_type],0Eh
je decode_server_hello_done
;cmp byte[zt_decode + TTLSh_type],0Fh
;je decode_certificate_verify
;cmp byte[zt_decode + TTLSh_type],10h
;je decode_client_key_exchange
;cmp byte[zt_decode + TTLSh_type],14h
;je decode_finished

;?????????????
mov esi,zt_decode
call affiche
;???????????????
jmp envoie_donnee





decode_server_hello:
mov edi,ecx         ;ne fait que l'afficher
mov esi,zt_decode

mov ecx,5
call affiche

mov ecx,6
call affiche

mov ecx,32
call affiche

xor ecx,ecx
mov cl,[esi]
inc ecx
call affiche

mov ecx,2
call affiche

mov ecx,1
call affiche

mov ecx,2
call affiche

@@:
xor ecx,ecx
mov ch,[esi+2]
mov cl,[esi+3]
add ecx,4
call affiche

cmp edi,0
ja @b


jmp envoie_donnee





decode_certificate:
;?????????????
mov esi,zt_decode
call affiche
;???????????????

jmp envoie_donnee






decode_server_hello_done:

;?????????????
mov esi,zt_decode
call affiche
;???????????????

jmp envoie_donnee









;**************************************************************************
affiche:
;!!!!!!!!!!!!!!!!!!on affiche les donnée brutes
pushad
mov edi,ecx
xor ebx,ebx
grdgrgr:
mov cl,[esi]
mov al,105
mov edx,zt_tempo
int 61h
mov word[zt_tempo+2]," "
inc ebx
cmp ebx,16
jne @f
xor ebx,ebx
mov word[zt_tempo+2],13
@@:
mov al,6
mov edx,zt_tempo
int 61h
inc esi
dec edi
jnz grdgrgr

mov byte[zt_tempo],13
mov byte[zt_tempo+1],"-"
mov word[zt_tempo+2],13
mov al,6
mov edx,zt_tempo
int 61h
popad
;!!!!!!!!!!!!!!!!!!on as fini d'afficher les données brutes
add esi,ecx
sub edi,ecx
ret


















;si on est en mode établissement de la connexion, enregistre les informations reçu

;si on as reçu le "server hello done" et toutes les information nécesssaire
;on envoie le client key exchange
;on envoie le Change Cipher Spec
;on envoie le client Encrypted Handshake Message
;on passe en mode attente validation serveur

;si on est en mode attente validation serveur, on attend le  Change Cipher Spec et le Encrypted Handshake Message
;on passe en mode connexion chiffré établit


;déchiffre les données
;!!!!!!!!!!!!!!!!!!on affiche les donnée brutes
mov dword[zt_tempo],0d0d0dh
mov al,6
mov edx,zt_tempo
int 61h

mov esi,zt_decode
mov edi,ecx
xor ebx,ebx
blblbl:
mov cl,[esi]
mov al,105
mov edx,zt_tempo
int 61h
mov word[zt_tempo+2]," "
inc ebx
cmp ebx,16
jne @f
xor ebx,ebx
mov word[zt_tempo+2],13
@@:
mov al,6
mov edx,zt_tempo
int 61h
inc esi
dec edi
jnz blblbl

mov word[zt_tempo],13
mov al,6
mov edx,zt_tempo
int 61h
;!!!!!!!!!!!!!!!!!!on as fini d'afficher les données brutes



;envoie les données au client







recept_donnee_ok:
;analyse les donnée éventuellement reçue 



;*******************************************
;*******************************************
envoie_donnee:
;lit les donné reçu sur chaque canal coté client


;chiffre les données


;envoie les données au serveur




;*************
pop edx
pop ecx
jmp suite_parcours_serveur




erreur_canal:
;on ferme les canaux exterieur
mov byte[edx+canal_etat],0


;on rend le canal disponible

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pop edx
pop ecx
jmp suite_parcours_serveur



;******************************************
;******************************************
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


mge_taille equ 1024
include "mge_code.inc"
include "crypto_code.inc"
;*********************************************************



sdata1:
org 0

include "mge_data.inc"
include "crypto_data.inc"



id_tache_ethernet:
dw 0


msg_plus_canaux:
db "CTLS: no more TLS available",13,0
db "CTLS: plus de canaux de connexion TLS disponible",13,0

zt_tempo:
rb 512

canaux:
rb nb_canaux * canal_taille 

zt_decode:



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
