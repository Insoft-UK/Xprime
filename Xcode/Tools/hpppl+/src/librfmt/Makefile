PROJECT_NAME := $(shell basename $(PWD))
ARCH := $(shell arch)

all:
	mkdir -p lib
	clang++ -arch $(ARCH) -std=c++23 -c src/*.cpp -Iinclude -I../libhpppl/include
	libtool -static -o lib/$(PROJECT_NAME).a *.o
	rm -f *.o

arm64:
	mkdir -p lib/arm64
	clang++ -arch arm64 -std=c++23 -c src/*.cpp -Iinclude -I../libhpppl/include
	libtool -static -o lib/arm64/$(PROJECT_NAME).a *.o
	rm -f *.o

x86_64:
	mkdir -p lib/x86_64
	clang++ -arch x86_64 -std=c++23 -c src/*.cpp -Iinclude -I../libhpppl/include
	libtool -static -o lib/x86_64/$(PROJECT_NAME).a *.o
	rm -f *.o

universal: arm64 x86_64
	mkdir -p lib
	lipo -create \
		-output lib/$(PROJECT_NAME).a \
		lib/arm64/$(PROJECT_NAME).a \
		lib/x86_64/$(PROJECT_NAME).a

clean:
	rm -rf lib
	rm -f *.o

.PHONY: all arm64 x86_64 universal clean
