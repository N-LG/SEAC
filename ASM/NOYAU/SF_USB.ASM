﻿SF_USB.ASM:


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




cmp al,10   ;envoie commande brute
je sfusb_commande_ext
cmp al,11   ;echange donnée bulk
je sfusb_bulk_ext
cmp al,12   ;ouverture canal vers terminaison isocrone 
je sfusb_open_iso_ext
cmp al,13   ;ouverture canal vers terminaison interruption
je sfusb_open_int_ext
cmp al,14  ;fermeture canal iso ou int
je sfusb_close_ext
cmp al,15  ;échange donnée canal isocrone ou int
je sfusb_isoint_ext
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







;**********************************************************
sfusb_lec_desc:    ;dl=index du descripteur dh=type de descripteur
push ecx
push edx
push ebp

xor ebp,ebp
cmp dh,3       ; si c'est un string descriptor, on récupère l'ID de la langue
jne @f

mov byte[edi],80h    ;bmRequestType
mov byte[edi+1],6    ;bRequest (ici read descriptor)
mov word[edi+2],300h ;wValue (LSB=index du descripteur MSB=type de descripteur)
mov word[edi+4],0    ;wIndex
mov word[edi+6],4    ;wLength=4 pour lire juste le descripteur de langue
push edx
mov edx,edi
mov eax,ebx
call sfusb_commande
pop edx
cmp eax,0
jne fin_sfusb_lec_desc

mov bp,[edi+2]
@@:



mov byte[edi],80h    ;bmRequestType
mov byte[edi+1],6  ;bRequest (ici read descriptor)
mov word[edi+2],dx ;wValue (LSB=index du descripteur MSB=type de descripteur)
mov word[edi+4],bp  ;wIndex
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
jne @f
mov cx,[edi+2]   ;si le descripteur est un descripteur de configuration, on lit la taille totale
@@:

mov byte[edi],80h    ;bmRequestType
mov byte[edi+1],6  ;bRequest (ici read descriptor)
mov word[edi+2],dx ;wValue (LSB=index du descripteur MSB=type de descripteur)
mov word[edi+4],bp  ;wIndex
mov word[edi+6],cx  ;wLength
mov edx,edi
mov eax,ebx
call sfusb_commande

fin_sfusb_lec_desc:
pop ebp
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


;active la configuration
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




;*****************************************
sfusb_commande_ext:
call sfusb_commande
iret


;*****************************************
sfusb_bulk_ext:
call sfusb_bulk
iret


;*****************************************
sfusb_open_iso_ext:
call sfusb_open_iso
iret


;*****************************************
sfusb_open_int_ext:
call sfusb_open_int
iret


;*****************************************
sfusb_close_ext:
call sfusb_close
iret


;*****************************************
sfusb_isoint_ext:
call sfusb_isoint
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
jne @f
mov eax,8
@@:
mov [ebx+uhci_bulkmem_param_tod],eax


;définis le nombre de TD et l'adresse de base des données
xor edx,edx
mov eax,[ebx+uhci_bulkmem_param_tframe]
mov ecx,[ebx+uhci_bulkmem_param_tod]
div ecx
add eax,4
shl eax,5
add eax,uhci_bulkmem_td
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






;**************************************************************************************************************************************************************************************************************
;**************************************************************************************************************************************************************************************************************
;crée canal isocrone usb
sfusb_open_iso:        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=taille d'une trame
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
mov dl,1        ;dl=periodicité de la trame
sfusb_int_uhci:
mov ebp,ebx     ;bl=adresse bh=endpoint+sens esi=adresse du descripteur de périphérique ebp=adresse du descripteur de controleur

;réserve mémoire
mov ebp,ebx
push eax
push ecx
mov ecx,uhci_isointmem_td
call resmem
jc sfusb_iso_uhci_err_mem2
pop ecx
pop eax
mov dword[ebx+8],czm_iso_usb     





;descripteur de périphérique USB
;dpu_att  equ 0 ;attributs: b0=présent b1=acces réservé
;dpu_ctrl equ 1 ;controleur auquel est raccordé le périphérique
;dpu_port equ 2 ;numéro du port sur lequel est branché le périphérique
;dpu_idr  equ 4 ;id de la tache qui as réservé l'acces au périphérique
;dpu_togl equ 6 ;état du dernier data toggle utilisé lors d'un transfer bulk pour chaque endpoint
;?????
;dpu_ted equ 32 ;taille de transfert max par endpoints 16*2






;enregistre parametre
mov [ebx+uhci_isointmem_param_adterm],eax
mov [ebx+uhci_isointmem_param_tframe],ecx
and edx,0FFh
mov [ebx+uhci_isointmem_param_peri],edx
mov [ebx+uhci_isointmem_param_desc_perif],esi      
mov [ebx+uhci_isointmem_param_desc_ctrl],ebp

;verifie les parametres
test ax,07080h
jnz sfusb_iso_uhci_err_param 

;???????????????????????????????????verifier que donnée transfer inf a donnée terminaison max (est vraiment utile?)




;calcul le nombre de descripteur de transfert (1024/periode)
xor edx,edx
mov eax,1024
mov ecx,[ebx+uhci_isointmem_param_peri]
div ecx
mov [ebx+uhci_isointmem_nbtd],eax


;calcul la taille de la ZT nécessaire
xor edx,edx
mov ecx,[ebx+uhci_isointmem_param_tframe]
add ecx,32
mul ecx

