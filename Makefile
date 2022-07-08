# To error out early
ifeq ($(strip $(DEVKITPPC)),)
$(error "Please set DEVKITPPC in your environment. export DEVKITPPC=<path to>devkitPPC")
endif

FOLDERS=MinimalTriangle

build-dol-%: %
	@make -C $<
	@cp $</$<.dol output/$<.dol

clean-dol-%: %
	@make -C $< clean

all: $(patsubst %, build-dol-%, $(FOLDERS))

clean: $(patsubst %, clean-dol-%, $(FOLDERS))
	@rm -rf output/*.dol

.PHONY: clean all
