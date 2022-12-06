pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "calculatrice"
scode:
org 0
mov ax,sel_dat1
mov ds,ax

;crée ecran
mov dx,sel_dat2
mov ah,1   ;option=mode texte
mov al,0   ;création console     
int 63h

mov dx,sel_dat1
mov ds,dx
mov es,dx
mov dx,sel_dat2
mov fs,dx


mov edx,msg_debut
mov al,11
mov ah,0Fh ;couleur
int 63h



boucle_principale:
;**************************************************************
;attent saisie chaine de caractère
mov edx,exp_hab
mov ecx,512
mov al,6
mov ah,0Fh   ;couleur
int 63h

;si la validation de la saisie est echap alors on termine l'application
cmp al,1
jne @f
int 60h 
@@:

fs
test byte[at_console],20h
jz @f
;redimensinne l'ecran si la taille de celuis ci as changé
mov dx,sel_dat2
mov ah,1   ;option=mode texte
mov al,0   ;création console     
int 63h

mov dx,sel_dat1
mov ds,dx
mov es,dx
mov dx,sel_dat2
mov fs,dx
@@:



;**************************************************************
;convertit l'expression en notation NPI

mov ebx,exp_hab

bocse:          ;boucle de suppression des espaces
inc bx
cmp byte[ebx],20h
jne pas_esp

mov esi,ebx
bocdecal:        ;boucle de décalage en cas d'espace
mov al,[esi+1]
mov [esi],al
inc esi
cmp al,0
jne bocdecal
dec ebx

pas_esp:
cmp byte[ebx],0
jne bocse


mov ebx,exp_hab

bocve:          ;boucle de v‚rification des énormité
mov ax,[ebx]
cmp ax,"(*"
je erreur_syntaxe
cmp ax,"(/"
je erreur_syntaxe
cmp ax,"(+"
je erreur_syntaxe
cmp ax,"*/"
je erreur_syntaxe
cmp ax,"/*"
je erreur_syntaxe
cmp ax,"*+"
je erreur_syntaxe
cmp ax,"+*"
je erreur_syntaxe



cmp ax,"*)"
je erreur_syntaxe
cmp ax,"/)"
je erreur_syntaxe
cmp ax,"+)"
je erreur_syntaxe
cmp ax,"-)"
je erreur_syntaxe
cmp ax,"^)"
je erreur_syntaxe




inc ebx
cmp al,0
jne bocve



mov ebx,exp_hab
mov edi,exp_npi
mov [sauvesp],esp

bcdef:             ;boucle de conversion notation standard > npi
mov al,[ebx]
cmp al,"*"
je fois
cmp al,"+"
je plus
cmp al,"/"
je divise
cmp al,"-"
je moins
cmp al,"^"
je expon
cmp al,"x"
je variable
cmp al,"X"
je variable
cmp al,"0"
je chiffre
cmp al,"1"
je chiffre
cmp al,"2"
je chiffre
cmp al,"3"
je chiffre
cmp al,"4"
je chiffre
cmp al,"5"
je chiffre
cmp al,"6"
je chiffre
cmp al,"7"
je chiffre
cmp al,"8"
je chiffre
cmp al,"9"
je chiffre
cmp al,"."
je point
cmp al,","
je point
cmp al,"("
je paranthese1
cmp al,")"
je paranthese2
cmp al,0
je fin
jmp erreur_syntaxe

chiffre:           ;les chiffre sont directement placé sur la chaine de sortie
mov [edi],al
inc edi
inc ebx
jmp bcdef

point:            ;point ou virgule on enregistre un point dans la chaine 
mov byte[edi],"."  ;de sortie
inc edi           
inc ebx
jmp bcdef

fois:
cmp esp,[sauvesp]
je pilevide
pop dx
cmp dl,"^"
je lkp
jmp norm


variable:
mov byte[edi]," "
mov byte[edi+1],"X"
add edi,2
inc ebx
jmp bcdef



divise:            ;signe divise, on v‚rifie qu'un multiplication n'est pas en haut de la pile
cmp esp,[sauvesp]
je pilevide
pop dx
cmp dl,"^"
je lkp
cmp dl,"*"
je lkp
jmp norm

