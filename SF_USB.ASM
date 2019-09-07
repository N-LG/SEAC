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






init_ctrl_usb:     ;initialise le controleur usb dont le descripteur est pointé par ds:esi descripteur dont
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
mov di,[esi+dcu_es] ;adresse de base du contoleur




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


















