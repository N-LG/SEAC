int 60h




;*****************************************************************************
;sous fonctions générale


lire_arg: ;recopie l'argument cl (1er = 0) en ds:edx 
push eax
push ecx
mov al,4
mov ah,cl
mov cl,25 ;taille max
int 61h
pop ecx
pop eax
ret



ouvre_fichier:
;entrée: ds:edx=nom du fichier a ouvrir
;sortie  eax=0 si ok   ebx=handle du fichier ouvert
xor ebx,ebx
mov al,0
int 64h
ret


cree_fichier:
;entrée: ds:edx=nom du fichier a créer
;sortie  eax=0 si ok   ebx=handle du fichier crée
xor ebx,ebx
mov al,2
int 64h
ret



ferme_fichier:
;ebx = handle fichier
mov al,1
int 64h
ret



lit_fichier:
;ebx=handle
;ecx=quantité
;edx=offset dans le fichier
;edi=adresse de destination
push es
mov ax,ds
mov es,ax
mov al,4
int 64h
pop es
ret

ecr_fichier:
;ebx=handle
;ecx=quantité
;edx=offset dans le fichier
;esi=adresse de source
push es
mov ax,ds
mov es,ax
mov al,5
int 64h
pop es
ret



taillef: ;ebx=handle
;sortie: ecx=taille
push edx
push ds
mov al,6
mov ah,1
mov edx,qword_temporaire
int 64h
cmp dword[qword_temporaire+4],0
jne taillef2
mov ecx,[qword_temporaire]
pop ds
pop edx
ret

taillef2:
mov ecx,0FFFFFFFFh
pop ds
pop edx
ret


affmsg: ;affiche la chaine asciiz pointé par edx
push eax
mov al,6
int 61h
pop eax
ret

conv_nombre:
ret



;***************************************************
sdata1:
org 0

qword_temporaire:
dd 0,0
 