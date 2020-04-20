;mise a jour totale de l'écran video

mov ax,seldat
mov fs,ax
mov ax,selramh
mov gs,ax


;*********************************************************
majv_charge_seg_csl:     ;charge le bon segment de mémoire relatif a la console
fs
cmp word[id_tache_af],0
jne majv_tache
mov dx,selconsole
mov ds,dx 
jmp majv_test_action

majv_tache:
;charge le descripteur du segment affiché dans le descripteur global correspondant

mov ax,selgdt
mov ds,ax

fs
mov ebx,[ad_tache_af]
gs
mov ax,[ebx+sel_ecranv]
and eax,0FFF8h
add ebx,ldt_tache
add ebx,eax
gs
mov eax,[ebx]
gs
mov edx,[ebx+4]

mov [selecran],eax
mov [selecran+4],edx

mov ax,selecran 
mov ds,ax


;***************************************************
majv_test_action:
fs  ;test si on doit mettre a jour l'écran
test byte[at_vid],01h
jnz maj_complete
fs
test byte[at_vid],02h
jnz majv_ctrl_valeur     ;mise a jour partielle

fs
test byte[atts1],01h
jz fin_majv
test byte[at_console],04h
jz fin_majv
fs
mov eax,[xs1]
fs
cmp [axs1],eax
je fin_majv

;********************************************************
xor eax,eax  ;on met a jour uniquement l'affichage souris
xor ebx,ebx
xor ecx,ecx
fs
mov ax,[axs1]
fs
mov bx,[ays1]
fs
mov dword[majv_xdeb],eax
fs
mov dword[majv_ydeb],ebx
add eax,8
add ebx,16
fs
mov dword[majv_xfin],eax
fs
mov dword[majv_yfin],ebx
fs
mov eax,[xs1]
fs
mov [axs1],eax

jmp majv_ctrl_valeur



;*********************************************************
maj_complete:          ;mise a jour complete de l'écran
xor eax,eax
xor ebx,ebx
fs
mov ax,[resx]
fs
mov bx,[resy]
fs
mov dword[majv_xdeb],0
fs
mov dword[majv_xfin],eax
fs
mov dword[majv_ydeb],0
fs
mov dword[majv_yfin],ebx
fs
test byte[atts1],01h
jz majv_ctrl_valeur       ;si on as une souris, l'affichage se feras en 2 fois pour eviter le clignotement de la souris
test byte[at_console],04h
jz majv_ctrl_valeur

xor ebx,ebx
fs
mov bx,[ys1]
add ebx,16
fs
mov dword[majv_yfin],ebx
fs
mov eax,[xs1]
fs
mov [axs1],eax
fs
or byte[at_vid],4h
jmp majv_ctrl_valeur

;*************************************************
majv_complet2:
xor eax,eax
xor ebx,ebx
fs
mov ax,[ays1]
add ax,16
fs
mov bx,[resy]
fs
mov dword[majv_ydeb],eax
fs
mov dword[majv_yfin],ebx
fs
and byte[at_vid],0F8h
;jmp majv_ctrl_valeur







;***********************************************************
majv_ctrl_valeur:          ;controle que les parametres ne débordent pas des valeurs admissibles
fs
and byte[at_vid],0FCh
fs
mov cx,[resy]
fs
cmp [majv_yfin],ecx
jb majv_ok_yfin 
fs
mov [majv_yfin],ecx
majv_ok_yfin:
dec ecx
fs
cmp [majv_ydeb],ecx
jb majv_ok_ydeb
fs
mov [majv_ydeb],ecx
majv_ok_ydeb:


majv_precalc:    ;précalcule certaines variables
xor eax,eax
fs
mov ax,[resxt]
shl eax,2
fs
mov [majv_precal_resxt],eax

mov al,[at_console]   ;determine le mode
and al,3h
cmp al,1
je majv_texte
cmp al,2
je majv_graph
cmp al,3
je majv_combi

fs                          ; si il y as une erreur dans l'affichage, affiche la console
mov word[id_tache_af],0
fs
mov dword[ad_tache_af],0
fs
mov byte[nb_zrc],0
jmp fin_majv




;************************************
majv_texte:
;test si on est en mode texte de base
fs
cmp byte[bitpp],0
jne majv_texte_graf

mov ebx,[ad_texte]
mov ebp,[to_texte]
add ebp,ebx
mov di,selvidB8
mov es,di
xor edi,edi

boucle_majv_texte:
mov eax,[ebx]
and eax,0FFFFFFh
mov ch,[ebx+3]
call ajuste_carac
mov cl,al
es
mov [edi],cx
add ebx,4
add edi,2
cmp ebx,ebp
jne boucle_majv_texte

;calcul de la position du curseur
mov ebx,[ad_curseur_texte]
sub ebx,[ad_texte]
shr ebx,2

mov dx,3D4h ;envoie les données a la carte
mov al,0Eh
out dx,al
mov dx,3D5h
mov al,bh
out dx,al
mov dx,3D4h
mov al,0Fh
out dx,al
mov dx,3D5h
mov al,bl
out dx,al

;affiche souris
fs
test byte[atts1],1
jz fin_majv
xor eax,eax
xor ebx,ebx
xor ecx,ecx
xor edx,edx
fs
mov bx,[xs1]
fs
mov ax,[ys1]
fs
mov cx,[resxt]
shr eax,4
shr ebx,3
mul ecx
add ebx,eax
shl ebx,1
es
mov byte[ebx],8Fh   ;ecrit le caractère
inc ebx
es
cmp byte[ebx],0
jne ignore_force_couleur_souris
mov byte[ebx],07h
ignore_force_couleur_souris:

;signal que la position souris as été mis a jour
fs
mov eax,[xs1]
fs
mov [axs1],eax
jmp fin_majv


;*************************************
majv_graph:
fs
mov eax,[majv_ydeb]
fs
mov [num_ligne_majv],eax

