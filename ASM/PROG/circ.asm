circ:
;rajouter support du multi canal
;rajouter test périodique de connexion


pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Client IRC"
scode:
org 0
mov ax,sel_dat1
mov ds,ax
mov es,ax


;génère un numéros de port local pseudo aléatoirement
mov eax,9
int 61h
xor ax,bx
xor ax,cx
xor ax,dx
xor ax,07CB3h
mov [port_local],ax



;**************************************************************
;determine l'id du service ethernet
mov byte[zt_recep],0

mov al,5   
mov ah,"c"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h
xor ebx,ebx
cmp eax,0
jne @f

mov al,100  
mov edx,zt_recep
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

@@:
mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,zt_recep
int 61h

shl ebx,1
mov ax,[zt_recep+ebx]
cmp ax,0
je aff_err_param
mov [id_tache],ax



;**************************************************************
;determine ip serveur
mov byte[zt_recep],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h

cmp byte[zt_recep],0
je aff_err_param


mov al,109  
mov edx,zt_recep
mov ecx,ip_serveur
int 61h

cmp dword[ip_serveur],0
je aff_err_param



;**************************************************************
;determine port serveur
mov byte[zt_recep],0

mov al,4   
mov ah,1   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h

cmp byte[zt_recep],0
je aff_err_param


mov al,100  
mov edx,zt_recep
int 61h

cmp ecx,0
je aff_err_param
test ecx,0FFFF0000h
jnz aff_err_param

mov [port_serveur],cx




;***********************************************************
;etablire une connexion
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,2000
mov edi,2000
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
mov edi,zt_recep
int 65h
cmp eax,0
jne aff_err_com

cmp byte[zt_recep],88h
jne aff_err_com


;initialisation ecran texte
mov dx,sel_dat2
mov ah,1   ;option=mode texte
mov al,0   ;création console     
int 63h

mov dx,sel_dat2    ;écran video
mov fs,dx

;***********************************************
;demande identifiant
mov edx,msg1
mov al,11
mov ah,0Ah ;couleur
int 63h

mov ah,07h
mov edx,identifiant
mov ecx,32
mov al,6
int 63h

;§§§§§§§§§§§§§§§§§§§§§§checker si il y as pas d'espace et redemander (ou remplacer par _)





;demande salon
mov edx,msg2
mov al,11
mov ah,0Ah ;couleur
int 63h

mov ah,07h
mov edx,salon
mov ecx,32
mov al,6
int 63h


;***********************************************
;envoie commande USER
mov dword[zt_recep],"USER"
mov byte[zt_recep+4]," "
mov edi,zt_recep+5
mov esi,identifiant
call insert_chaine

mov byte[edi]," "
inc edi

mov esi,identifiant
call insert_chaine

mov word[edi],"1 "
add edi,2

mov esi,identifiant
call insert_chaine

mov word[edi],"2 "
add edi,2

mov esi,identifiant
call insert_chaine

mov word[edi],"3 "
add edi,2
mov word[edi],0D0Ah
add edi,2

mov ecx,edi
mov al,7
mov ebx,[adresse_canal]
mov esi,zt_recep
sub ecx,esi
int 65h



;envoie commande NICK
mov dword[zt_recep],"NICK"
mov byte[zt_recep+4]," "
mov edi,zt_recep+5
mov esi,identifiant
boucle_cmd5:
mov al,[esi]
cmp al,0
je fin_cmd5
mov [edi],al
inc esi
inc edi
jmp boucle_cmd5 
fin_cmd5:

mov word[edi],0D0Ah
add edi,2

mov ecx,edi
mov al,7
mov ebx,[adresse_canal]
mov esi,zt_recep
sub ecx,esi
int 65h



;envoie la commande JOIN
mov dword[zt_recep],"JOIN"
mov word[zt_recep+4]," #"
mov edi,zt_recep+6
mov esi,salon
call insert_chaine

mov word[edi],0D0Ah
add edi,2

mov ecx,edi
mov al,7
mov ebx,[adresse_canal]
mov esi,zt_recep
sub ecx,esi
int 65h




boucle:
;******************************************************************************************************************
;test si donné reçu

mov al,6
mov ebx,[adresse_canal]
mov edi,zt_recep
mov ecx,512
sub ecx,[index_recep]
add edi,[index_recep]
int 65h
cmp eax,0
jne aff_err_cnx
add [index_recep],ecx


;verif si présence d'une fin de ligne
mov esi,zt_recep
mov ecx,[index_recep]
cmp ecx,0
je test_clavier
boucle_crlf:
cmp word[esi],0A0Dh
je traite_message
inc esi
dec ecx
jnz boucle_crlf
jmp test_clavier




