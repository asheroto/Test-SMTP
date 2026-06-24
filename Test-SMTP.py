#!/usr/bin/env python3
"""
Interactive and scriptable SMTP connection tester.

Zero external dependencies. Runs on any Python 3 install from cmd,
Windows PowerShell 5.1, or PowerShell 7.

Every setting can be supplied as a command-line argument. If an argument
is given, its prompt is skipped. Anything omitted is prompted for, unless
--batch is set, in which case missing required values cause an error
instead of a prompt (useful for scheduled tasks).

Examples
--------
Fully interactive:
    python Test-SMTP.py

Test a connection only, no prompts:
    python Test-SMTP.py --host email-smtp.us-east-1.amazonaws.com \
        --port 587 --mode starttls --username AKIA... --password SECRET --batch

Connect and send a test message, no prompts:
    python Test-SMTP.py --host smtp.example.com --port 465 --mode ssl \
        --username user --password SECRET --send \
        --from noreply@example.com --to you@example.com --batch

The password can also be read from the SMTP_PASSWORD environment variable,
which avoids putting the secret in your shell history.
"""

import os
import sys
import ssl
import smtplib
import socket
import argparse
from getpass import getpass
from email.message import EmailMessage

__version__ = "1.0.0"


def prompt(label, default=None):
    suffix = " [{0}]".format(default) if default else ""
    while True:
        value = input("{0}{1}: ".format(label, suffix)).strip()
        if value:
            return value
        if default is not None:
            return default
        print("  A value is required.")


def derive_mode(port):
    return "ssl" if port == 465 else "starttls"


def choose_security(port):
    suggested = derive_mode(port)
    print("\nSecurity mode:")
    print("  ssl       Implicit TLS, encrypted from the start (typical port 465)")
    print("  starttls  Plain connect, then upgrade to TLS (typical port 587 or 25)")
    print("  none      No encryption, plaintext only (internal relay testing)")
    while True:
        mode = prompt("Mode (ssl/starttls/none)", suggested).lower()
        if mode in ("ssl", "starttls", "none"):
            return mode
        print("  Enter ssl, starttls, or none.")


def yes_no(label, default_yes=False):
    default = "y" if default_yes else "n"
    answer = prompt("{0} (y/n)".format(label), default).lower()
    return answer.startswith("y")


def fail(message):
    print("[fail] " + message)
    sys.exit(2)


def show_tls_info(sock_obj):
    try:
        cipher = sock_obj.cipher()
        version = sock_obj.version()
        if cipher:
            print("  TLS version: {0}".format(version))
            print("  Cipher: {0} ({1} bits)".format(cipher[0], cipher[2]))
    except Exception:
        pass


def build_parser():
    examples = (
        "Any value you don't pass as an argument is prompted for interactively.\n"
        "Use --batch to never prompt (missing required values then error instead).\n\n"
        "Examples:\n"
        "  Run interactively (prompts for everything):\n"
        "    Test-SMTP.exe\n\n"
        "  Test a connection only, no prompts:\n"
        "    Test-SMTP.exe --host email-smtp.us-east-1.amazonaws.com --port 587 \\\n"
        "        --mode starttls --username AKIA... --password SECRET --batch\n\n"
        "  Connect and send a test message, no prompts:\n"
        "    Test-SMTP.exe --host smtp.example.com --port 465 --mode ssl \\\n"
        "        --username user --password SECRET --send \\\n"
        "        --from noreply@example.com --to you@example.com --batch\n\n"
        "Tip: set SMTP_PASSWORD in the environment instead of --password to keep\n"
        "the secret out of your command history.\n"
    )
    p = argparse.ArgumentParser(
        description="Test an SMTP connection with zero dependencies.",
        epilog=examples,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--version", "-V", action="version",
                   version="%(prog)s " + __version__)
    p.add_argument("--host", help="SMTP server hostname")
    p.add_argument("--port", type=int, help="SMTP port (for example 587, 465, 25)")
    p.add_argument("--mode", choices=["ssl", "starttls", "none"],
                   help="Security mode. Defaults from port if omitted in batch.")
    p.add_argument("--username", help="Login username. Omit to skip auth.")
    p.add_argument("--password",
                   help="Login password. Falls back to SMTP_PASSWORD env var.")
    p.add_argument("--no-verify-cert", action="store_true",
                   help="Skip TLS certificate verification (self-signed hosts).")
    p.add_argument("--send", action="store_true",
                   help="Send a test message after connecting.")
    p.add_argument("--from", dest="mail_from", help="From address for test send.")
    p.add_argument("--to", dest="mail_to", help="To address for test send.")
    p.add_argument("--subject", help="Subject for test send.")
    p.add_argument("--body", help="Body for test send.")
    p.add_argument("--batch", action="store_true",
                   help="Never prompt. Fail if a required value is missing.")
    return p


