bidon:
;message systeme uttilisé par SeaC 💩
;doit faire 2048 octet minimum une fois compilé
;doit être entregistré au format utf8
;
;0 - BLACK    4 - RED       8 - DARKGRAY    C - LIGHTRED
;1 - BLUE     5 - MAGENTA    9 - LIGHTBLUE   D - LIGHTMAGENTA
;2 - GREEN    6 - BROWN     A - LIGHTGREEN  E - YELLOW
;3 - CYAN     7 - LIGHTGRAY  B - LIGHTCYAN   F - WHITE
;ajoutez 10h au code couleur ci dessus pour pouvoir avoir la couleur souhaité
;ne pas oublier de revenir a gris clair (la couleur d'affichage habituelle)


db 1Ah,0C2h,08Eh,0C2h,08Fh,"SeLG V0.5 Décembre 2017",13 
db "version de dévellopement",17h,13,0

db "Commande inconnue: ",0 ;1
db "Répertoire introuvable: ",0   ;2
db "Erreur de lecture",13,0     ;3
db "Tâche non trouvé: ",0 ;4
db "Plus assez de Mémoire",13,0  ;5
db "Format de fichier non reconnue",13,0  ;6
db "Mode video non supporté",13,0 ;7
db "Format de commande incorrecte: ",0 ;8
db "Changement de mode video bloqué",13,0 ;9


;message des exceptions
db "Division par zéro",0                    ;ex0 message 10
db "Mode debug activé ",0                        ;ex1     
db "L'interruption non masquable(NMI), panne materiel grave",0      ;ex2
db "L'instruction int 3 executé",0        ;ex3 
db "Débordement detecté par INTO",0              ;ex4
db "Débordement detecté par BOUND",0       ;ex5
db "Le processeur a rencontré une instruction inconnue",0    ;ex6
db "Le coprocesseur ne répond pas",0       ;ex7
db "Double faute",0                 ;ex8
db "CoProcessor Segment Overrun",0  ;ex9
db "TSS invalide",13,0                 ;ex10
db "Segment de mémoire absent",0    ;ex11
db "Faute de pile",13,0                 ;ex12
db "Erreur de protection générale",0  ;ex13
db "Page Fault",0   ;ex14
db "Exception 15",0   ;ex15
db "Erreur FPU",0          ;ex16
db "Erreur d'alignement",0 ;ex17
db "Machine Check",0       ;ex18
db "Erreur SMID",0         ;ex19
db "Exception 20",0    ;ex20
db "exception 21",0   ;21
db "exception 22",0   ;22
db "exception 23",0   ;23
db "exception 24",0   ;24
db "exception 25",0   ;25
db "exception 26",0   ;26
db "exception 27",0   ;27
db "exception 28",0   ;28
db "exception 29",0   ;29
db "exception 30",0   ;30
db "exception 31",0   ;ex31 message 41 

db 13,1Ch,"le processus N°",0 ;42
db " a causé l'exception: ",0 ;43
db 13,"la tâche principale a dut être redémarré",17h,13,0  ;44
db 13,"la tâche fautive a dut être arreté",17h,13,0  ;45
db "état de la pile:",0  ;46
db "impossible de r",0E9h,"server de la m",0E9h,"moire",0  ;47 seul texte qui doit être codé en ISO 8859-1 et pas en UTF8
db 0  ;48
db 0  ;49





db 13,"Liste des disques amovibles detecté:",13,0  ;50
db 13,"Liste des partition detecté:",13,0 ;51
db " partition de type inconnue(",0 ;52
db " partition endommagé de ",0 ;53
db " partition de type FAT12 de ",0 ;54
db " partition de type FAT16 de ",0 ;55
db " partition de type FAT32 de ",0 ;56   
db " partition de type exFAT de ",0 ;57
db " partition de type Ext2 de ",0 ;58
db " partition de type Ext3 de ",0 ;59
db " partition de type SfB de ",0 ;60
db " partition de type NTFS de ",0 ;61
db " partition de type SFS de ",0 ;62
db 0 ;63
db 0 ;64
db 0 ;65
db 0 ;66
db 0 ;67
db 0 ;68
db 0 ;69

db 13,"Liste des fichiers du dossier: ",0   ;70

db 13,"Liste des Tâches en cours d'execution:",13,0   ;71


db 13,"organisation mémoire:",13,0   ;72 
db "mémoire libre: ",0   ;73
db 13,"mémoire utilisé par le systeme: ",0    ;74
db 13,"mémoire utilisé par les tâches: ",0    ;75
db 13,"mémoire utilisé par la communication intertâches: ",0 ;76
db 13,"mémoire Totale: ",0 ;77

db " octets",13,0 ;78
db 0 ;79

db 13,"Liste des modes vidéo supporté:",13,0   ;80
db " texte",13,0;81
db "bits fenêtré",13,0 ;82
db "bits linéaire",13,0 ;83
db 0 ;84
db 0 ;85
db 0 ;86
db 0 ;87
db 0 ;88
db 0 ;89

db "le dossier à supprimer n'est pas vide",13,0  ;90
db "fichier introuvable",13,0 ;91
db 0  ;92
db 0  ;93
db 0  ;94
db 0  ;95
db 0  ;96
db 0  ;97
db 0  ;98
db 0  ;99

db "erreur de paramêtre",0     ;100  (erreur 1)


;vide
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0






