SDCC=sdcc
CPU=z80
DATALOC=0xC000

OUT_DIR=build/
MAIN=os
OUTPUT=rom

SHARED_PATH=../shared/
SHARED_RELS_ALL=$(patsubst %.c,build/%.rel,$(wildcard $(SHARED_PATH)*.c)) # Get all c files from src/shared/ folder
IGNORE_SHARED_RELS=$(patsubst %, build/../shared/%.rel, $(IGNORE_SHARED)) # Format shared files to ignore correctly for filtering
SHARED_RELS=$(filter-out $(IGNORE_SHARED_RELS), $(SHARED_RELS_ALL)) # Filter out ignored shared files

PROJECT_RELS_ALL=$(patsubst %.c,build/%.rel,$(wildcard *.c)) # Get all c files from src/[project]  folder
IGNORE_PROJECT_RELS=$(patsubst %, build/%.rel, $(IGNORE_PROJECT)) # Format project files to ignore correctly for filtering
PROJECT_RELS_FILTERED=$(filter-out $(IGNORE_PROJECT_RELS),$(PROJECT_RELS_ALL)) # Filter out ignored shared files
PROJECT_RELS=$(patsubst build/$(MAIN).rel,,$(PROJECT_RELS_FILTERED))  # Remove main c file

TARGET_RELS=$(patsubst build/$(MAIN).rel,,$(wildcard build/*.rel))

all: $(OUTPUT).bin

build/$(OUTPUT).ihx: $(PROJECT_RELS) $(SHARED_RELS)
	$(SDCC) $(DEFINES) -m$(CPU) --data-loc $(DATALOC) -o $(OUT_DIR)$(OUTPUT).ihx $(MAIN).c $(TARGET_RELS)

build/%.rel: %.c
	$(SDCC) $(DEFINES) -m$(CPU) --data-loc $(DATALOC) -o $(OUT_DIR) -c $<

$(OUTPUT).bin: build/$(OUTPUT).ihx
	srec_cat $< -intel -o $@ -binary
	rm build/$(OUTPUT).ihx
	mv $(OUTPUT).bin bin/$(OUTPUT).bin
	mv build/$(OUTPUT).asm $(OUTPUT).asm
	rm -f build/$(OUTPUT).*

clean:
	rm -f build/*
	rm -f bin/*
