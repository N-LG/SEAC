org 0h

;3eme étage du démarrage, code recopié par l'etage 2 en 5000h:0000h puis executé en mode réel




include "DN_VARS.ASM"   ;declaration des constantes numériques

;**************************************************************
;vide la ram de 0003 0000h à 0004 FFFFh
xor ax,ax
mov ds,ax
mov ebx,30000h
xor eax,eax

boucleefreg:
mov [ebx],eax
add ebx,4
cmp ebx,50000h
jne boucleefreg


;**********************************************************************
;initiallise les données systemes
mov ax,segdat    
xor dx,dx       
mov ds,ax
mov es,dx


es                       ;récupère la taille de la ram trouvé par l'étage 2
mov eax,[7C00h]
mov [nb_ram],eax



mov word[resxt],80           ;charge les info video: mode texte 80x25 au d?but ;-)
mov word[resyt],25
mov byte[bitpp],00
mov word[resx],640
mov word[resy],400
mov word[xs1],320
mov word[ys1],200


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


mov dword[max_table_exec],16  ;initialise la liste des tache


es               ;copie les adresse de base des ports com et lpt detecté par le bios
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





es
test byte[417h],20h        ;active verr num si le bios l'as activé
jz vernumoff
mov byte[attcl],02h         
vernumoff:


;initialise variables de la fonction lecture disquette
es
test byte[410h],01h        ;test la présence d'au moin un lecteur disquette
jz floppyoff
or byte[at_fc_fichier],10h
mov word[sec_piste_disq],18
mov word[nb_piste_disq],80
mov word[sec_cyl_disq],36
floppyoff:

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



mov cx,512    ;copie la table de correspondance scan code PS2 vers num touche
mov ax,cs
mov ds,ax
mov si,touche_codeps2
mov ax,segdat
mov es,ax
mov di,ad_tabclav_code
cld
rep movsb      ;ds:si vers es:di



mov cx,256    ;copie la table de correspondance code usb vers num touche
mov ax,cs
mov ds,ax
mov si,touche_usb
mov ax,segdat
mov es,ax
mov di,ad_tabclav_usb
cld
rep movsb      ;ds:si vers es:di



mov cx,2048    ;copie la table de correspondance touche/caractères
mov ax,cs
mov ds,ax
mov si,touche_carac
mov ax,segdat
mov es,ax
mov di,ad_tabclav_carac
cld
rep movsb      ;ds:si vers es:di



mov cx,fintabacc-tabacc   ;copie la table des accents
mov ax,cs
mov ds,ax
mov si,tabacc
mov ax,segdat
mov es,ax
mov di,ad_tabclav_chasse
cld
rep movsb      ;ds:si vers es:di


mov cx,messages_erreur-messages_systeme    ;copie la table des messages systeme
mov ax,cs
mov ds,ax
mov si,messages_systeme
mov ax,segdat
mov es,ax
mov di,ad_msg_syst
cld
rep movsb    


mov cx,fin_messages-messages_erreur    ;copie la table des messages d'erreur
mov ax,cs
mov ds,ax
mov si,messages_erreur
mov ax,segdat
mov es,ax
mov di,ad_msg_erreur
cld
rep movsb    


mov cx,256        ;copie le bitmap du curseur graphique
mov ax,cs
mov ds,ax
mov si,curseur8bit
mov ax,segdat
mov es,ax
mov di,ad_curseur_defaut
cld
rep movsb   


;**********************************************
;**** charge le code 

mov ecx,finsegcod    ;copie le segment de code a l'endroit pr?vu
mov ax,cs
mov ds,ax
mov esi,start
mov ax,segcod
mov es,ax
xor edi,edi
;cld
;rep movsb      ;ds:si vers es:di

;push ds
;mov ax,segdat
;;mov ds,ax
;mov ax,cs
;mov [20000h],esi
;mov [20000h+4],ax
;pop ds

boucle_copie_code:
mov al,[esi]
es
mov [edi],al
inc esi
inc edi
dec ecx
jnz boucle_copie_code



;**********************************************************************
; préparation du mode protégé


mov dx,seggdt     ;on va configurer la gdt
mov ds,dx
xor ebx,ebx
mov [0],ebx
mov [4],ebx    ;descripteur nul (obligatoire)

mov ax,1            ;selecteur 1: code du programme
mov ebx,segcod*16
mov ecx,01FFFFh
mov dl,08Ah       ;segment de code lisible en 32bits
call crgdt

mov ax,2
mov ebx,segdat*16       ;segment de donn?es du programme
mov ecx,03FFFFh    ;256kibi
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

;mov ax,6        
;mov ebx,???????
;mov ecx,???????
;mov dl,02h       ;segment de donn?es en lect/ecr
;call crgdt

;mov ax,7        
;mov ebx,???????
;mov ecx,???????
;mov dl,02h       ;segment de donn?es en lect/ecr
;call crgdt

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

