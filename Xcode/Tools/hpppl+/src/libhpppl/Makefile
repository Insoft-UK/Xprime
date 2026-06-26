.DEFAULT_GOAL := all

PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

CXX := clang++

CXXFLAGS := -std=c++23 -c
	
INCLUDES := -Iinclude

SRC := $(wildcard src/*.cpp)

all: arm64 x86_64 universal

native:
	mkdir -p lib
	$(CXX) -arch $(ARCH) $(CXXFLAGS) \
	$(INCLUDES) \
	$(SRC)
	libtool -static -o lib/$(PROJECT_NAME).a *.o
	rm -f *.o

arm64:
	mkdir -p lib/arm64
	$(CXX) -arch arm64 $(CXXFLAGS) \
	$(INCLUDES) \
	$(SRC)
	libtool -static -o lib/arm64/$(PROJECT_NAME).a *.o
	rm -f *.o

x86_64:
	mkdir -p lib/x86_64
	$(CXX) -arch x86_64 $(CXXFLAGS) \
	$(INCLUDES) \
	$(SRC)
	libtool -static -o lib/x86_64/$(PROJECT_NAME).a *.o
	rm -f *.o

universal:
	mkdir -p lib
	lipo -create \
		-output lib/$(PROJECT_NAME).a \
		lib/arm64/$(PROJECT_NAME).a \
		lib/x86_64/$(PROJECT_NAME).a

clean:
	rm -rf lib
	rm -f *.o

.PHONY: all arm64 x86_64 universal clean
