;fichier d'include standard pour linux par nlg pour son usage personnel

;fin du programme
mov	eax,1
xor	ebx,ebx
int	80h

;***************
affmsg: ;edx=chaine ascciz a afficher
pushad
mov ecx,edx
mov esi,edx

pastrouvezero:
lodsb
or al,al
jnz pastrouvezero

mov edx,esi
sub edx,ecx
mov eax,4  ;ecrire
mov ebx,1  ;dans console
int 80h
popad
ret


pushdeci:
push eax
push ecx
push edx
mov dl,"$"
push dx
mov ecx,10

bpd32:
xor edx,edx
div ecx
add dl,48
push dx
cmp eax,0
jne bpd32

extract:
pop ax
cmp al,"$"
je finpushdeci
mov [esi],al
inc esi
jmp extract

finpushdeci:
mov word[esi],0020h
pop edx
pop ecx
pop eax
ret

;***************
lire_arg:   ;ecrit l'option numéros cl (commence a zéro) de la commande qui a créer la tache dans ds:edx 
pushad
call lire_commande

mov ah,cl
mov cl,255
mov ebx,commande
boucle_lire_arg_cmd:
cmp byte[ebx],0
jne suite_lire_arg_cmd
cmp byte[ebx+1],0
je suite_lire_arg_cmd
cmp ah,0
je trouve_lire_arg_cmd
dec ah
suite_lire_arg_cmd:
inc ebx
cmp ebx,commande+255
jne boucle_lire_arg_cmd
popad
ret

trouve_lire_arg_cmd:
inc ebx
mov al,[ebx]
mov [edx],al
inc edx
dec cl
jnz trouve_lire_arg_cmd

fin_lire_arg_cmd:
popad
ret


lire_commande:
pushad
cmp dword[handle_cmd],0
je charge_commande
popad
ret

charge_commande:
;récupérer son pid
mov eax,20
int 80h

;place le pid dans les chemin de fichier
mov esi,idproc
call pushdeci
mov edi,finadressecommande   ;puis place la fin de l'adresse du non de fichier
bcldepfin:
mov al,[edi]
mov [esi],al
inc esi
inc edi
cmp al,0
jne bcldepfin

;ouvre son fichier de ligne de commande
mov eax,5
mov ebx,adressecommande
mov ecx,00h ;accès en read only
int 80h
test eax,-1			
;je erreurfich
mov [handle_cmd],eax 

;lit maximum 256 octet du fichier ligne de commande
mov  eax, 3               
mov  ebx, [handle_cmd]                
mov  ecx, commande
mov  edx, 256       ;taille(maximum) a lire         
int  80h

;convertit les espaces en caractère nul
;§§§§§§§§§§§§§§§§§§§§§§

popad
ret

;***************
cree_fichier:
;ds:edx chaine asciiz du nom du fichier
push edx
mov eax,8
mov ebx,edx
mov ecx,01B6h ;accès en read/write
int 80h
pop edx


ouvre_fichier:
;ds:edx chaine asciiz du nom du fichier
;retour: ebx=numéros du déscripteur de dossier
;eax erreur


mov eax,5
mov ecx,02h ;accès en read/write
mov ebx,edx 
mov edx,0   ;?
int 80h
test eax,0FFFF0000h			
jnz erreur_ouvre_fichier 
mov ebx,eax
xor eax,eax
ret

erreur_ouvre_fichier:
xor ebx,ebx
mov eax,13
ret

;***************
lit_fichier:
;ebx=handle
;edx=adresse dans le fichier
;ecx=quantité
;edi=destination
pushad
push ecx                
push ebx

mov eax, 19
mov ecx, edx   ;offset dans le fichier       
mov edx, 0    ;offset depuis dans le début du fichier
int 80h

mov eax, 3               
pop ebx               
mov ecx,edi
pop edx          ;taille(maximum) a lire         
int  80h
cmp eax,-1
je err_lecr
popad
xor eax,eax
ret


;***************
ecr_fichier:
;ebx=handle
;edx=adresse dans le fichier
;ecx=quantité
;esi=source
pushad
push ecx                
push ebx

mov eax, 19
mov ecx,edx   ;offset dans le fichier       
mov edx, 0    ;offset depuis dans le début du fichier
int 80h

mov eax,4               
pop ebx               
mov ecx,esi
pop edx          ;taille(maximum) a lire         
int  80h
cmp eax,-1
je err_lecr
popad
xor eax,eax
ret

err_lecr:
popad
mov eax,13
ret

;***************
taillef:
mov eax,19
mov ecx,0
mov edx,2 ;2=depuis la fin
int 80h
mov ecx,eax
ret


;***************
ferme_fichier:
mov eax,6
int 80h
ret

;***************
conv_nombre:
mov al,"$"
push eax
mov eax,ecx
mov ecx,10

boucle_conv_nombre1:
xor edx,edx
div ecx
add dl,"0"
push edx
cmp eax,0
jne boucle_conv_nombre1

boucle_conv_nombre2:
pop eax
cmp al,"$"
je fin_conv_nombre
mov [esi],al
inc esi
jmp boucle_conv_nombre2


fin_conv_nombre:
mov byte[esi],0
ret



;************************************************************************************************
;données nécessaire a ces sous fonctions
segment readable writeable

;données de fonction de lecture commande
handle_cmd:
dd 0
adressecommande:
db "/proc/"
idproc:
db "             "
finadressecommande:
db "/cmdline",0
commande:
times 256 db 0