mov ax,16          ;TSS
mov ebx,segdat*16+ad_tss
mov ecx,02200h
mov dl,039h ;segment de TSS  en 32 bits           ;dl=option       type=0123 d/b=7 l=6 dpl=45
call crgdt
and byte[16*8+5],0EFh   ;met a 0 le bit S du descripteur de TSS (sinon le descripteur n'est pas valide)
;or byte[16*8+6],10h ;met le bit AVL a 1

;*******************************************************
;chargement des vecteurs d'interruption


mov dx,segidt      ;modifie l'idt
mov ds,dx
mov si,selcod
mov es,si
mov dl,06Eh

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

;interrruptions vides 20h a 2Fh
mov esi,int_vide
mov al,20h
boucle_setint1:
call cridt  
inc al
cmp al,30h
jne boucle_setint1 


;**************IRQ
mov al,30h       ;ensuite les IRQ
mov esi,irqtmp   ;l'irq déclenché ar le PIT
call cridt 
mov al,31h
mov esi,irqcla   ;l'irq déclenché par le clavier
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
mov esi,irqsouris   ;l'irq déclenché par la souris ps/2
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



;interrruptions vides 40h a 5Fh
mov esi,int_vide
mov al,40h
boucle_setint2:
call cridt  
inc al
cmp al,60h
jne boucle_setint2 



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
mov al,70h
mov esi,int_70   ;voir dans sf_tache
call cridt 
mov al,71h
mov esi,int_71   ;voir dans sf_tache
call cridt 
 

;interrruptions vides 72h a FFh
mov esi,int_vide
mov al,72h
boucle_setint3:
call cridt  
inc al
cmp al,0
jne boucle_setint3 


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
mov al,36h                  ;paramêtres de comptage
out dx,al
jmp $+2
mov dx,40h                 ;diviseur de fréquence de l'irq 0 (LSB en premier)
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
mov al,0A0h            ;masque les irq 5,7
out dx,al
mov dx,0A1h
mov al,0FFh            ;masque les irq 8 à 15
out dx,al



;************************************
;passage en mode protégé

mov ax,cs
mov ds,ax

lgdt[p_gdt+start]
lidt[p_idt+start]
                ;désactive les interruptions

mov eax,cr0
or eax,21h       ;NE et PE a 1
jmp $+2
mov cr0,eax
jmp selcod:0000h

;*************************************************************
;sous fonctions uttilisé par le lanceur

crgdt:  ;créer ou modifie un descripteur de segment
        ;ax=numéros du descripteur (13bit)
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


cridt:  ;créer ou modifie un descripteur d'interruption
        ;al=numéros du descripteur (8bit)
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
        ;ax=numéros du descripteur (13bit)
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

rcpbg:  ;récupère la base d'un descripteur de segment
        ;ax=num?ros du descripteur (13bit)
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
;données de base                                         **********************





polgraf:
include "DN_POLG.ASM"
finpolgraf:

palgraf:
include "DN_PALG.ASM"
finpalgraf:


;définition française au démarrage
include "DN_MSG_FR.ASM"    ;messages systeme en français
include "DN_CLAV_FR.ASM"      ;clavier Français azerty 
langue_demarrage equ "fra "


;définition anglaise au démarrage
;include "DN_MSG_EN.ASM"    ;messages systeme en anglais
;include "DN_CLAV_USI.ASM"    ;clavier US International
;langue_demarrage equ "eng "

tabacc:
include "DN_ACC.ASM"
fintabacc:


curseur8bit:
include "DN_CURS.ASM"

 

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
mov byte[trappe_tache0],1

mov dx,selpil
mov ss,dx
mov esp,0FFF0h



mov ax,seltss    ;définie la TSS global
ltr ax     
mov ax,sel_pilet0 ;et initialise les valeurs de base
mov bx,sel_pilet1
mov cx,sel_pilet2
mov dx,offset_iom
mov [tss_sauv_ss0],ax
mov [tss_sauv_ss1],bx
mov [tss_sauv_ss2],cx
mov [tss_iom],dx
sti      ;init des valeurs terminé, débloquage des irq



;**********************************************************************
;test capacités du processeur 
mov dword[at_processeur],0

;test si l'instruction cpuid est reconnue
pushfd
pop eax
mov edx,eax
xor eax,20000h
push eax
popfd
pushfd
pop eax
cmp eax,edx
je cpuid_absent

mov dword[at_processeur],1

mov eax,1
cpuid

bt edx,0
jnc fpu_absent
or dword[at_processeur],2
fpu_absent:

bt edx,9
jnc apic_absent
or dword[at_processeur],4
apic_absent:

bt edx,15
jnc cmov_absent
or dword[at_processeur],8
cmov_absent:

bt edx,23
jnc mmx_absent
or dword[at_processeur],10h
mmx_absent:

bt edx,24
jnc fxsave_absent
or dword[at_processeur],20h
fxsave_absent:

bt edx,25
jnc sse_absent
or dword[at_processeur],40h
sse_absent:

bt edx,26
jnc sse2_absent
or dword[at_processeur],80h
sse2_absent:

bt ecx,0
jnc sse3_absent
or dword[at_processeur],100h
sse3_absent:

bt ecx,9
jnc ssse3_absent
or dword[at_processeur],200h
ssse3_absent:

bt ecx,19
jnc sse41_absent
or dword[at_processeur],400h
sse41_absent:

bt ecx,20
jnc sse42_absent
or dword[at_processeur],800h
sse42_absent:

bt ecx,21
jnc apic2_absent
or dword[at_processeur],1000h
apic2_absent:

bt ecx,26
jnc xsave_absent
or dword[at_processeur],2000h
xsave_absent:

bt ecx,28
jnc avx_absent
or dword[at_processeur],4000h
avx_absent:


cpuid_absent:
mov byte[trappe_tache0],2






;**********************************************************************
;initialise les zones de taille variable

mov ax,seldat
mov ds,ax
mov ax,selramh
mov es,ax

mov ecx,1000h
call resmem
jc errallocmem
es
mov word[ebx+8],czm_pol      ;code zone police graphique
add ebx,16
mov dword[index_tabcar],0
mov [index_tabcar+4],ebx

push ds
mov cx,4096    ;copie la table de caractère graphique
mov ax,selramt
mov ds,ax
mov esi,polgraf+50000h
mov edi,ebx
cld
rep movsb      ;ds:esi vers es:edi
pop ds


mov ecx,80000h
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
cmp dword[nb_ram],800000h ;si inf a 8Mo zt de fat de 32Ko
jb @f
mov ecx,20000h  ;128ko
cmp dword[nb_ram],4000000h  ;si inf a 64Mo zt de fat de 128Ko
jb @f
mov ecx,80000h  ;512ko
@@:

call resmem
jc errallocmem
es
mov word[ebx+8],czm_ztf1      ;code de la zt lecture fat 1 
add ebx,10h             ;ne pas oublier de ne pas compter sur le descripteur
mov dword[ad_fat1],ebx
mov dword[max_fat1],ecx
mov byte[dsq_fat1],0FFh  

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

;mov ecx,8000h  ;32ko
;call resmem
;jc errallocmem
;es
;mov word[ebx+8],czm_dpu     ;descripteurs péripherique USB????????????????????????????????????????????????
;add ebx,10h             
;mov dword[ad_descusb],ebx
;mov dword[max_descusb],ecx

;mov ecx,8000h  ;32ko
;call resmem
;jc errallocmem
;es
;mov word[ebx+8],czm_ztu      ;zone tampon USB??????????????????????????????????????????????????????
;add ebx,10h             
;mov dword[ad_ztusb],ebx
;mov dword[max_ztusb],ecx 

mov byte[trappe_tache0],3
call maj_console0
jmp reserve_mem_isa


errallocmem:
mov ax,seldat
mov ds,ax
mov ax,selvidB8
mov es,ax

mov cl,47
mov ah,07h
xor ebx,ebx
mov edx,ad_msg_syst-1

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




;******************************************************************
;reserve le trou de mémoire isa
reserve_mem_isa:
mov byte[trappe_tache0],4
mov edx,0F00000h
mov ecx,0100000h
call resmemp
cmp eax,0
jne pas_reserve_isa
mov ax,selramh 
mov ds,ax
mov dword[0DFFFF8h],czm_tmi
pas_reserve_isa:






;jmp test1

;**********************************************************************
;programme souris ps/2

;commande au 8042: disable keyboard Interface
mov al,0ADh     
call env_8042_cmd

;commande au 8042: disable Auxiliary Interface
mov al,0A7h     
call env_8042_cmd

call vide_8042
      
;modifie le 8042 Command Byte
mov al,20h
call env_8042_cmd
call lec_ps2
;bts ax,0       ;enable l'interruption clavier
bts ax,1       ;enable l'interruption auxilliaire
;btr ax,4       ;met a zéro le bit "disable keyboard"
;btr ax,5       ;met a zéro le bit "disable auxiliary device"
mov bl, al
mov al,60h
call env_8042_cmd
mov al,bl
call env_8042_dat
call lec_ps2

;commande au 8042: disable keyboard Interface (pour pas envoyer de commande au clavier si il n'y as pas de souris)
mov al,0ADh     
call env_8042_cmd

;commande au 8042: enable Auxiliary Interface
mov al,0A8h     
call env_8042_cmd

;commande a la souris: set to default value
mov al,0F6h
call env_ps2

;envoie la séquence d'activation de la molette par sequence de commandes set sample rate
mov al, 0F3h   ;sample rate
call env_ps2
mov al, 200    ;a la valeur 200
call env_ps2
mov al, 0F3h    ;sample rate
call env_ps2
mov al, 100     ;a la valeur 100
call env_ps2
mov al, 0F3h    ;sample rate
call env_ps2
mov al, 80      ;a la valeur 80
call env_ps2

;envoie la séquence d'activation des 4eme et 5eme boutons par sequence de commandes set sample rate
mov al, 0F3h
call env_ps2
mov al, 200
call env_ps2
mov al, 0F3h
call env_ps2
mov al,200
call env_ps2
mov al, 0F3h
call env_ps2
mov al,80
call env_ps2


;vérifie le type de la souris
mov dx,seldat
mov ds,dx
mov al,0F2h
call env_ps2
call lec_ps2
cmp al,0
je souris_simple
cmp al,3
je souris_molette
cmp al,4
je souris_5boutons
jmp fin_init_souris

souris_simple:
mov byte[atts1],1
mov byte[nbts1],3
mov byte[nbzt1],0 
jmp suite_init_souris

souris_molette:
mov byte[atts1],1
mov byte[nbts1],4
mov byte[nbzt1],0 
jmp suite_init_souris

souris_5boutons:
mov byte[atts1],3
mov byte[nbts1],4
mov byte[nbzt1],0 
;jmp suite_init_souris



;configure la souris et l'active
suite_init_souris:
mov al,0F3h    ;set sample rate
call env_ps2
mov al,200     ;échantillons par seconde, valeur possible: 10,20,40,60,80,100,200
call env_ps2
mov al,0E8h    ;set resolution
call env_ps2
mov al,3       ;valeur possible: 0,1,2,3
call env_ps2
mov al,0E6h    ;set scaling 1:1
call env_ps2
mov al,0F4h    ;enable
call env_ps2

;démasque l'irq 12
mov dx,0A1h
mov al,0EFh
out dx,al
fin_init_souris:


;commande au 8042: enable keyboard Interface
mov al,0AEh     
call env_8042_cmd



;aquitte toutes irq en attente
mov al,20h
out 0A0h,al
mov al,20h
out 20h,al
mov byte[nbzt1],0 

call vide_8042
test1:
mov byte[trappe_tache0],5


;enregistre la langue initiale
mov dword[code_langue],langue_demarrage





;*******************************************************************
;fin de la séquence d'initialisation
mov cl,0
call affmsgsyst     ;rapel sur la version installé

mov ax,seldat
mov ds,ax
mov es,ax
mov byte[trappe_tache0],6
xor eax,eax    ;effacement de la seconde moitié du segment de donnée systeme (pas effectué avant car cette partie contenait le code d'amorçage)
mov ecx,08000h
mov edi,20000h
rep stosd

mov esi,[ad_ficho]
mov ax,selramh
mov es,ax

;initalisation du repertoire initiale en disque ram
mov dword[ad_repertoire],"#dm"
es
mov dword[esi+0],11
es
mov dword[esi+4],0
es
mov dword[esi+8],0
es
mov dword[esi+12],0
es
mov dword[esi+16],0
es
mov dword[esi+20],0
es
mov dword[esi+24],0
es
mov dword[esi+28],0


;et le disque systeme
mov dword[ad_repsys],"#dm"
es
mov dword[esi+32],11
es
mov dword[esi+36],0
es
mov dword[esi+40],0
es
mov dword[esi+44],0
es
mov dword[esi+48],0
es
mov dword[esi+52],0
es
mov dword[esi+56],0
es
mov dword[esi+60],0


mov word[ad_ztcmd+0],0
mov dword[ad_ztcmd+2],"ex c"   ;commande initiale: execution du script d'amorçage
mov dword[ad_ztcmd+6],"fg.s"
mov dword[ad_ztcmd+10],"h -v"
mov byte[ad_ztcmd+14],0
mov word[to_ztcmd],15


mov dword[ad_table_ecran],0           ;crée le descripteur d'écran de la tache 0
mov dword[ad_table_ecran+4],0
mov dword[ad_table_ecran+8],0
mov dword[ad_table_ecran+12],0
mov dword[ad_table_ecran+16],0
mov dword[ad_table_ecran+20],0
mov dword[ad_table_ecran+24],0
mov dword[ad_table_ecran+28],0
mov word[nb_ecran],1


mov dword[ad_tache_exec],0
mov word[id_tache_exec],0
mov byte[cpttc],25
mov byte[at_csl],0Eh ;signale que l'affichage complet de la console doit être mis a jour
sti
mov byte[trappe_tache0],7

;*********************************************************************
include "SF_INIT.ASM"     ;detection et d'initialisation des controleur FDC, ATA, USB et AHCI et des partitions installé

jmp btacheprincipale


;*****************************************************************
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

 


;**********************************************************************
;tache principale

btacheprincipale:    ;boucle de la tache principale
mov dx,seldat      ;init segment de donn?e
mov ds,dx
mov es,dx
mov fs,dx
mov gs,dx


;******************************************************
;retour a l'affichage du tecop si la souris est en position 0:0 (sauf si il n'y as pas de souris)
test byte[atts1],1
jz pas_retour_tecop
cmp dword[axs1],0
jne pas_retour_tecop
mov dx,0
call sfv_sf_choix_console
pas_retour_tecop:


;si ce n'est pas le tecop qui est affiché, on ne s'occupe pas de mettre a jour le tecop
cmp word[table_ecran_id],0
jne maj_ecran



;***************************************************************************
;gestion des entrées clavier du mode console

mov al,5
int 63h
cmp al,0
je majafcsl


;touches ctrl+
test ah,0Ch
jz @f
cmp al,61
je ctrlx
cmp al,62
je ctrlc
cmp al,63
je ctrlv
jmp majafcsl
@@:

;touches normale
cmp al,0F0h
je souris_tecop
cmp al,0F0h
ja majafcsl
cmp al,14
jb touchefx

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
cmp al,31
je autocompl
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
cmp al,76
je cmd_prec

cmp al,0F0h
je souris_tecop


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
mov [to_cce],di   ;maj de la taille occupé
mov eax,ecx
xor ecx,ecx
mov cx,[to_cce]
sub cx,[cu_cce]   ;calcul la différence entre la taille occupé et la position curseur
cmp ecx,0
je pas_decal_ins1
add edi,ad_cce
mov esi,edi
dec esi
std
rep movsb          ;décale les données
pas_decal_ins1:

and eax,7Fh         ;transformation du caractère
mov [edx+ad_cce],al  ;?crit le caract?re
inc word[cu_cce]    ;maj de la position curseur
jmp majafcsl

insert2:
add edi,2
cmp edi,255
jae pasconsole      ;verifie que la chaine n'est pas pleine
mov [to_cce],di   ;maj de la taille occupé
mov eax,ecx
xor ecx,ecx
mov cx,[to_cce]
sub cx,[cu_cce]   ;calcul la diff?rence entre la taille occupé et la position curseur
cmp ecx,0
je pas_decal_ins2
add edi,ad_cce
mov esi,edi
sub esi,2
std
rep movsb          ;décale les données

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
rep movsb          ;décale les donn?es
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
sub esi,4
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
inc edx
inc word[cu_cce]
mov ah,[ad_cce+edx]
and ah,11000000b
cmp ah,80h
je avcsl
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
mov cx,[resyt]
shr cx,1
cmp word[no_ligne_jcsl],cx
jbe ligne_debut
sub word[no_ligne_jcsl],cx
and byte[at_csl],0DFh    ;met a zero le bit "on doit afficher la fin du journal
or byte[at_csl],02h ;signale que l'affichage du journal doit être mis a jour
jmp majafcsl

ligne_pp:
mov cx,[resyt]
shr cx,1
add word[no_ligne_jcsl],cx
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

cmd_prec:      ;remplit la zone de commande en cours de rédaction par la commande précédente
test ah,3h
jnz cmd_suiv
inc byte[num_cmd]
and byte[num_cmd],03Fh ;on ne peut afficher que les 64 dernières commandes
jmp recop_cmd


cmd_suiv:
cmp byte[num_cmd],3Fh
je majafcsl
dec byte[num_cmd]
and byte[num_cmd],03Fh ;on ne peut afficher que les 64 dernières commandes

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
and byte[num_cmd],03Fh ;on ne peut afficher que les 64 dernières commandes
jmp recop_cmd

cmdoke:         ;on recopie dans la zt commande en cours de rédaction
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
dec edi          ;et on ne compte ps le zéro finale
mov [to_cce],di
mov [cu_cce],di
jmp majafcsl


autocompl:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§



;réserve un petite partie mémoire



;charge la liste des fichier



;recherche parmis les fichier ce qui est proche


;s'il n'y as eu qu'une correspondance on complete
jmp majafcsl


;fonctions du presse papier dans le tecop
ctrlx:
mov al,15
mov edx,ad_cce 
xor ecx,ecx
mov cx,[to_cce]
int 61h

mov word[to_cce],0
mov word[cu_cce],0
or byte[at_csl],08h ;signale que l'affichage de la commande doit être mis a jour
jmp majafcsl


ctrlc:
mov al,15
mov edx,ad_cce 
xor ecx,ecx
mov cx,[to_cce]
int 61h
jmp majafcsl

ctrlv:
mov al,16
mov edx,ad_zdc 
mov ecx,255
int 61h
cmp ecx,0
je majafcsl

mov ebx,255
sub bx,[to_cce]
cmp ebx,ecx
jb @f ;??????????????????????????????
mov ebx,ecx
@@:

xor eax,eax
xor ecx,ecx
mov ax,[cu_cce]
add cx,[to_cce]
sub ecx,eax
jz @f

mov esi,ad_cce
add si,[to_cce]
dec esi
mov  edi,esi
add edi,ebx
std
rep movsb
@@:


mov ecx,ebx
mov esi,ad_zdc
mov edi,ad_cce
add di,[cu_cce]
cld
rep movsb


add [to_cce],ebx
add [cu_cce],ebx
or byte[at_csl],08h ;signale que l'affichage de la commande doit être mis a jour
jmp majafcsl






;change l'ecran affiché
touchefx:
xor ebx,ebx
mov bl,al
mov ax,selramh
mov fs,ax
cmp ebx,1
je majafcsl
sub ebx,2
cmp cx,[nb_ecran_tecop]
jae majafcsl
mov ecx,ebx
jmp change_ecran_tecop


souris_tecop:
mov ax,selramh
mov fs,ax
shr ecx,4
cmp cx,[nb_ecran_tecop]
jae majafcsl



change_ecran_tecop:
mov ebx,table_ecran_id

boucle_change_ecran_tecop:
mov dx,[ebx]
cmp dx,0
je @f
cmp ecx,0
je fin_change_ecran_tecop 
dec ecx
@@:
add ebx,32
jmp boucle_change_ecran_tecop


fin_change_ecran_tecop:
call sfv_sf_choix_console
jmp maj_ecran 




;****************************************************************************
;mise a jour affichage console système

majafcsl:
mov bx,selramh
mov ds,bx
mov bx,seldat
mov es,bx

;**********************************************
;mise a jour descriptif cliquable de tache
es
test byte[at_csl],01h ;y'a t'il eu modification des descriptif de tâches?
jz finaft
es
and byte[at_csl],0FEh ;désactive le besoin de mettre a jour les descriptifs de tache
mov eax,7
int 63h ;signale que l'affichage doit être mis a jour

es
mov word[nb_ecran_tecop],0
mov edi,table_ecran_id
xor ebx,ebx


boucle_aff_listing_ecran:
es
mov ax,[nb_ecran]
dec ax
es
cmp [nb_ecran_tecop],ax
jae finaft

es
cmp word[edi],0
je ignore_aff_listing_ecran


es
mov esi,[edi+table_ecran_ad-table_ecran_id]

;affiche le descriptif tache
xor eax,eax
mov ebp,ebx
es
mov ax,[resxt]
add ebp,eax
mov ch,1Fh
mov eax,"F"
call affcarac
inc ebx
xor eax,eax
es
mov ax,[nb_ecran_tecop]
add eax,"1"
mov cl," "
cmp eax,":"
jb afftouchef
mov cl,al
sub cl,10
mov eax,"1"
cmp cl,"3"
jb afftouchef
mov al,"+"
mov cl,"+"
afftouchef:
call affcarac
inc ebx
mov al,cl
call affcarac
inc ebx
mov eax," "
call affcarac
inc ebx


mov edx,esi
add edx,descriptif_tache
b1_aff_listing_ecran:
call lireutf8
cmp eax,0
je f1_aff_listing_ecran
call affcarac
inc ebx
cmp ebx,ebp
jne b1_aff_listing_ecran

f1_aff_listing_ecran:
cmp ebx,ebp
je f2_aff_listing_ecran

b2_aff_listing_ecran:
mov eax," "
call affcarac
inc ebx
cmp ebx,ebp
jne b2_aff_listing_ecran
f2_aff_listing_ecran:

es
inc word[nb_ecran_tecop]
es
mov ax,[resyt]
shr ax,1
es
cmp [nb_ecran_tecop],ax
jae finaft

ignore_aff_listing_ecran:
add edi,32
jmp boucle_aff_listing_ecran

finaft:





;**********************************************************
;mise a jour journal systeme
es
test byte[at_csl],02h ;y'a t'il eu modification de l'affichage du journal de la console?
jz finafj
es
and byte[at_csl],0FDh ;désactive le besoin de mettre a jour la commande
mov eax,7
int 63h ;signale que l'affichage doit être mis a jour



;determination adresse de la première ligne a afficher
es
mov edx,[ad_jcsl]    ;adresse journal
es
mov ebp,[to_jcsl]
add ebp,edx ;adresse fin journal 
xor ecx,ecx
xor edi,edi
es
mov cx,[no_ligne_jcsl]    ;num ligne a afficher
es
mov di,[resxt]   ;nb de carac par ligne

boucle_trouve_ligne0:
cmp ecx,0
je ligne0_ok
call lireutf8
cmp edx,ebp
je ok_affichagej
cmp eax,13
je finligne_trouve
mov ebx,eax
and ebx,0FFFFFFF0h
cmp ebx,10h
jne @f
and al,0Fh
es
mov [coul_car],al
@@:
dec edi
jnz boucle_trouve_ligne0

finligne_trouve:
dec ecx
xor edi,edi
es
mov di,[resxt]   ;nb de carac par ligne
jmp boucle_trouve_ligne0


;test si il faut afficher la fin du journal
ligne0_ok:
es
test byte[at_csl],20h
jz ok_affichagej


;determination adresse minimum dernière ligne pour afficher fin
es
mov ebp,[ad_jcsl]    ;adresse journal
es
mov esi,[to_jcsl]
add esi,ebp ;adresse fin journal 
xor ecx,ecx
xor edi,edi
es
mov cx,[resyt]    ;nb de ligne pour le journal?
es
sub cx,[nb_ecran_tecop]
sub cx,3
es
mov di,[resxt]   ;nb de carac par ligne


boucle_trouve_lignef:
dec esi
mov al,[esi]
cmp al,13
je finligne_trouve2
test al,80h
jnz boucle_trouve_lignef
dec edi
jnz boucle_trouve_lignef

finligne_trouve2:
dec ecx
jz lignef_ok
xor edi,edi
es
mov di,[resxt]   ;nb de carac par ligne
jmp boucle_trouve_lignef


lignef_ok:
cmp esi,edx
jb ok_affichagej 




;determination du numéro de la ligne
xor edi,edi
es
mov di,[resxt]   ;nb de carac par ligne

boucle_trouve_lignex:
cmp esi,edx
jb ok_affichagej
call lireutf8
cmp edx,ebp
je ok_affichagej
cmp eax,13
je finlignex_trouve
mov ebx,eax
and ebx,0FFFFFFF0h
cmp ebx,10h
jne @f
and al,0Fh
es
mov [coul_car],al
@@:
dec edi
jnz boucle_trouve_lignex

finlignex_trouve:
es
inc word[no_ligne_jcsl]
xor edi,edi
es
mov di,[resxt]   ;nb de carac par ligne
jmp boucle_trouve_lignex



;affichage du journal
ok_affichagej:
push edx
xor eax,eax
xor ecx,ecx
es
mov ax,[resxt]   ;nb de carac par ligne
es
mov cx,[nb_ecran_tecop]
mul ecx
pop edx
mov ebx,eax
es
mov ebp,[ad_jcsl]
es
add ebp,[to_jcsl] ;adresse fin journal 


bcafj:          ;boucle d'affichage journal           
cmp edx,ebp      ;test si on est arrivé a la fin du journal système 
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
je finafj
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
cmp ebx,[ad_afrep]      ;test si on est arrivé a la fin de la zone d'affichage authorisé
je finafj
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



finafj:


;**************************************
;affiche le répertoire de travail
mov bx,seldat
mov ds,bx

test byte[at_csl],04h
jz finafr
and byte[at_csl],0FBh ;désactive le besoin de mettre a jour la commande
mov eax,7
int 63h ;signale que l'affichage doit être mis a jour
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
mov eax,7
int 63h ;signale que l'affichage doit être mis a jour

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

boucle_vide_zdc:    ;met tout les octet de la fin de la commande dans la zone de décodage a zéro
cmp edi,ad_zdc+200h
je fin_vide_zdc
es
mov byte[edi],0
inc edi
jmp boucle_vide_zdc
fin_vide_zdc:

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
or al,1
stop_correction_casse1:

cmp byte[esi]," "  
jne stop_correction_casse2
or al,1
stop_correction_casse2:

cmp word[esi]," -"  
jne redemarre_correction_casse1
and al,0FEh
redemarre_correction_casse1:


cmp word[esi],2220h  
jne interdit_correction_casse1
or al,2
interdit_correction_casse1:

cmp word[esi],223Ah  
jne interdit_correction_casse2
or al,2
interdit_correction_casse2:

cmp word[esi],2022h  
jne autorise_correction_casse1
and al,0FDh
autorise_correction_casse1:



test al,3
jnz pascorcasse
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
cmp eax,"vmem"
je cmdvmem
cmp eax,"cd.."
je cmdcdpp
cmp eax,"echo"
je cmdaf

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
cmp eax,"def"
je cmddef

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
cmp eax,"nd"
je cmdnd
cmp eax,"ls"
je cmddir
cmp eax,"rm"
je cmdsup
cmp eax,"cp"
je cmdcop
cmp eax,"mv"
je cmdren
cmp eax,"ps"
je cmdlt
cmp eax,"mk"
je cmdnd

commande_fichier:
include "SF_TACHE.ASM"

;****************************************************************
;commande integré de listage
include "CI_LISTE.ASM"

;****************************************************************
cmdvmem:
mov edx,ad_zdc          ;recherche la chaine qui coresspond a l'adresse a afficher
boucle_vmem1:
cmp byte[edx]," "
jne suite_boucle_vmem1
cmp byte[edx+1]," "
jne adresse_vmem
suite_boucle_vmem1:
inc edx
cmp edx,ad_zdc+200h
je fin_commande_erreur_param
jmp boucle_vmem1

;convertit l'id en entier 32 bit
adresse_vmem:
inc edx
mov eax,101
int 61h

mov ebx,ecx

mov ax,selramt
mov fs,ax

mov ecx,16

boucle_vmem3:

mov al,17h
test ecx,1
jnz ignore_couleur_vmem
mov al,1Fh
ignore_couleur_vmem:
call affcj


fs
mov al,[ebx]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+1]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+2]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+3]
call affh0j
mov al," "
call affcj
mov al," "
call affcj
fs
mov al,[ebx+4]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+5]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+6]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+7]
call affh0j
mov al," "
call affcj
mov al," "
call affcj
fs
mov al,[ebx+8]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+9]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+10]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+11]
call affh0j
mov al," "
call affcj
mov al," "
call affcj
fs
mov al,[ebx+12]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+13]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+14]
call affh0j
mov al," "
call affcj
fs
mov al,[ebx+15]
call affh0j
mov al,13
call affcj


add ebx,16
dec ecx
jnz boucle_vmem3


jmp pascommande






;****************************************************************
cmdmodv:       ;modification mode video
mov ax,selramh
mov es,ax

mov edx,ad_zdc          ;recherche le début du parametre
boucle_modv1:
cmp byte[edx]," "
jne suite_boucle_modv1
cmp byte[edx+1]," "
jne @f
suite_boucle_modv1:
inc edx
cmp edx,ad_zdc+200h
je fin_commande_erreur_param
jmp boucle_modv1

@@:
inc edx
mov esi,edx


boucle_modv2:             ;recherche si on as affaire a une résolution
cmp byte[edx],"x"
je @f
cmp byte[edx],"X"
je @f
cmp byte[edx],"*"
je @f
cmp byte[edx],0
je cmdmodv_num
inc edx
cmp edx,ad_zdc+200h
je fin_commande_erreur_param
jmp boucle_modv2

@@:
inc edx
mov edi,edx


boucle_modv3:             ;recherche si on as affaire a une resolution + nb bit
cmp byte[edx],"x"
je @f
cmp byte[edx],"X"
je @f
cmp byte[edx],"*"
je @f
cmp byte[edx],0
je cmdmodv_resol
inc edx
cmp edx,ad_zdc+200h
je fin_commande_erreur_param
jmp boucle_modv3

