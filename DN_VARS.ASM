
;variables GDT

selcod equ 08h     ;1    ;selecteur mode protégé
segcod equ 2000h       ;segment mode réel

seldat equ 10h     ;2
segdat equ 3000h


selpil equ 18h     ;3
segpil equ 8000h


selgdt equ 20h     ;4
seggdt equ 1000h
selidt equ 28h     ;5
segidt equ 0F80h
selddt equ 30h     ;6
segddt equ 05000h
selztsf equ 38h     ;7
segff equ 06000h
selramt equ 40h     ;8
selramh equ 48h     ;9

selcod16 equ 50h  ;10
selconsole equ 58h  ;11

selvidA equ 60h   ;12
selvidB8 equ 68h  ;13
sellfb equ 70h    ;14

selecran equ 78h  ;15

seltss equ 83h   ;16

;*****************************
;tables système


  
ad_tabclav    equ 1000h
ad_tabclav_ex equ 1800h
ad_tabaccent  equ 1C00h



ad_chaine_travail equ 2000h ;zt de travail des commandes internes et de la création de tache

ad_nomfichier1 equ 2200h  ;zt uttilisé par la fonction d'ouverture de fichier
ad_nomfichier2 equ 2400h ;zt uttilisé par la fonction d'ouverture de fichier

;???


ad_tabcoul equ 3000h ;1024 octets table de correspondance pour les 256 couleurs
infovesa equ 3400h ;zone tampon utillisé par les fonction VESA pour y charger les info de la carte ou des modes

;???

zt_maj_descp equ 3800h  ;zone tampon pour la mise a jour des descripteur des partitions
zt_conversion_ucs equ 4000h  ;definition temporaire

zt_disquette equ 4200h          ;zone tampon pour la lecture de secteur sur la disquette
bootsecteur equ 4400h           ;zone tampon de lecture du MBR, du premier secteur d'une partition, et d'un decripteur de CD
zt_lminfo equ 4600h             ;zone tampon de chargement de descripteur fichier pour lecture/modif métadonnées
secteurcd equ 4800h             ;zt pour la lecture partielle de secteur CD


;???

ad_msg equ 6000h ;8ko  

ad_tabcar equ 8000h      ;definition des caractère graphiques

;???


ad_repertoire equ 13400h  ;adresse du repertoire courant
ad_repsys     equ 13600h      ;adresse du repertoire système
zt_rcl        equ 13800h  ;zone de réception touche
ad_cce        equ 13900h  ;256 octet
ad_zdc        equ 13A00h  ;512 octet 
ad_descd      equ 13C00h  ;512 octets
ad_tss        equ 13E00h ;TSS et IO map (512 + 8196)  2200h
ad_descp      equ 16000h ;8kibi 128*64
ad_ztcmd      equ 18000h ;zone tampon reception commande



;*******************************************************************************************************************************************************
;variables systŠme

cu_cce equ 0  ;position du curseur dans la commande en cours de r‚daction
to_cce equ 2  ;taille de la commande en cours de r‚daction
id_zdc equ 6  ;id de la commande en cours de traitement
to_ztcmd equ 8  ;taille occup‚ dans la zt commande   
coul_car equ 0Ah ;couleur d'affichage du caractère
num_cmd equ 0Bh  ;num‚ro de la commnde dans l'historique (navigation pr touche F7 et F8)




cptsf equ 10h  ;compteur sans fin
cpttc equ 14h  ;compteur de la tache courante

nb_ram equ 18h ;taille de la ram sur le système

ad_copiercoller equ 1Ch  ;adresse de la zone reservé au copié/collé

atbp equ 20h    ;attribut bouton pressé
attcl equ 30h   ;attribut clavier
ztcl equ 32h    ;zone tampon clavier
nlafj equ 36h   ;pointeur sur la fin du journal
pfinj equ 38h   ;pointeur sur la fin du journal
nb_zrc equ 3Ah  ;nombre de touche dans la zone de reception clavier
sv_chas equ 3Ch ;sauvegarde de l'eventuel dernier caractère de chasse rentrée
sv_alt  equ 40h ;sauvegarde de l'eventuel caractère rentré par ALT+chiffres


