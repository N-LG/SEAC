codeMBR:  
;ce code d'amorçage charge le prmier secteur d'une partition marqué amorçable en 7c00h et saute sur celuis ci


;ce code utillise les fonctions du BIOS

type_part equ 30h


use16
org 7C00h
xor ax,ax
mov ds,ax
mov es,ax
mov ax,9000h        
mov ss,ax
mov sp,0FFF0h
mov [num_disque],dl ;dl=disque sur lequel le bios a booté



;test si la lecture des secteurs via fonction 42h est ok
mov ah,41h
mov dl,[num_disque]
mov bx,55AAh
int 13h
jnc newpc

;si non recupère les carac physique du disque
mov dl,[num_disque]
mov ah,8
int 13h
and cx,3Fh  ;cx=secteur par piste
mov [sec_piste],cx
xor ax,ax
mov al,dh   ;ax=nombre de tête
mul cx
mov [sec_cylindre],ax ;ax=nb de secteur par cylindre

newpc:




;recherche une partition d'un type spécial
mov si,1BEh+7C00h
test byte[si],80h  
jnz suite
add si,10h
test byte[si],80h  
jnz suite
add si,10h
test byte[si],80h  
jnz suite
add si,10h
test byte[si],80h  
jnz suite

mov si,messagerreur
call afmsg
infini:
jmp infini

suite: 
mov ebx,[si+8]    ;charge le premier secteur en 8000h
mov si,8000h
call chrg_sec




and byte[num_disque],0Fh
add byte[num_disque],"0"
mov si,messageok
call afmsg


mov si,7C00h     ;duplique le code en 7E00h
mov di,7E00h
mov cx,512
rep movsb
jmp 0000h:fin+200h ;et continue sur la version dupliqué

fin:
mov si,8000h      ;recopie le code précédamenct chargé a la bonne place
mov di,7C00h
mov cx,512
rep movsb
jmp 0000h:07C00h  ;et saute dessus!


;************************************************
;sous fonctions

afmsg:
mov al,[si]
cmp al,0
jne affiche
ret
affiche:
push ebx
mov ah,0Eh
mov bx,07h
int 10h
inc si
pop ebx
jmp afmsg


chrg_sec:    ;ebx=Numero de secteur es:si=zone ou copier
pushad
cmp word[sec_piste],0
jne oldpc

mov [ofsdap],si
mov ax,es
mov [segdap],ax
mov [adressedap],ebx

mov ah,42h
mov dl,[num_disque]
mov si,zt_dap
int 13h
jmp findec

oldpc:
mov ax,bx
xor dx,dx
mov cx,[sec_cylindre]
div cx
mov bx,ax  ;bx=cylindre
mov ax,dx
mov cl,[sec_piste] ;nb de secteur par piste
div cl
mov dh,al
mov cx,bx
xchg cl,ch
shl cl,6
and cl,0C0h
inc ah
and ah,03Fh
or cl,ah
mov bp,5
mov bx,si
alfq: 
mov al,1
mov ah,2
mov dl,[num_disque]
int 13h
jnc findec
dec bp
jnz alfq
findec:
popad
ret


messagerreur:
db 10,13,"pas de partition amorçable detect",82h,0
messageok:
db 10,13,"lancement ok sur 8"
num_disque:
db 0,0


sec_piste:
dw 0
sec_cylindre:
dw 0


zt_dap:
db 10h
db 0
dw 1
ofsdap:
dw 0
segdap:
dw 0
adressedap:
dd 0,0



;82h = é

;8Ah = è

;88h = ê


