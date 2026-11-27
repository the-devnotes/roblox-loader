#!/bin/sh
# Gabungkan loader ClipperHub + script apa pun jadi SATU LocalScript siap paste.
# Tidak butuh HttpGet / URL / token: payload disimpan sebagai hex di dalam file.
#
# Pakai:
#   sh build-allinone.sh                                      -> default Bike For Eggs
#   sh build-allinone.sh script.lua out.lua "Nama Script"      -> game/script lain
#
# Env opsional: TITLE, CREDIT, LOGO_ID (kosongkan LOGO_ID untuk ikon digambar).
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT_IN=${1:-}
OUT=${2:-}
NAME_IN=${3:-}

if [ -z "$SCRIPT_IN" ]; then
    sh "$ROOT/build.sh"
    SCRIPT_IN="$ROOT/dist/BikeForEggsMobile_v5_2.lua"
    OUT=${OUT:-"$ROOT/dist/BikeForEggs_AllInOne.lua"}
    NAME_IN=${NAME_IN:-"Bike For Eggs"}
fi

SCRIPT=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_IN")" && pwd)/$(basename -- "$SCRIPT_IN")
OUT=${OUT:-"$ROOT/dist/$(basename -- "$SCRIPT_IN" .lua)_AllInOne.lua"}
mkdir -p "$(dirname -- "$OUT")"
NAME=${NAME_IN:-$(basename -- "$SCRIPT_IN" .lua)}
TITLE=${TITLE:-CLIPPERHUB}
CREDIT=${CREDIT:-By ClipperHub}
LOGO_ID=${LOGO_ID:-102269948329032}

python3 - "$ROOT" "$SCRIPT" "$OUT" "$NAME" "$TITLE" "$CREDIT" "$LOGO_ID" <<'PY'
import json
import pathlib
import sys

root, script_path, out_path, name, title, credit, logo_id = sys.argv[1:8]
root = pathlib.Path(root)
q = lambda s: json.dumps(str(s), ensure_ascii=False)

loader_core = (root / "roblox/loader/ClipperHubCore.lua").read_text()

payload = pathlib.Path(script_path).read_bytes().hex()
safe_name = name.replace("\n", " ").replace("--", "-")

head = (
    "-- [LocalScript] | Lokasi: StarterPlayer > StarterPlayerScripts (paste sebagai LocalScript)\n"
    "--[[\n"
    "    ClipperHub All-In-One\n"
    "    Loader UI + " + safe_name + " dalam SATU file. Tidak butuh HttpGet / URL / token.\n"
    "    Payload disimpan sebagai hex di dalam file ini, lalu didekode dan dijalankan.\n"
    "]]\n\n"
    'local BFE_PAYLOAD = "'
)

run_call = (
    "\n\n-- Jalankan loader dengan payload bawaan (tanpa jaringan).\n"
    "run({\n"
    "    name = " + q(name) + ",\n"
    "    title = " + q(title) + ",\n"
    "    credit = " + q(credit) + ",\n"
    "    logoAssetId = " + q(logo_id) + ",\n"
    "    encoded = true,\n"
    "    autoStart = true,\n"
    "    showInfoButtons = false,\n"
    "    script = BFE_PAYLOAD,\n"
    "})\n"
)

pathlib.Path(out_path).write_text(head + payload + '"\n' + loader_core + run_call)
PY

if command -v luac >/dev/null 2>&1; then
    luac -p "$OUT"
fi

printf 'Built: %s\n' "$OUT"
