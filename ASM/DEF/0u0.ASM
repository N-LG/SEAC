db "DEFG"
db 8     ;largeur caractère (valeur possible: 8, 16, et 32)
db 16    ;hauteur caractère (valeur possible: 16 et 32)
dw 0     ;remplissage
dd 000h  ;numéros du premier caractère (doit etre aligné sur 256)
dd 0     ;remplissage


include "../NOYAU/DN_POLG.ASM"