xor ecx,ecx
xor edx,edx
fs
mov eax,[majv_xdeb]
fs
mov cx,[octpp]
mul ecx
mov edi,eax
xor ecx,ecx
xor edx,edx
fs
mov eax,[majv_ydeb]
fs
mov cx,[octpl]
mul ecx
add edi,eax
mov esi,edi
add esi,[ad_graf]  

xor ecx,ecx
xor edx,edx
fs
mov cx,[octpp]
fs
mov eax,[majv_xfin]
fs
sub eax,[majv_xdeb]
mul ecx
fs
mov [majv_precal_longeur_ligne],eax

fs
mov cx,[octpl]
sub ecx,eax
fs
mov [majv_precal_offset_ligne],ecx


fs
test word[at_csl],10h     ;test si on est en linear  
jz majv_graph_banked 


;*******************************************************
mov ax,sellfb             ;mise a jour écran en linear frame buffer
mov es,ax

boucle_majv_graph:
fs
mov ecx,[majv_precal_longeur_ligne]
cld
rep movsb
fs
add esi,[majv_precal_offset_ligne]
fs
add edi,[majv_precal_offset_ligne]
fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne boucle_majv_graph

fs
cmp byte[bitpp],32
je majv_souris_32b_linear
fs
cmp byte[bitpp],24
je majv_souris_24b_linear
fs
cmp byte[bitpp],15
je majv_souris_16b_linear
fs
cmp byte[bitpp],16
je majv_souris_16b_linear
fs
cmp byte[bitpp],8
je majv_souris_8b_linear
jmp fin_majv




;*******************************************************
majv_graph_banked:
mov ax,selvidA
mov es,ax
mov ebx,edi

boucle_majv_graph_banked:
call vesa_mem
fs
mov ecx,[majv_precal_longeur_ligne]
mov edi,ebx
add ebx,ecx
and edi,0FFFFh

mov eax,edi
add eax,ecx
cmp eax,10000h
ja majv_graph_banked_2

cld         ;maj ligne en une passe
rep movsb

fs
add esi,[majv_precal_offset_ligne]
fs
add ebx,[majv_precal_offset_ligne]
jmp suite_majv_graph_banked

majv_graph_banked_2:  ;maj ligne en deux passe
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§!
cld
rep movsb
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§!




suite_majv_graph_banked:
fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne boucle_majv_graph_banked


call vesa_mem



fs
cmp byte[bitpp],32
je majv_souris_32b_banked
fs
cmp byte[bitpp],24
je majv_souris_24b_banked
fs
cmp byte[bitpp],15
je majv_souris_16b_banked
fs
cmp byte[bitpp],16
je majv_souris_16b_banked
fs
cmp byte[bitpp],8
je majv_souris_8b_banked
jmp fin_majv



;********************************************
majv_texte_graf:             ;mise a jour du texte en mode graphique
fs
mov eax,[majv_ydeb]
fs
mov [num_ligne_majv],eax

fs
test word[at_csl],10h     ;test si on est en linear  
jz majv_texte_banked 

mov ax,sellfb
mov es,ax
fs
cmp byte[bitpp],32
je majv_ligne32linear
fs
cmp byte[bitpp],24
je majv_ligne24linear
fs
cmp byte[bitpp],15
je majv_ligne16linear
fs
cmp byte[bitpp],16
je majv_ligne16linear
fs
cmp byte[bitpp],8
je majv_ligne8linear
jmp fin_majv

majv_texte_banked: 
mov ax,selvidA
mov es,ax
fs
cmp byte[bitpp],32
je majv_ligne32banked
fs
cmp byte[bitpp],24
je majv_ligne24banked
fs
cmp byte[bitpp],15
je majv_ligne16banked
fs
cmp byte[bitpp],16
je majv_ligne16banked
fs
cmp byte[bitpp],8
je majv_ligne8banked
jmp fin_majv


;****************************************************
majv_ligne8linear:
call majv_init_text_graf
majv_carac8linear:
call lire_ligne_carac

fs
mov al,[couleur_fond] 
shl dl,1
jnc majets8l0
fs
mov al,[couleur_carac]
majets8l0:
es
mov [edi],al

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8l1
fs
mov al,[couleur_carac]
majets8l1:
es
mov [edi+1],al

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8l2
fs
mov al,[couleur_carac]
majets8l2:
es
mov [edi+2],al

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8l3
fs
mov al,[couleur_carac]
majets8l3:
es
mov [edi+3],al

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8l4
fs
mov al,[couleur_carac]
majets8l4:
es
mov [edi+4],al

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8l5
fs
mov al,[couleur_carac]
majets8l5:
es
mov [edi+5],al

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8l6
fs
mov al,[couleur_carac]
majets8l6:
es
mov [edi+6],al

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8l7
fs
mov al,[couleur_carac]
majets8l7:
es
mov [edi+7],al

add edi,8
add ebx,4
cmp ebx,ebp
jne majv_carac8linear

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_ligne8linear


;*****************************
majv_souris_8b_linear:
test byte[at_console],04h
jz fin_majv
fs
test byte[atts1],01h
jz fin_majv
call adresse_souris

boucle_majv_souris_8b_linear:
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_8b_linear
cmp ebx,edi
jae ignore_majv_souris_8b_linear 
es
mov [ebx],al
ignore_majv_souris_8b_linear:
inc esi
inc ebx
dec dl
jnz boucle_majv_souris_8b_linear
add ebx,ecx
add edi,ecx
sub ebx,16
mov dl,16
dec dh
jnz boucle_majv_souris_8b_linear

fs
test byte[at_vid],4h     ;test si on as besoin de poursuivre l'affichage
jnz majv_complet2
jmp fin_majv




;****************************************************
majv_ligne16linear:      ;et 15!  ;-)
call majv_init_text_graf
majv_carac16linear:
call lire_ligne_carac

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16l0
fs
mov ax,[couleur_carac]
majets16l0:
es
mov [edi],ax

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16l1
fs
mov ax,[couleur_carac]
majets16l1:
es
mov [edi+2],ax

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16l2
fs
mov ax,[couleur_carac]
majets16l2:
es
mov [edi+4],ax

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16l3
fs
mov ax,[couleur_carac]
majets16l3:
es
mov [edi+6],ax

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16l4
fs
mov ax,[couleur_carac]
majets16l4:
es
mov [edi+8],ax

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16l5
fs
mov ax,[couleur_carac]
majets16l5:
es
mov [edi+10],ax

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16l6
fs
mov ax,[couleur_carac]
majets16l6:
es
mov [edi+12],ax

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16l7
fs
mov ax,[couleur_carac]
majets16l7:
es
mov [edi+14],ax

