bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Ping ICMP"
scode:
org 0

;données du segment CS
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
mov [sequence],ax



;**************************************************************
;determine l'id du service ethernet
mov byte[zt_recep],0

mov al,5   
mov ah,"c"   ;lettre de l'option de commande a lire
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
je err_param
mov [id_tache],ax



;**************************************************************
;determine ip cible
mov byte[zt_recep],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h
cmp eax,0
jne err_param


mov al,109  
mov edx,zt_recep
mov ecx,adresse_cible
int 61h

cmp dword[adresse_cible],0
je err_param



;**************************************************************
;determine nombre de ping
mov byte[zt_recep],0

mov al,5
mov ah,"t"   ;lettre de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h
cmp eax,0
jne ignore_param2


mov al,100  
mov edx,zt_recep
int 61h

cmp ecx,0
je err_param
test ecx,0FFFFFF00h
jnz err_param

mov [nb_ping],cl

ignore_param2:

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

;configure 69
mov byte[zt_recep],9

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,zt_recep
mov edi,0
int 65h
cmp eax,0
jne err_cnx


;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne err_cnx

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,0
mov edi,zt_recep
int 65h
cmp eax,0
jne err_cnx

cmp byte[zt_recep],89h
jne err_cnx


;signal le début du test
mov al,6
mov edx,msg0a
call ajuste_langue
int 61h

mov al,112
mov ecx,adresse_cible
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6
mov edx,msg0b
int 61h



;**************************************************************
;envoie un ping a l'adresse
boucle_principale:

;prépare commande
mov word[zt_recep],128        ;ttl
mov eax,[adresse_cible]
mov [zt_recep+2],eax           ;adresse ipv4
mov dword[zt_recep+6],0        ;adresse ipv6
mov dword[zt_recep+10],0
mov dword[zt_recep+14],0
mov dword[zt_recep+18],0
mov byte[zt_recep+22],8        ;type 
mov byte[zt_recep+23],0        ;code
mov word[zt_recep+24],0        ;cheksum
mov ax,[sequence]
mov word[zt_recep+26],ax       ;identifiant
inc ax
mov word[zt_recep+28],ax       ;numeros de séquence
mov dword[zt_recep+30],"SALU"  ;data bidon (un ptit message a la noix)
mov dword[zt_recep+34],"T DU"
mov dword[zt_recep+38]," SYS"
mov dword[zt_recep+42],"TEME"
mov dword[zt_recep+46]," D'E"
mov dword[zt_recep+50],"XPLO"
mov dword[zt_recep+54],"ITAT"
mov dword[zt_recep+58],"ION "
mov dword[zt_recep+62],"SEaC"


;lit le compteur temp
mov eax,12          
int 61h
mov[cptsf],eax


;envoie le message
mov al,7
mov ebx,[adresse_canal]
mov ecx,66
mov esi,zt_recep
int 65h


;attend la réponse
mov ecx,600
continue_attente:
mov al,9
mov ebx,[adresse_canal]
int 65h
cmp eax,cer_ddi
jne erreur_ping


;lit la réponse
mov al,6
mov ebx,[adresse_canal]
mov ecx,512
mov edi,zt_recep
int 65h


;vérifie validité du résultat
mov ecx,600
mov eax,12          
int 61h
sub eax,[cptsf]
sub ecx,eax
cmp word[zt_recep+22],0
jne continue_attente 


;affiche le résultat
mov al,6
mov edx,msg1a
call ajuste_langue
int 61h

mov al,112
mov ecx,zt_recep+2
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6
mov edx,msg1b
call ajuste_langue
int 61h

mov eax,12          
int 61h
sub eax,[cptsf]
cmp eax,0
je temps_court

xor edx,edx
mov ecx,25
mul ecx
mov ecx,10
div ecx

mov ecx,eax
mov al,102
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6
mov edx,msg1d
int 61h

inc byte[ping_ok]
jmp suite_boucle


temps_court:
mov al,6
mov edx,msg1c
call ajuste_langue
int 61h

inc byte[ping_ok]
jmp suite_boucle


;si pas de réponse affiche un message d'erreur
erreur_ping:  
mov al,6
mov edx,msg2
call ajuste_langue
int 61h
inc byte[ping_erreur]


suite_boucle:
mov al,[nb_ping]
inc byte[ping_effectue]
inc word[sequence]
cmp byte[ping_effectue],al
jne boucle_principale




;affiche la synthèse
mov al,6
mov edx,msg3a
call ajuste_langue
int 61h

mov al,102
xor ecx,ecx
mov cl,[ping_effectue]
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6
mov edx,msg3b
call ajuste_langue
int 61h

mov al,102
xor ecx,ecx
mov cl,[ping_ok]
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6
mov edx,msg3c
call ajuste_langue
int 61h

mov al,102
xor ecx,ecx
mov cl,[ping_erreur]
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov al,6
mov edx,msg3d
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




;**************************************************************
err_param:
mov al,6
mov edx,msg_err1
call ajuste_langue
int 61h
int 60h


err_cnx:
mov al,6
mov edx,msg_err2
call ajuste_langue
int 61h
int 60h

sdata1:
org 0
id_tache:
dw 0
adresse_canal:
dd 0
adresse_cible:
dd 0
nb_ping:
db 4
sequence:
dw 0
cptsf:
dd 0
ping_effectue:
db 0
ping_erreur:
db 0
ping_ok:
db 0


msg0a:
db 13,"PING: test connection to ",0
db 13,"PING: test de connexion vers ",0
msg0b:
db 13,0

msg1a:
db "Response from ",0
db "Réponse de ",0
msg1b:
db " received in ",0
db " reçu en ",0
msg1c:
db "less than 2ms",13,0
db "moins de 2ms",13,0
msg1d:
db "ms",13,0


msg2:
db "Response timeout exceeded",13,0
db "Délais d'attente de réponse dépassé",13,0


msg3a:
db 13,"PING: connection test result:",13,"Sent: ",0
db 13,"PING: résultat des tests de connexion:",13,"Envoyé: ",0
msg3b:
db "  Received: ",0
db "  Reçu: ",0
msg3c:
db "  Lost: ",0
db "  Perdu: ",0
msg3d:
db 13,0





msg_err1:
db "PING: command line syntax error. enter ",22h,"man ping",22h," for correct syntax",13,0
db "PING: erreur dans la sytaxe de la ligne de commande. entrez ",22h,"man ping",22h," pour avoir la syntaxe correcte",13,0

msg_err2:
db "PING: error while communicating with the network interface",13,0
db "PING: erreur lors de la communication avec l'interface réseau",13,0

tempo:
dd 0,0,0,0,0,0,0,0,0,0,0,0

zt_recep:
rb 512

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
