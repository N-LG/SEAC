db "DEFG"
db 8     ;largeur caract�re (valeur possible: 8, 16, et 32)
db 16    ;hauteur caract�re (valeur possible: 16 et 32)
dw 0     ;remplissage
dd 000h  ;num�ros du premier caract�re (doit etre align� sur 256)
dd 0     ;remplissage


include "../NOYAU/DN_POLG.ASM"






