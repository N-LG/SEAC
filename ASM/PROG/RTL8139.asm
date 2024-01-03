rtl8139.asm:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Pilote pour usage IPv4 d'une carte RTL8139"
scode:
org 0




include "ip_code.inc" ;include standard pour les pilotes IP pour carte réseau




;********************************************************************************************
init_carte:
pushad


;convertit l'adresse passée en argument en "adresse pci"
cmp byte[arg_0+2],":"
jne erreur_adresse
cmp byte[arg_0+5],"."
jne erreur_adresse
cmp byte[arg_0+7],0
jne erreur_adresse

mov ebx,80000000h

mov edx,arg_0
mov eax,101
int 61h
test ecx,0FFFFFF00h
jnz erreur_adresse
shl ecx,16
or ebx,ecx

mov edx,arg_0+3
mov eax,101
int 61h
test ecx,0FFFFFFE0h
jnz erreur_adresse
shl ecx,11
or ebx,ecx

mov edx,arg_0+6
mov eax,101
int 61h
test ecx,0FFFFFFF8h
jnz erreur_adresse
shl ecx,8
or ebx,ecx

mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx

;verifie que le type est compatible
cmp eax,813910ECh   ;carte realtek 8139
je pci_trouv

;????????????????????????????il existe apparament des clones; a verifier

popad
mov eax,1
ret


erreur_adresse:
mov edx,msgadresse
call message_console
int 60h


pci_trouv:
mov [pci_base],ebx

;active controle par e/s
mov dx,0CF8h
mov eax,[pci_base]
add eax,4
out dx,eax
mov dx,0CFCh
mov eax,5   ;command + status register
out dx,eax

;enregistre la base des e/s
mov dx,0CF8h
mov eax,[pci_base]
add eax,10h
out dx,eax
mov dx,0CFCh
in eax,dx        
and eax,0FFFFFFFEh
mov [es_base],eax

;demande un remise a zéro des registre suivant enregistré par eeprom
;mov dx,[es_base]
;add dx,50h
;mov al,040h
;out dx,al
;att_fin_raz_eeprom:
;in al,dx
;test al,0C0h
;jnz att_fin_raz_eeprom

;lit adresse MAC
mov dx,[es_base]
in eax,dx
mov [adresse_mac],eax
add dx,4
in ax,dx
mov [adresse_mac+4],ax

;reserve une zone mémoire physique
mov ecx,12010h
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

;démarre l'horloge, ce registre est absent de la documentation mais présent dans deux sources trouvé sur internet
mov   edx,[es_base]
add   edx,05Bh          
mov   al,"R"		;"H" arrete l'horloge	    
out   dx,al

;déverrouille l'accès aux config register
mov dx,[es_base]
add dx,50h
mov al,0C0h
out dx,al
 
mov dx,[es_base]
add dx,052h         ;config1
mov al,001h         ;PMen=1
out dx,al

mov dx,[es_base]
add dx,05Ah         ;config4
mov al,000h      
out dx,al


;fait un reset du controlleur
mov dx,[es_base]
add dx,37h
mov al,010h
out dx,al

att_fin_raz_controleur:
in al,dx
test al,010h
jnz att_fin_raz_controleur

;déverrouille l'accès aux config register
mov dx,[es_base]
add dx,50h
mov al,0C0h
out dx,al

;active la carte
mov dx,[es_base]
add dx,37h
mov al,00Ch
out dx,al

;configure l'adresse de la zt de réception
mov dx,[es_base]
add dx,30h
mov eax,[adresse_physique_zt]
out dx,eax

;désactive les interruptions
mov dx,[es_base]
add dx,3Ch
mov ax,0
out dx,ax

;configure la reception (RCR)
mov dx,[es_base]
add dx,44h
mov eax,0FF1Fh ;no rx threshold, 64k buffer, unlimited DMA burst, accept all packet
out dx,eax


;configure l'adresse des ZT d'emission
mov dx,[es_base]
mov eax,[adresse_physique_zt]
add dx,20h
add eax,10000h
out dx,eax
add dx,4
add eax,800h
out dx,eax
add dx,4
add eax,800h
out dx,eax
add dx,4
add eax,800h
out dx,eax

;configure la transmission (TCR)
mov dx,[es_base]
add dx,40h
mov eax,03000700h ;16 tx retry, Max DMA Burst Size=2k crc=ok IGT=standard 
out dx,eax


;verrouille l'accès aux config register
mov dx,[es_base]
add dx,50h
mov al,00h
out dx,al


