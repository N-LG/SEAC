SF_USB.ASM:


test bl,80h
jnz erreurparamusb 
cmp bl,0
je erreurparamusb

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

cmp al,0   ;réservation périphérique
je sf_usb_reserve
cmp al,1   ;liberation acces périphérique
je sf_usb_libere

cmp al,2   ;lecture descripteur
je sfusb_lec_desc
cmp al,3   ;selection configuration actuelle
je sfusb_active_config
;cmp al,4   ;lecture configuration actuelle
;cmp al,5   ;envoie commande brute
;cmp al,6   ;envoie donnée bulk
;cmp al,7   ;reception donnée bulk
;cmp al,8   ;ouverture connexion isocrone vers terminaison
;cmp al,9   ;ouverture connexion interruption vers terminaison
;cmp al,10  ;fermeture connexion iso ou int

mov eax,cer_parami
iret





;*******************************************************************
sf_usb_reserve:
push ebx
push ds
mov ax,seldat
mov ds,ax
and ebx,7Fh
shl ebx,dc_desc_periph_usb
add ebx,ad_desc_periph_usb
or byte[ebx+dpu_att],02h
mov ax,[id_tache_exec]
mov [ebx+dpu_idr],ax
pop ds
pop ebx
xor eax,eax
iret


;*******************************************************************
sf_usb_libere:
push ebx
push ds
mov ax,seldat
mov ds,ax
and ebx,7Fh
shl ebx,dc_desc_periph_usb
add ebx,ad_desc_periph_usb
and byte[ebx+dpu_att],0FDh
mov word[ebx+dpu_idr],0
pop ds
pop ebx
xor eax,eax
iret















;bl=adresse
;bh=endpoint






;**********************************************************
sfusb_lec_desc:    ;dl=index du descripteur dh=type de descripteur
push ecx
push edx
mov byte[edi],80h    ;bmRequestType
mov byte[edi+1],6  ;bRequest (ici read descriptor)
mov word[edi+2],dx ;wValue (LSB=index du descripteur MSB=type de descripteur)
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
mov word[edi+2],dx ;wValue (LSB=index du descripteur MSB=type de descripteur)
mov word[edi+4],0  ;wIndex
mov word[edi+6],cx  ;wLength
mov edx,edi
mov eax,ebx
call sfusb_commande

fin_sfusb_lec_desc:
pop edx
pop ecx
iret






;**********************************************************
sfusb_active_config:    ;dl=index du descripteur de config    edi=zt de 512 ou copier le descripteur de configuration
push ecx
push edx

;lit le début du descripteur pour avoir la taille de celuis ci et la valeur de la configuration
mov byte[edi],80h  ;bmRequestType
mov byte[edi+1],6  ;bRequest (ici read descriptor)
mov byte[edi+2],dl ;LSB wValue (index du descripteur)
mov byte[edi+3],2  ;MSB wValue (type de descripteur)
mov word[edi+4],0  ;wIndex
mov word[edi+6],8  ;wLength=8 pour lire les taille réel des data completes
push edx
mov edx,edi
mov eax,ebx
call sfusb_commande
pop edx
cmp eax,0
jne fin_sfusb_active_config


;actrive la configuration
mov cx,[edi+2]
push ecx 
push edx
mov cl,[edi+5]
mov byte[edi],00h  ;bmRequestType
mov byte[edi+1],9  ;bRequest (ici set configuration)
mov byte[edi+2],cl ;LSB wValue (index du descripteur)
mov byte[edi+3],0  ;MSB wValue
mov word[edi+4],0  ;wIndex
mov word[edi+6],0  ;wLength
mov edx,edi
mov eax,ebx
call sfusb_commande
pop edx
pop ecx
cmp eax,0
jne fin_sfusb_active_config

