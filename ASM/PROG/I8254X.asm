i8254x.asm:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Pilote pour usage IPv4 d'une carte compatible Intel 8254x"
scode:
org 0

include "ip_code.inc" ;include standard pour les pilotes IP pour carte réseau





ad_descr_tx equ 20000h  ;adresse des descripteur d'émission dans la mémoire réservé
nb_tx equ 8          ;nombre de 
ad_descr_rx equ 16*nb_tx+ad_descr_tx  ;adresse des descripteur de reception dans la mémoire réservé
nb_rx equ 120

ad_zttx equ 16 * (nb_tx+nb_rx)+ad_descr_tx
ad_ztrx equ 16 * (nb_tx+nb_rx)+2048*nb_tx+ad_descr_tx

taille_mem equ 2048 * (nb_tx+nb_rx) + ad_zttx

;********************************************************************************************
init_carte:
push ecx
push edx
push ebx
push esp
push ebp
push esi
push edi


;recherche une carte portant la signature vendor ID et Device ID spécifique a la carte
mov ebx,80000000h
boucle_rech_pci:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx

cmp eax,10198086h   ;82547EI-A0 82547EI-A1 82547EI-B0 82547GI-B0
je pci_trouv
cmp eax,101A8086h   ;82547EI-B0(mobile) 
je pci_trouv
cmp eax,10108086h   ;82546EB-A1(Dual Port)
je pci_trouv       
cmp eax,10128086h   ;82546EB-A1(Dual Port+fiber)
je pci_trouv
cmp eax,101D8086h   ;82546EB-A1(quad Port)
je pci_trouv  
cmp eax,10798086h   ;82546GB-B0(Dual Port)
je pci_trouv  
cmp eax,107A8086h   ;82546GB-B0(Dual Port+fiber)
je pci_trouv
cmp eax,107B8086h   ;82546GB-B0(Dual Port+SerDes)
je pci_trouv
cmp eax,100F8086h   ;82545EM-A  -> testé sous virtualbox: ok
je pci_trouv
cmp eax,10118086h   ;82545EM-A(fiber)
je pci_trouv
cmp eax,10268086h   ;82545GM-B
je pci_trouv
cmp eax,10278086h   ;82545GM-B(fiber)
je pci_trouv
cmp eax,10288086h   ;82545GM-B(SerDes)
je pci_trouv
cmp eax,11078086h   ;82544EI-A4
je pci_trouv 
cmp eax,11128086h   ;82544GC-A4
je pci_trouv
cmp eax,10138086h   ;82541EI-A0 82541EI-B0
je pci_trouv
cmp eax,10188086h   ;82541EI-B0(mobile)
je pci_trouv
cmp eax,10768086h   ;82541GI-B1 82541PI-C0
je pci_trouv
cmp eax,10778086h   ;82541GI-B1(mobile)
je pci_trouv
cmp eax,10788086h   ;82541ER-C0
je pci_trouv
cmp eax,10178086h   ;82540EP-A
je pci_trouv
cmp eax,10168086h   ;82540EP-A(mobile)
je pci_trouv
cmp eax,100E8086h   ;82540EM-A -> testé sous virtualbox: ok
je pci_trouv
cmp eax,10158086h   ;82540EM-A(mobile)
je pci_trouv                     
cmp eax,10048086h   ;82543GC(pas dans la doc) -> testé sous virtualbox: ok
je pci_trouv  
                
;???????????il n'existe selon la doc pas d'autres cartes compatibles,mais sinon a insérer ici

add ebx,400h
test ebx,7F000000h
jz boucle_rech_pci

;affiche un message comme quoi aucune carte n'as été detecté
mov edx,msger1
mov al,6        
int 61h
mov eax,1
jmp erreur_init


;affiche un message signalant l'erreur d'accès a l'EEPROM
erreur_eeprom:
mov edx,msger2
mov al,6        
int 61h
mov eax,1
jmp erreur_init




;***********************
pci_trouv:
mov [pci_base],ebx


;test si un canal as déja été définis
mov edx,[adresse_physique_zt]
mov ebx,[adresse_logique_zt]
cmp edx,0
jne memoire_ok

;reserve une zone mémoire physique
mov ecx,taille_mem   ;taille
mov al,0
xor ebx,ebx
mov edx,2
mov esi,07FFFFh   ;masque de la granularité
int 65h
cmp eax,0
je memoire_ok
mov eax,1  ;?????????????????????
jmp erreur_init

memoire_ok:
mov [adresse_physique_zt],edx
mov [adresse_logique_zt],ebx


;configure les E/S
mov dx,0CF8h
mov eax,[pci_base]
add eax,10h  ;bar0
out dx,eax
mov dx,0CFCh
in eax,dx 
test eax,100b
jnz mem64



;configure la memoire pour du 32bit
mov dx,0CF8h
mov eax,[pci_base]
add eax,10h
out dx,eax
mov dx,0CFCh
mov eax,[adresse_physique_zt]
out dx,eax


;configure adress flash en 32bit ---- on s'en fout de l'acces flash pour l'instant
;mov dx,0CF8h
;mov eax,[pci_base]
;add eax,14h
;out dx,eax
;mov dx,0CFCh
;mov eax,[adresse_physique_zt]
;out dx,eax

;enregistre la base des e/s
mov dx,0CF8h
mov eax,[pci_base]
add eax,18h
out dx,eax
mov dx,0CFCh
in eax,dx        
and eax,0FFFFFFFEh
mov [es_base],eax
jmp finconfmem


mem64:   ;configure la memoire pour du 64bit
mov dx,0CF8h
mov eax,[pci_base]
add eax,10h
out dx,eax
mov dx,0CFCh
mov eax,[adresse_physique_zt]
or eax,100b
out dx,eax
mov dx,0CF8h
mov eax,[pci_base]
add eax,14h
out dx,eax
mov dx,0CFCh
xor eax,eax
out dx,eax



;configure adress flash en 64bit ---- on s'en fout de l'acces flash pour l'instant
;mov dx,0CF8h
;mov eax,[pci_base]
;add eax,18h
;out dx,eax
;mov dx,0CFCh
;mov eax,[adresse_physique_zt]
;or eax,100b
;out dx,eax
;mov dx,0CF8h
;mov eax,[pci_base]
;add eax,1Ch
;out dx,eax
;mov dx,0CFCh
;xor eax,eax
;out dx,eax


;enregistre la base des e/s
mov dx,0CF8h
mov eax,[pci_base]
add eax,20h
out dx,eax
mov dx,0CFCh
in eax,dx        
and eax,0FFFFFFFEh
mov [es_base],eax



finconfmem:
;active controle par e/s
mov dx,0CF8h
mov eax,[pci_base]
add eax,4
out dx,eax
mov dx,0CFCh
mov eax,5   ;command + status register
out dx,eax




;*******************************************************
;récupère l'adresse MAC
mov eax,0
call lire_eeprom
cmp edx,0
jne erreur_eeprom
mov [adresse_mac],ax
mov eax,1
call lire_eeprom
cmp edx,0
jne erreur_eeprom
mov [adresse_mac+2],ax
mov eax,2
call lire_eeprom
cmp edx,0
jne erreur_eeprom
mov [adresse_mac+4],ax


;reset la carte
mov dx,[es_base]
mov eax,0   ;CTRL
out dx,eax
add dx,4
in eax,dx
or eax,04000000h
out dx,eax

;attend 50ms
mov eax,1
mov ecx,20
int 61h


;active la carte
mov dx,[es_base]
mov eax,0   ;CTRL
out dx,eax
add dx,4
mov eax,061h  ;FD ASDE SLU 13.4.1
out dx,eax

;attend 50ms
mov eax,1
mov ecx,20
int 61h

;configure les interruption
mov dx,[es_base]
mov eax,0D8h   ;IMC Interrupt Mask Clear Register
out dx,eax
add dx,4
mov eax,0FFFFFFFFh  ;désactive toutes les interruptions
out dx,eax




;remplit les descripteur d'émission
mov edi,ad_descr_tx
mov ecx,nb_tx
mov eax,[adresse_physique_zt]
add eax,ad_zttx
mov [descr_tx],eax
mov dword[descr_tx+4],0
mov dword[descr_tx+8],0
mov dword[descr_tx+12],0

boucle_init_zttx:
push ecx
mov al,5
mov ebx,[adresse_logique_zt]
mov ecx,16
mov esi,descr_tx
int 65h
pop ecx
cmp eax,0
jne erreur_init
add edi,16
add dword[descr_tx],2048
dec ecx
jnz boucle_init_zttx


