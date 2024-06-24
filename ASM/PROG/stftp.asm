stftp:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Serveur TFTP"
scode:
org 0

;données du segment CS


taille_transfert equ 100000h
mov al,8
mov ecx,zt_transfert+taille_transfert
mov dx,sel_dat1
int 61h

mov ax,sel_dat1
mov ds,ax
mov es,ax



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
je aff_err_carte
mov [id_tache],ax



;**************************************************************
;ouvre dossier de lecture
mov byte[zt_recep],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h

cmp byte[zt_recep],0
je aff_err_param


xor eax,eax
mov bx,0
mov edx,zt_recep
int 64h
cmp eax,cer_dov
jne aff_err_ouv

mov [dossier_lecture],ebx



;**************************************************************
;test si l'écriture est autorisé
mov byte[zt_recep],0

mov al,5   
mov ah,"w"   ;lettre de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h
cmp eax,0
jne ignore_ecriture

mov eax,[dossier_lecture]
mov [dossier_ecriture],eax

ignore_ecriture:


;***********************************************************
;selectionne un numéros de port aléatoirement
mov eax,9
int 61h
xor ax,bx
xor ax,cx
xor ax,dx
xor ax,0B9F1h
or ax,1024h
mov [port_aleatoire],ax


;***********************************************************
;etablire une connexion
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,2000
mov edi,2000
int 65h
cmp eax,0
jne aff_err_port
mov [adresse_canal],ebx
mov [adresse_port69],ebx

;configure en écoute pour le port UDP69
mov word[zt_recep],7
mov word[zt_recep+2],69

mov al,5
mov ebx,[adresse_canal]
mov ecx,4
mov esi,zt_recep
mov edi,0
int 65h
cmp eax,0
jne aff_err_port

;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne aff_err_port

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,4
mov esi,0
mov edi,zt_recep
int 65h
cmp eax,0
jne aff_err_port

cmp byte[zt_recep],87h
jne aff_err_port



mov edx,msgok
call ajuste_langue
mov al,6        
int 61h


;**************************************************************************
boucle:

;si il y as un canal de com ouvert pour les données, on le ferm et on repasse sur le port 69
mov ebx,[adresse_canal]
cmp [adresse_port69],ebx
je @f
mov al,1
int 65h
mov ebx,[adresse_port69]
mov [adresse_canal],ebx
@@:


mov ebx,[num_fichier]    ;si un fichier a été ouvert, ferme le
cmp ebx,0
je aucun_fichier_ouvert
mov al,1
int 64h
mov dword[num_fichier],0
aucun_fichier_ouvert:



;test si il y as des données a reçevoir
mov al,3
int 65h
cmp eax,cer_ddi
je suite_boucle

int 62h   ;si aucune données a traiter on bascule a une autre tache
jmp boucle


suite_boucle:
;lit les données reçu
mov al,6
mov edi,zt_recep
mov ecx,512
int 65h

;on attent une requete
cmp word[code_oper],0100h
je rrq 
cmp word[code_oper],0200h
je wrq


call envoie_erreur4D
jmp boucle



;****************************************
;gère l'affichage des message d'erreur

aff_err_carte:
mov edx,msger_carte
call ajuste_langue
mov al,6        
int 61h
jmp afficheaide

aff_err_param:
mov edx,msger_param
call ajuste_langue
mov al,6        
int 61h
jmp afficheaide

aff_err_port:
mov edx,msger_ouvport
call ajuste_langue
mov al,6        
int 61h
jmp afficheaide

aff_err_ouv:
mov edx,msger_ouvdos
call ajuste_langue
mov al,6        
int 61h
jmp afficheaide

aff_err_ouve:
mov edx,msger_ouvdose
call ajuste_langue
mov al,6        
int 61h

afficheaide:
mov edx,msgaide
call ajuste_langue
mov al,6        
int 61h

int 60h




;******************************************************************************************************
rrq:       ;requete de lecture

;vérifie la conformité des options
call verif_req
jc boucle

;ouvre le fichier
xor eax,eax
mov ebx,[dossier_lecture]
mov edx,code_oper+2
int 64h
cmp eax,0
je ouverture_ok

call envoie_erreur1
jmp boucle

ouverture_ok:
mov [num_fichier],ebx

;récupère la taille du fichier
mov edx,to_fichier
mov al,6
mov ah,1 ;fichier
int 64h


;enregistre les données du client (port+IPs)
mov esi,zt_recep
mov edi,client
mov ecx,22
cld
rep movsb

;initialises compteurs pour démarrer transferts
mov byte[nb_emission],5
mov word[acq_attendu],1

mov edx,msgrrq
call ajuste_langue
mov al,6        
int 61h
mov edx,code_oper+2
mov al,6        
int 61h
mov edx,msgligne
mov al,6        
int 61h

boucle_rrq:
;attend qu'il y ait des données a reçevoir
mov al,9
mov ebx,[adresse_canal]
mov ecx,200
int 65h
cmp eax,cer_ddi
jne emis_trame_data


;lit les données reçu
mov al,6
mov edi,zt_recep
mov ecx,512
int 65h

;verifie que c'est bien le client actuel
mov esi,zt_recep
mov edi,client
mov ecx,22
cld
repe cmpsb
je test_rrq 

call envoie_erreur5
jmp boucle_rrq


test_rrq:           ;on attent un aquitement
cmp word[code_oper],0500h
je trame_erreur
cmp word[code_oper],0400h
jne boucle_rrq
mov ax,[code_oper+2]
xchg al,ah
cmp ax,[acq_attendu]
jne boucle_rrq

mov byte[nb_emission],5
inc word[acq_attendu]


emis_trame_data:    ;emet la trame de données
mov ax,[acq_attendu]
mov word[code_oper],0300h
xchg al,ah
mov [code_oper+2],ax

xor edx,edx
mov dx,[acq_attendu]
dec edx
shl edx,9 
mov eax,[to_fichier]

mov ecx,512
sub eax,edx
jb fin_rrq
cmp eax,512
ja fin_ajustement_taille
mov ecx,eax
fin_ajustement_taille:

push ecx
mov ebx,[num_fichier]
mov edi,code_oper+4
mov al,4
int 64h
pop ecx
cmp eax,0
jne erreur_lecture

mov ebx,[adresse_canal]
mov al,7
mov esi,zt_recep
add ecx,22+4
int 65h


dec byte [nb_emission]
jnz boucle_rrq
jmp erreur_perte


fin_rrq:
mov edx,msgfin
call ajuste_langue
mov al,6
int 61h
jmp boucle




erreur_lecture:
push eax
call envoie_erreur0A

mov edx,msg_errlec
call ajuste_langue
mov al,6
int 61h
pop ecx

mov al,13
mov ah,1
mov edx,zt_recep
int 61h
mov al,6
int 61h

mov al,6
mov edx,msg_errfin 
int 61h
jmp boucle





erreur_perte:
mov edx,msgfine
call ajuste_langue
mov al,6
int 61h
jmp boucle




;*****************************************************************************************************
wrq:       ;requete d'ecriture

cmp dword[dossier_ecriture],0
je erreur_demande_interdite

mov dword[adresse_transfert],0
mov dword[adresse_fichier],0

;vérifie la conformité des options
call verif_req
jc boucle

;créer le fichier
mov eax,2
mov ebx,[dossier_ecriture]
mov edx,code_oper+2
int 64h
cmp eax,0
je creation_ok
cmp eax,cer_nfr
je fichier_existant

erreur_wrq:
call envoie_erreur3
jmp boucle


fichier_existant:
;ouvre le fichier
mov eax,0
mov ebx,[dossier_ecriture]
mov edx,code_oper+2
int 64h
cmp eax,0
jne erreur_wrq

creation_ok:
mov [num_fichier],ebx


;enregistre les données du client (port+IPs)
mov esi,zt_recep
mov edi,client
mov ecx,22
cld
rep movsb

;initialises compteurs pour démarrer transferts
mov byte[nb_emission],5
mov word[acq_attendu],1


