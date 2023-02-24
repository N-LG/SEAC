bidon:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "mini serveur http"
scode:
org 0

port_client equ 0
offset_zt equ 4
adresse_com equ 8
ipv4_client equ 12
ipv6_client equ 16
zt_donnee equ 32


to_reception equ 4096

zts_reception equ zt_decode+to_reception*256




;données du segment CS

mov ax,sel_dat1
mov ds,ax
mov es,ax


;****************************************************************
;redimensionne la mémoire pour y enregistrer toute les zt de reception
mov eax,to_reception
mov ecx,[nb_reception]
mul ecx
mov ecx,zts_reception
add ecx,eax
mov dx,sel_dat1
mov al,8
int 61h




;**************************************************************
;determine l'id du service ethernet
mov byte[zt_decode],0

mov al,5   
mov ah,"c"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_decode
int 61h
xor ebx,ebx
cmp eax,0
jne @f

mov al,100  
mov edx,zt_decode
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

@@:
mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,zt_decode
int 61h

shl ebx,1
mov ax,[zt_decode+ebx]
mov [id_tache],ax



;**************************************************************
;ouvre dossier des fichier du site
mov byte[zt_decode],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_decode
int 61h

cmp byte[zt_decode],0
je aff_err_param


xor eax,eax
mov bx,0
mov edx,zt_decode
int 64h
cmp eax,cer_dov
jne erreur_ouverture_dossier

mov [dossier_site],ebx


;***********************************************************
;etablire une connexion
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,0
mov esi,0
mov edi,0
int 65h
mov [adresse_canal],ebx

;configure en écoute pour le port TCP80
mov word[zt_decode],8      ;ouverture port tcp
mov word[zt_decode+2],80
mov word[zt_decode+4],12 ;connexion max
mov dword[zt_decode+6],to_reception*1024 ;taille de la zt de communication a reserver a chaque canal de communication

mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,zt_decode
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
mov edi,zt_decode
int 65h
cmp eax,0
jne erreur_init_cpnr 

cmp byte[zt_decode],88h
jne erreur_init_cpnr




;********************
mov edx,msg_ok
mov al,6        
int 61h



;*****************************************************************
boucle_principale:
int 62h

;lire nouvelle connexion
mov al,2
int 65h
cmp eax,cer_ddi
jne test_donnee_rec

mov al,4
mov ecx,40h
mov esi,0
mov edi,zt_decode
int 65h


;si nouvelle créer descripteur
mov esi,zts_reception
mov ecx,[nb_reception]
boucle_cree_descr:
cmp word[esi+port_client],0
je descripteur_vide
add esi,to_reception
dec ecx
jnz boucle_rech_descr



mov eax,1 ;si nb max atteind, on supprime la connexion
int 65h
jmp test_donnee_rec

descripteur_vide:
mov ax,[zt_decode+0Ah]
mov [esi+port_client],ax
mov dword[esi+offset_zt],0
mov [esi+adresse_com],ebx
mov eax,[zt_decode+0Ch]
mov [esi+ipv4_client],eax
mov eax,[zt_decode+10h]
mov edx,[zt_decode+14h]
mov [esi+ipv6_client],eax
mov [esi+ipv6_client+4],edx
mov eax,[zt_decode+18h]
mov edx,[zt_decode+1Ch]
mov [esi+ipv6_client+8],eax
mov [esi+ipv6_client+12],edx


;**********************************************************
;test si il y as des données a reçevoir
test_donnee_rec:
mov al,3
int 65h
cmp eax,cer_ddi
jne boucle_principale


;recherche le descripteur de la connexion
mov esi,zts_reception
mov ecx,[nb_reception]
boucle_rech_descr:
cmp [esi+adresse_com],ebx
je upgrade_descr
add esi,to_reception
dec ecx
jnz boucle_rech_descr


mov eax,1 ;supprime la connexion
int 65h
jmp boucle_principale

;upgrader descripteur
upgrade_descr:
mov edi,zt_donnee
mov ecx,to_reception-zt_donnee
add edi,esi
sub ecx,[esi+offset_zt]
add edi,[esi+offset_zt]
mov eax,6 
int 65h
;???? gestion erreur
add [esi+offset_zt],ecx