xs1 equ 50h      ;position de la souris 1 en X
ys1 equ 52h      ;position de la souris 1 en Y
nbzt1 equ 54h    ;nombre d'octet dans la trame a d‚coder
nbts1 equ 55h    ;nombre d'octet de la trame a attendre avant de la dédoder
atts1 equ 56h    ;attribut souris 1
zts1 equ 58h     ;zone tampon de la souris 1
axs1 equ 5Ch     ;position d'affichage actuel en x de la souris 1
ays1 equ 5Eh     ;position d'affichage actuel en y de la souris 1

xs2 equ 60h      ;position de la souris 2 en X
ys2 equ 62h      ;position de la souris 2 en Y
nbzt2 equ 64h    ;nombre d'octet dans la trame a d‚coder
nbts2 equ 65h    ;nombre d'octet de la trame a attendre avant de la dédoder
atts2 equ 66h    ;attribut souris 2
zts2 equ 68h     ;zone tampon de la souris 2
axs2 equ 6Ch     ;position d'affichage actuel en x de la souris 2
ays2 equ 6Eh     ;position d'affichage actuel en y de la souris 2


;******************************************************************************
;gestion de la video

chunka equ 70h    ;chuk video actuellemt point‚ en A0000h
chunkb equ 72h    ;chuk video actuellemt point‚ en B0000h
mdvc  equ 74h     ;mode video en cour
octpl equ 76h     ;octets par lignes
bitpp equ 78h     ;bits par pixel (0=mode texte, valeur ok: 8,15,16,24,32)
octpp equ 79h     ;octet par pixel (valeur ok: 1,2,3,4) 




;attvid equ 80h ;attribut video?????
resx equ 82h   ;resolution X de l'écran en pixel
resy equ 84h   ;resolution Y de l'écran en pixel
resxt equ 86h  ;nombre de colonne de l'affichage texte
resyt equ 88h  ;nombre de ligne de l'affichage texte


ad_afrep equ 90h  ;numéro du premier caractère qui sert a ecrire le dossier en cours
ad_afcmd equ 94h  ;numéro du premier caractère qui sert a ecrire la commande en cours
ad_afin equ 98h   ;numéro du dernier caractère affichable

sauv_esp_vesa equ 9Ch ;sauvegarde de esp lors de l'appel de int 10h en mode protégé

;***************************************************************************

at_fc_fichier equ 0C0h ;attribut des fonctions fichier
;b0=fonction fichier active
;b1=dernière opération disquette raté
;b2=moteur disquette allumé
;b3=irq6 activé
essai_dsq equ 0C1h
sec_piste_disq equ 0C2h ;secteur par piste sur la disquette
nb_piste_disq equ 0C4h ;nombre de piste par face
sec_cyl_disq equ 0C6h ;nombre de secteur par cylindre
pos_cyl_disq equ 0C8h ;position actuelle de la tˆte
erreur_disquette equ 0C9h ;dernier code d'erreur disquette (3 octet)
temp_moteur_disq equ 0CCh ;si cptsf d‚passe cette valeur on eteint le moteur de la disquette  

;*****************************************************************************
;occupation de la m‚moire

taille_mem_vide equ 0D0h
taille_mem_syst equ 0D4h 
taille_mem_tache equ 0D8h 
taille_mem_com equ 0DCh 

nb_zone_vide equ 0E0h 
nb_zone_syst equ 0E2h 
nb_zone_tache equ 0E4h 
nb_zone_com equ 0E6h 

;*************************************************************************
;gestion de la console systŠme

at_csl equ 0F0h  ;attribut console  
;b0=l'affichage est a raffraichir 
;b1=le journal a été modifié
;b2=le dossier courant a été modifié
;b3=la commande a été modifié
;b4=utilisation du linear frame buffer
;b5=on doit afficher la fin du journal
;b6=la mise a jour de l'ecran est en court
no_ligne_jcsl equ 0F2h
ad_jcsl equ 0F4h ;zone d'enregistrement journal texte
max_jcsl equ 0F8h
to_jcsl equ 0FCh  ;taille occup‚ par le journal console




id_tache_af equ 100h ;num‚ros de tache affich‚
ad_tache_af equ 104h ;adresse de la tache affiché
cmd_bios equ 108h ;sauvegarde provisoire de eax lors d'un appel au bios en mode réel






;*************************************************************************
;registre de travail du systeme d'exploration des fichiers

at_partition equ 120h   ;attribut partition
no_disquepart equ 121h  ;numéros de disque physique correspondant a la partition
nb_fat equ 122h         ;nombre de fat
nb_sec_cluster equ 123h ;nombre de secteur par cluster
ad_partition equ 124h   ;adresse premier secteur de la partition 
to_partition equ 128h   ;nombre de secteur de la partition
ad_fat equ 12Ch         ;adresse des fat 
to_fat equ 130h         ;taille des fat
ad_cluster0 equ 134h    ;adresse du cluster 0  
to_1cluster equ 138h    ;taille d'un cluster
nb_cluster equ 13Ch     ;nombre de cluster de la partition

at_fichier equ 160h   ;attribut fichier
no_part equ 161h   ;numéros de disque/partition du fichier
id_ouvf equ 162h    ;id de la tache qui a ouvert le fichier
ad_fichier equ 164h  ;numéros du premier secteur/cluster du fichier/adresse de la zone fichier en ram
to_fichier equ 168h  ;taille du fichier
ad_dossierfichier equ 16Ch ;adresse du dossier qui dans lequel le dossier est rangé
to_dossierfichier equ 170h ;taille du dossier dans lequel le dossier est rangé
ad_dansdossier equ 174h   ;adresse du descripteur de fichier dans le dossier

ad_ztexpdossier equ 180h           ;zone tampon provisoire d'exploration de dossier
to_ztexpdossier equ 184h           ;taille de cette zone  
po_ztexpdossier equ 188h           ;adresse dans le dossier qui correspond a l'adresse 0 dans la zone tampon
po_descripteur_expdossier equ 18Ch ;adresse dans la zt du descripeur en cours d'analyse
to_descripteur_expdossier equ 190h ;taille du descripteur
to_fichier_expdossier equ 194h     ;taille du fichier 
ad_fichier_expdossier equ 198h     ;adresse du fichier
at_fichier_expdossier equ 19Ch     ;type du fichier actuellement analysé (seulement les deux premier bit utilisé)

option_ouverture equ 1A0h     ;option de la fonction d'ouverture fichier 0=on ne créer pas de fichier 1=on créer des fichier 2=on vient de créer un fichier et on peut le transformer en dossier


zt_dapbios equ 1C0h                ;Disk Address Packet utilisé lors de l'appel des fonction bios pour lire/ecrire sur un disque

ad_hc equ 01D0h ;adresse de l'historique des commande
max_hc equ 01D4h
ad_ficho equ 01D8h ;adresse des decripteur de fichier ouvert
max_ficho equ 01DCh

;**********************************************************************
;variable uttilisé par la fonction de création  et commutation de tache

id_tache_exec equ 1E0h ;ID de la tache en cours d'execution

derniere_id equ 1E2h  ;ID de la dernière tache créer
 
ad_tache_exec equ 1E4h  ;adresse de la tache en cours d'execution           

num_fichier_tache equ 1E8h
ad_tache_cree equ 1ECH

sauv_esp_t0 equ 1F0h    ;sauvegarde de la pile de la tache 0
id_tache_fichier equ 1F4h ;ID de la tache qui utillise la fonction fichier


;*************************************************************************
;zone tampon travail sur FAT et fichier

ad_fat1 equ 200h
max_fat1 equ 204h
index_fat1 equ 208h
dsq_fat1 equ 20Ch

dsq_fat2 equ 20Dh

at_fat equ 20Eh   ;b0=0 zone1 dernière mis a jour  b0=1 zone2 dernière mis a jour b1=1 si zt fat1 modifié b2=1 si fat2 modifié (par rapport au disque)
sauv_at_fichier equ 20Fh 

ad_fat2 equ 210h
max_fat2 equ 214h
index_fat2 equ 218h


ad_zt_lecluster equ 21Ch   ;adresse de la zone tampon de lecture cluster


