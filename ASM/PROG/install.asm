installeur:


pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "outil d'installation/configuration"
scode:
org 0
mov ax,sel_dat1
mov ds,ax
mov es,ax

;définis la taille ram
mov al,8
mov dx,sel_dat1
mov ecx,ZT+4096
int 61h

;initialisation ecran texte
mov dx,sel_dat2
mov ah,1   ;option=mode texte
mov al,0   ;création console     
int 63h

mov dx,sel_dat2    ;écran video
mov fs,dx



;**********************************
;ecran selection langage
selection_langue:
call raz_ecr
mov edx,msg_langue
mov al,11
mov ah,7
int 63h


mov al,13   ;menu
mov cl,2    ;démarre a la ligne
mov ch,2    ;sur ch ligne
mov bl,0    ;ligne preselectionné
mov bh,7    ;couleur
int 63h
cmp bh,1 
je fin

mov edx,cmd_langue
call cherche_cmd
mov [langue],edx




;**********************************
;ecran selection clavier
selection_clavier:
call raz_ecr
mov edx,msg_clav
call ajuste_langue
mov al,11
mov ah,7
int 63h


mov al,13   ;menu
mov cl,1    ;démarre a la ligne
mov ch,13    ;sur ch ligne
mov bl,0    ;ligne preselectionné
mov bh,7    ;couleur
int 63h
cmp bh,1
je selection_langue

mov edx,cmd_clav
call cherche_cmd
mov [clavier],edx



;**********************************
;selection taille de l'écran
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!a faire en dernier

;**********************************
;selection jeux de caractère
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!a faire en dernier

;**********************************
;selection config carte réseau
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!a faire en dernier




;**********************************
;ecran selection disque d'installation
selection_disque:
call raz_ecr
mov edx,msg_disque1
call ajuste_langue
mov al,11
mov ah,7
int 63h


;listing des disques présent
mov ch,08h
xor ebx,ebx
boucle_ldp:
push ebx
push ecx
mov al,10
mov edi,ZT
int 64h
cmp eax,0
jne suite_ldp

test byte[ZT+1],080h   ;test si le périphérique est atapi
jnz suite_ldp

;convertit le nom
mov ebx,ZT+36h
boucle_convn:
mov ax,[ebx]
xchg al,ah
mov[ebx],ax
add ebx,2
cmp ebx,ZT+5Eh
jne boucle_convn

;affiche le nom
mov edx,ZT+36h
mov byte[ZT+5Eh],0
mov al,11
mov ah,07h ;couleur
int 63h

mov word[ZT],13
mov al,11
mov ah,07h ;couleur
mov edx,ZT
int 63h

pop ecx
pop ebx
mov[ebx+disques],ch
push ecx
inc ebx

suite_ldp:
pop ecx
inc ch
cmp ch,60h
jne boucle_ldp



;***************************
mov ch,bl
mov al,13
mov bh,7 ;couleur
mov bl,0
mov cl,1
int 63h
cmp bh,1
je selection_clavier

and ebx,0FFh
mov al,[ebx+disques]
mov [disque],al




;*********************************************
;test si une partition est suceptible d'acceuillir le binaire, si non invite a démarrer partd

mov al,8
mov ch,[disque]
mov cl,1
mov edi,ZT
mov ebx,0
int 64h
cmp eax,0
jne nok_partition


mov ebx,ZT+1C2h
cmp byte[ebx],30h
je ok_partition
add ebx,10h
cmp byte[ebx],30h
je ok_partition
add ebx,10h
cmp byte[ebx],30h
je ok_partition
add ebx,10h
cmp byte[ebx],30h
je ok_partition

nok_partition:
call raz_ecr
mov edx,msg_disque2
call ajuste_langue
mov al,11
mov ah,7
int 63h


mov al,13
mov bh,7 ;couleur
mov bl,0
mov cl,2
mov ch,3
int 63h
cmp bh,1
je selection_clavier
cmp bl,1
je selection_disque
cmp bl,2
je partd
int 60h

partd:
mov edx,commande5
call envoie_cmd
mov edx,commande6
call envoie_cmd
int 60h

ok_partition:
cmp dword[ebx+8],2048 ;la partition doit aussi faire plus de 1Mo
jb nok_partition 
mov eax,[ebx+4]
mov [secteur],eax  ;on enregistre le

;*********************************
;ecran selection dossier systeme
selection_dossier:
call raz_ecr
mov edx,msg_dossier
call ajuste_langue
mov al,11
mov ah,7
int 63h

mov al,6
mov ah,7
mov edx,dossier
mov ecx,256
int 63h
cmp al,1
je selection_disque



;********************************
;ecran validation
call raz_ecr
mov edx,msg_conf
call ajuste_langue
mov al,11
mov ah,7
int 63h

mov al,13   ;menu
mov cl,1    ;démarre a la ligne
mov ch,2    ;sur ch ligne
mov bl,0    ;ligne preselectionné
mov bh,7    ;couleur
int 63h
cmp bh,1 
je fin

cmp bl,0
je fin


mov eax,1   ;fermeture de la fenetre
int 63h


mov eax,3   ;affichage du tecop
xor edx,edx
int 63h





;*********************************
;création des fichiers cfg.sh et boot.sh
mov edx,msg_prep
call ajuste_langue
mov al,6
int 61h

mov edx,fichier1
call oc_fichier

mov esi,base1a
call aj_fichier
mov esi,dossier
call aj_fichier
mov esi,base1b
call aj_fichier

mov al,1
mov ebx,[fichier]
int 64h


mov edx,fichier2
call oc_fichier

mov esi,base2a
call aj_fichier
mov esi,[langue]
call aj_fichier
mov esi,crlf
call aj_fichier
mov esi,[clavier]
call aj_fichier
mov esi,base2b
call aj_fichier

mov al,1
mov ebx,[fichier]
int 64h




;*********************************
;compilation du noyau

mov edx,commande1
call envoie_cmd

mov edx,commande2
call envoie_cmd

mov edx,commande3
call envoie_cmd



;*********************************
;copie du noyau
mov edx,msg_cop1
call ajuste_langue
mov al,6
int 61h

;ouvre le fichier
mov al,0
mov edx,fichier3
mov ebx,0
int 64h
cmp eax,0
;jne 


;test la taille du fichier
mov al,6
mov ah,1 ;taille
mov edx,ZT
int 64h
cmp eax,0
;jne 

mov eax,[ZT]
add eax,4095
shr eax,12
mov ebp,eax
xor edx,edx


@@:
push ebx
push edx
push ebp
mov al,4
mov ecx,4096
mov edi,ZT
int 64h
cmp eax,0
;jne 

mov al,9
mov ch,[disque]
mov cl,8
mov esi,ZT
mov ebx,[secteur]
int 64h
pop ebp
pop edx
pop ebx
cmp eax,0
;jne 


add edx,4096
add dword[secteur],8
dec ebp
jnz @b

mov al,1
int 64h






;*********************************
;copie du MBR
mov edx,msg_cop2
call ajuste_langue
mov al,6
int 61h


mov al,8
mov ch,[disque]
mov cl,1
mov edi,ZT
xor ebx,ebx
int 64h
cmp eax,0
;jne 


mov ebx,ZT
@@:
mov dword[ebx],0
add ebx,4
cmp ebx,ZT+1B8h
jne @b

mov al,0
mov edx,fichier4
mov ebx,0
int 64h
cmp eax,0
;jne

mov ecx,440
mov al,4
xor edx,edx
mov edi,ZT
int 64h
cmp eax,0
;jne 

mov al,1
int 64h


mov word[ZT+1FEh],0AA55h

mov al,9
mov ch,[disque]
mov cl,1
mov esi,ZT
xor ebx,ebx
int 64h
cmp eax,0
;jne 



;***************************
;copie des fichier
mov edx,commande4
call envoie_cmd




;*********************
;ecran fin
mov edx,msg_fin
call ajuste_langue
mov al,6
int 61h

fin:
int 60h


;*************************************************************************
raz_ecr:
fs
mov ebx,[ad_texte]
fs
mov ecx,[to_texte]
shr ecx,2

boucle_raz_ecr:
fs
mov dword[ebx],0
add ebx,4
dec ecx
jnz boucle_raz_ecr

xor ebx,ebx
xor ecx,ecx
mov al,12
int 63h     ;place le curseur en 0.0
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






;*****************************
cherche_cmd:
cmp bl,0
je envoie_cmd
cmp byte[edx],0
jne @f
dec bl
@@:
inc edx
jmp cherche_cmd

envoie_cmd:
mov al,0
int 61h


;****************************
attend_fincmd:
int 62h
mov word[ZT],0

push edx
mov al,19
mov cl,8
mov edx,ZT
int 61h
pop edx
cmp word[ZT],0
jne attend_fincmd
ret



;**************************
oc_fichier:    ;ouvre ou créer le fichier
mov al,0
xor ebx,ebx
int 64h
cmp eax,0
je @f

mov al,2
xor ebx,ebx
int 64h
cmp eax,0
je @f
ret

@@:
mov [fichier],ebx
mov dword[offset],0

mov al,7
mov ah,1
mov ebx,[fichier]
mov edx,offset
int 64h
ret


;********************
aj_fichier:   ;ajoute au fichier
mov ecx,esi
@@:
cmp byte[ecx],0
je @f
inc ecx
jmp @b

