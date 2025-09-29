# Outil pour la compilation
SHELL 			= /bin/bash
MKCWD 			= mkdir -p $(@D)
AS 				= fasm
DOSSIER_BIN 	= ./BIN

# Macro qui évite les répétitions
define COMPILE_ASM
	$(MKCWD)
	$(AS) $< $@
endef

# Compilation des outils 
$(DOSSIER_BIN)/ajarchl: ./OUTILS/ajarchl.asm
	$(COMPILE_ASM)


define build_rule
$1: $2
	fasm $$< $$@
endef

# Compilation des applications
DOSSIER_APP 	= ./ASM/PROG
SRC_APP 		:= $(wildcard $(DOSSIER_APP)/*.asm)
BIN_APP 		:= $(patsubst $(DOSSIER_APP)/%.asm,$(DOSSIER_BIN)/%.FE,$(SRC_APP))
BIN_APP 		:= $(shell echo $(BIN_APP) | tr 'a-z' 'A-Z')

$(foreach idx,$(shell seq 1 $(words $(SRC_APP))),\
  $(eval $(call build_rule,$(word $(idx),$(BIN_APP)),$(word $(idx),$(SRC_APP)))))

# Compialtion du noyau
DOSSIER_NOYAU 	= ./ASM/NOYAU
SRC_NOYAU 		:= $(DOSSIER_NOYAU)/ETAGE3.ASM
BIN_NOYAU 		:= $(patsubst $(DOSSIER_NOYAU)/%.ASM, $(DOSSIER_BIN)/%.BIN, $(SRC_NOYAU))

$(DOSSIER_BIN)/%.BIN: $(DOSSIER_NOYAU)/%.ASM
	$(COMPILE_ASM)

$(DOSSIER_NOYAU)/ETAGE3.BIN: $(DOSSIER_BIN)/ETAGE3.BIN
	@cp $^ $@

$(DOSSIER_BIN)/SEAC.BAZ: $(DOSSIER_NOYAU)/ETAGE2_MBR.ASM $(DOSSIER_NOYAU)/ETAGE3.BIN $(DOSSIER_NOYAU)/ETAGE4.BIN $(BIN_BOOT)
	$(COMPILE_ASM)

$(DOSSIER_BIN)/SEAC.IMG: $(DOSSIER_NOYAU)/ETAGE1_DSQ.ASM $(DOSSIER_NOYAU)/ETAGE3.BIN $(DOSSIER_NOYAU)/ETAGE4.BIN $(BIN_BOOT)
	$(COMPILE_ASM)

$(DOSSIER_BIN)/SEAC.PXE: $(DOSSIER_NOYAU)/ETAGE1_PXE.ASM $(DOSSIER_NOYAU)/ETAGE3.BIN $(DOSSIER_NOYAU)/ETAGE4.BIN $(BIN_BOOT)
	$(COMPILE_ASM)

$(DOSSIER_BIN)/SEAC.ISO: $(DOSSIER_NOYAU)/ETAGE1_ISO.ASM $(DOSSIER_NOYAU)/ETAGE3.BIN $(DOSSIER_NOYAU)/ETAGE4.BIN $(BIN_BOOT)
	$(COMPILE_ASM)

# Compilation des secteur de boot
DOSSIER_BOOT 	= ./ASM/BOOT
SRC_BOOT      := $(wildcard $(DOSSIER_BOOT)/MBR_*.ASM)
BIN_BOOT := $(patsubst $(DOSSIER_BOOT)/MBR_%.ASM, $(DOSSIER_BIN)/%.MBR, $(SRC_BOOT))

$(DOSSIER_BIN)/%.MBR: $(DOSSIER_BOOT)/MBR_%.ASM
	$(COMPILE_ASM)

# Compilation des fichiers de définitions
DOSSIER_DEF 	= ./ASM/DEF
SRC_DEF 		:= 				\
	$(DOSSIER_DEF)/0u0.asm 		\
	$(DOSSIER_DEF)/be-azs.asm 	\
	$(DOSSIER_DEF)/bepo.asm 	\
	$(DOSSIER_DEF)/ca-qws.asm 	\
	$(DOSSIER_DEF)/ch-qzf.asm 	\
	$(DOSSIER_DEF)/ch-qzg.asm 	\
	$(DOSSIER_DEF)/colemak.asm 	\
	$(DOSSIER_DEF)/dvorak.asm 	\
	$(DOSSIER_DEF)/en-qus.asm 	\
	$(DOSSIER_DEF)/en-qwi.asm 	\
	$(DOSSIER_DEF)/en-txt.asm 	\
	$(DOSSIER_DEF)/ergol.asm 	\
	$(DOSSIER_DEF)/fr-aza.asm 	\
	$(DOSSIER_DEF)/fr-txt.asm 	\
	$(DOSSIER_DEF)/gr-aza.asm 	\
	$(DOSSIER_DEF)/gr-qwi.asm

BIN_DEF 		= $(patsubst $(DOSSIER_DEF)/%.asm, $(DOSSIER_BIN)/%.def, $(SRC_DEF))

$(DOSSIER_BIN)/%.def: $(DOSSIER_DEF)/%.asm
	$(COMPILE_ASM)

# Création du zip de base et mise a jour du manuel zippé
FICHIERS_PNG 	:= $(wildcard ./IMGWIKI/*.png) 
FICHIERS_TXT 	:= $(wildcard $(DOSSIER_BIN)/*.txt)
FICHIERS_CFG 	:= $(wildcard $(DOSSIER_BIN)/*.cfg)

$(DOSSIER_BIN)/pci.ids:
	curl -k -o $@ "https://pci-ids.ucw.cz/v2.2/pci.ids"

$(DOSSIER_BIN)/usb.ids:
	curl -o $@ "http://www.linux-usb.org/usb.ids"

$(DOSSIER_BIN)/SEAC.ZIP: $(BIN_APP) $(DOSSIER_BIN)/pci.ids $(DOSSIER_BIN)/usb.ids $(FICHIERS_PNG)
	zip -9 -j $@ $^

$(DOSSIER_BIN)/CFG.ZIP: $(BIN_DEF) $(FICHIERS_CFG) $(FICHIERS_TXT)
	zip -9 -j $@ $^

# Création de l'archive Noyau
FICHIERS_ARCHIVE := 				\
	$(DOSSIER_NOYAU)/ETAGE4.ASM		\
	$(BIN_APP)						\
	$(DOSSIER_BIN)/icones.png		\
	$(DOSSIER_BIN)/CFG.ZIP			\
	$(DOSSIER_APP)/fe.inc			\
	$(DOSSIER_APP)/hello.asm		\
	$(DOSSIER_NOYAU)/ETAGE2_MBR.ASM	\
	$(BIN_BOOT)						\

$(DOSSIER_BIN)/ETAGE4.BIN: $(FICHIERS_ARCHIVE)
	fasm $< $@
	printf '%s\n' $^ | xargs -I FICHIER $(DOSSIER_BIN)/ajarchl FICHIER $(DOSSIER_BIN)/ETAGE4.BIN

$(DOSSIER_NOYAU)/ETAGE4.BIN: $(DOSSIER_BIN)/ETAGE4.BIN
	@cp $^ $@

all: $(DOSSIER_BIN)/ajarchl $(BIN_NOYAU) $(BIN_BOOT) $(DOSSIER_BIN)/SEAC.ZIP $(archive) $(DOSSIER_BIN)/SEAC.BAZ $(DOSSIER_BIN)/SEAC.IMG $(DOSSIER_BIN)/SEAC.PXE $(DOSSIER_BIN)/SEAC.ISO

clean:
	@echo $(BIN_APP)
	@rm -rf $(BIN_DEF) $(BIN_BOOT) $(BIN_NOYAU) $(BIN_APP) $(DOSSIER_BIN)/ajarchl

fasm:
	curl -k -o fasm.tgz "https://flatassembler.net/fasm-1.73.32.tgz"
	tar -xf fasm.tgz
	rm fasm.tgz
	chmod +x ./fasm/fasm
	-cp ./fasm/fasm ~/.local/bin
	rm -r fasm

.DEFAULT_GOAL = all
