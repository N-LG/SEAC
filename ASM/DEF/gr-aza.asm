clavier:
;fichier de définition pour clavier azerty spécial Seac

org 0
db "DEFC"
dw touche_codeps2       ;adresse de la définition PS/2
dw touche_usb           ;adresse de la définition usb
dw touche_grec          ;adresse de la définition clavier principale
dw touche_carac         ;adresse de la définition clavier secondaire
dw chasse_grec          ;adresse de la définition chasse
db 17,0                  ;numéros de touches a employer avec la touche CTRL pour basculer d'un jeu de carractère a un autre


include "../NOYAU/DN_CLAV_FR.ASM"

touche_grec:
;**********************************************************
;liste des caractères utilisable par touche
; caractère normal, caractère majuscule, caractère Alt, caractère Alt+majuscule
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
dd "`","~",0,0                 ;²               #017
dd "1","!",0,0                 ;1               #018
dd "2","@",0B2h,0              ;2               #019
dd "3","#",0B3h,0              ;3               #020
dd "4","$",0A3h,0              ;4               #021
dd "5","%",0A7h,0              ;5               #022
dd "6","^",0B6h,0              ;6               #023
dd "7","&",0,0                 ;7               #024
dd "8","*",0A4h,0              ;8               #025
dd "9","(",0A6h,0              ;9               #026    
dd "0",")",0B0h,0              ;0               #027
dd "-","_",0B1h,0              ;°               #028
dd "=","+",0BDh,0              ;+               #029
dd 0,0,0,0                     ;back            #030
dd 0,0,0,0                     ;tab             #031
dd ";",":",0,0                 ;a               #032
dd 3C2h,385h,0,0               ;z               #033
dd 3B5h,395h,020ACh,0          ;e               #034
dd 3C1h,3A1h,0AEh,0            ;r               #035
dd 3C4h,3A4h,0, 0              ;t               #036
dd 3C5h,3A5h,0A5h,0            ;y               #037
dd 3B8h,398h,0,0               ;u               #038
dd 3B9h,399h,0,0               ;i               #039
dd 3BFh,39Fh,0,0               ;o               #040
dd 3C0h,3A0h,0,0               ;p               #041
dd "[","{",0ABh,0              ;^               #042
dd "]","}",0BBh,0              ;$               #043
dd 0,0,0,0                     ;entre           #044
dd 0,0,0,0                     ;lock            #045
dd 3B1h,391h,0,0               ;q               #046
dd 3C3h,3A3h,0,0               ;s               #047
dd 3B4h,394h,0,0               ;d               #048
dd 3C6h,3A6h,0,0               ;f               #049
dd 3B3h,393h,0,0               ;g               #050
dd 3B7h, 397h,0,0              ;h               #051
dd 3BEh,39Eh,0,0               ;j               #052
dd 3BAh,39Ah,0,0               ;k               #053
dd 3BBh,39Bh,0,0               ;l               #054
dd 0384h,0A8h,385h,0           ;m               #055
dd "'",22h,0,0                 ;ù               #056
dd "\","|",0ACh,0              ;µ               #057
dd 0,0,0,0                     ;maj g           #058
dd "<",">",0,0                 ;<               #059
dd 3B6h,396h,0,0               ;w               #060
dd 3C7h,3A7h,0,0               ;x               #061
dd 3C8h,3A8h,0A9h,0            ;c               #062
dd 3C9h,3A9h,0,0               ;v               #063
dd 3B2h,392h,0,0               ;b               #064
dd 3BDh,39Dh,0,0               ;n               #065
dd 3BCh,39Ch,0,0               ;?               #066
dd ",","<",0,0                 ;.               #067
dd ".",">",0,0                 ;/               #068
dd "/","?",0ACh,0              ;!               #069
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
dd 0,0,0,0                     ;                #;119
dd 0,0,0,0                     ;                #120
dd 0,0,0,0                     ;                #121
dd 0,0,0,0                     ;                #122
dd 0,0,0,0                     ;                #123
dd 0,0,0,0                     ;                #124
dd 0,0,0,0                     ;                #125
dd 0,0,0,0                     ;                #126
dd 0,0,0,0                     ;                #127
dd 0,0,0,0                     ;                #128














chasse_grec:
include "../NOYAU/DN_ACC.ASM"

dd 900,913,902 ;Ά
dd 900,917,904 ;Έ
dd 900,919,905 ;Ή
dd 900,921,906 ;Ί
dd 900,927,908 ;Ό
dd 900,933,910 ;Ύ
dd 900,937,911 ;Ώ
dd 901,953,912 ;ΐ
dd 168,921,938 ;Ϊ
dd 168,933,939 ;Ϋ
dd 900,945,940 ;ά
dd 900,949,941 ;έ
dd 900,951,942 ;ή
dd 900,953,943 ;ί
dd 901,965,944 ;ΰ
dd 168,953,970 ;ϊ
dd 168,965,971 ;ϋ


dd 900,959,972 ;ό
dd 900,965,973 ;ύ
dd 900,969,974 ;ώ
dd 885,922,975 ;Ϗ

dd 900,978,979 ;ϓ
dd 168,978,980 ;ϔ