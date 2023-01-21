voir:
pile equ 4096 ;definition de la taille de la pile
include "../PROG/fe.inc"
db "visionneur image"   
scode:
org 0


;données du segment CS
mov ax,sel_dat1
mov ds,ax
mov es,ax



;test si il faut une couleur de fond spéciale
mov al,5   
mov ah,"c"   ;numéros de l'option de commande a lire
mov cl,16 ;0=256 octet max
mov edx,tempo
int 61h
cmp eax,0
jne @f
mov al,101
mov edx,tempo
int 61h
mov [couleur],ecx
@@:


;test si on as besoin d'information supplémentaire
mov al,5   
mov ah,"t"   ;lettre de l'option de commande a lire
mov cl,1 ;0=256 octet max
mov edx,tempo
int 61h
cmp eax,0
jne @f
or byte[opt],1
@@:

;test si on as besoin d'afficher la souris
mov al,5   
mov ah,"s"   ;lettre de l'option de commande a lire
mov cl,1 ;0=256 octet max
mov edx,tempo
int 61h
cmp eax,0
jne @f
or byte[opt],4
@@:



;lit nom du fichier dans la commande
mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,tempo
int 61h
cmp eax,0
jne erreur_ouv


;passe en mode video
mov dx,sel_dat2
mov ah,6   ;option=mode video ;6=video + souris
test byte[opt],4
jz @f
;and ah,0FBh   ;désactive la souris
@@:
mov al,0   ;création console     
int 63h
mov ax,sel_dat2
mov fs,ax
fs
or byte[at_console],8  ;met a 1 le bit de non mise a jour de l'ecran apres int 63h



;ouvre le fichier
mov al,0
xor ebx,ebx
mov edx,tempo
int 64h
cmp eax,0
jne erreur_ouv
mov [handle_fichier],ebx


;lit les carac de l'image
mov ebx,[handle_fichier]
mov al,51
int 63h
cmp eax,0
jne erreur_form
mov [x_image1],ebx
mov [y_image1],ecx
mov [x_image2],ebx
mov [y_image2],ecx
mov [x_image3],ebx
mov [y_image3],ecx

;calcul la taille d'une image ecran complete avec la résolution de l'image
push edx
xor ecx,ecx
mov cl,dl
shr ecx,3
xor eax,eax
xor ebx,ebx
xor edx,edx
fs
mov ax,[resx_ecran]
fs
mov bx,[resy_ecran]
mul ecx
mul ebx
add eax,14 ;eax=taille de l'image
pop edx



;aggrandit la zone pour pouvoir y charger l'image et les différentes zones intermédiaire de traitement
shr edx,8 
push edx
mov ecx,edx
add ecx,zt_sfv1    ;zone de chargement de l'image
mov [zt_sfv2],ecx  ;zone du fragment a afficher
add ecx,edx     
mov [zt_sfv3],ecx  ;zone de l'image redimensionné
add ecx,eax         
add ecx,objimage_dat

mov dx,sel_dat1
mov eax,8
int 61h
pop ecx
cmp eax,0
jne erreur_mem


;lit l'image
mov ebx,[handle_fichier]
mov edi,zt_sfv1
mov [zt_image],edi
mov al,52
int 63h
cmp eax,0
jne erreur_form2




calczoom:
mov ebx,[zoom]
mov ecx,10000
xor ebp,ebp



;calcul de la dimension de l'image théorique après application du zoom et tronquage si trop grand
mov eax,[x_image1]
mul ebx
div ecx
fs
mov bp,[resx_ecran]
cmp eax,ebp
jbe @f
mov eax,ebp
@@:
mov [x_image3],eax

mov eax,[y_image1]
mul ebx
div ecx
fs
mov bp,[resy_ecran]
cmp eax,ebp
jbe @f
mov eax,ebp
@@:
mov [y_image3],eax



;calcul des dimension de l'image intermédiaire
mov eax,[x_image3]
mul ecx
div ebx
mov [x_image2],eax

mov eax,[y_image3]
mul ecx
div ebx
mov [y_image2],eax








;*********************************************************************************************
affichage:
;ajustement pour que le déplacement ne déborde pas
mov eax,[offset_imagex]
mov ebx,[x_image1]
sub ebx,[x_image2]
cmp eax,0
jge @f
mov eax,0
@@:
cmp eax,ebx
jle @f
mov eax,ebx
@@:
mov [offset_imagex],eax

mov eax,[offset_imagey]
mov ebx,[y_image1]
sub ebx,[y_image2]
cmp eax,0
jge @f
mov eax,0
@@:
cmp eax,ebx
jle @f
mov eax,ebx
@@:
mov [offset_imagey],eax











mov ebx,[x_image2]
mov ecx,[y_image2]
mov edi,[zt_sfv2]
mov al,50   ;créer image    
mov ah,[zt_sfv1+objimage_bpp]
mov edx,0FFFFFFFFh
int 63h



;lit un fragment de l'image
mov ebx,[offset_imagex]
mov ecx,[offset_imagey]
mov esi,zt_sfv1
mov edi,[zt_sfv2]
mov al,54
int 63h




mov ebx,[x_image3]
mov ecx,[y_image3]
mov edi,[zt_sfv3]
mov al,50   ;créer image    
mov ah,[zt_sfv1+objimage_bpp]
mov edx,0FFFFFFFFh
int 63h


;redimensionne l'image
mov esi,[zt_sfv2]
mov edi,[zt_sfv3]
mov al,53
int 63h


;affiche un fond
xor ebx,ebx
xor ecx,ecx
xor esi,esi
xor edi,edi
fs
mov si,[resx_ecran]
fs
mov di,[resy_ecran]
mov al,22   ;afficher rectangle    
mov ah,24
mov edx,[couleur]
int 63h


;affiche l'image
xor ebx,ebx
xor ecx,ecx
fs
mov bx,[resx_ecran]
fs
mov cx,[resy_ecran]
sub ebx,[x_image3]
ja @f
mov ebx,0
@@:
sub ecx,[y_image3]
ja @f
mov ecx,0
@@:
shr ebx,1
shr ecx,1
mov edx,[zt_sfv3]
mov al,27   ;afficher image    
int 63h




;test si il faut afficher du texte
test byte[opt],1
jnz fin_affichage

;affiche l'indication pour sortir
mov ebx,0
mov ecx,0
mov edx,msgf
mov ah,0Fh
mov al,25   ;afficher texte    
int 63h

;affiche la largeur
mov eax,102
mov ecx,[x_image1]
mov edx,tempo
int 61h
mov ebx,0
mov ecx,16
mov edx,tempo
mov ah,0Fh
mov al,25
int 63h

;affiche la hauteur
mov eax,102
mov ecx,[y_image1]
mov edx,tempo
int 61h
mov ebx,0
mov ecx,32
mov edx,tempo
mov ah,0Fh
mov al,25
int 63h


fin_affichage:
mov eax,7  ;demande la mise a jour ecran
int 63h


;attend l'appuie d'une touche
boucle_touche:
test byte[opt],2
jne boucle_touche2

fs
test byte[at_console],20h
jnz redim_ecran

mov al,5
int 63h
cmp al,1  ;echap on quitte
je fin
cmp al,82
je zop
cmp al,84
je zom
cmp ecx,"i"
je info
cmp ecx,"I"
je info
cmp al,0F0h
je clique
;???????????????autres interaction
jmp boucle_touche




;que faire lors du maintien du clique droit
boucle_touche2:
mov al,5
int 63h
cmp al,0F1h
je clique
fs
mov eax,[posx_souris]
cmp [sauvx_souris],eax
je boucle_touche



;calcul du déplacement de la souris
mov ebx,[zoom]
mov ecx,10000

xor eax,eax
xor ebp,ebp
mov ax,[sauvx_souris]
fs
mov bp,[posx_souris]
sub eax,ebp
imul ecx
idiv ebx
add [offset_imagex],eax

xor eax,eax
xor ebp,ebp
mov ax,[sauvy_souris]
fs
mov bp,[posy_souris]
sub eax,ebp
imul ecx
idiv ebx
add [offset_imagey],eax

jmp affichage






fin:
int 60h



;********************************
zom:
cmp dword[zoom],2000
jbe boucle_touche
sub dword[zoom],1000
jmp calczoom

zop:
cmp dword[zoom],80000
jae boucle_touche
add dword[zoom],1000
jmp calczoom



clique:
;passe en mode de glisser l'image
xor byte[opt],2
fs
mov eax,[posx_souris]
mov [sauvx_souris],eax

;echange la fleche et la croix
mov esi,croix
fs
mov edi,[ad_curseur]
mov ecx,64

@@:
mov eax,[esi]
fs
xchg eax,[edi]
mov [esi],eax
add esi,4
add edi,4
dec ecx
jnz @b
jmp affichage



info:
xor byte[opt],1
jmp affichage



redim_ecran:
mov dx,sel_dat2
mov ah,6   ;option=mode video ;6=video + souris
test byte[opt],4
jz @f
@@:
mov al,0   ;création console     
int 63h
mov ax,sel_dat2
mov fs,ax
fs
or byte[at_console],8  ;met a 1 le bit de non mise a jour de l'ecran apres int 63h


;calcul la taille d'une image ecran complete avec la résolution de l'image
xor ecx,ecx
mov cl,dl
shr ecx,3
xor eax,eax
xor ebx,ebx
xor edx,edx
fs
mov ax,[resx_ecran]
fs
mov bx,[resy_ecran]
mul ecx
mul ebx
add eax,14 ;eax=taille de l'image

;aggrandit la zone pour pouvoir y charger l'image et les différentes zones intermédiaire de traitement
mov ecx,[zt_sfv3]  ;zone de l'image redimensionné
add ecx,eax         

mov dx,sel_dat1
mov eax,8
int 61h
cmp eax,0
jne erreur_mem

jmp affichage



;************************************************
erreur_ouv:
mov al,6
mov edx,msg1
int 61h
int 60h


erreur_form:
mov al,6
mov edx,msg2
int 61h
int 60h

erreur_form2:
mov al,6
mov edx,msg3
int 61h
int 60h


erreur_mem:
mov al,6
mov edx,msg4
int 61h
int 60h









sdata1:
org 0

handle_fichier:
dd 0
zt_image:
dd 0
x_image1:
dd 0
y_image1:
dd 0
x_image2:
dd 0
y_image2:
dd 0
x_image3:
dd 0
y_image3:
dd 0


offset_imagex:
dd 0
offset_imagey:
dd 0
posx_image:
dd 0
posy_image:
dd 0


couleur:
dd 0

opt:
db 0    ;b0=pas d'affichage info  b2=glissement souris en cours b3=souris pas affiché
zoom:
dd 10000


sauvx_souris:
dw 0
sauvy_souris:
dw 0

croix:
include "curs_crx.inc"

tempo:
rb 256

msg1:
db "impossible d'ouvrir le fichier",13,0
msg2:
db "le format de l'image n'est pas reconnu",13,0
msg3:
db "erreur dans le codage de l'image",13,0
msg4:
db "pas assez de mémoire pour ouvrir l'image",13,0

msgf:
db "appuyez sur echap pour quitter",13,0

zt_sfv2:
dd 0
zt_sfv3:
dd 0
zt_sfv1:

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