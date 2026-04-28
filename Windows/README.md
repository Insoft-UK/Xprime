# Xprime.Windows

Windows replication scaffold for the upstream Xprime HP Prime editor.

Upstream snapshot: `d01ebca9f2c5504daf9b51803f1c3626c541a252`

## Layout

- `Xprime.Windows.sln`: .NET solution.
- `src/Xprime.Windows`: WPF app targeting `net9.0-windows`.
- `src/Xprime.Windows.Core`: project, toolchain, archive, and install services.
- `toolchain`: CMake wrapper that builds the upstream C++ tools as Windows executables.

## Build The App

Full repeatable build, conversion, and verification:

```powershell
.\experimental\Windows\build-windows.ps1
```

Use `-SkipNative` if the native C++ tools are already built and copied from the last run.
By default the script points CMake at `C:\msys64\ucrt64` for PNG/ZLIB, which lets `grob.exe` build on this machine.

```powershell
dotnet build .\experimental\Windows\Xprime.Windows.sln -c Debug
dotnet build .\experimental\Windows\Xprime.Windows.sln -c Release
```

The WPF project copies `src\Xprime.Windows\tools\bin\*.exe` to the app output. Rebuild the native tools first when tool sources change.

## Build The Native Tools

Debug-style MinGW build:

```powershell
cmake -S .\experimental\Windows\toolchain -B .\experimental\Windows\toolchain\build -G "MinGW Makefiles" -DCMAKE_CXX_COMPILER=C:\msys64\ucrt64\bin\g++.exe -DCMAKE_PREFIX_PATH=C:\msys64\ucrt64
cmake --build .\experimental\Windows\toolchain\build --target hppplplus hpnote font grob -- -j2
```

Release MinGW build:

```powershell
cmake -S .\experimental\Windows\toolchain -B .\experimental\Windows\toolchain\build-release -G "MinGW Makefiles" -DCMAKE_CXX_COMPILER=C:\msys64\ucrt64\bin\g++.exe -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=C:\msys64\ucrt64
cmake --build .\experimental\Windows\toolchain\build-release --target hppplplus hpnote font grob -- -j2
```

`grob.exe` is generated when PNG/ZLIB development packages are discoverable by CMake. On this machine, `-DCMAKE_PREFIX_PATH=C:\msys64\ucrt64` resolves them.

## Copy Tools Into The App

```powershell
New-Item -ItemType Directory -Force .\experimental\Windows\src\Xprime.Windows\tools\bin
Copy-Item .\experimental\Windows\toolchain\build\hppplplus.exe, .\experimental\Windows\toolchain\build\hpnote.exe, .\experimental\Windows\toolchain\build\font.exe, .\experimental\Windows\toolchain\build\grob.exe .\experimental\Windows\src\Xprime.Windows\tools\bin -Force
dotnet build .\experimental\Windows\Xprime.Windows.sln -c Debug
```

## Smoke Tests

```powershell
$smoke = 'E:\Projects\HPPrimeCoder\experimental\Windows\toolchain\build\smoke'
$tool = 'E:\Projects\HPPrimeCoder\experimental\Windows\src\Xprime.Windows\bin\Debug\net9.0-windows\tools\bin\hppplplus.exe'
$include = 'E:\Projects\HPPrimeCoder\experimental\Xcode\Xprime\Resources\Developer\usr\include'
$lib = 'E:\Projects\HPPrimeCoder\experimental\Xcode\Xprime\Resources\Developer\usr\lib'
New-Item -ItemType Directory -Force -Path $smoke
Push-Location .\experimental\Examples\Graphics
& $tool '.\main.hppplplus' -o (Join-Path $smoke 'Graphics.hpprgm') "-I$include" "-L$lib"
Pop-Location
```

Expected result: `Graphics.hpprgm` is generated under `toolchain\build\smoke`.

Or run the bundled verifier:

```powershell
dotnet run --project .\experimental\Windows\src\Xprime.Windows.Tools\Xprime.Windows.Tools.csproj -- verify --repo .\experimental --app-root .\experimental\Windows\src\Xprime.Windows\bin\Debug\net9.0-windows --smoke .\experimental\Windows\toolchain\build\smoke
```

## Windows-safe Help Conversion

The upstream help folder contains filenames that Windows cannot materialize, such as `*.txt`, `<.txt`, and `>.txt`. The Windows port reads those files from Git blobs and writes a safe resource catalog:

```powershell
dotnet run --project .\experimental\Windows\src\Xprime.Windows.Tools\Xprime.Windows.Tools.csproj -- convert-help --repo .\experimental --out .\experimental\Windows\src\Xprime.Windows\Resources\HelpWindowsSafe --treeish HEAD
```

The generated `manifest.json` preserves each original path while the app reads the safe filenames.

## Current Limitations

- Seven upstream help files cannot be checked out as normal Windows files because their names contain Windows-invalid characters.
- The WPF shell now covers project open/save, source editing, build, app build, archive, install dry-run/overwrite, help browsing, theme loading, snippet insertion, and converted binary views. It is not yet a pixel-for-pixel port of every Cocoa panel.
- MSVC builds have not been completed yet; the verified native build path is MinGW.
- `grob.exe` requires PNG/ZLIB setup; verified here with MSYS2 UCRT64.
