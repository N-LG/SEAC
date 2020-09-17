
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
;?????? equ 30h     ;6
;?????? equ 38h     ;7
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


  



ad_chaine_travail equ 2000h ;zt de travail des commandes internes, gestion usb, et de la création de tache

ad_nomfichier1 equ 2200h  ;zt uttilisé par la fonction d'ouverture de fichier
ad_nomfichier2 equ 2400h ;zt uttilisé par la fonction d'ouverture de fichier

index_tabcar equ 2600h ;index des 32 tables de caractères (dword)

index_ecran equ 2700h ;index des 64 ecranS (word)

;???

ad_tabcoul equ 3000h ;1024 octets table de correspondance pour les 256 couleurs
infovesa equ 3400h ;zone tampon utillisé par les fonction VESA pour y charger les info de la carte ou des modes

;???

zt_maj_descp equ 3800h  ;zone tampon pour la mise a jour des descripteur des partitions
zt_conversion_ucs equ 4000h  ;definition temporaire

zt_disquette equ 4200h          ;zone tampon pour la lecture de secteur sur la disquette
bootsecteur equ 4400h           ;zone tampon de lecture du MBR, du premier secteur d'une partition, et d'un decripteur de CD
zt_lminfo equ 4600h             ;zone tampon de chargement de descripteur fichier pour lecture/modif métadonnées +lecture dossier
secteurcd equ 4800h             ;zt pour la lecture partielle de secteur CD
ad_msg_syst equ 5000h ;4ko
ad_msg_erreur equ 6000h ;8Ko  


ad_tabclav_code   equ 8000h   ;512 octet
;ad_tabclav_usb   equ 8200h    ;inconnu (128 estimé)
ad_curseur_defaut equ 8600h   ;256 octets
ad_tabclav_carac  equ 8800h     ;2 fois 2048
ad_tabclav_chasse equ 9800h    ;2048 max



;???

ad_desc_periph_usb equ 0B000h 
dc_desc_periph_usb equ 6 ;element de 64 octets
nb_desc_periph_usb equ 128 

ad_desc_ctrl_usb equ 0D000h   
dc_desc_ctrl_usb equ 5 ;element de 32 octets
nb_desc_ctrl_usb equ 64 ;64 elements

;???


ad_repertoire equ 13400h  ;adresse du repertoire courant
ad_repsys     equ 13600h      ;adresse du repertoire système
zt_rcl        equ 13800h  ;zone de réception touche
ad_cce        equ 13900h  ;256 octet
ad_zdc        equ 13A00h  ;512 octet 
ad_descd      equ 13C00h  ;512 octets
ad_tss        equ 13E00h ;TSS et IO map (512 + 8196)  2200h
ad_descp      equ 16000h ;8kibi 128*64



ad_table_exec equ 18000h ;table d'orde d'execution des taches constitué des élément suivant:
table_exec_id  equ ad_table_exec + 0  ;id de la tache
table_exec_ad  equ ad_table_exec + 4  ;adresse de la tache en mémoire
table_exec_dex equ ad_table_exec + 8  ;dernière execution de la tache


ad_ztcmd      equ 20000h ;zone tampon reception commande

;*******************************************************************************************************************************************************
;variables systŠme

cu_cce equ 0  ;position du curseur dans la commande en cours de rédaction
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
;b0=scroll lock activé
;b1=verr num activé
;b2=verr maj activé
;b3=
;b4=pause activé
;b5=
;b6=commande de maj led envoyé
;b7=jeu de caractère clavier alternatif activé

ztcl equ 32h    ;zone tampon clavier
nlafj equ 36h   ;pointeur sur la fin du journal
pfinj equ 38h   ;pointeur sur la fin du journal
nb_zrc equ 3Ah  ;nombre de touche dans la zone de reception clavier
sv_chas equ 3Ch ;sauvegarde de l'eventuel dernier caractère de chasse rentrée
sv_alt  equ 40h ;sauvegarde de l'eventuel caractère rentré par ALT+chiffres
alclat1 equ 44h ;touche 1 a presser avec ctrl pour avoir le clavier alternatif
alclat2 equ 45h ;touche 1 a presser avec ctrl pour avoir le clavier alternatif


xs1 equ 50h      ;position de la souris 1 en X
ys1 equ 52h      ;position de la souris 1 en Y
axs1 equ 54h     ;position d'affichage actuel en x de la souris 1
ays1 equ 56h     ;position d'affichage actuel en y de la souris 1
nbzt1 equ 58h    ;nombre d'octet dans la trame a d‚coder
nbts1 equ 59h    ;nombre d'octet de la trame a attendre avant de la dédoder
atts1 equ 5Ah    ;attribut souris 1
		 ;bo=souris activé
		 ;b1=touche 4 et 5 actives
