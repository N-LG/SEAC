;fichier de définition message systeme en anglais

org 0
db "DEFL"
dd messages_erreur,fin_messages
db "EN",0,0


include "../NOYAU/DN_MSG_EN.ASM"



