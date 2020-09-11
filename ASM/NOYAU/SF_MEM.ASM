sf_mem:
;sous fonctions de manipulation de la mémoire
;la mémoire allouable est répartie a partir de l'adresse 100000h celle ci correspond a la valeur zéro de la mémoire uttilisable
;chaque espace mémoire de X*16 octet occupe une taille de (X+1)*16 octet, ces 16 octets supplémentaires correspondent a un descripteur comme suit:
;0 octets "DM" en ascii 
;2 une lettre pour décrire ce qu'il y a dans le descripteur
;4 taille de la zone, descripteur inclu
;8 informations optionnels, dépendent du type de la zone


;**************************************************************************
resmem:   ;réserve mémoire
;in: ecx=taille souhaité (multiple de 16 octets obligatoirement)
;out ebx=position de la mémoire haute
;cf=0 ok    cf=1 erreur    
push eax
push ecx
push esi
push edi
push ds
push es
cli

mov ax,selramh
mov ds,ax
mov ax,seldat
mov es,ax

test ecx,0Fh        ;on test la granularité de la quantit demand
jnz trouvtnok
add ecx,10h        ;on ajoute la taille du descripteur

mov esi,0FFFFFFFFh   ;taille du plus petit descripteur rencontré mais sufisament grand
mov edi,0FFFFFFFFh   ;adresse du plus petit descripteur vide rencontré mais sufisament grand
xor ebx,ebx

bouclrecm:
cmp byte[ebx+2],"V"
je desvide
cmp byte[ebx+2],"F"
je trouvfinmem 
passelazone:     
mov eax,[ebx+4]    ;la zone a été testé, on passe a la suivante
add ebx,eax
jmp bouclrecm

desvide:
cmp ecx,[ebx+4]
je trouvtok     ;zone pile de la bonne taille
ja passelazone  ;zone vide mais trop petite

cmp esi,[ebx+4] ;test si cette zone est la plus petite zone vide suffisante rencontré
jb passelazone
mov esi,[ebx+4] ;si oui sauvegarde ses coordonnées
mov edi,ebx
jmp passelazone

trouvfinmem:          ;on est arrivé a la fin de la mémoire sans trouver notre bonheur
cmp esi,0FFFFFFFFh    ; a t'on trouvé au moin une zone de taille sufisante?
je trouvtnok

mov byte[edi+2],"S"   ;on le marque comme zone système
xchg [edi+4],ecx      ;on lui alloue la bonne taille
sub ecx,[edi+4]       ;on calcule la taille de l'espace non uttilis
xor eax,eax
mov [edi+8],eax 
mov [edi+0Ch],eax


push ecx     ;vide l'espace mémoire nouvellement créer
push edi		
mov ecx,[edi+4]
add edi,10h
sub ecx,10h
xor eax,eax
shr ecx,2
boucle_efface_resmem:
mov[edi],eax
add edi,4
dec ecx
jnz boucle_efface_resmem
pop edi
pop ecx


mov ebx,edi           ;on cre une zone vide avec l'espace non uttilis en deux
add ebx,[edi+4]       ;d'abord on rcupre l'adresse de la zone


mov dword[ebx],"DMV " ;on lui cre un descripteur vide valide
xor eax,eax
mov [ebx+4],ecx      ;avec la taille pralablement calcul
mov [ebx+8],eax 
mov [ebx+0Ch],eax

mov ebx,edi
call majetm  ;met a jour les compteurs 
clc
pop es
pop ds
pop edi
pop esi
pop ecx
pop eax
ret

trouvtnok:
xor ebx,ebx
stc
pop es
pop ds
pop edi
pop esi
pop ecx
pop eax
ret

trouvtok:             ;on a trouvé une zone mémoire pile a la taille!
mov byte[ebx+2],"S"   ;on le marque comme zone système
call majetm  ;met a jour les compteurs
clc
pop es
pop ds
pop edi
pop esi
pop ecx
pop eax
ret

