#!/usr/bin/env bash
set -euo pipefail

SRC="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/src"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/lazydocker/config.yml"
THEME="${LAZYDOCKER_THEME:-}"

mkdir -p "$(dirname "$DEST")"

python3 - "$SRC" "$DEST" "$THEME" <<'PY'
import sys, glob, os, yaml

src, dest, theme = sys.argv[1], sys.argv[2], sys.argv[3]

def merge(a, b):
    for k, v in b.items():
        if isinstance(v, dict) and isinstance(a.get(k), dict):
            merge(a[k], v)
        else:
            a[k] = v
    return a

def load_palette(path):
    with open(path) as fh:
        data = yaml.safe_load(fh) or {}
    return data.get("palette", {})

def resolve(value, palette):
    if isinstance(value, str) and value.startswith("@"):
        key = value[1:]
        if key not in palette:
            raise SystemExit("unknown palette token: " + value)
        return palette[key]
    if isinstance(value, list):
        return [resolve(v, palette) for v in value]
    if isinstance(value, dict):
        return {k: resolve(v, palette) for k, v in value.items()}
    return value

palette = load_palette(os.path.join(src, "themes", "palette.yml"))

if theme:
    theme_path = os.path.join(src, "themes", theme + ".yml")
    if not os.path.exists(theme_path):
        raise SystemExit("unknown theme: " + theme)
    theme_files = [theme_path]
else:
    theme_files = sorted(
        f for f in glob.glob(os.path.join(src, "themes", "*.yml"))
        if not f.endswith("palette.yml")
    )

files = [os.path.join(src, "config.yml")] + theme_files

out = {}
for f in files:
    with open(f) as fh:
        merge(out, yaml.safe_load(fh) or {})

out = resolve(out, palette)

with open(dest, "w") as fh:
    yaml.safe_dump(out, fh, sort_keys=False, allow_unicode=True)
PY

echo "wrote $DEST"