mov edx,msgwrq
call ajuste_langue
mov al,6        
int 61h
mov edx,code_oper+2
mov al,6        
int 61h
mov edx,msgligne
mov al,6        
int 61h
jmp emis_trame_ack


boucle_wrq:
;attend qu'il y ait des données a reçevoir
mov al,9
mov ebx,[adresse_canal]
mov ecx,200
int 65h
cmp eax,cer_ddi
jne emis_trame_ack


;lit les données reçu
mov al,6
mov edi,zt_recep
mov ecx,538
int 65h

;verifie que c'est bien le client actuel
push ecx
mov esi,zt_recep
mov edi,client
mov ecx,22
cld
repe cmpsb
pop ecx
je test_wrq 

call envoie_erreur5
jmp boucle_wrq


test_wrq:           ;on attent un pacquet de données
cmp word[code_oper],0500h
je trame_erreur
cmp word[code_oper],0300h
jne boucle_wrq
mov ax,[code_oper+2]
xchg al,ah
cmp ax,[acq_attendu]
jne boucle_wrq

;enregistre les données du fichier
sub ecx,22+4

push ecx
mov edi,zt_transfert
mov esi,code_oper+4
add edi,[adresse_transfert]
rep movsb
pop ecx
add [adresse_transfert],ecx
cmp dword[adresse_transfert],taille_transfert
jb zt_transfert_pasplein

push ecx
mov al,5
mov ebx,[num_fichier]
mov ecx,[adresse_transfert]
mov edx,[adresse_fichier]
add [adresse_fichier],ecx
mov esi,zt_transfert
int 64h
pop ecx
cmp eax,0
jne erreur_ecriture
mov dword[adresse_transfert],0


zt_transfert_pasplein:
cmp ecx,512
jne fin_wrq

mov byte[nb_emission],5
inc word[acq_attendu]

emis_trame_ack:
mov esi,client
mov edi,zt_recep
mov ecx,22
cld
rep movsb ;recopie les données du client

mov word[code_oper],0400h
mov ax,[acq_attendu]
dec ax
xchg al,ah
mov [code_oper+2],ax

mov ebx,[adresse_canal]
mov al,7
mov esi,zt_recep
mov ecx,22+4
int 65h

dec byte [nb_emission]
jnz boucle_wrq
jmp erreur_perte


fin_wrq:
push ecx
mov al,5
mov ebx,[num_fichier]
mov ecx,[adresse_transfert]
mov edx,[adresse_fichier]
add [adresse_fichier],ecx
mov esi,zt_transfert
int 64h
pop ecx
cmp eax,0
jne erreur_ecriture


mov byte[nb_emission],5

boucle_fin_wrq:
mov esi,client
mov edi,zt_recep
mov ecx,22
cld
rep movsb ;recopie les données du client

mov word[code_oper],0400h
mov ax,[acq_attendu]
xchg al,ah
mov [code_oper+2],ax

mov ebx,[adresse_canal]
mov al,7
mov esi,zt_recep
mov ecx,22+4
int 65h

mov al,1
mov ecx,100
int 61h

dec byte [nb_emission]
jnz boucle_fin_wrq


;enregistre la taille au cas ou on as écrasé un fichier plus gros
mov edx,[adresse_fichier]
mov dword[tempo],edx
mov dword[tempo+4],0
mov al,7
mov ah,1 ;taille fichier
mov ebx,[num_fichier]
mov edx,tempo
int 64h
cmp eax,0
jne erreur_wrq

mov dword[adresse_transfert],0
mov dword[adresse_fichier],0

mov edx,msgfin
call ajuste_langue
mov al,6
int 61h
jmp boucle


erreur_demande_interdite:
call envoie_erreur4A
jmp boucle


erreur_ecriture:
push eax
call envoie_erreur0B

mov al,6
mov edx,msg_errecr 
int 61h
pop ecx

mov al,13
mov ah,1
mov edx,zt_recep
int 61h
mov al,6
int 61h

mov al,6
mov edx,msg_errfin 
int 61h
jmp boucle



trame_erreur:
mov edx,msg_errclient
call ajuste_langue
mov al,6
int 61h

mov al,6
mov edx,code_oper+4 
int 61h

mov al,6
mov edx,msgligne
int 61h

jmp boucle

;******************************************************************************






envoie_erreur0A:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0000h  
mov ebx,code_oper+4
mov edx,msgcoder0A
jmp boucle_envoie_erreur0

envoie_erreur0B:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0000h  
mov ebx,code_oper+4
mov edx,msgcoder0B
jmp boucle_envoie_erreur0


envoie_erreur1:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0100h  
mov ebx,code_oper+4
mov edx,msgcoder1
jmp boucle_envoie_erreur0

;*********************************************
envoie_erreur2:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0200h   
mov ebx,code_oper+4
mov edx,msgcoder2
jmp boucle_envoie_erreur0

;*********************************************
envoie_erreur3:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0300h  
mov ebx,code_oper+4
mov edx,msgcoder3
jmp boucle_envoie_erreur0

;*********************************************
envoie_erreur4A:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0400h  
mov ebx,code_oper+4
mov edx,msgcoder4A
jmp boucle_envoie_erreur0

;*********************************************
envoie_erreur4B:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0400h  
mov ebx,code_oper+4
mov edx,msgcoder4B
jmp boucle_envoie_erreur0

;*********************************************
envoie_erreur4C:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0400h  
mov ebx,code_oper+4
mov edx,msgcoder4C
jmp boucle_envoie_erreur0
;*********************************************
envoie_erreur4D:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0400h  
mov ebx,code_oper+4
mov edx,msgcoder4D
jmp boucle_envoie_erreur0


;*********************************************
envoie_erreur5:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0500h   
mov ebx,code_oper+4
mov edx,msgcoder5
jmp boucle_envoie_erreur0

;*********************************************
envoie_erreur6:
mov word[code_oper],0500h   ;erreur
mov word[code_oper+2],0600h   
mov ebx,code_oper+4
mov edx,msgcoder6
jmp boucle_envoie_erreur0




;*********************************************
boucle_envoie_erreur0:
mov al,[edx]
mov [ebx],al
inc ebx
inc edx
cmp al,0
jne boucle_envoie_erreur0 

mov ecx,ebx
sub ecx,zt_recep
mov ebx,[adresse_canal]
mov al,7
mov esi,zt_recep
int 65h
ret














;********************
verif_req:
;verifie que le mode de transmission demandé soit bien "octet"
mov ebx,code_oper+2
boucle_verif_octet:
cmp byte[ebx],0
je verif_octet
cmp byte[ebx],"/"
je verif_nok1
cmp byte[ebx],"\"   ;verifie qu'il n'y ait pas de sous dossier dans le nom
je verif_nok1
inc ebx
jmp boucle_verif_octet

verif_octet:
inc ebx
cmp byte[ebx],"O"
je ok_lettre1
cmp byte[ebx],"o"
jne verif_nok2
ok_lettre1:
inc ebx
cmp byte[ebx],"C"
je ok_lettre2
cmp byte[ebx],"c"
jne verif_nok2
ok_lettre2:
inc ebx
cmp byte[ebx],"T"
je ok_lettre3
cmp byte[ebx],"t"
jne verif_nok2
ok_lettre3:
inc ebx
cmp byte[ebx],"E"
je ok_lettre4
cmp byte[ebx],"e"
jne verif_nok2
ok_lettre4:
inc ebx
cmp byte[ebx],"T"
je ok_lettre5
cmp byte[ebx],"t"
jne verif_nok2
ok_lettre5:
inc ebx
cmp byte[ebx],0
jne verif_nok2
verif_ok:
pushad

;ouvre un nouveau canal dédié a l'envoie de donnée
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,2000
mov edi,2000
int 65h
cmp eax,0
jne verif_nok3
mov [adresse_canal],ebx

;configure en écoute pour le port UDP aléatoire
inc word[port_aleatoire]
mov ax,[port_aleatoire]
mov word[tempo],7
mov word[tempo+2],ax

mov al,5
mov ebx,[adresse_canal]
mov ecx,4
mov esi,tempo
mov edi,0
int 65h
cmp eax,0
jne verif_nok3

