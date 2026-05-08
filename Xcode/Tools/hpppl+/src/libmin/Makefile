.DEFAULT_GOAL := all

PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

CXX := clang++

CXXFLAGS := -std=c++23 \
	-Iinclude \
	-I../libhpppl/include

SRC := src/*.cpp
OBJ := *.o

all:
	mkdir -p lib
	$(CXX) -arch $(ARCH) $(CXXFLAGS) -c $(SRC)
	libtool -static -o lib/$(PROJECT_NAME).a $(OBJ)
	rm -f $(OBJ)

arm64:
	mkdir -p lib/arm64
	$(CXX) -arch arm64 $(CXXFLAGS) -c $(SRC)
	libtool -static -o lib/arm64/$(PROJECT_NAME).a $(OBJ)
	rm -f $(OBJ)

x86_64:
	mkdir -p lib/x86_64
	$(CXX) -arch x86_64 $(CXXFLAGS) -c $(SRC)
	libtool -static -o lib/x86_64/$(PROJECT_NAME).a $(OBJ)
	rm -f $(OBJ)

universal: arm64 x86_64
	mkdir -p lib
	lipo -create \
		-output lib/$(PROJECT_NAME).a \
		lib/arm64/$(PROJECT_NAME).a \
		lib/x86_64/$(PROJECT_NAME).a

clean:
	rm -rf lib
	rm -f $(OBJ)

.PHONY: all arm64 x86_64 universal clean