;lit la totalité du descripteur
mov byte[edi],80h  ;bmRequestType
mov byte[edi+1],6  ;bRequest (ici read descriptor)
mov byte[edi+2],dl ;LSB wValue (index du descripteur)
mov byte[edi+3],2  ;MSB wValue (type de descripteur)
mov word[edi+4],0  ;wIndex
mov word[edi+6],cx  ;wLength
mov edx,edi
mov eax,ebx
call sfusb_commande
cmp eax,0
jne fin_sfusb_active_config



;parcours le descripteur et enregistre les infos des terminaisons (endpoint)
push eax
push ebx
push edi
push ebp
push fs
mov ax,seldat
mov fs,ax
and ebx,7Fh
shl ebx,dc_desc_periph_usb
add ebx,ad_desc_periph_usb+dpu_ted
mov ebp,edi
xor eax,eax
mov ax,[edi+2]
add ebp,eax

boucle_sfusb_active_config:
cmp byte[edi+1],5
jne ignore_sfusb_active_config

xor edx,edx
mov dl,[edi+2]
mov ax,[edi+4]
and dl,0Fh
shl edx,1
add edx,ebx
fs
mov [edx],ax

ignore_sfusb_active_config:
xor eax,eax
mov al,[edi]
add edi,eax
cmp edi,ebp
jb boucle_sfusb_active_config


pop fs
pop ebp
pop edi
pop ebx
pop eax


fin_sfusb_active_config:
pop edx
pop ecx
iret











;**************************************************************************************************************************************************************************************************************
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
and edx,078000h
shr edx,14
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
pushad ;§§§§§§§§§§§§§§§§§§TRAPPE


mov al,13
call affcj
mov al,"C"
call affcj

mov eax,[ebx+uhci_bulkmem_param_adterm]
call affh2j


mov al,13
call affcj
mov al," "
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


popad   ;§§§§§§§§§§§§§§§§§§









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








;**************************************************************************************************************************************************************************************************************
;**************************************************************************************************************************************************************************************************************
;crée canal isocrone usb
sfusb_iso:        ;al=périphérique ah=endpoint ??????????????????????????????????????????
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
jz sfusb_iso_err_param

xor ebx,ebx
fs
mov bl,[esi+dpu_ctrl] 
shl ebx,dc_desc_ctrl_usb
add ebx,ad_desc_ctrl_usb   ;ebx=adresse du descripteur de controleur

             
fs
cmp byte[ebx+dcu_type],01
je sfusb_iso_uhci
;fs
;cmp byte[ebx+dcu_type],02
;je sfusb_iso_ohci
;fs
;cmp byte[ebx+dcu_type],03
;je sfusb_iso_ehci
;fs
;cmp byte[ebx+dcu_type],04
;je sfusb_iso_xhci
sfusb_iso_err_param:
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret




;********************************************************
sfusb_iso_uhci:
;???????????????????????????????????????????????????
ret







;**************************************************************************************************************************************************************************************************************
;**************************************************************************************************************************************************************************************************************
;lit/ecrit donnée en mode bulk
sfusb_bulk:        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=quantité de données ds:edi=adresse des données 
pushad
push ds
push es
push fs

cmp ecx,0
je sfusb_bulk_err_param

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
jz sfusb_bulk_err_param

xor ebx,ebx
fs
mov bl,[esi+dpu_ctrl] 
shl ebx,dc_desc_ctrl_usb
add ebx,ad_desc_ctrl_usb   ;ebx=adresse du descripteur de controleur

             
fs
cmp byte[ebx+dcu_type],01
je sfusb_bulk_uhci
;fs
;cmp byte[ebx+dcu_type],02
;je sfusb_bulk_ohci
;fs
;cmp byte[ebx+dcu_type],03
;je sfusb_bulk_ehci
;fs
;cmp byte[ebx+dcu_type],04
;je sfusb_bulk_xhci
sfusb_bulk_err_param:
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret


sfusb_bulk_err_mem:
pop fs
pop es
pop ds
popad
mov eax,cer_pasm
ret


;********************************************************
sfusb_bulk_uhci:

;réserve mémoire
mov ebp,ebx
push eax
push ecx
mov ecx,uhci_bulkmem_td
call resmem
jc sfusb_bulk_err_mem
pop ecx
pop eax
mov dword[ebx+8],czm_bulk_usb      

;verifie les parametres
test ax,07080h
jnz sfusb_bulk_err_param


;enregistre parametre
mov [ebx+uhci_bulkmem_param_tframe],ecx
mov [ebx+uhci_bulkmem_param_datainout],edi
mov [ebx+uhci_bulkmem_param_desc_perif],esi      
mov [ebx+uhci_bulkmem_param_desc_ctrl],ebp


;prépare la base du td token
mov dword[ebx+uhci_bulkmem_param_adterm],069h ;pid in
test eax,8000h
jz sfusb_bulk_pid_uhci
mov dword[ebx+uhci_bulkmem_param_adterm],0E1h ;pid out
sfusb_bulk_pid_uhci:
push eax
and eax,07Fh
shl eax,8
or [ebx+uhci_bulkmem_param_adterm],eax ;adresse
pop eax
and eax,0F00h
shl eax,7
or  [ebx+uhci_bulkmem_param_adterm],eax   ;endpoint
mov ecx,[ebx+uhci_bulkmem_param_adterm]
and ecx,78000h
shr ecx,15
and ecx,0Fh
mov esi,[ebx+uhci_bulkmem_param_desc_perif]
fs
mov eax,[esi+dpu_togl]
shr eax,cl
and eax,1
shl eax,19
or [ebx+uhci_bulkmem_param_adterm],eax ;toggle bit



;definie quantité max transferé par TD pour cet endpoint
xor eax,eax
mov edx,[ebx+uhci_bulkmem_param_adterm]
and edx,078000h
shr edx,14
add edx,dpu_ted
add edx,[ebx+uhci_bulkmem_param_desc_perif]
fs
mov ax,[edx]
cmp eax,0
jne sfusb_bulk_uhci_oktod
mov eax,8
sfusb_bulk_uhci_oktod:
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
jc sfusb_bulk_err_mem  ;??????????????????????????????????????????????????????


;précalcule du dword Controle and status
mov ecx,038800000h ;CONTROL AND STATUS bit 23=TD actif  et bit 27-28=3 erreur avant arret  29=short packet detect
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
jz fin_precalc_bulk_uhci
or ecx,4000000h  ;26=low speed    
fin_precalc_bulk_uhci:
mov [ebx+uhci_bulkmem_param_pcs],ecx


;**********************************
;copie éventuellement les données a envoyer
cmp byte[ebx+uhci_bulkmem_param_adterm],0E1h
jne ignore_env_bulk_uhci
push ds
push es
push ds
push es
mov ecx,[ebx+uhci_bulkmem_param_tframe] 
mov edi,ebx
add edi,[ebx+uhci_bulkmem_param_adata]
mov esi,[ebx+uhci_bulkmem_param_datainout]
pop ds
pop es
cld
rep movsb
pop es
pop ds

pushad  ;§§§§§§§§§§§§§§§
mov ecx,[ebx+uhci_bulkmem_param_tframe]
mov esi,ebx
add esi,[ebx+uhci_bulkmem_param_adata]
mov al,13
call affcj
mov al,13
call affcj
mov al,"O"
call affcj
mov al," "
call affcj
bctrappe:
mov al,[esi]
call affh0j
mov al," "
call affcj
inc esi
dec ecx
jnz bctrappe
popad   ;§§§§§§§§§§§§§§§


ignore_env_bulk_uhci:



;*****************************
;crée la QH
mov dword[ebx+uhci_bulkmem_qh],1    ;LINK POINTER (marque link pointer invalide)
mov eax,ebx
add eax,uhci_bulkmem_td+100000h
mov dword[ebx+uhci_bulkmem_qh+4],eax  ;ELEMENT LINK POINTER (pointeur vers le premier TD)


