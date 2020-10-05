stlnt:
pile equ 4096 ;definition de la taille de la pile
include "../PROG/fe.inc"
db "serveur telnet de commande systeme a distance"
scode:
org 0

;choses encore a faire:
;signale nouvelle connexion
;gestion des codes d'échapement et iac dans les inputs
;supression de caractère possible
;ouverture d'un autre port que le standard
;

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
test al,080h
jz lutf1ch
test al,040h
jz suite_formatage
test al,020h
jz lutf2ch
test al,010h
jz lutf3ch
test al,08h
jz lutf4ch

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


lutf1ch:
mov [edi],al
inc edi
jmp suite_formatage


lutf2ch:
xor eax,eax
mov al,[esi]
and al,1Fh
shl eax,6
mov dl,[esi+1]
and dl,3Fh
or al,dl
jmp correspondance

lutf3ch:
xor eax,eax
mov al,[esi]
and al,0Fh
shl eax,6
mov dl,[esi+1]
and dl,3Fh
or al,cl
shl eax,6
mov dl,[esi+2]
and dl,3Fh
or al,dl
jmp correspondance

lutf4ch:
xor eax,eax
mov al,[esi]
and al,07h
shl eax,6
mov dl,[esi+1]
and dl,3Fh
or al,dl
shl eax,6
mov dl,[esi+2]
and dl,3Fh
or al,dl
shl eax,6
mov dl,[esi+3]
and dl,3Fh
or al,dl
correspondance:

test eax,0FFFF0000h
jnz remplacement

mov edx,code850
boucleap:
cmp [edx],ax
je trouve
add edx,2
cmp edx,code850+256
jne boucleap


remplacement:
mov byte[edi],0B0h ;carré a la place des caractères non affichable
inc edi
jmp suite_formatage

trouve:
sub edx,code850
shr edx,1
add dl,80h
mov [edi],dl
inc edi
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



code850:
dw 00C7h,00FCh,00E9h,00E2h,00E4h,00E0h,00E5h,00E7h,00EAh,00EBh,00E8h,00EFh,00EEh,00ECh,00C4h,00C5h
dw 00C9h,00E6h,00C6h,00F4h,00F6h,00F2h,00FBh,00F9h,00FFh,00D6h,00DCh,00F8h,00A3h,00D8h,00D7h,0192h
dw 00E1h,00EDh,00F3h,00FAh,00F1h,00D1h,00AAh,00BAh,00BFh,00AEh,00ACh,00BDh,00BCh,00A1h,00ABh,00BBh
dw 2591h,2592h,2593h,2502h,2524h,00C1h,00C2h,00C0h,00A9h,2563h,2551h,2557h,255Dh,00A2h,00A5h,2510h
dw 2514h,2534h,252Ch,251Ch,2500h,253Ch,00E3h,00C3h,255Ah,2554h,2569h,2566h,2560h,2550h,256Ch,00A4h
dw 00F0h,00D0h,00CAh,00CBh,00C8h,0131h,00CDh,00CEh,00CFh,2518h,250Ch,2588h,2584h,00A6h,00CCh,2580h
dw 00D3h,00DFh,00D4h,00D2h,00F5h,00D5h,00B5h,00FEh,00DEh,00DAh,00DBh,00D9h,00FDh,00DDh,00AFh,00B4h
dw 00ADh,00B1h,2017h,00BEh,00B6h,00A7h,00F7h,00B8h,00B0h,00A8h,00B7h,00B9h,00B3h,00B2h,25A0h,00A0h




msgok:
db "STLNT: serveur Telnet démarré",13,0
msgnok1:
db "STLNT: erreur lors de l'ouverture du port",13,0
msgnok2:
db "STLNT: erreur dans les parametre de la ligne de commande, format correcte:",13
db "STFTP [X]",13
db "[X] numéros de l'interface sur laquelle brancher le serveur TFTP",13,0

debut_cmd:
db 0C0h,0C4h,">"

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
