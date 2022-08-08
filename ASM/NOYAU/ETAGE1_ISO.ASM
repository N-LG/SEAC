cdrom:     ;voir chapitre2.5 de la spec "el torito" pour avoir le descriptif des tables
use16
org 0h


rb 16*2048
secteur_iso9660:           ;primary volume descriptor https://wiki.osdev.org/ISO_9660
db 1,"CD001",1,0
rb 32  ;system identifier
rb 32  ;volume identifier
rb 8  ;innutilisé
rb 8  ;nomre de secteur du volume
rb 32  ;innutilisé
dw 0,0 ;
dw 0,0 ;
dw 0,0 ;
dd 0,0 ;
dd 0   ;
dd 0   ;
dd 0   ;
dd 0   ;
rb 34  ;
rb 128 ;
rb 128 ;
rb 128 ;
rb 128 ;
rb 37  ;
rb 37  ;
rb 37  ;
rb 17  ;
rb 17  ;
rb 17  ;
rb 17  ;
db 1   ;version
db 0   ;innutilisé








rb 2048 + secteur_iso9660 - $ 

secteur_eltorito:     ;secteur de boot
db 0
db "CD001"
db 1
db "EL TORITO SPECIFICATION"
rb 41
dd 18   ;numéro du secteur ou se trouve le catalogue

rb 2048 + secteur_eltorito - $ 

secteur_catalogue:  

;validation entry pour x86
dd 1,0,0,0,0,0,0
db 0AAh,055h,055h,0AAh

;entrée par defaut
db 88h       ;signale que boutable
db 2         ;type d'emulation (2=disquette)
dw 0         ;segment ou charger l'image
db 0         ;system type
db 0         ;innutilisé
dw 720       ;nombre de secteur de l'image
dd 19        ;adresse du secteur ou commence limage 
dd 0,0,0,0,0 ;innutilisé

;entrée finale
dd 91h,0,0,0
dd 0,0,0,0

rb 2048 + secteur_catalogue - $ 


secteur_fichier_image:
file "../../BIN/SEAC.IMG"

