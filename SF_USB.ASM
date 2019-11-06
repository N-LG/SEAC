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


;bulk in out commande:
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
sfusb_commande:                 ;al=périphérique ds:esi=zt des 8 octet de la commande
push ebx
push edx
push esi
push edi
push fs
push gs

mov bp,bx
mov bx,seldat
mov fs,bx
mov bx,selramh
mov es,bx
xor ebx,ebx
xor edx,edx
mov dl,al
shl edx,dc_desc_periph_usb
add edx,ad_desc_periph_usb ;edx=adresse du descripteur de périphérique
fs
test byte[edx+dpu_att],01b
jz sfusb_commande_cer_parami
fs
mov bl,[edx+dpu_ctrl] 
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
sfusb_commande_cer_parami:
mov eax,cer_parami
xor ecx,ecx
pop gs
pop fs
pop edi
pop esi
pop edx
pop ebx
ret


;**********************************************
sfusb_commande_uhci:
;cherche une qh de libre
fs
mov edi,[ebx+dcu_mem] ;cherche un TD disponible
sub edi,0FF000h
es
cmp dword[edi+4],01
je sfusb_commande_uhci_qhok
int 62h
jmp sfusb_commande_uhci


sfusb_commande_uhci_qhok:    ;reserve le qh
es
mov dword[edi+4],0FFFFFFFFh




;recopie les données de la commande
pushad
mov ecx,8
add edi,uhci_mem_setup_type
cld
rep movsb
popad



;enregistrer param transaction
es
mov [edi+uhci_mem_ad_perif],edx 
es
mov [edi+uhci_mem_ad_ctrl],ebx 
;xor ecx,ecx
;es
;mov [edi+uhci_mem_setup_to],cx
es
mov [edi+uhci_mem_to_data],ecx
es
mov [edi+uhci_mem_to_max],bp 
es
mov [edi+uhci_mem_adresse],al 
es
mov [edi+uhci_mem_endpoint],ah 

;creer param de base
xor ecx,ecx
es
mov cx,[edi+uhci_mem_to_max]  ;ecx=max packet

xor edx,edx
es
mov dl,[edi+uhci_mem_endpoint]
shl edx,15
es
or dh,[edi+uhci_mem_adresse]     
push ecx
shl ecx,20
or edx,ecx    ;edx= td token sans le pid
pop ecx


push ecx
push edx
push esi
mov ecx,018800000h ;bit 23=TD actif et bit 27-28=3 erreur avant arret


;test si périphérique basse vitesse
es
mov edx,[edi+uhci_mem_ad_perif]
es
mov esi,[edi+uhci_mem_ad_ctrl]
xor eax,eax
fs
mov al,[edx+dpu_port]
shl al,1
fs
mov dx,[esi+dcu_es]
add dx,ax
add dx,ctrl_uhci_portsc1
in ax,dx
test ax,0100h 
jz sfusb_commande_uhci_pasbassevitesse 
or ecx,4000000h
sfusb_commande_uhci_pasbassevitesse:

mov eax,ecx          ;eax = td control & status 
pop esi
pop edx
pop ecx


;créer TD pour setup
mov ebx,edi
mov esi,edi
add ebx,uhci_mem_td1
add esi,uhci_mem_setup_type+100000h

es
mov dword[ebx],1         ;aucun TD suivant
es
mov dword[ebx+4],eax     ;td control & status
es
mov dword[ebx+8],edx     ;td token
es
mov byte[ebx+8],02Dh     ;PID setup
es
mov dword[ebx+12],esi


es
test byte[edi+uhci_mem_setup_type],80h
jz sfusb_commande_uhci_td_out
es
cmp dword[edi+uhci_mem_to_data],0
je sfusb_commande_uhci_fin_td

;***************************************
;-----créer TDs IN
mov esi,edi
add esi,uhci_mem_zt

sfusb_commande_uhci_boucle_tdin:
cmp [edi+uhci_mem_to_data],ecx
jb sfusb_commande_uhci_td_in_final 
cmp dword[edi+uhci_mem_to_data],0
je sfusb_commande_uhci_td_out

es
mov dword[ebx],ebx
es
add dword[ebx],100000h
add ebx,32
add esi,ecx
xor edx,80000h ;inverse le data toggle du TD token
es
mov dword[ebx],1         ;aucun TD suivant
es
mov dword[ebx+4],eax     ;td control & status
es
mov dword[ebx+8],edx     ;td token
es
mov byte[ebx+8],069h     ;PID in
es
mov dword[ebx+12],esi
es
sub[edi+uhci_mem_to_data],ecx
jmp sfusb_commande_uhci_boucle_tdin

sfusb_commande_uhci_td_in_final: 
es
mov dword[ebx],ebx
es
add dword[ebx],100000h
add ebx,32
add esi,ecx
xor edx,80000h ;inverse le data toggle du TD token
and edx,8FFFFh ;met a zéro le maximum length
es
mov dword[ebx],1         ;aucun TD suivant
es
mov dword[ebx+4],eax     ;td control & status
es
mov dword[ebx+8],edx     ;td token
es
mov byte[ebx+8],069h     ;PID in
es
mov dword[ebx+12],esi

;------creer TD OUT pour status
es
mov dword[ebx],ebx
es
add dword[ebx],100000h
add ebx,32
add esi,ecx
and edx,7FFFFh ;met a zéro le data toggle et le maximum length
es
mov dword[ebx],1         ;aucun TD suivant
es
mov dword[ebx+4],eax     ;td control & status
es
mov dword[ebx+8],edx     ;td token
es
mov byte[ebx+8],0E1h     ;PID out
es
mov dword[ebx+12],esi
jmp sfusb_commande_uhci_fin_td


