;fonction pour communication inter/tache int 65h

;al=0  ouverture canal
;al=1  fermeture canal
;al=2  tester changement descripteur
;al=3  tester donnée disponible sur canaux
;al=4  lire descripteur
;al=5  ecrire descripteur
;al=6  lire donnée sur canal
;al=7  envoyer donnée sur canal
;al=8  attendre changement descripteur sur canal
;al=9  attendre donnée disponible sur canal
;al=10 lire info sur canal

cmp al,0
je sf_com_ouverture
cmp al,2
je sf_com_test_cd
cmp al,3
je sf_com_test_dd

pushad
push ds
push es
push fs
push eax
mov ax,seldat
mov fs,ax
fs
mov dx,[id_tache_exec]
mov ax,selramh
mov fs,ax
pop eax

fs
cmp word[ebx],"DM"
jne sf_com_er_parami
fs
cmp byte[ebx+type_dm],"C"
jne sf_com_er_parami
fs
cmp [ebx+id_emetteur],dx
je sf_com_em_ok
fs
cmp [ebx+id_recepteur],dx
jne sf_com_er_parami


sf_com_rc_ok:
cmp al,1
je sf_com_fermeture_rc
cmp al,4
je sf_com_lecture_descripteur
cmp al,5
je sf_com_ecriture_descripteur
cmp al,6
je sf_com_lecture_rc
cmp al,7
je sf_com_ecriture_rc
cmp al,8
je sf_com_attente_cd
cmp al,9
je sf_com_attente_dd
cmp al,10
je sf_com_info_canal_rc
jmp sf_com_er_parami


sf_com_em_ok:
cmp al,1
je sf_com_fermeture_em
cmp al,4
je sf_com_lecture_descripteur
cmp al,5
je sf_com_ecriture_descripteur
cmp al,6
je sf_com_lecture_em
cmp al,7
je sf_com_ecriture_em
cmp al,8
je sf_com_attente_cd
cmp al,9
je sf_com_attente_dd
cmp al,10
je sf_com_info_canal_em

sf_com_er_parami:
pop fs
pop es
pop ds
popad
mov eax,cer_parami
iret




;**************************************************************************************************
sf_com_ouverture:
;bx=ID de la tache avec qui communiquer
;ecx=taille du descripteur
;edx=attribut canal
;esi=taille de la zone tampon d'envoie ou masque d'alignement mode 2
;edi=taille de la zone tampon de reception
;sortie:
;ebx=adresse de la zone dans la mémoire haute
;edx=adresse physique du descripteur


push ecx
push esi
push edi
push ebp
push ds

push ecx
push ebx

mov eax,edx
and eax,0Fh
cmp eax,2
je sf_com_ouverture_mode2

add ecx,esi
add ecx,edi
add ecx,30h
call resmem
jc erreur_sf_com_ouverture
jmp suite_sf_com_ouverture


sf_com_ouverture_mode2:  ;en mode 2 pas de zone d'échange, juste un descripteur avec possibilité d'aligner la mémoire
mov eax,esi
or eax,0Fh
add ecx,30h
mov edi,ad_descr_com
call resmemgo
jc erreur_sf_com_ouverture
xor esi,esi
xor edi,edi

suite_sf_com_ouverture:
mov ax,seldat
mov ds,ax
mov cx,[id_tache_exec]
mov ax,selramh
mov ds,ax
mov [ebx+id_emetteur],cx

mov byte[ebx+type_dm],"C"
pop eax

mov [ebx+id_recepteur],ax
pop eax
mov [ebx+to_descr_com],eax
mov [ebx+at_canal],dx
mov [ebx+to_zter],esi
mov [ebx+to_ztre],edi

mov eax,ad_descr_com
add eax,[ebx+to_descr_com]
mov [ebx+ad_zter],eax
add eax,[ebx+to_zter]
mov [ebx+ad_ztre],eax

xor eax,eax
mov [ebx+po_zter_lec],eax
mov [ebx+po_zter_ecr],eax
mov [ebx+po_ztre_lec],eax
mov [ebx+po_ztre_ecr],eax

pop ds
pop ebp
pop edi
pop esi
pop ecx
xor eax,eax
mov edx,ebx
add edx,100000h+ad_descr_com
iret

erreur_sf_com_ouverture:
pop ebx
pop ecx
pop ebp
pop edi
pop esi
pop ecx
xor ebx,ebx
xor edx,edx
mov eax,cer_parami
iret



;**************************************************************************************************
sf_com_fermeture_em:
fs
mov word[ebx+id_emetteur],0
fs
or word[ebx+at_canal],1000h   ;b12=canal terminé par emeteur, dès que la zone vers recepteur est vide on supprime le canal
mov dx,selramh
mov ds,dx
mov edx,ebx
add edx,to_zter
call sf_com_to
cmp ebp,0
jne fin_sf_com_fermeture
jmp ok_sf_com_fermeture



sf_com_fermeture_rc:
fs
mov word[ebx+id_recepteur],0
fs
or word[ebx+at_canal],2000h     ;b13=canal terminé par recepteur, dès que la zone vers emeteur est vide on supprime le canal
mov dx,selramh
mov ds,dx
mov edx,ebx
add edx,to_ztre
call sf_com_to
cmp ebp,0
jne fin_sf_com_fermeture


ok_sf_com_fermeture:
call libmem
jc sf_com_er_parami
fin_sf_com_fermeture:
pop fs
pop es
pop ds
popad
mov eax,eax
iret




;**************************************************************************************************
sf_com_test_cd:  ;test si un descripteur de canal a été modifié

push edx
push ds

mov ax,seldat
mov ds,ax
mov dx,[id_tache_exec]
mov ax,selramh
mov ds,ax

xor ebx,ebx
boucle_sf_com_test_cd:
cmp byte[ebx+type_dm],"F"
je stop_sf_com_test_cd
cmp byte[ebx+type_dm],"C"
jne passe_sf_com_test_cd 

cmp [ebx+id_recepteur],dx
jne test2_sf_com_test_cd 
test word[ebx+at_canal],4000h
jz passe_sf_com_test_cd
pop ds
pop edx
mov eax,cer_ddi
iret

test2_sf_com_test_cd:
cmp [ebx+id_emetteur],dx
jne passe_sf_com_test_cd 
test word[ebx+at_canal],8000h
jz passe_sf_com_test_cd 
pop ds
pop edx
mov eax,cer_ddi
iret


passe_sf_com_test_cd:
mov eax,[ebx+4]
add ebx,eax
jmp boucle_sf_com_test_cd

stop_sf_com_test_cd:
pop ds
pop edx
xor ebx,ebx
mov eax,cer_dnd
iret



;**************************************************************************************************
sf_com_test_dd:

push edx
push ds

mov ax,seldat
mov ds,ax
mov dx,[id_tache_exec]
mov ax,selramh
mov ds,ax

xor ebx,ebx
boucle_sf_com_test_dd:
cmp byte[ebx+type_dm],"F"
je erreur_sf_com_test_dd
cmp byte[ebx+type_dm],"C"
jne passe_sf_com_test_dd

cmp [ebx+id_recepteur],dx
jne test2_sf_com_test_dd 
mov eax,[ebx+po_zter_lec]
cmp eax,[ebx+po_zter_ecr]
je passe_sf_com_test_dd
pop ds
pop edx
mov eax,cer_ddi
iret

test2_sf_com_test_dd:
cmp [ebx+id_emetteur],dx
jne passe_sf_com_test_dd 
mov eax,[ebx+po_ztre_lec]
cmp eax,[ebx+po_ztre_ecr]
je passe_sf_com_test_dd 
pop ds
pop edx
mov eax,cer_ddi
iret

passe_sf_com_test_dd:
mov eax,[ebx+4]
add ebx,eax
jmp boucle_sf_com_test_dd

erreur_sf_com_test_dd:
pop ds
pop edx
xor ebx,ebx
mov eax,cer_dnd
iret



;**************************************************************************************************
sf_com_lecture_descripteur:
;ebx=adresse de la zone
;ecx=quantité a lire
;esi=adresse dans la zone
;es:edi=desitination

mov eax,ecx
fs
cmp eax,[ebx+to_descr_com]
ja sf_com_er_parami
add eax,esi
fs
cmp eax,[ebx+to_descr_com]
ja sf_com_er_parami


mov ax,selramh
mov ds,ax
add esi,ad_descr_com
add esi,ebx
cld
rep movsb ;ds ed


mov ax,seldat
mov fs,ax
fs
mov dx,[id_tache_exec]

cmp [ebx+id_recepteur],dx
je  sf_com_desc_lec_rc

and word[ebx+at_canal],07FFFh
jmp fin_sf_com_lecture_descripteur 

sf_com_desc_lec_rc:
and word[ebx+at_canal],0BFFFh

fin_sf_com_lecture_descripteur:
pop fs
pop es
pop ds
popad
xor eax,eax
iret






;**************************************************************************************************
sf_com_ecriture_descripteur:

;ebx=adresse de la zone
;ecx=quantité a lire
;edi=adresse dans la zone
;ds:esi=origine des données

mov eax,ecx
fs
cmp eax,[ebx+to_descr_com]
ja sf_com_er_parami
add eax,edi
fs
cmp eax,[ebx+to_descr_com]
ja sf_com_er_parami

mov ax,selramh
mov es,ax
add edi,ad_descr_com
add edi,ebx
cld
rep movsb ;ds ed

es
and word[ebx+at_canal],3FFFh
mov ax,seldat
mov fs,ax
fs
mov dx,[id_tache_exec]

es
cmp [ebx+id_recepteur],dx
je  sf_com_desc_modif_rc

es
or  word[ebx+at_canal],4000h
jmp fin_sf_com_ecriture_descripteur 

sf_com_desc_modif_rc:
es
or  word[ebx+at_canal],8000h

fin_sf_com_ecriture_descripteur:
pop fs
pop es
pop ds
popad
xor eax,eax
iret





;*******************************************************************************************************************************
sf_com_lecture_rc:
mov dx,selramh
mov ds,dx
mov edx,ebx
add edx,to_zter

jmp sf_com_lecture

sf_com_lecture_em:
mov dx,selramh
mov ds,dx
mov edx,ebx
add edx,to_ztre


sf_com_lecture:
cmp dword[edx],0
je sf_com_er_parami
mov al,[ebx+at_canal]
and al,07h
cmp al,0
je sf_com_lecture_type0 
cmp al,1
je sf_com_lecture_type1 
jmp sf_com_er_parami 



sf_com_lecture_type0:
call sf_com_to
cmp ebp,0
je sf_com_lecture0
cmp ecx,ebp
jbe sf_com_lecture_ok 
mov ecx,ebp

sf_com_lecture_ok:
call sf_com_lecture_transfert
pop fs
pop es
pop ds
ss
mov [esp+24],ecx    ;met la quantite dans ecx
popad
xor eax,eax
iret



sf_com_lecture_type1:
call sf_com_to
cmp ebp,0
je sf_com_lecture0
cmp ebp,4
jb sf_com_lecture_type1_err1



mov eax,[edx+po_ztcom_lec]
push ecx
push edi
push es
mov di,selramh
mov es,di
mov edi,ebx
add edi,com_tempo
mov ecx,4
call sf_com_lecture_transfert
pop es
pop edi
pop ecx
cmp ecx,[ebx+com_tempo]
jb sf_com_lecture_type1_err2
mov ecx,[ebx+com_tempo]
jmp sf_com_lecture_ok


sf_com_lecture0:
sub edx,ebx       ;test si le canal as été marqué comme a effacer
cmp edx,to_ztre
je sf_com_lecture0_ztre 

fs
test word[ebx+at_canal],1000h  
jz sf_com_lecture0_sansfermeture 
jmp sf_com_lecture0_fermeture 

sf_com_lecture0_ztre:
fs
test word[ebx+at_canal],2000h  
jz sf_com_lecture0_sansfermeture 

sf_com_lecture0_fermeture:
call libmem
sf_com_lecture0_sansfermeture:
pop fs
pop es
pop ds
popad
xor ecx,ecx
xor eax,eax
iret


