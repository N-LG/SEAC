;fonction fichier (interruption terminé par un iret)  int 64h
;al=0  ouvrir fichier 
;al=1  fermer le fichier
;al=2  créer fichier
;al=3  supprimer fichier
;al=4  lit le fichier
;al=5  ecrire dans le fichier
;al=6  lit les attributs d'un fichier
;al=7  ecrire les attributs d'un fichier
;al=8  lire dans un secteur
;al=9  ecrire dans un secteur
;al=10 lire les information d'un disque
;al=11 définit le msb du numéros de secteur lors des fonction 8 et 9
;al=12 met a jour la table des partition d'un disque
;al=13 definis vitesse disque
;al=14 définis le msb de l'adresse de lecture/ecriture fichier (fonction 4 et 5)
;al=15 réserve espace pour fichier
;al=16 lit contenue répertoire
;al=17 lit disques disponible

;************************************

pushad        ;sauvegarde les registres et initialise les segments de données
push ds
push es
push fs
push gs

push eax
mov ax,seldat
mov fs,ax
mov ax,selramh
mov gs,ax




testsifcfichierlibre:
cli
fs
test byte[at_fc_fichier],01h
jz fcfichierlibre
sti
int 62h
jmp testsifcfichierlibre

fcfichierlibre:
fs
or byte[at_fc_fichier],01h
fs
mov ax,[id_tache_exec]      ;sauvegarde de l'id de la tache qui utillise les fichier pour qu'au cas ou il y a plantage
fs
mov [id_tache_fichier],ax   ;on pense a rerendre les fonctions fichiers accesible
sti
pop eax 
cmp al,0
je ouvrirfichier
cmp al,1
je fermerfichier
cmp al,2
je creerfichier
cmp al,3
je supprimerfichier
cmp al,4
je lirefichier
cmp al,5
je ecrirefichier
cmp al,6
je infofichier
cmp al,7
je minfofichier
cmp al,8
je liresecteur
cmp al,9
je ecriresecteur
cmp al,10
je infodisque_ata_atapi
cmp al,11
je sff_definis_msb_disque
cmp al,12
je sff_maj_partition
;cmp al,13
;je sff_definis_vitesse_disque
;cmp al,14
;je sff_definis_msb_fichier
cmp al,15
je sff_reserve_espace_fichier
cmp al,16
je sff_lit_dossier
cmp al,17
je sff_lit_disques


errprmsf:   ;erreur de paramètres
fs
and byte[at_fc_fichier],0FEh
int 62h
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_parami
iret

errsysf:    ;erreur du système de fichier
fs
and byte[at_fc_fichier],0FEh
int 62h
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_sysf
iret

errlec:   ;erreur de lecture
fs
and byte[at_fc_fichier],0FEh
int 62h
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_lec
iret

errecr:   ;erreur d'écriture
fs
and byte[at_fc_fichier],0FEh
int 62h
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_ecr
iret

errlecnt:   ;lecteur non trouvé
fs
and byte[at_fc_fichier],0FEh
int 62h
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_lecnt
iret

errpaderep:   ;pas de réponse disque
fs
and byte[at_fc_fichier],0FEh
int 62h
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_prd
iret

errinterdit: ;action non autorisé
fs
and byte[at_fc_fichier],0FEh
int 62h
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_ano
iret

finfonctionfichiererr:    ;préserve eax
fs
and byte[at_fc_fichier],0FEh
int 62h
pop gs
pop fs
pop es
pop ds
ss
mov [esp+28],eax
popad
iret

finfonctionfichierokebx:  ;préserve eax et ebx
fs
and byte[at_fc_fichier],0FEh
int 62h
pop gs
pop fs
pop es
pop ds
ss
mov [esp+28],eax
ss
mov [esp+16],ebx
popad
iret

finfonctionfichier:
fs
and byte[at_fc_fichier],0FEh
int 62h
pop gs
pop fs
pop es
pop ds
popad
xor eax,eax
iret



;*******************************************************************************
;                                                   ****************************
ouvrirfichier:     ;ouvre fichier
		   ;ds:edx chaine asciiz du nom du fichier
		   ;bx=nø du decripteur du dossier
		   ;retour: bx=numéros du déscripteur de dossier
		   ;        al erreur
fs
mov byte[option_ouverture],0
ouvrir_creer_fichier:		   
call initdescrfdcourant


cmp byte [edx],"#"
je nouvlec              ;si le premier carac est un # ouvre un nouveau lecteur
cmp byte [edx],"/"
je debutslash
cmp byte [edx],"\"
je debutslash
jmp debutpaslach

nouvlec:
inc edx
cmp word [edx],"di"
je lec_disquette
cmp word [edx],"dd"
je lec_disquedur
cmp word [edx],"cd"
je lec_cdrom
cmp word [edx],"dm"
je lec_memoire
cmp word [edx],"DI"
je lec_disquette
cmp word [edx],"DD"
je lec_disquedur
cmp word [edx],"CD"
je lec_cdrom
cmp word [edx],"DM"
je lec_memoire
jmp errprmsf

lec_disquette:
cmp byte [edx+2],"/"
je suite1_lec_disquette
cmp byte [edx+2],"\"
je suite1_lec_disquette
cmp byte [edx+2],0
jne errprmsf
suite1_lec_disquette:

fs                                    ;le descripteur 0 est réservé pour la disquette
mov byte[no_part],0                    
fs                                     
mov dword[ad_partition],0              ;charge les données coresspondant a un disquette de 1.44Mo en FAT12
fs
mov dword[to_partition],2880
fs
mov byte[no_disquepart],01h
fs
mov byte[at_partition],04h


push es               ;charge le MBR de la disquette
mov bx,seldat
mov es,bx
fs
mov ebx,[ad_partition]
fs
mov ch,[no_disquepart]
mov cl,01
mov edi,bootsecteur+512
call lsct     
pop es
cmp eax,0
jne errlec


xor eax,eax
fs
mov ax,[bootsecteur+512+0Eh] ;nombre de secteur réservé en debut de partition
fs
add eax,[ad_partition]
fs
mov [ad_fat],eax          ;adresse absolue de la FAT   

xor eax,eax
fs
mov ax,[bootsecteur+512+16h]    ;taille d'une fat en secteur
fs
mov [to_fat],eax  ;taille d'une fat


push edx
xor ecx,ecx
xor edx,edx
fs
mov cl,[bootsecteur+512+10h]  ;nombre de FAT
fs
mov [nb_fat],cl
mul ecx
pop edx
fs
add eax,[ad_fat]
push eax   ;adresse du repertoire racine  

xor ecx,ecx
fs
mov cx,[bootsecteur+512+11h]   ;taille du repertoir racine (en nombre d'entrée de 32 octet)
shr ecx,4    ;mul par 32 et div par 512 (divise par 16)pour avoir la taille du rep racine en secteur
add eax,ecx  ;eax=adresse du cluster 2

xor ecx,ecx
fs
mov cl,[bootsecteur+512+0Dh]
fs
mov [nb_sec_cluster],cl      ;nombre de secteur par cluster

shl ecx,1    ;ecx=nombre de secteur pour 2 cluster  
sub eax,ecx  ;les cluster 1 et 2 n'existe pas!
fs
mov [ad_cluster0],eax  ;adresse du cluster 0

xor eax,eax
fs
mov ax,[bootsecteur+512+0Bh]      ;nombre d'octet par secteur
xor ecx,ecx
fs
mov cl,[bootsecteur+512+0Dh]      ;nombre de secteur par cluster  
push edx
xor edx,edx
mul ecx
pop edx
fs
mov [to_1cluster],eax   ;taille d'un cluster en octet


pop eax
fs
mov [ad_fichier],eax ;adresse du dossier racine
xor ecx,ecx
fs
mov cx,[bootsecteur+512+11h]   ;taille du repertoir racine (en nombre d'entrée de 32 octet)
shl ecx,5          ;mul par 32, la taille est en octet
fs
mov [to_fichier],ecx 

fs
mov byte[at_fichier],010011b  ;attribut de dossier racine fat12 

xor eax,eax    ;efface les données du repertoire du fichier
fs
mov [ad_dossierfichier],eax
fs
mov [to_dossierfichier],eax
fs
mov [ad_dansdossier],eax

fs
mov ax,[id_tache_exec]
fs
mov [id_ouvf],ax

xor edx,edx                ;calcul du nombre de cluster
xor ecx,ecx
fs
mov eax,[ad_partition]
fs
add eax,[to_partition]
fs
sub eax,[ad_cluster0]
fs
mov cl,[nb_sec_cluster]
div ecx
fs
mov [nb_cluster],eax

call sauvdescp ;sauve le descripteur car il  a été mis a jour

add edx,2
jmp dossiersuivant


lec_disquedur:
cmp byte [edx+3],"/"
je unchiffre_lec_disquedur
cmp byte [edx+3],"\"
je unchiffre_lec_disquedur
cmp byte [edx+3],0
je unchiffre_lec_disquedur

cmp byte [edx+4],"/"
je deuxchiffres_lec_disquedur
cmp byte [edx+4],"\"
je deuxchiffres_lec_disquedur
cmp byte [edx+4],0
jne errprmsf

unchiffre_lec_disquedur:
mov al,[edx+2]
sub al,"0"  ;numéros de disque
cmp al,9 
ja errprmsf
xor ecx,ecx
mov cl,al
add edx,3
jmp suite1_lec_disquedur

deuxchiffres_lec_disquedur:
mov ax,[edx+2]
sub al,"0"  ;dizaine numéros de partition
sub ah,"0"  ;unité du numéros de partition
cmp al,9 
ja errprmsf
cmp ah,9 
ja errprmsf
xor ecx,ecx
mov cl,ah
and eax,0FFh
push ecx
push edx
mov ecx,10
xor edx,edx
mul ecx
pop edx
pop ecx
add ecx,eax
add edx,4

suite1_lec_disquedur:     ;ecx=numéros de partition edx=suite de la chaine de dossier
cmp ecx,0
je errprmsf   ;le numéro zéro n'est pas un disque dur
fs
mov [no_part],cl 

call chardescp

;depend du type de partition
fs
cmp byte[at_partition],05h
je repfat16
fs
cmp byte[at_partition],06h
je repfat32
jmp errsysf

repfat16:
push es               ;charge le MBR de la partition
mov bx,seldat
mov es,bx
fs
mov ebx,[ad_partition]
fs
mov ch,[no_disquepart]
mov cl,01
mov edi,bootsecteur+512
call lsct     
pop es
cmp eax,0
jne errlec

fs
cmp byte[ad_fat],0
jne pasmajinfopartfat16  ;si le système a enregistré 0 fat il faut faire une maj des données de la partition

push edx

xor eax,eax
fs
mov ax,[bootsecteur+512+0Eh] ;nombre de secteur réservé en debut de partition
fs
add eax,[ad_partition]
fs
mov [ad_fat],eax          ;adresse absolue de la FAT   

xor eax,eax
fs
mov ax,[bootsecteur+512+16h]    ;taille d'une fat en secteur
fs
mov [to_fat],eax  ;taille d'une fat

xor ecx,ecx
xor edx,edx
fs
mov cl,[bootsecteur+512+10h]  ;nombre de FAT
fs
mov [nb_fat],cl
mul ecx

fs
add eax,[ad_fat]  ;eax=adresse du repertoire racine  

xor ecx,ecx
fs
mov cx,[bootsecteur+512+11h]   ;taille du repertoir racine (en nombre d'entrée de 32 octet)
shr ecx,4    ;mul par 32 et div par 512 (divise par 16)pour avoir la taille du rep racine en secteur
add eax,ecx  ;eax=adresse du cluster 2

xor ecx,ecx
fs
mov cl,[bootsecteur+512+0Dh]
fs
mov [nb_sec_cluster],cl      ;nombre de secteur par cluster

shl ecx,1    ;ecx=nombre de secteur pour 2 cluster  
sub eax,ecx  ;les cluster 1 et 2 n'existe pas!
fs
mov [ad_cluster0],eax  ;adresse du cluster 0

xor eax,eax
fs
mov ax,[bootsecteur+512+0Bh]      ;nombre d'octet par secteur
xor ecx,ecx
fs
mov cl,[bootsecteur+512+0Dh]      ;nombre de secteur par cluster  
xor edx,edx
mul ecx
fs
mov [to_1cluster],eax   ;taille d'un cluster en octet

xor edx,edx                ;calcul du nombre de cluster
xor ecx,ecx
fs
mov eax,[ad_partition]
fs
add eax,[to_partition]
fs
sub eax,[ad_cluster0]
fs
mov cl,[nb_sec_cluster]
div ecx
fs
mov [nb_cluster],eax

call sauvdescp ;sauve le descripteur car il  a été mis a jour
pop edx

pasmajinfopartfat16:

push edx ;determine l'adresse du dossier racine
fs
mov eax,[to_fat]
xor ecx,ecx
xor edx,edx
fs
mov cl,[bootsecteur+512+10h]  ;nombre de FAT
fs
mov [nb_fat],cl
mul ecx
pop edx
fs
add eax,[ad_fat]  ;eax=adresse du repertoire racine  
fs
mov [ad_fichier],eax


fs     ;determine la taille du dossier racine
mov ax,[bootsecteur+512+11h]
shl eax,5      ;mul par 32 car c'est exprimé en nombre d'entrée de répertoire
fs
mov [to_fichier],eax

fs
mov byte[at_fichier],010111b  ;attribut de dossier racine fat16 
fs
mov ax,[id_tache_exec]
fs
mov [id_ouvf],ax

xor eax,eax    ;efface les données du repertoire du fichier
fs
mov [ad_dossierfichier],eax
fs
mov [to_dossierfichier],eax
fs
mov [ad_dansdossier],eax
jmp dossiersuivant





repfat32:
push es               ;charge le MBR de la partition
mov bx,seldat
mov es,bx
fs
mov ebx,[ad_partition]
fs
mov ch,[no_disquepart]
mov cl,01
mov edi,bootsecteur+512
call lsct     
pop es
cmp eax,0
jne errlec

fs
cmp byte[ad_fat],0
jne pasmajinfopartfat32  ;si le système a enregistré 0 fat il faut faire une maj des données de la partition

push edx

xor eax,eax
fs
mov ax,[bootsecteur+512+0Eh] ;nombre de secteur réservé en debut de partition
fs
add eax,[ad_partition]
fs
mov [ad_fat],eax          ;adresse absolue de la FAT   

fs
mov eax,[bootsecteur+512+24h]    ;taille d'une fat en secteur
fs
mov [to_fat],eax  ;taille d'une fat

xor ecx,ecx
xor edx,edx
fs
mov cl,[bootsecteur+512+10h]  ;nombre de FAT
fs
mov [nb_fat],cl
mul ecx
pop edx
fs
add eax,[ad_fat]  ;eax=adresse du cluster 2

xor ecx,ecx
fs
mov cl,[bootsecteur+512+0Dh]
fs
mov [nb_sec_cluster],cl      ;nombre de secteur par cluster

shl ecx,1    ;ecx=nombre de secteur pour 2 cluster  
sub eax,ecx  ;les cluster 1 et 2 n'existe pas!
fs
mov [ad_cluster0],eax  ;adresse du cluster 0

xor eax,eax
fs
mov ax,[bootsecteur+512+0Bh]      ;nombre d'octet par secteur
xor ecx,ecx
fs
mov cl,[bootsecteur+512+0Dh]      ;nombre de secteur par cluster  
push edx
xor edx,edx
mul ecx
fs
mov [to_1cluster],eax   ;taille d'un cluster en octet

xor edx,edx                ;calcul du nombre de cluster
xor ecx,ecx
fs
mov eax,[ad_partition]
fs
add eax,[to_partition]
fs
sub eax,[ad_cluster0]
fs
mov cl,[nb_sec_cluster]
div ecx
fs
mov [nb_cluster],eax

call sauvdescp ;sauve le descripteur car il  a été mis a jour
pop edx

pasmajinfopartfat32:

fs                            ;determine l'adresse du dossier racine
mov eax,[bootsecteur+512+2Ch]
fs
mov [ad_fichier],eax

fs         ;determine la taille du dossier racine
mov dword[to_fichier],0FFFFFFFFh   ;la taille du répertoire root n'est pas connue, on met le max

fs
mov byte[at_fichier],011011b  ;attribut de dossier racine fat32 
fs
mov ax,[id_tache_exec]
fs
mov [id_ouvf],ax

xor eax,eax    ;efface les données du repertoire du fichier
fs
mov [ad_dossierfichier],eax
fs
mov [to_dossierfichier],eax
fs
mov [ad_dansdossier],eax
jmp dossiersuivant


lec_cdrom:
cmp byte [edx+3],"/"
je suite1_lec_cdrom
cmp byte [edx+3],"\"
je suite1_lec_cdrom
cmp byte [edx+3],0
jne errprmsf
suite1_lec_cdrom:
mov al,[edx+2]
sub al,"1"  ;numéros de disque
test al,0F8h
jnz errprmsf
add al,18h      ;on obtient le numéros correcte du disque

;on charge le secteur 16 du disque
mov ch,al  ;ch=nø de disque
mov cl,1   ;cl=nombre de secteur a lire
mov ebx,16 ;ebx=numéros de secteur
push es
mov ax,seldat
mov es,ax
mov edi,bootsecteur
call lsct  ; es:edi zone de destination
pop es
cmp eax,0
jne finfonctionfichiererr



exrootcd:  
fs
cmp byte[bootsecteur],1   ;on verifie que le secteur est bien le primary volume descriptor
jne errsysf
fs
cmp dword[bootsecteur+1],"CD00"
jne errsysf
fs
cmp byte[bootsecteur+5],"1"
jne errsysf
	    ;on extrait les paramètre du repertoire racine (root) 
fs
mov eax,[bootsecteur+158]    ;1er secteur du dossier root
fs
mov [ad_fichier],eax
fs
mov eax,[bootsecteur+166]    ;taille du dossier root
fs
mov [to_fichier],eax
fs
mov [no_part],ch

fs
mov byte[at_fichier],111b       ;dossier racine de lecteur cdrom

xor eax,eax    ;efface les données du repertoire du fichier
fs
mov [ad_dossierfichier],eax
fs
mov [to_dossierfichier],eax
fs
mov [ad_dansdossier],eax

fs                ;charge l'ID de la tache en cours d'execution
mov ax,[id_tache_exec]
fs
mov [id_ouvf],ax

add edx,3               ;edx pointe sur la suite du nom du fichier a lire
jmp dossiersuivant




lec_memoire:
fs
mov byte[at_fichier],1011b       ;dossier racine de fichier mémoire
add edx,2


dossiersuivant:
cmp byte [edx],0
je finchainefichier
cmp word [edx],002Fh ;/&0 
je finchainefichier
cmp word [edx],005Ch ;\&0
je finchainefichier


debutslash:
inc edx
debutpaslach:
mov edi,ad_nomfichier1
bouclerecopienomfichier:
mov al,[edx]
cmp al,"/"
je finrecopienomfichier
cmp al,"\"
je finrecopienomfichier
cmp al,0
je finrecopienomfichier
inc edx
fs
mov [edi],al
inc edi
cmp edi,ad_nomfichier1+01FFh
jne bouclerecopienomfichier

finrecopienomfichier:
fs
mov byte[edi],0   ;ad_nomfichier1 contient une chaine utf8z 
	       ;edx pointe sur le reste de la chaine a decoder

;remet a 0 les pointeurs de parcours dossier
xor eax,eax
fs
mov [po_ztexpdossier],eax
fs
mov [po_descripteur_expdossier],eax

;reserve une zt pour la lecture du dossier
mov ecx,4096
fs
mov [to_ztexpdossier],ecx
call resmem
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§erreur d'allocation de mémoire
add ebx,10h
fs
mov [ad_ztexpdossier],ebx




charge_partie_dossier:              ;charge une partie du dossier


fs
mov al,[at_fichier]
and al,00111100b
cmp al,00001000b
je bouclerecherche_fichier  ;si le fichier est enregistré en ram pas besoin de mettre a jour 

fs
mov eax,[po_descripteur_expdossier]
fs
add [po_ztexpdossier],eax
xor eax,eax
fs
mov [po_descripteur_expdossier],eax

fs
mov eax,[po_ztexpdossier]
fs
cmp eax,[to_fichier]
jb ok_charge_partie_dossier
jmp err_fichier_nt


ok_charge_partie_dossier: 
push edx
push es
mov ax, selramh
mov es,ax
fs
mov edi,[ad_ztexpdossier]
fs
mov ecx,[to_ztexpdossier]
fs
mov edx,[po_ztexpdossier]
call sflirefichier
pop es
pop edx
cmp eax,0
jne errouvfichier

bouclerecherche_fichier:
;charge le nom et info du fichier dont le descripteur est pointé par "po_descripteur_expdossier" dans ad_nomfichier2
fs
mov al,[at_fichier]
and al,00111100b
cmp al,00000100b
je exnomiso9660
cmp al,00001000b
je exnommem
cmp al,00010000b
je exnomfat
cmp al,00010100b
je exnomfat
cmp al,00011000b
je exnomfat
mov eax,cer_sysf  ;erreur du système de fichier
jmp errouvfichier


;*********************************************************************************************
exnomiso9660:           ;extrait les données d'un dossier de type iso9660 
xor eax,eax
fs
mov ebx,[ad_ztexpdossier]
fs
add ebx,[po_descripteur_expdossier]
gs
mov al,[ebx]                              ;eax=taille du descripteur
cmp eax,0
je err_fichier_nt   ;si la taille du descripteur est nulle on est arrivé a la fin du dossier
fs
mov [to_descripteur_expdossier],eax
fs
add eax,[po_descripteur_expdossier]
fs
cmp eax,[to_ztexpdossier]
ja charge_partie_dossier    ;si le descripteur n'est pas dans la zone tampon on réactualise celle ci

gs                     ;extrait le nom
mov cl,[ebx+32]        ;taille de la chaine du nom
mov esi,ebx
add esi,33
mov edi,ad_nomfichier2

boucleextraitnomiso9660:
gs
mov al,[esi]
cmp al,";"
je finextraitnomiso9660
fs
mov [edi],al
inc esi
inc edi
dec cl
jnz boucleextraitnomiso9660

finextraitnomiso9660:
fs
mov byte[edi],0

gs                  ;extrait l'adresse
mov eax,[ebx+2]
fs
mov [ad_fichier_expdossier],eax

gs                  ;extrait la taille
mov eax,[ebx+10]
fs
mov [to_fichier_expdossier],eax

gs         ;extrait le type
test byte[ebx+25],02h
jnz dossieriso9660
fs
mov byte[at_fichier_expdossier],001b
jmp comparaisondesdeuxnom

dossieriso9660:
fs
mov byte[at_fichier_expdossier],010b
jmp comparaisondesdeuxnom


;*********************************************************************************************
exnommem:
fs
mov ebx,[po_descripteur_expdossier]

boucle_exnommem:
gs
cmp byte[ebx+2],"F"
je err_fichier_nt
gs
cmp byte[ebx+2],"X"
je suite_exnomem
gs
mov eax,[ebx+4] ;si c'est pas un descripteur de zone mémoire fichier on essaye la zone suivante
add ebx,eax
fs
mov [po_descripteur_expdossier],ebx
jmp boucle_exnommem

suite_exnomem:
fs
mov [ad_fichier_expdossier],ebx

gs
mov eax,[ebx+4]
fs
mov [to_descripteur_expdossier],eax

gs
mov eax,[ebx+8]
fs
mov [to_fichier_expdossier],eax

push ds
push es
mov cx,selramh
mov ds,cx
fs
mov esi,[po_descripteur_expdossier]
add esi,10h
mov cx,seldat
mov es,cx
mov edi,ad_nomfichier2
mov ecx,400
cld
rep movsb
pop es
pop ds



fs
mov byte[at_fichier_expdossier],01b
jmp comparaisondesdeuxnom



;*********************************************************************************************
exnomfat:               ;extrait les données d'un dossier de type FAT simple
fs
mov ebx,[ad_ztexpdossier]
fs
add ebx,[po_descripteur_expdossier]
gs
cmp byte[ebx],0
je err_fichier_nt
gs
cmp byte[ebx],0E5h
je fat_non_valide
gs
cmp byte[ebx],05h
je fat_bizzard
gs
cmp byte[ebx],"."
je fat_non_valide
gs
cmp byte[ebx+0Bh],0Fh
jne fat_origine

fat_vfat:
gs
mov al,[ebx]
test al,40h    ;on test si c'est bien le marqueur de début de descripteur de nom long
je fat_non_valide
and eax,3Fh

shl eax,5
mov esi,ebx
add esi,eax

;calcul du checksum  
mov cx,11  ;ch=sum cl=i
push eax
push esi
boucle_chesum_vfat:
mov al,ch
shl ch,7
shr al,1
add ch,al
gs
add ch,[esi]
inc esi
dec cl
jnz boucle_chesum_vfat
pop esi
pop eax

mov edi,ad_nomfichier2
add eax,32
fs
mov [to_descripteur_expdossier],eax
fs
add eax,[po_descripteur_expdossier]
fs
cmp eax,[to_ztexpdossier]
ja charge_partie_dossier    ;si le descripteur n'est pas dans la zone tampon on réactualise celle ci


boucle_fat_vfat:
sub esi,32
gs 
cmp [esi+0Dh],ch   ;verification du cheksum
jne fat_non_valide
xor eax,eax
gs
mov ax,[esi+01h]
call utf8_vfat
gs
mov ax,[esi+03h]
call utf8_vfat
gs
mov ax,[esi+05h]
call utf8_vfat
gs
mov ax,[esi+07h]
call utf8_vfat
gs
mov ax,[esi+09h]
call utf8_vfat
gs
mov ax,[esi+0Eh]
call utf8_vfat
gs
mov ax,[esi+10h]
call utf8_vfat
gs
mov ax,[esi+12h]
call utf8_vfat
gs
mov ax,[esi+14h]
call utf8_vfat
gs
mov ax,[esi+16h]
call utf8_vfat
gs
mov ax,[esi+18h]
call utf8_vfat
gs
mov ax,[esi+1Ch]
call utf8_vfat
gs
mov ax,[esi+1Eh]
call utf8_vfat
cmp esi,ebx
jne boucle_fat_vfat
fs
mov byte[edi],0

fs
add esi,[to_descripteur_expdossier]
sub esi,32
jmp extrait_fat


utf8_vfat:
cmp eax,80h   ;-de 7 bit
jb utf8_vfat1
cmp eax,800h  ;-de 11 bits
jb utf8_vfat2
push eax
push eax
and al,3Fh
or al,80h
fs
mov [edi+2],al
pop eax
shr eax,6
and al,3Fh
or al,80h
fs
mov [edi+1],al
pop eax
shr eax,12
and al,0Fh
or al,0E0h
fs
mov [edi],al
add edi,3  
ret

utf8_vfat1:
fs
mov [edi],al
inc edi
ret

utf8_vfat2:
push eax
and al,3Fh
or al,80h
fs
mov [edi+1],al
pop eax
shr eax,6
and al,01Fh
or al,0C0h
fs
mov [edi],al
add edi,2    
ret



fat_non_valide:
fs
mov dword[to_descripteur_expdossier],20h 
jmp fichierpastrouve                         ;on ignore le descripteur

fat_bizzard:
gs
mov byte[ebx],0E5h    ;entrée fat originel commençant par le caractère 0E5h remplacé par le caractère 05h

fat_origine:
mov esi,ebx
mov edi,ad_nomfichier2
boucle_fat_nom8:
gs
mov al,[esi]
cmp al," "
je finboucle_fat_nom8
fs
mov [edi],al
inc esi
inc edi
cmp edi,ad_nomfichier2+8
jb boucle_fat_nom8

finboucle_fat_nom8:
gs
mov eax,[ebx+8]
and eax,0FFFFFFh
cmp eax,202020h
je fin_fat_origine
fs
mov byte[edi],"."
inc edi
fs
mov [edi],eax
inc edi
fs
cmp byte[edi]," "
je fin_fat_origine
inc edi
fs
cmp byte[edi]," "
je fin_fat_origine
inc edi
fin_fat_origine:
fs
mov byte[edi],0

fs
mov dword[to_descripteur_expdossier],20h 
mov esi,ebx

extrait_fat:

xor eax,eax
gs                  ;extrait l'adresse
mov ax,[esi+1Ah]
fs
mov [ad_fichier_expdossier],eax

fs
mov al,[at_fichier]
and al,00111100b
cmp al,00011000b
jne pasdatafat32
gs                  ;extrait les MSB du cluster si on est en fat32
mov ax,[esi+14h]
fs
mov [ad_fichier_expdossier+2],ax
pasdatafat32:

gs                  ;extrait la taille
mov eax,[esi+1Ch]
fs
mov [to_fichier_expdossier],eax

gs         ;extrait le type
test byte[esi+0Bh],010h
jnz dossierfatorigine
fs
mov byte[at_fichier_expdossier],001b
jmp comparaisondesdeuxnom

dossierfatorigine:
fs
mov byte[at_fichier_expdossier],010b
fs
mov dword[to_fichier_expdossier],0FFFFFFFFh ;la taille des dossier n'est pas enregistré!




;******************************************************************************************************
comparaisondesdeuxnom: ;compare ad_nomfichier1 et ad_nomfichier2
mov esi,ad_nomfichier1
mov edi,ad_nomfichier2
bouclecomparaison:
fs
mov al,[esi]
fs
cmp al,[edi]
jne fichierpastrouve
cmp al,0
je fichiertrouve
inc edi
inc esi
jmp bouclecomparaison


fichierpastrouve:     ;si pas trouvé on passe au descripteur suivant
fs
mov ebx,[to_descripteur_expdossier]
fs
add [po_descripteur_expdossier],ebx
fs
mov eax,[to_ztexpdossier]
fs
cmp [po_descripteur_expdossier],eax 
ja charge_partie_dossier            ;si le descripteur est hors de la zt on recharge la zt
jmp bouclerecherche_fichier


fichiertrouve:  ;si trouvé, désalloue la zt de lecture dossier
fs
mov ebx,[ad_ztexpdossier]
sub ebx,10h
call libmem
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

;met a jour les données du descripteur fichier avec celuis trouvé dans le dossier
fs
mov al,[at_fichier]   ;récupère les données du dossier
fs
and byte[at_fichier],03Ch ;ne garde que les données de type de système de fichier
and al,03h
cmp al,03h
jne pasdossierracine
fs
or byte[at_fichier],40h
pasdossierracine:
fs
mov al,[at_fichier_expdossier]
fs
or [at_fichier],al

fs                       ;transfert les données de dossier précédent
mov eax,[ad_fichier]     
fs
mov [ad_dossierfichier],eax  ;adresse
fs
mov eax,[to_fichier]
fs
mov [to_dossierfichier],eax  ;et taille du dossier

fs
mov eax,[po_ztexpdossier]
fs
add eax,[po_descripteur_expdossier]
fs
mov [ad_dansdossier],eax     ;position du descripteur dans le dossier

fs                            ;enregistre les données du fichier
mov eax,[ad_fichier_expdossier]
fs
mov [ad_fichier],eax  ;nouvelle adresse du fichier
fs
mov eax,[to_fichier_expdossier]
fs
mov [to_fichier],eax  ;et nouvelle taille 

cmp byte[edx],0        ;si c'est la fin de la chaine on termine
je finchainefichier
cmp word [edx],002Fh ;/&0 
je finchainefichier
cmp word [edx],005Ch ;\&0
je finchainefichier


fs
mov al,[at_fichier]
and al,03h
cmp al,010b   
je debutslash         ;si dossier trouvé et chaine pas terminé -> on recommence


;si pas dossier & si on est en mode création & si taille fichier nulle
fs
cmp byte[option_ouverture],2
jne errprmsf            ;sinon fichier trouvé et chaine pas terminé -> erreur de paramètre
fs
cmp dword[to_fichier],0
jne errprmsf 

call change_en_dossier
cmp eax,0
jne finfonctionfichiererr
fs
mov byte[option_ouverture],1 ;on reprend la création de dossier

mov eax,[edx]        ; si le fichier suivant est un . alors on arrete la
and eax,0FFFFFFh
cmp eax,002E2Fh
je finchainefichier
cmp eax,002E5Ch
jne debutslash 



finchainefichier:
;verifie que le fichier n'as pas déja été ouvert
fs
mov ebx,[ad_ficho]
fs
mov ebp,[max_ficho]
add ebp,ebx

fs
mov al,[at_fichier]
and al,011b
cmp al,10b
je ok_verif_dejaouvert   ;si c'est un dossier on ignore
cmp al,11b
je ok_verif_dejaouvert   ;si c'est un dossier racine on ignore cette vérif

boucle_verif_dejaouvert:
fs
mov eax,[at_fichier+4]
gs
cmp eax,[ebx+4]
jne nok_verif_dejaouvert
fs
mov eax,[at_fichier+8]
gs
cmp eax,[ebx+8]
jne nok_verif_dejaouvert
fs
mov ax,[at_fichier]      ;pas dans l'ordre parce que les param précédent avait plus de chance d'être différent
gs
cmp ax,[ebx]
jne nok_verif_dejaouvert  ;mais pas l'id de celuis qui a ouvert la tache parce que ça peut être différent     
fs
mov eax,[at_fichier+12]
gs
cmp eax,[ebx+12]
jne nok_verif_dejaouvert
fs
mov eax,[at_fichier+16]
gs
cmp eax,[ebx+16]
jne nok_verif_dejaouvert
fs
mov eax,[at_fichier+20]
gs
cmp eax,[ebx+20]
jne nok_verif_dejaouvert
;fs
;mov eax,[at_fichier+24]   ;on n'as pas encore besoin de cette partie du descripteur
;gs
;cmp eax,[ebx+24]
;jne nok_verif_dejaouvert
;fs
;mov eax,[at_fichier+28]
;gs
;cmp eax,[ebx+28]
;jne nok_verif_dejaouvert

fs
mov ax,[id_tache_exec]
gs
cmp ax,[ebx+2]
je descr_fichier_ok          ;si le fichier est identique et a été ouvert par le même programme on lui renvoie son numéro

mov eax,cer_fdo
jmp finfonctionfichiererr

nok_verif_dejaouvert:
add ebx,20h
cmp ebx,ebp
jb boucle_verif_dejaouvert
ok_verif_dejaouvert:


;trouve un emplacement vide dans les descripteur de fichier 
fs
mov ebx,[ad_ficho]
add ebx,40h       ;les deux premiers descripteur son reservé au dossier courant et au dossier système
fs
mov ebp,[max_ficho]
add ebp,ebx
bouclerechempv:
gs
cmp byte[ebx],0
je descfichvidet
add ebx,20h
cmp ebx,ebp
jb bouclerechempv
;on n'as pas trouvé de place libre :/
mov eax,cer_pasm
jmp finfonctionfichiererr


descfichvidet:
fs                ;charge l'ID de la tache en cours d'execution
mov ax,[id_tache_exec]
fs
mov [id_ouvf],ax

fs
mov esi,[at_fichier]
fs
mov edi,[at_fichier+4]
gs
mov [ebx],esi
gs
mov [ebx+4],edi

fs
mov esi,[at_fichier+8]
fs
mov edi,[at_fichier+12]
gs
mov [ebx+8],esi
gs
mov [ebx+12],edi

fs
mov esi,[at_fichier+16]
fs
mov edi,[at_fichier+20]
gs
mov [ebx+16],esi
gs
mov [ebx+20],edi

fs
mov esi,[at_fichier+24]     
fs
mov edi,[at_fichier+28]
gs
mov [ebx+24],esi
gs
mov [ebx+28],edi

descr_fichier_ok:
fs
sub ebx,[ad_ficho]
shr ebx,5
xor eax,eax

fs
mov al,[at_fichier]
and al,03h
cmp al,01b
je cestunfichierouvert
mov eax,cer_dov
jmp finfonctionfichierokebx   ;fin de la fonction en préservant eax et ebx

cestunfichierouvert:
xor eax,eax
jmp finfonctionfichierokebx   ;fin de la fonction en préservant eax et ebx


err_fichier_nt:

fs
cmp byte[option_ouverture],1  ;si on est pas en mode création de fichier, on as pas trouvé le fichier
je cree_fichier
mov eax,cer_lecnt

errouvfichier:   ;erreur, désalocation mémoire, préservation de eax et raz de ebx
fs
mov ebx,[ad_ztexpdossier]
sub ebx,10h
call libmem
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
xor ebx,ebx
jmp finfonctionfichierokebx   ;fin de la fonction en préservant eax et ebx


cree_fichier:       ;sinon on créer le fichier 
call sf_cree_fichier
cmp eax,0
jne errouvfichier

;remet a 0 les pointeurs de parcours dossier et recommence a essayer de trouver le fichier 
xor eax,eax
fs
mov [po_ztexpdossier],eax
fs
mov [po_descripteur_expdossier],eax
fs
mov byte[option_ouverture],2      ;et n'essaye plus de créer de fichier
jmp charge_partie_dossier




;****************************************************************************
initdescrfdcourant:  ;initialise le descriteur de fichier courant ainsi que 
;le descripteur de disque courant a partir du numéros de fichier en ebx
pushad
and ebx,0FFFFh
shl ebx,5   ;multiplie par 32
fs
cmp ebx,[max_ficho]
ja erinitdescrfdcourant              ;test si le descripteur ne déborde pas de la table
fs
add ebx,[ad_ficho]

gs
mov esi,[ebx]
gs
mov edi,[ebx+4]
fs
mov [at_fichier],esi
fs
mov [at_fichier+4],edi

gs
mov esi,[ebx+8]
gs
mov edi,[ebx+12]
fs
mov [at_fichier+8],esi
fs
mov [at_fichier+12],edi

gs
mov esi,[ebx+16]
gs
mov edi,[ebx+20]
fs
mov [at_fichier+16],esi
fs
mov [at_fichier+20],edi

gs
mov esi,[ebx+24]
gs
mov edi,[ebx+28]
fs
mov [at_fichier+24],esi
fs
mov [at_fichier+28],edi

fs
mov al,[at_fichier]  
and al,00111100b
cmp al,00000100b
je idfdc_vide       ;si c'est un descripteur vide il n'y as pas besoin de recopier le descripteur de partition
cmp al,00000100b
je idfdc_vide       ;idem si c'est un cd
cmp al,00001000b
je idfdc_vide       ;idem si c'est un  fichier mémoire

call chardescp

idfdc_vide:
clc
popad
ret


erinitdescrfdcourant:
stc
popad
ret

sauvdescp:                 ;sauvegarde du descripteur de partition
pushad
xor ebx,ebx
fs
mov bl,[no_part]
shl ebx,6   ;mul par 64
add ebx,ad_descp           ;ebx=adresse descripteur de la partition

fs
mov esi,[at_partition]
fs
mov edi,[at_partition+4]
fs
mov [ebx],esi
fs
mov [ebx+4],edi

fs
mov esi,[at_partition+8]
fs
mov edi,[at_partition+12]
fs
mov [ebx+8],esi
fs
mov [ebx+12],edi

fs
mov esi,[at_partition+16]
fs
mov edi,[at_partition+20]
fs
mov [ebx+16],esi
fs
mov [ebx+20],edi

fs
mov esi,[at_partition+24]
fs
mov edi,[at_partition+28]
fs
mov [ebx+24],esi
fs
mov [ebx+28],edi

fs
mov esi,[at_partition+32]
fs
mov edi,[at_partition+36]
fs
mov [ebx+32],esi
fs
mov [ebx+36],edi

fs
mov esi,[at_partition+40]
fs
mov edi,[at_partition+44]
fs
mov [ebx+40],esi
fs
mov [ebx+44],edi

fs
mov esi,[at_partition+48]
fs
mov edi,[at_partition+52]
fs
mov [ebx+48],esi
fs
mov [ebx+52],edi

fs
mov esi,[at_partition+56]
fs
mov edi,[at_partition+60]
fs
mov [ebx+56],esi
fs
mov [ebx+60],edi

jmp verif_zt_cluster




chardescp:      ;charge le descriteur de partition
pushad
xor ebx,ebx  
fs
mov bl,[no_part]
cmp bl,64
ja erscdescp
shl ebx,6   ;mul par 64
add ebx,ad_descp           ;ebx=descripteur de la partition

fs
mov esi,[ebx]
fs
mov edi,[ebx+4]
fs
mov [at_partition],esi
fs
mov [at_partition+4],edi

fs
mov esi,[ebx+8]
fs
mov edi,[ebx+12]
fs
mov [at_partition+8],esi
fs
mov [at_partition+12],edi

fs
mov esi,[ebx+16]
fs
mov edi,[ebx+20]
fs
mov [at_partition+16],esi
fs
mov [at_partition+20],edi

fs
mov esi,[ebx+24]
fs
mov edi,[ebx+28]
fs
mov [at_partition+24],esi
fs
mov [at_partition+28],edi

fs
mov esi,[ebx+32]
fs
mov edi,[ebx+36]
fs
mov [at_partition+32],esi
fs
mov [at_partition+36],edi

fs
mov esi,[ebx+40]
fs
mov edi,[ebx+44]
fs
mov [at_partition+40],esi
fs
mov [at_partition+44],edi

fs
mov esi,[ebx+48]
fs
mov edi,[ebx+52]
fs
mov [at_partition+48],esi
fs
mov [at_partition+52],edi

fs
mov esi,[ebx+56]
fs
mov edi,[ebx+60]
fs
mov [at_partition+56],esi
fs
mov [at_partition+60],edi


verif_zt_cluster:                ;verifie que la zone tampon de lecture de cluster est de taille suffisante
fs
mov ebx,[ad_zt_lecluster]
sub ebx,10h-4
gs
mov eax,[ebx]
fs
cmp eax,[to_1cluster]
jae finok_chardescp 

;sinon modifie la taille de la zone
fs
mov ebx,[ad_zt_lecluster]
sub ebx,10h
fs
mov ecx,[to_1cluster]
call modtm
jc erscdescp 
add ebx,10h
fs
mov [ad_zt_lecluster],ebx

finok_chardescp:  
clc
popad
ret

erscdescp:
stc
popad
ret

;*******************************************************************************
;                                                   ****************************
fermerfichier:

and ebx,0FFFFh
shl ebx,5   ;multiplie par 32
fs
cmp ebx,[max_ficho]
ja errprmsf              ;test si le descripteur ne déborde pas de la table
fs
add ebx,[ad_ficho]

;verifie que le programme qui veut le fermer est bien celui qui l'as ouvert
fs
mov ax,[id_tache_fichier]
gs
cmp ax,[ebx+2]
jne errinterdit
gs
mov dword[ebx],0
gs
mov dword[ebx+4],0
gs
mov dword[ebx+8],0
gs
mov dword[ebx+12],0
gs
mov dword[ebx+16],0
gs
mov dword[ebx+20],0
gs
mov dword[ebx+24],0
gs
mov dword[ebx+28],0

jmp finfonctionfichier

;*******************************************************************************
;                                                   ****************************
creerfichier:
fs
mov byte[option_ouverture],1
jmp ouvrir_creer_fichier


sf_cree_fichier:  ;créer un fichier suivant le nom contenue dans ad_nomfichier1
pushad
;vérifie que le nom ne soit pas vide
fs
cmp byte[ad_nomfichier1],0
je erreur_nom_sf_cree_fichier
;verifie que les caractère non autorisé soit absent
mov ebx,ad_nomfichier1
boucle_verif_sf_cree_fichier: 
fs
mov ax,[ebx]
cmp al,0
je fin_verif_sf_cree_fichier
cmp al,022h   ;"
je erreur_nom_sf_cree_fichier
cmp al,02Fh   ;/
je erreur_nom_sf_cree_fichier
cmp al,05Ch   ;\
je erreur_nom_sf_cree_fichier
cmp al,02Ah   ;*
je erreur_nom_sf_cree_fichier
cmp al,03Fh   ;?
je erreur_nom_sf_cree_fichier
cmp al,03Ch   ;<
je erreur_nom_sf_cree_fichier
cmp al,03Eh   ;>
je erreur_nom_sf_cree_fichier
cmp al,07Ch   ;|
je erreur_nom_sf_cree_fichier
cmp al,03Ah   ;:
je erreur_nom_sf_cree_fichier

test al,0E0h   ;inferieur a 20h
jz erreur_nom_sf_cree_fichier
cmp al,07Fh   ;DEL
je erreur_nom_sf_cree_fichier
cmp al,0C2h
jne ok_caraczz
and ah,0E0h
cmp ah,80h
je erreur_nom_sf_cree_fichier
ok_caraczz:
inc ebx
cmp ebx,ad_nomfichier1+512
jne boucle_verif_sf_cree_fichier

fin_verif_sf_cree_fichier:


fs
mov al,[at_fichier]
and al,00111100b
cmp al,00001000b
je cree_fichier_mem       ;on test si c'est un fichier mémoire
cmp al,010000b 
je cree_fichier_fat       ;on fat12,
cmp al,010100b
je cree_fichier_fat       ;ou fat16
cmp al,011000b
je cree_fichier_fat       ;ou fat32
popad
mov eax,cer_cfi   ;création de fichier impossible
ret


erreur_nom_sf_cree_fichier:
popad
mov eax,cer_cin ;carac interdit dans le nom de fichier
ret

;********************
cree_fichier_mem:
mov ecx,432
call resmem
jc err_cree_fichier_mem
gs
mov byte[ebx+2],"X"
gs
mov dword[ebx+8],0

mov esi,ad_nomfichier1
mov edi,ebx
add edi,10h
mov ecx,edi
add ecx,400

boucle_cree_fichier_mem:
fs
mov al,[esi]
gs
mov [edi],al
inc edi
cmp edi,ecx
je fin_cree_fichier_mem
cmp al,0
je boucle_cree_fichier_mem
inc esi
jmp boucle_cree_fichier_mem 

fin_cree_fichier_mem:
popad 
xor eax,eax
ret

err_cree_fichier_mem:
popad 
mov eax,cer_pasm
ret


;****************************************************************************
cree_fichier_fat:

;crer descripteur vide
fs
mov dword[ad_nomfichier2+0],020202020h
fs
mov dword[ad_nomfichier2+4],020202020h
fs
mov dword[ad_nomfichier2+8],000202020h
fs
mov dword[ad_nomfichier2+12],0
fs
mov dword[ad_nomfichier2+20],0
fs
mov dword[ad_nomfichier2+24],0
fs
mov dword[ad_nomfichier2+28],0
fs
mov dword[ad_nomfichier2+32],0

call lire_date_heure  
call conv_date_fat ;ax=heure dx=date
fs
mov [ad_nomfichier2+14],ax
fs
mov [ad_nomfichier2+16],dx
fs
mov [ad_nomfichier2+18],dx
fs
mov [ad_nomfichier2+22],ax
fs
mov [ad_nomfichier2+24],dx

mov ecx,1   ;ecx=nombre de bloc de 32octet utilisé par le descripteur

;ecrit le nom dans le descripteur
mov ebx,ad_nomfichier1
mov edx,ad_nomfichier2

cree_fichier_fat_court_bouclenom:
fs
mov al,[ebx]
cmp al,"."
je cree_fichier_fat_court_point

cmp al,0
je cree_fichier_fat_suite
cmp al,"/"
je cree_fichier_fat_suite
cmp al,"\"
je cree_fichier_fat_suite

;test carac autorisé     A-Z et 0-9 ou les lettres spéciales ! #$%&'() - @ ^_'  { } ~
cmp al,21h   ;!
je cree_fichier_fat_court_oknom
cmp al,23h  ;#
jb cree_fichier_fat_long
cmp al,29h  ;)
jbe cree_fichier_fat_court_oknom
cmp al,2Dh   ;-
je cree_fichier_fat_court_oknom
cmp al,30h  ;0
jb cree_fichier_fat_long
cmp al,39h  ;9
jbe cree_fichier_fat_court_oknom
cmp al,40h  ;@
jb cree_fichier_fat_long
cmp al,5Ah  ;Z
jbe cree_fichier_fat_court_oknom
cmp al,5Eh  ;^
jb cree_fichier_fat_long
cmp al,60h  ;' (accent grave)
jbe cree_fichier_fat_court_oknom
cmp al,7Bh   ;{
je cree_fichier_fat_court_oknom
cmp al,7Dh   ;}
je cree_fichier_fat_court_oknom
cmp al,7Eh   ;~
jne cree_fichier_fat_long

cree_fichier_fat_court_oknom:
fs
mov [edx],al
inc edx
inc ebx
cmp edx,ad_nomfichier2+8
jne cree_fichier_fat_court_bouclenom

fs
cmp byte[ebx],"."
jne cree_fichier_fat_long

cree_fichier_fat_court_point:
inc ebx
mov edx,ad_nomfichier2+8

cree_fichier_fat_court_bouclepoint:
fs
mov al,[ebx]
cmp al,"."
je cree_fichier_fat_long

cmp al,0
je cree_fichier_fat_suite
cmp al,"/"
je cree_fichier_fat_suite
cmp al,"\"
je cree_fichier_fat_suite

;test carac autorisé     A-Z et 0-9 ou les lettres spéciales ! #$%&'() - @ ^_'  { } ~
cmp al,21h   ;!
je cree_fichier_fat_court_okpoint
cmp al,23h  ;#
jb cree_fichier_fat_long
cmp al,29h  ;)
jbe cree_fichier_fat_court_okpoint
cmp al,2Dh   ;-
je cree_fichier_fat_court_okpoint
cmp al,30h  ;0
jb cree_fichier_fat_long
cmp al,39h  ;9
jbe cree_fichier_fat_court_okpoint
cmp al,40h  ;@
jb cree_fichier_fat_long
cmp al,5Ah  ;Z
jbe cree_fichier_fat_court_okpoint
cmp al,5Eh  ;^
jb cree_fichier_fat_long
cmp al,60h  ;' (accent grave)
jbe cree_fichier_fat_court_okpoint
cmp al,7Bh   ;{
je cree_fichier_fat_court_okpoint
cmp al,7Dh   ;}
je cree_fichier_fat_court_okpoint
cmp al,7Eh   ;~
jne cree_fichier_fat_long

cree_fichier_fat_court_okpoint:
fs
mov [edx],al
inc edx
inc ebx
cmp edx,ad_nomfichier2+11
jne cree_fichier_fat_court_bouclepoint
fs
cmp byte[ebx],0
jne cree_fichier_fat_long

;********************************
;recherche si un nom court identique existe déja
push es
push ecx 
mov ax,selramh
mov es,ax
mov esi,ad_nomfichier2

cree_fichier_fat_court_verif_recherche:
xor edx,edx  
cree_fichier_fat_court_verif_recharge:       ;lire partie dossier
fs
mov edi,[ad_ztexpdossier]
fs
mov ecx,[to_ztexpdossier]
call sflirefichier
cmp eax,0
jne cree_fichier_fat_long_verif_erreur_lecture 
fs
mov edi,[ad_ztexpdossier]
fs
mov ecx,[to_ztexpdossier]
add ecx,edi


cree_fichier_fat_court_verif_boucle:
es
cmp byte[edi],0
je cree_fichier_fat_long_verif_fin
fs
mov eax,[esi]
es
cmp [edi],eax
jne cree_fichier_fat_court_verif_suite
fs
mov eax,[esi+4]
es
cmp [edi+4],eax
jne cree_fichier_fat_court_verif_suite
fs
mov eax,[esi+8]
es
mov byte[edi+11],0
and eax,0FFFFFFh
es
cmp [edi+8],eax
je cree_fichier_fat_court_erreur

cree_fichier_fat_court_verif_suite:
add edi,20h
cmp edi,ecx
jne cree_fichier_fat_court_verif_boucle
fs
add edx,[to_ztexpdossier]
jmp cree_fichier_fat_court_verif_recharge


cree_fichier_fat_court_erreur:
pop ecx
pop es
popad
mov eax,cer_cfi   ;création de fichier impossible
ret



;****************************************
cree_fichier_fat_long:

;transformation du nom de fichier au format UCS-2
mov edx,ad_nomfichier1               ;edx pointe sur le nom a convertir
mov ebx,zt_conversion_ucs ;ebx pointe sur le nom convertit
push ds
mov ax,seldat
mov ds,ax


cree_fichier_fat_long_boucle_ucs:
call lireutf8

cmp eax,0
je cree_fichier_fat_long_ucs_fin
cmp eax,02Fh   ;/
je cree_fichier_fat_long_ucs_fin
cmp eax,05Ch   ;\
je cree_fichier_fat_long_ucs_fin
mov [ebx],ax
add ebx,2
cmp eax,0FFFFh
jb cree_fichier_fat_long_boucle_ucs

pop ds
jmp erreur_nom_sf_cree_fichier  ;si le caractère dépasse les capacité de UCS-2,impossible de créer le nom



cree_fichier_fat_long_ucs_fin:
pop ds
fs
mov dword[ebx],0FFFF0000h

;rajouter des codes FFFF pour completer le nom
fs
mov dword[ebx+4],0FFFFFFFFh
fs
mov dword[ebx+8],0FFFFFFFFh
fs
mov dword[ebx+12],0FFFFFFFFh
fs
mov dword[ebx+16],0FFFFFFFFh
fs
mov dword[ebx+20],0FFFFFFFFh
fs
mov dword[ebx+24],0FFFFFFFFh
fs
mov dword[ebx+28],0FFFFFFFFh

;calcul le nombre de bloc qui devront être employé dans le descripteur de nom long
xor edx,edx
mov eax,ebx
sub eax,zt_conversion_ucs
mov ecx,26
div ecx
cmp edx,0
je cree_fichier_fat_long_calcul_nombre_bloc
inc eax
cree_fichier_fat_long_calcul_nombre_bloc:
mov ecx,eax              ;ecx=nombre de bloc uttilisé
inc ecx


;*************************************
;création de l'entête descripteur de nom long

mov edi,ad_nomfichier2
mov esi,zt_conversion_ucs
dec eax
shl eax,5
add edi,eax
mov eax,1
push edi

boucle_creation_descripteur_nom_long_fat:
fs
mov [edi],al
fs
mov edx,[esi]
fs
mov [edi+01h],edx

fs
mov edx,[esi+4]
fs
mov [edi+05h],edx

fs
mov edx,[esi+8]
fs
mov [edi+09h],dx

fs
mov byte[edi+0Bh],0Fh ;marque que le descripteur est celui d'un nom long
fs
mov word[edi+0Ch],0

fs
mov edx,[esi+10]
fs
mov [edi+0Eh],edx

fs
mov edx,[esi+14]
fs
mov [edi+12h],edx

fs
mov edx,[esi+18]
fs
mov [edi+16h],edx

fs
mov word[edi+1Ah],0  

fs
mov edx,[esi+22]
fs
mov [edi+1Ch],edx

add esi,26
sub edi,32
inc al
cmp al,cl
jne boucle_creation_descripteur_nom_long_fat

pop edi
add edi,32
fs
or byte[ad_nomfichier2],40h


;*************************************************
;création de l'entête de compatibilité nom court

;créer descripteur vide
fs
mov dword[edi+0],020202020h
fs
mov dword[edi+4],020202020h
fs
mov dword[edi+8],000202020h
fs
mov dword[edi+12],0
fs
mov dword[edi+20],0
fs
mov dword[edi+24],0
fs
mov dword[edi+28],0
fs
mov dword[edi+32],0

push ecx
call lire_date_heure  
call conv_date_fat ;ax=heure dx=date
fs
mov [edi+14],ax
fs
mov [edi+16],dx
fs
mov [edi+18],dx
fs
mov [edi+22],ax
fs
mov [edi+24],dx
pop ecx

;remplissage avec un pseudo nom constitué uniquement de majuscules et chiffres
mov edx,edi
mov esi,ad_nomfichier1
add edx,8

cree_fichier_fat_long_boucle_pseudo_nom:
fs
mov al,[esi]
cmp al,0
je cree_fichier_fat_long_fin_pseudo
cmp al,"/"
je cree_fichier_fat_long_fin_pseudo
cmp al,"\"
je cree_fichier_fat_long_fin_pseudo
cmp al,"."
je cree_fichier_fat_long_pseudo_point

cmp al,"0"
jb cree_fichier_fat_long_boucle_pseudo_nom_ignore
cmp al,"9"  
jbe cree_fichier_fat_long_boucle_pseudo_nom_ok
cmp al,"A"
jb cree_fichier_fat_long_boucle_pseudo_nom_ignore
cmp al,"Z" 
jbe cree_fichier_fat_long_boucle_pseudo_nom_ok
cmp al,"a"
jb cree_fichier_fat_long_boucle_pseudo_nom_ignore
cmp al,"z" 
ja cree_fichier_fat_long_boucle_pseudo_nom_ignore

sub al,20h
cree_fichier_fat_long_boucle_pseudo_nom_ok:
fs
mov [edi],al
inc edi
cmp edi,edx
je cree_fichier_fat_long_pseudo_point
cree_fichier_fat_long_boucle_pseudo_nom_ignore:
inc esi
jmp cree_fichier_fat_long_boucle_pseudo_nom

cree_fichier_fat_long_pseudo_point:
mov edi,edx
add edx,3
mov esi,ad_nomfichier1 

;recherche la fin du fichier
cree_fichier_fat_long_pseudo_cherche_fin:
fs
cmp byte[esi],0
je cree_fichier_fat_long_pseudo_trouve_fin
fs
cmp byte[esi],"\"
je cree_fichier_fat_long_pseudo_trouve_fin
fs
cmp byte[esi],"/"
je cree_fichier_fat_long_pseudo_trouve_fin
inc esi
cmp esi,ad_nomfichier1+512 
je cree_fichier_fat_long_fin_pseudo
jmp cree_fichier_fat_long_pseudo_cherche_fin

cree_fichier_fat_long_pseudo_trouve_fin:
dec esi

;remonte debut de l'extension
cree_fichier_fat_long_pseudo_cherche_point:
fs
cmp byte[esi],"."
je cree_fichier_fat_long_pseudo_trouve_point
dec esi
cmp esi,ad_nomfichier1 
je cree_fichier_fat_long_fin_pseudo
jmp cree_fichier_fat_long_pseudo_cherche_point

cree_fichier_fat_long_pseudo_trouve_point:
inc esi

cree_fichier_fat_long_boucle_pseudo_point:
fs
mov al,[esi]
cmp al,0
je cree_fichier_fat_long_fin_pseudo
cmp al,"/"
je cree_fichier_fat_long_fin_pseudo
cmp al,"\"
je cree_fichier_fat_long_fin_pseudo

cmp al,"0"
jb cree_fichier_fat_long_boucle_pseudo_point_ignore
cmp al,"9" 
jbe cree_fichier_fat_long_boucle_pseudo_point_ok
cmp al,"A"
jb cree_fichier_fat_long_boucle_pseudo_point_ignore
cmp al,"Z" 
jbe cree_fichier_fat_long_boucle_pseudo_point_ok
cmp al,"a"
jb cree_fichier_fat_long_boucle_pseudo_point_ignore
cmp al,"z" 
ja cree_fichier_fat_long_boucle_pseudo_point_ignore

sub al,20h
cree_fichier_fat_long_boucle_pseudo_point_ok:
fs
mov [edi],al
inc edi
cmp edi,edx
je cree_fichier_fat_long_fin_pseudo
cree_fichier_fat_long_boucle_pseudo_point_ignore:
inc esi
jmp cree_fichier_fat_long_boucle_pseudo_point

cree_fichier_fat_long_fin_pseudo:


;************************************
;recherche si un nom court identique existe déja
push es
push ecx 
mov ax,selramh
mov es,ax
mov esi,ad_nomfichier2
fs
mov al,[ad_nomfichier2]
and eax,3Fh
shl eax,5
add esi,eax  ;esi=adreese du descripteur8:3



cree_fichier_fat_long_verif_recherche:
xor edx,edx  
cree_fichier_fat_long_verif_recharge:       ;lire partie dossier
fs
mov edi,[ad_ztexpdossier]
fs
mov ecx,[to_ztexpdossier]
call sflirefichier
cmp eax,0
jne cree_fichier_fat_long_verif_erreur_lecture 
fs
mov edi,[ad_ztexpdossier]
fs
mov ecx,[to_ztexpdossier]
add ecx,edi


cree_fichier_fat_long_verif_boucle:
es
cmp byte[edi],0
je cree_fichier_fat_long_verif_fin
fs
mov eax,[esi]
es
cmp [edi],eax
jne cree_fichier_fat_long_verif_suite
fs
mov eax,[esi+4]
es
cmp [edi+4],eax
jne cree_fichier_fat_long_verif_suite
fs
mov eax,[esi+8]
es
mov byte[edi+11],0
and eax,0FFFFFFh
es
cmp [edi+8],eax
je cree_fichier_fat_long_renomme

cree_fichier_fat_long_verif_suite:
add edi,20h
cmp edi,ecx
jne cree_fichier_fat_long_verif_boucle
fs
add edx,[to_ztexpdossier]
jmp cree_fichier_fat_long_verif_recharge


;*************************************
;adaptation du nom court (au besoin)
cree_fichier_fat_long_renomme:
mov edi,esi
add edi,7

cree_fichier_fat_long_renomme_boucle:
fs
cmp byte[edi],"0"
jb cree_fichier_fat_long_renomme_nonchiffre
fs
cmp byte[edi],"9"
ja cree_fichier_fat_long_renomme_nonchiffre

fs
inc byte[edi]
fs
cmp byte[edi],"9"+1
jne cree_fichier_fat_long_verif_recherche
fs
mov byte[edi],"0"
dec edi
jmp cree_fichier_fat_long_renomme_boucle


cree_fichier_fat_long_renomme_nonchiffre:
fs
mov byte[edi],"1"
dec edi
fs
mov byte[edi],23h    ;symbole croisillon(#)
jmp cree_fichier_fat_long_verif_recherche


cree_fichier_fat_long_verif_erreur_lecture:
pop ecx
jmp cree_fichier_fat_erreur


cree_fichier_fat_long_verif_fin:
pop ecx
pop es



;***************************************
;calcul et maj du checksum
cree_fichier_fat_long_cheksum:     ;calcul et met a jour la valeur du checksum du descripteur créer
fs
mov esi,[ad_nomfichier2]
and esi,3Fh
shl esi,5
add esi,ad_nomfichier2
mov ebx,esi

;calcul du checksum  
mov dx,11  ;dh=sum dl=i
cree_fichier_fat_long_cheksum_boucle1:
mov al,dh
shl dh,7
shr al,1
add dh,al
fs
add dh,[esi]
inc esi
dec dl
jnz cree_fichier_fat_long_cheksum_boucle1

cree_fichier_fat_long_cheksum_boucle2:
sub ebx,32
fs 
mov [ebx+0Dh],dh 
cmp ebx,ad_nomfichier2
jne cree_fichier_fat_long_cheksum_boucle2



;****************************************
cree_fichier_fat_suite:          ;cherche emplacement vide et ecrit le descripteur dedans
;ecx=nombre de bloc descripteur a ecrire
xor edx,edx ;edx=base de la partie de dossier chargé
xor eax,eax ;eax taille de l'emplacement trouvé
push es

cree_fichier_fat_suite_lecture:   ;lire partie dossier
push ecx
mov ax,selramh
mov es,ax
fs
mov edi,[ad_ztexpdossier]
fs
mov ecx,[to_ztexpdossier]
call sflirefichier
pop ecx
cmp eax,0
jne cree_fichier_fat_erreur

;chercher descripeur vide
fs
mov ebx,[ad_ztexpdossier]
fs
mov edi,[to_ztexpdossier]
add edi,ebx

cree_fichier_fat_suite_boucle:
es
cmp byte[ebx],00h
je cree_fichier_fat_suite_findossier
es
cmp byte[ebx],0E5h
je cree_fichier_fat_suite_vide

xor eax,eax
add ebx,20h
cmp ebx,edi
jne cree_fichier_fat_suite_boucle
fs
add edx,[to_ztexpdossier]
jmp cree_fichier_fat_suite_lecture

cree_fichier_fat_suite_vide:
inc eax
cmp eax,ecx
je cree_fichier_fat_suite_emplacement
add ebx,20h
cmp ebx,edi
jne cree_fichier_fat_suite_boucle
fs
add edx,[to_ztexpdossier]
jmp cree_fichier_fat_suite_lecture

cree_fichier_fat_suite_emplacement:  ;emplacement de taille suffisante trouvé
fs
sub ebx,[ad_ztexpdossier]
add ebx,32
shl ecx,5  ;x32
add edx,ebx
sub edx,ecx
jmp cree_fichier_fat_suite_ecriture

cree_fichier_fat_suite_findossier:  ;fin de dossier trouvé
fs
sub ebx,[ad_ztexpdossier]
shl ecx,5  ;x32
add edx,ebx
inc ecx

cree_fichier_fat_suite_ecriture:   ;ecriture descripteur
mov ax,seldat
mov es,ax
mov esi,ad_nomfichier2
call sfecrirefichier
cmp eax,0
jne cree_fichier_fat_erreur

pop es
popad
xor eax,eax
ret

cree_fichier_fat_erreur:
pop es
ss
mov [esp+28],eax   ;préserve eax
popad
ret



;******************************************************
change_en_dossier:
pushad
push es

fs
mov al,[at_fichier]
and al,00111100b
cmp al,010000b 
je change_en_dossier_fat       ;on fat12,
cmp al,010100b
je change_en_dossier_fat       ;ou fat16
cmp al,011000b
je change_en_dossier_fat       ;ou fat32
pop es
popad
mov eax,cer_cfi   ;création de fichier impossible
ret


;**********************************************************
change_en_dossier_fat:
;marque le descripteur comme étant un dossier
call minfo_charge_descripteur
cmp eax,0
jne fin_change_en_dossier_fat

xor ebx,ebx
fs
cmp byte[zt_lminfo+0Bh],0Fh
jne change_en_dossier_fat_nvfat
fs
mov bl,[zt_lminfo]
and ebx,3Fh
shl ebx,5
change_en_dossier_fat_nvfat:

fs                            ;verifie que le descripteur est le bon
mov ax,[ebx+zt_lminfo+14h]
shl eax,16
fs
mov ax,[ebx+zt_lminfo+1Ah]
fs                       
mov ch,[at_fichier]
and ch,0111100b
cmp ch,011000b   ;FAT32?
je change_en_dossier_fat_pas32
and eax,0FFFFh
change_en_dossier_fat_pas32:

fs
cmp eax,[ad_fichier]  ;on compare le numéros du premier cluster enregistré en ram et celui lut sur le disque
je change_en_dossier_fat_ok
mov eax,cer_sysf
jmp fin_change_en_dossier_fat

change_en_dossier_fat_ok:
cmp eax,0
jne ignore_ajclust_change_en_dossier_fat

xor edx,edx
call ajn_cluster   ;ajoute nouveau cluster
cmp eax,0
jne fin_change_en_dossier_fat
fs
mov [ad_fichier],edx
fs
mov [ebx+zt_lminfo+1Ah],dx
fs                       
mov ch,[at_fichier]
and ch,0111100b
cmp ch,011000b   ;FAT32?
jne ignore_ajclust_change_en_dossier_fat

shr edx,16
fs
mov [ebx+zt_lminfo+14h],dx


ignore_ajclust_change_en_dossier_fat:
fs
or byte[ebx+zt_lminfo+0Bh],10h

call minfo_sauvegarde_descripteur2
cmp eax,0
jne fin_change_en_dossier_fat


;ecrire les entrées de base de tout nouveau dossier
fs
mov eax,[ad_fichier]
fs
mov ecx,[ad_fichier]
fs
mov edi,[ad_dossierfichier]
fs
mov esi,[ad_dossierfichier]
shr eax,16
shr edi,16

fs                       
mov dl,[at_fichier]
and dl,0111100b
cmp dl,011000b   ;FAT32?
je ignore_raz_change_en_dossier_fat
xor eax,eax                           ;met a zéro les msb des numéros de cluster si on est pas en FAT32
xor edi,edi

fs                       
mov dl,[at_fichier]
and dl,01000000b
cmp dl,01000000b   ;dossier racine
jne ignore_raz_change_en_dossier_fat
xor esi,esi                           ;met a zéro le numéros de cluster si c'est un dossier racine

ignore_raz_change_en_dossier_fat:



fs
mov dword[ad_nomfichier2+00h],02020202Eh ;autoreference du dossier
fs
mov dword[ad_nomfichier2+04h],020202020h
fs
mov dword[ad_nomfichier2+08h],010202020h
fs
mov dword[ad_nomfichier2+0Ch],0
fs
mov dword[ad_nomfichier2+10h],0
fs
mov word[ad_nomfichier2+14h],ax   ;msb position autoreference du dossier
fs
mov dword[ad_nomfichier2+16h],0
fs 
mov word[ad_nomfichier2+1Ah],cx    ;lsb position autoreference du dossier
fs
mov dword[ad_nomfichier2+1Ch],0
fs
mov dword[ad_nomfichier2+20h],020202E2Eh  ;dossier parent
fs
mov dword[ad_nomfichier2+24h],020202020h
fs
mov dword[ad_nomfichier2+28h],010202020h
fs
mov dword[ad_nomfichier2+2Ch],0
fs
mov dword[ad_nomfichier2+30h],0
fs
mov word[ad_nomfichier2+34h],di   ;msb position dossier parent
fs
mov dword[ad_nomfichier2+36h],0
fs 
mov word[ad_nomfichier2+3Ah],si ;lsb position dossier parent
fs
mov dword[ad_nomfichier2+3Ch],0
fs
mov dword[ad_nomfichier2+40h],0

mov ax,seldat
mov es,ax
mov ecx,44h
xor edx,edx
mov esi,ad_nomfichier2
call sfecrirefichier

fs
and byte[at_fichier],0FCh
fs
or  byte[at_fichier],002h
fs
mov dword[to_fichier],0FFFFFFFFh

fin_change_en_dossier_fat:
pop es
ss
mov [esp+28],eax   ;préserve eax
popad
ret



;*******************************************************************
conv_date_fat: ;convertit la date et l'heure au format FAT
;entrée:
;al=heure ah=minute bx=seconde (en millième)
;dl=jour dh=mois cx=année
;sortie:
;ax=heure dx=date

push eax
sub cx,1980
shl cx,9
mov al,dh
and ax,0Fh
and dx,1Fh
shl ax,5
or cx,ax
or cx,dx
pop eax
push ecx
mov dl,ah
and dx,3Fh
shl dx,5
and ax,1Fh
shl ax,11
or dx,ax
push edx
xor edx,edx
mov eax,ebx
mov ecx,2000
div ecx
and ax,1Fh
pop ebx
or ax,bx 
pop edx
ret






;*******************************************************************************
;                                                   ****************************
supprimerfichier:
call initdescrfdcourant
jc errprmsf

fs
mov al,[at_fichier]
and al,00111100b
cmp al,1000b
je supprime_fichier_mem
cmp al,010000b 
je supprime_fichier_fat       ;on teste si le fichier est fat12,
cmp al,010100b
je supprime_fichier_fat       ;ou fat16
cmp al,011000b
je supprime_fichier_fat       ;ou fat32
jmp errprmsf

;*******************
supprime_fichier_fat:  
call minfo_charge_descripteur
cmp eax,0
jne finfonctionfichiererr

pushad            ;calcul de l'offset en cas de descripteur de type vfat
xor ebx,ebx
fs
cmp byte[zt_lminfo+0Bh],0Fh
jne supprime_fichier_nvfat
fs
mov bl,[zt_lminfo]
and ebx,3Fh
shl ebx,5
supprime_fichier_nvfat:

fs                            ;verifie que le descripteur est le bon
mov ax,[ebx+zt_lminfo+14h]
shl eax,16
fs
mov ax,[ebx+zt_lminfo+1Ah]
fs                       
mov ch,[at_fichier]
and ch,0111100b
cmp ch,011000b   ;FAT32?
je pas32_supprime_fichier_fat
and eax,0FFFFh
pas32_supprime_fichier_fat:
fs
cmp eax,[ad_fichier]  ;on compare le numéros du premier cluster enregistré en ram et celui lut sur le disque
je ok_supprime_fichier_fat
popad
jmp errsysf

ok_supprime_fichier_fat:
fs
mov al,[at_fichier]
and al,011b
cmp al,01b
je ok_supprime_dossier_fat


mov ecx,10000h ;si c'est un dossier on vérifie qu'il est bien vide
push ebx
push es
mov ax,selramh
mov es,ax
call resmem
jc errmem_supprime_dossier_fat 
xor edx,edx

recharge_verif_supprime_dossier_fat:
mov ecx,10000h
mov edi,ebx
add edi,10h
pushad
call sflirefichier
popad
add edx,10000h


mov esi,ebx
mov edi,ebx
sub esi,10h
add edi,10010h


boucle_verif_supprime_dossier_fat:
add esi,20h
cmp esi,edi
je recharge_verif_supprime_dossier_fat
es
cmp byte[esi],0E5h
je boucle_verif_supprime_dossier_fat
es
cmp byte[esi],0
je fin_verif_supprime_dossier_fat 
es
cmp word[esi],202Eh
je boucle_verif_supprime_dossier_fat
es
cmp dword[esi],20202E2Eh
je boucle_verif_supprime_dossier_fat


call libmem
pop es
pop ebx
popad
mov eax,cer_dnv      ;code d'erreur: dossier non vide
jmp finfonctionfichiererr


errmem_supprime_dossier_fat:
pop es
pop ebx
popad
mov eax,cer_pasm      ;pas assez de mémoire
jmp finfonctionfichiererr




fin_verif_supprime_dossier_fat:
call libmem
pop es
pop ebx

ok_supprime_dossier_fat:
push ebx
fs   ;supprime les cluster reservé
mov ebx,[ad_fichier]
cmp ebx,0
je fin_boucle_supprime_cluster_fichier_fat

boucle_supprime_cluster_fichier_fat:
cmp ebx,0
je fin_boucle_supprime_cluster_fichier_fat
cmp ebx,1
je fin_boucle_supprime_cluster_fichier_fat
mov eax,ebx
and eax,0FFFFFFF0h
cmp eax,0FFFFFFF0h
je fin_boucle_supprime_cluster_fichier_fat
mov ecx,ebx
call lireindexfat
cmp eax,0
jne fin_boucle_supprime_cluster_fichier_fat
xchg ebx,ecx
mov eax,0
call ecrireindexfat   ;ebx = index fat a ecrire eax = valeur de l'index fat
mov ebx,ecx
cmp eax,0
je boucle_supprime_cluster_fichier_fat

fin_boucle_supprime_cluster_fichier_fat:
pop ebx

;supprime le descripteur sur le disque
fs
mov word[ebx+zt_lminfo+14h],0
fs
mov word[ebx+zt_lminfo+1Ah],0
boucle_supprime_entree_fichier_fat:
fs
mov byte[ebx+zt_lminfo],0E5h
cmp ebx,0
je fin_supprime_entree_fichier_fat
sub ebx,32
jmp boucle_supprime_entree_fichier_fat
fin_supprime_entree_fichier_fat:

popad
call minfo_sauvegarde_descripteur
cmp eax,0
jne finfonctionfichiererr
jmp fermerfichier


;********************
supprime_fichier_mem:
push ebx
fs
mov ebx,[ad_fichier]
call libmem
pop ebx
jnc fermerfichier
mov eax,cer_parami
jmp finfonctionfichiererr


;*******************************************************************************
;                                                   ****************************
lirefichier:
;es:edi=zone ou copier les données
;ebx=numéros du fichier ouvert
;edx=offset dans le fichier
;ecx=quantité a lire
call initdescrfdcourant
jc errprmsf

fs
mov al,[at_fichier]
and al,00111100b
cmp al,100b
je ignore_lire_meta_fichier       ;si c'est iso9660 on n'a pas besoin de modifier les métadonnées
cmp al,1000b
je ignore_lire_meta_fichier       ;si c'est un fichier memoire idem
fs
mov al,[at_fichier]
and al,011b
cmp al,011b
je ignore_lire_meta_fichier       ;si c'est un dossier racine on ne peut pas modifier les métadonné


call minfo_charge_descripteur
cmp eax,0
jne finfonctionfichiererr

fs
mov al,[at_fichier]
and al,00111100b
cmp al,010000b 
je lire_meta_fichier_fat       ;on teste si le fichier est fat12,
cmp al,010100b
je lire_meta_fichier_fat       ;ou fat16
cmp al,011000b
je lire_meta_fichier_fat       ;ou fat32
jmp errprmsf

lire_meta_fichier_fat:               ;calcul de l'offset en cas de descripteur de type vfat
pushad
xor ebx,ebx
fs
cmp byte[zt_lminfo+0Bh],0Fh
jne lire_meta_fichier_nvfat
fs
mov bl,[zt_lminfo]
and ebx,3Fh
shl ebx,5
lire_meta_fichier_nvfat:

fs                            ;verifie que le descripteur est le bon
mov ax,[ebx+zt_lminfo+14h]
shl eax,16
fs
mov ax,[ebx+zt_lminfo+1Ah]
push ecx
fs                       
mov ch,[at_fichier]
and ch,0111100b
cmp ch,011000b   ;FAT32?
je pas32_lire_meta_fichier_fat
and eax,0FFFFh
pas32_lire_meta_fichier_fat:
pop ecx
fs
cmp eax,[ad_fichier]  ;on compare le numéros du premier cluster enregistré en ram et celui lut sur le disque
je ok_lire_meta_fichier_fat
popad
jmp ignore_lire_meta_fichier   ;on evite certaine phase
ok_lire_meta_fichier_fat:

;mettre a jour la date de dernier acces
push ebx
call lire_date_heure  
call conv_date_fat
pop ebx
fs
mov [ebx+zt_lminfo+12h],dx
popad
 
call minfo_sauvegarde_descripteur
cmp eax,0
jne finfonctionfichiererr

ignore_lire_meta_fichier:
call sflirefichier
jmp finfonctionfichiererr





;**********************************************************************************
sflirefichier:
fs                   ;verifie que l'adresse demandé ne dépasse pas du fichier
cmp edx,[to_fichier]
jae erplirefichier
mov eax,edx          ;calcule l'adresse max des données lu dans le fichier
add eax,ecx
fs                   ;tronque les données a lire si ça dépasse de la taille du fichier
cmp eax,[to_fichier]
jb pastronquelirefichier
fs
mov ecx,[to_fichier]
sub ecx,edx
pastronquelirefichier:


fs
mov al,[at_fichier]
and al,00111100b
cmp al,100b ;on test si le lecteur est un lecteur de cdrom
je lirefichiercdrom
cmp al,1000b ;on test si c'est un fichier memoire
je lirefichiermem
cmp al,010000b 
je lireracinefat       ;on teste si le fichier est fat12,
cmp al,010100b
je lireracinefat       ;ou fat16
cmp al,011000b
je lirefichierfat      ;ou bien fat32
erplirefichier: ;erreur de parametre
mov eax,cer_parami
ret

finlirefichier:  ;fin de lecture du fichier, tout vas bien
xor eax,eax

erllirefichier: ;erreur de lecture,conserve le code d'erreur
ret




lirefichiercdrom:
;determiner l'adresse du premier secteur a lire
mov ebx,edx
and edx,07FFh        ;edx est l'offset dans le premier secteur
shr ebx,11           ;ebx est le numéros du secteur
fs
add ebx,[ad_fichier]   ;ebx contient l'adresse absolue du secteur

cmp edx,0
jne sectcd_sincomplet   ;offset dans le secteur non null

cmp ecx,2048
ja sectcd_scomplet
jmp sectcd_sdebut

sectcd_sincomplet:
mov eax,ecx
add eax,edx   ;calcul si les données a lire sont contenue dans un seul secteur
cmp eax,2048
ja sectcd_sfin

;*************************lecture partielle millieu
;charge le secteur dans une zone tampon
push ecx
push edi
push es
mov di,seldat
mov es,di
mov edi,secteurcd
mov cl,1
fs
mov ch,[no_part]
call lsct                  
pop es
pop edi
pop ecx
cmp eax,0
jne erllirefichier

;transferer les seuls données utile
push esi
push ds
mov si,seldat
mov ds,si
mov esi,secteurcd
add esi,edx
cld
rep movsb
pop ds
pop esi
jmp finlirefichier

;*********************lecture partielle fin 
sectcd_sfin:
;charge le secteur dans une zone tampon
push ecx
push edi
push es
mov di,seldat
mov es,di
mov edi,secteurcd
mov cl,1
fs
mov ch,[no_part]
call lsct                  
pop es
pop edi
pop ecx
cmp eax,0
jne erllirefichier

;transferer les seuls données utile
push ecx
push esi
push ds
mov ax,seldat
mov ds,ax
mov esi,secteurcd
add esi,edx
mov ecx,2048
sub ecx,edx
mov eax,ecx
cld
rep movsb  ;ds:esi es:edi
pop ds
pop esi
pop ecx
sub ecx,eax
jmp sectcd_determination


;******************************secteur complet
sectcd_scomplet:

;charge le secteur directement a l'endroit souhaité
push ecx
mov cl,1
fs
mov ch,[no_part]
call lsct
pop ecx
cmp eax,0
jne erllirefichier
sub ecx,2048
add edi,2048



;******************************determination des secteurs suivant a lire
sectcd_determination:
cmp ecx,0
je finlirefichier

inc ebx  ;secteur suivant

cmp ecx,2048
ja sectcd_scomplet

;************************lecture partielle debut
sectcd_sdebut:

;charge le secteur dans une zone tampon
push ecx
push edi
push es
mov di,seldat
mov es,di
mov edi,secteurcd
mov cl,1
fs
mov ch,[no_part]
call lsct                  
pop es
pop edi
pop ecx
cmp eax,0
jne erllirefichier


;transferer les seuls données utile
push esi
push ds
mov ax,seldat
mov ds,ax
mov esi,secteurcd
cld
rep movsb
pop ds
pop esi
jmp finlirefichier


;***********************************************************************
lirefichiermem:
push ds
mov ax,selramh
mov ds,ax
fs
mov esi,[ad_fichier]
add esi,416
add esi,edx
rep movsb
pop ds
jmp finlirefichier 


;****************************************************
lireracinefat:

fs
mov al,[at_fichier]
and al,0011b
cmp al,3
jne lirefichierfat   ;si ce n'est pas le dossier racine alors ça se lit comme un fichier

;***********************************************lecture dossier racine fat
;determiner l'adresse du premier secteur a lire
mov ebx,edx
and edx,01FFh        ;edx est l'offset dans le premier secteur
shr ebx,9            ;ebx est le numéros du secteur
fs
add ebx,[ad_fichier]   ;ebx contient l'adresse absolue du secteur

cmp edx,0
jne sectds_sincomplet   ;offset dans le secteur non null

cmp ecx,512
ja sectds_scomplet
jmp sectds_sdebut

sectds_sincomplet:
mov eax,ecx
add eax,edx   ;calcul si les données a lire sont contenue dans un seul secteur
cmp eax,512
ja sectds_sfin

;*************************lecture partielle millieu
;charge le secteur dans une zone tampon
push ecx
push edi
push es
mov di,seldat
mov es,di
mov edi,secteurcd
mov cl,1
fs
mov ch,[no_disquepart]
call lsct                  
pop es
pop edi
pop ecx
cmp eax,0
jne erllirefichier

;transferer les seuls données utile
push esi
push ds
mov si,seldat
mov ds,si
mov esi,secteurcd
add esi,edx
cld
rep movsb
pop ds
pop esi
jmp finlirefichier

;*********************lecture partielle fin 
sectds_sfin:
;charge le secteur dans une zone tampon
push ecx
push edi
push es
mov di,seldat
mov es,di
mov edi,secteurcd
mov cl,1
fs
mov ch,[no_disquepart]
call lsct                  
pop es
pop edi
pop ecx
cmp eax,0
jne erllirefichier

;transferer les seuls données utile
push ecx
push esi
push ds
mov ax,seldat
mov ds,ax
mov esi,secteurcd
add esi,edx
mov ecx,512
sub ecx,edx
mov eax,ecx
cld
rep movsb  ;ds:esi es:edi
pop ds
pop esi
pop ecx
sub ecx,eax
jmp sectds_determination


;******************************secteur complet
sectds_scomplet:

;charge le secteur directement a l'endroit souhaité
push ecx
mov cl,1
fs
mov ch,[no_disquepart]
call lsct
pop ecx
cmp eax,0
jne erllirefichier
sub ecx,512
add edi,512



;******************************determination des secteurs suivant a lire
sectds_determination:
cmp ecx,0
je finlirefichier

inc ebx  ;secteur suivant

cmp ecx,512
ja sectds_scomplet

;************************lecture partielle debut
sectds_sdebut:

;charge le secteur dans une zone tampon
push ecx
push edi
push es
mov di,seldat
mov es,di
mov edi,secteurcd
mov cl,1
fs
mov ch,[no_disquepart]
call lsct                  
pop es
pop edi
pop ecx
cmp eax,0
jne erllirefichier


;transferer les seuls données utile
push esi
push ds
mov ax,seldat
mov ds,ax
mov esi,secteurcd
cld
rep movsb
pop ds
pop esi
jmp finlirefichier





lirefichierfat: ;***********************************************lecture fichier FAT 12,16,et 32

;determiner l'adresse du premier cluster a lire
fs
mov ebx,[ad_fichier]   ;ebx contient le numéros de cluster

boucle_deter_1ercluster:
fs
cmp edx,[to_1cluster]
jb num_1er_cluster
call lireindexfat
cmp ebx,0FFFFFFF0h ;réservé
je errlirefichier_sysf
cmp ebx,0FFFFFFF7h ;défaillant
je errlirefichier_lec
cmp ebx,0FFFFFFF8h ;fin de fichier
je finlirefichier
fs
sub edx,[to_1cluster]
jmp boucle_deter_1ercluster

num_1er_cluster:
cmp edx,0
jne cluster_sincomplet   ;offset dans le secteur non null

fs
cmp ecx,[to_1cluster]
ja cluster_scomplet
jmp cluster_sdebut

cluster_sincomplet:
mov eax,ecx
add eax,edx   ;calcul si les données a lire sont contenue dans un seul cluster
fs
cmp eax,[to_1cluster]
ja cluster_sfin

;*************************lecture partielle millieu
;charge le secteur dans une zone tampon
push ecx
push edi
push es
mov di,selramh
mov es,di
fs
mov edi,[ad_zt_lecluster]
call lire_cluster_fat                 
pop es
pop edi
pop ecx
cmp eax,0
jne erllirefichier

;transferer les seuls données utile
push esi
push ds
mov si,selramh
mov ds,si
fs
mov esi,[ad_zt_lecluster]
add esi,edx
cld
rep movsb
pop ds
pop esi
jmp finlirefichier

;*********************lecture partielle fin 
cluster_sfin:
;charge le secteur dans une zone tampon
push ecx
push edi
push es
mov di,selramh
mov es,di
fs
mov edi,[ad_zt_lecluster]
call lire_cluster_fat                 
pop es
pop edi
pop ecx
cmp eax,0
jne erllirefichier

;transferer les seuls données utile
push ecx
push esi
push ds
mov ax,selramh
mov ds,ax
fs
mov esi,[ad_zt_lecluster]
add esi,edx
fs
mov ecx,[to_1cluster]
sub ecx,edx
mov eax,ecx
cld
rep movsb  ;ds:esi es:edi
pop ds
pop esi
pop ecx
sub ecx,eax
jmp cluster_determination


;******************************secteur complet
cluster_scomplet:

;charge le secteur directement a l'endroit souhaité
call lire_cluster_fat
cmp eax,0
jne erllirefichier
fs
sub ecx,[to_1cluster]
fs
add edi,[to_1cluster]



;******************************determination des secteurs suivant a lire
cluster_determination:
cmp ecx,0
je finlirefichier

call lireindexfat  ;secteur suivant
cmp ebx,0FFFFFFF0h ;réservé
je errlirefichier_sysf
cmp ebx,0FFFFFFF7h ;défaillant
je errlirefichier_lec
cmp ebx,0FFFFFFF8h ;fin de fichier
je finlirefichier

fs
cmp ecx,[to_1cluster]
ja cluster_scomplet

;************************lecture partielle debut
cluster_sdebut:
;charge le secteur dans une zone tampon
push ecx
push edi
push es
mov di,selramh
mov es,di
fs
mov edi,[ad_zt_lecluster]
call lire_cluster_fat                 
pop es
pop edi
pop ecx
cmp eax,0
jne erllirefichier


;transferer les seuls données utile
push esi
push ds
mov ax,selramh
mov ds,ax
fs
mov esi,[ad_zt_lecluster]
cld
rep movsb
pop ds
pop esi
jmp finlirefichier

errlirefichier_lec:
mov eax,cer_lec
jmp erllirefichier

errlirefichier_sysf:
mov eax,cer_sysf
jmp erllirefichier



;******************************************************************************************
lire_cluster_fat:        ;lire un cluster
push ebx
push ecx
xor ah,ah
fs
mov al,[nb_sec_cluster]
bsf cx,ax                 ;extrait le numéros du premier bit a 1 dans l'octet
shl ebx,cl
fs
add ebx,[ad_cluster0]
fs
mov cl,[nb_sec_cluster]
fs
mov ch,[no_disquepart]
call lsct
pop ecx
pop ebx
ret


;******************************************************************************************
ecrire_cluster_fat:        ;ecrire un cluster
push ebx
push ecx
xor ah,ah
fs
mov al,[nb_sec_cluster]
bsf cx,ax                 ;extrait le numéros du premier bit a 1 dans l'octet
shl ebx,cl
fs
add ebx,[ad_cluster0]
fs
mov cl,[nb_sec_cluster]
fs
mov ch,[no_disquepart]
call esct
pop ecx
pop ebx
ret


;*******************************************************************************************
;travail sur la table FAT


lireindexfat:
;ebx = index fat a lire
;renvoie l'index fat lue dans ebx
;eax=code d'erreur

push ecx
push edx
push esi
push edi
push ebp
push es

mov ax,selramh
mov es,ax

fs
mov al,[at_fichier]
and al,00111100b
cmp al,00010000b
je fat12
cmp al,00010100b
je fat16
cmp al,00011000b
je fat32
jmp erparamfat

fat12:
shr ebx,1
jc fatimpaire

mov ax,bx   ;fat paire
mov cx,3
mul cx
xor ebx,ebx
mov bx,ax
call liredwordfat
cmp eax,0
jne finlireifat
jmp kirk

fatimpaire:
mov ax,bx
mov cx,3
mul cx
xor ebx,ebx
mov bx,ax
call liredwordfat
cmp eax,0
jne finlireifat
shr ebx,12

kirk:
and ebx,0FFFh
mov eax,ebx
and eax,0FF0h
cmp eax,0FF0h
je revcluster
xor eax,eax
jmp finlireifat

fat16:
cmp ebx,0FFF0h
ja erparamfat
shl ebx,1
call liredwordfat
cmp eax,0
jne finlireifat
and ebx,0FFFFh

mov eax,ebx
and eax,0FFF0h
cmp eax,0FFF0h
je revcluster
xor eax,eax
jmp finlireifat


fat32:
cmp ebx,0FFFFFF0h
ja erparamfat
shl ebx,2
call liredwordfat
cmp eax,0
jne finlireifat

mov eax,ebx
and eax,0FFFFFF0h
cmp eax,0FFFFFF0h
je revcluster
xor eax,eax
jmp finlireifat

revcluster:
and ebx,0Fh
testcluster:
cmp bl,7
je badcluster
test bl,08h
jnz fincluster

mov ebx,0FFFFFFF0h    ;réservé
xor eax,eax
jmp finlireifat

badcluster:
mov ebx,0FFFFFFF7h     ;cluster defaillant
xor eax,eax
jmp finlireifat

fincluster:               ;cluster de fin de fichier
mov ebx,0FFFFFFF8h
xor eax,eax
jmp finlireifat

erparamfat:
mov eax,cer_parami
xor ebx,ebx

finlireifat:
pop es
pop ebp
pop edi
pop esi
pop edx
pop ecx
ret



liredwordfat:
;ebx=adresse dword a lire
;ebx=octet en sortie
;eax=code d'erreur

fs
mov eax,[to_fat]
shl eax,9    ;mul par 512
cmp ebx,eax
jae errliredwordfat

fs
mov al,[no_part]
fs
cmp al,[dsq_fat1]
je utfat1
fs
cmp al,[dsq_fat2]
je utfat2
;le disque n'est pas en mémoire
fs
bt word[at_fat],0   ;quel est la dernière zone mise a jour
jc chargefat2
jmp chargefat1


utfat1:
;test si le dword voulue est en mémoire
fs
mov eax,[index_fat1]
cmp ebx,eax
jb chargefat1       ;si l'adresse est inferieur a l'index on met a jour la zt
fs
add eax,[max_fat1]
cmp ebx,eax          ;si l'adresse est bien en mémoire on la lit 
jb lirezt1

chargefat1:
fs
bt word[at_fat],1 ;test si la zt_fat1 as été modifié
jnc chargefat1_ok
call sauvegarde_zt_fat_1   ;si oui on sauvegarde
cmp eax,0
jne err1liredwordfat
chargefat1_ok:

fs
btc word[at_fat],0   ;la zone 1 est la dernière mise a jour
fs
mov ch,[no_part]
fs
mov [dsq_fat1],ch

;determine le nouvel index
push ebx
and ebx,0FFFFFE00h   
fs
mov [index_fat1],ebx

;determine le secteur asscocié a cet index
shr ebx,9
fs
add ebx,[ad_fat]

;determine le nombre de secteur a charger et charge la zt fat
fs
mov edx,[max_fat1]
shr edx,9
mov cl,dl
fs 
mov edi,[ad_fat1]
fs
mov ch,[no_disquepart]
call lsct
pop ebx       
cmp eax,0
jne err1liredwordfat  

lirezt1:
fs
sub ebx,[index_fat1]
fs
add ebx,[ad_fat1]
es
mov eax,[ebx]
mov ebx,eax
xor eax,eax
ret

err1liredwordfat:
fs
mov byte[dsq_fat1],0FFh
xor ebx,ebx
ret

errliredwordfat:
mov eax,cer_parami
xor ebx,ebx
ret


utfat2:
;test si le dword voulue est en mémoire
fs
mov eax,[index_fat2]
cmp ebx,eax
jb chargefat2       ;si l'adresse est inferieur a l'index on met a jour la zt
fs
add eax,[max_fat2]
cmp ebx,eax          ;si l'adresse est bien en mémoire on la lit 
jb lirezt2

chargefat2:
fs
bt word[at_fat],2 ;test si la zt_fat1 as été modifié
jnc chargefat2_ok
call sauvegarde_zt_fat_2   ;si oui on sauvegarde
cmp eax,0
jne err1liredwordfat
chargefat2_ok:


fs
btc word[at_fat],0   ;la zone 1 est la dernière mise a jour
fs
mov ch,[no_part]
fs
mov [dsq_fat2],ch

;determine le nouvel index
push ebx
and ebx,0FFFFFE00h   
fs
mov [index_fat2],ebx

;determine le secteur asscocié a cet index
shr ebx,9
fs
add ebx,[ad_fat]

;determine le nombre de secteur a charger et charge la zt fat
fs
mov edx,[max_fat2]
shr edx,9
mov cl,dl
fs 
mov edi,[ad_fat2]
fs
mov ch,[no_disquepart]
call lsct
pop ebx       
cmp eax,0
jne err1liredwordfat  

lirezt2:
fs
sub ebx,[index_fat2]
fs
add ebx,[ad_fat2]
es
mov eax,[ebx]
mov ebx,eax
xor eax,eax
ret

err2liredwordfat:
fs
mov byte[dsq_fat2],0FFh
xor ebx,ebx
ret




;*****************************************************
ecrireindexfat:
;ebx = index fat a ecrire
;eax = valeur de l'index fat

push ecx
push edx
push esi
push edi
push ebp
push es

mov dx,selramh
mov es,dx

fs
mov dl,[at_fichier]
and dl,00111100b
cmp dl,00010000b
je ecr_fat12
cmp dl,00010100b
je ecr_fat16
cmp dl,00011000b
je ecr_fat32
jne erparamfat



;***********************
ecr_fat12:
mov edx,eax
and edx,0FFFFFFF0h
cmp edx,0FFFFFFF0h
je okecr_fat12
and edx,0FFFFF000h
cmp edx,0
jne erparamfat

okecr_fat12:
and eax,0FFFh
shr ebx,1
jc ecr_fat12_impaire

push eax
mov ax,bx   ;fat paire
mov cx,3
mul cx
xor ebx,ebx
mov bx,ax
pop eax

push eax
push ebx
call liredwordfat
mov ecx,eax
mov edx,ebx
pop ebx
pop eax
cmp ecx,0
jne erparamfat

and edx,0FFFFF000h
or eax,edx
call ecrdwordfat
jmp finlireifat

ecr_fat12_impaire:
push eax
mov ax,bx
mov cx,3
mul cx
xor ebx,ebx
mov bx,ax
pop eax

push eax
push ebx
call liredwordfat
mov ecx,eax
mov edx,ebx
pop ebx
pop eax
cmp ecx,0
jne erparamfat

shl eax,12
and edx,0FF000FFFh
or eax,edx
call ecrdwordfat
jmp finlireifat


;***********************
ecr_fat16:
mov edx,eax
and edx,0FFFFFFF0h
cmp edx,0FFFFFFF0h
je okecr_fat16
test eax,0FFFF0000h
jnz erparamfat

okecr_fat16:
and eax,0FFFFh
shl ebx,1

;lire le dword précédent
push eax
push ebx
call liredwordfat
mov ecx,eax
mov edx,ebx
pop ebx
pop eax
cmp ecx,0
jne erparamfat

and edx,0FFFF0000h
or eax,edx
call ecrdwordfat
jmp finlireifat

;***********************
ecr_fat32: 
mov edx,eax
and edx,0F0000000h
cmp edx,0F0000000h
je okecr_fat32
test eax,0F0000000h
jnz erparamfat

okecr_fat32:
and eax,0FFFFFFFh
shl ebx,2
call ecrdwordfat
jmp finlireifat


;**********************
ecrdwordfat:
;ebx =adresse dans la fat
;eax=valeur a ecrire
;sortie eax=0


;lit la valeur pour mettre a jour les ZT
mov edx,eax
push ebx
call liredwordfat
pop ebx
cmp eax,0
jne errecrdwordfat

;determine laquel des zones tampon est utilisé
fs
mov al,[no_part]
fs
cmp al,[dsq_fat1]
je mdfat1
fs
cmp al,[dsq_fat2]
je mdfat2
jmp err_ztfat

mdfat1:      ;modifie la valeur dans la zt1
push ebx
fs
sub ebx,[index_fat1]
fs
add ebx,[ad_fat1]
es
mov [ebx],edx

fs
sub ebx,[ad_fat1] 
and ebx,0FFFFFE00h   
fs
add ebx,[ad_fat1]
mov esi,ebx 
jmp ecr_secfat

mdfat2:      ;modifie la valeur dans la zt2
push ebx
fs
sub ebx,[index_fat2]
fs
add ebx,[ad_fat2]
es
mov [ebx],edx

fs
sub ebx,[ad_fat2] 
and ebx,0FFFFFE00h   
fs
add ebx,[ad_fat2] 
mov esi,ebx


ecr_secfat:
;determine le numéros du secteur de fat a modifier
pop ebx
shr ebx,9
fs
add ebx,[ad_fat]


;charge le secteur modifié dans les fat de la partition

fs
mov dl,[nb_fat]
modifie1fat:
push dx	    
mov cl,1
fs	    
mov ch,[no_disquepart]	 
fs
mov dl,[at_fichier]
and dl,00111100b
cmp dl,00010000b
jne ecr_fat_ok
inc cl    ;si le disque est en FAT12 on ecrit sur deux secteur car le contenue a modifier du dword peut être a cheval entres deux secteur
ecr_fat_ok:     
call esct
pop dx
cmp eax,0
jne errecrdwordfat
fs
add ebx,[to_fat]
dec dl
jnz modifie1fat
ret

err_ztfat:
mov eax,cer_ers

errecrdwordfat:
xor ebx,ebx
ret

;*****************************************************
ecrireindexfat_sp:
;ebx = index fat a ecrire
;eax = valeur de l'index fat

push ecx
push edx
push esi
push edi
push ebp
push es

mov dx,selramh
mov es,dx

fs
mov dl,[at_fichier]
and dl,00111100b
cmp dl,00010000b
je ecr_fat12_sp
cmp dl,00010100b
je ecr_fat16_sp
cmp dl,00011000b
je ecr_fat32_sp
jne erparamfat



;***********************
ecr_fat12_sp:
mov edx,eax
and edx,0FFFFFFF0h
cmp edx,0FFFFFFF0h
je okecr_fat12_sp
and edx,0FFFFF000h
cmp edx,0
jne erparamfat

okecr_fat12_sp:
and eax,0FFFh
shr ebx,1
jc ecr_fat12_impaire_sp

push eax
mov ax,bx   ;fat paire
mov cx,3
mul cx
xor ebx,ebx
mov bx,ax
pop eax

push eax
push ebx
call liredwordfat
mov ecx,eax
mov edx,ebx
pop ebx
pop eax
cmp ecx,0
jne erparamfat

and edx,0FFFFF000h
or eax,edx
call ecrdwordfat_sp
jmp finlireifat

ecr_fat12_impaire_sp:
push eax
mov ax,bx
mov cx,3
mul cx
xor ebx,ebx
mov bx,ax
pop eax

push eax
push ebx
call liredwordfat
mov ecx,eax
mov edx,ebx
pop ebx
pop eax
cmp ecx,0
jne erparamfat

shl eax,12
and edx,0FF000FFFh
or eax,edx
call ecrdwordfat_sp
jmp finlireifat


;***********************
ecr_fat16_sp:
mov edx,eax
and edx,0FFFFFFF0h
cmp edx,0FFFFFFF0h
je okecr_fat16_sp
test eax,0FFFF0000h
jnz erparamfat

okecr_fat16_sp:
and eax,0FFFFh
shl ebx,1

;lire le dword précédent
push eax
push ebx
call liredwordfat
mov ecx,eax
mov edx,ebx
pop ebx
pop eax
cmp ecx,0
jne erparamfat

and edx,0FFFF0000h
or eax,edx
call ecrdwordfat_sp
jmp finlireifat

;***********************
ecr_fat32_sp: 
mov edx,eax
and edx,0F0000000h
cmp edx,0F0000000h
je okecr_fat32_sp
test eax,0F0000000h
jnz erparamfat

okecr_fat32_sp:
and eax,0FFFFFFFh
shl ebx,2
call ecrdwordfat_sp
jmp finlireifat


;**********************
ecrdwordfat_sp:
;ebx =adresse dans la fat
;eax=valeur a ecrire
;sortie eax=0

;lit la valeur pour mettre a jour les ZT
mov edx,eax
push ebx
call liredwordfat
pop ebx
cmp eax,0
jne errecrdwordfat

;determine laquel des zones tampon est utilisé
fs
mov al,[no_part]
fs
cmp al,[dsq_fat1]
je mdfat1_sp
fs
cmp al,[dsq_fat2]
je mdfat2_sp
jmp err_ztfat

mdfat1_sp:      ;modifie la valeur dans la zt1
push ebx
fs
sub ebx,[index_fat1]
fs
add ebx,[ad_fat1]
es
mov [ebx],edx
fs
bts word[at_fat],1   ;signale que la zone as été modifié
pop ebx
xor eax,eax
ret

mdfat2_sp:      ;modifie la valeur dans la zt2
push ebx
fs
sub ebx,[index_fat2]
fs
add ebx,[ad_fat2]
es
mov [ebx],edx
fs
bts word[at_fat],2   ;signale que la zone as été modifié
pop ebx
xor eax,eax
ret

;***************************************************
sauvegarde_zt_fat:
fs
bt word[at_fat],1 ;test si la zt_fat1 as été modifié
jnc sauvegarde_zt_fat_suite

;si oui on sauvegarde
call sauvegarde_zt_fat_1
cmp eax,0
je sauvegarde_zt_fat_fin

sauvegarde_zt_fat_suite:
fs
bt word[at_fat],2 ;test si la zt_fat2 as été modifié
jnc sauvegarde_zt_fat_fin

;si oui on sauvegarde
call sauvegarde_zt_fat_2
sauvegarde_zt_fat_fin:
ret



;***********************
sauvegarde_zt_fat_1:

push ebx
push ecx
push edx
push esi
push es
mov cx,selramh
mov es,cx
xor ecx,ecx
fs
mov cl,[dsq_fat1]
shl ecx,6 ;x64
add ecx,ad_descp
mov esi,ecx 
fs
mov ebx,[index_fat1]
shr ebx,9

fs
mov ecx,[max_fat1]
shr ecx,9 ;ecx=nb de secteur pour la zt

mov eax,ecx
add eax,ebx
fs
cmp eax,[esi+to_fat-at_partition]
jbe suite_sauvegarde_zt_fat_1
fs
mov ecx,[esi+to_fat-at_partition]
sub ecx,ebx
suite_sauvegarde_zt_fat_1:
fs
add ebx,[esi+ad_fat-at_partition]
fs
mov edi,[esi+to_fat-at_partition]
fs
mov ch,[esi+no_disquepart-at_partition]
fs
mov dl,[esi+nb_fat-at_partition]
fs 
mov esi,[ad_fat1]

boucle_sauvegarde_zt_fat_1:
call esct
add ebx,edi
Cmp eax,0
jne sauvegarde_zt_fat_1_erreur
dec dl
jnz boucle_sauvegarde_zt_fat_1

fs
btc word[at_fat],1
sauvegarde_zt_fat_1_erreur:
pop es
pop esi
pop edx
pop ecx
pop edx
pop ebx
ret


;***********************
sauvegarde_zt_fat_2:
push ebx
push ecx
push edx
push esi
push es
mov cx,selramh
mov es,cx
xor ecx,ecx
fs
mov cl,[dsq_fat2]
shl ecx,6 ;x64
add ecx,ad_descp
mov esi,ecx 

fs
mov ebx,[index_fat2]
shr ebx,9

fs
mov ecx,[max_fat2]
shr ecx,9 ;ecx=nb de secteur pour la zt

mov eax,ecx
add eax,ebx
fs
cmp eax,[esi+to_fat-at_partition]
jbe suite_sauvegarde_zt_fat_2
fs
mov ecx,[esi+to_fat-at_partition]
sub ecx,ebx
suite_sauvegarde_zt_fat_2:
fs
add ebx,[esi+ad_fat-at_partition]
fs
mov edi,[esi+to_fat-at_partition]
fs
mov ch,[esi+no_disquepart-at_partition]
fs
mov dl,[esi+nb_fat-at_partition]
fs 
mov esi,[ad_fat2]

boucle_sauvegarde_zt_fat_2:
call esct
add ebx,edi
cmp eax,0
jne sauvegarde_zt_fat_2_erreur
dec dl
jnz boucle_sauvegarde_zt_fat_2

fs
btc word[at_fat],2
sauvegarde_zt_fat_2_erreur:
pop es
pop esi
pop edx
pop ecx
pop edx
pop ebx
ret






;*********************************************************
ajn_cluster:               ;ajoute un nouveau cluster 
;entrée: edx=dernier cluster du fichier
;sortie: edx=nouveau cluster final

push ebx                      ;on verifie d'abord si le cluster suivant est disponible 
push edi
mov edi,edx     ;edi=sauvegarde du précédent cluster
inc edx
mov ebx,edx
call lireindexfat
cmp eax,0
jne fin_ajn_cluster
cmp ebx,0
je trouve_rech_nouv_cluster 

mov edx,2                      ;sinon on recommence depuis le début
boucle1_rech_nouv_cluster:
mov ebx,edx
call lireindexfat
cmp eax,0
jne fin_ajn_cluster
cmp ebx,0
je trouve_rech_nouv_cluster 
inc edx
jmp boucle1_rech_nouv_cluster  

trouve_rech_nouv_cluster: 
mov ebx,edx
mov eax,0FFFFFFF8h
call ecrireindexfat
cmp eax,0
jne fin_ajn_cluster

cmp edi,0
je fin_ajn_cluster  ;si le précédent cluster n'existait pas on ignore cette étape
mov eax,edx
mov ebx,edi
call ecrireindexfat

fin_ajn_cluster:
pop edi
pop ebx
ret

;*******************************************************************************
;                                                   ****************************
ecrirefichier:
;es:esi=adresse des données a copier
;ebx=numéros du fichier ouvert
;edx=offset dans le fichier
;ecx=quantité a ecrire
call initdescrfdcourant
jc errprmsf
fs
cmp edx,[to_fichier]
ja errprmsf            ;on ne peut écrire au dela de la taille existante du fichier


fs
mov al,[at_fichier]
and al,00111100b
cmp  al,1000b
je  ignore_ecrire_meta_fichier
cmp al,010000b 
je ecrire_meta_fichier_fat       ;on teste si le fichier est fat12,
cmp al,010100b
je ecrire_meta_fichier_fat       ;ou fat16
cmp al,011000b
je ecrire_meta_fichier_fat       ;ou fat32
jmp errprmsf



ecrire_meta_fichier_fat:               ;calcul de l'offset en cas de descripteur de type vfat
call minfo_charge_descripteur
cmp eax,0
jne finfonctionfichiererr

pushad
xor ebx,ebx
fs
cmp byte[zt_lminfo+0Bh],0Fh
jne ecrire_meta_fichier_nvfat
fs
mov bl,[zt_lminfo]
and ebx,3Fh
shl ebx,5
ecrire_meta_fichier_nvfat:

fs                            ;verifie que le descripteur est le bon
mov ax,[ebx+zt_lminfo+14h]
shl eax,16
fs
mov ax,[ebx+zt_lminfo+1Ah]
push ecx
fs                       
mov ch,[at_fichier]
and ch,0111100b
cmp ch,011000b   ;FAT32?
je pas32_ecrire_meta_fichier_fat
and eax,0FFFFh
pas32_ecrire_meta_fichier_fat:
pop ecx
fs
cmp eax,[ad_fichier]  ;on compare le numéros du premier cluster enregistré en ram et celui lut sur le disque
je ok_ecrire_meta_fichier_fat
popad
jmp errsysf
ok_ecrire_meta_fichier_fat:

mov eax,edx
add eax,ecx
fs
cmp [to_fichier],eax
jae pasajt_ecrire_meta_fichier_fat
fs
mov [to_fichier],eax           
fs
mov [ebx+zt_lminfo+01Ch],eax   ;modifie le descripteur du disque
pasajt_ecrire_meta_fichier_fat:

;verifie que le premier cluster existe bien
fs
cmp dword[ad_fichier],0
jne okcluster0_ecrire_meta_fichier_fat
push edx
xor edx,edx
call ajn_cluster   ;sinon on le créer
cmp eax,0
jne err_ecrire_meta_fichier_fat 

fs
mov [ad_fichier],edx
fs
mov [ebx+zt_lminfo+01Ah],dx
shr edx,16
fs
mov [ebx+zt_lminfo+014h],dx
pop edx
okcluster0_ecrire_meta_fichier_fat:


;mettre a jour la date de dernère modif
push ebx
call lire_date_heure  
call conv_date_fat
pop ebx
fs
mov [ebx+zt_lminfo+16h],ax
fs
mov [ebx+zt_lminfo+18h],dx
popad

fin_ecrire_meta_fichier:
call minfo_sauvegarde_descripteur
cmp eax,0
jne finfonctionfichiererr

ignore_ecrire_meta_fichier:
call sfecrirefichier
jmp finfonctionfichiererr


err_ecrire_meta_fichier_fat:
pop edx
popad
jmp finfonctionfichiererr

;*******************************************

sfecrirefichier:
push ds
fs
mov al,[at_fichier]
and al,00111100b
cmp  al,1000b
je  ecrirefichiermem
cmp al,010000b
je ecrireracinefat       ;on teste si le fichier est fat12,
cmp al,010100b
je ecrireracinefat       ;ou fat16
cmp al,011000b
je ecrirefichierfat       ;ou bien fat32
jmp fin_sfecrirefichier_erprm


;****************************************
ecrirefichiermem:

fs
mov edi,[ad_fichier]

mov eax,edx
add eax,ecx
gs
cmp [edi+8],eax          ;on verifie que on ne déborde pas du fichier
jae ecrirefichiermem_pasmodif_taillefichier
gs
mov [edi+8],eax           ;sinon on modifie la taille du fichier
fs
mov [to_fichier],eax
ecrirefichiermem_pasmodif_taillefichier:

fs
mov eax,[to_fichier]
add eax,431
and eax,0FFFFFFF0h
gs
cmp [edi+4],eax
jae ecrirefichiermem_pasmodif_taillebloc 
push ecx
push ebx
mov ebx,edi
mov ecx,eax
call modtm
mov edi,ebx
pop ebx
pop ecx
jc ecrirefichiermem_err
fs
mov [ad_fichier],edi
ecrirefichiermem_pasmodif_taillebloc:



;mise a jour du descripteur
pushad
and ebx,0FFFFh
shl ebx,5   ;multiplie par 32
fs
add ebx,[ad_ficho]

fs
mov esi,[at_fichier]
fs
mov edi,[at_fichier+4]
gs
mov [ebx],esi
gs
mov [ebx+4],edi

fs
mov esi,[at_fichier+8]
fs
mov edi,[at_fichier+12]
gs
mov [ebx+8],esi
gs
mov [ebx+12],edi

fs
mov esi,[at_fichier+16]
fs
mov edi,[at_fichier+20]
gs
mov [ebx+16],esi
gs
mov [ebx+20],edi

fs
mov esi,[at_fichier+24]
fs
mov edi,[at_fichier+28]
gs
mov [ebx+24],esi
gs
mov [ebx+28],edi
popad
  


push ds
push es
mov ax,es
mov ds,ax

mov ax,selramh
mov es,ax

add edi,edx
add edi,416
cld
rep movsb
pop es
pop ds
jmp fin_sfecrirefichier_ok

ecrirefichiermem_err:
mov eax,cer_pasm
jmp fin_sfecrirefichier_err


;*************************************
ecrireracinefat:
fs
mov al,[at_fichier]
and al,0011b
cmp al,3
jne ecrirefichierfat   ;si ce n'est pas le dossier racine alors ça s'écrit comme un fichier

mov ax,es
mov ds,ax
mov ax,seldat
mov es,ax




;***********************************************ecriture dossier racine fat
;determiner l'adresse du premier secteur a ecrire
mov ebx,edx
and edx,01FFh        ;edx est l'offset dans le premier secteur
shr ebx,9            ;ebx est le numéros du secteur
fs
add ebx,[ad_fichier]   ;ebx contient l'adresse absolue du secteur

cmp edx,0
jne sectds_ecr_sincomplet   ;offset dans le secteur non null

cmp ecx,512
ja sectds_ecr_scomplet
jmp sectds_ecr_sdebut

sectds_ecr_sincomplet:
mov eax,ecx
add eax,edx   ;calcul si les données a ecrire sont contenue dans un seul secteur
cmp eax,512
ja sectds_ecr_sfin

;*************************ecriture partielle millieu
;charge le secteur dans une zone tampon
push ecx
push edi
mov edi,secteurcd
mov cl,1
fs
mov ch,[no_disquepart]
call lsct                  
pop edi
pop ecx
cmp eax,0
jne fin_sfecrirefichier_erlec

;transferer les seuls données utile
mov edi,secteurcd
add edi,edx
cld
rep movsb

;écrit le secteur
push ecx
push esi
mov esi,secteurcd
mov cl,1
fs
mov ch,[no_disquepart]
call esct                  
pop esi
pop ecx
cmp eax,0
jne fin_sfecrirefichier_erecr

jmp fin_sfecrirefichier_ok

;*********************ecriture partielle fin 
sectds_ecr_sfin:
;charge le secteur dans une zone tampon
push ecx
push edi
mov edi,secteurcd
mov cl,1
fs
mov ch,[no_disquepart]
call lsct                  
pop edi
pop ecx
cmp eax,0
jne fin_sfecrirefichier_erlec

;transferer les seuls données utile
push ecx
mov edi,secteurcd
add edi,edx
mov ecx,512
sub ecx,edx
mov edx,ecx
cld
rep movsb
pop ecx
sub ecx,edx

;ecrit le secteur
push ecx
push esi
mov esi,secteurcd
mov cl,1
fs
mov ch,[no_disquepart]
call esct                  
pop esi
pop ecx
cmp eax,0
jne fin_sfecrirefichier_erecr

jmp sectds_ecr_determination


;******************************secteur complet
sectds_ecr_scomplet:
;charge le secteur directement a l'endroit souhaité
push ecx
push es
mov ax,ds
mov es,ax
mov cl,1
fs
mov ch,[no_disquepart]
call esct
pop es
pop ecx
cmp eax,0
jne fin_sfecrirefichier_erecr
sub ecx,512
add esi,512



;******************************determination des secteurs suivant a ecrire
sectds_ecr_determination:
cmp ecx,0
je fin_sfecrirefichier_ok

inc ebx  ;secteur suivant

cmp ecx,512
ja sectds_ecr_scomplet

;************************ecriture partielle debut
sectds_ecr_sdebut:




;charge le secteur dans une zone tampon
push ecx
push edi
mov edi,secteurcd
mov cl,1
fs
mov ch,[no_disquepart]
call lsct                  
pop edi
pop ecx
cmp eax,0
jne fin_sfecrirefichier_erlec


;transferer les seuls données utile
mov edi,secteurcd
cld
rep movsb



;ecrit le secteur
push ecx
push esi

mov esi,secteurcd
mov cl,1
fs
mov ch,[no_disquepart]
call esct                  

pop esi
pop ecx
cmp eax,0
jne fin_sfecrirefichier_erecr

jmp fin_sfecrirefichier_ok





ecrirefichierfat: ;***********************************************ecriture fichier FAT 12,16,et 32
mov ax,es
mov ds,ax
mov ax,selramh
mov es,ax

;determiner l'adresse du premier cluster ou ecrire
fs
mov ebx,[ad_fichier]   ;ebx contient le numéros de cluster

boucle_deter_1ercluster_ecr:
fs
cmp edx,[to_1cluster]
jb num_1er_cluster_ecr
mov ebp,ebx
call lireindexfat
cmp ebx,0FFFFFFF0h ;réservé
je fin_sfecrirefichier_ersyf
cmp ebx,0FFFFFFF7h ;défaillant
je fin_sfecrirefichier_erecr
cmp ebx,0FFFFFFF8h ;fin de fichier
je sfecrirefichier_arrivefin   

fs
sub edx,[to_1cluster]
jmp boucle_deter_1ercluster_ecr


sfecrirefichier_arrivefin:
fs
cmp edx,[to_1cluster]
jne fin_sfecrirefichier_ersyf

mov edx,ebp
call ajn_cluster
mov ebx,edx 
xor edx,edx
cmp eax,0
jne fin_sfecrirefichier_err


num_1er_cluster_ecr:
cmp edx,0
jne cluster_ecr_sincomplet   ;offset dans le secteur non null

fs
cmp ecx,[to_1cluster]
ja cluster_ecr_scomplet
jmp cluster_ecr_sdebut

cluster_ecr_sincomplet:
mov eax,ecx
add eax,edx   ;calcul si les données a ecrire sont contenue dans un seul cluster
fs
cmp eax,[to_1cluster]
ja cluster_ecr_sfin

;*************************ecriture partielle millieu
;charge le secteur dans une zone tampon

push ecx
push edi
fs
mov edi,[ad_zt_lecluster]
call lire_cluster_fat                 
pop edi
pop ecx
cmp eax,0
jne fin_sfecrirefichier_err   ;conservation du code d'erreur

;transferer les seuls données utile
fs
mov edi,[ad_zt_lecluster]
add edi,edx
cld
rep movsb

;ecrit dans le cluster
push ecx
push esi
fs
mov esi,[ad_zt_lecluster]
call ecrire_cluster_fat                 
pop esi
pop ecx
jmp fin_sfecrirefichier_err   ;conservation du code d'erreur

;*********************ecriture partielle fin 
cluster_ecr_sfin:
;charge le secteur dans une zone tampon
push ecx
push edi
fs
mov edi,[ad_zt_lecluster]
call lire_cluster_fat                 
pop edi
pop ecx
cmp eax,0
jne fin_sfecrirefichier_err   ;conservation du code d'erreur

;transferer les seules données utile
push ecx
fs
mov edi,[ad_zt_lecluster]
add edi,edx
fs
mov ecx,[to_1cluster]
sub ecx,edx
mov eax,ecx
cld
rep movsb
pop ecx
sub ecx,eax


;ecrit dans le cluster
push ecx
push esi
fs
mov esi,[ad_zt_lecluster]
call ecrire_cluster_fat                 
pop esi
pop ecx
cmp eax,0
jne fin_sfecrirefichier_err   ;conservation du code d'erreur
jmp cluster_ecr_determination


;******************************ecriture secteur complet
cluster_ecr_scomplet:
;charge le secteur directement a l'endroit souhaité
push es
mov ax,ds
mov es,ax
call ecrire_cluster_fat
pop es
cmp eax,0
jne fin_sfecrirefichier_err   ;conservation du code d'erreur
fs
sub ecx,[to_1cluster]
fs
add esi,[to_1cluster]



;******************************determination des secteurs suivant a ecrire
cluster_ecr_determination:
cmp ecx,0
je fin_sfecrirefichier_ok
mov edx,ebx
call lireindexfat  ;secteur suivant
cmp ebx,0FFFFFFF0h ;réservé
je fin_sfecrirefichier_ersyf   
cmp ebx,0FFFFFFF7h ;défaillant
je fin_sfecrirefichier_erecr   
cmp ebx,0FFFFFFF8h ;fin de fichier
jne cluster_ecr_najcluster   
call ajn_cluster 
cmp eax,0
jne fin_sfecrirefichier_err
mov ebx,edx

cluster_ecr_najcluster:
fs
cmp ecx,[to_1cluster]
ja cluster_ecr_scomplet

;************************ecriture partielle debut
cluster_ecr_sdebut:
;charge le secteur dans une zone tampon
push ecx
push edi
fs
mov edi,[ad_zt_lecluster]
call lire_cluster_fat                 
pop edi
pop ecx
cmp eax,0
jne fin_sfecrirefichier_err   ;conservation du code d'erreur

;transferer les seuls données utile
fs
mov edi,[ad_zt_lecluster]
cld
rep movsb

;ecrit dans le cluster
push ecx
push esi
fs
mov esi,[ad_zt_lecluster]
call ecrire_cluster_fat                 
pop esi
pop ecx
jmp fin_sfecrirefichier_err   ;conservation du code d'erreur


;*************************************************************
fin_sfecrirefichier_ermem:
mov eax,cer_pasm
fin_sfecrirefichier_ernum:
pop ds
ret

fin_sfecrirefichier_erprm:
mov eax,cer_parami   ;erreur de parametre
pop ds
ret


fin_sfecrirefichier_erlec:
mov eax,cer_lec 
pop ds
ret

;fin_sfecrirefichier_erecrp:
fs
mov ebx,[ad_zt_lecluster]
sub ebx,10h
call libmem

fin_sfecrirefichier_erecr:
mov eax,cer_ecr 
pop ds
ret

fin_sfecrirefichier_ersyf:
mov eax,cer_sysf
pop ds
ret

fin_sfecrirefichier_ok:
xor eax,eax
fin_sfecrirefichier_err:
pop ds
ret


;*******************************************************************************
;                                                   ****************************
infofichier:      ;lire les métadonnée du fichier
                  ;ah=numéros                        0=nom 1=taille fichier 2=attributs
		  ;ebx=numéros du fichier
		  ;ds:edx=destination des données demandé
call initdescrfdcourant
jc errprmsf

cmp ah,1
je infofichier_taille

fs
mov al,[at_fichier]
and al,00111100b
cmp al,000100b
je infofichier_iso9660   ;ou iso9660
cmp al,001000b
je infofichier_mem       ;fichier mémoire
cmp al,010000b 
je infofichier_fat       ;on teste si le fichier est fat12,
cmp al,010100b
je infofichier_fat       ;ou fat16
cmp al,011000b
je infofichier_fat       ;ou fat32
jmp errprmsf

infofichier_taille:
fs
mov eax,[to_fichier]
mov [edx],eax
jmp finfonctionfichier


infofichier_iso9660:
;?????????????????????????????????????
jmp errprmsf


infofichier_mem:
cmp ah,1
je infofichier_mem_nom
jmp errprmsf

infofichier_mem_nom:
fs
mov edi,[ad_fichier]
add edi,10h

boucle_infofichier_mem_nom:
gs
mov al,[edi]
mov [edx],al
inc edi
inc edx
cmp al,0
jne boucle_infofichier_mem_nom
jmp finfonctionfichier



infofichier_fat:
;????????????????????????????????????
jmp errprmsf




;*******************************************************************************
;                                                   ****************************
minfofichier:     ;modifie les métadonnée du fichier
                  ;ah=numéros       (voir "lire les info fichier")
		  ;ebx=numéros du fichier
		  ;ds:edx=source des données
mov cl,ah
call initdescrfdcourant
jc errprmsf


fs
mov al,[at_fichier]
and al,00111100b
cmp al,001000b
je minfofichier_mem
cmp al,010000b 
je minfofichier_fat       ;on teste si le fichier est fat12,
cmp al,010100b
je minfofichier_fat       ;ou fat16
cmp al,011000b
je minfofichier_fat       ;ou fat32
jmp errprmsf

;*********************************
minfofichier_mem:
cmp ah,0
je minfofichier_mem_nom
cmp ah,1
je minfofichier_mem_taille
jmp errprmsf

minfofichier_mem_nom:
fs
mov edi,[ad_fichier]
add edi,10h
mov esi,edi
add esi,400

boucle_minfofichier_mem_nom:
mov al,[edx]
gs
mov [edi],al
inc edi
inc edx
cmp edi,esi
je fin_minfofichier_mem_nom   ;si jamais ça dépasse de la taille maximum on tronque le nom
cmp al,0
jne boucle_minfofichier_mem_nom

fin_minfofichier_mem_nom:
dec edi
gs
mov byte[edi],0
jmp finfonctionfichier


minfofichier_mem_taille:
fs
mov edi,[ad_fichier]
cmp dword[edx+4],0
jne erreur_minfofichier_mem_taille  ;seul 32 bit pour la taille de fichier
mov eax,[edx]
gs
cmp eax,[edi+8]
ja finfonctionfichier  ;impossible d'augmenter la taille d'un fichier
gs
mov [edi+8],eax
fs
mov [to_fichier],eax

;mise a jour du descripteur
and ebx,0FFFFh
shl ebx,5   ;multiplie par 32
fs
add ebx,[ad_ficho]

fs
mov esi,[at_fichier]
fs
mov edi,[at_fichier+4]
gs
mov [ebx],esi
gs
mov [ebx+4],edi

fs
mov esi,[at_fichier+8]
fs
mov edi,[at_fichier+12]
gs
mov [ebx+8],esi
gs
mov [ebx+12],edi

fs
mov esi,[at_fichier+16]
fs
mov edi,[at_fichier+20]
gs
mov [ebx+16],esi
gs
mov [ebx+20],edi

fs
mov esi,[at_fichier+24]
fs
mov edi,[at_fichier+28]
gs
mov [ebx+24],esi
gs
mov [ebx+28],edi
jmp finfonctionfichier

erreur_minfofichier_mem_taille:
mov eax,cer_parami
jmp finfonctionfichiererr

;****************************
minfofichier_fat:               ;calcul de l'offset en cas de descripteur de type vfat
call minfo_charge_descripteur
cmp eax,0
jne finfonctionfichiererr


push ebx
xor ebx,ebx
fs
cmp byte[zt_lminfo+0Bh],0Fh
jne minfofichier_nvfat
fs
mov bl,[zt_lminfo]
and ebx,3Fh
shl ebx,5
minfofichier_nvfat:

fs                            ;verifie que le descripteur est le bon
mov ax,[ebx+zt_lminfo+14h]
shl eax,16
fs
mov ax,[ebx+zt_lminfo+1Ah]
fs                       
mov ch,[at_fichier]
and ch,0111100b
cmp ch,011000b   ;FAT32?
je pas32_minfofichier_fat
and eax,0FFFFh
pas32_minfofichier_fat:
fs
cmp eax,[ad_fichier]  ;on compare le numéros du premier cluster enregistré en ram et celui lut sur le disque
je ok_minfofichier_fat
pop ebx
jmp errsysf

ok_minfofichier_fat:  ;quel est l'info a modifier?
;cmp cl,0
;je minfofichier_fat_nom
cmp cl,1
je minfofichier_fat_taille
pop ebx
jmp errprmsf



minfofichier_fat_taille:
mov eax,[edx]
fs
cmp eax,[to_fichier]
je fin_minfofichier_fat_taille

fs
mov [to_fichier],eax           ;
fs
mov [ebx+zt_lminfo+01Ch],eax   ;modifie le descripteur du disque

fs
mov ebx,[ad_fichier]
cmp ebx,0
je fin_minfofichier_fat_taille

mov ecx,eax
boucle1_minfofichier_fat_taille:   ;recherche le dernier cluster a uttiliser
call lireindexfat
cmp eax,0
jne fin_minfofichier_fat_taille
mov eax,ebx
and eax,0FFFFFFF0h
cmp eax,0FFFFFFF0h
je fin_minfofichier_fat_taille
fs
cmp ecx,[to_1cluster]
jb boucle2_minfofichier_fat_taille
fs
sub ecx,[to_1cluster]
jmp boucle1_minfofichier_fat_taille

boucle2_minfofichier_fat_taille:  ;supprime ceux qui ne servent plus
mov ecx,ebx
call lireindexfat
cmp eax,0
jne fin_minfofichier_fat_taille
mov eax,ebx
and eax,0FFFFFFF0h
cmp eax,0FFFFFFF0h
je fin_minfofichier_fat_taille

push ebx
mov ebx,ecx
xor eax,eax
call ecrireindexfat
pop ebx
jmp boucle2_minfofichier_fat_taille

fin_minfofichier_fat_taille:
pop ebx


fin_minfofichier:
call minfo_sauvegarde_descripteur
jmp finfonctionfichiererr





;******************************
minfo_charge_descripteur:
fs
mov al,[at_fichier]
and al,00111100b
cmp al,010000b 
je minfo_charge_descripteur_fat       ;on teste si le fichier est fat12,
cmp al,010100b
je minfo_charge_descripteur_fat       ;ou fat16
cmp al,011000b
je minfo_charge_descripteur_fat       ;ou fat32
mov eax,cer_parami
ret

minfo_charge_descripteur_fat:
fs                      
mov al,[at_fichier]
and al,0011b
cmp al,0011b    ;si c'est un dossier racine, on ne peut modifier les métadonnées
jne ok_minfo_charge_descripteur_fat
mov eax,cer_parami
ret

ok_minfo_charge_descripteur_fat:

;corrige le descripteur de fichier pour le transformer en descripteur du dossier qui contient le fichier 
fs
mov eax,[ad_dossierfichier]
fs
xchg [ad_fichier],eax
fs
mov [ad_dossierfichier],eax
fs
mov eax,[to_dossierfichier]
fs
xchg [to_fichier],eax
fs
mov [to_dossierfichier],eax

fs                       
mov al,[at_fichier]
fs
mov [sauv_at_fichier],al
mov ah,al
and al,00111100b
shr ah,6
or al,10b
and ah,01b
or al,ah
fs
mov [at_fichier],al


;charge dans la zt le descripteur
push ebx
push ecx
push edx
push edi
push es
mov ax,seldat
mov es,ax
fs
mov edx,[ad_dansdossier]
mov ecx,512
mov edi,zt_lminfo
call sflirefichier
pop es
pop edi
pop edx
pop ecx
pop ebx

push eax
fs
mov eax,[ad_dossierfichier]
fs
xchg [ad_fichier],eax
fs
mov [ad_dossierfichier],eax
fs
mov eax,[to_dossierfichier]
fs
xchg [to_fichier],eax
fs
mov [to_dossierfichier],eax
fs                       
mov al,[sauv_at_fichier]
fs
mov [at_fichier],al
pop eax
ret


;******************************
minfo_sauvegarde_descripteur:

;sauvegarde le descripteur dans la table en ram
push ebx
push esi
push edi
and ebx,0FFFFh
shl ebx,5   ;multiplie par 32
fs
add ebx,[ad_ficho]

fs
mov esi,[at_fichier]
fs
mov edi,[at_fichier+4]
gs
mov [ebx],esi
gs
mov [ebx+4],edi

fs
mov esi,[at_fichier+8]
fs
mov edi,[at_fichier+12]
gs
mov [ebx+8],esi
gs
mov [ebx+12],edi

fs
mov esi,[at_fichier+16]
fs
mov edi,[at_fichier+20]
gs
mov [ebx+16],esi
gs
mov [ebx+20],edi

fs
mov esi,[at_fichier+24]
fs
mov edi,[at_fichier+28]
gs
mov [ebx+24],esi
gs
mov [ebx+28],edi
pop edi
pop esi
pop ebx


minfo_sauvegarde_descripteur2:

;corrige le descripteur de fichier pour le transformer en descripteur du dossier qui contient le fichier 
fs
mov eax,[ad_dossierfichier]
fs
xchg [ad_fichier],eax
fs
mov [ad_dossierfichier],eax
fs
mov eax,[to_dossierfichier]
fs
xchg [to_fichier],eax
fs
mov [to_dossierfichier],eax

fs                       
mov al,[at_fichier]
fs
mov [sauv_at_fichier],al
mov ah,al
and al,00111100b
shr ah,6
or al,10b
and ah,01b
or al,ah
fs
mov [at_fichier],al


;enregistre le descripteur
push ebx
push ecx
push edx
push esi
push edi
push es
mov ax,seldat
mov es,ax
fs
mov edx,[ad_dansdossier]
mov ecx,512
mov esi,zt_lminfo
call sfecrirefichier
pop es
pop edi
pop esi
pop edx
pop ecx
pop ebx

push eax
fs
mov eax,[ad_dossierfichier]
fs
xchg [ad_fichier],eax
fs
mov [ad_dossierfichier],eax
fs
mov eax,[to_dossierfichier]
fs
xchg [to_fichier],eax
fs
mov [to_dossierfichier],eax
fs                       
mov al,[sauv_at_fichier]
fs
mov [at_fichier],al
pop eax
ret



;************************************
sff_definis_msb_fichier:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§



;*****************************************************************************************
sff_reserve_espace_fichier:                   ;reserve espace pour fichier ecx=taille de fichier souhaité
call initdescrfdcourant
jc errprmsf

fs
mov al,[at_fichier]
and al,00111100b
cmp al,00001000b
je res_espace_fichier_mem
cmp al,00010000b
je res_espace_fichier_fat
cmp al,00010100b
je res_espace_fichier_fat
cmp al,00011000b
je res_espace_fichier_fat
jmp errprmsf


;**************************************
res_espace_fichier_mem:
push ebx
fs
mov ebx,[ad_fichier]
add ecx,431
and ecx,0FFFFFFF0h
call modtm 
mov edi,ebx
pop ebx
jnc ok_res_espace_fichier_mem  
mov eax,cer_pasm
jmp finfonctionfichiererr


ok_res_espace_fichier_mem:
fs
mov [ad_fichier],edi

;mise a jour du descripteur
pushad
and ebx,0FFFFh
shl ebx,5   ;multiplie par 32
fs
add ebx,[ad_ficho]

fs
mov esi,[at_fichier]
fs
mov edi,[at_fichier+4]
gs
mov [ebx],esi
gs
mov [ebx+4],edi

fs
mov esi,[at_fichier+8]
fs
mov edi,[at_fichier+12]
gs
mov [ebx+8],esi
gs
mov [ebx+12],edi

fs
mov esi,[at_fichier+16]
fs
mov edi,[at_fichier+20]
gs
mov [ebx+16],esi
gs
mov [ebx+20],edi

fs
mov esi,[at_fichier+24]
fs
mov edi,[at_fichier+28]
gs
mov [ebx+24],esi
gs
mov [ebx+28],edi
popad

jmp finfonctionfichier


;********************************
res_espace_fichier_fat:

call minfo_charge_descripteur
cmp eax,0
jne finfonctionfichiererr

pushad
xor ebx,ebx
fs
cmp byte[zt_lminfo+0Bh],0Fh
jne res_espace_fichier_fat_nvfat
fs
mov bl,[zt_lminfo]
and ebx,3Fh
shl ebx,5
res_espace_fichier_fat_nvfat:

fs                            ;verifie que le descripteur est le bon
mov ax,[ebx+zt_lminfo+14h]
shl eax,16
fs
mov ax,[ebx+zt_lminfo+1Ah]
push ecx
fs                       
mov ch,[at_fichier]
and ch,0111100b
cmp ch,011000b   ;FAT32?
je pas32_res_espace_fichier_fat
and eax,0FFFFh
pas32_res_espace_fichier_fat:
pop ecx
fs
cmp eax,[ad_fichier]  ;on compare le numéros du premier cluster enregistré en ram et celui lut sur le disque
je ok_meta_res_espace_fichier_fat
popad
jmp errsysf

ok_meta_res_espace_fichier_fat:
;verifie que le premier cluster existe bien
fs
cmp dword[ad_fichier],0
jne okcluster0_res_espace_fichier_fat
push edx
xor edx,edx
call ajn_cluster   ;sinon on le créer
cmp eax,0
jne err_ecrire_meta_fichier_fat 

fs
mov [ad_fichier],edx
fs
mov [ebx+zt_lminfo+01Ah],dx
shr edx,16
fs
mov [ebx+zt_lminfo+014h],dx
pop edx
okcluster0_res_espace_fichier_fat:


;mettre a jour la date de dernère modif
push ebx
call lire_date_heure  
call conv_date_fat
pop ebx
fs
mov [ebx+zt_lminfo+16h],ax
fs
mov [ebx+zt_lminfo+18h],dx
popad

call minfo_sauvegarde_descripteur
cmp eax,0
jne finfonctionfichiererr

xor edx,edx
mov eax,ecx
fs
mov ecx,[to_1cluster]
div ecx
mov ecx,eax
cmp edx,0
je ignor1_res_espace_fichier_fat
inc ecx      ;ecx=nombre de cluster nécessaire
ignor1_res_espace_fichier_fat:
cmp ecx,0 
je errprmsf

fs
mov edi,[ad_fichier]
dec ecx
jz finfonctionfichier


;*****************************************************
boucle_determination_fin_res_espace_fichier_fat:
mov ebx,edi
call lireindexfat   ;ebx=index a lire ebx=valeur

mov eax,ebx
and eax,0FFFFFFF0h
cmp eax,0FFFFFFF0h 
jne ignore2_res_espace_fichier_fat
test ebx,08h 
jnz res_espace_fichier_fat_ajoute_autre_cluster
jmp errsysf
ignore2_res_espace_fichier_fat:
mov edi,ebx
dec ecx
jnz boucle_determination_fin_res_espace_fichier_fat
jmp finfonctionfichier


res_espace_fichier_fat_ajoute_autre_cluster:
;cherche cluster vide
mov edx,edi
res_espace_fichier_fat_boucle_cherche_clustervide2:
mov ebx,edx
call lireindexfat   ;ebx=index a lire ebx=valeur
cmp eax,0
jne finfonctionfichiererr
cmp ebx,0
je res_espace_fichier_fat_clustervide_ok2
inc edx
fs
cmp edx,[nb_cluster]
jne ignore4_res_espace_fichier_fat
mov edx,2
ignore4_res_espace_fichier_fat:
cmp edx,edi
jne res_espace_fichier_fat_boucle_cherche_clustervide2

;plus de cluster libre
mov eax,cer_pasm
jmp finfonctionfichiererr

res_espace_fichier_fat_clustervide_ok2:  ;remplace le dernier cluster par l'index de cluster vide
mov eax,edx   ;edi=dernier cluster du fichier edx=cluster vide
mov ebx,edi
call ecrireindexfat_sp   ;ebx=index a ecrire eax=valeur de l'index.  écrit l'index fat dans la zt ram mais pas sur le disque

cmp eax,0
jne finfonctionfichiererr
mov edi,edx
dec ecx
jnz res_espace_fichier_fat_ajoute_autre_cluster

;************************************
;ecrit le dernier cluster
mov eax,0FFFFFFF8h
mov ebx,edi
call ecrireindexfat_sp   ;ebx=index a ecrire eax=valeur de l'index.  écrit l'index fat dans la zt ram mais pas sur le disque
cmp eax,0
jne finfonctionfichiererr
call sauvegarde_zt_fat   ;transfert la zt fat ram sur le disque si celle ci as été modifié
jmp finfonctionfichiererr




;*************************************************************************************************************************
sff_lit_dossier:            ;liste le contenu d'un dossier ebx=numéros du fichier 
                            ;ds:edi=zt ou copier les données ecx=taille max ;edx=premier fichier a lire
			    ;retour: ebx=nombre de fichier chargé dans la zt
call initdescrfdcourant
jc errprmsf

mov ebp,edi
add ecx,edi ;ecx=adresse a ne pas dépasser


fs
test byte[at_fichier],00000010b
jz errprmsf


fs
mov al,[at_fichier]
and al,00111100b
cmp al,000100b
je sff_lit_dossier_iso9660   ;ou iso9660
cmp al,001000b
je sff_lit_dossier_mem       ;fichier mémoire
cmp al,010000b 
je sff_lit_dossier_fat       ;on teste si le fichier est fat12,
cmp al,010100b
je sff_lit_dossier_fat       ;ou fat16
cmp al,011000b
je sff_lit_dossier_fat       ;ou fat32
jmp errprmsf


;**********************
sff_lit_dossier_mem:
mov ax,ds
mov es,ax
mov ax,selramh
mov ds,ax
xor ebx,ebx


boucle1_sff_lit_dossier_mem:             ;recherche le premier fichier a afficher
cmp edx,0
je boucle2_sff_lit_dossier_mem
cmp byte[ebx+2],"F"
je fin_sff_lit_dossier
cmp byte[ebx+2],"X"
jne ignore1_sff_lit_dossier_mem

dec edx

ignore1_sff_lit_dossier_mem:
mov eax,[ebx+4]
add ebx,eax
jmp boucle1_sff_lit_dossier_mem



boucle2_sff_lit_dossier_mem:            ;ajoute tout les noms des fichier a la sortie
cmp byte[ebx+2],"F"
je fin_sff_lit_dossier
cmp byte[ebx+2],"X"
jne ignore2_sff_lit_dossier_mem

mov esi,ebx
add esi,10h

boucle3_sff_lit_dossier_mem:        ;copie le nom du fichier
lodsb
cmp al,0
jne ignore3_sff_lit_dossier_mem 
inc edx
mov al,"|"
ignore3_sff_lit_dossier_mem :
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_mem
cmp al,"|"
jne boucle3_sff_lit_dossier_mem

ignore2_sff_lit_dossier_mem:         ;passe a la zone suivante
mov eax,[ebx+4]
add ebx,eax
jmp boucle2_sff_lit_dossier_mem


finzt_sff_lit_dossier_mem:          ;efface le dernier nom si il n'est pas complet
es
cmp byte[edi],"|"
je finzt2_sff_lit_dossier_mem
cmp edi,ebp
je finzt2_sff_lit_dossier_mem
dec edi
jmp finzt_sff_lit_dossier_mem

finzt2_sff_lit_dossier_mem:
mov al,0
stosb
mov eax,cer_pasm
mov ebx,edx
jmp finfonctionfichierokebx


fin_sff_lit_dossier:
mov al,0
stosb
xor eax,eax
mov ebx,edx
jmp finfonctionfichierokebx




;*****************************************************
charg_part_dossier:             ;charge une partie du dossier dans la chaine de travail

push ebx
push ecx
push edx
push edi
push ebp
push es
mov di,seldat
mov es,di
mov edi,zt_lminfo
mov ecx,256
call sflirefichier
pop es
pop ebp
pop edi
pop edx
pop ecx
pop ebx
ret






;**************************
sff_lit_dossier_iso9660:
mov ax,ds
mov es,ax
mov ax,seldat
mov ds,ax
mov ebx,edx
xor edx,edx


boucle1_sff_lit_dossier_iso9660:             ;recherche le premier fichier a afficher
cmp ebx,0
je boucle2_sff_lit_dossier_iso9660
call charg_part_dossier
cmp eax,0
jne err_sff_lit_dossier_iso9660
dec ebx
xor eax,eax
mov al,[zt_lminfo] ;taille du descripteur de fichier
cmp eax,0
je fin_sff_lit_dossier_iso9660
add edx,eax
jmp boucle1_sff_lit_dossier_iso9660




boucle2_sff_lit_dossier_iso9660:             ;enregistre le nom de chaques fichier suivants
call charg_part_dossier
cmp eax,0
jne err_sff_lit_dossier_iso9660
mov esi,[zt_lminfo+32]
and esi,0FFh
add esi,33
mov byte[zt_lminfo+esi],0

mov esi,zt_lminfo+33
boucle3_sff_lit_dossier_iso9660:
lodsb
cmp al,0
je suite_sff_lit_dossier_iso9660
cmp al,";"
je suite_sff_lit_dossier_iso9660
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
jmp boucle3_sff_lit_dossier_iso9660


suite_sff_lit_dossier_iso9660:
mov al,"|"
stosb
inc ebx
xor eax,eax
mov al,[zt_lminfo] ;taille du descripteur de fichier
cmp eax,0
je fin_sff_lit_dossier_iso9660 
add edx,eax
jmp boucle2_sff_lit_dossier_iso9660



finzt_sff_lit_dossier_iso9660:          ;efface le dernier nom si il n'est pas complet
es
cmp byte[edi],"|"
je finzt2_sff_lit_dossier_iso9660
cmp edi,ebp
je finzt2_sff_lit_dossier_iso9660
dec edi
jmp finzt_sff_lit_dossier_iso9660

finzt2_sff_lit_dossier_iso9660:
mov al,0
stosb
mov eax,cer_pasm
jmp finfonctionfichierokebx


fin_sff_lit_dossier_iso9660:
mov al,0
stosb
xor eax,eax
jmp finfonctionfichierokebx




err_sff_lit_dossier_iso9660:
es
mov byte[edi],0
jmp finfonctionfichiererr






;**************************
sff_lit_dossier_fat:
mov ax,ds
mov es,ax
mov ax,seldat
mov ds,ax
mov ebx,edx
xor edx,edx


boucle1_sff_lit_dossier_fat:             ;recherche le premier fichier a afficher
cmp ebx,0
je boucle2_sff_lit_dossier_fat
call charg_part_dossier
cmp eax,0
jne err_sff_lit_dossier_iso9660

cmp byte[zt_lminfo],0
je fin_sff_lit_dossier_iso9660
cmp byte[zt_lminfo],02Eh
je suite1_sff_lit_dossier_fat
cmp byte[zt_lminfo],0E5h
je suite1_sff_lit_dossier_fat
cmp byte[zt_lminfo+0Bh],0Fh
jne suite1_sff_lit_dossier_fat

dec ebx

suite1_sff_lit_dossier_fat:
add edx,32
jmp boucle1_sff_lit_dossier_fat




boucle2_sff_lit_dossier_fat:             ;enregistre le nom de chaques fichier suivants
call charg_part_dossier
cmp eax,0
jne err_sff_lit_dossier_iso9660

cmp byte[zt_lminfo],0
je fin_sff_lit_dossier_iso9660
cmp byte[zt_lminfo],02Eh
je suite2_sff_lit_dossier_fat
cmp byte[zt_lminfo],0E5h
je suite2_sff_lit_dossier_fat

cmp byte[zt_lminfo+0Bh],0Fh
je vfat_sff_lit_dossier_fat

mov esi,zt_lminfo             ;fichier fat classique
movsb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
lodsb
cmp al," "
je ext_sff_lit_dossier_fat
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
lodsb
cmp al," "
je ext_sff_lit_dossier_fat
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
lodsb
cmp al," "
je ext_sff_lit_dossier_fat
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
lodsb
cmp al," "
je ext_sff_lit_dossier_fat
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
lodsb
cmp al," "
je ext_sff_lit_dossier_fat
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
lodsb
cmp al," "
je ext_sff_lit_dossier_fat
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
lodsb
cmp al," "
je ext_sff_lit_dossier_fat
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660


ext_sff_lit_dossier_fat:
mov esi,zt_lminfo+8    
mov eax,[esi]
and eax,0FFFFFFh
cmp eax,0202020h
je ffn_sff_lit_dossier_fat

mov al,"."
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
movsb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
lodsb
cmp al," "
je ffn_sff_lit_dossier_fat
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
lodsb
cmp al," "
je ffn_sff_lit_dossier_fat
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660

ffn_sff_lit_dossier_fat:
mov al,"|"
stosb
inc ebx

suite2_sff_lit_dossier_fat:
add edx,32
jmp boucle2_sff_lit_dossier_fat




macro stob_utf8 {   ;macro de transformation en utf8
cmp eax,0
je fin_vfat_sff_lit_dossier_fat

cmp eax,80h   ;-de 7 bit
jb .stob_utf8_1
cmp eax,800h  ;-de 11 bits
jb .stob_utf8_2

push eax
push eax
and al,3Fh
or al,80h
mov bh,al
pop eax
shr eax,6
and al,3Fh
or al,80h
mov bl,al
pop eax
shr eax,12
and al,0Fh
or al,0E0h

stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
mov al,bl
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
mov al,bh
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
jmp .fin_stob_utf8


.stob_utf8_2:
mov ebx,eax
and bl,3Fh
or bl,80h

shr eax,6
and al,01Fh
or al,0C0h

stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
mov al,bl
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660
jmp .fin_stob_utf8


.stob_utf8_1:
stosb
cmp edi,ecx
je finzt_sff_lit_dossier_iso9660


.fin_stob_utf8: 
}




vfat_sff_lit_dossier_fat:           ;fichier vFat
mov esi,[zt_lminfo]
test esi,40h         ;on test si c'est bien le marqueur de début de descripteur de nom long
jz suite2_sff_lit_dossier_fat
and esi,3Fh
shl esi,5
add edx,esi
sub esi,32
add edx,32

boucle_vfat_sff_lit_dossier_fat:
xor eax,eax
mov ax,[esi+zt_lminfo+01h]
vfat_sff_lit_dossier_fat1:
stob_utf8
mov ax,[esi+zt_lminfo+03h]
vfat_sff_lit_dossier_fat2:
stob_utf8
mov ax,[esi+zt_lminfo+05h]
vfat_sff_lit_dossier_fat3:
stob_utf8
mov ax,[esi+zt_lminfo+07h]
vfat_sff_lit_dossier_fat4:
stob_utf8
mov ax,[esi+zt_lminfo+09h]
vfat_sff_lit_dossier_fat5:
stob_utf8
mov ax,[esi+zt_lminfo+0Eh]
vfat_sff_lit_dossier_fat6:
stob_utf8
mov ax,[esi+zt_lminfo+10h]
vfat_sff_lit_dossier_fat7:
stob_utf8
mov ax,[esi+zt_lminfo+12h]
vfat_sff_lit_dossier_fat8:
stob_utf8
mov ax,[esi+zt_lminfo+14h]
vfat_sff_lit_dossier_fat9:
stob_utf8
mov ax,[esi+zt_lminfo+16h]
vfat_sff_lit_dossier_fat10:
stob_utf8
mov ax,[esi+zt_lminfo+18h]
vfat_sff_lit_dossier_fat11:
stob_utf8
mov ax,[esi+zt_lminfo+1Ch]
vfat_sff_lit_dossier_fat12:
stob_utf8
mov ax,[esi+zt_lminfo+1Eh]
vfat_sff_lit_dossier_fat13:
stob_utf8
sub esi,32
jmp boucle_vfat_sff_lit_dossier_fat




fin_vfat_sff_lit_dossier_fat:
mov al,"|"
stosb
inc ebx
jmp boucle2_sff_lit_dossier_fat










;****************************************************************************************************
sff_lit_disques:   ;lit les disques installé   ds:edx pointeur ou copier le bitmap de 32 octet
                                               ;octet 0 à 15 partitions
					       ;octet 16 a 28 reservé
 					       ;octet 29 = b0-b6 reservé b7= disquette 
 					       ;octet 30 = atapi 
 					       ;octet 31 = ata  
mov dword[edx+00],0
mov dword[edx+04],0
mov dword[edx+08],0
mov dword[edx+12],0
mov dword[edx+16],0
mov dword[edx+20],0
mov dword[edx+24],0
mov dword[edx+28],0


;lit la présence disquette
fs
test byte[at_fc_fichier],10h
jz sff_lit_disques_pasdisquette
or byte[edx+29],80h
sff_lit_disques_pasdisquette:



;lit la présence de disque ata et atapi
mov esi,ad_descd
mov cl,1
sff_lit_disques_boucleata:
fs
mov al,[esi]
and al,07h

cmp al,1
je sff_lit_disques_ata
cmp al,2
je sff_lit_disques_ata
cmp al,3
jne sff_lit_disques_pasata
sff_lit_disques_ata:
or [edx+31],cl
sff_lit_disques_pasata:
cmp al,4
jne sff_lit_disques_pasatapi
or [edx+30],cl
sff_lit_disques_pasatapi:

add esi,32
shl cl,1
cmp esi,ad_descd+100h
jne sff_lit_disques_boucleata


;lit la présence de partition
mov esi,ad_descp+64
mov cl,1
sff_lit_disques_bouclepart:
fs
cmp byte[esi],2   ;ignore partition vide, inconnue et endommagé
jbe sff_lit_disques_suitepart
or [edx],cl
sff_lit_disques_suitepart:
shl cl,1
jnc sff_lit_disques_suitepart2
inc edx
mov cl,1
sff_lit_disques_suitepart2:
add esi,64
cmp esi,ad_descp+8192
jne sff_lit_disques_bouclepart

jmp finfonctionfichier
 