;*************************************************************************
;gestion des port com et lpt    (sf_port.asm)
port_com_base equ 240h ;addresses contoleurs com 1 (com2 =com1+4)
port_com_idr equ 242h  ;attribut com1 (com2 =com1+4)
port_lpt_base equ 260h ;addresses contoleurs lpt 1 (lpt2 =lpt1+4)
port_lpt_idr equ 262h  ;attribut lpt1 (lpt2 =lpt1+4)
port_com_zt equ 280h ;adresse la zone tampon de réception com 1 (com2 =com1+4)
port_lpt_zt equ 2A0h ;adresse la zone tampon de réception lpt 1 (lpt2 =lpt1+4)
port_com_to equ 2C0h ;nombre d'octet dans la zone tampon de réception com 1 (com2 =com1+4)
port_lpt_to equ 2E0h ;nombre d'octet dans la zone tampon de réception lpt 1 (lpt2 =lpt1+4)
 


;*************************************************************************
;gestion de l'USB §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§a revoir avec l'ahci

desc_ctrl_usb equ 500h ;8*16 octets(128)
ad_descusb equ 510h
ad_ztusb equ 514h
max_descusb equ 518h
max_ztusb equ 51Ch


;*****************************************************************
;variable utillisé pendant la mise a jour de l'écran

num_ligne_majv equ 540h   ;word
couleur_fond equ 544h
couleur_carac equ 548h
ad_console0 equ 54Ch       




;**********************************************************
;descripteur de disque
dd_atribut       equ 00h     
;b0-2 0=absent 1=chs 2=lba28 3=lba48 4=ATAPI
;b3   0=pio 1=dma
;b4   0=master 1=slave

dd_sec_par_piste equ 02h
dd_sec_par_cyl   equ 04h
dd_taille        equ 08h
dd_adress_base   equ 10h
dd_adress_ctrl   equ 12h
dd_adress_dma    equ 14h
dd_no_irq        equ 16h
dd_nb_octet_sec  equ 17h
dd_offset_num    equ 18h

;***********************************************************
;structure de TSS

tss_sauv_esp0 equ ad_tss + 004
tss_sauv_ss0  equ ad_tss + 008
tss_sauv_esp1 equ ad_tss + 012
tss_sauv_ss1  equ ad_tss + 016
tss_sauv_esp2 equ ad_tss + 020
tss_sauv_ss2  equ ad_tss + 024
tss_iom       equ ad_tss + 102
offset_iom    equ 512


;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
;descripteur d'un espace mémoire réservé a une tache

;db "DM"                 descripteur mémoire  
type_dm equ 02h   ;=T
;db 0
to_tache equ 04h  ;taille de la zone mémoire (identique aux autres descripteur de mémoire) 
id_tache equ 08h  ;ID de la tache
po_tache equ 0Ah  ;pointeur de la tache dans la liste

type_fe equ 10h            ;recopie de l'en tête fichier
ver_fe equ 13h
to_pile_fe equ 14h
ad_code_fe equ 18h
to_code_fe equ 1Ch

ad_data1_fe equ 30h
ad_data2_fe equ 34h
ad_data3_fe equ 38h
ad_data4_fe equ 3Ch

to_data1_fe equ 40h
to_data2_fe equ 44h
to_data3_fe equ 48h
to_data4_fe equ 4Ch

tsd_data1_fe equ 50h
tsd_data2_fe equ 54h
tsd_data3_fe equ 58h
tsd_data4_fe equ 5Ch    

tsf_data1_fe equ 60h
tsf_data2_fe equ 64h
tsf_data3_fe equ 68h
tsf_data4_fe equ 6Ch    ;fin de la recopie de l'en-tête



tt_data1_dt equ 0A0h  ;taille totale uttilisé par les secteurs de données
tt_data2_dt equ 0A4h
tt_data3_dt equ 0A8h
tt_data4_dt equ 0ACh

ad_data1_dt equ 0B0h  ;adresse (relative au debut de la zone) des différents segments
ad_data2_dt equ 0B4h
ad_data3_dt equ 0B8h
ad_data4_dt equ 0BCh

ad_pile0_dt equ 0C0h
ad_pile1_dt equ 0C4h
ad_pile2_dt equ 0C8h
ad_pile3_dt equ 0CCh

ad_code_dt equ 0D0h

sauv_esp0 equ 0E0h     ;sauvegarde du pointeur de la pile lors d'une commutation
sauv_esp1 equ 0E4h
sauv_esp2 equ 0E8h
sauv_esp3 equ 0ECh

sel_ldt_tache equ 0F0h ;selecteur de segment de la LDT
temp_exec_tache equ 0F2h   ;temp d'execution de la tache
code_service equ 0F3h ;code du service proposé par la tache
cpt_pause equ 0F4h    ;la tache doit être en pause jusqu'a cette valeur du compteur sans fin
sel_ecranv equ 0F8h   ;selecteur d'ecran virtuel

descriptif_tache equ 100h  ;descriptif (texte) de la tache executé
recop_commande equ 200h ;chaine utf8z de 512o
ldt_tache equ 400h       ;local descriptor table (16 descripteurs)
data_tache equ 500h  


;***************************************************
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


;************************************************************************************
;descripteur d'un espace mémoire  de communication

;db "DM"                 descripteur mémoire  
;type_dm equ 02h   ;=C

;to_tache equ 04h  ;taille de la zone mémoire (identique aux autres descripteur de mémoire) 
id_emetteur  equ 08h  ;ID de la tache
id_recepteur equ 0Ah ;ID de la tache receptrice
to_descr_com equ 0Ch ;taille du descripteur de canal
at_canal     equ 10h ;attribut du canal de communication 
com_tempo    equ 14h ;dword temporaire

to_zter      equ 20h ;taille de la zone emeteur vers recepteur
ad_zter      equ 24h ;adresse de la zone emeteur vers recepteur   
po_zter_lec  equ 28h ;pointeur de lecture dans la zt
po_zter_ecr  equ 2Ch ;pointeur d'ecriture dans la zt

to_ztre      equ 30h ;taille de la zone recepteur vers emeteur
ad_ztre      equ 34h ;adresse de la zone recepteur vers emeteur   
po_ztre_lec  equ 38h ;pointeur de lecture dans la zt
po_ztre_ecr  equ 3Ch ;pointeur d'ecriture dans la zt

ad_descr_com equ 40h 


to_ztcom      equ 00h ;taille de la zone com
ad_ztcom      equ 04h ;adresse de la zone com   
po_ztcom_lec  equ 08h ;pointeur de lecture dans la zt
po_ztcom_ecr  equ 0Ch ;pointeur d'ecriture dans la zt



;******************************************************************************
;organisation mémoire d'un segment console

at_console equ 00h
ad_texte equ 04h
to_texte equ 08h
ad_graf equ 0Ch
to_graf equ 10h
ad_souris equ 14h
to_souris equ 18h
ad_curseur equ 1Ch
to_curseur equ 20h
ad_curseur_texte equ 24h ;adresse du caractère sur lequel se trouve le curseur texte
ad_res_console equ 100h  ;adresse reservé

;**********************************************************
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

;ne pas oublier d'ajouter le texte correspondant dans le fichier DN_MSG.ASM


;**********************************************************
;code des zone de mémoire systeme

czm_zj     equ 1  ;journal du tecop
czm_hc     equ 2  ;historique des dernière commandes tapé
czm_etz    equ 3  ;ecran de la tache zéro
czm_cc     equ 4  ;zone tampon pour le copier/collé

czm_dfo    equ 10  ;descripteur des fichiers ouverts
czm_ztf1   equ 11  ;zone tampon FAT1
czm_ztf2    equ 12 ;zone tampon FAT2
czm_ztlef equ 13  ;zone tampon lecture/ecriture fichier

czm_com     equ 20  ;zone tampon de reception port com
czm_pil     equ 21  ;zone tampon utillisé par un pilote 
czm_tmi     equ 22  ;espace mémoire réservé aux périphériques isa

czm_flu equ 30  ;frame list uhci
czm_ztu equ 31  ;zone tampon usb
czm_dpu equ 32  ;descripteurs péripherique USB