;*********************************************************************************
traite_message:
mov word[esi],0
add esi,2

mov edx,zt_recep
cmp byte[edx],":"
jne commande_serveur

inc edx             
mov [offset_nom],edx

call rech_espace
mov [offset_cmd],edx

call rech_espace
mov [offset_chan],edx

call rech_espace
inc edx
mov [offset_msg],edx

mov ebx,[offset_cmd]
cmp dword[ebx],"PRIV"
jne affiche_complet
cmp dword[ebx+4],"MSG "
jne affiche_complet



mov edx,zt_recep+1     ;transforme tout les ! et espace en zéro
boucle_trespace:
cmp byte[edx],0
je fin_trespace
cmp byte[edx]," "
je zero_trespace
cmp byte[edx],"!"
jne suite_trespace
zero_trespace:
mov byte[edx],0
suite_trespace:
inc edx
cmp edx,[offset_msg]
jne boucle_trespace

fin_trespace:



suite_affiche_msg:
call efface_saisie

mov edx,[offset_nom]
mov al,11
mov ah,07h ;couleur
int 63h


mov edx,msg_arobase
mov al,11
mov ah,07h ;couleur
int 63h


mov edx,[offset_chan]
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,msg_deuxpoint
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,[offset_msg]
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,msg_crlf
mov al,11
mov ah,07h ;couleur
int 63h

call affiche_saisie
jmp fin_traite_message



affiche_complet:
call efface_saisie

mov edx,zt_recep
mov al,11
mov ah,06h ;couleur
int 63h

mov edx,msg_crlf
mov al,11
mov ah,07h ;couleur
int 63h

call affiche_saisie
jmp fin_traite_message








commande_serveur:
cmp dword[zt_recep],"PING"
je repond_ping
cmp dword[zt_recep],"PONG"
je fin_traite_message

mov al,11             ;on affiche la commande reçu
mov ah,07h ;couleur
int 63h
mov edx,msg_crlf
mov al,11
mov ah,07h ;couleur
int 63h
jmp fin_traite_message



;répond a un PING
repond_ping:
mov dword[zt_recep],"PONG"
sub esi,2
mov word[esi],0A0Dh
mov ecx,esi
sub ecx,zt_recep-2
mov al,7
mov ebx,[adresse_canal]
mov esi,zt_recep
int 65h
jmp fin_traite_message



;replace les dernières données en début de zone (si besoin)
fin_traite_message:
mov edi,zt_recep
mov ecx,[index_recep]
add ecx,edi
sub ecx,esi
mov [index_recep],ecx
cmp ecx,0
je test_clavier
rep movsb



;*******************************************************
;gestion clavier
test_clavier:
mov al,5   ;lecture entrée clavier
int 63h
cmp al,0
je maj_aff
cmp al,1
je fin
cmp al,44
je touche_entre
cmp al,100
je touche_entre
cmp al,30
je touche_back
cmp al,0F0h
jae maj_aff

cmp ecx,0
je maj_aff
cmp ecx,80h   ;-de 7 bit
jb insert1
cmp ecx,800h  ;-de 11 bits
jb insert2
cmp ecx,10000h  ;-de 16 bits
jb insert3
cmp ecx,200000h   ;-de 21 bits
jb insert4
jmp maj_aff



insert1:
mov ebx,[index_message]
mov [ebx+message],cl

mov byte[ebx+message+1],0
mov ecx,1
jmp suite_insert


insert2:
mov ebx,[index_message]
mov eax,ecx
and al,3Fh
or al,80h
mov [ebx+message+1],al

shr ecx,6
mov al,cl
and al,01Fh
or al,0C0h
mov [ebx+message],al

mov byte[ebx+message+2],0
mov ecx,2
jmp suite_insert



insert3:
mov ebx,[index_message]
mov eax,ecx
and al,3Fh
or al,80h
mov [ebx+message+2],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [ebx+message+1],al
shr ecx,6
mov al,cl
and al,0Fh
or al,0E0h
mov [ebx+message],al

mov byte[ebx+message+3],0
mov ecx,3
jmp suite_insert



insert4:
mov ebx,[index_message]
mov eax,ecx
and al,3Fh
or al,80h
mov [ebx+message+3],al

shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [ebx+message+2],al

shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [ebx+message+1],al

shr ecx,6
mov al,cl
and al,07h
or al,0F0h
mov [ebx+message],al

mov byte[ebx+message+4],0
mov ecx,4
;jmp suite_insert

suite_insert:
call efface_saisie
add [index_message],ecx
inc dword[carac_message]
call affiche_saisie
jmp maj_aff