moins:               ;signe + on verifie qu'il n'y a pas une multiplication
cmp esp,[sauvesp]   ;ou une division ou une n‚gation qui soit prioritaire
je pilevide
pop dx
cmp dl,"^"
je lkp
cmp dl,"*"
je lkp
cmp dl,"/"
je lkp

dec ebx
cmp byte[ebx],"("     ;si le signe moin est juste aprŠs une paranthŠse faire
jne nodebpar         ;commesi il y avait eu un z‚ro entre eux

mov byte[edi]," "
inc di
mov byte[edi],"0"
inc di
mov byte[edi]," "
inc edi
nodebpar:
inc ebx
jmp norm

plus:               ;signe + on verifie qu'il n'y a pas une multiplication
cmp esp,[sauvesp]   ;ou une division ou une n‚gation qui soit prioritaire
je pilevide
pop dx
cmp dl,"^"
je lkp
cmp dl,"*"
je lkp
cmp dl,"/"
je lkp
cmp dl,"-"
je lkp


norm:
push dx           ;rempile ce que l'on vient de dépiler et empile  l'opérande
expon:
pilevide:
push ax
mov al," "
mov [edi],al
inc edi
inc ebx
jmp bcdef


lkp:                 ;place l'opérande que l'on vient de dépiler en sortie
push ax              ;et empile l'opérande dernièrement lu
mov dh," "
mov [edi],dh
inc edi
mov [edi],dl
inc edi
mov [edi],dh
inc edi
inc ebx
jmp bcdef



