codeMBR:  
;ce code d'amorçage recherche la présence d'une partition de type 30h dans la table du MBR,
;charge les 256 premiers kilo octet  a partir du 2eme secteur du disque 
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


mov ax,5000h
mov es,ax
xor bx,bx
mov cx,2 ;on commence au deuxième secteur!
mov dh,0
mov dl,[num_disque] 



boucle_gen:


;lit le secteur en es:si, réesaye de lire 5 fois en cas d'erreur
mov bp,5
ressaye_lec:

mov ah,2  ;lecture secteur
mov al,1  ;un seul secteur
;dh=tête
;dl=numéros de disque
;cl=secteur + MSB du cylindre/piste
;ch=LSB du cylindre/piste
push cx
push dx
int 13h
pop dx
pop cx
jnc fin_ok_lec
dec bp
jnz ressaye_lec
fin_ok_lec:


;incrémente l'adresse CHS pour passer au secteur suivant
inc cl
cmp cl,64
jne ok_adresse 
inc dh    ;on passe a la tête suivante si on as finis de lire tout les secteurs de la piste
mov cl,1  ;et on revient au premier secteur
ok_adresse:




;incrémente l'adresse ou seront copié les données 
add bx,512
cmp bx,0
jne boucle_gen

;déplace le selecteur de segment si on dépasse les capacités
mov ax,es
add ax,1000h
mov es,ax
cmp ax,9000h
jne boucle_gen




and byte[num_disque],0Fh
add byte[num_disque],"0"
mov byte[num_disque+1],"h"

mov si,messageok
call afmsg
jmp 5000h:0000h ;saute sur la partition


erreur_de_lecture:
mov si,messagerreur
call afmsg
infini:
jmp infini










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




messagerreur:
db 10,13,"erreur de lecture...",0
messageok:
db 10,13,"lancement ok sur le disque 8"
num_disque:
dd 0



;82h = é

;8Ah = è

;88h = ê


