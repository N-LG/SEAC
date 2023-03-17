date.fe:
pile equ 40960 ;definition de la taille de la pile
include "fe.inc"
db "Affiche la date et l'heure enregistré dans l'horloge de l'ordinateur"
scode:
org 0




mov ax,sel_dat1
mov ds,ax

mov al,9
int 61h ;bl=heure bh=minute si=seconde (en millième) dl=jour dh=mois cx=année
mov [heure],bx
mov [seconde],si
mov [jour],dx
mov [annee],cx


mov al,6        
mov edx,msg1
call ajuste_langue
int 61h


mov eax,20
int 61h
cmp eax,"eng "
je @f
xor ch,ch
mov cl,[jour]
call afnombre
@@:

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
call ajuste_langue
mov al,6        
int 61h

mov eax,20
int 61h
cmp eax,"eng "
jne @f
xor ch,ch
mov cl,[jour]
call afnombre
@@:

mov edx,msg2
call ajuste_langue
mov al,6        
int 61h

mov cx,[annee]
call afnombre


mov edx,msg3
call ajuste_langue
mov al,6        
int 61h

xor ch,ch
mov cl,[heure+1]
mov eax,20
int 61h
cmp eax,"fra "
je @f
cmp ecx,13
jb @f
sub cx,12
mov byte[msg5+1],"p"
@@:

call afnombre

mov edx,msg4
call ajuste_langue
mov al,6        
int 61h

xor ch,ch
mov cl,[heure]   ;minutes
cmp cl,9 ;s'il y as moins de 10 minutes on rajoute un zéro
ja @f
mov al,6
mov edx,zero
int 61h
@@:
call afnombre

mov edx,msg5
call ajuste_langue
mov al,6        
int 61h

mov ax,[seconde]
mov cx,1000
xor dx,dx
div cx
mov cx,ax
call afnombre

mov edx,msg6
call ajuste_langue
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


;***************************
ajuste_langue:  ;selectionne le message adapté a la langue employé par le système
push eax
mov eax,20
int 61h
xor ecx,ecx
cmp eax,"eng "
je @f
inc ecx
cmp eax,"fra "
je @f
xor ecx,ecx
@@:

boucle_ajuste_langue:
cmp ecx,0
je ok_ajuste_langue
cmp byte[edx],0
jne @f
dec ecx
@@:
inc edx
jmp boucle_ajuste_langue

ok_ajuste_langue:
pop eax
ret

;it is March 3 of the year 2023 and it is 11:30 p.m. and 23 seconds

sdata1:
org 0
msg1:
db 19h,"Today is ",0
db 19h,"Nous sommes le ",0
msg2:
db " in the year ",0
db "de l'an ",0
msg3:
db " and it is ",0
db " et il est ",0
msg4:
db ":",0
db "h",0
msg5:
db " a.m. and ",0
db "min",0
msg6:
db " seconds",17h,13,0
db "s",17h,13,0

nombre:
dd 0,0,0,0,0,0

zero:
db "0",0

heure:
dw 0
seconde:
dw 0
annee:
dw 0
jour:
dw 0



mois1:
db "January ",0
db " Janvier ",0
mois2:
db "February ",0
db " Février ",0
mois3:
db "March ",0
db " Mars ",0
mois4:
db "April ",0
db " Avril ",0
mois5:
db "May ",0
db " Mai ",0
mois6:
db "June ",0
db " Juin ",0
mois7:
db "July ",0
db " Juillet ",0
mois8:
db " August ",0
db " Août ",0
mois9:
db "September ",0
db " Septembre ",0
mois10:
db "October ",0
db " Octobre ",0
mois11:
db "November ",0
db " Novembre ",0
mois12:
db "December ",0
db " Décembre ",0

sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
