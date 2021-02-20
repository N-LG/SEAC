qemu:   ;definition pour clavier ps2 pour le problème de mélange de touche avec qemu

db "DEFC"
dw touche_codeps2       ;adresse de la définition PS/2
dw 0                    ;adresse de la définition usb
dw 0                    ;adresse de la définition clavier principale
dw 0                    ;adresse de la définition clavier secondaire
dw 0                    ;adresse de la définition chasse
db 0,0                  ;numéros de touches a employer avec la touche CTRL pour basculer d'un jeu de carractère a un autre





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
db 028h,000h,000h,000h  ;²               #017
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
db 01Ah,000h,000h,000h  ;°               #028
db 00Dh,000h,000h,000h  ;+               #029
db 00Eh,000h,000h,000h  ;back            #030
db 00Fh,000h,000h,000h  ;tab             #031
db 01Eh,000h,000h,000h  ;a               #032
db 02Ch,000h,000h,000h  ;z               #033
db 012h,000h,000h,000h  ;e               #034
db 013h,000h,000h,000h  ;r               #035
db 014h,000h,000h,000h  ;t               #036
db 015h,000h,000h,000h  ;y               #037
db 016h,000h,000h,000h  ;u               #038
db 017h,000h,000h,000h  ;i               #039
db 018h,000h,000h,000h  ;o               #040
db 019h,000h,000h,000h  ;p               #041
db 01Bh,000h,000h,000h  ;^               #042
db 027h,000h,000h,000h  ;$               #043 
db 01Ch,000h,000h,000h  ;entre           #044
db 03Ah,000h,000h,000h  ;lock            #045
db 010h,000h,000h,000h  ;q               #046
db 01Fh,000h,000h,000h  ;s               #047
db 020h,000h,000h,000h  ;d               #048
db 021h,000h,000h,000h  ;f               #049
db 022h,000h,000h,000h  ;g               #050
db 023h,000h,000h,000h  ;h               #051
db 024h,000h,000h,000h  ;j               #052
db 025h,000h,000h,000h  ;k               #053
db 026h,000h,000h,000h  ;l               #054
db 032h,000h,000h,000h  ;m               #055  
db 029h,000h,000h,000h  ;ù               #056
db 02Bh,000h,000h,000h  ;*               #057
db 02Ah,000h,000h,000h  ;maj g           #058
db 056h,000h,000h,000h  ;<               #059  ???
db 011h,000h,000h,000h  ;w               #060
db 02Dh,000h,000h,000h  ;x               #061
db 02Eh,000h,000h,000h  ;c               #062
db 02Fh,000h,000h,000h  ;v               #063
db 030h,000h,000h,000h  ;b               #064
db 031h,000h,000h,000h  ;n               #065
db 033h,000h,000h,000h  ;?               #066 
db 034h,000h,000h,000h  ;.               #067 
db 035h,000h,000h,000h  ;/               #068 
db 049h,000h,000h,000h  ;!               #069  ???
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










