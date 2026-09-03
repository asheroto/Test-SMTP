![Test-SMTP screenshot](https://github.com/user-attachments/assets/926e6855-2fed-4430-a8be-5821e5b79ecb)

[![GitHub Downloads - All Releases](https://img.shields.io/github/downloads/asheroto/Test-SMTP/total?label=release%20downloads)](https://github.com/asheroto/Test-SMTP/releases)
[![Release](https://img.shields.io/github/v/release/asheroto/Test-SMTP)](https://github.com/asheroto/Test-SMTP/releases)
[![GitHub Release Date - Published_At](https://img.shields.io/github/release-date/asheroto/Test-SMTP)](https://github.com/asheroto/Test-SMTP/releases)

[![GitHub Sponsor](https://img.shields.io/github/sponsors/asheroto?label=Sponsor&logo=GitHub)](https://github.com/sponsors/asheroto?frequency=one-time&sponsor=asheroto)
<a href="https://ko-fi.com/asheroto"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="Ko-Fi Button" height="20px"></a>
<a href="https://www.buymeacoffee.com/asheroto"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" height="40px"></a>

# Test-SMTP

A zero-dependency, cross-platform SMTP connection tester. Connect to any SMTP
server (Amazon SES, Gmail, Office 365, an internal relay), verify TLS,
authenticate, and optionally send a test message.

## Why

Testing an SMTP server on Windows is more painful than it should be:

- **`Send-MailMessage`** is [officially obsolete](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/send-mailmessage)
  - Microsoft's own docs warn it "can't guarantee secure connections" and
  recommend against using it. It also gives you no real control over the TLS
  mode and only tells you "it worked" or a vague error.
- **MailKit** actually works well, but it's a NuGet/DLL dependency you have to
  download and load, and it usually wants PowerShell 7 - not what's on a stock
  Windows box.
- **`telnet` / `openssl s_client`** are fiddly, manual, and don't help with
  AUTH or STARTTLS upgrades.
- **Online SMTP testers** mean pasting your server credentials into someone
  else's website.

Test-SMTP is one self-contained file with zero dependencies. No module to
install, no PowerShell version requirement, no admin rights, nothing leaves
your machine. It explicitly drives the TLS mode (ssl / starttls / none),
reports the negotiated TLS version and cipher, and gives you clear `[ok]` /
`[fail]` results - so you can actually tell *why* a connection failed.

## Usage

### Windows

Download the EXE and run it - no Python, no install. Pick whichever you prefer:

**Option A - short URL (easiest to remember).** [asheroto.com/smtp](https://asheroto.com/smtp)
always redirects to the latest `Test-SMTP.exe`:

```powershell
irm asheroto.com/smtp -OutFile Test-SMTP.exe; .\Test-SMTP.exe
```

**Option B - direct release URL:**

```powershell
irm https://github.com/asheroto/Test-SMTP/releases/latest/download/Test-SMTP.exe -OutFile Test-SMTP.exe; .\Test-SMTP.exe
```

**Option C - download manually.** Grab [`Test-SMTP.exe`](https://github.com/asheroto/Test-SMTP/releases/latest/download/Test-SMTP.exe)
from [Releases](https://github.com/asheroto/Test-SMTP/releases) and double-click it.

Fully portable - a single file, no installation, nothing to set up. Drop it
on a USB stick or a server and go. It's ~10 MB because it bundles the Python
interpreter so the target machine needs nothing installed; the script itself
is tiny (run it with Python instead to skip the bundle).

### Linux

Download the binary from the release and run it - no Python, no install:

**Option A - direct release URL:**

```sh
curl -L https://github.com/asheroto/Test-SMTP/releases/latest/download/Test-SMTP-linux-amd64 -o Test-SMTP && chmod +x Test-SMTP && ./Test-SMTP
```

**Option B - download manually.** Grab [`Test-SMTP-linux-amd64`](https://github.com/asheroto/Test-SMTP/releases/latest/download/Test-SMTP-linux-amd64)
from [Releases](https://github.com/asheroto/Test-SMTP/releases), then rename it,
make it executable, and run it:

```sh
mv Test-SMTP-linux-amd64 Test-SMTP
chmod +x Test-SMTP
./Test-SMTP
```

One x86-64 binary covers every glibc distro - Debian, Ubuntu, RHEL, Fedora,
Rocky, Alma, openSUSE, Arch - because it's built against glibc 2.28, and glibc
is forward-compatible. Alpine and other musl distros should use the Python
option below.

### macOS, Alpine, and everything else (Python 3)

Run the script with any Python 3 install:

```sh
python3 Test-SMTP.py
```

A few KB, no installation, nothing to download but the one file. This works on
Windows and Linux too, if you'd rather skip the bundled interpreter.

### Running it

Run with no arguments to be prompted for everything (use `./Test-SMTP` or
`python3 Test-SMTP.py` in place of `Test-SMTP.exe` on non-Windows):

```sh
Test-SMTP.exe
```

The interactive prompts default to Amazon SES (`email-smtp.us-east-1.amazonaws.com`
on port 587), but Test-SMTP works with **any** SMTP server and port - Gmail,
Office 365, Postfix, an internal relay, whatever. Just type your own host and
port at the prompt, or pass `--host`/`--port`.

Every setting can also be passed as an argument; supplied values skip their
prompt. Use `--batch` to never prompt (for scheduled tasks) - missing required
values then cause an error instead.

Test a connection only, no prompts:

```sh
Test-SMTP.exe --host email-smtp.us-east-1.amazonaws.com --port 587 \
    --mode starttls --username AKIA... --password SECRET --batch
```

Connect and send a test message:

```sh
Test-SMTP.exe --host smtp.example.com --port 465 --mode ssl \
    --username you@example.com --password SECRET --send \
    --from you@example.com --to you@example.com --batch
```

The password can also be read from the `SMTP_PASSWORD` environment variable,
which keeps the secret out of your command history.

### Options

| Flag | Description |
|------|-------------|
| `--host` | SMTP server hostname |
| `--port` | SMTP port (e.g. 587, 465, 25) |
| `--mode` | `ssl`, `starttls`, or `none` (defaults from port) |
| `--username` | Login username. Omit to skip auth. |
| `--password` | Login password. Falls back to `SMTP_PASSWORD`. |
| `--no-verify-cert` | Skip TLS certificate verification (self-signed hosts) |
| `--send` | Send a test message after connecting |
| `--from` / `--to` | Addresses for the test send. `--from` defaults to the username, since most servers require it to match the authenticated mailbox. |
| `--subject` / `--body` | Content for the test send |
| `--batch` | Never prompt; fail if a required value is missing |
| `--version`, `-V` | Print version and exit |

## Build

### Everything at once

`deploy.ps1` builds both release artifacts, smoke-tests each one, and stages
them under `release\` with the names used on GitHub Releases. Needs Docker
running (for the Linux build) and `gh` only if you pass `-Publish`:

```powershell
.\deploy.ps1            # build and stage release\
.\deploy.ps1 -Publish   # also create or update the GitHub release
```

```
release\Test-SMTP.exe            Windows x86-64
release\Test-SMTP-linux-amd64    Linux x86-64, glibc 2.28+
```

### One platform at a time

Both build scripts install PyInstaller themselves and produce one
self-contained executable that needs nothing on the target machine.

**Windows** - `build.ps1`, output `dist\Test-SMTP.exe`:

```powershell
.\build.ps1                       # uses icon.ico if present
.\build.ps1 -Icon path\to\my.ico  # embed a specific icon
```

**Linux and macOS** - `build.sh`, output `dist/Test-SMTP`:

```sh
./build.sh
PYTHON=/path/to/python3 ./build.sh   # pick a specific interpreter
```

PyInstaller is not a cross-compiler: the binary matches the OS, libc, and CPU
architecture of the machine that built it, so each target needs its own build.
There is no per-distro build, though - glibc is forward-compatible only, so a
binary built against an old glibc runs on every newer distro (but not the
reverse). Build in an old-glibc container to get that reach:

```sh
docker run --rm -v "$PWD:/src" -w /src almalinux:8 \
    sh -c 'dnf install -y python39 && PYTHON=python3.9 ./build.sh'
```

That binary runs on anything with glibc 2.28 or newer - Debian 10+, Ubuntu
18.04+, RHEL 8+ - and is what gets released as `Test-SMTP-linux-amd64`. Alpine
and other musl distros need their own build in an Alpine container; arm64 needs
an arm64 machine or `--platform linux/arm64`.

(The `manylinux` images look like the obvious choice here and are not - their
Pythons are built without a shared `libpython`, which PyInstaller requires.)

To bump the version, edit `__version__` in `Test-SMTP.py` and nothing else -
`build.ps1` generates the Windows version resource from it and `deploy.ps1`
takes the release tag from it, so `-V`, the `.exe` file properties, and the
release tag always agree.

## TODO

- [ ] Include Linux and macOS builds in releases
- [ ] Add a test suite