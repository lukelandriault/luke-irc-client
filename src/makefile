# Makefile for Luke's IRC Client
# Will work on win32 with msys or cygwin

default: all

FBC = fbc
CMDMOD = -mt -g -d __LIC__=-1
CMDEXE = -mt -g

SRC = lic.bas lic-dcc.bas lic-dcc-send.bas lic-drawstring.bas lic-event_handler.bas \
		lic-events-mouse_press.bas lic-events-mouse_release.bas lic-font.bas lic-global.bas \
		lic-input.bas lic-main-parse.bas lic-misc.bas lic-numeric.bas lic-options.bas lic-room.bas \
		lic-rtl.bas lic-rtl-asm.bas lic-server.bas lic-server-parse.bas lic-systray.bas \
		lic-server-privmsg.bas lic-server-rpl.bas lic-dcc-parse-irc.bas

OBJ = $(SRC:%.bas=%.o)

INC =	lic.bi lic-compile-options.bi lic-font.bi lic-options.bi \
		lic-input.bi lic-dcc.bi lic-debug.bi lic-server.bi lic-rtl.bi

MAINBAS = lic
FBCVER := $(shell $(FBC) -version | grep -i "win32")
FBCARCH := $(shell $(FBC) -version | grep -i "32bit")

ifneq (,$(FBCVER))
   ifneq (,$(FBCARCH))
	   OSSPEC = lic.rc -t 64 -p chisock/lib/win32
	else
	   OSSPEC = lic.rc -t 64 -p chisock/lib/win64
	endif
	EXEOUT = lic.exe
else
   ifneq (,$(FBCARCH))
	   OSSPEC = lic_icon.xpm -p chisock/lib/linux32
	else
	   OSSPEC = lic_icon.xpm -p chisock/lib/linux64
	endif
	EXEOUT = lic
endif


all: $(EXEOUT)

$(EXEOUT): $(OBJ)
	$(FBC) $(CMDEXE) $(OBJ) $(OSSPEC)

%.o: %.bas $(INC)
	$(FBC) $(CMDMOD) -m $(MAINBAS) -i chisock -c $< -o $@

clean:
	rm -f $(OBJ)