etbs1 equ 5Bh    ;etat précédent boutons souris
zts1 equ 5Ch     ;zone tampon de la souris 1




;******************************************************************************
;gestion de la video

chunka equ 70h    ;chuk video actuellemt point‚ en A0000h
chunkb equ 72h    ;chuk video actuellemt point‚ en B0000h
mdvc  equ 74h     ;mode video en cour
octpl equ 76h     ;octets par lignes
bitpp equ 78h     ;bits par pixel (0=mode texte, valeur ok: 8,15,16,24,32)
octpp equ 79h     ;octet par pixel (valeur ok: 1,2,3,4) 




at_vid equ 80h ;attribut video
	       ;b0=maj complete demandé
	       ;b1=maj partielle demandé
	       ;b2=deuxième partie
	       ;b3=maj ecran en cours
	       ;b4=mémoire en linear frame buffer

	       
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
;b4=lecteur disquette présent
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
;b0=la liste des écran a été modifié 
;b1=le journal a été modifié
;b2=le dossier courant a été modifié
;b3=la commande a été modifié

;b5=on doit afficher la fin du journal


no_ligne_jcsl equ 0F2h
ad_jcsl equ 0F4h ;zone d'enregistrement journal texte
max_jcsl equ 0F8h
to_jcsl equ 0FCh  ;taille occup‚ par le journal console




ligne_listing_ecran equ 100h  ;nombre d'écran affiché dans le tecop
id_tache_af equ 102h ;num‚ros de tache affiché
ad_tache_af equ 104h ;adresse de la tache affiché
cmd_bios equ 108h ;sauvegarde provisoire de eax lors d'un appel au bios en mode réel






;*************************************************************************
;registre de travail du systeme d'exploration des fichiers

at_partition equ 120h   ;attribut/type partition
no_disquepart equ 121h  ;numéros de disque physique correspondant a la partition
nb_fat equ 122h         ;nombre de fat
nb_sec_cluster equ 123h ;nombre de secteur par cluster

ad_partition equ 128h   ;adresse premier secteur de la partition 
to_partition equ 130h   ;nombre de secteur de la partition



ad_fat equ 140h         ;adresse des fat 
to_fat equ 144h         ;taille des fat
ad_cluster0 equ 148h    ;adresse du cluster 0  
to_1cluster equ 14Ch    ;taille d'un cluster
nb_cluster equ 150h     ;nombre de cluster de la partition

at_fichier equ 160h   ;attribut fichier
		      ;b0 à b1 =type de fichier
		      ;b2 à b6=systeme de fichier
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
;????? equ 1F6h     ;reserve
index_table_exec equ 1F8h ;index pointant sur la prochaine tache a executer
max_table_exec equ 1FCh   ;nombre d'octet de la table d'ordre d'execution des taches



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
 


;*******************************************************************************
;gestion de l'ordre des taches
zt_temp_dexec equ 300h    ;zone tampon utilisé lors de la priorisation de l'orde d'execution des taches



;*****************************************************************
;variable utillisé pendant la mise a jour de l'écran

num_ligne_majv equ 540h   
couleur_fond equ 544h
couleur_carac equ 548h
ad_console0 equ 54Ch       

majv_xdeb equ 550h ;coordonnées utilisé lors des mise a jour de l'écran
majv_xfin equ 554h
majv_ydeb equ 558h
majv_yfin equ 55Ch

;précal mise a jour écran en mode graphique uniquement
majv_precal_longeur_ligne equ 560h
majv_precal_offset_ligne equ 564h

;précal mise a jour écran en mode combiné et emulation texte
majv_precal_resxt equ  560h  ;dword resxt x4
majv_precal_offsetx_ecran equ 564h
majv_precal_offsetx_image equ 568h
majv_precal_finligne equ 56Ch
majv_precal_debutligne equ 570h






;*************************************************************************
;gestion de l'USB

usb_ctrl_test equ 600h     ;controleur suivant a tester
usb_port_test equ 601h     ;port suivant a tester
usb_action    equ 602h     ;action a effectuer
usb_adresse   equ 603h     ;adresse du périphérique sur lequel on travail
usb_tempo     equ 604h     ;temporisation a attendre si action<>0
usb_commande  equ 608h     ;zt utillisé pour l'envoie d'une commande (8 octets)
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§




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
;po_tache equ 0Ah  ;pointeur de la tache dans la liste

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
id_maitre equ 0F4h    ;id de la tache a l'origine de celle ci
sel_ecranv equ 0F6h   ;selecteur d'ecran virtuel

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
		     ;b0-b3 type de connexion
		     ;b12=canal terminé par emeteur, dès que la zone vers recepteur est vide on supprime le canal
		     ;b13=canal terminé par recepteur, dès que la zone vers emeteur est vide on supprime le canal
		     ;b14=descripteur modifié par emeteur
		     ;b15=descripteur modifié par recepteur

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



