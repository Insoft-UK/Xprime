PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)
	
all:
	mkdir -p build
	g++ -arch $(ARCH) -std=c++23 \
	-I../../src/libhpprgm/include ../../src/libhpprgm/lib/libhpprgm.a \
	-Isrc/libpng/include \
	-Isrc/libz/include \
	src/*.cpp src/libpng/lib/$(ARCH)/libpng.a src/libz/lib/$(ARCH)/libz.a \
	-o build/$(PROJECT_NAME) -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-dead_strip -Wl,-x
	
clean:
	rm -rf build/*

install:
	cp build/$(PROJECT_NAME) /usr/local/bin/$(PROJECT_NAME)
	
uninstall:
	rm /usr/local/bin/$(PROJECT_NAME)

