ctftp:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Client TFTP"
scode:
org 0


;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax


;agrandit la zone mémoire
mov al,8
mov ecx,sdata2
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
mov byte[zt_echange],0

mov al,5   
mov ah,"c"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_echange
int 61h
xor ebx,ebx
cmp eax,0
jne @f

mov al,100  
mov edx,zt_echange
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

@@:
mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,zt_echange
int 61h

shl ebx,1
mov ax,[zt_echange+ebx]
mov [id_tache],ax




;*********************************
;lit si il faudrat ecraser le fichier
mov al,5   
mov ah,"e"   ;lettre de l'option de commande a lire
mov cl,10 
mov edx,zt_echange
int 61h
cmp eax,0
jne @f
mov byte[ecrase],1
@@:





;**************************************************************
;lit l'adresse du serveur
mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,adresse_serveur_texte
int 61h

cmp byte[adresse_serveur_texte],0
je aff_err_param

mov al,109  
mov edx,adresse_serveur_texte
mov ecx,adresse_serveur_ip
int 61h
cmp eax,0
jne aff_err_param




;***********************************************************
;extrait l'action a effectuer


mov al,5   
mov ah,"r"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_ressource
int 61h
cmp eax,0
je lire_fichier


mov al,5   
mov ah,"w"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_ressource
int 61h
cmp eax,0
je envoie_fichier



;****************************
aff_err_param:
mov al,6
mov edx,msg_err_param
int 61h
int 60h


erreur_ouv_port:
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
mov edx,zt_echange+24
mov al,6
int 61h
int 60h


aff_err_pdr:
mov al,6
mov edx,msg_err_pdr
int 61h
int 60h








;**********************************************************************
lire_fichier:
call connexion_serveur


;prépare requete initiale
mov word[requete],100h

mov ecx,zt_ressource
@@:
mov al,[ecx]
inc ecx
cmp al,0
jne @b
mov dword[ecx],"octe"
mov dword[ecx+4],"t"
sub ecx,requete_ini-6

;envoie requete initiale
mov ebx,[adresse_canal]
mov al,7
mov esi,requete_ini
int 65h
cmp eax,0
jne erreur_ouv_port
cmp ecx,0
je erreur_ouv_port

mov word[numeros_bloc],1


mov al,6
mov edx,msg_okr1
int 61h
mov al,6
mov edx,zt_ressource
int 61h
mov al,6
mov edx,zt_echange
mov dword[edx],0D22h ;" puis cr puis zéro
int 61h


;*************
boucle_rrq:
mov al,9
mov ebx,[adresse_canal]
mov ecx,800 ;2s
int 65h
cmp eax,cer_ddi
jne aff_err_pdr


;lit les données reçu
mov al,6
mov edi,zt_echange
mov ecx,560
int 65h
cmp eax,0
jne boucle_rrq
sub ecx,26


;verifie si c'est la bonne adresse et le bon port
mov ax,[port_serveur]
mov ebx,[adresse_serveur_ip]
cmp [zt_echange],ax
jne boucle_rrq
cmp [zt_echange+2],ebx
jne boucle_rrq


;test si c'est un message d'erreur
cmp word[zt_echange+22],0500h
je aff_err_srv

;test si c'est bien les données attendu
mov ax,[numeros_bloc]
xchg al,ah
cmp word[zt_echange+22],0300h
jne boucle_rrq
cmp word[zt_echange+24],ax
jb ack_rrq
jne boucle_rrq



;si c'est le premier bloc on créer le fichier
cmp word[numeros_bloc],1
jne @f


mov al,2 
mov bx,0
mov edx,zt_ressource
int 64h
cmp eax,0
je ok_fichier
cmp eax,cer_nfr
jne aff_err_cre
cmp byte[ecrase],1
jne aff_err_cre

;si il existe et si on as autorisé l'ecrasement, on ouvre le fichier
mov al,0 
mov bx,0
mov edx,zt_ressource
int 64h
cmp eax,0
jne aff_err_ouv


ok_fichier:
mov [handle_fichier],ebx
@@:

;ecrire les données dans le fichier
mov eax,5
mov ebx,[handle_fichier]
mov edx,[offset_fichier]
mov esi,zt_echange+26
int 64h
add [offset_fichier],ecx
inc word[numeros_bloc]

;envoyer accusé de reception
ack_rrq:
push ecx
mov word[zt_echange+22],0400h
mov al,7
mov ebx,[adresse_canal]
mov ecx,26
mov esi,zt_echange
int 65h
pop ecx

cmp ecx,512
je boucle_rrq


;definis la taille fichier (au cas ou on écrase un fichier plus grand)
mov al,7
mov ah,1 ;taille fichier
mov ebx,[handle_fichier]
mov edx,offset_fichier
int 64h


