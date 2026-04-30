nsn.asm:
pile equ 4960 ;definition de la taille de la pile
include "fe.inc"
db "Navigateur SmolNet"
scode:
org 0


;a faire
;[ok]ajouter un fichier de config
;ajouter une page menu/aide (F1)
;ajouter une page d'enregistrement (F2) (CTRL+S)
;ajouter une recherche dans le document (F3) (CTRL+F)
;[ok]ajouter une page de config (F4)
;[ok]ajouter une touche actualisation (F5)
;[ok]ajouter des touches de raccourcis (F7 à F12)
;ajouter timeout réponse serveur
;affichage destination liens si on survole le lien


;*****************************************
;active le mode video
mov dx,sel_dat2
mov ah,5   ;option=mode texte+souris
mov al,0   ;création console     
int 63h

mov dx,sel_dat1
mov ds,dx
mov es,dx
mov dx,sel_dat2
mov fs,dx



;agrandit la zone mémoire
mov al,8
mov ecx,zt_recep+20000h
mov dx,sel_dat1
int 61h


;génère un numéros de port local pseudo aléatoirement
mov eax,9
int 61h
xor ax,bx
xor ax,cx
xor ax,dx
xor ax,01F57h
mov [port_local],ax


;**********************************************************
;récupère le fichier de parametre de base
mov al,0
mov ebx,1
mov edx,fichier_parametres
int 64h
cmp eax,0
jne @f

mov al,4
mov ecx,fin_parametres-parametres
xor edx,edx
mov edi,parametres
int 64h

mov al,1
int 64h
@@:


;**************************************************************
;determine l'id du service ethernet
mov byte[zt_recep],0

mov al,5   
mov ah,"c"   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_recep
int 61h
xor ebx,ebx
cmp eax,0
jne @f

mov al,100  
mov edx,zt_recep
int 61h
mov ebx,ecx    ;ebx=numéros de l'interface

@@:
mov al,11
mov ah,6     ;code service 
mov cl,16
mov edx,zt_recep
int 61h

shl ebx,1
mov ax,[zt_recep+ebx]
mov [id_tache],ax



;**********************************************************
;lit l'adresse de la ressource souhaité
mov byte[zt_recep],0

mov al,4   
mov ah,0   ;numéros de l'option de commande a lire
mov cl,0 ;0=256 octet max
mov edx,zt_url
int 61h

cmp byte[zt_url],0
jne ouvrir_url

;selectionne le raccourcis F7 si aucune adresse n'est renseigné



;*********************************************************************************************************
;ouvrir nouvel url
ouvrir_url:


;***********************************
;enregistre le chemin dans l'historique
mov esi,zt_url
mov edi,[fin_historique]

boucle_enreg_historique:
cmp edi,historique+8192
je @f
mov al,[esi]
mov [edi],al
cmp al,0
je fin_enreg_historique
inc esi
inc edi
jmp boucle_enreg_historique


;ça va déborder, on fait un peu de place dans l'historique
@@:
push esi
push edi

mov esi,historique
@@:
cmp byte[esi],0
je @f
inc esi
jmp @b

@@:
inc esi
mov ecx,historique+8192
mov edi,historique
sub ecx,esi
push ecx
cld
rep movsb
pop ecx
pop edi
sub edi,ecx
pop esi
jmp boucle_enreg_historique


fin_enreg_historique:
inc edi
mov [fin_historique],edi




;*******************************************************
;extrait les données de l'url
mov byte[zt_protocole],0
mov byte[zt_user],0
mov byte[zt_host],0
mov byte[zt_port],0
mov byte[zt_ressource],0
mov byte[zt_param],0
mov byte[zt_ancre],0

mov esi,zt_url

;extrait le protocole
@@:
mov eax,[esi]
and eax,0FFFFFFh
cmp al,0
je pasprotocol
cmp eax,"://"
je okprotocol
inc esi
jmp @b

pasprotocol:
mov esi,zt_url
jmp extrait_user

okprotocol:
mov ecx,esi
add esi,3
push esi
sub ecx,zt_url
mov esi,zt_url
mov edi,zt_protocole
cld
rep movsb
pop esi
mov byte[edi],0

;*************************************************************
extrait_user:
mov ebp,esi
@@:
mov eax,[esi]
and eax,0FFFFFFh
cmp byte[esi],0
je pasuser
cmp byte[esi],"@"
je okuser
inc esi
jmp @b

pasuser:
mov esi,ebp
jmp extrait_adresse

okuser:
mov ecx,esi
inc esi
push esi
sub ecx,ebp
mov esi,ebp
mov edi,zt_user
cld
rep movsb
pop esi
mov byte[edi],0

;**************************************************************
extrait_adresse:  ; note: penser a distinguer les éventuelles adresse ipv6
mov edi,zt_host

@@:
mov al,[esi]
cmp al,":"
je extrait_port
cmp al,"/"
je extrait_ressource
cmp al,0
je extrait_fin
mov [edi],al
inc esi
inc edi
jmp @b


;extrait le port (éventuellement)
extrait_port:
mov byte[edi],0
inc esi
mov edi,zt_port
@@:
mov al,[esi]
cmp al,"/"
je extrait_ressource
cmp al,0
je extrait_fin
mov [edi],al
inc esi
inc edi
jmp @b


;extrait le nom de la ressource (éventuellement)
extrait_ressource:
mov byte[edi],0
inc esi
mov edi,zt_ressource

@@:
mov al,[esi]
cmp al,"?"
je extrait_param
cmp al,9
je extrait_param
cmp al,"#"
je extrait_ancre
cmp al,0
je extrait_fin
mov [edi],al
inc esi
inc edi
jmp @b



extrait_param:
mov byte[edi],0
inc esi
mov edi,zt_param

@@:
mov al,[esi]
cmp al,"#"
je extrait_ancre
cmp al,0
je extrait_fin
mov [edi],al
inc esi
inc edi
jmp @b


extrait_ancre:
mov byte[edi],0
inc esi
mov edi,zt_ancre

