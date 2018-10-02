org 0h

include "DN_VARS.ASM"   ;declaration des constantes numériques

;*********************************************************************
;correction de la position du code dans la RAM

call enregistre_ip ;empile ip et fait un saut nul
enregistre_ip:
push cs
xor eax,eax
xor ebp,ebp
pop ax
pop bp
shl eax,4
add ebp,eax
sub ebp,enregistre_ip     ;ebp pointe désormais sur le premier octet du programme (adresse absolue)

cmp ebp,50000h
je position_code_ok

mov eax,ebp    ;déplace le code au bon endroit 
mov esi,ebp
shr eax,4
and esi,0Fh    
mov ds,ax
xor di,di
mov ax,5000h
mov es,ax

mov ecx,20000h

boucle_recopie_code:
mov al,[si]
es
mov [di],al
inc si
inc di
cmp si,0
jne pas_change_ds
mov ax,ds
add ax,1000h
mov ds,ax
pas_change_ds:
cmp di,0
jne pas_change_es
mov ax,es
add ax,1000h
mov es,ax
pas_change_es:

dec ecx
jne boucle_recopie_code 

jmp 5000h:position_code_ok

position_code_ok:



;*********************************************************************
;passage en flat real mode

mov dx,seggdt     ;on va configurer la gdt
mov ds,dx
xor ebx,ebx
mov [0],ebx
mov [4],ebx    ;descripteur nul (obligatoire)

mov ax,1
mov ebx,0       ;segment de donn?es de 4Go partant de l'adresse 0
mov ecx,0FFFFFFFFh
mov dl,02h      ;segment de donn?e en lecture/?criture
call crgdt     

mov ax,5000h
mov ds,ax
lgdt[p_gdt+start]  ;charge la gdt


mov cx,8
mov eax,cr0
mov ebx,eax
or ebx,1
jmp $+2
mov cr0,ebx         ;passe en mode protégé
nop
mov ds,cx
mov es,cx
mov fs,cx
mov gs,cx
mov cr0,eax         ;mode en mode réel flat
jmp $+2



;*********************************************************************
;active la ligne A20 pour pouvoir ?crire dns la zone memoire superieur!!!!!!!!!!!!!!!!!!!!!méthode ne fonctionnant pas a chaque fois m'as t'on dit
mov al,0D1h          ;active A20
out 64h,al           ;la prochaine ?criture sur 60h sera pour le port de sortie
call attporok
mov al,0DFh
out 60h,al           ;envoie de la configuration pour l'activation de l'A20
call attporok
mov al,0FFh          ;envoie une commande d'impulsion sur aucune des sorties
out 64h,al            
call attporok        

;autre méthode pour activer la ligne A20 (si l'autre ne fonctionne pas!!!)
;in al, 0x92
;or al, 2
;out 0x92, al


;*******************************************************************************************
;test la taille de la ram

mov ebx,100000h     
xor ax,ax
mov ds,ax

boucltestram:
mov al,[ebx]
not byte[ebx]
cmp al,[ebx]
je suitestram
add ebx,10000h
jmp boucltestram

suitestram:
dec ebx
mov al,[ebx]
not byte[ebx]
cmp al,[ebx]
je suitestram

and ebx,0FFFFFFF0h     ;ne prend en compte que les bloc de 16 octet
sub ebx,10h
mov dword[ebx],"DMF?"   ;et le descripteur de fin de m?moire

sub ebx,100000h
mov [nb_ram+30000h],ebx      ;sauvegarde la quantit? total de ram

                             ;crée le premier descripteur de m?moire vide
mov dword[100000h],"DMV?"
mov dword[100004h],ebx
mov dword[100008h],"????"  
mov dword[10000Ch],"????"


;**********************************************************************
;ajoute les fichier RAM

mov ebx,50000h+start+finsegcod      ;calcule la taille ocupé par les fichier (dont le fichier syst.baz)
boucle_ajoute_fichier_ram:
cmp byte[ebx+2],"F"
je suite_ajoute_fichier_ram
mov eax,[ebx+4]
add ebx,eax
jmp boucle_ajoute_fichier_ram

suite_ajoute_fichier_ram:
sub ebx,50000h
add ebx,432

mov edx,[100004h]                    ;recréer le nouveau descripteur de mémoire libre un peu plus loin
sub edx,ebx

mov dword[ebx+100000h],"DMV?"
mov dword[ebx+100004h],edx
mov dword[ebx+100008h],"????"  
mov dword[ebx+10000Ch],"????"


mov dword[100000h],"DMX?"                ;crée le descripteur pour le fichier SYST.BAZ
mov dword[100004h],432+start+finsegcod 
mov dword[100008h],16+start+finsegcod
mov dword[10000Ch],"????"

mov dword[100010h],"SYST"
mov dword[100014h],".BAZ"
mov edi,100018h

boucle_descrsystbaz:
mov dword[edi],0
add edi,4
cmp edi,1001A0h
jne boucle_descrsystbaz


sub ebx,432+start+finsegcod
shr ebx,2                              ;recopie les données du fichier syst.baz

mov esi,50000h
mov edi,1001A0h
boucle_ajoute_fichier_ram2:
mov eax,[esi]
mov[edi],eax
add esi,4
add edi,4
cmp esi,50000h+start+finsegcod
jne boucle_ajoute_fichier_ram2

;créer le faux descripteur final qui doit se trouver a la fin de syst.baz
mov dword[edi+00h],"DMF?"
mov dword[edi+04h],"????"
mov dword[edi+08h],"????"  
mov dword[edi+0Ch],"????"
add edi,16

cmp ebx,0
je fin_ajoute_fichier_ram

;recopie les données des autres fichiers
boucle_ajoute_fichier_ram3:
mov eax,[esi]
mov[edi],eax
add esi,4
add edi,4
dec ebx
jnz boucle_ajoute_fichier_ram3



fin_ajoute_fichier_ram:

;**********************************************************************
;initiallise les données syst?mes

xor ax,ax           ;vide la ram de 0003 0000h à 0008 0000h
mov ds,ax
mov ebx,30000h
xor eax,eax

boucleefreg:
mov [ebx],eax
add ebx,4
cmp ebx,80000h
jne boucleefreg


mov ax,segdat    ;charge les info video
mov ds,ax
mov word[resxt],80           ;mode texte 80x25 au d?but ;-)
mov word[resyt],25
mov byte[bitpp],00

xor eax,eax
xor ecx,ecx
xor edx,edx
mov ax,[resyt]
mov cx,[resxt]
mul ecx
mov [ad_afin],eax   ;numéro du dernier caractère affichable 
sub eax,ecx
sub eax,ecx
mov [ad_afcmd],eax  ;numéro du premier caractère qui sert a ecrire la commande en cours (-2 lignes)
sub eax,ecx
mov [ad_afrep],eax ;numéro du premier caractère qui sert a ecrire le dossier en cours (-3 lignes)



xor dx,dx        ;copie les adresse de base des ports com et lpt detecté par le bios
mov es,dx
es
mov ax,[400h]
es
mov dx,[402h]
mov [port_com_base],ax
mov [port_com_base+04h],dx
es
mov ax,[404h]
es
mov dx,[406h]
mov [port_com_base+08h],ax
mov [port_com_base+0Ch],dx

es
mov ax,[408h]
es
mov dx,[40Ah]
mov [port_lpt_base],ax
mov [port_lpt_base+04h],dx
es
mov ax,[40Ch]
es
mov dx,[40Eh]
mov [port_lpt_base+08h],ax
mov [port_lpt_base+0Ch],dx


;initialise variables de la fonction lecture disquette
mov word[sec_piste_disq],18
mov word[nb_piste_disq],80
mov word[sec_cyl_disq],36


;**********************************************
;**** charge les données

mov cx,1024    ;copie la palette graphique pour les conversion en modes 256 couleurs
mov ax,cs
mov ds,ax
mov si,palgraf
mov ax,segdat
mov es,ax
mov di,ad_tabcoul
cld
rep movsb      ;ds:si vers es:di

mov cx,4096    ;copie la table de caract?re graphique
mov ax,cs
mov ds,ax
mov si,polgraf
mov ax,segdat
mov es,ax
mov di,ad_tabcar
cld
rep movsb      ;ds:si vers es:di

mov cx,2048    ;copie la table de correspondance touche
mov ax,cs
mov ds,ax
mov si,tabclv
mov ax,segdat
mov es,ax
mov di,ad_tabclav
cld
rep movsb      ;ds:si vers es:di


mov cx,1024    ;copie la table des accents
mov ax,cs
mov ds,ax
mov si,tabacc
mov ax,segdat
mov es,ax
mov di,ad_tabaccent
cld
rep movsb      ;ds:si vers es:di


mov cx,2048    ;copie la table des messages
mov ax,cs
mov ds,ax
mov si,msgsyst
mov ax,segdat
mov es,ax
mov di,ad_msg
cld
rep movsb    


 

;**********************************************
;**** charge le code 

mov cx,finsegcod    ;copie le segment de code a l'endroit pr?vu
mov ax,cs
mov ds,ax
mov si,start
mov ax,segcod
mov es,ax
xor di,di
cld
rep movsb      ;ds:si vers es:di


;**********************************************************************
; préparation du mode protégé


mov dx,seggdt     ;on va configurer la gdt
mov ds,dx
xor ebx,ebx
mov [0],ebx
mov [4],ebx    ;descripteur nul (obligatoire)

mov ax,1            ;selecteur 1: code du programme
mov ebx,segcod*16
mov ecx,0FFFFh
mov dl,08Eh       ;segment de code lisible en 32bits
call crgdt

mov ax,2
mov ebx,segdat*16       ;segment de donn?es du programme
mov ecx,01FFFFh    ;128kibi
mov dl,02h      ;segment de donn?e en lecture/?criture
call crgdt

mov ax,3
mov ebx,segpil*16      ;segment de pile du programme
mov ecx,0FFFFh
mov dl,02h       ;segment de donn?es en lect/ecr
call crgdt

mov ax,4           ;segment de donn? de la GDT
mov ebx,seggdt*16
mov ecx,0FFFFh
mov dl,02h       ;segment de donn?es en lect/ecr
call crgdt

mov ax,5           ;segment de donn? de l'IDT
mov ebx,seggdt*16  ;
mov ecx,07FFh
mov dl,02h       ;segment de donn?es en lect/ecr
call crgdt

mov ax,6           ;segment des descripteurs de t?che
mov ebx,segddt*16
mov ecx,0FFFFh
mov dl,02h       ;segment de donn?es en lect/ecr
call crgdt

mov ax,7           ;segment des fonction fichier
mov ebx,segff*16
mov ecx,1FFFFh    ;128ko
mov dl,02h       ;segment de donn?es en lect/ecr
call crgdt

mov ax,8           ;segment de lecture de la totalit? de la ram
mov ebx,00000h
mov ecx,0FFFFFFFFh 
mov dl,00h       ;segment de donn?es en lecture seule
call crgdt

mov ax,9          ;ram haute
mov ebx,0100000h
mov ecx,0FFEFFFFFh
mov dl,02h ;segment de donn?es en lect/ecr
call crgdt


mov ax,10            ;selecteur 10: code du système mais en 16bit
mov ebx,segcod*16
mov ecx,0FFFFh
mov dl,00Eh       ;segment de code lisible en 16bits
call crgdt

mov ax,12          ;chunk video A0000h (128Ko)
mov ebx,0A0000h
mov ecx,01FFFFh
mov dl,02h ;segment de donn?es en lect/ecr
call crgdt

mov ax,13          ;chunk video B8000h (32Ko)
mov ebx,0B8000h
mov ecx,07FFFh
mov dl,02h ;segment de donn?es en lect/ecr
call crgdt

mov ax,14          ;Linear Frame Buffer
mov ebx,0A0000h
mov ecx,01FFFFFh
mov dl,02h ;segment de donn?es en lect/ecr
call crgdt




;*******************************************************
;chargement des vecteurs d'interruption


