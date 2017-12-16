;gestion de la taille de la zt de reception
;gestion du blocage de l'accès pour les autres tâches
;lecture/ecriture des bits spéciaux




;fonction pour port parralèle et série int 66h
;al=0 envoyer octet
;al=1 envoyer chaine
;al=2 reçevoir octet
;al=3 reçevoir chaine
;al=4 reserver accès port
;al=5 configurer port 
;al=6 lecture/ecriture des bit de controle des ports 
;al=7 changer la taille de la zt de reception

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
xor bl,ah
shl ebx,2
mov di,[port_com_base+ebx]
cmp di,0
je sf_port_fin_parami

;verifie que le port n'est pas reservé et si la tache qui l'as reservé existe bien toujours
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
;mov eax,cer_ano  ;action non autorisé
;xor ecx,ecx
;jmp sf_port_fin

cmp al,0
je sf_port_env1
cmp al,1
je sf_port_env2
cmp al,2
je sf_port_rec1
cmp al,3
je sf_port_rec2
cmp al,4
je sf_port_res
cmp al,5
je sf_port_conf
cmp al,6
je sf_port_sp
cmp al,7
je sf_port_zt

sf_port_fin_parami:
xor ecx,ecx
mov eax,cer_parami

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







xor ecx,ecx
jmp sf_port_fin





;*****************************************************************
sf_port_env1:      ;envoie 1 octet sur port série et parallèle
                   ;cl=octet a envoyer
                   ;entrée ah=N° du port 0-7 port COM 8-15 portLPT
                   ;retour eax=erreur
call sf_port_env
xor ecx,ecx
jmp sf_port_fin
;*****************************************************************
sf_port_env2:      ;envoie une chaine d'octet sur port série et parallèle
                   ;es:esi=adresse de la chaine
		   ;ecx=nombre d'octet de la chaine
                   ;entrée ah=N° du port 0-7 port COM 8-15 portLPT
                   ;retour eax=erreur
mov edx,ecx
boucle_sf_port_env2: 
es
mov cl,[esi]
call sf_port_env
xor ecx,ecx
cmp eax,0
jne sf_port_fin
inc esi
dec edx
jnz boucle_sf_port_env2 
xor eax,eax
xor ecx,ecx
jmp sf_port_fin

;*****************************************************************
sf_port_env:       ;envoie 1 octet sur port série et parallèle

cmp ah,8
jae sf_port_env_lpt

mov dx,di
add dx,5
mov ebx,[cptsf]
add ebx,40      ;temps d'atente maximum 100ms

boucle_env_com:
in al,dx
test al,20h
jnz ok_env_com    ;si connex ok envoie
cmp [cptsf],ebx
jb boucle_env_com
mov eax,cer_crp   ;controleur ne répond pas
ret

ok_env_com:
mov dx,di
mov al,cl
out dx,al
xor eax,eax
ret

sf_port_env_lpt:

;out dx,al
;mov ah,al
;add dx,2
;mov al,04h
;out dx,al
;dec dx
;add ecx,200

;boucle_sf_port_env_lpt:
;in al,dx
;test al,80h
;jnz sf_port_env_lpt_ok
;cmp [cptsf],ecx
;jne boucle_sf_port_env_lpt



;sf_port_env_lpt_ok:
;inc dx
;mov al,05h
;out dx,al
;mov ecx,1
;int 8Fh          ;???????????????
;mov al,04h
;out dx,al
xor eax,eax
ret






;*************************************************************************
sf_port_rec1:         ;lit octet reçu sur zt du port série et parallèle
                      ;entrée ah=N° du port 0-3 portCOM 4-5 portLPT
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
rep movsb


xor ecx,ecx
mov cl,al
xor eax,eax
jmp sf_port_fin 


;*************************************************************************
sf_port_rec2:         ;lit chaine d'octet reçu sur zt du port série et parallèle
                      ;entrée ah=N° du port 0-3 portCOM 4-5 portLPT
		      ;ecx=taille de la chaine a lire
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§s
jmp sf_port_fin_parami 


;************************************************************************
sf_port_res:                ;reserve le port pour l'usage d'une seule application
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp sf_port_fin_parami 


;************************************************************************
sf_port_conf:    ;configure le port com
                 ;ah=n°du port (0 à 7)
                 ;ecx=vitesse du port (max 115200bit/s)
                 ;bl=config:
;4|3|2|1|0|  
;| | | | `-- 0 = 7 bits par caractère 1 = 8bit par caractère
;| | | `---- innutilisé
;| | `------ 0 = 1 bit de stop, 1 =  2 bit de stop 
;| `-------- 0 = pas de bit de parité, 1 = présence d'un bit de parité
;`---------- 0 = parité impaire(odd), 1 = parité paire(even)

cmp ah,7
ja sf_port_fin_parami
cmp ecx,115200
ja sf_port_fin_parami


and ah,1Dh    ;complete l'option de config pour obtenir le LCR(line controle register)
or  ah,02h

push eax
xor edx,edx
mov eax,115200  ;1843200/16
div ecx
mov ecx,eax      ;ecx=diviseur
pop eax
cmp edx,0
jne sf_port_fin_parami    ;le reste doit être 0

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
mov al,ah     ;line control register
out dx,al
mov dx,di ;dx=base+1
inc dx
mov al,01h    ;interrupt enable register  (interruption si donnée reçu)
out dx,al

add dx,3    ;dx=base+4
mov al,08h    ;out2=1 (pour le circuit d'oscillation?!) DTR=1 RTS=1 sur le MCR (pour le circuit d'oscillation?!)
out dx,al
xor eax,eax
jmp sf_port_fin



;************************************************************************
sf_port_sp:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp sf_port_fin_parami 



;************************************************************************
sf_port_zt:              ;redimensionne la zt de reception d'un port
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp sf_port_fin_parami 






;************************************************************************************************************************
irqcom: ;interruption par un controleur de port COM
cli
push eax
push ebx
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
add dx,2    ;adress du Interrupt Identification Register
in al,dx

and al,07h   ;on test si une interruption données disponible est en cours sur le controleur
cmp al,04h 
;test al,1
je trouve_origine_irq_com
add ebx,4
cmp ebx,20h
jne cherche_origine_irq_com
jmp fin_irq_com

trouve_origine_irq_com:
sub dx,2  ;lit l'octet reçu
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

;mov al,3
;out 61h,al        ;allume le bipper


fin_irq_com:
mov al,20h
out 20h,al
pop es
pop ds
pop edi
pop edx
pop ebx
pop eax
sti
iret


