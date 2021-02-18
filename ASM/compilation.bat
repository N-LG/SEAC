echo off
color 40
echo compilation du système

cd NOYAU
fasm ETAGE3.ASM ../../BIN/ETAGE3.BIN
fasm ETAGE4.ASM ../../BIN/ETAGE4.BIN

cd ../FASM/SELG
fasm FASM_FR.ASM ../../../BIN/FASM.FE

cd ../../PROG
fasm date.asm ../../BIN/DATE.FE
fasm edt.asm ../../BIN/EDT.FE
fasm edh.asm ../../BIN/EDH.FE
fasm edg.asm ../../BIN/EDG.FE
fasm partd.asm ../../BIN/PARTD.FE
fasm LC.ASM ../../BIN/LC.FE
fasm TERM.ASM ../../BIN/TERM.FE
fasm CIRC.ASM ../../BIN/CIRC.FE
fasm CDNS.ASM ../../BIN/CDNS.FE
fasm ping.asm ../../BIN/PING.FE
fasm trace.asm ../../BIN/TRACE.FE
fasm EXPL.ASM ../../BIN/EXPL.FE
fasm UTF8.ASM ../../BIN/UTF8.FE
fasm CALC.ASM ../../BIN/CALC.FE
fasm ipconfig.asm ../../BIN/IPCONFIG.FE
fasm shttp.asm ../../BIN/SHTTP.FE
fasm stftp.asm ../../BIN/STFTP.FE
fasm stlnt.asm ../../BIN/STLNT.FE
fasm sdhcp.asm ../../BIN/SDHCP.FE
fasm snif.asm ../../BIN/SNIF.FE
fasm man.asm ../../BIN/MAN.FE
fasm ajarch.asm ../../BIN/AJARCH.FE
fasm RTL8139.asm ../../BIN/RTL8139.FE
fasm 3C90X.asm ../../BIN/3C90X.FE
fasm I8254X.asm ../../BIN/I8254X.FE
fasm TRACA.asm ../../BIN/TRACA.FE

ajarch fe.inc ../../BIN/ETAGE4.BIN
ajarch hello.asm ../../BIN/ETAGE4.BIN

cd ../NOYAU
ajarch ETAGE2_MBR.ASM ../../BIN/ETAGE4.BIN
ajarch ETAGE4.ASM ../../BIN/ETAGE4.BIN



cd ../BOOT
fasm MBR_BIOS.ASM ../../BIN/MBR_BIOS.MBR


cd ../DEF
fasm bug1.asm ../../BIN/bug1.def
fasm fr-txt.asm ../../BIN/fr-txt.def
fasm fr-aza.asm ../../BIN/fr-aza.def
fasm be-azs.asm ../../BIN/be-azs.def
fasm en-txt.asm ../../BIN/en-txt.def
fasm en-qwi.asm ../../BIN/en-qwi.def
fasm 0u0.asm  ../../BIN/0u0.def
fasm 1u0.asm  ../../BIN/1u0.def
fasm 25u0.asm  ../../BIN/25u0.def
fasm F00u0.asm  ../../BIN/F00u0.def

cd ../../BIN/
ajarch FASM.FE ETAGE4.BIN
ajarch DATE.FE ETAGE4.BIN
ajarch EDT.FE ETAGE4.BIN
ajarch EDH.FE ETAGE4.BIN
ajarch EDG.FE ETAGE4.BIN
ajarch PARTD.FE ETAGE4.BIN
ajarch LC.FE ETAGE4.BIN
ajarch TERM.FE ETAGE4.BIN
ajarch CIRC.FE ETAGE4.BIN
ajarch CDNS.FE ETAGE4.BIN
ajarch PING.FE ETAGE4.BIN
ajarch TRACE.FE ETAGE4.BIN
ajarch EXPL.FE ETAGE4.BIN
ajarch UTF8.FE ETAGE4.BIN
ajarch CALC.FE ETAGE4.BIN
ajarch MBR_BIOS.MBR ETAGE4.BIN
ajarch IPCONFIG.FE ETAGE4.BIN
ajarch SHTTP.FE ETAGE4.BIN
ajarch STFTP.FE ETAGE4.BIN
ajarch STLNT.FE ETAGE4.BIN
ajarch MAN.FE ETAGE4.BIN
ajarch SNIF.FE ETAGE4.BIN
ajarch AJARCH.FE ETAGE4.BIN
ajarch RTL8139.FE ETAGE4.BIN
ajarch 3C90X.FE ETAGE4.BIN
ajarch I8254X.FE ETAGE4.BIN
ajarch TRACA.FE ETAGE4.BIN

ajarch MANUEL.TXT ETAGE4.BIN
ajarch bug1.def ETAGE4.BIN
ajarch fr-txt.def ETAGE4.BIN
ajarch fr-aza.def ETAGE4.BIN
ajarch be-azs.def ETAGE4.BIN
ajarch en-txt.def ETAGE4.BIN
ajarch en-qwi.def ETAGE4.BIN
ajarch 0u0.def ETAGE4.BIN
ajarch 1u0.def ETAGE4.BIN
ajarch 25u0.def ETAGE4.BIN
ajarch F00u0.def ETAGE4.BIN



cd ../ASM/NOYAU
fasm ETAGE2_MBR.ASM ../../BIN/SEAC.BAZ
fasm ETAGE2_IMB.ASM ../../BIN/SEAC.IMB


fasm ETAGE1_DSQ.asm ../../BIN/SEAC.IMG
fasm ETAGE1_PXE.asm ../../BIN/SEAC.PXE



cd ../../BIN
copy SEAC.PXE  ..\OUTILS\WINDOWS\BOOTNET\SYST.BIN
cd ../ASM



color F0

