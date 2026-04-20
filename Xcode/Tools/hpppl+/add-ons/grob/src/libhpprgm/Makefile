PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

all:
	clang++ -arch $(ARCH) -std=c++23 -c src/*.cpp -Iinclude
	mkdir -p build
	mv *.o build
	mkdir -p lib
	ar rcs lib/$(PROJECT_NAME).a build/*.o

clean:
	rm -rf build
	rm l*.a
