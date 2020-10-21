
;****************************************************************************
;lire et ecrire un secteur                       ****************************
liresecteur:
call aj_acces_disque
call lsct
jmp finfonctionfichiererr

ecriresecteur:
call aj_acces_disque
call esct
jmp finfonctionfichiererr

;***********************************************
;numéros de disque:
;01h disquette
;10h à 17h disque ATA
;18h à 1Fh cdrom
;20h à 3Fh disque ahci (projet) 
;40h à 5Fh disque USB 
;6Fh à 7Fh reserve (inutilisé)
;80h à BFh partition 




;***********************************************************************
aj_acces_disque:   ;ajuste les valeur en cas de lecture de partition
push ecx
and ch,0F0h
cmp ch,080h
je modif_partition 
cmp ch,090h
je modif_partition 
cmp ch,0A0h
je modif_partition 
cmp ch,0B0h
je modif_partition 
pop ecx
ret


modif_partition:
pop ecx
push ebx
mov al,ch
sub al,7Fh   ;sub 80h add 1
and eax,03Fh
shl eax,6   ;mul par 64
fs
cmp [ad_descp+eax+8],ebx
jb erreur_acces_partition
and ecx,0FFh
add ebx,ecx
fs
cmp [ad_descp+eax+8],ebx
jb erreur_acces_partition
pop ebx
fs
add ebx,[ad_descp+eax+4]; ajoute l'adresse de début de partition au numéros de secteur
fs
mov ch,[ad_descp+eax+1]  ;change le code
ret


erreur_acces_partition:
pop ebx
pop ecx
mov ch,0
ret




;******************************************************************************************
lsct:         ;lire  un secteur                                ****************************
	      ;ebx=numéros de secteur
	      ;ch=nø de disque
	      ;cl=nombre de secteur a lire 
	      ;es:edi zone de destination
pushad
push ds
push es
push fs
push gs
cmp ch,01h
je lecdsq
cmp ch,0Fh
je lecdbios
mov al,ch
and al,0F8h
cmp al,10h
je lecata
cmp al,18h
je lecatapi
mov al,ch
and al,0E0h
;cmp al,20h
;je lecsata
cmp al,40h
je lecusb
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret


lecdsq:
fs
test byte[at_fc_fichier],10h    ;test si le lecteur disquette est présent
jz erreurdsq
fs
test byte[at_fc_fichier],04h    ;test si le moteur de la disquette est déja allumé
jnz motdjal1
push ecx
mov dx,3F2h     ;allume le moteur 
mov al,1Ch
out dx,al
fs
mov ecx,[cptsf]    ;attend 500ms que le moteur soit V correcte
add ecx,200
bclatm1:
int 62h
fs
cmp [cptsf],ecx
jb bclatm1
pop ecx
motdjal1:
fs
mov eax,[cptsf]   ;fixe le délais pour l'arret du moteur disquette
add eax,12000      ;30 secondes
fs
mov [temp_moteur_disq],eax
fs
or byte[at_fc_fichier],04h

fs
mov byte[essai_dsq],3   ;3 réessais de lecture


blecdsq:
push cx
push ebx
push edi
push ebx
mov ebx,30000h+zt_disquette     ;configuration dma 2 pour transferer les données
mov cx,511
mov ah,044h     ;ecriture par le périphérique   en single mode
call inidma2
pop ebx

mov ax,bx
fs
mov cx,[sec_cyl_disq]   ;secteur par cylindre
xor dx,dx
div cx

mov bx,ax         
mov ax,dx
fs
mov cx,[sec_piste_disq]   ;secteur par piste
xor dx,dx
div cx         
inc dx        ;bx=piste ax=tête dx=secteur
mov dh,al     ;dh=tête dl=secteur
mov bh,al     
shl bh,2      ;bh=lec&tête bl=cylindre/piste

call placetete

mov al,66h    ;lecture double densité et sans lire les deleted adress marks 
call envfdc
mov al,bh    ;lecteur & tête 
call envfdc
mov al,bl     ;cylindre/piste
call envfdc
mov al,dh     ;tête
call envfdc
mov al,dl     ;secteur  (commence a 1)
call envfdc
mov al,02h     ;taille du secteur 02=512
call envfdc
mov al,01h     ;nombre de secteur a lire ?
call envfdc
mov al,1Bh     ;GAP3 length ?
call envfdc
mov al,0FFh     ;taille des données a lire,  
call envfdc    ;valide uniquement si la taille du secteur = 0

call recfdc                    ;octet d'état 0
fs
mov [erreur_disquette+0],al
call recfdc                    ;octet d'état 1
fs
mov [erreur_disquette+1],al
call recfdc                    ;octet d'état 2
fs
mov [erreur_disquette+2],al
call recfdc                    ;piste/cylindre           on lit les données
call recfdc                    ;tête                     mais on ne vérifie rien
call recfdc                    ;nombre de secteur
call recfdc                    ;nombre d'octet par secteur

fs
mov al,[erreur_disquette+0]
and al,0C0h
cmp al,0
je octet_etat_ok1
fs
or byte[at_fc_fichier],02h
octet_etat_ok1:


;recopie le secteur lu a sa destination
push ds
mov si,seldat
mov ds,si
mov esi,zt_disquette
mov ecx,128
cld
rep movsd    ;(128dword=512byte)
pop ds

pop edi
pop ebx
pop cx
fs
test byte[at_fc_fichier],02h
jz lec_suivant_dsq 
call razfdc
fs
dec byte[essai_dsq]
jz erreurdsq
jmp blecdsq

lec_suivant_dsq:
fs
mov byte[essai_dsq],3
add edi,200h
inc ebx
dec cl
jnz blecdsq

pop gs
pop fs
pop es
pop ds
popad
xor eax,eax
ret

erreurdsq:
call razfdc
pop gs
pop fs
pop es
pop ds
popad                         
mov eax,cer_lec
ret

lecdbios:
call bios_liresec
cmp ax,0
jne errlecdbios

;recopie le secteur lu a sa destination
push ecx
push ds
mov si,seldat
mov ds,si
mov esi,zt_disquette
mov ecx,128
cld
rep movsd    ;(128dword=512byte)
pop ds
pop ecx

inc ebx
dec cl
jnz lecdbios

pop gs
pop fs
pop es
pop ds
popad
xor eax,eax
ret

errlecdbios:
pop gs
pop fs
pop es
pop ds
popad                         
mov eax,cer_lec
ret



lecata:
call liresecteurata
pop gs
pop fs
pop es
pop ds
ss
mov [esp+28],eax
popad
ret



lecatapi:
mov esi,edi

sub ch,18h
mov edi,ecx
and edi,0FF00h
shr edi,3       ;div par 256 mul par 32
add edi,ad_descd

fs
mov al,[edi]
and al,07h
cmp al,4
je lecatapi_ok

pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret


lecatapi_ok:
call selection_ata
jc erdnt24

xor al,al         ;parametres vides
fs
mov dx,[edi+dd_adress_base]
inc dx
out dx,al
inc dx
out dx,al
inc dx
out dx,al

inc dx
mov al,12     ;taille de la commande packet(LSB)
out dx,al

xor al,al     ;taille de la commande packet(MSB)
inc dx
out dx,al

mov al,0A0h        ;envoye la commande
add dx,2
out dx,al

push ecx
mov ecx,200
call attdok
pop ecx        ;attend pour savoir si c'est bon!
jc ernrf24

;envoie commande packet
fs
mov dx,[edi+dd_adress_base]
mov ax,00A8h
out dx,ax    ;1
push bx
shr ebx,16
mov ax,bx
xchg al,ah
out dx,ax   ;2
pop ax
xchg al,ah
out dx,ax   ;3
xor ax,ax
out dx,ax   ;4
mov ah,cl
out dx,ax  ;5
xor ax,ax
out dx,ax  ;6

xor ebx,ebx
mov bl,cl
shl ebx,10    ;ebx=nombre de mot a transferer


tdf24i:
push ecx
mov ecx,4000
call attdok
pop ecx        ;attend pour savoir si c'est bon!
jc ernrf24

fs
mov dx,[edi+dd_adress_base]
add dx,2
in al,dx
and al,3
cmp al,2
jne erlecf24    ;si ce n'est pas "out data"

add dx,2
xor ecx,ecx
in al,dx
mov cl,al
inc dx
in al,dx
mov ch,al
shr ecx,1  ;nombre de mot a transferer = Nb de d'octet/2

fs
mov dx,[edi+dd_adress_base]
recomf24i:
in ax,dx
es
mov [esi],ax
dec ebx
add esi,2
dec ecx    
jnz recomf24i   ;un secteur est passé  

cmp ebx,0
jne tdf24i




fs
mov dx,[edi+dd_adress_base]
add dx,7
in al,dx
test al,1
jnz erlecf24
pop gs
pop fs
pop es
pop ds
popad 
xor eax,eax
ret



erlecf24:
pop gs
pop fs
pop es
pop ds
popad 
mov eax,cer_lec
ret
erdnt24:
pop gs
pop fs
pop es
pop ds
popad 
mov eax,cer_lecnt
ret
ernrf24:
pop gs
pop fs
pop es
pop ds
popad 
mov eax,cer_prd
ret
erokupf24:
pop gs
pop fs
pop es
pop ds
popad 
mov eax,cer_do
ret





lecusb:
mov dl,ch
and edx,1Fh
shl edx,dc_desc_clef_usb
add edx,ad_desc_clef_usb
fs
cmp byte[edx+dlu_type],01
je lecusb_boscsi 
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret

lecusb_boscsi:
mov ax,seldat
mov ds,ax
mov esi,edi
;prépare cbw
and ecx,0FFh
cmp ecx,0
jne lecusb_boscsi_ok
mov ecx,100h
lecusb_boscsi_ok:
push ecx
mov eax,ecx
mov cl,[edx+dlu_nboct]
shl eax,cl
mov ecx,[cptsf]

mov dword[zt_clefusb],43425355h ;mot magique "USBC"
mov [zt_clefusb+4],ecx ;tag
mov [zt_clefusb+8],eax     ;taille des données
mov byte[zt_clefusb+0ch],80h   ;flag (in) 
mov al,[edx+dlu_lun]
mov [zt_clefusb+0Dh],al   ;lun

bswap ebx
pop ecx
xchg cl,ch
mov eax,[edx+dlu_msb_ad]
bswap eax

cmp eax,0
jne lecusb_boscsi_cmd16

mov byte[zt_clefusb+0Eh],10   ;taille de la commande 
mov byte[zt_clefusb+0Fh],28h  ;commande 
mov byte[zt_clefusb+10h],0    ;vide
mov [zt_clefusb+11h],ebx      ;adresse du secteur
mov byte[zt_clefusb+15h],0    ;vide
mov [zt_clefusb+16h],cx       ;nb de secteur
mov dword[zt_clefusb+18h],0   ;vide
mov dword[zt_clefusb+1Ch],0   ;vide
mov dword[zt_clefusb+20h],0   ;vide
jmp lecusb_bo_envcbw


;mov byte[zt_clefusb+0Eh],12   ;taille de la commande 
;mov byte[zt_clefusb+0Fh],0A8h  ;commande 
;mov byte[zt_clefusb+10h],0    ;vide
;mov [zt_clefusb+11h],ebx      ;adresse du secteur
;mov word[zt_clefusb+15h],0    ;nb de secteur (MSB)
;mov [zt_clefusb+17h],cx       ;nb de secteur (LSB)
;mov dword[zt_clefusb+19h],0   ;vide
;mov dword[zt_clefusb+1Dh],0   ;vide
;mov dword[zt_clefusb+21h],0   ;vide
;jmp lecusb_bo_envcbw


lecusb_boscsi_cmd16:
mov byte[zt_clefusb+0Eh],16   ;taille de la commande 
mov byte[zt_clefusb+0Fh],88h  ;commande 
mov byte[zt_clefusb+10h],0    ;vide
mov [zt_clefusb+11h],eax      ;adresse du secteur (MSB)
mov [zt_clefusb+15h],ebx      ;adresse du secteur (LSB)
mov word[zt_clefusb+19h],0    ;nb de secteur (MSB)
mov [zt_clefusb+1Bh],cx       ;nb de secteur (LSB)
mov dword[zt_clefusb+1Dh],0   ;vide
mov dword[zt_clefusb+20h],0   ;vide

;envoie cbw
lecusb_bo_envcbw:
push ds
mov ax,fs
mov ds,ax
mov al,[edx+dlu_adresse]
mov ah,[edx+dlu_endpout]
or ah,80h
mov ecx,31
mov edi,zt_clefusb
call sfusb_bulk        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=quantité de données ds:edi=adresse des données 
pop ds
cmp eax,0
jne erreur_lecusb_boscsi


;reçois donnée
boucle_lecusb_boscsi:
push ds
mov ax,es
mov ds,ax
fs
mov al,[edx+dlu_adresse]
fs
mov ah,[edx+dlu_endpin]
mov ecx,512
mov edi,esi
call sfusb_bulk        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=quantité de données ds:edi=adresse des données 
pop ds

add esi,512
sub dword[zt_clefusb+8],512
cmp dword[zt_clefusb+8],0
jne boucle_lecusb_boscsi 
;on ignore les eventuelles erreur a ce moment la


;reçois csw
push ds
mov ax,fs
mov ds,ax
mov al,[edx+dlu_adresse]
mov ah,[edx+dlu_endpin]
mov ecx,13
mov edi,zt_clefusb+32
call sfusb_bulk        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=quantité de données ds:edi=adresse des données 
pop ds
cmp eax,0
jne erreur_lecusb_boscsi


;lit résultat opération
cmp  dword[zt_clefusb+32],53425355h ;est ce le mot magique "USBS"?
jne erreur_lecusb_boscsi
mov eax,[zt_clefusb+4] 
cmp  dword[zt_clefusb+36],eax ;est ce le bon tag?
jne erreur_lecusb_boscsi
cmp  dword[zt_clefusb+40],0 ;est ce qu'il n'y as aucunes données manquante?
jne erreur_lecusb_boscsi
cmp  byte[zt_clefusb+44],0 ;est ce que le code d'erreur est ok?
jne erreur_lecusb_boscsi


pop gs
pop fs
pop es
pop ds
;ss
;mov [esp+28],eax
popad
xor eax,eax
ret


erreur_lecusb_boscsi:
call reset_clef_bo
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_lec
ret








;******************************************************************************************
esct:         ;ecrire un secteur                               ****************************
	      ;ebx=numéros de secteur
	      ;ch=nø de disque
	      ;cl=nombre de secteur a lire 
	      ;es:esi zone de source
pushad
push ds
push es
push fs
push gs
cmp ch,01h
je ecrdsq
mov al,ch
and al,0F8h
cmp al,10h
je ecrata
cmp al,18h
je ecratapi
;cmp al,20h
;je ecrsata
cmp al,40h
je ecrusb
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret



ecrdsq:
fs
test byte[at_fc_fichier],10h    ;test si le lecteur disquette est présent
jz erreurdsq
fs
test byte[at_fc_fichier],04h
jnz motdjal2
push cx
mov dx,3F2h     ;allume le moteur 
mov al,1Ch
out dx,al
fs
mov ecx,[cptsf]    ;attend 1 seconde que le moteur soit V correcte
add ecx,400
bclatm3:
int 62h
fs
cmp [cptsf],ecx
jb bclatm3
pop cx
motdjal2:
fs
mov eax,[cptsf]   ;fixe le délais pour l'arret du moteur disquette
add eax,12000      ;30 secondes
fs
mov [temp_moteur_disq],eax
fs
or byte[at_fc_fichier],04h

fs
mov byte[essai_dsq],3   ;3 réessais d'écriture

becrdsq:
push cx
push ebx
push esi
push ebx
;ecrit le secteur dans la zone tampon de lecture/ecriture disquette
push ds
push es
mov ax,es
mov ds,ax
mov ax,seldat
mov es,ax
mov edi,zt_disquette
mov ecx,128
cld
rep movsd    ;(128dword=512byte)
pop es
pop ds


mov ebx,30000h+zt_disquette
mov cx,511
mov ah,048h     ;lecture par le périphérique   en single mode
call inidma2
pop ebx

mov ax,bx
fs
mov cx,[sec_cyl_disq]   ;secteur par cylindre
xor dx,dx
div cx

mov bx,ax         
mov ax,dx
fs
mov cx,[sec_piste_disq]   ;secteur par piste
xor dx,dx
div cx         
inc dx        ;bx=piste ax=tête dx=secteur
mov dh,al     ;dh=tête dl=secteur
mov bh,al     
shl bh,2      ;bh=lec&tête bl=cylindre/piste

call placetete

mov al,65h    ;ecriture double densité et sans lire les deleted adress marks 
call envfdc
mov al,bh    ;lecteur zéro, tête 0
call envfdc
mov al,bl     ;cylindre/piste
call envfdc
mov al,dh     ;tête
call envfdc
mov al,dl     ;secteur  (commence a 1)
call envfdc
mov al,02h     ;taille du secteur 02=512
call envfdc
mov al,01h     ;nombre de secteur a lire ?
call envfdc
mov al,18h    ;27h     ;GAP3 length ?
call envfdc
mov al,0FFh     ;taille des données a lire,  
call envfdc    ;valide uniquement si la taille du secteur = 0

call recfdc                    ;octet d'état 0
fs
mov [erreur_disquette+0],al
call recfdc                    ;octet d'état 1
fs
mov [erreur_disquette+1],al
call recfdc                    ;octet d'état 2
fs
mov [erreur_disquette+2],al
call recfdc                    ;piste/cylindre           on lit les données
call recfdc                    ;tête                     mais on ne vérifie rien
call recfdc                    ;nombre de secteur
call recfdc                    ;nombre d'octet par secteur

fs
mov al,[erreur_disquette+0]
and al,0C0h
cmp al,0
je octet_etat_ok2
fs
or byte[at_fc_fichier],02h
octet_etat_ok2:

pop esi
pop ebx
pop cx
fs
test byte[at_fc_fichier],02h
jz ecr_suivant_dsq
call razfdc 
fs
dec byte[essai_dsq]
jz erreurdsq
jmp becrdsq

ecr_suivant_dsq:
fs
mov byte[essai_dsq],3
add esi,200h
inc ebx
dec ch
jnz becrdsq
pop gs
pop fs
pop es
pop ds
popad
xor eax,eax
ret


ecrata:
call ecriresecteurata
pop gs
pop fs
pop es
pop ds
ss
mov [esp+28],eax
popad
ret


ecratapi:
pop gs
pop fs
pop es
pop ds
popad 
mov eax,cer_parami
ret




ecrusb:
mov dl,ch
and edx,1Fh
shl edx,dc_desc_clef_usb
add edx,ad_desc_clef_usb
fs
cmp byte[edx+dlu_type],01
je ecrusb_boscsi 
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret

ecrusb_boscsi:
mov ax,seldat
mov ds,ax
;prépare cbw
and ecx,0FFh
cmp ecx,0
jne ecrusb_boscsi_ok
mov ecx,100h
ecrusb_boscsi_ok:
push ecx
mov eax,ecx
mov cl,[edx+dlu_nboct]
shl eax,cl
mov ecx,[cptsf]

mov dword[zt_clefusb],43425355h ;mot magique "USBC"
mov [zt_clefusb+4],ecx ;tag
mov [zt_clefusb+8],eax     ;taille des données
mov byte[zt_clefusb+0ch],00h   ;flag (out) 
mov al,[edx+dlu_lun]
mov [zt_clefusb+0Dh],al   ;lun

bswap ebx
pop ecx
xchg cl,ch
mov eax,[edx+dlu_msb_ad]
bswap eax

cmp eax,0
jne ecrusb_boscsi_cmd16

mov byte[zt_clefusb+0Eh],10   ;taille de la commande 
mov byte[zt_clefusb+0Fh],2Ah  ;commande 
mov byte[zt_clefusb+10h],0    ;vide
mov [zt_clefusb+11h],ebx      ;adresse du secteur
mov byte[zt_clefusb+15h],0    ;vide
mov [zt_clefusb+16h],cx       ;nb de secteur
mov dword[zt_clefusb+18h],0   ;vide
mov dword[zt_clefusb+1Ch],0   ;vide
mov dword[zt_clefusb+20h],0   ;vide
jmp ecrusb_bo_envcbw


;mov byte[zt_clefusb+0Eh],12   ;taille de la commande 
;mov byte[zt_clefusb+0Fh],0AAh  ;commande 
;mov byte[zt_clefusb+10h],0    ;vide
;mov [zt_clefusb+11h],ebx      ;adresse du secteur
;mov word[zt_clefusb+15h],0    ;nb de secteur (MSB)
;mov [zt_clefusb+17h],cx       ;nb de secteur (LSB)
;mov dword[zt_clefusb+19h],0   ;vide
;mov dword[zt_clefusb+1Dh],0   ;vide
;mov dword[zt_clefusb+21h],0   ;vide
;jmp ecrusb_bo_envcbw


ecrusb_boscsi_cmd16:
mov byte[zt_clefusb+0Eh],16   ;taille de la commande 
mov byte[zt_clefusb+0Fh],8Ah  ;commande 
mov byte[zt_clefusb+10h],0    ;vide
mov [zt_clefusb+11h],eax      ;adresse du secteur (MSB)
mov [zt_clefusb+15h],ebx      ;adresse du secteur (LSB)
mov word[zt_clefusb+19h],0    ;nb de secteur (MSB)
mov [zt_clefusb+1Bh],cx       ;nb de secteur (LSB)
mov dword[zt_clefusb+1Dh],0   ;vide
mov dword[zt_clefusb+20h],0   ;vide

;envoie cbw
ecrusb_bo_envcbw:
push ds
mov ax,fs
mov ds,ax
mov al,[edx+dlu_adresse]
mov ah,[edx+dlu_endpout]
or ah,80h
mov ecx,31
mov edi,zt_clefusb
call sfusb_bulk        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=quantité de données ds:edi=adresse des données 
pop ds
cmp eax,0
jne erreur_ecrusb_boscsi


;reçois donnée
boucle_ecrusb_boscsi:
push ds
mov ax,es
mov ds,ax
fs
mov al,[edx+dlu_adresse]
fs
mov ah,[edx+dlu_endpout]
or ah,80h
mov ecx,512
mov edi,esi
call sfusb_bulk        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=quantité de données ds:edi=adresse des données 
pop ds

add esi,512
sub dword[zt_clefusb+8],512
cmp dword[zt_clefusb+8],0
jne boucle_ecrusb_boscsi 
;on ignore les eventuelles erreur a ce moment la


;reçois csw
push ds
mov ax,fs
mov ds,ax
mov al,[edx+dlu_adresse]
mov ah,[edx+dlu_endpin]
mov ecx,13
mov edi,zt_clefusb+32
call sfusb_bulk        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=quantité de données ds:edi=adresse des données 
pop ds
cmp eax,0
jne erreur_ecrusb_boscsi


;lit résultat opération
cmp  dword[zt_clefusb+32],53425355h ;est ce le mot magique "USBS"?
jne erreur_ecrusb_boscsi
mov eax,[zt_clefusb+4] 
cmp  dword[zt_clefusb+36],eax ;est ce le bon tag?
jne erreur_ecrusb_boscsi
cmp  dword[zt_clefusb+40],0 ;est ce qu'il n'y as aucunes données manquante?
jne erreur_ecrusb_boscsi
cmp  byte[zt_clefusb+44],0 ;est ce que le code d'erreur est ok?
jne erreur_ecrusb_boscsi


pop gs
pop fs
pop es
pop ds
;ss
;mov [esp+28],eax
popad
xor eax,eax
ret


erreur_ecrusb_boscsi:
call reset_clef_bo
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_ecr
ret






;*****************************************************************************
;sous fonction lecteur disquette

envfdc:   ;envoie données sur le registre data du fdc
push dx
push ecx
push ax
fs
test byte[at_fc_fichier],02h
jnz erenvfdc
fs
mov ecx,[cptsf]    ;attend  maximum 2s
add ecx,800
mov dx,3F4h
benvfdc:
fs
cmp [cptsf],ecx
ja erenvfdc
in al,dx
and al,0C0h
cmp al,80h
jne benvfdc
pop ax
mov dx,3F5h
out dx,al
pop ecx
pop dx
ret

erenvfdc:   ;erreur d'entrée/sortie sur le fdc
pop ax
fs
or byte[at_fc_fichier],02h  ;erreur, car on a attendu trop longtemp
pop ecx
pop dx
ret


recfdc:    ;lit des données sur le port data du fdc
push dx
push ecx
fs
test byte[at_fc_fichier],02h
jnz errecfdc
fs
mov ecx,[cptsf]    ;attend  maximum 2s
add ecx,800
mov dx,3F4h
brecfdc:
fs
cmp [cptsf],ecx
ja errecfdc
in al,dx
and al,0C0h
cmp al,0C0h
jne brecfdc
mov dx,3F5h
in al,dx
pop ecx
pop dx
ret

errecfdc:   ;erreur d'entrée/sortie sur le fdc
fs
or byte[at_fc_fichier],02h  ;erreur, car on a attendu trop longtemp
pop ecx
pop dx
ret


razfdc:
pushad
mov dx,3F7h ;mode 500000 bit/s
mov al,00h
out dx,al

mov dx,3F2h ;reinitialisation du controleur disquette
mov al,00h
out dx,al
fs
mov ecx,[cptsf]    ;attend 250ms que le controleur ai fini
add ecx,100
bclatraz1:
int 62h
fs
cmp [cptsf],ecx
jb bclatraz1

mov dx,3F2h     ;allume le moteur 
mov al,1Ch
out dx,al
fs
mov ecx,[cptsf]    ;attend 500ms que le moteur soit V correcte
add ecx,500
bclatraz2:
int 62h
fs
cmp [cptsf],ecx
jb bclatraz2
fs
mov eax,[cptsf]   ;fixe le délais pour l'arret du moteur disquette
add eax,12000      ;30 secondes
fs
mov [temp_moteur_disq],eax
fs
or byte[at_fc_fichier],04h


mov al,07h    ;recalibrage 
call envfdc
mov al,0    ;lecteur & tête 
call envfdc
fs
mov ecx,[cptsf]    ;attend 500ms que la recalibration soit terminé
add ecx,200
bclatraz3:
int 62h
fs
cmp [cptsf],ecx
jb bclatraz3

fs
and byte[at_fc_fichier],0FDh  ;reset le bit "erreur de lecture controleur a raz"
xor ebx,ebx
jmp pltet


placetete:
pushad
fs
cmp bl,[pos_cyl_disq]
jne pltet
popad
ret

pltet:
mov al,0Fh    ;place la tête 
call envfdc
mov al,bh    ;lecteur & tête 
call envfdc
mov al,bl     ;cylindre/piste
call envfdc
fs
mov ecx,[cptsf]    ;attend 500ms
add ecx,200
bclattete:
int 62h
fs
cmp [cptsf],ecx
jb bclattete
fs
mov [pos_cyl_disq],bl
popad
ret







inidma2:  ;canal 2 ah=mode de transfert
	  ;ebx=adresse ram absolue cx=taille de la zone

mov dx,0Ah    ;Masquer le canal DMA - registre Masque 1 ;
mov al,06h
out dx,al
    
mov dx,0Bh    ;Spécificer le mode de transfert - registre Mode ;
mov al,ah
and al,0FCh
or al,02h     ;selectionne canal 2
out dx,al

mov dx,0Ch    ;Donner l 'adresse du buffer (offset + page) - registre Flip-Flop ;
xor al,al    
out dx,al
mov dx,04h
mov al,bl
out dx,al
mov al,bh
out dx,al
shr ebx,16
mov dx,81h
mov al,bl
out dx,al

mov dx,0Ch    ;Donner la taille du buffer - registre Flip-Flop ;
xor al,al    
out dx,al
mov dx,05h
mov al,cl
out dx,al
mov al,ch
out dx,al

    
mov dx,0Ah    ;Libérer le canal DMA - registre Masque 1. 
mov al,02h
out dx,al
ret


;****************************************************************************
;sous fonction ata/atapi


liresecteurata:

mov esi,edi

sub ch,10h
mov edi,ecx
and edi,0FF00h
shr edi,3       ;div par 256 mul par 32
add edi,ad_descd
;fs
;test byte[edi],08h
;je liresecteurata_dma


liresecteurata_pio:
call envoie_coord_ata
jc erparamsecteurata
cmp al,1
je liresecteurata_pio_lba48


mov al,020h        ;envoye la commande lec lba28/chs
jmp liresecteurata_pio_cmdok


liresecteurata_pio_lba48:
mov al,024h        ;envoye la commande lec lba48


liresecteurata_pio_cmdok:
fs
mov dx,[edi+dd_adress_base]
add dx,7
out dx,al

xor bx,bx
mov bh,cl     ;bx=nombre de mot a transferer


liresecteurata_pio_1secteur:
push ecx
mov ecx,600
call attdok
pop ecx
jc ernrpsecteurata

fs
mov dx,[edi+dd_adress_base]
liresecteurata_pio_1word:
in ax,dx
es
mov [esi],ax
dec bx
add esi,2
cmp bl,0
jne liresecteurata_pio_1word
cmp bx,0
jne liresecteurata_pio_1secteur
fs
mov dx,[edi+dd_adress_base]
add dx,7
in al,dx
test al,1
jnz erlecsecteurata
xor eax,eax
ret





