.DEFAULT_GOAL := all

PROJECT_NAME ?= $(shell basename $(PWD))
ARCH := $(shell arch)
CXXFLAGS := -std=c++23 -Os -fno-ident -fno-asynchronous-unwind-tables
LDFLAGS := -Wl,-dead_strip -Wl,-x

all:
	mkdir -p build
	g++ -arch $(ARCH) $(CXXFLAGS) \
		src/*.cpp \
		-o build/$(PROJECT_NAME) $(LDFLAGS)

arm64:
	mkdir -p build/arm64
	g++ -arch arm64 $(CXXFLAGS) \
		src/*.cpp \
		-o build/arm64/$(PROJECT_NAME) $(LDFLAGS)

x86_64:
	mkdir -p build/x86_64
	g++ -arch x86_64 $(CXXFLAGS) \
		src/*.cpp \
		-o build/x86_64/$(PROJECT_NAME) $(LDFLAGS)

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
