;fonction pour communication inter/tache int 65h

;al=0 ouverture canal
;al=1 fermeture canal
;al=2 tester présence nouveau canaux
;al=3 tester donnée disponible sur canaux
;al=4 lire donnée sur canal
;al=5 envoyer donnée sur canal
;al=6 lire descripteur
;al=7 ecrire descripteur

cmp al,0
je sf_com_ouverture
cmp al,2
je sf_com_nouv_cn

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
je sf_com_ok
fs
cmp [ebx+id_recepteur],dx
jne sf_com_er_parami

sf_com_ok:
cmp al,1
je sf_com_fermeture
cmp al,3
je sf_com_test
cmp al,4
je sf_com_lecture
cmp al,5
je sf_com_ecriture
cmp al,6
je sf_com_lecture_descripteur
cmp al,7
je sf_com_ecriture_descripteur

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
add ecx,10h
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
pop fs
pop es
pop ds
popad
xor eax,eax
iret





;**************************************************************************************************
sf_com_lecture:
mov ax,selramh
mov ds,ax







type0_er_sf_com_lecture:


mov eax,[ebx+po_zter_ecr] 
cmp eax,[ebx+po_zter_lec]
ja temp1_sf_com_lecture
add eax,[ebx+to_zter]
temp1_sf_com_lecture:
sub eax,[ebx+po_zter_lec]    ;eax=taille occupé


cmp eax,ecx
ja temp2_sf_com_lecture
mov ecx,eax
temp2_sf_com_lecture:     ;ecx=taille a transferer



mov eax,[ebx+po_zter_lec]
add eax,ecx
cmp eax,[ebx+to_zter]
ja deb_type0_er_sf_com_lecture



mov esi,ebx
add esi,[ebx+ad_zter]
add esi,[ebx+po_zter_lec]
rep movsb

pop fs
pop es
pop ds
popad
xor eax,eax
iret




deb_type0_er_sf_com_lecture:
mov eax,[ebx+to_zter]
sub eax,[ebx+po_zter_lec]
xchg eax,ecx
sub eax,ecx

mov esi,ebx
add esi,[ebx+ad_zter]
add esi,[ebx+po_zter_lec]
rep movsb

mov ecx,eax
mov esi,ebx
add esi,[ebx+ad_zter]
rep movsb

pop fs
pop es
pop ds
popad
xor eax,eax
iret














;**************************************************************************************************
sf_com_ecriture:
pop fs
pop es
pop ds
popad
xor eax,eax
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
rep movsb ;ds ed
pop fs
pop es
pop ds
popad
xor eax,eax
iret