;*****************************************
sfusb_commande_uhci_td_out:
es
cmp dword[edi+uhci_mem_to_data],0
je sfusb_commande_uhci_fin_td


;++++++copier data


;++++++créer TDs OUT


;++++++créer TD IN pour status


sfusb_commande_uhci_fin_td:

;active QH
mov eax,edi
add eax,100000h+uhci_mem_td1
es
mov dword[edi+4],eax

;attendre dernier TD inactive
boucle2_reserve_trame_uhci:
es
test dword[ebx+4],0800000h ;bit 23=active
jz ok2_reserve_trame_uhci
int 62h
jmp boucle2_reserve_trame_uhci

ok2_reserve_trame_uhci:

;lire resultat TDs


;------copier data
es
test byte[edi+uhci_mem_setup_type],80h
jnz sfusb_commande_uhci_desac_qh
pushad
push ds
push es
xor ecx,ecx
es
mov cx,[edi+uhci_mem_setup_to]
mov ax,ds
mov es,ax
mov ax,selramh
mov ds,ax
mov ebx,edi
mov edi,esi
mov esi,ebx
add esi,uhci_mem_zt

rep movsb

pop es
pop ds
popad




;libère/désactive QH
sfusb_commande_uhci_desac_qh:
es
mov dword[edi+4],1h


xor eax,eax
xor ecx,ecx

pop gs
pop fs
pop edi
pop esi
pop edx
pop ebx
ret























;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§








;**************************************************************************
reserve_trame_uhci:     ;eax=pid/adresse/endpoint/type  edx=adresse descripteur edi=descripteur controleur es:esi=donnée ecx=qt donnée
fs
mov ebx,[edi+dcu_mem] ;cherche un TD disponible
sub ebx,0FF000h

boucle1_reserve_trame_uhci:
gs
cmp dword[ebx+4],0
je ok1_reserve_trame_uhci
int 62h
jmp boucle1_reserve_trame_uhci

ok1_reserve_trame_uhci:                 ;gs:ebx=TD a employer


;si PID<>IN recopie les données de la source vers la ZT
cmp al,69h
je ignore1_reserve_trame_uhci
pushad
push ds
push es
mov ax,es
mov dx,selramh
mov ds,ax
mov es,dx
gs
mov edi,[ebx+12] ;adresse physique de la ZT de transmission
sub edi,100000h
cld
rep movsb
pop es
pop ds
popad
ignore1_reserve_trame_uhci:


;prépare le TD Token
push eax
push edx
mov edx,eax
and eax,07FFFh
and edx,1F0000h
shr edx,1
or eax,edx
mov edx,ecx
dec edx
and edx,3FFh
shl edx,21
or eax,edx

;écrit le TD token
gs
mov [ebx+8],eax
pop edx
pop eax

;prépare le Dword control&Status
pushad
mov ecx,018800000h ;bit 23=TD actif et bit 27-28=3 erreur avant arret

;test si transfert isocrone
and eax,00600000h
cmp eax,00200000h
jne pasisocrone_reserve_trame_uhci 
or ecx,2000000h
pasisocrone_reserve_trame_uhci:


;test si périphérique basse vitesse
xor eax,eax
fs
mov al,[edx+dpu_port]
shl al,1
fs
mov dx,[edi+dcu_es]
add dx,ax
add dx,ctrl_uhci_portsc1
in ax,dx

pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
push eax
mov al,13
call affcj
mov al,"S"
call affcj
pop eax
call affh1j

mov al,"h"
call affcj
popad   ;§§§§§§§§§§§§§§§§§§

test ax,0100h 
jz pasbassevitesse_reserve_trame_uhci 
or ecx,4000000h
pasbassevitesse_reserve_trame_uhci:


;écrit le Dword control&Status
gs
mov [ebx+4],ecx
popad


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


;attend que le TD soit traité



pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
mov al,13
call affcj
mov al,"R"
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


;vérifie le résultat de la transmission
gs
mov ecx,[ebx+4]
and ecx,07E0000h
shr ecx,17
cmp ecx,0
jne erreur_reserve_trame_uhci


;calcul la quantité de données échangé
gs
mov ecx,[ebx+4]
and ecx,07FFh

;si PID=IN recopie les données de la ZT vers la destination
cmp al,69h
jne ignore2_reserve_trame_uhci
pushad
push ds
push es
mov ax,selramh
mov ds,ax
mov edi,esi
gs
mov esi,[ebx+12] ;adresse physique de la ZT de réception
sub esi,100000h
cld
rep movsb
pop es
pop ds
popad
ignore2_reserve_trame_uhci:

gs
mov dword[ebx+4],0
gs
mov dword[ebx+8],0
xor eax,eax
ret



erreur_reserve_trame_uhci:
gs
mov dword[ebx+4],0
gs
mov dword[ebx+8],0
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
mov edx,1002h
add edx,ebx  ;edx=pointeur vers le seul qh
sub ebx,100000h

boucle_table_uhci:
es
mov [ebx],edx
add ebx,4
dec ecx
jnz boucle_table_uhci


;créer 1 qh inactif
mov ebx,[esi+dcu_mem] 
mov edx,[esi+dcu_mem] 
sub ebx,0FF000h
add edx,1020h

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


















