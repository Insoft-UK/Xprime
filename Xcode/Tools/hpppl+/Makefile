PROJECT_NAME := hpppl+
ARCH := $(shell arch)

all:
	mkdir -p build
	clang++ -arch arm64 -std=c++23 \
	-Isrc src/*.cpp \
	-Isrc/libhpppl/include src/libhpppl/lib/libhpppl.a \
	-Isrc/librfmt/include src/librfmt/lib/librfmt.a \
	-Isrc/libmin/include src/libmin/lib/libmin.a \
	-Isrc/libhpprgm/include src/libhpprgm/lib/libhpprgm.a \
	-Isrc/common/include \
	-o build/$(PROJECT_NAME) -licucore -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-dead_strip -Wl,-x

clean:
	rm -rf build/*
	
install:
	cp build/$(PROJECT_NAME) /usr/local/bin/$(PROJECT_NAME)
	
uninstall:
	rm /usr/local/bin/$(PROJECT_NAME)
