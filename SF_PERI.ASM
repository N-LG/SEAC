SF_PERI.ASM:         ;fonction effectué périodiquement par la tache principale

;********************************
mov ax,seldat    ;gestion du moteur de la disquette
mov ds,ax
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
;gestion de la detection de nouvelles connexion a un port de controleur USB
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

uhci_test_cnx_usb:
xor edx,edx
mov dl,[usb_port_test]
shl dx,1
add dx,ctrl_uhci_portsc1
add dx,[ebx+dcu_es]
in ax,dx
test ax,02h
jz suite_test_cnx_usb
out dx,ax 

pushad ;§§§§§§§§§§§§§§§§§§TRAPPE
mov al,"U"
call affcj
popad   ;§§§§§§§§§§§§§§§§§§

jmp suite_test_cnx_usb


ehci_test_cnx_usb:



;jmp suite_test_cnx_usb




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