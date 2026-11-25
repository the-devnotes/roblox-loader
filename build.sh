#!/bin/sh
# Gabungkan src/*.lua menjadi satu LocalScript siap paste ke Roblox.
# Urutan alphabetik = urutan asli v5.2, jadi hasilnya identik.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUT="$ROOT/dist/BikeForEggsMobile_v5_2.lua"

mkdir -p "$(dirname "$OUT")"
: > "$OUT"

for f in "$ROOT"/src/*.lua; do
    cat "$f" >> "$OUT"
done

if command -v luac >/dev/null 2>&1; then
    luac -p "$OUT"
fi

printf 'Built: %s\n' "$OUT"
