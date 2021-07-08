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
db "sup #dd1/SEAC.EFI",10,3
db "cop SEAC.EFI #dd1/SEAC.EFI",10,3

fin_fichier1:

rb 16 - ($ - zone1)mod 16        ;remplissage pour faire que le fichier ai une granularité de 16 octets
 
fin_zone1:









;marqueur de fin de l'archive
db "DMF?"
dd 0,0,0
