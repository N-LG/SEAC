bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "service de résolution DNS"
scode:
org 0

;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax



;lit le nom du serveur a interroger spécifiquement (param optionel)
mov al,5
mov ah,"s" 
mov cl,0 ;0=256 octet max
mov edx,tempo
mov byte[tempo],0
int 61h
cmp byte[tempo],0
je @f

mov al,109  
mov edx,tempo
mov ecx,serveurs_dns
int 61h
mov dword[serveurs_dns+4],0
@@:


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

mov al,5   
mov ah,"c"   ;lettre de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,data_dns
int 61h
xor ebx,ebx
cmp eax,0
jne @f

mov al,100  
mov edx,data_dns
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

@@:
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





;******************************************************************************************
;lit le nom du destinataire a rechercher
mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,recherche
int 61h
cmp byte[recherche],0
je service_uniquement


;lit le numéros du type de requete (param optionel)
mov al,5
mov ah,"t" 
mov cl,0 ;0=256 octet max
mov edx,tempo
mov byte[tempo],0
int 61h
cmp byte[tempo],0
je @f

mov al,100  
mov edx,tempo
int 61h
;cmp ecx,0
;je @f
mov [no_requete],cx
@@:


call envoyer_requete
cmp eax,1
je fin
cmp eax,0
jne erreur_ouv_port





;************************
;affichage info réponse


mov ax,[qdcount]   ;remet dans l'ordre le qdswer count
xchg al,ah
mov [qdcount],ax

mov ax,[ancount]   ;remet dans l'ordre le answer count
xchg al,ah
mov [ancount],ax
cmp ax,0
je aucune_reponse

mov edx,msg_rep1
call ajuste_langue
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
call ajuste_langue
mov al,6        
int 61h

mov edx,recherche
mov al,6        
int 61h

mov edx,msg_rep3
mov al,6        
int 61h

mov ebx,requete_dns+12
@@:    ;on passe les question
call passer_nom_rr
add ebx,4   
dec word [qdcount]
jnz @b

boucle_affichage:    ;affichage des réponses
mov edx,ebx
call passer_nom_rr
cmp dword[ebx],1000100h
je affichage_ipv4
cmp dword[ebx],1001C00h
je affichage_ipv6
cmp dword[ebx],1000200h
je affichage_ns
cmp dword[ebx],1000F00h
je affichage_mx
cmp dword[ebx],1001000h
je affichage_txt
cmp dword[ebx],1000500h
je affichage_cname
cmp dword[ebx],1000600h
je affichage_soa




;affiche les RR inconnus
call affiche_nom_rr

mov edx,msg_rep6
mov al,6        
int 61h

xor ecx,ecx
mov cx,[ebx]
xchg cl,ch
mov edx,tempo
mov al,102
int 61h
mov edx,tempo
mov al,6
int 61h

mov edx,msg_rep7
mov al,6        
int 61h

xor ecx,ecx
mov esi,ebx
mov cx,[ebx+8]
add esi,10
xchg cl,ch

@@:
push ecx
mov cl,[esi]
mov edx,tempo
mov al,105
int 61h
mov edx,tempo
mov al,6
int 61h
mov edx,msg_espace
mov al,6
int 61h
pop ecx
inc esi
dec ecx
jnz @b


mov edx,msg_rep5
mov al,6        
int 61h

jmp suite_boucle_affichage



;**************
affichage_ns:
call affiche_nom_rr

mov edx,msg_rep_ns
mov al,6        
int 61h

mov edx,ebx
add edx,10
call affiche_nom_rr

mov edx,msg_rep5
mov al,6        
int 61h

jmp suite_boucle_affichage


;**************
affichage_mx:
call affiche_nom_rr

mov edx,msg_rep_mx
mov al,6        
int 61h

mov edx,ebx
add edx,12
call affiche_nom_rr

mov edx,msg_rep5
mov al,6        
int 61h

jmp suite_boucle_affichage


;**************
affichage_txt:
call affiche_nom_rr

mov edx,msg_rep_txt
mov al,6        
int 61h

xor ecx,ecx
mov edx,ebx
add edx,10
mov esi,edx
mov edi,edx
inc esi
mov cl,[edx]
cld
rep movsb
mov byte[edi],0

mov al,6        
int 61h

mov edx,msg_rep5
mov al,6        
int 61h

jmp suite_boucle_affichage


;**************
affichage_soa:
call affiche_nom_rr

mov edx,msg_rep_soa
mov al,6        
int 61h

mov edx,ebx
add edx,10
call affiche_nom_rr

mov edx,msg_espace
mov al,6        
int 61h

push ebx
add ebx,10
call passer_nom_rr
mov edx,ebx
pop ebx
call affiche_nom_email

mov edx,msg_rep5
mov al,6        
int 61h

jmp suite_boucle_affichage



;**************
affichage_cname:
call affiche_nom_rr

mov edx,msg_rep_cname
mov al,6        
int 61h

mov edx,ebx
add edx,10
call affiche_nom_rr

mov edx,msg_rep5
mov al,6        
int 61h

jmp suite_boucle_affichage




;**************
affichage_ipv6:
call affiche_nom_rr

mov edx,msg_rep4
mov al,6        
int 61h

mov ecx,ebx
add ecx,10
mov edx,tempo
mov al,113
int 61h
mov edx,tempo
mov al,6
int 61h

mov edx,msg_rep5
mov al,6        
int 61h

jmp suite_boucle_affichage


;*****************
affichage_ipv4:
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