;verif si présence double fin de ligne
mov edi,zt_donnee
mov ecx,[esi+offset_zt]
add edi,esi
boucle_doublefin:
cmp dword[edi],0A0D0A0Dh
je envoie_req
inc edi
dec ecx
jnz boucle_doublefin
jmp boucle_principale


;********************************************************************************
;si oui envoie requete a la ZT de traitement
envoie_req:
pushad
mov ecx,edi
add esi,zt_donnee
mov edi,zt_decode
sub ecx,esi
cld
rep movsb
mov byte[esi],0
popad
mov dword[esi+offset_zt],0


;verif si 1er instruction GET
cmp dword[zt_decode],"GET "
jne envoie_501


;extrait nom fichier
mov ebx,zt_decode
mov edi,nom_fichier-1
boucle_exnom1:
cmp byte[ebx],20h
jne suite_exnom1
cmp byte[ebx+1],20h
jne debut_nom_trouve
suite_exnom1:
inc ebx
cmp ebx,zt_decode+to_reception
jne boucle_exnom1
jmp envoie_404

debut_nom_trouve:
inc ebx
inc edi
mov al,[ebx]
mov [edi],al
cmp al,20h
jne debut_nom_trouve
mov byte[edi],0



;transforme les %xx en caractère dans le nom
pushad
mov ebx,nom_fichier
boucle_ajustement_chaine_nom:
cmp byte[ebx],"%"
jne suite_ajustement_chaine_nom
mov ax,[ebx+1]

cmp al,"0"
jb suite_ajustement_chaine_nom
cmp al,"9"
jbe chiffre1_ajustement_chaine_nom
cmp al,"A"
jb suite_ajustement_chaine_nom
cmp al,"F"
ja suite_ajustement_chaine_nom
sub al,"A"-10
jmp finnb1_ajustement_chaine_nom
chiffre1_ajustement_chaine_nom:
sub al,"0"
finnb1_ajustement_chaine_nom:

cmp ah,"0"
jb suite_ajustement_chaine_nom
cmp ah,"9"
jbe chiffre2_ajustement_chaine_nom
cmp ah,"A"
jb suite_ajustement_chaine_nom
cmp ah,"F"
ja suite_ajustement_chaine_nom
sub ah,"A"-10
jmp finnb2_ajustement_chaine_nom
chiffre2_ajustement_chaine_nom:
sub ah,"0"
finnb2_ajustement_chaine_nom:

shl al,4
add al,ah
cmp al,20h
jb suite_ajustement_chaine_nom
mov byte[ebx],al
mov esi,ebx
mov edi,ebx
add esi,3
inc edi
mov ecx,nom_fichier+510
sub ecx,ebx
cld
rep movsb

suite_ajustement_chaine_nom:
cmp byte[ebx],"?"
jne @f
mov byte[ebx],0
@@:
inc ebx
cmp ebx,nom_fichier+510
jne boucle_ajustement_chaine_nom
popad


mov edx,nom_fichier
mov al,6
int 61h


;si le nom est "/" c'est le dossier racine
mov ebx,[dossier_site]
mov [handle_fichier],ebx
cmp word[nom_fichier],02Fh
je envoie_dossier


;ouvrir fichier
mov al,0
mov ebx,[dossier_site]
mov edx,nom_fichier
int 64h
mov [handle_fichier],ebx
cmp eax,cer_dov
je envoie_dossier
cmp eax,0
jne envoie_404


;envoie en-tête 200
suite_envoie_fichier:
mov ebx,[esi+adresse_com]
mov esi,tete_200
mov ecx,fin_200-tete_200
mov al,7
int 65h
cmp eax,0
;jne ?????????????????????????????????????????????????????????????????????????

call envoie_fichier
cmp eax,0
;jne ???????????????????????????????????????????????????????????????????????

;ferme fichier 
mov eax,1
mov ebx,[handle_fichier]
int 64h
jmp boucle_principale



;*********************************************************
envoie_dossier:
mov al,0
mov ebx,[handle_fichier]
mov edx,nom_index
int 64h
cmp eax,0
jne envoie_listing
mov [handle_fichier],ebx
jmp suite_envoie_fichier


envoie_listing: 
mov ebx,[esi+adresse_com]

push ebx
mov eax,16
mov ebx,[handle_fichier]
mov ecx,to_reception*256
xor edx,edx
mov edi,zt_decode
int 64h
pop ebx
cmp eax,0
;jne ?????????????????????????????????????????????????????????????????????????

;mov eax,1
;mov ebx,[handle_fichier]
;int 64h


;créer le fichier temporaire
push ebx
mov al,2
xor ebx,ebx
mov edx,fichier_temporaire
int 64h
mov [handle_temporaire],ebx
pop ebx
cmp eax,0
jne envoie_500





;remplit le fichier temporaire

mov esi,zt_decode
mov ebp,esi
xor edx,edx


push ebx
push esi
mov eax,5
mov ebx,[handle_temporaire]
mov ecx,fin_dossier - debut_dossier
mov esi,debut_dossier
int 64h
pop esi
pop ebx
;????????????????????????????????
add edx,ecx


boucle_cree_listing:
cmp byte[esi],0
je fin_cree_listing
cmp byte[esi],"|"
jne suite_cree_listing 

mov byte[esi],0

call ajoute_fichier

mov ebp,esi
inc ebp

suite_cree_listing:
inc esi
jmp boucle_cree_listing 

fin_cree_listing:
call ajoute_fichier


push ebx
push esi
mov eax,5
mov ebx,[handle_temporaire]
mov ecx,end_dossier - fin_dossier
mov esi,fin_dossier
int 64h
pop esi
pop ebx
;????????????????????????????????
add edx,ecx

mov eax,[handle_temporaire]
mov [handle_fichier],eax


;mov ebx,[esi+adresse_com]
mov esi,tete_200
mov ecx,fin_200-tete_200
mov al,7
int 65h
cmp eax,0
;jne ?????????????????????????????????????????????????????????????????????????

call envoie_fichier
cmp eax,0
;jne ???????????????????????????????????????????????????????????????????????

;supprime fichier 
mov eax,3
mov ebx,[handle_fichier]
int 64h
jmp boucle_principale









;***************
ajoute_fichier:
push edx
mov edi,tempo

mov edx,ligne1_dossier
call ajoute_dossier

cmp word[nom_fichier],02Fh
je ignore_sousdossier

mov edx,nom_fichier
call ajoute_dossier

mov byte[edi],"/"
inc edi

ignore_sousdossier:

mov edx,ebp
call ajoute_dossier

mov edx,ligne2_dossier
call ajoute_dossier

mov edx,ebp
call ajoute_dossier

mov edx,ligne3_dossier
call ajoute_dossier

pop edx

push ebx
push esi
mov eax,5
mov ebx,[handle_temporaire]
mov ecx,edi
sub ecx,tempo
mov esi,tempo
int 64h
pop esi
pop ebx
;????????????????????????????????
add edx,ecx



ret


ajoute_dossier:
mov al,[edx]
cmp al,0
jne ttt
ret
ttt:
mov [edi],al
inc edx
inc edi
jmp ajoute_dossier





;*****************************************************
ferme_connexion:

;§§§§§§§§§§§§§§§§§§§§ laisse le temps aux données d'être envoyé avant la fermeture de la connexion
mov ecx,100
mov al,1
int 61h
;§§§§§§§§§§§§§§§§§§§§  correction temporaire le temps de corriger le bug du pilote ip 

pushad
;recherche le descripteur de la connexion
mov esi,zts_reception
mov ecx,[nb_reception]
boucle_ferme_cnx:
cmp [esi+adresse_com],ebx
jne suite_ferme_cnx

mov word[esi+port_client],0
mov eax,1 ;supprime la connexion
int 65h

suite_ferme_cnx:
add esi,to_reception
dec ecx
jnz boucle_ferme_cnx

popad
ret




;***********************************************************
envoie_fichier:
pushad

;envoie la fin de l'entête standard
mov esi,tete_standard1
call envoie_tramez
cmp eax,0
jne erreur_envoie_fichier

;lit taille fichier
push ebx
mov ebx,[handle_fichier]
mov edx,taille_fichier
mov al,6
mov ah,1 ;fichier
int 64h
pop ebx
cmp eax,0
jne erreur_envoie_fichier


;envoie la taille du fichier
mov ecx,[taille_fichier]
mov edx,tempo
mov eax,102
int 61h
mov esi,tempo
mov ecx,tempo
boucle1_envoie_fichier:
inc ecx
cmp byte[ecx],0
jne boucle1_envoie_fichier
sub ecx,esi
mov al,7
int 65h

;envoie le double CRLF
mov esi,tete_standard2
mov ecx,4
mov al,7
int 65h


xor edx,edx

boucle2_envoie_fichier:
cmp dword[taille_fichier],to_reception*256
jbe fin_envoie_fichier

push ebx
mov eax,4
mov ebx,[handle_fichier]
mov ecx,to_reception*256
mov edi,zt_decode
int 64h
pop ebx
cmp eax,0
jne erreur_envoie_fichier

mov esi,zt_decode
mov ecx,to_reception*256
mov al,7
int 65h
cmp eax,cer_ztp
je boucle2_envoie_fichier
cmp eax,0
jne erreur_envoie_fichier


add edx,to_reception*256
sub dword[taille_fichier],to_reception*256
jmp boucle2_envoie_fichier


fin_envoie_fichier:
push ebx
mov eax,4
mov ebx,[handle_fichier]
mov ecx,[taille_fichier]
mov edi,zt_decode
int 64h
pop ebx
cmp eax,0
jne erreur_envoie_fichier


mov esi,zt_decode
mov ecx,[taille_fichier]
mov al,7
int 65h
cmp eax,cer_ztp
je fin_envoie_fichier
cmp eax,0
jne erreur_envoie_fichier

;supprime la connexion
call ferme_connexion
popad
xor eax,eax
ret


erreur_envoie_fichier:
ss
mov [esp+28],eax
popad
ret


;***********************************
envoie_404:             ;(fichier non trouvé)
mov ebx,[esi+adresse_com]
mov esi,tete_404
mov ecx,msg_404-tete_404
mov al,7
int 65h

mov edi,msg_404
mov ebp,fin_404-msg_404
jmp envoie_bloc


envoie_500:
mov ebx,[esi+adresse_com]
mov esi,tete_500
mov ecx,msg_500-tete_500
mov al,7
int 65h

mov edi,msg_500
mov ebp,fin_500-msg_500
jmp envoie_bloc


envoie_501:
mov ebx,[esi+adresse_com]
mov esi,tete_501
mov ecx,msg_501-tete_501
mov al,7
int 65h

mov edi,msg_505
mov ebp,fin_505-msg_505
jmp envoie_bloc


envoie_505:            ;(HTTP Version not supported) 
mov ebx,[esi+adresse_com]
mov esi,tete_505
mov ecx,msg_505-tete_505
mov al,7
int 65h

mov edi,msg_505
mov ebp,fin_505-msg_505
;jmp envoie_bloc



;*******************************************
envoie_bloc:

;envoie la fin de l'entête standard
mov esi,tete_standard1
call envoie_tramez

;envoie la taille du message
mov ecx,ebp
mov edx,tempo
mov eax,102
int 61h
mov esi,tempo
mov ecx,tempo
boucle_envoiestandard:
inc ecx
cmp byte[ecx],0
jne boucle_envoiestandard
sub ecx,esi
mov al,7
int 65h

;envoie le double CRLF
mov esi,tete_standard2
mov ecx,4
mov al,7
int 65h

;envoie le message
mov esi,edi
mov ecx,ebp
mov al,7
int 65h

;supprime la connexion
call ferme_connexion
jmp boucle_principale




;*******************************************
;envoie en-tete

;envoie la fin de l'entête standard
mov esi,tete_standard1
call envoie_tramez
cmp eax,0
jne erreur_envoie_fichier




;envoie la taille du fichier
mov ecx,[taille_fichier]
mov edx,tempo
mov eax,102
int 61h
mov esi,tempo
mov ecx,tempo
;boucle1_envoie_fichier:
inc ecx
cmp byte[ecx],0
;jne boucle1_envoie_fichier
sub ecx,esi
mov al,7
int 65h

;envoie le double CRLF
mov esi,tete_standard2
mov ecx,4
mov al,7
int 65h
ret