add edi,16
add ebx,4
cmp ebx,ebp
jne majv_carac16linear

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_ligne16linear

;*****************************
majv_souris_16b_linear:
test byte[at_console],04h
jz fin_majv
fs
test byte[atts1],01h
jz fin_majv
call adresse_souris

boucle_majv_souris_16b_linear:
xor eax,eax
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_16b_linear
cmp ebx,edi
jae ignore_majv_souris_16b_linear 
call conv8_24
call conv24_16
es
mov [ebx],ax
ignore_majv_souris_16b_linear:
inc esi
add ebx,2
dec dl
jnz boucle_majv_souris_16b_linear
add ebx,ecx
add edi,ecx
sub ebx,16*2
mov dl,16
dec dh
jnz boucle_majv_souris_16b_linear

fs
test byte[at_vid],4h     ;test si on as besoin de poursuivre l'affichage
jnz majv_complet2
jmp fin_majv



;****************************************************
majv_ligne24linear:
call majv_init_text_graf
majv_carac24linear:
call lire_ligne_carac

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24l0
fs
mov eax,[couleur_carac]
majets24l0:
es
mov [edi],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24l1
fs
mov eax,[couleur_carac]
majets24l1:
es
mov [edi+3],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24l2
fs
mov eax,[couleur_carac]
majets24l2:
es
mov [edi+6],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24l3
fs
mov eax,[couleur_carac]
majets24l3:
es
mov [edi+9],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24l4
fs
mov eax,[couleur_carac]
majets24l4:
es
mov [edi+12],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24l5
fs
mov eax,[couleur_carac]
majets24l5:
es
mov [edi+15],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24l6
fs
mov eax,[couleur_carac]
majets24l6:
es
mov [edi+18],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24l7
fs
mov eax,[couleur_carac]
majets24l7:
es
mov [edi+21],ax
shr eax,16
es
mov [edi+23],al

add edi,24
add ebx,4
cmp ebx,ebp
jne majv_carac24linear

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_ligne24linear

;*****************************
majv_souris_24b_linear:
test byte[at_console],04h
jz fin_majv
fs
test byte[atts1],01h
jz fin_majv
call adresse_souris

boucle_majv_souris_24b_linear:
xor eax,eax
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_24b_linear
cmp ebx,edi
jae ignore_majv_souris_24b_linear 
call conv8_24
es
mov [ebx],ax
shr eax,16
es
mov [ebx+2],al
ignore_majv_souris_24b_linear:
inc esi
add ebx,3
dec dl
jnz boucle_majv_souris_24b_linear
add ebx,ecx
add edi,ecx
sub ebx,16*3
mov dl,16
dec dh
jnz boucle_majv_souris_24b_linear

fs
test byte[at_vid],4h     ;test si on as besoin de poursuivre l'affichage
jnz majv_complet2
jmp fin_majv


;****************************************************
majv_ligne32linear:
call majv_init_text_graf
majv_carac32linear:
call lire_ligne_carac

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32l0
fs
mov eax,[couleur_carac]
majets32l0:
es
mov [edi],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32l1
fs
mov eax,[couleur_carac]
majets32l1:
es
mov [edi+4],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32l2
fs
mov eax,[couleur_carac]
majets32l2:
es
mov [edi+8],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32l3
fs
mov eax,[couleur_carac]
majets32l3:
es
mov [edi+12],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32l4
fs
mov eax,[couleur_carac]
majets32l4:
es
mov [edi+16],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32l5
fs
mov eax,[couleur_carac]
majets32l5:
es
mov [edi+20],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32l6
fs
mov eax,[couleur_carac]
majets32l6:
es
mov [edi+24],eax

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32l7
fs
mov eax,[couleur_carac]
majets32l7:
es
mov [edi+28],eax

add edi,32
add ebx,4
cmp ebx,ebp
jne majv_carac32linear

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_ligne32linear


;*****************************
majv_souris_32b_linear:
test byte[at_console],04h
jz fin_majv
fs
test byte[atts1],01h
jz fin_majv
call adresse_souris

boucle_majv_souris_32b_linear:
xor eax,eax
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_32b_linear
cmp ebx,edi
jae ignore_majv_souris_32b_linear 
call conv8_24
es
mov [ebx],eax
ignore_majv_souris_32b_linear:
inc esi
add ebx,4
dec dl
jnz boucle_majv_souris_32b_linear
add ebx,ecx
add edi,ecx
sub ebx,16*4
mov dl,16
dec dh
jnz boucle_majv_souris_32b_linear

fs
test byte[at_vid],4h     ;test si on as besoin de poursuivre l'affichage
jnz majv_complet2
jmp fin_majv


;****************************************************
majv_ligne8banked:
call majv_init_text_graf
majv_carac8banked:
call lire_ligne_carac
call majbank

fs
mov al,[couleur_fond] 
shl dl,1
jnc majets8b0
fs
mov al,[couleur_carac]
majets8b0:
es
mov [di],al

inc edi
call majbank

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8b1
fs
mov al,[couleur_carac]
majets8b1:
es
mov [di],al

inc edi
call majbank

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8b2
fs
mov al,[couleur_carac]
majets8b2:
es
mov [di],al

inc edi
call majbank

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8b3
fs
mov al,[couleur_carac]
majets8b3:
es
mov [di],al

inc edi
call majbank

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8b4
fs
mov al,[couleur_carac]
majets8b4:
es
mov [di],al

inc edi
call majbank

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8b5
fs
mov al,[couleur_carac]
majets8b5:
es
mov [di],al

inc edi
call majbank

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8b6
fs
mov al,[couleur_carac]
majets8b6:
es
mov [di],al