;aggrandit la zone mémoire
add ecx,uhci_isointmem_td
add ecx,15
and ecx,0FFFFFFF0h
call modtm
jc sfusb_iso_uhci_err_mem




;précalcule du dword Controle and status
mov ecx,03A800000h ;CONTROL AND STATUS bit 23=TD actif 25=isocrone et bit 27-28=3 erreur avant arret  29=short packet detect
mov esi,[ebx+uhci_isointmem_param_desc_perif]
mov edi,[ebx+uhci_isointmem_param_desc_ctrl]
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
jz @f
or ecx,4000000h  ;26=low speed    
@@:
mov edx,ecx


;précalcule le td token
mov eax,[ebx+uhci_isointmem_param_tframe]
mov ecx,[ebx+uhci_isointmem_param_adterm]
dec eax
and cx,0F7Fh
shl eax,6
or al,ch
shl eax,7
or al,cl
shl eax,8
mov al,069h ;pid in
test dword[ebx+uhci_isointmem_param_adterm],8000h
jz @f
mov al,0E1h ;pid out
@@:


;créer les TD
mov edi,[ebx+uhci_isointmem_nbtd]
shl edi,5  ;mul per 32
add edi,100000h

mov esi,ebx
add esi,uhci_isointmem_td

mov ecx,[ebx+uhci_isointmem_nbtd]

@@:
mov [esi+4],eax  ;status
mov [esi+8],edx  ;td token
mov [esi+12],edi ;buffer
add esi,32
add edi,[ebx+uhci_bulkmem_param_tframe]
dec ecx
jnz @b



;insère les TD dans la frame liste uhci
mov edx,[ebx+uhci_isointmem_param_peri]
shl edx,2  ;mul par 4 ;edx=saut a effectuer

mov edi,[ebx+uhci_isointmem_param_desc_ctrl]
mov esi,[edi+ctrl_uhci_frbaseadd]  ;esi= adresse de la frame list

mov edi,ebx
add edi,uhci_isointmem_td    ;edi= adresse des TD a inserer

mov ecx,[ebx+uhci_isointmem_nbtd]





cli
@@:
mov eax,[esi] ;lire adresse dans index
mov [edi+4],eax ;copier adresse actuellement dans la table d'index dans adresse de sortie descripteur
mov eax,edi
add eax,1000000h 
mov [esi],eax ;copier adresse descripteur dans index
add esi,edx
add edi,32
dec ecx
jnz @b
sti



pop fs
pop es
pop ds
ss
mov [esp+16],ebx ;préserve ebx
popad
xor eax,eax
ret



sfusb_iso_uhci_err_mem:
call libmem
sfusb_iso_uhci_err_mem2:
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret




sfusb_iso_uhci_err_param:
call libmem 
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret



;**************************************************************************************************************************************************************************************************************
;**************************************************************************************************************************************************************************************************************
;crée canal interruption usb
sfusb_open_int:        ;bl=périphérique bh=endpoint+bit7=sens(0=in 1=out) ecx=taille d'une trame dl=périodicité de la trame
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
je sfusb_int_uhci ;(voir du coté isochrone)
;fs
;cmp byte[ebx+dcu_type],02
;je sfusb_int_ohci
;fs
;cmp byte[ebx+dcu_type],03
;je sfusb_int_ehci
;fs
;cmp byte[ebx+dcu_type],04
;je sfusb_int_xhci
sfusb_int_err_param:
pop fs
pop es
pop ds
popad
mov eax,cer_parami
iret






;**************************************************************************************************************************************************************************************************************
;**************************************************************************************************************************************************************************************************************
;ferme une connexion int ou iso
sfusb_close:
;????????????????????????
ret

;**************************************************************************************************************************************************************************************************************
;**************************************************************************************************************************************************************************************************************
;echange donnée sur canal int ou iso
sfusb_isoint:
;????????????????????????
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

;reset le controleur  ;??????????????? a revoir peut être
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

;reset le frame number
mov dx,di
add dx,ctrl_uhci_frnum
mov ax,00h
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
add edx,ebx    ;edx=pointeur vers le qh toutes periodes
sub ebx,100000h
@@:
es
mov [ebx],edx
add ebx,4
dec ecx
jnz @b


;créer QH vide qu est pointé par chaque entrée de la frame list
mov ebx,[esi+dcu_mem] 
sub ebx,0FF000h   ;-1Mo +4Ko (juste après la frame list)
es
mov dword[ebx],1  ;marqueur d'entrée suivante invalide
es
mov dword[ebx+4],1  ;marqueur d'entrée suivante invalide


;on s'assure que le start of frame est bien reglé
mov dx,di
add dx,ctrl_uhci_sofmod
mov al,040h
out dx,al

;reset le status
mov dx,di
add dx,ctrl_uhci_usbsts
mov ax,0FFFFh
out dx,ax

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
pushad
push es
mov ax,selramh
mov es,ax 


;arrete le controleur
mov ecx,[cptsf]
add ecx,40
mov edx,[esi+dcu_es]
es
mov eax,[edx]
and eax,0FFFFFFFEh
es
mov [edx],eax
@@:
nop
es
test dword[edx],1
jz @f
cmp [cptsf],ecx
jb @b

pop es
popad
ret

@@:  ;reset le controleur
es
mov eax,[edx]
or eax,2
es
mov [edx],eax

@@:
nop
es
test dword[edx],2
jz @f
cmp [cptsf],ecx
jb @b

pop es
popad
ret


@@:


;et rien de plus car le but est pour l'instant de simplement de laisser le champ libre a l'UHCI
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§



pop es
popad
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


















