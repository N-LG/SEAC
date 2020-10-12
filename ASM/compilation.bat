echo off
color 40
echo compilation du système

cd NOYAU
fasm SYST.ASM ../../BIN/SYST.BAZ

cd ../FASM/SELG
fasm FASM_FR.ASM ../../../BIN/FASM.FE

cd ../../PROG
::fasm date.asm ../../BIN/DATE.FE
fasm edt.asm ../../BIN/EDT.FE
::fasm edd.asm ../../BIN/EDD.FE
fasm edh.asm ../../BIN/EDH.FE
fasm edg.asm ../../BIN/EDG.FE
fasm partd.asm ../../BIN/PARTD.FE
::fasm imgp.asm ../../BIN/IMGP.FE
fasm LC.ASM ../../BIN/LC.FE
fasm TERM.ASM ../../BIN/TERM.FE
::fasm CIRC.ASM ../../BIN/CIRC.FE
::fasm CDNS.ASM ../../BIN/CDNS.FE
fasm EXPL.ASM ../../BIN/EXPL.FE
::fasm UTF8.ASM ../../BIN/UTF8.FE
::fasm CALC.ASM ../../BIN/CALC.FE
fasm ipconfig.asm ../../BIN/IPCONFIG.FE
fasm shttp.asm ../../BIN/SHTTP.FE
fasm stftp.asm ../../BIN/STFTP.FE
fasm stlnt.asm ../../BIN/STLNT.FE
::fasm chttp.asm ../../BIN/CHTTP.FE
::fasm ctftp.asm ../../BIN/CTFTP.FE
::fasm csdns.asm ../../BIN/CSDNS.FE
fasm sdhcp.asm ../../BIN/SDHCP.FE
fasm snif.asm ../../BIN/SNIF.FE
fasm ajarch.asm ../../BIN/AJARCH.FE
fasm RTL8139.asm ../../BIN/RTL8139.FE
fasm 3C90X.asm ../../BIN/3C90X.FE
fasm I8254X.asm ../../BIN/I8254X.FE
fasm VETHER.asm ../../BIN/VETHER.FE

cd ../BOOT
::fasm MBR_BIOS.ASM ../../BIN/MBR_BIOS.BIN
::fasm MBR_LBA.ASM ../../BIN/MBR_LBA.BIN
::fasm MBR_CHS.ASM ../../BIN/MBR_CHS.BIN
::fasm MBR_STOP.ASM ../../BIN/MBR_STOP.BIN

cd ../DEF
::fasm bug1.asm ../../BIN/bug1.def
fasm fr-txt.asm ../../BIN/fr-txt.def
::fasm fr-azs.asm ../../BIN/fr-azs.def
fasm fr-aza.asm ../../BIN/fr-aza.def
::fasm fr-azn.asm ../../BIN/fr-azn.def
::fasm fr-bep.asm ../../BIN/fr-bep.def
fasm en-txt.asm ../../BIN/en-txt.def
::fasm en-qws.asm ../../BIN/en-qws.def
::fasm en-qws.asm ../../BIN/en-qwi.def
::fasm en-qwi.asm ../../BIN/en-qwi.def
::fasm en-dvk.asm ../../BIN/en-qwi.def
::fasm 0u0.asm  ../../BIN/0u0.def
::fasm 1u0.asm  ../../BIN/1u0.def
::fasm 25u0.asm  ../../BIN/25u0.def
::fasm F00u0.asm  ../../BIN/F00u0.def

cd ../../BIN/
copy SYST.BAZ SYST.BIN 
copy SYST.BAZ SYST2.BIN 
::ajarch FASM.FE SYST.BIN
ajarch DATE.FE SYST.BIN
ajarch EDT.FE SYST.BIN
::ajarch EDD.FE SYST.BIN
ajarch EDH.FE SYST.BIN
ajarch EDG.FE SYST.BIN
ajarch PARTD.FE SYST.BIN
::ajarch IMGP.FE SYST.BIN
ajarch LC.FE SYST.BIN
ajarch TERM.FE SYST.BIN
ajarch CIRC.FE SYST.BIN
ajarch CDNS.FE SYST.BIN
ajarch EXPL.FE SYST.BIN
ajarch UTF8.FE SYST.BIN
ajarch CALC.FE SYST.BIN
ajarch MBR_BIOS.BIN SYST.BIN
::ajarch MBR_LBA.BIN SYST.BIN
ajarch MBR_CHS.BIN SYST.BIN
::ajarch MBR_STOP.BIN SYST.BIN
ajarch IPCONFIG.FE SYST.BIN
ajarch SHTTP.FE SYST.BIN
ajarch STFTP.FE SYST.BIN
ajarch STLNT.FE SYST.BIN
::ajarch CHTTP.FE SYST.BIN
::ajarch CSDNS.FE SYST.BIN
::ajarch CTFTP.FE SYST.BIN
::ajarch SDHCP.FE SYST.BIN
ajarch SNIF.FE SYST.BIN
ajarch AJARCH.FE SYST.BIN
ajarch RTL8139.FE SYST.BIN
ajarch 3C90X.FE SYST.BIN
ajarch I8254X.FE SYST.BIN
::ajarch VETHER.FE SYST.BIN
copy cfg1.sh cfg.sh
ajarch cfg.sh SYST.BIN
ajarch aide.txt SYST.BIN
::ajarch bug1.def SYST.BIN
::ajarch fr-txt.def SYST.BIN
::ajarch fr-azs.def SYST.BIN
::ajarch fr-aza.def SYST.BIN
::ajarch fr-azn.def SYST.BIN
::ajarch fr-bep.def SYST.BIN
ajarch en-txt.def SYST.BIN
::ajarch en-qws.def SYST.BIN
ajarch en-qwi.def SYST.BIN
::ajarch en-dvk.def SYST.BIN
ajarch 0u0.def SYST.BIN
ajarch 1u0.def SYST.BIN
ajarch 25u0.def SYST.BIN
ajarch F00u0.def SYST.BIN
copy SYST.BIN  ..\OUTILS\WINDOWS\BOOTNET

copy cfg2.sh cfg.sh
ajarch cfg.sh SYST2.BIN
ajarch FASM.FE SYST2.BIN
ajarch EDT.FE SYST2.BIN
cd ../ASM/PROG
ajarch fe.inc ../../BIN/SYST2.BIN
ajarch hello.asm ../../BIN/SYST2.BIN


cd ../NOYAU

fasm CHARGEUR.ASM ../../BIN/SEAC_BAZ.IMB
fasm CHARGEUR2.ASM ../../BIN/SEAC_DEV.IMB
fasm disquette.asm ../../BIN/DISQUETTE.IMG
::fasm ddur.asm ../../BIN/DDUR.VHD
cd ..


color F0

