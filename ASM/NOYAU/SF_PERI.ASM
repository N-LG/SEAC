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
je uhci_lit_descripteur
cmp byte[usb_action],4
je uhci_finreset2_adresse
cmp byte[usb_action],5
je global_set_adresse
cmp byte[usb_action],6
je global_fin_conf_usb

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
add eax,20          ;attent 50ms avant d'arretet le reset
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
add eax,80           ;attent 200ms avant de chercher a lire le descripteur
mov [usb_tempo],eax
mov byte[usb_action],3
jmp fin_test_cnx_usb




;****************************************************************
uhci_lit_descripteur:

;remplit les parametre de base du périphérique 0
mov al,[usb_ctrl_test]
mov ah,[usb_port_test]
mov byte[ad_desc_periph_usb+dpu_att],1
mov [ad_desc_periph_usb+dpu_ctrl],al
mov [ad_desc_periph_usb+dpu_port],ah
mov word[ad_desc_periph_usb+dpu_idr],0
mov word[ad_desc_periph_usb+dpu_togl],0
mov byte[ad_desc_periph_usb+dpu_att],1
mov dword[ad_desc_periph_usb+dpu_ted],0
mov dword[ad_desc_periph_usb+dpu_ted+4],0
mov dword[ad_desc_periph_usb+dpu_ted+8],0
mov dword[ad_desc_periph_usb+dpu_ted+12],0
mov dword[ad_desc_periph_usb+dpu_ted+16],0
mov dword[ad_desc_periph_usb+dpu_ted+20],0
mov dword[ad_desc_periph_usb+dpu_ted+24],0
mov dword[ad_desc_periph_usb+dpu_ted+28],0


;prépare la commande
push edx
mov byte[usb_commande],80h    ;bmRequestType
mov byte[usb_commande+1],6  ;bRequest (ici read descriptor)
mov byte[usb_commande+2],0 ;LSB wValue (index du descripteur)
mov byte[usb_commande+3],1  ;MSB wValue (type de descripteur)
mov word[usb_commande+4],0  ;wIndex
mov word[usb_commande+6],8  ;wLength (normalemnt 18 octet)
;envoie la commande
mov ax,0 ;adresse+endpoint
mov edx,usb_commande
mov edi,usb_commande
call sfusb_commande
pop edx
cmp eax,0
jne global_erreur_connexionUSB


;eregistre la taille de l'enpoint 0
mov al,[usb_commande+7]
mov [ad_desc_periph_usb+dpu_ted],al

mov ax,0204h   ;met a 1  reset 
out dx,ax

mov eax,[cptsf]
add eax,20          ;attent 50ms avant d'arretet le reset
mov [usb_tempo],eax
mov byte[usb_action],4
jmp fin_test_cnx_usb



;*****************
uhci_finreset2_adresse:
xor eax,eax
out dx,ax
int 62h
mov ax,04h
out dx,ax
int 62h
mov ax,06h
out dx,ax

mov eax,[cptsf]
add eax,80           ;attent 200ms avant de chercher a affecter l'adresse
mov [usb_tempo],eax
mov byte[usb_action],5
jmp fin_test_cnx_usb




;***************************************
uhci_supp_periph_usb:
mov ax,0Ah             ;reset les bit de changement d'état et
out dx,ax 
jmp supp_periph_usb









;********************************************************************************************
global_set_adresse:


;cherche une adresse libre

mov edx,ad_desc_periph_usb
boucle_global_set_adresse:
fs
test byte[edx],1
jz trouve_global_set_adresse 
add edx,64
cmp edx,ad_desc_periph_usb+128*64
jne boucle_global_set_adresse
jmp global_erreur_connexionUSB

trouve_global_set_adresse:
sub edx,ad_desc_periph_usb
shr edx,6
mov byte[usb_adresse],dl



;prépare la commande
mov al,[usb_adresse]
mov byte[usb_commande],0h    ;bmRequestType
mov byte[usb_commande+1],5  ;bRequest (ici set adress)
mov [usb_commande+2],al     ;LSB wValue (nouvelle adresse)
mov byte[usb_commande+3],0  ;MSB wValue
mov word[usb_commande+4],0  ;wIndex
mov word[usb_commande+6],0  ;wLength
;envoie la commande
mov ax,0 ;adresse+endpoint
mov edx,usb_commande
mov edi,usb_commande
call sfusb_commande
cmp eax,0
jne global_erreur_connexionUSB

;recopie les données de l'adresse 0 a l'adresse configuré
xor ecx,ecx
mov cl,[usb_adresse]
shl ecx,6
mov esi,ad_desc_periph_usb
mov edi,ecx
add edi,esi
mov ecx,16
cld
rep movsd


mov eax,[cptsf]
add eax,80           ;attent 200ms avant de chercher a affecter l'adresse
mov [usb_tempo],eax
mov byte[usb_action],6
jmp fin_test_cnx_usb










;****************************************************************************************************************
global_fin_conf_usb:

;prépare la commande
mov byte[usb_commande],80h    ;bmRequestType
mov byte[usb_commande+1],6  ;bRequest (ici read descriptor)
mov byte[usb_commande+2],0 ;LSB wValue (index du descripteur)
mov byte[usb_commande+3],1  ;MSB wValue (type de descripteur)
mov word[usb_commande+4],0  ;wIndex
mov word[usb_commande+6],18  ;wLength (normalemnt 18 octet)
;envoie la commande
mov al,[usb_adresse] ;adresse
mov ah,0 ;endpoint
mov edx,usb_commande
mov edi,ad_chaine_travail
call sfusb_commande
cmp eax,0
jne global_erreur_connexionUSB


mov cl,[ad_chaine_travail+15]
cmp cl,0
jne ok_lire_chaine
mov cl,[ad_chaine_travail+16]
cmp cl,0
jne ok_lire_chaine
mov cl,[ad_chaine_travail+14]
cmp cl,0
jne ok_lire_chaine

mov byte[ad_chaine_travail],8     ;cree un nom vide
mov word[ad_chaine_travail+2],"?"
mov word[ad_chaine_travail+4],"?"
mov word[ad_chaine_travail+6],"?"
jmp nom_usb_charg


ok_lire_chaine:

;prépare la commande
mov byte[usb_commande],80h    ;bmRequestType
mov byte[usb_commande+1],6  ;bRequest (ici read descriptor)
mov byte[usb_commande+2],cl ;LSB wValue (index du descripteur)
mov byte[usb_commande+3],3  ;MSB wValue (type de descripteur)
mov word[usb_commande+4],0  ;wIndex
mov word[usb_commande+6],2  ;wLength (on lit les deux premier octet pour determiner la taille)
;envoie la commande
mov al,[usb_adresse] ;adresse
mov ah,0 ;endpoint
mov edx,usb_commande
mov edi,ad_chaine_travail
call sfusb_commande
cmp eax,0
jne global_erreur_connexionUSB

xor edx,edx
mov dl,[ad_chaine_travail]

;prépare la commande
mov byte[usb_commande],80h    ;bmRequestType
mov byte[usb_commande+1],6  ;bRequest (ici read descriptor)
mov byte[usb_commande+2],cl ;LSB wValue (index du descripteur)
mov byte[usb_commande+3],3  ;MSB wValue (type de descripteur)
mov word[usb_commande+4],0  ;wIndex
mov word[usb_commande+6],dx  ;wLength
;envoie la commande
mov al,[usb_adresse] ;adresse
mov ah,0 ;endpoint
mov edx,usb_commande
mov edi,ad_chaine_travail
call sfusb_commande
cmp eax,0
jne global_erreur_connexionUSB



nom_usb_charg:

mov cl,100
call affmsgsyst

mov cl,[ad_chaine_travail]
sub cl,2
shr cl,1
mov esi,ad_chaine_travail+2

boucle_affichage_nom_usb:
mov ax,[esi]
cmp ax,7Fh
ja ignore_affichage_nom_usb
call affcj
ignore_affichage_nom_usb:
add esi,2
dec cl
jnz boucle_affichage_nom_usb


mov cl,101
call affmsgsyst

xor eax,eax
mov al,[usb_adresse]
call affnje

mov al,13
call affcj

mov dword[usb_tempo],0
mov byte[usb_action],0
jmp suite_test_cnx_usb







;************************************
global_erreur_connexionUSB:
mov cl,102
call affmsgsyst
mov dword[usb_tempo],0
mov byte[usb_action],0
jmp suite_test_cnx_usb



;******************************************
supp_periph_usb:
mov edx,ad_desc_periph_usb+64
mov ax,[usb_ctrl_test]  ;al=n° de controleur ah=N°de port (usb_ctrl_port)
boucle_supp_periph_usb:
test byte[edx],01b
jz ignore_supp_periph_usb
cmp [edx+dpu_ctrl],ax
jne ignore_supp_periph_usb

;libère le descriptif de périphérique
xor eax,eax
mov edi,edx
mov ecx,16
cld
rep stosd

mov cl,103
call affmsgsyst

mov eax,edx
sub eax,ad_desc_periph_usb
shr eax,6
call affnje

mov al,13
call affcj



;libère eventuellement tout les périphérique qui y était attaché
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§(voir quant on gèrera les hub)

ignore_supp_periph_usb:
add edx,64
cmp edx,ad_desc_periph_usb+128*64
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