def resolve_settings(args):
    batch = args.batch

    # Host
    if args.host:
        host = args.host
    elif batch:
        fail("Missing --host in batch mode.")
    else:
        host = prompt("SMTP server", "email-smtp.us-east-1.amazonaws.com")

    # Port
    if args.port is not None:
        port = args.port
    elif batch:
        port = 587
    else:
        raw = prompt("Port", "587")
        try:
            port = int(raw)
        except ValueError:
            port = 587
            print("  Not a number, using 587.")

    # Security mode
    if args.mode:
        mode = args.mode
    elif batch:
        mode = derive_mode(port)
    else:
        mode = choose_security(port)

    # Certificate verification
    if args.no_verify_cert:
        verify = False
    elif mode in ("ssl", "starttls") and not batch:
        verify = not yes_no(
            "Skip certificate verification (only for self-signed test hosts)",
            default_yes=False,
        )
    else:
        verify = True

    # Username and password
    username = args.username
    if username is None and not batch:
        username = prompt("Username (blank to skip auth)", "")
    username = (username or "").strip()

    password = ""
    if username:
        if args.password is not None:
            password = args.password
        elif os.environ.get("SMTP_PASSWORD"):
            password = os.environ["SMTP_PASSWORD"]
        elif batch:
            fail("Username given but no password. Use --password or SMTP_PASSWORD.")
        else:
            password = getpass("Password (hidden): ")

    # Test send
    if args.send:
        do_send = True
    elif batch:
        do_send = False
    else:
        do_send = yes_no("Send a test message after connecting", default_yes=False)

    mail_from = mail_to = subject = body = None
    if do_send:
        mail_from = args.mail_from
        if not mail_from:
            mail_from = fail("Missing --from for test send.") if batch else prompt("From address")
        mail_to = args.mail_to
        if not mail_to:
            mail_to = fail("Missing --to for test send.") if batch else prompt("To address")
        subject = args.subject or ("SMTP test message" if batch else prompt("Subject", "SMTP test message"))
        body = args.body or ("This is a test message from Test-SMTP." if batch
                             else prompt("Body", "This is a test message from Test-SMTP."))

    return {
        "host": host, "port": port, "mode": mode, "verify": verify,
        "username": username, "password": password, "do_send": do_send,
        "mail_from": mail_from, "mail_to": mail_to,
        "subject": subject, "body": body,
    }


def run(cfg):
    print("=" * 60)
    print(" SMTP Connection Tester (stdlib only)")
    print("=" * 60)

    context = ssl.create_default_context()
    if not cfg["verify"]:
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE

    host, port, mode = cfg["host"], cfg["port"], cfg["mode"]
    print("\n" + "-" * 60)
    print("Connecting to {0}:{1} using mode '{2}'...".format(host, port, mode))
    print("-" * 60)

    server = None
    try:
        if mode == "ssl":
            server = smtplib.SMTP_SSL(host, port, timeout=30, context=context)
            print("[ok] Connected with implicit TLS.")
            show_tls_info(server.sock)
        else:
            server = smtplib.SMTP(host, port, timeout=30)
            print("[ok] TCP connection established.")

        code, _ = server.ehlo()
        print("[ok] EHLO response code {0}.".format(code))
        if server.esmtp_features:
            print("  Advertised features:")
            for name, params in sorted(server.esmtp_features.items()):
                line = name if not params else "{0} {1}".format(name, params.strip())
                print("    - {0}".format(line))

        if mode == "starttls":
            if not server.has_extn("starttls"):
                print("[warn] Server does not advertise STARTTLS.")
            server.starttls(context=context)
            print("[ok] STARTTLS upgrade complete.")
            show_tls_info(server.sock)
            server.ehlo()

        if cfg["username"]:
            try:
                server.login(cfg["username"], cfg["password"])
                print("[ok] Authentication succeeded for {0}.".format(cfg["username"]))
            except smtplib.SMTPAuthenticationError as auth_err:
                print("[fail] Authentication rejected.")
                print("  Code: {0}".format(auth_err.smtp_code))
                detail = auth_err.smtp_error
                if isinstance(detail, bytes):
                    detail = detail.decode("utf-8", "replace")
                print("  Server said: {0}".format(detail))
                return 2
        else:
            print("[skip] No username given, auth not attempted.")

        if cfg["do_send"]:
            msg = EmailMessage()
            msg["From"] = cfg["mail_from"]
            msg["To"] = cfg["mail_to"]
            msg["Subject"] = cfg["subject"]
            msg.set_content(cfg["body"])
            server.send_message(msg)
            print("[ok] Test message accepted by server for delivery.")

        print("\nResult: connection test PASSED.")
        return 0

    except smtplib.SMTPConnectError as err:
        print("[fail] Server refused the connection: {0}".format(err))
    except smtplib.SMTPServerDisconnected as err:
        print("[fail] Server dropped the connection: {0}".format(err))
        print("  Often a TLS mismatch. Try a different mode or port.")
    except ssl.SSLError as err:
        print("[fail] TLS error: {0}".format(err))
        print("  If using mode 'ssl' on port 587, try 'starttls' instead.")
        print("  If using 'starttls' on port 465, try 'ssl' instead.")
    except socket.timeout:
        print("[fail] Timed out. Port may be blocked by a firewall.")
    except socket.gaierror as err:
        print("[fail] Could not resolve host '{0}': {1}".format(host, err))
    except ConnectionRefusedError:
        print("[fail] Connection refused. Nothing listening on that port.")
    except smtplib.SMTPException as err:
        print("[fail] SMTP error: {0}".format(err))
    except Exception as err:
        print("[fail] Unexpected error: {0}".format(err))
    finally:
        if server is not None:
            try:
                server.quit()
            except Exception:
                try:
                    server.close()
                except Exception:
                    pass

    print("\nResult: connection test FAILED.")
    return 1


if __name__ == "__main__":
    parser = build_parser()
    parsed = parser.parse_args()
    try:
        settings = resolve_settings(parsed)
        sys.exit(run(settings))
    except KeyboardInterrupt:
        print("\nCancelled.")
        sys.exit(130)