sf_com_lecture_type1_err1:        ;erreur dans la fifo
pop fs
pop es
pop ds
popad
xor ecx,ecx
mov eax,cer_ers
iret



sf_com_lecture_type1_err2:        ;pas assez de mémoire pour reçevoir les données disponible
fs
mov [edx+po_ztcom_lec],eax
pop fs
pop es
pop ds
popad
xor ecx,ecx
mov eax,cer_pasm
iret







;**************************************************************************************************
sf_com_ecriture_rc:

fs
mov dx,[ebx+id_emetteur]
call prio_tache
mov dx,selramh
mov es,dx
mov edx,ebx
add edx,to_ztre
jmp sf_com_ecriture

sf_com_ecriture_em:
fs
mov dx,[ebx+id_recepteur]
call prio_tache
mov dx,selramh
mov es,dx
mov edx,ebx
add edx,to_zter

sf_com_ecriture:
es
cmp dword[edx],0
je sf_com_er_parami
es
mov al,[ebx+at_canal]
and al,07h
cmp al,0
je sf_com_ecriture_type0 
cmp al,1
je sf_com_ecriture_type1 
jmp sf_com_er_parami 


sf_com_ecriture_type0:
call sf_com_tl
cmp ecx,ebp
ja sf_com_ecriture_err1

sfcom_ecriture_ok:
call sf_com_ecriture_transfert
int 62h  ;on bascule de tache pour forcer l'execution de la tache receptrice
pop fs
pop es
pop ds
popad
xor eax,eax
iret

sf_com_ecriture_type1:
call sf_com_tl
mov eax,ecx
add eax,4
cmp eax,ebp
ja sf_com_ecriture_err1

fs
mov [ebx+com_tempo],ecx
push ecx
push esi
push ds
mov si,selramh
mov ds,si
mov ecx,4
mov esi,ebx
add esi,com_tempo
call sf_com_ecriture_transfert
pop ds
pop esi
pop ecx
jmp sfcom_ecriture_ok

sf_com_ecriture_err1:
pop fs
pop es
pop ds
popad
mov eax,cer_ztp
xor ecx,ecx
iret











;*******************************************************************************
sf_com_lecture_transfert:
pushad
mov eax,[edx+po_ztcom_lec]
add eax,ecx
cmp eax,[edx+to_ztcom]
ja sf_com_lecture_transfert2


mov esi,ebx
add esi,[edx+ad_ztcom]
add esi,[edx+po_ztcom_lec]
cld
rep movsb
jmp sf_com_lecture_fin


sf_com_lecture_transfert2:
mov eax,[edx+to_ztcom]
sub eax,[edx+po_ztcom_lec]
xchg eax,ecx
sub eax,ecx

mov esi,ebx
add esi,[edx+ad_ztcom]
add esi,[edx+po_ztcom_lec]
cld
rep movsb

mov ecx,eax
mov esi,ebx
add esi,[edx+ad_ztcom]
cld
rep movsb

sf_com_lecture_fin:
sub esi,ebx
sub esi,[edx+ad_ztcom]
mov [edx+po_ztcom_lec],esi
popad
ret




;******************************************************************************
sf_com_ecriture_transfert:
pushad

es
mov eax,[edx+po_ztcom_ecr]
add eax,ecx
es
cmp eax,[edx+to_ztcom]
ja sf_com_ecriture_transfert2


mov edi,ebx
es
add edi,[edx+ad_ztcom]
es
add edi,[edx+po_ztcom_ecr]
cld
rep movsb
jmp sf_com_ecriture_fin


sf_com_ecriture_transfert2:
es
mov eax,[edx+to_ztcom]
es
sub eax,[edx+po_ztcom_ecr]
xchg eax,ecx
sub eax,ecx

mov edi,ebx
es
add edi,[edx+ad_ztcom]
es
add edi,[edx+po_ztcom_ecr]
cld
rep movsb

mov ecx,eax
mov edi,ebx
es
add edi,[edx+ad_ztcom]
cld
rep movsb

