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
add eax,180      ;attent 200ms avant de reseter le port (norme:100ms)
mov [usb_tempo],eax
mov byte[usb_action],1
jmp fin_test_cnx_usb


;*****************
uhci_reset1_port:
mov ax,0204h   ;met a 1  reset 
out dx,ax

mov eax,[cptsf]
add eax,22          ;attent 50ms avant d'arretet le reset
mov [usb_tempo],eax
mov byte[usb_action],2
jmp fin_test_cnx_usb


;*****************
uhci_finreset1_adresse:
mov ecx,[cptsf]
add ecx,1200 ;3 secondes
xor eax,eax
out dx,ax
bc1_uhci_finreset1_adresse:
cmp [cptsf],ecx
ja global_erreur_connexionUSB
in ax,dx
test ax,02h
jz bc1_uhci_finreset1_adresse 
mov ax,06h
out dx,ax
bc2_uhci_finreset1_adresse:
cmp [cptsf],ecx
ja global_erreur_connexionUSB
in ax,dx
test ax,04h
jz bc2_uhci_finreset1_adresse 

mov eax,[cptsf]
add eax,40           ;attend 100ms avant de chercher a lire le descripteur
mov [usb_tempo],eax
mov byte[usb_action],3
jmp fin_test_cnx_usb


;????????????????????????????????????????????????????????????
mov ecx,[cptsf]
add ecx,1200 ;3 secondes
xor eax,eax
out dx,ax

@@:
cmp [cptsf],ecx
ja global_erreur_connexionUSB
in ax,dx
test ax,02h ;csc (connect status change)
jz @b 
mov ax,06h ;enable + clear csc
out dx,ax
@@:
cmp [cptsf],ecx
ja global_erreur_connexionUSB
in ax,dx
test ax,04h;attend enable change
jz @b 

;mov ax,0 
;out dx,ax
;mov ecx,[cptsf]
;inc ecx
;@@:
;nop
;cmp [cptsf],ecx
;jbe @b
;mov ax,06h ;enable+csc
;out dx,ax
;mov ecx,[cptsf]
;inc ecx
;@@:
;nop
;cmp [cptsf],ecx
;jbe @b
;mov ax,0Ch ;enable+EC
;out dx,ax



;????????????????????????????????????????????????????????????