@@:
mov al,[esi]
cmp al,0
je extrait_fin
mov [edi],al
inc esi
inc edi
jmp @b

extrait_fin:
mov byte[edi],0




;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
mov al,6
mov edx,zt_protocole
int 61h
mov al,6
mov edx,crlf
int 61h

mov al,6
mov edx,zt_user
int 61h
mov al,6
mov edx,crlf
int 61h

mov al,6
mov edx,zt_host
int 61h
mov al,6
mov edx,crlf
int 61h

mov al,6
mov edx,zt_port
int 61h
mov al,6
mov edx,crlf
int 61h

mov al,6
mov edx,zt_ressource
int 61h
mov al,6
mov edx,crlf
int 61h

mov al,6
mov edx,zt_param
int 61h
mov al,6
mov edx,crlf
int 61h

mov al,6
mov edx,zt_ancre
int 61h
mov al,6
mov edx,crlf
int 61h


;int 60h

;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

mov al,5   
mov ah,"a"   ;lettre de l'option de commande a lire
mov cl,32 
mov edx,zt_url
int 61h

cmp eax,0
je @f 
mov edx,zt_host
@@:

mov al,109
mov ecx,ip_serveur
int 61h






;************************************
;identifie le protocole

mov esi,zt_protocole
;ignore les / \
ajuste_deb_url:
cmp byte[esi],"/"
jne @f
inc esi
jmp ajuste_deb_url
@@:
cmp byte[esi]," "
jne @f
inc esi
jmp ajuste_deb_url
@@:
cmp byte[esi],"\"
jne @f
inc esi
jmp ajuste_deb_url
@@:


cmp dword[esi],"file"
jne @f
cmp byte[esi+4],0
je ouvrir_fichier
@@:


cmp dword[esi],"goph"
jne @f
cmp word[esi+4],"er"
jne @f
cmp byte[esi+6],0
je ouvrir_gopher
@@:

cmp dword[esi],"http"
jne @f
cmp byte[esi+4],0
je ouvrir_http
;cmp word[esi+4],"s"
;je ouvrir_https
;@@:

;cmp dword[esi],"ftp"
;je ouvrir_ftp

;cmp dword[esi],"ftps"
;jne @f
;cmp byte[esi+4],0
;je ouvrir_ftps
;@@:

;cmp dword[esi],"tftp"
;jne @f
;cmp byte[esi+4],0
;je ouvrir_tftp
;@@:

mov edx,msg6
call ajuste_langue
mov [page_encours],edx
jmp affiche_erreur


;*********************************************************************************************************************
ouvrir_gopher:


;convertir le numéros de port en valeur (si pas de valeur on prend le port standard)
mov cx,70
mov al,100
mov edx,zt_port
cmp byte[edx],0
je @f
int 61h
@@:
mov [port_serveur],cx


;etablie une connexion
inc word[port_local]
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,20000h
mov edi,20000h
int 65h
cmp eax,0
jne aff_err_net
mov [adresse_canal],ebx


mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,commande_ethernet
mov edi,0
mov byte[esi],8h
int 65h
cmp eax,0
jne aff_err_serv


;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne aff_err_serv

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,1
mov esi,0
mov edi,commande_ethernet
int 65h
cmp eax,0
jne aff_err_serv

cmp byte[commande_ethernet],88h
jne aff_err_serv



;************************************
;envoie requete
mov esi,zt_ressource
mov edi,ligne_vide
cmp byte[zt_ressource],0
je @f
inc esi
@@:
mov al,[esi]
cmp al,0
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:

cmp byte[zt_ressource],"7"
jne @f
cmp byte[zt_param],0
jne @f

pushad
call raz_ecr
call affiche_adresse
mov al,11
mov ah,[coul_base]
mov edx,msg_paramg
call ajuste_langue
int 63h
mov al,6
mov ah,[coul_base]
mov edx,zt_param
mov ecx,256
int 63h
popad


@@:

mov esi,zt_param
cmp byte[zt_param],0
je envoie_rqgoph
mov byte[edi],9
inc edi
@@:
mov al,[esi]
cmp al,0
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:

envoie_rqgoph:
mov dword[edi],0A0Dh
mov edx,ligne_vide
call envoie_utf8z







;******************************
;lit les données reçu jusqu'a la fermeture de la connexion
call raz_ecr
call affiche_adresse
mov al,11
mov ah,[coul_base]
mov edx,msg1
call ajuste_langue
int 63h


mov dword[taille],0
mov al,8
mov ecx,zt_recep+4000h
mov [memoire],ecx
mov dx,sel_dat1
int 61h


boucle_reception_gopher:

;on verifie qu'il y as la place de copier les données
mov edi,zt_recep
add edi,[taille]
mov ecx,[memoire]
sub ecx,2048
cmp edi,ecx
jae @f

;on agrandit au besoin
mov al,8
mov ecx,edi
add ecx,40000h
mov [memoire],ecx
mov dx,sel_dat1
int 61h
@@:

mov al,6
mov ecx,2048
mov ebx,[adresse_canal]
int 65h
cmp eax,0
jne fin_reception_gopher




cmp ecx,0
je @f
;????????????????????
pushad
mov al,6
mov edx,zt_recep
add edx,[taille]
push edx
add edx,ecx
mov byte[edx],0
pop edx
int 61h
popad
;?????????????????


add [taille],ecx
mov al,11
mov ah,[coul_base]
mov edx,msg2
int 63h
jmp boucle_reception_gopher

@@:
int 62h
mov edi,zt_recep-3
add edi,[taille]
mov eax,[edi]
and eax,0FFFFFFh
cmp eax,0A0D2Eh
jne boucle_reception_gopher
sub dword[taille],3


fin_reception_gopher:
cmp byte[zt_ressource],0
je fichier_gopher
cmp byte[zt_ressource],"0"
je fichier_formate
cmp byte[zt_ressource],"1"
je fichier_gopher
cmp byte[zt_ressource],"7"
je fichier_gopher


mov al,6
mov edx,zt_recep
int 61h
int 60h