liresecteurata_dma:
;£££££££££££££££££££££££££££££££££££


;préparer la PRDT
;envoyer la position du PRDT au controleur
;envoyer le sens du transfert au controleur
;effacer les bit erreur et interruption sur le controleur?
;selectionner le disque
;envoyer l'adresse du secteur au disque
;envoyer le nombre de secteur au controleur
;envoyer la commande au controleur
;mettre a 1 le bit de trabnsfert
;attendre une interruption?
;mettre a 0 le bit de transfert
;lire l'état du controleur


;0xC8			Read DMA (28 bit LBA)
;0x25			Read DMA (48 bit LBA)
;0xCA			Write DMA (28 bit LBA)
;0x35			Write DMA (48 bit LBA)


ret








;*************************************************************************
ecriresecteurata:
sub ch,10h
mov edi,ecx
and edi,0FF00h
shr edi,3       ;div par 256 mul par 32
add edi,ad_descd
fs
test byte[edi],08h
;je ecriresecteurata_dma

ecriresecteurata_pio:
call envoie_coord_ata
jc erparamsecteurata

cmp al,1
je ecriresecteurata_pio_lba48


mov al,030h        ;envoye la commande ecr lba28/chs
jmp ecriresecteurata_pio_cmdok

ecriresecteurata_pio_lba48:
mov al,034h        ;envoye la commande ecr lba48

ecriresecteurata_pio_cmdok:
fs
mov dx,[edi+dd_adress_base]
add dx,7
out dx,al

xor bx,bx
mov bh,cl     ;bx=nombre de mot a transferer

ecriresecteurata_pio_1secteur:
push ecx
mov ecx,600
call attdok
pop ecx
jc ernrpsecteurata

fs
mov dx,[edi+dd_adress_base]
ecriresecteurata_pio_1word:
es
mov ax,[esi]
out dx,ax
dec bx
add esi,2
cmp bl,0
jne ecriresecteurata_pio_1word
cmp bx,0
jne ecriresecteurata_pio_1secteur

fs
mov dx,[edi+dd_adress_base]
add dx,7
in al,dx
test al,1
jnz erecrsecteurata
xor eax,eax
ret

;*************************************************************************
infodisqueata:
mov esi,edi

sub ch,10h
mov edi,ecx
and edi,0FF00h
shr edi,3       ;div par 256 mul par 32
add edi,ad_descd

call selection_ata
jc eroqpsecteurata

fs
mov dx,[edi+dd_adress_base]
add dx,7
mov al,0ECh        ;envoye la commande
out dx,al

mov bx,256     ;bx=nombre de mot a transferer

push ecx
mov ecx,100
call attdok
pop ecx
jc ernrpsecteurata

fs
mov dx,[edi+dd_adress_base]
infodisqueata_1word:
in ax,dx
es
mov [esi],ax
add esi,2
dec bx
jnz infodisqueata_1word

fs
mov dx,[edi+dd_adress_base]
add dx,7
in al,dx
test al,1
jnz erlecsecteurata
xor eax,eax
ret


;****************************************************************************
infodisqueatapi:
mov esi,edi

sub ch,18h
mov edi,ecx
and edi,0FF00h
shr edi,3       ;div par 256 mul par 32
add edi,ad_descd

call selection_ata
jc eroqpsecteurata

fs
mov dx,[edi+dd_adress_base]
add dx,7
mov al,0A1h        ;envoye la commande
out dx,al

mov bx,256     ;bx=nombre de mot a transferer


push ecx
mov ecx,100
call attdok
pop ecx
jc ernrpsecteurata

fs
mov dx,[edi+dd_adress_base]
infodisqueatapi_1word:
in ax,dx
es
mov [esi],ax
add esi,2
dec bx
jnz infodisqueatapi_1word

fs
mov dx,[edi+dd_adress_base]
add dx,7
in al,dx
test al,1
jnz erlecsecteurata
xor eax,eax
ret

erparamsecteurata:  ;erreur parametre
mov eax,cer_parami
ret

eroqpsecteurata: ;controleur occupé
mov eax,cer_lecnt
ret

ernrpsecteurata: ;controleur ne répond pas
mov eax,cer_prd
ret

erlecsecteurata: ;erreur de lecture
mov eax,cer_lec
ret

erecrsecteurata: ;erreur de lecture
mov eax,cer_ecr
ret







;***************************************************
selection_ata:
pushad
mov al,0A0h           ;E=1010b met a un les bit obsolete
fs
mov ch,[edi]
and ch,10h   ;isole le bit maitre/esclave   
or al,ch

fs
mov dx,[edi+dd_adress_base]  ;envoye information tête + disque (important: si on envoie d'autre paramêttre avant il seront envoyé au mauvais disque)
cmp dx,0
je selection_ata_nok 
add dx,6
out dx,al

call attsl       
jnc selection_ata_ok

mov al,08h        ;envoye la commande device reset si il est occupé???
fs
mov dx,[edi+dd_adress_ctrl]
add dx,7
out dx,al

call attsl       
jc selection_ata_nok


selection_ata_ok:
popad
clc
ret


selection_ata_nok:
popad
stc
ret





;********************************************************
envoie_coord_ata:
;ebx=adresse LBA cl=Nombre de secteur a transferer edi=adresse du desctipteur de disque
pushad

fs
mov al,[edi]
and al,07h
cmp al,1
je envoie_coord_ata_chs
cmp al,2
je envoie_coord_ata_lba28
cmp al,3
je envoie_coord_ata_lba48

popad
stc
ret

;*********************************
envoie_coord_ata_chs:
push ecx
xor edx,edx
mov eax,ebx
fs
mov ecx,[edi+4] ;secteur par cylindre
cmp ecx,0
je ajuste_erreur
div ecx
mov ebx,eax  ;ebx=piste

mov eax,edx
xor edx,edx
xor ecx,ecx
fs
mov cx,[edi+2] ;secteur par piste
cmp cx,0
je ajuste_erreur
div ecx        ;eax=tête
inc edx        ;edx=secteur
pop ecx

test eax,0FFFFFFF0h
jnz ajuste_erreur
test ebx,0FFFF0000h
jnz ajuste_erreur
test edx,0FFFFFF00h
jnz ajuste_erreur

and eax,00Fh
and ebx,0FFFFh
and edx,0FFh
shl ebx,8
or ebx,edx

or al,0A0h           ;A=1010b met a un les bit obsolete et a zéro le bit lba
fs
mov ch,[edi]
and ch,10h   ;isole le bit maitre/esclave   
or al,ch

fs
mov dx,[edi+dd_adress_base]  ;envoye information tête + disque (important: si on envoie d'autre paramêttre avant il seront envoyé au mauvais disque)
add dx,6
out dx,al

call attsl       
jnc envoie_coord_ata_lba28_ok ;pour la suite ça fonctionne comme le lba28

mov al,08h        ;envoye la commande device reset si il est occupé???
fs
mov dx,[edi+dd_adress_ctrl]
add dx,7
out dx,al

call attsl       
jnc envoie_coord_ata_lba28_ok


ajuste_erreur:
popad
stc
ret

;*****************************
envoie_coord_ata_lba28:
mov eax,ebx
shr eax,24
test al,0F0h
jnz ajuste_erreur

or al,0E0h           ;E=1110b met a un les bit obsolete et le bit lba
fs
mov ch,[edi]
and ch,10h   ;isole le bit maitre/esclave   
or al,ch

fs
mov dx,[edi+dd_adress_base]  ;envoye information tête + disque (important: si on envoie d'autre paramêttre avant il seront envoyé au mauvais disque)
add dx,6
out dx,al

call attsl       
jnc envoie_coord_ata_lba28_ok


mov al,08h        ;envoye la commande device reset si il est occupé???
fs
mov dx,[edi+dd_adress_ctrl]
add dx,7
out dx,al

call attsl       
jnc envoie_coord_ata_lba28_ok

popad
stc
ret

;******************************
envoie_coord_ata_lba28_ok:
fs
mov dx,[edi+dd_adress_ctrl]
mov al,2h           ;désactive interruption
out dx,al

fs
mov dx,[edi+dd_adress_base]
add dx,2
mov al,cl         ;Nombre de secteur a lire/écrire
out dx,al

inc dx
mov al,bl         ;bit 0-7 de LBA ou coordonné secteur
out dx,al

inc dx
mov al,bh        ;bit 8-15 de LBA ou LSB cylindre
out dx,al

inc dx
mov eax,ebx          ;bit 16-23 de LBA ou MSB cylindre
shr eax,16
out dx,al

popad
xor eax,eax
clc
ret







;*****************************
envoie_coord_ata_lba48:
fs
cmp word[edi+dd_offset_num],0
jne envoie_coord_ata_lba48_valide
test ebx,0F0000000h
jz envoie_coord_ata_lba28    ;si il n'y as pas besoin d'uttiliser le LBA48 on utilise le LBA28

envoie_coord_ata_lba48_valide:
mov al,0E0h           ;E=1110b met a un les bit obsolete et le bit lba
fs
mov ch,[edi]
and ch,10h   ;isole le bit maitre/esclave   
or al,ch

fs
mov dx,[edi+dd_adress_base]  ;envoye information tête + disque (important: si on envoie d'autre paramêttre avant il seront envoyé au mauvais disque)
add dx,6
out dx,al

call attsl       
jnc envoie_coord_ata_lba48_ok


mov al,08h        ;envoye la commande device reset si il est occupé???
fs
mov dx,[edi+dd_adress_ctrl]
add dx,7
out dx,al

call attsl       
jnc envoie_coord_ata_lba48_ok

popad
stc
ret

;******************************
envoie_coord_ata_lba48_ok:
fs
mov dx,[edi+dd_adress_ctrl]
mov al,2h           ;désactive interruption
out dx,al

fs
mov dx,[edi+dd_adress_base]
add dx,2
mov al,0         ;MSB du Nombre de secteur a lire/écrire
out dx,al

inc dx
mov eax,ebx         ;bit 31-24 de LBA
shr eax,24
out dx,al

inc dx
fs
mov al,[edi+dd_offset_num]        ;bit 39-32 de LBA
out dx,al

inc dx
fs
mov al,[edi+dd_offset_num+1]         ;bit 47-40 de LBA
out dx,al

fs
mov dx,[edi+dd_adress_base]
add dx,2
mov al,cl         ;LSB du Nombre de secteur a lire/écrire
out dx,al

inc dx
mov al,bl         ;bit 0-7 de LBA ou coordonné secteur
out dx,al

inc dx
mov al,bh        ;bit 8-15 de LBA
out dx,al

inc dx
mov eax,ebx          ;bit 16-23 de LBA
shr eax,16
out dx,al


fs
mov dword[edi+dd_offset_num],0    ;efface le MSB du numéros de secteur pour le prochain tour
popad
mov eax,1
clc
ret




attdok:         ;attend que le disque soit pret a envoyer les donnÈes
fs
mov dx,[edi+dd_adress_ctrl]
in al,dx     ;lit 1 fois le alternate status register et ignore le résultat

fs
mov dx,[edi+dd_adress_base]
add dx,7

fs
add ecx,[cptsf]

bocpre:
in al,dx
and al,89h
cmp al,08h       ;drq=1  bsy=0 err=0
je tsfok
cmp al,01h        ;err=1
je tsfnok
fs
cmp [cptsf],ecx
jb bocpre

tsfnok:
stc
ret

tsfok:
clc
ret


attsl:         ;attend que le disque soit selectionné
push ecx
fs
mov dx,[edi+dd_adress_base]
add dx,7
in al,dx   ;lit 4 foit le status register pour créer artificiellement un délais de 400ns
in al,dx
in al,dx
in al,dx

fs
mov ecx,[cptsf]
add ecx,100               ;temp a attendre pour tester

bocsl:
in al,dx
test al,88h       ;bsy=0 et drq=0
jz slok
fs
cmp [cptsf],ecx
jb bocsl
stc
pop ecx
ret
slok:
clc
pop ecx
ret


;*********************************************************************************************************
infodisque_ata_atapi:   ;ch =numéros de disque ata/cdrom (10h a 1Fh)
                        ;information disque es:edi=cible


mov al,ch
and al,0F8h
cmp al,10h
je info_ata
cmp al,18h
je info_atapi
mov al,ch
and al,0E0h
;cmp al,20h
;je info_sata
cmp al,40h
je info_usb
cmp ch,80h
jae info_partition
mov eax,cer_parami
jmp finfonctionfichiererr

info_ata:
call infodisqueata
jmp finfonctionfichiererr
info_atapi:
call infodisqueatapi
jmp finfonctionfichiererr




info_usb:
mov dl,ch
and edx,1Fh
shl edx,dc_desc_clef_usb
add edx,ad_desc_clef_usb
fs
cmp byte[edx+dlu_type],01
je infousb_boscsi 
mov eax,cer_parami
jmp finfonctionfichiererr 

infousb_boscsi:
;on charge d'abord la dimension du disque
mov ax,fs
mov ds,ax
mov esi,edi
;efface la zone ou on vas recopier le descripteur
mov ecx,64 
xor eax,eax
cld
rep stosd

;prépare cbw
mov ecx,[cptsf]
mov dword[zt_clefusb],43425355h ;mot magique "USBC"
mov [zt_clefusb+4],ecx ;tag
mov dword[zt_clefusb+8],8     ;taille des données
mov byte[zt_clefusb+0ch],80h   ;flag (in) 
mov al,[edx+dlu_lun]
mov [zt_clefusb+0Dh],al   ;lun
mov byte[zt_clefusb+0Eh],10   ;taille de la commande 
mov byte[zt_clefusb+0Fh],25h  ;commande 
mov dword[zt_clefusb+10h],0   ;vide
mov dword[zt_clefusb+14h],0   ;vide
mov dword[zt_clefusb+18h],0   ;vide
mov dword[zt_clefusb+1Ch],0   ;vide
mov dword[zt_clefusb+20h],0   ;vide

;envoie cbw
mov al,[edx+dlu_adresse]
mov ah,[edx+dlu_endpout]
or ah,80h
mov ecx,31
mov edi,zt_clefusb
call sfusb_bulk        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=quantité de données ds:edi=adresse des données 
cmp eax,0
jne erreur_infousb_boscsi

;reçois donnée
mov al,[edx+dlu_adresse]
mov ah,[edx+dlu_endpin]
mov ecx,8
mov edi,zt_clefusb+64
call sfusb_bulk        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=quantité de données ds:edi=adresse des données 
;on ignore les eventuelles erreur a ce moment la

;reçois csw
mov al,[edx+dlu_adresse]
mov ah,[edx+dlu_endpin]
mov ecx,13
mov edi,zt_clefusb+32
call sfusb_bulk        ;al=périphérique ah=endpoint+bit7=sens(0=in 1=out) ecx=quantité de données ds:edi=adresse des données 
cmp eax,0
jne erreur_infousb_boscsi


;lit résultat opération
cmp  dword[zt_clefusb+32],53425355h ;est ce le mot magique "USBS"?
jne erreur_infousb_boscsi
mov eax,[zt_clefusb+4] 
cmp  dword[zt_clefusb+36],eax ;est ce le bon tag?
jne erreur_infousb_boscsi
cmp  dword[zt_clefusb+40],0 ;est ce qu'il n'y as aucunes données manquante?
jne erreur_infousb_boscsi
cmp  byte[zt_clefusb+44],0 ;est ce que le code d'erreur est ok?
jne erreur_infousb_boscsi


mov eax,[zt_clefusb+64]
mov ecx,[zt_clefusb+68]
bswap eax
bswap ecx

es
mov [esi],eax
es
mov [esi+8],ecx
es
mov dword[esi+12],0
add esi,64
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§simuler les autres options?



;charge le descripteur du périphérique
push edx
mov eax,2
mov bl,[edx+dlu_adresse] ;adresse
mov bh,0 ;endpoint
mov dh,1   ;type de descripteur (descripteur global)(chaine)
mov dl,0  ;index
mov edi,zt_clefusb
int 68h
pop edx
cmp eax,0
jne finfonctionfichiererr 

cmp byte[zt_clefusb+15],0
je nomgenerique_infousb_boscsi

;charge le descripteur de chaine
push edx
mov eax,2
mov bl,[edx+dlu_adresse] ;adresse
mov bh,0 ;endpoint
mov dh,3   ;type de descripteur (chaine)
mov dl,[zt_clefusb+15]  ;index
mov edi,zt_clefusb
int 68h
pop edx
cmp eax,0
jne finfonctionfichiererr 


;recopie maximum 64 caractère du nom au format utf8
cmp byte[zt_clefusb],10       ;si 4 ou moins on inscrit le nom générique
jbe nomgenerique_infousb_boscsi
cmp byte[zt_clefusb],82      ;si 40 ou plus on tronque le nom
jbe pastronque_infousb_boscsi
mov byte[zt_clefusb],82
pastronque_infousb_boscsi:
push esi
mov esi,zt_clefusb
mov edi,zt_clefusb+128
call conv_chaine_usb
pop edi
mov esi,zt_clefusb+128
cld
repnz movsb
xor eax,eax
jmp finfonctionfichiererr







;génère un nom générique si pas de nom
nomgenerique_infousb_boscsi:
es
mov dword[esi],"Clef"
es
mov dword[esi+4]," USB"
es
mov dword[esi+8],0B0C24E20h  ;" N°" en utf8

xor ecx,ecx
mov eax,102
mov cl,[edx+dlu_adresse]
mov edx,esi
add edx,12
push es
pop ds
int 61h
xor eax,eax
jmp finfonctionfichiererr


erreur_infousb_boscsi:
call reset_clef_bo
mov eax,cer_lec
jmp finfonctionfichiererr





;**********************************
;reset la cle usb bulk only (obligatoire apres une erreur)
reset_clef_bo:
pushad
mov esi,edx

;reset la clef
xor dh,dh
mov dl,[esi+dlu_interface]
mov byte[zt_clefusb],21h    ;bmRequestType
mov byte[zt_clefusb+1],0FFh  ;bRequest (ici reset bulk-only)
mov word[zt_clefusb+2],0   ;wValue
mov word[zt_clefusb+4],dx  ;wIndex (numéros de l'interface)
mov word[zt_clefusb+6],0   ;wLength
;envoie la commande
mov al,[esi+dlu_adresse] ;adresse
mov ah,0 ;endpoint
mov edx,zt_clefusb
mov edi,zt_clefusb
call sfusb_commande


;clear le stall de l'endpoint in
xor dh,dh
mov dl,[esi+esi+dlu_endpin]
mov byte[zt_clefusb],02h    ;bmRequestType
mov byte[zt_clefusb+1],01h  ;bRequest (ici clear feature)
mov word[zt_clefusb+2],0   ;wValue (endpoint halt)
mov word[zt_clefusb+4],dx  ;wIndex (numéros de terminaison)
mov word[zt_clefusb+6],0   ;wLength
mov al,[esi+dlu_adresse] ;adresse
mov ah,0 ;endpoint
mov edx,zt_clefusb
mov edi,zt_clefusb
call sfusb_commande


;clear le stall de l'endpoint out
xor dh,dh
mov dl,[esi+esi+dlu_endpout]
mov byte[zt_clefusb],02h    ;bmRequestType
mov byte[zt_clefusb+1],01h  ;bRequest (ici clear feature)
mov word[zt_clefusb+2],0   ;wValue (endpoint halt)
mov word[zt_clefusb+4],dx  ;wIndex (numéros de terminaison)
mov word[zt_clefusb+6],0   ;wLength
mov al,[esi+dlu_adresse] ;adresse
mov ah,0 ;endpoint
mov edx,zt_clefusb
mov edi,zt_clefusb
call sfusb_commande

;reseter les enregistrement des toggle bit
mov ax,1
mov dx,1
mov cl,[esi+esi+dlu_endpin]
shl ax,cl
mov cl,[esi+esi+dlu_endpout]
shl dx,cl
or ax,dx
not ax
xor edx,edx
mov dl,[esi+dlu_adresse]
shl edx,dc_desc_periph_usb
add edx,ad_desc_periph_usb
and [edx+dpu_togl],ax
popad
ret


;**********************************
info_partition:
mov al,ch
sub al,7Fh  ;-80h +1
and eax,03Fh
shl eax,5
mov esi,eax
add esi,ad_descp
mov ax,seldat
mov ds,ax
mov ecx,20h
rep movsb
xor eax,eax
jmp finfonctionfichiererr









;*********************************************************************************************
sff_definis_msb_disque:

;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

mov eax,cer_parami
jmp finfonctionfichiererr




;*********************************************************************************************
sff_maj_partition:
mov ax,seldat
mov ds,ax
mov es,ax

mov ebx,zt_maj_descp 
xor eax, eax
bouclevide_maj_partiton:
mov [ebx],eax
add ebx,4
cmp ebx,zt_maj_descp+2048
jne bouclevide_maj_partiton

mov edi,bootsecteur
mov al,8
push cx
mov cl,1
xor ebx,ebx
call lsct
pop cx
cmp eax,0
jne finfonctionfichiererr


;cmp byte[bootsecteur+1BEh],0EEh  ;on vérifie si la première partition est une partition de protection GPT
;jne maj_partition_mbr
;cmp byte[bootsecteur+1CEh],0    ; et si les autres partitions sont bien vide
;jne maj_partition_mbr
;cmp byte[bootsecteur+1DEh],0    ;sinon le partitionnement est reconnue comme MBR 
;jne maj_partition_mbr
;cmp byte[bootsecteur+1EEh],0
;jne maj_partition_mbr

;***************************chargement des données de partitionnement de type GPT
;§§§§§§§§§§§§§§§§§
;jmp maj_partition_trie


;***************************chargement des données de partitionnement de type MBR
maj_partition_mbr:
mov esi,bootsecteur+1BEh
mov edi,zt_maj_descp  
call ex_part_mbr
add esi,10h
add edi,40h
call ex_part_mbr
add esi,10h
add edi,40h
call ex_part_mbr
add esi,10h
add edi,40h
call ex_part_mbr


;*****************************trie des partition déja enregistré et des nouvelles
maj_partition_trie:
mov edi,ad_descp+64

boucle1_maj_partition:  ;balaye le descripteur de partition et vérifie si les partition du disque selectionné existent toujours
cmp byte[edi+1],ch 
jne maj_partition_existante_suivante

mov esi,zt_maj_descp  
boucle2_maj_partition:  ;on vérifie si le type de disque est identique  
mov eax,[esi]
mov edx,[esi+4]
cmp [edi],eax
jne maj_partition_tempo_suivante
cmp [edi+4],edx
jne maj_partition_tempo_suivante

mov eax,[esi+08h]  ;l'adresse
mov edx,[esi+0Ch]
cmp [edi+08h],eax
jne maj_partition_tempo_suivante
cmp [edi+0Ch],edx
jne maj_partition_tempo_suivante

mov eax,[esi+10h]   ;la taille
mov edx,[esi+14h]
cmp [edi+10h],eax
jne maj_partition_tempo_suivante
cmp [edi+14h],edx
jne maj_partition_tempo_suivante



;si le disque existe dans les nouvelle partition on l'efface des nouvelles partitions
mov dword[esi+00h],0
mov dword[esi+04h],0
mov dword[esi+08h],0
mov dword[esi+0Ch],0
mov dword[esi+10h],0
mov dword[esi+14h],0
mov dword[esi+18h],0
mov dword[esi+1Ch],0
mov dword[esi+20h],0
mov dword[esi+24h],0
mov dword[esi+28h],0
mov dword[esi+2Ch],0
mov dword[esi+30h],0
mov dword[esi+34h],0
mov dword[esi+38h],0
mov dword[esi+3Ch],0
jmp maj_partition_existante_suivante


maj_partition_tempo_suivante:
add esi,64
cmp esi,zt_maj_descp +2048 
jne boucle2_maj_partition

;si la partition n'existe plus dans les nouvelles partition on ferme tout les fichier ouverts sur cette partition 
mov eax,edi
sub eax,ad_descp
shr eax,6     ;div par 64
mov ebx,[ad_ficho]
mov ecx,[max_ficho]
add ecx,ebx

boucle3_maj_partition:
gs
cmp [ebx+1],al
jne maj_partition_pasfermer
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

maj_partition_pasfermer:
add ebx,32
cmp ebx,ecx
jne boucle3_maj_partition



;et on efface le descripteur de partition
mov dword[edi+00h],0
mov dword[edi+04h],0
mov dword[edi+08h],0
mov dword[edi+0Ch],0
mov dword[edi+10h],0
mov dword[edi+14h],0
mov dword[edi+18h],0
mov dword[edi+1Ch],0
mov dword[edi+20h],0
mov dword[edi+24h],0
mov dword[edi+28h],0
mov dword[edi+2Ch],0
mov dword[edi+30h],0
mov dword[edi+34h],0
mov dword[edi+38h],0
mov dword[edi+3Ch],0


maj_partition_existante_suivante:
add edi,64
cmp edi,ad_descp+8192
jne boucle1_maj_partition


;intègre les descripeur de nouvelles partition dans la table des descripteur de partition
mov esi,zt_maj_descp 
mov edi,ad_descp+64

boucle4_maj_partition:
cmp dword[esi],0
je maj_partition_temporaire_vide

cmp dword[edi],0
jne maj_partition_existante_nonvide

mov ecx,64
cld
rep movsb
jmp boucle4_maj_partition


maj_partition_existante_nonvide:
add edi,64
cmp edi,ad_descp+8192
jne boucle4_maj_partition
xor eax,eax
jmp finfonctionfichiererr

maj_partition_temporaire_vide:
add esi,64
cmp esi,zt_maj_descp +2048
jne boucle4_maj_partition
xor eax,eax
jmp finfonctionfichiererr



;*************************************************************************************************************************
ex_part_mbr:  ;extrait les informations type, adresse et taille d'une partition a partir d'une entrée de la table mbr
	      ;ds:esi=entrée de la table mbr de la partition
	      ;ds:edi=descripteur		
	       

mov al,[esi+04h]
cmp al,0
je ex_part_mbr_vide

cmp al,06h
je ex_part_mbr_F16
cmp al,04h                           ;al=04 06 0E 14 16 1E si fat16  
je ex_part_mbr_F16                          
cmp al,06h
je ex_part_mbr_F16
cmp al,0Eh
je ex_part_mbr_F16
cmp al,14h
je ex_part_mbr_F16
cmp al,16h
je ex_part_mbr_F16
cmp al,1Eh
je ex_part_mbr_F16

cmp al,0Bh
je ex_part_mbr_F32                          ;al=0C 0B 1C 1B si fat32
cmp al,0Ch
je ex_part_mbr_F32
cmp al,1Ch
je ex_part_mbr_F32
cmp al,1Bh
je ex_part_mbr_F32

;?????????
;je ex_part_mbr_exFAT
;?????????
;je ex_part_mbr_ext2
;?????????
;je part_ext3

cmp al,2Eh
je ex_part_mbr_TOD

cmp al,07h                      ;al=07 17 si ntfs
je ex_part_mbr_NTFS
cmp al,17h
je ex_part_mbr_NTFS

cmp al,42h
je ex_part_mbr_SFS

mov ah,al
mov al,2 ;partition inconnue
jmp ex_part_suite

ex_part_mbr_vide:
xor eax,eax
mov [edi+0h],eax
mov [edi+4h],eax
mov [edi+8h],eax
jmp ex_part_mbr_vide_fin

ex_part_mbr_F12:
mov ax,4 ;partition fat12
jmp ex_part_suite

ex_part_mbr_F16:
mov ax,5 ;partition fat16
jmp ex_part_suite

ex_part_mbr_F32:
mov ax,6 ;partition fat32
jmp ex_part_suite

ex_part_mbr_exFAT:
mov ax,7 ;partition exFAT
jmp ex_part_suite

ex_part_mbr_ext2:
mov ax,8 ;partition ext2
jmp ex_part_suite

ex_part_mbr_ext3:
mov ax,9 ;partition ext3
jmp ex_part_suite

ex_part_mbr_TOD:
mov ax,10 ;partition TOD
jmp ex_part_suite

ex_part_mbr_NTFS:
mov ax,11 ;partition NTFS
jmp ex_part_suite

ex_part_mbr_SFS:
mov ax,12 ;partition SFS
jmp ex_part_suite

ex_part_suite:  ;al=type de partition ah=0 ou le code trouvé dans le MBR si c'est inconnue
mov [edi],al      ;type de la partition
mov [edi+1],ch    ;lecteur de la partition
mov [edi+2],ah    ;code MBR

mov eax,[esi+08h]   ;adresse de base de la partition  
mov [edi+08h],eax
mov dword[edi+0Ch],0

mov eax,[esi+0Ch]   ;taille de la partition
mov [edi+10h],eax
mov dword[edi+14h],0

xor eax,eax       ;on vide le reste des descripteurs
mov [edi+3],al
ex_part_mbr_vide_fin:
mov [edi+04h],eax
mov [edi+18h],eax
mov [edi+1Ch],eax
mov [edi+20h],eax
mov [edi+24h],eax
mov [edi+28h],eax
mov [edi+2Ch],eax
mov [edi+30h],eax
mov [edi+34h],eax
mov [edi+38h],eax
mov [edi+3Ch],eax
ret





;************************************
sff_definis_vitesse_disque:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§




