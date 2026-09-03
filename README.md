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

Testing an SMTP server is more painful than it should be, whatever you're on.

**On Windows:**

- **`Send-MailMessage`** is [officially obsolete](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/send-mailmessage)
  - Microsoft's own docs warn it "can't guarantee secure connections" and
  recommend against using it. It also gives you no real control over the TLS
  mode and only tells you "it worked" or a vague error.
- **MailKit** actually works well, but it's a NuGet/DLL dependency you have to
  download and load, and it usually wants PowerShell 7 - not what's on a stock
  Windows box.

**On Linux and macOS:**

- **`swaks`** is genuinely good, but it's a Perl script you have to install
  first, and it isn't on a fresh box or a locked-down server.
- **`mail` / `sendmail`** hand your message to a local MTA and return before
  it's delivered, so a "success" tells you nothing about the remote server you
  were actually trying to test.

**Everywhere:**

- **`telnet` and `openssl s_client`** are fiddly and manual. You type the SMTP
  conversation by hand, base64 your own credentials, and still can't easily tell
  a failed STARTTLS upgrade from a server that never offered it.
- **Online SMTP testers** mean pasting your server credentials into someone
  else's website.

Test-SMTP is one self-contained file with zero dependencies. Nothing to install,
no runtime version to satisfy, no admin or root, nothing leaves your machine. It
explicitly drives the TLS mode (ssl / starttls / none), reports the negotiated
TLS version and cipher, and gives you clear `[ok]` / `[fail]` results - so you
can actually tell *why* a connection failed.

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

Download the binary and run it - no Python, no install. Pick whichever you prefer:

**Option A - short URL (easiest to remember).** [asheroto.com/smtp-linux](https://asheroto.com/smtp-linux)
always redirects to the latest `Test-SMTP-linux-amd64`:

```sh
curl -fL asheroto.com/smtp-linux -o Test-SMTP && chmod +x Test-SMTP && ./Test-SMTP
```

**Option B - direct release URL:**

```sh
curl -fL https://github.com/asheroto/Test-SMTP/releases/latest/download/Test-SMTP-linux-amd64 -o Test-SMTP && chmod +x Test-SMTP && ./Test-SMTP
```

**Option C - download manually.** Grab [`Test-SMTP-linux-amd64`](https://github.com/asheroto/Test-SMTP/releases/latest/download/Test-SMTP-linux-amd64)
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

Run it with no arguments and it prompts for everything:

```sh
./Test-SMTP              # Windows and Linux
python3 Test-SMTP.py     # anywhere with Python 3
```

`./Test-SMTP` works in PowerShell as well as in a Linux shell, so every example
below runs as written on both.

The prompts default to Amazon SES (`email-smtp.us-east-1.amazonaws.com` on port
587), but Test-SMTP works with **any** SMTP server and port - Gmail, Office 365,
Postfix, an internal relay, whatever. Type your own host and port at the prompt,
or pass `--host` and `--port`.

Every setting can also be passed as an argument, and anything you supply skips
its prompt. Add `--batch` to never prompt at all - a missing required value then
errors instead of asking, which is what you want for scheduled tasks:

```sh
./Test-SMTP --host smtp.example.com --port 587 --mode starttls --username you@example.com --password SECRET --batch
```

See [Examples](#examples) for real-world recipes and [Options](#options) for the
full flag list.

### Examples

**Gmail.** Needs an [App Password](https://myaccount.google.com/apppasswords),
not your account password - Google rejects the latter over SMTP:

```sh
./Test-SMTP --host smtp.gmail.com --port 587 --mode starttls --username you@gmail.com --password abcdefghijklmnop --batch
```

**Microsoft 365.** SMTP AUTH is disabled per-mailbox by default on newer
tenants; a `535` here usually means it needs enabling, not a bad password:

```sh
./Test-SMTP --host smtp.office365.com --port 587 --mode starttls --username you@yourdomain.com --password SECRET --batch
```

**Amazon SES.** Use SES SMTP credentials, which are generated in the SES
console - they are not your AWS access keys:

```sh
./Test-SMTP --host email-smtp.us-east-1.amazonaws.com --port 587 --mode starttls --username AKIA... --password SECRET --send --from verified@yourdomain.com --to you@example.com --batch
```

**Implicit TLS on port 465.** Common on cPanel and older providers:

```sh
./Test-SMTP --host mail.yourdomain.com --port 465 --mode ssl --username you@yourdomain.com --password SECRET --batch
```

**Internal relay, no auth, no encryption.** Omit `--username` to skip AUTH
entirely - useful for checking a Postfix or Exchange relay accepts your host:

```sh
./Test-SMTP --host relay.internal.lan --port 25 --mode none --batch
```

**Self-signed or mismatched certificate.** Skips verification so you can see
whether the rest of the path works:

```sh
./Test-SMTP --host mail.internal.lan --port 587 --mode starttls --username svc-account --password SECRET --no-verify-cert --batch
```

**Keep the password out of your shell history.** `SMTP_PASSWORD` is read when
`--password` is omitted, which also keeps it out of the process list. This is
the one place the two shells differ, since setting a variable isn't the same:

```sh
export SMTP_PASSWORD='SECRET'                                    # Linux and macOS
./Test-SMTP --host smtp.gmail.com --port 587 --mode starttls --username you@gmail.com --batch
```

```powershell
$env:SMTP_PASSWORD = 'SECRET'                                    # Windows
./Test-SMTP --host smtp.gmail.com --port 587 --mode starttls --username you@gmail.com --batch
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

`deploy.ps1` builds both release artifacts, smoke-tests each one, and leaves
`dist\` holding exactly the release, named as it appears on GitHub Releases.
Needs Docker running, for the Linux build. Uploading is manual:

```powershell
.\deploy.ps1                       # build both into dist\
.\deploy.ps1 -Icon path\to\my.ico  # passed through to build.ps1
```

```
dist\Test-SMTP.exe            Windows x86-64
dist\Test-SMTP-linux-amd64    Linux x86-64, glibc 2.28+
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