sf_com_ecriture_fin:
sub edi,ebx
es
sub edi,[edx+ad_ztcom]
es
mov [edx+po_ztcom_ecr],edi

popad
ret



;*************************
sf_com_to:
fs
mov ebp,[edx+po_ztcom_ecr] 
fs
cmp ebp,[edx+po_ztcom_lec]
jae sf_com_to_1
fs
add ebp,[edx+to_ztcom]
sf_com_to_1:
fs
sub ebp,[edx+po_ztcom_lec]    ;ebp=taille occupé
ret

;***********************
sf_com_tl:
push eax
fs
mov eax,[edx+to_ztcom]
call sf_com_to 
sub eax,ebp
dec eax
mov ebp,eax                ;ebp=taille libre
pop eax
ret





;****************************************************************************************
sf_com_attente_cd:
mov ax,seldat
mov fs,ax
mov ax,selramh
mov ds,ax
fs
mov dx,[id_tache_exec]
fs
add ecx,[cptsf]


boucle_sf_com_attente_cd:
cmp [ebx+id_recepteur],dx
jne test2_sf_com_attente_cd 
test word[ebx+at_canal],4000h
jz passe_sf_com_attente_cd
pop fs
pop es
pop ds
popad
mov eax,cer_ddi
iret

test2_sf_com_attente_cd:
cmp [ebx+id_emetteur],dx
jne erreur_sf_com_attente_cdd
test word[ebx+at_canal],8000h
jz passe_sf_com_attente_cd 
pop fs
pop es
pop ds
popad
mov eax,cer_ddi
iret

passe_sf_com_attente_cd:
int 62h
fs
cmp [cptsf],ecx 
jb boucle_sf_com_attente_cd  

pop fs
pop es
pop ds
popad
mov eax,cer_dnd
iret


erreur_sf_com_attente_cdd:
pop fs
pop es
pop ds
popad
mov eax,cer_dnd
iret




;******************************************************************************************
sf_com_attente_dd:           ;ecx*2.5ms= temp maximum a attendre
mov ax,seldat
mov fs,ax
mov ax,selramh
mov ds,ax
fs
mov dx,[id_tache_exec]
fs
add ecx,[cptsf]


boucle_sf_com_attente_dd:
cmp [ebx+id_recepteur],dx
jne test2_sf_com_attente_dd 
mov eax,[ebx+po_zter_lec]
cmp eax,[ebx+po_zter_ecr]
je passe_sf_com_attente_dd
pop fs
pop es
pop ds
popad
mov eax,cer_ddi
iret

test2_sf_com_attente_dd:
cmp [ebx+id_emetteur],dx
jne erreur_sf_com_attente_cdd
mov eax,[ebx+po_ztre_lec]
cmp eax,[ebx+po_ztre_ecr]
je passe_sf_com_attente_dd 
pop fs
pop es
pop ds
popad
mov eax,cer_ddi
iret

passe_sf_com_attente_dd:
int 62h
fs
cmp [cptsf],ecx 
jb boucle_sf_com_attente_dd  

pop fs
pop es
pop ds
popad
mov eax,cer_dnd
iret




;************************************************************************************
;bx=ID de la tache avec qui communiquer
;ecx=taille du descripteur
;edx=attribut canal
;esi=taille de la zone tampon d'envoie
;edi=taille de la zone tampon de reception


sf_com_info_canal_rc:
pop fs
pop es
pop ds
popad
push ds
mov ax,selramh
mov ds,ax

mov ax,[ebx+id_emetteur]
mov ecx,[ebx+to_descr_com]
mov edx,[ebx+at_canal]
and edx,1
mov esi,[ebx+to_ztre]
mov edi,[ebx+to_zter]
mov bx,ax
pop ds
xor eax,eax
iret



sf_com_info_canal_em:
pop fs
pop es
pop ds
popad
push ds
mov ax,selramh
mov ds,ax

mov ax,[ebx+id_recepteur]
mov ecx,[ebx+to_descr_com]
mov edx,[ebx+at_canal]
and edx,01
mov esi,[ebx+to_zter]
mov edi,[ebx+to_ztre]
mov bx,ax
pop ds
xor eax,eax
iret




