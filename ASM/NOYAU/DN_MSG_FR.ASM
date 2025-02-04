dn_msg_fr:
;message systeme uttilisé par SeaC
;doit être entregistré au format utf8
;
;0 - BLACK    4 - RED       8 - DARKGRAY    C - LIGHTRED
;1 - BLUE     5 - MAGENTA    9 - LIGHTBLUE   D - LIGHTMAGENTA
;2 - GREEN    6 - BROWN     A - LIGHTGREEN  E - YELLOW
;3 - CYAN     7 - LIGHTGRAY  B - LIGHTCYAN   F - WHITE
;ajoutez 10h au code couleur ci dessus pour pouvoir avoir la couleur souhaité
;ne pas oublier de revenir a gris clair (la couleur d'affichage habituelle)

messages_systeme:
db 1Ah,0C2h,080h,0C2h,081h,0C2h,082h,0C2h,083h,1Fh,"SEAC",1Ah," V0.23 Février 2025 version de dévellopement",13 
db 0C2h,084h,0C2h,085h,0C2h,086h,0C2h,087h,1Fh,"S",1Ah,"ysteme d'",1Fh,"E",1Ah,"xploitation ",1Fh,"A",1Ah,"proximativement ",1Fh,"C",1Ah,"omplet",17h,13,0

db 13,16h,"Commande inconnue: ",0 ;1
db 13,16h,"Répertoire introuvable: ",0   ;2
db 13,16h,"Erreur lors de l'execution de la commande ",34,0     ;3
db 13,16h,"Tâche non trouvé: ",0 ;4
db 13,16h,"Impossible de remonter plus dans l'arborescence des fichiers",17h,13,0  ;5
db "Format de fichier non reconnue",13,0  ;6
db 13,16h,"Mode video non supporté",17h,13,0 ;7
db 0 ;8
db 13,16h,"Changement de mode video bloqué",17h,13,0 ;9


;message des exceptions
db "Division par zéro",0                    ;ex0 message 10
db "Mode debug activé ",0                        ;ex1     
db "L'interruption non masquable(NMI), panne materiel grave",0      ;ex2
db "L'instruction int 3 à été appelé par la tâche ",0        ;ex3 
db "Débordement detecté par INTO",0              ;ex4
db "Débordement detecté par BOUND",0       ;ex5
db "Le processeur a rencontré une instruction inconnue",0    ;ex6
db "Le coprocesseur ne répond pas",0       ;ex7
db "Double faute",0                 ;ex8
db "CoProcessor Segment Overrun",0  ;ex9
db "TSS invalide",0                 ;ex10
db "Segment de mémoire absent",0    ;ex11
db "Faute de pile",0                 ;ex12
db "Erreur de protection générale",0  ;ex13
db "Page Fault",0   ;ex14
db "Exception 15",0   ;ex15
db "Erreur FPU",0          ;ex16
db "Erreur d'alignement",0 ;ex17
db "Machine Check",0       ;ex18
db "Erreur SMID",0         ;ex19
db "Exception de virtualisation",0    ;ex20
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

db 13,"le processus N°",0 ;42
db " a causé l'exception: ",0 ;43
db " apres l'étape ",0  ;44
db 13,"la tâche principale a dut être redémarré",17h,13,0  ;45
db 13,"la tâche fautive a dut être arreté",17h,13,0  ;46
db "impossible de r",0E9h,"server de la m",0E9h,"moire",0  ;47 seul texte qui doit être codé en ISO 8859-1 et pas en UTF8
db 1Ch,"detection d'une erreur dans la mémoire, effacement de la mémoire corrompue",17h,13,0  ;48
db 0  ;49





db 13,"Liste des disques:",13,"#dm  Disque Mémoire",13,0  ;50
db 13,"Liste des partition detecté:",13,0 ;51
db " partition de type inconnue(",0 ;52
db " partition endommagé de ",0 ;53
db " partition de type FAT12 de ",0 ;54
db " partition de type FAT16 de ",0 ;55
db " partition de type FAT32 de ",0 ;56   
db " partition de type exFAT de ",0 ;57
db " partition de type Ext2 de ",0 ;58
db " partition de type Ext3 de ",0 ;59
db " partition de type TOD de ",0 ;60
db " partition de type NTFS de ",0 ;61
db " partition de type SFS de ",0 ;62
db 0 ;63
db 0 ;64
db 0 ;65
db 0 ;66
db 0 ;67
db 0 ;68
db "#di  Lecteur de Disquette",13,0 ;69

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
db " de definition de langue a été chargé",13,0              ;87
db " de definition de clavier à été chargé",13,0             ;88
db " de definition graphique de caractère a été chargé",13,0 ;89

db 0 ;90
db 0 ;91
db "arret forcé de la tâche ",0  ;92
db "modification du temp d'execution de la tâche ",0  ;93
db "le dossier système a été définis",13,0  ;94
db " a été copié en ",0  ;95
db " a été supprimé",13,0  ;96
db " a été rennommé ",0  ;97
db "le fichier ",0  ;98
db "erreur durant l'initialisation du périphérique HID",13,0  ;99
db "le périphérique USB «",0  ;100
db "» a été connecté a l'adresse ",0 ;101
db "erreur lors de la connexion d'un nouveau périphérique USB durant la phase ",0 ;102
db "déconnexion du périphérique USB ",0 ;103
db 0;104
db 0;105
db 0;106
db 0;107
db 0;108
db 0;109
db "erreur durant l'ouverture du fichier d'entrée",0      ;110
db "erreur durant l'ouverture du fichier de sortie",0     ;111
db "erreur durant l'ouverture du dossier d'entrée",0      ;112
db "erreur durant l'ouverture du dossier de sortie",0     ;113
db "erreur durant la création du fichier d'entrée",0      ;114
db "erreur durant la création du fichier de sortie",0     ;115
db "erreur durant la création du dossier d'entrée",0      ;116
db "erreur durant la création du dossier de sortie",0     ;117
db "erreur durant la lecture dans le fichier d'entrée",0  ;118
db "erreur durant la lecture dans le fichier de sortie",0 ;119
db "erreur durant la lecture dans le dossier d'entrée",0  ;120
db "erreur durant la lecture dans le dossier de sortie",0 ;121
db "erreur durant l'écriture dans le fichier d'entrée",0  ;122
db "erreur durant l'écriture dans le fichier de sortie",0 ;123
db "erreur durant l'écriture dans le dossier d'entrée",0  ;124
db "erreur durant l'écriture dans le dossier de sortie",0 ;125










messages_erreur:
db "action terminé sans problème",0
db "erreur de paramètre",13,0                   ;erreur 1
db "erreur de lecture",13,0                     ;erreur 2
db "lecteur/disque/fichier non trouvé",13,0     ;erreur 3
db "erreur du systême de fichier",13,0          ;erreur 4
db "erreur d'écriture",13,0                     ;erreur 5
db "pas de réponse disque",13,0                 ;erreur 6
db "disque occupé",13,0                         ;erreur 7
db "fichier déjà ouvert",13,0                   ;erreur 8
db "interdiction de lecture",13,0               ;erreur 9
db "interdicion d'ouverture",13,0               ;erreur 10
db "plus assez de mémoire",13,0                 ;erreur 11
db "le fichier ouvert est un dossier",13,0      ;erreur 12
db "erreur d'origine inconnue",13,0             ;erreur 13
db "nombre de couleur non reconnue",13,0        ;erreur 14
db "ecran absent",13,0                          ;erreur 15
db "action non autorisé",13,0                   ;erreur 16
db "zone tampon vide",13,0                      ;erreur 17
db "zone tampon pleine",13,0                    ;erreur 18
db "controleur ne répond pas",13,0              ;erreur 19
db "controleur absent",13,0                     ;erreur 20
db "impossible de supprimer le dossier car il n'est pas vide",13,0 ;erreur 21
db "caractère interdit dans le nom de fichier",13,0 ;erreur 22
db "création de fichier impossible",13,0        ;erreur 23
db "nom de fichier deja uttilisé",13,0          ;erreur 24
db "pas de réponse",13,0                        ;erreur 25
db "erreur dans la structure",13,0              ;erreur 26
db "données disponible",13,0                    ;erreur 27
db "données non disponible",13,0                ;erreur 28
db "zone de mémoire indisponible",13,0          ;erreur 29
db "zone de mémoire hors mémoire physique",13,0 ;erreur 30
db "erreur controleur UHCI",13,0                ;erreur 31
db "erreur controleur OHCI",13,0                ;erreur 32
db "erreur controleur EHCI",13,0                ;erreur 33
db "erreur controleur XHCI",13,0                ;erreur 34
db "débordement de pile du FPU",13,0            ;erreur 35
db "opération arithmétique invalide",13,0       ;erreur 36
db "opération invalide",13,0                    ;erreur 37
db "opérand incorrecte",13,0                    ;erreur 38
db "division par zéro",13,0                     ;erreur 39
db "débordement numérique",13,0                 ;erreur 40
db "sous capacité numérique",13,0               ;erreur 41
db "résultat inexacte",13,0                     ;erreur 42
db 0                                            ;erreur 43
db 0                                            ;erreur 44
db 0                                            ;erreur 45
db 0                                            ;erreur 46
db 0                                            ;erreur 47
db 0                                            ;erreur 48
db 0                                            ;erreur 49
db "erreur durant l'ouverture du fichier d'entrée:",0      ;erreur 50
db "erreur durant l'ouverture du fichier de sortie:",0     ;erreur 51
db "erreur durant l'ouverture du dossier d'entrée:",0      ;erreur 52
db "erreur durant l'ouverture du dossier de sortie:",0     ;erreur 53
db "erreur durant la création du fichier d'entrée:",0      ;erreur 54
db "erreur durant la création du fichier de sortie:",0     ;erreur 55
db "erreur durant la création du dossier d'entrée:",0      ;erreur 56
db "erreur durant la création du dossier de sortie:",0     ;erreur 57
db "erreur durant la lecture dans le fichier d'entrée:",0  ;erreur 58
db "erreur durant la lecture dans le fichier de sortie:",0 ;erreur 59
db "erreur durant la lecture dans le dossier d'entrée:",0  ;erreur 60
db "erreur durant la lecture dans le dossier de sortie:",0 ;erreur 61
db "erreur durant l'écriture dans le fichier d'entrée:",0  ;erreur 62
db "erreur durant l'écriture dans le fichier de sortie:",0 ;erreur 63
db "erreur durant l'écriture dans le dossier d'entrée:",0  ;erreur 64
db "erreur durant l'écriture dans le dossier de sortie:",0 ;erreur 65


fin_messages:

