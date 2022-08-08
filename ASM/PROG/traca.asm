term:




pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "simulation d'envoie de recette traça"
scode:
org 0


mov dx,sel_dat1    ;variable du programme
mov ds,dx
mov es,dx




;récupère numéros de port











;configure port







;envoie 5 et attend 









;***********************************
changer_port:
mov edx,msg2
mov al,11
mov ah,0Ah ;couleur
int 63h

mov ah,07h
mov edx,num_port
mov ecx,2
mov al,6
int 63h
cmp al,1
je fin

cmp byte[num_port],"T"
je config_tcpip
cmp byte[num_port],"t"
je config_tcpip
cmp byte[num_port],"1"
je config_port
cmp byte[num_port],"2"
je config_port
cmp byte[num_port],"3"
je config_port
cmp byte[num_port],"4"
je config_port
cmp byte[num_port],"5"
je config_port
cmp byte[num_port],"6"
je config_port
cmp byte[num_port],"7"
je config_port
cmp byte[num_port],"8"
je config_port
jmp changer_port 





;****************************
config_port:

mov edx,msg3
mov al,11
mov ah,0Ah ;couleur
int 63h

mov ah,07h
mov edx,vitesse_port
mov ecx,12
mov al,6
int 63h

mov al,100
mov edx,vitesse_port
int 61h

xor edx,edx
mov eax,115200  ;1843200/16
div ecx
cmp edx,0
je ok_bit_port
call erreurp
jmp config_port

ok_bit_port:    ;config bit par carac (COM)
mov edx,msg4
mov al,11
mov ah,0Ah ;couleur
int 63h

mov ah,07h
mov edx,bits_port
mov ecx,2
mov al,6
int 63h

cmp byte[bits_port],"7"
je ok_parite_port
cmp byte[bits_port],"8"
je ok_parite_port
call erreurp
jmp ok_bit_port

ok_parite_port:   ;config bit de parité (COM)
mov edx,msg5
mov al,11
mov ah,0Ah ;couleur
int 63h

mov ah,07h
mov edx,parite_port
mov ecx,2
mov al,6
int 63h

cmp byte[parite_port],"N"
je ok_stop_port
cmp byte[parite_port],"I"
je ok_stop_port
cmp byte[parite_port],"P"
je ok_stop_port
cmp byte[parite_port],"n"
je ok_stop_port
cmp byte[parite_port],"i"
je ok_stop_port
cmp byte[parite_port],"p"
je ok_stop_port
call erreurp
jmp ok_parite_port


ok_stop_port:    ;config bit de stop (COM)
mov edx,msg6
mov al,11
mov ah,0Ah ;couleur
int 63h

mov ah,07h
mov edx,stop_port
mov ecx,2
mov al,6
int 63h

cmp byte[stop_port],"1"
je configure_port
cmp byte[stop_port],"2"
je configure_port
call erreurp
jmp ok_stop_port



;************************************************************
configure_port: ;configure les caractéristique de transmission du port com selectionnée
mov al,100
mov edx,vitesse_port
int 61h

xor bl,bl

cmp byte[bits_port],"8"
jne pp8
or bl,00001b
pp8:

cmp byte[stop_port],"2"
jne pp2
or bl,00100b
pp2:

;cmp byte[parite_port],"I"
jne ppI
or bl,01000b
ppI:

;cmp byte[parite_port],"i"
jne ppi
or bl,01000b
ppi:

;cmp byte[parite_port],"P"
jne ppP
or bl,11000b
ppP:

cmp byte[parite_port],"p"
jne ppp
or bl,11000b
ppp:

mov al,6
mov ah,[num_port]
sub ah,"1"
cmp ah,8
jae communication
int 66h
cmp eax,16 ;action non autorisé
je port_reserve
cmp eax,0
jne port_absent

jmp communication

;***************************************************
config_tcpip:    ;config_adresse_ip
mov byte[num_port],"T"

mov edx,msg7
mov al,11
mov ah,0Ah ;couleur
int 63h

mov ah,07h
mov edx,ip_cible
mov ecx,15
mov al,6
int 63h

mov al,109
mov edx,ip_cible
mov ecx,cmd_ip
int 61h

cmp dword[cmd_ip],0
jne ok_adresse_ip
call erreurp
jmp config_tcpip
ok_adresse_ip:


mov edx,msg8
mov al,11
mov ah,0Ah ;couleur
int 63h

mov ah,07h
mov edx,port_cible
mov ecx,8
mov al,6
int 63h

mov al,100
mov dx,port_cible
int 61h

mov [cmd_port_dest],cx
test ecx,0FFFF0000h
jz ok_port_cible
call erreurp
jmp ok_adresse_ip
ok_port_cible:





;*********************************
config_cnx:
inc dword[cmd_port]

mov al,11    ;lit l'ID des tache qui offrent un service
mov ah,6     ;code service recherché
mov cl,8
mov edx,carac
int 61h

mov ax,[carac]                     ;a modifier si on as plusieurs carte réseau dispo!!!!!!!!!!!!!!!!!!!!!!!
mov [id_tache],ax

;ferme le précédent canal si ça n'as pas été fait
mov al,1                    
mov ebx,[adresse_canal]
int 65h

;ouvre un canal de communication
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,0
mov esi,80000
mov edi,80000
int 65h
mov [adresse_canal],ebx

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,commande_ethernet
mov edi,0
int 65h
cmp eax,0
jne erreur_init_cpnr 

;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne erreur_init_cpnr 

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,2
mov esi,0
mov edi,carac
int 65h
cmp eax,0
jne erreur_init_cpnr  

cmp byte[carac],0C0h  ;si le port local est déja reservé on en essaye un autre
je config_cnx
cmp byte[carac],88h
jne erreur_init_cpnr







;**********************************************************************
communication:
call raz_ecr


;*************
boucle:
mov al,5   ;lecture entrée clavier
int 63h

cmp al,0
je lit_port
cmp al,1
je fin
cmp al,2
je changer_port
;cmp al,3
;je config_port
;cmp al,4
;je config_affichage

cmp al,44
je touche_entre
cmp al,100
je touche_entre
cmp al,30
je touche_back

cmp ecx,7Fh ;si le caractère est au dela des 128 premier caractère, on ignore (en attendant de trouver mieux)
ja boucle
cmp ecx,20h
jb boucle


;*************************************************affichage eventuel de l'entrée clavier
affichage_carac:           
cmp byte[mode],0
jne envoie_carac
push ecx
mov [carac],cl
mov byte[carac+1],0
mov edx,carac
mov al,11
mov ah,0Ah ;couleur
int 63h
pop ecx


;**************************************************** envoie les données sur le port COM
envoie_carac:
cmp byte[num_port],"T"
je envoie_carac_tcp   ;sauf bien sur si c'est une connexion TCP


;envoie entrée clavier sur port
mov al,0
mov ah,[num_port]
sub ah,"1"
int 66h
cmp eax,0
je lit_port

;affiche un message d'erreur si il y as un probleme d'envoie
mov edx,msgerr1
mov al,11
mov ah,0Ch ;couleur
int 63h




;*************************************** lit les données écrite sur le port COM
lit_port:  
cmp byte[num_port],"T"
je lit_port_tcp   ;sauf bien sur si c'est une connexion TCP


mov al,2   ;lecture entrée port COM
mov ah,[num_port]
sub ah,"1"
int 66h
cmp eax,0
jne boucle
mov [carac],cl


;******************************************affichage données reçu
affichage_rec:
cmp byte[carac],13
je ok_affichage_rec
cmp byte[carac],20h
jb boucle

ok_affichage_rec:
mov byte[carac+1],0
mov edx,carac
mov al,11
mov ah,07h ;couleur
int 63h
jmp boucle




;**************************************** envoie les donnée via la connexion TCP
envoie_carac_tcp: 
mov [carac],cl
mov ecx,1
cmp byte[carac],13
jne ok_tcp
mov byte[carac+1],10
mov ecx,2
ok_tcp:
mov al,7
mov ebx,[adresse_canal]
mov esi,carac
int 65h
cmp eax,0
jne erreur_cnxtcp



;*************************************** recoit les données de la connexion TCP
lit_port_tcp:  
mov al,6
mov ebx,[adresse_canal]
mov ecx,1
mov edi,carac
int 65h
cmp eax,0
jne erreur_cnxtcp
cmp ecx,0
je boucle

jmp affichage_rec




;*************************************************************************************** messages d'erreurs

port_absent:
mov edx,msgerr2
mov al,11
mov ah,0Ch ;couleur
int 63h
jmp changer_port

port_reserve:
mov edx,msgerr3
mov al,11
mov ah,0Ch ;couleur
int 63h
jmp changer_port

erreurp:
mov edx,msgerr4
mov al,11
mov ah,0Ch ;couleur
int 63h
ret

erreur_init_cpnr:
mov edx,msgerr5
mov al,11
mov ah,0Ch ;couleur
int 63h
jmp changer_port

erreur_cnxtcp:
mov edx,msgerr6
mov al,11
mov ah,0Ch ;couleur
int 63h
jmp changer_port




;*************************************************
config_affichage:
xor byte[mode],1
jmp boucle


touche_entre:
mov ecx,13
jmp affichage_carac


touche_back:
fs
mov edi,[ad_curseur_texte]
fs
cmp edi,[ad_texte]
je fin_touche_back
sub edi,4
fs
mov dword[ad_curseur_texte],edi
fs
mov dword[edi],0
mov eax,7
int 63h
fin_touche_back:
mov ecx,8
jmp envoie_carac


fin:
int 60h



;**************************************************************************************************
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




;***************************************************
sdata1:
org 0

num_port:      ;0=COM1 etc... T=tcp
db "1",0
vitesse_port:
db "9600",0,0,0,0,0,0,0,0
bits_port:     ;7 ou 8
db "8",0
parite_port:  ;N?pas de parité I=parité impaire(odd) P=parité impaire(even)
db "N",0
stop_port:   ;1 ou 2
db "1",0

mode:   ;mode de fonctionnement 0=affiche caractère reçu et tapé 1=affiche uniquement caractère reçu
db 0

id_tache:
dw 0
adresse_canal:
dd 0

ip_cible:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0

port_cible:
dd 0,0

port_local:
dd 0,0

commande_ethernet:
db 8,1
cmd_port:
dw 0
cmd_max:
dw 0
cmd_fifo:
dw 8,0 
cmd_port_dest:
dw 0
cmd_ip:
dd 0
cmd_ip6:
dd 0,0,0,0



msg1:
db "TERM: Terminal de communication par port",0

msg2:
db "quel port de Communication souhaitez vous uttiliser?",13
db "(1 à 8 port COM, T=communication par TCP/IP, echap pour quitter)",13,0
msg3:
db 13,"quel vitesse de transmission (en Baud) pour ce port?",13,0
msg4:
db 13,"7 ou 8 bits par caractère envoyé?",13,0
msg5:
db 13,"quel type de parité?  N=pas de parité I=parité impaire(odd) P=parité impaire(even)",13,0
msg6:
db 13,"1 ou 2 bit de stop par caractère envoyé?",13,0
msg7:
db 13,"quel est l'adresse IP de la cible?",13,0
msg8:
db 13,"Quel est le port TCP de la cible?",13,0
msg9:
db 13,"Quel est le Port TCP local à utiliser?",13,0


msgerr1:
db 13,"erreur d'ecriture sur port ",13,0



msgerr2:
db 13,"ce port n'existe pas",0

msgerr3:
db 13,"ce port est réservé",0

msgerr4:
db 13,"parametre choisi incorrecte, réessayez",0


msgerr5:
db 13,"erreur lors de l'ouverture de la connexion, verifiez les paramètres",0


msgerr6:
db 13,"fermeture de la connexion TCP par le driver de la carte",13,0


carac:
dd 0,0,0,0




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
