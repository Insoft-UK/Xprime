.DEFAULT_GOAL := all

PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

CXX := clang++

CXXFLAGS := -std=c++23 -Os -fno-ident -fno-asynchronous-unwind-tables
LDFLAGS := -licucore -Wl,-dead_strip -Wl,-x

INCLUDES := \
	-Isrc \
	-Isrc/libhpppl/include \
	-Isrc/librfmt/include \
	-Isrc/libmin/include \
	-Isrc/libhpprgm/include \
	-Isrc/common/include

SRC := src/*.cpp

all:
	mkdir -p build
	$(CXX) -arch $(ARCH) $(CXXFLAGS) \
		$(INCLUDES) \
		$(SRC) \
		src/libhpppl/lib/$(ARCH)/libhpppl.a \
		src/librfmt/lib/$(ARCH)/librfmt.a \
		src/libmin/lib/$(ARCH)/libmin.a \
		src/libhpprgm/lib/$(ARCH)/libhpprgm.a \
		-o build/$(PROJECT_NAME) \
		$(LDFLAGS)

arm64:
	mkdir -p build/arm64
	$(CXX) -arch arm64 $(CXXFLAGS) \
		$(INCLUDES) \
		$(SRC) \
		src/libhpppl/lib/arm64/libhpppl.a \
		src/librfmt/lib/arm64/librfmt.a \
		src/libmin/lib/arm64/libmin.a \
		src/libhpprgm/lib/arm64/libhpprgm.a \
		-o build/arm64/$(PROJECT_NAME) \
		$(LDFLAGS)

x86_64:
	mkdir -p build/x86_64
	$(CXX) -arch x86_64 $(CXXFLAGS) \
		$(INCLUDES) \
		$(SRC) \
		src/libhpppl/lib/x86_64/libhpppl.a \
		src/librfmt/lib/x86_64/librfmt.a \
		src/libmin/lib/x86_64/libmin.a \
		src/libhpprgm/lib/x86_64/libhpprgm.a \
		-o build/x86_64/$(PROJECT_NAME) \
		$(LDFLAGS)

universal: arm64 x86_64
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

.PHONY: all arm64 x86_64 universal clean install uninstall
