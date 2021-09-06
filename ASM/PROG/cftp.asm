bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Client FTP"
scode:
org 0





;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax


;agrandit la zone mémoire
mov al,8
mov ecx,zt_decode+20000h
mov dx,sel_dat1
int 61h



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
mov [id_tache],ax



;**************************************************************
;lit l'adresse de la ressource souhaité
mov byte[zt_decode],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_url
int 61h

cmp byte[zt_url],0
je aff_err_param



;charge les parametre de base
mov dword[zt_port],3132h   ;21
mov dword[zt_ressource],2Fh ;/


;**************************************************************
;extrait l'adresse     note: penser a distinguer les éventuelles adresse ipv6
mov esi,zt_url
mov edi,zt_host

@@:
mov al,[esi]
cmp al,":"
je extrait_port
cmp al,"/"
je extrait_ressource
cmp al,0
je extrait_fin
mov [edi],al
inc esi
inc edi
jmp @b


;extrait le port (éventuellement)
extrait_port:
mov byte[edi],0
inc esi
mov edi,zt_port
@@:
mov al,[esi]
cmp al,"/"
je extrait_ressource
cmp al,0
je extrait_fin
mov [edi],al
inc esi
inc edi
jmp @b


;extrait le nom de la ressource (éventuellement)
extrait_ressource:
mov byte[edi],0
inc esi
mov edi,zt_ressource

@@:
mov al,[esi]
cmp al,0
je extrait_fin
mov [edi],al
inc esi
inc edi
jmp @b

extrait_fin:
mov byte[edi],0

;convertir les parametre en valeur
mov al,100
mov edx,zt_port
int 61h
mov [port_serveur],ecx


;convertit l'adresse/port pour la commande de connexion
mov al,5   
mov ah,"a"   ;lettre de l'option de commande a lire
mov cl,32 
mov edx,zt_adresse
int 61h

cmp eax,0
je @f 
mov edx,zt_host
@@:

mov al,109
mov ecx,ip_serveur
int 61h




;**************************************************************
;extrait le nom d'utilisateur

mov al,5   
mov ah,"u"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_user
int 61h

;et le mot de passe
mov al,5   
mov ah,"p"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_pass
int 61h








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
mov edi,zt_decode
int 65h
cmp eax,0
jne aff_err_com

cmp byte[zt_decode],88h
jne aff_err_com



call attend1ligne



;************************************
;commande user et pass
mov edx,ftp_req1
call envoie_utf8z
mov edx,zt_user
call envoie_utf8z
mov edx,ftp_reqf
call envoie_utf8z
call attend1ligne


mov edx,ftp_req2
call envoie_utf8z
mov edx,zt_pass
call envoie_utf8z
mov edx,ftp_reqf
call envoie_utf8z
call attend1ligne
cmp byte[zt_decode],"2"  
jne aff_err_srv



;******************************
;passe en binaire et mode passif avancé
;comande type i
mov edx,ftp_req3
call envoie_utf8z
call attend1ligne
cmp byte[zt_decode],"2"  
jne aff_err_srv


;commande epsv
mov edx,ftp_req4
call envoie_utf8z
call attend1ligne
cmp byte[zt_decode],"2"  
jne aff_err_srv

;extrait numéros de port §§§§§§§§§§§§§a devoir ameliorer je pense
mov edx,zt_decode

boucle_num_port:
cmp dword[edx],"(|||"
je ok_num_port
cmp byte[edx],0Dh
je aff_err_exe
inc edx
jmp boucle_num_port

ok_num_port:
add edx,4
mov al,100
int 61h
mov [port_serveur],cx
inc word[port_local]


;*****************************************
;ouvre la connexion 2
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,400
mov edi,20000h
int 65h
mov [adresse_canal2],ebx


mov al,5
mov ebx,[adresse_canal2]
mov ecx,34h
mov esi,commande_ethernet
mov edi,0
int 65h
cmp eax,0
jne aff_err_com


;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal2]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne aff_err_com

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal2]
mov ecx,34h
mov esi,0
mov edi,zt_decode
int 65h
cmp eax,0
jne aff_err_com

