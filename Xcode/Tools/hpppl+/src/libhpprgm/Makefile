PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

all:
	mkdir -p lib
	clang++ -arch $(ARCH) -std=c++23 -c src/*.cpp -Iinclude
	libtool -static -o lib/$(PROJECT_NAME).a *.o
	rm *.o
	
clean:
	rm -rf build
	rm l*.a
	
	
