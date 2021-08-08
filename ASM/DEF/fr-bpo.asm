frbpo: ;fichier de définition pour clavier bépo

;créer a partir des info trouvé sur:
;    https://download.tuxfamily.org/dvorak/windows/bepo-azerty.klc
;    https://bepo.fr/wiki/Version_1.1
;    https://bepo.fr/wiki/Touches_mortes
;(merci au serveur discord de bepo.fr)
;la définition des touches mortes as été tronqué a cause de la limitation de SEAC

org 0
db "DEFC"
dw 0                    ;adresse de la définition PS/2
dw 0                    ;adresse de la définition usb
dw touche_carac         ;adresse de la définition clavier principale
dw 0                    ;adresse de la définition clavier secondaire
dw touches_mortes       ;adresse de la définition chasse
db 0,0                  ;numéros de touches a employer avec la touche CTRL pour basculer d'un jeu de carractère a un autre






;**********************************************************
;liste des caractères utilisable par touche
; caractère normal, caractère majuscule, caractère Alt, caractère Alt+majuscule
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
dd 24h,23h,2013h,0B6h          ;$               #017
dd 22h,"1",2014h,201Eh         ;1               #018
dd 0ABh,"2",3Ch,201Ch          ;2               #019
dd 0BBh,"3",3Eh,201Dh          ;3               #020
dd 28h,"4",5Bh,2264h           ;4               #021
dd 29h,"5",5Dh,2265h           ;5               #022
dd 40h,"6",5Eh,0               ;6               #023
dd 2Bh,"7",0B1h,0ACh           ;7               #024
dd 2Dh,"8",2212h,0BCh          ;8               #025
dd 2Fh,"9",0F7h,0BDh           ;9               #026    
dd 2Ah,"0",0D7h,0BEh           ;0               #027
dd 3Dh,"°",2260h,2032h         ;=               #028
dd 25h,60h,2030h,2033h         ;%               #029
dd 0,0,0,0                     ;back            #030
dd 0,0,0,0                     ;tab             #031
dd "b","B",7Ch,0A6h            ;b               #032
dd 0E9h,0C9h,0B4h,2DDh         ;é               #033
dd "p","P",26h,0A7h            ;p               #034
dd "o","O",153h,152h           ;o               #035
dd 0E8h,0C8H,060h,60h          ;è               #036
dd 05Eh,21h,0A1h,0             ;^               #037
dd "v","V",2C7h,0              ;v               #038
dd "d","D",0F0h,0D0h           ;d               #039
dd "l","L",338h,0              ;l               #040
dd "j","J",133h,132h           ;j               #041
dd "z","Z",259h,18Fh           ;z               #042
dd "w","W",2D8h,0              ;w               #043
dd 0,0,0,0                     ;entre           #044
dd 0,0,0,0                     ;lock            #045
dd "a","A",0E6h,0C6h           ;a               #046
dd "u","U",0F9h,0D9h           ;u               #047
dd "i","I",0A8h,2D9h           ;i               #048
dd "e","E",20ACh,0A4h          ;e               #049
dd 2Ch,3Bh,2019h,31Bh          ;,               #050
dd "c","C",0A9h,17Fh           ;c               #051
dd "t","T",0FEh,0DEh           ;t               #052
dd "s","S",0DFh,1E9Eh          ;s               #053
dd "r","R",0AEh,02122h         ;r               #054
dd "n","N",7Eh,0               ;n               #055
dd "m","M",0AFh,0BAh           ;m               #056
dd 0E7h,0C7h,0B8h,2Ch          ;ç               #057
dd 0,0,0,0                     ;maj g           #058
dd 0EAh,0CAh,2Fh,0             ;ê               #059
dd 0E0h,0C0h,5Ch,0             ;à               #060
dd "y","Y",7Bh,2018h           ;y               #061
dd "x","X",7Dh,2019h           ;x               #062
dd 2Eh,3Ah,2026h,0B7h          ;.               #063
dd "k","K",7Eh,2328h           ;k               #064
dd 27h,3Fh,0BFh,309h           ;'               #065
dd "q","Q",2DAh,323h           ;q               #066
dd "g","G",0B5h,0              ;g               #067
dd "h","H",2020h,2021h         ;h               #068
dd "f","F",5Fh,202Fh           ;f               #069
dd 0,0,0,0                     ;maj dr          #070
dd 0,0,0,0                     ;ctrl g          #071
dd 0,0,0,0                     ;alt g           #072
dd " ",0A0h,5Fh,202Fh          ;espace          #073
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



touches_mortes:
dd 2d9h,0041h,0226h ; A -> Ȧ
dd 2d9h,0100h,01e0h ; Ā -> Ǡ
dd 2d9h,0061h,0227h ; a -> ȧ
dd 2d9h,0101h,01e1h ; ā -> ǡ
dd 2d9h,0042h,1e02h ; B -> Ḃ
dd 2d9h,0062h,1e03h ; b -> ḃ
dd 2d9h,0043h,010ah ; C -> Ċ
dd 2d9h,0063h,010bh ; c -> ċ
dd 2d9h,0044h,1e0ah ; D -> Ḋ
dd 2d9h,0064h,1e0bh ; d -> ḋ
dd 2d9h,0045h,0116h ; E -> Ė
dd 2d9h,0065h,0117h ; e -> ė
dd 2d9h,0046h,1e1eh ; F -> Ḟ
dd 2d9h,0066h,1e1fh ; f -> ḟ
dd 2d9h,0047h,0120h ; G -> Ġ
dd 2d9h,0067h,0121h ; g -> ġ
dd 2d9h,0048h,1e22h ; H -> Ḣ
dd 2d9h,0068h,1e23h ; h -> ḣ
dd 2d9h,0049h,0130h ; I -> İ
dd 2d9h,0069h,0131h ; i -> ı
dd 2d9h,006ah,0237h ; j -> ȷ
dd 2d9h,004ch,013fh ; L -> Ŀ
dd 2d9h,006ch,0140h ; l -> ŀ
dd 2d9h,017fh,1e9bh ; ſ -> ẛ
dd 2d9h,004dh,1e40h ; M -> Ṁ
dd 2d9h,006dh,1e41h ; m -> ṁ
dd 2d9h,004eh,1e44h ; N -> Ṅ
dd 2d9h,006eh,1e45h ; n -> ṅ
dd 2d9h,004fh,022eh ; O -> Ȯ
dd 2d9h,014ch,0230h ; Ō -> Ȱ
dd 2d9h,006fh,022fh ; o -> ȯ
dd 2d9h,014dh,0231h ; ō -> ȱ
dd 2d9h,0050h,1e56h ; P -> Ṗ
dd 2d9h,0070h,1e57h ; p -> ṗ
dd 2d9h,0052h,1e58h ; R -> Ṙ
dd 2d9h,0072h,1e59h ; r -> ṙ
dd 2d9h,0053h,1e60h ; S -> Ṡ
dd 2d9h,015ah,1e64h ; Ś -> Ṥ
dd 2d9h,1e62h,1e68h ; Ṣ -> Ṩ
dd 2d9h,0160h,1e66h ; Š -> Ṧ
dd 2d9h,0073h,1e61h ; s -> ṡ
dd 2d9h,015bh,1e65h ; ś -> ṥ
dd 2d9h,1e63h,1e69h ; ṣ -> ṩ
dd 2d9h,0161h,1e67h ; š -> ṧ
dd 2d9h,0054h,1e6ah ; T -> Ṫ
dd 2d9h,0074h,1e6bh ; t -> ṫ
dd 2d9h,0057h,1e86h ; W -> Ẇ
dd 2d9h,0077h,1e87h ; w -> ẇ
dd 2d9h,0058h,1e8ah ; X -> Ẋ
dd 2d9h,0078h,1e8bh ; x -> ẋ
dd 2d9h,0059h,1e8eh ; Y -> Ẏ
dd 2d9h,0079h,1e8fh ; y -> ẏ
dd 2d9h,005ah,017bh ; Z -> Ż
dd 2d9h,007ah,017ch ; z -> ż
dd 2d9h,2d9h,2d9h ; ˙ -> ˙
dd 2d9h,00a0h,0307h ;   -> ̇
;dd 2d9h,0020h,2d9h ;   -> ˙

dd 0B4h,0041h,00c1h ; A -> Á
dd 0B4h,0102h,1eaeh ; Ă -> Ắ
dd 0B4h,00c2h,1ea4h ; Â -> Ấ
dd 0B4h,00c5h,01fah ; Å -> Ǻ
dd 0B4h,0061h,00e1h ; a -> á
dd 0B4h,0103h,1eafh ; ă -> ắ
dd 0B4h,00e2h,1ea5h ; â -> ấ
dd 0B4h,00e5h,01fbh ; å -> ǻ
dd 0B4h,00c6h,01fch ; Æ -> Ǽ
dd 0B4h,00e6h,01fdh ; æ -> ǽ
dd 0B4h,0043h,0106h ; C -> Ć
dd 0B4h,00c7h,1e08h ; Ç -> Ḉ
dd 0B4h,0063h,0107h ; c -> ć
dd 0B4h,00e7h,1e09h ; ç -> ḉ
dd 0B4h,0045h,00c9h ; E -> É
dd 0B4h,00cah,1ebeh ; Ê -> Ế
dd 0B4h,0112h,1e16h ; Ē -> Ḗ
dd 0B4h,0065h,00e9h ; e -> é
dd 0B4h,00eah,1ebfh ; ê -> ế
dd 0B4h,0113h,1e17h ; ē -> ḗ
dd 0B4h,0047h,01f4h ; G -> Ǵ
dd 0B4h,0067h,01f5h ; g -> ǵ
dd 0B4h,0049h,00cdh ; I -> Í
dd 0B4h,00cfh,1e2eh ; Ï -> Ḯ
dd 0B4h,0069h,00edh ; i -> í
dd 0B4h,00efh,1e2fh ; ï -> ḯ
dd 0B4h,004bh,1e30h ; K -> Ḱ
dd 0B4h,006bh,1e31h ; k -> ḱ
dd 0B4h,004ch,0139h ; L -> Ĺ
dd 0B4h,006ch,013ah ; l -> ĺ
dd 0B4h,004dh,1e3eh ; M -> Ḿ
dd 0B4h,006dh,1e3fh ; m -> ḿ
dd 0B4h,004eh,0143h ; N -> Ń
dd 0B4h,006eh,0144h ; n -> ń
dd 0B4h,004fh,00d3h ; O -> Ó
dd 0B4h,00d4h,1ed0h ; Ô -> Ố
dd 0B4h,01a0h,1edah ; Ơ -> Ớ
dd 0B4h,014ch,1e52h ; Ō -> Ṓ
dd 0B4h,00d8h,01feh ; Ø -> Ǿ
dd 0B4h,00d5h,1e4ch ; Õ -> Ṍ
dd 0B4h,006fh,00f3h ; o -> ó
dd 0B4h,00f4h,1ed1h ; ô -> ố
dd 0B4h,01a1h,1edbh ; ơ -> ớ
dd 0B4h,014dh,1e53h ; ō -> ṓ
dd 0B4h,00f8h,01ffh ; ø -> ǿ
dd 0B4h,00f5h,1e4dh ; õ -> ṍ
dd 0B4h,0050h,1e54h ; P -> Ṕ
dd 0B4h,0070h,1e55h ; p -> ṕ
dd 0B4h,0052h,0154h ; R -> Ŕ
dd 0B4h,0072h,0155h ; r -> ŕ
dd 0B4h,1e60h,1e64h ; Ṡ -> Ṥ
dd 0B4h,0053h,015ah ; S -> Ś
dd 0B4h,1e61h,1e65h ; ṡ -> ṥ
dd 0B4h,0073h,015bh ; s -> ś
dd 0B4h,0055h,00dah ; U -> Ú
dd 0B4h,00dch,01d7h ; Ü -> Ǘ
dd 0B4h,0056h,01d7h ; V -> Ǘ
dd 0B4h,01afh,1ee8h ; Ư -> Ứ
dd 0B4h,0168h,1e78h ; Ũ -> Ṹ
dd 0B4h,0075h,00fah ; u -> ú
dd 0B4h,00fch,01d8h ; ü -> ǘ
dd 0B4h,0076h,01d8h ; v -> ǘ
dd 0B4h,01b0h,1ee9h ; ư -> ứ
dd 0B4h,0169h,1e79h ; ũ -> ṹ
dd 0B4h,0057h,1e82h ; W -> Ẃ
dd 0B4h,0077h,1e83h ; w -> ẃ
dd 0B4h,0059h,00ddh ; Y -> Ý
dd 0B4h,0079h,00fdh ; y -> ý
dd 0B4h,005ah,0179h ; Z -> Ź
dd 0B4h,007ah,017ah ; z -> ź
dd 0B4h,0B4h,0B4h ; ´ -> ´
dd 0B4h,00a0h,0301h ;   -> ́
dd 0B4h,0020h,0027h ;   -> '

