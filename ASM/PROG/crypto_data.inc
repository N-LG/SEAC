;include pour fonction de chiffrement(données)
;voir dans crypto_code.inc


 
table_permut_aes:
db 063h,07Ch,077h,07Bh,0F2h,06Bh,06Fh,0C5h,030h,001h,067h,02Bh,0FEh,0D7h,0ABh,076h
db 0CAh,082h,0C9h,07Dh,0FAh,059h,047h,0F0h,0ADh,0D4h,0A2h,0AFh,09Ch,0A4h,072h,0C0h
db 0B7h,0FDh,093h,026h,036h,03Fh,0F7h,0CCh,034h,0A5h,0E5h,0F1h,071h,0D8h,031h,015h
db 004h,0C7h,023h,0C3h,018h,096h,005h,09Ah,007h,012h,080h,0E2h,0EBh,027h,0B2h,075h
db 009h,083h,02Ch,01Ah,01Bh,06Eh,05Ah,0A0h,052h,03Bh,0D6h,0B3h,029h,0E3h,02Fh,084h
db 053h,0D1h,000h,0EDh,020h,0FCh,0B1h,05Bh,06Ah,0CBh,0BEh,039h,04Ah,04Ch,058h,0CFh
db 0D0h,0EFh,0AAh,0FBh,043h,04Dh,033h,085h,045h,0F9h,002h,07Fh,050h,03Ch,09Fh,0A8h
db 051h,0A3h,040h,08Fh,092h,09dh,038h,0F5h,0BCh,0B6h,0DAh,021h,010h,0FFh,0F3h,0D2h
db 0CDh,00Ch,013h,0ECh,05Fh,097h,044h,017h,0C4h,0A7h,07Eh,03Dh,064h,05Dh,019h,073h
db 060h,081h,04Fh,0DCh,022h,02Ah,090h,088h,046h,0EEh,0B8h,014h,0DEh,05Eh,00Bh,0DBh
db 0E0h,032h,03Ah,00Ah,049h,006h,024h,05Ch,0C2h,0D3h,0ACh,062h,091h,095h,0E4h,079h
db 0E7h,0C8h,037h,06Dh,08Dh,0D5h,04Eh,0A9h,06Ch,056h,0F4h,0EAh,065h,07Ah,0AEh,008h
db 0BAh,078h,025h,02Eh,01Ch,0A6h,0B4h,0C6h,0E8h,0DDh,074h,01Fh,04Bh,0BDh,08Bh,08Ah
db 070h,03Eh,0B5h,066h,048h,003h,0F6h,00Eh,061h,035h,057h,0B9h,086h,0C1h,01Dh,09Eh
db 0E1h,0F8h,098h,011h,069h,0D9h,08Eh,094h,09Bh,01Eh,087h,0E9h,0CEh,055h,028h,0DFh
db 08Ch,0A1h,089h,00Dh,0BFh,0E6h,042h,068h,041h,099h,02Dh,00Fh,0B0h,054h,0BBh,016h


table_rev_permut_aes:
db 052h,009h,06Ah,0D5h,030h,036h,0A5h,038h,0BFh,040h,0A3h,09Eh,081h,0F3h,0D7h,0FBh
db 07Ch,0E3h,039h,082h,09Bh,02Fh,0FFh,087h,034h,08Eh,043h,044h,0C4h,0DEh,0E9h,0CBh
db 054h,07Bh,094h,032h,0A6h,0C2h,023h,03Dh,0EEh,04Ch,095h,00Bh,042h,0FAh,0C3h,04Eh
db 008h,02Eh,0A1h,066h,028h,0D9h,024h,0B2h,076h,05Bh,0A2h,049h,06Dh,08Bh,0D1h,025h
db 072h,0F8h,0F6h,064h,086h,068h,098h,016h,0D4h,0A4h,05Ch,0CCh,05Dh,065h,0B6h,092h
db 06Ch,070h,048h,050h,0FDh,0EDh,0B9h,0DAh,05Eh,015h,046h,057h,0A7h,08Dh,09Dh,084h
db 090h,0D8h,0ABh,000h,08Ch,0BCh,0D3h,00Ah,0F7h,0E4h,058h,005h,0B8h,0B3h,045h,006h
db 0D0h,02Ch,01Eh,08Fh,0CAh,03Fh,00Fh,002h,0C1h,0AFh,0BDh,003h,001h,013h,08Ah,06Bh
db 03Ah,091h,011h,041h,04Fh,067h,0DCh,0EAh,097h,0F2h,0CFh,0CEh,0F0h,0B4h,0E6h,073h
db 096h,0ACh,074h,022h,0E7h,0ADh,035h,085h,0E2h,0F9h,037h,0E8h,01Ch,075h,0DFh,06Eh
db 047h,0F1h,01Ah,071h,01Dh,029h,0C5h,089h,06Fh,0B7h,062h,00Eh,0AAh,018h,0BEh,01Bh
db 0FCh,056h,03Eh,04Bh,0C6h,0D2h,079h,020h,09Ah,0DBh,0C0h,0FEh,078h,0CDh,05Ah,0F4h
db 01Fh,0DDh,0A8h,033h,088h,007h,0C7h,031h,0B1h,012h,010h,059h,027h,080h,0ECh,05Fh
db 060h,051h,07Fh,0A9h,019h,0B5h,04Ah,00Dh,02Dh,0E5h,07Ah,09Fh,093h,0C9h,09Ch,0EFh
db 0A0h,0E0h,03Bh,04Dh,0AEh,02Ah,0F5h,0B0h,0C8h,0EBh,0BBh,03Ch,083h,053h,099h,061h
db 017h,02Bh,004h,07Eh,0BAh,077h,0D6h,026h,0E1h,069h,014h,063h,055h,021h,00Ch,07Dh

