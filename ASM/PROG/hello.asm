pile equ 40960 ;definition de la taille de la pile
include "fe.inc"
db "traditionnel hello world"
scode:
org 0

mov ax,sel_dat1  ;choisi le segment de donn�e, ici le segment de donn�es N�1
mov ds,ax

mov al,6        ;fonction n�6: ecriture d'une chaine dans le journal
mov edx,msg1    ;adresse du message a afficher
int 61h         ;appel fonction systeme g�n�rales

int 60h         ;fin du programme

sdata1:   ;donn�es dans le segment de donn�e N�1
org 0

msg1:
db "bonjour tout le monde!",13,0   ;donn�e du message: chaine utf8 termin� par le caract�re 0

sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
