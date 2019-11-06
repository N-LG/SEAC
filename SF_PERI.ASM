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
cmp byte[ebx+dcu_type],3
je ehci_test_cnx_usb
;cmp byte[ebx+dcu_type],4
;je xhci_test_cnx_usb
jmp ctrl_suivant_test_cnx_usb

;***************************
uhci_test_cnx_usb:
xor edx,edx
mov dl,[usb_port_test]
shl dx,1
add dx,ctrl_uhci_portsc1
add dx,[ebx+dcu_es]

cmp byte[usb_action],1
je uhci_reset_port
cmp byte[usb_action],2
je uhci_attrib_adresse
cmp byte[usb_action],3
je uhci_set_adresse
cmp byte[usb_action],4
je global_lit_descripteur

in ax,dx
test ax,02h
jz suite_test_cnx_usb
out dx,ax
test ax,1
jz supp_periph_usb
mov ax,06h
out dx,ax 

pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
push eax
mov al,"C"
call affcj
pop eax

mov cx,ax
call affh1j

mov al,"h"
call affcj
popad   ;§§§§§§§§§§§§§§§§§§

mov eax,[cptsf]
add eax,40      ;attent 125ms avant de reseter le port (norme:100ms)
mov [usb_tempo],eax
mov byte[usb_action],1
jmp fin_test_cnx_usb


;*****************
uhci_reset_port:
mov ax,0204h   ;met a 1  reset 
out dx,ax
int 62h
xor eax,eax
out dx,ax
int 62h
mov ax,04h
out dx,ax
int 62h
mov ax,06h
out dx,ax


pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
mov al,"1"
call affcj
popad   ;§§§§§§§§§§§§§§§§§§

mov eax,[cptsf]
add eax,40          ;attent 75ms avant d'arretet le reset(norme 50ms
mov [usb_tempo],eax
mov byte[usb_action],2
jmp fin_test_cnx_usb


;*****************
uhci_attrib_adresse:
;mov ax, 04h       ;et a 1 le bit enable 
;out dx,ax
;int 62h          ;attend au moins 2.5ms
;or ax, 02       ;raz le signalement du changement d'etat
;out dx,ax


pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
mov al,"2"
call affcj
popad   ;§§§§§§§§§§§§§§§§§§





mov eax,[cptsf]
add eax,40           ;attent 50ms avant de chercher a lire le descripteur (le temps que le périphérique prenne bien en compte la nouvelle adresse)
mov [usb_tempo],eax
mov byte[usb_action],3
jmp fin_test_cnx_usb














;***************************
ehci_test_cnx_usb:
xor edx,edx
mov dl,[usb_port_test]
shl dx,2
add dx,ctrl_ehci_portsc
add dx,[ebx+dcu_es]
in eax,dx
test eax,02h
jz suite_test_cnx_usb
out dx,eax
test ax,1
jz supp_periph_usb 

pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
mov al,"E"
call affcj
popad   ;§§§§§§§§§§§§§§§§§§

jmp fin_test_cnx_usb




;****************************************************************
uhci_set_adresse:


;cherche une adresse de périphérique libre
mov ebx,ad_desc_periph_usb+16
boucle_uhci_attrib_adresse:
test byte[ebx],01b
jz trouve_uhci_attrib_adresse
add ebx,16
cmp ebx,ad_desc_periph_usb+800h
jne boucle_uhci_attrib_adresse 

mov byte[usb_action],0
jmp suite_test_cnx_usb   ;on ignore ce nouveau périphérique parce que toutes les adresses sont prises

trouve_uhci_attrib_adresse:
mov ax,[usb_ctrl_test]  ;al=n° de controleur ah=N°de port (usb_ctrl_port)
mov byte[ebx],01b     ;remplit le descripteur du périphérique
mov [ebx+dpu_ctrl],ax
mov byte[ad_desc_periph_usb],01b   ;et aussi le périphérique d'adresse 0 car c'est son adresse pour l'instant
mov [ad_desc_periph_usb+dpu_ctrl],ax
sub ebx,ad_desc_periph_usb   ;sauvegarde l'adresse du périphérique sur lequel on travaille
shr ebx,4
mov [usb_adresse],bl


;prépare la commande
mov byte[usb_commande],10000000b    ;bmRequestType
mov byte[usb_commande+1],6  ;bRequest (ici get descriptor)
mov byte[usb_commande+2],0  ;LSB wValue (index)
mov byte[usb_commande+3],1  ;MSB wValue (type)
mov word[usb_commande+4],0  ;wIndex
mov word[usb_commande+6],18  ;wLength
;envoie la commande
xor eax,eax
mov al,0  ;[usb_adresse]
mov esi,usb_commande
call sfusb_commande


pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
push ecx
push eax
mov al,13
call affcj
mov al,"A"
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


mov eax,[cptsf]
add eax,4           ;attent 50ms avant de chercher a lire le descripteur (le temps que le périphérique prenne bien en compte la nouvelle adresse)
mov [usb_tempo],eax
mov byte[usb_action],4
jmp fin_test_cnx_usb




;***************************************
global_lit_descripteur:

pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
mov al,"3"
call affcj
popad   ;§§§§§§§§§§§§§§§§§§












;prépare la commande
;mov byte[usb_commande],0    ;bmRequestType
;mov byte[usb_commande+1],5  ;bRequest (ici set_adress)
;mov byte[usb_commande+2],al ;LSB wValue
;mov byte[usb_commande+3],0  ;MSB wValue
;mov word[usb_commande+4],0  ;wIndex
;mov word[usb_commande+6],0  ;wLength
;envoie la commande
;mov al,0 ;le périphérique a temporairement l'adresse 0
;mov esi,usb_commande
;call sfusb_commande



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




mov dword[usb_tempo],0
mov byte[usb_action],0
jmp suite_test_cnx_usb





;******************************************
supp_periph_usb:
pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
mov al,"D"
call affcj
popad   ;§§§§§§§§§§§§§§§§§§

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