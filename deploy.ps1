param(
    # Icon to embed in the Windows build. Passed straight to build.ps1.
    [string]$Icon,

    # Create or update the GitHub release and upload both binaries.
    # Without this, deploy.ps1 only builds and stages them in release\.
    [switch]$Publish
)

$ErrorActionPreference = "Stop"

<#
Test-SMTP deploy script

Builds every release artifact in one shot and stages them under release\ with
the names used on GitHub Releases.

Dependencies (required on build machine)

- Windows with PowerShell (this script drives build.ps1 directly)
- Docker, for the Linux build. PyInstaller is not a cross-compiler, so the
  Linux binary has to be built on Linux; the container is how we do that from
  Windows without a second machine.
- gh (GitHub CLI), only when -Publish is passed.

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
- Each binary is smoke-tested with --version before it is staged. A build that
  produces a file but not a working program should not reach a release.
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
$tag     = $version   # existing tags are bare version numbers, no 'v' prefix

Write-Output "Deploying Test-SMTP $version"

# -- Preflight -----------------------------------------------------------------
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker not found on PATH. It is required to build the Linux binary."
}
docker info *> $null
if ($LASTEXITCODE -ne 0) { throw "Docker is installed but not running. Start Docker Desktop." }

if ($Publish -and -not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "gh (GitHub CLI) not found on PATH. It is required for -Publish."
}

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

# -- Publish -------------------------------------------------------------------
if (-not $Publish) {
    Write-Output "`nNot published. Re-run with -Publish to create or update release $tag."
    return
}

$assets = (Get-ChildItem $distDir).FullName

gh release view $tag *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Output "`nRelease $tag exists, uploading assets..."
    gh release upload $tag @assets --clobber
} else {
    Write-Output "`nCreating release $tag..."
    gh release create $tag @assets --title $tag --generate-notes
}
if ($LASTEXITCODE -ne 0) { throw "gh failed" }

Write-Output "Published $tag"
