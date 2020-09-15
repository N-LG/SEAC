SF_USB.ASM:


;lecture descripteur appareil
;lecture configuration actuelle
;selection configuration actuelle
;lecture descripteur de configuration
;reservation usage appareil
;liberation reservation appareil
;ouverture connexion isocrone vers terminaison
;ouverture connexion interruption vers terminaison
;fermeture terminaison
;envoie donnée bulk
;reception donnée bulk
;envoie commande



iret








;****************************************************************************************************************************************************************************************************************
;envoie commande USB
sfusb_commande:        ;al=périphérique ah=endpoint ds:edx=zt des 8 octet de la commande ds:edi=adresse des données optionnel de commande
pushad
push ds
push es
push fs


push ds
pop es
mov bx,selramh
mov ds,bx
mov bx,seldat
mov fs,bx

xor ebx,ebx
mov bl,al
shl ebx,dc_desc_periph_usb
add ebx,ad_desc_periph_usb 
mov esi,ebx                ;esi=adresse du descripteur de périphérique

fs
test byte[esi+dpu_att],01b
jz sfusb_commande_err_param

xor ebx,ebx
fs
mov bl,[esi+dpu_ctrl] 
shl ebx,dc_desc_ctrl_usb
add ebx,ad_desc_ctrl_usb   ;ebx=adresse du descripteur de controleur

             
fs
cmp byte[ebx+dcu_type],01
je sfusb_commande_uhci
;fs
;cmp byte[ebx+dcu_type],02
;je sfusb_commande_ohci
;fs
;cmp byte[ebx+dcu_type],03
;je sfusb_commande_ehci
;fs
;cmp byte[ebx+dcu_type],04
;je sfusb_in_xhci
sfusb_commande_err_param:
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret




;(les 16 premier octet sont le descripteur mémoire de base)
uhci_bulkmem_cmd   equ 10h   ;8 octet
uhci_bulkmem_cmdto equ uhci_bulkmem_cmd+6
uhci_bulkmem_param_adterm equ 18h
uhci_bulkmem_param_tframe equ 1Ch
uhci_bulkmem_param_datainout equ 20h
uhci_bulkmem_param_pcs equ 24h
uhci_bulkmem_param_desc_perif equ 28h
uhci_bulkmem_param_desc_ctrl equ 2Ch
uhci_bulkmem_param_tod equ 30h


uhci_bulkmem_qh    equ 40h   ;16 octets
uhci_bulkmem_td    equ 50h   ;3*32 octets

uhci_bulkmem_data  equ 0B0h   ;taille variable




;**********************************************
sfusb_commande_uhci:    ;al=adresse ah=endpoint    edx=adresse de la commande   edi données a echanger

;réserve mémoire
mov ebp,ebx
push eax
push ecx
xor ecx,ecx
es
mov cx,[edx+6]
add ecx,uhci_bulkmem_data
call resmem
;????????????????gestion erreur reservation mémoire
pop ecx
pop eax
mov dword[ebx+8],39      ;??????????????????????????code zone mémoire a définir


;verifie les parametres
test ax,0F080h
jnz sfusb_commande_err_param


;enregistre parametre
push eax
and eax,07Fh
mov [ebx+uhci_bulkmem_param_adterm],eax
pop eax
and eax,0F00h
shr eax,1
or  [ebx+uhci_bulkmem_param_adterm],eax
xor ecx,ecx
es
mov cx,[edx+6]
mov [ebx+uhci_bulkmem_param_tframe],ecx
mov [ebx+uhci_bulkmem_param_datainout],edi
mov [ebx+uhci_bulkmem_param_desc_perif],esi      
mov [ebx+uhci_bulkmem_param_desc_ctrl],ebp


;enregistre commande
es
mov eax,[edx]
es
mov ecx,[edx+4]
mov [ebx+uhci_bulkmem_cmd],eax
mov [ebx+uhci_bulkmem_cmd+4],ecx


;crée la QH
mov dword[ebx+uhci_bulkmem_qh],1    ;LINK POINTER (marque link pointer invalide)
mov eax,ebx
add eax,uhci_bulkmem_td+100000h
mov dword[ebx+uhci_bulkmem_qh+4],eax  ;ELEMENT LINK POINTER (pointeur vers le premier TD)


;précalcule du dword Controle and status
mov ecx,018800000h ;CONTROL AND STATUS bit 23=TD actif  et bit 27-28=3 erreur avant arret  
mov esi,[ebx+uhci_bulkmem_param_desc_perif]
mov edi,[ebx+uhci_bulkmem_param_desc_ctrl]
fs
mov edx,[esi+dpu_port]
shl edx,1
add edx,ctrl_uhci_portsc1
fs
add edx,[edi+dcu_es]  ;dx=port
in ax,dx
test ax,100h
jz fin_precalc_uhci
or ecx,4000000h  ;26=low speed    
fin_precalc_uhci:
mov [ebx+uhci_bulkmem_param_pcs],ecx



;definie quantité transferé par TD
xor eax,eax
mov edx,[ebx+uhci_bulkmem_param_adterm]
and edx,0780h
shr edx,6
add edx,dpu_ted
add edx,[ebx+uhci_bulkmem_param_desc_perif]
fs
mov ax,[edx]
cmp eax,0
jne sfusb_commande_uhci_oktod
mov eax,8
sfusb_commande_uhci_oktod:
mov [ebx+uhci_bulkmem_param_tod],eax




;*****************
;crée le td de commande
mov edi,uhci_bulkmem_td
add edi,ebx

mov eax,edi
add eax,100020h
or  eax,4
mov [edi],eax    ;LINK POINTER

mov edx,[ebx+uhci_bulkmem_param_pcs]
mov dword[edi+4],edx ;CONTROL AND STATUS

mov eax,8 ;taille
dec eax
shl eax,13
or eax,[ebx+uhci_bulkmem_param_adterm] ;adresse+endpoint
shl eax,8
mov al,02Dh  ;pid
mov [edi+8],eax  ;TOKEN 

mov eax,ebx
add eax,uhci_bulkmem_cmd+100000h
mov [edi+12],eax ;BUFFER POINTER

add edi,32



;***************************
;création des TD IN
mov esi,80000h   ;1er data toggle a 1
mov ebp,ebx
add ebp,uhci_bulkmem_data+100000h
mov ecx,[ebx+uhci_bulkmem_param_tframe]
cmp ecx,0
je tdinstatus_sfusb_commande_uhci
bouclein_sfusb_commande_uhci:
cmp ecx,[ebx+uhci_bulkmem_param_tod]
jb partielin_sfusb_commande_uhci



;********************
;créer le td de in    (taille max)
mov eax,edi
add eax,100020h
or  eax,4
mov [edi],eax    ;LINK POINTER

mov edx,[ebx+uhci_bulkmem_param_pcs]
mov dword[edi+4],edx ;CONTROL AND STATUS


mov eax,[ebx+uhci_bulkmem_param_tod]
dec eax
shl eax,13
or eax,[ebx+uhci_bulkmem_param_adterm] ;adresse+endpoint
shl eax,8
or eax,esi   ;data toggle 
mov al,069h  ;pid
mov [edi+8],eax  ;TOKEN 

mov [edi+12],ebp ;BUFFER POINTER


add edi,32
xor esi,80000h 
add ebp,[ebx+uhci_bulkmem_param_tod]
sub ecx,[ebx+uhci_bulkmem_param_tod]
cmp ecx,0
je tdoutstatus_sfusb_commande_uhci
jmp bouclein_sfusb_commande_uhci





;********************
;créer le td de in   (taille inferieur a la taille max)
partielin_sfusb_commande_uhci:
mov eax,edi
add eax,100020h
or  eax,4
mov [edi],eax    ;LINK POINTER

mov edx,[ebx+uhci_bulkmem_param_pcs]
mov dword[edi+4],edx ;CONTROL AND STATUS


mov eax,ecx
dec eax
shl eax,13
or eax,[ebx+uhci_bulkmem_param_adterm] ;adresse+endpoint
shl eax,8
or eax,esi   ;data toggle 
mov al,069h  ;pid
mov [edi+8],eax  ;TOKEN 

mov [edi+12],ebp ;BUFFER POINTER

add edi,32


;*****************
;créer le TD de out pour le status
tdoutstatus_sfusb_commande_uhci:
mov dword[edi],1    ;LINK POINTER

mov edx,[ebx+uhci_bulkmem_param_pcs]
mov dword[edi+4],edx  ;CONTROL AND STATUS

xor eax,eax ;taille
dec eax
shl eax,13
or eax,[ebx+uhci_bulkmem_param_adterm] ;adresse+endpoint
shl eax,8
or eax,80000h   ;data toggle a 1
mov al,0E1h  ;pid
mov [edi+8],eax  ;TOKEN 

mov dword[edi+12],0 ;BUFFER POINTER

jmp insert_sfusb_commande_uhci





;*****************
;créer le TD de IN pour le status
tdinstatus_sfusb_commande_uhci:
mov dword[edi],1    ;LINK POINTER

mov edx,[ebx+uhci_bulkmem_param_pcs]
mov dword[edi+4],edx  ;CONTROL AND STATUS

xor eax,eax ;taille
dec eax
shl eax,13
or eax,[ebx+uhci_bulkmem_param_adterm] ;adresse+endpoint
shl eax,8
or eax,80000h   ;data toggle a 1
mov al,069h  ;pid
mov [edi+8],eax  ;TOKEN 

mov dword[edi+12],0 ;BUFFER POINTER




;**************************
;insère le qh dans la file
insert_sfusb_commande_uhci:
cli
mov edi,[ebx+uhci_bulkmem_param_desc_ctrl]
fs
mov esi,[edi+dcu_mem]
sub esi,100000h-1000h ;esi=qh
boucle_rqh_uhci:
test dword[esi],1
jnz trouve_rqh_uhci
mov eax,esi
and eax,0FFFFFFF0h
sub eax,100000h
mov esi,eax
jmp boucle_rqh_uhci

trouve_rqh_uhci:
mov edx,ebx
add edx,100000h+uhci_bulkmem_qh
or edx,2
mov [esi],edx
sti

;attend que les td soit traité
mov esi,ebx
add esi,uhci_bulkmem_td
fs
mov ecx,[cptsf]
add ecx,160         ;attend 200ms max

boucle_att_uhci:
fs
cmp [cptsf],ecx
ja erreur_transfert_uhci
test dword[esi+4],800000h ;test bit 23 du control and status
jnz boucle_att_uhci
test byte[esi],1
jnz fin_att_uhci
add esi,32
jmp boucle_att_uhci

fin_att_uhci:
cli
;supprime le qh de la file
mov edi,[ebx+uhci_bulkmem_param_desc_ctrl]
fs
mov esi,[edi+dcu_mem]
sub esi,100000h-1000h ;esi=qh
boucle_rqh2_uhci:
cmp [esi],edx
je trouve_rqh2_uhci
mov eax,esi
and eax,0FFFFFFF0h
sub eax,100000h
mov esi,eax
jmp boucle_rqh2_uhci

trouve_rqh2_uhci:
mov eax,[ebx+ebx+uhci_bulkmem_qh]
mov [esi],eax



;copie les éventuelles données reçu







;efface la zone réservé
call libmem
sti
pop fs
pop es
pop ds
popad
xor eax,eax
ret










erreur_transfert_uhci:

cli
;supprime le qh de la file
mov edi,[ebx+uhci_bulkmem_param_desc_ctrl]
fs
mov esi,[edi+dcu_mem]
sub esi,100000h-1000h ;esi=qh
boucle_rqh3_uhci:
cmp [esi],edx
je trouve_rqh3_uhci
mov eax,esi
and eax,0FFFFFFF0h
sub eax,100000h
mov esi,eax
jmp boucle_rqh3_uhci

trouve_rqh3_uhci:
mov eax,[ebx+ebx+uhci_bulkmem_qh]
mov [esi],eax


;efface la zone réservé
call libmem
sti
pop fs
pop es
pop ds
popad
mov eax,cer_uhci
ret








