﻿SF_USB.ASM:


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





;*******************************************************************************
uhci_mem_setup_type equ 08h
uhci_mem_setup_to equ 0Eh

uhci_mem_ad_perif equ 10h
uhci_mem_ad_ctrl equ 14h
uhci_mem_to_data equ 18h
uhci_mem_to_max equ 1Ch
uhci_mem_adresse equ 20h
uhci_mem_endpoint equ 21h
uhci_mem_td1 equ 40h
uhci_mem_zt equ 800h


;bulk in/out commande:
;ds:esi= data
;ecx=qt  (in et out uniquement)
;al=device
;ah=endpoint
;bx=maxtrame

;plus tard:

;edx=descripteur périphérique  ;??????????????????
;ebx=descripteur controleur    ;??????????????????
;edi=qh uttilisé par le transfert



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
mov ebp,ebx                ;ebp=adresse du descripteur de périphérique

fs
test byte[ebp+dpu_att],01b
jz sfusb_commande_err_param

xor ebx,ebx
fs
mov bl,[ebp+dpu_ctrl] 
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

uhci_bulkmem_qh    equ 30h   ;16 octets
uhci_bulkmem_td    equ 40h   ;3*32 octets

uhci_bulkmem_data  equ 0A0h   ;taille variable




;**********************************************
sfusb_commande_uhci:    ;al=adresse ah=endpoint    edx=adresse de la commande   edi données a echanger


;réserve mémoire
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
mov cx,[edx+6]
mov [ebx+uhci_bulkmem_param_tframe],ecx
mov [ebx+uhci_bulkmem_param_datainout],edi
mov [ebx+uhci_bulkmem_param_desc_perif],ebp      
mov [ebx+uhci_bulkmem_param_desc_ctrl],ebx



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
mov edx,018800000h ;CONTROL AND STATUS bit 23=TD actif  et bit 27-28=3 erreur avant arret  
;or edx,4000000h  ;26=low speed    ;?????????????????????????????????????????????????????????????????????????
mov [ebx+uhci_bulkmem_param_pcs],edx




;*****************
;crée le td de commande
mov edi,uhci_bulkmem_td
add edi,ebx
xor esi,esi


mov eax,edi
add edi,32
and eax,4
mov [edi],eax    ;LINK POINTER

mov edx,[ebx+uhci_bulkmem_param_pcs]
mov dword[edi+4],edx ;CONTROL AND STATUS

mov eax,8 ;taille
dec eax
shl eax,13
or eax,[ebx+uhci_bulkmem_param_adterm] ;adresse+endpoint
shl eax,8
;or eax,esi   ;data toggle inutile il est a zéros
mov al,02Dh  ;pid
mov [edi+8],eax  ;TOKEN 

mov [edi+12],eax ;BUFFER POINTER

add edi,32
xor esi,80000h 

;********************
;créer le td de in
mov eax,edi
add edi,32
and eax,4
mov [edi],eax    ;LINK POINTER

mov edx,[ebx+uhci_bulkmem_param_pcs]
mov dword[edi+4],edx ;CONTROL AND STATUS

xor eax,eax 
mov ax,[ebx+uhci_bulkmem_cmdto] ;taille
dec eax
shl eax,13
or eax,[ebx+uhci_bulkmem_param_adterm] ;adresse+endpoint
shl eax,8
or eax,esi   ;data toggle 
mov al,069h  ;pid
mov [edi+8],eax  ;TOKEN 

mov eax,ebx
add eax,uhci_bulkmem_data+100000h
mov [edi+12],eax ;BUFFER POINTER

add edi,32
xor esi,80000h 


;*****************
;créer le TD de out pour le status
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

mov edx,[ebx+uhci_bulkmem_param_pcs]
mov dword[edi+4],edx ;CONTROL AND STATUS



;insère le qh dans la file
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





;attend que les td soit traité






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

pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
mov al,13
call affcj
mov al,"K"
call affcj

gs
mov eax,[ebx+4]
call affh2j

mov al,"h"
call affcj

gs
mov eax,[ebx+8]
call affh2j

mov al,"h"
call affcj

popad   ;§§§§§§§§§§§§§§§§§§





;efface la zone réservé
call libmem

ret


















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

















