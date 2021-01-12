disquette.asm:
use16
org 0h
MBR:
mov ax,7C0h
mov ds,ax
mov ax,9000h        
mov ss,ax
xor esp,esp



mov ax,7E0h
mov es,ax
xor bx,bx
mov cx,2 ;on commence au deuxième secteur!
mov dh,0
mov dl,0 ;disquette
mov si,(fin_noyau-noyau+511)/512


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

cmp cl,19      ;nombre max de secteur+1
jne ok_secteur 
inc dh    ;on passe a la tête suivante si on as finis de lire tout les secteurs de la piste

cmp dh,2    ;nombre max de tête+1
jne ok_tete
inc ch ;on passe au cylindre suivant

mov dh,0 ;on revient a la première tête
ok_tete:

mov cl,1  ;et on revient au premier secteur
ok_secteur:




;incrémente l'adresse ou seront copié les données 
add bx,512
dec si
jz fin_chargement
cmp bx,0
jne boucle_gen

;déplace le selecteur de segment si on dépasse les capacités
mov ax,es
add ax,1000h
mov es,ax
jmp boucle_gen

fin_chargement:
mov si,messageok
call afmsg
jmp noyau


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
db 10,13,"lancement ok sur la disquette",0





rb 510 + MBR - $ 
db 055h,0AAh


noyau:
file "../../BIN/SEAC.BAZ"
fin_noyau:
rb 1474559 + MBR - $ 
db 0

