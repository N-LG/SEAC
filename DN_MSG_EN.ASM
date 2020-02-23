bidon:
;message systeme uttilisé par SeLG 💩
;doit être entregistré au format utf8

db 1Ah,0C2h,080h,0C2h,081h,0C2h,082h,0C2h,083h,"SEaC V0.9 January 2020",13 
db 0C2h,084h,0C2h,085h,0C2h,086h,0C2h,087h,"development version",17h,13,0

db "unknown command: ",0 ;1
db "directory not found: ",0   ;2
db 0     ;3
db "Task not found: ",0 ;4
db 0  ;5
db "unrecognized file format",13,0  ;6
db "Video mode not supported",13,0 ;7
db "wrong command syntax: ",0 ;8
db "Locked video mode change",13,0 ;9


;message des exceptions
db "Divide by zéro",0                    ;ex0 message 10
db "debug mode activated",0                        ;ex1     
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
db "Exception # 15",0   ;ex15
db "Erreur FPU",0          ;ex16
db "Erreur d'alignement",0 ;ex17
db "Machine Check",0       ;ex18
db "Erreur SMID",0         ;ex19
db "Exception # 20",0    ;ex20
db "exception # 21",0   ;21
db "exception # 22",0   ;22
db "exception # 23",0   ;23
db "exception # 24",0   ;24
db "exception # 25",0   ;25
db "exception # 26",0   ;26
db "exception # 27",0   ;27
db "exception # 28",0   ;28
db "exception # 29",0   ;29
db "exception # 30",0   ;30
db "exception # 31",0   ;ex31 message 41 

db 13,1Ch,"Process # ",0 ;42
db " caused the exception: ",0 ;43
db 13,"the main task had to be restarted",17h,13,0  ;44
db 13,"the faulty task had to be stopped",17h,13,0  ;45
db "state of the stack:",0  ;46
db "impossible to reserve memory",0  ;47 seul texte qui doit être codé en ISO 8859-1 et pas en UTF8
db 1Ch,"detection of an error in memory, erasure of corrupted memory",17h,13,0  ;48
db 0  ;49





db 13,"List of partitions and removable disks detected:",13,0  ;50
db 13,"Liste des partitions et disques amovibles detecté:",13,0 ;51
db " Unknown partition type(",0 ;52
db " damaged partition of ",0 ;53
db " partition type FAT12 of",0 ;54
db " partition type FAT16 of ",0 ;55
db " partition type FAT32 of ",0 ;56   
db " partition type exFAT of ",0 ;57
db " partition type Ext2 of ",0 ;58
db " partition type Ext3 of ",0 ;59
db " partition type TOD of ",0 ;60
db " partition type NTFS of ",0 ;61
db " partition type SFS of ",0 ;62
db 0 ;63
db 0 ;64
db 0 ;65
db 0 ;66
db 0 ;67
db 0 ;68
db 0 ;69

db 13,"List of files in the folder: ",0   ;70

db 13,"List of Tasks running:",13,0   ;71


db 13,"memory organization:",13,0   ;72 
db "free memory: ",0   ;73
db 13,"memory used by system: ",0    ;74
db 13,"memory used by task: ",0    ;75
db 13,"memory used by communication between tasks: ",0 ;76
db 13,"total memory: ",0 ;77

db " bytes",13,0 ;78
db 0 ;79

db 13,"List of video modes supported:",13,0   ;80
db " text",13,0;81
db "bits banked memory",13,0 ;82
db "bits linear memory",13,0 ;83
db 0 ;84
db 0 ;85
db 0 ;86
db " file has been loaded for the language definition",13,0               ;87
db " file has been loaded for the keyboard definition",13,0               ;88
db " file has been loaded for the  the graphic character definition",13,0 ;89

db "le dossier à supprimer n'est pas vide",13,0  ;90
db "file not found",13,0 ;91
db "forced stop of task ",0  ;92
db "modification du temp d'execution de la tâche ",0  ;93
db "the system folder has been defined",13,0  ;94
db " has been copied to ",0  ;95
db " has been removed",13,0  ;96
db " file has been renamed to ",0  ;97
db "the ",0  ;98
db 0  ;99
db 0  ;100


;************************************************************************
msgerreur:
db "execution sans probleme",0
db "parameter error",13,0                   ;101  (erreur 1)
db "read error",13,0                     ;102  (erreur 2)
db "lecteur/disque/fichier non trouvé",13,0     ;103  (erreur 3)
db "file system error",13,0          ;104  (erreur 4)
db "writing error",13,0                     ;105  (erreur 5)
db "no disk response",13,0                 ;106  (erreur 6)
db "disk busy",13,0                         ;107  (erreur 7)
db "file already open",13,0                   ;108  (erreur 8)
db "forbidden reading",13,0               ;109  (erreur 9)
db "forbidden opening",13,0               ;110  (erreur 10)
db "not enougth memory",13,0                 ;111  (erreur 11)
db "le fichier ouvert est un dossier",13,0      ;112  (erreur 12)
db "erreur d'origine inconnue",13,0             ;113  (erreur 13)
db "nombre de couleur non reconnue",13,0        ;114  (erreur 14)
db "ecran absent",13,0                          ;115  (erreur 15)
db "action non autorisé",13,0                   ;116  (erreur 16)
db "zone tampon vide",13,0                      ;117  (erreur 17)
db "zone tampon pleine",13,0                    ;118  (erreur 18)
db "controleur ne répond pas",13,0              ;119  (erreur 19)
db "controleur absent",13,0                     ;120  (erreur 20)
db "impossible de supprimer le dossier car il n'est pas vide",13,0 ;102  (erreur 21)
db "caractère interdit dans le nom de fichier",13,0 ;102  (erreur 22)
db "création de fichier impossible",13,0        ;123  (erreur 23)
db "nom de fichier deja uttilisé",13,0          ;124  (erreur 24)
db "pas de réponse",13,0                        ;125  (erreur 25)
db "erreur dans la structure",13,0              ;126  (erreur 26)
db "données disponible",13,0                    ;127  (erreur 27)
db "données non disponible",13,0                ;128  (erreur 28)



