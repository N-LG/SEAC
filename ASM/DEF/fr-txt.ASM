;fichier de définition message systeme en Français

org 0
db "DEFL"
dd messages_erreur,fin_messages
db "FR",0,0


include "../NOYAU/DN_MSG_FR.ASM"



