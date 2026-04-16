PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

all: arm64 x86_64 universal win_x86_64
 
arm64:
	mkdir -p build/arm64
	g++ -arch arm64 -std=c++23 \
	-I../../src/libhpprgm/include ../../src/libhpprgm/lib/arm64/libhpprgm.a \
	-Isrc/libpng/include \
	-Isrc/libz/include \
	src/*.cpp src/libpng/lib/arm64/libpng.a src/libz/lib/arm64/libz.a \
	-o build/arm64/$(PROJECT_NAME) -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-dead_strip -Wl,-x
	
x86_64:
	mkdir -p build/x86_64
	g++ -arch x86_64 -std=c++23 \
	-I../../src/libhpprgm/include ../../src/libhpprgm/lib/x86_64/libhpprgm.a \
	-Isrc/libpng/include \
	-Isrc/libz/include \
	src/*.cpp src/libpng/lib/x86_64/libpng.a src/libz/lib/x86_64/libz.a \
	-o build/x86_64/$(PROJECT_NAME) -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-dead_strip -Wl,-x
	
universal:
	# Combine into a universal binary
	lipo -create -output build/$(PROJECT_NAME) build/arm64/$(PROJECT_NAME) build/x86_64/$(PROJECT_NAME)
	
win_x86_64:
	mkdir -p build/win_x86_64
	x86_64-w64-mingw32-g++ \
	-std=c++23 \
	src/*.cpp \
	-I../../src/libhpprgm/include ../../src/libhpprgm/lib/win_x86_64/libhpprgm.a \
	-o build/win_x86_64/$(PROJECT_NAME).exe \
	-static -O2 -s
	
linux_x86_64:
	mkdir -p build/linux_x86_64
	x86_64-linux-musl-g++ \
	-std=c++23 \
	src/*.cpp \
	-I../../src/libhpprgm/include ../../src/libhpprgm/lib/linux_x86_64/libhpprgm.a \
	-o build/linux_x86_64/$(PROJECT_NAME) \
	-static -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-x

clean:
	rm -rf build/*

install:
	cp build/$(ARCH)/$(PROJECT_NAME) /usr/local/bin/$(PROJECT_NAME)
	
uninstall:
	rm /usr/local/bin/$(PROJECT_NAME)

