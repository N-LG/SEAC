# SeaC
Systeme d'exploitation (operating system)
![](https://raw.githubusercontent.com/N-LG/SEAC/master/IMGWIKI/exemple1.png)

### [en]more information in the [wiki](https://github-com.translate.goog/N-LG/SEAC/wiki?_x_tr_sl=fr&_x_tr_tl=en&_x_tr_hl=fr&_x_tr_pto=wapp) automatically translated by Google Translate

### [fr]voir dans le [wiki](/wiki) pour plus d'info

# 
organisation du dépot:

ASM: contient toutes les sources en assembleur  
    ASM/NOYAU noyau  
    ASM/BOOT bootloader  
    ASM/PROG applications  
    ASM/DEF fichier de définitions  
    ASM/compilation.bat scripte batch pour compiler le systeme (windows)
    ASM/compilation.sh scripte batch pour compiler le systeme (Gnu/Linux)
    
BIN: contient tout les binaires précompilé dont Fasm qui n'est pas sur ce dépot  
    *.fe fichier executable du systeme  
    *.baz code de base du noyau / fichier amorçable réseau  
    *.imb fichier multiboot 1  
    *.img image de disquette  
    *.mbr code pour Master Boot Record  
    *.def fichier de définition (clavier, message, et caractères matriciels)

IMGWIKI: images pour illustrer cetrains parties du wiki

OUTILS: outils de dévellopement
    *ajarch uttilisé pour créer le noyau (version windows et Gnu/Linux)
    *bootnet permet de booter en PXE (disponible que pour windows hélas)