mov dx,segidt      ;modifie l'idt
mov ds,dx
mov si,selcod
mov es,si
mov dl,0Eh

mov al,0          ;d'abord les exeptions
mov esi,iex0
call cridt
mov al,1
mov esi,iex1
call cridt
mov al,2
mov esi,iex2
call cridt
mov al,3
mov esi,iex3
call cridt
mov al,4
mov esi,iex4
call cridt
mov al,5
mov esi,iex5
call cridt
mov al,6
mov esi,iex6
call cridt
mov al,7
mov esi,iex7
call cridt
mov al,8
mov esi,iex8
call cridt
mov al,9
mov esi,iex9
call cridt
mov al,0Ah
mov esi,iexA
call cridt
mov al,0Bh
mov esi,iexB
call cridt
mov al,0Ch
mov esi,iexC
call cridt
mov al,0Dh
mov esi,iexD
call cridt
mov al,0Eh
mov esi,iexE
call cridt
mov al,0Fh
mov esi,iexF
call cridt
mov al,10h
mov esi,iex10
call cridt
mov al,11h
mov esi,iex11
call cridt
mov al,12h
mov esi,iex12
call cridt
mov al,13h
mov esi,iex13
call cridt
mov al,14h
mov esi,iex14
call cridt
mov al,15h
mov esi,iex15
call cridt
mov al,16h
mov esi,iex16
call cridt
mov al,17h
mov esi,iex17
call cridt
mov al,18h
mov esi,iex18
call cridt
mov al,19h
mov esi,iex19
call cridt
mov al,1Ah
mov esi,iex1A
call cridt
mov al,1Bh
mov esi,iex1B
call cridt
mov al,1Ch
mov esi,iex1C
call cridt
mov al,1Dh
mov esi,iex1D
call cridt
mov al,1Eh
mov esi,iex1E
call cridt
mov al,1Fh
mov esi,iex1F
call cridt

;**************IRQ

mov al,30h       ;ensuite les IRQ
mov esi,irqtmp   ;l'irq d?clench? ar le PIT
call cridt 
mov al,31h
mov esi,irqcla   ;l'irq d?clench? par le clavier
call cridt 
mov al,32h
mov esi,irq2  ;l'irq déclenché par le PIC esclave, aquitement simple
call cridt 
mov al,33h
mov esi,irqcom
call cridt 
mov al,34h
mov esi,irqcom
call cridt 
mov al,35h
mov esi,irq5
call cridt 
mov al,36h
mov esi,irq6
call cridt 
mov al,37h
mov esi,irq7
call cridt 
mov al,38h
mov esi,irq8
call cridt 
mov al,39h
mov esi,irq9
call cridt 
mov al,3Ah
mov esi,irqA
call cridt 
mov al,3Bh
mov esi,irqB
call cridt 
mov al,3Ch
mov esi,irqsouris   ;l'irq d?clench? par la souris ps/2
call cridt 
mov al,3Dh
mov esi,irqUSB
call cridt 
mov al,3Eh
mov esi,irqE
call cridt 
mov al,3Fh
mov esi,irqF
call cridt 

;************** interruption systeme

mov al,60h
mov esi,int_60
call cridt 
mov al,61h
mov esi,int_61
call cridt 
mov al,62h
mov esi,int_62
call cridt 
mov al,63h
mov esi,int_63
call cridt 
mov al,64h
mov esi,int_64
call cridt 
mov al,65h
mov esi,int_65
call cridt
mov al,66h
mov esi,int_66
call cridt 
mov al,67h
mov esi,int_67
call cridt 
mov al,68h
mov esi,int_68
call cridt 
mov al,69h
mov esi,int_69
call cridt 
mov al,6Ah
mov esi,int_6A
call cridt 
mov al,6Bh
mov esi,int_6B
call cridt 
mov al,6Ch
mov esi,int_6C
call cridt 
mov al,6Dh
mov esi,int_6D
call cridt 
mov al,6Eh
mov esi,int_6E
call cridt 
mov al,6Fh
mov esi,int_6F
call cridt  

;************************************************
;changement de la police des caractère en mode texte
mov bh,16 	   ;octet par caractère
mov bl,0	   ;???? BL = table in character generator RAM ????
mov cx,0100h 	   ;nombre de caractère a remplacer
mov dx,0	   ;numéros du premier caractère a remplacer
mov ax,5000h
mov es,ax
mov bp,polgraf	   ;ES:BP=pointeur sur le début de la nouvelle police de caractère
mov ax,1110h
int 10h



;*************************************************
;désactive le clignotement en mode texte (marche pas)
;mov dx,3B8h
;in al,dx
;and al,0DFh
;out dx,al

;mov dx,3D8h
;in al,dx
;and al,0DFh
;out dx,al


;**********************************************************************
;programme temporisateur, buzzer, & pic 

cli                         ;programme le temporisateur
mov dx,43h                  
mov al,36h                  ;param?tres de comptage
out dx,al
jmp $+2
mov dx,40h                 ;diviseur de fr?quence de l'irq 0 (LSB en premier)
mov ax,2983                ;1193200/f  ;11932: t=10ms  100Hz
out dx,al                               ;5966: t=5ms    200Hz
jmp $+2                                 ;2983: t=2.5ms  400Hz
mov al,ah                  ;puis le MSB
out dx,al                 

mov dx,42h                 ;diviseur de fréquence du buzzer (LSB en premier)
mov ax,2983                ;ax=1193200/fréquence désiré
out dx,al
jmp $+2
mov al,ah                  ;puis le MSB
out dx,al                 


mov dx,20h                  ;reprogramme les pics
mov al,11h
out dx,al
inc dx
mov al,30h                  ;nø de l'interruption de l'IRQ0
out dx,al
mov al,4
out dx,al
mov al,1
out dx,al

mov dx,0A0h
mov al,11h
out dx,al
inc dx
mov al,38h                 ;nø de l'interruption de l'IRQ8
out dx,al
mov al,2
out dx,al
mov al,1
out dx,al

mov dx,21h             ;regle le masquage des irq
mov al,0A0h            ;masque les irq 5&7
out dx,al
mov dx,0A1h
mov al,0EFh            ;masque les irq 8?11 et 13?15
out dx,al



;************************************
;passage en mode prot?g?

mov ax,cs
mov ds,ax

lgdt[p_gdt+start]
lidt[p_idt+start]
                ;désactive les interruptions

mov eax,cr0
or eax,1
jmp $+2
mov cr0,eax
jmp selcod:0000h

;*************************************************************
;sous fonctions uttilisé par le lanceur

crgdt:  ;cr?er ou modifie un descripteur de segment
        ;ax=num?ros du d?scripteur (13bit)
        ;ds=selecteur du segment  ou se trouve la GDT
        ;ebx=adresse de base
        ;ecx=limite
        ;dl=option       type=0123 d/b=7 l=6 dpl=45

xchg eax,ebx
and ebx,01FFFh
shl bx,3          ;ds:bx=adresse de base du descripteur
mov [bx+2],ax     ;charge la base du segment
shr eax,16
mov [bx+4],al
mov [bx+7],ah

test ecx,0FFF00000h  ;charge la limite du segment
jz gez
shr ecx,12
or ecx,800000h
gez:
mov [bx],cx     ;lsb de la limite
shr ecx,16
mov dh,dl
shr dh,1
and dh,40h
or cl,dh        ;rajoute l'option d/b (16 ou 32bis)
mov dh,dl
shr dh,2
and dh,10h
or cl,dh        ;rajoute l'option l (ou avl) 
and cl,0DFh
mov [bx+6],cl

mov dh,dl
and dx,300Fh
shl dh,1
or dl,dh
or dl,90h     ;p et s mis a 1
mov [bx+5],dl
ret


cridt:  ;cr?er ou modifie un descripteur d'interruption
        ;al=num?ros du d?scripteur (8bit)
        ;ds=selecteur du segment ou se trouve l'IDT
        ;es=selecteur de segment ou se trouve la routine a appeler
        ;esi=offset de la routine a appeler
        ;dl=option                     6-5 dpl
push dx                             ;  3 1=32 0=16 
mov bx,ax                           ;  2-0  type  100=porte d'appel
and bx,0FFh                         ;             110=porte d'interruption
shl bx,3                            ;             111=porte de trappe
mov [bx],si     ;charge l'offset
shr esi,16
mov [bx+6],si
mov [bx+2],es ;charge le selecteur
shl dx,8
and dx,0EF00h
or dx,8000h
mov [bx+4],dx
pop dx
ret

attporok:        ;attend la fin du traitement des donn?es par la puce 8042
in al,64h
jmp $+2
test al,1
jz suit842
in al,60h
in al,64h
suit842:
and al,2
jnz attporok
ret

modbg:  ;modifie la base d'un descripteur de segment
        ;ax=num?ros du d?scripteur (13bit)
        ;ds=selecteur du segment  ou se trouve la GDT
        ;ebx=adresse de base

xchg eax,ebx
and ebx,01FFFh
shl bx,3          ;ds:bx=adresse de base du descripteur
mov [bx+2],ax     ;charge la base du segment
shr eax,16
mov [bx+4],al
mov [bx+7],ah
ret

rcpbg:  ;r?cup?re la base d'un descripteur de segment
        ;ax=num?ros du d?scripteur (13bit)
        ;ds=selecteur du segment  ou se trouve la GDT
        ;ebx=adresse de base

mov ebx,eax
and ebx,01FFFh
shl bx,3          ;ds:bx=adresse de base du descripteur
mov al,[bx+4]
mov ah,[bx+7]
shl eax,16
mov ax,[bx+2]     ;charge la base du segment
mov ebx,eax
ret

;******************************************************************************
;donn?es pour le segment de donn?es                      **********************

msgsyst:
include "DN_MSG.ASM"

polgraf:
include "DN_POLG.ASM"

palgraf:
include "DN_PALG.ASM"

tabclv:
include "DN_CLAV.ASM"

tabacc:
include "DN_ACC.ASM"

fintab:
 

;******************************************************************************
;segment de code recopi? dans le segment             **************************
start:
org 0h
use32

mov dx,seldat      ;init pile et data
mov ds,dx
mov es,dx
mov fs,dx
mov gs,dx

mov dx,selpil
mov ss,dx
mov esp,0FFF0h




sti      ;init des valeurs termin?, d?bloquage des irq


;*********************************************************************
;configure le port com1 

;mov ah,0                   
;mov al,2                                             
;mov ecx,9600                                         
;mov bl,8                                             
;mov bh,0                                             
;int 66h                                              


;**********************************************************************
;programme souris ps/2

mov ax,seldat    ;charge les info souris de base
mov ds,ax
mov byte[nbts1],03          ;nombre d'octet de la trame souris


call at8042ok 
mov al,0A8h     ;activation de la souris ps/2   
out 64h,al

call at8042ok 
mov al,0D4h     ;la prochaine commande sera pour la souris
out 64h,al            

call at8042ok
cli
mov al,0FFh      ;commande souris > reset souris
out 60h,al            
or byte[atts1],01h  ;met a 1 le bit ack attendu
sti
call atacks
jc err_init_souris

cli
or byte[atts1],01h  ;met a 1 le bit ack attendu
sti
call atacks
jc err_init_souris

cli
or byte[atts1],01h  ;met a 1 le bit ack attendu
sti
call atacks
jc err_init_souris

call at8042ok 
mov al,0D4h     ;la prochaine commande sera pour la souris
out 64h,al            

call at8042ok
cli
mov al,0F4h      ;commande souris > active le data reporting 
out 60h,al            
or byte[atts1],01h  ;met a 1 le bit ack attendu
sti
call atacks
jnc fin_init_souris

err_init_souris:   ;(au cas ou qq chose aurais merdé lors de l'init souris)     
in al,64h
test al,1
jz fin_init_souris
in al,60h
jmp err_init_souris

fin_init_souris:

;**********************************************************************
;initialise les zones de taille variable

mov ax,seldat
mov ds,ax
mov ax,selramh
mov es,ax


mov ecx,8000h
call resmem
jc errallocmem
es
mov word[ebx+8],czm_zj      ;code zone journal
add ebx,10h             ;ne pas oublier de ne pas compter sur le descripteur
mov dword[ad_jcsl],ebx
mov dword[max_jcsl],ecx     ;journal mode console

mov ecx,8000h
call resmem
jc errallocmem
es
mov word[ebx+8],czm_hc      ;code historique de commande
add ebx,10h             ;ne pas oublier de ne pas compter sur le descripteur
es
mov dword[ebx],0     ;marque la fin de la liste
mov dword[ad_hc],ebx
mov dword[max_hc],ecx     

mov ecx,10000h  ;64ko
call resmem
jc errallocmem
es
mov word[ebx+8],czm_dfo      ;code descripteur de fichier ouvert
add ebx,10h             ;ne pas oublier de ne pas compter sur le descripteur
mov dword[ad_ficho],ebx
mov dword[max_ficho],ecx  

mov ecx,8000h  ;32ko
call resmem
jc errallocmem
es
mov word[ebx+8],czm_ztf1      ;code de la zt lecture fat 1 
add ebx,10h             ;ne pas oublier de ne pas compter sur le descripteur
mov dword[ad_fat1],ebx
mov dword[max_fat1],ecx
mov byte[dsq_fat1],0FFh  

mov ecx,8000h  ;32ko
call resmem
jc errallocmem
es
mov word[ebx+8],czm_ztf2      ;code de la zt lecture fat 2
add ebx,10h             ;ne pas oublier de ne pas compter sur le descripteur
mov dword[ad_fat2],ebx
mov dword[max_fat2],ecx
mov byte[dsq_fat2],0FFh  

mov ecx,2048
call resmem
jc errallocmem
es
mov word[ebx+8],czm_ztlef      ;zone tampon lecture/ecriture fichier
add ebx,10h             
mov [ad_zt_lecluster],ebx

mov edi,port_com_base    ;réserve les zones zompon pour la reception sur port com
boucle_zt_rec_com:
xor ebx,ebx
cmp word[edi],0
je ignore_zt_rec_com
mov ecx,400h  ;1ko
call resmem
jc ignore_zt_rec_com
es
mov word[ebx+8],czm_com ;code de zone système mémoire pour reception sur port com
ignore_zt_rec_com:
mov [edi+port_com_zt-port_com_base],ebx
mov dword[edi+port_com_to-port_com_base],0
add edi,4
cmp edi,port_lpt_base
jne boucle_zt_rec_com

mov ecx,8000h  ;32ko
call resmem
jc errallocmem
es
mov word[ebx+8],czm_dpu     ;descripteurs péripherique USB
add ebx,10h             
mov dword[ad_descusb],ebx
mov dword[max_descusb],ecx

mov ecx,8000h  ;32ko
call resmem
jc errallocmem
es
mov word[ebx+8],czm_ztu      ;zone tampon USB
add ebx,10h             
mov dword[ad_ztusb],ebx
mov dword[max_ztusb],ecx 

call maj_console0
jmp detecte_usb_sata


errallocmem:
mov ax,seldat
mov ds,ax
mov ax,selvidB8
mov es,ax

mov cl,47
mov ah,07h
xor ebx,ebx
mov edx,ad_msg-1

boucle1_errallocmem:
inc edx
cmp cl,0
je boucle2_errallocmem
cmp byte[edx],0
jne boucle1_errallocmem
dec cl
jmp boucle1_errallocmem

boucle2_errallocmem:
mov al,[edx]
es
mov [ebx],ax
add ebx,2
cmp ebx,8000h
je infini_errallocmem
cmp al,0
je boucle2_errallocmem
inc edx
jmp boucle2_errallocmem

infini_errallocmem:
sti
nop
jmp infini_errallocmem



;*********************************************************************
;detecte les controleurs USB et SATA
detecte_usb_sata:
mov ebx,80000008h
mov esi,desc_ctrl_usb
boucletcusb:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx
cmp ax,0FFFFh
je pasctrl
mov edx,eax
;and eax,0FFFFFF00h 
;cmp eax,01060100h  ;classe=01h sous-classe=06h  if=01
;je ctrl_ahci            ;AHCI
and eax,0FFFF0000h 
cmp eax,0C030000h  ;classe=0Ch sous-classe=03h
jne pasctrl

cmp dh,00h          ;UHCI
je ctrl_uhci
cmp dh,10h          ;OHCI
je ctrl_ohci
cmp dh,20h          ;EHCI
je ctrl_ehci
cmp dh,30h          ;XHCI
je ctrl_xhci
jmp pasctrl

ctrl_uhci:
mov dx,0CF8h
mov eax,ebx
add eax,18h ;pour avoir l'adresse de base des ports
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,1  ;on vérifie que c'est bien un descripteur de port d'e/s
jz pasctrl
and eax,0FFE0h
mov [esi+4],eax  ;adresse de base du controleur
mov eax,ebx
and eax,0FFFF00h
shr eax,8
mov [esi+2],ax  ;coordonnée PCI
mov byte[esi],1 ;controleur de type uhci
mov byte[esi+1],2 ;deux port

push ebx
mov eax,0FFFh
mov ecx,1000h   ;4096 octets
call resmemg   ;réserve une place pour la frame list uhci 
es
mov word[ebx+8],czm_flu   ;code pour frame list uhci 
add ebx,100010h   ;adresse physique
mov [esi+8],ebx
pop ebx 

add esi,10h
jmp pasctrl

ctrl_ohci:
xor eax,eax
mov [esi+4],eax  ;adresse de base du controleur
mov eax,ebx
and eax,0FFFF00h
shr eax,8
mov [esi+2],ax  ;coordonnée PCI
mov byte[esi],2 ;controleur de type ohci
add esi,16
jmp pasctrl

ctrl_ehci:
mov dx,0CF8h
mov eax,ebx
add eax,8 ;pour avoir l'adresse de base des ports
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,1  ;on vérifie que c'est bien un descripteur de port d'e/s
;jnz pasctrl
and eax,0FFFFFFF0h
mov [esi+4],eax  ;adresse de base du controleur
mov eax,ebx
and eax,0FFFF00h
shr eax,8
mov [esi+2],ax  ;coordonnée PCI
mov byte[esi],3 ;controleur de type ehci
add esi,16
jmp pasctrl

ctrl_xhci:
xor eax,eax
mov [esi+4],eax  ;adresse de base du controleur
mov eax,ebx
and eax,0FFFF00h
shr eax,8
mov [esi+2],ax  ;coordonnée PCI
mov byte[esi],4 ;controleur de type xhci
add esi,16
jmp pasctrl


ctrl_ahci:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§


pasctrl:
add ebx,100h
test ebx,7F000000h
jz boucletcusb


;**********************************************************************
;réinitialise le controleur disquette
mov ax,seldat
mov es,ax
mov ds,ax
mov byte[pos_cyl_disq],0FFh  ;position de la tête indeterminé

mov dx,3F7h ;mode 500000 bit/s
mov al,00h
out dx,al

mov dx,3F2h ;reinitialisation du controleur disquette
mov al,00h
out dx,al

;**********************************************************************
;lit les info disque ata et met a jour les info de partitions
mov ch,10h
mov esi,ad_descd

boucle_init_infopart:
mov al,10
mov edi,bootsecteur
push cx
int 64h          ;charge les info disque
pop cx
cmp eax,0
je init_infodisque_ata


;mov al,10
;mov edi,bootsecteur
;push cx
;add ch,8
;int 64h          ;si ça ne fonctionne pas on réessaye en ATAPI
;pop cx
;cmp eax,0
;jne pasinfopart


;mov byte[esi],1
jmp pasinfopart


init_infodisque_ata:

mov eax,[bootsecteur+0C8h]   ;LSB nombre de secteur en LBA48 
mov edx,[bootsecteur+0CCh]   ;MSB nombre de secteur en LBA48 
cmp edx,0
je init_infodisque_lba28
test eax,0C0000000h
jz init_infodisque_lba28
mov byte[esi],4
mov [esi+8],eax
mov [esi+12],edx
jmp init_infopart

init_infodisque_lba28:
mov eax,[bootsecteur+78h]   ;nombre de secteur en LBA28
cmp eax,0
je init_infodisque_chs
mov byte[esi],3
mov [esi+8],eax
mov dword[esi+12],0
jmp init_infopart
 


init_infodisque_chs:
mov eax,[bootsecteur+72h]   ;nombre de secteur en CHS
mov byte[esi],2
mov [esi+8],eax
mov dword[esi+12],0
push ecx
xor eax,eax
xor ecx,ecx
mov ax,[bootsecteur+70h]   ;secteur par piste
mov cx,[bootsecteur+6Eh]   ;nombre de tête
mov [esi+2],ax
mul ecx
mov [esi+4],eax       ;nombre de secteur par cylindre
pop ecx


init_infopart:
mov al,8
mov edi,bootsecteur
push cx
mov cl,1
xor ebx,ebx
int 64h           ;charge le mbr disque
pop cx
cmp eax,0
jne pasinfopart

mov esi,bootsecteur+1BEh ;esi=1er octet du descripteur de la partition
call exbasepart    ;1er partition
add esi,10h
call exbasepart    ;2eme partition
add esi,10h
call exbasepart    ;3eme partition
add esi,10h
call exbasepart    ;4eme partition  (fonction dans sf_disk.asm)

pasinfopart:
inc ch
add esi,32
cmp ch,18h
;jne boucle_init_infopart                 §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§!!!désactivé temporairement pour rendre la vitesse de démarrage plus rapide


;*******************************************************************
;fin de la séquence d'initialisation
mov cl,0
call affmsgsyst     ;rapel sur la version installé

mov dword[ad_ztcmd+0],0
mov dword[ad_ztcmd+2],"ex #"   ;execution du script d'amorçage
mov dword[ad_ztcmd+6],"dm/C"
mov dword[ad_ztcmd+10],"FG.T"
mov word[ad_ztcmd+14],"XT"
mov byte[ad_ztcmd+16],0
mov word[to_ztcmd],17

mov dword[ad_tache_exec],0
mov word[id_tache_exec],0
mov byte[cpttc],25
or byte[at_csl],0Fh ;signale que l'affichage complet de la console doit être mis a jour

;**********************************************************************
;tache principale

btacheprincipale:    ;boucle de la tache principale
mov dx,seldat      ;init segment de donn?e
mov ds,dx
mov es,dx
mov fs,dx
mov gs,dx


;***************************************************************************
;gestion des entrées clavier du mode console

mov al,5
int 63h
cmp al,0
je majafcsl

or byte[at_csl],08h ;signale que l'affichage de la commande doit être mis a jour

xor edx,edx
xor edi,edi
mov dx,[cu_cce]  ;edx=position du curseur de la chaine 
mov di,[to_cce]  ;edi=taille actuelle de la chaine 

cmp al,44
je entrcsl
cmp al,100
je entrcsl
cmp al,79
je supprcsl
cmp al,30
je backcsl
cmp al,85
je avcsl
cmp al,83
je rccsl
cmp al,82
je ligne_m
cmp al,84
je ligne_p
cmp al,78
je ligne_mm
cmp al,81
je ligne_pp
cmp al,77
je ligne_debut
cmp al,80
je ligne_fin
cmp al,08h
je cmd_prec
cmp al,09h
je cmd_suiv


test ecx,0FFFFFFE0h
jz pasconsole

cmp ecx,80h   ;-de 7 bit
jb insert1
cmp ecx,800h  ;-de 11 bits
jb insert2
cmp ecx,10000h  ;-de 16 bits
jb insert3
cmp ecx,200000h   ;-de 21 bits
jb insert4
jmp pasconsole

insert1:
inc edi
cmp edi,255
jae pasconsole      ;verifie que la chaine n'est pas pleine
mov [to_cce],di   ;maj de la taille occup?
mov eax,ecx
xor ecx,ecx
mov cx,[to_cce]
sub cx,[cu_cce]   ;calcul la diff?rence entre la taille occup? et la position curseur
cmp ecx,0
je pas_decal_ins1
add edi,ad_cce
mov esi,edi
dec esi
std
rep movsb          ;d?cale les donn?es
pas_decal_ins1:

and eax,7Fh         ;transformation du caract?re
mov [edx+ad_cce],al  ;?crit le caract?re
inc word[cu_cce]    ;maj de la position curseur
jmp majafcsl

insert2:
add edi,2
cmp edi,255
jae pasconsole      ;verifie que la chaine n'est pas pleine
mov [to_cce],di   ;maj de la taille occup?
mov eax,ecx
xor ecx,ecx
mov cx,[to_cce]
sub cx,[cu_cce]   ;calcul la diff?rence entre la taille occup? et la position curseur
cmp ecx,0
je pas_decal_ins2
add edi,ad_cce
mov esi,edi
sub esi,2
std
rep movsb          ;d?cale les donn?es

pas_decal_ins2:

mov ecx,eax
and al,3Fh
or al,80h
mov [edx+ad_cce+1],al
shr ecx,6
mov al,cl
and al,01Fh
or al,0C0h
mov [edx+ad_cce],al
add word[cu_cce],2    ;maj de la position curseur
jmp majafcsl


insert3:
add edi,3
cmp edi,255
jae pasconsole      ;verifie que la chaine n'est pas pleine
mov [to_cce],di   ;maj de la taille occup?
mov eax,ecx
xor ecx,ecx
mov cx,[to_cce]
sub cx,[cu_cce]   ;calcul la diff?rence entre la taille occup? et la position curseur
cmp ecx,0
je pas_decal_ins3
add edi,ad_cce
mov esi,edi
sub esi,3
std
rep movsb          ;d?cale les donn?es
pas_decal_ins3:

mov ecx,eax
and al,3Fh
or al,80h
mov [edx+ad_cce+2],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [edx+ad_cce+1],al
shr ecx,6
mov al,cl
and al,0Fh
or al,0E0h
mov [edx+ad_cce],al
add word[cu_cce],3    ;maj de la position curseur
jmp majafcsl

insert4:
add edi,4
cmp edi,255
jae pasconsole      ;verifie que la chaine n'est pas pleine
mov [to_cce],di   ;maj de la taille occup?
mov eax,ecx
xor ecx,ecx
mov cx,[to_cce]
sub cx,[cu_cce]   ;calcul la diff?rence entre la taille occup? et la position curseur
cmp ecx,0
je pas_decal_ins4
add edi,ad_cce
mov esi,edi
sub esi,3
std
rep movsb          ;décale les données
pas_decal_ins4:

mov ecx,eax
and al,3Fh
or al,80h
mov [edx+ad_cce+3],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [edx+ad_cce+2],al
shr ecx,6
mov al,cl
and al,3Fh
or al,80h
mov [edx+ad_cce+1],al
shr ecx,6
mov al,cl
and al,07h
or al,0F0h
mov [edx+ad_cce],al
add word[cu_cce],4    ;maj de la position curseur
jmp majafcsl

;***************************************************
entrcsl:
;rajoute un zéro a la fin
xor ebx,ebx
mov bx,[to_cce]
add ebx,ad_cce
mov byte[ebx],0

;envoie la commande dans la fifo des commandes a executer
mov al,0
mov edx,ad_cce
int 61h

mov byte[num_cmd],03Fh   ;décale les données dans l'historique de commande
                         
xor edx,edx
mov dx,[to_cce]
inc edx          ;taille du trou faire
mov ecx,[max_hc]
sub ecx,edx      ;taille des données a décaler

mov edi,[ad_hc]
add edi,[max_hc]
dec edi
mov esi,edi
sub esi,edx
push ds
push es
mov ax,selramh
mov ds,ax
mov es,ax
std          ;set direction flag (pour inverser le sens d'incrementation de movsb
rep movsb
pop es
pop ds

;recopie la nouvelle commande au début l'historique
push es
mov ax,selramh
mov es,ax
xor ecx,ecx
mov cx,[to_cce]
mov esi,ad_cce
mov edi,[ad_hc]
cld
rep movsb       
xor al,al
stosb        ;et rajoute un octet zéro a la fin
pop es



xor cx,cx
mov [to_cce],cx
mov [cu_cce],cx    ;et efface les pointeur de la comande précédente
jmp majafcsl


;***************************************
backcsl:
cmp edx,0
je pasconsole
recobackcsl:
dec edx
mov ah,[ad_cce+edx]
and ah,11000000b
cmp ah,80h
je recobackcsl

supprcsl:
cmp edi,edx
je pasconsole
mov ebp,edi
recosupprcsl:
mov esi,edx
mov ecx,ebp
add esi,ad_cce
sub ecx,edx
mov edi,esi
dec ecx
cmp ecx,0
je pas_decal_supprcsl
inc esi
cld
rep movsb
pas_decal_supprcsl:
dec ebp
cmp ebp,edx
je finsuprcsl
mov ah,[ad_cce+edx]
and ah,11000000b
cmp ah,80h
je recosupprcsl
finsuprcsl:
mov [to_cce],bp
mov [cu_cce],dx
jmp majafcsl 

avcsl:
cmp edx,edi
je pasconsole
recoavcsl:
inc edx
mov ah,[ad_cce+edx]
and ah,11000000b
cmp ah,80h
je recoavcsl
mov [cu_cce],dx 
jmp majafcsl

rccsl:
cmp edx,0
je pasconsole
recorccsl:
dec edx
mov ah,[ad_cce+edx]
and ah,11000000b
cmp ah,80h
je recorccsl
mov [cu_cce],dx 
jmp majafcsl

ligne_m:
cmp word[no_ligne_jcsl],0
je majafcsl
dec word[no_ligne_jcsl]
and byte[at_csl],0DFh    ;met a zero le bit "on doit afficher la fin du journal
or byte[at_csl],02h ;signale que l'affichage du journal doit être mis a jour
jmp majafcsl

ligne_p:
inc word[no_ligne_jcsl]
and byte[at_csl],0DFh    ;met a zero le bit "on doit afficher la fin du journal
or byte[at_csl],02h ;signale que l'affichage du journal doit être mis a jour
jmp majafcsl

ligne_mm:
cmp word[no_ligne_jcsl],7
jna ligne_debut
sub word[no_ligne_jcsl],8
and byte[at_csl],0DFh    ;met a zero le bit "on doit afficher la fin du journal
or byte[at_csl],02h ;signale que l'affichage du journal doit être mis a jour
jmp majafcsl

ligne_pp:
add word[no_ligne_jcsl],8   ;8 ça suffit
and byte[at_csl],0DFh    ;met a zero le bit "on doit afficher la fin du journal
or byte[at_csl],02h ;signale que l'affichage du journal doit être mis a jour
jmp majafcsl

ligne_debut:
mov word[no_ligne_jcsl],0
and byte[at_csl],0DFh    ;met a zero le bit "on doit afficher la fin du journal
or byte[at_csl],02h ;signale que l'affichage du journal doit être mis a jour
jmp majafcsl


ligne_fin:
or byte[at_csl],020h    ;met a un le bit "on doit afficher la fin du journal
or byte[at_csl],02h ;signale que l'affichage du journal doit être mis a jour
jmp majafcsl

cmd_prec:      ;remplit la zone de commande en cours de r?daction par la commande pr?c?dente
inc byte[num_cmd]
and byte[num_cmd],03Fh ;on ne peut afficher que les 64 derni?res commandes
jmp recop_cmd


cmd_suiv:
cmp byte[num_cmd],3Fh
je majafcsl
dec byte[num_cmd]
and byte[num_cmd],03Fh ;on ne peut afficher que les 64 derni?res commandes

recop_cmd:
mov bx,selramh
mov fs,bx

mov ebx,[ad_hc]   ;on recherche la commande qui se trouve dns l'historique
mov cl,[num_cmd]
boucl_recmd:
cmp cl,0
je cmdoke
fs
cmp word[ebx],0
je max_recmd
fs
cmp byte[ebx],0
jne pzcmd
dec cl
pzcmd:
inc ebx
jmp boucl_recmd

max_recmd:
dec byte[num_cmd]
and byte[num_cmd],03Fh ;on ne peut afficher que les 64 derni?res commandes
jmp recop_cmd

cmdoke:         ;on recopie dans la zt commande en cours de r?daction
mov edi,ad_cce
boc_rec_hc:
fs
mov al,[ebx]
mov [edi],al
inc ebx
inc edi
cmp al,0
jne boc_rec_hc

fin_rec_hc:
sub edi,ad_cce
dec edi          ;et on ne compte ps le z?ro finale
mov [to_cce],di
mov [cu_cce],di

;****************************************************************************
;mise a jour affichage console syst?me

majafcsl:


mov bx,selramh
mov ds,bx
mov bx,seldat
mov es,bx
es
test byte[at_csl],02h ;y'a t'il eu modification de l'affichage du journal de la console?
jz finafj
es
and byte[at_csl],0FDh ;désactive le besoin de mettre a jour la commande
es
or byte[at_csl],01h ;signale que l'affichage doit être mis a jour

es
mov edx,[ad_jcsl]
es
mov ebp,[to_jcsl]  
add ebp,edx       ;ebp=adresse de la fin du journal
es
mov cx,[no_ligne_jcsl]
es
mov byte[coul_car],07h ;initialise la couleur du premier caract?re par defaut
xor ebx,ebx

bcherchedebj:         ;recherche le d?but de la zone a afficher dans le fichier journal
cmp cx,0
je bcafj
cmp byte[edx],13  ;est ce une fin de ligne?
jne debj_pasfl
dec cx
jmp debj_pascoul

debj_pasfl:
mov al,[edx]
and al,0F0h
cmp al,10h
jne debj_pascoul
mov al,[edx]
and al,0Fh
es
mov [coul_car],al

debj_pascoul:
inc edx
cmp edx,ebp           ;est ce que l'on est arrivé a la fin du journal?
jb bcherchedebj

es
dec word[no_ligne_jcsl]  ;si oui on recule d'une ligne
es
mov edx,[ad_jcsl]
es
mov cx,[no_ligne_jcsl]
es
and byte[at_csl],0DFh  ;on desactive l'obligation de visionner la fin du journal
jmp bcherchedebj        ;et on recommence

bcafj:          ;boucle d'affichage journal           
cmp edx,ebp      ;test si on est arriv? a la fin du journal syst?me 
jae bouclevj
call lireutf8
cmp eax,13
jne testbcj    ;en cas de CR(code ASCII 13)  afficher le reste de la ligne vide     

bcaflv:
mov eax,20h 
mov ch,07h
call affcarac
inc ebx
es
cmp ebx,[ad_afrep]
je verifscroll
push edx
mov eax,ebx
xor edx,edx
xor ecx,ecx
es
mov cx,[resxt]
div ecx
mov eax,edx
pop edx
cmp eax,0
jne bcaflv
jmp bcafj


testbcj:
mov ecx,eax
and ecx,0FFFFFFF0h
cmp ecx,10h
jne affcarj
and al,0Fh
es
mov [coul_car],al
jmp bcafj

affcarj:
es
mov ch,[coul_car]
call affcarac

inc ebx
es
cmp ebx,[ad_afrep]      ;test si on est arriv? a la fin de la zone d'affichage authoris?
je verifscroll
jmp bcafj


bouclevj:   ;si le journal est plus petit que l'affichage du reste on affiche du vide
mov eax,20h
mov ch,07h
call affcarac
inc ebx
es
cmp ebx,[ad_afrep]
jne bouclevj
es             
or byte[at_csl],020h      ;rajoute le besoin d'afficher la fin du journal
jmp finafj

verifscroll:               ;test si on avai besoin d'afficher la fin du journal
es             
test byte[at_csl],020h      
jz finafj                 
cmp edx,ebp      ;test si on est arriv? a la fin du journal 
jae finafj
es
inc word[no_ligne_jcsl]   ;si on avait besoin on descend d'une ligne
es
or byte[at_csl],02h ;signale que l'affichage journal doit être mis a jour
jmp majafcsl              ;et on recommence


finafj:


;**************************************
;affiche le répertoire de travail
mov bx,seldat
mov ds,bx

test byte[at_csl],04h
jz finafr
and byte[at_csl],0FBh ;désactive le besoin de mettre a jour la commande
or byte[at_csl],01h ;signale que l'affichage doit être mis a jour

mov edx,ad_repertoire
mov ebx,[ad_afrep]

bcafr:            
call lireutf8
cmp eax,0
je bouclevr
mov ch,0Ah
call affcarac
inc ebx
cmp ebx,[ad_afcmd]
je finafr
jmp bcafr

bouclevr:   ;si le repertoire est plus petit que l'affichage du reste on affiche du vide
mov eax,20h
mov ch,07h
call affcarac
inc ebx
cmp ebx,[ad_afcmd]
jne bouclevr

finafr:


;**************************************
;affiche la commande
test byte[at_csl],08h
jz finafc
and byte[at_csl],0F7h ;désactive le besoin de mettre a jour la commande
or byte[at_csl],01h ;signale que l'affichage doit être mis a jour

mov edx,ad_cce
mov ebx,[ad_afcmd]
xor esi,esi
xor edi,edi
mov si,[cu_cce]
mov di,[to_cce]
add esi,edx
add edi,edx

bcafc:            ;affichge de la commande
cmp edx,esi
jne pascurcmd
call curtext
pascurcmd:
cmp edx,edi
je bouclevc
call lireutf8
cmp eax,0
je bouclevc
mov ch,07h
call affcarac
inc ebx
cmp ebx,[ad_afin]
je finafc
jmp bcafc

bouclevc:   ;si la commande est plus petite que l'affichage du reste on affiche du vide
mov eax,20h
mov ch,07h
call affcarac
inc ebx
cmp ebx,[ad_afin]
jne bouclevc

finafc:




;***************************************************************************
;mise a jour de l'écran
maj_ecran:
include "SF_MAJV.ASM"
fin_majv:


;***************************************************************************
;traitement des lignes de commande

pasconsole:
mov dx,seldat  
mov ds,dx
mov es,dx
cmp word[to_ztcmd],0   ;la fifo des commandes est elle vide?
je pascommande
xor edi,edi
mov esi,ad_ztcmd+2 ;les deux premier octet contienne l'ID de la tache qui a emise la commande
mov di,[to_ztcmd]
add edi,esi
bcrecfincmd:
cld
lodsb
cmp al,0
je fincomtrouve
cmp esi,edi
jne bcrecfincmd

mov word[to_ztcmd],0
jmp pascommande 

fincomtrouve:          
mov ax,[ad_ztcmd]     ;charger l'ID de l'emetteur de la commande
mov [id_zdc],ax

sub esi,ad_ztcmd+2    ;charger la commande dans la zone de préraitement 
mov ecx,esi
mov eax,esi       ;sauvegarde de la quantité
add eax,2         ;+2   
mov esi,ad_ztcmd+2
mov edi,ad_zdc
cld
rep movsb

;décaler le fifo des commandes
mov edi,ad_ztcmd
xor ecx,ecx
mov cx,[to_ztcmd]
sub ecx,eax
cmp ecx,0
je fifocmdvide
cld
rep movsb            

fifocmdvide:
sub edi,ad_ztcmd
mov [to_ztcmd],di   ;mettre a jour la taille de la fifo  

;supprimer l'eventuelle zone de vide au début
boucle_supprime_vide:
cmp byte[ad_zdc]," "
jne fin_boucle_supprime_vide
mov esi,ad_zdc
mov edi,esi
inc esi
mov ecx,1FFh
cld
rep movsb
jmp boucle_supprime_vide
fin_boucle_supprime_vide:

;metre en minuscule le nom de la commande et les codes d'option
mov esi,ad_zdc
mov al,0
correction_casse:

cmp byte[esi],":"  
jne stop_correction_casse1
mov al,1
stop_correction_casse1:

cmp byte[esi]," "  
jne stop_correction_casse2
mov al,1
stop_correction_casse2:

cmp byte[esi],"-"  
jne redemarre_correction_casse1
mov al,0
redemarre_correction_casse1:

cmp al,1
je pascorcasse
cmp byte[esi],"A"  
jb pascorcasse
cmp byte[esi],"Z"
ja pascorcasse
add byte[esi],20h
pascorcasse:
inc esi
cmp esi,ad_zdc+200h
jne correction_casse

;cherche si il s'agit d'une commande de base
cmp byte[ad_zdc+2],0
je commande2
cmp byte[ad_zdc+2]," "
je commande2
cmp byte[ad_zdc+2],":"
je commande2
cmp byte[ad_zdc+2],"-"
je commande2
cmp byte[ad_zdc+3],0
je commande3
cmp byte[ad_zdc+3]," "
je commande3
cmp byte[ad_zdc+3],":"
je commande3
cmp byte[ad_zdc+3],"-"
je commande3
cmp byte[ad_zdc+4],0
je commande4
cmp byte[ad_zdc+4]," "
je commande4
cmp byte[ad_zdc+4],":"
je commande4
cmp byte[ad_zdc+4],"-"
je commande4

jmp commande_fichier


commande4:
mov eax,[ad_zdc]  
cmp eax,"modv"
je cmdmodv
cmp eax,"stop"
je cmdstop
cmp eax,"cd.."
je cmdcdpp

jmp commande_fichier


commande3:
mov eax,[ad_zdc]  
and eax,0FFFFFFh
cmp eax,"ver"
je cmdver
cmp eax,"efj"
je cmdefj
cmp eax,"dir"
je cmddir
cmp eax,"fix"
je cmdfix
cmp eax,"mtt"
je cmdmtt
cmp eax,"cop"
je cmdcop
cmp eax,"sup"
je cmdsup
cmp eax,"ren"
je cmdren
jmp commande_fichier


commande2:
mov ax,[ad_zdc]  
cmp ax,"cd"
je cmdcd
cmp ax,"af"
je cmdaf
cmp ax,"lt"
je cmdlt
cmp ax,"lm"
je cmdlm
cmp eax,"ld"
je cmdld
cmp eax,"lv"
je cmdlv
cmp eax,"ex"
je cmdex
cmp eax,"1s"
je cmd1s

commande_fichier:
include "SF_TACHE.ASM"

;****************************************************************
;commande integré de listage
include "CI_LISTE.ASM"

;****************************************************************
cmdmodv:       ;modification mode video


;verification qu'aucune fenetre n'est ouverte
mov ax,selramh
mov es,ax
xor ebx,ebx
boucle_modv0:
es
cmp byte[ebx+type_dm],"F"
je modv_0fen
es
cmp byte[ebx+type_dm],"T"
jne modv_pas_t
es
cmp word[ebx+sel_ecranv],0
jne fonc_video_nok
modv_pas_t:
es
mov eax,[ebx+to_tache]
add ebx,eax
jmp boucle_modv0 
modv_0fen:


mov edx,ad_zdc          ;recherche la chaine qui coresspond au numéros de mode
boucle_modv1:
cmp byte[edx]," "
jne suite_boucle_modv1
cmp byte[edx+1]," "
jne id_modv
suite_boucle_modv1:
inc edx
cmp edx,ad_zdc+200h
je erreurcommandeparam
jmp boucle_modv1

;convertit l'id en entier 16 bit
id_modv:
inc edx
mov eax,101
int 61h
test ecx,0FFFF0000h
jnz erreurmodv

call vesa_infomode    ;lit les informations du mode video
cmp ax,004Fh
jne erreurmodv

;verifie que c'est du mode texte, chainé, ou direct color
cmp byte[infovesa+1Bh],0 ;texte
je ok_mem_modv
cmp byte[infovesa+1Bh],4 ;chainé
je ok_mem_modv
cmp byte[infovesa+1Bh],6 ;couleur directe
je ok_mem_modv
jmp erreurmodv
ok_mem_modv:



;verifie que c'est un mode texte, 8,15,16,24,32bit par pixel
cmp byte[infovesa+19h],0 ;texte
je ok_col_modv
cmp byte[infovesa+19h],8 
je ok_col_modv
cmp byte[infovesa+19h],15 
je ok_col_modv
cmp byte[infovesa+19h],16 
je ok_col_modv
cmp byte[infovesa+19h],24 
je ok_col_modv
cmp byte[infovesa+19h],32 
je ok_col_modv
jmp erreurmodv
ok_col_modv:

;si le mode est compatible avc le linear frame buffer, on l'active
test dword[infovesa],080h
jz pasdelinear
or cx,4000h
pasdelinear:


call vesa_mode        ;passe dans le mode
cmp ax,004Fh
jne erreurmodv

;maj les info sur le mode video en court
and cx,1FFh
mov [mdvc],cx
or byte[at_csl],0Fh ;signale que l'affichage de la console doit être mis a jour

test dword[infovesa],10h ;on teste si on est un mode texte ou pas
jz cmdmodv_texte


mov ax,[infovesa+12h]    ;maj des resolutions
mov bx,[infovesa+14h]
mov [resx],ax
shr ax,3
mov [resxt],ax
mov [resy],bx
shr bx,4
mov [resyt],bx

mov cx,[infovesa+10h]
mov [octpl],cx


mov al,[infovesa+19h] 
mov [bitpp],al    ;bit par pixel	
inc al;pour que l'opération suivante fonctionne avec 15
shr al,3
mov [octpp],al    ;octet par pixel

test dword[infovesa],080h
jz banked_cmdmodv

or word[at_csl],10h     ;met le bit 4 a un (bit utilisation du linear frame buffer)
push ds
mov ebx,[infovesa+28h] ;adresse de base du linear frame buffer
mov eax,sellfb
mov ecx,0FFFFFFFFh  ;limite   
mov dx,selgdt
mov ds,dx     
mov dl,02h       ;segment de données ring 0
call creeds
pop ds
jmp fin_cmdmodv

cmdmodv_texte:
mov ax,[infovesa+12h]    ;maj des resolutions
mov bx,[infovesa+14h]
mov [resx],ax
mov [resxt],ax
mov [resy],bx
mov [resyt],bx
mov byte[bitpp],00
jmp fin_cmdmodv



banked_cmdmodv:
and word[at_csl],0FFEFh    ;met le bit 4 a zéro (bit utilisation du linear frame buffer)
push ds
mov ebx,0A0000h ;adresse de base de la ram video en banked
mov eax,sellfb
mov ecx,01FFFFh  ;limite   
mov dx,selgdt
mov ds,dx     
mov dl,02h       ;segment de données ring 0
call creeds
pop ds

fin_cmdmodv:
mov ax,[resx]   ;met la souris au centre
mov bx,[resy]
shr ax,1
shr bx,1
mov [xs1],ax
mov [ys1],bx

xor eax,eax     ;initialise les positions de la console
xor ecx,ecx
xor edx,edx
mov ax,[resyt]
mov cx,[resxt]
mul ecx
mov [ad_afin],eax   ;numéro du dernier caractère affichable 
sub eax,ecx
sub eax,ecx
mov [ad_afcmd],eax  ;numéro du premier caractère qui sert a ecrire la commande en cours (-2 lignes)
sub eax,ecx
mov [ad_afrep],eax ;numéro du premier caractère qui sert a ecrire le dossier en cours (-3 lignes)

call maj_console0
jmp pascommande

erreurmodv:
mov cl,7
call affmsgsyst
jmp pascommande

fonc_video_nok:
mov cl,9
call affmsgsyst
jmp pascommande

;****************************************************************
cmdver:       ;affichage information version systême
mov cl,0
call affmsgsyst
jmp pascommande

;****************************************************************
cmdefj:             ;efface le journal de la console
mov dword[to_jcsl],0
mov word[no_ligne_jcsl],0
or byte[at_csl],2      ;met a 1 le bit de mise a jour affichage journal
jmp pascommande

;****************************************************************
cmddir:             ;liste le contenue du repertoire courant
include "CI_DIR.ASM"

;****************************************************************
cmdfix:             ;enregisre le dossier actuel comme étant le dossier systeme

;recopie l'adresse
mov ax,seldat
mov ds,ax
mov es,ax
mov esi,ad_repertoire
mov edi,ad_repsys
mov ecx,512
cld
rep movsb

;recopie le descripteur de fichier
mov esi,[ad_ficho]
mov ax,selramh
mov ds,ax
mov es,ax
mov edi,esi
add edi,20h
mov ecx,20h
cld
rep movsb   ;déplacement

jmp pascommande

;********************************************
cmdren:
mov edx,ad_zdc

boucle1_cmdren:     ;trouve le debut du nom du fichier
cmp byte[edx],0
je err3cmdsup          ;si on arrive a la fin de la chaine c'est une erreur
inc edx
cmp byte[edx]," "
jne boucle1_cmdren          
cmp byte[edx+1]," "
je boucle1_cmdren          

inc edx
mov esi,edx

boucle2_cmdren:     ;trouve le debut du nouveau nom du fichier
cmp byte[edx],0
je err3cmdsup          ;si on arrive a la fin de la chaine c'est une erreur
inc edx
cmp byte[edx],":"
jne boucle2_cmdren   

mov byte[edx],0
inc edx
mov edi,edx

xor eax,eax         ;ouvre le fichier
xor ebx,ebx
mov edx,esi
int 64h
cmp eax,0       
je suite_cmdren
cmp eax,12       
je suite_cmdren
jmp err3cmdsup

suite_cmdren:
mov al,7   ;modifie les données du nom de fichier
mov ah,0
mov edx,edi
int 64h
cmp eax,0       
je pascommande
cmp eax,cer_dnv       
je err2cmdsup
jmp err1cmdsup


;********************************************
cmdsup:
mov edx,ad_zdc

boucle_cmpsup:     ;trouve le debut du nom du fichier
cmp byte[edx],0
je err3cmdsup          ;si on arrive a la fin de la chaine c'est une erreur
inc edx
cmp byte[edx]," "
jne boucle_cmpsup           
cmp byte[edx+1]," "
je boucle_cmpsup           

inc edx
xor eax,eax         ;ouvre le fichier
xor ebx,ebx
int 64h
cmp eax,0       
je suite_cmdsup
cmp eax,12       
je suite_cmdsup
jmp err3cmdsup

suite_cmdsup:
mov eax,3
int 64h
cmp eax,0       
je pascommande
cmp eax,cer_dnv       
je err2cmdsup

err1cmdsup:
mov cl,3     ;erreur de lecture
call affmsgsyst
jmp pascommande

err2cmdsup:
mov cl,90    ;dossier non vide
call affmsgsyst
jmp pascommande

err3cmdsup:
mov cl,91   ;fichier non trouvé
call affmsgsyst
jmp pascommande

;********************************************
cmdcop:
jmp pascommande



;****************************************************************
cmdcd:          ;change le répertoire courant (inclue la commande cd..)
include "CI_CD.ASM"

;****************************************************************
cmdaf:
mov al,1Fh
call affcj
;mov al,"["
;call affcj
;mov ax,[id_zdc]
;call affh1j
;mov al,"]"
;call affcj   ;affiche l'id de la tache qui a emise cette commande


mov edx,ad_zdc
boucle_cmdaf:
cmp byte[edx]," "
je fin_cmdaf
inc edx
cmp edx,ad_zdc+200h
jne boucle_cmdaf
jmp pascommande

fin_cmdaf:
inc edx
call affjournal
mov al,17h
call affcj
mov al,13
call affcj
jmp pascommande

;**************************************************************
cmdex:

mov edx,ad_zdc
boucle1_cmpex:     ;trouve le debut du nom du fichier
cmp byte[edx],0
je err3cmdsup          ;si on arrive a la fin de la chaine c'est une erreur
inc edx
cmp byte[edx]," "
jne boucle1_cmpex           
cmp byte[edx+1]," "
je boucle1_cmpex           

inc edx
xor eax,eax         ;ouvre le fichier
xor ebx,ebx
int 64h
cmp eax,0       
jne err3cmdsup

;lit la taille du fichier
mov al,6
mov ah,1
mov edx,ad_chaine_travail
int 64h
cmp eax,0
jne err3cmdsup

;vérifie que le fichier n'est pas trop grand
mov ecx,[ad_chaine_travail]
;mov eax,1024
;cmp ecx,eax
;jne err3cmdsup

;réserve une zt de taille suffisante
push ebx
push ecx
add ecx,1Fh
and ecx,0FFFFFFF0h
call resmem
pop ecx
pop edx
jc err3cmdsup
xchg ebx,edx         ;edx=adresse de base ebx=adresse du fichier

    


;lit le fichier
push edx
mov ax,selramh
mov ds,ax
mov es,ax
mov al,4
mov edi,edx
xor edx,edx
add edi,16
int 64h
pop edx
cmp eax,0
jne err3cmdsup




;convertit toute les caractère <20h en caractère NULL
add ecx,16
mov edi,edx
mov esi,edx
add edi,16
add esi,ecx
boucle2_cmpex:
cmp byte[edi],20h
jae cmdex_flnd
mov byte[edi],0

cmdex_flnd:
inc edi
cmp edi,esi
jne boucle2_cmpex

;envoie les commandes
mov edi,edx
mov esi,edx
add edi,16
add esi,ecx

push edx     ;envoie la première ligne
mov edx,edi
mov al,0
int 61h
pop edx

boucle3_cmpex:
cmp byte[edi],0
jne passe_cmdex
cmp byte[edi+1],0
je passe_cmdex

push edx          ;envoie les autres
mov edx,edi
inc edx
mov al,0
int 61h
pop edx


passe_cmdex:
inc edi
cmp edi,esi
jne boucle3_cmpex

mov ebx,edx
call libmem
jmp pascommande


;****************************************
cmd1s:
mov ecx,[cptsf]
add ecx,400

boucle_cmd1s:
int 62h
cmp ecx,[cptsf]
ja boucle_cmd1s




;jmp pascommande


;********************************************************
;gestion du moteur de la disquette

pascommande:
mov ax,seldat
mov ds,ax
test byte[at_fc_fichier],04h   ;on test si le moteur disquette est allumé
jz pasarretmoteurdisquette 
mov eax,[temp_moteur_disq]
cmp [cptsf],eax
jna pasarretmoteurdisquette
mov dx,3F2h   ;délais dépassé, on eteint le moteur
mov al,04h
out dx,al
and byte[at_fc_fichier],0FBh   ;on signal que le moteur de la disquette est éteint
pasarretmoteurdisquette:

;********************************
hlt
jmp btacheprincipale




;********************************************************************
;sous fonctions de manipulation journal


affcj:      ;ajoute un caractère dans le journal
push eax
push edx
push ds
push es
cli
mov dx,seldat
mov ds,dx
mov dx,selramh
mov es,dx

testjok:
mov edx,[to_jcsl]
inc edx
cmp edx,[max_jcsl]
jne okaffcj
call efflignej
jmp testjok 

okaffcj:
xor edx,edx
mov edx,[to_jcsl]
add edx,[ad_jcsl]
es
mov [edx],al
inc dword[to_jcsl]
or byte[at_csl],02h
sti
pop es
pop ds
pop edx
pop eax
ret

efflignej:       ;efface la première ligne du journal
push ecx
push esi
push edi
push ds
push es
push fs
mov cx,selramh
mov ds,cx
mov es,cx
mov cx,seldat
mov fs,cx

fs
mov esi,[ad_jcsl]
fs
mov ecx,[to_jcsl]
mov edi,esi   ;edi et esi= debut du journal
add ecx,esi   ;ecx=limite max du journal

boucl1erligne:
cmp byte[esi],13
je trouvligne2
inc esi
cmp esi,ecx
jne boucl1erligne

fs                    ;on a pas trouv? le d?but de la deuxi?me ligne avant
mov dword[to_jcsl],0  ;d'avoir ateint la fin du journal donc on efface le journal 
fs
mov word[no_ligne_jcsl],0
jmp finefflignej

trouvligne2:
inc esi            ;esi=d?but de la ligne nø2
mov ecx,esi
sub ecx,edi        ;ecx=taille de la ligne 1
fs
sub [to_jcsl],ecx  ;on la retire de la taille du journal
fs
mov ecx,[to_jcsl]  ;et on d?cale les donn?es
cld
rep movsb

fs                          ;si le num?ros de la premi?re ligne a afficher 
cmp word[no_ligne_jcsl],0   ;n'est pas nul on l'ajuste
je finefflignej
fs
dec word[no_ligne_jcsl]

finefflignej:
pop fs
pop es
pop ds
pop edi
pop esi
pop ecx
ret

affmsgsyst:   ;affiche le message systême nø=cl
push ecx
push edx
push ds
push fs
mov dx,seldat
mov ds,dx
mov fs,dx

mov edx,ad_msg
bclrecmsg:
cmp cl,0
je suitemsg
cmp byte[edx],0
jne paszeromsg
dec cl
paszeromsg:
inc edx
jmp bclrecmsg

affjournal:  ;copie chaine asciiz adress? par ds:edx dans le journal console
push ecx
push edx
push ds
push fs
mov cx,seldat
mov fs,cx

suitemsg:
mov al,[edx]
cmp al,0
je fin_affjournal
call affcj
inc edx
jmp suitemsg

fin_affjournal:
pop fs
pop ds
pop edx
pop ecx
ret

affnj:     ;affiche le chiffre eax en décimal
push eax
push ebx
push ecx
push edx

mov dl,"$"
push dx

mov ecx,10

boucle_nj:
xor edx,edx
div ecx
add dl,"0"
push dx
cmp eax,0
jne boucle_nj

boucle_afnj:
pop ax
cmp al,"$"
je fin_nj
call affcj
jmp boucle_afnj

fin_nj:
pop edx
pop ecx
pop ebx
pop eax
ret


affnje:     ;affiche le chiffre eax en décimal avec des espaces
push eax
push ebx
push ecx
push edx
push si

mov dl,"$"
push dx

mov ecx,10
xor si,si

boucle_nje:
xor edx,edx
div ecx
add dl,"0"
push dx
inc si
cmp si,3
jne psespcenje
xor si,si
mov dl," "    ;signe entres groupe de 3 chiffre
push dx
psespcenje: 
cmp eax,0
jne boucle_nje

boucle_afnje:
pop ax
cmp al,"$"
je fin_nje
call affcj
jmp boucle_afnje

fin_nje:
pop si
pop edx
pop ecx
pop ebx
pop eax
ret

affh0j:      ;affiche dans le journal la valeur de al en hexad?cimal
push ax
mov ah,al
shr al,4
and ax,0F0Fh
cmp al,9
jna alpasa
add al,7 
alpasa:
cmp ah,9
jna ahpasa
add ah,7
ahpasa:
add al,"0"
add ah,"0"
call affcj
mov al,ah
call affcj
pop ax
ret

affh1j:      ;affiche dans le journal la valeur de ax en hexad?cimal
push eax
xchg ah,al
call affh0j
mov al,ah
call affh0j
pop eax
ret

affh2j:     ;affiche le chiffre eax en hexad?cimal
push eax
push edx
mov dx,ax
shr eax,16
xchg ah,al
call affh0j
mov al,ah
call affh0j
mov al,dh
call affh0j
mov al,dl
call affh0j
pop edx
pop eax
ret




;***************************************************************************************
;fonction de lecture de chaine UTF8


lireutf8:      ;lit le caractère utf8 en ds:edx et le copie dans eax, incrémente edx pour passer au caractère suivant
push cx
debut_lireutf8:
mov al,[edx]
test al,080h
jz lutf1ch
test al,040h
jz lutf0ch
test al,020h
jz lutf2ch
test al,010h
jz lutf3ch
test al,08h
jz lutf4ch

lutf0ch:
inc edx
jmp debut_lireutf8

lutf1ch:
and eax,07Fh
inc edx
jmp fin_lireutf8

lutf2ch:
xor eax,eax
mov al,[edx]
and al,1Fh
shl eax,6
mov cl,[edx+1]
and cl,3Fh
or al,cl
add edx,2
jmp fin_lireutf8

lutf3ch:
xor eax,eax
mov al,[edx]
and al,0Fh
shl eax,6
mov cl,[edx+1]
and cl,3Fh
or al,cl
shl eax,6
mov cl,[edx+2]
and cl,3Fh
or al,cl
add edx,3
jmp fin_lireutf8

lutf4ch:
xor eax,eax
mov al,[edx]
and al,07h
shl eax,6
mov cl,[edx+1]
and cl,3Fh
or al,cl
shl eax,6
mov cl,[edx+2]
and cl,3Fh
or al,cl
shl eax,6
mov cl,[edx+3]
and cl,3Fh
or al,cl
add edx,4

fin_lireutf8:
pop cx
ret



;****************************************************************************************
;fonctions video utilisé par la tache principale

affcarac:
;eax=carac
;ebx=position  (colonne + ligne * nombre de caractère par ligne)
;ch=couleur
pushad
push ds

and eax,0FFFFFFh
mov dx,selconsole
mov ds,dx 
shl ebx,2
add ebx,[ad_texte]
mov [ebx],eax
mov [ebx+3],ch
pop ds
popad
ret


curtext: ;place le curseur a la même position que ebx 
pushad
push ds
mov ax,selconsole
mov ds,ax
shl ebx,2
add ebx,[ad_texte]
mov [ad_curseur_texte],ebx
pop ds
popad
ret

;********************************************************************
;sous fonction exploration de commande

fchoption:     ;cherche l'option cl=première lettre ch=2eme lettre(ou zéro si pas de deuxième lettre)
push ds       ;retour cf=1 si trouve ebx=adresse de l'octet dans la zt_pdc 
mov bx,seldat
mov ds,bx
mov ebx,ad_zdc 

cmp ch,0
jne bchoption2

bchoption1:
cmp [ebx+1],cl
jne nokoption1
cmp byte[ebx],"-"
je optiontrv
nokoption1:
inc ebx
cmp ebx,ad_zdc+200h
jne bchoption1
xor ebx,ebx
clc
pop ds
ret

bchoption2:
cmp [ebx+1],cx
jne nokoption2
cmp byte[ebx],"-"
je optiontrv
nokoption2:
inc ebx
cmp ebx,ad_zdc+200h
jne bchoption2
xor ebx,ebx
clc
pop ds
ret


optiontrv:
inc ebx
sub ebx,ad_zdc 
stc
pop ds
ret






;*********************************************************************
;sous fonctions manipulation de la gdt/ldt

modbgp:  ;modifie la base d'un descripteur de segment
        ;ax=num?ros du d?scripteur (13bit)
        ;ds=selecteur du segment  ou se trouve la GDT
        ;ebx=adresse de base

xchg eax,ebx
and ebx,01FFFh
shl bx,3          ;ds:bx=adresse de base du descripteur
mov [bx+2],ax     ;charge la base du segment
shr eax,16
mov [bx+4],al
mov [bx+7],ah
ret

creeds: ;créer ou modifie un descripteur de segment GDT ou LDT
        ;ds:eax=adresse du descripteur
        ;ebx=adresse de base
        ;ecx=limite
        ;dl=option       type=0123 d/b=7 l=6 dpl=45

push eax
push ebx
push ecx
push edx

xchg eax,ebx
mov [ebx+2],ax     ;charge la base du segment
shr eax,16
mov [ebx+4],al
mov [ebx+7],ah

test ecx,0FFF00000h  ;charge la limite du segment
jz creeds_g
shr ecx,12
or ecx,800000h
creeds_g:
mov [ebx],cx     ;lsb de la limite
shr ecx,16
mov dh,dl
shr dh,1
and dh,40h
or cl,dh        ;rajoute l'option d/b (16 ou 32bis)
mov dh,dl
shr dh,2
and dh,10h
or cl,dh        ;rajoute l'option l (ou avl) 
and cl,0DFh
mov [ebx+6],cl

mov dh,dl
and dx,300Fh
shl dh,1
or dl,dh
or dl,90h     ;p et s mis a 1
mov [ebx+5],dl

pop edx
pop ecx
pop ebx
pop eax
ret



;***************************************************************************
;**************************************************                        *
;fonctions système                               ;*                        *
                                                 ;*                        *
                                                 ;**************************



;**********************************************************************************
include "SF_MEM.ASM"   ;sous fonction sytème pour la gestion des espaces mémoires


at8042ok:        ;attend la fin du traitement des donn?es par la puce 8042
in al,64h
test al,2
jnz at8042ok
ret

atacks:        ;attend que la souris ait re?u un octet
push ecx
mov ecx,[cptsf]
add ecx,400     ;ajoute 1 seconde   ;ecx=temp limite a attendre

batacks:
cmp ecx,[cptsf]
jb eratacks         ;si temp max inf a compteur sans fin on arrete d'attendre
test byte[atts1],01
jnz batacks

clc            ;pas d'erreur cf=0
pop ecx
ret

eratacks:      ;en cas d'errerur mettre cf a 1
stc
pop ecx
ret


;***************************************************************************
;**************************************************                        *
;gestionnaires d'exceptions                      ;*                        *
                                                 ;*                        *
                                                 ;**************************
iex0:
mov cx,0
jmp exsig

iex1:
mov cx,1
jmp exsig

iex2:
mov cx,2
jmp exsig

iex3:
mov cx,3
jmp exsig

iex4:
mov cx,4
jmp exsig

iex5:
mov cx,5
jmp exsig

iex6:
mov cx,6
jmp exsig

iex7:
mov cx,7
jmp exsig

iex8:
mov cx,8
jmp exsig

iex9:
mov cx,9
jmp exsig

iexA:
mov cx,10
jmp exsig

iexB:
mov cx,11
jmp exsig

iexC:
mov cx,12
jmp exsig

iexD:
mov cx,13
jmp exsig

iexE:
mov cx,14
jmp exsig

iexF:
mov cx,15
jmp exsig

iex10:
mov cx,16
jmp exsig

iex11:
mov cx,17
jmp exsig

iex12:
mov cx,18
jmp exsig

iex13:
mov cx,19
jmp exsig

iex14:
mov cx,20
jmp exsig

iex15:
mov cx,21
jmp exsig

iex16:
mov cx,22
jmp exsig

iex17:
mov cx,23
jmp exsig

iex18:
mov cx,24
jmp exsig

iex19:
mov cx,25
jmp exsig

iex1A:
mov cx,26
jmp exsig

iex1B:
mov cx,27
jmp exsig

iex1C:
mov cx,28
jmp exsig

iex1D:
mov cx,29
jmp exsig

iex1E:
mov cx,30
jmp exsig

iex1F:
mov cx,31

exsig:  ;exception: signale et stoppe

mov dx,seldat      ;init pile et data
mov ds,dx
mov es,dx
mov fs,dx
mov gs,dx
mov dx,selpil
mov ss,dx
mov esp,[sauv_esp0]
sub esp,10h         ;pour avoir une pile sans ecraser la pile de la tache systême
push cx

mov cl,42
call affmsgsyst


mov ax,[id_tache_exec]
call affh1j

mov cl,43
call affmsgsyst

pop cx
add cx,10
call affmsgsyst

mov ax,[id_tache_fichier]
cmp [id_tache_exec],ax
jne excep_fc_ok
and byte[at_fc_fichier],0FEh
excep_fc_ok:

cmp word[id_tache_exec],0 ;si c'est une tache de base on l'arrete
je redem_id0
mov cl,45
call affmsgsyst
jmp int_60

redem_id0:  ;sinon on redemarre la tache principale
mov dword[ad_tache_exec],0
mov word[id_tache_exec],0
mov byte[cpttc],25
mov cl,44
call affmsgsyst
mov esp,0FFFCh
sti
jmp selcod:btacheprincipale











;***************************************************************************
;**************************************************                        *
;gestionnaires d'IRQ                             ;*                        *
                                                 ;*                        *
                                                 ;**************************
;pour l'irq de la tempo, voir sf_tache.asm 


irqcla:
cli
push eax
push ebx
push ecx
push edx
push ds

mov ax,seldat
mov ds,ax
in al,60h
cmp al,0FEh      ;? je ne me souviens plus pourquoi
je finircl
cmp al,0FAh
jne nackcla
mov al,[attcl]
test al,40h
jz finircl
and al,0BFh
mov [attcl],al
and al,07h
out 60h,al

finircl:
mov al,20h
out 20h,al   ;(End Of Interrupt)
pop ds
pop edx
pop ecx
pop ebx
pop eax
sti
iret

nackcla:
shr dword[ztcl],8
mov [ztcl+3],al
xor cx,cx
bclintcl1:
mov bx,cx
shl bx,4
mov edx,[ad_tabclav+bx]
cmp [ztcl],edx
je press
or edx,80808080h
cmp [ztcl],edx
je depress
inc cx
test cx,0FF80h
jz bclintcl1

xor cx,cx
bclintcl2:
mov bx,cx
shl bx,4
mov eax,[ztcl+1]
and eax,00FFFFFFh
mov edx,[ad_tabclav+bx]
cmp eax,edx
je press
or edx,808080h
cmp eax,edx
je depress
inc cx
test cx,0FF80h
jz bclintcl2

xor cx,cx
bclintcl3:
mov bx,cx
shl bx,4
mov ax,[ztcl+2]
mov dx,[ad_tabclav+bx]
cmp ax,dx
je press
or dx,8080h
cmp ax,dx
je depress
inc cx
test cx,0FF80h
jz bclintcl3

xor cx,cx
bclintcl4:
mov bx,cx
shl bx,4
mov ax,[ztcl+3]
mov dx,[ad_tabclav+bx]
cmp al,dl
je press
or dl,80h
cmp al,dl
je depress
inc cx
test cx,0FF80h
jz bclintcl4
jmp finircl

depress:
mov bx,cx
mov ch,cl
and cl,07h
mov al,01h
shl al,cl
shr bx,3
mov ah,[atbp+bx]
not al
and ah,al
mov [atbp+bx],ah
mov cl,ch
xor ch,ch

cmp cx,71           ;touche alt g    (num?ros de touche -1)
je depressalt
cmp cx,73           ;touche alt d    
je depressalt
jmp finircl


depressalt:
cmp dword[sv_alt],0  ;on verifie si il y as un caractère qui as été 
je finircl
mov eax,[sv_alt]
mov dword[sv_alt],0
jmp ajoute_carac_zt

press:
mov bx,cx
mov ch,cl
and cl,07h
mov al,01h
shl al,cl
shr bx,3
mov ah,[atbp+bx]
or ah,al
mov [atbp+bx],ah
mov cl,ch
xor ch,ch

cmp cx,85     ;touche spéciale verr num    (numéros de touche -1)
je touche_num
cmp cx,44     ;touche spéciale verr maj
je touche_maj
cmp cx,14     ;touche spéciale arret defil
je touche_scroll
cmp cx,15     ;touche spéciale pause
je touche_pause
cmp cx,10
je touche_retour_console ;f10
cmp cx,11
je touche_ecran_moins   ;f11
cmp cx,12
je touche_ecran_plus    ;f12
cmp cx,104
je touche_retour_console ;list d
cmp cx,102
je touche_ecran_moins   ;win G
cmp cx,103
je touche_ecran_plus    ;win D

cmp cx,89    ;touche 7 pave numerique
je touche7_pavenum
cmp cx,90    ;touche 8 pave numerique
je touche8_pavenum
cmp cx,91    ;touche 9 pave numerique
je touche9_pavenum
cmp cx,93    ;touche 4 pave numerique
je touche4_pavenum
cmp cx,94    ;touche 5 pave numerique
je touche5_pavenum
cmp cx,95    ;touche 6 pave numerique
je touche6_pavenum
cmp cx,96    ;touche 1 pave numerique
je touche1_pavenum
cmp cx,97    ;touche 2 pave numerique
je touche2_pavenum
cmp cx,98    ;touche 3 pave numerique
je touche3_pavenum
cmp cx,100   ;touche 0 pave numerique
je touche0_pavenum

cmp cx,78     ;touche suppr
jne pas_touche_sp
mov ax,[atbp+8h]
test ax,0440h
jz pas_touche_sp 
test ax,0280h
jz pas_touche_sp 
jmp selcod16:reboot ;rebouter via le mode réel



pas_touche_sp:
xor ebx,ebx
mov bx,cx
shl ebx,4
test byte[atbp+8h],80h  ;alt
jnz tkalt
test byte[atbp+9h],02h  ;alt gr
jnz tkalt


test byte[atbp+7h],02h
jnz tkmaj
test byte[atbp+8h],20h
jnz tkmaj
test byte[attcl],04h
jnz tkvmaj

tknorm:
mov eax,[ad_tabclav+ebx+4]
jmp fintk

tkmaj:
test byte[attcl],04h
jnz tknorm

tkvmaj:
mov eax,[ad_tabclav+ebx+8]
jmp fintk

tkalt:
mov eax,[ad_tabclav+ebx+12]

fintk:
inc cx            ;cl= numéros de touche eax=caractère
xor ch,ch

mov bl,[atbp+7h]
and bl,02h   ;majG
shr bl,1
or ch,bl

mov bl,[atbp+8h]
and bl,20h   ;majD
shr bl,4
or ch,bl

mov bl,[atbp+8h]
and bl,40h   ;CtrlG
shr bl,4
or ch,bl

mov bl,[atbp+9h]
and bl,04h   ;CtrlD
shl bl,1
or ch,bl

mov bl,[atbp+8h]
and bl,80h   ;Alt
shr bl,3
or ch,bl

mov bl,[atbp+9h]
and bl,02h   ;Alt Gr
shl bl,4
or ch,bl

;ch=touches spéciale pressé   0=majG 1=majD 2=CtrlG 3=CtrlD 4=Alt 5=AltGr

cmp eax,0
je ajoute_carac_zt
cmp dword[sv_chas],0
je verifie_chasse

mov ebx,ad_tabaccent                            ;comme il y as un caractère de chasse enregistré, on verifie si il n'y as pas une correspondance
mov edx,[sv_chas]
boucle_recherche_correspondance_chasse:
cmp [ebx],edx
jne chasse_suivante
cmp [ebx+4],eax
je correspondance_chasse_trouve
chasse_suivante:
cmp dword[ebx],0
je correspondance_chasse_pastrouve
add ebx,12
cmp ebx,ad_tabaccent+1020
jne boucle_recherche_correspondance_chasse

correspondance_chasse_pastrouve:
push eax
mov eax,[sv_chas]
mov dword[sv_chas],0 
xor ebx,ebx              ;ajoute le caractère de casse dans la ZT clavier
cmp byte[nb_zrc],42
je ignore_aj_chasse
mov bl,[nb_zrc]
inc byte[nb_zrc]
mov edx,ebx      ;mul ebx par 6
shl ebx,2
shl edx,1
add ebx,edx
mov [ebx+zt_rcl],cx
mov [ebx+zt_rcl+2],eax
ignore_aj_chasse:
pop eax
jmp ajoute_carac_zt

correspondance_chasse_trouve:
mov dword[sv_chas],0 
mov eax,[ebx+8]
jmp ajoute_carac_zt



verifie_chasse:     ;verifie que le caractère correspond a un caractère de chasse qui est présent dans la liste
mov ebx,ad_tabaccent
boucle_recherche_chasse:
cmp dword[ebx],0
je ajoute_carac_zt 
cmp [ebx],eax
jne pas_chasse_trouve
mov [sv_chas],eax
jmp bougled
pas_chasse_trouve:
add ebx,12
cmp ebx,ad_tabaccent+1020
jne boucle_recherche_chasse

ajoute_carac_zt:
xor ebx,ebx              ;ajoute le caractère dans la ZT clavier
cmp byte[nb_zrc],42
je bougled
mov bl,[nb_zrc]
inc byte[nb_zrc]
mov edx,ebx      ;mul ebx par 6
shl ebx,2
shl edx,1
add ebx,edx
mov [ebx+zt_rcl],cx
mov [ebx+zt_rcl+2],eax

bougled:
mov al,0EDh       ;commande led
out 60h,al
or byte[attcl],40h
jmp finircl


touche_num:
xor byte[attcl],02h
jmp bougled

touche_maj:
xor byte[attcl],04h
jmp bougled

touche_scroll:
xor byte[attcl],01h
jmp bougled

touche_pause:
xor byte[attcl],10h
jmp bougled

touche0_pavenum:
xor ebx,ebx
jmp touche_pavenum
touche1_pavenum:
mov ebx,1
jmp touche_pavenum
touche2_pavenum:
mov ebx,2
jmp touche_pavenum
touche3_pavenum:
mov ebx,3
jmp touche_pavenum
touche4_pavenum:
mov ebx,4
jmp touche_pavenum
touche5_pavenum:
mov ebx,5
jmp touche_pavenum
touche6_pavenum:
mov ebx,6
jmp touche_pavenum
touche7_pavenum:
mov ebx,7
jmp touche_pavenum
touche8_pavenum:
mov ebx,8
jmp touche_pavenum
touche9_pavenum:
mov ebx,9

touche_pavenum:
mov ax,[atbp+8h]
test ax,0280h
jz pas_touche_sp 

xor edx,edx
mov eax,[sv_alt]
mov ecx,10
mul ecx
add eax,ebx
mov [sv_alt],eax
jmp finircl 



touche_retour_console: ;f10
mov al,0
out 61h,al        ;éteint le bipper
xor ax,ax ;selectionne la tache principale comme tache a afficher
xor edx,edx

charge_ecran:
mov bx,seldat
mov ds,bx
mov [id_tache_af],ax
mov [ad_tache_af],edx
or byte[at_csl],1      ;met a 1 le bit de mise a jour affichage
mov byte[nb_zrc],0    ;efface la zt de reception souris
jmp bougled

touche_ecran_moins:   ;f11
xor ebx,ebx ;recherche la tache précédente
mov cx,[id_tache_af]
mov ax,selramh
mov ds,ax
xor edx,edx

boucle_touche_ecran_moins:
cmp byte[ebx+type_dm],"F"
je trouve_ecran_moins
cmp byte[ebx+type_dm],"T"
jne pas_touche_ecran_moins
cmp word[ebx+sel_ecranv],0
je pas_touche_ecran_moins

cmp [ebx+id_tache],cx
je trouve_ecran_moins
mov edx,ebx
         
pas_touche_ecran_moins:
mov eax,[ebx+to_tache]
add ebx,eax
jmp boucle_touche_ecran_moins 

trouve_ecran_moins:
cmp edx,0
je retour_ecran0
mov ax,[edx+id_tache]
jmp charge_ecran

touche_ecran_plus:    ;f12
mov edx,[ad_tache_af] ;recherche la tache suivante
mov ax,selramh
mov ds,ax
mov eax,[edx+to_tache]
add edx,eax

boucle_touche_ecran_plus:
cmp byte[edx+type_dm],"F"
je retour_ecran0
cmp byte[edx+type_dm],"T"
jne pas_touche_ecran_plus
cmp word[edx+sel_ecranv],0
je pas_touche_ecran_plus

mov ax,[edx+id_tache]
jmp charge_ecran

pas_touche_ecran_plus:
mov eax,[edx+to_tache]
add edx,eax
jmp boucle_touche_ecran_plus


retour_ecran0:
xor ax,ax          ;selectionne la tache principale comme tache a afficher
xor edx,edx
jmp charge_ecran


irqsouris:
push ax
push bx
push si
push ds

mov bx,seldat
mov ds,bx

test byte[atts1],01h ;test si un ack est atendu
jz pasacks
in al,60h
and byte[atts1],0FEh
jmp finirqs

pasacks:
mov bl,[nbzt1]       ;charge le nombre d'octet déja reçu
xor bh,bh
mov si,bx
inc bl
mov [nbzt1],bl       ; et l'incrémente
in al,60h
mov [zts1+si],al    ;met le caractère reçu dans la zt souris
cmp [nbts1],bl
jne finirqs         ;si la trame n'as pas été totalement reçu -> fin


xor al,al            ;on décode, d'abord mettre le compteur de la trame a zéros
mov [nbzt1],al

mov al,[zts1]       ;extrait le déplacement en x
xor bh,bh
mov bl,[zts1+1]
test al,10h
jz noadjx1
not bh
noadjx1:
add [xs1],bx      ;et l'additionne (c'est un nombre signé)

xor bh,bh         ;extrait le déplacement en y
mov bl,[zts1+2]
test al,20h
jz noadjy1
not bh
noadjy1:
sub [ys1],bx     ;et l'additionne (c'est un nombre signé)

