PROJECT_NAME := ppl+
ARCH := $(shell arch)

all: arm64 x86_64 universal

arm64:
	mkdir -p build/arm64
	clang++ -arch arm64 -std=c++23 \
	-Isrc src/*.cpp \
	-Isrc/libppl/include src/libppl/lib/arm64/libppl.a \
	-Isrc/librfmt/include src/librfmt/lib/arm64/librfmt.a \
	-Isrc/libmin/include src/libmin/lib/arm64/libmin.a \
	-Isrc/libhpprgm/include src/libhpprgm/lib/arm64/libhpprgm.a \
	-Isrc/common/include \
	-o build/arm64/$(PROJECT_NAME) -licucore -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-dead_strip -Wl,-x

x86_64:
	mkdir -p build/x86_64
	clang++ -arch x86_64 -std=c++23 \
	-Isrc src/*.cpp \
	-Isrc/libppl/include src/libppl/lib/x86_64/libppl.a \
	-Isrc/librfmt/include src/librfmt/lib/x86_64/librfmt.a \
	-Isrc/libmin/include src/libmin/lib/x86_64/libmin.a \
	-Isrc/libhpprgm/include src/libhpprgm/lib/x86_64/libhpprgm.a \
	-Isrc/common/include \
	-o build/x86_64/$(PROJECT_NAME) -licucore -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-dead_strip -Wl,-x
	
win_x86_64:
	mkdir -p build/win_x86_64
	x86_64-w64-mingw32-g++ \
	-std=c++23 \
	-Isrc src/*.cpp \
	-Isrc/libppl/include src/libppl/lib/win_x86_64/libppl.a \
	-Isrc/libhpprgm/include src/libhpprgm/lib/win_x86_64/libhpprgm.a \
	-Isrc/librfmt/include src/librfmt/lib/win_x86_64/librfmt.a \
	-Isrc/libmin/include src/libmin/lib/win_x86_64/libmin.a \
	-Isrc/common/include \
	-o build/win_x86_64/ppl+.exe -static -O2 -s
	
linux_x86_64:
	mkdir -p build/linux_x86_64
	x86_64-linux-musl-g++ \
	-std=c++23 \
	-Isrc src/*.cpp \
	-Isrc/libppl/include src/libppl/lib/linux_x86_64/libppl.a \
	-Isrc/libhpprgm/include src/libhpprgm/lib/linux_x86_64/libhpprgm.a \
	-Isrc/librfmt/include src/librfmt/lib/linux_x86_64/librfmt.a \
	-Isrc/libmin/include src/libmin/lib/linux_x86_64/libmin.a \
	-Isrc/common/include \
	-static -o build/linux_x86_64/$(PROJECT_NAME) -Os -fno-ident -fno-asynchronous-unwind-tables -Wl,-x

universal:
	# Combine into a universal binary
	lipo -create -output build/$(PROJECT_NAME) build/arm64/$(PROJECT_NAME) build/x86_64/$(PROJECT_NAME)
	
clean:
	rm -rf build/*
	
install:
	cp build/$(ARCH)/$(PROJECT_NAME) /usr/local/bin/$(PROJECT_NAME)
	
uninstall:
	rm /usr/local/bin/$(PROJECT_NAME)
