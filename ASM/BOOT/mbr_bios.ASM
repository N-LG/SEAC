codeMBR:  
;ce code d'amorçage recherche la présence d'une partition de type 30h dans la table du MBR,
;charge les 128 premiers kilo octet de la première partition 30h trouvé en 5000h:0000h 
;saute vers 5000h:0000h


;ce code utillise les fonctions du BIOS

type_part equ 30h


use16
org 0h
mov ax,7C0h
mov ds,ax
mov ax,9000h        
mov ss,ax
xor esp,esp
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
mov si,1C2h
cmp byte[si],type_part  
je suite
add si,10h
cmp byte[si],type_part  
je suite
add si,10h
cmp byte[si],type_part  
je suite
add si,10h
cmp byte[si],type_part  
je suite

mov si,messagerreur
call afmsg
infini:
jmp infini

suite: 
mov ebx,[si+4]
mov ax,5000h             ;charge les 256 premiers secteurs de la partition (128ko) de 5000h:0000h à 6000h:FFFFh
mov es,ax
xor si,si


boucle_chargement:
call chrg_sec
inc ebx
add si,200h
cmp si,0
jne boucle_chargement

mov ax,6000h             
mov es,ax

boucle_chargement2:
call chrg_sec
inc ebx
add si,200h
cmp si,0
jne boucle_chargement2

and byte[num_disque],0Fh
add byte[num_disque],"0"


mov si,messageok
call afmsg
jmp 5000h:0000h ;saute sur la partition

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
db 10,13,"pas de partition de type 30h detect",82h,0
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