;****************************************************************************
;descripteur de controleur de bus USB
dcu_type    equ 00h   ;type 1=controleur UHCI 2=OHCI 3=EHCI 4=XHCI FFh=Hub
dcu_nb_port equ 01h
dcu_es      equ 02h 
dcu_pci     equ 04h
dcu_mem     equ 08h
dcu_to      equ 0ch





;****************************************************************************
;descripteur de périphérique USB
dpu_att  equ 0 ;attributs: b0=présent b1=acces réservé
dpu_ctrl equ 1 ;controleur auquel est raccordé le périphérique
dpu_port equ 2 ;numéro du port sur lequel est branché le périphérique
dpu_idr  equ 4 ;id de la tache qui as réservé l'acces au périphérique
dpu_togl equ 6 ;état du dernier data toggle utilisé lors d'un transfer bulk pour chaque endpoint
;?????
dpu_ted equ 32 ;taille de transfert max par endpoints 16*2


;***********************************************
;port utillisé par controleur UHCI
ctrl_uhci_usbcmd    equ 000h
ctrl_uhci_usbsts    equ 002h
ctrl_uhci_usbintr   equ 004h
ctrl_uhci_frnum     equ 006h
ctrl_uhci_frbaseadd equ 008h
ctrl_uhci_sofmod    equ 00ch
ctrl_uhci_portsc1   equ 010h


;***********************************************
;port utillisé par controleur EHCI
ctrl_ehci_usbcmd           equ 000h
ctrl_ehci_usbsts           equ 004h
ctrl_ehci_usbintr          equ 008h
ctrl_ehci_frindex          equ 00Ch
ctrl_ehci_ctrldssegment    equ 010h
ctrl_ehci_periodiclistbase equ 014h
ctrl_ehci_asynclistaddr    equ 018h
ctrl_ehci_configflag       equ 040h
ctrl_ehci_portsc           equ 044h


;******************************************************************************
;organisation mémoire d'un segment console

at_console equ 00h
      ;b0=mote texte actif
      ;b1=mode graphique actif
      ;b2=souris ative
      ;b3=pas de maj ecran obligatoire après appel fonction int 63h
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
cer_uhci   equ 31 ;erreur controleur UHCI
cer_ohci   equ 32 ;erreur controleur OHCI
cer_ehci   equ 33 ;erreur controleur EHCI
cer_xhci   equ 34 ;erreur controleur XHCI


;ne pas oublier d'ajouter le texte correspondant dans le fichier DN_MSG.ASM


;**********************************************************
;code des zone de mémoire systeme

czm_zj     equ 1  ;journal du tecop
czm_hc     equ 2  ;historique des dernière commandes tapé
czm_etz    equ 3  ;ecran de la tache zéro
czm_cc     equ 4  ;zone tampon pour le copier/collé
czm_pol    equ 5  ;police de caractère matricielle

czm_dfo    equ 10  ;descripteur des fichiers ouverts
czm_ztf1   equ 11  ;zone tampon FAT1
czm_ztf2    equ 12 ;zone tampon FAT2
czm_ztlef equ 13  ;zone tampon lecture/ecriture fichier

czm_com     equ 20  ;zone tampon de reception port com
czm_pil     equ 21  ;zone tampon utillisé par un pilote 
czm_tmi     equ 22  ;espace mémoire réservé aux périphériques isa


czm_setup_usb equ 30 ;zt echange setup usb
czm_bulk_usb equ 31 ;zt echange bulk usb
czm_iso_usb equ 32 ;zt echange iso usb
czm_int_usb equ 33 ;zt echange int usb


czm_uhci equ 35  ;zoné mémoire utillisé par un controleur UHCI
czm_ohci equ 36  ;zoné mémoire utillisé par un controleur OHCI
czm_ehci equ 37  ;zoné mémoire utillisé par un controleur EHCI
czm_xhci equ 38  ;zoné mémoire utillisé par un controleur XHCI


czm_ahci equ 40  ;zone mémoire réservé au dialogue avec un contoleur ahci
czm_sata equ 41  ;zone mémoire réservé au dialogue d'un périphérique sata branché sur un controleur ahci