;mise a jour de l'écran video
mov ax,seldat
mov fs,ax
mov ax,selramh
mov gs,ax
fs
or byte[at_vid],08h

fs
mov byte[trappe_tache0],50

;*********************************************************
majv_charge_seg_csl:     ;charge le bon segment de mémoire relatif a la console
xor esi,esi
fs
mov si,[no_ecran]
shl esi,5
fs
cmp word[esi+table_ecran_id],0
jne majv_tache
mov dx,selconsole
mov ds,dx 
jmp majv_test_action

majv_tache:
;charge le descripteur du segment affiché dans le descripteur global correspondant

mov ax,selgdt
mov ds,ax

fs
mov ebx,[esi+table_ecran_ad]
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



;************************************************
;charge les  touches appuyé et la position souris

fs
mov eax,[atbp]
fs
mov ebx,[atbp+4]
fs
mov ecx,[atbp+8]
fs
mov edx,[atbp+12]
mov [bm_clavier],eax
mov [bm_clavier+4],ebx
mov [bm_clavier+8],ecx
mov [bm_clavier+12],edx
fs
mov eax,[xs1]
mov [posx_souris],eax             ;????????????????????a changer lors du multiecran


;***************************************************
majv_test_action:
fs
mov eax,[cptsf]
fs
cmp eax,[majv_dern]
jb majv_juste_souris
add eax,25
fs
mov [majv_dern],eax
                     
test byte[at_console],010h  ;test si on doit mettre a jour l'écran
jz majv_juste_souris
and byte[at_console],0EFh
fs
or byte[at_vid],01
fs
mov byte[trappe_tache0],51


;charge les coordonnée de mise a jour
xor eax,eax
mov ax,[dmaj_xdeb]
fs
mov [majv_xdeb],ax
mov ax,[dmaj_xfin]
fs
mov [majv_xfin],ax
mov ax,[dmaj_ydeb]
fs
mov [majv_ydeb],ax
mov ax,[dmaj_yfin]
fs
mov [majv_yfin],ax



;ajuste les parametre de la mise a jour si c'est hors limite
;d'abord sur les informations globales
xor ecx,ecx
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

xor ecx,ecx
fs
mov cx,[resx]
fs
cmp [majv_xfin],ecx
jb majv_ok_xfin
fs
mov [majv_xfin],ecx
majv_ok_xfin:
dec ecx
fs
cmp [majv_xdeb],ecx
jb majv_ok_xdeb
fs
mov [majv_xdeb],ecx
majv_ok_xdeb:


;puis sur les informations de l'écran de la tache
xor ecx,ecx
mov cx,[resy_ecran]
fs
cmp [majv_yfin],ecx
jb majv_ok_yfin2 
fs
mov [majv_yfin],ecx
majv_ok_yfin2:
dec ecx
fs
cmp [majv_ydeb],ecx
jb majv_ok_ydeb2
fs
mov [majv_ydeb],ecx
majv_ok_ydeb2:

xor ecx,ecx
mov cx,[resx_ecran]
fs
cmp [majv_xfin],ecx
jb majv_ok_xfin2
fs
mov [majv_xfin],ecx
majv_ok_xfin2:
dec ecx
fs
cmp [majv_xdeb],ecx
jb majv_ok_xdeb2
fs
mov [majv_xdeb],ecx
majv_ok_xdeb2:





;********************
;précalcule certaines variables

xor eax,eax
mov ax,[resx_texte]
shl eax,2
fs
mov [majv_precal_resxt],eax
fs
mov eax,[majv_xdeb]
and eax,0FFFFFFF8h
xor ecx,ecx
xor edx,edx
mov cl,[octet_pixel]
mul ecx
fs
mov [majv_precal_offsetx_ecran],eax
add eax,[ad_graf]
fs
mov [majv_precal_offsetx_image],eax

fs
mov eax,[majv_xdeb]
fs
mov ebx,[majv_xfin]
and eax,0FFFFFFF8h
sub ebx,eax
add ebx,7
and ebx,0FFFFFFF8h
shr eax,1
shr ebx,1
add eax,[ad_texte]
fs
mov [majv_precal_finligne],ebx
fs
mov [majv_precal_debutligne],eax



fs
mov byte[trappe_tache0],52


;**************************************************
mov al,[at_console]   ;determine le mode
and al,3h
cmp al,1
je majv_texte
cmp al,2
je majv_graph
cmp al,3
je majv_combi
mov dx,0
call sfv_sf_choix_console
jmp fin_majv








;************************************
majv_texte:
;test si on est en mode texte de base
fs
cmp byte[bitpp],0
jne majv_texte_graf
fs
mov byte[trappe_tache0],53


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


majv_affiche_souris_texte:  ;affiche souris
test byte[at_console],04h
jz fin_majv
fs
test byte[atts1],01h
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
xor byte[ebx+1],7Fh

;signal que la position souris as été mis a jour
fs
mov eax,[xs1]
fs
mov [axs1],eax
jmp fin_majv





;*************************************
majv_graph:

fs
mov byte[trappe_tache0],53

mov ax,selramh
mov es,ax
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
fs
add edi,[ad_zt_ecran]

xor ecx,ecx
xor edx,edx
fs
mov cx,[octpp]
fs
mov eax,[majv_xfin]
fs
sub eax,[majv_xdeb]
mul ecx
;?
add eax,3
and eax,0FFFFFFFCh
push eax
shr eax,2
;?
fs
mov [majv_precal_longeur_ligne],eax
;?
pop eax


fs
mov cx,[octpl]
sub ecx,eax
fs
mov [majv_precal_offset_ligne],ecx  ;coté ecran


mov cx,[octet_ligne]
sub ecx,eax
fs
mov [majv_precal_offset_ligne2],ecx  ;coté application





boucle_majv_graph:
fs
mov ecx,[majv_precal_longeur_ligne]
cld
rep movsd
fs
add esi,[majv_precal_offset_ligne2]
fs
add edi,[majv_precal_offset_ligne]
fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_yfin],eax
jne boucle_majv_graph
jmp maj_ztverscarte


;*********************************************************************************************************************************
majv_texte_graf:             ;mise a jour du texte en mode graphique
fs
mov byte[trappe_tache0],54
fs
mov eax,[majv_ydeb]
fs
mov [num_ligne_majv],eax

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
jmp maj_ztverscarte



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
jmp maj_ztverscarte



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
jmp maj_ztverscarte



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
jmp maj_ztverscarte



;******************************************************************************************************************************************
majv_combi:             ;mise a jour du mode combiné
fs
mov byte[trappe_tache0],55
fs
mov eax,[majv_ydeb]
fs
mov [num_ligne_majv],eax

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
jmp maj_ztverscarte



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
jmp maj_ztverscarte




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
jmp maj_ztverscarte



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
jmp maj_ztverscarte






;***************************************************************************************************
;***************************************************************************************************
majv_juste_souris:
fs
mov eax,[axs1]
fs
cmp [xs1],eax
je fin_majv
test byte[at_console],04h
jz fin_majv
fs
test byte[atts1],01h
jz fin_majv
fs
or byte[at_vid],02

fs
cmp byte[bitpp],0
jne majv_souris_graphique

;***********************
;souris en mode texte
mov ax,selvidB8
mov es,ax

;efface souris
xor eax,eax
xor ebx,ebx
xor ecx,ecx
xor edx,edx
fs
mov bx,[axs1]
fs
mov ax,[ays1]
fs
mov cx,[resxt]
shr eax,4
shr ebx,3
mul ecx
add ebx,eax
shl ebx,1
es
xor byte[ebx+1],7Fh
jmp majv_affiche_souris_texte



;*********************************
majv_souris_graphique:
xor eax,eax
xor ebx,ebx
fs
mov ax,[axs1]
fs
mov bx,[ays1]
fs
mov [majv_xdeb],eax
fs
mov [majv_ydeb],ebx
add eax,16
add ebx,16
fs
mov [majv_xfin],eax
fs
mov [majv_yfin],ebx
jmp maj_ztverscarte_procedure




;****************************************
maj_ztverscarte:    ;transfert de la zone tampon a la carte


;test si la souris est présente dans la zone a mettre a jour
xor eax,eax
fs
mov ax,[axs1]
fs
cmp eax,[majv_xfin]
ja maj_ztverscarte_sourishz
add eax,16
fs
cmp eax,[majv_xdeb]
jb maj_ztverscarte_sourishz

xor eax,eax
fs
mov ax,[ays1]
fs
cmp eax,[majv_yfin]
ja maj_ztverscarte_sourishz
add eax,16
fs
cmp eax,[majv_ydeb]
jb maj_ztverscarte_sourishz

;si oui alors il faudra redessiner la souris
fs
or byte[at_vid],02

;test si la souris as bougé
fs
mov eax,[axs1]
fs
cmp eax,[xs1]
je maj_ztverscarte_sourishz

;si oui on agrandit eventuellement la zone pour effacer le vieux cursur
xor eax,eax
fs
mov ax,[axs1]
fs
cmp eax,[majv_xdeb]
ja @f
fs
mov [majv_xdeb],eax
@@:
add eax,16
fs
cmp eax,[majv_xfin]
jb @f
fs
mov [majv_xfin],eax
@@:

xor eax,eax
fs
mov ax,[ays1]
fs
cmp eax,[majv_ydeb]
ja @f
fs
mov [majv_ydeb],eax
@@:
add eax,16
fs
cmp eax,[majv_yfin]
jb @f
fs
mov [majv_yfin],eax
@@:

maj_ztverscarte_sourishz:








;***********************
maj_ztverscarte_procedure:

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
fs
add esi,[ad_zt_ecran]  

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

;calcul la pause dans l'affichage souris qui permet la mise a jour de celle ci
xor eax,eax
fs
mov ax,[ays1]
add eax,16
test byte[at_console],04h
jz majv_ajustement_ysouris
fs
test byte[atts1],01h
jz majv_ajustement_ysouris
fs
test byte[at_vid],02h
jz majv_ajustement_ysouris
fs
cmp eax,[majv_ydeb]
jb majv_ajustement_ysouris 
fs
cmp eax,[majv_yfin]
jbe majv_fincalcul_ysouris

majv_ajustement_ysouris:
fs
mov eax,[majv_yfin]
majv_fincalcul_ysouris:
fs
mov [majv_ysouris],eax

push ds
mov ax,selramh
mov ds,ax
fs
test word[at_vid],10h     ;test si on est en linear  
jz maj_ztverscarte_banked


;*******************************************************
mov ax,sellfb             ;mise a jour écran en linear frame buffer
mov es,ax

;permet l'alignement des transfert de données en dword
fs
mov eax,[majv_precal_longeur_ligne]
mov ecx,eax
add ecx,3
and ecx,0FFFFFFFCh
push ecx
shr ecx,2
fs
mov [majv_precal_longeur_ligne],ecx
pop ecx
sub ecx,eax
fs
sub [majv_precal_offset_ligne],ecx


boucle_maj_ztverscarte:
fs
mov ecx,[majv_precal_longeur_ligne]
cld
rep movsd
fs
add esi,[majv_precal_offset_ligne]
fs
add edi,[majv_precal_offset_ligne]
fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_ysouris],eax
jne boucle_maj_ztverscarte

pop ds

test byte[at_console],04h
jz fin_majv
fs
test byte[atts1],01h
jz fin_majv
fs
test byte[at_vid],02h
jz fin_majv

pushad
call adresse_souris

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
jmp maj_ztverscarte_linear2



;*****************************
majv_souris_8b_linear:


boucle_majv_souris_8b_linear:
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_8b_linear
cmp edi,ebx
jae ignore_majv_souris_8b_linear 
es
mov [edi],al
ignore_majv_souris_8b_linear:
inc esi
inc edi
dec dl
jnz boucle_majv_souris_8b_linear
add edi,ecx
add ebx,ecx
sub edi,16
mov dl,16
dec dh
jnz boucle_majv_souris_8b_linear
jmp maj_ztverscarte_linear2



