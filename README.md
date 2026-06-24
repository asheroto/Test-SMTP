# Test-SMTP

A zero-dependency SMTP connection tester for Windows. Connect to any SMTP
server, verify TLS, authenticate, and optionally send a test message - all
from a single self-contained executable or a plain Python script.

Pure Python standard library. No `pip install`, no external packages.

## Install

Download `Test-SMTP-<version>.exe` from the
[Releases](https://github.com/asheroto/Test-SMTP/releases) page and run it.
No installation required.

Or run the script directly with any Python 3 install:

```sh
python Test-SMTP.py
```

## Usage

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

Builds a single self-contained `.exe` with PyInstaller. Windows only
(PyInstaller is not a cross-compiler).

```powershell
.\build.ps1                       # uses icon.ico if present
.\build.ps1 -Icon path\to\my.ico  # embed a specific icon
```

Output: `dist\Test-SMTP-<version>.exe`. The version is read from
`__version__` in `Test-SMTP.py`; keep it in sync with `version_info.txt`.

## License

[MIT](LICENSE)
