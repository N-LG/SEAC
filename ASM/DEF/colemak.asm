;fichier de d�finition pour clavier colemak
org 0
db "DEFC"
dw touche_codeps2       ;adresse de la d�finition PS/2
dw 0                    ;adresse de la d�finition usb
dw touche_carac         ;adresse de la d�finition clavier principale
dw 0                    ;adresse de la d�finition clavier secondaire
dw 0                    ;adresse de la d�finition chasse
db 0,0                  ;num�ros de touches a employer avec la touche CTRL pour basculer d'un jeu de carract�re a un autre




;****************************************************************
;liste des code touche pour clavier PS2

touche_codeps2:
db 001h,000h,000h,000h  ;esc             #001
db 03Bh,000h,000h,000h  ;F1              #002
db 03Ch,000h,000h,000h  ;F2              #003
db 03Dh,000h,000h,000h  ;F3              #004
db 03Eh,000h,000h,000h  ;F4              #005
db 03Fh,000h,000h,000h  ;F5              #006
db 040h,000h,000h,000h  ;F6              #007
db 041h,000h,000h,000h  ;F7              #008
db 042h,000h,000h,000h  ;F8              #009
db 043h,000h,000h,000h  ;F9              #010
db 044h,000h,000h,000h  ;F10             #011
db 057h,000h,000h,000h  ;F11             #012
db 058h,000h,000h,000h  ;F12             #013
db 0E0h,02Ah,0E0h,037h  ;impr ecran      #014
db 046h,000h,000h,000h  ;stop defil      #015
db 0E1h,01Dh,045h,000h  ;pause           #016
db 029h,000h,000h,000h  ;�               #017
db 002h,000h,000h,000h  ;1               #018
db 003h,000h,000h,000h  ;2               #019
db 004h,000h,000h,000h  ;3               #020
db 005h,000h,000h,000h  ;4               #021
db 006h,000h,000h,000h  ;5               #022
db 007h,000h,000h,000h  ;6               #023
db 008h,000h,000h,000h  ;7               #024
db 009h,000h,000h,000h  ;8               #025
db 00Ah,000h,000h,000h  ;9               #026    
db 00Bh,000h,000h,000h  ;0               #027
db 00Ch,000h,000h,000h  ;�               #028
db 00Dh,000h,000h,000h  ;+               #029
db 00Eh,000h,000h,000h  ;back            #030
db 00Fh,000h,000h,000h  ;tab             #031
db 010h,000h,000h,000h  ;a               #032
db 011h,000h,000h,000h  ;z               #033
db 012h,000h,000h,000h  ;e               #034
db 013h,000h,000h,000h  ;r               #035
db 014h,000h,000h,000h  ;t               #036
db 015h,000h,000h,000h  ;y               #037
db 016h,000h,000h,000h  ;u               #038
db 017h,000h,000h,000h  ;i               #039
db 018h,000h,000h,000h  ;o               #040
db 019h,000h,000h,000h  ;p               #041
db 01Ah,000h,000h,000h  ;^               #042
db 01Bh,000h,000h,000h  ;$               #043
db 01Ch,000h,000h,000h  ;entre           #044
db 03Ah,000h,000h,000h  ;lock            #045
db 01Eh,000h,000h,000h  ;q               #046
db 01Fh,000h,000h,000h  ;s               #047
db 020h,000h,000h,000h  ;d               #048
db 021h,000h,000h,000h  ;f               #049
db 022h,000h,000h,000h  ;g               #050
db 023h,000h,000h,000h  ;h               #051
db 024h,000h,000h,000h  ;j               #052
db 025h,000h,000h,000h  ;k               #053
db 026h,000h,000h,000h  ;l               #054
db 027h,000h,000h,000h  ;m               #055
db 028h,000h,000h,000h  ;�               #056
db 02Bh,000h,000h,000h  ;*               #057
db 02Ah,000h,000h,000h  ;maj g           #058
db 056h,000h,000h,000h  ;<               #059
db 02Ch,000h,000h,000h  ;w               #060
db 02Dh,000h,000h,000h  ;x               #061
db 02Eh,000h,000h,000h  ;c               #062
db 02Fh,000h,000h,000h  ;v               #063
db 030h,000h,000h,000h  ;b               #064
db 031h,000h,000h,000h  ;n               #065
db 032h,000h,000h,000h  ;?               #066
db 033h,000h,000h,000h  ;.               #067
db 034h,000h,000h,000h  ;/               #068
db 035h,000h,000h,000h  ;!               #069
db 036h,000h,000h,000h  ;maj dr          #070
db 01Dh,000h,000h,000h  ;ctrl g          #071
db 038h,000h,000h,000h  ;alt g           #072
db 039h,000h,000h,000h  ;espace          #073
db 0E0h,038h,000h,000h  ;alt gr          #074
db 0E0h,01Dh,000h,000h  ;ctrl d          #075
db 0E0h,052h,000h,000h  ;inser           #076
db 0E0h,047h,000h,000h  ;top             #077
db 0E0h,049h,000h,000h  ;page haut       #078
db 0E0h,053h,000h,000h  ;suppr           #079
db 0E0h,04Fh,000h,000h  ;fin             #080
db 0E0h,051h,000h,000h  ;page bas        #081
db 0E0h,048h,000h,000h  ;fl haut         #082
db 0E0h,04Bh,000h,000h  ;fl gauche       #083
db 0E0h,050h,000h,000h  ;fl bas          #084
db 0E0h,04Dh,000h,000h  ;fl droit        #085
db 045h,000h,000h,000h  ;verr num        #086
db 0E0h,035h,000h,000h  ;/               #087
db 037h,000h,000h,000h  ;*               #088
db 04Ah,000h,000h,000h  ;-               #089
db 047h,000h,000h,000h  ;7               #090
db 048h,000h,000h,000h  ;8               #091
db 049h,000h,000h,000h  ;9               #092
db 04Eh,000h,000h,000h  ;+               #093
db 04Bh,000h,000h,000h  ;4               #094
db 04Ch,000h,000h,000h  ;5               #095
db 04Dh,000h,000h,000h  ;6               #096
db 04Fh,000h,000h,000h  ;1               #097
db 050h,000h,000h,000h  ;2               #098
db 051h,000h,000h,000h  ;3               #099
db 0E0h,01Ch,000h,000h  ;entre pav n     #100
db 052h,000h,000h,000h  ;0               #101
db 053h,000h,000h,000h  ;.               #102
db 0E0h,05Bh,000h,000h  ;win g           #103
db 0E0h,05Ch,000h,000h  ;win d           #104
db 0E0h,05Dh,000h,000h  ;list d          #105
db 0E0h,05Eh,000h,000h  ;inc1            #106
db 0E0h,05Fh,000h,000h  ;inc2            #107
db 0E0h,063h,000h,000h  ;inc3            #108
db 000h,000h,000h,000h  ;                #109
db 000h,000h,000h,000h  ;                #110
db 000h,000h,000h,000h  ;                #111
db 000h,000h,000h,000h  ;                #112
db 000h,000h,000h,000h  ;                #113
db 000h,000h,000h,000h  ;                #114
db 000h,000h,000h,000h  ;                #115
db 000h,000h,000h,000h  ;                #116
db 000h,000h,000h,000h  ;                #117
db 000h,000h,000h,000h  ;                #118
db 000h,000h,000h,000h  ;                #119
db 000h,000h,000h,000h  ;                #120
db 000h,000h,000h,000h  ;                #121
db 000h,000h,000h,000h  ;                #122
db 000h,000h,000h,000h  ;                #123
db 000h,000h,000h,000h  ;                #124
db 000h,000h,000h,000h  ;                #125
db 000h,000h,000h,000h  ;                #126
db 000h,000h,000h,000h  ;                #127
db 000h,000h,000h,000h  ;                #128








