ddur.asm:
use16
org 0h

td_o1 equ 16    ;nombre de secteur du disque  bit 8 a 15
td_o2 equ 0    ;nombre de secteur du disque  bit 16 a 23
ran1 equ 443345456
ran2 equ 214257155
ran3 equ 158948756
ran4 equ 349982456




MBR:
file "../../BIN/MBR_BIOS.BIN"

rb 446 + MBR - $ 

db 0      ;etat partition
db 0,0,0  ;coordonné 1er secteur partition
db 30h    ;type de partition
db 0,0,0  ;coordonné dernier secteur partition
dd 1      ;adresse premier secteur de la partition
dd 1024   ;taille en secteur de la partition

rb 510 + MBR - $ 

db 055h,0AAh

file "../../BIN/SYST.BIN"

rb (td_o1 * 131072)+(td_o2*33554432) + MBR - $ 


;footer du format VHD  !!!!!!!!!!!!!!! pas au point  !!!!!!!!!!!!!!!!!!!!!!!
db "conectix"              ;Cookie 8o
dd 0                       ;Features 4o
db 0,1,0,0                 ;File Format Version 4o
dd 0FFFFFFFFh,0FFFFFFFFh   ;Data Offset 8o
dd 0                       ;Time Stamp 4o
db "fasm"                  ;Creator Application 4o
db 0,0,0,9                 ;Creator Version 4o
dd 06B326957h              ;Creator Host OS 4o  06B326957h=windows  02063614Dh=mac
db 0,0,0,0,0,td_o2,td_o1,0 ;Original Size 8o
db 0,0,0,0,0,td_o2,td_o1,0 ;Current Size 8o
dw 0C807h                  ;Cylinder      Disk Geometry 4o
db 16                      ;Heads
db 63                      ;Sectors per track/cylinder
db 0,0,0,2                 ;Disk Type 4o  2=Fixed hard disk
dd 0                       ;Checksum 4o
dd ran1,ran2,ran3,ran3     ;Unique Id 16o
db 0                       ;Saved State 1o
rb 426                     ;Reserved 427o
db 0