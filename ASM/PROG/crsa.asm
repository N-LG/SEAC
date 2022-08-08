pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "tentative de factoriser un grand nombre"
scode:
org 0



taille_nombre equ 256    ;les nombres font 256 octet en big endian



mov ax,sel_dat1
mov ds,ax


;lit le nom du fichier
mov al,4
mov ah,0   ;1er argument
mov edx,nom_fichier
mov cl,0    ;256 octet
int 61h


;ouvre le fichier
mov al,1
mov edx,nom_fichier
int 64h
cmp eax,0
jne errouvf

;lit les données du fichier
mov al,4
mov edx,0
mov ecx,2047
mov edi,zt_fichier
int 64h
cmp eax,0
jne errouvf


;convertit le texte en nombre
mov esi,zt_fichier
mov edi,nombrek
call conv_tb        ;converti la chaine en binaire


mov esi,nombrek
call affiche2048
int 60h




;mov si,nombrek
;call bcdp
;mov al,"#"
;mov ah,0Ah
;int 84h          

mov si,nombrek
call raccar             ;cherche la racine carr‚
mov si,carresup         ;et prend l'entier imm‚diatement superieur
mov di,nombrea
call depln

;********************************

bouclep: 

mov si,nombrea
mov bx,nombrea
mov di,nombrea2        ;pour trouver le carr‚ imm‚diatement superieur
call multi

mov si,nombrek
mov di,temp1
call depln
mov si,temp1
call negatif
mov si,temp1
mov bx,nombrea2
mov di,temp1
call addition          ;calcul la diff‚rence entre le carr‚ imm‚diatement 
                       ;superieur et K

mov si,temp1
call raccar            ;cherche la racine carr‚ de cette valeur
mov si,carreinf        ;et prend la valeur imm‚diatement inferieur
mov di,nombrec
call depln
mov si,nombrec
mov bx,nombrec
mov di,nombrec2k
call multi            ;calcul ce carr‚
mov si,nombrec2k
mov bx,nombrek
mov di,nombrec2k
call addition        ;et l'additionne a K

;********************
;!!!!!!!!!!!!!!!!!!int 88h
cmp ah,00h
je pascla
mov si,nombrea
call bcdp
mov al,"#"
mov ah,0Ch
;!!!!!!!!!!!!!!!!!int 84h          
mov si,nombrec
call bcdp
mov al,"#"
mov ah,0Ah
;!!!!!!!!!!!!!!!!!!!!int 84h          
pascla:
;********************

mov si,nombrea2
mov di,nombrec2k
call comp
cmp al,0
je actrouv

mov si,nombrea   ;sino incr‚mente nombrea
mov bx,neg1      ;constante, valeur: 1
mov di,nombrea
call addition
jmp bouclep


actrouv:
mov si,nombrea
mov bx,nombrec
mov di,apc
call addition
mov si,nombrec
call negatif
mov si,nombrea
mov bx,nombrec
mov di,amc
call addition

mov al,"!"
mov ah,0Ah
;!!!!!!!!!!!!!!!!!!!int 84h          
mov si,apc
call bcdp
mov al,"&"
mov ah,0Ch
;!!!!!!!!!!!!!!!!!!!!!!!!int 84h          
mov si,amc
call bcdp
mov al,07
mov ah,0Ah
;!!!!!!!!!!!!!!!!!!!!!!!int 84h          
mov al,10
mov ah,0Ah
;!!!!!!!!!!!!!!!!!!!!!int 84h          
mov al,13
mov ah,0Ah
;!!!!!!!!!!!!!!!!!int 84h          
mov al,"T"
mov ah,0Ah
;!!!!!!!!!!!!!!!!int 84h          



int 60h




errouvf:
mov al,6
mov edx,msger1
int 61h



int 60h




;**********************************************************************************************
conv_tb: ;converti chaine en ds:esi en nombre 2048b en ds:edi


push esi
mov esi,zero
call depln


mov esi,zero
mov edi,temp1
call depln
pop esi

boucle_conv_tb:
mov al,[esi]
sub al,"0"
cmp al,9
ja fin_conv_tb

push esi
mov esi,edi
mov ebx,dix
call multi


mov [temp1],al
mov ebx,temp1
call addition
pop esi

inc esi
jmp boucle_conv_tb

fin_conv_tb:
ret






;********************************************************************************
depln:   ;deplacer nombre   ds:esi a ds:edi
push ecx
push esi
push edi
push es
cmp edi,esi
je pasdepl
mov cx,ds
mov es,cx
mov ecx,100h
rep movsb
pasdepl:
pop es
pop edi
pop esi
pop ecx
ret