inc edi
call majbank

fs
mov al,[couleur_fond]
shl dl,1
jnc majets8b7
fs
mov al,[couleur_carac]
majets8b7:
es
mov [di],al

inc edi
add ebx,4
cmp ebx,ebp
jne majv_carac8banked

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_ligne8banked

;*****************************
majv_souris_8b_banked:



;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§




jmp fin_majv

;****************************************************
majv_ligne16banked: ;et 15!  ;-)
call majv_init_text_graf
majv_carac16banked:
call lire_ligne_carac
call majbank

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16b0
fs
mov ax,[couleur_carac]
majets16b0:
es
mov [di],ax

add edi,2
call majbank

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16b1
fs
mov ax,[couleur_carac]
majets16b1:
es
mov [di],ax

add edi,2
call majbank

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16b2
fs
mov ax,[couleur_carac]
majets16b2:
es
mov [di],ax

add edi,2
call majbank

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16b3
fs
mov ax,[couleur_carac]
majets16b3:
es
mov [di],ax

add edi,2
call majbank

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16b4
fs
mov ax,[couleur_carac]
majets16b4:
es
mov [di],ax

add edi,2
call majbank

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16b5
fs
mov ax,[couleur_carac]
majets16b5:
es
mov [di],ax

add edi,2
call majbank

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16b6
fs
mov ax,[couleur_carac]
majets16b6:
es
mov [di],ax

add edi,2
call majbank

fs
mov ax,[couleur_fond]  
shl dl,1
jnc majets16b7
fs
mov ax,[couleur_carac]
majets16b7:
es
mov [di],ax

add edi,2
add ebx,4
cmp ebx,ebp
jne majv_carac16banked

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_ligne16banked

;*****************************
majv_souris_16b_banked:



;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§




jmp fin_majv




;****************************************************
majv_ligne24banked:
call majv_init_text_graf
majv_carac24banked:
call lire_ligne_carac
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24b0
fs
mov eax,[couleur_carac]
majets24b0:
es
mov [di],eax

add edi,3
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24b1
fs
mov eax,[couleur_carac]
majets24b1:
es
mov [di],eax

add edi,3
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24b2
fs
mov eax,[couleur_carac]
majets24b2:
es
mov [di],eax

add edi,3
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24b3
fs
mov eax,[couleur_carac]
majets24b3:
es
mov [di],eax

add edi,3
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24b4
fs
mov eax,[couleur_carac]
majets24b4:
es
mov [di],eax

add edi,3
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24b5
fs
mov eax,[couleur_carac]
majets24b5:
es
mov [di],eax

add edi,3
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24b6
fs
mov eax,[couleur_carac]
majets24b6:
es
mov [di],eax

add edi,3
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets24b7
fs
mov eax,[couleur_carac]
majets24b7:
es
mov [di],ax
shr eax,16

add edi,2
call majbank
es
mov [di],al

inc di
add ebx,4
cmp ebx,ebp
jne majv_carac24banked

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_ligne24banked


;*****************************
majv_souris_24b_banked:



;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§




jmp fin_majv

;****************************************************
majv_ligne32banked:
call majv_init_text_graf
majv_carac32banked:
call lire_ligne_carac
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32b0
fs
mov eax,[couleur_carac]
majets32b0:
es
mov [di],eax

add edi,4
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32b1
fs
mov eax,[couleur_carac]
majets32b1:
es
mov [di],eax

add edi,4
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32b2
fs
mov eax,[couleur_carac]
majets32b2:
es
mov [di],eax

add edi,4
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32b3
fs
mov eax,[couleur_carac]
majets32b3:
es
mov [di],eax

add edi,4
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32b4
fs
mov eax,[couleur_carac]
majets32b4:
es
mov [di],eax

add edi,4
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32b5
fs
mov eax,[couleur_carac]
majets32b5:
es
mov [di],eax

add edi,4
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32b6
fs
mov eax,[couleur_carac]
majets32b6:
es
mov [di],eax

add edi,4
call majbank

fs
mov eax,[couleur_fond]  
shl dl,1
jnc majets32b7
fs
mov eax,[couleur_carac]
majets32b7:
es
mov [di],eax

add edi,4
add ebx,4
cmp ebx,ebp
jne majv_carac32banked

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_ligne32banked


;*****************************
majv_souris_32b_banked:



;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§




jmp fin_majv



;*********************************************************************************
majv_combi:             ;mise a jour du mode combiné
fs
mov eax,[majv_ydeb]
fs
mov [num_ligne_majv],eax

fs
test word[at_csl],10h     ;test si on est en linear  
jz majv_combi_banked 

mov ax,sellfb
mov es,ax
fs
cmp byte[bitpp],32
je majv_combi32linear
fs
cmp byte[bitpp],24
je majv_combi24linear
fs
cmp byte[bitpp],15
je majv_combi16linear
fs
cmp byte[bitpp],16
je majv_combi16linear
fs
cmp byte[bitpp],8
je majv_combi8linear
jmp fin_majv

majv_combi_banked: 
mov ax,selvidA
mov es,ax
fs
cmp byte[bitpp],32
je majv_combi32banked
fs
cmp byte[bitpp],24
je majv_combi24banked
fs
cmp byte[bitpp],15
je majv_combi16banked
fs
cmp byte[bitpp],16
je majv_combi16banked
fs
cmp byte[bitpp],8
je majv_combi8banked
jmp fin_majv


;****************************************************
majv_combi8linear:
call majv_init_text_graf
majv_carac8linear_combi:
call lire_ligne_carac

mov al,[esi] 
shl dl,1
jnc majetc8l0
fs
mov al,[couleur_carac]
majetc8l0:
es
mov [edi],al

mov al,[esi+1]
shl dl,1
jnc majetc8l1
fs
mov al,[couleur_carac]
majetc8l1:
es
mov [edi+1],al

mov al,[esi+2]
shl dl,1
jnc majetc8l2
fs
mov al,[couleur_carac]
majetc8l2:
es
mov [edi+2],al