;*************************************************
;convertie le menu gopher
fichier_gopher:
cmp dword[taille],0
je fichier_formate


;agrandit la zone
mov al,8
mov ecx,[taille]
shl ecx,2
add ecx,zt_recep
mov dx,sel_dat1
int 61h

;convertit les lignes
mov edi,zt_recep
mov esi,zt_recep
add edi,[taille]
mov ebp,edi
;mov dword[edi],":ind"
;mov word[edi+4],"ex"
;mov word[edi+6],0A0Dh
;add edi,8


boucle_conversion_menugopher:
cmp byte[esi],"i"
je texte_conversion_menugopher
cmp byte[esi],"h"
je url_conversion_menugopher
jmp lien_conversion_menugopher

;****************
texte_conversion_menugopher:
inc esi
@@:
mov al,[esi]
call ajoute_carac_menugopher
cmp al,0
je ligne_conversion_menugopher
jmp @b


;*****************
url_conversion_menugopher:
mov byte[edi],"~"
inc edi

;ajoute nom lien
push esi
inc esi
menugopher_nomurl:
mov al,[esi]
cmp al,"/"
jne @f
mov al,"\"
@@:
call ajoute_carac_menugopher
cmp al,0
je @f
jmp menugopher_nomurl
@@:
pop esi

mov byte[edi],"/"
inc edi

@@:
cmp byte[esi],9
je @f
cmp esi,ebp
jae fin_conversion_menugopher
inc esi
jmp @b
@@:
add esi,5

@@:
mov al,[esi]
call ajoute_carac_menugopher
cmp al,0
je @f
jmp @b
@@:

mov byte[edi],"~"
inc edi
jmp ligne_conversion_menugopher



;*****************
lien_conversion_menugopher:
mov byte[edi],"~"
inc edi

mov cl,[esi]

;ajoute nom lien
push esi
inc esi
menugopher_nomlien:
mov al,[esi]
cmp al,"/"
jne @f
mov al,"\"
@@:
call ajoute_carac_menugopher
cmp al,0
je @f
jmp menugopher_nomlien
@@:
pop esi

mov byte[edi],"/"
inc edi

;ajoute url lien
mov dword[edi],"goph"
mov dword[edi+4],"er:/"
mov dword[edi+8],"/"
add edi,9

@@:
cmp byte[esi],9
je @f
cmp esi,ebp
jae fin_conversion_menugopher
inc esi
jmp @b
@@:
inc esi
mov eax,esi
@@:
cmp byte[esi],9
je @f
cmp esi,ebp
jae fin_conversion_menugopher
inc esi
jmp @b
@@:
inc esi
mov ebx,esi
@@:
cmp byte[esi],9
je @f
cmp esi,ebp
jae fin_conversion_menugopher
inc esi
jmp @b
@@:
inc esi
push eax
push esi
mov esi,ebx



;host
@@:
mov al,[esi]
call ajoute_carac_menugopher
cmp al,0
je @f
jmp @b
@@:

;port
mov byte[edi],":"
inc edi
pop esi
@@:
mov al,[esi]
call ajoute_carac_menugopher
cmp al,0
je @f
jmp @b
@@:

;ressource
mov byte[edi],"/"
inc edi
mov [edi],cl
inc edi
pop esi
@@:
mov al,[esi]
call ajoute_carac_menugopher
cmp al,0
je @f
jmp @b
@@:

mov byte[edi],"~"
inc edi


ligne_conversion_menugopher:
mov byte[edi],13
inc edi

@@:
cmp word[esi],0A0Dh
je @f
cmp esi,ebp
jae fin_conversion_menugopher
inc esi
jmp @b

@@:
add esi,2
cmp esi,ebp
jb boucle_conversion_menugopher

fin_conversion_menugopher:

;remplace le menu
mov ecx,edi
mov esi,zt_recep
mov edi,zt_recep
add esi,[taille]
sub ecx,esi
mov [taille],ecx
cld
rep movsb
jmp fichier_formate



;********************
@@:
mov al,0
ret

ajoute_carac_menugopher:
cmp esi,ebp
ja @b
cmp al,0
je @b
cmp al,9
je @b
cmp al,10
je @b
cmp al,13
je @b

mov [edi],al
inc esi
inc edi
cmp al,"~"
jne @f
mov [edi],al
inc edi
@@:
ret





;****************************************************************************************
ouvrir_fichier:  ;ouvre le fichier





;***********************************
;extrait le nom de fichier de l'url
mov esi,zt_host
mov edi,fichier
@@:
mov al,[esi]
cmp al,"0"
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:
mov byte[edi],"/"
mov esi,zt_ressource
inc edi
@@:
mov al,[esi]
cmp al,"0"
je @f
mov [edi],al
inc esi
inc edi
jmp @b
@@:




;**********************
;test si le fichier en mémoire est le fichier a lire
;mov esi,fichier
;mov edi,fichier_mem
;@@:
;mov al,[esi]
;cmp al,[edi]
;jne @f
;cmp al,0
;je recherche_rubrique
;inc esi
;inc edi
;jmp @b

;@@:






mov edx,fichier
xor eax,eax
xor ebx,ebx
int 64h
cmp eax,0
je @f
xor eax,eax
mov ebx,1
int 64h
cmp eax,0
jne aff_err_fichier
@@:
mov [handle],ebx


;lit taille fichier
mov ebx,[handle]
mov edx,taille
mov al,6
mov ah,1 ;fichier
int 64h
cmp eax,0
jne aff_err_fichier


;agrandit la zone mémoire pour pouvoir contenir 2 fois le fichier pour rajouter le listing des mots clefs
mov dx,sel_dat1
mov ecx,[taille]
shl ecx,2
add ecx,zt_recep
mov al,8
int 61h
cmp eax,0
jne aff_err_mem


;charge fichier
mov ebx,[handle]
mov ecx,[taille]
mov edx,0   ;offset dans le fichier
mov edi,zt_recep   ;offset dans le segment
mov al,4
int 64h
cmp eax,0
jne aff_err_fichier