;****************************************************************
uhci_lit_descripteur:
;pushad
;in ax,dx
;call affh1j
;mov al,13
;call affcj
;popad


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
mov word[usb_commande+6],8  ;wLength (normalemnt 18 octet mais on en lit que 8 car on ne connait pas encore la taille max de l'endpoint)
;envoie la commande
mov ax,0 ;adresse+endpoint
mov edx,usb_commande
mov edi,usb_commande
call sfusb_commande
pop edx
cmp eax,0
jne global_erreur_connexionUSB

;enregistre la taille de l'enpoint 0
mov al,[usb_commande+7]
mov [ad_desc_periph_usb+dpu_ted],al

mov ax,0204h   ;met a 1  reset 
out dx,ax

mov eax,[cptsf]
add eax,22          ;attent 55ms avant d'arretet le reset
mov [usb_tempo],eax
mov byte[usb_action],4
jmp fin_test_cnx_usb



;*****************
uhci_finreset2_adresse:
mov ecx,[cptsf]
add ecx,1200 ;3 secondes
xor eax,eax
out dx,ax
bc1_uhci_finreset2_adresse:
cmp [cptsf],ecx
ja global_erreur_connexionUSB
in ax,dx
test ax,02h
jz bc1_uhci_finreset2_adresse 
mov ax,06h
out dx,ax
bc2_uhci_finreset2_adresse:
cmp [cptsf],ecx
ja global_erreur_connexionUSB
in ax,dx
test ax,04h
jz bc2_uhci_finreset2_adresse 

mov eax,[cptsf]
add eax,40           ;attent 100ms avant de chercher a affecter l'adresse
mov [usb_tempo],eax
mov byte[usb_action],5
jmp fin_test_cnx_usb






;????????????????????????????????????????????????????????????

mov ecx,[cptsf]
add ecx,1200 ;3 secondes
xor eax,eax
out dx,ax

@@:
cmp [cptsf],ecx
ja global_erreur_connexionUSB
in ax,dx
test ax,02h
jz @b 
mov ax,06h
out dx,ax
@@:
cmp [cptsf],ecx
ja global_erreur_connexionUSB
in ax,dx
test ax,04h
jz @b 


;mov ecx,[cptsf]
;inc ecx
;@@:
;nop
;cmp [cptsf],ecx
;jbe @b
;mov ax,06h ;enable+csc
;out dx,ax
;mov ecx,[cptsf]
;inc ecx
;@@:
;nop
;cmp [cptsf],ecx
;jbe @b
;mov ax,0Ch ;enable+EC
;out dx,ax


mov eax,[cptsf]
add eax,40           ;attent 100ms avant de chercher a affecter l'adresse
mov [usb_tempo],eax
mov byte[usb_action],5
jmp fin_test_cnx_usb




;***************************************
uhci_supp_periph_usb:
mov ax,0Ah             ;reset les bit de changement d'état
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
add eax,400           ;attent 1s avant de poursuivre
mov [usb_tempo],eax
mov byte[usb_action],6
jmp fin_test_cnx_usb










;****************************************************************************************************************
global_fin_conf_usb:
push ebx
mov eax,2
mov bl,[usb_adresse] ;adresse
mov bh,0 ;endpoint
mov dl,0   ;numéros de descripteur
mov dh,1   ;type de descripteur (global)
mov edi,ad_chaine_travail
int 68h
pop ebx
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
jne ignore_lecture_nom_usb


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
xor edx,edx

boucle_active_config_usb:
cmp byte[edi+1],4   ;si ça n'est pas une interface on ignore
jne ignore_active_config_usb


cmp byte[edi+5],3
je config_hid_usb
cmp byte[edi+5],8
je config_msd_usb
cmp byte[edi+5],9
je config_hub_usb

suite_active_config_usb:
inc edx
ignore_active_config_usb:
xor eax,eax
mov al,[edi]
add edi,eax
cmp edi,ebp
jb boucle_active_config_usb

mov dword[usb_tempo],0
mov byte[usb_action],0
jmp suite_test_cnx_usb

;********************************************************************************
config_hid_usb:
pushad
mov ebx,edx
;créer une entré dans la table des périphérique hid
mov esi,ad_hid
@@:
cmp byte[esi+dhu_adresse],0
je @f
add esi,64
cmp esi,ad_hid+512
jne @b
jmp suite_active_config_usb  ;si plus de place, on abandonne

@@:
mov al,[usb_adresse]  ;adresse
mov [esi+dhu_adresse],al
mov [esi+dhu_interface],bl    ;n°interface


@@:
xor eax,eax
mov al,[edi]
add edi,eax
cmp byte[edi+1],21h
je @b                    ;si c'est le descripteur hid on l'ignore
cmp byte[edi+1],22h
je @b                    ;si c'est le descripteur de rapport on l'ignore
cmp byte[edi+1],05
jne erreur_activation_hid ;si apres le descripteur d'interface ce n'est pas non plus un descripteur de terminaison c'est qu'il y as une erreur
test byte[edi+2],80h
jz @b

mov al,[edi+2]
and al,0Fh
mov [esi+dhu_terminaisonIn],al;terminaison in
mov ax,[edi+4]
mov [esi+dhu_tailleIn],ax     ;taille de la terminaison
mov al,[edi+6]
mov [esi+dhu_frequenceIn],al  ;fréquence de la terminaison


mov edi,ad_chaine_travail+256

;lit le descripteur hid
mov al,[usb_adresse] ;adresse
xor ah,ah
mov byte[edi],81h    ;bmRequestType
mov byte[edi+1],6  ;bRequest (ici read descriptor)
mov word[edi+2],2100h ;wValue (LSB=index du descripteur MSB=type de descripteur)
mov word[edi+4],bx  ;wIndex
mov word[edi+6],9  ;wLength
mov edx,edi
call sfusb_commande
cmp eax,0
jne erreur_activation_hid 

xor ecx,ecx
mov cx,[edi+7] ;lit la taille du descripteur de rapport

;lit le descripteur de rapport
mov al,[usb_adresse] ;adresse
xor ah,ah
mov byte[edi],81h    ;bmRequestType
mov byte[edi+1],6  ;bRequest (ici read descriptor)
mov word[edi+2],2200h ;wValue (LSB=index du descripteur MSB=type de descripteur)
mov word[edi+4],bx  ;wIndex
mov word[edi+6],cx  ;wLength
mov edx,edi
call sfusb_commande
cmp eax,0
jne erreur_activation_hid 


;interprete le descripteur de rapport et complete la table des descripteur hid
pushad
mov ebp,edi
add ebp,ecx

;raz  tout au démarrage
mov dword[decod_hid_offset_in],0
mov dword[decod_hid_offset_out],0
mov dword[decod_hid_report_size],0
mov dword[decod_hid_report_count],0
mov dword[decod_hid_nb_usage],0
mov dword[decod_hid_ad_usage],0
mov dword[decod_hid_page_usage],0
mov dword[decod_hid_id],0
mov dword[decod_hid_usage_minimum],0
mov dword[decod_hid_type],0




boucle_parseHIDusb:
call extrait_item_hidreport
cmp al,004h
je hid04
cmp al,008h
je hid08
cmp al,018h
je hid18
cmp al,074h
je hid74
cmp al,080h
je hid80
cmp al,084h
je hid84
cmp al,090h
je hid90
cmp al,094h
je hid94
jmp suite_parseHIDusb



;************************
hid04:   ;usage page
mov [decod_hid_page_usage],edx
mov dword[decod_hid_nb_usage],0
jmp suite_parseHIDusb


;************************
hid08:    ;usage  voir 6.2.2.7 et HUT
cmp dword[decod_hid_nb_usage],0
jne @f
mov [decod_hid_ad_usage],edi
@@:
inc dword[decod_hid_nb_usage]
jmp suite_parseHIDusb


;************************
hid18:   ;usage minimum
mov [decod_hid_usage_minimum],edx
jmp suite_parseHIDusb


;************************
hid74:   ;report size
mov [decod_hid_report_size],edx
jmp suite_parseHIDusb


;************************
hid80:    ;input  voir 6.2.2.5
;si c'est une constante on ignore
test edx,1
jnz fin_parseHIDusb_input
mov [decod_hid_type],edx
;si il n'y as pas d'usage on test l'usage page
cmp dword[decod_hid_nb_usage],0
jne @f
;ici on test les usages pages
cmp dword[decod_hid_page_usage],7             ;keycode
je parseHIDusb_input_clav
cmp dword[decod_hid_page_usage],9             ;button
je parseHIDusb_input_bouton
jmp fin_parseHIDusb_input
@@:


;parcours les usage et enregistre ceux reconnue
pushad
mov edi,[decod_hid_ad_usage]
mov ebp,[decod_hid_offset_in]


boucle_parseHIDusb_input:
call extrait_item_hidreport
cmp eax,080h
je fin_parseHIDusb_input2 
cmp eax,0C0h
je fin_parseHIDusb_input2 
cmp eax,8
jne suite_parseHIDusb_input
mov eax,[decod_hid_page_usage]
shl eax,16
mov ax,dx  ;eax=usage page+usage

;compare si c'est un usage connu
cmp eax,10030h             ;generic desktop:X
je parseHIDusb_input_xs
cmp eax,10031h             ;generic desktop:y souris
je parseHIDusb_input_ys
cmp eax,10038h             ;generic desktop:molette
je parseHIDusb_input_molette

;si c'est un usage inconnu on incrémente simplement l'adresse
add ebp,[decod_hid_report_size]

suite_parseHIDusb_input:
add edi,ecx
jmp boucle_parseHIDusb_input 

fin_parseHIDusb_input2:
popad

fin_parseHIDusb_input:
push ecx
mov dword[decod_hid_nb_usage],0
xor edx,edx
mov eax,[decod_hid_report_size]
mov ecx,[decod_hid_report_count]
mul ecx
pop ecx
add [decod_hid_offset_in],eax
jmp suite_parseHIDusb

;DEBUT de la partie a modifier pour enregistrer la structure des rapport HID!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

;*********
parseHIDusb_input_clav:  ;touche
pushad
mov al,"T"
call affcj
mov al," "
call affcj
mov eax,[decod_hid_offset_in]
call affh2j
mov al,13
call affcj
popad
jmp fin_parseHIDusb_input


;*********
parseHIDusb_input_bouton:  ;bouton
pushad
mov al,"B"
call affcj
mov al," "
call affcj
mov eax,[decod_hid_offset_in]
call affh2j
mov al,13
call affcj
popad
jmp fin_parseHIDusb_input

;*********
parseHIDusb_input_xs:  ;x souris
pushad
mov al,"X"
call affcj
mov al," "
call affcj
mov eax,ebp
call affh2j
mov al,13
call affcj
popad
add ebp,[decod_hid_report_size]
jmp suite_parseHIDusb_input



;*********
parseHIDusb_input_ys:  ;y souris
pushad
mov al,"Y"
call affcj
mov al," "
call affcj
mov eax,ebp
call affh2j
mov al,13
call affcj
popad
add ebp,[decod_hid_report_size]
jmp suite_parseHIDusb_input



;*********
parseHIDusb_input_molette:  ;molette
pushad
mov al,"M"
call affcj
mov al," "
call affcj
mov eax,ebp
call affh2j
mov al,13
call affcj
popad
add ebp,[decod_hid_report_size]
jmp suite_parseHIDusb_input


;*********
parseHIDusb_output_led:  ;type sortie led
pushad
mov al,"L"
call affcj
mov al,""
call affcj
mov eax,[decod_hid_offset_out]
call affh2j
mov al,13
call affcj
popad
jmp fin_parseHIDusb_output



;FIN de la partie a modifier pour enregistrer la structure des rapport HID!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


;************************
hid84:   ;ID
mov [decod_hid_id],edx
mov dword[decod_hid_nb_usage],0
mov dword[decod_hid_offset_in],8
mov dword[decod_hid_offset_out],8
jmp suite_parseHIDusb


;************************
hid90:    ;output
;si c'est une constante on ignore
test edx,1
jnz fin_parseHIDusb_output
mov [decod_hid_type],edx
;si il n'y as pas d'usage on test l'usage page
cmp dword[decod_hid_nb_usage],0
jne @f
;ici on test les usages pages
cmp dword[decod_hid_page_usage],8             ;usage page:LED
je parseHIDusb_output_led  ;voir plus haut
jmp fin_parseHIDusb_output
@@:


;parcours les usage et enregistre ceux reconnue
;pushad
;mov edi,[decod_hid_ad_usage]
;mov ebp,[decod_hid_offset_out]

;boucle_parseHIDusb_output:
;call extrait_item_hidreport
;cmp eax,090h
;je fin_parseHIDusb_output2 
;cmp eax,0C0h
;je fin_parseHIDusb_output2 
;cmp eax,8
;jne suite_parseHIDusb_output
;mov eax,[decod_hid_page_usage]
;shl eax,16
;mov ax,dx  ;eax=usage page+usage




;compare si c'est un usage connu
;(aucuns pour le moment)

;si c'est un usage inconnu on incrémente simplement l'adresse
;add ebp,[decod_hid_report_size]

;suite_parseHIDusb_output:
;add edi,ecx
;jmp boucle_parseHIDusb_output 

;fin_parseHIDusb_output2:
;popad

fin_parseHIDusb_output:
push ecx
xor edx,edx
mov eax,[decod_hid_report_size]
mov ecx,[decod_hid_report_count]
mul ecx
pop ecx
add [decod_hid_offset_out],eax

mov dword[decod_hid_nb_usage],0
jmp suite_parseHIDusb





;************************
hid94:   ;report count
mov [decod_hid_report_count],edx
jmp suite_parseHIDusb


;**************************
extrait_item_hidreport:
mov al,[edi]
cmp al,0FEh
je extrait_item_hidreport_long
mov cl,[edi]
mov edx,[edi+1]
and eax,0FCh
and ecx,3h

cmp cl,3
jne @f
inc cl
@@:

cmp cl,0
jne @f
xor edx,edx
@@:
cmp cl,1
jne @f
and edx,0FFh
test edx,80h
jz @f
or edx,0FFFFFF00h
@@:
cmp cl,2
jne @f
and edx,0FFFFh
test edx,8000h
jz @f
or edx,0FFFF0000h
@@:
inc ecx
ret

extrait_item_hidreport_long:
xor eax,eax
xor ecx,ecx
mov edx,[edi+3] ;bof parce qu'il peut théoriquement avoir plus
mov al,[edi+2]
mov cl,[edi+1]
add ecx,3
ret



suite_parseHIDusb:
add edi,ecx
cmp edi,ebp
jb boucle_parseHIDusb

fin_parseHIDusb:
popad



;active idle



mov al,[usb_adresse] ;adresse



xor ah,ah



mov byte[edi],21h    ;bmRequestType



mov byte[edi+1],0Ah  ;bRequest (set idle)



mov word[edi+2],0000h ;wValue (LSB=tout report MSB=indefiniment)
mov word[edi+4],bx  ;wIndex
mov word[edi+6],0  ;wLength
mov edx,edi
call sfusb_commande
;cmp eax,0
;jne erreur_activation_hid ;pas de controle d'erreur parce que l'option n'est pas obligatoirement reconnu


;active le report descriptor
mov al,[usb_adresse] ;adresse
xor ah,ah
xor ecx,ecx
mov byte[edi],21h    ;bmRequestType
mov byte[edi+1],0Bh  ;bRequest (set protocol)
mov word[edi+2],1  ;wValue (0=boot protocol 1=report protocol)
mov word[edi+4],bx  ;wIndex
mov word[edi+6],0  ;wLength
mov edx,edi
call sfusb_commande
;cmp eax,0
;jne erreur_activation_hid ;pas de controle d'erreur parce que l'option n'est pas obligatoirement reconnu


;ouvre un canal int in vers le périphérique 
mov al,13
mov bl,[esi+dhu_adresse]
mov bh,[esi+dhu_terminaisonIn]
xor ecx,ecx
mov cx,[esi+dhu_tailleIn]
mov dl,[esi+dhu_frequenceIn]
int 68h
cmp eax,0
jne erreur_activation_hid
mov [esi+dhu_canalIn],ebx


popad
jmp suite_active_config_usb


erreur_activation_hid:
mov cl,99
call affmsgsyst
popad
jmp suite_active_config_usb





;**********************************************************************
config_msd_usb:  ;configuration clef usb/disque dur
cmp word[edi+6],05006h
je config_bulkonly_usb
jmp suite_active_config_usb


;*******************************************
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
jz @f
xchg al,ah
@@:
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
sub ecx,ad_desc_clef_usb
shr ecx,6
add ecx,40h
mov ch,cl



mov edi,usb_commande
mov eax,10
int 64h

mov eax,12
int 64h
popad

cmp cl,0
je suite_active_config_usb
dec cl
jmp boucle_config_bulkonly_usb




;**********************************************************************
config_hub_usb:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp suite_active_config_usb



;************************************
global_erreur_connexionUSB:
mov cl,102
call affmsgsyst
mov al,[usb_action]
call affh0j
mov al,13
call affcj
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

;met a jour la table des partitions
push eax
push edx
mov eax,edx
sub eax,ad_desc_clef_usb
shr eax,6
add eax,40h
mov edx,ad_descp
boucle2_deco_usb:
cmp [edx+1],al
jne suite2_deco_usb

mov dword[edx],0
mov dword[edx+4],0

suite2_deco_usb:
add edx,64
cmp edx,ad_descp+800h
jne boucle2_deco_usb
pop edx
pop eax

suite1_deco_usb:
add edx,64
cmp edx,ad_desc_clef_usb+2000h
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








;*********************************************************
;lit les données envoyé par les peripheriques hid usb


;???????????????????????????????????????





;*********************************************************
;envoie les eventuelles modification des leds claviers
;jmp pas_modif_led_clavier 
mov ax,seldat
mov ds,ax
mov al,[attcl]
mov ah,[ledcl]
and ax,707h
cmp al,ah
je pas_modif_led_clavier 

;ps2
or byte[attcl],40h
mov al,0EDh       ;commande led
out 60h,al




;usb hid




mov al,[attcl]
and al,7
mov [ledcl],al
pas_modif_led_clavier:




