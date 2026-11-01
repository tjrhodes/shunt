"""Gives the built game script a name that changes whenever its contents do
(shunt-1a2b3c4d.js), and writes the page pointing at it. Browsers keep
scripts they have seen; a new name means a new build is always loaded,
never an old copy.

The page's source is client/page.html (kept in git, pointing at plain
"shunt.js"); the built page, www/index.html, is made from it on every build
and isn't kept in git, so building never leaves a changed file behind
(which stopped `git pull` on 1 Nov).

Run by client/build.hxml after each build.
Usage: python3 tools/fingerprint-script.py client/www
"""

import hashlib
import re
import sys
from pathlib import Path

BUILT_NAME = "shunt.js"
SCRIPT_TAG = re.compile(r'src="shunt(-[0-9a-f]+)?\.js"')


def fingerprint(script):
    """The first 8 characters of the script's SHA-256: changes whenever any byte does."""
    return hashlib.sha256(script.read_bytes()).hexdigest()[:8]


def remove_old_copies(folder):
    """Earlier fingerprinted scripts, which nothing points at any more."""
    for old in folder.glob("shunt-*.js"):
        old.unlink()


def write_page_pointing_at(source, page, script_name):
    """The built page: the page's source, with the script tag pointing at this build's script."""
    text = source.read_text(encoding="utf8")
    page.write_text(SCRIPT_TAG.sub(f'src="{script_name}"', text), encoding="utf8")


def main(folder):
    built = folder / BUILT_NAME
    named = folder / f"shunt-{fingerprint(built)}.js"
    remove_old_copies(folder)
    built.rename(named)
    write_page_pointing_at(folder.parent / "page.html", folder / "index.html", named.name)
    print(f"{named.name}")


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "client/www"))
