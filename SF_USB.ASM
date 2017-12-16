;sous fonction USB
;al=0  configure périphérique
;al=1  envoie des donné a une terminaison
;al=2  reçois des données d'une terminaison
;ah=adresse du périphérique
;dl=numéros de la terminaison + data0/1
;ecx=quantité de données a envoyer
;es:esi=source des données
;es:edi=destination des données reçu

cmp al,0
;je configusb


finsfusb:
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






irqUSB:              ;irq D
push ax
mov al,20h
out 0A0h,al
mov al,20h
out 20h,al
pop ax
sti
iret








