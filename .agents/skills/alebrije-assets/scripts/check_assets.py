#!/usr/bin/env python3
"""Lista los assets faltantes o inválidos según assets/manifest.json. Solo usa la stdlib."""
import itertools
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
ASSETS = ROOT / "assets"


def png_info(path):
    """Devuelve (ancho, alto, tiene_alpha) leyendo el encabezado PNG, o None si no es PNG."""
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    width, height, _, color_type = struct.unpack(">IIBB", data[16:26])
    has_alpha = color_type in (4, 6) or b"tRNS" in data
    return width, height, has_alpha


def check(path, transparent, square, min_side=1024):
    if not path.exists():
        return "falta"
    info = png_info(path)
    if info is None:
        return "no es PNG"
    width, height, has_alpha = info
    problems = []
    if min(width, height) < min_side:
        problems.append(f"muy chico ({width}x{height})")
    if square and width != height:
        problems.append(f"no es cuadrado ({width}x{height})")
    if transparent and not has_alpha:
        problems.append("sin canal alpha")
    return ", ".join(problems) or None


def main():
    manifest = json.loads((ASSETS / "manifest.json").read_text())
    slugs = sorted(a["slug"] for a in manifest["animales"])

    expected = [(ASSETS / "animales" / f"{s}.png", True, True) for s in slugs]
    expected += [
        (ASSETS / "mezclas" / f"{a}-{b}.png", True, True)
        for a, b in itertools.combinations(slugs, 2)
    ]
    expected += [
        (ASSETS / "cuento" / f"pagina-{n:02d}.png", False, False)
        for n in manifest["paginas_ilustradas"]
    ]

    issues = []
    for path, transparent, square in expected:
        problem = check(path, transparent, square)
        if problem:
            issues.append((path.relative_to(ROOT), problem))

    ok = len(expected) - len(issues)
    print(f"{ok}/{len(expected)} assets OK")
    for path, problem in issues:
        print(f"  {path}: {problem}")
    sys.exit(1 if issues else 0)


if __name__ == "__main__":
    main()
