;fonction pour communication inter/tache int 65h

;al=0 ouverture canal
;al=1 fermeture canal
;al=2 tester présence nouveau canaux
;al=3 tester donnée disponible sur canaux
;al=4 lire descripteur
;al=5 ecrire descripteur
;al=6 lire donnée sur canal
;al=7 envoyer donnée sur canal

cmp al,0
je sf_com_ouverture
cmp al,2
je sf_com_nouv_cn
cmp al,3
je sf_com_test

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
jne sf_com_rc_ok





sf_com_rc_ok:
cmp al,1
je sf_com_fermeture

cmp al,4
je sf_com_lecture_descripteur
cmp al,5
je sf_com_ecriture_descripteur
cmp al,6
je sf_com_lecture_rc
cmp al,7
je sf_com_ecriture_rc
jmp sf_com_er_parami



sf_com_em_ok:
cmp al,1
je sf_com_fermeture
cmp al,4
je sf_com_lecture_descripteur
cmp al,5
je sf_com_ecriture_descripteur
cmp al,6
je sf_com_lecture_em
cmp al,7
je sf_com_ecriture_em

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
;esi=taille de la zone tampon d'envoie
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
add ecx,esi
add ecx,edi
add ecx,30h
call resmem
jc erreur_sf_com_ouverture


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
or dx,4000h
mov [ebx+at_canal],dx
mov [ebx+to_zter],esi
mov [ebx+to_ztre],edi

mov eax,[ebx+to_descr_com]
add eax,ad_descr_com
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
sf_com_nouv_cn:

push edx
push ds

mov ax,seldat
mov ds,ax
mov dx,[id_tache_exec]
mov ax,selramh
mov ds,ax

xor ebx,ebx
boucle_sf_com_nouv_cn:
cmp byte[ebx+type_dm],"V"
je erreur_sf_com_nouv_cn 
cmp byte[ebx+type_dm],"C"
jne passe_sf_com_nouv_cn 
cmp [ebx+id_recepteur],dx
jne passe_sf_com_nouv_cn 
test word[ebx+at_canal],8000h
jz passe_sf_com_nouv_cn 

and word[ebx+at_canal],7FFFh
pop ds
pop edx
xor eax,eax
iret

passe_sf_com_nouv_cn:
mov eax,[ebx+4]
add ebx,eax
jmp boucle_sf_com_nouv_cn

erreur_sf_com_nouv_cn:
pop ds
pop edx
xor ebx,ebx
mov eax,cer_anc
iret



;**************************************************************************************************
sf_com_test:

;$$$$$$$$$$$$$$$$$$$$$$$

pop fs
pop es
pop ds
popad
xor eax,eax
iret


;**************************************************************************************************
sf_com_fermeture:

call libmem
jc sf_com_er_parami

pop fs
pop es
pop ds
popad
mov eax,eax
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


fs
test word[ebx+at_canal],4000h
jz fin_sf_com_ecriture_descripteur
fs
and word[ebx+at_canal],3FFFh
fs
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
mov al,[ebx+at_canal]
and al,07h
cmp al,0
je sf_com_lecture_type0 
cmp al,1
je sf_com_lecture_type1 
jmp sf_com_er_parami 

sf_com_lecture_type1:

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

cmp ecx,[com_tempo]
jl sf_com_lecture_type1_err




mov ecx,[com_tempo]


sf_com_lecture_type0:

call sf_com_lecture_transfert


pop fs
pop es
pop ds
ss
mov [esp+24],ebp    ;met la quantite dans ecx
popad
xor eax,eax
iret



sf_com_lecture_type1_err:
mov [edx+po_ztcom_lec],eax
pop fs
pop es
pop ds
popad
xor ecx,ecx
mov ecx,cer_pasm
iret



;to_ztcom      equ 00h ;taille de la zone com
;ad_ztcom      equ 04h ;adresse de la zone com   
;po_ztcom_lec  equ 08h ;pointeur de lecture dans la zt
;po_ztcom_ecr  equ 0Ch ;pointeur d'ecriture dans la zt



;*******************************************************************************
sf_com_lecture_transfert:
pushad
mov ebp,[edx+po_ztcom_ecr] 
cmp ebp,[edx+po_ztcom_lec]
ja temp1_sf_com_lecture
add ebp,[edx+to_ztcom]
temp1_sf_com_lecture:
sub ebp,[edx+po_ztcom_lec]    ;ebp=taille occupé
;cmp ebp,0
;jne sf_com_lecture_test





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
mov esi,[edx+po_ztcom_lec]
popad
ret









;**************************************************************************************************
sf_com_ecriture_rc:
mov dx,selramh
mov es,dx
mov edx,ebx
add edx,to_ztre
jmp sf_com_ecriture

sf_com_ecriture_em:
mov dx,selramh
mov ds,dx
mov edx,ebx
add edx,to_zter

sf_com_ecriture:
mov al,[ebx+at_canal]
and al,07h
cmp al,0
je sf_com_ecriture_type0 
cmp al,1
je sf_com_ecriture_type1 
jmp sf_com_er_parami 







sf_com_ecriture_type1:
es
mov ebp,[edx+po_zter_ecr] 
es
cmp ebp,[edx+po_zter_lec]
ja temp1_sf_com_ecriture
es
add ebp,[edx+to_zter]
temp1_sf_com_ecriture:
es
sub ebp,[edx+po_zter_ecr]    ;ebp=taille libre
sub ebp,4
cmp ecx,ebp
jl sf_com_ecriture_type1_ok 

pop fs
pop es
pop ds
popad
mov eax,cer_ztp
iret



sf_com_ecriture_type1_ok:
es
mov [com_tempo],ecx
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

sf_com_ecriture_type0:
call sf_com_ecriture_transfert

pop fs
pop es
pop ds
popad
xor eax,eax
iret





;******************************************************************************
sf_com_ecriture_transfert:
pushad
es
mov ebp,[edx+po_zter_lec] 
es
cmp ebp,[edx+po_zter_ecr]
ja temp2_sf_com_ecriture
es
add ebp,[edx+to_zter]
temp2_sf_com_ecriture:
es
sub ebp,[edx+po_zter_ecr]    ;ebp=taille libre
cmp ecx,ebp
jl sf_com_ecriture_transfert_ok 
popad
mov eax,cer_ztp
iret




sf_com_ecriture_transfert_ok:
mov eax,[edx+po_zter_ecr]
add eax,ecx
cmp eax,[edx+to_zter]
ja sf_com_ecriture_transfert2


mov edi,ebx
es
add edi,[edx+ad_zter]
es
add edi,[edx+po_zter_ecr]
cld
rep movsb
jmp sf_com_ecriture_fin


sf_com_ecriture_transfert2:
es
mov eax,[edx+to_zter]
es
sub eax,[edx+po_zter_ecr]
xchg eax,ecx
sub eax,ecx

mov edi,ebx
es
add edi,[edx+ad_zter]
es
add edi,[edx+po_zter_ecr]
cld
rep movsb

mov ecx,eax
mov edi,ebx
es
add edi,[edx+ad_zter]
cld
rep movsb

sf_com_ecriture_fin:
sub edi,ebx
es
sub edi,[edx+ad_zter]
es
mov edi,[edx+po_zter_ecr]

popad
xor eax,eax
iret












