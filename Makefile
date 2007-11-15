FPC = fpc
FPRCP = fprcp
WINDRES = windres

FPCFLAGS = -Sd -Sa
#FPCFLAGS = -Sd -Sa -pg

PAS = *.pas
TXT = resources/*.txt

all: grf2html

grf2html: grfbase.or tables.or $(PAS) grf2html.dpr
	$(FPC) $(FPCFLAGS) grf2html.dpr

grfbase.or: grfbase.res
	rm -f grfbase.ppu grfbase.o grfbase.or

grfbase.res: resources/pal_dos.bcp resources/pal_win.bcp grfbase.rc
	cat grfbase.rc | sed 's#\\#/#g' | $(WINDRES) -o grfbase.res

tables.or: tables.res
	rm -f tables.ppu tables.o tables.or

tables.res: $(TXT) tables.rc
	cat tables.rc | sed 's#\\#/#g' | $(WINDRES) -o tables.res

clean:
	rm -f *.o *.ppu *.res *.or
