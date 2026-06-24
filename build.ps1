param(
    # Icon to embed. Defaults to icon.ico beside this script if present.
    [string]$Icon
)

$ErrorActionPreference = "Stop"

<#
Test-SMTP build script

Dependencies (required on build machine)

Python
- Python 3 (64-bit), on PATH as 'python' or via the 'py' launcher

Python packages
- pyinstaller (current release; installed automatically below)

Output
- Final distributable:
    dist\Test-SMTP.exe

- Single self-contained executable (PyInstaller onefile)
- No external dependencies required on target system

Notes
- Build on Windows. PyInstaller is not a cross-compiler.
- Console app (--console); do not build windowed.
- No .spec file: PyInstaller is driven directly from the flags below so
  there is one fewer file to keep in sync. icon.ico is embedded if present.
#>

# -- Paths ---------------------------------------------------------------------
$scriptDir = $PSScriptRoot
$source    = Join-Path $scriptDir "Test-SMTP.py"
$verFile   = Join-Path $scriptDir "version_info.txt"

# Icon: -Icon arg wins, else icon.ico beside the script if it exists.
$iconFile = if ($Icon) { $Icon } else { Join-Path $scriptDir "icon.ico" }
if ($Icon -and -not (Test-Path $iconFile)) { throw "Icon not found: $iconFile" }

# Version pulled from __version__ in the source, used in the output filename.
$verMatch = Select-String -Path $source -Pattern '__version__\s*=\s*"([^"]+)"'
if (-not $verMatch) { throw "Could not find __version__ in $source" }
$version = $verMatch.Matches[0].Groups[1].Value

# Python (prefer 'python', fall back to the 'py' launcher)
$py = $null
foreach ($candidate in @("python", "py")) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) { $py = $candidate; break }
}
if (-not $py) { throw "Python 3 not found on PATH" }

$pyBits = & $py "-c" "import struct; print(struct.calcsize('P') * 8)"
if ($pyBits -ne "64") {
    Write-Warning "Python at '$py' is $pyBits-bit. The EXE will match; build with 64-bit for current fleets."
}

# Output
$distDir   = Join-Path $scriptDir "dist"
$exeName   = "Test-SMTP-$version"
$outputExe = Join-Path $distDir "$exeName.exe"

# -- Clean ---------------------------------------------------------------------
Remove-Item $distDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $distDir -Force | Out-Null

# -- Install deps --------------------------------------------------------------
& $py "-m" "pip" "install" "--upgrade" "pyinstaller"
if ($LASTEXITCODE -ne 0) { throw "pyinstaller install failed" }

# -- Build EXE -----------------------------------------------------------------
$pyiArgs = @(
    "-m", "PyInstaller",
    "--clean", "--noconfirm",
    "--onefile", "--console",
    "--name", $exeName,
    "--version-file", $verFile,
    # Stdlib modules PyInstaller auto-pulls but this script never uses. Trims a
    # couple MB. Safe given the imports (os/ssl/smtplib/socket/argparse/email).
    "--exclude-module", "tkinter",
    "--exclude-module", "unittest",
    "--exclude-module", "pydoc",
    "--exclude-module", "lib2to3",
    "--exclude-module", "test"
)
if (Test-Path $iconFile) { $pyiArgs += @("--icon", $iconFile) }
$pyiArgs += $source

& $py @pyiArgs
if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed" }

if (-not (Test-Path $outputExe)) {
    throw "EXE not found after build: $outputExe"
}

Copy-Item $outputExe (Join-Path $scriptDir "$exeName.exe") -Force

Write-Output "Done: $outputExe"