;*****************************
majv_souris_16b_linear:

boucle_majv_souris_16b_linear:
xor eax,eax
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_16b_linear
cmp edi,ebx
jae ignore_majv_souris_16b_linear 
call conv8_24
call conv24_165
es
mov [edi],ax
ignore_majv_souris_16b_linear:
inc esi
add edi,2
dec dl
jnz boucle_majv_souris_16b_linear
add edi,ecx
add ebx,ecx
sub edi,16*2
mov dl,16
dec dh
jnz boucle_majv_souris_16b_linear
jmp maj_ztverscarte_linear2



;*****************************
majv_souris_24b_linear:


boucle_majv_souris_24b_linear:
xor eax,eax
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_24b_linear
cmp edi,ebx
jae ignore_majv_souris_24b_linear 
call conv8_24
es
mov [edi],ax
shr eax,16
es
mov [edi+2],al
ignore_majv_souris_24b_linear:
inc esi
add edi,3
dec dl
jnz boucle_majv_souris_24b_linear
add edi,ecx
add ebx,ecx
sub edi,16*3
mov dl,16
dec dh
jnz boucle_majv_souris_24b_linear
jmp maj_ztverscarte_linear2



;***************************
majv_souris_32b_linear:


boucle_majv_souris_32b_linear:
xor eax,eax
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_32b_linear
cmp edi,ebx
jae ignore_majv_souris_32b_linear 
call conv8_24
es
mov [edi],eax
ignore_majv_souris_32b_linear:
inc esi
add edi,4
dec dl
jnz boucle_majv_souris_32b_linear
add edi,ecx
add ebx,ecx
sub edi,16*4
mov dl,16
dec dh
jnz boucle_majv_souris_32b_linear
;jmp maj_ztverscarte_linear2



;********************************
maj_ztverscarte_linear2:
popad

fs
mov eax,[majv_yfin]
fs
cmp [majv_ysouris],eax
je fin_majv
mov ax,selramh             ;mise a jour écran en linear frame buffer
mov ds,ax


boucle2_maj_ztverscarte:
fs
mov ecx,[majv_precal_longeur_ligne]
cld
rep movsd
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
jne boucle2_maj_ztverscarte
jmp fin_majv








;*******************************************************
maj_ztverscarte_banked:
mov ax,selvidA
mov es,ax

boucle_maj_ztverscarte_banked:
call majbank     
fs
mov ecx,[majv_precal_longeur_ligne]
mov eax,edi
and eax,0FFFFh
add eax,ecx
cmp eax,10000h
ja maj_ztverscarte_bankedB


push edi         ;maj ligne en une passe
and edi,0FFFFh
cld
rep movsb
pop edi
fs
add edi,[majv_precal_longeur_ligne]
jmp suite_maj_ztverscarte_banked


maj_ztverscarte_bankedB:  ;maj ligne en deux passe
push edi
push edi
and edi,0FFFCh
mov ecx,10000h
sub ecx,edi
push ecx
shr ecx,2
cld
rep movsd
pop eax
pop edi
add edi,eax
fs
mov ecx,[majv_precal_longeur_ligne]
sub ecx,eax
call majbank

xor edi,edi
add ecx,3
shr ecx,2
cld
rep movsd
pop edi
fs
add edi,[majv_precal_longeur_ligne]


suite_maj_ztverscarte_banked:
fs
add esi,[majv_precal_offset_ligne]
fs
add edi,[majv_precal_offset_ligne]
fs
inc dword[num_ligne_majv]
fs
mov eax,[num_ligne_majv]
fs
cmp [majv_ysouris],eax
jne boucle_maj_ztverscarte_banked


pop ds
test byte[at_console],04h
jz fin_majv
fs
test byte[atts1],01h
jz fin_majv
fs
test byte[at_vid],02h
jz fin_majv
pushad
call adresse_souris


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
jmp maj_ztverscarte_banked2




;***************************************
majv_souris_8b_banked:

boucle_majv_souris_8b_banked:
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_8b_banked
cmp edi,ebx
jae ignore_majv_souris_8b_banked 
call majbank
es
mov [di],al
ignore_majv_souris_8b_banked:
inc esi
inc edi
dec dl
jnz boucle_majv_souris_8b_banked
add edi,ecx
add ebx,ecx
sub edi,16
mov dl,16
dec dh
jnz boucle_majv_souris_8b_banked
jmp maj_ztverscarte_banked2



;*****************************
majv_souris_16b_banked:

boucle_majv_souris_16b_banked:
xor eax,eax
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_16b_banked
cmp edi,ebx
jae ignore_majv_souris_16b_banked 
call conv8_24
call conv24_165
call majbank
es
mov [di],ax
ignore_majv_souris_16b_banked:
inc esi
add edi,2
dec dl
jnz boucle_majv_souris_16b_banked
add edi,ecx
add ebx,ecx
sub edi,16*2
mov dl,16
dec dh
jnz boucle_majv_souris_16b_banked
jmp maj_ztverscarte_banked2



;*****************************
majv_souris_24b_banked:

boucle_majv_souris_24b_banked:
xor eax,eax
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_24b_banked
cmp edi,ebx
jae ignore_majv_souris_24b_banked 
call conv8_24
call majbank
es
mov [di],al
inc edi
call majbank
es
mov [di],ah
inc edi
call majbank
shr eax,16
es
mov [di],al
sub edi,2
ignore_majv_souris_24b_banked:
inc esi
add edi,3
dec dl
jnz boucle_majv_souris_24b_banked
add edi,ecx
add ebx,ecx
sub edi,16*3
mov dl,16
dec dh
jnz boucle_majv_souris_24b_banked
jmp maj_ztverscarte_banked2



;*****************************
majv_souris_32b_banked:

boucle_majv_souris_32b_banked:
xor eax,eax
mov al,[esi]
cmp al,0FFh
je ignore_majv_souris_32b_banked
cmp edi,ebx
jae ignore_majv_souris_32b_banked 
call conv8_24
call majbank
es
mov [di],eax
ignore_majv_souris_32b_banked:
inc esi
add edi,4
dec dl
jnz boucle_majv_souris_32b_banked
add edi,ecx
add ebx,ecx
sub edi,16*4
mov dl,16
dec dh
jnz boucle_majv_souris_32b_banked
jmp maj_ztverscarte_banked2




;**********************************
maj_ztverscarte_banked2:
popad
fs
mov eax,[majv_yfin]
fs
cmp [majv_ysouris],eax
je fin_majv
mov ax,selramh
mov ds,ax

boucle2_maj_ztverscarte_banked:
call majbank     
fs
mov ecx,[majv_precal_longeur_ligne]
mov eax,edi
and eax,0FFFFh
add eax,ecx
cmp eax,10000h
ja maj_ztverscarte_bankedB2


push edi         ;maj ligne en une passe
and edi,0FFFFh
cld
rep movsb
pop edi
fs
add edi,[majv_precal_longeur_ligne]
jmp suite2_maj_ztverscarte_banked


maj_ztverscarte_bankedB2:  ;maj ligne en deux passe
push edi
push edi
and edi,0FFFCh
mov ecx,10000h
sub ecx,edi
push ecx
shr ecx,2
cld
rep movsd
pop eax
pop edi
add edi,eax
fs
mov ecx,[majv_precal_longeur_ligne]
sub ecx,eax
call majbank

xor edi,edi
add ecx,3
shr ecx,2
cld
rep movsd
pop edi
fs
add edi,[majv_precal_longeur_ligne]


suite2_maj_ztverscarte_banked:
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
jne boucle2_maj_ztverscarte_banked
jmp fin_majv



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
push eax
call vesa_mem
pop eax
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
and eax,0FFFFFFh
cmp eax,20h
ja caracsup20
mov eax,20h
caracsup20:
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
je majv_couleur16
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


majv_couleur16:
mov esi,ad_tabcoul
mov al,cl
and eax,0Fh
shl eax,2
add esi,eax

fs
mov eax,[esi] 
and eax,0FFFFFFh
call conv24_165
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
call conv24_165
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
mov edi,eax   
fs
add edi,[ad_zt_ecran] 
fs
add edi,[majv_precal_offsetx_ecran]   ;edi=pointeur sur la zone ecran


fs
mov eax,[num_ligne_majv]
mov cx,[octet_ligne]
mul ecx
mov esi,eax
fs
add esi,[majv_precal_offsetx_image]   ;esi=pointeur sur la zone image

fs
mov eax,[num_ligne_majv]
fs
mov ecx,[majv_precal_resxt]
shr eax,4
xor edx,edx
mul ecx
mov ebx,eax 
fs
add ebx,[majv_precal_debutligne]    ;ebx=pointeur sur la zone texte


fs
mov ebp,[majv_precal_finligne]
add ebp,ebx         ;ebp=adresse max pour la ligne

mov ax,selramh
mov es,ax

ret





;***********************************************************
adresse_souris:
xor ecx,ecx
xor edx,edx
fs
mov eax,[xs1]
fs
mov [axs1],eax
and eax,0FFFFh
fs
mov cx,[octpp]
mul ecx
mov edi,eax
xor eax,eax
xor ecx,ecx
xor edx,edx
fs
mov ax,[ys1]
fs
mov cx,[octpl]        ;ecx=octet par ligne
mul ecx
add edi,eax           ;edi=pointeur sur pixel haut gauche du curseur
mov ebx,eax
add ebx,ecx           ;ebx=pointeur extremité ligne
mov esi,[ad_curseur]  ;esi=pointeur sur image curseur
mov edx,1010h         ;dh= nb de ligne dl=nb de colonne
ret




;***********************************************************
maj_console0:
cli
push ds
push es
mov ax,seldat
mov ds,ax
mov ax,selramh
mov es,ax
or byte[at_csl],0Fh ;signal que le tecop doit être mis a jour

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
mov ax,seldat
mov es,ax

mov word[at_console],05h     ;texte+curseur souris



es
mov ax,[resx]
es
mov bx,[resy]
mov [resx_ecran],ax
mov [resy_ecran],bx
shr ax,3
shr bx,4
mov [resx_texte],ax
mov [resy_texte],bx
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
mov ecx,64
cld
rep movsd
pop es
pop ds


;****************reserve la zone tampon écran
mov ebx,[ad_zt_ecran]
cmp ebx,0
je init_zt_ecran

sub ebx,10h
call libmem

init_zt_ecran:
xor eax,eax
xor ebx,ebx
xor ecx,ecx
cmp byte[bitpp],0
je init_zt_ecrant

mov ax,[resx]
mov bx,[resy]
mov cx,[octpp]
mul ebx
mul ecx
mov ecx,eax
jmp init_zt_ecranv

init_zt_ecrant:
mov ax,[resxt]
mov bx,[resyt]
mul ebx
shl eax,1
mov ecx,eax

init_zt_ecranv:
call resmem
jc errallocmem
es
mov word[ebx+8],czm_zte      ;zone tampon ecran
add ebx,10h             ;ne pas oublier de ne pas compter sur le descripteur
mov dword[ad_zt_ecran],ebx
sti
ret


fin_majv:
fs
and byte[at_vid],0F0h

fs                ;met a jour le bitmap clavier
mov eax,[atbp]
fs
mov ebx,[atbp+4]
fs
mov ecx,[atbp+8]
fs
mov edx,[atbp+12]
mov [bm_clavier],eax
mov [bm_clavier+4],ebx
mov [bm_clavier+8],ecx
mov [bm_clavier+12],edx

fs                          ;met a jour la position souris
mov eax,[axs1]
mov [posx_souris],eax

