bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Client DNS"
scode:
org 0

;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax



;lit le nom du destinataire a rechercher
mov al,4   
mov ah,1   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,recherche
int 61h
cmp byte[recherche],0
je erreur_param

;génère un numéros de port local pseudo aléatoirement
mov eax,9
int 61h
xor ax,bx
xor ax,cx
xor ax,dx
xor ax,0CA71h
mov [local_port],ax

xor ax,0803Ch
mov [requete_dns],ax   ;et un numéros de requete


;**************************************************************
;determine l'id du service ethernet
mov byte[data_dns],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,data_dns
int 61h

cmp byte[data_dns],0
je erreur_param

mov al,100  
mov edx,data_dns
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,data_dns
int 61h

shl ebx,1
mov ax,[data_dns+ebx]
cmp ax,0
je erreur_param
mov [id_tache],ax



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

;configure en écoute pour un port UDP 
mov ax,[local_port]
mov byte[data_dns],7
mov [data_dns+2],ax

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,data_dns
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
mov edi,data_dns
int 65h
cmp eax,0
jne erreur_ouv_port

cmp byte[data_dns],87h
jne erreur_ouv_port


;créer une requete DNS
mov dword[index_serveur],serveurs_dns
boucle_test_different_serveur:

mov word[port_out],53
mov ebx,[index_serveur]
mov eax,[ebx]
mov [ipv4_out],eax


;mov word[requete_dns],????
mov byte[qropcode],1  
mov byte[razrcode],0
mov word[qdcount],100h   ;1 ordre inversé
mov word[ancount],0
mov word[nscount],0
mov word[arcount],0

mov esi,recherche
mov edi,data_dns+1
mov ecx,64
rep movsd

;transforme le nom en chaine valide pour le serveur
mov esi,data_dns
mov edi,data_dns+1

boucle_conversion_nom:
cmp byte[edi],0
je fin_conversion_nom
cmp byte[edi],"."
jne point_conversion_nom
mov eax,edi
sub eax,esi
dec al
mov [esi],al
mov esi,edi

point_conversion_nom:
inc edi
jmp boucle_conversion_nom 


fin_conversion_nom:
mov eax,edi
sub eax,esi
dec al
mov [esi],al
mov byte[edi],0
inc edi

mov word[edi],100h       ;type (ordre inversé)
mov word[edi+2],100h     ;classe (ordre inversé)


;envoie la requete dns
mov al,7
mov ebx,[adresse_canal]
mov ecx,edi
sub ecx,port_out-4
mov esi,port_out
int 65h
cmp eax,0
jne erreur_ouv_port


;attend serveur réponse
mov al,9
mov ebx,[adresse_canal]
mov ecx,200
int 65h
cmp eax,cer_ddi
je okdata



;si temps écoulé renvoie la demande a un autre serveur
aucune_reponse:
mov edx,msg_nrep1
mov al,6        
int 61h

mov ecx,ipv4_out
mov edx,tempo
mov al,112
int 61h
mov edx,tempo
mov al,6
int 61h

mov edx,msg_nrep2
mov al,6        
int 61h

mov edx,recherche
mov al,6        
int 61h

mov edx,msg_nrep3
mov al,6        
int 61h


add dword[index_serveur],4
cmp dword[index_serveur],fin_serveurs_dns
jne boucle_test_different_serveur

;si tout serveur passé fin
int 60h

;***********************
erreur_ouv_port:
mov edx,msg_err1
mov al,6        
int 61h
int 60h


;*****************
erreur_param:
mov edx,msg_err2
mov al,6        
int 61h
int 60h

;************************
;lecture et affichage info réponse
okdata:
mov al,6
mov ebx,[adresse_canal]
mov ecx,512
mov edi,port_out
int 65h
cmp eax,0
jne erreur_ouv_port


mov ax,[ancount]   ;remet dans l'ordre le answer count
xchg al,ah
mov [ancount],ax
cmp ax,0
je aucune_reponse

mov edx,msg_rep1
mov al,6        
int 61h

mov ecx,ipv4_out
mov edx,tempo
mov al,112
int 61h
mov edx,tempo
mov al,6
int 61h

mov edx,msg_rep2
mov al,6        
int 61h

mov edx,recherche
mov al,6        
int 61h

mov edx,msg_rep3
mov al,6        
int 61h

mov ebx,requete_dns+12
call passer_nom_rr
add ebx,4   ;on passe la question


boucle_affichage:    ;affichage des réponses
mov edx,ebx
call passer_nom_rr
cmp dword[ebx],1000100h
jne suite_boucle_affichage

call affiche_nom_rr

mov edx,msg_rep4
mov al,6        
int 61h

mov ecx,ebx
add ecx,10
mov edx,tempo
mov al,112
int 61h
mov edx,tempo
mov al,6
int 61h

mov edx,msg_rep5
mov al,6        
int 61h

suite_boucle_affichage:
xor eax,eax
add ebx,8
mov ax,[ebx]
add ebx,2
xchg al,ah
add ebx,eax

dec word[ancount]
jnz boucle_affichage

int 60h





;***********************
passer_nom_rr:
mov al,[ebx]
cmp al,0
je fin1_passer_nom_rr
and al,0C0h
cmp al,0C0h
je fin2_passer_nom_rr
xor eax,eax
mov al,[ebx]
inc eax
add ebx,eax
jmp passer_nom_rr

fin1_passer_nom_rr:
inc ebx
ret

fin2_passer_nom_rr:
add ebx,2
ret


;************************
affiche_nom_rr:
push ebx
mov ebx,edx

boucle_afficher_nom:
mov al,[ebx]
cmp al,0
je fin_afficher_nom
and al,0C0h
cmp al,0C0h
je saut_afficher_nom
xor eax,eax
mov al,[ebx]
inc ebx
mov edx,ebx
add ebx,eax
mov ah,0

xchg [ebx],ah
push eax
mov al,6        
int 61h
pop eax
xchg [ebx],ah

cmp byte[ebx],0
je fin_afficher_nom
mov edx,msg_point
mov al,6
int 61h
jmp boucle_afficher_nom


saut_afficher_nom:
mov ax,[ebx]
xchg al,ah
and eax,03FFFh
mov ebx,requete_dns
add ebx,eax
jmp boucle_afficher_nom


fin_afficher_nom:
pop ebx
ret




sdata1:
org 0
id_tache:
dw 0
adresse_canal:
dd 0
index_serveur:
dd 0
local_port:
dw 0


msg_err1:
db "CDNS: erreur lors de l'ouverture du port UDP",13,0
msg_err2:
db "CDNS: erreur dans la commande, sytaxe correct: cdns X YYYY",13
db "X   = numéros de l'interface réseau",13
db "YYY = nom de domaine recherché",13,0








msg_rep1:
db "CDNS: Réponse du serveur DNS ",0
msg_rep2:
db " pour ",0
msg_rep3:
db ":",13,0
msg_rep4:
db " = ",0
msg_rep5:
db 13,0

msg_point:
db ".",0

msg_nrep1:
db "CDNS: le serveur ",0
msg_nrep2:
db " ne connait pas ",0
msg_nrep3:
db 13,0


serveurs_dns:
db 192,168,1,1
;google
db 8,8,8,8
db 8,8,4,4
;verisign
db 64,6,64,6
db 64,6,65,6
;fdn
db 80,67,169,12
db 80,67,169,40
fin_serveurs_dns:



tempo:
rb 256




;**********************trame udp
port_out:
rb 2
ipv4_out:
rb 4
ipv6_out:
rb 16

requete_dns:
rb 2
qropcode:
rb 1
razrcode:
rb 1
qdcount:
rb 2
ancount:
rb 2
nscount:
rb 2
arcount:
rb 2
data_dns:
rb 500



recherche:
rb 256












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
