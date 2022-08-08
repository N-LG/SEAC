bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Pilote pour usage IPv4 d'une carte 3C90x"
scode:
org 0


include "ip_code.inc" ;include standard pour les pilotes IP pour carte réseau

int 60h





eepromCommand equ 0Ah
eepromdata equ 0Ch
timer equ 1Ah
txstatus equ 1Bh
command equ 0Eh
intstatus equ 0Eh
dmactrl equ 20h
dnlistptr equ 24h
txfreethresh equ 2Fh
uppktstatus equ 30h
freetimer equ 34h
countdown equ 36h
uplistptr equ 38h


;********************************************************************************************
init_carte:
pushad


;recherche une carte portant la signature vendor ID et Device ID spécifique a la carte
mov ebx,80000000h
boucle_rech_pci:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx

;3C90X
cmp eax,900010B7h   ;PCI 10/100 Mbps; shared 10BASE-T/100BASE-TX connector
je pci_trouv_a
cmp eax,900110B7h   ;PCI 10/100 Mbps; shared 10BASE-T/100BASE-T4 connector
je pci_trouv_a
cmp eax,905010B7h   ;PCI 10BASE-T (TPO)
je pci_trouv_a
cmp eax,905110B7h   ;PCI 10BASE-T/10BASE2/AUI (COMBO)
je pci_trouv_a

;3C90XB
cmp eax,905410B7h   ;(selon info internet)
je pci_trouv_b
cmp eax,905510B7h   ;PCI 10/100 Mbps; shared 10BASE-T/100BASE-TX connector
je pci_trouv_b
cmp eax,905610B7h   ;PCI 10/100 Mbps; shared 10BASE-T/100BASE-T4 connector
je pci_trouv_b
cmp eax,905810B7h   ;(selon info internet)
je pci_trouv_b
cmp eax,900410B7h   ;PCI 10BASE-T (TPO)
je pci_trouv_b
cmp eax,900510B7h   ;PCI 10BASE-T/10BASE2/AUI (COMBO)
je pci_trouv_b
cmp eax,900610B7h   ;PCI 10BASE-T/10BASE2 (TPC)
je pci_trouv_b
cmp eax,900A10B7h   ;PCI 10BASE-FL
je pci_trouv_b
cmp eax,905A10B7h   ;PCI 10BASE-FX
je pci_trouv_b

;3C90XC
cmp eax,920010B7h   ;EtherLink 10/100 PCI (TX)  --> testé!
je pci_trouv_c
cmp eax,980510B7h   ;EtherLink Server 10/100 PCI (TX) (carte nommé 3c980-C mais présenté dans la doc de la 3c905-C)
je pci_trouv_c

;????????????????????????????il existe apparament d'autres cartes compatibles, a insérer ici

add ebx,400h
test ebx,7F000000h
jz boucle_rech_pci

;affiche un message comme quoi aucune carte n'as été detecté
mov edx,msg1
mov al,6        
int 61h
popad
mov eax,1
ret


pci_trouv_a:
mov byte[type]," "
jmp pci_trouv

pci_trouv_b:
mov byte[type],"B"
jmp pci_trouv

pci_trouv_c:
mov byte[type],"C"
;jmp pci_trouv


pci_trouv:
mov [pci_base],ebx



;lit la base des e/s
mov dx,0CF8h
mov eax,[pci_base]
add eax,10h
out dx,eax
mov dx,0CFCh
in eax,dx
and eax,0FFFFFF80h
mov [es_base],eax

;active controle par e/s
mov dx,0CF8h
mov eax,[pci_base]
add eax,4
out dx,eax
mov dx,0CFCh
mov eax,5   ;command + status register
out dx,eax


;effectue un global reset
mov dx,[es_base]
add dx,command
mov ax,00h  ;reset global
out dx,ax
call attend_fin_commande

;reserve une zone mémoire physique
mov ecx,2040h
mov al,0
xor ebx,ebx
xor edx,edx
xor esi,esi
xor edi,edi
int 65h
cmp eax,0
je memoire_ok

int 60h

memoire_ok:
mov [adresse_physique_zt],edx
mov [adresse_logique_zt],ebx

