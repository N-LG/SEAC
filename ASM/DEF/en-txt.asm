;fichier de définition message systeme en anglais

org 0
db "DEFL"
dd messages_erreur,fin_messages
db "eng "   ;code du language iso 639-5


include "../NOYAU/DN_MSG_EN.ASM"