touche_entre:
call efface_saisie
mov ebx,[index_message]
mov word[ebx+message],0D0Ah
add dword[index_message],2
cmp byte[message],"/"
je touche_commande

;envoe message au channel
mov dword[zt_envoie],"PRIV"
mov dword[zt_envoie+4],"MSG "
mov dword[zt_envoie+8],"#"

mov edi,zt_envoie+9
mov esi,salon
call insert_chaine

mov word[edi]," :"
add edi,2

mov ecx,[index_message]
mov esi,message
rep movsb

mov ecx,edi
mov al,7
mov ebx,[adresse_canal]
mov esi,zt_envoie
sub ecx,esi
int 65h

mov ebx,[index_message]
mov byte[ebx+message],0



mov edx,msg_arobase
mov al,11
mov ah,02h ;couleur
int 63h


mov edx,salon
mov al,11
mov ah,02h ;couleur
int 63h

mov edx,msg_deuxpoint
mov al,11
mov ah,02h ;couleur
int 63h

mov edx,message
mov al,11
mov ah,02h ;couleur
int 63h






mov dword[index_message],0
mov dword[carac_message],0
mov byte[message],0
jmp maj_aff





touche_commande:
;§§§§§§§§§§§passe la commande en majuscule

mov al,7
mov ebx,[adresse_canal]
mov ecx,[index_message]
mov esi,message+1
dec ecx
int 65h

mov dword[index_message],0
mov dword[carac_message],0
mov byte[message],0
jmp maj_aff






touche_back:
call efface_saisie
cmp dword[carac_message],0
je fin_touche_back
dec dword[carac_message]
boucle_touche_back:
cmp dword[index_message],0
je fin_touche_back
dec dword[index_message]
mov ebx,[index_message]
mov al,[ebx+message]
and al,0C0h
cmp al,80h
je boucle_touche_back
mov dword[ebx+message],0
fin_touche_back:
call affiche_saisie


;jmp maj_aff



;met a jour l'affichage
maj_aff:
;§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp boucle




;***************************
fin:
int 60h



aff_err_param:
mov al,6
mov edx,msg_err1
int 61h
int 60h


aff_err_com:
mov al,6
mov edx,msg_err2
int 61h
int 60h



aff_err_cnx:
mov al,6
mov edx,msg_err3
int 61h
int 60h



;**********************************
insert_chaine:
mov al,[esi]
cmp al,0
je fin_insert_chaine
mov [edi],al
inc esi
inc edi
jmp insert_chaine 
fin_insert_chaine:
ret




rech_espace:
cmp byte[edx],0
je fin_rech_espace
cmp byte[edx]," "
je suite_rech_espace
inc edx
jmp rech_espace

suite_rech_espace:
inc edx
cmp byte[edx]," "
je rech_espace
fin_rech_espace:
ret



efface_saisie:
push ecx
push esi
mov ecx,[carac_message]
fs
mov esi,[ad_curseur_texte]
cmp ecx,0
jne boucle_efface_saisie
pop esi
pop ecx
ret
boucle_efface_saisie:
sub esi,4
fs
mov dword[esi],0
dec ecx
jnz boucle_efface_saisie 
fs
mov [ad_curseur_texte],esi
pop esi
pop ecx
ret


affiche_saisie:
push eax
push edx
mov edx,message
mov al,11
mov ah,0Ah ;couleur
int 63h
pop edx
pop eax
ret






;***************************************************
sdata1:
org 0
msg1:
db "quel est votre identifiant? ",0
msg2:
db 13,"aller sur quel salon? ",0

msg_err1:
db "CIRC: erreur de parametres, syntaxe correcte: circ [adresse] [port] [-c:X]",13
db "[adresse]  adresse du serveur IRC",13
db "[port] port du serveur IRC",13 
db "[-c:X] numéros de l'interface réseau (champ optionnel, 0 par défaut)",13,0
msg_err2:
db "CIRC: erreur lors de la connexion avec le serveur",13,0

msg_err3:
db "CIRC: perte de connexion avec le serveur",13,0



msg_arobase:
db "@",0
msg_deuxpoint:
db ":",0
msg_crlf:
db 13,0
msg_vide:
db 0

id_tache:
dw 0
adresse_canal:
dd 0


index_message:
dd 0
carac_message:
dd 0


offset_nom:
dd 0
offset_cmd:
dd 0
offset_chan:
dd 0
offset_msg:
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


identifiant:
rb 32
salon:
rb 32
message:
rb 256

commande:
rb 512

zt_envoie:
rb 512
zt_recep:
rb 512
zt_conv:


sdata2:
org 0
db 0;données du segment ES
sdata3:
org 0
;données du segment FS
sdata4:
org 0
;données du segment GS
findata:
