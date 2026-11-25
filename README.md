# Bike For Eggs — Mobile v5 (clean source)

Folder ini siap dipush ke GitHub. Script asli di `../Lainnya/BikeForEggsMobile_v5.lua` **tidak diubah**; folder ini hanya memisahkan kodenya supaya enak dibaca/dikelola.

## Cara pakai di Roblox

### Opsi A — paling aman (disarankan)
1. Buka `dist/BikeForEggsMobile.lua`.
2. Copy seluruh isinya.
3. Paste ke satu `LocalScript` (misal di `StarterPlayerScripts`).
4. Jalankan. Script ini **standalone**: BFEUI sudah ditanam, tidak butuh `HttpGet` / module luar.

### Opsi B — load dari GitHub raw
1. Push folder ini ke GitHub.
2. Buka `loader.lua`, ganti `USER/REPO/BRANCH` dengan milikmu.
3. Paste `loader.lua` ke `LocalScript`.

Kalau `loadstring` / HttpGet tidak tersedia, pakai Opsi A.

## Strukturfolder

```
BikeForEggs/
├── build.sh              # regenerate dist dari src
├── dist/
│   └── BikeForEggsMobile.lua   # HASIL GABUNGAN — yang dipaste ke Roblox
├── src/                  # source bersih, dipisah per bagian
│   ├── 00_header.lua             anti double-run + notice
│   ├── 10_boot_start.lua         boot + services
│   ├── 20_ui_library.lua         BFEUI mini library
│   ├── 21_page_widgets.lua       widget dropdown/toggle/button/card
│   ├── 30_state.lua              state + konstanta area/rarity
│   ├── 31_log.lua                log system
│   ├── 32_helpers.lua            parse/format/guid/ser
│   ├── 40_snapshot.lua           RequestAreaEggSnapshot + index
│   ├── 41_egg_data.lua           eggInfo, score, filter, gallery data
│   ├── 50_base_area.lua          base + setArea + pickBestArea
│   ├── 51_prompts.lua            scan proximity prompt
│   ├── 52_steal.lua              doSteal + konfirmasi CarryState
│   ├── 60_ui_boot.lua            init UI + sidebar
│   ├── 61..68_page_*.lua         halaman Home/Steal/Auto/Filter/Egg/Area/Log/Info
│   ├── 70_dashboard.lua          update dashboard
│   ├── 71_loops.lua              loop hatch/sell/snapshot/event
│   └── 99_start.lua              start + error notice
├── loader.lua            optional raw-GitHub loader
├── TODO.md               catatan lanjutan / bug yang belum selesai
└── docs/
    └── BFE_V5_HANDOFF.md  catatan teknis hasil investigasi API
```

## Kenapa `src/` tidak langsung dipaste?

Roblox `LocalScript` cuma bisa satu file. Jadi `src/` dibuat terpisah untuk clean code, lalu `build.sh` menggabungkannya lagi jadi satu file di `dist/`. Semua bagian masih berbagi scope yang sama seperti script v5.2, jadi perilakunya tidak berubah.

## Regenerate setelah edit `src/`

```sh
cd /storage/emulated/0/Download/BikeForEggs
sh build.sh
```

`build.sh` juga menjalankan `luac -p` kalau tersedia. Hasil `dist/BikeForEggsMobile.lua` saat ini **byte-identik** dengan `BikeForEggsMobile_v5.lua` yang sudah dites mock.

## Status singkat

- Auto pilih area terbaik: sudah terbukti jalan di log user (`Forest -> Crystal Canyon`).
- Steal + konfirmasi `AreaEggCarryState`: sudah terbukti jalan (`Grizzlite @ Crystal Canyon`).
- Belum selesai: rarity/value/weight masih `0` untuk egg yang belum pernah di-claim. Lihat `TODO.md`.
