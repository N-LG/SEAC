;sous fonction de création, d'arret de tache a partir de programme *.FPM
; et sous fonction de commutation de tache




;******************************************************************************************
;création d'une nouvelle tache

;création du nom a partir de la commande
mov esi,ad_zdc
mov edi,ad_chaine_travail
boucle_creation_nom_exec:
mov al,[esi]
cmp al,0
je fin_commande
cmp al," "
je fin_commande
cmp al,"a"
jb pas_cor_cass_nf
cmp al,"z"
ja pas_cor_cass_nf
sub al,20h               ;on passe les lettres du nom en majuscule
pas_cor_cass_nf:
mov [edi],al
inc esi
inc edi
cmp edi,ad_chaine_travail+1F0h
jne boucle_creation_nom_exec
fin_commande:
mov dword[edi],".FE"
mov byte[edi+3],0


;ouverture du fichier dans le répertoire courant
xor eax,eax
mov bx,0
mov edx,ad_chaine_travail
int 64h
cmp eax,0
je fichier_exec_ok

;si echec ouverture a partir du repertoire système
xor eax,eax
mov bx,1
mov edx,ad_chaine_travail
int 64h
cmp eax,0
je fichier_exec_ok

;si toujours echec affichage du message d'erreur
erreurcommande:
mov cl,1
call affmsgsyst
mov edx,ad_zdc
call affjournal
mov al,17h
call affcj
mov al,13
call affcj
jmp pascommande


fichier_exec_ok:        ;si fichier trouvé, sauvegarde de l'index
mov [num_fichier_tache],ebx

mov ecx,500h             ;réservation d'un espace mémoire 
call resmem
jc cretache_ermm2
mov [ad_tache_cree],ebx

;chargement de l'en tête du fichier
mov ax,selramh
mov es,ax
mov edi,[ad_tache_cree]
add edi,10h
mov ebx,[num_fichier_tache]
mov ecx,60h  ;taille de l'en-tête fichier
xor edx,edx
mov al,4
int 64h
cmp eax,0
jne cretache_erlc

;verifie si le format est correcte
mov ebx,[ad_tache_cree]
es
cmp dword[ebx+type_fe],"FE 1"
jne cretache_erfc

;vérifie que la taille de la pile est superieur ou égale a 4ko
es
cmp dword[ebx+to_pile_fe],1000h
jae pile_ok_tache
es
mov dword[ebx+to_pile_fe],1000h  ;sinon on corrige
pile_ok_tache:

;vérifie que la taille du code est non nul
es
cmp dword[ebx+to_code_fe],0
je cretache_erfc


;calcul des tailles réel des différente zone mémoire
es
mov ecx,[ebx+to_data1_fe]
es
add ecx,[ebx+tsd_data1_fe]
es
add ecx,[ebx+tsf_data1_fe]
es
mov [ebx+tt_data1_dt],ecx

es
mov ecx,[ebx+to_data2_fe]
es
add ecx,[ebx+tsd_data2_fe]
es
add ecx,[ebx+tsf_data2_fe]
es
mov [ebx+tt_data2_dt],ecx

es
mov ecx,[ebx+to_data3_fe]
es
add ecx,[ebx+tsd_data3_fe]
es
add ecx,[ebx+tsf_data3_fe]
es
mov [ebx+tt_data3_dt],ecx

es
mov ecx,[ebx+to_data4_fe]
es
add ecx,[ebx+tsd_data4_fe]
es
add ecx,[ebx+tsf_data4_fe]
es
mov [ebx+tt_data4_dt],ecx

;calcul des adresse (relative au debut de la zone mémoire) des différent zone mémoire
mov eax,data_tache
es
mov [ebx+ad_pile0_dt],eax
es
add eax,[ebx+to_pile_fe]
es
mov [ebx+ad_pile1_dt],eax
es
add eax,[ebx+to_pile_fe]
es
mov [ebx+ad_pile2_dt],eax
es
add eax,[ebx+to_pile_fe]
es
mov [ebx+ad_pile3_dt],eax
es
add eax,[ebx+to_pile_fe]
es
mov [ebx+ad_code_dt],eax
es
add eax,[ebx+to_code_fe]
es
mov [ebx+ad_data1_dt],eax
es
add eax,[ebx+tt_data1_dt]
es
mov [ebx+ad_data2_dt],eax
es
add eax,[ebx+tt_data2_dt]
es
mov [ebx+ad_data3_dt],eax
es
add eax,[ebx+tt_data3_dt]
es
mov [ebx+ad_data4_dt],eax

;calcul de la taille mémoire totale nécessaire a la tache
es
add eax,[ebx+tt_data4_dt]
mov ecx,eax

;agrandissement de la mémoire pour s'adapter aux besoins
mov ebx,[ad_tache_cree]
and ecx,0FFFFFFF0h
add ecx,10h       ;pour avoir une granularité de 16octets
call modtm
jc cretache_ermm1
mov [ad_tache_cree],ebx



;recopie de la commande
mov esi,ad_zdc
mov edi,recop_commande
add edi,ebx
mov ecx,512
cld
rep movsb



;recopie du descriptif de la tache
mov esi,[ad_tache_cree]
mov ebx,[num_fichier_tache]  

es                                
mov ecx,[esi+ad_code_fe]
sub ecx,60h
cmp ecx,0
je ignore_descriptif     ;controle si non nulle
cmp ecx,255
ja ignore_descriptif     ;controle si ne dépasse pas 255 octet

mov edi,descriptif_tache
add edi,esi
es
mov edx,60h           ;position (fixe) du texte descripteur de tache
mov al,4
int 64h
cmp eax,0
jne cretache_erlc

es                                
mov edi,[esi+ad_code_fe]
sub edi,60h
add edi,descriptif_tache
add edi,esi
es
mov byte[edi],0     ;place un zero a la fin si ça a été oublié
ignore_descriptif:

;remplissage des zones mémoires

es
mov edi,[esi+ad_code_dt]            ;segment de code
add edi,esi
es                                
mov ecx,[esi+to_code_fe]
es
mov edx,[esi+ad_code_fe]
mov al,4
int 64h
cmp eax,0
jne cretache_erlc

es                                ;segment de donnée 1
mov edi,[esi+ad_data1_dt]
es                                
add edi,[esi+tsd_data1_fe]
add edi,esi
es
mov ecx,[esi+to_data1_fe]
cmp ecx,0
je ignore_data1  
es
mov edx,[esi+ad_data1_fe]
mov al,4
int 64h
cmp eax,0
jne cretache_erlc
ignore_data1:


es                                ;segment de données 2
mov edi,[esi+ad_data2_dt]
es                                
add edi,[esi+tsd_data2_fe]
add edi,esi
es
mov ecx,[esi+to_data2_fe]  
cmp ecx,0
je ignore_data2
es
mov edx,[esi+ad_data2_fe]
mov al,4
int 64h
cmp eax,0
jne cretache_erlc
ignore_data2:

mov esi,[ad_tache_cree]
mov ebx,[num_fichier_tache]
es                               ;segment de données 3
mov edi,[esi+ad_data3_dt]
es                                
add edi,[esi+tsd_data3_fe]
add edi,esi
es
mov ecx,[esi+to_data3_fe]  
cmp ecx,0
je ignore_data3
es
mov edx,[esi+ad_data3_fe]
mov al,4
int 64h
cmp eax,0
jne cretache_erlc
ignore_data3:

mov esi,[ad_tache_cree]
mov ebx,[num_fichier_tache]
es                                ;segment de données 4
mov edi,[esi+ad_data4_dt]
es                                
add edi,[esi+tsd_data4_fe]
add edi,esi
es
mov ecx,[esi+to_data4_fe]  
cmp ecx,0
je ignore_data4
es
mov edx,[esi+ad_data4_fe]
mov al,4
int 64h
cmp eax,0
jne cretache_erlc
ignore_data4:
jmp suite_crea_tache



;************************************************************************************
creation_tache_interne:         ;cs:esi=code de l'application  ecx=nombre d'octet du code


push ecx   ;calcul espace nécessaire
add ecx,16384
add ecx,data_tache 
add ecx,15
and ecx,0FFFFFFF0h            
call resmem              ;réservation d'un espace mémoire 
pop ecx
jc cretache_ermm2
mov [ad_tache_cree],ebx