cmp byte[zt_decode],88h
jne aff_err_com


;*************************************
;envoie la commande size
mov edx,ftp_req5
call envoie_utf8z
mov edx,zt_ressource
call envoie_utf8z
mov edx,ftp_reqf
call envoie_utf8z
call attend1ligne


;extrait taille du fichier
cmp byte[zt_decode],"2"
jne @f
mov al, 100
mov edx,zt_decode+4
int 61h
mov [taille_totale],ecx
@@:

;***************************************
;evoie la commande retr
mov edx,ftp_req6
call envoie_utf8z
mov edx,zt_ressource
call envoie_utf8z
mov edx,ftp_reqf
call envoie_utf8z
call attend1ligne
cmp byte[zt_decode],"1"  ;attend le signal que le téléchargement as bien commencé
jne aff_err_srv




;*****************************
;créer le fichier au besoin
mov al,5   
mov ah,"o"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,nom_fichier
int 61h
cmp eax,0
jne affiche_resultat


;cree le fichier
mov al,2 
mov bx,0
mov edx,nom_fichier
int 64h
cmp eax,0
je ok_fichier
cmp eax,cer_nfr
jne aff_err_cre

mov al,5   
mov ah,"e"   ;lettre de l'option de commande a lire
mov cl,10 
mov edx,zt_port
int 61h
cmp eax,0
jne aff_err_cre


;ouvre le fichier
mov al,0 
mov bx,0
mov edx,nom_fichier
int 64h
cmp eax,0
jne aff_err_ouv

ok_fichier:
mov [handle_fichier],ebx

mov ecx,[taille_totale]  ;réserve l'espace pour le fichier fichier
cmp ecx,0
je @f
mov al,15
int 64h
@@:


;******************************
;envoie dans fichier le reste des données
mov al,6
mov edx,msg_ok_af1
int 61h


boucle_enregistre_resultat:
mov al,6
mov ecx,20000h
mov edi,zt_decode
mov ebx,[adresse_canal2]
int 65h
cmp eax,0
jne fin_telechargement 
cmp ecx,0
je boucle_enregistre_resultat

mov ebx,[handle_fichier]
mov edx,[taille_telec]
mov esi,zt_decode
mov al,5
int 64h
cmp eax,0
jne aff_err_ecr
add [taille_telec],ecx
jmp boucle_enregistre_resultat 


;************************************
;affiche les données dans le journal
affiche_resultat:

mov al,6
mov edx,msg_ok_af1
int 61h

boucle_affiche_resultat:
mov al,6
mov ecx,1FFFFh
mov edi,zt_decode
mov ebx,[adresse_canal2]
int 65h
cmp eax,0
jne fin_telechargement 
cmp ecx,0
je boucle_affiche_resultat


mov byte[ecx+zt_decode],0
mov edx,zt_decode
mov al,6
int 61h
add [taille_telec],ecx
jmp boucle_affiche_resultat




;***************************************
fin_telechargement:
cmp dword[taille_totale],0
je fin_inconnue
mov ecx,[taille_telec]
cmp [taille_totale],ecx
jne fin_incomplet
mov al,6
mov edx,msg_fin1
int 61h
int 60h


fin_inconnue:
mov al,6
mov edx,msg_fin2
int 61h

mov al,102
mov ecx,[taille_telec]
mov edx,zt_decode
int 61h
mov al,6
mov edx,zt_decode
int 61h

mov al,6
mov edx,msg_fin5
int 61h
int 60h


fin_incomplet:
mov al,6
mov edx,msg_fin3
int 61h

mov al,102
mov ecx,[taille_telec]
mov edx,zt_decode
int 61h
mov al,6
mov edx,zt_decode
int 61h

mov al,6
mov edx,msg_fin4
int 61h

mov al,102
mov ecx,[taille_totale]
mov edx,zt_decode
int 61h
mov al,6
mov edx,zt_decode
int 61h

mov al,6
mov edx,msg_fin5
int 61h
int 60h



;****************************
aff_err_param:
mov al,6
mov edx,msg_err_param
int 61h
int 60h


aff_err_com:
mov al,6
mov edx,msg_err_com
int 61h
int 60h

aff_err_cre:
mov al,6
mov edx,msg_err_cre
int 61h
int 60h

aff_err_ouv:
mov al,6
mov edx,msg_err_ouv
int 61h
int 60h

aff_err_ecr:
mov al,6
mov edx,msg_err_ecr
int 61h
int 60h

aff_err_exe:
mov al,6
mov edx,msg_err_exe
int 61h
int 60h



aff_err_srv:
mov al,6
mov edx,msg_err_srv
int 61h
mov edx,zt_decode
mov al,6
int 61h
int 60h








;*****************************
envoie_utf8z:
mov esi,edx
xor ecx,ecx

@@:
cmp byte[edx],0
je @f
inc ecx
inc edx
jmp @b

@@:
mov al,7
mov ebx,[adresse_canal]
int 65h
ret




;********************************
attend1ligne:
mov dword[offset],0
boucle_attend1ligne:
mov al,6
mov ecx,1024
sub ecx,[offset]
mov edi,zt_decode
add edi,[offset]
mov ebx,[adresse_canal]
int 65h
cmp eax,0
jne aff_err_com

cmp ecx,0
je boucle_attend1ligne
add [offset],ecx
test_attend1ligne:
cmp dword[offset],2
jb boucle_attend1ligne

;recherche si fin d'en_tête 
mov edi,zt_decode-1
mov esi,zt_decode
add edi,[offset]
@@:
cmp word[esi],0A0Dh
je fin_attend1ligne
inc esi
cmp esi,edi
jne @b
jmp boucle_attend1ligne


fin_attend1ligne:
mov byte[esi+1],0
;mov edx,zt_decode  ;pour debug
;mov al,6           ;pour debug
;int 61h            ;pour debug

cmp byte[zt_decode+3],"-"
je @f 
ret

@@:
add esi,2
mov ecx,[offset]
add ecx,zt_decode
sub ecx,esi
mov [offset],ecx
cmp ecx,0
je boucle_attend1ligne

mov edi,zt_decode
cld
rep movsb
jmp test_attend1ligne






sdata1:
org 0

msg_ok_af1:
db "CFTP: début du téléchargement du document",13,0

msg_fin1:
db "CFTP: téléchargement complet",13,0
msg_fin2:
db "CFTP: fin du téléchargement par coupure de connexion par le serveur, ",0
msg_fin3:
db "CFTP: téléchargement incomplet, ",0
msg_fin4:
db " sur ",0
msg_fin5:
db " octets ont été téléchargé",13,0


msg_err_srv:
db "CFTP: le serveur a renvoyé une erreur:",13,0



msg_err_param:
db "CFTP: erreur de parametre",13,0
msg_err_com:
db "CFTP: erreur de communication",13,0
msg_err_cre:
db "CFTP: impossible de créer le fichier",13,0
msg_err_ouv:
db "CFTP: impossible d'ouvrir le fichier",13,0
msg_err_ecr:
db "CFTP: impossible d'écrire dans le fichier",13,0
msg_err_exe:
db "CFTP: erreur durant l'échange avec le serveur",13,0







id_tache:
dw 0
adresse_canal:
dd 0
adresse_canal2:
dd 0
offset:
dd 0
taille_telec:
dd 0
taille_totale:
dd 0
handle_fichier:
dd 0


commande_ethernet:
db 8,1
port_local:
dw 0
cmd_max:
dw 0
cmd_fifo:
dw 2000,2000 
port_serveur:
dw 0
ip_serveur:
dd 0
cmd_ip6:
dd 0,0,0,0
index_recep:
dd 0



ftp_req1:
db "USER ",0
ftp_req2:
db "PASS ",0
ftp_req3:
db "TYPE I",13,10,0
ftp_req4:
db "EPSV",13,10,0
ftp_req5:
db "SIZE ",0
ftp_req6:
db "RETR ",0


ftp_reqf:
db 13,10,0



zt_user:
db "anonymous"
rb 256
zt_pass:
rb 256
zt_adresse:
rb 32
nom_fichier:
rb 256
zt_port:
rb 10
zt_url:
rb 256
zt_host:
rb 256
zt_ressource:
rb 256
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
