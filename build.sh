#!/bin/sh
# Gabungkan src/*.lua menjadi satu LocalScript siap paste ke Roblox.
# Urutan gabung didefinisikan eksplisit di ORDER (dulu bergantung pada prefix angka).
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUT="$ROOT/dist/BikeForEggsMobile_v5_2.lua"

# Urutan asli v5.2. Jangan diurutkan alphabetik: page_widgets butuh Page dari
# ui_library, dan start harus jadi bagian terakhir.
ORDER="
header
boot
ui_library
page_widgets
state
log
helpers
snapshot
egg_data
catalog
base_area
prompts
steal
debug
ui_boot
page_home
page_steal
page_auto
page_filter
page_egg
page_area
page_log
page_info
dashboard
loops
start
"

# Gagal kalau ada file src yang belum terdaftar di ORDER.
for f in "$ROOT"/src/*.lua; do
    name=$(basename "$f" .lua)
    listed=0
    for n in $ORDER; do
        if [ "$n" = "$name" ]; then listed=1; break; fi
    done
    if [ "$listed" -eq 0 ]; then
        printf 'build.sh: file src belum terdaftar di ORDER: %s\n' "$name" >&2
        exit 1
    fi
done

mkdir -p "$(dirname "$OUT")"
: > "$OUT"

for name in $ORDER; do
    f="$ROOT/src/$name.lua"
    if [ ! -f "$f" ]; then
        printf 'build.sh: file tidak ditemukan: %s\n' "$f" >&2
        exit 1
    fi
    cat "$f" >> "$OUT"
done

if command -v luac >/dev/null 2>&1; then
    luac -p "$OUT"
fi

printf 'Built: %s\n' "$OUT"
