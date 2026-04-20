PROJECT_NAME ?= hpnote
ARCH := $(shell arch)

all:
	mkdir -p build
	g++ -arch $(ARCH) -std=c++23 \
	src/*.cpp \
	-o build/$(PROJECT_NAME) -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-dead_strip -Wl,-x
	
clean:
	rm -rf build/*

install:
	cp build/$(PROJECT_NAME) /usr/local/bin/$(PROJECT_NAME)
	
uninstall:
	rm /usr/local/bin/$(PROJECT_NAME)
