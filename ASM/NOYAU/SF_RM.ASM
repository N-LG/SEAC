;************************************************************************************
;appel des fonctions BIOS via un retour provisoire en mode r�el
;(le mode prot�g� du VESA 3.0 �tant trop bugg� sur certaine carte et pas support� sur d'autres)




;************************************************************
vesa_infomode: ;charge les info du mode video dont le code est dans cx
push ebx
push ecx
push edx
push esi
push edi
push ebp
push ds
push es
push fs
push gs

mov ax,seldat
mov ds,ax
mov dword[cmd_bios],4F01h
mov di,infovesa

jmp selcod16:appel_mode_reel_vesa



;***********************************************************
vesa_mode: ;change le mode vid�o pour celui dans cx
push ebx
push ecx
push edx
push esi
push edi
push ebp
push ds
push es
push fs
push gs

mov ax,seldat
mov ds,ax
mov dword[cmd_bios],4F02h
mov bx,cx
and cx,041FFh   ;uniquement les modes et le choix du lfb

jmp selcod16:appel_mode_reel_vesa


;***********************************************************
vesa_mem:
push ebx
push ecx
push edx
push esi
push edi
push ebp
push ds
push es
push fs
push gs

mov ax,seldat
mov ds,ax
mov dword[cmd_bios],4F05h
mov bx,0        ;changer la bank video en A0000h

jmp selcod16:appel_mode_reel_vesa










;**********************************************************
retourvesa:
push ax         
mov al,20h    ;aquitement des pic
out 0A0h,al
mov al,20h
out 20h,al

mov dx,21h             ;regle le masquage des irq
mov al,0A0h            ;masque les irq 5&7
out dx,al
mov dx,0A1h
mov al,0EFh            ;masque les irq 8?11 et 13?15
out dx,al
pop ax

mov dx,seldat      ;init pile et data
mov ds,dx
mov es,dx
mov fs,dx
mov gs,dx
mov dx,selpil
mov ss,dx

sti
pop gs
pop fs
pop es
pop ds
pop ebp
pop edi
pop esi
pop edx
pop ecx
pop ebx
ret


;*************************************************************************************
use16                       ;partie du code s'executant en mode prot�g� 16 bit

appel_mode_reel_vesa:
cli
push dx
mov dx,21h             ;regle le masquage des irq
mov al,0FFh            ;masque tout
out dx,al
mov dx,0A1h
mov al,0FFh            ;masque tout
out dx,al
pop dx

mov eax,cr0
and eax,0FFFFFFFEh
jmp $+2
mov cr0,eax
jmp segcod:mode_reel_vesa


appel_mode_reel_bios:
cli
push dx
mov dx,21h             ;regle le masquage des irq
mov al,0FFh            ;masque tout
out dx,al
mov dx,0A1h
mov al,0FFh            ;masque tout
out dx,al
pop dx

mov eax,cr0
and eax,0FFFFFFFEh
jmp $+2
mov cr0,eax
jmp segcod:mode_reel_bios

reboot:
cli
mov eax,cr0
and eax,0FFFFFFFEh
jmp $+2
mov cr0,eax
jmp 0FFFFh:0000h


;********************************************************************************
                                                 ;partie s'executant en mode r�el:





mode_reel_vesa:
mov ax,segcod      ;charge l'idt du mode r�el
mov ds,ax
lidt [r_idt]

mov ax,segdat      ;init pile et data
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ax,segpil
mov ss,ax

mov eax,[cmd_bios]
int 10h  

mov dx,segcod      ;charge l'idt du mode prot�g�
mov ds,dx
lidt [p_idt]
mov edx,cr0
or edx,1
jmp $+2
mov cr0,edx
jmp selcod:retourvesa




mode_reel_bios:
mov bx,segcod      ;charge l'idt du mode r�el
mov ds,bx
lidt [r_idt]

mov bx,segdat      ;init pile et data
mov ds,bx
mov es,bx
mov fs,bx
mov gs,bx
mov bx,segpil
mov ss,bx

int 13h           ;on d�sactive pour le moment �a bug de trop 
xor ax,ax
jnc errint13
mov ax,1
errint13:

mov dx,segcod      ;charge l'idt du mode prot�g�
mov ds,dx
lidt [p_idt]
mov edx,cr0
or edx,1
jmp $+2
mov cr0,edx
jmp selcod:retourvesa






use32 