;initialisation des variables de la taches
mov ax,selramh
mov es,ax

es
mov dword[ebx+to_pile_fe],4096
es
mov [ebx+to_code_fe],ecx
es
mov dword[ebx+tt_data1_dt],0
es
mov dword[ebx+tt_data2_dt],0
es
mov dword[ebx+tt_data3_dt],0
es
mov dword[ebx+tt_data4_dt],0


mov eax,data_tache
es
mov [ebx+ad_pile0_dt],eax
add eax,4096
es
mov [ebx+ad_pile1_dt],eax
add eax,4096
es
mov [ebx+ad_pile2_dt],eax
add eax,4096
es
mov [ebx+ad_pile3_dt],eax
add eax,4096
es
mov [ebx+ad_code_dt],eax
add eax,ecx
es
mov [ebx+ad_data1_dt],eax
es
mov [ebx+ad_data2_dt],eax
es
mov [ebx+ad_data3_dt],eax
es
mov [ebx+ad_data4_dt],eax



;remplissage de la zones de code
mov edi,ebx
es
add edi,[ebx+ad_code_dt]
push ds
push cs
pop ds
rep movsb
pop ds


;recopie de la commande dans le descriptif
mov esi,ad_zdc
mov edi,descriptif_tache
add edi,ebx
mov ecx,256
cld
rep movsb


;recopie la commande
mov esi,ad_zdc
mov edi,recop_commande
add edi,ebx
mov ecx,512
cld
rep movsb

mov esi,ebx

;*************************************************************************************
;recherche emplacement disponible et création d'un segment pour la LDT dans la GDT
suite_crea_tache:
mov ax,selgdt
mov ds,ax
mov ebx,8        ;on ne remplace pas le descripteur nul
boucle_rGDT:
cmp dword[ebx],0
jne pastrouvevidegdt
cmp dword[ebx+4],0
je trouvevidegdt
pastrouvevidegdt:
add ebx,8
cmp ebx,10000h
jne boucle_rGDT
jmp cretache_ermm1

trouvevidegdt:
es
mov [esi+sel_ldt_tache],bx     ;selecteur de segment qui coresspond a la LDT de la tache, sauvegarde


;créer les descripteur de secteur   
mov ax,seldat
mov ds,ax
mov esi,[ad_tache_cree]             
mov ax,selramh
mov ds,ax
call maj_ldtache


;initialisation des piles de tache
es
lldt [esi+sel_ldt_tache] ;on charge d'abord la bonne LDT

;initialisation de la pile 3 de la tache
es
mov edi,[esi+to_pile_fe]
sub edi,4
mov ax,sel_pilet3
mov ds,ax
es
mov [esi+sauv_esp3],edi   ;sauvegarde pointeur de la pile

;initialisation de la pile 2 de la tache
es
mov edi,[esi+to_pile_fe]
sub edi,4
mov ax,sel_pilet2
mov ds,ax
es
mov [esi+sauv_esp2],edi   ;sauvegarde pointeur de la pile

;initialisation de la pile 1 de la tache
es
mov edi,[esi+to_pile_fe]
sub edi,4
mov ax,sel_pilet1
mov ds,ax
es
mov [esi+sauv_esp1],edi     ;sauvegarde pointeur de la pile


;initialisation de la pile 0 de la tache
es
mov edi,[esi+to_pile_fe]
sub edi,4
mov ax,sel_pilet0
mov ds,ax


;sauvegarde sur la pile des instruction de retour (int 61h/int 30h)
sub edi,4
mov dword[edi],sel_pilet3  ;push ss niv 3
sub edi,4
es
mov eax,[esi+sauv_esp3]
mov dword[edi],eax         ;push esp niv 3


mov eax,000011001000000010b     ;   IOPL=3  IF=1     ;flag=0:0:ID:VIP  VIF:AC:VM:RF  0:NT:IOPL:IOPL  OF:DF:IF:TF  SF:ZF:0:AF  0:PF:1:CF
sub edi,4
mov [edi],eax        ;pushfd
sub edi,4
mov dword[edi],sel_codet  ;push cs (32 bits)
sub edi,4
mov dword[edi],0         ;push eip

