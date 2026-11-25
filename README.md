# Bike For Eggs — Mobile v5 (clean source)

Folder ini siap dipush ke GitHub. Script asli di `../Lainnya/BikeForEggsMobile_v5.lua` **tidak diubah**; folder ini hanya memisahkan kodenya supaya enak dibaca/dikelola.

## Cara pakai di Roblox

### Opsi A — paling aman (disarankan)
1. Buka `dist/BikeForEggsMobile_v5_2.lua`.
2. Copy seluruh isinya.
3. Paste ke satu `LocalScript` (misal di `StarterPlayerScripts`).
4. Jalankan. Script ini **standalone**: BFEUI sudah ditanam, tidak butuh `HttpGet` / module luar.

### Opsi B — load lewat URL (GitHub raw / Netlify)
1. `loader.lua` sekarang punya UI biru + hitam, ikon digambar (tanpa emoji).
2. Paste `loader.lua` ke `LocalScript`.
3. Pilih sumber:
   - **GitHub raw**: default sudah terisi `danu-dev/roblox` branch `main`. Repo harus PUBLIC.
   - **Netlify**: pakai CLI seperti di bawah, lalu isi `NETLIFY_URL` di `loader.lua`.

#### Deploy Netlify pakai CLI
```sh
npm install -g netlify-cli
netlify login
netlify init          # sekali saja, pilih "Create & configure a new site"
sh deploy-netlify.sh
```

Kalau site sudah ada dan ingin di-link:
```sh
netlify link --id <site-id>
NETLIFY_SITE_ID=<site-id> sh deploy-netlify.sh
```

`deploy-netlify.sh` otomatis menjalankan `build.sh`, menyalin script + logo ke folder `netlify/`, lalu `netlify deploy --prod --dir=netlify`.

Setelah deploy, buka URL yang muncul. Isi di `loader.lua`:
```lua
local NETLIFY_URL = "https://nama-site.netlify.app/BikeForEggsMobile_v5_2.lua"
```

Logo: upload `logo.jpg` ke Roblox lalu isi `LOGO_ID`. Kalau kosong, loader menggambar ikon telur biru.

Urutan ambil loader: Netlify (kalau diisi) → GitHub raw → gist cadangan. Kalau `loadstring` tidak tersedia di environment-mu, pakai Opsi A. Opsi A selalu paling aman karena tidak bergantung URL sama sekali.

## Strukturfolder

```
BikeForEggs/
├── build.sh              # regenerate dist dari src
├── dist/
│   └── BikeForEggsMobile_v5_2.lua   # HASIL GABUNGAN — yang dipaste ke Roblox
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

Roblox `LocalScript` cuma bisa satu file. Jadi `src/` dibuat terpisah untuk clean code, lalu `build.sh` menggabungkannya lagi jadi satu file di `dist/`. Semua bagian masih berbagi scope yang sama seperti script utuh, jadi perilakunya tidak berubah.

## Regenerate setelah edit `src/`

```sh
cd /storage/emulated/0/Download/BikeForEggs
sh build.sh
```

`build.sh` juga menjalankan `luac -p` kalau tersedia. Hasil `dist/BikeForEggsMobile_v5_2.lua` saat ini **byte-identik** dengan `BikeForEggsMobile_v5.lua` yang sudah dites mock.

## Status singkat

- Auto pilih area terbaik: sudah terbukti jalan di log user (`Forest -> Crystal Canyon`).
- Steal + konfirmasi `AreaEggCarryState`: sudah terbukti jalan (`Grizzlite @ Crystal Canyon`).
- v5.3: setelah prompt steal, karakter **langsung teleport ke base** dulu, baru menunggu konfirmasi — penjaga tidak sempat mengambil egg walaupun targetnya di paling belakang.
- v5.4: debug data aktif untuk **semua area** — `RequestRuntimeSnapshot` + `RequestEggRecord` diprobe otomatis (terbatas) dan bisa dipicu manual dari halaman Egg.
- Kartu egg tidak lagi memakai `?` kalau rarity belum ada; memakai `-`.
- Tombol debug: **Probe Record (semua area)**, **Dump Semua Egg**, **Dump 1 Egg**, dan toggle **Auto Probe Record**.
- v5.5 (optimasi masuk game): satu `workspace:GetDescendants()` untuk hatch/sell + smart prompt, cache model egg, kartu galeri dibuat hanya saat halaman Egg dibuka, probe debug ditunda 5 detik, dan toggle **Mode Ringan (4 kartu)** di halaman Info.
- v5.6: error `attempt to call a nil value` di mode Best diperbaiki (`rarityOf` dipindah lebih awal). Probe `RequestEggRecord` sekarang pakai Uid penuh `AreaEgg_<guid>` dan kategori dari `PetDisplayName`.
- v5.7: kategori generik `egg` tidak dipakai lagi; probe UID-first, log argumen/raw response (`RECORD coba`, `SNAPSHOT RAW`) supaya format remote bisa dilacak tanpa klik manual.
- v5.8: snapshot `ActiveAssets` + hook `StealTargetEvent` sebagai sumber data cadangan; fallback progression untuk egg bertema (penguin … cerberus).
- Lihat `TODO.md` kalau sebagian rarity/value/weight tetap kosong.