popad
xor eax,eax
ret


;********************************************************************************************************
rec_trame:
pushad
;test si des données ont été reçu
mov dx,[es_base]
add dx,37h
in al,dx
test al,1
jnz pas_rec_trame

;charge l'en tete de reception de trame
mov dx,[es_base]
add dx,38h
in ax,dx
add ax,10h
mov [pointeur_reception],ax


mov ecx,4
xor esi,esi
mov si,ax
push edi
mov edi,flag_rx
mov al,4
mov ebx,[adresse_logique_zt]
int 65h
pop edi
cmp eax,0
jne erreur_rec_trame





;charge la trame 
xor ecx,ecx
mov cx,[taille_rx]
xor eax,eax
mov ax,[pointeur_reception]
add eax,ecx
test eax,0FFFF0000h
jnz doublebloc_rec_trame



;la trame est d'un bloc
xor esi,esi
mov si,[pointeur_reception]
add esi,4
mov al,4
mov ebx,[adresse_logique_zt]
int 65h
cmp eax,0
jne erreur_rec_trame
jmp maj_rec_trame



doublebloc_rec_trame:    ;charge la trame en 2x
mov ecx,10000h
xor esi,esi
mov si,[pointeur_reception]
add esi,4
sub ecx,esi
push ecx
mov al,4
mov ebx,[adresse_logique_zt]
int 65h
pop ebx
cmp eax,0
jne erreur_rec_trame

add edi,ebx    ;charge le deuxième bloc
xor ecx,ecx
mov cx,[taille_rx]

sub ecx,ebx
xor esi,esi
mov al,4
mov ebx,[adresse_logique_zt]
int 65h
cmp eax,0
jne erreur_rec_trame

maj_rec_trame:    ;met a jour l'index de la zt de reception
mov dx,[es_base]
add dx,38h
in ax,dx
add ax,[taille_rx]
add ax,7
and ax,0FFFCh
out dx,ax


popad
xor ecx,ecx
xor eax,eax
mov cx,[taille_rx]
ret



pas_rec_trame:
popad
xor ecx,ecx
xor eax,eax
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
add dx,3Eh
mov ax,0FFFFh
out dx,ax 

recommence_test_zone_tx:
mov dx,[es_base]
add dx,[base_tx]
add dx,10h
in eax,dx

test eax,040008000h
jnz zone_tx_ok     ;test si tok=1 ou TABT=1
test  eax,0x1fff
jz zone_tx_ok      ;ou si il n'y as pas de donnée dans la zt
add word[base_tx],4
and word[base_tx],0Fh
jmp recommence_test_zone_tx

zone_tx_ok:
;configure la transmission (TCR)
push edx
mov dx,[es_base]
add dx,40h
mov eax,03000700h ;16 tx retry, Max DMA Burst Size=2k crc=ok IGT=standard 
out dx,eax
pop edx

;configure l'adresse de la ZT d'emission
add dx,10h
xor eax,eax
mov ax,dx
sub ax,20h
sub ax,[es_base]
shl eax,9   ;div par 4 et multiplie par 2048
add eax,[adresse_physique_zt]
add eax,10000h
out dx,eax
sub dx,10h

xor edi,edi
mov di,dx
sub di,[es_base]
sub di,10h
shl edi,9   ;div par 4 et multiplie par 2048
add edi,10000h
mov al,5
mov ebx,[adresse_logique_zt]
int 65h
cmp eax,0
je data_tx_ok
popad
mov eax,cer_ecr
ret


data_tx_ok:
mov eax,ecx
and eax,7FFh
out dx,eax

add word[base_tx],4
and word[base_tx],0Fh

popad
xor eax,eax
ret









sdata1:
org 0
msgnok:
db "RTL8139: card selected not compatible",13,0
db "RTL8139: carte selectionné non compatible",13,0
msgadresse:
db "RTL8139: error in address format",13,0
db "RTL8139: erreur dans le format de l'adresse",13,0
msgok1:
db "the RTL8139 card with address ",0
db "la carte RTL8139 d'adresse ",0
msgok2:
db " has been initialized",13,0
db " a été initialisé",13,0

pci_base:
dd 0
es_base:
dd 0
adresse_physique_zt:
dd 0
adresse_logique_zt:
dd 0
base_tx:
dd 0

flag_rx:
dw 0
taille_rx:
dw 0
pointeur_reception:
dw 0



include "ip_data.inc" ;include standard pour les pilotes IP pour carte réseau

sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