@@:            ;recherche le mode vidéo qui as exactement les bonne caractéristique
inc edx
mov eax,100
int 61h
mov ebp,ecx   ;ebp=nb bit par pixel
mov edx,esi
mov eax,100
int 61h
mov esi,ecx  ;esi=resol X
mov edx,edi
mov eax,100
int 61h
mov edi,ecx  ;edi=resol y
mov edx,ebp


;recherche un mode dans la liste
xor ecx,ecx

boucle_modv4:
call vesa_infomode
cmp ax,004Fh
jne @f
cmp [infovesa+12h],si
jne @f
cmp [infovesa+14h],di
jne @f
cmp [infovesa+19h],dl
je cmdmodv_ok 
@@:
inc ecx
cmp ecx,400h
jne boucle_modv4 
jmp erreurmodv


cmdmodv_resol:    ;recherche le mode video de la meilleur résolution 
mov edx,esi
mov eax,100
int 61h
mov esi,ecx  ;esi=resol X
mov edx,edi
mov eax,100
int 61h
mov edi,ecx  ;edi=resol y
mov edx,ebp


xor ecx,ecx
xor ebp,ebp
xor edx,edx
boucle_modv5:
call vesa_infomode
cmp ax,004Fh
jne @f
cmp [infovesa+12h],si
jne @f
cmp [infovesa+14h],di
jne @f
cmp [infovesa+19h],dl
jb @f
mov dl,[infovesa+19h]
mov ebp,ecx
@@:
inc ecx
cmp ecx,200h
jne boucle_modv5 

cmp ebp,0
je erreurmodv
mov ecx,ebp
jmp cmdmodv_ok 


cmdmodv_num:
mov edx,esi
mov eax,101
int 61h
test ecx,0FFFF0000h
jnz erreurmodv

