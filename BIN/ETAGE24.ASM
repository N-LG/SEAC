
;table des valeurs a communiquer a l'etage 3
nb_ram equ 7C00h






org 7E00h  ;a copier juste apres le  secteur de bout 
use16


;***************************************************
;désactive et masque les irq
cli
mov al,0FFh
out 021h,al
out 0A1h,al



;*********************************************************************
;passage en flat real mode
xor ax,ax
mov ds,ax
lgdt[vecteur_gdt]  ;charge la gdt
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
xor ax,ax
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ax,9000h
mov ss,ax
mov sp,0FFF0h



;*********************************************************************
;active la ligne A20 pour pouvoir écrire dns la zone memoire superieur!!!!!!!!!!!!!!!!!!!!!méthode ne fonctionnant pas a chaque fois m'as t'on dit
in al, 092h
or al, 2
out 92h, al
    

;test si la ligne A20 est bien désactivé
xor eax,eax
mov ds,ax
mov eax,[0]
xor eax,055AA55AAh
mov [100000h],eax      ;on écrit a 1Mo un truc forcément différent de 0
nop
nop
nop
nop
nop
nop
nop
nop
cmp [100000h],eax      ;on vérifie que l'ecriture est bien effective
je autre_methode_A20
mov eax,[0]
cmp [100000h],eax
jne ignore_2eme_methode_A20


;autre méthode pour activer la ligne A20 (si l'autre ne fonctionne pas!!!)
autre_methode_A20:
mov al,0D1h          ;active A20
out 64h,al           ;la prochaine ?criture sur 60h sera pour le port de sortie
;call attporok
mov al,0DFh
out 60h,al           ;envoie de la configuration pour l'activation de l'A20
;call attporok
mov al,0FFh          ;envoie une commande d'impulsion sur aucune des sorties
out 64h,al            
;call attporok  


ignore_2eme_methode_A20:



;*******************************************************************************************
;test la taille de la ram

mov ebx,100000h     
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
mov [nb_ram],ebx      ;sauvegarde la quantité total de ram

                             ;crée le premier descripteur de m?moire vide
mov dword[100000h],"DMV?"
mov dword[100004h],ebx
mov dword[100008h],"????"  
mov dword[10000Ch],"????"


;**********************************************************************
;ajoute les fichier RAM
mov esi,fichiers_mem
mov edi,100000h

copie_fichier:
cmp byte[esi+2],"F"
je fin_copie_fichier
cmp byte[edi+2],"F"
je incomplet_copie_fichier
cmp byte[edi+2],"V"
jne zone_suivante

mov ecx,[esi+4]
mov ebx,[edi+4]
cmp ecx,ebx
ja zone_suivante

sub ebx,ecx
shr ecx,2
boucle:
mov eax,[esi]
mov [edi],eax
add esi,4
add edi,4
dec ecx
jnz boucle
cmp ebx,0
je copie_fichier
mov dword[edi],"DMV?"
mov dword[edi+4],ebx
mov dword[edi+8],0
mov dword[edi+12],0
jmp copie_fichier

zone_suivante:
mov eax,[edi+4]
add edi,eax
jmp copie_fichier


incomplet_copie_fichier:
;eventuellement message signalant l'impossibilité de charger completement les fichiers

fin_copie_fichier:




;***************************************************************************
;recopie les données de l'étage 3 en 5000h:0000h et fait un saut
mov esi,data_etage3
mov edi,50000h
mov ecx,fin_etage3-data_etage3+3
shr ecx,2
boucle_copie_etage3:
mov eax,[esi]
mov[edi],eax
add esi,4
add edi,4
dec ecx
jnz boucle_copie_etage3
jmp 5000h:0000h



vecteur_gdt:
dw 15           ;taille-1
dd table_gdt    ;adresse



table_gdt:
dd 0,0   ;selecteur vide
dw 0FFFFh ;segment de données de 4Go
db 0,0,0
dw 0CF92h ;data r/w granularité 4K + limite
db 0

fichiers_mem:
dd "DMX?"
dd data_etage4-fichiers_mem         ;taille de la zone mémoire utilisé par le fichier
dd fin_etage3-data_etage3           ;taille réelle du fichier
dd 0                                ;réservé 
db "ETAGE3.BIN"                     ;nom du fichier
rb 416 - ($ - fichiers_mem)mod 416  ;remplissage pour faire une entête de 416 octet

data_etage3:
file "ETAGE3.BIN"
fin_etage3:

rb 16 - ($ - fichiers_mem)mod 16   ;remplissage pour faire que le fichier ai une granularité de 16 octets
 

data_etage4:
org 0h





zone1:
dd "DMX?"
dd fin_zone1-zone1                  ;taille de la zone mémoire utilisé par le fichier
dd fin_fichier1-fichier1            ;taille réelle du fichier
dd 0                                ;réservé 
db "cfg.sh"                         ;nom du fichier
rb 416 - ($ - zone1)mod 416         ;remplissage pour faire une entête de 416 octet

fichier1:
db "ex #dd1/boot.sh",10,13



fin_fichier1:

rb 16 - ($ - zone1)mod 16        ;remplissage pour faire que le fichier ai une granularité de 16 octets
 
fin_zone1:









;marqueur de fin de l'archive
db "DMF?"
dd 0,0,0












