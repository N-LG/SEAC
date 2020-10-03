stlnt:
pile equ 4096 ;definition de la taille de la pile
include "../PROG/fe.inc"
db "serveur telnet de commande systeme a distance"
scode:
org 0


taille_journal equ 10000h

;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax

mov ecx,finzt
mov dx,sel_dat2
mov al,8
int 61h





;**************************************************************
;determine l'id du service ethernet
mov byte[zt_recep],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h

cmp byte[zt_recep],0
je erreur_param

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
je erreur_init
mov bx,ax

;etablire une connexion
mov al,0
mov ecx,64
mov edx,0
mov esi,0
mov edi,0
int 65h
mov [adresse_canal],ebx

;configure en écoute pour le port TCP23
mov word[zt_recep],8      ;ouverture port tcp
mov word[zt_recep+2],23
mov word[zt_recep+4],12 ;connexion max
mov dword[zt_recep+6],4096 ;taille de la zt de communication a reserver a chaque canal de communication

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,zt_recep
mov edi,0
int 65h
cmp eax,0
jne erreur_init 

;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne erreur_init 

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,0
mov edi,zt_recep
int 65h
cmp eax,0
jne erreur_init 

cmp byte[zt_recep],88h
jne erreur_init

mov edx,msgok
mov al,6        
int 61h


;***************************************************************************************************************************************************
partie1: ;test si il y as des descripteur modifié (=nouvelles connexions)

mov al,2
int 65h
cmp eax,cer_ddi
jne partie2

;lit les données du descripteur
mov al,4
mov ecx,2h
mov esi,0
mov edi,zt_temp
int 65h

;ajoute la connexion a la liste
mov esi,zt_cnx-4

boucle:
add esi,4
cmp esi,zt_cnx+512
je partie2               ;§§§§§§§§§§§§§§§§§ou envoyer un message: désolé on as atteind le nombre de connexion maximum
cmp dword[esi],0
jne boucle
mov [esi],ebx

;envoie la demande de non echo local
mov al,7
mov ecx,3
mov esi,nonecho
int 65h

;le contenu du journal
mov ecx,zt_journal2
boucle2:
inc ecx
cmp byte[ecx],0
jne boucle2
mov esi,zt_journal2
sub ecx,esi
call formatage
mov al,7
int 65h

;l'invite de commande
mov al,7
mov ecx,3
mov esi,debut_cmd
int 65h

;et la commande
mov al,7
mov ecx,[offset]
mov esi,zt_recep
int 65h



;***************************************************************************************************************************************************
partie2: ;cherche si il y as eu modification du journal systeme

;lit le journal
mov al,14
mov edx,zt_journal1
mov ecx,taille_journal
int 61h
mov byte[ecx+zt_journal1],0

;compare avec le dernier journal pour voir si quelquechose as été modifié
mov esi,zt_journal1
mov edi,zt_journal2
mov ecx,taille_journal
cld
repe cmpsb
dec edi
dec esi
cmp byte[esi],0
je partie3


;efface la ligne de commande
call efface

;envoie la dernières parties modifé aux correspondants
mov ecx,esi
boucle3:
inc ecx
cmp byte[ecx],0
jne boucle3
sub ecx,esi
call formatage
call envoie_massif
  

;sauvegarde le dernier journal modifié
mov esi,zt_journal1
mov edi,zt_journal2
mov ecx,taille_journal
cld
rep movsb


;reécrit la ligne de commande
mov ecx,3
mov esi,debut_cmd
call envoie_massif
mov esi,zt_recep
mov ecx,[offset]
call envoie_massif


;***************************************************************************************************************************************************
partie3:  ;test si il y as des données a reçevoir
mov al,3
int 65h
cmp eax,cer_ddi
jne partie1


;lit les données reçu
mov edi,zt_recep
mov ecx,2048
mov eax,[offset]
add edi,eax
sub ecx,eax
mov al,6
push edi
int 65h
pop esi
add [offset],ecx


mov edx,zt_recep
boucle5:
cmp byte[edx],13
je commandetrouve
inc edx
cmp edx,zt_recep+2048
jne boucle5

;envoie aux autres machine connecté
call envoie_massif
jmp partie1


commandetrouve:    
;efface la ligne de commande
call efface
mov ecx,3
mov esi,debut_cmd
call envoie_massif

mov byte[edx],0    ;et envoie la commande
mov edx,zt_recep
mov al,0
int 61h

mov byte[zt_recep],0
mov dword[offset],0

jmp partie1









;*********************************************************************************************
envoie_massif:
pushad
mov edi,zt_cnx
boucle_envoie_massif:
mov ebx,[edi]
cmp ebx,0
je suite_envoie_massif
push ecx
push esi
mov al,7
int 65h
pop esi
pop ecx
cmp eax,0
je suite_envoie_massif
mov dword[edi],0 
suite_envoie_massif:
add edi,4
cmp edi,zt_cnx+512
jne boucle_envoie_massif
popad
ret





;*******************************************
efface:
pushad
mov ecx,[offset]
add ecx,3
mov edi,zt_transfert
mov eax,082008h ;code backsup espace backup
boucle_efface:
mov [edi],eax
add edi,3
dec ecx
jnz boucle_efface
mov esi,zt_transfert
mov ecx,[offset]
add ecx,[offset]
add ecx,[offset]
add ecx,9
call envoie_massif
popad
ret






;******************
formatage:
mov edi,zt_transfert
boucle_formatage:
mov al,[esi]
cmp al,13
je crlf_formatage
cmp al,20h
jb suite_formatage
cmp al,7Fh
ja suite_formatage 

mov [edi],al
inc edi

suite_formatage:
inc esi
dec ecx
jnz boucle_formatage
mov ecx,edi
mov esi,zt_transfert
sub ecx,zt_transfert
ret

crlf_formatage:
mov word[edi],0A0Dh
add edi,2
jmp suite_formatage




;***********************************
erreur_init:
mov edx,msgnok1
mov al,6        
int 61h
int 60h


erreur_param:
mov edx,msgnok2
mov al,6        
int 61h
int 60h


sdata1:
org 0

msgok:
db "STLNT: serveur Telnet démarré",13,0
msgnok1:
db "STLNT: erreur lors de l'ouverture du port",13,0
msgnok2:
db "STLNT: erreur dans les parametre de la ligne de commande, format correcte:",13
db "STFTP [X]",13
db "[X] numéros de l'interface sur laquelle brancher le serveur TFTP",13,0

debut_cmd:
db "-->"

nonecho:
db 0ffh,0fbh,01h


adresse_canal:
dd 0
offset:
dd 0


zt_temp:
dd 0


zt_cnx:
rb 512
zt_commande:
rb 512
zt_journal1:
rb taille_journal
zt_journal2:
rb taille_journal
zt_transfert:
rb taille_journal
zt_recep:
rb taille_journal
finzt:



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
