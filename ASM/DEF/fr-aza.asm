;fichier de d�finition pour clavier us international

org 0
db "DEFC"
dw touche_codeps2       ;adresse de la d�finition PS/2
dw touche_usb           ;adresse de la d�finition usb
dw touche_carac         ;adresse de la d�finition clavier principale
dw 0                    ;adresse de la d�finition clavier secondaire
dw 0                    ;adresse de la d�finition chasse
db 0,0                  ;num�ros de touches a employer avec la touche CTRL pour basculer d'un jeu de carract�re a un autre


include "../NOYAU/DN_CLAV_FR.ASM"

