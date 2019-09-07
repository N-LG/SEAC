SF_PERI.ASM:         ;fonction effectué périodiquement par la tache principale

mov ax,seldat
mov ds,ax
test byte[at_fc_fichier],04h   ;on test si le moteur disquette est allumé
jz pasarretmoteurdisquette 
mov eax,[temp_moteur_disq]
cmp [cptsf],eax
jna pasarretmoteurdisquette
mov dx,3F2h   ;délais dépassé, on eteint le moteur
mov al,04h
out dx,al
and byte[at_fc_fichier],0FBh   ;on signal que le moteur de la disquette est éteint
pasarretmoteurdisquette:

;********************************



hlt
int 62h















