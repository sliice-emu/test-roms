# To error out early
ifeq ($(strip $(DEVKITPPC)),)
$(error "Please set DEVKITPPC in your environment. export DEVKITPPC=<path to>devkitPPC")
endif

build-dol-%: %
	@make -C $<
	@cp $</$<.dol output/$<.dol

clean-dol-%: %
	@make -C $< clean

all: build-dol-MinimalTriangle

clean: clean-dol-MinimalTriangle
	@rm -rf output/*.dol

.PHONY: clean all
