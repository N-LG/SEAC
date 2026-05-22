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
canal_zt_recetption equ 2048


canal_taille equ canal_zt_recetption+10000h


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
mov ecx,zt_decode + 4096
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
cmp byte[zt_decode],4
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
mov byte[zt_decode+512]   ;copie le nom du serveur
mov edi,edx
mov esi,zt_decode+34h
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
mov ecx,34h
mov esi,zt_decode
mov edi,0
int 65h
cmp eax,0
jne abandon_cnx


;attend que le programme réponde
mov al,8
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne abandon_cnx

;lit la réponse du programme
mov al,4
mov ecx,34h
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
mov word[edi+TTLS_version],304; ;????versin 1.3

;en tête handshake
mov byte[edi+TTLSh_type],1  ;client hello
mov word[edi+TTLSh_ch_version],303; ;version 1.2 pour des raison de compatibilité
add edi,TTLSh_ch_random
;????????????????????????générer 32 octets random
mov dword[edi]   ,452e58B5h
mov dword[edi+4] ,06fd7236h
mov dword[edi+8] ,7c87ed34h
mov dword[edi+12],92fcd744h
mov dword[edi+16],89eaac78h
mov dword[edi+20],be1147f8h
mov dword[edi+24],7d7d9912h
mov dword[edi+28],h
;??????????????????????????génération manuelle pour l'instant
add edi,32

;session id
mov byte[edi],0 ;pas de session ID
inc edi

;cypher suite
mov word[edi],200h ;2 en MSB first 
mov word[edi+2],3300h ;33h en MSB first: TLS_DHE_RSA_WITH_AES_128_CBC_SHA selon exemple, sinon voir plus bas
add edi,4

;compression methode
mov byte[edi],1
mov byte[edi+1],0 ;aucune compression
add edi,2


;les extentions************
mov ebx,edi
add edi,2

;renegotiation_info
mov word[edi],1FFh
mov word[edi+2],100h
mov byte[edi+4],0
add edi,5

;server name
mov word[edi],0
mov ecx,edx
add ecx,nom_serveur
@@:
cmp byte[ecx],0
je @f
inc ecx
jmp @b
@@:
sub ecx,edx
sub ecx,nom_serveur
mov ax,cx
xchg al,ah
mov [edi+2],ax
add edi,4
mov esi,edx
add esi,nom_serveur
cld
rep movsb

;algo de signature supporté ???????trouver doc pour comprendre les correspondance valeur/algo
mov word[edi],0D00h
mov word[edi+2],800h  ;4algo   supporté
mov word[edi+4],104h
mov word[edi+6],304h
mov word[edi+8],106h
mov word[edi+10],306h
add edi,12


;ec_point_format ?????????????trouver doc pour comprendre
mov word[edi],0B00h
mov word[edi+2],200h
mov word[edi+2],200h
add edi,6


;courbe elliptique ?????????????trouver doc pour comprendre
mov word[edi],0A00h
mov word[edi+2],600h  
mov word[edi+4],400h    ;elliptic curve length=4 (2 curves)
mov word[edi+6],1700h   ;secp256r1 elliptic curve   (voir https://std.neuromancer.sk/secg/)
mov word[edi+8],1800h   ;secp384r1 elliptic curve
add edi,10


;bourrage pour faire une trame de 512 octet (sans compter l'en tête TLS)
mov word[edi],1500h
mov ecx,zt_decode+512+5
sub ecx,edi
mov [edi+2],ch  
mov [edi+3],cl  
add edi,4
xor eax,eax
cld
rep stosb


;enregistre les tailles
mov ecx,edi
sub ecx,zt_decode
push ecx

mov [zt_decode+TTLS_taille],ch ;taille trame tls
mov [zt_decode+TTLS_taille+1],cl
sub ecx,4;en tête handshake 

mov byte[zt_decode+TTLSh_taille],0
mov [zt_decode+TTLSh_taille+1],ch ;taille trame handshake
mov [zt_decode+TTLSh_taille+2],cl

mov ecx,edi
sub ecx,ebx
;sub ecx,????????
mov [ebx],ch   ;taille des extensions
mov [ebx+1],cl   
pop ecx


;envoie client hello
mov al,7
mov esi,ztdecod
mov ebx[edx+canal_serveur]
int 65h
cmp eax,0
;jne ??????????????????????????




;*******************************************
;*******************************************
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

;lit sur canal
mov al,6
mov edi,zt_decode
mov ecx,2048
int 65h
cmp eax,0
jne erreur_canal
cmp ecx,0
je envoie_donnee






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
