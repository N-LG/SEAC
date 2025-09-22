;fichier de définition message systeme en Français

org 0
db "DEFL"
dd messages_erreur,fin_messages
db "fra "   ;code du language iso 639-5


include "../NOYAU/DN_MSG_FR.ASM"