paranthese1:        ;simplement empile la parantèse (
push ax
mov al," "
mov [edi],al
inc edi
inc ebx
jmp bcdef

paranthese2:      ;dépile les opérande et les écrit dans la chaine de sortie
inc bx
bcdepp2:
cmp esp,[sauvesp]  ;si on atteind la fin de la pile avant d'avoir trouvé une
je erreur_parenthese          ;paranthèse ( c'est qu'il y a eu une erreur
pop ax
cmp al,"("
je bcdef
mov ah," "
mov [edi],ah
inc edi
mov [edi],al
inc edi
mov [edi],ah
inc edi
jmp bcdepp2



fin:
cmp esp,[sauvesp]  ;d‚pile tout les op‚rateur restant jusque a la fin de la pile
je okay
pop ax
mov ah," "
mov [edi],ah
inc edi
mov [edi],al
inc edi
jmp fin



erreur_syntaxe:              
mov edx,err_syn
mov al,11
mov ah,08h
int 63h
jmp boucle_principale



erreur_parenthese:              
mov edx,err_para
mov al,11
mov ah,08h
int 63h
jmp boucle_principale



okay:
mov byte[edi],0 ;place un symbole 0 a la fin de la chaine de sortie


;**************************************************************
;affiche la notation NPI

mov edx,ligne
mov al,11
mov ah,0Fh ;couleur
int 63h

mov edx,exp_npi
mov al,11
mov ah,08h
int 63h

mov edx,ligne
mov al,11
mov ah,0Fh ;couleur
int 63h

;**************************************************************
;effectue le calcule de l'expression NPI
xor ebx,ebx
push ebx
mov ebx,1
push ebx

mov ebx,exp_npi


boclcnpi:              ;boucle de calcul en notation npi
mov al,[ebx]
cmp al,"*"
je foisnpi
cmp al,"+"
je plusnpi
cmp al,"/"
je divisenpi
cmp al,"-"
je moinsnpi
cmp al,"^"
je exponpi
cmp al,"X"
je xnpi
cmp al,"0"
je chiffrenpi
cmp al,"1"
je chiffrenpi
cmp al,"2"
je chiffrenpi
cmp al,"3"
je chiffrenpi
cmp al,"4"
je chiffrenpi
cmp al,"5"
je chiffrenpi
cmp al,"6"
je chiffrenpi
cmp al,"7"
je chiffrenpi
cmp al,"8"
je chiffrenpi
cmp al,"9"
je chiffrenpi
cmp al,0
je finpi
inc ebx
jmp boclcnpi



xnpi:
mov eax,[xh]              ;empile le résultat de l'opération précédente  
mov ecx,[xb]
push eax                     
push ecx
inc ebx
jmp boclcnpi



exponpi:
pop ecx
pop eax
mov [op2h],eax
mov [op2b],ecx
pop ecx
pop eax
mov [op1h],eax
mov [op1b],ecx
mov eax,1
mov [op3h],eax     
mov [op3b],eax

test dword[op2b],80000000h
jz pasadjex1
neg dword[op2h]
neg dword[op2b]
pasadjex1:
test dword[op2h],80000000h
jz pasadjex2
neg dword[op2h]
mov eax,[op1h]
xchg eax,[op1b]
mov [op1h],eax
pasadjex2:


bouclexponpi:
mov eax,[op2h]
cmp eax,[op2b]
jl finexponpi

xor edx,edx
mov eax,[op3h]
mov ecx,[op1h] 
imul ecx
mov [op3h],eax 
xor edx,edx
mov eax,[op3b]
mov ecx,[op1b] 
imul ecx
mov [op3b],eax 

mov eax,[op2b]
sub [op2h],eax
jmp bouclexponpi


finexponpi:
mov eax,[op3h]              ;rempile le résultat  
mov ecx,[op3b]
push eax                     
push ecx
inc ebx
jmp boclcnpi


foisnpi:                         ;dépile les deux dernier nombres
pop ecx
pop eax
mov [op2h],eax
mov [op2b],ecx
pop ecx
pop eax
mov [op1h],eax
mov [op1b],ecx

xor edx,edx
mov eax,[op1h]
mov ecx,[op2h] 
imul ecx
mov [op3h],eax 
xor edx,edx
mov eax,[op1b]
mov ecx,[op2b] 
imul ecx
mov [op3b],eax 

mov eax,[op3h]              ;rempile le résultat  
mov ecx,[op3b]
push eax                     
push ecx
inc ebx
jmp boclcnpi

divisenpi:                  ;dépile les deux dernier nombres
pop ecx
pop eax
mov [op2h],eax
mov [op2b],ecx
pop ecx
pop eax
mov [op1h],eax
mov [op1b],ecx

xor edx,edx
mov eax,[op1h]
mov ecx,[op2b] 
imul ecx
mov [op3h],eax 
xor edx,edx
mov eax,[op1b]
mov ecx,[op2h] 
imul ecx
mov [op3b],eax 

mov eax,[op3h]              ;rempile le résultat  
mov ecx,[op3b]
push eax                     
push ecx
inc ebx
jmp boclcnpi

moinsnpi:                ;dépile les deux dernier nombres
pop ecx
pop eax
neg eax         ;c'est la seul diff‚rence avec l'op‚ration +
mov [op2h],eax
mov [op2b],ecx
pop ecx
pop eax
mov [op1h],eax
mov [op1b],ecx
jmp faitleplus

plusnpi:                ;dépile les deux dernier nombres
pop ecx
pop eax
mov [op2h],eax
mov [op2b],ecx
pop ecx
pop eax
mov [op1h],eax
mov [op1b],ecx

faitleplus:
xor edx,edx
mov eax,[op1h]
mov ecx,[op2b] 
imul ecx
mov [op1h],eax 
xor edx,edx
mov eax,[op1b]
mov ecx,[op2h] 
imul ecx
mov [op2h],eax 

xor edx,edx
mov eax,[op1b]
mov ecx,[op2b] 
imul ecx
mov [op3b],eax 

mov eax,[op1h]
add eax,[op2h]
mov [op3h],eax

mov eax,[op3h]              ;rempile le résultat  
mov ecx,[op3b]
push eax                     
push ecx
inc ebx
jmp boclcnpi
jmp boclcnpi


chiffrenpi:         ;on décode le nomre et on l'empile
xor edx,edx
bochifnpi:
mov al,[bx]
cmp al,"."
je suitedecod     ;si on tombe sur un . c'est qu'on a finit de lire le nombre
cmp al," "
je findecod     ;sion tombe sur un espace c'est qu'on a finit de lire le nombre
sub al,"0"
and eax,0Fh
mov ecx,edx         ;divise edx par dix  1) on dédouble la variable
shl edx,3           ;2) on multiplie l'un par 8 (décalage de 3 bit)
shl ecx,1           ;3) on multiplie l'autre par 2 (décalage de 1 bit)
add edx,ecx         ;4) on additionne les résultat
add edx,eax
inc ebx
jmp bochifnpi

