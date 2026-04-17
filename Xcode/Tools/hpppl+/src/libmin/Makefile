PROJECT_NAME := $(shell basename $(PWD))

all: arm64
	
arm64:
	mkdir -p lib
	clang++ -arch arm64 -std=c++23 -c src/*.cpp -Iinclude -I../libhpppl/include
	libtool -static -o lib/$(PROJECT_NAME).a *.o
	rm *.o

clean:
	rm -rf build
	
	
