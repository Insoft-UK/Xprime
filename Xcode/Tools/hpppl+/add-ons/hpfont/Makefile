.DEFAULT_GOAL := all

PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

CXX := clang++
CXXWIN := x86_64-w64-mingw32-g++
CXXLINUX := x86_64-linux-musl-g++

CXXFLAGS := -std=c++23 -Os -fno-ident -fno-asynchronous-unwind-tables
LDFLAGS := -licucore -Wl,-dead_strip -Wl,-x

SRC := src/*.cpp
	
all: arm64 x86_64 universal

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
		
win_x86_64:
	mkdir -p build/win_x86_64
	$(CXXWIN) -std=c++23 \
		$(INCLUDES) \
		$(SRC) \
		-o build/win_x86_64/$(PROJECT_NAME).exe \
		-static -O2 -s

linux_x86_64:
	mkdir -p build/linux_x86_64
	$(CXXLINUX) $(CXXFLAGS) \
		$(INCLUDES) \
		$(SRC) \
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
