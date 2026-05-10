.DEFAULT_GOAL := all

PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

CXX := clang++

CXXFLAGS := -std=c++23 -Iinclude

SRC := $(wildcard src/*.cpp)

ARM64_OBJ := $(patsubst src/%.cpp,build/arm64/%.o,$(SRC))
X86_64_OBJ := $(patsubst src/%.cpp,build/x86_64/%.o,$(SRC))
NATIVE_OBJ := $(patsubst src/%.cpp,build/$(ARCH)/%.o,$(SRC))

all: lib/$(PROJECT_NAME).a

lib/$(PROJECT_NAME).a: $(NATIVE_OBJ)
	mkdir -p lib
	libtool -static -o $@ $(NATIVE_OBJ)

arm64: lib/arm64/$(PROJECT_NAME).a

lib/arm64/$(PROJECT_NAME).a: $(ARM64_OBJ)
	mkdir -p lib/arm64
	libtool -static -o $@ $(ARM64_OBJ)

x86_64: lib/x86_64/$(PROJECT_NAME).a

lib/x86_64/$(PROJECT_NAME).a: $(X86_64_OBJ)
	mkdir -p lib/x86_64
	libtool -static -o $@ $(X86_64_OBJ)

universal: arm64 x86_64
	mkdir -p lib
	lipo -create \
		lib/arm64/$(PROJECT_NAME).a \
		lib/x86_64/$(PROJECT_NAME).a \
		-output lib/$(PROJECT_NAME).a

build/$(ARCH)/%.o: src/%.cpp
	mkdir -p $(dir $@)
	$(CXX) -arch $(ARCH) $(CXXFLAGS) -c $< -o $@

build/arm64/%.o: src/%.cpp
	mkdir -p $(dir $@)
	$(CXX) -arch arm64 $(CXXFLAGS) -c $< -o $@

build/x86_64/%.o: src/%.cpp
	mkdir -p $(dir $@)
	$(CXX) -arch x86_64 $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf build
	rm -rf lib

.PHONY: all arm64 x86_64 universal clean
