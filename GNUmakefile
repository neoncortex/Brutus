ifeq ($(GNUSTEP_MAKEFILES),)
	GNUSTEP_MAKEFILES := $(shell gnustep-config \
		--variable=GNUSTEP_MAKEFILES 2>/dev/null)
endif
ifeq ($(GNUSTEP_MAKEFILES),)
	$(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Brutus

Brutus_HEADERS = Document.h

Brutus_OBJC_FILES = main.m \
	Document.m \
	Controller.m \
	Editor.m \
	TextView.m \
	Rtf.m \
	Util.m

Brutus_RESOURCE_FILES =BrutusInfo.plist \
	Brutus.gorm \
	Document.gorm \
	Brutus.png


Brutus_MAIN_MODEL_FILE = Brutus.gorm

include $(GNUSTEP_MAKEFILES)/application.make