mov ax,[xs1]                     ;ajuste la position x de la souris par
cmp ax,[resx]                    ;rapport a la résolution de l'écran
jng passupxs1
mov ax,[resx]
passupxs1:
cmp ax,0
jnl pasinfxs1
mov ax,0
pasinfxs1:
mov [xs1],ax

mov ax,[ys1]                   ;ajuste la position y de la souris par
cmp ax,[resy]                  ;rapport a la résolution de l'écran
jng passupys1
mov ax,[resy]
passupys1:
cmp ax,0
jnl pasinfys1
mov ax,0
pasinfys1:
mov [ys1],ax

;**************************************
;que faire du "clic"
mov al,[zts1]    
test al,1
jz stopbip
mov al,3
out 61h,al        ;allume le bipper
jmp finirqs

stopbip:
mov al,0
out 61h,al        ;?teint le bip
;**************************************

finirqs:
mov al,20h
out 0A0h,al
mov al,20h
out 20h,al
pop ds
pop si
pop bx
pop ax
sti
iret




;********************************
;irq non gérés, acquitement simple


irq8:
irq9:
irqA:
irqB:
irqC:
irqD:
irqE:
irqF:
push ax
mov al,20h
out 0A0h,al
pop ax
irq0:
irq1:
irq2:
irq3:
irq4:
irq5:
irq6:
irq7:
push ax
mov al,20h
out 20h,al
pop ax
sti
iret

