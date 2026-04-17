PROJECT_NAME := $(shell basename $(PWD))

all: arm64 x86_64 universal
	
arm64:
	clang++ -arch arm64 -std=c++23 -c src/*.cpp -Iinclude
	mkdir -p build/arm64
	mv *.o build/arm64
	mkdir -p lib/arm64
	ar rcs lib/arm64/$(PROJECT_NAME).a build/arm64/*.o
	
x86_64:
	clang++ -arch x86_64 -std=c++23 -c src/*.cpp -Iinclude
	mkdir -p build/x86_64
	mv *.o build/x86_64
	mkdir -p lib/x86_64
	ar rcs lib/x86_64/$(PROJECT_NAME).a build/x86_64/*.o
	
win_x86_64:
	x86_64-w64-mingw32-g++ -std=c++23 -c src/*.cpp -Iinclude
	mkdir -p build/win_x86_64
	mv *.o build/win_x86_64
	mkdir -p lib/win_x86_64
	ar rcs lib/win_x86_64/$(PROJECT_NAME).a build/win_x86_64/*.o
	x86_64-w64-mingw32-ranlib lib/win_x86_64/$(PROJECT_NAME).a

universal:
	lipo -create \
	    lib/arm64/$(PROJECT_NAME).a \
		lib/x86_64/$(PROJECT_NAME).a \
		-output lib/$(PROJECT_NAME).a

clean:
	rm -rf build
	rm l*.a
	
	
