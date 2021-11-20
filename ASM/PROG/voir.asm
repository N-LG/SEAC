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


mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,tempo
int 61h
cmp eax,0
jne erreur_ouv

mov al,0
xor ebx,ebx
mov edx,tempo
int 64h
cmp eax,0
jne erreur_ouv
mov [handle_fichier],ebx



mov ebx,[handle_fichier]
mov al,51
int 63h
cmp eax,0
jne erreur_form
mov [x_image],ebx
mov [y_image],ecx



shr edx,8 
push edx
mov ecx,edx
add ecx,zt_sfv
mov edx,sel_dat1
mov eax,8
int 61h
pop ecx


mov ebx,[handle_fichier]
mov edi,zt_sfv
mov [zt_image],edi
push ds
push es
mov al,52
int 63h
pop es
pop ds
cmp eax,0
jne erreur_form2


;passe en mode video
mov dx,sel_dat2
mov ah,2   ;option=mode video ;6=video + souris
mov al,0   ;crÃ©ation console     
int 63h
mov ax,sel_dat2
mov fs,ax

xor ebx,ebx
xor ecx,ecx
fs
mov bx,[resx_ecran]
fs
mov cx,[resy_ecran]
sub ebx,[x_image]
ja @f
mov ebx,0
@@:
sub ecx,[y_image]
ja @f
mov ecx,0
@@:
shr ebx,1
shr ecx,1
mov edx,[zt_image]
mov al,27   ;afficher image    
int 63h


;test si il faut afficher l'indication pour sortir
mov al,5   
mov ah,"t"   ;numéros de l'option de commande a lire
mov cl,1 ;0=256 octet max
mov edx,temp
int 61h
cmp eax,0
je @f

;affiche l'indication pour sortir
mov ebx,0
mov ecx,0
mov edx,msgf
mov ah,0Fh
mov al,25   ;afficher texte    
int 63h



;attend l'appuie de la touche echap
@@:
mov al,5
int 63h
cmp al,1
jne @b

int 60h


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











sdata1:
org 0

handle_fichier:
dd 0
zt_image:
dd 0
x_image:
dd 0
y_image:
dd 0
temp:
dd 0



msgtrappe:
rb 256

tempo:
rb 256


msg1:
db "impossible d'ouvrir le fichier",13,0
msg2:
db "le format de l'image n'est pas reconnu",13,0
msg3:
db "erreur dans le codage de l'image",13,0

msgf:
db "appuyez sur echap pour quitter",13,0


zt_sfv:

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