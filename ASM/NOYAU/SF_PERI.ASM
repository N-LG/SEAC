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



mov byte[ad_chaine_travail],0

mov dl,[ad_chaine_travail+15]   ;index du descripteur
cmp dl,0
je ignore_lecture_nom_usb
push ebx
mov eax,2
mov bl,[usb_adresse] ;adresse
mov bh,0 ;endpoint
mov dh,3   ;type de descripteur (chaine)
mov edi,ad_chaine_travail+256
int 68h
pop ebx
cmp eax,0
jne global_erreur_connexionUSB

mov esi,ad_chaine_travail+256
mov edi,ad_chaine_travail
call conv_chaine_usb

ignore_lecture_nom_usb:



mov cl,100
call affmsgsyst

mov edx,ad_chaine_travail
call affjournal

mov cl,101
call affmsgsyst

xor eax,eax
mov al,[usb_adresse]
call affnje

mov al,13
call affcj



;**********************************
;charge et active le descripteur de configuration 
push ebx
mov eax,3
mov bl,[usb_adresse] ;adresse
mov bh,0 ;endpoint
mov dl,0   ;index du descripteur
mov edi,ad_chaine_travail
int 68h
pop ebx
cmp eax,0
jne global_erreur_connexionUSB



;cherche dans le descripteur de configuration si il y  as une fonction géré par le systeme
mov edi,ad_chaine_travail
xor eax,eax
mov ebp,edi
mov ax,[ad_chaine_travail+2]
add ebp,eax

boucle_active_config_usb:
cmp byte[edi+1],4
jne suite_active_config_usb


cmp byte[edi+5],3
je config_hid_usb
cmp byte[edi+5],8
je config_msd_usb
cmp byte[edi+5],9
je config_hub_usb

suite_active_config_usb:
xor eax,eax
mov al,[edi]
add edi,eax
cmp edi,ebp
jb boucle_active_config_usb

mov dword[usb_tempo],0
mov byte[usb_action],0
jmp suite_test_cnx_usb


config_hid_usb:
cmp byte[edi+7],1
je config_clavier_usb
cmp byte[edi+7],2
je config_souris_usb
jmp suite_active_config_usb


config_msd_usb:
cmp word[edi+6],05006h
je config_bulkonly_usb
jmp suite_active_config_usb


config_hub_usb:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp suite_active_config_usb


config_souris_usb:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp suite_active_config_usb


config_clavier_usb:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp suite_active_config_usb


config_bulkonly_usb:
push edx
push edi
xor edx,edx
mov dl,[edi+2]
;prépare la commande
mov byte[usb_commande],0A1h   ;bmRequestType
mov byte[usb_commande+1],0FEh ;bRequest (ici get max LUN)
mov word[usb_commande+2],0    ;wValue
mov word[usb_commande+4],dx   ;wIndex
mov word[usb_commande+6],1    ;wLength 
;envoie la commande
mov al,[usb_adresse] ;adresse
mov ah,0 ;endpoint
mov edx,usb_commande
mov edi,usb_commande
call sfusb_commande
pop edi
pop edx
cmp eax,0
je maxlun1_config_bulkonly_usb
mov byte[usb_commande],0 
maxlun1_config_bulkonly_usb:
cmp byte[usb_commande],0FFh 
jne maxlun2_config_bulkonly_usb
mov byte[usb_commande],0 
maxlun2_config_bulkonly_usb:

mov esi,edi
xor ecx,ecx
mov cl,[esi]
add esi,ecx
cmp byte[esi+1],5
jne suite_active_config_usb
cmp byte[esi+3],2
jne suite_active_config_usb
mov al,[esi+2]

mov cl,[esi]
add esi,ecx
cmp byte[esi+1],5
jne suite_active_config_usb
cmp byte[esi+3],2
jne suite_active_config_usb
mov ah,[esi+2]

test ah,80h
jz okendp_config_bulkonly_usb
xchg al,ah
okendp_config_bulkonly_usb:
test ah,80h
jnz suite_active_config_usb
and ax,0F0Fh

mov ch,[usb_adresse]
mov cl,[usb_commande] 
mov dl,[edi+2] ;al=endpoint in ah=endpoint out cl=nb max de Lun ch=adresse dl=N° d'interface

mov esi,ad_desc_clef_usb 

boucle_config_bulkonly_usb:
cmp byte[esi+dlu_type],0
je ok_config_bulkonly_usb
add esi,64
cmp esi,ad_desc_clef_usb+nb_desc_clef_usb*64
jne boucle_config_bulkonly_usb
jmp suite_active_config_usb


ok_config_bulkonly_usb:
mov byte[esi+dlu_type],1 ;code clef usb protocole bulk-only et commande scsi
mov [esi+dlu_endpin],al
mov [esi+dlu_endpout],ah
mov [esi+dlu_lun],cl
mov [esi+dlu_adresse],ch
mov [esi+dlu_interface],dl
mov byte[esi+dlu_nboct],9  ;on vas supposer que les périphérique ont des secteur de 512 octet 
mov dword[esi+dlu_msb_ad],0

;met a jour les partition du disque
pushad
mov ecx,esi
shr ecx,6
sub ecx,ad_desc_clef_usb
mov ch,cl
mov eax,12
int 64h
popad

cmp cl,0
je suite_active_config_usb
dec cl
jmp boucle_config_bulkonly_usb








;************************************
global_erreur_connexionUSB:
mov cl,102
call affmsgsyst
mov dword[usb_tempo],0
mov byte[usb_action],0
jmp suite_test_cnx_usb








;****************************************************
;déconnecte le périphérique usb d'adresse cl
deco_usb:
pushad
and ecx,07Fh
push ecx
push ecx
shl ecx,6
add ecx,ad_desc_periph_usb
mov edi,ecx
xor eax,eax
mov ecx,16
cld
rep stosd
pop eax



;libère eventuellement tout les disque qui y était attaché
mov edx,ad_desc_clef_usb
boucle1_deco_usb:
cmp byte[edx+dlu_type],0
je suite1_deco_usb
cmp [edx+dlu_adresse],al
jne suite1_deco_usb

mov dword[edx],0
mov dword[edx+4],0
;§§§§§§§§§§§§§§§§§§§§§§met a jour la table des partitions

suite1_deco_usb:
add edx,64
cmp edx,ad_desc_clef_usb+800h
jne boucle1_deco_usb


;libère eventuellement tout les périphérique qui y était attaché
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§(voir quant on gèrera les hub)



mov cl,103
call affmsgsyst

pop eax
call affnje

mov al,13
call affcj

popad
ret











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
mov ecx,edx
sub ecx,ad_desc_periph_usb
shr ecx,6
call deco_usb 

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