;remplit les descripteur de réception
mov edi,ad_descr_rx
mov ecx,nb_rx
mov eax,[adresse_physique_zt]
add eax,ad_ztrx
mov [descr_rx],eax
mov dword[descr_rx+4],0
mov dword[descr_rx+8],0
mov dword[descr_rx+12],0

boucle_init_ztrx:
push ecx
mov al,5
mov ebx,[adresse_logique_zt]
mov ecx,16
mov esi,descr_rx
int 65h
pop ecx
cmp eax,0
jne erreur_init
add edi,16
add dword[descr_rx],2048
dec ecx
jnz boucle_init_ztrx


;initialise la zt de réception
mov dx,[es_base]
mov eax,02800h   ;RDBAL
out dx,eax
add dx,4
mov eax,[adresse_physique_zt]
add eax,ad_descr_rx 
out dx,eax

mov dx,[es_base]
mov eax,02804h   ;RDBAH
out dx,eax
add dx,4
mov eax,0  
out dx,eax

mov dx,[es_base]
mov eax,02808h   ;RDLEN
out dx,eax
add dx,4
mov eax,nb_rx * 16
out dx,eax

mov dx,[es_base]
mov eax,02810h   ;RDH
out dx,eax
add dx,4
mov eax,0  
out dx,eax

mov dx,[es_base]
mov eax,02818h   ;RDT
out dx,eax
add dx,4
mov eax,nb_rx-1
out dx,eax


;initialise la zt d'emission
mov dx,[es_base]
mov eax,03800h   ;TDBAL
out dx,eax
add dx,4
mov eax,[adresse_physique_zt]
add eax,ad_descr_tx  
out dx,eax

mov dx,[es_base]
mov eax,03804h   ;TDBAH
out dx,eax
add dx,4
mov eax,0  
out dx,eax

mov dx,[es_base]
mov eax,03808h   ;TDLEN
out dx,eax
add dx,4
mov eax,nb_tx * 16  
out dx,eax

mov dx,[es_base]
mov eax,03810h   ;TDH
out dx,eax
add dx,4
mov eax,0   
out dx,eax

mov dx,[es_base]
mov eax,03818h   ;TDT
out dx,eax
add dx,4
mov eax,0 
out dx,eax


;configure la reception
mov dx,[es_base]
mov eax,0100h   ;RCTL Receive Control Register
out dx,eax
add dx,4
mov eax,0801Ah  ;EN UPE MPE BAM 13.4.22 
out dx,eax


;configure l'emission
mov dx,[es_base]
mov eax,0400h   ;TCTL   Transmit Control Register
out dx,eax
add dx,4
mov eax,0400F2h  ;EN CT=0Fh COLD=40h 13.4.33  
out dx,eax


;configure l'emission
;mov dx,[es_base]
;mov eax,0410h   ;TIPG   Transmit IPG Register
;out dx,eax
;add dx,4
;mov eax,602006h   
;out dx,eax







;*******************************************************
;affiche un message comme quoi la carte est ok
mov edx,msgok1
mov al,6        
int 61h

mov al,111
mov ecx,adresse_mac
mov edx,tempo
int 61h
mov al,6        
mov edx,tempo
int 61h

mov edx,msgok2
mov al,6        
int 61h


xor eax,eax
erreur_init:
pop edi
pop esi
pop ebp
pop esp
pop ebx
pop edx
pop ecx
ret




;********************************************************************************************************
rec_trame:
push edx
push ebx
push esp
push ebp
push esi
push edi
mov [ad_copie_rec_trame],edi

;test si une trame est disponible dans la zt
mov dx,[es_base]
mov eax,02810h   ;RDH
out dx,eax
add dx,4
in eax,dx
mov ebx,eax
cmp ebx,0
jne rec_trame_headok
mov ebx,nb_rx
rec_trame_headok:
dec ebx
mov dx,[es_base]
mov eax,02818h   ;RDT
out dx,eax
add dx,4
in eax,dx
cmp eax,ebx
je rec_trame_vide



;incrémente le registre TAIL
inc eax
cmp eax,nb_rx
jne okmaj
xor eax,eax
okmaj:
push eax
mov dx,[es_base]
mov eax,02818h   ;RDT
out dx,eax
add dx,4
pop eax
out dx,eax



;lit le descripteur de reception
push eax
mov esi,eax
shl esi,4
add esi,ad_descr_rx
mov al,4
mov ebx,[adresse_logique_zt]
mov ecx,16
mov edi,descr_rx
int 65h
pop esi
cmp eax,0
jne erreur_rec_trame


