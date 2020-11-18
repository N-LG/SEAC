bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Serveur TFTP"
scode:
org 0

;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax



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
je aff_err_carte
mov [id_tache],ax



;**************************************************************
;ouvre dossier de lecture
mov byte[zt_recep],0

mov al,4   
mov ah,1   ;numéros de l'option de commande a lire
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
;ouvre dossier d'écriture
mov byte[zt_recep],0

mov al,4   
mov ah,2   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h

cmp byte[zt_recep],0
je ignore_ecriture

xor eax,eax
mov bx,0
mov edx,zt_recep
int 64h
cmp eax,cer_dov
jne aff_err_ouve

mov [dossier_ecriture],ebx

ignore_ecriture:



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

;configure en écoute pour le port UDP69
mov byte[zt_recep],7
mov word[zt_recep+2],69

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
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
mov ecx,34h
mov esi,0
mov edi,zt_recep
int 65h
cmp eax,0
jne aff_err_port

cmp byte[zt_recep],87h
jne aff_err_port



mov edx,msgok
mov al,6        
int 61h


;**************************************************************************
boucle:

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
mov al,6        
int 61h
jmp afficheaide

aff_err_param:
mov edx,msger_param
mov al,6        
int 61h
jmp afficheaide

aff_err_port:
mov edx,msger_ouvport
mov al,6        
int 61h
jmp afficheaide

aff_err_ouv:
mov edx,msger_ouvdos
mov al,6        
int 61h
jmp afficheaide

aff_err_ouve:
mov edx,msger_ouvdose
mov al,6        
int 61h

afficheaide:
mov edx,msgaide
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
mov byte[nb_emission],15
mov word[acq_attendu],1

mov edx,msgrrq
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
mov ecx,400
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
cmp word[code_oper],0400h
jne boucle_rrq
mov ax,[code_oper+2]
xchg al,ah
cmp ax,[acq_attendu]
jne boucle_rrq

mov byte[nb_emission],15
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
jmp boucle


fin_rrq:
mov al,6
mov edx,msgfin
int 61h
jmp boucle




erreur_lecture:
push eax
call envoie_erreur0A

mov al,6
mov edx,msg_errlec
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




;*****************************************************************************************************
wrq:       ;requete d'ecriture
cmp dword[dossier_ecriture],0
je erreur_demande_interdite

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

;fixe sa taille a zéro
mov dword[tempo],0
mov dword[tempo+4],0
mov edx,tempo
mov al,7
mov ah,1 ;taille fichier
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
mov byte[nb_emission],15
mov word[acq_attendu],1


mov edx,msgwrq
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
mov ecx,400
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
cmp word[code_oper],0300h
jne boucle_wrq
mov ax,[code_oper+2]
xchg al,ah
cmp ax,[acq_attendu]
jne boucle_wrq


;enregistre les données du fichier
sub ecx,22+4

push ecx
mov al,5
mov ebx,[num_fichier]
xor edx,edx
mov dx,[acq_attendu]
dec edx
shl edx,9
mov esi,code_oper+4
int 64h
pop ecx
cmp eax,0
jne erreur_ecriture



cmp ecx,512
jne fin_wrq

mov byte[nb_emission],15
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
jmp boucle


fin_wrq:
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

mov al,6
mov edx,msgfin
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








;*********************************************
envoie_ack:
mov word[code_oper],0400h   ;accusé de reception
xchg al,ah
mov [code_oper+2],ax
mov ebx,[adresse_canal]
mov al,7
mov esi,zt_recep
mov ecx,22+4
int 65h
ret














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




sdata1:
org 0
adresse_canal:
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
msg3:
db 17h,13,0


msgok:
db "STFTP: serveur TFTP démarré",13,0

msgrrq:
db "STFTP: début de l'envoie du fichier: ",0
msgwrq:
db "STFTP: début de la réception du fichier: ",0
msgligne:
db 13,0
msgfin:
db "STFTP: fin de transfert de fichier",13,0


msg_errlec:
db "STFTP: erreur lors de la lecture du fichier: ",16h,0
msg_errecr:
db "STFTP: erreur lors de l'écriture du fichier: ",16h,0
msg_errfin:
db 17h,0

msger_carte:
db 13,"STFTP: carte réseau selectionné absente",13,0

msger_param:
db 13,"STFTP: erreur dans les parametre de la ligne de commande",13,0

msger_ouvport:
db 13,"STFTP: erreur lors de l'ouverture port",13,0

msger_ouvdos:
db 13,"STFTP: impossible d'ouvrir le dossier de lecture",13,0

msger_ouvdose:
db 13,"STFTP: impossible d'ouvrir le dossier d'écriture",13,0



msgaide:
db "format de la commande SFTP:",13
db "STFTP [X] [repertoire lecture] [repertoire ecriture]",13
db "[X] numéros de l'interface sur laquelle brancher le serveur TFTP",13
db "[repertoire lecture]  contient fichier disponible a la lecture",13 
db "[repertoire écriture] contient fichier qui seront reçu (champ optionnel)",13,0 


msgcoder0A:
db "erreur lors de la lecture du fichier",0
msgcoder0B:
db "erreur lors de la l'",233,"criture du fichier",0
msgcoder1:
db "fichier non trouv",233,0
msgcoder2:
db "acc",232,"s interdit",0
msgcoder3:
db "Espace insuffisant pour stocker le fichier",0
msgcoder4A:
db "op",233,"ration ill",233,"gale, ",233,"criture interdite",233,0
msgcoder4B:
db "op",233,"ration ill",233,"gale, Seul le mode octet est support",233,0
msgcoder4C:
db "op",233,"ration ill",233,"gale, accès sous dossier interdit",0
msgcoder4D:
db "op",233,"ration ill",233,"gale, non reconnue",233,0
msgcoder5:
db "ID de transfer inconnue",0
msgcoder6:
db "Le fichier est d",233,"j",224," pr",233,"sent",0


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


 
rb 2047
db 0

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
