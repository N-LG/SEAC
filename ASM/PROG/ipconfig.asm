ipconfig:   
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "lecture et configuration des parametre de cartes ethernet"
scode:
org 0
mov ax,sel_dat1
mov ds,ax
mov es,ax

mov al,11
mov ah,6     ;code service carte ethernet 
mov cl,16
mov edx,zt_liste
int 61h

cmp word[zt_liste],0
je aucunescarte


mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,128 ;octet max
mov edx,zt_param0
int 61h

cmp byte[zt_param0],0
je affichage_param 

mov eax,100
mov edx,zt_param0
int 61h

cmp ecx,8
jae erreurparam 
shl ecx,1
mov dx,[ecx+zt_liste]
cmp dx,0
je carteinexistante
mov [id_carte],dx

mov al,4   
mov ah,1   ;numéros de l'option de commande a lire
mov cl,128 ;octet max
mov edx,zt_param1
int 61h
cmp byte[zt_param1],0
je erreurparam 

mov al,4   
mov ah,2   ;numéros de l'option de commande a lire
mov cl,128 ;octet max
mov edx,zt_param2
int 61h
;cmp byte[zt_param2],0
;je erreurparam







;******************************************************
;lire config actuelle


;créer un canal de communication
mov bx,[id_carte]
mov al,0
mov ecx,64
mov esi,0
mov edi,0
int 65h

mov [adresse_canal],ebx

;envoie la commande de lecture info carte
mov word[zt_commande],02h
mov al,5
mov ebx,[adresse_canal]
mov ecx,2h
mov edi,0
mov esi,zt_commande
int 65h