;************************************************************************************
negatif:   ;compl‚mente a 2 de ds:si
push bx
push cx
push si
push di
push si
mov cx,40h
bneg:
not dword[si]
add si,4
dec cx
jnz bneg
pop si
mov di,si
mov bx,neg1
call addition
pop di
pop si
pop cx
pop bx
ret



;*****************************************************************************************
addition:  ;additionne ds:si a ds:bx et met le r‚sultat dans ds:di
push eax
push ebx
push cx
push si
push di
call depln
clc
pushf
mov cx,40h
baddition:
mov eax,[bx]
popf
adc [di],eax
pushf
add bx,4
add di,4
dec cx
jnz baddition
popf
pop di
pop si
pop cx
pop ebx
pop eax
ret



;******************************************************************************************
multi:  ;multiplie ds:esi a ds:ebx et met le résultat dans ds:edi
push eax
push ebx
push ecx
push esi
push edi





push edi
mov edi,multi1
call depln
mov esi,ebx
mov edi,multi2
call depln
pop edi
mov ebx,edi
xor eax,eax
mov ecx,40h
bmulti1:    ;met a zéro le résultat
mov [bx],eax
add bx,4
dec ecx
jnz bmulti1
mov ecx,800h
bmulti2:
test byte[multi1],01h
jz pasaddition
mov si,di
mov bx,multi2
call addition

pasaddition:
mov bx,multi1
call div2
mov bx,multi2
call double
dec cx
jnz bmulti2

pop di
pop si
pop cx
pop bx
pop eax
ret



;************************************************************************************
comp: ;comparaison de ds:si par rapport a ds:di
      ;al=0 égale =1 inferieur =2 supérieur
push cx
push si
push di
push eax
add si,0FCh
add di,0FCh
mov cx,40h
bcomp:
mov eax,[si]
cmp eax,[di]
jne nonegal
sub di,4
sub si,4
dec cx
jnz bcomp
pop eax
mov al,0
pop di
pop si
pop cx
ret

nonegal:
cmp eax,[di]
ja nsup
pop eax
mov al,1
pop di
pop si
pop cx
ret

nsup:
pop eax
mov al,2
pop di
pop si
pop cx
ret



;***********************************************************************************
raccar:   ;racine carr‚  source ds:si 

mov di,carreo   ;met carr‚ origine a la valeur initial
call depln


mov bx,carreinf   ;met a z‚ro carr‚inf et carresup
xor eax,eax
mov cx,80h
braccar1:    
mov [bx],eax
add bx,4
dec cx
jnz braccar1
;cherche le premier bit a 1 dans carre0
mov bx,carreo
add bx,100h
recpbit:
dec bx
cmp byte[bx],0
je recpbit
mov al,[bx]
sub bx,carreo
shr bx,1
add bx,carresup+1
mov [bx],al



braccar2:

mov si,carreinf   ;additionne carr‚inf et carresup
mov bx,carresup
mov di,carre
call addition
mov bx,carre   ;divise par deux  pour faire la moyenne
call div2

mov si,carreinf
mov di,carre
call comp
cmp al,0
je carretrouve1    ;si la moyenne est ‚gale au carreinf c'est que carresup=carreinf+1

mov si,carre ;calcul le carr‚
mov bx,carre
mov di,carre2
call multi

;compare
mov si,carreo
mov di,carre2
call comp

cmp al,0  ;si ‚gale=trouv‚
je carretrouve2
cmp al,2  ;si plus grand carr‚inf prend la valeur de carr‚
je carreplus
;cmp al,1  ;si plus petit carr‚sup prend la valeur de carr‚
mov si,carre
mov di,carresup
call depln
jmp braccar2

carreplus:
mov si,carre
mov di,carreinf
call depln
dec cx
jmp braccar2

carretrouve2: ;‚galit‚ trouv‚ carreinf et carresup prennent la valeur de carre
mov si,carre
mov di,carresup
call depln
mov si,carre
mov di,carreinf
call depln

carretrouve1:
ret



;********************************************************************************
divise: ;divise ds:si par ds:di

push di   ;initialiser le nombre a diviser
mov di,ledivise
call depln

pop si   ;initialiser le diviseur interm‚diaire  
mov di,diviseurinter
call depln

;initialiser le quotient intem‚diaire
mov si,un
mov di,quotientinter
call depln

;mettre le quotient a z‚ro
mov bx,quotient
xor eax,eax
mov cx,40h
bdivise1:    
mov [bx],eax
add bx,4
dec cx
jnz bdivise1

;doubler le diviseur et quotient intem‚diaire N fois jusqu'a ce que msbDI=1
bdivise2:    
mov bx,quotientinter
call double
mov bx,diviseurinter
call double
test byte[diviseurinter+0FFh],80h
jz bdivise2


