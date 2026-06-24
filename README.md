# Test-SMTP

A zero-dependency, cross-platform SMTP connection tester. Connect to any SMTP
server, verify TLS, authenticate, and optionally send a test message - all
from a plain Python script or a single self-contained Windows executable.

Pure Python standard library. No `pip install`, no external packages. The
script runs on Windows, Linux, and macOS - anywhere Python 3 is installed.

## Usage

**Windows (no Python needed):** download `Test-SMTP.exe` from the
[Releases](https://github.com/asheroto/Test-SMTP/releases) page and run it.
Fully portable - a single file, no installation, nothing to set up. Drop it
on a USB stick or a server and go.

**Linux / macOS / other (Python 3):** run `python Test-SMTP.py` directly -
same thing, no installation either way.

Run with no arguments to be prompted for everything:

```sh
Test-SMTP.exe
```

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