;regarde si on as une réponse (une modification du descripteur
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne erreur_com 

mov al,4
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,0
mov edi,zt_commande
int 65h
cmp byte[zt_commande],82h
jne erreur_com



;cherche le nom du parametre a modifier
cmp byte[zt_param1+4],0
jne erreurparam
cmp dword[zt_param1],"comp"
je chg_comp
cmp dword[zt_param1],"ipv4"
je chg_ipv4
cmp dword[zt_param1],"mas4"
je chg_mas4
cmp dword[zt_param1],"pas4"
je chg_pas4
cmp dword[zt_param1],"amac"
je chg_mac
cmp dword[zt_param1],"ip6p"
je chg_ip6p
cmp dword[zt_param1],"ip6g"
je chg_ip6g
cmp dword[zt_param1],"auto"
je chg_auto
jmp erreurparam


;*************************************************
;modifie un seul parametre 
chg_mac:
mov eax,108
mov edx,zt_param2
mov ecx,adresse_mac
int 61h
jmp ecrire_config

chg_ipv4:
mov eax,109
mov edx,zt_param2
mov ecx,adresse_ipv4
int 61h
jmp ecrire_config

chg_mas4:
mov eax,109
mov edx,zt_param2
mov ecx,masque_ipv4
int 61h
jmp ecrire_config

chg_pas4:
mov eax,109
mov edx,zt_param2
mov ecx,passerelle_ipv4
int 61h
jmp ecrire_config

chg_ip6p:
mov eax,110
mov edx,zt_param2
mov ecx,adresse_ipv6_prive
int 61h
jmp ecrire_config

chg_ip6g:
mov eax,110
mov edx,zt_param2
mov ecx,adresse_ipv6_global
int 61h
jmp ecrire_config







;*************************************************************
;modifie tout les parametres
chg_comp:
mov eax,109
mov edx,zt_param2
mov ecx,adresse_ipv4
int 61h

mov al,4   
mov ah,3   ;numéros de l'option de commande a lire
mov cl,128 ;octet max
mov edx,zt_param2
int 61h
cmp byte[zt_param2],0
je erreurparam

mov eax,109
mov edx,zt_param2
mov ecx,masque_ipv4
int 61h

mov al,4   
mov ah,4   ;numéros de l'option de commande a lire
mov cl,128 ;octet max
mov edx,zt_param2
int 61h
cmp byte[zt_param2],0
je erreurparam

mov eax,109
mov edx,zt_param2
mov ecx,passerelle_ipv4
int 61h

mov al,4   
mov ah,5   ;numéros de l'option de commande a lire
mov cl,128 ;octet max
mov edx,zt_param2
int 61h
cmp byte[zt_param2],0
je erreurparam

mov eax,110
mov edx,zt_param2
mov ecx,adresse_ipv6_prive
int 61h

mov al,4   
mov ah,6   ;numéros de l'option de commande a lire
mov cl,128 ;octet max
mov edx,zt_param2
int 61h
cmp byte[zt_param2],0
je erreurparam

mov eax,110
mov edx,zt_param2
mov ecx,adresse_ipv6_global
int 61h


;******************************************************
ecrire_config:
;envoie la commande d'écriture info carte
mov word[zt_commande],03h
mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov edi,0
mov esi,zt_commande
int 65h

;regarde si on as une réponse (une modification du descripteur)
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne erreur_com 

mov al,4
mov ebx,[adresse_canal]
mov ecx,2h
mov esi,0
mov edi,zt_commande
int 65h
cmp byte[zt_commande],83h
jne erreur_com
jmp affichage_param




;******************************************************
;demande la config auto via dhcp
chg_auto:
;envoie la commande de demande de config par DHCP
mov word[zt_commande],0Ah
mov al,5
mov ebx,[adresse_canal]
mov ecx,2
mov edi,0
mov esi,zt_commande
int 65h

;regarde si on as une réponse (une modification du descripteur)
mov al,8
mov ebx,[adresse_canal]
mov ecx,10000  ;10s
int 65h
cmp eax,cer_ddi
jne erreur_com 

mov al,4
mov ebx,[adresse_canal]
mov ecx,2h
mov esi,0
mov edi,zt_commande
int 65h
cmp byte[zt_commande],8Ah
jne erreur_com
;jmp affichage_param


;*****************************************************************
affichage_param:
mov al,6        
mov edx,msg_info1
call ajuste_langue
int 61h

mov ebp,zt_liste
boucle:

mov ebx,ebp
mov ax,[ebx]
cmp ax,0
je fin

mov bx,ax
mov al,0
mov ecx,64
mov esi,0
mov edi,0
int 65h

mov [adresse_canal],ebx

;envoie la commande de lecture info carte
mov word[zt_commande],02h
mov al,5
mov ebx,[adresse_canal]
mov ecx,2h
mov edi,0
mov esi,zt_commande
int 65h

;regarde si on as une réponse (une modification du descripteur
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne test_autre 

mov al,4
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,0
mov edi,zt_commande
int 65h
cmp byte[zt_commande],82h
jne test_autre



mov al,6        
mov edx,msg2
call ajuste_langue
int 61h
mov al,102
mov ecx,ebp
sub ecx,zt_liste
shr ecx,1
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h


mov al,6        
mov edx,msg3
call ajuste_langue
int 61h
mov al,111
mov ecx,adresse_mac
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6        
mov edx,msg4
call ajuste_langue
int 61h
mov al,112
mov ecx,adresse_ipv4
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6        
mov edx,msg5
call ajuste_langue
int 61h
mov al,112
mov ecx,masque_ipv4
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6        
mov edx,msg6
call ajuste_langue
int 61h
mov al,112
mov ecx,passerelle_ipv4
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6        
mov edx,msg7
call ajuste_langue
int 61h
mov al,113
mov ecx,adresse_ipv6_lien
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6        
mov edx,msg8
call ajuste_langue
int 61h
mov al,113
mov ecx,adresse_ipv6_prive
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6        
mov edx,msg9
call ajuste_langue
int 61h
mov al,113
mov ecx,adresse_ipv6_global
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6        
mov edx,msg10
int 61h

test_autre:
add ebp,2
jmp boucle


aucunescarte:
mov al,6        
mov edx,msg_info2
call ajuste_langue
int 61h

fin:
int 60h



carteinexistante:
mov al,6        
mov edx,msg_info3
call ajuste_langue
int 61h
int 60h


erreurparam:
mov al,6        
mov edx,msg_info4
call ajuste_langue
int 61h
int 60h

erreur_com:
mov al,6        
mov edx,msg_info5
call ajuste_langue
int 61h
int 60h




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


msg_info1:
db 13,"configuration of network cards:",13,0 
db 13,"configuration des cartes réseaux:",13,0 

msg_info2:
db "IPCONFIG: no network adapters detected",13,0
db "IPCONFIG: aucunes cartes réseau détecté",13,0


msg_info3:
db "IPCONFIG: the selected card does not exist",13,0
db "IPCONFIG: la carte selectionné n'existe pas",13,0

msg_info4:
db "IPCONFIG: command line syntax error. enter ",22h,"man ipconfig",22h," for correct syntax",13,0
db "IPCONFIG: erreur dans la sytaxe de la ligne de commande. entrez ",22h,"man ipconfig",22h," pour avoir la syntaxe correcte",13,0

msg_info5:
db "IPCONFIG: communication error with the card",13,0
db "IPCONFIG: erreur de communication avec la carte",13,0


msg2:
db 13,"carte ",0
db 13,"carte ",0
msg3:
db 13,"    MAC adress:   ",0
db 13,"    adresse MAC:  ",0
msg4:
db 13,"    IPv4 adress:     ",0
db 13,"    adresse IPv4:    ",0
msg5: 
db 13,"    IPv4 mask:       ",0
db 13,"    masque IPv4:     ",0
msg6:
db 13,"    IPv4 gateway:    ",0
db 13,"    passerelle IPv4: ",0
msg7:
db 13,"    local IPv6 adress:    ",0
db 13,"    adresse IPv6 lien:    ",0
msg8:
db 13,"    private IPv6 adress:  ",0
db 13,"    adresse IPv6 privée:  ",0
msg9:
db 13,"    global IPv6 adress:   ",0
db 13,"    adresse IPv6 globale: ",0
msg10:
db 13,0

adresse_canal:
dd 0

msgtrappe:
db "trappe!",13,0

tempo:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0

id_carte:
dw 0

zt_liste:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0

zt_commande:
dw 0
adresse_mac:
dw 0,0,0
adresse_ipv4:
dd 0
masque_ipv4:
dd 0
passerelle_ipv4:
dd 0
adresse_ipv6_lien:
dd 0,0,0,0
adresse_ipv6_prive:
dd 0,0,0,0
adresse_ipv6_global:
dd 0,0,0,0


zt_param0:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

zt_param1:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

zt_param2:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0



sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
