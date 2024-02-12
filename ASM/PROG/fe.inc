fe.inc:;en-tête prémaché pour compiler un fichier de type FE sous Fasm
org 0
format binary
use32
db "FE "                         ;signale le type du fichier  
db "1"                           ;version du fichier
dd pile                          ;taille de la pile
dd scode                          ;adresse de la zone de code
dd sdata1                         ;taille du segment de code   

dd 0                             ;réservé pour un usage ultérieur
dd 0
dd 0
dd 0

dd scode+sdata1                    ;adresse des data 1 dans le fichier  
dd scode+sdata1+sdata2              ;adresse des data 2 dans le fichier
dd scode+sdata1+sdata2+sdata3        ;adresse des data 3 dans le fichier
dd scode+sdata1+sdata2+sdata3+sdata4  ;adresse des data 4 dans le fichier

dd sdata2                         ;taille du segment de donnée 1 dans le fichier
dd sdata3                         ;taille du segment de donnée 2 dans le fichier 
dd sdata4                         ;taille du segment de donnée 3 dans le fichier 
dd findata                       ;taille du segment de donnée 4 dans le fichier

dd 0                             ;octets supplémentaire début du segment de données 1 
dd 0                             ;octets supplémentaire début du segment de données 2
dd 0                             ;octets supplémentaire début du segment de données 3
dd 0                             ;octets supplémentaire début du segment de données 4

dd 0                             ;octets supplémentaire fin du segment de données 1 
dd 0                             ;octets supplémentaire fin du segment de données 2
dd 0                             ;octets supplémentaire fin du segment de données 3
dd 0                             ;octets supplémentaire fin du segment de données 4

;selecteur de segment de la LDT de la tache
sel_res1   equ 004h  ;segment LDT 0  DPL0
sel_codet  equ 00Fh  ;segment LDT 1  DPL3
sel_res2   equ 014h  ;segment LDT 2  DPL0
sel_res3   equ 01Ch  ;segment LDT 3  DPL0

sel_pilet0 equ 024h  ;segment LDT 4  DPL0   
sel_pilet1 equ 02Dh  ;segment LDT 5  DPL1
sel_pilet2 equ 036h  ;segment LDT 6  DPL2              
sel_pilet3 equ 03Fh  ;segment LDT 7  DPL3             

sel_dat1 equ 047h  ;segment LDT 8  DPL3
sel_dat2 equ 04Fh  ;segment LDT 9  DPL3
sel_dat3 equ 057h  ;segment LDT 10 DPL3
sel_dat4 equ 05Fh  ;segment LDT 11 DPL3

sel_res4   equ 064h  ;segment LDT 12 DPL0
sel_res5   equ 06Ch  ;segment LDT 13 DPL0
sel_res6   equ 074h  ;segment LDT 14 DPL0
sel_res7   equ 07Ch  ;segment LDT 15 DPL0



;structure d'un ecran virtuel
at_console equ 00h
      ;b0=mote texte actif
      ;b1=mode graphique actif
      ;b2=souris ative
      ;b3=pas de maj ecran obligatoire après appel fonction int 63h
      ;b4=demande de mise a jour écran
      ;b5=caracteristique ecran réel changé
      ;b6=mode fenetre
ad_texte equ 04h
to_texte equ 08h
ad_graf equ 0Ch
to_graf equ 10h
ad_curseur equ 14h
to_curseur equ 18h
ad_curseur_texte equ 1Ch ;adresse du caractère sur lequel se trouve le curseur texte
bm_clavier equ 20h
posx_souris equ 30h
posy_souris equ 32h
resx_ecran equ 34h
resy_ecran equ 36h
resx_texte equ 38h
resy_texte equ 3Ah
octet_ligne equ 3Ch
bit_pixel equ 3Eh 
octet_pixel equ 3Fh
dmaj_xdeb equ 40h
dmaj_xfin equ 44h
dmaj_ydeb equ 48h
dmaj_yfin equ 4Ch

ad_res_console equ 100h  ;adresse reservé



;structure d'un objet image
objimage_bpp equ 00h ;0 bit par pixel
objimage_att equ 01h ;1 attribut image
objimage_x   equ 02h ;2 largeur image
objimage_y   equ 04h ;4 hauteur image
objimage_opl equ 06h ;6 nombre d'octet par ligne
objimage_ctp equ 0Ah ;10 couleur de transparence
objimage_dat equ 0Eh ;14 image



;*********************************************************************************
;code d'erreur
cer_parami equ 1  ;parametre incorrecte
cer_lec    equ 2  ;erreur de lecture
cer_lecnt  equ 3  ;lecteur/disque/fichier non trouvé
cer_sysf   equ 4  ;erreur du systême de fichier
cer_ecr    equ 5  ;erreur d'écriture
cer_prd    equ 6  ;pas de réponse disque
cer_do     equ 7  ;disque occupé
cer_fdo    equ 8  ;fichier deja ouvert
cer_il     equ 9  ;interdiction de lecture
cer_ie     equ 10 ;interdicion d'ouverture
cer_pasm   equ 11 ;plus assez de mémoire
cer_dov    equ 12 ;le fichier ouvert est un dossier
cer_inc    equ 13 ;erreur d'origine inconnue (normallement jamais utilisé, sauf erreur)
cer_nci    equ 14 ;nombre de couleur non reconnue
cer_eabs   equ 15 ;ecran absent
cer_ano    equ 16 ;action non autorisé
cer_ztv    equ 17 ;zone tampon vide
cer_ztp    equ 18 ;zone tampon pleine
cer_crp    equ 19 ;controleur ne répond pas
cer_cab    equ 20 ;controleur absent
cer_dnv    equ 21 ;dossier non vide (dans le cas d'une suppression)
cer_cin    equ 22 ;caractère interdit dans le nom de fichier
cer_cfi    equ 23 ;création de fichier impossible
cer_nfr    equ 24 ;nom de fichier deja uttilisé
cer_prt    equ 25 ;pas de réponse 
cer_ers    equ 26 ;erreur dans la structure
cer_ddi    equ 27 ;données disponible
cer_dnd    equ 28 ;données non disponible
cer_znd    equ 29 ;zone de mémoire indisponible
cer_zhm    equ 30 ;zone de mémoire hors mémoire physique
cer_uhci   equ 31 ;erreur controleur UHCI
cer_ohci   equ 32 ;erreur controleur OHCI
cer_ehci   equ 33 ;erreur controleur EHCI
cer_xhci   equ 34 ;erreur controleur XHCI
cer_efis   equ 35 ;exception du fpu
cer_efia   equ 36 ;exception du fpu
cer_efi    equ 37 ;exception du fpu
cer_efd    equ 38 ;exception du fpu
cer_efz    equ 39 ;exception du fpu
cer_efo    equ 40 ;exception du fpu
cer_efu    equ 41 ;exception du fpu
cer_efp    equ 42 ;exception du fpu
cer_ahci   equ 43 ;erreur controleur AHCI
