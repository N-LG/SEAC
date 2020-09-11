lc:   
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "liste les informations de base sur les cartes branché sur les bus pci et agp"
scode:
org 0
mov ax,sel_dat1
mov ds,ax

mov al,6        
mov edx,msg1
int 61h

mov ebx,80000000h
bouclecmdlc:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx
cmp ax,0FFFFh
je paslc

mov ebp,eax

mov ecx,ebx
shr ecx,16
and ecx,0FFh
mov edx,bus
mov al,105
int 61h
mov byte[edx+2]," "

mov ecx,ebx
shr ecx,11
and ecx,01Fh
mov edx,carte
mov al,105
int 61h
mov byte[edx+2]," "

mov ecx,ebx
shr ecx,8
and ecx,07h
mov edx,fonction
mov al,105
int 61h
mov byte[edx+2]," "

mov ecx,ebp
and ecx,0FFFFh
mov edx,vendor
mov al,104
int 61h
mov byte[edx+4]," "

mov ecx,ebp
shr ecx,16
and ecx,0FFFFh
mov edx,id
mov al,104
int 61h
mov byte[edx+4]," "

mov dx,0CF8h
mov eax,ebx
add eax,8
out dx,eax
mov dx,0CFCh
in eax,dx
mov ebp,eax

mov ecx,ebp
shr ecx,24
and ecx,0FFh
mov edx,classe
mov al,105
int 61h
mov byte[edx+2],"."

mov ecx,ebp
shr ecx,16
and ecx,0FFh
mov edx,sousclasse
mov al,105
int 61h
mov byte[edx+2],"."

mov ecx,ebp
shr ecx,8
and ecx,0FFh
mov edx,progif
mov al,105
int 61h
mov byte[edx+2],13

mov al,6  
mov ah,7      
mov edx,desciption
int 61h


paslc:
mov dx,0CF8h
mov eax,ebx
add eax,0Ch
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,00800000h
;jz simplefonction

add ebx,100h          ;on passe a la fonction suivante
test ebx,7F000000h
jz bouclecmdlc
int 60h


simplefonction:
add ebx,800h          ;on passe au device suivant
and ebx,0FFFFF800h
test ebx,7F000000h
jz bouclecmdlc
int 60h



sdata1:
org 0


msg1:
db 13,"liste des périphériques PCI et AGP détecté:",13,0 

desciption:
db "Bus:"
bus:
dw 0   
db " Carte:"
carte:
dw 0
db " Fonction:"
fonction:
dw 0
db " Vendor:"
vendor:
dd 0
db " ID:"
id:
dd 0
db " Classe:"
classe:
dw 0
db "."
sousclasse:
dw 0
db "."
progif:
dw 0
db 13,0



sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