;ferme le fichier
mov al,1
mov ebx,[handle]
int 64h

;enregistre le fichier comme étant celui en mémoire
mov esi,fichier
mov edi,fichier_mem
mov ecx,64
cld
rep movsd
jmp detecte_type



;****************************************************************************************
ouvrir_http:

;convertir le numéros de port en valeur (si pas de valeur on prend le port standard)
mov cx,80
mov al,100
mov edx,zt_port
cmp byte[edx],0
je @f
int 61h
@@:
mov [port_serveur],cx


;etablie une connexion
inc word[port_local]
mov al,0
mov bx,[id_tache]
mov ecx,64
mov edx,1
mov esi,20000h
mov edi,20000h
int 65h
cmp eax,0
jne aff_err_net
mov [adresse_canal],ebx


mov al,5
mov ebx,[adresse_canal]
mov ecx,34h
mov esi,commande_ethernet
mov edi,0
mov byte[esi],8h
int 65h
cmp eax,0
jne aff_err_serv


;attend que le programme réponde
mov al,8
mov ebx,[adresse_canal]
mov ecx,200  ;500ms
int 65h
cmp eax,cer_ddi
jne aff_err_serv

;lit la réponse du programme
mov al,4
mov ebx,[adresse_canal]
mov ecx,1
mov esi,0
mov edi,commande_ethernet
int 65h
cmp eax,0
jne aff_err_serv

cmp byte[commande_ethernet],88h
jne aff_err_serv


;*************************
;envoie requete
mov edx,http_req1
call envoie_utf8z

mov edx,zt_ressource
cmp byte[edx],0
jne @f
mov word[edx],"/"
@@:
call envoie_utf8z

mov edx,http_req2
call envoie_utf8z

mov edx,zt_host
call envoie_utf8z

mov edx,http_req3
call envoie_utf8z

mov dword[taille],0

;***********************
;attend réponse
mov al,9
mov ecx,1000
mov ebx,[adresse_canal]
int 65h
cmp eax,cer_ddi    ;???????????????????????????probleme
jne aff_err_serv

;**************************
lecture_entete:
mov al,6
mov ecx,20000h
sub ecx,[taille]
mov edi,zt_recep
add edi,[taille]
mov ebx,[adresse_canal]
int 65h
cmp eax,0
jne aff_err_serv

cmp ecx,0
je lecture_entete  ;??????????????????????????????probleme

add [taille],ecx

;recherche si fin d'en_tête 
mov edi,zt_recep-3
mov esi,zt_recep
add edi,[taille]
@@:
cmp dword[esi],0A0D0A0Dh
je fin_entete
inc esi
cmp esi,edi
jne @b
jmp lecture_entete


fin_entete:
add esi,4    ;esi=début du fichier



;****************************
;affiche si réponse négative?????????????????
;cmp dword[zt_recep+8]," 200"
;je ok_chargement
;jmp aff_err_serv   ;?????????????????????????????????
;ok_chargement:


;*****************************
;extrait taille donnée
mov dword[taille_attendue],0
mov edx,zt_recep  
mov edi,taille_http
call cherche_option_http  ;cherche "Content-Length: " dans l'en-tête (insensible a la casse)
cmp edx,zt_recep
je @f
add edx,ebp
mov al,100
int 61h
mov [taille_attendue],ecx 
@@:


;aggrandit la zone pour reçevoir le document
pushad
mov al,8
mov ecx,[taille_attendue]
shl ecx,1
cmp ecx,0
jne @f
mov ecx,80000h
@@:
add ecx,zt_recep
mov dx,sel_dat1
int 61h
popad


;supprime l'en-tête
mov edi,zt_recep
mov ecx,[taille]
add ecx,edi
sub ecx,esi
mov [taille],ecx
cld
rep movsb







;télécharge la suite du document
boucle_telecharge_http:
mov al,6
mov ecx,1FFFFh
mov edi,zt_recep
mov ebx,[adresse_canal]
add edi,[taille]
int 65h
cmp eax,0
jne @f   ;???????????????????????gestion
cmp ecx,0
je boucle_telecharge_http
add [taille],ecx
cmp dword[taille_attendue],0
je boucle_telecharge_http

mov ecx,[taille_attendue]
cmp [taille],ecx
jb boucle_telecharge_http


@@:



;jmp affiche_page




;*************************************************
;detecte le format du fichier en mémoire
detecte_type:






;*************************************************
fichier_formate:
mov al,6
mov edx,zt_recep
int 61h

;transforme cr et lf en zéros
mov ecx,[taille]
mov ebx,zt_recep
add ecx,ebx

boucle_transf:
cmp byte[ebx],10
je transf_zero
cmp byte[ebx],13
je transf_zero
jmp ignore_transf

transf_zero:
mov byte[ebx],0

ignore_transf:
inc ebx
cmp ebx,ecx
jbe boucle_transf

;???????????????????????????????????????????
jmp ignore_ajout_rubrique

;***************************************************
;fait une liste des mots clefs
mov ebx,zt_recep
mov eax,[taille]
mov ecx,[taille]
mov esi,[taille]
shr eax,1
add ecx,zt_recep
add esi,eax
add esi,ebx


mov ebp,esi
dec esi

boucle1_liste:
cmp byte[ebx],":"
jne suite1_liste


boucle2_liste:
mov al,[ebx]
cmp al,0
je suite1_liste
mov[esi],al
inc ebx
inc esi
cmp ebx,ecx
jae fin1_liste
jmp boucle2_liste


suite1_liste:
call atteint_ligne_suivante
cmp ebx,ecx
jb boucle1_liste
fin1_liste:
mov byte[esi],0



;********************************************
;trie les rubriques par ordre alphabetique
mov edx,ebp
mov edi,ebp

sff_lit_dossier_trie_fichier_suivant:
cmp byte[edi],":"
je @f
cmp byte[edi],0
je sff_lit_dossier_trie_fin
inc edi
jmp sff_lit_dossier_trie_fichier_suivant
@@:
inc edi

