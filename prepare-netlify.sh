#!/bin/sh
# Siapkan folder publish Netlify dari hasil build terakhir.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

sh "$ROOT/build.sh"
mkdir -p "$ROOT/netlify"
cp "$ROOT/dist/BikeForEggsMobile_v5_2.lua" "$ROOT/netlify/BikeForEggsMobile_v5_2.lua"
python3 - "$ROOT/dist/BikeForEggsMobile_v5_2.lua" "$ROOT/netlify/BikeForEggsMobile_v5_2.hex" <<'PY'
import pathlib
import sys

src, out = sys.argv[1], sys.argv[2]
pathlib.Path(out).write_text(pathlib.Path(src).read_bytes().hex())
PY
if [ -f "$ROOT/logo.jpg" ]; then
    cp "$ROOT/logo.jpg" "$ROOT/netlify/logo.jpg"
fi

printf 'Siap: %s\n' "$ROOT/netlify"
