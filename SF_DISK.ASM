
;****************************************************************************
;lire et ecrire un secteur                       ****************************
liresecteur:
call lsct
jmp finfonctionfichiererr

ecriresecteur:
call esct
jmp finfonctionfichiererr

;***********************************************
;numéros de disque:
;01h disquette
;10h à 17h disque ATA
;18h à 1Fh cdrom
;20h à 3Fh disque USB   ;projet
;40h à 7Fh disque ahci  ;projet 


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
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret



lecdsq:
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
fs
cmp [cptsf],ecx
jb bclatm1
pop ecx
fs
or byte[at_fc_fichier],04h      ;signale que le moteur est allumé
motdjal1:

blecdsq:
push cx
push ebx
push edi
push ebx
mov ebx,30000h+zt_disquette     ;configuration dma 2 pour trnsferer les données
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

fs
mov ecx,[cptsf]    ;attend 25ms
add ecx,10
bclatm1b:
fs
cmp [cptsf],ecx
jb bclatm1b

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


call recfdc  ;octet d'état 0
mov ah,al
and ah,0C0h
cmp ah,0
je st0ok
fs
or byte[at_fc_fichier],02h
fs
mov [erreur_disquette+0],al
st0ok:
call recfdc  ;octet d'état 1
cmp al,0
je st1ok
fs
or byte[at_fc_fichier],02h
fs
mov [erreur_disquette+1],al
st1ok:
call recfdc  ;octet d'état 2
cmp al,0
je st2ok
fs
or byte[at_fc_fichier],02h
fs
mov [erreur_disquette+2],al
st2ok:
call recfdc  ;piste/cylindre           on lit les données
call recfdc  ;tête                     mais on ne vérifie rien
call recfdc  ;nombre de secteur
call recfdc  ;nombre d'octet par secteur

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
jnz erreurdsq
add edi,200h
inc ebx
dec cl
jnz blecdsq
fs
mov ecx,[cptsf]   ;fixe le délais pour l'arret du moteur disquette
add ecx,2000      ;5 secondes
fs
mov [temp_moteur_disq],ecx
pop gs
pop fs
pop es
pop ds
popad
xor eax,eax
ret

erreurdsq:
call razfdc
fs
mov ecx,[cptsf]   ;fixe le délais pour l'arret du moteur disquette
add ecx,2000      ;5 secondes
fs
mov [temp_moteur_disq],ecx
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
sub ch,18h       ;lecteur de 18h a 1Fh
xchg cl,ch
mov ax,cx
and al,1
shr cl,1
and cx,3
mov dx,1F0h
shl cx,7
sub dx,cx
mov cx,ax      ;ch=Nombre cl=maitre/esclave
mov di,dx      ;di=adresse de base

or cl,0Eh           ;E=1110b
shl cl,4           ;cl=disque/tÕte

push ecx
mov dx,7            ;teste si le controleur est occupé
add dx,di
fs
mov ecx,[cptsf]
add ecx,100

testokupi:
in al,dx
test al,80h
jz pasokupi
fs
cmp [cptsf],ecx
jb testokupi
pop ecx
jmp erokupf24

pasokupi:
call attsl        
jc erdnt24

