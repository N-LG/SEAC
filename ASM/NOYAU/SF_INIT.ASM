﻿SF_INIT:           ;detection et initialisation des contoleur disquette, ATA et USB



;********************************************************************************************************************************
;réinitialise le controleur disquette
mov ax,seldat
mov es,ax
mov ds,ax
mov byte[trappe_tache0],31
mov byte[pos_cyl_disq],0FFh  ;position de la tête indeterminé

mov dx,3F7h ;mode 500000 bit/s
mov al,00h
out dx,al

mov dx,3F2h ;reinitialisation du controleur disquette
mov al,00h
out dx,al



;************************************************************************************************
;désactive les périphériques PCI (pour eviter les bug de virtualbox au démarrage)
mov ebx,80000000h
boucle_stop_pci:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx
cmp eax,0FFFFFFFFh
je @f

mov dx,0CF8h
mov eax,ebx
add eax,8
out dx,eax
mov dx,0CFCh
in eax,dx
shr eax,24
cmp al,01h    ;sauf les périphériques de stockage
je @f
cmp al,03h    ;les cartes video
je @f
cmp al,06h    ;les bridges
je @f
cmp al,08h    ;les périphériques de base
je @f
cmp al,0Ch    ;et les controleurs USB
je @f

mov dx,0CF8h
mov eax,ebx
add eax,4
out dx,eax
mov dx,0CFCh
mov eax,0   ;command + status register
out dx,eax

@@:
add ebx,100h
test ebx,7F000000h
jz boucle_stop_pci





;***********************************************************************************************************************************
;detecte les contolleur ATA sur le bus PCI et enregistre les adresses
mov ebx,80000008h
mov esi,ad_descd
boucle_detec_ata:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx
cmp ax,0FFFFh
je pasctrlata
mov ecx,eax
and eax,0FFFF0000h 
cmp eax,001010000h  ;classe=01h sous-classe=01h
jne pasctrlata

mov word[esi+dd_atribut],00h
mov word[esi+dd_atribut+32],10h
mov word[esi+dd_atribut+64],00h
mov word[esi+dd_atribut+96],10h

test ch,80h
jz crtl_dma_abs
mov dx,0CF8h
mov eax,ebx
add eax,24     ;BAR4
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,0FFFF0000h
jnz crtl_dma_abs
test al,1
jz crtl_dma_abs
and eax,0FFFCh
cmp eax,0
je crtl_dma_abs
or word[esi+dd_atribut],08h
or word[esi+dd_atribut+32],08h
or word[esi+dd_atribut+64],08h
or word[esi+dd_atribut+96],08h
jmp @f
crtl_dma_abs:
xor eax,eax
@@:
mov [esi+dd_adress_dma],ax
mov [esi+dd_adress_dma+32],ax
add eax,8
mov [esi+dd_adress_dma+64],ax
mov [esi+dd_adress_dma+96],ax

test ch,1
jz bar0_nok
mov dx,0CF8h
mov eax,ebx
add eax,8     ;BAR0
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,0FFFF0000h
jnz ctrlata0_nok
test al,1
jz ctrlata0_nok
and eax,0FFFCh
cmp eax,0
jne bar0_ok
bar0_nok:
mov eax,1F0h
bar0_ok:
mov [esi+dd_adress_base],ax
mov [esi+dd_adress_base+32],ax

test ch,1
jz bar1_nok
mov dx,0CF8h
mov eax,ebx
add eax,12     ;BAR1
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,0FFFF0000h
jnz ctrlata0_nok
test al,1
jz ctrlata0_nok
and eax,0FFFCh
cmp eax,0
jne bar1_ok
bar1_nok:
mov eax,3F6h
bar1_ok:
mov [esi+dd_adress_ctrl],ax
mov [esi+dd_adress_ctrl+32],ax

jmp @f
ctrlata0_nok:
mov dword[esi+00h],0
mov dword[esi+04h],0
mov dword[esi+08h],0
mov dword[esi+0Ch],0
mov dword[esi+10h],0
mov dword[esi+14h],0
mov dword[esi+18h],0
mov dword[esi+1Ch],0
mov dword[esi+20h],0
mov dword[esi+24h],0
mov dword[esi+28h],0
mov dword[esi+2Ch],0
mov dword[esi+30h],0
mov dword[esi+34h],0
mov dword[esi+38h],0
mov dword[esi+3Ch],0
@@:
add esi,64
cmp esi,ad_descd+256
je fin_detec_ata


test ch,4
jz bar2_nok
mov dx,0CF8h
mov eax,ebx
add eax,16     ;BAR2
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,0FFFF0000h
jnz ctrlata1_nok
test al,1
jz ctrlata1_nok
and eax,0FFFCh
cmp eax,0
jne bar2_ok
bar2_nok:
mov eax,170h
bar2_ok:
mov [esi+dd_adress_base],ax
mov [esi+dd_adress_base+32],ax

test ch,4
jz bar3_nok
mov dx,0CF8h
mov eax,ebx
add eax,20     ;BAR3
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,0FFFF0000h
jnz ctrlata1_nok
test al,1
jz ctrlata1_nok
and eax,0FFFCh
cmp eax,0
jne bar3_ok
bar3_nok:
mov eax,376h
bar3_ok:
mov [esi+dd_adress_ctrl],ax
mov [esi+dd_adress_ctrl+32],ax


jmp @f
ctrlata1_nok:
mov dword[esi+00h],0
mov dword[esi+04h],0
mov dword[esi+08h],0
mov dword[esi+0Ch],0
mov dword[esi+10h],0
mov dword[esi+14h],0
mov dword[esi+18h],0
mov dword[esi+1Ch],0
mov dword[esi+20h],0
mov dword[esi+24h],0
mov dword[esi+28h],0
mov dword[esi+2Ch],0
mov dword[esi+30h],0
mov dword[esi+34h],0
mov dword[esi+38h],0
mov dword[esi+3Ch],0
@@:
add esi,64
cmp esi,ad_descd+256
je fin_detec_ata


pasctrlata:
add ebx,100h
test ebx,7F000000h
jz boucle_detec_ata

mov byte[trappe_tache0],32
gs
mov word[158],"L" or 7000h


;*****************************************************************************************************************************
;détecte les controleur ahci et leurs port ouverts
mov ax,seldat 
mov ds,ax
mov fs,ax
mov ax,selramh 
mov es,ax
mov gs,ax
mov ebx,80000008h

boucle_detec_ahci:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx
and eax,0FFFFFF00h 
cmp eax,01060100h  ;classe=01h sous-classe=06h  if=01 (AHCI)
jne pas_ctrl_ahci            

ahci_pi equ 00Ch
ahci_port0 equ 100h


pushad
;lit adresse de base du controleur
mov dx,0CF8h
mov eax,ebx
add eax,28
out dx,eax
mov dx,0CFCh
in eax,dx
sub eax,100000h
mov esi,eax

;activation controleur
mov dx,0CF8h
mov eax,ebx
sub eax,4
out dx,eax
mov dx,0CFCh
in eax,dx
and eax,0FFFF0000h
or  eax,000000416h
out dx,eax

;configure le cache line size et le master latency timer
;mov dx,0CF8h
;mov eax,ebx
;add eax,4
;out dx,eax
;mov dx,0CFCh
;in eax,dx
;mov ax,8040h     ; master latency timer=128  cache line size=64 
;out dx,eax

es
test dword[esi+24h],1
jz handoffbiosok

es
mov eax,[esi+28h] ;demande le controle
test eax,2
jz @f
or al,8
@@:
or al,2
es
mov [esi+28h],eax
mov ecx,[cptsf]
add ecx,400

@@:
es
test dword[esi+28h],1
jz handoffbiosok
cmp ecx,[cptsf]
jb erreur_ctrl_ahci 
jmp @b

handoffbiosok:


;active le mode ahci
es
or dword[esi+4],80000000h



;effectue reset controleur
es
or dword[esi+4],1
mov ecx,[cptsf]
add ecx,1200
@@:
es
test dword[esi+4],1
jz @f 
cmp ecx,[cptsf]
jb erreur_ctrl_ahci
jmp @b

@@:


;active ahci enable
es
or dword[esi+4],80000000h 

;test disponibilité port
es
mov edx,[esi+ahci_pi]
mov ebx,ahci_port0
add ebx,esi

boucle_test_port_ahci:
test edx,01h
jz passe_test_port_ahci


;création espace port
pushad
push ebx
mov ecx,0FF0h ;4Ko-16
mov eax,003FFh 
call resmemg 
mov edi,ebx
pop ebx
jc erreur_port_ahci
es
mov dword[edi+8],czm_sata

call reset_port_ahci  ;reset et desactive le port (voir SF_DISK.ASM)

;config port
es
mov [edi+zsata_ad_ahci],esi  ;enregistre l'adresse de base du controleur
es
mov [edi+zsata_ad_port],ebx  ;enregistre l'adresse port de base de cette interface
es
mov byte[edi+zsata_conv_secteur],9 ;enregistre par defaut que les secteurs font 512 octets


mov eax,edi
add eax,zsata_liste+100000h   ;configure l'adresse de la liste de commande
es
mov [ebx],eax
es
mov dword[ebx+04h],0
mov eax,edi
add eax,zsata_recfis+100000h  ;configure l'adresse de la receved fis
es
mov [ebx+08h],eax
es
mov dword[ebx+0Ch],0

call start_port_ahci  ;active le port (voir SF_DISK.ASM)

erreur_port_ahci:
popad

passe_test_port_ahci:
shr edx,1
add ebx,80h
cmp edx,0
jnz boucle_test_port_ahci


erreur_ctrl_ahci:
popad


pas_ctrl_ahci:
add ebx,100h
test ebx,7F000000h
jz boucle_detec_ahci



;liste les disques ahci***********
xor esi,esi
mov edi,po_zech_sata

boucle_liste_disque_ahci:
es
cmp byte[esi+2],"F"
je fin_liste_disque_ahci
es
cmp byte[esi+2],"S"
jne suite_liste_disque_ahci
es
cmp dword[esi+8],14
jne suite_liste_disque_ahci

mov [edi],esi
mov dword[edi+4],0  ;dword réservé pour un usage future
add edi,8
cmp edi,po_zech_sata+512
je fin_liste_disque_ahci

suite_liste_disque_ahci:
es
mov eax,[esi+4]
add esi,eax
jmp boucle_liste_disque_ahci

fin_liste_disque_ahci:

mov ax,selvidB8
mov gs,ax
mov byte[trappe_tache0],33
gs
mov word[158],"M" or 7000h




;***************************************************
mov ax,seldat 
mov ds,ax
cmp word[ad_descd+dd_adress_base],0 ;si aucun controleur ata n'as été detecté
jne fin_detec_ata 
cmp dword[po_zech_sata],0           ;et si aucun controleur ahci n'as été détecté, on remplit les descripteur avec les adresses standard
jne fin_detec_ata 



mov ebx,ad_descd
mov ax,1F0h
mov dx,3F6h

boucle_remplissage_ctrl_ata:
mov word[ebx+dd_atribut],00h
mov word[ebx+dd_atribut+32],10h
mov [ebx+dd_adress_base],ax
mov [ebx+dd_adress_base+32],ax
mov [ebx+dd_adress_ctrl],dx
mov [ebx+dd_adress_ctrl+32],dx
mov word[ebx+dd_adress_dma],0
mov word[ebx+dd_adress_dma+32],0

sub ax,80h
sub dx,80h
add ebx,64
cmp ebx,ad_descd+256
jne boucle_remplissage_ctrl_ata


fin_detec_ata:
mov byte[trappe_tache0],34
gs
mov word[158],"N" or 7000h



;********************************************************************************************************************************
;lit les info disque ata et met a jour les info de partitions
mov ax,seldat 
mov ds,ax
mov es,ax
mov ch,8h
mov esi,ad_descd


boucle_init_infopart:
mov al,10
mov edi,bootsecteur
push cx
int 64h          ;charge les info disque
pop cx
cmp eax,0
je init_infodisque_ata
or byte[esi+dd_atribut],7
jmp pasinfopart


init_infodisque_ata:
test byte[bootsecteur+1],080h   ;test si le périphérique est atapi
jnz init_infodisque_atapi

mov eax,[bootsecteur+0C8h]   ;LSB nombre de secteur en LBA48 
mov edx,[bootsecteur+0CCh]   ;MSB nombre de secteur en LBA48 
cmp edx,0
je init_infodisque_lba28
test eax,0C0000000h
jz init_infodisque_lba28
or byte[esi+dd_atribut],3
mov [esi+dd_taille],eax
mov [esi+dd_taille+4],edx
jmp init_infopart

init_infodisque_lba28:
mov eax,[bootsecteur+78h]   ;nombre de secteur en LBA28
cmp eax,0
je init_infodisque_chs
or byte[esi+dd_atribut],2
mov [esi+dd_taille],eax
mov dword[esi+dd_taille+4],0
jmp init_infopart


init_infodisque_chs:
mov eax,[bootsecteur+72h]   ;nombre de secteur en CHS
or byte[esi+dd_atribut],1
mov [esi+dd_taille],eax
mov dword[esi+dd_taille+4],0
push ecx
xor eax,eax
xor ecx,ecx
mov ax,[bootsecteur+70h]   ;secteur par piste
mov cx,[bootsecteur+6Eh]   ;nombre de tête
mov [esi+dd_sec_par_piste],ax
mul ecx
mov [esi+dd_sec_par_cyl],eax       ;nombre de secteur par cylindre
pop ecx

init_infopart:
mov ax,[bootsecteur+0D4h]
mov edx,[bootsecteur+0EAh]
mov cl,9

test ax,8000h
jnz init_ata_conv_secteur 
test ax,8000h
jz init_ata_conv_secteur 
test ax,1000h
jz init_ata_conv_secteur

mov cl,0
boucle_init_ata_conv_secteur:
inc cl
shr edx,1
cmp edx,1
jne boucle_init_ata_conv_secteur 

init_ata_conv_secteur:
mov byte[esi+dd_nb_octet_sec],cl

mov al,12
int 64h
jmp pasinfopart


init_infodisque_atapi:
or byte[esi+dd_atribut],4
mov edi,table_cdrom
@@:
cmp byte[edi],0 
je @f
inc edi
cmp edi,table_cdrom+8
je pasinfopart
jmp @b
@@:
mov [edi],ch

pasinfopart:
inc ch
add esi,32
cmp ch,10h
jne boucle_init_infopart




;*********************************************************************************************************************************************
;lit les info disque sata et met a jour les info de partitions
mov ax,selramh 
mov ds,ax
mov ax,seldat
mov es,ax
mov ch,20h
mov esi,po_zech_sata

boucle_init_infopart2:
es
mov ebx,[esi]
cmp ebx,0
je pasinfopart2
mov al,10
mov edi,bootsecteur
push cx
int 64h          ;charge les info disque
pop cx
cmp eax,0
jne pasinfopart2

es
test byte[bootsecteur+1],080h   ;test si le périphérique est atapi
jnz init_infodisque_atapi2

es
mov eax,[bootsecteur+0C8h]   ;LSB nombre de secteur en LBA48 
es
mov edx,[bootsecteur+0CCh]   ;MSB nombre de secteur en LBA48 
cmp edx,0
je init_infodisque2_lba28
test eax,0C0000000h
jnz init_sata_taille
init_infodisque2_lba28:
es
mov eax,[bootsecteur+78h]   ;nombre de secteur en LBA28
xor edx,edx
cmp eax,0
jne init_sata_taille
es
mov eax,[bootsecteur+72h]   ;nombre de secteur en CHS
xor edx,edx

init_sata_taille:
mov [ebx+zsata_nb_secteur],eax
mov [ebx+zsata_nb_secteur+4],edx
es
mov ax,[bootsecteur+0D4h]
es
mov edx,[bootsecteur+0EAh]
mov cl,9

test ax,8000h
jnz init_sata_conv_secteur 
test ax,8000h
jz init_sata_conv_secteur 
test ax,1000h
jz init_sata_conv_secteur

mov cl,0
boucle_init_sata_conv_secteur:
inc cl
shr edx,1
cmp edx,1
jne boucle_init_sata_conv_secteur 

init_sata_conv_secteur:
mov byte[ebx+zsata_conv_secteur],cl

mov al,12
int 64h
jmp pasinfopart2


init_infodisque_atapi2:
mov edi,table_cdrom
@@:
es
cmp byte[edi],0 
je @f
inc edi
cmp edi,table_cdrom+8
je pasinfopart2
jmp @b
@@:
es
mov [edi],ch

pasinfopart2:
inc ch
add esi,8
cmp ch,30h
jne boucle_init_infopart2




mov byte[trappe_tache0],35
gs
mov word[158],"O" or 7000h


;*********************************************************************************************************************************************
;code de detection  et de création des descripteur pour les controleur de bus USB 
mov ax,seldat 
mov ds,ax
mov ax,selramh 
mov es,ax
mov ebx,80000008h  ;enable bit + classe code, subclass
mov esi,ad_desc_ctrl_usb
boucletcusb:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx
cmp ax,0FFFFh
je pasctrl
mov edx,eax
and eax,0FFFF0000h 
cmp eax,0C030000h  ;classe=0Ch sous-classe=03h
jne pasctrl

cmp dh,00h          ;UHCI
je ctrl_uhci
;cmp dh,10h          ;OHCI
;je ctrl_ohci
cmp dh,20h          ;EHCI
je ctrl_ehci
;cmp dh,30h          ;XHCI
;je ctrl_xhci
jmp pasctrl

;*************************************
ctrl_uhci:
mov byte[esi+dcu_type],1 ;controleur de type uhci
mov eax,ebx
and eax,0FFFFFF00h
mov [esi+dcu_pci],eax  ;coordonnée PCI

;active controle par e/s
mov dx,0CF8h
mov eax,[esi+dcu_pci]
add eax,4
out dx,eax
mov dx,0CFCh
mov eax,5   ;command + status register
out dx,eax

mov dx,0CF8h
mov eax,ebx
add eax,18h ;pour avoir l'adresse de base des ports (BAR4)
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,1  ;on vérifie que c'est bien un descripteur de port d'e/s
jz pasctrl
and eax,0FFE0h
mov [esi+dcu_es],ax  ;adresse de base du controleur

mov byte[esi+dcu_nb_port],2 ;deux port

push ebx
mov eax,0FFFh
mov ecx,139264   ;136Koctets
mov [esi+dcu_to],ecx
call resmemg 
;§§§§§§§§§§§§§§§§§§§§§§§§que faire en cas d'imposibilité de réserver de la mémoire   
es
mov word[ebx+8],czm_uhci  
add ebx,100010h   ;adresse physique
mov [esi+dcu_mem],ebx
pop ebx 

call init_uhci    ;voir SF_USB.ASM
jmp fin_init_ctrl



;*********************************************
ctrl_ohci:
mov byte[esi+dcu_type],2 ;controleur de type ohci
mov eax,ebx
and eax,0FFFF00h
mov [esi+dcu_pci],eax  ;coordonnée PCI
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
call init_ohci    ;voir SF_USM.ASM
jmp fin_init_ctrl


;*************************************************
ctrl_ehci:
mov byte[esi+dcu_type],3 ;controleur de type ehci
mov eax,ebx
and eax,0FFFFFF00h
mov [esi+dcu_pci],eax  ;coordonnée PCI


;active controle par mémoire
mov dx,0CF8h
mov eax,[esi+dcu_pci]
add eax,4
out dx,eax
mov dx,0CFCh
mov eax,6   ;command + status register (6=bus master+memory space)
out dx,eax


;récupère adresse de base
mov dx,0CF8h
mov eax,[esi+dcu_pci]
add eax,10h 
out dx,eax
mov dx,0CFCh
in eax,dx
and eax,0FFFFFF00h
sub eax,100000h
mov [esi+dcu_es],eax

;récupère le nombre de port
mov edi,[esi+dcu_es]
es
mov eax,[edi+4]
and al,0Fh
mov [esi+dcu_nb_port],al 


;trouve les operationals registers
xor eax,eax
es
mov al,[edi]
add [esi+dcu_es],eax


call init_ehci    ;voir SF_USM.ASM
jmp fin_init_ctrl


;***********************************************
ctrl_xhci:
mov byte[esi+dcu_type],4 ;controleur de type xhci
mov eax,ebx
and eax,0FFFF00h
mov [esi+dcu_pci],eax  ;coordonnée PCI
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
call init_xhci    ;voir SF_USM.ASM



;*****************************
fin_init_ctrl:
add esi,32
cmp esi,ad_desc_ctrl_usb+800h
je fin_detection_ctrl_usb

pasctrl:
add ebx,100h
test ebx,7F000000h
jz boucletcusb
fin_detection_ctrl_usb:



