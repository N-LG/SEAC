mge_:
;index des fonctions mge_*
;tout les registres sont des pointeur

;mge_divise: ;edi=esi/edi esi=reste
;mge_multiplie: ;edi=esi*edi
;mge_copie:  ;edi=esi
;mge_efface: ;edi=0
;mge_compare:  cmp edi,esi
;mge_addition:  ;edi=edi+esi
;mge_soustraction: ;edi=edi-esi
;mge_decalm:    ;edx=edx/2
;mge_decalp:    ;edx=edx*2
;mge_hexa:  affiche edx en hexadécimal
;mge_deci:  affiche edx en décimal






;***************************************
mge_divise: ;edi=esi/edi esi=reste
pushad

mov eax,esi  ;nombre a diviser qui finira en reste
mov ebx,edi  ;quotient  

;copie diviseur dans temp1
mov esi,edi
mov edi,mge_temp1
call mge_copie

;met quotient a zéro
mov edi,ebx
call mge_efface

;décale+ temp1 jusqu'à qu'il soit sup a reste
xor ecx,ecx
@@:
mov edx,mge_temp1
call mge_decalp
inc ecx
mov edi,mge_temp1
mov esi,eax
call mge_compare
jb @b


boucle_mge_division:

;décale- temp1
mov edx,mge_temp1
call mge_decalm
dec ecx

;décale+ quotient
mov edx,ebx
call mge_decalp

;reste sup a temp1?
mov edi,eax
mov esi,mge_temp1
call mge_compare
jb @f   ;non-> suite

;bit 0 de quotient a 1
or byte[ebx],1

mov edi,eax
mov esi,mge_temp1
call mge_soustraction

@@:
cmp ecx,0
jne boucle_mge_division
popad
ret

;***************************************
mge_multiplie: ;edi=esi*edi
push ecx
push edx
push esi
push edi

push edi
push edi
mov edi,mge_temp1
call mge_copie
pop esi
mov edi,mge_temp2
call mge_copie
pop edi
call mge_efface

mov ecx,[mge_nb_dw]
shl ecx,5
mov esi,mge_temp2


boucle_mge_multiplie:
test byte[mge_temp1],1
jz @f
call mge_addition
@@:

mov edx,mge_temp1
call mge_decalm
mov edx,mge_temp2
call mge_decalp
dec ecx
jnz boucle_mge_multiplie

pop edi
pop esi
pop edx
pop ecx
ret

;***************************************
mge_copie:  ;edi=esi
push ecx
push esi
push edi
mov ecx,[mge_nb_dw]
cld
rep movsd
pop edi
pop esi
pop ecx
ret

;***************************************
mge_efface: ;edi=0
push eax
push ecx
push edi
xor eax,eax
mov ecx,[mge_nb_dw]
cld
rep stosd
pop edi
pop ecx
pop eax
ret



;***************************************
mge_compare:   ;cmp edi,esi
push eax
push ecx
push esi
push edi

mov ecx,[mge_nb_dw]
push ecx
shl ecx,2
add esi,ecx
add edi,ecx
pop ecx

@@:
sub esi,4
sub edi,4
mov eax,[esi]
cmp [edi],eax
jne @f
dec ecx
jnz @b

@@:
pop edi
pop esi
pop ecx
pop eax
ret



;***************************************
mge_addition:  ;edi=edi+esi
push eax
push ecx
push esi
push edi
mov ecx,[mge_nb_dw]
clc
pushf
@@:
popf
mov eax,[esi]
adc [edi],eax
pushf
add esi,4
add edi,4
dec ecx
jnz @b
popf
pop edi
pop esi
pop ecx
pop eax
ret



;***************************************
mge_soustraction: ;edi=edi-esi
push eax
push ecx
push esi
push edi
mov ecx,[mge_nb_dw]
clc
pushf
@@:
popf
mov eax,[esi]
sbb [edi],eax
pushf
add esi,4
add edi,4
dec ecx
jnz @b
popf
pop edi
pop esi
pop ecx
pop eax
ret


;***************************************
mge_decalp:    ;(x2)
push ecx
push edx
mov ecx,[mge_nb_dw]
clc
pushf
@@:
popf
rcl dword[edx],1
pushf
add edx,4
dec ecx
jnz @b
popf
pop edx
pop ecx
ret

;***************************************
mge_decalm:    ;(/2)
push ecx
push edx
mov ecx,[mge_nb_dw]
push ecx
dec ecx
shl ecx,2
add edx,ecx
pop ecx
clc
pushf
@@:
popf
rcr dword[edx],1
pushf
sub edx,4
dec ecx
jnz @b
popf
pop edx
pop ecx
ret

;*********************************************************************************
mge_hexa:
pushad
mov ebx,edx
mov ebp,edx
mov eax,[mge_nb_dw]
shl eax,2
add ebx,eax
@@:
sub ebx,4
mov al,103
mov ecx,[ebx]
mov edx,mge_temp1
int 61h
mov al,6
int 61h

cmp ebx,ebp
jne @b
popad
ret



;*********************************************************************************
mge_deci:
pushad

push dword "$"


mov esi,edx
mov edi,mge_temp3
call mge_copie

mov edi,mge_temp2
call mge_efface


@@:


mov byte[mge_temp2],10

mov esi,mge_temp3
mov edi,mge_temp2
call mge_divise


mov eax,[mge_temp3]
add eax,"0"
push eax

mov esi,mge_temp2
mov edi,mge_temp3
call mge_copie


mov edi,mge_temp2
call mge_efface

mov esi,mge_temp2
mov edi,mge_temp3
call mge_compare
jne @b


@@:
pop ecx
cmp ecx,"$"
je @f

mov [mge_temp1],cx

mov al,6
mov edx,mge_temp1
int 61h
jmp @b

@@:


popad
ret
