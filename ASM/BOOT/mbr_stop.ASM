codeMBR: ;affiche un simple message  


use16
org 0h
mov ax,7C0h
mov ds,ax
mov ax,9000h        
mov ss,ax
xor esp,esp

mov si,message
call afmsg

sansfin:
nop
nop
jmp sansfin

;************************************************
;sous fonctions

afmsg:
mov al,[si]
cmp al,0
jne affiche
ret

affiche:
mov ah,0Eh
mov bx,07h
int 10h
inc si
jmp afmsg








message:
db 10,13,"Attention!",10,13
db "il ne faut JAMAIS d",82h,"marrer un pc avec une clef usb de banch",82h," dessus car il",10,13 
db "pourrait y avoir un virus d'install",82h," sur la clef (a la place de cet inofensif",10,13 
db "message d'avertissement)",10,13
db 10,13
db "d",82h,"branchez la clef et redemarrez votre PC pour pouvoir retrouver votre systeme",10,13 
db "d'exploitation",0


;82h = é

;8Ah = è

;88h = ê