;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne verif_nok3

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,4
mov esi,0
mov edi,tempo
int 65h
cmp eax,0
jne verif_nok3

cmp byte[tempo],87h
jne verif_nok3

popad
clc
ret


verif_nok1:
call envoie_erreur4C
stc
ret

verif_nok2:
call envoie_erreur4B
stc
ret

verif_nok3:
popad
stc
ret



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





sdata1:
org 0
port_aleatoire:
dw 0
adresse_canal:
dd 0
adresse_port69:
dd 0
acq_attendu:
dw 0
nb_emission:
db 0
id_tache:
dw 0
num_fichier:
dd 0
to_fichier:
dd 0,0
dossier_lecture:
dd 0
dossier_ecriture:
dd 0

tempo:
dd 0,0,0,0,0,0,0,0,0,0,0,0


msgok:
db "STFTP: TFTP server started",13,0
db "STFTP: serveur TFTP démarré",13,0

msgrrq:
db "STFTP: start sending the file: ",0
db "STFTP: début de l'envoie du fichier: ",0
msgwrq:
db "STFTP: start of file reception: ",0
db "STFTP: début de la réception du fichier: ",0
msgligne:
db 13,0
msgfin:
db "STFTP: end of file transfer",13,0
db "STFTP: fin de transfert de fichier",13,0

msgfine:
db "STFTP: loss of connection with client, incomplete transfer",13,0
db "STFTP: perte de connexion avec le client, transfert incomplet",13,0


msg_errlec:
db "STFTP: error while reading file: ",16h,0
db "STFTP: erreur lors de la lecture du fichier: ",16h,0
msg_errecr:
db "STFTP: error writing file: ",16h,0
db "STFTP: erreur lors de l'écriture du fichier: ",16h,0
msg_errfin:
db 17h,0


msg_errclient:
db "STFTP: the client returned an error message: ",0
db "STFTP: le client a renvoyé un message d'erreur: ",0



msger_carte:
db 13,"STFTP: network card selected absent",13,0
db 13,"STFTP: carte réseau selectionné absente",13,0

msger_param:
db 13,"STFTP: error in command line parameters",13,0
db 13,"STFTP: erreur dans les paramètre de la ligne de commande",13,0

msger_ouvport:
db 13,"STFTP: error while opening port",13,0
db 13,"STFTP: erreur lors de l'ouverture port",13,0

msger_ouvdos:
db 13,"STFTP: unable to open reading folder",13,0
db 13,"STFTP: impossible d'ouvrir le dossier de lecture",13,0

msger_ouvdose:
db 13,"STFTP: unable to open write folder",13,0
db 13,"STFTP: impossible d'ouvrir le dossier d'écriture",13,0


msgaide:
db "STFTP: command line syntax error. enter ",22h,"man stftp",22h," for correct syntax",13,0
db "STFTP: erreur dans la sytaxe de la ligne de commande. entrez ",22h,"man stftp",22h," pour avoir la syntaxe correcte",13,0

msgcoder0A:
db "erreur lors de la lecture du fichier",0
msgcoder0B:
db "erreur lors de la l'ecriture du fichier",0
msgcoder1:
db "fichier non trouve",0
msgcoder2:
db "acces interdit",0
msgcoder3:
db "Espace insuffisant pour stocker le fichier",0
msgcoder4A:
db "operation illegale, ecriture interdite",0
msgcoder4B:
db "operation illegale, Seul le mode octet est supporte",0
msgcoder4C:
db "operation illegale, accès sous dossier interdit",0
msgcoder4D:
db "operation illegale, non reconnue",233,0
msgcoder5:
db "ID de transfer inconnue",0
msgcoder6:
db "Le fichier est deja present",0



adresse_transfert:
dd 0
adresse_fichier:
dd 0

client:
dw 0
dd 0
dd 0,0,0,0



zt_recep:
port:
dw 0
adresse_ipv4:
dd 0
adresse_ipv6:
dd 0,0,0,0
code_oper:
dw 0
rb 2048
zt_transfert:

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
