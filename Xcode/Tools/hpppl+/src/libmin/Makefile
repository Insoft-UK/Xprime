PROJECT_NAME := $(shell basename $(PWD))

all: arm64 x86_64
	
arm64:
	mkdir -p lib/arm64
	clang++ -arch arm64 -std=c++23 -c src/*.cpp -Iinclude -I../libhpppl/include
	libtool -static -o lib/arm64/$(PROJECT_NAME).a *.o
	rm *.o
	
x86_64:
	mkdir -p lib/x86_64
	clang++ -arch x86_64 -std=c++23 -c src/*.cpp -Iinclude -I../libhpppl/include
	libtool -static -o lib/x86_64/$(PROJECT_NAME).a *.o
	rm *.o

clean:
	rm -rf build
	
	
