"""Self-check for the password masking loop. Run: python test_masked_input.py

Drives _read_masked directly with canned keystrokes, so it exercises the real
logic on any platform regardless of which branch masked_input would pick.
"""

import io
import sys
import importlib.util

spec = importlib.util.spec_from_file_location("test_smtp", "Test-SMTP.py")
test_smtp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(test_smtp)


def feed(keys):
    """Run the masking loop over a keystroke list, return (value, echo)."""
    it = iter(keys)
    real_stdout = sys.stdout
    sys.stdout = io.StringIO()
    try:
        return test_smtp._read_masked(lambda: next(it), ""), sys.stdout.getvalue()
    finally:
        sys.stdout = real_stdout


def main():
    value, echo = feed(list("hunter2") + ["\r"])
    assert value == "hunter2", value
    assert echo == "*" * 7 + "\n", repr(echo)

    # Enter as newline (POSIX raw mode may deliver either).
    value, _ = feed(list("abc") + ["\n"])
    assert value == "abc", value

    # Backspace removes a character and erases one asterisk. Windows sends
    # \b, POSIX terminals send \x7f; both must work.
    for bs in ("\b", "\x7f"):
        value, echo = feed(list("abc") + [bs, "d", "\r"])
        assert value == "abd", (bs, value)
        assert echo == "***" + "\b \b" + "*\n", (bs, repr(echo))

    # Backspace on an empty buffer must not underflow or echo anything.
    value, echo = feed(["\b", "\x7f", "x", "\r"])
    assert value == "x", value
    assert echo == "*\n", repr(echo)

    # Windows arrow keys arrive as a prefix + scancode pair; discard both.
    value, echo = feed(["a", "\xe0", "H", "b", "\r"])
    assert value == "ab", value
    assert echo == "**\n", repr(echo)

    # POSIX escape sequences must not land in the password as literal junk.
    value, echo = feed(["a", "\x1b", "b", "\r"])
    assert value == "ab", value
    assert echo == "**\n", repr(echo)

    # Ctrl+C aborts rather than returning a partial password.
    try:
        feed(list("secret") + ["\x03"])
    except KeyboardInterrupt:
        pass
    else:
        raise AssertionError("Ctrl+C did not raise KeyboardInterrupt")

    print("ok")


if __name__ == "__main__":
    main()