pop ecx
mov dx,6     ;envoye information + disque (important: si on envoie
add dx,di    ;d'autre paramettre avant il seront envoyé au mauvais disque)
mov al,cl
out dx,al

call attsl        
jc ernrf24

mov al,2h           ;désactive interruption
mov dx,206h
add dx,di
out dx,al

xor al,al         ;OVL
mov dx,1
add dx,di
out dx,al

xor al,al         ;Nombre de secteur a lire/Ècrire (0 ici)
mov dx,2
add dx,di
out dx,al

xor al,al         ;rien (on envoie, au cas ou)
mov dx,3
add dx,di
out dx,al

mov al,12         ;LSB du nombre d'octet (12 donc)
mov dx,4
add dx,di
out dx,al

mov al,0h        ;MSB du nombre d'octet (0 donc) 
mov dx,5
add dx,di
out dx,al

mov al,0A0h        ;envoye la commande
mov dx,7
add dx,di
out dx,al

mov dx,206h
add dx,di
in al,dx     ;lit le alternate status register et ignore le résultat
call attdok        ;attend pour savoir si c'est bon!
jc ernrf24

mov dx,di
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
mov ah,ch
out dx,ax  ;5
xor ax,ax
out dx,ax  ;6

xor ebx,ebx
mov bl,ch
shl ebx,10    ;ebx=nombre de mot a transferer

tdf24i:
mov dx,206h
add dx,di
in al,dx     ;lit le alternate status register et ignore le résultat

call attdok2      
jc ernrf24

mov dx,di
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

mov dx,di
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


mov dx,di
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
pop gs
pop fs
pop es
pop ds
popad
mov eax,cer_parami
ret



ecrdsq:
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
fs
cmp [cptsf],ecx
jb bclatm3
pop cx
fs
or byte[at_fc_fichier],04h
motdjal2:


becrdsq:
push cx
push ebx
push esi
push ebx
;recopie le secteur lu a sa destination
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
mov ah,045h     ;lecture par le périphérique   en single mode
call inidma2
pop ebx

mov bx,ax
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
mov bh,dh     
shl bh,2      ;bh=lec&tête bl=cylindre/piste

mov al,0Fh    ;place la tête 
call envfdc
mov al,bh    ;lecteur & tête 
call envfdc
mov al,bl     ;cylindre/piste
call envfdc
fs
mov ecx,[cptsf]    ;attend 25ms
add ecx,10
bclatm2b:
fs
cmp [cptsf],ecx
jb bclatm2b


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
mov al,27h     ;GAP3 length ?
call envfdc
mov al,0FFh     ;taille des données a lire,  
call envfdc    ;valide uniquement si la taille du secteur = 0


call recfdc  ;octet d'état 0
and al,011111011b
cmp al,0
je st0ok2
fs
or byte[at_fc_fichier],02h
st0ok2:
call recfdc  ;octet d'état 1
cmp al,0
je st1ok2
fs
or byte[at_fc_fichier],02h
st1ok2:
call recfdc  ;octet d'état 2
cmp al,0
je st2ok2
fs
or byte[at_fc_fichier],02h
st2ok2:
call recfdc  ;piste/cylindre           on lit les données
call recfdc  ;tête                     mais on ne vérifie rien
call recfdc  ;nombre de secteur
call recfdc  ;nombre d'octet par secteur


pop esi
pop ebx
pop cx
fs
test byte[at_fc_fichier],02h
jnz erreurdsq
add esi,200h
inc ebx
dec ch
jnz becrdsq
fs
mov ecx,[cptsf]  ;fixe le délais pour l'arret du moteur disquette
add ecx,2000     ;5 secondes
fs
mov [temp_moteur_disq],ecx
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

erlecf25:
pop gs
pop fs
pop es
pop ds
popad 
mov eax,cer_parami
ret
ernrf25:
pop gs
pop fs
pop es
pop ds
popad 
mov eax,cer_parami
ret
erokupf25:
pop gs
pop fs
pop es
pop ds
popad 
mov eax,cer_parami
ret




ecratapi:
pop gs
pop fs
pop es
pop ds
popad 
mov eax,cer_parami
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
fs
cmp [cptsf],ecx
jb bclatraz1
mov dx,3F2h     ;allume le moteur 
mov al,1Ch
out dx,al
fs
mov ecx,[cptsf]    ;attend 500ms que le moteur soit V correcte
add ecx,200
bclatraz2:
fs
cmp [cptsf],ecx
jb bclatraz2
mov al,07h    ;recalibrage 
call envfdc
mov al,0    ;lecteur & tête 
call envfdc
fs
mov ecx,[cptsf]    ;attend 500ms que la recalibration soit terminé
add ecx,200
bclatraz3:
fs
cmp [cptsf],ecx
jb bclatraz3
mov al,0Fh    ;place la tête 
call envfdc
mov al,0    ;lecteur & tête 
call envfdc
mov al,0     ;cylindre/piste
call envfdc
fs
mov ecx,[cptsf]    ;attend 250ms que la tête soit bien placé
add ecx,100
bclatraz4:
fs
cmp [cptsf],ecx
jb bclatraz4
fs
mov byte[pos_cyl_disq],0
fs
and byte[at_fc_fichier],0FDh  ;reset le bit "erreur de lecture controleur a raz"
ret

placetete:
fs
cmp bl,[pos_cyl_disq]
jne pltet
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
fs
cmp [cptsf],ecx
jb bclattete
fs
mov [pos_cyl_disq],bl
ret


inidma2:  ;canal 2 ah=mode de transfert
	  ;ebx=adresse ram absolue cx=taille de la zone

mov dx,0Ah    ;Masquer le canal DMA - registre Masque 1 ;
mov al,06h
out dx,al
    
mov dx,0Bh    ;Spécificer le mode de transfert - registre Mode ;
mov al,ah
and al,0FCh
or al,02h
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
call iniata
jc eroqpsecteurata

mov al,020h        ;envoye la commande
mov dx,7
add dx,di
out dx,al

xor bx,bx
mov bh,ch     ;bx=nombre de mot a transferer

tdf24:
call at1puls
call attdok
jc ernrpsecteurata

mov dx,di
recomf24:
in ax,dx
es
mov [esi],ax
dec bx
add esi,2
cmp bl,0
jne recomf24
cmp bx,0
jne tdf24
mov dx,di
add dx,7
in al,dx
test al,1
jnz erlecsecteurata
xor eax,eax
ret


ecriresecteurata:
call iniata
jc eroqpsecteurata

mov al,030h        ;envoye la commande
mov dx,7
add dx,di
out dx,al

xor bx,bx
mov bh,ch     ;bx=nombre de mot a transferer

tdf25:
call at1puls
call attdok
jc ernrpsecteurata

mov dx,di  
recomf25:
es
mov ax,[esi]
out dx,ax
dec bx
add esi,2
cmp bl,0
jne recomf25
cmp bx,0
jne tdf25

mov dx,di
add dx,7
in al,dx
test al,1
jnz erecrsecteurata
xor eax,eax
ret


infodisqueata:
mov esi,edi
xor ebx,ebx
mov cl,1
call iniata
jc eroqpsecteurata

mov al,0ECh        ;envoye la commande
mov dx,7
add dx,di
out dx,al

xor bx,bx
mov bh,ch     ;bx=nombre de mot a transferer

tdf26:
call at1puls
call attdok3
jc ernrpsecteurata

mov dx,di
recomf26:
in ax,dx
es
mov [esi],ax
dec bx
add esi,2
cmp bl,0
jne recomf26
cmp bx,0
jne tdf26
mov dx,di
add dx,7
in al,dx
test al,1
jnz erlecsecteurata
xor eax,eax
ret

infodisqueatapi:
mov esi,edi
xor ebx,ebx
mov cl,1
sub ch,8
call iniata
jc eroqpsecteurata

mov al,0A1h        ;envoye la commande
mov dx,7
add dx,di
out dx,al

xor bx,bx
mov bh,ch     ;bx=nombre de mot a transferer

tdf27:
call at1puls
call attdok3
jc ernrpsecteurata

mov dx,di
recomf27:
in ax,dx
es
mov [esi],ax
dec bx
add esi,2
cmp bl,0
jne recomf27
cmp bx,0
jne tdf27
mov dx,di
add dx,7
in al,dx
test al,1
jnz erlecsecteurata
xor eax,eax
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


;**************************************************
;initialisatio ATA
;ebx=adresse LBA cl=Nombre de secteur a transferer
;ch=numéros du disque(10h à 17h)
iniata:

sub ch,10h
xchg cl,ch        ;cl=lecteur ch=nombre

mov ax,cx
and al,1
shr cl,1
and cx,3
mov dx,1F0h
shl cx,7
sub dx,cx
mov cx,ax      ;ch=Nombre cl=maitre/esclave
mov di,dx      ;di=adresse de base

and ebx,0FFFFFFFh
mov eax,ebx
or cl,0Eh           ;E=1110b
shl cl,4
shr eax,24
or cl,al            ;cl=disque/tÍte


;call at1puls    ;teste si le controleur est occupé
call attsl        
jnc pasokup
stc
ret

pasokup:

mov dx,6     ;envoye information tête + disque (important: si on envoie  
add dx,di    ;d'autre paramêttre avant il seront envoyé au mauvais disque)   
mov al,cl
out dx,al

call at1puls
call attsl        
jnc disc_sel_iniata
stc
ret

disc_sel_iniata:
mov al,2h           ;désactive interruption
mov dx,206h
add dx,di
out dx,al

mov al,ch         ;Nombre de secteur a lire/écrire
mov dx,2
add dx,di
out dx,al

mov al,bl         ;bit 0-7 de LBA
mov dx,3
add dx,di
out dx,al

mov al,bh        ;bit 8-15 de LBA
mov dx,4
add dx,di
out dx,al

mov eax,ebx          ;bit 16-23   de LBA
shr eax,16
mov dx,5
add dx,di
out dx,al
clc
ret

attdok:         ;attend que le disque soit pret a envoyer les donnÈes
push ecx
mov dx,7
add dx,di
fs
mov ecx,[cptsf]
add ecx,600               ;temp a attendre pour tester
jmp bocpre

attdok2:         ;attend que le disque soit pret a envoyer les donnÈes
push ecx
mov dx,7
add dx,di
fs
mov ecx,[cptsf]
add ecx,2000               ;temp a attendre pour tester
jmp bocpre

attdok3:         ;attend que le disque soit pret a envoyer les donnÈes
push ecx
mov dx,7
add dx,di
fs
mov ecx,[cptsf]
add ecx,40               ;temp a attendre pour tester

bocpre:
in al,dx
test al,08h       ;drq=1  
jnz tsfok
test al,01h        ;err=1
jnz tsfnok
fs
cmp [cptsf],ecx
jb bocpre
tsfnok:
stc
pop ecx
ret
tsfok:
test al,01h        ;on vérifie quand même que err=0
jnz tsfnok
clc
pop ecx
ret




at1puls:
push ecx
fs
mov ecx,[cptsf]
bat1puls:
fs
cmp ecx,[cptsf]
je bat1puls
pop ecx
ret

attsl:         ;attend que le disque soit selectionné
push ecx
mov dx,7
add dx,di
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
mov eax,cer_parami
jmp finfonctionfichiererr

info_ata:
call infodisqueata
jmp finfonctionfichiererr
info_atapi:
call infodisqueatapi
jmp finfonctionfichiererr






;*************************************************************************************************************************
exbasepart:    ;extrait les informations type, adresse et taille d'une partition a prtir de la table secteur mbr
	       ;es:esi=table mbr de la partition 
	       
es
mov al,[esi+04h]
cmp al,0
je part_vide
cmp al,04h                           ;al=04 06 0E 14 16 1E si fat16  
je part_F16                          
cmp al,06h
je part_F16
cmp al,0Eh
je part_F16
cmp al,14h
je part_F16
cmp al,16h
je part_F16
cmp al,1Eh
je part_F16
cmp al,0Ch
je part_F32                          ;al=0C 0B 1C 1B si fat32
cmp al,0Ch
je part_F32
cmp al,0Ch
je part_F32
cmp al,0Ch
je part_F32
mov ah,al
mov al,2 ;partition inconnue
jmp suiteinfopart

part_vide:
ret

part_F12:
mov ax,4 ;partition fat12
jmp suiteinfopart

part_F16:
mov ax,5 ;partition fat16
jmp suiteinfopart

part_F32:
mov ax,6 ;partition fat32
jmp suiteinfopart

part_exFAT:
mov ax,7 ;partition exFAT
jmp suiteinfopart

part_ext2:
mov ax,8 ;partition ext2
jmp suiteinfopart

part_ext3:
mov ax,9 ;partition ext3
jmp suiteinfopart

part_SfB:
mov ax,10 ;partition SfB
jmp suiteinfopart

part_NTFS:
mov ax,11 ;partition NTFS
jmp suiteinfopart

part_SFS:
mov ax,12 ;partition SFS


suiteinfopart:  ;al=type de partition ah=0 ou le code trouvé dans le MBR si c'est inconnue
;cherche un descripteur de partition vide
mov ebx,ad_descp+32        ;(+32 car le descripteur zéro est réservé a la disquette)
boucle_infopart:
cmp byte[ebx],0
je charge_infopart
add ebx,32
cmp ebx,ad_descp+1024
jne boucle_infopart
ret

charge_infopart:
mov [ebx],al      ;type de la partition
mov [ebx+1],ch    ;lecteur de la partition
mov [ebx+2],ah    ;code MBR

mov eax,[esi+08h]   ;adresse de base de la partition  
mov [ebx+4],eax

mov eax,[esi+0Ch]   ;taille de la partition
mov [ebx+8],eax

xor eax,eax       ;on vide le reste des descripteurs
mov [ebx+3],al
mov [ebx+0Ch],eax
mov [ebx+10h],eax
mov [ebx+14h],eax
mov [ebx+18h],eax
mov [ebx+1Ch],eax
ret









