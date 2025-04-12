# SeaC
Systeme d'exploitation (operating system)

![](https://raw.githubusercontent.com/N-LG/SEAC/master/IMGWIKI/exemple1.png)

### [en]more information in the [wiki](https://github-com.translate.goog/N-LG/SEAC/wiki?_x_tr_sl=fr&_x_tr_tl=en&_x_tr_hl=fr&_x_tr_pto=wapp) automatically translated by Google Translate
channel dedicated to project developments on the discord server of [osdev](https://discord.com/channels/440442961147199490/1091753976443187222)

### [fr]voir dans le [wiki](https://github.com/N-LG/SEAC/wiki) pour plus d'info
salon dédié aux evolutions du projet sur le serveur discord de [devse](https://discord.com/channels/746454130448531546/1043677858301759528)

## organisation du dépot:
- ***compilation.bat*** scripte batch pour compiler le systeme (windows)
- ***compilation.sh*** scripte batch pour compiler le systeme (Gnu/Linux)
- ***makefile*** options pour make

- ***/ASM***: contient toutes les sources en assembleur
  - ***/BOOT*** bootloader
  - ***/NOYAU*** noyau 
  - ***/DEF*** fichiers de définitions
  - ***/PROG*** applications
  - 
- ***/BIN***: contient tout les binaires précompilé dont Fasm qui n'est pas sur ce dépot
  - ****.fe*** fichier executable du systeme
  - ****.baz*** code de base du noyau / fichier amorçable réseau
  - ****.imb*** fichier multiboot 1
  - ****.img*** image de disquette
  - ****.mbr*** code pour Master Boot Record
  - ****.def*** fichier de définition (clavier, messages, et polices de caractères matriciels)

- ***/C***: contient toutes les resources pour coder une application en C

- ***/IMGWIKI***: images pour illustrer cetrains parties du wiki

- ***/OUTILS***: outils de dévellopement
  - ***ajarch*** uttilisé pour créer le noyau (version windows et Gnu/Linux)
  - ***bootnet*** permet de booter en PXE (disponible que pour windows hélas)