mov [descr_rx],edx
add edx,20h
mov [zt_rx],edx
add edx,1000h
mov [descr_tx],edx
add edx,20h
mov [zt_tx],edx


;****************************************
;configure la reception

;prépare l'UPD
mov eax,[zt_rx]
mov dword[upd_upnextpointer],0
mov dword[upd_uppktstatus],0
mov [upd_upfragadress],eax
mov dword[upd_upfraglen],080000FFFh

;écrit l'UPD en mémoire
mov al,5
mov ebx,[adresse_logique_zt]
mov ecx,16
mov edi,0
mov esi,upd_upnextpointer
int 65h

;écrit l'adresse de l'UPD
mov dx,[es_base]
add dx,uplistptr
mov eax,[descr_rx]
out dx,eax

mov dx,[es_base]
add dx,command
mov ax,08008h  ;accepte toute les trames
out dx,ax
call attend_fin_commande
mov ax,02000h  ;active la reception
out dx,ax
call attend_fin_commande

;************************************************
;configurations diverses
mov ax,1000h  ;active l'alim
out dx,ax
call attend_fin_commande
mov ax,7000h  ;désactive les interruptions
out dx,ax
call attend_fin_commande
mov ax,6FFFh  ;aquitte toutes interruptions (je ne sais pas si c'est VRAIMENT utile)
out dx,ax
call attend_fin_commande
mov dx,[es_base]
add dx,command
mov ax,0A800h  ;enable statistique
out dx,ax
call attend_fin_commande





;*******************************************************
;récupère l'adresse MAC de l'EEPROM
mov eax,10
call lire_eeprom
xchg al,ah
mov [adresse_mac],ax
mov eax,11
call lire_eeprom
xchg al,ah
mov [adresse_mac+2],ax
mov eax,12
call lire_eeprom
xchg al,ah
mov [adresse_mac+4],ax




popad
xor eax,eax
ret




attend_fin_commande:
in ax,dx
in ax,dx
in ax,dx
boucle_reset:
in ax,dx
and ax,1000h
cmp ax,1000h
je boucle_reset
ret


attend_dispo_eeprom:
in ax,dx
in ax,dx
in ax,dx
@@:
in ax,dx
and ax,8000h
cmp ax,8000h
je @b
ret



lire_eeprom:
push edx
and eax,0Fh
or eax,80h  ;commande lecture

push eax
mov dx,[es_base]
add dx,command
mov ax,0800h  ;select bank 0
out dx,ax
call attend_fin_commande

mov dx,[es_base]
add dx,eepromCommand
call attend_dispo_eeprom
pop eax
out dx,ax
call attend_dispo_eeprom
add dx,eepromdata-eepromCommand
in ax,dx
pop edx
ret


;lire_mii:
;mov dx,[es_base]
;add dx,command
;mov ax,0804h  ;select bank 4
;out dx,ax
;call attend_fin_commande
;mov dx,[es_base]
;add dx,8 ;PhysicalMgmt


;********************************************************************************************************
rec_trame:
pushad
push edi
mov al,4
mov ebx,[adresse_logique_zt]
mov ecx,16
mov esi,0
mov edi,upd_upnextpointer
int 65h
pop edi

mov eax,[upd_uppktstatus]
test eax,8000h
jz rec_trame_vide
test eax,0FFFh
jz rec_trame_vide
and eax,0FFFh
mov [taille_recu],eax

mov dx,[es_base]
add dx,command
mov ax,3000h  ;upstall
out dx,ax
call attend_fin_commande

;lit la trame reçu
mov al,4
mov ebx,[adresse_logique_zt]
mov ecx,[taille_recu]
mov esi,20h
int 65h

;prépare l'UPD
mov eax,[zt_rx]
mov dword[upd_upnextpointer],0
mov dword[upd_uppktstatus],0
mov [upd_upfragadress],eax
mov dword[upd_upfraglen],080000FFFh

;écrit l'UPD en mémoire
mov al,5
mov ebx,[adresse_logique_zt]
mov ecx,16
mov edi,0
mov esi,upd_upnextpointer
int 65h

;écrit l'adresse de l'UPD
mov dx,[es_base]
add dx,uplistptr
mov eax,[descr_rx]
out dx,eax

mov dx,[es_base]
add dx,command
mov ax,3001h  ;upunstall
out dx,ax
call attend_fin_commande

popad
xor eax,eax
mov ecx,[taille_recu]
ret


rec_trame_vide:
popad
xor eax,eax
xor ecx,ecx
ret


erreur_rec_trame:
popad
xor ecx,ecx
mov eax,2                 ;cer_lec
ret





;**********************************************************************************************
env_trame:
pushad

mov dx,[es_base]
add dx,command
mov ax,5800h  ;tx reset
out dx,ax
call attend_fin_commande

;désactive l'emission (désactivé parce que le reset fait la même chose et en + remet d'aplomb le controleur)
;mov dx,[es_base]
;add dx,command
;mov ax,5000h  ;tx disable
;out dx,ax
;call attend_fin_commande

