ifeq ($(GNUSTEP_MAKEFILES),)
	GNUSTEP_MAKEFILES := $(shell gnustep-config \
		--variable=GNUSTEP_MAKEFILES 2>/dev/null)
endif
ifeq ($(GNUSTEP_MAKEFILES),)
	$(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = BrutusClient

BrutusClient_OBJC_FILES = BrutusClient.m \
		Service.m

include $(GNUSTEP_MAKEFILES)/application.make