@@:
mov eax,5
mov ebx,[fichier]
sub ecx,esi
mov edx,[offset]
add [offset],ecx
int 64h

ret


;***************************************************
sdata1:
org 0


msg_langue:
db "bienvenu dans l'outil d'installation de SEaC, veuillez selectionner votre langue",13
db "Welcome to the SEaC installation tool, please select your language",13
db "english",13
db "français",13

db 13,13,13,"touche Echap pour quitter l'installation",13
db "Press Esc to exit the installation",0

cmd_langue:
db "def en-txt.def",0
db "def fr-txt.def",0





msg_clav:
db "Please select your keyboard layout:",13
db "QWERTY International",13

db "QWERTY US",13

db "QWERTY Canadian",13

db "AZERTY French",13

db "AZERTY Belgian",13

db "QWERTZ Swiss (French)",13

db "QWERTZ Swiss (German)",13

db "Bépo",13

db "Dvorak",13

db "Colemak",13

db "Ergol",13

db "Greek + QWERTY International",13

db "Greek + AZERTY French",13

db 13,13,13,"Press Escape key to return to the previous screen",0

db "veuillez choisir votre disposition clavier:",13
db "QWERTY international",13
db "QWERTY usa",13
db "QWERTY canadien",13
db "AZERTY français",13
db "AZERTY belge",13
db "QWERTZ suisse francophone",13
db "QWERTZ suisse germanophone",13
db "bépo",13
db "dvorak",13
db "colemak",13
db "ergol",13
db "grec+QWERTY international",13
db "grec+AZERTY français",13
db 13,13,13,"touche Echap pour revenir a l'écran précédent",0


cmd_clav:
db "def en-qwi.def",0
db "def en-qus.def",0
db "def ca-qws.def",0
db "def fr-aza.def",0
db "def be-azs.def",0
db "def ch-qzf.def",0
db "def ch-qzg.def",0
db "def bepo.def",0
db "def dvorak.def",0
db "def colemak.def",0
db "def ergol.def",0
db "def gr-qwi.def",0
db "def gr-aza.def",0





msg_disque1:
db "Please select the boot disk:",13,0
db "veuillez selectionner le disque d'amorçage:",13,0

msg_disque2:
db "A single partition with code 30h and a size of at least 1MB is required to",13

db "copy the kernel to the boot disk.",13

db "Abort installation",13

db "choose another disk",13
db "Partition the disk and restart",0
db "il es nécessaire d'avoir une seule partition code 30h d'au moins 1Mo pour",13
db "pouvoir y copier le noyau sur le disque d'amorçage",13 
db "abandonner l'installation",13
db "choisir un autre disque",13
db "partitionner le disque et redémarrer",0







msg_dossier:
db "Please select the desired location for the system folder:",13,0
db "veuillez selectionner l'adresse souhaité  pour le dossier systeme:",13,0



msg_conf:
db "Are you sure you want to install SEaC on your computer?",13

db "No",13

db "Yes",13,13,13,0
db "êtes vous sûr de vouloir installer SEac sur votre ordinateur?",13
db "non",13
db "oui",13,13,13,0


msg_prep:
db "INSTALL: preparing files in progress...",13,0
db "INSTALL: préparation des fichier en cours...",13,0

msg_cop1:
db "INSTALL: copying boot data in progress...",13,0
db "INSTALL: copie des données d'amorçage en cours...",13,0

msg_cop2:
db "INSTALL: Copying files in progress...",13,0
db "INSTALL: copie des fichiers en cours...",13,0


msg_fin:
db "INSTALL: The installation is now complete.",13,0
db "INSTALL: l'installation est a présent terminé,",13,0


fichier1:
db "#dm/cfg.sh",0

base1a:
db "cd ",0

base1b:
db 13,"ex boot.sh",0


fichier2:
db "#dm/boot.sh",0

base2a:
db "fds",13,0

base2b:
db 13
db "modv 800*600",13
db "ics",0
db "pilote pci",13
db "ipconfig 0 auto",13
db 0

fichier3:
db "#dm/SEAC.BIN",0


fichier4:
db "#dm/BIOS.MBR",0

crlf:
db 13,0


commande5:
db "partd",0

commande6:
db "pwr -r",0


commande1:
db "cd #dm",0

commande2:
db "FASM ETAGE4.ASM ETAGE4.BIN",0

commande3:
db "FASM ETAGE2_MBR.ASM SEAC.BIN",0




commande4:
db "cop *.* "

;configuration
dossier:
rb 256
langue:
dd 0
clavier:
dd 0
disque:
db 0
secteur:
dd 0


fichier:
dd 0
offset:
dd 0,0




disques:
rb 64


ZT:






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