cmdmodv_ok:
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
or cx,4000h             ;désactiver cette ligne si on ne veux pas uttiliser le linear frame buffer pour les test !!!!!!!!!!!!!!!!!!!!
pasdelinear:


call vesa_mode        ;passe dans le mode
cmp ax,004Fh
jne erreurmodv


;maj les info sur le mode video en court
and cx,1FFh
mov [mdvc],cx
or byte[at_csl],0Eh ;signale que l'affichage de la console doit être mis a jour
test dword[infovesa],10h ;on teste si on est un mode texte ou pas
jz cmdmodv_texte


mov ax,[infovesa+12h]    ;maj des resolutions
mov bx,[infovesa+14h]
mov [resx],ax
mov [resy],bx
shr ax,3
shr bx,4
mov [resxt],ax
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
;jmp banked_cmdmodv   ;activer cette ligne si on ne veux pas uttiliser le linear frame buffer pour les test !!!!!!!!!!!!!!!!!!
or word[at_vid],10h     ;met le bit 4 a un (bit utilisation du linear frame buffer)
mov ebx,[infovesa+28h] ;adresse de base du linear frame buffer

mov eax,[nb_ram]
cmp ebx,eax                ;on test si le lfb est bien hors de la ram utilisable
ja cmdmodv_ok_positionlfb 
and dword[infovesa],07Fh ;met a zéro le bit de disponibilité du linear frame buffer
mov cx,[mdvc]
jmp pasdelinear             ;si non on passe en mode banked


cmdmodv_ok_positionlfb:
push ds
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
mov [resxt],ax
mov [resyt],bx
shl ax,3
shl bx,4
mov [resx],ax
mov [resy],bx

mov byte[bitpp],00
jmp fin_cmdmodv


banked_cmdmodv:
and word[at_vid],0FFEFh    ;met le bit 4 a zéro (bit utilisation du linear frame buffer)
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



;met a 1 le bit "caracteristique ecran réel changé" de chaque ecran de tache
push es
mov ax,selramh
mov fs,ax
mov ax,selgdt
mov gs,ax
xor esi,esi
xor edi,edi
mov di,[nb_ecran]
shl edi,5
boucle_bit5_cmdmodv:
cmp word[esi+table_ecran_id],0
je @f 

;recopie le descripteur de l'écran en ldt dans le descripteur d'ecran
mov ebx,[esi+table_ecran_ad]
fs
mov ax,[ebx+sel_ecranv]
and eax,0FFF8h
add ebx,ldt_tache
add ebx,eax
fs
mov eax,[ebx]
fs
mov edx,[ebx+4]
gs
mov [selecran],eax
gs
mov [selecran+4],edx

mov ax,selecran 
mov es,ax
es
or byte[at_console],20h ;met a 1 le bit5

@@:
add esi,32
cmp esi,edi
jne boucle_bit5_cmdmodv 
pop es

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

mov cl,94   
call affmsgsyst
jmp pascommande



;****************************************************************
cmddir:             ;liste le contenue du repertoire courant
mov esi,debut_cmddir
mov ecx,fin_cmddir-debut_cmddir
jmp creation_tache_interne

debut_cmddir:
include "CI_DIR.ASM"
fin_cmddir:



;********************************************
cmdren:
mov esi,debut_cmdren
mov ecx,fin_cmdren-debut_cmdren
jmp creation_tache_interne

debut_cmdren:
include "CI_REN.ASM"
fin_cmdren:



;********************************************
cmdsup:
mov esi,debut_cmdsup
mov ecx,fin_cmdsup-debut_cmdsup
jmp creation_tache_interne

debut_cmdsup:
include "CI_SUP.ASM"
fin_cmdsup:



;********************************************
cmdcop:
mov esi,debut_cmdcop
mov ecx,fin_cmdcop-debut_cmdcop
jmp creation_tache_interne

debut_cmdcop:
include "CI_COP.ASM"
fin_cmdcop:



;********************************************
cmddef:   ;charge des fichier de definition supplémentaire
mov edx,ad_zdc
boucle_cmddef:     ;trouve le debut du nom du fichier
cmp byte[edx],0
je fin_commande_erreur_param          ;si on arrive a la fin de la chaine c'est une erreur
inc edx
cmp byte[edx]," "
jne boucle_cmddef           
cmp byte[edx+1]," "
je boucle_cmddef           


inc edx
mov ebp,edx
xor eax,eax         ;ouvre le fichier
xor ebx,ebx
int 64h
cmp eax,0       
jne fin_commande_erreur


;lit l'en tête du fichier
mov al,4
mov ecx,16
xor edx,edx
mov edi,ad_chaine_travail
int 64h
cmp eax,0
jne fin_commande_erreur


;lit la taille du fichier
mov al,6
mov ah,1
mov edx,ad_chaine_travail+16
int 64h
cmp eax,0
jne fin_commande_erreur


;test le type de definition
cmp dword[ad_chaine_travail],"DEFL"
je cmddef_lang
cmp dword[ad_chaine_travail],"DEFC"
je cmddef_clav
cmp dword[ad_chaine_travail],"DEFG"
je cmddef_graph


erreur_cmddef_structure:
mov eax,26
erreur_cmddef_autres:
push eax
mov eax,1
int 64h
pop eax
jmp fin_commande_erreur 


;***********
cmddef_lang:  
;efface l'ancienne definition des messages systèmes et erreur
xor eax,eax
mov edi,ad_msg_syst
mov ecx,3072
cld
rep stosd

;charge la nouvelle definition des messages systemes
mov al,4
mov ecx,[ad_chaine_travail+4]
mov edx,16
sub ecx,edx
mov edi,ad_msg_syst
int 64h
cmp eax,0
jne erreur_cmddef_autres


;charge la nouvelle definition des messages erreur
mov al,4
mov ecx,[ad_chaine_travail+8]
mov edx,[ad_chaine_travail+4]
mov edi,ad_msg_erreur
int 64h
cmp eax,0
jne erreur_cmddef_autres

;enregistre le code de langue
mov eax,[ad_chaine_travail+12]
mov [code_langue],eax


mov eax,1
int 64h
mov cl,98  
call affmsgsyst
mov edx,ebp
call affjournal
mov cl,87   
call affmsgsyst
jmp pascommande


;**********
cmddef_clav: 

;charge la nouvelle definition de chasse si existant
xor edx,edx
mov dx,[ad_chaine_travail+12]
cmp edx,0
je ignore_chasse_cmddef_clav 
mov ecx,[ad_chaine_travail+16]
cmp edx,ecx
ja erreur_cmddef_structure
sub ecx,edx
cmp ecx,3FFCh
ja erreur_cmddef_structure

;efface l'ancienne definition de chasse
push ecx
push edx
xor eax,eax
mov edi,ad_tabclav_chasse
mov ecx,1000h
cld
rep stosd
pop edx
pop ecx

;et charge la nouvelle
mov al,4
mov edi,ad_tabclav_chasse
int 64h
cmp eax,0
jne erreur_cmddef_autres
ignore_chasse_cmddef_clav:

;charge la nouvelle definition de touche PS/2 si existant
xor edx,edx
mov dx,[ad_chaine_travail+4]
cmp edx,0
je ignore_codeps2_cmddef_clav 
mov al,4
mov ecx,512
mov edi,ad_tabclav_code
int 64h
cmp eax,0
jne erreur_cmddef_autres
ignore_codeps2_cmddef_clav:

;charge la nouvelle definition de touche usb si existant
xor edx,edx
mov dx,[ad_chaine_travail+8]
cmp edx,0
je ignore_codeusb_cmddef_clav 
mov al,4
mov ecx,256
mov edi,ad_tabclav_usb 
int 64h
cmp eax,0
jne erreur_cmddef_autres
ignore_codeusb_cmddef_clav:


;charge la nouvelle definition de caractère touche si existant
xor edx,edx
mov dx,[ad_chaine_travail+8]
cmp edx,0
je ignore_touchesp_cmddef_clav 
mov al,4
mov ecx,2048
mov edi,ad_tabclav_carac
int 64h
cmp eax,0
jne erreur_cmddef_autres

xor edx,edx
mov dx,[ad_chaine_travail+10]
cmp edx,0
je ignore_touchess_cmddef_clav 
mov al,4
mov ecx,2048
mov edi,ad_tabclav_carac+2048
int 64h
cmp eax,0
jne erreur_cmddef_autres

ignore_touchess_cmddef_clav:
mov dx,[ad_chaine_travail+14]
dec dl
dec dh
mov [alclat1],dx
ignore_touchesp_cmddef_clav:

mov eax,1
int 64h
mov cl,98  
call affmsgsyst
mov edx,ebp
call affjournal
mov cl,88   
call affmsgsyst
jmp pascommande



;**********
cmddef_graph:      ;charge la nouvelle definition de caractère graphique
;vérifie que la taille des caractère de la matrice correspondent bien a la taille actuellement utilisé
cmp dword[ad_chaine_travail+4],1008h  ;taille 8x16
jne erreur_cmddef_structure 
;verifie que l'index des caractère est bien aligné sur 256
cmp byte[ad_chaine_travail+8],0 
jne erreur_cmddef_structure

;cherche si la table est déja en mémoire
mov ax,selramh
mov es,ax
mov eax,[ad_chaine_travail+8]
mov edx,index_tabcar
boucle_verif_defg:
cmp [edx],eax
je defg_deja_existant 
add edx,8
cmp edx,index_tabcar+512
jne boucle_verif_defg

