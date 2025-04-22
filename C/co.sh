#efface le dernier fichier
rm $1.FE

# option de GCC utillisÃ© ici 
#-std=gnu90  //norme du language (au choix)
#-march=i386 //famille du processeur cible
#-m32        //processeur en 32bits (indispensable)
#-nostdlib   //pas besoin de stdlib (indispensable)
#-e _start   //spÃ©cfie le point d'entrÃ©e (indispensable)
#-o $1.FE    //nom du fichier de sortie(doit Ãªtre en majuscule avec l'extension FE)          
#-s          //enlÃ¨ve les table de symbole et de relocation (gagne de l'espace)
#-fno-asynchronous-unwind-tables //enlÃ¨ve  (gagne de l'espace)
#-Wl         //option du linkage sÃ©parÃ© par des virgules
#-c          //pas de linkage (inutilisÃ© ici)

# option de LD utillisÃ© ici
#--nmagic         //dÃ©sactive l'alignement par page (gagne de l'espace)
#--strip-all      //ne met pas les infos pour le dÃ©buggeure (gagne de l'espace)
#--script=seac.ld //script de linkage a employer (indispensable)


#compilation et linkage
gcc -std=gnu90 -m32 -march=i386  -nostdlib -e _start -fno-asynchronous-unwind-tables -s -o $1.FE -Wl,--nmagic,--strip-all,--script=includes/seac.ld $1.C includes/base_seac.s

#affiche des infos sur le fichier compilÃ©
#readelf -S -l $1.FE

#envoyer le rÃ©sultat de la compilation a un pc qui a dÃ©marrÃ© SEAC 
#tftp -4 192.168.1.200 -m binary -c put $1.FE

