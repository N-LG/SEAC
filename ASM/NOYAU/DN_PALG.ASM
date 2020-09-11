;palette graphique pour les modes 256 couleurs

db 0,0,0         ;RGB 24bits  (BGR ici)
db 0             
;bleu
db 170,0,0
db 0 
;vert
db 0,170,0
db 0
;cyan
db 170,170,0
db 0
;rouge
db 0,0,170
db 0
;magenta
db 170,0,170
db 0 
;marron
db 0,85,170
db 0
;gris clair
db 170,170,170
db 0
;gris foncé
db 85,85,85
db 0 
;bleu clair
db 255,85,85
db 0
;vert clair
db 85,255,85
db 0
;cyan clair
db 255,255,85
db 0 
;rouge clair
db 85,85,255
db 0
;magenta clair
db 255,85,255
db 0
;jaune
db 85,255,255
db 0  
;blanc
db 255,255,255
db 0

;debut des 16 niveaux de gris
db 0,0,0
db 0

db 17,17,17
db 0

db 34,34,34
db 0

db 51,51,51
db 0

db 68,68,68
db 0

db 85,85,85
db 0

db 102,102,102
db 0

db 119,119,119
db 0

db 136,136,136
db 0

db 153,153,153
db 0

db 170,170,170
db 0

db 187,187,187
db 0

db 204,204,204
db 0

db 221,221,221
db 0

db 238,238,238
db 0

db 255,255,255
db 0
;fin des 16 niveaux de gris

macro bloc24vga niv0,niv1,niv2,niv3,niv4   ;macro de variation VGA par bloc de 24 couleur
{
db niv4,niv0,niv0
db 0
db niv4,niv0,niv1
db 0
db niv4,niv0,niv2
db 0
db niv4,niv0,niv3
db 0
db niv4,niv0,niv4
db 0
db niv3,niv0,niv4
db 0
db niv2,niv0,niv4
db 0
db niv1,niv0,niv4
db 0
db niv0,niv0,niv4
db 0
db niv0,niv1,niv4
db 0
db niv0,niv2,niv4
db 0
db niv0,niv3,niv4
db 0
db niv0,niv4,niv4
db 0
db niv0,niv4,niv3
db 0
db niv0,niv4,niv2
db 0
db niv0,niv4,niv1
db 0
db niv0,niv4,niv0
db 0
db niv1,niv4,niv0
db 0
db niv2,niv4,niv0
db 0
db niv3,niv4,niv0
db 0
db niv4,niv4,niv0
db 0
db niv4,niv3,niv0
db 0
db niv4,niv2,niv0
db 0
db niv4,niv1,niv0
db 0
}


bloc24vga 000h,041h,07Dh,0BEh,0FFh
bloc24vga 07Dh,09Eh,0BEh,0DFh,0FFh
bloc24vga 0B6h,0C7h,0DBh,0EBh,0FFh

bloc24vga 000h,01Ch,038h,055h,071h
bloc24vga 038h,045h,055h,061h,071h
bloc24vga 051h,059h,061h,069h,071h

bloc24vga 000h,010h,020h,030h,041h
bloc24vga 020h,028h,030h,038h,041h
bloc24vga 02Ch,030h,034h,03Ch,041h

dd 0,0,0,0,0,0,0,0   ;8 couleurs noir pour completer la palette