findecod:
push edx
mov edx,1
push edx
inc ebx
jmp boclcnpi

suitedecod:
inc ebx
mov [op3h],edx
mov dword[op3b],1

bocvirnpi:
mov al,[bx]
cmp al," "
je findecodvir     ;si on tombe sur un espace c'est qu'on a finit de lire le nombre
cmp al,0
je findecodvir     ;ou si on tombe sur la fin de la chaine
sub al,"0"
and eax,0Fh
mov edx,[op3h]
mov ecx,edx         ;divise edx par dix  1) on dédouble la variable
shl edx,3           ;2) on multiplie l'un par 8 (décalage de 3 bit)
shl ecx,1           ;3) on multiplie l'autre par 2 (décalage de 1 bit)
add edx,ecx         ;4) on additionne les résultat
add edx,eax
mov [op3h],edx

mov edx,[op3b]
mov ecx,edx         ;divise edx par dix  1) on dédouble la variable
shl edx,3           ;2) on multiplie l'un par 8 (décalage de 3 bit)
shl ecx,1           ;3) on multiplie l'autre par 2 (décalage de 1 bit)
add edx,ecx         ;4) on additionne les résultat
mov [op3b],edx
call ajustement
inc ebx
jmp bocvirnpi

findecodvir:
mov eax,[op3h]              ;rempile le résultat  
mov ecx,[op3b]
push eax                     
push ecx
jmp boclcnpi  

finpi:
pop ecx   ;diviseur
pop eax   ;divisé

mov [xb],ecx    ;sauvegarde le résultat
mov [xh],eax





;**************************************************************
;affiche le résultat
pushad
mov edx,msgegal
mov al,11
mov ah,0Fh ;couleur
int 63h
popad

test ecx,80000000h
jz pasinv
neg ecx
neg eax
pasinv:
test eax,80000000h
jz pasneg
neg eax

pushad
mov edx,msgneg
mov al,11
mov ah,0Fh ;couleur
int 63h
popad

pasneg:
push ecx
xor edx,edx
div ecx
pop ecx

pushad
mov ecx,eax
mov edx,tempo
mov al,102
int 61h
mov edx,tempo
mov al,11
mov ah,0Fh ;couleur
int 63h
popad

cmp edx,0
je  finaffichage

pushad
mov edx,msgvirg
mov al,11
mov ah,0Fh ;couleur
int 63h
popad

mov bp,20       ;20 chiffre apres la virgule maximum
recom:
mov eax,edx

push ecx
xor edx,edx
mov ecx,10
mul ecx
xor edx,edx
pop ecx
div ecx

pushad
mov ecx,eax
mov edx,tempo
mov al,102
int 61h
mov edx,tempo
mov al,11
mov ah,0Fh ;couleur
int 63h
popad

cmp edx,0
je finaffichage

dec bp
jnz recom



finaffichage:
mov edx,ligne
mov al,11
mov ah,0Fh ;couleur
int 63h



mov byte[exp_hab],0
jmp boucle_principale


;******************************************************
ajustement:
;test dword[op3h],01h
;jnz pasadj
;test dword[op3b],01h
;jnz pasadj
;shr dword[op3h],1
;shr dword[op3b],1
ret

pasadj:
ret




;**************************************************************
sdata1:
org 0

msg_debut:
db "calculatrice simple"
ligne:
db 13,0

msgneg:
db "-",0
msgvirg:
db ",",0
msgegal:
db " = ",0


err_syn:
db 13,"erreur dans la syntaxe de l'expression",13,0

err_carac:
db 13,"caractère non reconnue dans l'expression",13,0

err_hexa:
db 13,"caractère héxadécimal",13,0

err_para:
db 13,"erreur de paranthèse",13,0


xh:
dd 0
xb:
dd 1


op1h:     ;op‚rande de calcul
dd 0
op1b:
dd 0
op2h:
dd 0
op2b:
dd 0
op3h:
dd 0
op3b:
dd 0
sauvesp:
dd 0


tempo:
dd 0,0,0,0


exp_hab:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
exp_npi:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0




sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