;enregistre la taille de la trame
xor eax,eax
mov ax,[taille_rx]
mov [taille_rx_dw],eax


;lit les données
shl esi,11
add esi,ad_ztrx
mov al,4
mov ebx,[adresse_logique_zt]
mov ecx,[taille_rx_dw]
mov edi,[ad_copie_rec_trame]
int 65h
cmp eax,0
jne erreur_rec_trame


mov ecx,[taille_rx_dw]
xor eax,eax
pop edi
pop esi
pop ebp
pop esp
pop ebx
pop edx
ret


rec_trame_vide:
xor eax,eax
erreur_rec_trame:
xor ecx,ecx
pop edi
pop esi
pop ebp
pop esp
pop ebx
pop edx
ret






;**********************************************************************************************
env_trame:
push ecx
push edx
push ebx
push esp
push ebp
push esi
push edi
mov [taille_tx_dw],ecx
mov [ad_copie_env_trame],esi 


;préparer descripteur 
mov [taille_tx],cx
mov byte[checksum_tx],0
mov byte[command_tx],01h
mov dword[status_tx],0


;tester si espace disponible pour emission
test_env_ok:
mov dx,[es_base]
mov eax,03810h   ;TDH
out dx,eax
add dx,4
in eax,dx
mov ebx,eax
cmp ebx,0
jne env_trame_headok
mov ebx,nb_tx
env_trame_headok:
dec ebx
mov dx,[es_base]
mov eax,03818h   ;TDT
out dx,eax
add dx,4
in eax,dx
cmp eax,ebx
jne env_ok
int 62h
jmp test_env_ok
env_ok:



;ecrire descripteur d'envoie
push eax
mov edi,eax
shl edi,4
add edi,ad_descr_tx+8
mov al,5
mov ebx,[adresse_logique_zt]
mov ecx,8
mov esi,descr_tx+8
int 65h
pop edi
cmp eax,0
jne erreur_env_trame



;ecrire les données
shl edi,11
add edi,ad_zttx
mov al,5
mov ebx,[adresse_logique_zt]
mov ecx,[taille_tx_dw]
mov esi,[ad_copie_env_trame]
int 65h
cmp eax,0
jne erreur_env_trame



;incrémenter pointeurs tail
mov dx,[es_base]
mov eax,03818h   ;TDT
out dx,eax
add dx,4
in eax,dx
inc eax
cmp eax,nb_tx
jne env_inc_tail
xor eax,eax
env_inc_tail:
out dx,eax


xor eax,eax
erreur_env_trame:
pop edi
pop esi
pop ebp
pop esp
pop ebx
pop edx
pop ecx
ret




;**********************************************************************************************
;sous fonctions


lire_eeprom:  ; in=eax=adress out=eax=data
push eax
mov dx,[es_base]
mov eax,14h   ;EERD
out dx,eax
add dx,4

pop eax
shl eax,8
or eax,1
out dx,eax
mov ecx,10000

boucle_lire_eeprom:
dec ecx
jz erreur_lire_eeprom
int 62h
in eax,dx
test eax,10h
jz boucle_lire_eeprom

shr eax,16
xor edx,edx
ret


erreur_lire_eeprom:
xor eax,eax
mov edx,-1
ret



sdata1:
org 0
msger1:
db "aucune carte compatible Intel 8254X n'as été detecté",13,0
msger2:
db "erreur lors de l'acces a la mémoire EEPROM d'une carte compatible Intel 8254X, impssible de terminer l'initialisation",13,0
msgok1: 
db "la carte compatible Intel 8254X d'adresse ",0
msgok2:
db " a été initialisé",13,0

pci_base:
dd 0
es_base:
dd 0


descr_tx:
dd 0,0
taille_tx:
dw 0
checksum_tx:
db 0
command_tx:
db 0
status_tx:
db 0
rsv_css_tx:
db 0
special_tx:
dw 0

descr_rx:
dd 0,0
taille_rx:
dw 0
checksum_rx:
dw 0
status_rx:
db 0
error_rx:
db 0
special_rx:
dw 0


adresse_physique_zt:
dd 0
adresse_logique_zt:
dd 0


taille_rx_dw:
dd 0
ad_copie_rec_trame:
dd 0

taille_tx_dw:
dd 0
ad_copie_env_trame:
dd 0


include "ip_data.inc" ;include standard pour les pilotes IP pour carte réseau

sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
