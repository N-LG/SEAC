cdrom:    ;image disque amorçable, a la fois pour cdrom et pour disque dur 
use16
org 0h




;macro pour la génération de donnée spécifique a iso9660


;doubles dw 
macro dwlm v
 {
        dw v
        db (v shr 8)
        db (v and 0xFF)
 }


;double dd
macro ddlm v
 {
        dd v
        db ((v shr 24) and 0xFF)
        db ((v shr 16) and 0xFF)
        db ((v shr  8) and 0xFF)
        db (v and 0xFF)
}














;*******************************************************
;partie pour démarrer sur disque dur 
MBR:
file "../../BIN/BIOS.MBR"


rb 446 + MBR - $ 
;partition de protection du systeme de fichier iso9660 (finalement inutile)
;db 0      ;partition bootable?
;db 0,0,0  ;coordonnée CHS
;db 031h    ;type de partition(bidon)
;db 0,0,0  ;coordonné CHS de fin
;dd 1 ;adresse de début
;dd (secteur_partition_boot/512)-1 ;taille

;partition contenant l'image boutable
db 0      ;partition bootable?
db 0,0,0  ;coordonnée CHS
db 030h   ;type de partition (30h=partition image boot seac)
db 0,0,0  ;coordonné CHS de fin
dd secteur_partition_boot/512 ;adresse de début
dd ((finsecteur_partition_boot-secteur_partition_boot)/512) ;taille



rb 510 + MBR - $ 
db 055h,0AAh













rb 16*2048-$





secteur_iso9660:           ;primary volume descriptor https://wiki.osdev.org/ISO_9660
db 1,"CD001",1,0
rb 32  ;system identifier
rb 32  ;volume identifier
rb 8   ;innutilisé
ddlm (fin_image_iso/2048)   ;nombre de secteur du volume
rb 32  ;innutilisé
dw 0,0 ;
dw 0,0 ;
dw 0,0 ;
dd 0,0 ;
dd 0   ;
dd 0   ;
dd 0   ;
dd 0   ;

;descripteur du dossier racine
db 34,0 ;longueur descripteur
ddlm (secteur_dossier/2048);position fichier
ddlm (fin_secteur_dossier-secteur_dossier) ;taille fichier
db 85,4,28,12,20,0,4
db 0,0,0 ;attributs
dwlm 0 ;numéros de volume
db 10 ;taille du nom du fichier
db 0


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








;voir chapitre2.5 de la spec "el torito" pour avoir le descriptif des tables



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

;sans emulation
;db 88h       ;signale que boutable
;db 0         ;type d'emulation (0=sans)
;dw 7E0h      ;segment ou charger l'image
;db 0         ;system type
;db 0         ;innutilisé
;dw (finsecteur_partition_boot-secteur_partition_boot)/2048      ;nombre de secteur chargé au démarrage
;dd secteur_partition_boot/2048       ;adresse du secteur ou commence l'image 
;dd 0,0,0,0,0 ;innutilisé

;emulation de disque dur
;db 88h       ;signale que boutable
;db 4         ;type d'emulation (4=disque dur)
;dw 0         ;segment ou charger l'image
;db 0         ;system type
;db 0         ;innutilisé
;dw finsecteur_partition_boot/2048      ;nombre de secteur chargé au démarrage
;dd 0       ;adresse du secteur ou commence l'image 
;dd 0,0,0,0,0 ;innutilisé

;emulation de disquette
db 88h       ;signale que boutable
db 2         ;type d'emulation (2=disquette)
dw 0         ;segment ou charger l'image
db 0         ;system type
db 0         ;innutilisé
dw 720       ;nombre de secteur chargé au démarrage?
dd (secteur_fichier_image/2048)       ;adresse du secteur ou commence l'image 
dd 0,0,0,0,0 ;innutilisé


;entrée finale
dd 91h,0,0,0
dd 0,0,0,0

rb 2048 + secteur_catalogue - $ 


;*************************************************dossier racine de l'image de cdrom
secteur_dossier:
db 44,0 ;longueur descripteur
ddlm 0 ;position fichier
ddlm fin_image_iso ;taille fichier
db 85,4,28,12,20,0,4
db 0,0,0 ;attributs
dwlm 0 ;numéros de volume
db 10 ;taille du nom du fichier
db "SEAC.ISO;1"
db 0

db 46,0 ;longueur descripteur
ddlm (secteur_readme/2048) ;position fichier
ddlm (finsecteur_readme-secteur_readme) ;taille fichier
db 85,4,28,12,20,0,4
db 0,0,0 ;attributs
dwlm 0 ;numéros de volume
db 12 ;taille du nom du fichier
db "README.TXT;1"
db 0

db 44,0 ;longueur descripteur
ddlm (secteur_fichier_image/2048) ;position fichier
ddlm 1474560 ;taille fichier
db 85,4,28,12,20,0,4
db 0,0,0 ;attributs
dwlm 0 ;numéros de volume
db 10 ;taille du nom du fichier
db "SEAC.IMG;1"
db 0

db 44,0 ;longueur descripteur
ddlm (secteur_archive/2048) ;position fichier
ddlm (finsecteur_archive-secteur_archive) ;taille fichier
db 85,4,28,12,20,0,4
db 0,0,0 ;attributs
dwlm 0 ;numéros de volume
db 10 ;taille du nom du fichier
db "SEAC.ZIP;1"
db 0


fin_secteur_dossier:


rb 2048 + secteur_dossier - $ 




;*************************************************dossier racine de l'image de cdrom
secteur_readme:
db "you are on a bootable cdrom of the SEAC operating system",13,10
db "SEAC.ISO = hybrid bootable image file of CDrom and hard disk",13,10
db "SEAC.IMG = bootable floppy image file",13,10
db 13,10
db "vous êtes sur un cdrom amorçable du systeme d'exploitation SEAC",13,10
db "SEAC.ISO = fichier image hybride amorçable de CDrom et disque dur",13,10
db "SEAC.IMG = fichier image amorçable de disquette",13,10


finsecteur_readme:

rb 2048 + secteur_readme - $

secteur_archive:
file "../../BIN/SEAC.ZIP"
rb ((($/2048)+1)*2048)-$ 
finsecteur_archive:




secteur_fichier_image:
file "../../BIN/SEAC.IMG"
rb ((($/2048)+1)*2048)-$ 


secteur_partition_boot:
file "../../BIN/SEAC.BAZ"
rb ((($/2048)+1)*2048)-$-1 
db 0
finsecteur_partition_boot:



fin_image_iso:
