.DEFAULT_GOAL := all

PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

CXX := clang++

CXXFLAGS := -std=c++23 -Os -fno-ident -fno-asynchronous-unwind-tables
LDFLAGS := -licucore -Wl,-dead_strip -Wl,-x

SRC := src/*.cpp

all: arm64 x86_64 uninstall win_x86_64

native:
	mkdir -p build
	$(CXX) -arch $(ARCH) $(CXXFLAGS) \
		$(SRC) \
		-o build/$(PROJECT_NAME) \
		$(LDFLAGS)

arm64:
	mkdir -p build/arm64
	$(CXX) -arch arm64 $(CXXFLAGS) \
		$(SRC) \
		-o build/arm64/$(PROJECT_NAME) \
		$(LDFLAGS)
	
x86_64:
	mkdir -p build/x86_64
	$(CXX) -arch x86_64 $(CXXFLAGS) \
		$(SRC) \
		-o build/x86_64/$(PROJECT_NAME) \
		$(LDFLAGS)
		
universal: arm64 x86_64
	lipo -create \
		-output build/$(PROJECT_NAME) \
		build/arm64/$(PROJECT_NAME) \
		build/x86_64/$(PROJECT_NAME)
		
win_x86_64:
	x86_64-w64-mingw32-g++ $(CXXFLAGS) \
		$(SRC) \
		-o build/$(PROJECT_NAME).exe \
		-static -O2 -s
	
clean:
	rm -rf build/*

install:
	cp build/$(PROJECT_NAME) /usr/local/bin/$(PROJECT_NAME)
	
uninstall:
	rm /usr/local/bin/$(PROJECT_NAME)
	
.PHONY: all native arm64 x86_64 universal win_x86_64 clean install uninstall