;désactive l'accès mémoire
mov dx,[es_base]
add dx,command
mov ax,3002h  ;dn stall
out dx,ax
call attend_fin_commande

;prépare la DPD
mov dword[dpd_dnnextpointer],0
cmp byte[type],"B"
je dpd_type_b
cmp byte[type],"C"
je dpd_type_c

dpd_type_a:
mov dword[dpd_framestartheader],ecx
jmp suite_crea_dpd

dpd_type_b:
;jmp suite_crea_dpd
dpd_type_c:
inc dword[packet_id]
mov eax,[packet_id]
shl eax,2
and eax,03FCh
;or eax,10000000h
or eax, 10b
mov [dpd_framestartheader],eax

suite_crea_dpd:
or dword[dpd_framestartheader],8000h ;met a 1 le bit TxIndicate
mov eax,[zt_tx]
mov [dpd_dnfragadress],eax
mov [dpd_dnfraglen],ecx
or dword[dpd_dnfraglen],080000000h

;écrit le DPD en mémoire
push ecx
push esi
mov al,5
mov ebx,[adresse_logique_zt]
mov ecx,32
mov edi,1020h
mov esi,dpd_dnnextpointer
int 65h
pop esi
pop ecx

;écrit le contenue de la trame
mov al,5
mov ebx,[adresse_logique_zt]
mov edi,1040h
int 65h

;écrit l'adresse du DPD
mov dx,[es_base]
add dx,dnlistptr
mov eax,[descr_tx]
out dx,eax

;active l'emission
mov dx,[es_base]
add dx,command
mov ax,3003h  ;dn unstall
out dx,ax
call attend_fin_commande

;active l'emission
mov dx,[es_base]
add dx,command
mov ax,4800h  ;tx enable
out dx,ax
call attend_fin_commande

mov dx,[es_base]         
add dx,txstatus
mov ecx,1500          ;lit 1500 fois le registre TxStatus pour voir le résultat          
boucle_attent_fin_tx:
in al,dx
test al,80h
jnz fin_emission
int 62h                ;si c'est pas encore bon done le controle aux autres tâches 
dec ecx
jnz boucle_attent_fin_tx

mov al,0FFh

erreur_emission:
mov [error],al
popad
xor eax,eax
mov al,[error]
ret

fin_emission:
test al,3Fh
jnz erreur_emission
popad
xor eax,eax
ret






sdata1:
org 0
msg1:
db "aucune carte compatible 3C90x n'as été detecté",13,0
msgok1: 
db "la carte compatible 3C90x"
type:
db 0
db " d'adresse ",0
msgok2:
db " a été initialisé",13,0

pci_base:
dd 0
es_base:
dd 0

adresse_logique_zt:
dd 0
adresse_physique_zt:
dd 0
descr_rx:
dd 0
zt_rx:
dd 0
descr_tx:
dd 0
zt_tx:
dd 0
taille_recu:
dd 0

packet_id:
dd 0
error:
db 0

upd_upnextpointer:
dd 0
upd_uppktstatus:
dd 0
upd_upfragadress:
dd 0
upd_upfraglen:
dd 0
dd 0,0,0,0

dpd_dnnextpointer:
dd 0
dpd_framestartheader:
dd 0
dpd_dnfragadress:
dd 0
dpd_dnfraglen:
dd 0
dd 0,0,0,0


include "ip_data.inc" ;include standard pour les pilotes IP pour carte réseau

sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
