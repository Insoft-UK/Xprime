.DEFAULT_GOAL := all

PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

CXX := clang++

CXXFLAGS := -std=c++23 -Os -fno-ident -fno-asynchronous-unwind-tables
LDFLAGS := -Wl,-dead_strip -Wl,-x

INCLUDES := \
	-I../../src/libhpprgm/include \
	-Isrc/libpng/include \
	-Isrc/libz/include

SRC := src/*.cpp

all: arm64 x86_64 universal

native:
	mkdir -p build
	$(CXX) -arch $(ARCH) $(CXXFLAGS) \
		$(INCLUDES) \
		../../src/libhpprgm/lib/$(ARCH)/libhpprgm.a \
		$(SRC) \
		src/libpng/lib/$(ARCH)/libpng.a \
		src/libz/lib/$(ARCH)/libz.a \
		-o build/$(PROJECT_NAME) \
		$(LDFLAGS)

arm64:
	mkdir -p build/arm64
	$(CXX) -arch arm64 $(CXXFLAGS) \
		$(INCLUDES) \
		../../src/libhpprgm/lib/arm64/libhpprgm.a \
		$(SRC) \
		src/libpng/lib/arm64/libpng.a \
		src/libz/lib/arm64/libz.a \
		-o build/arm64/$(PROJECT_NAME) \
		$(LDFLAGS)

x86_64:
	mkdir -p build/x86_64
	$(CXX) -arch x86_64 $(CXXFLAGS) \
		$(INCLUDES) \
		../../src/libhpprgm/lib/x86_64/libhpprgm.a \
		$(SRC) \
		src/libpng/lib/x86_64/libpng.a \
		src/libz/lib/x86_64/libz.a \
		-o build/x86_64/$(PROJECT_NAME) \
		$(LDFLAGS)

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
