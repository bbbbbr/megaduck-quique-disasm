
all: gb duck

DIRDUCK=build_duck
DIRGB=build_gb
GFXDIR=gfx
SRCDIR=src
INCPATH=$(SRCDIR)

REF_ROM_DIR=reference_rom
REFERENCE_ROM_NAME=megaduck_quique_spa.duck
REFERENCE_ROM=$(REF_ROM_DIR)/$(REFERENCE_ROM_NAME)
ROMNAME_BASE=quique

SPLIT_ROMS_DIR=$(REF_ROM_DIR)/split_roms

UPS_PATCHTOOL_PATH=tools/ups_patch

MKDIRS = $(DIRDUCK) $(DIRGB) $(REF_ROM_DIR) $(SPLIT_ROMS_DIR)


ifeq ($(wildcard $(REFERENCE_ROM)),)
#ifeq (,$(wildcard $(REFERENCE_ROM))
$(error Original ROM not found at "$(REFERENCE_ROM)".)
endif


gb: $(DIRGB)/$(ROMNAME_BASE).gb
duck: $(DIRDUCK)/$(ROMNAME_BASE).duck

clean: cleanduck cleangb


# == Game Boy ==

cleangb:
	rm -f $(DIRGB)/*

$(DIRGB)/$(ROMNAME_BASE).gb: gbgfx $(SRCDIR)/megaduck_quique_spa.asm
	rgbasm -Wno-obsolete --preserve-ld --halt-without-nop -i $(INCPATH) -o $(DIRGB)/$(ROMNAME_BASE).o $(SRCDIR)/megaduck_quique_spa.asm
	rgblink -n $(DIRGB)/$(ROMNAME_BASE).sym -m $(DIRGB)/$(ROMNAME_BASE).map -o $(DIRGB)/$(ROMNAME_BASE).gb $(DIRGB)/$(ROMNAME_BASE).o
#	rgbfix ..TODO..	(is rom header region free of code, or is there any to relocate?)
	@if which md5sum &>/dev/null; then md5sum $@; else md5 $@; fi
	@if which md5sum &>/dev/null; then md5sum $(REFERENCE_ROM); else md5 $(REFERENCE_ROM); fi

gbgfx:
#	rgbgfx $(GFXDIR)/megaduck_logo_9x_8x8.png -o src/megaduck_logo_9_tiles.2bpp -c "#FFFFFF,#A0A0A0,#4E4E4E,#000000;"


# == Mega Duck ==

duck: $(DIRDUCK)/$(ROMNAME_BASE).duck

clean: cleanduck

cleanduck:
	rm -f $(DIRDUCK)/*

$(DIRDUCK)/$(ROMNAME_BASE).duck: duckgfx $(SRCDIR)/megaduck_quique_spa.asm
	rgbasm -Wno-obsolete -DTARGET_MEGADUCK --preserve-ld --halt-without-nop -i $(INCPATH) -o $(DIRDUCK)/$(ROMNAME_BASE).o $(SRCDIR)/megaduck_quique_spa.asm
	rgblink -n $(DIRDUCK)/$(ROMNAME_BASE).sym -m $(DIRDUCK)/$(ROMNAME_BASE).map -o $(DIRDUCK)/$(ROMNAME_BASE).duck $(DIRDUCK)/$(ROMNAME_BASE).o
	@if which md5sum &>/dev/null; then md5sum $@; else md5 $@; fi
	@if which md5sum &>/dev/null; then md5sum $(REFERENCE_ROM); else md5 $(REFERENCE_ROM); fi

duckgfx:
#	rgbgfx $(GFXDIR)/megaduck_logo_9x_8x8.png -o src/megaduck_logo_9_tiles.2bpp -c "#FFFFFF,#A0A0A0,#4E4E4E,#000000;"


bindiffduck:
	vbindiff $(REFERENCE_ROM) $(DIRDUCK)/$(ROMNAME_BASE).duck

bindiffgb:
	vbindiff $(REFERENCE_ROM) $(DIRGB)/$(ROMNAME_BASE).gb


usage:
	romusage $(DIRDUCK)/$(ROMNAME_BASE).map -g

# Needs stock inside gadgets firmware to work, can use flashgbx ui to swap it out if needed
# Make sure 32K cart is specified
flashduck:
	-cd tools/gbxcart_duck; ./gbxcart_rw_megaduck_32kb_flasher ../../$(DIRDUCK)/$(ROMNAME_BASE).duck &


# Split the rom into 32K blocks and flash the first one
# For now delete the split blocks when done
flashbank0:
	mkdir -p $(DIRDUCK)/splitroms
	split --verbose --bytes=32k --numeric-suffixes --suffix-length=2 $(DIRDUCK)/$(ROMNAME_BASE).duck $(DIRDUCK)/splitroms/bank.
	-cd tools/gbxcart_duck; ./gbxcart_rw_megaduck_32kb_flasher ../../$(DIRDUCK)/splitroms/bank.00
	rm -rf $(DIRDUCK)/splitroms


# rom-first-32k:
#	dd bs=32K count=1 if=$(REFERENCE_ROM) of=$(REFERENCE_ROM)_32k.duck

# Split SYSTEM ROM into 32K bank chunks
split-rom-banks:
	split --verbose --bytes=32k --numeric-suffixes --suffix-length=2 $(REFERENCE_ROM) $(SPLIT_ROMS_DIR)/$(REFERENCE_ROM_NAME).


# create necessary directories after Makefile is parsed but before build
# info prevents the command from being pasted into the makefile
$(info $(shell mkdir -p $(MKDIRS)))

