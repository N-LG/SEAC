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
fasm MBR_BIOS.ASM ../../BIN/MBR_BIOS.MBR
::fasm MBR_LBA.ASM ../../BIN/MBR_LBA.MBR
::fasm MBR_CHS.ASM ../../BIN/MBR_CHS.MBR
::fasm MBR_STOP.ASM ../../BIN/MBR_STOP.MBR

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
copy SYST.BAZ SYST1.BAZ 
copy cfg1.sh cfg.sh
ajarch cfg.sh SYST1.BAZ
::ajarch FASM.FE SYST1.BAZ
ajarch DATE.FE SYST1.BAZ
ajarch EDT.FE SYST1.BAZ
::ajarch EDD.FE SYST1.BAZ
ajarch EDH.FE SYST1.BAZ
ajarch EDG.FE SYST1.BAZ
ajarch PARTD.FE SYST1.BAZ
::ajarch IMGP.FE SYST1.BAZ
ajarch LC.FE SYST1.BAZ
ajarch TERM.FE SYST1.BAZ
ajarch CIRC.FE SYST1.BAZ
ajarch CDNS.FE SYST1.BAZ
ajarch EXPL.FE SYST1.BAZ
ajarch UTF8.FE SYST1.BAZ
ajarch CALC.FE SYST1.BAZ
ajarch MBR_BIOS.MBR SYST1.BAZ
::ajarch MBR_LBA.MBR SYST1.BAZ
::ajarch MBR_CHS.MBR SYST1.BAZ
::ajarch MBR_STOP.MBR SYST1.BAZ
ajarch IPCONFIG.FE SYST1.BAZ
ajarch SHTTP.FE SYST1.BAZ
ajarch STFTP.FE SYST1.BAZ
ajarch STLNT.FE SYST1.BAZ
::ajarch CHTTP.FE SYST1.BAZ
::ajarch CSDNS.FE SYST1.BAZ
::ajarch CTFTP.FE SYST1.BAZ
::ajarch SDHCP.FE SYST1.BAZ
ajarch SNIF.FE SYST1.BAZ
ajarch AJARCH.FE SYST1.BAZ
ajarch RTL8139.FE SYST1.BAZ
ajarch 3C90X.FE SYST1.BAZ
ajarch I8254X.FE SYST1.BAZ
::ajarch VETHER.FE SYST1.BAZ
ajarch aide.txt SYST1.BAZ
::ajarch bug1.def SYST1.BAZ
::ajarch fr-txt.def SYST1.BAZ
::ajarch fr-azs.def SYST1.BAZ
::ajarch fr-aza.def SYST1.BAZ
::ajarch fr-azn.def SYST1.BAZ
::ajarch fr-bep.def SYST1.BAZ
ajarch en-txt.def SYST1.BAZ
::ajarch en-qws.def SYST1.BAZ
ajarch en-qwi.def SYST1.BAZ
::ajarch en-dvk.def SYST1.BAZ
ajarch 0u0.def SYST1.BAZ
ajarch 1u0.def SYST1.BAZ
ajarch 25u0.def SYST1.BAZ
ajarch F00u0.def SYST1.BAZ
copy SYST1.BAZ  ..\OUTILS\WINDOWS\BOOTNET

copy SYST.BAZ SYST2.BAZ
copy cfg2.sh cfg.sh
ajarch cfg.sh SYST2.BAZ
ajarch FASM.FE SYST2.BAZ
ajarch EDT.FE SYST2.BAZ
cd ../ASM/PROG
ajarch fe.inc ../../BIN/SYST2.BAZ
ajarch hello.asm ../../BIN/SYST2.BAZ


cd ../NOYAU

fasm CHARGEUR1.ASM ../../BIN/SEAC_BAZ.IMB
fasm CHARGEUR2.ASM ../../BIN/SEAC_DEV.IMB
fasm disquette.asm ../../BIN/DISQUETTE.IMG
cd ..


color F0

