circ:
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

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h

cmp byte[zt_recep],0
je aff_err_param

mov al,100  
mov edx,zt_recep
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

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
mov ah,1   ;numéros de l'option de commande a lire
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
mov ah,2   ;numéros de l'option de commande a lire
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

mov dx,sel_dat1    ;variable du programme
mov ds,dx
mov es,dx
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
;************************************************************
;test si donné reçu

mov al,6
mov ebx,[adresse_canal]
mov edi,zt_recep
mov ecx,511
int 65h
cmp eax,0
jne aff_err_cnx
cmp ecx,0
je test_clavier












mov byte[ecx+zt_recep],0
mov edx,zt_recep
mov al,11
mov ah,07h ;couleur
int 63h



;répond a un PING







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
mov [zt_recep],cl

mov byte[zt_recep+1],0
mov edx,zt_recep
mov al,11
mov ah,0Ah ;couleur
int 63h

inc dword[index_message]
jmp maj_aff


insert2:
mov ebx,[index_message]
mov eax,ecx
and al,3Fh
or al,80h
mov [ebx+message+1],al
mov [zt_recep+1],al
shr ecx,6
mov al,cl
and al,01Fh
or al,0C0h
mov [ebx+message],al
mov [zt_recep],al

mov byte[zt_recep+2],0
mov edx,zt_recep
mov al,11
mov ah,0Ah ;couleur
int 63h

add dword[index_message],2    
jmp maj_aff



insert3:
mov ebx,[index_message]
mov eax,ecx
and al,3Fh
or al,80h
mov [ebx+message+2],al
mov [zt_recep+2],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [ebx+message+1],al
mov [zt_recep+1],al
shr ecx,6
mov al,cl
and al,0Fh
or al,0E0h
mov [ebx+message],al
mov [zt_recep],al

mov byte[zt_recep+3],0
mov edx,zt_recep
mov al,11
mov ah,0Ah ;couleur
int 63h

add dword[index_message],3    
jmp maj_aff



insert4:
mov ebx,[index_message]
mov eax,ecx
and al,3Fh
or al,80h
mov [ebx+message+3],al
mov [zt_recep+3],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [ebx+message+2],al
mov [zt_recep+2],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [ebx+message+1],al
mov [zt_recep+1],al
shr ecx,6
mov al,cl
and al,07h
or al,0F0h
mov [ebx+message],al
mov [zt_recep],al

mov byte[zt_recep+4],0
mov edx,zt_recep
mov al,11
mov ah,0Ah ;couleur
int 63h

add dword[index_message],4    
jmp maj_aff








touche_entre:
mov ebx,[index_message]
mov word[ebx+message],0D0Ah
add dword[index_message],2
cmp byte[message],"/"
je touche_commande

;envoe message au channel
mov dword[zt_recep],"PRIV"
mov dword[zt_recep+4],"MSG "
mov dword[zt_recep+8],"#"

mov edi,zt_recep+9
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
mov esi,zt_recep
sub ecx,esi
int 65h

mov dword[index_message],0
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
jmp maj_aff






touche_back:
cmp dword[index_message],0
je maj_aff
dec dword[index_message]
mov ebx,[index_message]
mov al,[ebx+message]
and al,0C0h
cmp al,80h
je touche_back


mov byte[zt_recep],"#"
mov byte[zt_recep+1],0
mov edx,zt_recep
mov al,11
mov ah,10h ;couleur
int 63h


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












;***************************************************
sdata1:
org 0
msg1:
db "quel est votre identifiant? ",0
msg2:
db 13,"aller sur quel salon? ",0

msg_err1:
db "CIRC: erreur de parametres, sytax correcte: circ X YYY ZZ",13
db "X   = numéros de l'interface réseau",13
db "YYY = adresse du serveur",13
db "ZZ  = port du serveur",13,0

msg_err2:
db "CIRC: erreur lors de la connexion avec le serveur",13,0

msg_err3:
db "CIRC: perte de connexion avec le serveur",13,0



id_tache:
dw 0
adresse_canal:
dd 0


index_message:
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

identifiant:
rb 32
salon:
rb 32
message:
rb 256

commande:
rb 512

zt_recep:
rb 512


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