;********************************************************************************
resmemg:
;in: ecx=taille souhaité (multiple de 16 octets obligatoirement)
;    eax=masque (les bit mis a un dans le masque devront être a zéro dans l'adresse des données de la zone)
;out ebx=position de la mémoire haute
;cf=0 ok    cf=1 erreur   

push eax
push ecx
push edx
push esi
push edi
push ds
cli
mov dx,selramh
mov ds,dx

mov edi,ecx ;sauvegarde taille souhaité
push eax
inc eax
add ecx,eax  ;calcul taille demandé + granularité
call resmem
pop eax
mov esi,ebx   ;esi=adresse de la zone mémoire 
jc fin_resmemg ;si il n'y a aucune place suffisante on quitte

mov edx,ebx
add edx,10h
test edx,eax
jz redim_resmemg    ;la zone trouvé est a la bonne granularité   

mov edx,eax
not eax
inc edx
and ebx,eax
add ebx,edx         
sub ebx,10h     ;ebx=adresse dans la zone mémoire respectant la granularité souhaité

mov ecx,[esi+4]
add ecx,esi
sub ecx,ebx        ;ecx= taille de la nouvelle zone

          
mov dword[ebx],"DMS "    ;on crée un descripteur pour cette zone
xor eax,eax
mov [ebx+4],ecx
mov [ebx+8],eax 
mov [ebx+0Ch],eax 

mov ecx,ebx
sub ecx,esi       ;ecx= taille de la zone précédente
mov [esi+4],ecx   ;on met a jour le descripteur
mov byte[esi+2],"V"

redim_resmemg:
mov ecx,edi
call modtm  ;on redimensionne la zone
fin_resmemg:
pop ds
pop edi
pop esi
pop edx
pop ecx
pop eax
ret


;********************************************************************************
resmemgo:
;in: ecx=taille souhaité (multiple de 16 octets obligatoirement)
;    eax=masque (les bit mis a un dans le masque devront être a zéro dans l'adresse des données de la zone)
;    edi=offset de la granularité par rapport au début de la zone
;out ebx=position de la mémoire haute
;cf=0 ok    cf=1 erreur   

push eax
push ecx
push edx
push esi
push edi
push ebp
push ds
cli
mov dx,selramh
mov ds,dx

mov ebp,ecx ;sauvegarde taille souhaité
push eax
inc eax
add ecx,eax  ;calcul taille demandé + granularité
call resmem
pop eax
mov esi,ebx   ;esi=adresse de la zone mémoire 
jc fin_resmemgo ;si il n'y a aucune place suffisante on quitte

mov edx,ebx
add edx,edi
test edx,eax
jz redim_resmemgo    ;la zone trouvé est a la bonne granularité   

mov edx,eax
not eax
inc edx
and ebx,eax
add ebx,edx         
sub ebx,edi     ;ebx=adresse dans la zone mémoire respectant la granularité souhaité

mov ecx,[esi+4]
add ecx,esi
sub ecx,ebx        ;ecx= taille de la nouvelle zone

          
mov dword[ebx],"DMS "    ;on crée un descripteur pour cette zone
xor eax,eax
mov [ebx+4],ecx
mov [ebx+8],eax 
mov [ebx+0Ch],eax 

mov ecx,ebx
sub ecx,esi       ;ecx= taille de la zone précédente
mov [esi+4],ecx   ;on met a jour le descripteur
mov byte[esi+2],"V"

redim_resmemgo:
mov ecx,ebp
call modtm  ;on redimensionne la zone
fin_resmemgo:
pop ds
pop ebp
pop edi
pop esi
pop edx
pop ecx
pop eax
ret



;******************************************************************************
resmemp:            ;réserve une zone de mémoire physique
                    ;edx=adresse physique souhaité
                    ;ecx=qt souhaité
pushad
push ds
cli
mov ax,selramh
mov ds,ax


test edx,0Fh
jnz resmemp_erreur_param
test ecx,0Fh
jnz resmemp_erreur_param
cmp edx,100010h
jbe resmemp_erreur_param

sub edx,100010h
add ecx,10h
add ecx,edx     ;edx=adresse 1er octet a utilliser ecx=adresse octet suivant libre



xor ebx,ebx
resmemp_boucle:
cmp word[ebx],"DM"
jne resmemp_erreur_structure
mov eax,[ebx+4]
add eax,ebx     ;eax=adresse de la zone suivante ebx=adresse de la zone analysé

cmp byte[ebx+2],"F"
je resmemp_fin_absent
cmp byte[ebx+2],"V"
jne resmemp_ignore

cmp edx,ebx
je resmemp_trouve_debut
jb resmemp_fin_indisponible
cmp edx,eax
ja resmemp_ignore
cmp ecx,eax
je resmemp_trouve_fin
jb resmemp_trouve_centre

resmemp_ignore:
mov ebx,eax
jmp resmemp_boucle



resmemp_trouve_debut:          ;la zone souhaité se trouve au début d'une zone vide
mov byte[edx+2],"S"
mov [edx+4],ecx
sub [edx+4],edx
mov dword[edx+8],0
mov dword[edx+12],0

cmp ecx,eax
je resmemp_fin_ok

mov word[ecx],"DM"
mov byte[ecx+2],"V"
mov [ecx+4],eax
sub [ecx+4],ecx
mov dword[ecx+8],0
mov dword[ecx+12],0
jmp resmemp_fin_ok



resmemp_trouve_centre:    ;la zone souhaité se trouve au millieux d'une zone vide
mov [ebx+4],edx
sub [ebx+4],ebx

mov word[edx],"DM"
mov byte[edx+2],"S"
mov [edx+4],ecx
sub [edx+4],edx
mov dword[edx+8],0
mov dword[edx+12],0

mov word[ecx],"DM"
mov byte[ecx+2],"V"
mov [ecx+4],eax
sub [ecx+4],ecx
mov dword[ecx+8],0
mov dword[ecx+12],0
jmp resmemp_fin_ok



resmemp_trouve_fin:   ;la zone souhaité se trouve a la fin d'une zone vide
mov [ebx+4],edx
sub [ebx+4],ebx

mov word[edx],"DM"
mov byte[edx+2],"S"
mov [edx+4],ecx
sub [edx+4],edx
mov dword[edx+8],0
mov dword[edx+12],0



resmemp_fin_ok:
call majetm   ;met a jour les compteurs
pop ds
popad
xor eax,eax
ret

resmemp_erreur_param:
pop ds
popad
mov eax,cer_parami ;erreur de parametre
ret

resmemp_erreur_structure:
pop ds
popad
mov eax,cer_ers ;erreur de structure mémoire
ret

resmemp_fin_indisponible:
pop ds
popad
mov eax,cer_znd   ;zone non disponible
ret

resmemp_fin_absent:
pop ds
popad
mov eax,cer_zhm   ;zone hors mémoire
ret






;*********************************************************************************
libmem:   ;libère de la mémoire
;in: ebx=adresse de la mémoire haute a liberer
;cf=0 ok    cf=1 erreur    
push eax
push ebx
push ds
push es
cli

;vérifie la validité du descripteur
mov ax,selramh
mov ds,ax
mov ax,seldat
mov es,ax

test ebx,0Fh        ;on test la granularité de l'adresse demandé
jnz nolibmem


cmp word[ebx],"DM"
jne nolibmem

;change le descripteur de mémoire en descripteur de mémoire vide
mov byte[ebx+2],"V"
xor eax,eax
mov [ebx+08h],eax
mov [ebx+0Bh],eax

call fusmemv  ;fusionne les descripteurs de mémoire vide contigue 
call majetm   ;met a jour les compteurs
clc
pop es
pop ds
pop ebx
pop eax
ret

nolibmem:
stc
pop es
pop ds
pop ebx
pop eax
ret


;*********************************************************************************
majetm:   ;maj de l'état de la mémoire: compte la quantité occupé par les différentes zone 
push eax
push ebx
push ds
push es

mov ax,selramh
mov ds,ax
mov ax,seldat
mov es,ax

xor ebx,ebx                  ;remise a zéro des différents indicateurs
es
mov [taille_mem_vide],ebx
es
mov [taille_mem_syst],ebx
es
mov [taille_mem_tache],ebx
es
mov [taille_mem_com],ebx
es
mov [nb_zone_vide],bx
es
mov [nb_zone_syst],bx
es
mov [nb_zone_tache],bx
es
mov [nb_zone_com],bx


boclmajetm:        ;parcours les différentes zone de mémoire
mov al,[ebx+2]
cmp al,"V"
je tzvide
cmp al,"S"
je tzsyst
cmp al,"T"
je tztache
cmp al,"C"
je tzcom
cmp al,"F"
je tzfin
mov eax,[ebx+4]
add ebx,eax
jmp boclmajetm

tzfin:
pop es
pop ds
pop ebx
pop eax
ret

tzvide:                ;et additionne les tailles des différentes zones suivant leurs type
mov eax,[ebx+4]
es
inc word[nb_zone_vide]
es
add [taille_mem_vide],eax
add ebx,eax
jmp boclmajetm

tzsyst:
mov eax,[ebx+4]
es
inc word[nb_zone_syst]
es
add [taille_mem_syst],eax
add ebx,eax
jmp boclmajetm

tztache:
mov eax,[ebx+4]
es
inc word[nb_zone_tache]
es
add [taille_mem_tache],eax
add ebx,eax
jmp boclmajetm

tzcom:
mov eax,[ebx+4]
es
inc word[nb_zone_com]
es
add [taille_mem_com],eax
add ebx,eax
jmp boclmajetm



;***************************************************************************
fusmemv:     ;fusionne les zone vides entres elles
push eax
push ebx
push esi
push ds

mov ax,selramh
mov ds,ax
xor ebx,ebx

mov eax,[ebx+4]
mov esi,ebx
add ebx,eax

bouclefusion:
cmp byte[ebx+2],"F"
je finfusion              ;si on tombe le descripteur final on arrete
cmp byte[ebx+2],"V"
jne pasfusion
cmp byte[esi+2],"V"      ;si les deux zone qui se suivent sont "vide"
jne pasfusion

;toutes les conditions sont remplies on fusionne les deux zones de vide
mov eax,[ebx+4]    ;rcupre la taille de la deuxime zone
add [esi+4],eax    ;et l'ajoute a la zone prcdente
xor eax,eax
mov [ebx+0],eax    ;on efface le descripteur innutilis
mov [ebx+4],eax
mov [ebx+8],eax
mov [ebx+0Ch],eax
mov ebx,esi

pasfusion:
mov eax,[ebx+4]
mov esi,ebx           ;esi=descripeur prcdent
add ebx,eax           ;ebx=descripteur en cours
jmp bouclefusion


finfusion:
pop ds
pop esi
pop ebx
pop eax
ret





;*********************************************************************************
modtm:   ;modifie la taille d'une zone mmoire
;in  ecx=taille souhaité (multiple de 16 octets obligatoirement)
;    ebx=adresse de la zone a agrandir
;out ebx=position de la zone aggrandit
;cf=0 ok    cf=1 erreur    
push eax
push edx
push esi
push edi
push ds
push es
push fs
cli

mov ax,selramh
mov ds,ax
mov es,ax
mov ax,seldat
mov fs,ax

test ecx,0Fh
jnz echecagrzm ;verifie que ecx est un multiple de 16
add ecx,10h
cmp ecx,0
jz echecagrzm  ;verifie que ecx n'est pas nul

cmp ecx,[ebx+4]  ;si la nouvelle taille est plus petite on rduit la zone
jna reducmem

mov eax,[ebx+4]
mov esi,ebx
add esi,eax
cmp byte[esi+2],"V"    ;on test si la zone suivante est vide
jne passuivievide


add eax,[esi+4]
cmp eax,ecx            ;et suffisante pour contenir la nouvelle zone?
jb passuivievide


;si la zone suivante est vide on redimensionne les deux zone
sub eax,ecx     ;eax=taille de la zone vide

push ecx        ;on efface la zone mémoire que l'on vas occuper
push esi
xor edx,edx
add ecx,ebx         
efface_modtm:
mov [esi],edx
add esi,4
cmp esi,ecx
jnz efface_modtm
pop esi
pop ecx

cmp eax,0           ;test si le nouveau descripeur est de taille 0
je pasdescnouv      ;si oui pas besoin d'en recreer un
mov esi,ebx         ;on replace le nouveau
add esi,ecx
mov word[esi],"DM"
mov byte[esi+2],"V"
mov [esi+4],eax
mov [esi+8],edx
mov [esi+0Ch],edx

pasdescnouv:
mov [ebx+4],ecx    ;on enregistre le premier descripteur avec la bonne taille 
jmp finagrmem



passuivievide:    ;on realoue une zone a la bonne taille 
mov esi,ebx
sub ecx,10h
call resmem  
jc echecagrzm     ;test si on a trouv

;et on transfert les donnes dans la nouvelle zone
mov ecx,[esi+4]  ;on rcupre la taille de la zone d'origine
sub ecx,10h      ;on enlve la taille du descipteur
shr ecx,2        ;on convertie en nombre de dword (div par 4)

push esi
add esi,10h      ;calcul de la source
mov edi,ebx
add edi,10h      ;calcul de la destination
cld
rep movsd
pop esi

;on transfert ses carac a la nouvelle  
mov dl,[esi+2]
mov [ebx+2],dl   ;la lettre de type 
mov edx,[esi+8]
mov [ebx+8],edx   ;les indications optionnelles 1
mov edx,[esi+0Ch]
mov [ebx+0Ch],edx   ;les indications optionnelles 2

;puis on marque comme vide l'ancienne zone
mov byte[esi+2],"V"     
xor edx,edx
mov [esi+08h],edx   
mov [esi+0Ch],edx   ;les indications optionnelles 1&2

finagrmem: 
call fusmemv  ;fusionne les descripteurs de mémoire vide contigue 
call majetm   ;met a jour les compteurs
clc
pop fs
pop es
pop ds
pop edi
pop esi
pop edx
pop eax
ret

reducmem:
cmp ecx,[ebx+4]
je finreducmem

xchg [ebx+4],ecx   ;met la nouvelle taile dans le descripteur
sub ecx,[ebx+4]    ;calcul la taille du descripteur vide a mettre aprs

push ebx
mov eax,[ebx+4]
add ebx,eax
mov word[ebx],"DM"    ;crer le descripeur vide
mov byte[ebx+2],"V"
mov [ebx+4],ecx
xor eax,eax
mov [ebx+8],eax
mov [ebx+0Ch],eax
pop ebx

call fusmemv  ;fusionne les descripteurs de mémoire vide contigue 
call majetm   ;met a jour les compteurs
finreducmem:
clc
pop fs
pop es
pop ds
pop edi
pop esi
pop edx
pop eax
ret


echecagrzm:
stc
pop fs
pop es
pop ds
pop edi
pop esi
pop edx
pop eax
ret
