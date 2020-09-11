codeMBR:  
;ce code d'amorçage recherche la présence d'une partition de type 30h dans la table du MBR,
;recherche l'adresse du disque
;charge les 128 premiers kilo octet de la première partition 30h trouvé en 5000h:0000h 
;saute vers 5000h:0000h


;ce code utillise pilote directement le disque ATA, a utiliser lorsque que les fonction bios ne prenne pas en charge ce type de disque

type_part equ 30h

use16
org 0h
mov ax,7C0h
mov ds,ax
mov es,ax
mov ax,9000h        
mov ss,ax
xor esp,esp

mov bp,1C2h

cmp byte[bp],type_part  
je suite
add bp,10h
cmp byte[bp],type_part  
je suite
add bp,10h
cmp byte[bp],type_part  
je suite
add bp,10h
cmp byte[bp],type_part  
je suite


mov si,messagerreur1
call afmsg
infini:
jmp infini





suite: 
mov ch,0
boucle_rech_disque:
mov si,200
xor ebx,ebx
call chrg_sec

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


inc ch
cmp ch,8
jne boucle_rech_disque

mov si,messagerreur2
call afmsg
jmp infini  


disque_trouve:
mov ax,5000h             ;charge les 256 premiers secteurs de la partition (128ko) de 5000h:0000h à 6000h:FFFFh
mov es,ax
xor si,si
mov ebx,[bp+4]

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

mov si,messageok
call afmsg

jmp 5000h:0000h   ;saute sur la partition


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


chrg_sec:    ;ebx=Numero de secteur es:si=zone ou copier ch=numeros de disque

;call ajuste_lba!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
jc err_chrg_sec
mov esi,edi
;call iniata!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
jc err_chrg_sec

mov al,020h        ;envoye la commande
mov dx,7
add dx,di
out dx,al

xor bl,bl



;call at1puls!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;call attdok!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
jc err_chrg_sec

mov dx,di
recomf24:
in ax,dx
es
mov [si],ax
dec bl
add si,2
cmp bl,0
jne recomf24


err_chrg_sec:
ret






messagerreur1:
db 10,13,"partition non trouv",82h,0

messagerreur2:
db 10,13,"disque non trouv",82h,0

messageok:
db 10,13,"lancement ok"








;82h = é

;8Ah = è

;88h = ê


