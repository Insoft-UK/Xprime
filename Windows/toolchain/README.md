# Xprime Windows Toolchain

This folder adds a Windows-first CMake entry point for the portable Xprime C++ tools.

## Targets

- `hppplplus.exe`: PPL+/Pascal preprocessing, `.hpprgm` and `.hpappprgm` create/extract, compression, reformatting.
- `hpnote.exe`: `.md`, `.ntf`, `.rtf`, `.hpnote`, and `.hpappnote` conversion.
- `font.exe`: Adafruit GFX font conversion add-on.
- `grob.exe`: bitmap/image conversion add-on when PNG/ZLIB development packages are available.

## Configure

```powershell
cmake -S .\Windows\toolchain -B .\Windows\toolchain\build -G "MinGW Makefiles" -DCMAKE_CXX_COMPILER=C:\msys64\ucrt64\bin\g++.exe
cmake --build .\Windows\toolchain\build
cmake --install .\Windows\toolchain\build --prefix .\Windows\src\Xprime.Windows\bin\Release\net9.0-windows
```

The WPF app expects the executables under `tools\bin` beside the app binary. MSVC is also supported by the CMake layout once Visual Studio Build Tools are installed.

## Known Porting Notes

- The upstream macOS Makefiles link prebuilt `.a` libraries; this CMake build compiles the library sources directly.
- The `grob` target intentionally requires real PNG/ZLIB packages instead of linking the upstream macOS static archives.
- Console output is expected to be UTF-8 so that PPL symbols and note text survive round trips.