mov al,[esi+3]
shl dl,1
jnc majetc8l3
fs
mov al,[couleur_carac]
majetc8l3:
es
mov [edi+3],al

mov al,[esi+4]
shl dl,1
jnc majetc8l4
fs
mov al,[couleur_carac]
majetc8l4:
es
mov [edi+4],al

mov al,[esi+5]
shl dl,1
jnc majetc8l5
fs
mov al,[couleur_carac]
majetc8l5:
es
mov [edi+5],al

mov al,[esi+6]
shl dl,1
jnc majetc8l6
fs
mov al,[couleur_carac]
majetc8l6:
es
mov [edi+6],al

mov al,[esi]
shl dl,1
jnc majetc8l7
fs
mov al,[couleur_carac]
majetc8l7:
es
mov [edi+7],al

add esi,8
add edi,8
add ebx,4
cmp ebx,ebp
jne majv_carac8linear_combi

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_combi8linear
jmp majv_souris_8b_linear



;****************************************************
majv_combi16linear:      ;et 15!  ;-)
call majv_init_text_graf
majv_carac16linear_combi:
call lire_ligne_carac

mov ax,[esi] 
shl dl,1
jnc majetc16l0
fs
mov ax,[couleur_carac]
majetc16l0:
es
mov [edi],ax

mov ax,[esi+2] 
shl dl,1
jnc majetc16l1
fs
mov ax,[couleur_carac]
majetc16l1:
es
mov [edi+2],ax

mov ax,[esi+4] 
shl dl,1
jnc majetc16l2
fs
mov ax,[couleur_carac]
majetc16l2:
es
mov [edi+4],ax

mov ax,[esi+6] 
shl dl,1
jnc majetc16l3
fs
mov ax,[couleur_carac]
majetc16l3:
es
mov [edi+6],ax

mov ax,[esi+8]  
shl dl,1
jnc majetc16l4
fs
mov ax,[couleur_carac]
majetc16l4:
es
mov [edi+8],ax

mov ax,[esi+10]  
shl dl,1
jnc majetc16l5
fs
mov ax,[couleur_carac]
majetc16l5:
es
mov [edi+10],ax

mov ax,[esi+12]
shl dl,1
jnc majetc16l6
fs
mov ax,[couleur_carac]
majetc16l6:
es
mov [edi+12],ax

mov ax,[esi+14]   
shl dl,1
jnc majetc16l7
fs
mov ax,[couleur_carac]
majetc16l7:
es
mov [edi+14],ax

add esi,16
add edi,16
add ebx,4
cmp ebx,ebp
jne majv_carac16linear_combi

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_combi16linear
jmp majv_souris_16b_linear

;****************************************************
majv_combi24linear:
call majv_init_text_graf
majv_carac24linear_combi:
call lire_ligne_carac

mov eax,[esi]   
shl dl,1
jnc majetc24l0
fs
mov eax,[couleur_carac]
majetc24l0:
es
mov [edi],eax

mov eax,[esi+3]   
shl dl,1
jnc majetc24l1
fs
mov eax,[couleur_carac]
majetc24l1:
es
mov [edi+3],eax

mov eax,[esi+6]   
shl dl,1
jnc majetc24l2
fs
mov eax,[couleur_carac]
majetc24l2:
es
mov [edi+6],eax

mov eax,[esi+9]   
shl dl,1
jnc majetc24l3
fs
mov eax,[couleur_carac]
majetc24l3:
es
mov [edi+9],eax

mov eax,[esi+12]  
shl dl,1
jnc majetc24l4
fs
mov eax,[couleur_carac]
majetc24l4:
es
mov [edi+12],eax

mov eax,[esi+15]  
shl dl,1
jnc majetc24l5
fs
mov eax,[couleur_carac]
majetc24l5:
es
mov [edi+15],eax

mov eax,[esi+18]  
shl dl,1
jnc majetc24l6
fs
mov eax,[couleur_carac]
majetc24l6:
es
mov [edi+18],eax

mov al,[esi+23] 
shl eax,16
mov ax,[esi+21]  
shl dl,1
jnc majetc24l7
fs
mov eax,[couleur_carac]
majetc24l7:
es
mov [edi+21],ax
shr eax,16
es
mov [edi+23],al

add esi,24
add edi,24
add ebx,4
cmp ebx,ebp
jne majv_carac24linear_combi

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_combi24linear
jmp majv_souris_24b_linear


;****************************************************
majv_combi32linear:
call majv_init_text_graf
majv_carac32linear_combi:
call lire_ligne_carac

mov eax,[esi]  
shl dl,1
jnc majetc32l0
fs
mov eax,[couleur_carac]
majetc32l0:
es
mov [edi],eax

mov eax,[esi+4]  
shl dl,1
jnc majetc32l1
fs
mov eax,[couleur_carac]
majetc32l1:
es
mov [edi+4],eax

mov eax,[esi+8]  
shl dl,1
jnc majetc32l2
fs
mov eax,[couleur_carac]
majetc32l2:
es
mov [edi+8],eax

mov eax,[esi+12]   
shl dl,1
jnc majetc32l3
fs
mov eax,[couleur_carac]
majetc32l3:
es
mov [edi+12],eax

mov eax,[esi+16]  
shl dl,1
jnc majetc32l4
fs
mov eax,[couleur_carac]
majetc32l4:
es
mov [edi+16],eax

mov eax,[esi+20]   
shl dl,1
jnc majetc32l5
fs
mov eax,[couleur_carac]
majetc32l5:
es
mov [edi+20],eax

mov eax,[esi+24]  
shl dl,1
jnc majetc32l6
fs
mov eax,[couleur_carac]
majetc32l6:
es
mov [edi+24],eax

mov eax,[esi+28]  
shl dl,1
jnc majetc32l7
fs
mov eax,[couleur_carac]
majetc32l7:
es
mov [edi+28],eax

add esi,32
add edi,32
add ebx,4
cmp ebx,ebp
jne majv_carac32linear_combi

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_combi32linear
jmp majv_souris_32b_linear


;****************************************************
majv_combi8banked:
call majv_init_text_graf
majv_carac8banked_combi:
call lire_ligne_carac
call majbank

mov al,[esi] 
shl dl,1
jnc majetc8b0
fs
mov al,[couleur_carac]
majetc8b0:
es
mov [di],al

inc edi
call majbank

mov al,[esi+1]
shl dl,1
jnc majetc8b1
fs
mov al,[couleur_carac]
majetc8b1:
es
mov [di],al

inc edi
call majbank

mov al,[esi+2]
shl dl,1
jnc majetc8b2
fs
mov al,[couleur_carac]
majetc8b2:
es
mov [di],al

inc edi
call majbank

mov al,[esi+3]
shl dl,1
jnc majetc8b3
fs
mov al,[couleur_carac]
majetc8b3:
es
mov [di],al

inc edi
call majbank

mov al,[esi+4]
shl dl,1
jnc majetc8b4
fs
mov al,[couleur_carac]
majetc8b4:
es
mov [di],al

inc edi
call majbank

mov al,[esi+5]
shl dl,1
jnc majetc8b5
fs
mov al,[couleur_carac]
majetc8b5:
es
mov [di],al

inc edi
call majbank

mov al,[esi+6]
shl dl,1
jnc majetc8b6
fs
mov al,[couleur_carac]
majetc8b6:
es
mov [di],al

inc edi
call majbank

mov al,[esi+7]
shl dl,1
jnc majetc8b7
fs
mov al,[couleur_carac]
majetc8b7:
es
mov [di],al

add esi,8
inc edi
add ebx,4
cmp ebx,ebp
jne majv_carac8banked_combi

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_combi8banked
jmp majv_souris_8b_banked

;****************************************************
majv_combi16banked: ;et 15!  ;-)
call majv_init_text_graf
majv_carac16banked_combi:
call lire_ligne_carac
call majbank

mov ax,[esi]  
shl dl,1
jnc majetc16b0
fs
mov ax,[couleur_carac]
majetc16b0:
es
mov [di],ax

add edi,2
call majbank

mov ax,[esi+2]   
shl dl,1
jnc majetc16b1
fs
mov ax,[couleur_carac]
majetc16b1:
es
mov [di],ax

add edi,2
call majbank

mov ax,[esi+4]  
shl dl,1
jnc majetc16b2
fs
mov ax,[couleur_carac]
majetc16b2:
es
mov [di],ax

add edi,2
call majbank

mov ax,[esi+6]   
shl dl,1
jnc majetc16b3
fs
mov ax,[couleur_carac]
majetc16b3:
es
mov [di],ax

add edi,2
call majbank

mov ax,[esi+8]   
shl dl,1
jnc majetc16b4
fs
mov ax,[couleur_carac]
majetc16b4:
es
mov [di],ax

add edi,2
call majbank

mov ax,[esi+10]  
shl dl,1
jnc majetc16b5
fs
mov ax,[couleur_carac]
majetc16b5:
es
mov [di],ax

add edi,2
call majbank

mov ax,[esi+12]  
shl dl,1
jnc majetc16b6
fs
mov ax,[couleur_carac]
majetc16b6:
es
mov [di],ax

add edi,2
call majbank

mov ax,[esi+14]  
shl dl,1
jnc majetc16b7
fs
mov ax,[couleur_carac]
majetc16b7:
es
mov [di],ax

add esi,16
add edi,2
add ebx,4
cmp ebx,ebp
jne majv_carac16banked_combi

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_combi16banked
jmp majv_souris_16b_banked




;****************************************************
majv_combi24banked:
call majv_init_text_graf
majv_carac24banked_combi:
call lire_ligne_carac
call majbank

mov eax,[esi]  
shl dl,1
jnc majetc24b0
fs
mov eax,[couleur_carac]
majetc24b0:
es
mov [di],eax

add edi,3
call majbank

mov eax,[esi+3]  
shl dl,1
jnc majetc24b1
fs
mov eax,[couleur_carac]
majetc24b1:
es
mov [di],eax

add edi,3
call majbank

mov eax,[esi+6] 
shl dl,1
jnc majetc24b2
fs
mov eax,[couleur_carac]
majetc24b2:
es
mov [di],eax

add edi,3
call majbank

mov eax,[esi+9]   
shl dl,1
jnc majetc24b3
fs
mov eax,[couleur_carac]
majetc24b3:
es
mov [di],eax

add edi,3
call majbank

mov eax,[esi+12]   
shl dl,1
jnc majetc24b4
fs
mov eax,[couleur_carac]
majetc24b4:
es
mov [di],eax

add edi,3
call majbank

mov eax,[esi+15]  
shl dl,1
jnc majetc24b5
fs
mov eax,[couleur_carac]
majetc24b5:
es
mov [di],eax

add edi,3
call majbank

mov eax,[esi+18]  
shl dl,1
jnc majetc24b6
fs
mov eax,[couleur_carac]
majetc24b6:
es
mov [di],eax

add edi,3
call majbank

mov al,[esi+23]   
shl eax,16
mov ax,[esi+21]
shl dl,1
jnc majetc24b7
fs
mov eax,[couleur_carac]
majetc24b7:
es
mov [di],ax
shr eax,16

add edi,2
call majbank
es
mov [di],al

add esi,24
inc di
add ebx,4
cmp ebx,ebp
jne majv_carac24banked_combi

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_combi24banked
jmp majv_souris_24b_banked

;****************************************************
majv_combi32banked:
call majv_init_text_graf
majv_carac32banked_combi:
call lire_ligne_carac
call majbank

mov eax,[esi] 
shl dl,1
jnc majetc32b0
fs
mov eax,[couleur_carac]
majetc32b0:
es
mov [di],eax

add edi,4
call majbank

mov eax,[esi+4] 
shl dl,1
jnc majetc32b1
fs
mov eax,[couleur_carac]
majetc32b1:
es
mov [di],eax

add edi,4
call majbank

mov eax,[esi+8]   
shl dl,1
jnc majetc32b2
fs
mov eax,[couleur_carac]
majetc32b2:
es
mov [di],eax

add edi,4
call majbank

mov eax,[esi+12]   
shl dl,1
jnc majetc32b3
fs
mov eax,[couleur_carac]
majetc32b3:
es
mov [di],eax

add edi,4
call majbank

mov eax,[esi+16]   
shl dl,1
jnc majetc32b4
fs
mov eax,[couleur_carac]
majetc32b4:
es
mov [di],eax

add edi,4
call majbank

mov eax,[esi+20]   
shl dl,1
jnc majetc32b5
fs
mov eax,[couleur_carac]
majetc32b5:
es
mov [di],eax

add edi,4
call majbank

mov eax,[esi+24]   
shl dl,1
jnc majetc32b6
fs
mov eax,[couleur_carac]
majetc32b6:
es
mov [di],eax

add edi,4
call majbank

mov eax,[esi+28]   
shl dl,1
jnc majetc32b7
fs
mov eax,[couleur_carac]
majetc32b7:
es
mov [di],eax

add esi,32
add edi,4
add ebx,4
cmp ebx,ebp
jne majv_carac32banked_combi

fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne majv_combi32banked
jmp majv_souris_32b_banked




;***********************************************************
majbank:   ;change la bank video dans A0000h si les MSB de l'adresse du pointeur dans edi n'est plus la bonne
push edx
mov edx,edi
shr edx,16
fs
cmp dx,[chunka]
jne corrige_bank
pop edx
ret

corrige_bank:
fs
mov [chunka],dx
call vesa_mem
pop edx
ret


;***********************************************************
lire_ligne_carac:     ;lit le carac en ebx et extrait l'octet image du carac correspondant a la ligne dans dl
push eax
push ebx
push ecx
push esi

;cherche  la table de caractère correspondant a la page
mov eax,[ebx]
and eax,0FFFF00h
mov esi,index_tabcar
boucle_lire_ligne_carac:
fs
cmp eax,[esi]
je index_tabcar_trouve
add esi,8
cmp esi,index_tabcar+512
jne boucle_lire_ligne_carac

mov eax,[ebx]     ;charge les caractères par défaut si aucune table de carractès correspond a la page
and eax,0FFFFFFh
call ajuste_carac
fs
mov esi,[index_tabcar+4]
jmp suite_lire_ligne_carac

index_tabcar_trouve: ;lit la position de la table des caractère correspondant a la page
fs
mov eax,[esi+4]
mov esi,eax
mov eax,[ebx]
and eax,0FFh

suite_lire_ligne_carac:
shl eax,4
add esi,eax
fs
mov ax,[num_ligne_majv]
and eax,0Fh
add esi,eax    
gs
mov dl,[esi]

mov cl,[ebx+3]
cmp [ad_curseur_texte],ebx
jne pascurseur
cmp eax,12    ;numéros de la ligne actuellement affiché
jne pascurseur
mov cl,0FFh   ;couleur du curseur
mov dl,0FFh
pascurseur:

fs
cmp byte[bitpp],8
je majv_couleur8
fs
cmp byte[bitpp],15
je majv_couleur15
fs
cmp byte[bitpp],16
je majv_couleur16

mov esi,ad_tabcoul
mov al,cl
and eax,0Fh
shl eax,2
add esi,eax
fs
mov eax,[esi] 
and eax,0FFFFFFh
fs
mov [couleur_carac],eax

mov esi,ad_tabcoul
mov al,cl
and eax,0F0h
shr eax,2
add esi,eax
fs
mov eax,[esi] 
and eax,0FFFFFFh
fs
mov [couleur_fond],eax
pop esi
pop ecx
pop ebx
pop eax
ret

majv_couleur8:
mov al,cl
and eax,0Fh
fs
mov [couleur_carac],ax

mov al,cl
and eax,0F0h
shr eax,4
fs
mov [couleur_fond],ax
pop esi
pop ecx
pop ebx
pop eax
ret


majv_couleur15:
mov al,cl
and eax,0Fh
shl eax,3
mov esi,eax
fs
mov ax,[esi+ad_tabcoul]
call conv24_15
fs
mov [couleur_carac],ax

mov al,cl
and eax,0F0h
shr eax,1
mov esi,eax
fs
mov ax,[esi+ad_tabcoul]
call conv24_15
fs
mov [couleur_fond],ax
pop esi
pop ecx
pop ebx
pop eax
ret

majv_couleur16:
mov esi,ad_tabcoul
mov al,cl
and eax,0Fh
shl eax,2
add esi,eax

fs
mov eax,[esi] 
and eax,0FFFFFFh
call conv24_16
fs
mov [couleur_carac],eax

mov esi,ad_tabcoul
mov al,cl
and eax,0F0h
shr eax,2
add esi,eax

fs
mov eax,[esi] 
and eax,0FFFFFFh
call conv24_16
fs
mov [couleur_fond],eax
pop esi
pop ecx
pop ebx
pop eax
ret



;****************************************************
ajuste_carac:                    ;ajuste le numéros de caractère pour ajouter le support de caractère supplémentaire
test eax,0FFFFFFE0h              ;qui ne sont pas comprit dans les 256 premier catactère unicode
jz espacevide
test eax,0FFFF00h
jz caracok_ajuste_carac
cmp eax,152h           ;e dans l'o majuscule
je t152
cmp eax,153h           ;e dans l'o minuscule
je t153
cmp eax,178h           ;Ÿ 
je t178
cmp eax,393h
je t393
cmp eax,394h
je t394
cmp eax,3A3h
je t3A3
cmp eax,3A6h
je t3A6
cmp eax,3A9h
je t3A9
cmp eax,3B1h
je t3B1
cmp eax,3B2h
je t3B2
cmp eax,3BBh
je t3BB
cmp eax,3B8h
je t3B8
cmp eax,3C0h
je t3C0
cmp eax,3C6h
je t3C6
cmp eax,3C8h
je t3C8
cmp eax,3C9h
je t3C9
cmp eax,20ACh     ;€
je t20AC
cmp eax,221Ah
je t221A
cmp eax,221Bh
je t221B
cmp eax,221Eh
je t221E
cmp eax,222Bh
je t222B
cmp eax,2248h
je t2248
cmp eax,2264h
je t2264
cmp eax,2265h
je t2265
cmp eax,2610h
je t2610
cmp eax,2611h
je t2611
cmp eax,17fh
je t17F
cmp eax,2DAh
je t2DA
cmp eax,2C4h
je t2C4
cmp eax,2C5h
je t2C5


mov al,1Fh             ;si le symbole est inconnu
jmp caracok_ajuste_carac

espacevide:
mov al," "
jmp caracok_ajuste_carac

t152:
mov al,01h        ;remplaçant du e dans l'o majuscule
jmp caracok_ajuste_carac

t153:
mov al,02h        ;remplaçant du e dans l'o minuscule   
jmp caracok_ajuste_carac

t178:
mov al,03h        ;remplaçant du Ÿ
jmp caracok_ajuste_carac 

t393:
mov al,04h
jmp caracok_ajuste_carac

t394:
mov al,05h
jmp caracok_ajuste_carac 

t3A3:
mov al,06h
jmp caracok_ajuste_carac 

t3A6:
mov al,07h
jmp caracok_ajuste_carac 

t3A9:
mov al,08h
jmp caracok_ajuste_carac 

t3B1:
mov al,09h
jmp caracok_ajuste_carac 

t3B2:
mov al,0Ah
jmp caracok_ajuste_carac 

t3BB:
mov al,0Bh
jmp caracok_ajuste_carac 

t3B8:
mov al,0Ch
jmp caracok_ajuste_carac 

t3C0:
mov al,0Dh
jmp caracok_ajuste_carac 

t3C6:
mov al,0Eh
jmp caracok_ajuste_carac 

t3C8:
mov al,0Fh
jmp caracok_ajuste_carac 

t3C9:
mov al,10h 
jmp caracok_ajuste_carac 

t20AC:
mov al,11h 
jmp caracok_ajuste_carac

t221A:
mov al,12h
jmp caracok_ajuste_carac 

t221B:
mov al,13h
jmp caracok_ajuste_carac 

t221E:
mov al,14h
jmp caracok_ajuste_carac 

t222B:
mov al,15h
jmp caracok_ajuste_carac 

t2248:
mov al,16h
jmp caracok_ajuste_carac 

t2264:
mov al,17h
jmp caracok_ajuste_carac 

t2265:
mov al,18h
jmp caracok_ajuste_carac 

t2610:
mov al,19h
jmp caracok_ajuste_carac 

t2611:
mov al,1Ah
jmp caracok_ajuste_carac 

t17F:
mov al,1Bh
jmp caracok_ajuste_carac 

t2DA:
mov al,1Ch
jmp caracok_ajuste_carac 

t2C4:
mov al,1Dh
jmp caracok_ajuste_carac 

t2C5:
mov al,1Eh

caracok_ajuste_carac:
and eax,0FFh
ret


;****************************************************
majv_init_text_graf:
xor ecx,ecx
xor edx,edx
fs
mov eax,[num_ligne_majv]
fs
mov cx,[octpl]
mul ecx
mov edi,eax   ;edi=pointeur sur la zone ecran

mov esi,eax
add esi,[ad_graf] ;esi=pointeur sur la zone image


fs
mov eax,[num_ligne_majv]
fs
mov ecx,[majv_precal_resxt]
shr eax,4
xor edx,edx
mul ecx
mov ebx,eax 
add ebx,[ad_texte]    ;ebx=pointeur sur la zone texte


fs
mov ebp,[majv_precal_resxt]
add ebp,ebx         ;ebp=adresse max pour la ligne
ret





;***********************************************************
adresse_souris:
xor eax,eax
xor ecx,ecx
xor edx,edx
fs
mov ax,[axs1]
fs
mov cx,[octpp]
mul ecx
mov ebx,eax
xor eax,eax
xor ecx,ecx
xor edx,edx
fs
mov ax,[ays1]
fs
mov cx,[octpl]        ;ecx=octet par ligne
mul ecx
add ebx,eax           ;ebx=pointeur sur pixel haut gauche du curseur
mov edi,eax
add edi,ecx           ;edi=pointeur extremité ligne
mov esi,[ad_curseur]  ;esi=pointeur sur image curseur
mov edx,1010h         ;dh= nb de ligne dl=nb de colonne
ret




;***********************************************************
maj_console0:

push ds
push es
mov ax,seldat
mov ds,ax
mov ax,selramh
mov es,ax

mov ebx,[ad_console0]
cmp ebx,0
je init_console0

sub ebx,10h
call libmem

init_console0:
xor eax,eax
xor ecx,ecx
xor edx,edx
mov ax,[resxt]
mov cx,[resyt]

cmp byte[bitpp],0
je noaj_console0
test word[resy],0Fh ;test si on a pas un multiple de 16 en resolution verticale
jz noaj_console0
inc cx             ;si oui rajoute une ligne de texte
noaj_console0:

mul ecx
shl eax,2
push eax

mov ecx,eax
add ecx,ad_res_console+256


push ecx
add ecx,15
and ecx,0FFFFFFF0h
call resmem
pop ecx
es
mov word[ebx+8],czm_etz      ;ecran tache zéro
add ebx,10h
mov [ad_console0],ebx

add ebx, 100000h   ;parce qu'on est en mémoire haute
mov eax,selconsole
mov dx,selgdt
mov ds,dx     
mov dl,02h       ;segment de données ring 0
call creeds

mov eax,selecran
mov dx,selgdt
mov ds,dx     
mov dl,02h       ;segment de données ring 0
call creeds

mov dx,selconsole
mov ds,dx  

mov word[at_console],05h     ;texte+curseur souris

pop eax
mov [to_texte],eax
mov dword[ad_texte],ad_res_console
mov dword[ad_curseur_texte],ad_res_console
add eax,ad_res_console
mov [ad_curseur],eax

mov edi,eax    ;copie la souris par défaut
mov esi,ad_curseur_defaut
mov ax,seldat
mov cx,ds
mov ds,ax
mov es,cx
mov ecx,256
cld
rep movsb
pop es
pop ds
ret

