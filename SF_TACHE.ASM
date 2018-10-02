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
mov al,13
call affcj
jmp pascommande

erreurcommandeparam:
mov cl,8
call affmsgsyst
mov edx,ad_zdc
call affjournal
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
mov [ebx+ad_pile_dt],eax
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




;recherche emplacement disponible et création d'un segment pour la LDT dans la GDT
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



;initialisation de la pile de la tache
mov ax,seldat
mov ds,ax
es
lldt [esi+sel_ldt_tache] ;on charge d'abord la bonne LDT
es
mov edi,[esi+to_pile_fe]
sub edi,4
mov ax,sel_pilet
mov ds,ax

;sauvegarde sur la pile des instruction de retour (int 61h/int 30h)

mov eax,000000001000000010b     ;IF=1         ;flag=ID:VIP  VIF:AC:VM:RF  0:NT:IOPL  OF:DF:IF:TF  SF:ZF:0:AF  0:PF:1:CF
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

;sauvegarde pointeur de la pile
es
mov [esi+sauv_esp],edi

;initialistaion de l'en tête descripteur espace mémoire
es
mov byte[esi+type_dm],"T"

;initialisation du temps d'execution de la tache (temps par defaut)
es
mov byte[esi+temp_exec_tache],10

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
je erreurcommandeparam
jmp boucle1_mtt


;convertit l'id en entier 16 bit
id_mtt:
inc edx
mov eax,101
int 61h
test ecx,0FFFF0000h
jnz erreurcommandeparam

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
je erreurcommandeparam
jmp boucle2_mtt


;convertit le temps en entier 8 bit
tt_mtt:
inc edx
mov eax,100
int 61h
test ecx,0FFFFFF00h
jnz erreurcommandeparam
cmp ecx,0
je erreurcommandeparam

es
mov [ebx+temp_exec_tache],cl ;chargement du nouveau temp
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
je erreurcommandeparam
jmp boucle_stop1

;convertit l'id en entier 16 bit
id_stop:
inc edx
mov eax,101
int 61h
test ecx,0FFFF0000h
jnz erreurcommandeparam


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
jmp pascommande


erreurtachent:
push cx
mov cl,4
call affmsgsyst
pop ax
call affh1j
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
jne tache_suivante
mov byte[nb_zrc],0
mov word[id_tache_af],0
mov dword[ad_tache_af],0
or byte[at_csl],01h ;signale que l'affichage doit être mis a jour
jmp tache_suivante 

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
call libmem  ;désactivé parce que cela cause des bugs
xor ebx,ebx
jmp boucle_efface_canauxcom

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
jnz finirqtmp         ;si arrivé a zéro, on commute

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

mov [sauv_esp0],esp  ;sauvegarde de l'offset de la pile de la tache zéro
xor ebx,ebx
jmp tache_suivante

sauv_tache_norm:      ;sauvegarde de la pile d'une tache normale
mov ebx,[ad_tache_exec]
es
mov [ebx+sauv_esp],esp  



tache_suivante:    ;recherche du descripteur de tache suivant
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
jne tache_suivante

;*********************************restauration d'une tache normale
;maj info de la tache
mov [ad_tache_exec],ebx
es
mov al,[ebx+temp_exec_tache]
mov byte[cpttc],al
es
mov ax,[ebx+8]
mov [id_tache_exec],ax

;restauration de la LDT
es
lldt [ebx+sel_ldt_tache]

;restauration de la pile
es
mov esp,[ebx+sauv_esp]
mov ax,sel_pilet             
mov ss,ax
jmp fin_com_tache


;*******************************************
erreur_org_mem:    ;detection d'une erreur dans l'organisation de la mémoire haute lors d'un basculement de tache

mov eax,[nb_ram]
es
mov dword[eax],"DMF?"
es
mov dword[ebx],"DMV?"
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
mov byte[cpttc],25

;restauration de la pile
mov ax,selpil
mov ss,ax
mov esp,[sauv_esp0]

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

finirqtmp:
mov al,20h
out 20h,al   ;(End Of Interrupt)
pop ds
pop eax
sti
iret


;************************************************************************************************************************************
maj_ldtache:   ;crée/met a jour les dscripteurs de segment de la LDT pointé par ds:esi
push ds

mov ebx,[esi+ad_pile_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+to_pile_fe]        
dec ecx
mov eax,esi
add eax,ldt_tache+0
mov dl,002h       ;segment de données en lect/ecr ring 0
call creeds

mov ebx,[esi+ad_code_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+to_code_fe]        
dec ecx
mov eax,esi
add eax,ldt_tache+8
mov dl,08Eh       ;segment de code lisible en 32bits ring 0
call creeds

mov ebx,[esi+ad_data1_dt]
add ebx,esi
add ebx,100000h    ;ajoute 1Mo
mov ecx,[esi+tt_data1_dt]        
cmp ecx,0
je ignore_segd1
dec ecx
mov eax,esi
add eax,ldt_tache+16
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
add eax,ldt_tache+24
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
add eax,ldt_tache+32
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
add eax,ldt_tache+40
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









