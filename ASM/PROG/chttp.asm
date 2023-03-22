bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "téléchargeur de ressources HTTP"
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

mov dword[zt_port],3038h   ;80
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
mov edi,zt_ressource+1

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



;***********************************************************
;etablire une connexion
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,20000h
mov edi,20000h
int 65h
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



;************************************
;envoie requete
mov edx,http_req1
call envoie_utf8z

mov edx,zt_ressource
call envoie_utf8z

mov edx,http_req2
call envoie_utf8z

mov edx,zt_host
call envoie_utf8z

mov edx,http_req3
call envoie_utf8z


;******************************
;attend réponse
mov al,9
mov ecx,1000
mov ebx,[adresse_canal]
int 65h
cmp eax,cer_ddi    ;???????????????????????????probleme
jne aff_err_com





;**************************
lecture_entete:
mov al,6
mov ecx,20000h
sub ecx,[offset]
mov edi,zt_decode
add edi,[offset]
mov ebx,[adresse_canal]
int 65h
cmp eax,0
jne aff_err_com

cmp ecx,0
je lecture_entete  ;??????????????????????????????probleme

add [offset],ecx

;recherche si fin d'en_tête 
mov edi,zt_decode-3
mov esi,zt_decode
add edi,[offset]
@@:
cmp dword[esi],0A0D0A0Dh
je fin_entete
inc esi
cmp esi,edi
jne @b
jmp lecture_entete


fin_entete:


;****************************
;affiche si réponse négative
cmp dword[zt_decode+8]," 200"
je ok_chargement

mov al,6
mov edx,msg_err1
call ajuste_langue
int 61h

mov word[esi+2],0
mov al,6
mov edx,zt_decode
int 61h

int 60h



;*****************************
;extrait taille donnée
ok_chargement:
;mov byte[esi+2],0  ;DEBUG
mov edx,zt_decode  ;DEBUG
mov al,6           ;DEBUG
int 61h            ;DEBUG
mov edx,zt_decode  ;cherche "Content-Length: " dans l'en-tête (insensible a la casse)
mov edi,mot_taille


boucle1_cherche_taille:
push edx
push edi
mov ecx,16

boucle2_cherche_taille:
mov al,[edx]
cmp al,"A"
jb @f
cmp al,"Z"
ja @f
add al,20h
@@:
cmp al,[edi]
jne suivant_cherche_taille
inc edx
inc edi
dec ecx
jnz boucle2_cherche_taille
pop edi
pop edx
add edx,16
mov al,100
int 61h
mov [taille_totale],ecx
jmp @f


suivant_cherche_taille:

;mov [msg_tmp],al
;mov edx,msg_tmp
;mov al,6
;int 61h

pop edi
pop edx
inc edx
cmp edx,esi
jne boucle1_cherche_taille
@@:


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
call ajuste_langue
int 61h

add esi,4
mov ecx,[offset]
add ecx,zt_decode
sub ecx,esi
mov ebx,[handle_fichier]
mov edx,0
mov al,5
int 64h
cmp eax,0
jne aff_err_ecr
add [taille_telec],ecx

boucle_enregistre_resultat:
mov al,6
mov ecx,20000h
mov edi,zt_decode
mov ebx,[adresse_canal]
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

mov ecx,[taille_telec]
cmp ecx,[taille_totale]
jb boucle_enregistre_resultat 
jmp fin_telechargement


;************************************
;affiche les données dans le journal
affiche_resultat:

mov al,6
mov edx,msg_ok_af1
call ajuste_langue
int 61h

add esi,4
mov ecx,[offset]
mov edx,esi
mov byte[ecx+zt_decode],0
mov al,6
int 61h
add [taille_telec],ecx

boucle_affiche_resultat:
mov al,6
mov ecx,1FFFFh
mov edi,zt_decode
mov ebx,[adresse_canal]
int 65h
cmp eax,0
;jne fin_telechargement 
cmp ecx,0
je boucle_affiche_resultat

mov byte[ecx+zt_decode],0
mov edx,zt_decode
mov al,6
int 61h
add [taille_telec],ecx

mov ecx,[taille_telec]
cmp ecx,[taille_totale]
jb boucle_affiche_resultat


;***************************
fin_telechargement:
cmp dword[taille_totale],0
je fin_inconnue
mov ecx,[taille_telec]
cmp [taille_totale],ecx
jne fin_incomplet
mov al,6
mov edx,msg_fin1
call ajuste_langue
int 61h
int 60h


fin_inconnue:
mov al,6
mov edx,msg_fin2
call ajuste_langue
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
call ajuste_langue
int 61h
int 60h


fin_incomplet:
mov al,6
mov edx,msg_fin3
call ajuste_langue
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
call ajuste_langue
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
call ajuste_langue
int 61h
int 60h



;****************************
aff_err_param:
mov al,6
mov edx,msg_err_param
call ajuste_langue
int 61h
int 60h


aff_err_com:
mov al,6
mov edx,msg_err_com
call ajuste_langue
int 61h
int 60h


aff_err_cre:
mov al,6
mov edx,msg_err_cre
call ajuste_langue
int 61h
int 60h

aff_err_ouv:
mov al,6
mov edx,msg_err_ouv
call ajuste_langue
int 61h
int 60h

aff_err_ecr:
mov al,6
mov edx,msg_err_ecr
call ajuste_langue
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

msg_ok_af1:
db "CHTTP: start of document download",13,0
db "CHTTP: début du téléchargement du document",13,0
msg_fin1:
db "CHTTP: download complete",13,0
db "CHTTP: téléchargement complet",13,0
msg_fin2:
db "CHTTP: end of download by connection cut by the server, ",0
db "CHTTP: fin du téléchargement par coupure de connexion par le serveur, ",0
msg_fin3:
db "CHTTP: incomplete download, ",0
db "CHTTP: téléchargement incomplet, ",0
msg_fin4:
db " bytes out of ",0
db " octets sur ",0
msg_fin5:
db " have been downloaded",13,0
db " ont été téléchargé",13,0


msg_err1:
db "CHTTP: The server returned an error:",13,20h,0
db "CHTTP: le serveur a renvoyé une erreur:",13,20h,0


msg_err_param:
db "CHTTP: command line syntax error. enter ",22h,"man chttp",22h," for correct syntax",13,0
db "CHTTP: erreur dans la sytaxe de la ligne de commande. entrez ",22h,"man chttp",22h," pour avoir la syntaxe correcte",13,0
msg_err_com:
db "CHTTP: communication error",13,0
db "CHTTP: erreur de communication",13,0
msg_err_cre:
db "CHTTP: unable to create file",13,0
db "CHTTP: impossible de créer le fichier",13,0
msg_err_ouv:
db "CHTTP: Impossible to open file",13,0
db "CHTTP: impossible d'ouvrir le fichier",13,0
msg_err_ecr:
db "CHTTP: cannot write to file",13,0
db "CHTTP: impossible d'écrire dans le fichier",13,0



msg_tmp:
db "-",0



id_tache:
dw 0
adresse_canal:
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
dw 20000,20000 
port_serveur:
dw 0
ip_serveur:
dd 0
cmd_ip6:
dd 0,0,0,0
index_recep:
dd 0

mot_taille:
db "content-length: "


http_req1:
db "GET ",0
http_req2:
db " HTTP/1.0",13,10,"Host: ",0
http_req3:
db 13,10,"User-Agent: Chttp/SEaC"
db 13,10,13,10,0

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
