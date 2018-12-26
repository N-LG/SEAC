dn_acc:
;table de combinaison entre les suites d'une chasse et le caractère associé pour produire des caractères accentué
;4o=caractère de chasse 4o=lettre simple 4o=caractère resultant

dd 060h,041h,0C0h ;À	
dd 0B4h,041h,0C1h ;Á	
dd 05Eh,041h,0C2h ;Â	
dd 07Eh,041h,0C3h ;Ã
dd 0A8h,041h,0C4h ;Ä 
dd 2DAh,041h,0C5h ;Å		
dd 0B8h,043h,0C7h ;Ç
dd 060h,045h,0C8h ;È 				
dd 0B4h,045h,0C9h ;É		
dd 05Eh,045h,0CAh ;Ê	
dd 0A8h,045h,0CBh ;Ë  
dd 060h,049h,0CCh ;Ì				
dd 0B4h,049h,0CDh ;Í		
dd 05Eh,049h,0CEh ;Î	
dd 0A8h,049h,0CFh ;Ï   
dd 07Eh,04Eh,0D1h ;Ñ	
dd 060h,04Fh,0D2h ;Ò	
dd 0B4h,04Fh,0D3h ;Ó	
dd 05Eh,04Fh,0D4h ;Ô	
dd 07Eh,04Fh,0D5h ;Õ 
dd 0A8h,04Fh,0D6h ;Ö  
dd 060h,055h,0D9h ;Ù	
dd 0B4h,055h,0DAh ;Ú	
dd 05Eh,055h,0DBh ;Û	
dd 0A8h,055h,0DCh ;Ü	
dd 0B4h,059h,0DDh ;Ý		
dd 060h,061h,0E0h ;à	
dd 0B4h,061h,0E1h ;á	
dd 05Eh,061h,0E2h ;â	
dd 07Eh,061h,0E3h ;ã
dd 0A8h,061h,0E4h ;ä
dd 2DAh,061h,0E5h ;å		
dd 0B8h,063h,0E7h ;ç 
dd 060h,065h,0E8h ;è 				
dd 0B4h,065h,0E9h ;é 		
dd 05Eh,065h,0EAh ;ê	
dd 0A8h,065h,0EBh ;ë
dd 060h,069h,0ECh ;ì				
dd 0B4h,069h,0EDh ;í		
dd 05Eh,069h,0EEh ;î	
dd 0A8h,069h,0EFh ;ï
dd 07Eh,06Eh,0F1h ;ñ	
dd 060h,06Fh,0F2h ;ò	
dd 0B4h,06Fh,0F3h ;ó	
dd 05Eh,06Fh,0F4h ;ô	
dd 07Eh,06Fh,0F5h ;õ
dd 0A8h,06Fh,0F6h ;ö
dd 060h,075h,0F9h ;ù 	
dd 0B4h,075h,0FAh ;ú	
dd 05Eh,075h,0FBh ;û	
dd 0A8h,075h,0FCh ;ü	
dd 0B4h,079h,0FDh ;ý		
dd 0A8h,079h,0FFh ;ÿ 
dd 0A8h,059h,178h ;Ÿ



;*******************************************************
;rajout non officiels

dd 0A4h,041h,0C6h ;Æ  ;rajout non officiel avec le caractère monétaire comme chasse
dd 0A4h,061h,0E6h ;æ
dd 0A4h,04Fh,152h ;Œ
dd 0A4h,06Fh,153h ;œ
dd 0A4h,073h,17Fh ;ſ
dd 0A4h,053h,0DFh ;ß
dd 0A4h,02Fh,0F7h ;÷
dd 2DAh,04Fh,0D8h ;Ø  ;rajout non officiel avec le l'accent rond
dd 2DAh,06Fh,0F8h ;ø


dd 0