bdivise3:
;comparer le nombre a diviser par le diviseur interm‚diaire
mov si,ledivise
mov di,diviseurinter
call comp
;si inf‚rieur ne rien faire
cmp al,1
je divisenrf

;retirer le diviseur interm‚diaire au nombre a diviser
mov si,diviseurinter
mov di,negdiviseurinter
call depln
mov si,negdiviseurinter
call negatif
mov si,ledivise
mov bx,negdiviseurinter
mov di,ledivise
call addition

;ajouter le quotient interm‚diaire au quotient
mov si,quotient
mov bx,quotientinter
mov di,quotient
call addition

divisenrf:
test byte[quotientinter],01b
jnz findivise
mov bx,quotientinter
call div2
mov bx,diviseurinter
call div2
jmp bdivise3

findivise:
;charger le nombre a diviser dans le reste
mov si,ledivise
mov di,reste
call depln
ret


;*******************************************************************************
affiche2048:
mov di,nombreaffiche
call depln

xor ax,ax
mov al,"$"
push ax

baf20481:
mov si,nombreaffiche
mov di,dix
call divise
mov ax,[reste]
add al,"0"
push ax
mov si,quotient
mov di,nombreaffiche
call depln
mov si,nombreaffiche
mov di,zero
call comp
cmp al,0
jne baf20481

baf20482:
pop ax
cmp al,"$"
je finaf2048
mov ah,07h
;??????????????????????????????int 84h
jmp baf20482
finaf2048:
ret











double: ;multiplie par 2 ds:ebx
clc
rcl dword[ebx],1
rcl dword[ebx+004h],1
rcl dword[ebx+008h],1
rcl dword[ebx+00Ch],1
rcl dword[ebx+010h],1
rcl dword[ebx+014h],1
rcl dword[ebx+018h],1
rcl dword[ebx+01Ch],1
rcl dword[ebx+020h],1
rcl dword[ebx+024h],1
rcl dword[ebx+028h],1
rcl dword[ebx+02Ch],1
rcl dword[ebx+030h],1
rcl dword[ebx+034h],1
rcl dword[ebx+038h],1
rcl dword[ebx+03Ch],1
rcl dword[ebx+040h],1
rcl dword[ebx+044h],1
rcl dword[ebx+048h],1
rcl dword[ebx+04Ch],1
rcl dword[ebx+050h],1
rcl dword[ebx+054h],1
rcl dword[ebx+058h],1
rcl dword[ebx+05Ch],1
rcl dword[ebx+060h],1
rcl dword[ebx+064h],1
rcl dword[ebx+068h],1
rcl dword[ebx+06Ch],1
rcl dword[ebx+070h],1
rcl dword[ebx+074h],1
rcl dword[ebx+078h],1
rcl dword[ebx+07Ch],1
rcl dword[ebx+080h],1
rcl dword[ebx+084h],1
rcl dword[ebx+088h],1
rcl dword[ebx+08Ch],1
rcl dword[ebx+090h],1
rcl dword[ebx+094h],1
rcl dword[ebx+098h],1
rcl dword[ebx+09Ch],1
rcl dword[ebx+0A0h],1
rcl dword[ebx+0A4h],1
rcl dword[ebx+0A8h],1
rcl dword[ebx+0ACh],1
rcl dword[ebx+0B0h],1
rcl dword[ebx+0B4h],1
rcl dword[ebx+0B8h],1
rcl dword[ebx+0BCh],1
rcl dword[ebx+0C0h],1
rcl dword[ebx+0C4h],1
rcl dword[ebx+0C8h],1
rcl dword[ebx+0CCh],1
rcl dword[ebx+0D0h],1
rcl dword[ebx+0D4h],1
rcl dword[ebx+0D8h],1
rcl dword[ebx+0DCh],1
rcl dword[ebx+0E0h],1
rcl dword[ebx+0E4h],1
rcl dword[ebx+0E8h],1
rcl dword[ebx+0ECh],1
rcl dword[ebx+0F0h],1
rcl dword[ebx+0F4h],1
rcl dword[ebx+0F8h],1
rcl dword[ebx+0FCh],1
ret





div2: ;divise par 2 ds:ebx
clc
rcr dword[ebx+0FCh],1
rcr dword[ebx+0F8h],1
rcr dword[ebx+0F4h],1
rcr dword[ebx+0F0h],1
rcr dword[ebx+0ECh],1
rcr dword[ebx+0E8h],1
rcr dword[ebx+0E4h],1
rcr dword[ebx+0E0h],1
rcr dword[ebx+0DCh],1
rcr dword[ebx+0D8h],1
rcr dword[ebx+0D4h],1
rcr dword[ebx+0D0h],1
rcr dword[ebx+0CCh],1
rcr dword[ebx+0C8h],1
rcr dword[ebx+0C4h],1
rcr dword[ebx+0C0h],1
rcr dword[ebx+0BCh],1
rcr dword[ebx+0B8h],1
rcr dword[ebx+0B4h],1
rcr dword[ebx+0B0h],1
rcr dword[ebx+0ACh],1
rcr dword[ebx+0A8h],1
rcr dword[ebx+0A4h],1
rcr dword[ebx+0A0h],1
rcr dword[ebx+09Ch],1
rcr dword[ebx+098h],1
rcr dword[ebx+094h],1
rcr dword[ebx+090h],1
rcr dword[ebx+08Ch],1
rcr dword[ebx+088h],1
rcr dword[ebx+084h],1
rcr dword[ebx+080h],1
rcr dword[ebx+07Ch],1
rcr dword[ebx+078h],1
rcr dword[ebx+074h],1
rcr dword[ebx+070h],1
rcr dword[ebx+06Ch],1
rcr dword[ebx+068h],1
rcr dword[ebx+064h],1
rcr dword[ebx+060h],1
rcr dword[ebx+05Ch],1
rcr dword[ebx+058h],1
rcr dword[ebx+054h],1
rcr dword[ebx+050h],1
rcr dword[ebx+04Ch],1
rcr dword[ebx+048h],1
rcr dword[ebx+044h],1
rcr dword[ebx+040h],1
rcr dword[ebx+03Ch],1
rcr dword[ebx+038h],1
rcr dword[ebx+034h],1
rcr dword[ebx+030h],1
rcr dword[ebx+02Ch],1
rcr dword[ebx+028h],1
rcr dword[ebx+024h],1
rcr dword[ebx+020h],1
rcr dword[ebx+01Ch],1
rcr dword[ebx+018h],1
rcr dword[ebx+014h],1
rcr dword[ebx+010h],1
rcr dword[ebx+00Ch],1
rcr dword[ebx+008h],1
rcr dword[ebx+004h],1
rcr dword[ebx],1
ret




sdata1:
org 0



msg1:
db "conversion ok",0


msger1:
db "erreur de lecture fichier",0



nom_fichier:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet


zt_fichier:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;128 octet


zero:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

un:
dd 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

dix:
dd 10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet


temp1:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
temp2:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
temp3:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
temp4:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet














nombrek:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
nombrea:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
nombrea2:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
nombrec:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
nombrec2k:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
apc:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
amc:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet







;Name:         RSA-2048
;Digits:       617
;Digit Sum:    2738
myst1:
db "25195908475657893494027183240048398571429282126204032027777137836043662"
db "02070759555626401852588078440691829064124951508218929855914917618450280"
db "84891200728449926873928072877767359714183472702618963750149718246911650"
db "77613379859095700097330459748808428401797429100642458691817195118746121"
db "51517265463228221686998754918242243363725908514186546204357679842338718"
db "47744479207399342365848238242811981638150106748104516603773060562016196"
db "76256133844143603833904414952634432190114657544454178424020924616515723"
db "35077870774981712577246796292638635637328991215483143816789988504044536"
db "4023527381951378636564391212010397122822120720357"
db "$"

;Name:         RSA-1024
;Digits:       309
;Digit Sum:    1369
myst2:
db "13506641086599522334960321627880596993888147560566702752448514385152651"
db "06048595338339402871505719094417982072821644715513736804197039641917430"
db "46496589274256239341020864383202110372958725762358509643110564073501508"
db "18751067659462920556368552947521350085287941637732853390610975054433499"
db "9811150056977236890927563"
db "$"

;RSA-768 = 12301866845301177551304949583849627207728535695953347921973224521517264005
;          07263657518745202199786469389956474942774063845925192557326303453731548268
;          50791702612214291346167042921431160222124047927473779408066535141959745985
;          6902143413
;
;RSA-768 = 33478071698956898786044169848212690817704794983713768568912431388982883793
;          878002287614711652531743087737814467999489
;        X 36746043666799590428244633799627952632279158164343087642676032283815739666
;          511279233373417143396810270092798736308917

;Name:         RSA-768
;Digits:       232
;Digit Sum:    1018
myst3:
db "12301866845301177551304949583849627207728535695953347921973224521517264"
db "00507263657518745202199786469389956474942774063845925192557326303453731"
db "54826850791702612214291346167042921431160222124047927473779408066535141"
db "9597459856902143413"
db "$"

myst4:
db "456789777$46878475241321213465468798546546231318$"

myst5:
db "1234567890123456789876543210$"







nombreaffiche:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet




quotientinter:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

diviseurinter:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

negdiviseurinter:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

ledivise:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

quotient:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

reste:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet


carreo:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

carre:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

carre2:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

carreinf:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

carresup:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

multi1:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
multi2:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet

neg1:
dd 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet


conv1:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64 octet



sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:

