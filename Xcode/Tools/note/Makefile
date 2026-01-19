PROJECT_NAME ?= note
ARCH := $(shell arch)

all: arm64 x86_64 universal win_x86_64

arm64:
	mkdir -p build/arm64
	g++ -arch arm64 -std=c++23 \
	src/*.cpp \
	-o build/arm64/$(PROJECT_NAME) -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-dead_strip -Wl,-x
	
x86_64:
	mkdir -p build/x86_64
	g++ -arch x86_64 -std=c++23 \
	src/*.cpp \
	-o build/x86_64/$(PROJECT_NAME) -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-dead_strip -Wl,-x

universal:
	# Combine into a universal binary
	lipo -create -output build/$(PROJECT_NAME) build/arm64/$(PROJECT_NAME) build/x86_64/$(PROJECT_NAME)
	
win_x86_64:
	x86_64-w64-mingw32-g++ \
    -std=c++23 \
	-Isrc src/*.cpp \
    -o build/$(PROJECT_NAME).exe -static -O2 -s
	
clean:
	rm -rf build/*

install:
	cp build/$(ARCH)/$(PROJECT_NAME) /usr/local/bin/$(PROJECT_NAME)
	
uninstall:
	rm /usr/local/bin/$(PROJECT_NAME)
