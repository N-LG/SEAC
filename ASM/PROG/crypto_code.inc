;include pour fonction de chiffrements (code)








;mode de parcours des blocs
;ECB ok
;CBC comprit
;CFB plusieurs modes disponibles
;OFB comprit
;CTR comment est mixé le nonce et le compteur? (uttilisé dans le GCM)







;***************************************************************
;pour toutes les fonction suivantes:
;eax= taille de la clef AES
;ebx= pointeur sur vecteur d'initialisation
;ecx=nb de bloc a traiter
;edx=pointeur sur la clef
;esi pointeur sur donnée d'entrée
;esi pointeur sur donnée d'entrée


err_encAES:
popad
mov eax,1
ret



;******************************************************
enc_AES_ECB:
pushad
call AESkeygen
cmp eax,0
jne err_encAES

@@:
call C1B_AES 
add esi,16
add edi,16
dec ecx
jnz @b
popad
xor eax,eax
ret

;******************************************************
dec_AES_ECB:
pushad
call AESkeygen
cmp eax,0
jne err_encAES

@@:
call D1B_AES 
add esi,16
add edi,16
dec ecx
jnz @b
popad
xor eax,eax
ret


;******************************************************
enc_AES_CBC:
pushad
call AESkeygen
cmp eax,0
jne err_encAES

@@:
;effectue le xor avec le vecteur d'init
mov eax,[esi]
mov edx,[esi+4]
xor eax,[ebx]
xor edx,[ebx+4]
mov [bloc_tampon],eax
mov [bloc_tampon+4],edx
mov eax,[esi+8]
mov edx,[esi+12]
xor eax,[ebx+8]
xor edx,[ebx+12]
mov [bloc_tampon+8],eax
mov [bloc_tampon+12],edx

push esi
mov esi,bloc_tampon
call C1B_AES 
pop esi
mov ebx,edi
add esi,16
add edi,16
dec ecx
jnz @b
popad
xor eax,eax
ret


;******************************************************
dec_AES_CBC:
pushad
call AESkeygen
cmp eax,0
jne err_encAES

@@:
push edi
mov edi,bloc_tampon
call D1B_AES 
pop edi

;effectu le xor avec le vecteur d'init
mov eax,[bloc_tampon]
mov edx,[bloc_tampon+4]
xor eax,[ebx]
xor edx,[ebx+4]
mov [edi],eax
mov [edi+4],edx
mov eax,[bloc_tampon+8]
mov edx,[bloc_tampon+12]
xor eax,[ebx+8]
xor edx,[ebx+12]
mov [edi+8],eax
mov [edi+12],edx


mov ebx,esi
add esi,16
add edi,16
dec ecx
jnz @b
popad
xor eax,eax
ret


;***********************************************
enc_AES_CFB:
pushad
call AESkeygen
cmp eax,0
jne err_encAES


@@:
push esi
push edi
mov esi,ebx
mov edi,bloc_tampon
call C1B_AES
pop edi 
pop esi

;efffectue le xor avec la clef genéré
mov eax,[esi]
mov edx,[esi+4]
xor eax,[bloc_tampon]
xor edx,[bloc_tampon+4]
mov [edi],eax
mov [edi+4],edx
mov eax,[esi+8]
mov edx,[esi+12]
xor eax,[bloc_tampon+8]
xor edx,[bloc_tampon+12]
mov [edi+8],eax
mov [edi+12],edx

mov ebx,edi
add esi,16
add edi,16
dec ecx
jnz @b
popad
xor eax,eax
ret


dec_AES_CFB:
pushad
call AESkeygen
cmp eax,0
jne err_encAES


@@:
push esi
push edi
mov esi,ebx
mov edi,bloc_tampon
call C1B_AES
pop edi 
pop esi

;efffectue le xor avec la clef genéré
mov eax,[esi]
mov edx,[esi+4]
xor eax,[bloc_tampon]
xor edx,[bloc_tampon+4]
mov [edi],eax
mov [edi+4],edx
mov eax,[esi+8]
mov edx,[esi+12]
xor eax,[bloc_tampon+8]
xor edx,[bloc_tampon+12]
mov [edi+8],eax
mov [edi+12],edx

mov ebx,esi
add esi,16
add edi,16
dec ecx
jnz @b
popad
xor eax,eax
ret


;***********************************************
enc_AES_OFB:
dec_AES_OFB:
pushad
call AESkeygen
cmp eax,0
jne err_encAES

;enregistre le vecteur d'initialisation
mov eax,[ebx]
mov edx,[ebx+4]
mov [init_vec],eax
mov [init_vec+4],eax
mov eax,[ebx+8]
mov edx,[ebx+12]
mov [init_vec+8],eax
mov [init_vec+12],eax


@@:
push esi
push edi
mov esi,init_vec
mov edi,bloc_tampon
call C1B_AES
pop edi 
pop esi

;efffectue le xor avec la clef genéré
mov eax,[esi]
mov edx,[esi+4]
xor eax,[bloc_tampon]
xor edx,[bloc_tampon+4]
mov [edi],eax
mov [edi+4],edx
mov eax,[esi+8]
mov edx,[esi+12]
xor eax,[bloc_tampon+8]
xor edx,[bloc_tampon+12]
mov [edi+8],eax
mov [edi+12],edx


;met a jour le vecteur d'initialisation
mov eax,[bloc_tampon]
mov edx,[bloc_tampon+4]
mov [init_vec],eax
mov [init_vec+4],eax
mov eax,[bloc_tampon+8]
mov edx,[bloc_tampon+12]
mov [init_vec+8],eax
mov [init_vec+12],eax


add esi,16
add edi,16
dec ecx
jnz @b
popad
xor eax,eax
ret




;***********************************************
;fonctions initialisation bloc compteur a partir du nonce créer pour les mode CTR, CCM, et GCM
;ebp = taille du nonce
;ebx = adresse du nonce

err_init_iv:
mov eax,cer_parami
ret



;**********
init_iv_ctr:     ;appendice B de la documentation nist
cmp ebp,0    ;taille minimal du nonce
je err_init_iv
cmp ebp,16    ;taille maximal du nonce
ja err_init_iv
pushad
mov ecx,ebp
mov esi,ebx
mov edi,init_vec
cld
rep movsb
xor eax,eax
@@:
cmp edi,init_vec+16
jne @f
stosb
jmp @b
@@:
popad
xor eax,eax
ret


;***********
init_iv_ccm:
cmp ebp,7     ;taille minimal du nonce (appendice A de la doc du nist concernant le CCM)
jb err_init_iv
cmp ebp,13    ;taille maximal du nonce
ja err_init_iv
pushad
mov al,14
mov ecx,ebp
mov esi,ebx
sub al,cl     
mov edi,init_vec+1
mov [init_vec],al   ;taille du compteur-1
cld
rep movsb
xor eax,eax
@@:
cmp edi,init_vec+15
jne @f
stosb
jmp @b
@@:
popad
xor eax,eax
ret


;*************???????????????????????????????
init_iv_gcm:
pushad
mov ecx,ebp
mov esi,ebx
mov edi,init_vec+1
mov [init_vec],cl;???????????????
cld
rep movsb
xor eax,eax
@@:
cmp edi,init_vec+16
jne @f
stosb
jmp @b
@@:
popad
xor eax,eax
ret






;***********************************************
enc_AES_CTR:
dec_AES_CTR:
pushad
call AESkeygen
cmp eax,0
jne err_encAES

;init_vec as été initialisé avant d'appeler la fonction!

@@:
;genere la clef a partir du compteur
push esi
push edi
mov esi,init_vec
mov edi,bloc_tampon
call C1B_AES
pop edi 
pop esi


;efffectue le xor avec la clef genéré
mov eax,[esi]
mov edx,[esi+4]
xor eax,[bloc_tampon]
xor edx,[bloc_tampon+4]
mov [edi],eax
mov [edi+4],edx
mov eax,[esi+8]
mov edx,[esi+12]
xor eax,[bloc_tampon+8]
xor edx,[bloc_tampon+12]
mov [edi+8],eax
mov [edi+12],edx


;incrémente le compteur
mov ebx,15
inc byte[ebx+init_vec]
@@:
jnc @f
cmp ebx,0
je @f
dec ebx
stc
adc byte[ebx+init_vec],0
jmp @b
@@:

add esi,16
add edi,16
dec ecx
jnz @b
popad
xor eax,eax
ret





;************************************************************************
;chiffre un bloc en AES  esi=bloc 

C1B_AES:
pushad
mov edx,clef_complete
mov ecx,[nb_tours_AES]
dec ecx


;addroundkey initial
mov eax,[esi]
xor eax,[edx]
mov [edi],eax
mov eax,[esi+4]
xor eax,[edx+4]
mov [edi+4],eax
mov eax,[esi+8]
xor eax,[edx+8]
mov [edi+8],eax
mov eax,[esi+12]
xor eax,[edx+12]
mov [edi+12],eax
add edx,16


boucle_tour_enAES:
;subbytes
xor ebx,ebx
mov ch,16
@@:
mov bl,[edi]
mov al,[ebx+table_permut_aes]
mov [edi],al
inc edi
dec ch
jnz @b
sub edi,16


;shiftrows
mov al,[edi+1]
mov ah,[edi+5]
mov bl,[edi+9]
mov bh,[edi+13]
mov [edi+1],ah
mov [edi+5],bl
mov [edi+9],bh
mov [edi+13],al
mov al,[edi+2]
mov ah,[edi+6]
mov bl,[edi+10]
mov bh,[edi+14]
mov [edi+2],bl
mov [edi+6],bh
mov [edi+10],al
mov [edi+14],ah
mov al,[edi+3]
mov ah,[edi+7]
mov bl,[edi+11]
mov bh,[edi+15]
mov [edi+3],bh
mov [edi+7],al
mov [edi+11],ah
mov [edi+15],bl


;mixcolumns
call mix_columns
add edi,4
call mix_columns
add edi,4
call mix_columns
add edi,4
call mix_columns
sub edi,12


;addroundkey
mov eax,[edx]
xor [edi],eax
mov eax,[edx+4]
xor [edi+4],eax
mov eax,[edx+8]
xor [edi+8],eax
mov eax,[edx+12]
xor [edi+12],eax
add edx,16


dec cl
jnz boucle_tour_enAES


;subbytes
xor ebx,ebx
mov ch,16
@@:
mov bl,[edi]
mov al,[ebx+table_permut_aes]
mov [edi],al
inc edi
dec ch
jnz @b
sub edi,16


;shiftrows
mov al,[edi+1]
mov ah,[edi+5]
mov bl,[edi+9]
mov bh,[edi+13]
mov [edi+1],ah
mov [edi+5],bl
mov [edi+9],bh
mov [edi+13],al
mov al,[edi+2]
mov ah,[edi+6]
mov bl,[edi+10]
mov bh,[edi+14]
mov [edi+2],bl
mov [edi+6],bh
mov [edi+10],al
mov [edi+14],ah
mov al,[edi+3]
mov ah,[edi+7]
mov bl,[edi+11]
mov bh,[edi+15]
mov [edi+3],bh
mov [edi+7],al
mov [edi+11],ah
mov [edi+15],bl


;addroundkey
mov eax,[edx]
xor [edi],eax
mov eax,[edx+4]
xor [edi+4],eax
mov eax,[edx+8]
xor [edi+8],eax
mov eax,[edx+12]
xor [edi+12],eax
add edx,16


popad
ret









;******************************************************
;décrypte un bloc AES
D1B_AES:
pushad
mov edx,clef_complete
mov eax,[nb_tours_AES]
mov ecx,[nb_tours_AES]
shl eax,4
dec ecx
add edx,eax

;rev addroundkey initial
mov eax,[esi]
xor eax,[edx]
mov [edi],eax
mov eax,[esi+4]
xor eax,[edx+4]
mov [edi+4],eax
mov eax,[esi+8]
xor eax,[edx+8]
mov [edi+8],eax
mov eax,[esi+12]
xor eax,[edx+12]
mov [edi+12],eax
sub edx,16


;rev shiftrows
mov al,[edi+1]
mov ah,[edi+5]
mov bl,[edi+9]
mov bh,[edi+13]
mov [edi+1],bh
mov [edi+5],al
mov [edi+9],ah
mov [edi+13],bl
mov al,[edi+2]
mov ah,[edi+6]
mov bl,[edi+10]
mov bh,[edi+14]
mov [edi+2],bl
mov [edi+6],bh
mov [edi+10],al
mov [edi+14],ah
mov al,[edi+3]
mov ah,[edi+7]
mov bl,[edi+11]
mov bh,[edi+15]
mov [edi+3],ah
mov [edi+7],bl
mov [edi+11],bh
mov [edi+15],al


;rev subbytes
xor ebx,ebx
mov ch,16
@@:
mov bl,[edi]
mov al,[ebx+table_rev_permut_aes]
mov [edi],al
inc edi
dec ch
jnz @b
sub edi,16


boucle_tour_decAES:
;rev addroundkey
mov eax,[edx]
xor [edi],eax
mov eax,[edx+4]
xor [edi+4],eax
mov eax,[edx+8]
xor [edi+8],eax
mov eax,[edx+12]
xor [edi+12],eax
sub edx,16


;rev mixcolumns
call rev_mix_columns
add edi,4
call rev_mix_columns
add edi,4
call rev_mix_columns
add edi,4
call rev_mix_columns
sub edi,12


;rev shiftrows
mov al,[edi+1]
mov ah,[edi+5]
mov bl,[edi+9]
mov bh,[edi+13]
mov [edi+1],bh
mov [edi+5],al
mov [edi+9],ah
mov [edi+13],bl
mov al,[edi+2]
mov ah,[edi+6]
mov bl,[edi+10]
mov bh,[edi+14]
mov [edi+2],bl
mov [edi+6],bh
mov [edi+10],al
mov [edi+14],ah
mov al,[edi+3]
mov ah,[edi+7]
mov bl,[edi+11]
mov bh,[edi+15]
mov [edi+3],ah
mov [edi+7],bl
mov [edi+11],bh
mov [edi+15],al


;rev subbytes
xor ebx,ebx
mov ch,16
@@:
mov bl,[edi]
mov al,[ebx+table_rev_permut_aes]
mov [edi],al
inc edi
dec ch
jnz @b
sub edi,16

dec cl
jnz boucle_tour_decAES


;rev addroundkey
mov eax,[edx]
xor [edi],eax
mov eax,[edx+4]
xor [edi+4],eax
mov eax,[edx+8]
xor [edi+8],eax
mov eax,[edx+12]
xor [edi+12],eax
sub edx,16

popad
ret




;**********************************************************
AESkeygen:
cmp eax,128
je AESkeygen128
cmp eax,192
je AESkeygen192
cmp eax,256
je AESkeygen256
mov eax,cer_parami
ret



AESkeygen128:
pushad
mov eax,[edx]
mov ebx,[edx+4]
mov esi,[edx+8]
mov edi,[edx+12]
mov [clef_complete],eax
mov [clef_complete+4],ebx
mov [clef_complete+8],esi
mov [clef_complete+12],edi

xor ebx,ebx
mov esi,clef_complete
mov ecx,1

boucle_AESkeygen128:
mov eax,[esi+12]

cmp ch,0
jne @f

;rotword
ror eax,8

;subword
mov [esi+16],eax
mov bl,[esi+16]
mov al,[ebx+table_permut_aes]
mov [esi+16],al
mov bl,[esi+17]
mov al,[ebx+table_permut_aes]
mov [esi+17],al
mov bl,[esi+18]
mov al,[ebx+table_permut_aes]
mov [esi+18],al
mov bl,[esi+19]
mov al,[ebx+table_permut_aes]
mov [esi+19],al
mov eax,[esi+16]

;xor avec Rcon
xor eax,ecx
mov ch,4
rol cl,1
jnc @f
xor cl,1Ah

@@:
xor eax,[esi]
mov [esi+16],eax

dec ch
add esi,4
cmp esi,clef_complete+160
jne boucle_AESkeygen128

mov dword[nb_tours_AES],10
popad
xor eax,eax
ret


AESkeygen192:
pushad
mov eax,[edx]
mov ebx,[edx+4]
mov esi,[edx+8]
mov edi,[edx+12]
mov [clef_complete],eax
mov [clef_complete+4],ebx
mov [clef_complete+8],esi
mov [clef_complete+12],edi
mov eax,[edx+16]
mov ebx,[edx+20]
mov [clef_complete+16],eax
mov [clef_complete+20],ebx

xor ebx,ebx
mov esi,clef_complete
mov ecx,1

boucle_AESkeygen192:
mov eax,[esi+20]

cmp ch,0
jne @f

;rotword
ror eax,8

;subword
mov [esi+24],eax
mov bl,[esi+24]
mov al,[ebx+table_permut_aes]
mov [esi+24],al
mov bl,[esi+25]
mov al,[ebx+table_permut_aes]
mov [esi+25],al
mov bl,[esi+26]
mov al,[ebx+table_permut_aes]
mov [esi+26],al
mov bl,[esi+27]
mov al,[ebx+table_permut_aes]
mov [esi+27],al

;xor avec Rcon
mov eax,[esi+24]
xor eax,ecx
mov ch,6
rol cl,1
jnc @f
xor cl,1Ah

@@:
xor eax,[esi]
mov [esi+24],eax

dec ch
add esi,4
cmp esi,clef_complete+184
jne boucle_AESkeygen192


mov dword[nb_tours_AES],12
popad
xor eax,eax
ret


AESkeygen256:
pushad
mov eax,[edx]
mov ebx,[edx+4]
mov esi,[edx+8]
mov edi,[edx+12]
mov [clef_complete],eax
mov [clef_complete+4],ebx
mov [clef_complete+8],esi
mov [clef_complete+12],edi
mov eax,[edx+16]
mov ebx,[edx+20]
mov esi,[edx+24]
mov edi,[edx+28]
mov [clef_complete+16],eax
mov [clef_complete+20],ebx
mov [clef_complete+24],esi
mov [clef_complete+28],edi

xor ebx,ebx
mov esi,clef_complete
mov ecx,1

boucle_AESkeygen256:
mov eax,[esi+28]

cmp ch,4
je AESkeygen256_justesubword
cmp ch,0
jne @f

;rotword
ror eax,8

;subword
mov [esi+32],eax
mov bl,[esi+32]
mov al,[ebx+table_permut_aes]
mov [esi+32],al
mov bl,[esi+33]
mov al,[ebx+table_permut_aes]
mov [esi+33],al
mov bl,[esi+34]
mov al,[ebx+table_permut_aes]
mov [esi+34],al
mov bl,[esi+35]
mov al,[ebx+table_permut_aes]
mov [esi+35],al
mov eax,[esi+32]

;xor avec Rcon
xor eax,ecx
mov ch,8
rol cl,1
jnc @f
xor cl,1Ah
jmp @f

AESkeygen256_justesubword:
mov [esi+32],eax
mov bl,[esi+32]
mov al,[ebx+table_permut_aes]
mov [esi+32],al
mov bl,[esi+33]
mov al,[ebx+table_permut_aes]
mov [esi+33],al
mov bl,[esi+34]
mov al,[ebx+table_permut_aes]
mov [esi+34],al
mov bl,[esi+35]
mov al,[ebx+table_permut_aes]
mov [esi+35],al
mov eax,[esi+32]

@@:
xor eax,[esi]
mov [esi+32],eax

dec ch
add esi,4
cmp esi,clef_complete+208
jne boucle_AESkeygen256

mov dword[nb_tours_AES],14
popad
xor eax,eax
ret



;**********************
prepare_colonne:
mov eax,[edi]
mov [var0],eax
mov [var1],eax

rol byte[var1],1
jnc @f
xor byte[var1],1Ah
@@:
rol byte[var1+1],1
jnc @f
xor byte[var1+1],1Ah
@@:
rol byte[var1+2],1
jnc @f
xor byte[var1+2],1Ah
@@:
rol byte[var1+3],1
jnc @f
xor byte[var1+3],1Ah
@@:



mov eax,[var1]
mov [var2],eax

rol byte[var2],1
jnc @f
xor byte[var2],1Ah
@@:
rol byte[var2+1],1
jnc @f
xor byte[var2+1],1Ah
@@:
rol byte[var2+2],1
jnc @f
xor byte[var2+2],1Ah
@@:
rol byte[var2+3],1
jnc @f
xor byte[var2+3],1Ah
@@:

mov eax,[var2]
mov [var3],eax

rol byte[var3],1
jnc @f
xor byte[var3],1Ah
@@:
rol byte[var3+1],1
jnc @f
xor byte[var3+1],1Ah
@@:
rol byte[var3+2],1
jnc @f
xor byte[var3+2],1Ah
@@:
rol byte[var3+3],1
jnc @f
xor byte[var3+3],1Ah
@@:
ret



mix_columns:
call prepare_colonne
mov al,[var1]
xor al,[var1+1]
xor al,[var0+1] 
xor al,[var0+2] 
xor al,[var0+3] 
mov [edi],al

mov al,[var0]
xor al,[var1+1]
xor al,[var1+2] 
xor al,[var0+2] 
xor al,[var0+3] 
mov [edi+1],al

mov al,[var0]
xor al,[var0+1]
xor al,[var1+2] 
xor al,[var1+3] 
xor al,[var0+3] 
mov [edi+2],al

mov al,[var0]
xor al,[var1]
xor al,[var0+1] 
xor al,[var0+2] 
xor al,[var1+3] 
mov [edi+3],al
ret





rev_mix_columns:
call prepare_colonne
mov al,[var3]
xor al,[var2]
xor al,[var1]
xor al,[var3+1]
xor al,[var1+1]
xor al,[var0+1]
xor al,[var3+2]
xor al,[var2+2]
xor al,[var0+2]
xor al,[var3+3]
xor al,[var0+3]
mov [edi],al

mov al,[var3]
xor al,[var0]
xor al,[var3+1]
xor al,[var2+1]
xor al,[var1+1]
xor al,[var3+2]
xor al,[var1+2]
xor al,[var0+2]
xor al,[var3+3]
xor al,[var2+3]
xor al,[var0+3]
mov [edi+1],al

mov al,[var3]
xor al,[var2]
xor al,[var0]
xor al,[var3+1]
xor al,[var0+1]
xor al,[var3+2]
xor al,[var2+2]
xor al,[var1+2]
xor al,[var3+3]
xor al,[var1+3]
xor al,[var0+3]
mov [edi+2],al

mov al,[var3]
xor al,[var1]
xor al,[var0]
xor al,[var3+1]
xor al,[var2+1]
xor al,[var0+1]
xor al,[var3+2]
xor al,[var0+2]
xor al,[var3+3]
xor al,[var2+3]
xor al,[var1+3]
mov [edi+3],al

ret









;******************************************************************************************************************
;inspiration: https://sha256algorithm.com/

;************************
calc_SHA224:
push dword 224
push edi

;calcul le nombre de bloc de 64 octet
mov [taille_SHA],ecx
mov ebp,ecx
add ebp,9+63
shr ebp,6


;initialise le hachage initiale
mov dword[hachage+00],0c1059ed8h
mov dword[hachage+04],0367cd507h
mov dword[hachage+08],03070dd17h
mov dword[hachage+12],0f70e5939h
mov dword[hachage+16],0ffc00b31h
mov dword[hachage+20],068581511h
mov dword[hachage+24],064f98fa7h
mov dword[hachage+28],0befa4fa4h
jmp boucle_sha256






;************************
calc_SHA256:
push dword 256
push edi

;calcul le nombre de bloc de 64 octet
mov [taille_SHA],ecx
mov ebp,ecx
add ebp,9+63
shr ebp,6


;initialise le hachage initiale
mov dword[hachage+00],06a09e667h
mov dword[hachage+04],0bb67ae85h
mov dword[hachage+08],03c6ef372h
mov dword[hachage+12],0a54ff53ah
mov dword[hachage+16],0510e527fh
mov dword[hachage+20],09b05688ch
mov dword[hachage+24],01f83d9abh
mov dword[hachage+28],05be0cd19h
;jmp boucle_sha256




;*******
boucle_sha256:

mov edi,variables_sha2
cmp ecx,-1 
je sha256_bloc_taille
cmp ecx,0 
je sha256_bloc_final
cmp ecx,64
jae sha256_bloc_complet


;si il rest moins de 64 octets on remplis le bloc avec du remplissage
mov edx,ecx
cld
rep movsb
mov al,080h  ;on met un octet 80h a la fin
stosb

mov ecx,-1
;on replit jusqu'a zero la fin du bloc
@@:
cmp edi,variables_sha2+64
je @f
mov byte[edi],0
inc edi
jmp @b

@@:
cmp edx,56 
jae sha256_fincopiebloc

mov eax,[taille_SHA]
shl eax,3
bswap eax
mov  [variables_sha2+60],eax
jmp sha256_fincopiebloc


;*****
sha256_bloc_final:
mov byte[edi],80h
inc edi

;********
sha256_bloc_taille:
cmp edi,variables_sha2+64
je @f
mov byte[edi],0
inc edi
jmp sha256_bloc_taille
@@:

mov eax,[taille_SHA]
shl eax,3
bswap eax
mov  [variables_sha2+60],eax
jmp sha256_fincopiebloc


;si il reste + de 64 octets: copie 64 octet et decremente ecx
sha256_bloc_complet:
push ecx
mov ecx,16
cld
rep movsd
pop ecx
sub ecx,64
sha256_fincopiebloc:



pushad
;mise du bloc en doublemot de 32bits little endian
mov esi,variables_sha2
@@:
mov eax,[esi]
bswap eax
mov [esi],eax
add esi,4
cmp esi,variables_sha2+64
jne @b



;boucle calcul de w16 à w63 ****************************************
mov esi,variables_sha2
boucle_calc_ws256:

mov eax,[esi]   ;w+0 (16)
mov [esi+64],eax ;w+16 (0)

mov edx,[esi+4] ;w+1 (15)
ror edx,7
mov eax,[esi+4] ;w+1 (15)
ror eax,18
xor edx,eax
mov eax,[esi+4] ;w+1 (15)
shr eax,3
xor edx,eax
add [esi+64],edx ;w+16 (0)

mov eax,[esi+36] ;w+9 (7)
add [esi+64],eax ;w+16 (0)

mov edx,[esi+56] ;w+14 (2)
ror edx,17
mov eax,[esi+56] ;w+14 (2)
ror eax,19
xor edx,eax
mov eax,[esi+56] ;w+14 (2)
shr eax,10
xor edx,eax
add [esi+64],edx ;w+16 (0)

add esi,4
cmp esi,variables_sha2+192
jne boucle_calc_ws256



;chargement valeurs initiales A-H******************************
mov esi,hachage
mov edi,A_sha2
movsd
add edi,4
movsd
add edi,4
movsd
add edi,4
movsd
add edi,4
movsd
add edi,4
movsd
add edi,4
movsd
add edi,4
movsd




;boucle calcul A-H progressif ******************************************
xor esi,esi
boucle_calc_wk256:

;temp1
mov eax,[H_sha2]
mov [temp1_sha2],eax 

mov edx,[E_sha2]
ror edx,6
mov eax,[E_sha2]
ror eax,11
xor edx,eax
mov eax,[E_sha2]
ror eax,25
xor edx,eax
add [temp1_sha2],edx 

mov eax,[E_sha2]
not eax
and eax,[G_sha2]
mov edx,[E_sha2]
and edx,[F_sha2]
xor eax,edx
add [temp1_sha2],eax 

mov edx,[esi+constantes_sha256]
add [temp1_sha2],edx 

mov eax,[esi+variables_sha2]
add [temp1_sha2],eax 

;temp2
mov eax,[A_sha2]
and eax,[B_sha2]
mov edx,[A_sha2]
and edx,[C_sha2]
xor eax,edx
mov edx,[B_sha2]
and edx,[C_sha2]
xor eax,edx
mov [temp2_sha2],eax 

mov edx,[A_sha2]
ror edx,2
mov eax,[A_sha2]
ror eax,13
xor edx,eax
mov eax,[A_sha2]
ror eax,22
xor edx,eax
add [temp2_sha2],edx 

;H
mov eax,[G_sha2] 
mov [H_sha2],eax

;G
mov eax,[F_sha2]
mov [G_sha2],eax

;F
mov eax,[E_sha2]
mov [F_sha2],eax

;E
mov eax,[D_sha2]
add eax,[temp1_sha2]
mov [E_sha2],eax

;D
mov eax,[C_sha2]
mov [D_sha2],eax

;C
mov eax,[B_sha2]
mov [C_sha2],eax

;B
mov eax,[A_sha2]
mov [B_sha2],eax

;A
mov eax,[temp1_sha2]
add eax,[temp2_sha2]
mov [A_sha2],eax

add esi,4
cmp esi,256
jne boucle_calc_wk256


mov eax,[A_sha2]
add [hachage],eax
mov eax,[B_sha2]
add [hachage+4],eax
mov eax,[C_sha2]
add [hachage+8],eax
mov eax,[D_sha2]
add [hachage+12],eax
mov eax,[E_sha2]
add [hachage+16],eax
mov eax,[F_sha2]
add [hachage+20],eax
mov eax,[G_sha2]
add [hachage+24],eax
mov eax,[H_sha2]
add [hachage+28],eax

popad
dec ebp
jnz boucle_sha256


;copie de la chaine de hachage calculé***********************
pop edi
pop ecx
mov eax,[hachage]
bswap eax
mov [edi],eax
mov eax,[hachage+4]
bswap eax
mov [edi+4],eax
mov eax,[hachage+8]
bswap eax
mov [edi+8],eax
mov eax,[hachage+12]
bswap eax
mov [edi+12],eax
mov eax,[hachage+16]
bswap eax
mov [edi+16],eax
mov eax,[hachage+20]
bswap eax
mov [edi+20],eax
mov eax,[hachage+24]
bswap eax
mov [edi+24],eax
cmp ecx,256
jne @f
mov eax,[hachage+28]
bswap eax
mov [edi+28],eax
@@:
xor eax,eax
ret




;************************
calc_SHA384:
push dword 384
push edi

;calcul le nombre de bloc de 128 octet
mov [taille_SHA],ecx
mov ebp,ecx
add ebp,17+127
shr ebp,7


;initialise le hachage initiale
mov dword[hachage+00],0c1059ed8h
mov dword[hachage+04],0cbbb9d5dh
mov dword[hachage+08],0367cd507h
mov dword[hachage+12],0629a292ah
mov dword[hachage+16],03070dd17h
mov dword[hachage+20],09159015ah
mov dword[hachage+24],0f70e5939h
mov dword[hachage+28],0152fecd8h
mov dword[hachage+32],0ffc00b31h
mov dword[hachage+36],067332667h
mov dword[hachage+40],068581511h
mov dword[hachage+44],08eb44a87h
mov dword[hachage+48],064f98fa7h
mov dword[hachage+52],0db0c2e0dh
mov dword[hachage+56],0befa4fa4h
mov dword[hachage+60],047b5481dh
jmp boucle_sha512





;************************
calc_SHA512:
push dword 512
push edi

;calcul le nombre de bloc de 128 octet
mov [taille_SHA],ecx
mov ebp,ecx
add ebp,17+127
shr ebp,7

;initialise le hachage initiale
mov dword[hachage+00],0f3bcc908h
mov dword[hachage+04],06a09e667h
mov dword[hachage+08],084caa73bh
mov dword[hachage+12],0bb67ae85h
mov dword[hachage+16],0fe94f82bh
mov dword[hachage+20],03c6ef372h
mov dword[hachage+24],05f1d36f1h
mov dword[hachage+28],0a54ff53ah
mov dword[hachage+32],0ade682d1h
mov dword[hachage+36],0510e527fh
mov dword[hachage+40],02b3e6c1fh
mov dword[hachage+44],09b05688ch
mov dword[hachage+48],0fb41bd6bh
mov dword[hachage+52],01f83d9abh
mov dword[hachage+56],0137e2179h
mov dword[hachage+60],05be0cd19h
;jmp boucle_sha512

;https://github.com/RealFoxerity/tls13/blob/master/crypto/sha2_consts.c


;*******
boucle_sha512:
mov edi,variables_sha2
cmp ecx,-1 
je sha512_bloc_taille
cmp ecx,0 
je sha512_bloc_final
cmp ecx,128
jae sha512_bloc_complet


;si il rest moins de 128 octets on remplis le bloc avec du remplissage
mov edx,ecx
cld
rep movsb
mov al,080h  ;on met un octet 80h a la fin
stosb

mov ecx,-1
;on replit jusqu'a zero la fin du bloc
@@:
cmp edi,variables_sha2+128
je @f
mov byte[edi],0
inc edi
jmp @b

@@:
cmp edx,112 
jae sha512_fincopiebloc

mov eax,[taille_SHA]
shl eax,3
bswap eax
mov  [variables_sha2+124],eax
jmp sha512_fincopiebloc


;*****
sha512_bloc_final:
mov byte[edi],80h
inc edi

;********
sha512_bloc_taille:
cmp edi,variables_sha2+128
je @f
mov byte[edi],0
inc edi
jmp sha512_bloc_taille
@@:

mov eax,[taille_SHA]
shl eax,3
bswap eax
mov  [variables_sha2+124],eax
jmp sha512_fincopiebloc


;si il reste + de 128 octets: copie 128 octet et decremente ecx
sha512_bloc_complet:
push ecx
mov ecx,32
cld
rep movsd
pop ecx
sub ecx,128
sha512_fincopiebloc:



pushad
;mise du bloc en doublemot de 32bits little endian
mov esi,variables_sha2
@@:
mov eax,[esi]
mov edx,[esi+4]
bswap eax
bswap edx
mov [esi+4],eax
mov [esi],edx
add esi,8
cmp esi,variables_sha2+128
jne @b



;boucle calcul de w16 à w63 ***************************************
mov esi,variables_sha2
boucle_calc_ws512:

mov eax,[esi]   ;w+0 (16)
mov ebx,[esi+4]
mov [esi+128],eax ;w+16 (0)
mov [esi+132],ebx


mov eax,[esi+8] ;w+1 (15)
mov ebx,[esi+12]
mov cl,1
call ror512
mov edx,eax
mov edi,ebx
mov eax,[esi+8] ;w+1 (15)
mov ebx,[esi+12]
mov cl,8
call ror512
xor edx,eax
xor edi,ebx
mov eax,[esi+8] ;w+1 (15)
mov ebx,[esi+12]
mov cl,7
call shr512
xor edx,eax
xor edi,ebx
add [esi+128],edx ;w+16 (0)
adc [esi+132],edi


mov eax,[esi+72] ;w+9 (7)
mov ebx,[esi+76]
add [esi+128],eax ;w+16 (0)
adc [esi+132],ebx


mov eax,[esi+112] ;w+14 (2)
mov ebx,[esi+116]
mov cl,19
call ror512
mov edx,eax
mov edi,ebx
mov eax,[esi+112] ;w+14 (2)
mov ebx,[esi+116]
mov cl,61
call ror512
xor edx,eax
xor edi,ebx
mov eax,[esi+112] ;w+14 (2)
mov ebx,[esi+116]
mov cl,6
call shr512
xor edx,eax
xor edi,ebx
add [esi+128],edx ;w+16 (0)
adc [esi+132],edi


add esi,8
cmp esi,variables_sha2+512
jne boucle_calc_ws512



;chargement valeurs initiales A-H******************************
mov esi,hachage
mov edi,A_sha2
mov ecx,16
cld
rep movsd



;boucle calcul A-H progressif ******************************************
xor esi,esi
boucle_calc_wk512:

;temp1
mov eax,[H_sha2]
mov ebx,[H_sha2+4]
mov [temp1_sha2],eax 
mov [temp1_sha2+4],ebx 

mov eax,[E_sha2]
mov ebx,[E_sha2+4]
mov cl,14
call ror512
mov edx,eax
mov edi,ebx
mov eax,[E_sha2]
mov ebx,[E_sha2+4]
mov cl,18
call ror512
xor edx,eax
xor edi,ebx
mov eax,[E_sha2]
mov ebx,[E_sha2+4]
mov cl,41
call ror512
xor edx,eax
xor edi,ebx
add [temp1_sha2],edx 
adc [temp1_sha2+4],edi 

mov eax,[E_sha2]
mov ebx,[E_sha2+4]
not eax
not ebx
and eax,[G_sha2]
and ebx,[G_sha2+4]
mov edx,[E_sha2]
mov edi,[E_sha2+4]
and edx,[F_sha2]
and edi,[F_sha2+4]
xor eax,edx
xor ebx,edi
add [temp1_sha2],eax 
adc [temp1_sha2+4],ebx 


mov eax,[esi+constantes_sha512+4]
mov ebx,[esi+constantes_sha512]
add [temp1_sha2],eax 
adc [temp1_sha2+4],ebx 

mov eax,[esi+variables_sha2]
mov ebx,[esi+variables_sha2+4]
add [temp1_sha2],eax 
adc [temp1_sha2+4],ebx 


;temp2
mov eax,[A_sha2]
mov ebx,[A_sha2+4]
and eax,[B_sha2]
and ebx,[B_sha2+4]
mov edx,[A_sha2]
mov edi,[A_sha2+4]
and edx,[C_sha2]
and edi,[C_sha2+4]
xor eax,edx
xor ebx,edi
mov edx,[B_sha2]
mov edi,[B_sha2+4]
and edx,[C_sha2]
and edi,[C_sha2+4]
xor eax,edx
xor ebx,edi
mov [temp2_sha2],eax 
mov [temp2_sha2+4],ebx 

mov eax,[A_sha2]
mov ebx,[A_sha2+4]
mov cl,28
call ror512 
mov edx,eax
mov edi,ebx
mov eax,[A_sha2]
mov ebx,[A_sha2+4]
mov cl,34
call ror512 
xor edx,eax
xor edi,ebx
mov eax,[A_sha2]
mov ebx,[A_sha2+4]
mov cl,39
call ror512 
xor edx,eax
xor edi,ebx
add [temp2_sha2],edx 
adc [temp2_sha2+4],edi 

;H
mov eax,[G_sha2] 
mov ebx,[G_sha2+4] 
mov [H_sha2],eax
mov [H_sha2+4],ebx

;G
mov eax,[F_sha2]
mov ebx,[F_sha2+4]
mov [G_sha2],eax
mov [G_sha2+4],ebx

;F
mov eax,[E_sha2]
mov ebx,[E_sha2+4]
mov [F_sha2],eax
mov [F_sha2+4],ebx

;E
mov eax,[D_sha2]
mov ebx,[D_sha2+4]
add eax,[temp1_sha2]
adc ebx,[temp1_sha2+4]
mov [E_sha2],eax
mov [E_sha2+4],ebx

;D
mov eax,[C_sha2]
mov ebx,[C_sha2+4]
mov [D_sha2],eax
mov [D_sha2+4],ebx

;C
mov eax,[B_sha2]
mov ebx,[B_sha2+4]
mov [C_sha2],eax
mov [C_sha2+4],ebx

;B
mov eax,[A_sha2]
mov ebx,[A_sha2+4]
mov [B_sha2],eax
mov [B_sha2+4],ebx

;A
mov eax,[temp1_sha2]
mov ebx,[temp1_sha2+4]
add eax,[temp2_sha2]
adc ebx,[temp2_sha2+4]
mov [A_sha2],eax
mov [A_sha2+4],ebx

add esi,8
cmp esi,640
jne boucle_calc_wk512



;
mov eax,[A_sha2]
mov ebx,[A_sha2+4]
add [hachage],eax
adc [hachage+4],ebx

mov eax,[B_sha2]
mov ebx,[B_sha2+4]
add [hachage+8],eax
add [hachage+12],ebx

mov eax,[C_sha2]
mov ebx,[C_sha2]
add [hachage+16],eax
adc [hachage+20],ebx

mov eax,[D_sha2]
mov ebx,[D_sha2+4]
add [hachage+24],eax
adc [hachage+28],ebx

mov eax,[E_sha2]
mov ebx,[E_sha2+4]
add [hachage+32],eax
adc [hachage+36],ebx

mov eax,[F_sha2]
mov ebx,[F_sha2+4]
add [hachage+40],eax
adc [hachage+44],eax

mov eax,[G_sha2]
mov ebx,[G_sha2+4]
add [hachage+48],eax
adc [hachage+52],ebx

mov eax,[H_sha2]
mov ebx,[H_sha2+4]
add [hachage+56],eax
add [hachage+60],ebx

popad
dec ebp
jnz boucle_sha512


;copie de la chaine de hachage calculé***********************
pop edi
pop ecx
mov eax,[hachage]
mov ebx,[hachage+4]
bswap eax
bswap ebx
mov [edi+4],eax
mov [edi],ebx
mov eax,[hachage+8]
mov ebx,[hachage+12]
bswap eax
bswap ebx
mov [edi+12],eax
mov [edi+8],ebx
mov eax,[hachage+16]
mov ebx,[hachage+20]
bswap eax
bswap ebx
mov [edi+20],eax
mov [edi+16],ebx
mov eax,[hachage+24]
mov ebx,[hachage+28]
bswap eax
bswap ebx
mov [edi+28],eax
mov [edi+24],ebx
mov eax,[hachage+32]
mov ebx,[hachage+36]
bswap eax
bswap ebx
mov [edi+36],eax
mov [edi+32],ebx
mov eax,[hachage+40]
mov ebx,[hachage+44]
bswap eax
bswap ebx
mov [edi+44],eax
mov [edi+40],ebx
mov eax,[hachage+48]
mov ebx,[hachage+52]
bswap eax
bswap ebx
mov [edi+52],eax
mov [edi+48],ebx
cmp ecx,512
jne @f
mov eax,[hachage+56]
mov ebx,[hachage+60]
bswap eax
bswap ebx
mov [edi+60],eax
mov [edi+56],ebx
@@:
xor eax,eax
ret










;******************************************
ror512: ;effectue un ror de cl bit sur le mot de 64bit eax(lsb) et ebx(msb)
bt eax,0
rcr ebx,1
rcr eax,1
dec cl
jnz ror512
ret


shr512: ;effectue un shr de cl bit sur le mot de 64bit eax(lsb) et ebx(msb)
clc
rcr ebx,1
rcr eax,1
dec cl
jnz shr512
ret




