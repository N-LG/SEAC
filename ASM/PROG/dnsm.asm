pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "filtrage DNS"
scode:
org 0

;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax

;rechercher service ethernet
mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,zt_recep
int 61h

mov bx,[zt_recep]
mov [id_tache],bx


;***********************************************************
;etablire une connexion
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,2000
mov edi,2000
int 65h
mov [adresse_canal],ebx

;configure en écoute pour le port UDP53
mov byte[zt_recep],7
mov word[zt_recep+2],53

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,zt_recep
mov edi,0
int 65h
cmp eax,0
jne erreur_init_cpnr 


;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne erreur_init_cpnr 

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,0
mov edi,zt_recep
int 65h
cmp eax,0
jne erreur_init_cpnr 

cmp byte[zt_recep],87h
jne erreur_init_cpnr



;***********************************************************
;etablire une 2eme connexion
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,2000
mov edi,2000
int 65h
mov [adresse_canal2],ebx

;configure en écoute pour le port UDP253
mov byte[zt_recep],7
mov word[zt_recep+2],253

mov al,5
mov ebx,[adresse_canal2]
mov ecx,34h
mov esi,zt_recep
mov edi,0
int 65h
cmp eax,0
jne erreur_init_cpnr 


;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal2]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne erreur_init_cpnr 

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal2]
mov ecx,34h
mov esi,0
mov edi,zt_recep
int 65h
cmp eax,0
jne erreur_init_cpnr 

cmp byte[zt_recep],87h
jne erreur_init_cpnr





boucle:
int 62h   

;test si il y as des données a reçevoir
mov al,3
int 65h
cmp eax,cer_ddi
jne boucle

cmp ebx,[adresse_canal2]
je partie2


;**************************** "faux" port DNS
;lit les données reçu
mov al,6
mov edi,zt_recep
mov ecx,512
int 65h

mov ax,[zt_recep]
mov bx,[zt_recep+22]
mov edx,[zt_recep+2]
mov edi,[pointeur_correspondance]
add edi,table_correspondance
mov [edi],bx
mov [edi+2],ax
mov [edi+4],edx
add dword[pointeur_correspondance],8
and dword[pointeur_correspondance],7FFh


mov word[zt_recep],53
mov eax,[serveur]
mov [zt_recep+2],eax

mov ebx,[adresse_canal2]   ;renvoie sur un véritable serveur DNS
mov al,7
mov esi,zt_recep
int 65h

mov edx,msg1
mov al,6        
int 61h

mov esi,zt_recep+22+12
bouclebizzard:
xor eax,eax
mov al,[esi]
cmp eax,0
je finbouclebizzard
inc eax
mov byte[esi],"."
add esi,eax
jmp bouclebizzard

finbouclebizzard:
mov edx,zt_recep+22+13
mov al,6        
int 61h

;mov esi,zt_recep+22
;mov edi,esi
;add edi,ecx
;bouclemerde:
;mov cl,[esi]
;mov edx,tempo
;mov al,105
;int 61h
;mov edx,tempo
;mov al,6
;int 61h
;inc esi
;cmp esi,edi
;jne bouclemerde

mov edx,msg3
mov al,6        
int 61h
jmp boucle


partie2:

mov al,6
mov edi,zt_recep
mov ecx,512
int 65h

mov ax,[zt_recep+22]
mov edi,table_correspondance
boucle_partie2:
cmp [edi],ax
je suite_partie2
add edi,8
cmp edi,table_correspondance+2048
jne boucle_partie2
jmp boucle

suite_partie2:
mov ax,[edi+2]
mov edx,[edi+4]
mov [zt_recep],ax
mov [zt_recep+2],edx


mov ebx,[adresse_canal]
mov al,7
mov esi,zt_recep
int 65h


mov edx,msg2
mov al,6        
int 61h

;mov esi,zt_recep+22
;mov edi,esi
;add edi,ecx
;bouclemerde2:
;mov cl,[esi]
;mov edx,tempo
;mov al,105
;int 61h
;mov edx,tempo
;mov al,6
;int 61h
;inc esi
;cmp esi,edi
;jne bouclemerde2

mov edx,msg3
mov al,6        
int 61h
jmp boucle


erreur_init_cpnr:

mov cx,[zt_recep]
mov edx,zt_recep
mov al,104
int 61h

mov edx,zt_recep
mov al,6        
int 61h

mov edx,msg3
mov al,6        
int 61h


int 60h

sdata1:
org 0
adresse_canal:
dd 0
adresse_canal2:
dd 0
id_tache:
dw 0

port_client:
dw 0
client:
db 192,168,1,40
serveur:
;db 192,168,1,1
;verisign
db 64,6,64,6
;64.6.65.6
;fdn
;80.67.169.12
;80.67.169.40
;google
;8.8.8.8
;8.8.4.4


tempo:
dd 0,0,0,0,0,0,0,0,0,0,0,0
msg1:
db 19h,"Demande résolution DNS: ",0
msg2:
db 1Ch,"!",0
msg3:
db 17h,13,0

pointeur_correspondance:
dd 0

zt_recep:
rb 2047
db 0
table_correspondance:
rb 2047
db 0

sdata2:
org 0
;données du segment ES
sdata3:
org 0
;données du segment FS
sdata4:
org 0
;données du segment GS
findata:
