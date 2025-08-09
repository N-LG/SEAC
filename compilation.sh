echo off
echo compilation du systeme


#compilation des outils
fasm OUTILS/ajarchl.asm ajarch


#compilation des applications
#fasm ASM/FASM/SEAC/FASM_FR.ASM BIN/FASM.FE
#fasm ASM/FASM/SEAC/FASM.ASM BIN/FASM.FE
fasm ASM/PROG/date.asm BIN/DATE.FE
fasm ASM/PROG/edt.asm BIN/EDT.FE
fasm ASM/PROG/edh.asm BIN/EDH.FE
fasm ASM/PROG/edg.asm BIN/EDG.FE
fasm ASM/PROG/ics.asm BIN/ICS.FE
fasm ASM/PROG/partd.asm BIN/PARTD.FE
fasm ASM/PROG/lspci.asm BIN/LSPCI.FE
fasm ASM/PROG/lsusb.asm BIN/LSUSB.FE
fasm ASM/PROG/term.asm BIN/TERM.FE
fasm ASM/PROG/circ.asm BIN/CIRC.FE
fasm ASM/PROG/cdns.asm BIN/CDNS.FE
fasm ASM/PROG/chttp.asm BIN/CHTTP.FE
fasm ASM/PROG/cftp.asm BIN/CFTP.FE
fasm ASM/PROG/ctftp.asm BIN/CTFTP.FE
fasm ASM/PROG/whois.asm BIN/WHOIS.FE
fasm ASM/PROG/sdns.asm BIN/SDNS.FE
fasm ASM/PROG/ping.asm BIN/PING.FE
fasm ASM/PROG/trace.asm BIN/TRACE.FE
fasm ASM/PROG/scanip.asm BIN/SCANIP.FE
fasm ASM/PROG/expl.asm BIN/EXPL.FE
fasm ASM/PROG/voir.asm BIN/VOIR.FE
fasm ASM/PROG/utf8.asm BIN/UTF8.FE
fasm ASM/PROG/calc.asm BIN/CALC.FE
fasm ASM/PROG/ipconfig.asm BIN/IPCONFIG.FE
fasm ASM/PROG/shttp.asm BIN/SHTTP.FE
fasm ASM/PROG/stftp.asm BIN/STFTP.FE
fasm ASM/PROG/stlnt.asm BIN/STLNT.FE
fasm ASM/PROG/spxe.asm BIN/SPXE.FE
fasm ASM/PROG/cdg.asm BIN/CDG.FE
fasm ASM/PROG/snif.asm BIN/SNIF.FE
fasm ASM/PROG/man.asm BIN/MAN.FE
fasm ASM/PROG/help.asm BIN/HELP.FE
fasm ASM/PROG/ajarch.asm BIN/AJARCH.FE
fasm ASM/PROG/dcp.asm BIN/DCP.FE
fasm ASM/PROG/pilote.asm BIN/PILOTE.FE
fasm ASM/PROG/RTL8139.asm BIN/RTL8139.FE
fasm ASM/PROG/RTL8169.asm BIN/RTL8169.FE
fasm ASM/PROG/BCM5755.asm BIN/BCM5755.FE
fasm ASM/PROG/3C90X.asm BIN/3C90X.FE
fasm ASM/PROG/I8254X.asm BIN/I8254X.FE
fasm ASM/PROG/jn1.asm BIN/JN1.FE
fasm ASM/PROG/snake.asm BIN/SNAKE.FE
fasm ASM/PROG/palette.asm BIN/PALETTE.FE


#compilation du noyau
fasm ASM/NOYAU/ETAGE3.ASM BIN/ETAGE3.BIN
fasm ASM/NOYAU/ETAGE4.ASM BIN/ETAGE4.BIN


#compilation des secteur de boot
fasm ASM/BOOT/MBR_BIOS.ASM BIN/BIOS.MBR
fasm ASM/BOOT/MBR_RELAIS.ASM BIN/RELAIS.MBR

#compilation des fichiers de définitions
#fasm ASM/DEF/bug1.asm BIN/bug1.def
fasm ASM/DEF/fr-txt.asm BIN/fr-txt.def
fasm ASM/DEF/fr-aza.asm BIN/fr-aza.def
#fasm ASM/DEF/be-azs.asm BIN/be-azs.def
fasm ASM/DEF/en-txt.asm BIN/en-txt.def
fasm ASM/DEF/en-qwi.asm BIN/en-qwi.def
fasm ASM/DEF/bepo.asm BIN/bepo.def
fasm ASM/DEF/colemak.asm BIN/colemak.def
fasm ASM/DEF/dvorak.asm BIN/dvorak.def
fasm ASM/DEF/gr-aza.asm BIN/gr-aza.def
fasm ASM/DEF/gr-qwi.asm BIN/gr-qwi.def

#fasm ASM/DEF/0u0.asm  BIN/0u0.def

#création du zip de base et mise a jour du manuel zipp�
cd BIN
zip -9 SEAC.ZIP *.ids
zip -9 SEAC.ZIP *.FE
zip -9 SEAC.ZIP *.png
zip -9 SEAC.ZIP *.def

zip -9 CFG.ZIP LSPCI.CFG
zip -9 CFG.ZIP LSPCI.CFG
zip -9 CFG.ZIP MANUEL.TXT
zip -9 CFG.ZIP MANUAL.TXT
zip -9 CFG.ZIP AUTOCOMP.CFG
zip -9 CFG.ZIP EXPL.CFG
cd ..


#ajout de la bibliotheque de base pour la création d'application assembleur et d'un exemple a l'archive du noyau
./ajarch ASM/PROG/fe.inc BIN/ETAGE4.BIN
./ajarch ASM/PROG/hello.asm BIN/ETAGE4.BIN

#ajout des sources de base pour recompiler le noyau a l'archive du noyau
./ajarch ASM/NOYAU/ETAGE2_MBR.ASM BIN/ETAGE4.BIN
./ajarch ASM/NOYAU/ETAGE4.ASM BIN/ETAGE4.BIN
./ajarch BIN/BIOS.MBR BIN/ETAGE4.BIN
./ajarch BIN/RELAIS.MBR BIN/ETAGE4.BIN

#ajout des applications et de leurs données de base à l'archive du noyau
./ajarch BIN/FASM.FE BIN/ETAGE4.BIN
./ajarch BIN/DATE.FE BIN/ETAGE4.BIN
./ajarch BIN/EDT.FE BIN/ETAGE4.BIN
./ajarch BIN/EDH.FE BIN/ETAGE4.BIN
./ajarch BIN/EDG.FE BIN/ETAGE4.BIN
./ajarch BIN/ICS.FE BIN/ETAGE4.BIN
./ajarch BIN/PARTD.FE BIN/ETAGE4.BIN
./ajarch BIN/LSPCI.FE BIN/ETAGE4.BIN
./ajarch BIN/LSUSB.FE BIN/ETAGE4.BIN
./ajarch BIN/TERM.FE BIN/ETAGE4.BIN
./ajarch BIN/CIRC.FE BIN/ETAGE4.BIN
./ajarch BIN/CDNS.FE BIN/ETAGE4.BIN
./ajarch BIN/CHTTP.FE BIN/ETAGE4.BIN
./ajarch BIN/CFTP.FE BIN/ETAGE4.BIN
./ajarch BIN/CTFTP.FE BIN/ETAGE4.BIN
./ajarch BIN/WHOIS.FE BIN/ETAGE4.BIN
./ajarch BIN/PING.FE BIN/ETAGE4.BIN
./ajarch BIN/TRACE.FE BIN/ETAGE4.BIN
./ajarch BIN/SCANIP.FE BIN/ETAGE4.BIN
./ajarch BIN/EXPL.FE BIN/ETAGE4.BIN
./ajarch BIN/VOIR.FE BIN/ETAGE4.BIN
./ajarch BIN/UTF8.FE BIN/ETAGE4.BIN
./ajarch BIN/CALC.FE BIN/ETAGE4.BIN
./ajarch BIN/IPCONFIG.FE BIN/ETAGE4.BIN
./ajarch BIN/SHTTP.FE BIN/ETAGE4.BIN
./ajarch BIN/STFTP.FE BIN/ETAGE4.BIN
./ajarch BIN/STLNT.FE BIN/ETAGE4.BIN
./ajarch BIN/SPXE.FE BIN/ETAGE4.BIN
./ajarch BIN/CDG.FE BIN/ETAGE4.BIN
./ajarch BIN/MAN.FE BIN/ETAGE4.BIN
./ajarch BIN/HELP.FE BIN/ETAGE4.BIN
./ajarch BIN/SNIF.FE BIN/ETAGE4.BIN
./ajarch BIN/AJARCH.FE BIN/ETAGE4.BIN
./ajarch BIN/DCP.FE BIN/ETAGE4.BIN
./ajarch BIN/PILOTE.FE BIN/ETAGE4.BIN
./ajarch BIN/PILOTEPCI.CFG BIN/ETAGE4.BIN
./ajarch BIN/RTL8139.FE BIN/ETAGE4.BIN
./ajarch BIN/3C90X.FE BIN/ETAGE4.BIN
./ajarch BIN/I8254X.FE BIN/ETAGE4.BIN
./ajarch BIN/JN1.FE BIN/ETAGE4.BIN
./ajarch BIN/SNAKE.FE BIN/ETAGE4.BIN
./ajarch BIN/PALETTE.FE BIN/ETAGE4.BIN


#ajout des fichiers de définition à l'archive du noyau
./ajarch BIN/bug1.def BIN/ETAGE4.BIN
./ajarch BIN/fr-txt.def BIN/ETAGE4.BIN
./ajarch BIN/fr-aza.def BIN/ETAGE4.BIN
./ajarch BIN/be-azs.def BIN/ETAGE4.BIN
./ajarch BIN/en-txt.def BIN/ETAGE4.BIN
./ajarch BIN/en-qwi.def BIN/ETAGE4.BIN
./ajarch BIN/bepo.def BIN/ETAGE4.BIN
./ajarch BIN/colemak.def BIN/ETAGE4.BIN
./ajarch BIN/dvorak.def BIN/ETAGE4.BIN
./ajarch BIN/gr-aza.def BIN/ETAGE4.BIN
./ajarch BIN/gr-qwi.def BIN/ETAGE4.BIN
./ajarch BIN/0u0.def BIN/ETAGE4.BIN
./ajarch BIN/1u0.def BIN/ETAGE4.BIN
./ajarch BIN/3u0.def BIN/ETAGE4.BIN
./ajarch BIN/25u0.def BIN/ETAGE4.BIN
./ajarch BIN/FFu0.def BIN/ETAGE4.BIN
./ajarch BIN/F00u0.def BIN/ETAGE4.BIN
./ajarch BIN/ETAGE24.ASM BIN/ETAGE4.BIN
./ajarch BIN/icones.png BIN/ETAGE4.BIN
./ajarch BIN/CFG.ZIP BIN/ETAGE4.BIN


#compilation des différents format du noyau
fasm ASM/NOYAU/ETAGE2_MBR.ASM BIN/SEAC.BAZ
#fasm ASM/NOYAU/ETAGE2_EFI.ASM BIN/SEAC.EFI
fasm ASM/NOYAU/ETAGE1_DSQ.ASM BIN/SEAC.IMG
fasm ASM/NOYAU/ETAGE1_PXE.ASM BIN/SEAC.PXE
fasm ASM/NOYAU/ETAGE1_ISO.ASM BIN/SEAC.ISO

#./ajarch usb.ids ETAGE4.BIN
#./ajarch pci.ids ETAGE4.BIN
#./ajarch fond.png ETAGE4.BIN

fasm ASM/NOYAU/ETAGE2_IMB.ASM BIN/SEAC.IMB

rm -f ajarch



