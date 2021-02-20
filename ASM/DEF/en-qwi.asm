;fichier de définition pour clavier us international

org 0
db "DEFC"
dw touche_codeps2       ;adresse de la définition PS/2
dw 0                    ;adresse de la définition usb
dw touche_carac         ;adresse de la définition clavier principale
dw 0                    ;adresse de la définition clavier secondaire
dw 0                    ;adresse de la définition chasse
db 0,0                  ;numéros de touches a employer avec la touche CTRL pour basculer d'un jeu de carractère a un autre


include "../NOYAU/DN_CLAV_USI.ASM"

