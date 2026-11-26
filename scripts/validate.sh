#!/usr/bin/env bash
set -euo pipefail

SRC="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/src"
THEME="${LAZYDOCKER_THEME:-}"

python3 - "$SRC" "$THEME" <<'PY'
import sys, glob, os, yaml

src, theme = sys.argv[1], sys.argv[2]

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

result = {}
for f in [os.path.join(src, "config.yml")] + theme_files:
    with open(f) as fh:
        merge(result, yaml.safe_load(fh) or {})

result = resolve(result, palette)

warnings = []
gui = result.get("gui", {}) or {}
if gui.get("mouseEvents") is True:
    warnings.append(
        "gui.mouseEvents: true disables the mouse (upstream IgnoreMouseEvents); set false to enable it"
    )
if "viewAllLogs" in (result.get("commandTemplates", {}) or {}):
    warnings.append("commandTemplates.viewAllLogs is a typo; upstream key is viewAlLogs")
if not gui.get("theme"):
    warnings.append("gui.theme is empty; no theme was merged")

print("config: OK")
print("themes: " + ", ".join(os.path.basename(f) for f in theme_files))
print("graphs: %d" % len((result.get("stats", {}) or {}).get("graphs", [])))
for w in warnings:
    print("warning: " + w)
PY