var0:
dd 0
var1:
dd 0
var2:
dd 0
var3:
dd 0


init_vec:
rb 16
bloc_tampon:
rb 16

nb_tours_AES:
dd 0
clef_complete:
rb 256          ;160 192 224 octet



;***************************************************************************************************************
taille_SHA:
dd 0,0
A_sha2:
dd 0,0
B_sha2:
dd 0,0
C_sha2:
dd 0,0
D_sha2:
dd 0,0
E_sha2:
dd 0,0
F_sha2:
dd 0,0
G_sha2:
dd 0,0
H_sha2:
dd 0,0
temp1_sha2:
dd 0,0
temp2_sha2:
dd 0,0
hachage:
rb 64







constantes_sha256:
dd 0428a2f98h,071374491h,0b5c0fbcfh,0e9b5dba5h
dd 03956c25bh,059f111f1h,0923f82a4h,0ab1c5ed5h
dd 0d807aa98h,012835b01h,0243185beh,0550c7dc3h
dd 072be5d74h,080deb1feh,09bdc06a7h,0c19bf174h
dd 0e49b69c1h,0efbe4786h,00fc19dc6h,0240ca1cch
dd 02de92c6fh,04a7484aah,05cb0a9dch,076f988dah
dd 0983e5152h,0a831c66dh,0b00327c8h,0bf597fc7h
dd 0c6e00bf3h,0d5a79147h,006ca6351h,014292967h
dd 027b70a85h,02e1b2138h,04d2c6dfch,053380d13h
dd 0650a7354h,0766a0abbh,081c2c92eh,092722c85h
dd 0a2bfe8a1h,0a81a664bh,0c24b8b70h,0c76c51a3h
dd 0d192e819h,0d6990624h,0f40e3585h,0106aa070h
dd 019a4c116h,01e376c08h,02748774ch,034b0bcb5h
dd 0391c0cb3h,04ed8aa4ah,05b9cca4fh,0682e6ff3h
dd 0748f82eeh,078a5636fh,084c87814h,08cc70208h
dd 090befffah,0a4506cebh,0bef9a3f7h,0c67178f2h

;les nombre 64 bit sont séparé en 2 nombres 32bits avec le MSB en premier (parce que c'est moin chiant a recopier)
constantes_sha512:
dd 0428a2f98h,0d728ae22h,071374491h,023ef65cdh,0b5c0fbcfh,0ec4d3b2fh,0e9b5dba5h,08189dbbch
dd 03956c25bh,0f348b538h,059f111f1h,0b605d019h,0923f82a4h,0af194f9bh,0ab1c5ed5h,0da6d8118h
dd 0d807aa98h,0a3030242h,012835b01h,045706fbeh,0243185beh,04ee4b28ch,0550c7dc3h,0d5ffb4e2h
dd 072be5d74h,0f27b896fh,080deb1feh,03b1696b1h,09bdc06a7h,025c71235h,0c19bf174h,0cf692694h
dd 0e49b69c1h,09ef14ad2h,0efbe4786h,0384f25e3h,00fc19dc6h,08b8cd5b5h,0240ca1cch,077ac9c65h
dd 02de92c6fh,0592b0275h,04a7484aah,06ea6e483h,05cb0a9dch,0bd41fbd4h,076f988dah,0831153b5h
dd 0983e5152h,0ee66dfabh,0a831c66dh,02db43210h,0b00327c8h,098fb213fh,0bf597fc7h,0beef0ee4h
dd 0c6e00bf3h,03da88fc2h,0d5a79147h,0930aa725h,006ca6351h,0e003826fh,014292967h,00a0e6e70h
dd 027b70a85h,046d22ffch,02e1b2138h,05c26c926h,04d2c6dfch,05ac42aedh,053380d13h,09d95b3dfh
dd 0650a7354h,08baf63deh,0766a0abbh,03c77b2a8h,081c2c92eh,047edaee6h,092722c85h,01482353bh
dd 0a2bfe8a1h,04cf10364h,0a81a664bh,0bc423001h,0c24b8b70h,0d0f89791h,0c76c51a3h,00654be30h
dd 0d192e819h,0d6ef5218h,0d6990624h,05565a910h,0f40e3585h,05771202ah,0106aa070h,032bbd1b8h
dd 019a4c116h,0b8d2d0c8h,01e376c08h,05141ab53h,02748774ch,0df8eeb99h,034b0bcb5h,0e19b48a8h
dd 0391c0cb3h,0c5c95a63h,04ed8aa4ah,0e3418acbh,05b9cca4fh,07763e373h,0682e6ff3h,0d6b2b8a3h
dd 0748f82eeh,05defb2fch,078a5636fh,043172f60h,084c87814h,0a1f0ab72h,08cc70208h,01a6439ech
dd 090befffah,023631e28h,0a4506cebh,0de82bde9h,0bef9a3f7h,0b2c67915h,0c67178f2h,0e372532bh
dd 0ca273eceh,0ea26619ch,0d186b8c7h,021c0c207h,0eada7dd6h,0cde0eb1eh,0f57d4f7fh,0ee6ed178h
dd 006f067aah,072176fbah,00a637dc5h,0a2c898a6h,0113f9804h,0bef90daeh,01b710b35h,0131c471bh
dd 028db77f5h,023047d84h,032caab7bh,040c72493h,03c9ebe0ah,015c9bebch,0431d67c4h,09c100d4ch
dd 04cc5d4beh,0cb3e42b6h,0597f299ch,0fc657e2ah,05fcb6fabh,03ad6faech,06c44198ch,04a475817h




variables_sha2:
rb 640




