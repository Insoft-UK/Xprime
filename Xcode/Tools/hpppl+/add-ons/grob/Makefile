.DEFAULT_GOAL := all

PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

CXX := clang++
CXXWIN := x86_64-w64-mingw32-g++
CXXLINUX := x86_64-linux-musl-g++

CXXFLAGS := -std=c++23 -Os -fno-ident -fno-asynchronous-unwind-tables
LDFLAGS := -Wl,-dead_strip -Wl,-x

INCLUDES := \
	-I../../src/libpng/include \
	-I../../src/libz/include

LIBPNG := \
	../../src/libpng/lib
	
LIBZ := \
	../../src/libz/lib
	
SRC := \
	src/*.cpp
	

all: arm64 x86_64 universal

native:
	mkdir -p build
	$(CXX) -arch $(ARCH) $(CXXFLAGS) \
		$(INCLUDES) \
		$(SRC) \
		$(LIBPNG)/$(ARCH)/libpng.a \
		$(LIBZ)/$(ARCH)/libz.a \
		-o build/$(PROJECT_NAME) \
		$(LDFLAGS)

arm64:
	mkdir -p build/arm64
	$(CXX) -arch arm64 $(CXXFLAGS) \
		$(INCLUDES) \
		$(SRC) \
		$(LIBPNG)/arm64/libpng.a \
		$(LIBZ)/arm64/libz.a \
		-o build/arm64/$(PROJECT_NAME) \
		$(LDFLAGS)

x86_64:
	mkdir -p build/x86_64
	$(CXX) -arch x86_64 $(CXXFLAGS) \
		$(INCLUDES) \
		$(SRC) \
		$(LIBPNG)/x86_64/libpng.a \
		$(LIBZ)/x86_64/libz.a \
		-o build/x86_64/$(PROJECT_NAME) \
		$(LDFLAGS)
		
win_x86_64:
	mkdir -p build/win_x86_64
	$(CXXWIN) -std=c++23 \
		$(INCLUDES) \
		$(SRC) \
		$(LIBPNG)/win_x86_64/libpng.a \
		$(LIBZ)/win_x86_64/libz.a \
		-o build/win_x86_64/$(PROJECT_NAME).exe \
		-static -O2 -s

linux_x86_64:
	mkdir -p build/linux_x86_64
	$(CXXLINUX) $(CXXFLAGS) \
		$(INCLUDES) \
		$(SRC) \
		$(LIBPNG)/linux_x86_64/libpng.a \
		$(LIBZ)/linux_x86_64/libz.a \
		-o build/linux_x86_64/$(PROJECT_NAME) \
		-static -Wl,-x

universal:
	lipo -create \
		-output build/$(PROJECT_NAME) \
		build/arm64/$(PROJECT_NAME) \
		build/x86_64/$(PROJECT_NAME)

clean:
	rm -rf build

install:
	cp build/$(PROJECT_NAME) /usr/local/bin/$(PROJECT_NAME)

uninstall:
	rm -f /usr/local/bin/$(PROJECT_NAME)

.PHONY: all native arm64 x86_64 universal clean install uninstall
