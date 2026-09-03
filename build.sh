#!/usr/bin/env sh
#
# Test-SMTP build script (Linux and macOS)
#
# Dependencies (required on build machine)
#
# Python
# - Python 3.8+, on PATH as 'python3' (override with the PYTHON env var)
#
# Python packages
# - pyinstaller (current release; installed automatically below)
#
# Output
# - Final distributable:
#     dist/Test-SMTP
#
# - Single self-contained executable (PyInstaller onefile)
# - No external dependencies required on target system
#
# Notes
# - PyInstaller is not a cross-compiler. The binary matches the OS, libc, and
#   CPU architecture of the machine that built it. Windows uses build.ps1.
# - glibc is forward-compatible only: a binary built against an old glibc runs
#   on newer distros, but not the reverse. Build inside an old-glibc container
#   (see README) so one amd64 binary covers Debian, Ubuntu, RHEL, and friends.
#   Note that the manylinux images do not work: their Pythons have no shared
#   libpython, which PyInstaller requires.
# - No .spec file: PyInstaller is driven directly from the flags below so there
#   is one fewer file to keep in sync.
# - No version resource; that is a Windows-only concept. --version reads
#   __version__ from the source either way.

set -eu

# -- Paths ---------------------------------------------------------------------
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_file="$script_dir/Test-SMTP.py"
dist_dir="$script_dir/dist"
output_bin="$dist_dir/Test-SMTP"

py=${PYTHON:-python3}
command -v "$py" >/dev/null 2>&1 || { echo "Python 3 not found: $py" >&2; exit 1; }

version=$("$py" - "$source_file" <<'EOF'
import re, sys
src = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r'(?m)^__version__\s*=\s*"([^"]+)"', src)
if not match:
    sys.exit("Could not find __version__ in " + sys.argv[1])
print(match.group(1))
EOF
)

# -- Clean ---------------------------------------------------------------------
# Only this build's own output, not all of dist/. deploy.ps1 puts the Windows
# and Linux binaries side by side there, and neither build may clobber the other.
rm -f "$output_bin"
mkdir -p "$dist_dir"

echo "Building Test-SMTP $version for $(uname -s) $(uname -m)"

# -- Install deps --------------------------------------------------------------
"$py" -m pip install --upgrade pyinstaller

# -- Build binary --------------------------------------------------------------
# Stdlib modules PyInstaller auto-pulls but this script never uses. Trims a
# couple MB. Safe given the imports (os/ssl/smtplib/socket/argparse/email).
"$py" -m PyInstaller \
    --clean --noconfirm \
    --onefile --console \
    --name Test-SMTP \
    --distpath "$dist_dir" \
    --workpath "$script_dir/build" \
    --specpath "$script_dir/build" \
    --exclude-module tkinter \
    --exclude-module unittest \
    --exclude-module pydoc \
    --exclude-module lib2to3 \
    --exclude-module test \
    "$source_file"

[ -x "$output_bin" ] || { echo "Binary not found after build: $output_bin" >&2; exit 1; }

echo "Done: $output_bin"
