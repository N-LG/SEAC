etage4:
org 0h

;etage 4: fichiers optionnels




zone1:
dd "DMX?"
dd fin_zone1-zone1                  ;taille de la zone mémoire utilisé par le fichier
dd fin_fichier1-fichier1            ;taille réelle du fichier
dd 0                                ;réservé 
db "cfg.sh"                         ;nom du fichier
rb 416 - ($ - zone1)mod 416         ;remplissage pour faire une entête de 416 octet

fichier1:
db "rtl8139",10,13
db "3c90x",10,13
db "I8254X",10,13
db "*",10,13
db "stftp #dm -w",10,13
db "shttp #dm",10,13
db "stlnt",10,13
db "ipconfig 0 comp 192.168.1.200 255.255.255.0 192.168.1.1 0:0:0:0:0:0:0:0 0:0:0:0:0:0:0:0",10,13
;db "ipconfig 1 comp 192.168.1.201 255.255.255.0 192.168.1.1 0:0:0:0:0:0:0:0 0:0:0:0:0:0:0:0",10,13
db "*",10,13
db "af ",10,13
db "af pour un rappel des principales commandes disponible,",10,13
db "af entrez la commande «man commandes»",10,13
;db "cd #dd3",10,13
;db "dcp test5.zip -e",10,13
;db "dcp fasm-1.73.08.tgz -e",10,13
;db "dcp fasm-1.73.08.TAR -e",10,13
;db "*",10,13
;db "*",10,13
;db "*",10,13
;db "*",10,13
;db "*",10,13
;db "edh fasm-1.73.08.TAR -e",10,13

fin_fichier1:

rb 16 - ($ - zone1)mod 16        ;remplissage pour faire que le fichier ai une granularité de 16 octets
 
fin_zone1:









;marqueur de fin de l'archive
db "DMF?"
dd 0,0,0
