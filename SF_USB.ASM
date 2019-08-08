SF_USB.ASM:
;sous fonction USB
;al=0  configure périphérique
;al=1  envoie des donné a une terminaison
;al=2  reçois des données d'une terminaison
;ah=adresse du périphérique
;dl=numéros de la terminaison + data0/1
;ecx=quantité de données a envoyer
;es:esi=source des données
;es:edi=destination des données reçu


iret






cuhcitd: ;créer un transfert descriptor pour controleur uhci
;entrée: ecx=taille
;	al=adresse du périphérique
;	ah=terminaison
;       dl=numéros du controleur
;
add ecx,10h
call resmem
add ebx,10h
mov dword[ebx],1 ;link pointer vide
mov dword[ebx+4],0 ;champ vide

and ecx,3FFh
shl ecx,21
or cl,2Dh   ;PID setup

mov [ebx+8],ecx
mov eax,ebx
add eax,100010h
mov [ebx+0Ch],eax ;pointeur sur l'adresse physique de la zone tampon
ret



initusb:
push ds
push fs

mov ax,selramh
mov ds,ax
mov ax,seldat
mov fs,ax

mov ebx,desc_ctrl_usb

bociniusb:
fs
mov al,[ebx]
cmp al,1
je inituhci
cmp al,2
je initohci
cmp al,3
je initehci
cmp al,4
je initxhci
suiteiniusb:
add ebx,10h
cmp ebx,desc_ctrl_usb+100h
jne bociniusb

pop fs
pop ds
ret







inituhci:
fs
mov di,[ebx+4] ;adresse de base du contoleur


;arret de l'interface
mov ax,2  ;bit run/stop=0 hcreset=1
mov dx,di
out dx,ax  
add dx,2
attentuhcistop:
in ax,dx       
test ax,00FFh
jz attentuhcistop

xor ax,ax ;désactive les irq
add dx,2
out dx,ax   

xor ax,ax  ;config adress frame liste
mov dx,di
add dx,6
out dx,ax     
fs
mov eax,[ebx+8]
add dx,2
out dx,eax    

mov al,40h ;configure le signal de debut de frame
add dx,4
out dx,al     

mov dx,di  ;active les ports et remet a zero les bit de changement
add dx,10h
mov ax,0Eh 
out dx,ax
add dx,2   ;et le port 2
out dx,ax

fs
mov esi,[ebx+8]
mov eax,1               ;remplis l'adress fram list avec des pointeur null
bocrempuhci:
mov [esi],eax
add esi,4
test esi,0FFFh
jnz bocrempuhci

jmp suiteiniusb

initohci:
jmp suiteiniusb

initehci:
jmp suiteiniusb

initxhci:
jmp suiteiniusb




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



;descripteur de contoleur USB
desc_ctrl_usb_type equ 0 ;type 0=vide 1=uhci 2=ohci 3=ehci 4=xhci
desc_ctrl_usb_nb   equ 1 ;nombre de port du controleur
desc_ctrl_usb_pci  equ 2 ;coordonné PCI
desc_ctrl_usb_es   equ 4 ;adresse des E/S
desc_ctrl_usb_mem  equ 8 ;espace mémoire reservé



;******************************************************************************************************
;code de detection  et de création des descripteur pour les controleur de bus USB 
detection_ctrl_usb:
mov ax,seldat 
mov ds,ax
mov ax,selramh 
mov es,ax
mov ebx,80000008h  ;enable bit + classe code, subclass
mov esi,desc_ctrl_usb
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
cmp dh,10h          ;OHCI
je ctrl_ohci
cmp dh,20h          ;EHCI
je ctrl_ehci
cmp dh,30h          ;XHCI
je ctrl_xhci
jmp pasctrl

;*************************************
ctrl_uhci:
mov byte[esi+desc_ctrl_usb_type],1 ;controleur de type uhci
mov eax,ebx
and eax,0FFFF00h
shr eax,8
mov [esi+desc_ctrl_usb_pci],ax  ;coordonnée PCI

mov dx,0CF8h
mov eax,ebx
add eax,18h ;pour avoir l'adresse de base des ports (BAR4)
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,1  ;on vérifie que c'est bien un descripteur de port d'e/s
jz pasctrl
and eax,0FFE0h
mov [esi+desc_ctrl_usb_es],ax  ;adresse de base du controleur

mov byte[esi+desc_ctrl_usb_nb],2 ;deux port

push ebx
mov eax,0FFFh
mov ecx,1000h   ;4096 octets
call resmemg   ;réserve une place pour la frame list uhci 
es
mov word[ebx+8],czm_flu   ;code pour frame list uhci 
add ebx,100010h   ;adresse physique
mov [esi+desc_ctrl_usb_mem],ebx
pop ebx 
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp fin_init_ctrl



;*********************************************
ctrl_ohci:
mov byte[esi+desc_ctrl_usb_type],2 ;controleur de type ohci
mov eax,ebx
and eax,0FFFF00h
shr eax,8
mov [esi+desc_ctrl_usb_pci],ax  ;coordonnée PCI
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp fin_init_ctrl


;*************************************************
ctrl_ehci:
mov byte[esi+desc_ctrl_usb_type],3 ;controleur de type ehci
mov eax,ebx
and eax,0FFFF00h
shr eax,8
mov [esi+desc_ctrl_usb_pci],ax  ;coordonnée PCI

mov dx,0CF8h
mov eax,ebx
add eax,8 ;pour avoir l'adresse de base des ports (Bar0)
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,1  ;on vérifie que c'est bien un descripteur de port d'e/s
jnz pasctrl
and eax,0FFFFFFF0h
mov [esi+desc_ctrl_usb_es],ax  ;adresse de base du controleur
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp fin_init_ctrl


;***********************************************
ctrl_xhci:
mov byte[esi+desc_ctrl_usb_type],4 ;controleur de type xhci
mov eax,ebx
and eax,0FFFF00h
shr eax,8
mov [esi+desc_ctrl_usb_pci],ax  ;coordonnée PCI
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

fin_init_ctrl:
add esi,16
pasctrl:
cmp esi,desc_ctrl_usb+200h
je fin_detection_ctrl_usb

add ebx,100h
test ebx,7F000000h
jz boucletcusb
fin_detection_ctrl_usb:
ret














;****************************************************************************************************************
;code executé periodiquement par la tache principale pour mettre a jour les descripteur de periphérique branché a l'USB
verif_periodique_usb:














ret









