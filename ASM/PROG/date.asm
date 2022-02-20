date.fe:
pile equ 40960 ;definition de la taille de la pile
include "fe.inc"
db "Affiche la date et l'heure enregistré dans l'horloge de l'ordinateur"
scode:
org 0




mov ax,sel_dat1
mov ds,ax

mov al,9
int 61h ;al=heure ah=minute bx=seconde (en millième) dl=jour dh=mois cx=année
mov [heure],ax
mov [seconde],bx
mov [jour],dx
mov [annee],cx


mov al,6        
mov edx,msg1
int 61h

xor ch,ch
mov cl,[jour]
call afnombre

mov al,[jour+1]   ;n° du mois

cmp al,01h 
jne test1
mov edx,mois1
test1:
cmp al,02h 
jne test2
mov edx,mois2
test2:
cmp al,03h 
jne test3
mov edx,mois3
test3:
cmp al,04h 
jne test4
mov dx,mois4
test4:
cmp al,05h 
jne test5
mov edx,mois5
test5:
cmp al,06h 
jne test6
mov edx,mois6
test6:
cmp al,07h 
jne test7
mov edx,mois7
test7:
cmp al,08h 
jne test8
mov edx,mois8
test8:
cmp al,09h 
jne test9
mov edx,mois9
test9:
cmp al,0Ah 
jne test10
mov edx,mois10
test10:
cmp al,0Bh 
jne test11
mov edx,mois11
test11:
cmp al,0Ch 
jne test12
mov edx,mois12
test12:
mov al,6        
int 61h

mov edx,msg2
mov al,6        
int 61h

mov cx,[annee]
call afnombre


mov edx,msg3
mov al,6        
int 61h

xor ch,ch
mov cl,[heure]
call afnombre

mov edx,msg4
mov al,6        
int 61h

xor ch,ch
mov cl,[heure+1]   ;minutes
call afnombre

mov edx,msg5
mov al,6        
int 61h

mov ax,[seconde]
mov cx,1000
xor dx,dx
div cx
mov cx,ax
call afnombre

mov edx,msg6
mov al,6        
int 61h

int 60h



afnombre:
mov al,102
mov edx,nombre
int 61h

mov edx,nombre
mov al,6        
int 61h
ret

sdata1:
org 0
msg1: 
db 19h,"Nous sommes le ",0
msg2:
db "de l'an ",0
msg3:
db " et il est ",0
msg4:
db "h",0
msg5:
db "min",0
msg6:
db "s",17h,13,0

nombre:
dd 0,0,0,0,0,0


heure:
dw 0
seconde:
dw 0
annee:
dw 0
jour:
dw 0



mois1:
db " Janvier ",0
mois2:
db " Février ",0
mois3:
db " Mars ",0
mois4:
db " Avril ",0
mois5:
db " Mai ",0
mois6:
db " Juin ",0
mois7:
db " Juillet ",0
mois8:
db " Aout ",0
mois9:
db " Septembre ",0
mois10:
db " Octobre ",0
mois11:
db " Novembre ",0
mois12:
db " Décembre ",0

sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