;réserve une zone mémoire pour les données
mov ecx,4096
push ebx
call resmem
mov edi,ebx
pop ebx
jc errallocmem

;marque la zone comme étant un police matricielle
es
mov word[edi+8],czm_pol  
add edi,16

;copie les données
mov al,4
mov ecx,4096
mov edx,16
int 64h
cmp eax,0
jne erreur_cmddef_autres

;met a jour l'index des tables de caractères
mov esi,index_tabcar
boucle_cmddef_graph:
cmp dword[esi],0
jne boucle_cmddef_graph_suite
cmp dword[esi+4],0
je boucle_cmddef_graph_fin

boucle_cmddef_graph_suite:
add esi,8
cmp esi,index_tabcar+512
jne boucle_cmddef_graph 

;si la table est pleine on supprime la dernière entrée de la table
sub esi,8

mov eax,[esi]
push ebx
mov ebx,eax
call libmem
pop ebx

boucle_cmddef_graph_fin:
mov eax,[ad_chaine_travail+8]
mov [esi],eax
mov [esi+4],edi

fin_defg_ok:
mov eax,1
int 64h
mov cl,98  
call affmsgsyst
mov edx,ebp
call affjournal
mov cl,89   
call affmsgsyst
jmp pascommande


defg_deja_existant:
mov edi,[edx+4]
mov al,4
mov ecx,4096
mov edx,16
int 64h
cmp eax,0
jne erreur_cmddef_autres
jmp fin_defg_ok





;****************************************************************
cmdcd:          ;change le répertoire courant (inclue la commande cd..)
include "CI_CD.ASM"

;****************************************************************
cmdaf:
mov al,1Fh
call affcj

mov edx,ad_zdc
boucle_cmdaf:
cmp byte[edx]," "
je suite_cmdaf
inc edx
cmp edx,ad_zdc+200h
jne boucle_cmdaf
jmp pascommande

suite_cmdaf:
inc edx

;ouvre le fichier
push edx
mov eax,0
mov ebx,0
int 64h
pop edx
cmp eax,0
jne fin_cmdaf

;lit taille fichier
push ebx
push edx
mov edx,ad_chaine_travail
mov al,6
mov ah,1 ;fichier
int 64h
pop edx
pop ebx
cmp eax,0
jne fin_cmdaf

cmp dword[ad_chaine_travail],80000h
ja fin_cmdaf
;cmp dword[ad_chaine_travail+4],0
;jne fin_cmdaf

mov ecx,[ad_chaine_travail]
add ecx,1Fh
and ecx,0FFFFFF0h
push ebx
call resmem
mov edi,ebx
pop ebx
jc errallocmem
add edi,10h

push ebx
push edi
mov ax,selramh
mov es,ax
mov ecx,[ad_chaine_travail]
mov edx,0 
mov al,4
int 64h
pop edi
pop ebx
cmp eax,0
jne fin_cmdaf

mov eax,1 ;ferme le fichier
int 64h

mov ebx,edi
mov ecx,[ad_chaine_travail]
mov ax,selramh
mov ds,ax

boucle2_cmdaf:
cmp word[edi],0D0Ah
je cmdaf_finligne_cpx
cmp word[edi],0A0Dh
je cmdaf_finligne_cpx
cmp byte[edi],0Ah
je cmdaf_finligne_sim
cmp byte[edi],0Dh
je cmdaf_finligne_sim
cmp byte[edi],32
jb cmdaf_decale
jmp ignore_boucle2_cmdaf

cmdaf_finligne_sim:
mov byte[edi],0Dh
jmp ignore_boucle2_cmdaf


cmdaf_finligne_cpx:
mov byte[edi+1],0Dh

cmdaf_decale:
push ecx
push edi
mov esi,edi
inc esi
cli
rep movsb
pop edi
pop ecx
ignore_boucle2_cmdaf:
inc edi
dec ecx
jnz boucle2_cmdaf 

mov edx,ebx
sub ebx,10h
call libmem


fin_cmdaf:
call affjournal
mov al,17h
call affcj
mov al,13
call affcj
jmp pascommande




;**************************************************************
cmdex:
mov esi,debut_cmdex
mov ecx,fin_cmdex-debut_cmdex
jmp creation_tache_interne

debut_cmdex:
include "CI_EX.ASM"
fin_cmdex:




;*****************************************
cmdnd:
mov edx,ad_zdc-1
boucle1_cmdnd:     
inc edx
cmp byte[edx],0
jne boucle1_cmdnd  

boucle2_cmdnd:  
dec edx
cmp byte[edx]," "
je boucle2_cmdnd
cmp byte[edx],"\"
je boucle2_cmdnd
cmp byte[edx],"/"
je boucle2_cmdnd
inc edx
mov dword[edx],002E2Fh  ;on rajoute une cotice et point a la fin du nom de dossier

mov edx,ad_zdc
boucle3_cmdnd:     ;trouve le debut du nom du fichier
cmp byte[edx],0
je fin_commande_erreur_param          ;si on arrive a la fin de la chaine c'est une erreur
inc edx
cmp byte[edx]," "
jne boucle3_cmdnd           
cmp byte[edx+1]," "
je boucle3_cmdnd           

inc edx
mov eax,2        ;créer le dossier
xor ebx,ebx
int 64h
cmp eax,cer_nfr      
jne fin_commande_erreur

mov eax,1
int 64h
cmp eax,0
jne fin_commande_erreur

mov edx,ad_zdc-1
boucle4_cmdnd:     
inc edx
cmp byte[edx],0
jne boucle4_cmdnd  
sub edx,2
mov byte[edx],0
jmp cmdcd   ;une fois le dossier créer on l'ouvre



;************************************************************
fin_commande_erreur_param:
mov eax,1
jmp fin_commande_erreur

fin_commande_erreur_mem:
mov eax,11

;affichel le message correspondant a l'erreur dans eax
fin_commande_erreur:
push eax

mov cl,3  
call affmsgsyst
mov edx,ad_zdc
call affjournal
mov al,34
call affcj
mov al,13
call affcj
pop ecx   
call affmsgerr
mov al,17h
call affcj



;********************************************************
pascommande:
sti
include "SF_PERI.ASM"         ;gestion periodique du materiel
int 62h
jmp btacheprincipale

;fin de la boucle de la tache principale







;**********************************************************************************************************************************************************************************************
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



;**********************
affmsgsyst:   ;affiche le message systême nø=cl
push ecx
push edx
push ds
push fs
mov dx,seldat
mov ds,dx
mov fs,dx

mov edx,ad_msg_syst
bclrecmsgs:
cmp cl,0
je suitemsg
cmp byte[edx],0
jne paszeromsgs
dec cl
paszeromsgs:
inc edx
jmp bclrecmsgs




;***********************
affmsgerr:   ;affiche le message erreur nø=cl
push ecx
push edx
push ds
push fs
mov dx,seldat
mov ds,dx
mov fs,dx

mov edx,ad_msg_erreur
bclrecmsge:
cmp cl,0
je suitemsg
cmp byte[edx],0
jne paszeromsge
dec cl
paszeromsge:
inc edx
jmp bclrecmsge


;********************
affjournal:  ;copie chaine asciiz adressé par ds:edx dans le journal console
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

affh0j:      ;affiche dans le journal la valeur de al en hexadécimal
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

affh1j:      ;affiche dans le journal la valeur de ax en hexadécimal
push eax
xchg ah,al
call affh0j
mov al,ah
call affh0j
pop eax
ret

affh2j:     ;affiche le chiffre eax en hexadécimal
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


;********************************************************************
;sous fonctions 8042

at8042ok_lec:        ;attend que la puce ait des données disponible sur 60h
push eax
push ecx
mov ecx,10000
boucle_at8042ok_lec: 
in al,64h
test al,1
jnz at8042ok
dec ecx 
jnz boucle_at8042ok_lec 

at8042ok:
pop ecx
pop eax
ret


at8042ok_env:        ;attend la fin du traitement des donnes par la puce 8042
push eax
push ecx
mov ecx,10000
boucle_at8042ok_env: 
in al,64h
test al,2
jz at8042ok
dec ecx 
jnz boucle_at8042ok_env 
pop ecx
pop eax
ret



env_ps2:
call at8042ok_env
push eax
mov al,0D4h
out 64h,al
pop eax
call at8042ok_env
out 60h,al

lec_ps2:
call at8042ok_lec
in al,60h
fin_lec_ps2:
ret

env_8042_cmd:
call at8042ok_env
out 64h,al
call at8042ok_env
ret

env_8042_dat:
call at8042ok_env
out 60h,al
ret



vide_8042:
mov ecx,10000
@@:
dec ecx
jz @f
in al,60h
nop
in al,64h
test al,01h ;0=vide
jnz @b
@@: 
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





;***************************************************************************
;**************************************************                        *
;gestionnaires d'exceptions                      ;*                        *
                                                 ;*                        *
                                                 ;**************************
iex0:
mov cx,0
jmp exsigstop

iex1:
mov cx,1
jmp exsigcont

iex2:
mov cx,2
jmp exsigstop

iex3:
mov cx,3
jmp exsigcont

iex4:
mov cx,4
jmp exsigstop

iex5:
mov cx,5
jmp exsigstop

iex6:
mov cx,6
jmp exsigstop

iex7:
mov cx,7
jmp exsigstop

iex8:
mov cx,8
jmp exsigstop

iex9:
mov cx,9
jmp exsigstop

