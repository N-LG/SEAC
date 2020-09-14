SF_PERI.ASM:         ;fonction effectué périodiquement par la tache principale

;********************************
mov ax,seldat    ;gestion du moteur de la disquette
mov ds,ax
mov es,ax
test byte[at_fc_fichier],04h   ;on test si le moteur disquette est allumé
jz pasarretmoteurdisquette 
mov eax,[temp_moteur_disq]
cmp [cptsf],eax
jna pasarretmoteurdisquette
mov dx,3F2h   ;délais dépassé, on eteint le moteur
mov al,04h
out dx,al
and byte[at_fc_fichier],0FBh   ;on signal que le moteur de la disquette est éteint
pasarretmoteurdisquette:





;*********************************************************
;gestion de la detection de nouvelles connexion/déconnexion a un port de controleur USB
cmp byte[usb_action],0
je pastempousb
mov eax,[usb_tempo]
cmp eax,0
je pastempousb
cmp [cptsf],eax
jb fin_test_cnx_usb
pastempousb:

xor ebx,ebx
mov bl,[usb_ctrl_test]
shl ebx,dc_desc_ctrl_usb   
add ebx,ad_desc_ctrl_usb
cmp byte[ebx+dcu_type],1
je uhci_test_cnx_usb
;cmp byte[ebx+dcu_type],2
;je ohci_test_cnx_usb
;cmp byte[ebx+dcu_type],3
;je ehci_test_cnx_usb
;cmp byte[ebx+dcu_type],4
;je xhci_test_cnx_usb
jmp ctrl_suivant_test_cnx_usb

;*************************************************************************************
uhci_test_cnx_usb:
xor edx,edx
mov dl,[usb_port_test]
shl dx,1
add dx,ctrl_uhci_portsc1
add dx,[ebx+dcu_es]

cmp byte[usb_action],1
je uhci_reset1_port
cmp byte[usb_action],2
je uhci_finreset1_adresse
cmp byte[usb_action],3
je uhci_set_adresse
cmp byte[usb_action],4
je global_lit_descripteur

in ax,dx
test ax,02h
jz suite_test_cnx_usb
out dx,ax
test ax,1
jz uhci_supp_periph_usb
mov ax,06h
out dx,ax 

mov eax,[cptsf]
add eax,80      ;attent 200ms avant de reseter le port (norme:100ms)
mov [usb_tempo],eax
mov byte[usb_action],1
jmp fin_test_cnx_usb


;*****************
uhci_reset1_port:
mov ax,0204h   ;met a 1  reset 
out dx,ax

mov eax,[cptsf]
add eax,20          ;attent 100ms avant d'arretet le reset(norme 50ms)
mov [usb_tempo],eax
mov byte[usb_action],2
jmp fin_test_cnx_usb


;*****************
uhci_finreset1_adresse:
xor eax,eax
out dx,ax
int 62h
mov ax,04h
out dx,ax
int 62h
mov ax,06h
out dx,ax

mov eax,[cptsf]
add eax,20           ;attent 50ms avant de chercher a lire le descripteur
mov [usb_tempo],eax
mov byte[usb_action],3
jmp fin_test_cnx_usb

















;****************************************************************
uhci_set_adresse:

pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
mov al,"3"
call affcj
popad   ;§§§§§§§§§§§§§§§§§§



;enregistre la position du périphérique 0
mov al,[usb_ctrl_test]
mov ah,[usb_port_test]
mov byte[ad_desc_periph_usb+dpu_att],1
mov [ad_desc_periph_usb+dpu_ctrl],al
mov [ad_desc_periph_usb+dpu_port],ah


;prépare la commande
mov byte[usb_commande],80h    ;bmRequestType
mov byte[usb_commande+1],6  ;bRequest (ici read descriptor)
mov byte[usb_commande+2],0 ;LSB wValue (index du descripteur
mov byte[usb_commande+3],1  ;MSB wValue (type de descripteur)
mov word[usb_commande+4],0  ;wIndex
mov word[usb_commande+6],8  ;wLength
;envoie la commande
mov ax,0 ;adresse+endpoint
mov edx,usb_commande
mov edi,usb_commande
call sfusb_commande


;pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
;call affh2j
;mov al,"h"
;call affcj
;popad   ;§§§§§§§§§§§§§§§§§§





;?????????????????????????????????????????????????????????????????

mov eax,[cptsf]
add eax,4           ;attent 50ms avant de chercher a lire le descripteur (le temps que le périphérique prenne bien en compte la nouvelle adresse)
mov [usb_tempo],eax
mov byte[usb_action],4
jmp fin_test_cnx_usb






uhci_supp_periph_usb:
mov ax,0Ah             ;reset les bit de changement d'état et
out dx,ax 
jmp supp_periph_usb


;***************************************
global_lit_descripteur:

;?????????????????????????????????????????????????????????????????

mov dword[usb_tempo],0
mov byte[usb_action],0
jmp suite_test_cnx_usb











pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
push ecx
push eax
mov al,13
call affcj
mov al,"F"
call affcj
pop eax
call affh1j

mov al,"h"
call affcj

pop eax
call affh2j

mov al,"h"
call affcj

popad   ;§§§§§§§§§§§§§§§§§§










;******************************************
supp_periph_usb:
pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
mov al,"D"
call affcj
popad   ;§§§§§§§§§§§§§§§§§§

jmp suite_test_cnx_usb ;????????????????????????????????????????????????????????????????ignore l'étape suivante


mov ebx,ad_desc_periph_usb+16
mov ax,[usb_ctrl_test]  ;al=n° de controleur ah=N°de port (usb_ctrl_port)
boucle_supp_periph_usb:
test byte[ebx],01b
jz ignore_supp_periph_usb
cmp [ebx+dpu_ctrl],ax
jne ignore_supp_periph_usb

;libère le descriptif de périphérique
mov dword[ebx],0
mov dword[ebx+4],0
mov dword[ebx+8],0
mov dword[ebx+12],0

;libère eventuellement tout les périphérique qui y était attaché
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§(voir quant on gèrera les hub)

ignore_supp_periph_usb:
add ebx,16
cmp ebx,ad_desc_periph_usb+800h
jne boucle_supp_periph_usb 












;***************************
suite_test_cnx_usb:
mov al,[ebx+dcu_nb_port] 
inc byte[usb_port_test]     ;passe au port suivant pour le prochain test
cmp al,[usb_port_test]    
jne fin_test_cnx_usb       
ctrl_suivant_test_cnx_usb:
mov byte[usb_port_test],0   ;si on est arrivé au nombre max de port pour ce controleur, on passe au suivant
inc byte[usb_ctrl_test]
cmp byte[usb_ctrl_test],nb_desc_ctrl_usb
jne fin_test_cnx_usb
mov byte[usb_ctrl_test],0   ;si on est au ctrl max on revient au premier
fin_test_cnx_usb: