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
enc_AES_CTR:
dec_AES_CTR:
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
mov eax,[init_vec+12]
mov edx,[init_vec+8]
bswap eax
bswap edx
inc eax
adc edx,0
bswap eax
bswap edx
mov [init_vec+12],eax
mov [init_vec+8],edx

mov eax,[init_vec+4]
mov edx,[init_vec]
bswap eax
bswap edx
adc eax,0
adc edx,0
bswap eax
bswap edx
mov [init_vec+4],eax
mov [init_vec],edx


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

calc_SHA256:
push edi

;calcul le nombre de bloc de 64 octet
mov [taille_SHA],ecx
mov ebp,ecx
add ebp,9+63
shr ebp,6
inc ecx  ;pour inclure l'octet a 80h

;initialise le hachage initiale
mov dword[hachage+00],06a09e667h
mov dword[hachage+04],0bb67ae85h
mov dword[hachage+08],03c6ef372h
mov dword[hachage+12],0a54ff53ah
mov dword[hachage+16],0510e527fh
mov dword[hachage+20],09b05688ch
mov dword[hachage+24],01f83d9abh
mov dword[hachage+28],05be0cd19h


boucle_sha256:

mov edi,variables_sha256
cmp ecx,0
je @f
cmp ecx,64
ja sha256_copiebloc

dec ecx
push ecx
cld
rep movsb
mov al,080h
stosb
pop ecx

@@:
cmp edi,variables_sha256+64
je @f
mov byte[edi],0
inc edi
jmp @b


@@:
mov eax,ecx
xor ecx,ecx
cmp eax,56
jae sha256_fincopiebloc

mov eax,[taille_SHA]
shl eax,3
bswap eax
mov  [variables_sha256+60],eax
jmp sha256_fincopiebloc



;si il reste + de 64 octets: copie 64 octet et decremente ecx
sha256_copiebloc:
push ecx
mov ecx,16
cld
rep movsd
pop ecx
sub ecx,64
sha256_fincopiebloc:




pushad
;mise du bloc en doublemot de 32bits little endian
mov esi,variables_sha256
@@:
mov eax,[esi]
bswap eax
mov [esi],eax
add esi,4
cmp esi,variables_sha256+64
jne @b



;boucle calcul de w16 à w63 ****************************************
mov esi,variables_sha256
boucle_calc_ws:

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
cmp esi,variables_sha256+192
jne boucle_calc_ws



;chargement valeurs initiales A-H
mov esi,hachage
mov edi,A_sha256
mov ecx,8
cld
rep movsd



;boucle calcul A-H progressif ******************************************
xor esi,esi
boucle_calc_wk:

;temp1
mov eax,[H_sha256]
mov [temp1_sha256],eax 

mov edx,[E_sha256]
ror edx,6
mov eax,[E_sha256]
ror eax,11
xor edx,eax
mov eax,[E_sha256]
ror eax,25
xor edx,eax
add [temp1_sha256],edx 

mov eax,[E_sha256]
not eax
and eax,[G_sha256]
mov edx,[E_sha256]
and edx,[F_sha256]
xor eax,edx
add [temp1_sha256],eax 

mov edx,[esi+constantes_sha256]
add [temp1_sha256],edx 

mov eax,[esi+variables_sha256]
add [temp1_sha256],eax 

;temp2
mov eax,[A_sha256]
and eax,[B_sha256]
mov edx,[A_sha256]
and edx,[C_sha256]
xor eax,edx
mov edx,[B_sha256]
and edx,[C_sha256]
xor eax,edx
mov [temp2_sha256],eax 

mov edx,[A_sha256]
ror edx,2
mov eax,[A_sha256]
ror eax,13
xor edx,eax
mov eax,[A_sha256]
ror eax,22
xor edx,eax
add [temp2_sha256],edx 

;H
mov eax,[G_sha256] 
mov [H_sha256],eax

;G
mov eax,[F_sha256]
mov [G_sha256],eax

;F
mov eax,[E_sha256]
mov [F_sha256],eax

;E
mov eax,[D_sha256]
add eax,[temp1_sha256]
mov [E_sha256],eax

;D
mov eax,[C_sha256]
mov [D_sha256],eax

;C
mov eax,[B_sha256]
mov [C_sha256],eax

;B
mov eax,[A_sha256]
mov [B_sha256],eax

;A
mov eax,[temp1_sha256]
add eax,[temp2_sha256]
mov [A_sha256],eax

add esi,4
cmp esi,256
jne boucle_calc_wk


mov eax,[A_sha256]
add [hachage],eax
mov eax,[B_sha256]
add [hachage+4],eax
mov eax,[C_sha256]
add [hachage+8],eax
mov eax,[D_sha256]
add [hachage+12],eax
mov eax,[E_sha256]
add [hachage+16],eax
mov eax,[F_sha256]
add [hachage+20],eax
mov eax,[G_sha256]
add [hachage+24],eax
mov eax,[H_sha256]
add [hachage+28],eax

popad
dec ebp
jnz boucle_sha256

;copie de la chaine de hachage calculé
pop edi
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
mov eax,[hachage+28]
bswap eax
mov [edi+28],eax

xor eax,eax
ret