;***************************************************************************
;**************************************************                        *
;interruption systeme                            ;*                        *
                                                 ;*                        *
                                                 ;**************************

;int_60 -> voir sf_tache.asm  arret de la tache (pas d'argument)


int_61:  ;fonctions système générale
include "SF_GEN.ASM"


int_62:              ;commutation de tache pour le multitache coopératif (pas d'argument)
cli
push eax
push ds
jmp commutation

int_63:             ;fonction interface
include "SF_VID.ASM" 
iret

int_64:
include "SF_FICH.ASM" ;fonction générales et système de fichier
include "SF_DISK.ASM" ;fonction de lecture disques

int_65: ;communication inter tache 
include "SF_COM.ASM"
iret

int_66:
include "SF_PORT.ASM"

int_67:
iret

int_68:
include "SF_USB.ASM"

int_69:
int_6A:
int_6B:
int_6C:
int_6D:
int_6E:
int_6F:
iret




include "SF_RM.ASM"   ;appel fonctions bios avec retour en mode réel

;***************************************************************************
;données systèmes figées
r_idt:
dw 0x3ff		
dd 0	
p_idt:
dw 07FFh
dd segidt*16
p_gdt:
dw 0FFFFh
dd seggdt*16

rb 16

rb 16 - ($ + start)mod 16   ;pour que le fichier ait une granulométrie de 16 octet


finsegcod:
db "DMF?"
dd 0,0,0
