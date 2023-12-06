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


cmp byte[edx],22h   ;ignore le guillemet du début
jne @f
inc edx
@@:



cmp byte[edx],"#"      ;si le premier caractere est un croisillon c'est un nom de disque
je nvchemin            ;on part alors d'un chemin vide


cmdcd_decode:

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

@@:  ;retire les slash, antislash, et les espaces a la fin de la chaine actuelle
dec edi
cmp byte[edi],"/"
je @b
cmp byte[edi],"\"
je @b
cmp byte[edi]," "
je @b
inc edi


cmdcd_1:
cmp byte[edx],"/"      ;verifie la présence de slash et antislash au début de la nouvelle chaine
jne passlashcdr
inc edx                ; et les supprime
passlashcdr:
cmp byte[edx],"\" 
jne pasaslashcdr
inc edx
pasaslashcdr:


;cherche
mov eax,[edx]
and eax,0FFFFFFh
cmp eax,".."
je @f
cmp eax,222E2Eh ; .."
je @f
cmp eax,"../"
je @f
cmp eax,"..\"
jne cmdcd_ajchemin

@@:     ;supprime le dernier dossier
dec edi
cmp byte[edi],"/"
je @f
cmp byte[edi],"\"
je @f
cmp edi,ad_chaine_travail
jne @b
jmp cderr2 
@@:

add edx,2
cmp byte[edx],0
je @f
cmp byte[edx],22h
jne cmdcd_1
@@:
mov byte[edi],0
jmp cdouvdossier



cmdcd_ajchemin:
mov byte[edi],"/"   ;ajoute le chemin dans la commande au chemin actuelle
inc edi
jmp @f


nvchemin:
mov edi,ad_chaine_travail

@@:
mov al,[edx]
mov[edi],al
inc edx
inc edi
cmp al,0
je @f
cmp al,22h
jne @b
dec edi
mov byte[edi],0
@@:


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
mov al,17h
call affcj
mov al,13
call affcj
jmp pascommande



cderr2:       ;si on as demandé le fichier racine, afficher un message
mov cl,5
call affmsgsyst
jmp pascommande



cmdcdpp:
mov edx,ad_zdc+2
jmp cmdcd_decode