;***************************
;création des TD
mov edi,uhci_bulkmem_td
add edi,ebx
mov ebp,ebx
add ebp,100000h
add ebp,[ebx+uhci_bulkmem_param_adata]
mov ecx,[ebx+uhci_bulkmem_param_tframe]
boucletd_sfusb_bulk_uhci:
cmp ecx,[ebx+uhci_bulkmem_param_tod]
jb partiel_sfusb_bulk_uhci


;********************
;créer le td     (taille max)
mov eax,edi
add eax,100020h
or  eax,4
mov [edi],eax    ;LINK POINTER

mov edx,[ebx+uhci_bulkmem_param_pcs]
mov dword[edi+4],edx ;CONTROL AND STATUS

mov eax,[ebx+uhci_bulkmem_param_tod]
dec eax
shl eax,21
or eax,[ebx+uhci_bulkmem_param_adterm] ;adresse+endpoint+pid
mov [edi+8],eax  ;TOKEN 

mov [edi+12],ebp ;BUFFER POINTER

sub ecx,[ebx+uhci_bulkmem_param_tod]
jz dernier_td_bulk_uhci
add edi,32
xor dword[ebx+uhci_bulkmem_param_adterm],80000h 
add ebp,[ebx+uhci_bulkmem_param_tod]
jmp boucletd_sfusb_bulk_uhci


;********************
;créer le td   (taille inferieur a la taille max)
partiel_sfusb_bulk_uhci:
mov edx,[ebx+uhci_bulkmem_param_pcs]
mov dword[edi+4],edx ;CONTROL AND STATUS

mov eax,ecx
dec eax
shl eax,21
or eax,[ebx+uhci_bulkmem_param_adterm] ;adresse+endpoint+pid
mov [edi+8],eax  ;TOKEN 

mov [edi+12],ebp ;BUFFER POINTER

xor dword[ebx+uhci_bulkmem_param_adterm],80000h 

dernier_td_bulk_uhci:
mov dword[edi],1    ;LINK POINTER

;**************************
;insère le qh dans la file
cli
mov edi,[ebx+uhci_bulkmem_param_desc_ctrl]
fs
mov esi,[edi+dcu_mem]
sub esi,100000h-1000h ;esi=qh

boucle_rqh_bulk_uhci:
test dword[esi],1
jnz trouve_rqh_bulk_uhci
mov eax,[esi]
and eax,0FFFFFFF0h
sub eax,100000h
mov esi,eax
jmp boucle_rqh_bulk_uhci

trouve_rqh_bulk_uhci:
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
add ecx,2000         ;attend 5s max (certains périphériques sont lent a réveiller)

boucle_att_bulk_uhci:
fs
cmp [cptsf],ecx
ja erreur_transfert_bulk_uhci
test dword[esi+4],800000h ;test bit 23 du control and status (td actif)
jnz boucle_att_bulk_uhci
test dword[esi+4],7F0000h ;test bit 16 a 22 du control and status (erreurs)
jnz erreur_transfert_bulk_uhci
test byte[esi],1
jnz fin_att_bulk_uhci
add esi,32
jmp boucle_att_bulk_uhci


fin_att_bulk_uhci:
;************************************
;met a jour le prochain toggl bit a utiliser dans la mémoire
mov eax,[esi+8] 
shr eax,19
not eax
and eax,1
push eax
mov ecx,[ebx+uhci_bulkmem_param_adterm]
and ecx,78000h
shr ecx,15
and ecx,0Fh
mov eax,1
shl eax,cl
not eax
mov esi,[ebx+uhci_bulkmem_param_desc_perif]
fs
and [esi+dpu_togl],ax
pop eax
shl eax,cl
fs
or [esi+dpu_togl],ax



