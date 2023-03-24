utf8:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "convertit un code de caractère unicode exprimé en hexadécimal en une suite d'octet pour un codage en UTF8"
scode:
org 0

;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax

mov eax,0004h       ;charge le premier param
mov edx,chaine
mov cl,200
int 61h
cmp eax,0
jne carac0

mov edx,chaine
mov eax,101
int 61h
cmp ecx,0
jne okcarac
carac0:
mov ecx,1
okcarac:
mov [carac],ecx

mov eax,0104h       ;charge le deuxième param
mov edx,chaine
mov cl,200
int 61h
cmp eax,0
jne nombre0

mov edx,chaine
mov eax,101
int 61h
cmp ecx,0
jne oknombre
nombre0:
mov ecx,1
oknombre:
mov [nombre],ecx



boucle:
mov ecx,[carac]
mov al,103
mov edx,chaine
int 61h
bouclehexa:
cmp byte[edx],"0"
jne suitehexa
inc edx
jmp bouclehexa
suitehexa:
mov al,6        
int 61h

mov edx,msgegal
mov al,6        
int 61h

mov ecx,[carac]
mov al,102
mov edx,chaine
int 61h
mov al,6        
int 61h


mov byte[chaine],"("

cmp ecx,80h   ;-de 7 bit
jb insert1
cmp ecx,800h  ;-de 11 bits
jb insert2
cmp ecx,10000h  ;-de 16 bits
jb insert3
cmp ecx,200000h   ;-de 21 bits
jb insert4
mov al,6        
mov edx,msgerr
call ajuste_langue
int 61h
int 60h





;********************************
insert1:
and ecx,7Fh  
mov [chaine+1],cl

mov dword[chaine+2],")-> "
       
mov edx,chaine+6
mov al,105
int 61h
jmp fin_norm



;***********************************
insert2:
mov al,cl
and al,3Fh
or al,80h
mov [chaine+2],al
shr ecx,6
mov al,cl
and al,01Fh
or al,0C0h
mov [chaine+1],al

mov dword[chaine+3],")-> "

mov al,105
mov cl,[chaine+1]
mov edx,chaine+7
int 61h
mov byte[chaine+9]," "
mov al,105
mov cl,[chaine+2]
mov edx,chaine+10
int 61h
jmp fin_norm






;*********************************
insert3:
mov al,cl
and al,3Fh
or al,80h
mov [chaine+3],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [chaine+2],al
shr ecx,6
mov al,cl
and al,0Fh
or al,0E0h
mov [chaine+1],al

mov dword[chaine+4],")-> "

mov al,105
mov cl,[chaine+1]
mov edx,chaine+8
int 61h
mov byte[chaine+10]," "
mov al,105
mov cl,[chaine+2]
mov edx,chaine+11
int 61h
mov byte[chaine+13]," "
mov al,105
mov cl,[chaine+3]
mov edx,chaine+14
int 61h

jmp fin_norm

;******************************
insert4:
mov al,cl
and al,3Fh
or al,80h
mov [chaine+4],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [chaine+3],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [chaine+2],al
shr ecx,6
mov al,cl
and al,07h
or al,0F0h
mov [chaine+1],al

mov dword[chaine+5],")-> "

mov al,105
mov cl,[chaine+1]
mov edx,chaine+9
int 61h
mov byte[chaine+11]," "
mov al,105
mov cl,[chaine+2]
mov edx,chaine+12
int 61h
mov byte[chaine+14]," "
mov al,105
mov cl,[chaine+3]
mov edx,chaine+15
int 61h
mov byte[chaine+17]," "
mov al,105
mov cl,[chaine+4]
mov edx,chaine+18
int 61h





;******************************
fin_norm:
mov al,6        
mov edx,chaine
int 61h

mov al,6        
mov edx,msgfin
int 61h


inc dword[carac]
dec dword[nombre]
jnz boucle

int 60h



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




sdata1:
org 0

carac:
dd 0
nombre:
dd 0
msgerr:
db " -> the character code entered exceeds the 21 bits authorized by UNICODE",13,0
db " -> le code de caractère entrée dépasse les 21 bits autorisé par UNICODE",13,0
msgfin:
db 13,0
msgegal:
db "h = ",0
chaine:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0
sdata2:
org 0
;données du segment ES
sdata3:
org 0
;données du segment FS
sdata4:
org 0
;données du segment GS
findata:
