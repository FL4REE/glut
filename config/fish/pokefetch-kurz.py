"""pokefetch mit kurzer OS-Zeile ("CachyOS 7.3.1" statt "Linux-7.3.1-1-cachyos-x86_64-with-glibc2.44").

Wird von functions/pokefetch-kurz.fish mit dem Python von pokefetch gestartet.
"""
import platform
import sys


def _short(*_a, **_k):
    info = {}
    try:
        with open("/etc/os-release") as f:
            for line in f:
                key, _, val = line.strip().partition("=")
                info[key] = val.strip('"')
    except OSError:
        pass
    name = info.get("PRETTY_NAME") or info.get("NAME") or platform.system()
    kernel = platform.release().split("-")[0]
    return f"{name} {kernel}".strip()


platform.platform = _short
sys.argv[0] = "pokefetch"
try:
    from src.cli import main
except ImportError:
    # Paket nicht gefunden: normales pokefetch starten
    import os
    os.execvp("pokefetch", ["pokefetch", *sys.argv[1:]])

main()