dd 323h,0041h,1ea0h ; A -> Ạ
dd 323h,0102h,1eb6h ; Ă -> Ặ
dd 323h,00c2h,1each ; Â -> Ậ
dd 323h,0061h,1ea1h ; a -> ạ
dd 323h,0103h,1eb7h ; ă -> ặ
dd 323h,00e2h,1eadh ; â -> ậ
dd 323h,0042h,1e04h ; B -> Ḅ
dd 323h,0062h,1e05h ; b -> ḅ
dd 323h,0044h,1e0ch ; D -> Ḍ
dd 323h,0064h,1e0dh ; d -> ḍ
dd 323h,0045h,1eb8h ; E -> Ẹ
dd 323h,00cah,1ec6h ; Ê -> Ệ
dd 323h,0065h,1eb9h ; e -> ẹ
dd 323h,00eah,1ec7h ; ê -> ệ
dd 323h,0048h,1e24h ; H -> Ḥ
dd 323h,0068h,1e25h ; h -> ḥ
dd 323h,0049h,1ecah ; I -> Ị
dd 323h,0069h,1ecbh ; i -> ị
dd 323h,004bh,1e32h ; K -> Ḳ
dd 323h,006bh,1e33h ; k -> ḳ
dd 323h,004ch,1e36h ; L -> Ḷ
dd 323h,006ch,1e37h ; l -> ḷ
dd 323h,004dh,1e42h ; M -> Ṃ
dd 323h,006dh,1e43h ; m -> ṃ
dd 323h,004eh,1e46h ; N -> Ṇ
dd 323h,006eh,1e47h ; n -> ṇ
dd 323h,004fh,1ecch ; O -> Ọ
dd 323h,00d4h,1ed8h ; Ô -> Ộ
dd 323h,01a0h,1ee2h ; Ơ -> Ợ
dd 323h,006fh,1ecdh ; o -> ọ
dd 323h,00f4h,1ed9h ; ô -> ộ
dd 323h,01a1h,1ee3h ; ơ -> ợ
dd 323h,0052h,1e5ah ; R -> Ṛ
dd 323h,0072h,1e5bh ; r -> ṛ
dd 323h,1e60h,1e68h ; Ṡ -> Ṩ
dd 323h,0053h,1e62h ; S -> Ṣ
dd 323h,1e61h,1e69h ; ṡ -> ṩ
dd 323h,0073h,1e63h ; s -> ṣ
dd 323h,0054h,1e6ch ; T -> Ṭ
dd 323h,0074h,1e6dh ; t -> ṭ
dd 323h,0055h,1ee4h ; U -> Ụ
dd 323h,01afh,1ef0h ; Ư -> Ự
dd 323h,0075h,1ee5h ; u -> ụ
dd 323h,01b0h,1ef1h ; ư -> ự
dd 323h,0056h,1e7eh ; V -> Ṿ
dd 323h,0076h,1e7fh ; v -> ṿ
dd 323h,0057h,1e88h ; W -> Ẉ
dd 323h,0077h,1e89h ; w -> ẉ
dd 323h,0059h,1ef4h ; Y -> Ỵ
dd 323h,0079h,1ef5h ; y -> ỵ
dd 323h,005ah,1e92h ; Z -> Ẓ
dd 323h,007ah,1e93h ; z -> ẓ
dd 323h,323h,323h ; ̣ -> ̣
;dd 323h,00a0h,323h ;   -> ̣
;dd 323h,0020h,323h ;   -> ̣

dd 2d8h,00c1h,1eaeh ; Á -> Ắ
dd 2d8h,1ea0h,1eb6h ; Ạ -> Ặ
dd 2d8h,0041h,0102h ; A -> Ă
dd 2d8h,00c0h,1eb0h ; À -> Ằ
dd 2d8h,1ea2h,1eb2h ; Ả -> Ẳ
dd 2d8h,00c3h,1eb4h ; Ã -> Ẵ
dd 2d8h,00e1h,1eafh ; á -> ắ
dd 2d8h,1ea1h,1eb7h ; ạ -> ặ
dd 2d8h,0061h,0103h ; a -> ă
dd 2d8h,00e0h,1eb1h ; à -> ằ
dd 2d8h,1ea3h,1eb3h ; ả -> ẳ
dd 2d8h,00e3h,1eb5h ; ã -> ẵ
dd 2d8h,0045h,0114h ; E -> Ĕ
dd 2d8h,0228h,1e1ch ; Ȩ -> Ḝ
dd 2d8h,0065h,0115h ; e -> ĕ
dd 2d8h,0229h,1e1dh ; ȩ -> ḝ
dd 2d8h,0047h,011eh ; G -> Ğ
dd 2d8h,0067h,011fh ; g -> ğ
dd 2d8h,0049h,012ch ; I -> Ĭ
dd 2d8h,0069h,012dh ; i -> ĭ
dd 2d8h,004fh,014eh ; O -> Ŏ
dd 2d8h,006fh,014fh ; o -> ŏ
dd 2d8h,0055h,016ch ; U -> Ŭ
dd 2d8h,0075h,016dh ; u -> ŭ
dd 2d8h,2d8h,2d8h ; ˘ -> ˘
dd 2d8h,0a0h,0306h ;   -> ̆
;dd 2d8h,20h,2d8h ;   -> ˘

dd 2c7h,0028h,208dh ; ( -> ₍
dd 2c7h,0029h,208eh ; ) -> ₎
dd 2c7h,002bh,208ah ; + -> ₊
dd 2c7h,002dh,208bh ; - -> ₋
dd 2c7h,0030h,2080h ; 0 -> ₀
dd 2c7h,0031h,2081h ; 1 -> ₁
dd 2c7h,0032h,2082h ; 2 -> ₂
dd 2c7h,0033h,2083h ; 3 -> ₃
dd 2c7h,0034h,2084h ; 4 -> ₄
dd 2c7h,0035h,2085h ; 5 -> ₅
dd 2c7h,0036h,2086h ; 6 -> ₆
dd 2c7h,0037h,2087h ; 7 -> ₇
dd 2c7h,0038h,2088h ; 8 -> ₈
dd 2c7h,0039h,2089h ; 9 -> ₉
dd 2c7h,003dh,208ch ; = -> ₌
dd 2c7h,0041h,01cdh ; A -> Ǎ
dd 2c7h,0061h,01ceh ; a -> ǎ
dd 2c7h,0043h,010ch ; C -> Č
dd 2c7h,0063h,010dh ; c -> č
dd 2c7h,0044h,010eh ; D -> Ď
dd 2c7h,0064h,010fh ; d -> ď
dd 2c7h,01f2h,01c5h ; ǲ -> ǅ
dd 2c7h,0045h,011ah ; E -> Ě
dd 2c7h,0065h,011bh ; e -> ě
dd 2c7h,0047h,01e6h ; G -> Ǧ
dd 2c7h,0067h,01e7h ; g -> ǧ
dd 2c7h,0048h,021eh ; H -> Ȟ
dd 2c7h,0068h,021fh ; h -> ȟ
dd 2c7h,0049h,01cfh ; I -> Ǐ
dd 2c7h,0069h,01d0h ; i -> ǐ
dd 2c7h,006ah,01f0h ; j -> ǰ
dd 2c7h,004bh,01e8h ; K -> Ǩ
dd 2c7h,006bh,01e9h ; k -> ǩ
dd 2c7h,004ch,013dh ; L -> Ľ
dd 2c7h,006ch,013eh ; l -> ľ
dd 2c7h,004eh,0147h ; N -> Ň
dd 2c7h,006eh,0148h ; n -> ň
dd 2c7h,004fh,01d1h ; O -> Ǒ
dd 2c7h,006fh,01d2h ; o -> ǒ
dd 2c7h,0052h,0158h ; R -> Ř
dd 2c7h,0072h,0159h ; r -> ř
dd 2c7h,1e60h,1e66h ; Ṡ -> Ṧ
dd 2c7h,0053h,0160h ; S -> Š
dd 2c7h,1e61h,1e67h ; ṡ -> ṧ
dd 2c7h,0073h,0161h ; s -> š
dd 2c7h,0054h,0164h ; T -> Ť
dd 2c7h,0074h,0165h ; t -> ť
dd 2c7h,0055h,01d3h ; U -> Ǔ
dd 2c7h,00dch,01d9h ; Ü -> Ǚ
dd 2c7h,0056h,01d9h ; V -> Ǚ
dd 2c7h,0075h,01d4h ; u -> ǔ
dd 2c7h,00fch,01dah ; ü -> ǚ
dd 2c7h,0076h,01dah ; v -> ǚ
dd 2c7h,005ah,017dh ; Z -> Ž
dd 2c7h,007ah,017eh ; z -> ž
dd 2c7h,2c7h,2c7h ; ˇ -> ˇ
dd 2c7h,00a0h,030ch ;   -> ̌
;dd 2c7h,0020h,2c7h ;   -> ˇ

dd 0B8h,0106h,1e08h ; Ć -> Ḉ
dd 0B8h,0043h,00c7h ; C -> Ç
dd 0B8h,20a1h,20b5h ; ₡ -> ₵
dd 0B8h,0107h,1e09h ; ć -> ḉ
dd 0B8h,0063h,00e7h ; c -> ç
dd 0B8h,00a2h,20b5h ; ¢ -> ₵
dd 0B8h,0044h,1e10h ; D -> Ḑ
dd 0B8h,0064h,1e11h ; d -> ḑ
dd 0B8h,0114h,1e1ch ; Ĕ -> Ḝ
dd 0B8h,0045h,0228h ; E -> Ȩ
dd 0B8h,0115h,1e1dh ; ĕ -> ḝ
dd 0B8h,0065h,0229h ; e -> ȩ
dd 0B8h,0047h,0122h ; G -> Ģ
dd 0B8h,0067h,0123h ; g -> ģ
dd 0B8h,0048h,1e28h ; H -> Ḩ
dd 0B8h,0068h,1e29h ; h -> ḩ
dd 0B8h,004bh,0136h ; K -> Ķ
dd 0B8h,006bh,0137h ; k -> ķ
dd 0B8h,004ch,013bh ; L -> Ļ
dd 0B8h,006ch,013ch ; l -> ļ
dd 0B8h,004eh,0145h ; N -> Ņ
dd 0B8h,006eh,0146h ; n -> ņ
dd 0B8h,0052h,0156h ; R -> Ŗ
dd 0B8h,0072h,0157h ; r -> ŗ
dd 0B8h,0053h,015eh ; S -> Ş
dd 0B8h,0073h,015fh ; s -> ş
dd 0B8h,0054h,0162h ; T -> Ţ
dd 0B8h,0074h,0163h ; t -> ţ
dd 0B8h,0B8h,0B8h ; ¸ -> ¸
dd 0B8h,00a0h,0327h ;   -> ̧
;dd 0B8h,0020h,0B8h ;   -> ¸

dd 05Eh,0028h,207dh ; ( -> ⁽
dd 05Eh,0029h,207eh ; ) -> ⁾
dd 05Eh,002bh,207ah ; + -> ⁺
dd 05Eh,002dh,207bh ; - -> ⁻
dd 05Eh,0030h,2070h ; 0 -> ⁰
dd 05Eh,0031h,00b9h ; 1 -> ¹
dd 05Eh,0032h,00b2h ; 2 -> ²
dd 05Eh,0033h,00b3h ; 3 -> ³
dd 05Eh,0034h,2074h ; 4 -> ⁴
dd 05Eh,0035h,2075h ; 5 -> ⁵
dd 05Eh,0036h,2076h ; 6 -> ⁶
dd 05Eh,0037h,2077h ; 7 -> ⁷
dd 05Eh,0038h,2078h ; 8 -> ⁸
dd 05Eh,0039h,2079h ; 9 -> ⁹
dd 05Eh,003dh,207ch ; = -> ⁼
dd 05Eh,00c1h,1ea4h ; Á -> Ấ
dd 05Eh,1ea0h,1each ; Ạ -> Ậ
dd 05Eh,0041h,00c2h ; A -> Â
dd 05Eh,00c0h,1ea6h ; À -> Ầ
dd 05Eh,1ea2h,1ea8h ; Ả -> Ẩ
dd 05Eh,00c3h,1eaah ; Ã -> Ẫ
dd 05Eh,00e1h,1ea5h ; á -> ấ
dd 05Eh,1ea1h,1eadh ; ạ -> ậ
dd 05Eh,0061h,00e2h ; a -> â
dd 05Eh,00e0h,1ea7h ; à -> ầ
dd 05Eh,1ea3h,1ea9h ; ả -> ẩ
dd 05Eh,00e3h,1eabh ; ã -> ẫ
dd 05Eh,0043h,0108h ; C -> Ĉ
dd 05Eh,0063h,0109h ; c -> ĉ
dd 05Eh,00c9h,1ebeh ; É -> Ế
dd 05Eh,1eb8h,1ec6h ; Ẹ -> Ệ
dd 05Eh,0045h,00cah ; E -> Ê
dd 05Eh,00c8h,1ec0h ; È -> Ề
dd 05Eh,1ebah,1ec2h ; Ẻ -> Ể
dd 05Eh,1ebch,1ec4h ; Ẽ -> Ễ
dd 05Eh,00e9h,1ebfh ; é -> ế
dd 05Eh,1eb9h,1ec7h ; ẹ -> ệ
dd 05Eh,0065h,00eah ; e -> ê
dd 05Eh,00e8h,1ec1h ; è -> ề
dd 05Eh,1ebbh,1ec3h ; ẻ -> ể
dd 05Eh,1ebdh,1ec5h ; ẽ -> ễ
dd 05Eh,0047h,011ch ; G -> Ĝ
dd 05Eh,0067h,011dh ; g -> ĝ
dd 05Eh,0048h,0124h ; H -> Ĥ
dd 05Eh,0068h,0125h ; h -> ĥ
dd 05Eh,0049h,00ceh ; I -> Î
dd 05Eh,0069h,00eeh ; i -> î
dd 05Eh,004ah,0134h ; J -> Ĵ
dd 05Eh,006ah,0135h ; j -> ĵ
dd 05Eh,00d3h,1ed0h ; Ó -> Ố
dd 05Eh,1ecch,1ed8h ; Ọ -> Ộ
dd 05Eh,004fh,00d4h ; O -> Ô
dd 05Eh,00d2h,1ed2h ; Ò -> Ồ
dd 05Eh,1eceh,1ed4h ; Ỏ -> Ổ
dd 05Eh,00d5h,1ed6h ; Õ -> Ỗ
dd 05Eh,00f3h,1ed1h ; ó -> ố
dd 05Eh,1ecdh,1ed9h ; ọ -> ộ
dd 05Eh,006fh,00f4h ; o -> ô
dd 05Eh,00f2h,1ed3h ; ò -> ồ
dd 05Eh,1ecfh,1ed5h ; ỏ -> ổ
dd 05Eh,00f5h,1ed7h ; õ -> ỗ
dd 05Eh,0053h,015ch ; S -> Ŝ
dd 05Eh,0073h,015dh ; s -> ŝ
dd 05Eh,0055h,00dbh ; U -> Û
dd 05Eh,0075h,00fbh ; u -> û
dd 05Eh,0057h,0174h ; W -> Ŵ
dd 05Eh,0077h,0175h ; w -> ŵ
dd 05Eh,0059h,0176h ; Y -> Ŷ
dd 05Eh,0079h,0177h ; y -> ŷ
dd 05Eh,005ah,1e90h ; Z -> Ẑ
dd 05Eh,007ah,1e91h ; z -> ẑ
dd 05Eh,05Eh,05Eh ; ^ -> ^
dd 05Eh,00a0h,0302h ;   -> ̂
;dd 05Eh,0020h,05Eh ;   -> ^

dd 0A4h,0041h,20b3h ; A -> ₳
dd 0A4h,0061h,060bh ; a -> ؋
dd 0A4h,0042h,20b1h ; B -> ₱
dd 0A4h,0062h,0e3fh ; b -> ฿
dd 0A4h,00c7h,20b5h ; Ç -> ₵
dd 0A4h,0043h,20a1h ; C -> ₡
dd 0A4h,00e7h,20b5h ; ç -> ₵
dd 0A4h,0063h,00a2h ; c -> ¢
dd 0A4h,0044h,20afh ; D -> ₯
dd 0A4h,0064h,20abh ; d -> ₫
dd 0A4h,0045h,20a0h ; E -> ₠
dd 0A4h,0065h,20ach ; e -> €
dd 0A4h,0046h,20a3h ; F -> ₣
dd 0A4h,0066h,0192h ; f -> ƒ
dd 0A4h,0047h,20b2h ; G -> ₲
dd 0A4h,0067h,20b2h ; g -> ₲
dd 0A4h,0048h,20B4h ; H -> ₴
dd 0A4h,0068h,20B4h ; h -> ₴
dd 0A4h,0049h,17dbh ; I -> ៛
dd 0A4h,0069h,0fdfch ; i -> ﷼
dd 0A4h,004bh,20adh ; K -> ₭
dd 0A4h,006bh,20adh ; k -> ₭
dd 0A4h,004ch,20A4h ; L -> ₤
dd 0A4h,006ch,00a3h ; l -> £
dd 0A4h,004dh,2133h ; M -> ℳ
dd 0A4h,006dh,20a5h ; m -> ₥
dd 0A4h,004eh,20a6h ; N -> ₦
dd 0A4h,006eh,20a6h ; n -> ₦
dd 0A4h,004fh,0af1h ; O -> ૱
dd 0A4h,006fh,0bf9h ; o -> ௹
dd 0A4h,0050h,20a7h ; P -> ₧
dd 0A4h,0070h,20b0h ; p -> ₰
dd 0A4h,0072h,20a2h ; r -> ₢
dd 0A4h,0052h,20a8h ; R -> ₨
dd 0A4h,0053h,0024h ; S -> $
dd 0A4h,0073h,20aah ; s -> ₪
dd 0A4h,0054h,20aeh ; T -> ₮
dd 0A4h,0074h,09f3h ; t -> ৳
dd 0A4h,00deh,09f2h ; Þ -> ৲
dd 0A4h,00feh,09f2h ; þ -> ৲
dd 0A4h,0055h,5713h ; U -> 圓
dd 0A4h,0075h,5143h ; u -> 元
dd 0A4h,0057h,20a9h ; W -> ₩
dd 0A4h,0077h,20a9h ; w -> ₩
dd 0A4h,0059h,5186h ; Y -> 円
dd 0A4h,0079h,00a5h ; y -> ¥
dd 0A4h,0A4h,0A4h ; ¤ -> ¤
;dd 0A4h,00a0h,0A4h ;   -> ¤
;dd 0A4h,0020h,0A4h ;   -> ¤

dd 2Ch,0053h,0218h ; S -> Ș
dd 2Ch,0073h,0219h ; s -> ș
dd 2Ch,0054h,021ah ; T -> Ț
dd 2Ch,0074h,021bh ; t -> ț
dd 2Ch,002ch,002ch ; , -> ,
;dd 2Ch,00a0h,0326h ;   -> ̦
;dd 2Ch,0020h,002ch ;   -> ,

dd 0A8h,0041h,00c4h ; A -> Ä
dd 0A8h,0100h,01deh ; Ā -> Ǟ
dd 0A8h,0061h,00e4h ; a -> ä
dd 0A8h,0101h,01dfh ; ā -> ǟ
dd 0A8h,0045h,00cbh ; E -> Ë
dd 0A8h,0065h,00ebh ; e -> ë
dd 0A8h,0048h,1e26h ; H -> Ḧ
dd 0A8h,0068h,1e27h ; h -> ḧ
dd 0A8h,00cdh,1e2eh ; Í -> Ḯ
dd 0A8h,0049h,00cfh ; I -> Ï
dd 0A8h,00edh,1e2fh ; í -> ḯ
dd 0A8h,0069h,00efh ; i -> ï
dd 0A8h,004fh,00d6h ; O -> Ö
dd 0A8h,014ch,022ah ; Ō -> Ȫ
dd 0A8h,00d5h,1e4eh ; Õ -> Ṏ
dd 0A8h,006fh,00f6h ; o -> ö
dd 0A8h,014dh,022bh ; ō -> ȫ
dd 0A8h,00f5h,1e4fh ; õ -> ṏ
dd 0A8h,0074h,1e97h ; t -> ẗ
dd 0A8h,00dah,01d7h ; Ú -> Ǘ
dd 0A8h,01d3h,01d9h ; Ǔ -> Ǚ
dd 0A8h,0055h,00dch ; U -> Ü
dd 0A8h,00d9h,01dbh ; Ù -> Ǜ
dd 0A8h,016ah,01d5h ; Ū -> Ǖ
dd 0A8h,00fah,01d8h ; ú -> ǘ
dd 0A8h,01d4h,01dah ; ǔ -> ǚ
dd 0A8h,0075h,00fch ; u -> ü
dd 0A8h,00f9h,01dch ; ù -> ǜ
dd 0A8h,016bh,01d6h ; ū -> ǖ
dd 0A8h,0057h,1e84h ; W -> Ẅ
dd 0A8h,0077h,1e85h ; w -> ẅ
dd 0A8h,0058h,1e8ch ; X -> Ẍ
dd 0A8h,0078h,1e8dh ; x -> ẍ
dd 0A8h,0059h,0178h ; Y -> Ÿ
dd 0A8h,0079h,00ffh ; y -> ÿ
dd 0A8h,0A8h,0A8h ; ¨ -> ¨
;dd 0A8h,00a0h,0308h ;   -> ̈
;dd 0A8h,0020h,0022h ;   -> "

dd 2DDh,004fh,0150h ; O -> Ő
dd 2DDh,006fh,0151h ; o -> ő
dd 2DDh,0055h,0170h ; U -> Ű
dd 2DDh,0075h,0171h ; u -> ű
dd 2DDh,02ddh,02ddh ; ˝ -> ˝
;dd 2DDh,00a0h,030bh ;   -> ̋
;dd 2DDh,0020h,02ddh ;   -> ˝

dd 60h,0102h,1eb0h ; Ă -> Ằ
dd 60h,00c2h,1ea6h ; Â -> Ầ
dd 60h,0041h,00c0h ; A -> À
dd 60h,0103h,1eb1h ; ă -> ằ
dd 60h,00e2h,1ea7h ; â -> ầ
dd 60h,0061h,00e0h ; a -> à
dd 60h,00cah,1ec0h ; Ê -> Ề
dd 60h,0045h,00c8h ; E -> È
dd 60h,0112h,1e14h ; Ē -> Ḕ
dd 60h,00eah,1ec1h ; ê -> ề
dd 60h,0065h,00e8h ; e -> è
dd 60h,0113h,1e15h ; ē -> ḕ
dd 60h,0049h,00cch ; I -> Ì
dd 60h,0069h,00ech ; i -> ì
dd 60h,004eh,01f8h ; N -> Ǹ
dd 60h,006eh,01f9h ; n -> ǹ
dd 60h,00d4h,1ed2h ; Ô -> Ồ
dd 60h,004fh,00d2h ; O -> Ò
dd 60h,01a0h,1edch ; Ơ -> Ờ
dd 60h,014ch,1e50h ; Ō -> Ṑ
dd 60h,00f4h,1ed3h ; ô -> ồ
dd 60h,006fh,00f2h ; o -> ò
dd 60h,01a1h,1eddh ; ơ -> ờ
dd 60h,014dh,1e51h ; ō -> ṑ
dd 60h,00dch,01dbh ; Ü -> Ǜ
dd 60h,0056h,01dbh ; V -> Ǜ
dd 60h,0055h,00d9h ; U -> Ù
dd 60h,01afh,1eeah ; Ư -> Ừ
dd 60h,00fch,01dch ; ü -> ǜ
dd 60h,0076h,01dch ; v -> ǜ
dd 60h,0075h,00f9h ; u -> ù
dd 60h,01b0h,1eebh ; ư -> ừ
dd 60h,0057h,1e80h ; W -> Ẁ
dd 60h,0077h,1e81h ; w -> ẁ
dd 60h,0059h,1ef2h ; Y -> Ỳ
dd 60h,0079h,1ef3h ; y -> ỳ
dd 60h,60h,60h ; ` -> `
;dd 60h,0a0h,0300h ;   -> ̀
;dd 60h,0020h,60h ;   -> `

dd 0B5h,0041h,0391h ; A -> Α
dd 0B5h,0061h,03b1h ; a -> α
dd 0B5h,0042h,0392h ; B -> Β
dd 0B5h,0062h,03b2h ; b -> β
dd 0B5h,0044h,0394h ; D -> Δ
dd 0B5h,0064h,03b4h ; d -> δ
dd 0B5h,0045h,0395h ; E -> Ε
dd 0B5h,0065h,03b5h ; e -> ε
dd 0B5h,0046h,03a6h ; F -> Φ
dd 0B5h,0066h,03c6h ; f -> φ
dd 0B5h,0047h,0393h ; G -> Γ
dd 0B5h,0067h,03b3h ; g -> γ
dd 0B5h,0048h,0397h ; H -> Η
dd 0B5h,0068h,03b7h ; h -> η
dd 0B5h,0049h,0399h ; I -> Ι
dd 0B5h,0069h,03b9h ; i -> ι
dd 0B5h,004ah,0398h ; J -> Θ
dd 0B5h,006ah,03b8h ; j -> θ
dd 0B5h,004bh,039ah ; K -> Κ
dd 0B5h,006bh,03bah ; k -> κ
dd 0B5h,004ch,039bh ; L -> Λ
dd 0B5h,006ch,03bbh ; l -> λ
dd 0B5h,004dh,039ch ; M -> Μ
dd 0B5h,006dh,03bch ; m -> μ
dd 0B5h,004eh,039dh ; N -> Ν
dd 0B5h,006eh,03bdh ; n -> ν
dd 0B5h,004fh,039fh ; O -> Ο
dd 0B5h,006fh,03bfh ; o -> ο
dd 0B5h,0050h,03a0h ; P -> Π
dd 0B5h,0070h,03c0h ; p -> π
dd 0B5h,0051h,03a7h ; Q -> Χ
dd 0B5h,0071h,03c7h ; q -> χ
dd 0B5h,0052h,03a1h ; R -> Ρ
dd 0B5h,0072h,03c1h ; r -> ρ
dd 0B5h,0053h,03a3h ; S -> Σ
dd 0B5h,0073h,03c3h ; s -> σ
dd 0B5h,0054h,03a4h ; T -> Τ
dd 0B5h,0074h,03c4h ; t -> τ
dd 0B5h,0055h,03a5h ; U -> Υ
dd 0B5h,0075h,03c5h ; u -> υ
dd 0B5h,0057h,03a9h ; W -> Ω
dd 0B5h,0077h,03c9h ; w -> ω
dd 0B5h,0058h,039eh ; X -> Ξ
dd 0B5h,0078h,03beh ; x -> ξ
dd 0B5h,0059h,03a8h ; Y -> Ψ
dd 0B5h,0079h,03c8h ; y -> ψ
dd 0B5h,005ah,0396h ; Z -> Ζ
dd 0B5h,007ah,03b6h ; z -> ζ
dd 0B5h,0B5h,0B5h ; µ -> µ
;dd 0B5h,0a0h,0B5h ;   -> µ
;dd 0B5h,20h,0B5h ;   -> µ

dd 309h,0102h,1eb2h ; Ă -> Ẳ
dd 309h,00c2h,1ea8h ; Â -> Ẩ
dd 309h,0041h,1ea2h ; A -> Ả
dd 309h,0103h,1eb3h ; ă -> ẳ
dd 309h,00e2h,1ea9h ; â -> ẩ
dd 309h,0061h,1ea3h ; a -> ả
dd 309h,0042h,0181h ; B -> Ɓ
dd 309h,0062h,0253h ; b -> ɓ
dd 309h,0043h,0187h ; C -> Ƈ
dd 309h,0063h,0188h ; c -> ƈ
dd 309h,0044h,018ah ; D -> Ɗ
dd 309h,0064h,0257h ; d -> ɗ
dd 309h,0256h,1d91h ; ɖ -> ᶑ
dd 309h,00cah,1ec2h ; Ê -> Ể
dd 309h,0045h,1ebah ; E -> Ẻ
dd 309h,00eah,1ec3h ; ê -> ể
dd 309h,0065h,1ebbh ; e -> ẻ
dd 309h,0046h,0191h ; F -> Ƒ
dd 309h,0066h,0192h ; f -> ƒ
dd 309h,0047h,0193h ; G -> Ɠ
dd 309h,0067h,0260h ; g -> ɠ
dd 309h,0068h,0266h ; h -> ɦ
dd 309h,0049h,1ec8h ; I -> Ỉ
dd 309h,0069h,1ec9h ; i -> ỉ
dd 309h,025fh,0284h ; ɟ -> ʄ
dd 309h,004bh,0198h ; K -> Ƙ
dd 309h,006bh,0199h ; k -> ƙ
dd 309h,004dh,2c6eh ; M -> Ɱ
dd 309h,006dh,0271h ; m -> ɱ
dd 309h,004eh,019dh ; N -> Ɲ
dd 309h,006eh,0272h ; n -> ɲ
dd 309h,00d4h,1ed4h ; Ô -> Ổ
dd 309h,004fh,1eceh ; O -> Ỏ
dd 309h,01a0h,1edeh ; Ơ -> Ở
dd 309h,00f4h,1ed5h ; ô -> ổ
dd 309h,006fh,1ecfh ; o -> ỏ
dd 309h,01a1h,1edfh ; ơ -> ở
dd 309h,0050h,01a4h ; P -> Ƥ
dd 309h,0070h,01a5h ; p -> ƥ
dd 309h,0071h,02a0h ; q -> ʠ
dd 309h,0073h,0282h ; s -> ʂ
dd 309h,0259h,025ah ; ə -> ɚ
dd 309h,0054h,01ach ; T -> Ƭ
dd 309h,0074h,01adh ; t -> ƭ
dd 309h,0055h,1ee6h ; U -> Ủ
dd 309h,01afh,1eech ; Ư -> Ử
dd 309h,0075h,1ee7h ; u -> ủ
dd 309h,01b0h,1eedh ; ư -> ử
dd 309h,0056h,01b2h ; V -> Ʋ
dd 309h,0076h,028bh ; v -> ʋ
dd 309h,0057h,2c72h ; W -> Ⱳ
dd 309h,0077h,2c73h ; w -> ⱳ
dd 309h,0059h,1ef6h ; Y -> Ỷ
dd 309h,0079h,1ef7h ; y -> ỷ
dd 309h,005ah,0224h ; Z -> Ȥ
dd 309h,007ah,0225h ; z -> ȥ
dd 309h,309h,309h ; ̉ -> ̉
;dd 309h,0a0h,309h ;   -> ̉
;dd 309h,20h,309h ;   -> ̉


dd 0AFh,0226h,01e0h ; Ȧ -> Ǡ
dd 0AFh,00c4h,01deh ; Ä -> Ǟ
dd 0AFh,0041h,0100h ; A -> Ā
dd 0AFh,0227h,01e1h ; ȧ -> ǡ
dd 0AFh,00e4h,01dfh ; ä -> ǟ
dd 0AFh,0061h,0101h ; a -> ā
dd 0AFh,00c6h,01e2h ; Æ -> Ǣ
dd 0AFh,00e6h,01e3h ; æ -> ǣ
dd 0AFh,00c9h,1e16h ; É -> Ḗ
dd 0AFh,00c8h,1e14h ; È -> Ḕ
dd 0AFh,0045h,0112h ; E -> Ē
dd 0AFh,00e9h,1e17h ; é -> ḗ
dd 0AFh,00e8h,1e15h ; è -> ḕ
dd 0AFh,0065h,0113h ; e -> ē
dd 0AFh,0047h,1e20h ; G -> Ḡ
dd 0AFh,0067h,1e21h ; g -> ḡ
dd 0AFh,0049h,012ah ; I -> Ī
dd 0AFh,0069h,012bh ; i -> ī
dd 0AFh,1e36h,1e38h ; Ḷ -> Ḹ
dd 0AFh,1e37h,1e39h ; ḷ -> ḹ
dd 0AFh,022eh,0230h ; Ȯ -> Ȱ
dd 0AFh,00d3h,1e52h ; Ó -> Ṓ
dd 0AFh,00d6h,022ah ; Ö -> Ȫ
dd 0AFh,00d2h,1e50h ; Ò -> Ṑ
dd 0AFh,004fh,014ch ; O -> Ō
dd 0AFh,01eah,01ech ; Ǫ -> Ǭ
dd 0AFh,00d5h,022ch ; Õ -> Ȭ
dd 0AFh,022fh,0231h ; ȯ -> ȱ
dd 0AFh,00f3h,1e53h ; ó -> ṓ
dd 0AFh,00f6h,022bh ; ö -> ȫ
dd 0AFh,00f2h,1e51h ; ò -> ṑ
dd 0AFh,006fh,014dh ; o -> ō
dd 0AFh,01ebh,01edh ; ǫ -> ǭ
dd 0AFh,00f5h,022dh ; õ -> ȭ
dd 0AFh,1e5ah,1e5ch ; Ṛ -> Ṝ
dd 0AFh,1e5bh,1e5dh ; ṛ -> ṝ
dd 0AFh,00dch,1e7ah ; Ü -> Ṻ
dd 0AFh,0056h,01d5h ; V -> Ǖ
dd 0AFh,0055h,016ah ; U -> Ū
dd 0AFh,00fch,1e7bh ; ü -> ṻ
dd 0AFh,0076h,01d6h ; v -> ǖ
dd 0AFh,0075h,016bh ; u -> ū
dd 0AFh,0059h,0232h ; Y -> Ȳ
dd 0AFh,0079h,0233h ; y -> ȳ
dd 0AFh,0AFh,0AFh ; ¯ -> ¯
;dd 0AFh,0a0h,0304h ;   -> ̄
;dd 0AFh,20h,0AFh ;   -> ¯

dd 31bh,00d3h,1edah ; Ó -> Ớ
dd 31bh,1ecch,1ee2h ; Ọ -> Ợ
dd 31bh,00d2h,1edch ; Ò -> Ờ
dd 31bh,1eceh,1edeh ; Ỏ -> Ở
dd 31bh,004fh,01a0h ; O -> Ơ
dd 31bh,00d5h,1ee0h ; Õ -> Ỡ
dd 31bh,00f3h,1edbh ; ó -> ớ
dd 31bh,1ecdh,1ee3h ; ọ -> ợ
dd 31bh,00f2h,1eddh ; ò -> ờ
dd 31bh,1ecfh,1edfh ; ỏ -> ở
dd 31bh,006fh,01a1h ; o -> ơ
dd 31bh,00f5h,1ee1h ; õ -> ỡ
dd 31bh,00dah,1ee8h ; Ú -> Ứ
dd 31bh,1ee4h,1ef0h ; Ụ -> Ự
dd 31bh,00d9h,1eeah ; Ù -> Ừ
dd 31bh,1ee6h,1eech ; Ủ -> Ử
dd 31bh,0055h,01afh ; U -> Ư
dd 31bh,0168h,1eeeh ; Ũ -> Ữ
dd 31bh,00fah,1ee9h ; ú -> ứ
dd 31bh,1ee5h,1ef1h ; ụ -> ự
dd 31bh,00f9h,1eebh ; ù -> ừ
dd 31bh,1ee7h,1eedh ; ủ -> ử
dd 31bh,0075h,01b0h ; u -> ư
dd 31bh,0169h,1eefh ; ũ -> ữ
dd 31bh,31bh,31bh ; ̛ -> ̛
;dd 31bh,0a0h,31bh ;   -> ̛
;dd 31bh,20h,31bh ;   -> ̛

dd 338h,0032h,01bbh ; 2 -> ƻ
dd 338h,003dh,2260h ; = -> ≠
dd 338h,0041h,023ah ; A -> Ⱥ
dd 338h,0061h,2c65h ; a -> ⱥ
dd 338h,0042h,0243h ; B -> Ƀ
dd 338h,0062h,0180h ; b -> ƀ
dd 338h,0043h,023bh ; C -> Ȼ
dd 338h,0063h,023ch ; c -> ȼ
dd 338h,0044h,0110h ; D -> Đ
dd 338h,0064h,0111h ; d -> đ
dd 338h,0045h,0246h ; E -> Ɇ
dd 338h,0065h,0247h ; e -> ɇ
dd 338h,0047h,01e4h ; G -> Ǥ
dd 338h,0067h,01e5h ; g -> ǥ
dd 338h,003eh,226fh ; > -> ≯
dd 338h,2265h,2271h ; ≥ -> ≱
dd 338h,0048h,0126h ; H -> Ħ
dd 338h,0068h,0127h ; h -> ħ
dd 338h,0049h,0197h ; I -> Ɨ
dd 338h,0069h,0268h ; i -> ɨ
dd 338h,004ah,0248h ; J -> Ɉ
dd 338h,006ah,0249h ; j -> ɉ
dd 338h,0269h,1d7ch ; ɩ -> ᵼ
dd 338h,0237h,025fh ; ȷ -> ɟ
dd 338h,004ch,0141h ; L -> Ł
dd 338h,006ch,0142h ; l -> ł
dd 338h,003ch,226eh ; < -> ≮
dd 338h,2264h,2270h ; ≤ -> ≰
dd 338h,00d3h,01feh ; Ó -> Ǿ
dd 338h,004fh,00d8h ; O -> Ø
dd 338h,00f3h,01ffh ; ó -> ǿ
dd 338h,006fh,00f8h ; o -> ø
dd 338h,0050h,2c63h ; P -> Ᵽ
dd 338h,0070h,1d7dh ; p -> ᵽ
dd 338h,0052h,024ch ; R -> Ɍ
dd 338h,0072h,024dh ; r -> ɍ
dd 338h,0054h,0166h ; T -> Ŧ
dd 338h,0074h,0167h ; t -> ŧ
dd 338h,0055h,0244h ; U -> Ʉ
dd 338h,0075h,0289h ; u -> ʉ
dd 338h,0059h,024eh ; Y -> Ɏ
dd 338h,0079h,024fh ; y -> ɏ
dd 338h,005ah,01b5h ; Z -> Ƶ
dd 338h,007ah,01b6h ; z -> ƶ
dd 338h,338h,2Fh ; / -> /


dd 7Eh,0102h,1eb4h ; Ă -> Ẵ
dd 7Eh,00c2h,1eaah ; Â -> Ẫ
dd 7Eh,0041h,00c3h ; A -> Ã
dd 7Eh,0103h,1eb5h ; ă -> ẵ
dd 7Eh,00e2h,1eabh ; â -> ẫ
dd 7Eh,0061h,00e3h ; a -> ã
dd 7Eh,00cah,1ec4h ; Ê -> Ễ
dd 7Eh,0045h,1ebch ; E -> Ẽ
dd 7Eh,00eah,1ec5h ; ê -> ễ
dd 7Eh,0065h,1ebdh ; e -> ẽ
dd 7Eh,0049h,0128h ; I -> Ĩ
dd 7Eh,0069h,0129h ; i -> ĩ
dd 7Eh,004eh,00d1h ; N -> Ñ
dd 7Eh,006eh,00f1h ; n -> ñ
dd 7Eh,00d3h,1e4ch ; Ó -> Ṍ
dd 7Eh,00d4h,1ed6h ; Ô -> Ỗ
dd 7Eh,00d6h,1e4eh ; Ö -> Ṏ
dd 7Eh,01a0h,1ee0h ; Ơ -> Ỡ
dd 7Eh,014ch,022ch ; Ō -> Ȭ
dd 7Eh,004fh,00d5h ; O -> Õ
dd 7Eh,00f3h,1e4dh ; ó -> ṍ
dd 7Eh,00f4h,1ed7h ; ô -> ỗ
dd 7Eh,00f6h,1e4fh ; ö -> ṏ
dd 7Eh,01a1h,1ee1h ; ơ -> ỡ
dd 7Eh,014dh,022dh ; ō -> ȭ
dd 7Eh,006fh,00f5h ; o -> õ
dd 7Eh,00dah,1e78h ; Ú -> Ṹ
dd 7Eh,01afh,1eeeh ; Ư -> Ữ
dd 7Eh,0055h,0168h ; U -> Ũ
dd 7Eh,00fah,1e79h ; ú -> ṹ
dd 7Eh,01b0h,1eefh ; ư -> ữ
dd 7Eh,75h,0169h ; u -> ũ
dd 7Eh,56h,1e7ch ; V -> Ṽ
dd 7Eh,76h,1e7dh ; v -> ṽ
dd 7Eh,59h,1ef8h ; Y -> Ỹ
dd 7Eh,79h,1ef9h ; y -> ỹ
dd 7Eh,2dh,2243h ; - -> ≃
dd 7Eh,3ch,2272h ; < -> ≲
dd 7Eh,3eh,2273h ; > -> ≳
dd 7Eh,7Eh,7Eh ; ~ -> ~
;dd 7Eh,0a0h,303h ;   -> ̃
;dd 7Eh,20h,7Eh ;   -> ~

dd 2dah,00c1h,01fah ; Á -> Ǻ
dd 2dah,0041h,00c5h ; A -> Å
dd 2dah,00e1h,01fbh ; á -> ǻ
dd 2dah,0061h,00e5h ; a -> å
dd 2dah,0055h,016eh ; U -> Ů
dd 2dah,0075h,016fh ; u -> ů
dd 2dah,0077h,1e98h ; w -> ẘ
dd 2dah,0079h,1e99h ; y -> ẙ
dd 2dah,2dah,00b0h ; ˚ -> °
;dd 2dah,0a0h,030ah ;   -> ̊
;dd 2dah,20h,00b0h ;   -> °

dd 2dbh,0041h,0104h ; A -> Ą
dd 2dbh,0061h,0105h ; a -> ą
dd 2dbh,0045h,0118h ; E -> Ę
dd 2dbh,0065h,0119h ; e -> ę
dd 2dbh,0049h,012eh ; I -> Į
dd 2dbh,0069h,012fh ; i -> į
dd 2dbh,014ch,01ech ; Ō -> Ǭ
dd 2dbh,004fh,01eah ; O -> Ǫ
dd 2dbh,014dh,01edh ; ō -> ǭ
dd 2dbh,006fh,01ebh ; o -> ǫ
dd 2dbh,0055h,0172h ; U -> Ų
dd 2dbh,0075h,0173h ; u -> ų
dd 2dbh,2dbh,2dbh ; ˛ -> ˛
;dd 2dbh,00a0h,328h ;   -> ̨
;dd 2dbh,20h,2dbh ;   -> ˛