;********************
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
erreur_ouv_port:
mov edx,msg_err1
call ajuste_langue
mov al,6        
int 61h
int 60h


;*****************
erreur_param:
mov edx,msg_err2
call ajuste_langue
mov al,6        
int 61h
int 60h



;***********
fin:
int 60h








;***************************************************
envoyer_requete:
;créer une requete DNS
mov dword[index_serveur],serveurs_dns
boucle_test_different_serveur:

mov word[port_out],53
mov ebx,[index_serveur]
mov eax,[ebx]
cmp eax,0
je fin_envoyer_requete
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

mov ax,[no_requete]
xchg al,ah
mov word[edi],ax       ;type (ordre inversé)
mov word[edi+2],100h     ;classe internet(ordre inversé)



;envoie la requete dns
mov al,7
mov ebx,[adresse_canal]
mov ecx,edi
sub ecx,port_out-4
mov esi,port_out
int 65h
cmp eax,0
jne erreur_envoyer_requete


;attend serveur réponse
mov al,9
mov ebx,[adresse_canal]
mov ecx,300
int 65h
cmp eax,cer_ddi
je okdata


;si temps écoulé renvoie la demande a un autre serveur
aucune_reponse:
mov edx,msg_nrep1
call ajuste_langue
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
call ajuste_langue
mov al,6        
int 61h

mov edx,recherche
mov al,6        
int 61h

mov edx,msg_nrep3
mov al,6        
int 61h


add dword[index_serveur],4
jmp boucle_test_different_serveur




;************************
;lecture et affichage info réponse
okdata:
mov al,6
mov ebx,[adresse_canal]
mov ecx,512
mov edi,port_out
int 65h
erreur_envoyer_requete:
ret


fin_envoyer_requete:
mov eax,1
ret





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
mov eax,ebx
inc eax
pop ebx
ret



;************************
affiche_nom_email:
push ebx
mov ebx,edx

boucle_afficher_email:
mov al,[ebx]
cmp al,0
je fin_afficher_email
and al,0C0h
cmp al,0C0h
je saut_afficher_email
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
je fin_afficher_email
mov edx,msg_point
mov al,6
int 61h
jmp boucle_afficher_email


saut_afficher_email:
mov ax,[ebx]
xchg al,ah
and eax,03FFFh
mov ebx,requete_dns
add ebx,eax
jmp boucle_afficher_email


fin_afficher_email:
mov eax,ebx
inc eax
pop ebx
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











;******************************************
service_uniquement:
;test si il existe déja un service dns
mov word[tempo],0
mov al,11
mov ah,8     ;code service résolution dns
mov cl,16
mov edx,tempo
int 61h
cmp word[tempo],0
jne fin

;se déclare comme service dns
mov al,10
mov ah,8 ;code service résolution dns
int 61h

mov edx,msg_serv
call ajuste_langue
mov al,6        
int 61h

;boucle service dns

boucle_service:
int 62h

;recherche si il y as une nouvelle connexion
mov al,2
int 65h
cmp eax,cer_ddi
jne boucle_service

;lit la requete
mov al,4
mov ecx,8 
mov esi,0
mov edi,tempo
int 65h
cmp eax,0
jne ferme_connexion

;test de quel type est la requete
cmp byte[tempo],1
je requete_info_rr

;ferme la connexion si la requete est inconnue
ferme_connexion:
mov al,1
int 65h
jmp boucle_service 


requete_info_rr:
;recup champ recherché
mov ax,[tempo+2]
mov [no_requete],ax

;recup nom recherché
mov al,4
mov ecx,[tempo+4] 
mov esi,8
mov edi,recherche
int 65h
cmp eax,0
jne ferme_connexion




;recherche....
push ebx
call envoir_requete
pop ebx
cmp eax,0
jne ferme_connexion 


;envoie réponse!
mov byte[tempo],81h

;recopie RR
;??????????????????????????

mov al,5
mov ecx,8 
mov edi,0
mov esi,tempo
int 65h
jmp boucle_service












jmp boucle_service


int 60h



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
no_requete:
dw 255


msg_serv:
db "CDNS: the DNS resolver service has started",13,0
db "CDNS: le service de résolution DNS as démarré",13,0

msg_err1:
db "CDNS: error while opening UDP port",13,0
db "CDNS: erreur lors de l'ouverture du port UDP",13,0
msg_err2:
db "CDNS: command line syntax error. enter ",22h,"man cdns",22h," for correct syntax",13,0
db "CDNS: erreur dans la sytaxe de la ligne de commande. entrez ",22h,"man cdns",22h," pour avoir la syntaxe correcte",13,0


msg_rep1:
db "CDNS: DNS server response ",0
db "CDNS: Réponse du serveur DNS ",0
msg_rep2:
db " for ",0
db " pour ",0
msg_rep3:
db ":",13,0
msg_rep4:
db " = ",0
msg_rep5:
db 13,0

msg_rep6:
db " [",0
msg_rep7:
db "] ",0


msg_rep_hinfo:
db " [HINFO] ",0
msg_rep_ns:
db " [NS] ",0
msg_rep_mx:
db " [MX] ",0
msg_rep_txt:
db " [TXT] ",0
msg_rep_soa:
db " [SOA] ",0
msg_rep_caa:
db " [CAA] ",0
msg_rep_cname:
db " [CNAME] ",0



msg_point:
db ".",0
msg_espace:
db "  ",0

msg_nrep1:
db "CDNS: the ",0
db "CDNS: le serveur ",0
msg_nrep2:
db " server does not know ",0
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
db 0,0,0,0



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