iexA:
mov cx,10
jmp exsigstop

iexB:
mov cx,11
jmp exsigstop

iexC:
mov cx,12
jmp exsigstop

iexD:
mov cx,13
jmp exsigstop

iexE:
mov cx,14
jmp exsigstop

iexF:
mov cx,15
jmp exsigstop

iex10:
mov cx,16
jmp exsigstop

iex11:
mov cx,17
jmp exsigstop

iex12:
mov cx,18
jmp exsigstop

iex13:
mov cx,19
jmp exsigstop

iex14:
mov cx,20
jmp exsigstop

iex15:
mov cx,21
jmp exsigstop

iex16:
mov cx,22
jmp exsigstop

iex17:
mov cx,23
jmp exsigstop

iex18:
mov cx,24
jmp exsigstop

iex19:
mov cx,25
jmp exsigstop

iex1A:
mov cx,26
jmp exsigstop

iex1B:
mov cx,27
jmp exsigstop

iex1C:
mov cx,28
jmp exsigstop

iex1D:
mov cx,29
jmp exsigstop

iex1E:
mov cx,30
jmp exsigstop

iex1F:
mov cx,31

exsigstop:  ;exception: signale et stoppe
mov dx,seldat      ;init pile et data
mov ds,dx
mov es,dx
mov fs,dx
mov gs,dx
;mov dx,selpil
;mov ss,dx
;mov esp,[sauv_esp_t0]
;sub esp,20h         ;pour avoir une pile sans ecraser la pile de la tache systême (désactivé parce que visiblement ça triple faute PARFOIS lorsque ça interromp un ring 0)


push cx

mov al,1Ch
call affcj

mov cl,42
call affmsgsyst


mov ax,[id_tache_exec]
call affh1j

mov cl,43
call affmsgsyst

pop cx

add cx,10
call affmsgsyst

;test si c'est l'exception du fpu et signale les eventuelles erreur
jmp suite_exception
cmp cx,26
jne suite_exception
push ecx
mov al,13
call affcj
fnstsw ax

test ax,1
jz exfpu_ni
mov ecx,37
call affmsgerr

mov ecx,eax
shr ecx,6
and ecx,1
add ecx,35
call affmsgerr
exfpu_ni:

test ax,2
jz exfpu_nd
mov ecx,38
call affmsgerr
exfpu_nd:

test ax,4
jz exfpu_nz
mov ecx,39
call affmsgerr
exfpu_nz:

test ax,8
jz exfpu_no
mov ecx,40
call affmsgerr
exfpu_no:

test ax,16
jz exfpu_nu
mov ecx,41
call affmsgerr
exfpu_nu:

test ax,32
jz exfpu_np
mov ecx,42
call affmsgerr
exfpu_np:


pop ecx
fnclex   ;clear les exception du fpu
suite_exception:

mov ax,[id_tache_fichier]
cmp [id_tache_exec],ax
jne excep_fc_ok
and byte[at_fc_fichier],0FEh
excep_fc_ok:

cmp word[id_tache_exec],0 ;si c'est une tache de base on l'arrete
je redem_id0
mov cl,46
call affmsgsyst
jmp int_60

redem_id0:  ;sinon on redemarre la tache principale
mov cl,44
call affmsgsyst
xor eax,eax
mov al,[trappe_tache0]
call affnj
mov dword[ad_tache_exec],0
mov word[id_tache_exec],0
mov byte[cpttc],25
mov cl,45
call affmsgsyst
mov esp,0FFFCh
sti
jmp selcod:btacheprincipale




exsigcont:  ;exception: signale et continue
push ecx
push ds
push ecx
mov cx,seldat      
mov ds,cx

mov al,1Fh
call affcj

mov cl,42
call affmsgsyst

mov ax,[id_tache_exec]
call affh1j

mov cl,43
call affmsgsyst

pop ecx
add cx,10
call affmsgsyst

mov al,13
call affcj
mov al,17h
call affcj

pop ds
pop ecx
iret





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
;pushad       ;TRAPPE
;push ax
;mov al,"!"
;call affcj
;pop ax
;call affh0j
;popad
cmp al,0FEh      ;demande de réenvoie touche
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
iret

;******************************************
nackcla:
shr dword[ztcl],8
mov [ztcl+3],al
xor cx,cx
cmp word[ztcl+2],02AE0h  ;ignore la première touche virtuelle généré par "verr num"
je finircl
cmp word[ztcl+2],0AAE0h  ;et son équivalent relachement de touche
je finircl
cmp word[ztcl+2],036E0h  ;ignore la seconde touche virtuelle généré par "verr num"
je finircl
cmp word[ztcl+2],0B6E0h  ;et son équivalent relachement de touche
je finircl


;*****************************************
;cherche a quel touche correspond la séquence de code envoyé par le clavier
bclintcl1:
mov bx,cx
shl bx,2
mov edx,[ad_tabclav_code+bx]
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
shl bx,2
mov eax,[ztcl+1]
and eax,00FFFFFFh
mov edx,[ad_tabclav_code+bx]
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
shl bx,2
mov eax,[ztcl+2]
and eax,00FFFFh
mov edx,[ad_tabclav_code+bx]
cmp eax,edx
je press
or dx,8080h
cmp eax,edx
je depress
inc cx
test cx,0FF80h
jz bclintcl3

xor cx,cx
bclintcl4:
mov bx,cx
shl bx,2
mov eax,[ztcl+3]
and eax,00FFh
mov edx,[ad_tabclav_code+bx]
cmp eax,edx
je press
or dl,80h
cmp eax,edx
je depress
inc cx
test cx,0FF80h
jz bclintcl4
jmp finircl

;*************************************************
;gestion lorsque la touche est relaché
depress:
mov dword[ztcl],0
mov bx,cx
mov ch,cl
and cl,07h
mov al,01h
shl al,cl
shr bx,3
mov ah,[atbp+bx]
not al
and ah,al
mov [atbp+bx],ah   ;met a jour la table d'état des touches
mov cl,ch
xor ch,ch

cmp cx,71           ;touche alt g    (num?ros de touche -1)
je depressalt
cmp cx,73           ;touche alt d    
je depressalt
jmp finircl


depressalt:
cmp word[no_ecran],0
jne fin_alttab
cmp dword[sv_alt],0  ;on verifie si il y as un caractère qui as été 
je finircl
mov eax,[sv_alt]
mov dword[sv_alt],0
jmp lect_touches_sp

;***************************************************
;gestion lorsque la touche touche est actionné
press:
mov dword[ztcl],0
mov bx,cx
mov ch,cl
and cl,07h
mov al,01h
shl al,cl
shr bx,3
mov ah,[atbp+bx]
or ah,al
mov [atbp+bx],ah   ;met a jour la table d'état des touches
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
cmp cx,104
je touche_retour_console ;touche list
;cmp cx,102
;je touche_retour_console   ;win G
;cmp cx,103
;je touche_retour_console    ;win D


cmp cx,30     ;touche tab
jne pas_touche_tab
mov ax,[atbp+8h]
test ax,0280h
jz pas_touche_tab 
test ax,0440h
jz debut_alttab
jmp touche_retour_console
pas_touche_tab:

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
jne pas_touche_reboot
mov ax,[atbp+8h]
test ax,0440h
jz pas_touche_reboot 
test ax,0280h
jz pas_touche_reboot 
jmp selcod16:reboot ;rebouter via le mode réel
pas_touche_reboot:


;test si les touches de changement de clavier
xor ebx,ebx
mov bl,[alclat1]
cmp cx,bx
je touche_clavier_alternatif1
mov bl,[alclat2]
cmp bx,0FFh
je pas_touche_clavier_alternative
cmp cx,bx
jne pas_touche_clavier_alternative

;si touche 2 on test si la touche 1 est déja enfoncé
push ecx
mov bl,[alclat1]
mov cl,[alclat1]
mov eax,1
shr ebx,3
and cl,7h
shl eax,cl
pop ecx
test [ebx+atbp],al
jz pas_touche_clavier_alternative
mov ax,[atbp+8h]
test ax,0440h
jz pas_touche_clavier_alternative 
jmp touche_clavier_alternative


touche_clavier_alternatif1:  ;si touche 1 on test si la touche 2 est déja enfoncé
mov bl,[alclat2]
cmp bl,0FFh
je touche_clavier_alternatif2
push ecx
mov cl,[alclat2]
mov eax,1
shr ebx,3
and cl,7h
shl eax,cl
pop ecx
test [ebx+atbp],al
jz pas_touche_clavier_alternative

touche_clavier_alternatif2:
mov ax,[atbp+8h]
test ax,0440h
jnz touche_clavier_alternative

pas_touche_clavier_alternative:

;******************************************************
charge_carac_touche:   ;charge le caractère associé a la touche
xor ebx,ebx
mov bx,cx
shl ebx,4
test byte[attcl],080h
jz clavier_alter_inactif 
add ebx,2048
clavier_alter_inactif:

test byte[atbp+7h],02h
jnz tkmaj
test byte[atbp+8h],20h
jnz tkmaj
test byte[attcl],04h
jnz tkvmaj

tknorm:
test byte[atbp+8h],80h  ;alt
jnz tkalt
test byte[atbp+9h],02h  ;alt gr
jnz tkalt
mov eax,[ad_tabclav_carac+ebx]
jmp lect_touches_sp

tkmaj:
test byte[attcl],04h
jnz tknorm
tkvmaj:
test byte[atbp+8h],80h  ;alt
jnz tkmajalt
test byte[atbp+9h],02h  ;alt gr
jnz tkmajalt
mov eax,[ad_tabclav_carac+ebx+4]
jmp lect_touches_sp

tkalt:
mov eax,[ad_tabclav_carac+ebx+8]
jmp lect_touches_sp

tkmajalt:
mov eax,[ad_tabclav_carac+ebx+12]

;*******************************************
;relève l'état des touches spéciales
lect_touches_sp:
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

mov bl,[atbp+0Ch]
and bl,0C0h   ;WinD +WinG
or ch,bl

;ch=touches spéciale pressé   0=majG 1=majD 2=CtrlG 3=CtrlD 4=Alt 5=AltGr 6=WinG 7=winD



;**********************************************
cmp eax,0
je ajoute_carac_zt
cmp dword[sv_chas],0
je verifie_chasse

mov ebx,ad_tabclav_chasse                            ;comme il y as un caractère de chasse enregistré, on verifie si il n'y as pas une correspondance
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
cmp ebx,ad_tabclav_chasse+3FFCh
jne boucle_recherche_correspondance_chasse

correspondance_chasse_pastrouve:
push eax
mov eax,[sv_chas]
mov dword[sv_chas],0 
xor ebx,ebx              ;ajoute le caractère de chasse dans la ZT clavier
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


;*******************************************************
verifie_chasse:     ;verifie que le caractère correspond a un caractère de chasse qui est présent dans la liste
mov ebx,ad_tabclav_chasse
boucle_recherche_chasse:
cmp dword[ebx],0
je ajoute_carac_zt 
cmp [ebx],eax
jne pas_chasse_trouve
mov [sv_chas],eax
jmp bougled
pas_chasse_trouve:
add ebx,12
cmp ebx,ad_tabclav_chasse+3FFCh
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




;****************************************
;gestion des touches spéciales
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
jz charge_carac_touche

xor edx,edx
mov eax,[sv_alt]
mov ecx,10
mul ecx
add eax,ebx
mov [sv_alt],eax
jmp finircl 

touche_clavier_alternative:
xor byte[attcl],080h
jmp finircl 



touche_retour_console: ;list ou ctrl+alt+tab
mov al,0
out 61h,al        ;éteint le bipper

mov dx,0
call sfv_sf_choix_console
jmp bougled


debut_alttab:    ;alt+tab
inc word[no_ecran]
mov ax,[nb_ecran]
cmp [no_ecran],ax
jae @f
call majv_complet
jmp bougled

@@:
mov word[no_ecran],0
call majv_complet
jmp bougled


fin_alttab:
xor ebx,ebx
mov bx,[no_ecran]
shl ebx,5
mov dx,[ebx+table_ecran_id]
call sfv_sf_choix_console
jmp bougled


;*****************************************************
irqsouris:
pushad
push ds

mov bx,seldat
mov ds,bx

xor bh,bh
mov bl,[nbzt1]       ;charge le nombre d'octet déja reçu
mov esi,[cptsf]
cmp [tps1],esi      ;si l'octet est reçu apres trop longtemps on reset la trame
ja @f
xor ebx,ebx
@@:
add esi,20h
mov [tps1],esi
mov si,bx
inc bl
mov [nbzt1],bl       ; et l'incrémente
in al,60h
mov [zts1+si],al    ;met le caractère reçu dans la zt souris
cmp [nbts1],bl
jne finirqs         ;si la trame n'as pas été totalement reçu -> fin

mov byte[nbzt1],0     ;on décode, d'abord mettre le compteur de la trame a zéros


;******************************************************met a jour la position curseur   
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

mov ax,[resx]                   ;ajuste la position x de la souris par
dec ax
cmp [xs1],ax                    ;rapport a la résolution de l'écran
jl passupxs1
mov [xs1],ax
passupxs1:
cmp word[xs1],0 
jg pasinfxs1
mov word[xs1],0
pasinfxs1:

mov ax,[resy]                   ;ajuste la position y de la souris par
dec ax
cmp [ys1],ax                    ;rapport a la résolution de l'écran
jl passupys1
mov [ys1],ax
passupys1:
cmp word[ys1],0 
jg pasinfys1
mov word[ys1],0
pasinfys1:




;************************************************************traitement cliques 0-3
mov cl,[zts1]
and cl,07h
test byte[atts1],2
jz irqs_pasbouton45
mov ch,[zts1+3]
and ch,30h
shr ch,1
or cl,ch
irqs_pasbouton45:
mov ch,[etbs1]
mov [etbs1],cl
xor cl,ch

test cl,1
jnz modifbts1
test cl,2
jnz modifbts2
test cl,4
jnz modifbts3
test cl,8
jnz modifbts4
test cl,16
jnz modifbts5
jmp molettes_souris

modifbts1:
test byte[zts1],1
jnz bts1_press
jmp bts1_depress 

modifbts2:
test byte[zts1],2
jnz bts2_press
jmp bts2_depress 

modifbts3:
test byte[zts1],4
jnz bts3_press
jmp bts3_depress 

modifbts4:
test byte[zts1+3],16
jnz bts4_press
jmp bts4_depress 

modifbts5:
test byte[zts1+3],32
jnz bts5_press
jmp bts5_depress 

bts1_press:
mov cl,0F0h
jmp code_souris_ok

bts1_depress:
mov cl,0F1h
jmp code_souris_ok

bts2_press:
mov cl,0F2h
jmp code_souris_ok

bts2_depress:
mov cl,0F3h
jmp code_souris_ok

bts3_press:
mov cl,0F4h
jmp code_souris_ok

bts3_depress:
mov cl,0F5h
jmp code_souris_ok

bts4_press:
mov cl,0F6h
jmp code_souris_ok

bts4_depress:
mov cl,0F7h
jmp code_souris_ok

bts5_press:
mov cl,0F8h
jmp code_souris_ok

bts5_depress:
mov cl,0F9h

;***************************************
code_souris_ok:         ;lit les touches spéciales
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

;*******************************************
xor ebx,ebx              ;ajoute le clique dans la ZT clavier
cmp byte[nb_zrc],42
je finirqs
mov bl,[nb_zrc]
inc byte[nb_zrc]
mov edx,ebx      ;mul ebx par 6
shl ebx,2
shl edx,1
add ebx,edx
mov [ebx+zt_rcl],cx
mov eax,[xs1]    ;xs1=lsb ys1=msb
mov [ebx+zt_rcl+2],eax


;******************************************
molettes_souris:   ;gestion de la molette souris
cmp byte[nbts1],4
jne finirqs

test byte[atts1],2    ;etend le bit de signe si on est en mode 5 boutons
jz molettesansbouton
and byte[zts1+3],0Fh
test byte[zts1+3],08h
jz molettesansbouton
or byte[zts1+3],0F0h
molettesansbouton:

boucle_molette:
cmp byte[zts1+3],0
je finirqs 
test byte[zts1+3],80h
jnz molette_haut

xor ebx,ebx              ;ajoute la touche bas dans la ZT clavier
cmp byte[nb_zrc],42
je finirqs
mov bl,[nb_zrc]
inc byte[nb_zrc]
mov edx,ebx      ;mul ebx par 6
shl ebx,2
shl edx,1
add ebx,edx
test word[atbp+8h],0280h    ;alt
jnz alt_bt_mb
test word[atbp+8h],0440h    ;ctrl
jnz ctrl_bt_mb
mov word[ebx+zt_rcl],84   ;bas
jmp pas_bt_mb
alt_bt_mb:
mov word[ebx+zt_rcl],85   ;droite
jmp pas_bt_mb
ctrl_bt_mb:
mov word[ebx+zt_rcl],81   ;page bas
pas_bt_mb:
mov dword[ebx+zt_rcl+2],0
dec byte[zts1+3]
jmp boucle_molette

molette_haut:
xor ebx,ebx              ;ajoute la touche haut dans la ZT clavier
cmp byte[nb_zrc],42
je finirqs
mov bl,[nb_zrc]
inc byte[nb_zrc]
mov edx,ebx      ;mul ebx par 6
shl ebx,2
shl edx,1
add ebx,edx
test word[atbp+8h],0280h    ;alt
jnz alt_bt_mh
test word[atbp+8h],0440h    ;ctrl
jnz ctrl_bt_mh
mov word[ebx+zt_rcl],82   ;haut
jmp pas_bt_mh
alt_bt_mh:
mov word[ebx+zt_rcl],83   ;gauche
jmp pas_bt_mh
ctrl_bt_mh:
mov word[ebx+zt_rcl],78   ;page haut
pas_bt_mh:
mov dword[ebx+zt_rcl+2],0
inc byte[zts1+3]
jmp boucle_molette


finirqs:
mov al,20h
out 0A0h,al
mov al,20h
out 20h,al
pop ds
popad
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
push eax
push ds
jmp commutation

int_63:             ;fonction interface
include "SF_VID.ASM" 

int_64:
include "SF_FICH.ASM" ;fonction générales et système de fichier
include "SF_DISK.ASM" ;fonction de lecture disques

int_65: ;communication inter tache 
include "SF_COM.ASM"

int_66:
include "SF_PORT.ASM"



int_68:
include "SF_USB.ASM"


int_67:
int_69:
int_6A:
int_6B:
int_6C:
int_6D:
int_6E:
int_6F:
int_vide:
iret

finsegcod:
