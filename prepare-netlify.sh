#!/bin/sh
# Siapkan folder publish Netlify untuk loader ClipperHub.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TOKEN=${CLIPPERHUB_TOKEN:-ClipperHub-2026}
PAYLOAD="a3f9c2e1d7.txt"

sh "$ROOT/build.sh"

mkdir -p "$ROOT/public"

# Bersihkan artifact lama supaya tidak ada source polos yang ikut publish.
rm -f "$ROOT/public/index.html" \
      "$ROOT/public/BikeForEggsMobile_v5_2.lua" \
      "$ROOT/public/BikeForEggsMobile_v5_2.hex" \
      "$ROOT/public/_redirects"

# Payload hex dibuat dari hasil build. Isinya bukan Lua polos.
python3 - "$ROOT/dist/BikeForEggsMobile_v5_2.lua" "$ROOT/public/$PAYLOAD" <<'PY'
import pathlib
import sys

src, out = sys.argv[1], sys.argv[2]
pathlib.Path(out).write_text(pathlib.Path(src).read_bytes().hex())
PY

# Gate lewat Netlify redirects:
# - browser biasa (tanpa token) -> 302 ke /
# - Roblox dengan ?k=<token>    -> 200 berisi hex
cat > "$ROOT/public/_redirects" <<EOF
# Loader ClipperHub: hanya token yang benar yang mendapat payload.
/clipperhub.lua k=$TOKEN /$PAYLOAD 200
/clipperhub.lua / 302!
/$PAYLOAD / 302!
EOF

if [ -f "$ROOT/logo.jpg" ]; then
    cp "$ROOT/logo.jpg" "$ROOT/public/logo.jpg"
fi

printf 'Siap: %s (payload=%s, token=%s)\n' "$ROOT/public" "$PAYLOAD" "$TOKEN"
