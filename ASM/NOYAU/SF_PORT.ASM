;gestion de la taille de la zt de reception
;gestion du blocage de l'acc�s pour les autres t�ches
;lecture/ecriture des bits sp�ciaux




;fonction pour port parral�le et s�rie int 66h
;al=0 envoyer octet
;al=1 envoyer chaine
;al=2 re�evoir octet
;al=3 re�evoir chaine
;al=4 lecture des bit de controle des ports 
;al=5 ecriture des bit de controle des ports
;al=6 configurer port 
;al=7 reserver acc�s port
;al=8 liberer acc�s port
;al=9 changer la taille de la zt de reception

push ebx
push edx
push esi
push edi
push ds
push es
push fs
push ax
mov ax,seldat
mov ds,ax
mov ax,selramh
mov fs,ax
pop ax

cmp ah,15
ja sf_port_fin_parami
 
xor ebx,ebx  ;charge adresse de base du contoleur port dans di et la base dans ebx
xchg bl,ah
shl ebx,2
mov di,[port_com_base+ebx]
cmp di,0
je sf_port_fin_parami

;verifie que le port n'est pas reserv� et si la tache qui l'as reserv� existe bien toujours
push esi
mov si,[port_com_idr+ebx]
cmp si,0
je sf_port_okid
cmp si,[id_tache_exec]
je sf_port_okid
pop esi
mov eax,cer_ano  ;action non autoris�
xor ecx,ecx
jmp sf_port_fin

sf_port_okid:
pop esi
cmp al,0
je sf_port_env1
cmp al,1
je sf_port_env2
cmp al,2
je sf_port_rec1
cmp al,3
je sf_port_rec2
cmp al,4
je sf_port_sp1
cmp al,5
je sf_port_sp2
cmp al,6
je sf_port_conf
cmp al,7
je sf_port_res
cmp al,8
je sf_port_dres
cmp al,9
je sf_port_zt

sf_port_fin_parami:
mov eax,cer_parami

sf_port_fin_erreur:
xor ecx,ecx

sf_port_fin:
pop fs
pop es
pop ds
pop edi
pop esi
pop edx
pop ebx
sti
iret









;*****************************************************************
sf_port_env1:      ;envoie 1 octet sur port s�rie et parall�le
                   ;cl=octet a envoyer
                   ;entr�e ah=N� du port 0-7 port COM 8-15 portLPT
                   ;retour eax=erreur
call sf_port_env
xor ecx,ecx
jmp sf_port_fin
;*****************************************************************
sf_port_env2:      ;envoie une chaine d'octet sur port s�rie et parall�le
                   ;es:esi=adresse de la chaine
		   ;ecx=nombre d'octet de la chaine
                   ;entr�e ah=N� du port 0-7 port COM 8-15 portLPT
                   ;retour eax=erreur
mov edx,ecx
mov ch,ah
xor eax,eax
cmp edx,0
je sf_port_fin

boucle_sf_port_env2: 
es
mov cl,[esi]
mov ah,ch
call sf_port_env
cmp eax,0
jne sf_port_fin_erreur
inc esi
dec edx
jnz boucle_sf_port_env2 
xor eax,eax
xor ecx,ecx
jmp sf_port_fin

;*****************************************************************
sf_port_env:       ;envoie 1 octet sur port s�rie et parall�le
pushad
cmp ah,7
ja sf_port_env_lpt

mov dx,di
add dx,5
mov ebx,[cptsf]
add ebx,40      ;temps d'atente maximum 100ms

boucle_env_com:
int 62h
in al,dx
test al,20h
jnz ok_env_com    ;si connex ok envoie
cmp [cptsf],ebx
jb boucle_env_com
popad
mov eax,cer_crp   ;controleur ne r�pond pas
ret

ok_env_com:
mov dx,di
mov al,cl
out dx,al
popad
xor eax,eax
ret

sf_port_env_lpt:

mov al,cl
mov dx,di
out dx,al ;�crit l'octet sur le port de donn�es

inc dx
mov ecx,[cptsf]
add ecx,200      ;temps d'atente maximum 500ms

boucle1_sf_port_env_lpt:   ;atent que le signal busy ne soit plus actif
int 62h
in al,dx
test al,80h
jnz sf_port_env_lpt_ok
cmp [cptsf],ecx
jb boucle1_sf_port_env_lpt
popad
mov eax,cer_crp   ;controleur ne r�pond pas
ret


sf_port_env_lpt_ok:
inc dx
in al,dx
mov ah,al
or al,05h
out dx,al         ;active le signal output data   
int 62h
mov al,ah
out dx,al    ;puis le d�sactive





sf_port_env_lpt_fin:
popad
xor eax,eax
ret






;*************************************************************************
sf_port_rec1:         ;lit octet re�u sur zt du port s�rie et parall�le
                      ;entr�e ah=N� du port 0-3 portCOM 4-5 portLPT
		      ;octet en retour=cl

cmp ah,7
ja sf_port_fin_parami
  
cli
cmp dword[port_com_to+ebx],0
jne sf_port_rec1_suite
xor ecx,ecx
mov eax,cer_ztv  ;zone tampon vide
jmp sf_port_fin 

sf_port_rec1_suite:
dec dword[port_com_to+ebx]
mov edi,[port_com_zt+ebx]
mov ecx,[port_com_to+ebx]
mov ax,selramh
mov ds,ax
mov es,ax
mov esi,edi
add edi,10h
add esi,11h
mov al,[edi]
cld
rep movsb


xor ecx,ecx
mov cl,al
xor eax,eax
jmp sf_port_fin 


;*************************************************************************
sf_port_rec2:         ;lit chaine d'octet re�u sur zt du port s�rie et parall�le
                      ;entr�e ah=N� du port 0-3 portCOM 4-5 portLPT
		      ;es:edi=
		      ;ecx=taille de la chaine a lire
cmp ah,7
ja sf_port_fin_parami
  
cli
mov eax,[port_com_to+ebx]
cmp eax,0
jne sf_port_rec2_suite
xor ecx,ecx
mov eax,cer_ztv  ;zone tampon vide
jmp sf_port_fin 

sf_port_rec2_suite:   ;verifie que la zt puisse re�evoir toutes les donn�es
cmp ecx,eax
ja sf_port_rec2_partiel

mov ecx,eax
mov dword[port_com_to+ebx],0
mov esi,[port_com_zt+ebx]
add esi,10h
mov ax,selramh
mov ds,ax
cld
rep movsb

xor ecx,ecx
xor eax,eax
jmp sf_port_fin 



sf_port_rec2_partiel:   ;si la zt ne peut pas lire toutes les donn� on en lit qu'une partie
sub [port_com_to+ebx],ecx
mov esi,[port_com_zt+ebx]
add esi,10h
mov ax,selramh
mov ds,ax
cld
rep movsb

mov ax,seldat           ;et on d�cale les donn�es
mov ds,ax
mov edi,[port_com_zt+ebx]
add edi,10h
mov ecx,[port_com_to+ebx]
mov ax,selramh
mov ds,ax
mov es,ax
cld
rep movsb

xor ecx,ecx
xor eax,eax
jmp sf_port_fin 

;************************************************************************
sf_port_sp1:                 ;lire bit etat    ah=num�ros de port ecx=bit sp�ciaux du port
;ecx pour port com:
;b0=DTR b1=RTS b2=CTS b3=DSR b4=RI b5=DCD/RLSD
;ecx pour port lpt:
;b0=saut de page
;b1=reset
;b2=selection p�riph�rique
;b3=signal erreur
;b4=signal p�riph�rique on line
;b5=signal plus de papier


xor ecx,ecx
cmp ah,7
ja sf_port_sp1_lpt

xor eax,eax
mov dx,di
add dx,4
in al,dx
and al,03h
or ecx,eax
add dx,2
xor eax,eax
in al,dx
and al,0F0h
shr eax,2
or ecx,eax
xor eax,eax
jmp sf_port_fin 


sf_port_sp1_lpt:
xor eax,eax
mov dx,di
inc dx
in al,dx
and al,1Ch
shr eax,2
or ecx,eax
inc dx
xor eax,eax
in al,dx
and al,0Eh
shl eax,2
or ecx,eax
xor eax,eax
jmp sf_port_fin 



;************************************************************************
sf_port_sp2:
cmp ah,7
ja sf_port_sp2_lpt

mov dx,di
add dx,4
in al,dx
and al,0FCh
and cl,003h
or al,cl
out dx,al
xor eax,eax
jmp sf_port_fin 

sf_port_sp2_lpt:
mov dx,di
add dx,2
in al,dx
and al,0F8h
and cl,007h
or al,cl
out dx,al
xor eax,eax
jmp sf_port_fin 

;************************************************************************
sf_port_conf:    ;configure le port com
                 ;ah=n�du port (0 � 7)
                 ;ecx=vitesse du port (max 115200bit/s)
                 ;dl=config:
;4|3|2|1|0|  
;| | | | `-- 0 = 7 bits par caract�re 1 = 8bit par caract�re
;| | | `---- innutilis�
;| | `------ 0 = 1 bit de stop, 1 =  2 bit de stop 
;| `-------- 0 = pas de bit de parit�, 1 = pr�sence d'un bit de parit�
;`---------- 0 = parit� impaire(odd), 1 = parit� paire(even)

cmp ah,7
ja sf_port_fin_parami
cmp ecx,115200
ja sf_port_fin_parami

mov bl,dl
and bl,1Dh    ;complete l'option de config pour obtenir le LCR(line controle register)
or  bl,02h

xor edx,edx
mov eax,115200  ;1843200/16
div ecx
mov ecx,eax      ;ecx=diviseur
cmp edx,0
jne sf_port_fin_parami    ;le reste doit �tre 0

mov dx,di ;dx=base+3
add dx,3
mov al,80h
out dx,al      ;line control register dlab=1

mov dx,di;dx=base+0
mov al,cl      ;lsb diviseur
out dx,al
inc dx    ;dx=base+1
mov al,ch      ;msb diviseur
out dx,al
add dx,2  ;dx=base+3
mov al,bl     ;line control register
out dx,al
mov dx,di ;dx=base+1
inc dx
mov al,01h    ;interrupt enable register  (interruption si donn�e re�u)
out dx,al

add dx,3    ;dx=base+4
mov al,08h    ;out2=1 (pour le circuit d'oscillation?!) DTR=1 RTS=1 sur le MCR (pour le circuit d'oscillation?!)
out dx,al
xor eax,eax
jmp sf_port_fin




;************************************************************************
sf_port_res:                ;reserve le port pour l'usage d'une seule application
mov ax,[id_tache_exec]
mov [port_com_idr+ebx],ax
xor ecx,ecx
xor eax,eax
jmp sf_port_fin

;************************************************************************
sf_port_dres:                ;lib�re le port pour l'usage d'une seule application
mov dword[port_com_idr+ebx],0
xor ecx,ecx
xor eax,eax
jmp sf_port_fin

;************************************************************************
sf_port_zt:              ;redimensionne la zt de reception d'un port
cmp ah,7
ja sf_port_fin_parami

mov edx,ebx
mov ebx,[port_com_zt+edx]
call modtm
jc sf_port_zt_erreur 
mov [port_com_zt+edx],ebx
xor ecx,ecx
xor eax,eax
jmp sf_port_fin

sf_port_zt_erreur:
mov eax,cer_pasm
jmp sf_port_fin_erreur







;************************************************************************************************************************
irqcom: ;interruption par un controleur de port COM
cli
push eax
push ebx
push ecx
push edx
push edi
push ds
push es
mov bx,seldat
mov ds,bx
mov bx,selramh
mov es,bx

xor ebx,ebx
cherche_origine_irq_com:
mov dx,[ebx+port_com_base]
cmp dx,0
je suite_origine_irq_com 
add dx,2    ;adress du Interrupt Identification Register
in al,dx

and al,07h   ;on test si une interruption donn�es disponible est en cours sur le controleur
cmp al,04h 
je trouve_origine_irq_com
suite_origine_irq_com:
add ebx,4
cmp ebx,20h
jne cherche_origine_irq_com
jmp fin_irq_com

trouve_origine_irq_com:
sub dx,2  ;lit l'octet re�u
in al,dx

;verifie que la zt n'est pas pleine
mov edi,[ebx+port_com_zt]
mov ecx,[ebx+port_com_to]
add ecx,10h
es
cmp ecx,[edi+to_tache]
jae fin_irq_com 

;ajoute dans la zt
add edi,ecx
es
mov [edi],al
inc dword[ebx+port_com_to]


fin_irq_com:
mov al,20h
out 20h,al
pop es
pop ds
pop edi
pop edx
pop ecx
pop ebx
pop eax
sti
iret