sub edi,4
mov dword[edi],0   
sub edi,4
mov dword[edi],sel_codet

;sauvegarde sur la pile de toute les valeurs initiales
sub edi,4
mov dword[edi],0       ;eax
sub edi,4
mov dword[edi],0       ;ebx
sub edi,4
mov dword[edi],0       ;ecx
sub edi,4
mov dword[edi],0       ;edx
sub edi,4
mov dword[edi],0       ;esi
sub edi,4
mov dword[edi],0       ;edi
sub edi,4
mov dword[edi],0       ;ebp

mov eax,sel_codet
sub edi,4
mov [edi],eax        ;ds
sub edi,4
mov [edi],eax        ;es
sub edi,4
mov [edi],eax        ;fs
sub edi,4
mov [edi],eax        ;gs  

es
mov [esi+sauv_esp0],edi  ;sauvegarde pointeur de la pile



;initialistaion de l'en tête descripteur espace mémoire
es
mov byte[esi+type_dm],"T"

;initialisation du temps d'execution de la tache (temps par defaut)
es
mov byte[esi+temp_exec_tache],1

mov ax,seldat
mov ds,ax
calcIDnt:
inc dword[derniere_id]   ;calcul l'ID de la tache
mov ax,[derniere_id]
cmp ax,0
je calcIDnt

xor ebx,ebx
boucle_verif_id:             ;verification que cet ID n'est pas déja uttilisé
es
cmp byte[ebx+type_dm],"T"
jne ignore_verif_id

es
cmp [ebx+id_tache],ax
je calcIDnt             ;si c'est deja uttilisé on essaye une autre ID

ignore_verif_id:
es
mov ecx,[ebx+to_tache]
add ebx,ecx
es
cmp byte[ebx+type_dm],"F"
jne boucle_verif_id

es
mov [esi+id_tache],ax




;referme le fichier
mov ebx,[num_fichier_tache]  
mov al,1
int 64h
jmp pascommande


cretache_erlc:      ;fin erreur lecture de fichier
mov ebx,[ad_tache_cree]
call libmem

mov ebx,[num_fichier_tache]  
mov al,1
int 64h

call affnj
mov cl,3
call affmsgsyst
jmp pascommande


cretache_ermm1:    ;fin erreur manque de mémoire (en liberant la mémoire)
mov ax,seldat
mov ds,ax
mov ebx,[ad_tache_cree]
call libmem

cretache_ermm2:    ;fin erreur manque de mémoire (sans liberer la mémoire)
mov ebx,[num_fichier_tache]  
mov al,1
int 64h

mov cl,5
call affmsgsyst
jmp pascommande


cretache_erfc:        ;fin erreur fichier corrompu
mov cl,6
call affmsgsyst
jmp pascommande


;**********************************************************************************************
cmdmtt:                     ;execute la commande "mtt ID temp"

mov edx,ad_zdc          ;recherche la chaine qui coresspond a l'ID
boucle1_mtt:
cmp byte[edx]," "
jne suite_boucle1_mtt
cmp byte[edx+1]," "
jne id_mtt
suite_boucle1_mtt:
inc edx
cmp edx,ad_zdc+200h
je fin_commande_erreur_param
jmp boucle1_mtt


;convertit l'id en entier 16 bit
id_mtt:
inc edx
mov eax,101
int 61h
test ecx,0FFFF0000h
jnz fin_commande_erreur_param

;recherche la zone mémoire qui correspond a l'ID
mov ax,selramh
mov es,ax
xor ebx,ebx

boucle_mtt:
es
cmp byte[ebx+2],"F"
je erreurtachent
es
cmp byte[ebx+2],"T"
jne suite_boucle_mtt
es
cmp [ebx+8],cx
je mtt_tache_trouv

suite_boucle_mtt:
es
mov eax,[ebx+4]
add ebx,eax
jmp boucle_mtt

mtt_tache_trouv:

boucle2_mtt:
cmp byte[edx]," "
jne suite_boucle2_mtt
cmp byte[edx+1]," "
jne tt_mtt
suite_boucle2_mtt:
inc edx
cmp edx,ad_zdc+200h
je fin_commande_erreur_param
jmp boucle2_mtt


;convertit le temps en entier 8 bit
tt_mtt:
mov si,cx
inc edx
mov eax,100
int 61h
test ecx,0FFFFFF00h
jnz fin_commande_erreur_param
cmp ecx,0
je fin_commande_erreur_param

es
mov [ebx+temp_exec_tache],cl ;chargement du nouveau temp

push cx              ;signal le changement de temp d'execution
mov cl,93
call affmsgsyst
mov ax,si
call affh1j
pop cx
mov al,13
call affcj
jmp pascommande




;**********************************************************************************************
cmdstop:                     ;execute la commande "stop ID"


mov edx,ad_zdc          ;recherche la chaine qui coresspond a l'ID
boucle_stop1:
cmp byte[edx]," "
jne suite_boucle_stop1
cmp byte[edx+1]," "
jne id_stop
suite_boucle_stop1:
inc edx
cmp edx,ad_zdc+200h
je fin_commande_erreur_param
jmp boucle_stop1

;convertit l'id en entier 16 bit
id_stop:
inc edx
mov eax,101
int 61h
test ecx,0FFFF0000h
jnz fin_commande_erreur_param


cmp [id_tache_af],cx
jne pas_af_stop
mov byte[nb_zrc],0
mov word[id_tache_af],0
mov dword[ad_tache_af],0
or byte[at_csl],01h ;signale que l'affichage doit être mis a jour
pas_af_stop:

;recherche la zone mémoire qui correspond a l'ID
mov ax,selramh
mov es,ax
xor ebx,ebx

boucle_stop:
es
cmp byte[ebx+2],"F"
je erreurtachent
es
cmp byte[ebx+2],"T"
jne suite_boucle_stop
es
cmp [ebx+8],cx
je stop_tache_trouv

suite_boucle_stop:
es
mov eax,[ebx+4]
add ebx,eax
jmp boucle_stop

stop_tache_trouv:

;supprime le descripteur de la LDT
es
mov si,[ebx+sel_ldt_tache]
mov ax,selgdt
mov ds,ax
mov dword[si],0
mov dword[si+4],0

;libère la mémoire
call libmem

;ferme les fichier
call ferme_fichier_tache

push cx  ;signal l'arret forcée de la tache
mov cl,92
call affmsgsyst
pop ax
call affh1j
mov al,13
call affcj
jmp pascommande


erreurtachent:
push ecx
mov cl,3  
call affmsgsyst
mov edx,ad_zdc
call affjournal
mov al,34
call affcj
mov cl,4
call affmsgsyst
pop eax
call affh1j
mov al,17h
call affcj
mov al,13
call affcj
jmp pascommande

;*********************************************************************************************
int_60:   ;arret de la tache qui a appellé cette fonction (pas d'argument)
cli
mov ax,seldat
mov ds,ax
mov ax,selramh
mov es,ax
mov ebx,[ad_tache_exec]

;supprime le descripteur de la LDT
es
mov si,[ebx+sel_ldt_tache]
mov ax,selgdt
mov ds,ax
mov dword[si],0
mov dword[si+4],0

;libère la mémoire
call libmem

;ferme les fichier
mov ax,seldat
mov ds,ax
mov cx,[id_tache_exec]
call ferme_fichier_tache
xor ebx,ebx
mov cx,[id_tache_af]
cmp [id_tache_exec],cx
jne selection_tache_suivante
mov byte[nb_zrc],0
mov word[id_tache_af],0
mov dword[ad_tache_af],0
or byte[at_csl],01h ;signale que l'affichage doit être mis a jour
jmp selection_tache_suivante

;*********************************************************************************************
ferme_fichier_tache:          ;ferme les fichier ouvert par la tache et les zone de communication employé (cx=ID de la tache)
pushad
push ds
push es



mov ax,seldat              ;ferme les fichier ouvert par la tache
mov ds,ax
mov ax,selramh
mov es,ax
mov ebx,[ad_ficho]
mov ebp,[max_ficho]
add ebp,ebx

boucle_ferme_fichier_tache:
es
cmp cx,[ebx+2]
jne nok_ferme_fichier_tache
es
mov dword[ebx],0
es
mov dword[ebx+4],0
es
mov dword[ebx+8],0
es
mov dword[ebx+12],0
es
mov dword[ebx+16],0
es
mov dword[ebx+20],0
es
mov dword[ebx+24],0
es
mov dword[ebx+28],0

nok_ferme_fichier_tache:
add ebx,20h
cmp ebx,ebp
jb boucle_ferme_fichier_tache


mov ax,selramh            ;efface les canaux de communication employé par la tache
mov ds,ax
xor ebx,ebx
boucle_efface_canauxcom:
mov eax,[ebx+to_tache]
cmp byte[ebx+type_dm],"C" 
jne suite_efface_canauxcom
cmp [ebx+id_emetteur],cx
je ok_efface_canauxcom
cmp [ebx+id_recepteur],cx 
jne suite_efface_canauxcom

ok_efface_canauxcom:
call libmem  
xor ebx,ebx
jmp boucle_efface_canauxcom ;on recommence la purge mémoire depuis le début car une libération de mémoire perturbe la continuité de la mémoire

suite_efface_canauxcom:
add ebx,eax
cmp byte[ebx+type_dm],"F" 
jne boucle_efface_canauxcom


pop es
pop ds
popad
ret


;**********************************************************************************************
irqtmp:
cli
push eax
push ds
mov ax,seldat
mov ds,ax
inc dword[cptsf]     ;incrémente le compteur global
dec byte[cpttc]      ;décrémente le compteur de la t?che en cours
jz commutation         ;si arrivé a zéro, on commute

finirqtmp:
mov al,20h
out 20h,al   ;(End Of Interrupt)
pop ds
pop eax
sti
iret




;*********************
commutation:    
push eax         ;sauvegarde complète des registres
push ebx
push ecx
push edx
push esi
push edi
push ebp
push ds
push es
push fs
push gs
mov ax,seldat
mov ds,ax
mov ax,selramh
mov es,ax

;test si on est une tache normal ou la tache système
cmp word[id_tache_exec],0
jne sauv_tache_norm

mov [sauv_esp_t0],esp  ;sauvegarde de l'offset de la pile de la tache zéro
xor ebx,ebx
jmp selection_tache_suivante

sauv_tache_norm:      ;sauvegarde des piles d'une tache normale
mov ebx,[ad_tache_exec]
es
mov [ebx+sauv_esp0],esp  


selection_tache_suivante:
cmp word[tache_force],0
je boucle_tache_suivante

xor edx,edx            ;recherche du descripteur de tache avec id spécifique
xchg dx,[tache_force]
xor ebx,ebx

boucle_tache_sp:
es
mov eax,[ebx+4]
es
cmp word[ebx],"DM"
jne erreur_org_mem
test eax,0Fh
jnz erreur_org_mem
cmp eax,0
je erreur_org_mem
add ebx,eax
es
cmp byte[ebx+2],"F" ;si on arrive a la fin des descripteur mémoire on revient a la tache 0
je rest_tache_sp
es
cmp byte[ebx+2],"T"
jne boucle_tache_sp
es
cmp [ebx+id_tache],dx
jne boucle_tache_sp
jmp restauration_tache


boucle_tache_suivante:    ;recherche du descripteur de tache suivant
es
mov eax,[ebx+4]
es
cmp word[ebx],"DM"
jne erreur_org_mem
test eax,0Fh
jnz erreur_org_mem
cmp eax,0
je erreur_org_mem
add ebx,eax
es
cmp byte[ebx+2],"F" ;si on arrive a la fin des descripteur mémoire on revient a la tache 0
je rest_tache_sp
es
cmp byte[ebx+2],"T"
jne boucle_tache_suivante



;*********************************restauration d'une tache normale
restauration_tache:
;maj info de la tache
mov [ad_tache_exec],ebx
es
mov al,[ebx+temp_exec_tache]
mov byte[cpttc],al
es
mov ax,[ebx+id_tache]
mov [id_tache_exec],ax

;restauration de la LDT
es
lldt [ebx+sel_ldt_tache]

;restauration des pile
es
mov esp,[ebx+sauv_esp0]
es
mov eax,[ebx+to_pile_fe]
sub eax,4
mov [tss_sauv_esp0],eax
mov ax,sel_pilet0             
mov ss,ax
jmp fin_com_tache


;*******************************************
erreur_org_mem:    ;detection d'une erreur dans l'organisation de la mémoire haute lors d'un basculement de tache

mov eax,[nb_ram]
es
mov dword[ebx],"DMV?"
es
mov dword[eax],"DMF?"
sub eax,ebx
es
mov [ebx+4],eax

mov cl,48
call affmsgsyst


;***************************
rest_tache_sp:           ;restautation de la tache zéro
;maj info de la tache
mov dword[ad_tache_exec],0
mov word[id_tache_exec],0
mov byte[cpttc],1          ;1x2,5ms alloué a la tache principale, oui c'est peu

;restauration de la pile
mov ax,selpil
mov ss,ax
mov esp,[sauv_esp_t0]


fin_com_tache:   ;restauration complète des registres
pop gs
pop fs
pop es
pop ds
pop ebp
pop edi
pop esi
pop edx
pop ecx
pop ebx
pop eax

jmp finirqtmp 



;************************************************************************************************************************************
maj_ldtache:   ;crée/met a jour les dscripteurs de segment de la LDT pointé par ds:esi
push ds


mov ebx,[esi+ad_code_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+to_code_fe]        
dec ecx
mov eax,esi
add eax,ldt_tache+8
mov dl,0BEh       ;segment de code lisible en 32bits ring 3
call creeds

mov ebx,[esi+ad_pile0_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+to_pile_fe]        
dec ecx
mov eax,esi
add eax,ldt_tache+32
mov dl,002h       ;segment de données en lect/ecr ring 0
call creeds

mov ebx,[esi+ad_pile1_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+to_pile_fe]        
dec ecx
mov eax,esi
add eax,ldt_tache+40
mov dl,012h       ;segment de données en lect/ecr ring 1
call creeds

mov ebx,[esi+ad_pile2_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+to_pile_fe]        
dec ecx
mov eax,esi
add eax,ldt_tache+48
mov dl,022h       ;segment de données en lect/ecr ring 2
call creeds

mov ebx,[esi+ad_pile3_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+to_pile_fe]        
dec ecx
mov eax,esi
add eax,ldt_tache+56
mov dl,032h       ;segment de données en lect/ecr ring 3
call creeds

mov ebx,[esi+ad_data1_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+tt_data1_dt]        
cmp ecx,0
je ignore_segd1
dec ecx
mov eax,esi
add eax,ldt_tache+64
mov dl,032h       ;segment de données en lect/ecr ring 3
call creeds
ignore_segd1:

mov ebx,[esi+ad_data2_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+tt_data2_dt]        
cmp ecx,0
je ignore_segd2
dec ecx
mov eax,esi
add eax,ldt_tache+72
mov dl,032h       ;segment de données en lect/ecr ring 3
call creeds
ignore_segd2:

mov ebx,[esi+ad_data3_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+tt_data3_dt]        
cmp ecx,0
je ignore_segd3
dec ecx
mov eax,esi
add eax,ldt_tache+80
mov dl,032h       ;segment de données en lect/ecr ring 3
call creeds
ignore_segd3:

mov ebx,[esi+ad_data4_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+tt_data4_dt]
cmp ecx,0
je ignore_segd4
dec ecx        
mov eax,esi
add eax,ldt_tache+88
mov dl,032h       ;segment de données en lect/ecr ring 3
call creeds
ignore_segd4:

xor eax,eax
mov ax,[esi+sel_ldt_tache]
mov ebx,esi  ;adresse
add ebx,100000h+ldt_tache
mov ecx,0FFh  ;limite   
mov dx,selgdt
mov ds,dx     
mov dl,02h       ;segment d'une LDT (sans le bit système a 0)
call creeds
and byte[eax+5],0EFh ;on met le bit systeme a zéro (sinon le système pense que c'est un simple descripteur de segment de données

pop ds
ret









