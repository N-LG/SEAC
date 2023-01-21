test14:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "Jeu Nul N°1"
scode:
org 0

;donnÃ©es du segment CS
mov dx,sel_dat1
mov ds,dx
mov es,dx

mov dx,sel_dat2
mov ah,10   ;option=mode video  + pas de rafraichissement automatique
mov al,0   ;crÃ©ation console     
int 63h
cmp eax,0
je @f

erreur_init:
mov edx,msg_err_init
mov al,6
int 61h
int 60h

@@:
mov dx,sel_dat2
mov fs,dx

masse equ 0
posx equ 10
posy equ 20
vitx equ 30
vity equ 40

fclex
fstcw [tempo]
and word[tempo],0FFC0h  ;active toutes les sources des interruptions
fldcw [tempo]





finit

;initialise valeurs
mov dword[tempo],1200
fild dword[tempo]
fstp qword[terre+masse]
fldz
fst qword[terre+posx]
fst qword[terre+posy]
fst qword[terre+vitx]
fstp qword[terre+vity]




mov dword[tempo],200
fild dword[tempo]
fstp qword[lune+masse]

mov dword[tempo],1
fild dword[tempo]
fstp qword[lune+vity]

mov dword[tempo],250
fild dword[tempo]
fstp qword[lune+posy]

mov dword[tempo],0
fild dword[tempo]
fstp qword[lune+vitx]

mov dword[tempo],180
fild dword[tempo]
fstp qword[lune+posx]







boucle:

;redimensionne l'ecran au besoin
fs
test byte[at_console],20h
jz @f
mov dx,sel_dat2
mov ah,10   ;option=mode video  + pas de rafraichissement automatique
mov al,0   ;crÃ©ation console     
int 63h
cmp eax,0
jne erreur_init
@@:


;calcul la variation de vitesse
fld qword[terre+posx]
fsub qword[lune+posx]
fld qword[terre+posy]
fsub qword[lune+posy]
fld st0
fmul st0,st1
fld st2
fmul st0,st3 
faddp
fld st0
fsqrt  ;st0=distance st1=distance au carré st2=y  st3=x 
fdiv st2,st0
fdiv st3,st0   ;st2=composante x  st3=composante y


 
fld qword[terre+masse]
fdiv st0,st2

fld st0
fmul st0,st5
fadd qword[lune+vitx]
fstp qword[lune+vitx]

fld st0
fmul st0,st4
fadd qword[lune+vity]
fstp qword[lune+vity]


finit



;calcul les déplacements
fld qword[terre+posx]
fadd qword[terre+vitx]
fstp qword[terre+posx]
fld qword[terre+posy]
fadd qword[terre+vity]
fstp qword[terre+posy]
fld qword[lune+posx]
fadd qword[lune+vitx]
fstp qword[lune+posx]
fld qword[lune+posy]
fadd qword[lune+vity]
fstp qword[lune+posy]


;*********************applique poussé (éventuellement)
fs
test byte[bm_clavier+9],1
jz pasdepousse

mov dword[tempo],5000
mov dword[tempo+4],180
fild dword[angle]
fidiv dword[tempo+4]
fldpi
fmulp



fld qword[lune+vity]
fild dword[tempo]
fild dword[pousse]
fld st3
fsin
fmulp
fxch st1
fdivp
faddp
fstp qword[lune+vity]

fld qword[lune+vitx]
fild dword[tempo]
fild dword[pousse]
fld st3
fcos
fmulp
fxch st1
fdivp
faddp
fstp qword[lune+vitx]

pasdepousse:


;***********************efface l'affichage
mov ebx,0
mov ecx,0
fs
mov esi,[resx_ecran]
fs
mov edi,[resy_ecran]
and esi,0FFFFh
and edi,0FFFFh
mov ah,4    ;4bit par pixel pour la couleur
mov edx,0   ;couleur
mov al,22   ;afficher un carré   
int 63h

;affiche cadran
mov ebx,50
mov ecx,65
mov al,24  ;afficher un cercle
mov ah,4    ;4bit par pixel pour la couleur
mov edx,07h
mov esi,50  ;rayon
int 63h
mov ebx,50
mov ecx,65
mov al,24  ;afficher un cercle
mov ah,4    ;4bit par pixel pour la couleur
mov edx,00h
mov esi,48  ;rayon
int 63h





;********************affiche orientation vitesse




;*********************affiche orientation
mov dword[tempo],45
mov dword[tempo+4],45
mov dword[tempo+8],180

fild dword[angle]
fidiv dword[tempo+8]
fldpi
fmulp
fld st0

fcos
fimul dword[tempo]
fistp dword[tempo]
fsin
fimul dword[tempo+4]
fistp dword[tempo+4]

mov ebx,50
mov ecx,65
mov esi,50
mov edi,65
add esi,[tempo]
add edi,[tempo+4]
mov al,23  ;afficher un segment
mov ah,4    ;4bit par pixel pour la couleur
mov edx,07h
int 63h



;********************affichage poussé
mov ebx,0
mov ecx,0
mov esi,[pousse]
mov edi,15
mov ah,4      ;4bit par pixel pour la couleur
mov edx,0Fh   ;couleur
mov al,22     ;afficher un carré   
int 63h






;****************************affiche trajectoire
mov esi,liste_point
xor ebx,ebx
xor ecx,ecx
mov edx,0FFFFFFh   ;couleur

boucle_traj:
mov bx,[esi]
mov cx,[esi+2]

push esi
mov al,21  ;afficher un point
mov ah,24    ;4bit par pixel pour la couleur
mov esi,30  ;rayon
int 63h
pop esi

sub edx,10101h
add esi,4
cmp esi,liste_point+1024
jne boucle_traj





;affiche terre
xor ebx,ebx
xor ecx,ecx
fs
mov bx,[resx_ecran]
fs
mov cx,[resy_ecran]
shr bx,1
shr cx,1

fld qword[terre+posx]
fistp dword[tempo]
fld qword[terre+posy]
fistp dword[tempo+4]
add ebx,[tempo]
add ecx,[tempo+4]

mov al,24   ;afficher un disque
mov ah,4    ;4bit par pixel pour la couleur
mov edx,09h   ;couleur
mov esi,20  ;rayon
int 63h


;affiche lune
xor ebx,ebx
xor ecx,ecx
fs
mov bx,[resx_ecran]
fs
mov cx,[resy_ecran]
shr bx,1
shr cx,1

fld qword[lune+posx]
fistp dword[tempo]
fld qword[lune+posy]
fistp dword[tempo+4]
add ebx,[tempo]
add ecx,[tempo+4]

push ebx
push ecx

mov al,24   ;afficher un disque
mov ah,4    ;4bit par pixel pour la couleur
mov edx,0Ah   ;couleur
mov esi,10  ;rayon
int 63h

mov al,7     ;mise a jour de l'écran
int 63h


;met a jour la table des coordonné
mov esi,liste_point+1016
mov edi,liste_point+1020
mov ecx,255
std
rep movsd
pop ecx
pop ebx
mov [liste_point],bx
mov [liste_point+2],cx



;*********************************
attend_touche:
mov al,5
int 63h

cmp al,82
je aug_pousse
cmp al,84
je dim_pousse
cmp al,83
je aug_angle
cmp al,85
je dim_angle

cmp al,1
jne boucle
int 60h



aug_angle:
sub dword[angle],5
cmp dword[angle],360
jl boucle
sub dword[angle],360
jmp boucle


dim_angle:
add dword[angle],5
cmp dword[angle],0
jae boucle
add dword[angle],360
jmp boucle


aug_pousse:
cmp dword[pousse],100
je boucle
inc dword[pousse]
jmp boucle


dim_pousse:
cmp dword[pousse],0
je boucle
dec dword[pousse]
jmp boucle



sdata1:
org 0
tempo:
rb 128


terre:
rb 128
lune:
rb 128

liste_point:
rb 1024


angle:
dd 90
pousse:
dd 0

msg_err_init:
db "JN1: impossible de démarrer, vous devez être en mode graphique",13,0


sdata2:
org 0
;donnÃ©es du segment ES
sdata3:
org 0
;donnÃ©es du segment FS
sdata4:
org 0
;donnÃ©es du segment GS
findata: