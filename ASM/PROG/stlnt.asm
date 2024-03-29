﻿stlnt:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "serveur telnet de commande systeme a distance"
scode:
org 0

;choses encore a faire:
;demande mot de passe a la connexion
;affichage de l'adresse

taille_journal equ 80000h

;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax

mov ecx,finzt
mov dx,sel_dat1
mov al,8
int 61h


;**************************************************************
;selectionne port a utiliser
mov byte[zt_transfert],0

mov al,5   
mov ah,"p"   ;lettre de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_transfert
int 61h

cmp byte[zt_transfert],0
je ignore_choix_port

mov al,100  
mov edx,zt_transfert
int 61h

cmp ecx,0
je erreur_param
test ecx,0FFFF0000h
jnz erreur_param

mov [port],cx

ignore_choix_port:


;**************************************************************
;determine l'id du service ethernet
mov byte[zt_transfert],0

mov al,5   
mov ah,"c"   ;lettre de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_transfert
int 61h
xor ebx,ebx
cmp eax,0
jne @f

mov al,100  
mov edx,zt_transfert
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

@@:
mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,zt_transfert
int 61h

shl ebx,1
mov ax,[zt_transfert+ebx]
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

;configure en écoute pour le port TCP23 (ou celuis choisi dans la commande)
mov ax,[port]
mov word[zt_transfert],8      ;ouverture port tcp
mov word[zt_transfert+2],ax
mov word[zt_transfert+4],12 ;connexion max
mov dword[zt_transfert+6],taille_journal ;taille de la zt de communication a reserver a chaque canal de communication

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,zt_transfert
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
mov edi,zt_transfert
int 65h
cmp eax,0
jne erreur_init 

cmp byte[zt_transfert],88h
jne erreur_init

mov edx,msgok
call ajuste_langue
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
mov ecx,64
mov esi,0
mov edi,zt_transfert
int 65h
cmp eax,0
jne partie2

;affiche qu'il y as eu une nouvelle connexion
cmp dword[zt_transfert+0Ch],0
jne affiche_ipv4 

mov eax,113
mov ecx,zt_transfert+10h
mov edx,zt_transfert+64
int 61h
jmp fin_affiche_adresse

affiche_ipv4:
mov eax,112
mov ecx,zt_transfert+0Ch
mov edx,zt_transfert+64
int 61h

fin_affiche_adresse:
mov edx,msgnc
call ajuste_langue
mov al,6
int 61h

mov edx,zt_transfert+64
mov al,6
int 61h

mov edx,msgcrlf
mov al,6
int 61h


;ajoute la connexion a la liste
mov esi,zt_cnx-4
boucle:
add esi,4
cmp esi,zt_cnx+512
je partie2               ;§§§§§§§§§§§§§§§§§ou envoyer un message: désolé on as atteind le nombre de connexion maximum
cmp dword[esi],ebx
je  existant
cmp dword[esi],0
jne boucle
mov [esi],ebx
existant:

;envoie la demande de non echo local
mov al,7
mov ecx,3
mov esi,nonecho
int 65h

;..le contenu du journal
mov esi,zt_journal2
mov ecx,[taille_journal2]
call formatage
mov al,7
int 65h

;..un petit message de bienvenu
mov al,7
mov edx,msgbase
call ajuste_langue
call compte0
mov esi,edx
int 65h

;..l'invite de commande
mov al,7
mov ecx,3
mov esi,debut_cmd
int 65h

;..et la commande
mov al,7
mov ecx,[offset]
mov esi,zt_commande
int 65h


;***************************************************************************************************************************************************
partie2: ;cherche si il y as eu modification du journal systeme

;lit le journal
mov al,14
mov edx,zt_journal1
mov ecx,taille_journal
int 61h
mov byte[ecx+zt_journal1],0
inc ecx
mov [taille_journal1],ecx
cmp ecx,1
je sauvgarde_journal

;compare avec le dernier journal pour voir si quelquechose as été modifié
mov esi,zt_journal1
mov edi,zt_journal2
mov ecx,[taille_journal1]
cld
repe cmpsb
cmp ecx,0
je partie3
dec edi
dec esi

;efface la ligne de commande
call efface

;envoie la dernières parties modifé aux correspondants
call formatage
call envoie_massif
  
;reécrit la ligne de commande
mov ecx,3
mov esi,debut_cmd
call envoie_massif
mov esi,zt_commande
mov ecx,[offset]
call envoie_massif


;sauvegarde le dernier journal modifié
sauvgarde_journal:
mov esi,zt_journal1
mov edi,zt_journal2
mov ecx,taille_journal
cld
rep movsb
mov eax,[taille_journal1]
mov [taille_journal2],eax


;***************************************************************************************************************************************************
partie3:  ;test si il y as des données a reçevoir
mov al,3
int 65h
cmp eax,cer_ddi
jne partie1


;lit les données reçu
mov edi,zt_transfert
mov ecx,64
mov al,6
int 65h


mov edi,zt_commande
mov esi,zt_transfert
mov edx,zt_transfert+128
add edi,[offset]
boucle5:
mov al,[esi]
cmp al,08h
je annulcarac
cmp al,13
je commandetrouve
cmp al,1Bh      ;escape code
je ignore_carac
cmp al,7Fh
je annulcarac
cmp al,0FFh     ;interprete as command
je interpretascommand
cmp al,20
jb ignore_carac
mov [edi],al
mov [edx],al
inc esi
inc edx
inc edi
inc dword[offset]
dec ecx
jnz boucle5 


;envoie aux autres machine connecté
fincommande:
mov ecx,edx
mov esi,zt_transfert+128
sub ecx,esi
call envoie_massif
jmp partie1

annulcarac:
cmp dword[offset],0
je ignore_carac
dec dword[offset]
dec edi
mov dword[edx],082008h
add edx,3
ignore_carac:
inc esi
dec ecx
jnz boucle5 
jmp fincommande

interpretascommand:
inc esi
dec ecx
jz fincommande
mov al,[esi]
inc esi
dec ecx
jz fincommande
cmp al,0FBh
jb boucle5
inc esi
dec ecx
jz fincommande
jmp boucle5 



commandetrouve:
mov byte[edi],0 ;marque la fin de la commande    

call efface     ;efface la ligne de commande

mov ecx,3         ;réecrit la commande
mov esi,debut_cmd
call envoie_massif
   
mov edx,zt_commande  ;et envoie la commande au systeme
mov al,0
int 61h
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

cmp eax,0               ;si erreur on ferme le canal
je suite_envoie_massif
cmp eax,cer_ztp
je suite_envoie_massif
mov ebx,[edi]
mov al,1
int 65h
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
cmp al,0
je fin_formattage
cmp al,13
je crlf_formatage
cmp al,20h
jb suite_formatage
cmp al,0FFh
je suite_formatage 
;test al,080h
;jz lutf1ch
;test al,040h
;jz suite_formatage
;test al,020h
;jz lutf2ch
;test al,010h
;jz lutf3ch
;test al,08h
;jz lutf4ch

mov [edi],al
inc edi

suite_formatage:
inc esi
dec ecx
jnz boucle_formatage
fin_formattage:
mov ecx,edi
mov esi,zt_transfert
sub ecx,zt_transfert
ret

crlf_formatage:
mov word[edi],0A0Dh
add edi,2
jmp suite_formatage


;lutf1ch:
;mov [edi],al
;inc edi
;jmp suite_formatage


;lutf2ch:
;xor eax,eax
;mov al,[esi]
;and al,1Fh
;shl eax,6
;mov dl,[esi+1]
;and dl,3Fh
;or al,dl
;jmp correspondance

;lutf3ch:
;xor eax,eax
;mov al,[esi]
;and al,0Fh
;shl eax,6
;mov dl,[esi+1]
;and dl,3Fh
;or al,cl
;shl eax,6
;mov dl,[esi+2]
;and dl,3Fh
;or al,dl
;jmp correspondance

;lutf4ch:
;xor eax,eax
;mov al,[esi]
;and al,07h
;shl eax,6
;mov dl,[esi+1]
;and dl,3Fh
;or al,dl
;shl eax,6
;mov dl,[esi+2]
;and dl,3Fh
;or al,dl
;shl eax,6
;mov dl,[esi+3]
;and dl,3Fh
;or al,dl
;correspondance:

;test eax,0FFFF0000h
;jnz remplacement

;mov edx,code850
;boucleap:
;cmp [edx],ax
;je trouve
;add edx,2
;cmp edx,code850+256
;jne boucleap

;remplacement:
;mov byte[edi],0B0h ;carré a la place des caractères non affichable
;inc edi
;jmp suite_formatage

;trouve:
;sub edx,code850
;shr edx,1
;add dl,80h
;cmp dl,0FFh
;je remplacement
;mov [edi],dl
;inc edi
;jmp suite_formatage


;***********************************
erreur_init:
mov edx,msgnok1
call ajuste_langue
mov al,6
int 61h
int 60h


erreur_param:
mov edx,msgnok2
call ajuste_langue
mov al,6
int 61h
int 60h




;***************************
ajuste_langue:  ;selectionne le message adapté a la langue employé par le système
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
ret


;***********
compte0:
mov ecx,edx

@@:
cmp byte[ecx],0
je @f
inc ecx
jmp @b
@@:

sub ecx,edx
ret





sdata1:
org 0



;code850:
;dw 00C7h,00FCh,00E9h,00E2h,00E4h,00E0h,00E5h,00E7h,00EAh,00EBh,00E8h,00EFh,00EEh,00ECh,00C4h,00C5h
;dw 00C9h,00E6h,00C6h,00F4h,00F6h,00F2h,00FBh,00F9h,00FFh,00D6h,00DCh,00F8h,00A3h,00D8h,00D7h,0192h
;dw 00E1h,00EDh,00F3h,00FAh,00F1h,00D1h,00AAh,00BAh,00BFh,00AEh,00ACh,00BDh,00BCh,00A1h,00ABh,00BBh
;dw 2591h,2592h,2593h,2502h,2524h,00C1h,00C2h,00C0h,00A9h,2563h,2551h,2557h,255Dh,00A2h,00A5h,2510h
;dw 2514h,2534h,252Ch,251Ch,2500h,253Ch,00E3h,00C3h,255Ah,2554h,2569h,2566h,2560h,2550h,256Ch,00A4h
;dw 00F0h,00D0h,00CAh,00CBh,00C8h,0131h,00CDh,00CEh,00CFh,2518h,250Ch,2588h,2584h,00A6h,00CCh,2580h
;dw 00D3h,00DFh,00D4h,00D2h,00F5h,00D5h,00B5h,00FEh,00DEh,00DAh,00DBh,00D9h,00FDh,00DDh,00AFh,00B4h
;dw 00ADh,00B1h,2017h,00BEh,00B6h,00A7h,00F7h,00B8h,00B0h,00A8h,00B7h,00B9h,00B3h,00B2h,25A0h,00A0h

msgbase:
db "*****************************************",10,13
db "* Welcome to this remote command server *",10,13
db "*       of a SEAC operating system      *",10,13
db "*****************************************",10,13,0
db "********************************************",10,13
db "*  Bienvenue sur ce serveur de commande a  *",10,13
db "* distance d'un sytème d'exploitation SEAC *",10,13
db "********************************************",10,13,0



msgok:
db "STLNT: Telnet server started",13,0
db "STLNT: serveur Telnet démarré",13,0
msgcrlf:
db 13,0
msgnc:
db "STLNT: connection established with ",0
db "STLNT: connexion établie avec ",0
msgnok1:
db "STLNT: error opening port",13,0
db "STLNT: erreur lors de l'ouverture du port",13,0
msgnok2:
db "STLNT: incorrect port numbers selected",13,0
db "STLNT: numéros de port selectionné incorrecte",13,0


debut_cmd:
db "-->"
;db 0C0h,0C4h,">"

nonecho:
db 0ffh,0fbh,01h


port:
dw 23     ;port par défaut
adresse_canal:
dd 0
offset:
dd 0
taille_journal1:
dd 0
taille_journal2:
dd 0





zt_cnx:
rb 512
zt_commande:
rb 1024
zt_journal1:
rb taille_journal
zt_journal2:
rb taille_journal
zt_transfert:
rb taille_journal*2
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
