;sous fonction intégré de changement de répertoire

mov edx,ad_zdc

bcdeb1cd:
cmp byte[edx],0
je cderr           ;si on arrive a la fin de la chaine c'est une erreur
inc edx
cmp byte[edx]," "
jne bcdeb1cd            ;trouver le début du nom du dossier a ouvrir
bcdeb2cd:               ;d'abord les espaces après la commande
cmp byte[edx],0
je cderr
inc edx
cmp byte[edx]," "
je bcdeb2cd             ;ensuite le début du nom

cmp byte[edx],"#"      ;si c'est un croisillon c'est un nom de disque
je nvchemin

mov esi,ad_repertoire  ;recopie le chemin actuel dans la chaine de travail
mov edi,ad_chaine_travail
borchem:
mov al,[esi]
mov[edi],al
inc esi
inc edi
cmp al,0
jne borchem
dec edi

tcdslash:  ;retire les slash, antislash et les espaces a la fin de la chaine
dec edi
cmp byte[edi],"/"
je tcdslash
cmp byte[edi],"\"
je tcdslash
cmp byte[edi]," "
je tcdslash
inc edi

cmp byte[edx],"/"      ;verifie la présence de slash et antislash
jne passlashcdr
inc edx                ; et les supprime
passlashcdr:
cmp byte[edx],"\" 
jne pasaslashcdr
inc edx
pasaslashcdr:


mov byte[edi],"/"   ;ajoute le chemin dans la commande au chemin actuelle
inc edi             ;avec un slash devant
bcreccd:
mov al,[edx]
mov [edi],al
inc edx
inc edi
cmp al,0
jne bcreccd
jmp cdouvdossier

nvchemin:
mov ebx,ad_chaine_travail
bnvchem:
mov al,[edx]
mov[ebx],al
inc edx
inc ebx
cmp al,0
jne bnvchem

cdouvdossier:   ;ouvre le dossier
xor eax,eax
xor ebx,ebx
mov edx,ad_chaine_travail
int 64h
cmp eax,cer_dov       ;si c'est bien un dossier que l'on vient d'ouvrir
jne cderr

;si le dossier existe, on déplace le descripteur dans le descripeur de fichier zéro
shl ebx,5
mov edi,[ad_ficho]
add ebx,edi
mov si,selramh
push ds
push es
mov ds,si
mov es,si
mov esi,ebx
mov ecx,32
cld
rep movsb   ;déplacement

mov byte[ebx],0 ;effacement source
pop es
pop ds

mov esi,ad_chaine_travail   ;et on recopie le chemin du dossier dans le chemin ouvert
mov edi,ad_repertoire
bokchem:
mov al,[esi]
mov[edi],al
inc esi
inc edi
cmp al,0
jne bokchem

or byte[at_csl],04h

jmp pascommande

cderr:       ;si le dossier n'est pas accesible, afficher un message
mov cl,2
call affmsgsyst
mov edx,ad_chaine_travail
call affjournal
mov al,13
call affcj
jmp pascommande







;****************************************************************
cmdcdpp:
mov esi,ad_repertoire  ;recopie le chemin actuel dans la chaine de travail
mov edi,ad_chaine_travail
recopiechem:
mov al,[esi]
mov[edi],al
inc esi
inc edi
cmp al,0
jne recopiechem
dec edi         ;edi pointe sur le zéro de la fin de la chaine
cmp edi,ad_chaine_travail 
je cderr        ;si edi est vide c'est une erreur

tcdppslash:  ;retire les slash, antislash et les espaces a la fin de la chaine
dec edi
cmp byte[edi],"/"
je tcdppslash
cmp byte[edi],"\"
je tcdppslash
cmp byte[edi]," "
je tcdppslash
cmp byte[edi],0
je tcdppslash
cmp edi,ad_chaine_travail 
je cderr        ;si on est au dbut de la chaine c'est une erreur

bccdpp:     ;supprime le dernier dossier
dec edi
cmp byte[edi],"/"
je finbccpp
cmp byte[edi],"\"
je finbccpp
cmp edi,ad_chaine_travail
jne bccdpp
jmp cderr

finbccpp:
mov byte[edi],0
jmp cdouvdossier

