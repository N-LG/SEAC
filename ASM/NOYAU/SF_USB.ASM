SF_USB.ASM:


test bl,80h
jnz erreurparamusb 

;vérifie que le périphérique n'est pas déja réservé
push eax
push ebx
push ds
mov ax,seldat
mov ds,ax
and ebx,7Fh
shl ebx,dc_desc_periph_usb
add ebx,ad_desc_periph_usb
test byte[ebx+dpu_att],02h
jz ok_sf_usb  
mov ax,[id_tache_exec]
cmp [ebx+dpu_idr],ax
je ok_sf_usb  
pop ds
pop ebx
pop eax
erreurparamusb:
mov eax,cer_parami
iret


ok_sf_usb:
pop ds
pop ebx
pop eax

;cmp al,0   ;réservation périphérique
;cmp al,1   ;liberation acces périphérique
cmp al,2   ;lecture descripteur
je sfusb_lec_desc
;cmp al,4   ;selection configuration actuelle
;cmp al,3   ;lecture configuration actuelle
;cmp al,5   ;lecture descripteur de configuration
;cmp al,6   ;envoie donnée bulk
;cmp al,7   ;reception donnée bulk
;cmp al,8   ;ouverture connexion isocrone vers terminaison
;cmp al,9   ;ouverture connexion interruption vers terminaison
;cmp al,10  ;fermeture connexion iso ou int

mov eax,cer_parami
iret






;bl=adresse
;bh=endpoint






;**********************************************************
sfusb_lec_desc:    ;dl=index du descripteur dh=type de descripteur
push ecx
push edx
mov byte[edi],80h    ;bmRequestType
mov byte[edi+1],6  ;bRequest (ici read descriptor)
mov word[edi+2],dx ;wValue
mov word[edi+4],0  ;wIndex
mov word[edi+6],8  ;wLength=8 pour lire les taille réel des data completes
push edx
mov edx,edi
mov eax,ebx
call sfusb_commande
pop edx
cmp eax,0
jne fin_sfusb_lec_desc

xor ecx,ecx
mov cl,[edi]   ;lit la taille du descripteur
cmp byte[edi+1],2
jne suite_sfusb_lec_desc
mov cx,[edi+2]   ;si le descripteur est un descripteur de configuration, on lit la taille totale

suite_sfusb_lec_desc:
mov byte[edi],80h    ;bmRequestType
mov byte[edi+1],6  ;bRequest (ici read descriptor)
mov byte[edi+2],dl ;LSB wValue (index du descripteur)
mov byte[edi+3],dh  ;MSB wValue (type de descripteur)
mov word[edi+4],0  ;wIndex
mov word[edi+6],cx  ;wLength
mov edx,edi
mov eax,ebx
call sfusb_commande

fin_sfusb_lec_desc:
pop edx
pop ecx
iret


















;**************************************************************************************************************************************************************************************************************
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


sfusb_commande_err_mem:
pop fs
pop es
pop ds
popad
mov eax,cer_pasm
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
uhci_bulkmem_param_adata equ 34h
uhci_bulkmem_qh    equ 40h   ;16 octets
uhci_bulkmem_td    equ 50h   ;3*32 octets




;**********************************************
sfusb_commande_uhci:    ;al=adresse ah=endpoint    edx=adresse de la commande   edi données a echanger

;réserve mémoire
mov ebp,ebx
push eax
push ecx
mov ecx,uhci_bulkmem_td
call resmem
jc sfusb_commande_err_mem
pop ecx
pop eax
mov dword[ebx+8],czm_setup_usb      

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


;definie quantité max transferé par TD pour cet endpoint
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


;définis le nombre de TD et l'adresse de base des données
xor edx,edx
mov eax,[ebx+uhci_bulkmem_param_tframe]
mov ecx,[ebx+uhci_bulkmem_param_tod]
div ecx
add eax,3
shl eax,5
add eax,uhci_bulkmem_td
mov eax,200h
mov [ebx+uhci_bulkmem_param_adata],eax


;aggrandit la zone mémoire
mov ecx,eax
add ecx,[ebx+uhci_bulkmem_param_tframe]
add ecx,15
and ecx,0FFFFFFF0h
call modtm
jc erreur_transfert_uhci  ;??????????????????????????????????????????????????????


;précalcule du dword Controle and status
mov ecx,018800000h ;CONTROL AND STATUS bit 23=TD actif  et bit 27-28=3 erreur avant arret  
mov esi,[ebx+uhci_bulkmem_param_desc_perif]
mov edi,[ebx+uhci_bulkmem_param_desc_ctrl]
xor edx,edx
xor eax,eax
fs
mov dl,[esi+dpu_port]
shl edx,1
add edx,ctrl_uhci_portsc1
fs
mov ax,[edi+dcu_es]
add edx,eax
in ax,dx    ;dx=port
test ax,100h
jz fin_precalc_uhci
or ecx,4000000h  ;26=low speed    
fin_precalc_uhci:
mov [ebx+uhci_bulkmem_param_pcs],ecx



;*****************************
;crée la QH
mov dword[ebx+uhci_bulkmem_qh],1    ;LINK POINTER (marque link pointer invalide)
mov eax,ebx
add eax,uhci_bulkmem_td+100000h
mov dword[ebx+uhci_bulkmem_qh+4],eax  ;ELEMENT LINK POINTER (pointeur vers le premier TD)



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
add ebp,100000h
add ebp,[ebx+uhci_bulkmem_param_adata]
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
mov eax,[esi]
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


;**********************
;attend que les td soit traité
mov esi,ebx
add esi,uhci_bulkmem_td
fs
mov ecx,[cptsf]
add ecx,400         ;attend 500ms max

boucle_att_uhci:
fs
cmp [cptsf],ecx
ja erreur_transfert_uhci
test dword[esi+4],800000h ;test bit 23 du control and status (td actif)
jnz boucle_att_uhci
test dword[esi+4],7F0000h ;test bit 16 a 22 du control and status (erreurs)
jnz erreur_transfert_uhci
test byte[esi],1
jnz fin_att_uhci
add esi,32
jmp boucle_att_uhci

fin_att_uhci:

;*****************************
;supprime le qh de la file
cli
mov edi,[ebx+uhci_bulkmem_param_desc_ctrl]
fs
mov esi,[edi+dcu_mem]
sub esi,100000h-1000h ;esi=qh
boucle_rqh2_uhci:
cmp [esi],edx
je trouve_rqh2_uhci
mov eax,[esi]
and eax,0FFFFFFF0h
sub eax,100000h
mov esi,eax
jmp boucle_rqh2_uhci

trouve_rqh2_uhci:
mov eax,[ebx+uhci_bulkmem_qh]
mov [esi],eax

;**********************************
;copie les éventuelles données reçu
mov ecx,[ebx+uhci_bulkmem_param_tframe]
cmp ecx,0
je finok_uhci

mov esi,ebx
add esi,[ebx+uhci_bulkmem_param_adata]
mov edi,[ebx+uhci_bulkmem_param_datainout]
rep movsb


finok_uhci:

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
mov eax,[ebx+uhci_bulkmem_qh]
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


