mov al,6
mov edx,msg_okr2
int 61h
mov al,6
mov edx,zt_ressource
int 61h
mov al,6
mov edx,msg_okr3
int 61h

mov al,102
mov ecx,[offset_fichier]
mov edx,zt_echange
int 61h
mov al,6
mov edx,zt_echange
int 61h

mov al,6
mov edx,msg_okr4
int 61h


int 60h





;****************************************************************************************
envoie_fichier:
call connexion_serveur

;prépare requete initiale
mov word[requete],200h

mov ecx,zt_ressource
@@:
mov al,[ecx]
inc ecx
cmp al,0
jne @b
mov dword[ecx],"octe"
mov dword[ecx+4],"t"
sub ecx,requete_ini-6

;envoie requete initiale
mov ebx,[adresse_canal]
mov al,7
mov esi,requete_ini
int 65h
cmp eax,0
jne erreur_ouv_port
cmp ecx,0
je erreur_ouv_port

mov word[numeros_bloc],1


boucle_wrq:
mov al,3
int 65h
cmp eax,cer_ddi
je @f

int 62h   ;si aucune données a traiter on bascule a une autre tache
jmp boucle_wrq


@@:
;lit les données reçu
mov al,6
mov edi,zt_echange
mov ecx,560
int 65h
cmp eax,0
jne boucle_wrq
sub ecx,4


;verifie si c'est la bonne adresse et le bon port
mov ax,[port_serveur]
mov ebx,[adresse_serveur_ip]
cmp [zt_echange],ax
jne boucle_rrq
cmp [zt_echange+4],ebx
jne boucle_rrq

;test si c'est un message d'erreur
cmp word[zt_echange+22],0500h
je aff_err_srv

;test si c'est bien l'ack attendu
mov ax,[numeros_bloc]
cmp word[zt_echange+22],0400h
jne boucle_rrq
cmp word[zt_echange+24],ax
jb ack_rrq
jne boucle_rrq



;lit les données dans le fichier

mov eax,4 ;?????????
mov ebx,[handle_fichier]
mov edx,[offset_fichier]
mov edi,zt_echange+24
int 64h
add [offset_fichier],ecx



;envoyer les données 
mov word[zt_echange+22],0300h
mov al,7
mov ebx,[adresse_canal]
add ecx,24
mov esi,zt_echange
int 65h

jmp boucle_wrq

;un petit message pour la fin!!!!!!!!!!!!!!




int 60h






;*****************************************************************************
connexion_serveur:


;etablire une connexion
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,2000
mov edi,2000
int 65h
mov [adresse_canal],ebx
cmp eax,0
jne erreur_ouv_port


;configure en écoute pour un port UDP 
mov ax,[port_local]
mov word[zt_echange],7
mov [zt_echange+2],ax

mov al,5
mov ebx,[adresse_canal]
mov ecx,4h
mov esi,zt_echange
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
mov edi,zt_echange
int 65h
cmp eax,0
jne erreur_ouv_port

cmp byte[zt_echange],87h
jne erreur_ouv_port

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

msg_okr1:
db "CTFTP: début du téléchargement du fichier ",22h,0
msg_okr2:
db "CTFTP: fin du téléchargement du fichier ",22h,0
msg_okr3:
db 22h,", ",0
msg_okr4:
db " octets ont été téléchargé",13,0


msg_okw1:
db "CTFTP: début de l'envoie du fichier ",22h,0
msg_okw2:
db "CTFTP: fin de l'envoie du fichier ",22h,0
msg_okw3:
db 22h,", ",0
msg_okw4:
db " octets ont été envoyé",13,0






msg_err_srv:
db "CFTP: le serveur a renvoyé une erreur:",13,0



msg_err_param:
db "CTFTP: erreur de parametre",13,0
msg_err_com:
db "CTFTP: erreur de communication",13,0
msg_err_cre:
db "CTFTP: impossible de créer le fichier",13,0
msg_err_ouv:
db "CTFTP: impossible d'ouvrir le fichier",13,0
msg_err_ecr:
db "CTFTP: impossible d'écrire dans le fichier",13,0
msg_err_exe:
db "CTFTP: erreur durant l'échange avec le serveur",13,0
msg_err_pdr:
db "CTFTP: pas de réponse du serveur",13,0



port_local:
rb 2
id_tache:
rb 2
adresse_canal:
rb 4
numeros_bloc:
rb 4
handle_fichier:
rb 4
offset_fichier:
rb 8
ecrase:
rb 1




adresse_serveur_texte:
rb 256



requete_ini:
port_serveur:
dw 69
adresse_serveur_ip:
rb 4
ipv6:
rb 16
requete:
rb 2
zt_ressource:
rb 256







zt_echange:
rb 1024






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