;test si le fichier doit être placé avant et le déplace si nécessaire
mov esi,edx
sff_lit_dossier_trie_boucle:
call sff_lit_dossier_test
jnc @f
call sff_lit_dossier_decale
jmp sff_lit_dossier_trie_fichier_suivant


@@:
cmp byte[esi],":"
je @f
cmp byte[esi],0
je sff_lit_dossier_trie_fichier_suivant
inc esi
jmp @b
@@:
inc esi
cmp esi,edi
je sff_lit_dossier_trie_fichier_suivant
jmp sff_lit_dossier_trie_boucle

sff_lit_dossier_trie_fin: 


;****************************************************
;compte les mots clefs et la largeur max d'un mot clef
mov dword[nb_motclef],0
mov dword[taille_colonne],0
mov dword[nb_colonnes],0
mov dword[nb_lignes],0


xor eax,eax
mov ebx,ebp

boucle_comptaille:
cmp byte[ebx],":"
jne @f

inc dword[nb_motclef]
mov ecx,eax
xor eax,eax
cmp ecx,[taille_colonne]
jb @f
add ecx,4 ;espace de 4 caractère entre chaque colonnes
mov [taille_colonne],ecx

@@:
mov dl,[ebx]
inc ebx
and dl,0C0h
cmp dl,80h
je @f
inc eax
@@:
cmp byte[ebx],0
jne boucle_comptaille


cmp dword[nb_motclef],0
je ignore_ajout_rubrique 
cmp dword[taille_colonne],0
je ignore_ajout_rubrique 
jmp ignore_ajout_rubrique  

xor eax,eax
fs
mov ax,[resx_texte]
xor edx,edx
mov ecx,[taille_colonne]
div ecx
mov [nb_colonnes],eax

xor edx,edx
mov ecx,eax
mov eax,[nb_motclef]
div ecx
mov [nb_lignes],eax
cmp edx,0
je @f
inc dword[nb_lignes]
@@:



;***********************************************
;créer une rubrique étoile qui est une liste des rubriques du fichier
mov edi,zt_recep
mov esi,ebp
add edi,[taille]
dec edi
cmp byte[edi],0
je @f
inc edi
mov byte[edi],0
@@:
inc edi
mov dword[edi],":*  "
mov byte[edi+2],0
add edi,4

mov ebx,[nb_lignes]

boucle_rubrique:
mov ebp,[nb_colonnes]
push esi

boucle_ligne_rubrique:
mov ecx,[taille_colonne]

mov byte[edi],"~"
inc edi

boucle_mot_rubrique:
mov al,[esi]
cmp al,0
je fin_mot_rubrique
inc esi
cmp al,":"
je fin_mot_rubrique

mov [edi],al 
inc edi
and al,0C0h
cmp al,80h
je boucle_mot_rubrique
dec ecx
jmp boucle_mot_rubrique


fin_mot_rubrique:
mov byte[edi],"~"
inc edi
cmp al,0
je fin_ligne_rubrique

@@:
mov byte[edi]," "
inc edi
dec ecx
jnz @b

mov ecx,[nb_lignes]
dec ecx
@@:
inc esi
cmp byte[esi],0
je fin_ligne_rubrique
cmp byte[esi],":"
jne @b
dec ecx
jnz @b
inc esi

dec ebp
jnz boucle_ligne_rubrique

fin_ligne_rubrique:
mov word[edi],2000h
add edi,2
pop esi

@@:
inc esi
cmp byte[esi],":"
jne @b
inc esi

dec ebx
jnz boucle_rubrique
dec edi
mov [taille],edi

ignore_ajout_rubrique:

;***********************************************
;recherche la rubrique
recherche_rubrique:
mov ebp,zt_recep
mov ebx,zt_recep
add ebp,[taille]

boucle_recherche:
cmp byte[ebx],":"
jne suite_recherche 

mov edi,ebx
inc edi
mov esi,zt_ancre

boucle_test_nom:
mov al,[edi]
mov ah,[esi]

cmp ax,0
je nom_ok
cmp ax,":"
je nom_ok
cmp al,0
je suite_recherche 
cmp al,ah
je @f
add al,20h
cmp al,ah
jne autrenom
@@:
inc edi
inc esi
jmp boucle_test_nom 
 
autrenom:
cmp byte[edi],0
je suite_recherche 
cmp byte[edi],":"
je continue_recherche
inc edi
jmp autrenom

continue_recherche:
inc edi
mov esi,zt_ancre
jmp boucle_test_nom

suite_recherche:
call atteint_ligne_suivante
cmp ebx,ebp
jb boucle_recherche

;si aucunes rubrique n'as été trouvé, on affiche une erreur
mov ebx,zt_recep
jmp @f

nom_ok:
call atteint_ligne_suivante
@@:
mov [page_encours],ebx
mov word[offsety],0


;*************************************************************************************************************************
;*************************************************************************************************************************
affiche_page:
mov ebp,zt_recep
mov ebx,[page_encours]
add ebp,[taille]



call raz_ecr
mov dword[fin_cliquable],cliquable
;affiche l'url
call affiche_adresse



;atteint la première ligne
mov cx,[offsety]
@@:
cmp cx,0
je @f
dec cx
call atteint_ligne_suivante
jmp @b
@@:


;affiche le texte
fs
mov cx,[resy_texte]
dec cx


affiche_ligne:
mov eax,zt_recep
mov esi,ebx

cmp esi,ebp
jae touche_boucle
cmp byte[esi],":"
je touche_boucle

push ecx
mov dl,[coul_base]
mov dh,[coul_base]


cmp byte[ebx],"?"
jne @f
inc esi
@@:


@@:
cmp byte[esi],">"
jne @f
add edi,4
inc esi
jmp @b
@@:


cmp byte[esi],"#"
jne @f
mov dl,[coul_titre]
mov dh,[coul_titre]
inc esi
cmp byte[esi],"#"
jne @f
mov dl,[coul_stitre]
mov dh,[coul_stitre]
inc esi
cmp byte[esi],"#"
jne @f
mov dl,[coul_sstitre]
mov dh,[coul_sstitre]
inc esi
@@:






continue_ligne:
fs
mov cx,[resx_texte]
@@:
call lirecarac
fs
mov [edi],eax
fs
mov [edi+3],dl
add edi,4
dec cx
jnz @b

call lirecarac
cmp byte[esi],0
je @f

pop ecx
dec cx
jz touche_boucle
push ecx
jmp continue_ligne


@@:
call atteint_ligne_suivante
pop ecx
dec cx
jnz affiche_ligne




;*******************************************
touche_boucle:          ;attente touche
fs
test byte[at_console],20h
jnz redim_ecran 
mov al,5
int 63h
cmp al,1
je fin
cmp al,2
je menu
cmp al,5
je parametrage
cmp al,8
jb @f
cmp al,13
jbe goto_raccourcis
@@:
cmp al,30
je backspace
cmp al,82
je moins
cmp al,84
je plus
cmp al,0F0h
je clique

jmp touche_boucle

;*****************************************
fin:
int 60h

;***********************
menu:
call raz_ecr
mov al,11
mov ah,7
mov edx,msg_menu
call ajuste_langue
int 63h
;?????????????????????????
jmp affiche_page

;**************************
parametrage:
call raz_ecr
mov al,11
mov ah,[coul_base]
mov edx,msg_param
call ajuste_langue
int 63h

;affiche les parametres de couleurs
mov ecx,3
mov esi,coul_base
boucle1af_param:
push ecx
mov cl,[esi]
mov edx,ligne_vide
mov al,105
int 61h
pop ecx
mov al,10
mov ah,[coul_base]
mov ebx,18 
int 63h
inc ecx
inc esi
cmp ecx,12
jne boucle1af_param

;affiche les param de raccourcis
mov esi,raccourcis
mov ecx,14

boucle_affiche_raccourcis:
push ecx
push esi

mov eax,12
mov ebx,4
int 63h

fs
mov edi,[ad_curseur_texte]
fs
mov cx,[resx_texte]
mov dl,[coul_base]
sub cx,4

@@:
call lirecarac
cmp eax,0
je @f
fs
mov [edi],eax
fs
mov [edi+3],dl
add edi,4
dec cx
jnz @b
@@:

pop esi
pop ecx
inc ecx
add esi,512
cmp ecx,20 
jne boucle_affiche_raccourcis


mov al,13
mov bl,0
mov bh,[coul_base]
mov cl,2
mov ch,10
int 63h
cmp bh,1
je affiche_page
cmp bl,0
je affiche_page


parametrage_couleur:
and ebx,0FFh
mov esi,ebx
add ebx,2
add esi,coul_base-1
mov cl,[esi]
mov edx,ligne_vide
mov al,105
int 61h

;place le curseur
mov ecx,ebx
mov eax,12
mov ebx,18
int 63h

;permet d'entrer le champs
mov al,6
mov ah,[coul_base]
mov edx,ligne_vide
mov ecx,3
int 63h
cmp al,1
je parametrage


;enregistre la modif
mov eax,101
mov edx,ligne_vide
int 61h
mov [esi],cl
;jmp enregistre_param



;***********************
enregistre_param:
mov al,0
mov ebx,1
mov edx,fichier_parametres
int 64h
cmp eax,0
je @f

;s'il n'existe pas on le créer
mov al,2
mov ebx,1
mov edx,fichier_parametres
int 64h
cmp eax,0
jne affiche_page

@@:
mov al,5
mov ecx,fin_parametres-parametres
xor edx,edx
mov esi,parametres
int 64h

mov al,1
int 64h
jmp affiche_page

;*********************
goto_raccourcis:
sub al,8
mov esi,eax
and esi,07h
shl esi,9
add esi,raccourcis
test ah,1100b ;si c'est CTRL on enregistre l'url actuelle dans le raccourcis
jne enreg_raccourcis
mov ecx,128
mov edi,zt_url
cld
rep movsd
jmp ouvrir_url


enreg_raccourcis:
mov edi,esi
mov ecx,128
mov esi,zt_url
cld
rep movsd
jmp enregistre_param



;****************************************
moins:
cmp word[offsety],0     
je touche_boucle
dec word[offsety]
jmp affiche_page


plus:
cmp byte[esi],":"
je touche_boucle
inc word[offsety]
jmp affiche_page

;*****************************************
clique:
and ebx,0FFFFh
and ecx,0FFFFh
shr ebx,3  ;div par 8, mul par 4
shr ecx,4  ;div par 16,mul par 4
cmp ecx,0
je selection_manuelle
xor eax,eax
fs
mov ax,[resx_texte]
mul ecx
add ebx,eax
shl ebx,2
fs
add ebx,[ad_texte]

mov esi,cliquable
cmp esi,[fin_cliquable]
je touche_boucle

boucle_clique:
cmp ebx,[esi+4]
jb @f
cmp ebx,[esi+8]
jb trouve_clique

@@:
add esi,12
cmp esi,[fin_cliquable]
jne boucle_clique
jmp touche_boucle


trouve_clique:
mov ebx,[esi]
mov edx,zt_url
@@:
mov al,[ebx]
inc ebx
cmp al,"/"
je @f
cmp byte[ebx],"~"
jne @b
mov ebx,[esi]
@@:
mov al,[ebx]
mov [edx],al
inc ebx
inc edx
cmp byte[ebx],"~"
jne @b
mov byte[edx],0
jmp ouvrir_url


;****************************************
selection_manuelle:
mov al,6
mov ah,70h
mov edx,zt_url
xor ecx,ecx
fs
mov cx,[resx_texte]
int 63h
cmp al,1
je touche_boucle
jmp ouvrir_url



;******************************************
backspace:
;remonte au précédent
mov esi,[fin_historique]
cmp esi,historique
je touche_boucle
dec esi

@@:
cmp esi,historique
je touche_boucle
dec esi
cmp byte[esi],0
jne @b

@@:
cmp esi,historique
je @f
dec esi
cmp byte[esi],0
jne @b

