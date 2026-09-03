# CmdletBinding so an unknown argument is an error. Without it PowerShell
# silently ignores one, and a leftover -Publish would look like it worked.
[CmdletBinding()]
param(
    # Icon to embed in the Windows build. Passed straight to build.ps1.
    [string]$Icon
)

$ErrorActionPreference = "Stop"

<#
Test-SMTP deploy script

Builds every release artifact in one shot and leaves dist\ holding exactly the
release, named as it appears on GitHub Releases. Publishing is deliberately
manual; this script never touches GitHub.

Dependencies (required on build machine)

- Windows with PowerShell (this script drives build.ps1 directly)
- Docker, for the Linux build. PyInstaller is not a cross-compiler, so the
  Linux binary has to be built on Linux; the container is how we do that from
  Windows without a second machine.

Output
- dist\Test-SMTP.exe             Windows x86-64
- dist\Test-SMTP-linux-amd64     Linux x86-64, glibc 2.28+

Notes
- dist\ is wiped once here, not by the individual build scripts, so both
  binaries survive side by side and dist\ ends up holding exactly the release.
- The Linux build runs in almalinux:8 for its old glibc: glibc is forward-
  compatible only, so building there produces one binary that runs on Debian
  10+, Ubuntu 18.04+, and RHEL 8+. The manylinux images cannot be used, their
  Pythons have no shared libpython and PyInstaller requires one.
- Each binary is smoke-tested with --version. A build that produces a file but
  not a working program should not reach a release.
#>

# -- Paths ---------------------------------------------------------------------
$scriptDir = $PSScriptRoot
$source    = Join-Path $scriptDir "Test-SMTP.py"
$distDir   = Join-Path $scriptDir "dist"

$linuxImage = "almalinux:8"

# -- Version -------------------------------------------------------------------
# Single source of truth is __version__ in Test-SMTP.py, same as build.ps1.
$match = [regex]::Match((Get-Content $source -Raw), '(?m)^__version__\s*=\s*"([^"]+)"')
if (-not $match.Success) { throw "Could not find __version__ in $source" }
$version = $match.Groups[1].Value

Write-Output "Deploying Test-SMTP $version"

# -- Preflight -----------------------------------------------------------------
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker not found on PATH. It is required to build the Linux binary."
}
docker info *> $null
if ($LASTEXITCODE -ne 0) { throw "Docker is installed but not running. Start Docker Desktop." }

# Wiped once here so a stale artifact from an older version cannot ride along
# into a release. The build scripts only clean their own output file.
Remove-Item $distDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $distDir -Force | Out-Null

# -- Windows build -------------------------------------------------------------
Write-Output "`n=== Windows build ==="
$buildArgs = @{}
if ($Icon) { $buildArgs["Icon"] = $Icon }
& (Join-Path $scriptDir "build.ps1") @buildArgs
if ($LASTEXITCODE -ne 0) { throw "build.ps1 failed" }

$windowsExe = Join-Path $distDir "Test-SMTP.exe"
if (-not (Test-Path $windowsExe)) { throw "Windows build produced no EXE" }

& $windowsExe --version | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Windows binary failed its --version smoke test" }

# -- Linux build ---------------------------------------------------------------
# Build and smoke-test inside the same container run; the image is only pulled
# once and the binary never has to leave Linux to be verified.
Write-Output "`n=== Linux build ($linuxImage) ==="
docker run --rm -v "${scriptDir}:/src" -w /src $linuxImage `
    sh -c "dnf install -y python39 && PYTHON=python3.9 ./build.sh && ./dist/Test-SMTP --version"
if ($LASTEXITCODE -ne 0) { throw "Linux build failed" }

$linuxBin = Join-Path $distDir "Test-SMTP"
if (-not (Test-Path $linuxBin)) { throw "Linux build produced no binary" }

# build.sh names its output for running, not for releasing.
Rename-Item $linuxBin "Test-SMTP-linux-amd64"

# -- Summary -------------------------------------------------------------------
Write-Output "`n=== Artifacts ==="
Get-ChildItem $distDir | ForEach-Object {
    Write-Output ("  {0,-24} {1,10:N0} bytes" -f $_.Name, $_.Length)
}

Write-Output "`nReady for release $version. Upload both files from dist\ manually."