;********************************************
envoie_tramez:    ;envoie la trame en esi terminé par zéros sur le descripteur de communication ebx
push esi
dec esi
@@:
inc esi
cmp byte[esi],0
jne @b
mov ecx,esi
pop esi
sub ecx,esi
mov al,7
int 65h
ret




;*********************************************
aff_err_param:
mov edx,msg_er0
mov al,6        
int 61h
int 60h


erreur_ouverture_dossier:
mov edx,msg_er1
mov al,6        
int 61h
int 60h


erreur_init_cpnr:
mov edx,msg_er2
mov al,6        
int 61h
int 60h

sdata1:
org 0


msg_ok:
db "SHTTP: serveur HTTP démarré",13,0


msg_er0:
db "SHTTP: erreur dans la sytaxe de la ligne de commande",13
db "format correcte: SHTTP [repertoire] [-c:X]",13
db "[repertoire]  contient les fichier du site a afficher",13 
db "[-c:X] numéros de l'interface réseau (champ optionnel, 0 par défaut)",13,0




msg_er1:
db "SHTTP: erreur lors de l'ouverture du dossier des fichier du site",13,0

msg_er2:
db "SHTTP: erreur lors de l'ouverture du port 80",13,0




tete_standard1:
db "Server: SHTTP.FE V0.3",13,10
db "Content-Length: ",0
tete_standard2:
db 13,10,13,10



extension:
dd "HTML",0

tete_type:
db "content type: ",0

tete_types:
db 0
db "JS   application/javascript",0
db "PDF  application/pdf",0
db "EXE  application/octet-stream",0
db "ZIP  application/zip",0
db "GIF  image/gif",0   
db "JPEG image/jpeg",0   
db "JPG  image/jpeg",0   
db "PNG  image/png",0   
db "TIFF image/tiff",0    
db "TIF  image/tiff",0    
db "SVG  image/svg+xml",0   
db "CSS  text/css",0    
db "CSV  text/csv",0    
db "HTML text/html",0    
db "HTM  text/html",0    
db "TXT  text/plain",0,"$" 






tete_200:
db "HTTP/1.0 200 OK",13,10
fin_200:

tete_404:
db "HTTP/1.0 404 Not Found",13,10
msg_404:
db "<!DOCTYPE html><html><head><title>Erreur 404</title><meta charset=",22h,"UTF-8",22h,"/></head><body><h1>erreur 404: Ressource non trouvée.</h1></body></html>"
fin_404:

tete_500:
db "HTTP/1.0 500 HTTP Internal Server Error",13,10
msg_500:
db "<!DOCTYPE html><html><head><title>Erreur 500</title><meta charset=",22h,"UTF-8",22h,"/></head><body><h1>erreur 500: Erreur Interne serveur.</h1></body></html>"
fin_500:

tete_501:
db "HTTP/1.0 501 Not Implemented",13,10
msg_501:
db "<!DOCTYPE html><html><head><title>Erreur 501</title><meta charset=",22h,"UTF-8",22h,"/></head><body><h1>erreur 501: Fonctionnalité réclamée non supportée par le serveur.</h1></body></html>"
fin_501:

tete_505:
db "HTTP/1.0 505 HTTP Version not supported",13,10
msg_505:
db "<!DOCTYPE html><html><head><title>Erreur 505</title><meta charset=",22h,"UTF-8",22h,"/></head><body><h1>erreur 505: Version HTTP non gérée par le serveur.</h1></body></html>"
fin_505:


debut_dossier:
db "<!DOCTYPE html><html><head><title>liste fichier du dossier</title><meta charset=",22h,"UTF-8",22h,"/></head><body>"
fin_dossier:
db "</body></html>"
end_dossier:

ligne1_dossier:
db "<a href=",22h,0
ligne2_dossier:
db 22h,">",0
ligne3_dossier:
db "</a><br/>",0


nom_index:
db "INDEX.HTML",0
fichier_temporaire:
db "#dm/shttp.temp",0
handle_temporaire:
dd 0


id_tache:
dw 0
dossier_site:
dd 0
adresse_canal:
dd 0
nb_reception:
dd 50


tempo:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


taille_fichier:
dd 0,0
handle_fichier:
dd 0
nom_fichier:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

zt_decode:
dd 0



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