inc esi
@@:
mov ecx,[fin_historique]
mov edi,zt_url
mov [fin_historique],esi
sub ecx,esi
cld
rep movsb
jmp ouvrir_url



;*****************************************************************************************
aff_err_mem:
mov edx,msg8
call ajuste_langue
mov al,6
int 61h
int 60h

aff_err_fichier:
mov edx,msg4
call ajuste_langue
mov [page_encours],edx
jmp affiche_erreur

aff_err_net:
mov edx,msg3
call ajuste_langue
mov [page_encours],edx
jmp affiche_erreur

aff_err_serv:
mov edx,msg5
call ajuste_langue
mov [page_encours],edx
;jmp affiche_erreur

;***************************************
affiche_erreur:
mov ebx,[page_encours]

call raz_ecr
fs
mov edi,[ad_texte]


;affiche le nom de la rubrique
fs
mov cx,[resx_texte]
mov esi,zt_url
@@:
call lirecarac
fs
mov [edi],eax
fs
mov byte[edi+3],70h
add edi,4
dec cx
jnz @b

;affiche le message d'erreur
fs
mov cx,[resx_texte]
mov esi,ebx
@@:
call lirecarac
fs
mov [edi],eax
fs
mov byte[edi+3],0C0h
add edi,4
dec cx
jnz @b

jmp touche_boucle







;******************************************
redim_ecran:
mov dx,sel_dat2
mov ah,5   ;option=mode texte+souris
mov al,0   ;création console     
int 63h

mov dx,sel_dat2
mov fs,dx
jmp affiche_page



;**********************************************************************************************
raz_ecr:
pushad
fs
mov ebx,[ad_texte]
fs
mov ecx,[to_texte]
shr ecx,2
mov al,[coul_base]
shl eax,24


boucle_raz_ecr:
fs
mov dword[ebx],eax
add ebx,4
dec ecx
jnz boucle_raz_ecr


xor ebx,ebx
xor ecx,ecx
mov al,12
int 63h     ;place le curseur en 0.0
popad
ret


;************************************
affiche_adresse:
fs
mov edi,[ad_texte]
fs
mov cx,[resx_texte]
mov esi,zt_url
mov dl,[coul_adresse]

@@:
call lirecarac
fs
mov [edi],eax
fs
mov byte[edi+3],dl
add edi,4
dec cx
jnz @b
ret



;************************************
atteint_ligne_suivante:
cmp byte[ebx],0
jne @f
cmp byte[ebx+1],0
jne fin_ligne_trouve
@@:
inc ebx
cmp ebx,ebp
jne atteint_ligne_suivante
ret

fin_ligne_trouve:
inc ebx
ret





;******************
sff_lit_dossier_test:  ;cf=1 si le fichier en edi doit se placer avant celuis en esi
pushad
sff_lit_dossier_test_boucle:
mov al,[edi]
mov ah,[esi]
cmp al,"a"
jb @f
cmp al,"z"
ja @f
sub al,"a"-"A"
@@:
cmp ah,"a"
jb @f
cmp ah,"z"
ja @f
sub ah,"a"-"A"
@@:
cmp al,ah
jb sff_lit_dossier_test_ok
jne sff_lit_dossier_test_nok
inc edi
inc esi
jmp sff_lit_dossier_test_boucle

sff_lit_dossier_test_ok:
popad
stc
ret

sff_lit_dossier_test_nok:
popad
clc
ret




;***************
sff_lit_dossier_decale:
pushad
;calcul taille a deplacer
mov edx,edi
mov ecx,edi
sub edx,2
sub ecx,esi


;sauvegarde nom a decaler
push word 8000h
xor eax,eax
@@:
mov al,[edi]
cmp al,0
je @f
cmp al,":"
je @f
push ax
inc edi
jmp @b
@@:
dec edi

;décale les noms
dec ecx
mov esi,edx
std
rep movsb

;recopie nom sauvegardé
mov byte[edi],":"
dec edi
@@:
pop ax
cmp ax,8000h
je @f
mov [edi],al
dec edi
jmp @b
@@:

popad
ret




;***************************
ajuste_langue:  ;selectionne le message adapté a la langue employé par le système
push eax
push ecx
mov eax,20
int 61h
xor ecx,ecx
cmp eax,"eng "
je @f
inc ecx
cmp eax,"fra "
je @f
xor ecx,ecx
@@:

boucle_ajuste_langue:
cmp ecx,0
je ok_ajuste_langue
cmp byte[edx],0
jne @f
dec ecx
@@:
inc edx
jmp boucle_ajuste_langue

ok_ajuste_langue:
pop ecx
pop eax
ret




;*****************************
envoie_utf8z:
push ebx
mov esi,edx
xor ecx,ecx

@@:
cmp byte[edx],0
je @f
inc ecx
inc edx
jmp @b

@@:
mov al,7
mov ebx,[adresse_canal]
int 65h
pop ebx
ret


;************************************
cherche_option_http:

;cherche la taile de la variable
push edi
@@:
cmp byte[edi],0
je @f
inc edi
jmp @b
@@:
mov ebp,edi
pop edi
sub ebp,edi



boucle1_cherche_option_http:
push edx
push edi
mov ecx,ebp

boucle2_cherche_option_http:
mov al,[edx]
cmp al,"A"
jb @f
cmp al,"Z"
ja @f
add al,20h
@@:
cmp al,[edi]
jne suivant_cherche_option_http
inc edx
inc edi
dec ecx
jnz boucle2_cherche_option_http

pop edi
pop edx

;place edx apres les : et les espaces apres le nom de l'attribut
add edx,ebp
@@:
cmp byte[edx],":"
je @f
inc edx
jmp @b
@@:
inc edx
cmp byte[edx]," "
je @b
ret


suivant_cherche_option_http:
pop edi
pop edx
inc edx
cmp edx,esi
jne boucle1_cherche_option_http
ret







;*************************************************
lirecarac:
push ecx
mov al,[esi]
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
mov eax,0FFFDh ;caractère de remplacement
inc esi
jmp fin_lireutf8

lutf1ch:
and eax,07Fh
inc esi
jmp fin_lireutf8

lutf2ch:
mov eax,[esi]
and eax,0C0E0h
cmp eax,080C0h
jne lutf0ch
xor eax,eax
mov al,[esi]
and al,1Fh
shl eax,6
mov cl,[esi+1]
and cl,3Fh
or al,cl
add esi,2
jmp fin_lireutf8

lutf3ch:
es
mov eax,[esi]
and eax,0C0C0F0h
cmp eax,08080E0h
jne lutf0ch
xor eax,eax
es
mov al,[esi]
and al,0Fh
shl eax,6
es
mov cl,[esi+1]
and cl,3Fh
or al,cl
shl eax,6
es
mov cl,[esi+2]
and cl,3Fh
or al,cl
add esi,3
jmp fin_lireutf8

lutf4ch:
es
mov eax,[esi]
and eax,0C0C0C0F8h
cmp eax,0808080F0h
jne lutf0ch

xor eax,eax
es
mov al,[esi]
and al,07h
shl eax,6
es
mov cl,[esi+1]
and cl,3Fh
or al,cl
shl eax,6
es
mov cl,[esi+2]
and cl,3Fh
or al,cl
shl eax,6
es
mov cl,[esi+3]
and cl,3Fh
or al,cl
add esi,4

fin_lireutf8:
pop ecx

cmp eax,0
jne @f
dec esi
ret

@@:
cmp eax,"~"
je @f
cmp eax,"/"
je stop_lien
ret

@@:
cmp byte[esi],"~"
jne @f
inc esi
ret

@@:
cmp dl,[coul_lien]
je fin_lien
mov dl,[coul_lien]
pushad
mov ebx,[fin_cliquable]
mov [ebx],esi
mov [ebx+4],edi
popad
jmp lirecarac

fin_lien:
mov dl,dh
pushad
mov ebx,[fin_cliquable]
mov [ebx+8],edi
add dword[fin_cliquable],12
popad
jmp lirecarac


stop_lien:
cmp dl,[coul_lien]
je @f
ret

@@:
inc esi
cmp byte[esi],"~"
jne @b
inc esi
jmp fin_lien





;*******************************************************
sdata1:   ;données dans le segment de donnée N°1
org 0


msg1:
db 13,"Loading in progress",13,0
db 13,"Chargement en cours",13,0
msg2:
db ".",0

msg3:
db "error accessing network",0
db "erreur d'acces au réseau",0
msg4:
db "error accessing file",0
db "erreur d'acces au fichier",0
msg5:
db "error during server access",0
db "erreur lors de la connexion au serveur",0
msg6:
db "unknow protocol",0
db "protocole de communication inconnu",0


msg8:
db 13,"NSN: memory reservation error",13,0
db 13,"NSN: erreur de reservation mémoire",13,0


msg_paramg:
db 13,"option de la page:",0
db 13,"option de la page:",0


crlf:
db 13,10,0


http_req1:
db "GET ",0
http_req2:
db " HTTP/1.0",13,10,"Host: ",0
http_req3:
db 13,10,"User-Agent: NSn/SEaC"

db 13,10,13,10,0

taille_http:
db "content-length",0 
type_http:
db "content-type",0 



taille_attendue:
dd 0


nb_motclef:
dd 0
taille_colonne:
dd 0
nb_colonnes:
dd 0
nb_lignes:
dd 0











page_encours:
dd 0


trace:
rb 64




commande_ethernet:
db 8,1
port_local:
dw 0
cmd_max:
dw 0
cmd_fifo:
dw 20000,20000 
port_serveur:
dw 0
ip_serveur:
dd 0
cmd_ip6:
dd 0,0,0,0
index_recep:
dd 0





id_tache:
dw 0

adresse_canal:
dd 0

handle:
dd 0
taille:
dd 0,0
memoire:
dd 0

fin_cliquable:
dd 0
fin_historique:
dd historique



index:
rb 256

offsetx:
dw 0
offsety:
dw 0




msg_menu:






msg_param:
db "parametrage de l'application",13,13
db "quitter",13
db "couleur de base:",13
db "barre d'adresse:",13
db "liens:",13
db "titre:",13
db "sous titre:",13
db "sousous titre:",13
db "paragraphe:",13
db "remarque:",13
db "surligné:",13,13
db "raccourcis:",13
db "F7",13
db "F8",13
db "F9",13
db "F10",13
db "F11",13
db "F12",13,13
db "pour enregistrer la page courante en raccourcis faites CTRL+touche dans la page de navigation",0
db "parametrage de l'application",13,13
db "quitter",13
db "couleur de base:",13
db "barre d'adresse:",13
db "liens:",13
db "titre:",13
db "sous titre:",13
db "sousous titre:",13
db "paragraphe:",13
db "remarque:",13
db "surligné:",13,13
db "raccourcis:",13
db "F7",13
db "F8",13
db "F9",13
db "F10",13
db "F11",13
db "F12",13,13
db "pour enregistrer la page courante en raccourcis faites CTRL+touche dans la page de navigation",0

fichier_parametres:
db "NG.DAT",0

parametres:
coul_base:
db 07h
coul_adresse:
db 70h
coul_lien:
db 03h
coul_titre:
db 0Ah
coul_stitre:
db 0Fh
coul_sstitre:
db 0Bh
coul_parag:
db 70h
coul_rem:
db 0Bh
coul_surl:
db 0A0h

raccourcis:
rb 512*6
fin_parametres:



zt_url:
rb 512
zt_protocole:
rb 32
zt_user:
rb 256
zt_host:
rb 256
zt_port:
rb 32
zt_ressource:
rb 256
zt_param:
rb 256
zt_ancre:
rb 256


ligne_vide:
rb 512
historique:
rb 8192
cliquable:
rb 4096
adresse:
rb 256
fichier:
rb 256
fichier_mem:
rb 256

zt_recep:
rb 512

sdata2:
org 0
sdata3:
org 0
sdata4:
org 0
findata:
