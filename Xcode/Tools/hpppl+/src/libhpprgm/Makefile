PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

all:
	mkdir -p lib
	clang++ -arch $(ARCH) -std=c++23 -c src/*.cpp -Iinclude
	libtool -static -o lib/$(PROJECT_NAME).a *.o
	rm *.o
	
arm64:
	mkdir -p lib/arm64
	clang++ -arch arm64 -std=c++23 -c src/*.cpp -Iinclude
	libtool -static -o lib/arm64/$(PROJECT_NAME).a *.o
	rm *.o
	
x86_64:
	mkdir -p lib/x86_64
	clang++ -arch x86_64 -std=c++23 -c src/*.cpp -Iinclude
	libtool -static -o lib/x86_64/$(PROJECT_NAME).a *.o
	rm *.o
	
universal: arm64 x86_64
	
clean:
	rm -rf build
	rm l*.a
	
	