;*****************************
;supprime le qh de la file
cli
mov edi,[ebx+uhci_bulkmem_param_desc_ctrl]
fs
mov esi,[edi+dcu_mem]
sub esi,100000h-1000h ;esi=qh
boucle_rqh2_bulk_uhci:
cmp [esi],edx
je trouve_rqh2_bulk_uhci
mov eax,[esi]
and eax,0FFFFFFF0h
sub eax,100000h
mov esi,eax
jmp boucle_rqh2_bulk_uhci

trouve_rqh2_bulk_uhci:
mov eax,[ebx+uhci_bulkmem_qh]
mov [esi],eax


;**********************************
;copie éventuellement les données reçu
cmp byte[ebx+uhci_bulkmem_param_adterm],069h
jne ignore_recep_bulk_uhci 
mov ecx,[ebx+uhci_bulkmem_param_tframe]
mov esi,ebx
add esi,[ebx+uhci_bulkmem_param_adata]
mov edi,[ebx+uhci_bulkmem_param_datainout]
cld
rep movsb
ignore_recep_bulk_uhci:




;efface la zone réservé
call libmem
sti
pop fs
pop es
pop ds
popad
xor eax,eax
ret










erreur_transfert_bulk_uhci:



pushad ;§§§§§§§§§§§§§§§§§§TRAPPE


mov al,13
call affcj
mov al,"B"
call affcj

mov eax,[ebx+uhci_bulkmem_param_adterm]
call affh2j


mov al,13
call affcj
mov al," "
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


popad   ;§§§§§§§§§§§§§§§§§§






;************************************
;met a jour le toggl bit dans la mémoire
mov eax,[esi+8] 
and eax,80000h
shr eax,19
push eax
mov ecx,[ebx+uhci_bulkmem_param_adterm]
and ecx,78000f
shr ecx,15
and ecx,0Fh
mov eax,1
shl eax,cl
not eax
mov esi,[ebx+uhci_bulkmem_param_desc_perif]
and [esi+dpu_togl],ax
pop eax
fs
or [esi+dpu_togl],ax


cli
;supprime le qh de la file
mov edi,[ebx+uhci_bulkmem_param_desc_ctrl]
fs
mov esi,[edi+dcu_mem]
sub esi,100000h-1000h ;esi=qh
boucle_rqh3_bulk_uhci:
cmp [esi],edx
je trouve_rqh3_bulk_uhci
mov eax,esi
and eax,0FFFFFFF0h
sub eax,100000h
mov esi,eax
jmp boucle_rqh3_bulk_uhci

trouve_rqh3_bulk_uhci:
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
;************************************************************************************************************************************************

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










;****************************************************
conv_chaine_usb:      ;convertit la chaine usb en ds:esi au format utf8z en ds:edi
pushad
xor ecx,ecx
mov cl,[esi]
cmp ecx,2
jb fin_conv_chaine_usb
sub ecx,2
shr ecx,1
cmp ecx,0
je fin_conv_chaine_usb
add esi,2

boucle_conv_chaine_usb:
mov ax,[esi]
add esi,2

test eax,0FF80h
jz o1_convchaine_usb
test eax,0F800h
jz o2_convchaine_usb

push eax
push eax
and al,3Fh
or al,80h
mov [edi+2],al
pop eax
shr eax,6
and al,3Fh
or al,80h
mov [edi+1],al
pop eax
shr eax,12
and al,0Fh
or al,0E0h
mov [edi],al
add edi,3
jmp suite_conv_chaine_usb

o2_convchaine_usb:
push eax
and al,3Fh
or al,80h
mov [edi+1],al
pop eax
shr eax,6
and al,01Fh
or al,0C0h
mov [edi],al
add edi,2  
jmp suite_conv_chaine_usb

o1_convchaine_usb:
mov [edi],al
inc edi

suite_conv_chaine_usb:
dec ecx
jnz boucle_conv_chaine_usb
fin_conv_chaine_usb:
mov byte[edi],0
popad
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


















