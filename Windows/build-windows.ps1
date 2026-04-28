param(
    [string]$Generator = "MinGW Makefiles",
    [string]$Compiler = "C:\msys64\ucrt64\bin\g++.exe",
    [string]$CMakePrefixPath = "C:\msys64\ucrt64",
    [switch]$SkipNative
)

$ErrorActionPreference = "Stop"

$WindowsRoot = $PSScriptRoot
$RepoRoot = Resolve-Path (Join-Path $WindowsRoot "..")
$Solution = Join-Path $WindowsRoot "Xprime.Windows.sln"
$ToolchainRoot = Join-Path $WindowsRoot "toolchain"
$AppProjectRoot = Join-Path $WindowsRoot "src\Xprime.Windows"
$ToolProject = Join-Path $WindowsRoot "src\Xprime.Windows.Tools\Xprime.Windows.Tools.csproj"
$ToolSource = Join-Path $AppProjectRoot "tools\bin"
$HelpOutput = Join-Path $AppProjectRoot "Resources\HelpWindowsSafe"
$DebugAppRoot = Join-Path $AppProjectRoot "bin\Debug\net9.0-windows"
$ReleaseAppRoot = Join-Path $AppProjectRoot "bin\Release\net9.0-windows"
$DebugBuild = Join-Path $ToolchainRoot "build"
$ReleaseBuild = Join-Path $ToolchainRoot "build-release"

function Build-NativeTools {
    param(
        [string]$BuildDirectory,
        [string]$BuildType
    )

    $configure = @(
        "-S", $ToolchainRoot,
        "-B", $BuildDirectory,
        "-G", $Generator,
        "-DCMAKE_CXX_COMPILER=$Compiler"
    )

    if ($BuildType) {
        $configure += "-DCMAKE_BUILD_TYPE=$BuildType"
    }

    if ($CMakePrefixPath -and (Test-Path -LiteralPath $CMakePrefixPath)) {
        $configure += "-DCMAKE_PREFIX_PATH=$CMakePrefixPath"
    }

    cmake @configure
    $targets = @("hppplplus", "hpnote", "font")
    if ($CMakePrefixPath -and (Test-Path -LiteralPath (Join-Path $CMakePrefixPath "include\png.h")) -and (Test-Path -LiteralPath (Join-Path $CMakePrefixPath "include\zlib.h"))) {
        $targets += "grob"
    }

    cmake --build $BuildDirectory --target @targets -- -j2
}

if (-not $SkipNative) {
    Build-NativeTools -BuildDirectory $DebugBuild -BuildType ""
    Build-NativeTools -BuildDirectory $ReleaseBuild -BuildType "Release"
}

New-Item -ItemType Directory -Force -Path $ToolSource | Out-Null
Copy-Item -LiteralPath (Join-Path $DebugBuild "hppplplus.exe") -Destination $ToolSource -Force
Copy-Item -LiteralPath (Join-Path $DebugBuild "hpnote.exe") -Destination $ToolSource -Force
Copy-Item -LiteralPath (Join-Path $DebugBuild "font.exe") -Destination $ToolSource -Force
if (Test-Path -LiteralPath (Join-Path $DebugBuild "grob.exe")) {
    Copy-Item -LiteralPath (Join-Path $DebugBuild "grob.exe") -Destination $ToolSource -Force
}

dotnet build $Solution -c Debug
dotnet run --project $ToolProject -- convert-help --repo $RepoRoot --out $HelpOutput --treeish HEAD
dotnet build $Solution -c Debug
dotnet build $Solution -c Release
dotnet run --project $ToolProject -- verify --repo $RepoRoot --app-root $DebugAppRoot --smoke (Join-Path $DebugBuild "smoke")
dotnet run --project $ToolProject -- verify --repo $RepoRoot --app-root $ReleaseAppRoot --smoke (Join-Path $ReleaseBuild "smoke")

Write-Host "Xprime Windows build and verification completed."
