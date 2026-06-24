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
authenticate, and optionally send a test message - all from a plain Python
script or a single self-contained Windows executable.

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

### Windows (no Python needed)

Download the EXE and run it - no Python, no install. In PowerShell, pick
whichever you prefer:

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

### Linux, macOS, and other (Python 3)

No EXE needed - just run the script with any Python 3 install:

```sh
python Test-SMTP.py
```

A few KB, no installation, nothing to download but the one file.

### Running it

Run with no arguments to be prompted for everything (use `python Test-SMTP.py`
in place of `Test-SMTP.exe` on non-Windows):

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
    --username user --password SECRET --send \
    --from noreply@example.com --to you@example.com --batch
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
| `--from` / `--to` | Addresses for the test send |
| `--subject` / `--body` | Content for the test send |
| `--batch` | Never prompt; fail if a required value is missing |
| `--version`, `-V` | Print version and exit |

## Build

`build.ps1` builds a single self-contained `.exe` with PyInstaller on Windows:

```powershell
.\build.ps1                       # uses icon.ico if present
.\build.ps1 -Icon path\to\my.ico  # embed a specific icon
```

PyInstaller is not a cross-compiler, but it runs on Linux and macOS too - to
build a native binary there, install PyInstaller and run it directly:

```sh
pyinstaller --onefile --console --name Test-SMTP Test-SMTP.py
```

Output: `dist\Test-SMTP.exe`. The version shown by `-V` comes from
`__version__` in `Test-SMTP.py`; keep it in sync with `version_info.txt`.

## License

[MIT](LICENSE)