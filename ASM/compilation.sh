echo compilation du système
cd NOYAU
fasm ETAGE3.ASM ../../BIN/ETAGE3.BIN
fasm ETAGE4.ASM ../../BIN/ETAGE4.BIN
#cd ../FASM/SEAC
#fasm FASM_FR.ASM ../../../BIN/FASM.FE
#cd ../../PROG
cd ../PROG
fasm date.asm ../../BIN/DATE.FE
fasm edt.asm ../../BIN/EDT.FE
fasm edh.asm ../../BIN/EDH.FE
fasm edg.asm ../../BIN/EDG.FE
fasm partd.asm ../../BIN/PARTD.FE
fasm lc.asm ../../BIN/LC.FE
fasm term.asm ../../BIN/TERM.FE
fasm circ.asm ../../BIN/CIRC.FE
fasm cdns.asm ../../BIN/CDNS.FE
fasm chttp.asm ../../BIN/CHTTP.FE
fasm cftp.asm ../../BIN/CFTP.FE
fasm sdns.asm ../../BIN/SDNS.FE
fasm ping.asm ../../BIN/PING.FE
fasm trace.asm ../../BIN/TRACE.FE
fasm scanip.asm ../../BIN/SCANIP.FE
fasm expl.asm ../../BIN/EXPL.FE
fasm voir.asm ../../BIN/VOIR.FE
fasm utf8.asm ../../BIN/UTF8.FE
fasm calc.asm ../../BIN/CALC.FE
fasm ipconfig.asm ../../BIN/IPCONFIG.FE
fasm shttp.asm ../../BIN/SHTTP.FE
fasm stftp.asm ../../BIN/STFTP.FE
fasm stlnt.asm ../../BIN/STLNT.FE
fasm sdhcp.asm ../../BIN/SDHCP.FE
fasm snif.asm ../../BIN/SNIF.FE
fasm man.asm ../../BIN/MAN.FE
fasm ajarch.asm ../../BIN/AJARCH.FE
fasm dcp.asm ../../BIN/DCP.FE
fasm RTL8139.asm ../../BIN/RTL8139.FE
fasm 3C90X.asm ../../BIN/3C90X.FE
fasm I8254X.asm ../../BIN/I8254X.FE
ajarch fe.inc ../../BIN/ETAGE4.BIN
ajarch hello.asm ../../BIN/ETAGE4.BIN
fasm jn1.asm ../../BIN/JN1.FE
cd ../NOYAU
ajarch ETAGE2_MBR.ASM ../../BIN/ETAGE4.BIN
ajarch ETAGE4.ASM ../../BIN/ETAGE4.BIN
cd ../BOOT
fasm MBR_BIOS.ASM ../../BIN/BIOS.MBR
fasm MBR_RELAIS.ASM ../../BIN/RELAIS.MBR
cd ../DEF
#fasm bug1.asm ../../BIN/bug1.def
fasm fr-txt.asm ../../BIN/fr-txt.def
#fasm fr-aza.asm ../../BIN/fr-aza.def
#fasm fr-bpo.asm ../../BIN/fr-bpo.def
#fasm be-azs.asm ../../BIN/be-azs.def
fasm en-txt.asm ../../BIN/en-txt.def
#fasm en-qwi.asm ../../BIN/en-qwi.def
#fasm 0u0.asm  ../../BIN/0u0.def
#fasm 25u0.asm  ../../BIN/25u0.def
#fasm F00u0.asm  ../../BIN/F00u0.def
cd ../../BIN/
#ajarch FASM.FE ETAGE4.BIN
ajarch DATE.FE ETAGE4.BIN
ajarch EDT.FE ETAGE4.BIN
ajarch EDH.FE ETAGE4.BIN
ajarch EDG.FE ETAGE4.BIN
ajarch PARTD.FE ETAGE4.BIN
ajarch LC.FE ETAGE4.BIN
ajarch PCICLASS.TXT ETAGE4.BIN
ajarch TERM.FE ETAGE4.BIN
ajarch CIRC.FE ETAGE4.BIN
ajarch CDNS.FE ETAGE4.BIN
ajarch CHTTP.FE ETAGE4.BIN
ajarch CFTP.FE ETAGE4.BIN
ajarch SDNS.FE ETAGE4.BIN
ajarch PING.FE ETAGE4.BIN
ajarch TRACE.FE ETAGE4.BIN
ajarch SCANIP.FE ETAGE4.BIN
ajarch EXPL.FE ETAGE4.BIN
ajarch VOIR.FE ETAGE4.BIN
ajarch UTF8.FE ETAGE4.BIN
ajarch CALC.FE ETAGE4.BIN
ajarch BIOS.MBR ETAGE4.BIN
ajarch RELAIS.MBR ETAGE4.BIN
ajarch IPCONFIG.FE ETAGE4.BIN
ajarch SHTTP.FE ETAGE4.BIN
ajarch STFTP.FE ETAGE4.BIN
ajarch STLNT.FE ETAGE4.BIN
ajarch MAN.FE ETAGE4.BIN
ajarch SNIF.FE ETAGE4.BIN
ajarch AJARCH.FE ETAGE4.BIN
ajarch DCP.FE ETAGE4.BIN
ajarch RTL8139.FE ETAGE4.BIN
ajarch 3C90X.FE ETAGE4.BIN
ajarch I8254X.FE ETAGE4.BIN
ajarch JN1.FE ETAGE4.BIN
ajarch MANUEL.TXT ETAGE4.BIN
ajarch bug1.def ETAGE4.BIN
ajarch fr-txt.def ETAGE4.BIN
ajarch fr-aza.def ETAGE4.BIN
ajarch fr-bpo.def ETAGE4.BIN
ajarch be-azs.def ETAGE4.BIN
ajarch en-txt.def ETAGE4.BIN
ajarch en-qwi.def ETAGE4.BIN
ajarch 0u0.def ETAGE4.BIN
ajarch 1u0.def ETAGE4.BIN
ajarch 25u0.def ETAGE4.BIN
ajarch F00u0.def ETAGE4.BIN
ajarch ETAGE24.ASM ETAGE4.BIN
ajarch logo.png ETAGE4.BIN
cd ../ASM/NOYAU
fasm ETAGE2_MBR.ASM ../../BIN/SEAC.BAZ
fasm ETAGE2_IMB.ASM ../../BIN/SEAC.IMB
fasm ETAGE2_EFI.ASM ../../BIN/SEAC.EFI
fasm ETAGE1_DSQ.ASM ../../BIN/SEAC.IMG
fasm ETAGE1_PXE.ASM ../../BIN/SEAC.PXE
#fasm ETAGE1_VHD.ASM ../../BIN/SEAC.VHD
cd ..