pushad ;§§§§§§§§§§§§§§§§§§TRAPPE

mov eax,[ebx+uhci_bulkmem_cmd+0]
call affh2j

mov al,"h"
call affcj

mov eax,[ebx+uhci_bulkmem_cmd+4]
call affh2j

mov al,"h"
call affcj


mov al,13
call affcj
mov al,"T"
call affcj

mov eax,[ebx+uhci_bulkmem_td+4]
call affh2j

mov al,"h"
call affcj

mov eax,[ebx+uhci_bulkmem_td+8]
call affh2j

mov al,"h"
call affcj


mov eax,[ebx+uhci_bulkmem_td+36]
call affh2j

mov al,"h"
call affcj


mov eax,[ebx+uhci_bulkmem_td+40]
call affh2j

mov al,"h"
call affcj


mov eax,[ebx+uhci_bulkmem_td+68]
call affh2j

mov al,"h"
call affcj


mov eax,[ebx+uhci_bulkmem_td+72]
call affh2j

mov al,"h"
call affcj

mov al,13
call affcj
mov al,"R"
call affcj

mov eax,[ebx+uhci_bulkmem_data]
call affh2j

mov al,"h"
call affcj

mov eax,[ebx+uhci_bulkmem_data+4]
call affh2j

mov al,"h"
call affcj


mov eax,[ebx+uhci_bulkmem_data+8]
call affh2j

mov al,"h"
call affcj

mov eax,[ebx+uhci_bulkmem_data+12]
call affh2j

mov al,"h"
call affcj


mov ax,[ebx+uhci_bulkmem_data+16]
call affh1j

mov al,"h"
call affcj

popad   ;§§§§§§§§§§§§§§§§§§













;*****************************************************************************************************************************************
init_ctrl_usb:     ;initialise le controleur usb dont le descripteur est pointé par ds:esi
cmp byte[esi+dcu_type],01
je init_uhci
cmp byte[esi+dcu_type],02
je init_ohci
cmp byte[esi+dcu_type],03
je init_ehci
cmp byte[esi+dcu_type],04
je init_xhci
ret


;************************************************************************
init_uhci:  
pushad
push es
mov ax,selramh
mov es,ax        
mov di,[esi+dcu_es] ;adresse de base du contoleur

;reset le controleur
mov dx,di
mov ax,02h
out dx,ax
boucle_reset_uhci:
in ax,dx
test dx,02h
jnz boucle_reset_uhci

;configure les interruptions
mov dx,di
add dx,ctrl_uhci_usbintr
mov ax,00h   ;aucune interruption activé
out dx,ax

;configure l'adresse de la frame listuhci
mov dx,di
add dx,ctrl_uhci_frbaseadd
mov eax,[esi+dcu_mem] 
out dx,eax

;écrit une entrée de terminaison dans la frame list uhci
mov ebx,[esi+dcu_mem] 
mov ecx,1024
mov edx,1002h  ;position du premier QH + indication que l'on pointe sur un QH (bit1=1)
add edx,ebx    ;edx=pointeur vers le seul qh
sub ebx,100000h

boucle_table_uhci:
es
mov [ebx],edx
add ebx,4
dec ecx
jnz boucle_table_uhci


;créer qh des interruption
mov ebx,[esi+dcu_mem] 
sub ebx,0FF000h   ;-1Mo +4Ko
es
mov dword[ebx],1  ;marqueur d'entrée suivante invalide
es
mov dword[ebx+4],1  ;marqueur d'entrée suivante invalide


;configure le controleur
mov dx,di
mov ax,080h ;accepte les grandes trames
out dx,ax

;démarre le controleur
mov dx,di
mov ax,081h
out dx,ax


pop es
popad
ret

;**********************************
init_ohci:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
ret


;**********************************
init_ehci:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
ret

;**********************************
init_xhci:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
ret




;****************************************************************************************************
irqUSB:              ;irq D
push ax
mov al,20h
out 0A0h,al
mov al,20h
out 20h,al
pop ax
sti
iret


















