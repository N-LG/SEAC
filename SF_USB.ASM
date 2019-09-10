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





;*****************************************************************************************
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
add eax,100000h
out dx,eax

;écrit une entrée de terminaison dans la frame list uhci
mov ebx,[esi+dcu_mem] 
mov ecx,1024
boucle_table_uhci:
es
mov dword[ebx],1 ;marqueur d'entrée de table invalide
add ebx,4
dec ecx
jnz boucle_table_uhci


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


