;**********************************************************
;liste des caract�res utilisable par touche
; caract�re normal, caract�re majuscule, caract�re Alt, caract�re Alt+majuscule

touche_carac:
dd 0,0,0,0                     ;esc             #001
dd 0,0,0,0                     ;F1              #002
dd 0,0,0,0                     ;F2              #003
dd 0,0,0,0                     ;F3              #004
dd 0,0,0,0                     ;F4              #005
dd 0,0,0,0                     ;F5              #006
dd 0,0,0,0                     ;F6              #007
dd 0,0,0,0                     ;F7              #008
dd 0,0,0,0                     ;F8              #009
dd 0,0,0,0                     ;F9              #010
dd 0,0,0,0                     ;F10             #011
dd 0,0,0,0                     ;F11             #012
dd 0,0,0,0                     ;F12             #013
dd 0,0,0,0                     ;impr ecran      #014
dd 0,0,0,0                     ;stop defil      #015
dd 0,0,0,0                     ;pause           #016
dd "`","~",0,0                 ;`               #017
dd "1","!",0,0                 ;1               #018
dd "2","@",0,0                 ;2               #019
dd "3","#",0,0                 ;3               #020
dd "4","$",0,0                 ;4               #021
dd "5","%",0,0                 ;5               #022
dd "6","^",0,0                 ;6               #023
dd "7","&",0,0                 ;7               #024
dd "8","*",0,0                 ;8               #025
dd "9","(",0,0                 ;9               #026   
dd "0",")",0,0                 ;0               #027
dd "-","_",0,0                 ;-               #028
dd "=","+",0,0                 ;=               #029
dd 0,0,0,0                     ;back            #030
dd 0,0,0,0                     ;tab             #031
dd "q","Q",0,0                 ;q               #032
dd "w","W",0,0                 ;w               #033
dd "f","F",0,0                 ;f               #034
dd "p","P",0,0                 ;p               #035
dd "g","G",0,0                 ;g               #036
dd "j","J",0,0                 ;j               #037
dd "l","L",0,0                 ;l               #038
dd "u","U",0,0                 ;u               #039
dd "y","Y",0,0                 ;o               #040
dd ";",":",0,0                 ;p               #041
dd "[","{",0,0                 ;[               #042
dd "]","}",0,0                 ;]               #043
dd 0,0,0,0                     ;entre           #044
dd 0,0,0,0                     ;lock            #045
dd "a","A",0,0                 ;a               #046
dd "r","R",0,0                 ;r               #047
dd "s","S",0,0                 ;s               #048
dd "t","T",0,0                 ;t               #049
dd "d","D",0,0                 ;d               #050
dd "h","H",0,0                 ;h               #051
dd "n","N",0,0                 ;n               #052
dd "e","E",0,0                 ;k               #053
dd "i","I",0,0                 ;l               #054
dd "o","O",0,0                 ;;               #055
dd "'",22h,0,0                 ;'               #056   
dd "\","|",0,0                 ;*               #057
dd 0,0,0,0                     ;maj g           #058
dd 0,0,0,0                     ;                #059
dd "z","Z",0,0                 ;z               #060
dd "x","X",0,0                 ;x               #061
dd "c","C",0,0                 ;c               #062
dd "v","V",0,0                 ;v               #063
dd "b","B",0,0                 ;b               #064
dd "k","K",0,0                 ;k               #065
dd "m","M",0,0                 ;m               #066
dd ",","<",0,0                 ;,               #067
dd ".",">",0,0                 ;.               #068
dd "/","?",0,0                 ;/               #069
dd 0,0,0,0                     ;maj dr          #070
dd 0,0,0,0                     ;ctrl g          #071
dd 0,0,0,0                     ;alt g           #072
dd " "," "," "," "             ;espace          #073
dd 0,0,0,0                     ;alt gr          #074
dd 0,0,0,0                     ;ctrl d          #075
dd 0,0,0,0                     ;inser           #076
dd 0,0,0,0                     ;top             #077
dd 0,0,0,0                     ;page haut       #078
dd 0,0,0,0                     ;suppr           #079
dd 0,0,0,0                     ;fin             #080
dd 0,0,0,0                     ;page bas        #081
dd 0,0,0,0                     ;fl haut         #082
dd 0,0,0,0                     ;fl gauche       #083
dd 0,0,0,0                     ;fl bas          #084
dd 0,0,0,0                     ;fl droit        #085
dd 0,0,0,0                     ;verr num        #086
dd "/","/","/","/"             ;/               #087
dd "*","*","*","*"             ;*               #088
dd "-","-","-","-"             ;-               #089
dd "7","7","7","7"             ;7               #090
dd "8","8","8","8"             ;8               #091
dd "9","9","9","9"             ;9               #092
dd "+","+","+","+"             ;+               #093
dd "4","4","4","4"             ;4               #094
dd "5","5","5","5"             ;5               #095
dd "6","6","6","6"             ;6               #096
dd "1","1","1","1"             ;1               #097
dd "2","2","2","2"             ;2               #098
dd "3","3","3","3"             ;3               #099
dd 0,0,0,0                     ;entre pav n     #100
dd "0","0","0","0"             ;0               #101
dd ".",".",".","."             ;.               #102
dd 0,0,0,0                     ;win g           #103
dd 0,0,0,0                     ;win d           #104
dd 0,0,0,0                     ;list d          #105
dd 0,0,0,0                     ;inc1            #106
dd 0,0,0,0                     ;inc2            #107
dd 0,0,0,0                     ;inc3            #108
dd 0,0,0,0                     ;                #109
dd 0,0,0,0                     ;                #110
dd 0,0,0,0                     ;                #111
dd 0,0,0,0                     ;                #112
dd 0,0,0,0                     ;                #113
dd 0,0,0,0                     ;                #114
dd 0,0,0,0                     ;                #115
dd 0,0,0,0                     ;                #116
dd 0,0,0,0                     ;                #117
dd 0,0,0,0                     ;                #118
dd 0,0,0,0                     ;                #119
dd 0,0,0,0                     ;                #120
dd 0,0,0,0                     ;                #121
dd 0,0,0,0                     ;                #122
dd 0,0,0,0                     ;                #123
dd 0,0,0,0                     ;                #124
dd 0,0,0,0                     ;                #125
dd 0,0,0,0                     ;                #126
dd 0,0,0,0                     ;                #127
dd 0,0,0,0                     ;                #128

















