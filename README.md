# Bike For Eggs — Mobile v5 (clean source)

Folder ini siap dipush ke GitHub. Script asli di `../Lainnya/BikeForEggsMobile_v5.lua` **tidak diubah**; folder ini hanya memisahkan kodenya supaya enak dibaca/dikelola.

## Cara pakai di Roblox

### Opsi A — paling aman (disarankan)
1. Buka `dist/BikeForEggsMobile_v5_2.lua`.
2. Copy seluruh isinya.
3. Paste ke satu `LocalScript` (misal di `StarterPlayerScripts`).
4. Jalankan. Script ini **standalone**: BFEUI sudah ditanam, tidak butuh `HttpGet` / module luar.

### Opsi B — Loader ClipperHub (universal)
1. `loader.lua`: UI biru + hitam, ikon digambar (tanpa emoji), tanda `By ClipperHub`, **tanpa subjudul**.
2. Paste `loader.lua` ke `LocalScript`. Loader langsung jalan otomatis, tanpa klik.
3. Untuk script lain, edit tabel `SOURCES` di atas. Isi URL Netlify / GitHub raw / gist; sumber dicoba berurutan.
4. Set `ENCODED = true` kalau sumber berisi hex. Set `false` kalau sumber Lua polos.

#### Auto loader tanpa UI
`loader-auto.lua` adalah versi satu baris ala:

```lua
loadstring(game:HttpGet("URL"))()
```

Isinya otomatis mengambil file `.hex`, mendekode, lalu menjalankan. Tidak ada kartu UI.

#### Site Netlify aktif
- Project: `bikeforeggs-loader`
- Team: `YE` (`danzsukargb`)
- URL: https://bikeforeggs-loader.netlify.app
- File Lua polos: https://bikeforeggs-loader.netlify.app/BikeForEggsMobile_v5_2.lua
- File hex (dipakai loader): https://bikeforeggs-loader.netlify.app/BikeForEggsMobile_v5_2.hex
- Project ID: `3c1e05d6-93c9-453a-857a-2d4f4c68702e`

Kalau file `.hex` dibuka di browser, isinya tampak seperti deretan angka, bukan kode Lua. Roblox tetap bisa menjalankannya setelah didekode loader.

Catatan jujur: ini **penyamaran**, bukan enkripsi. Siapa pun yang punya URL dan tahu caranya tetap bisa mendekode. Tidak mungkin menyembunyikan kode sepenuhnya selama Roblox harus mengunduh source-nya untuk `loadstring`.

#### Deploy ulang pakai CLI
```sh
sh prepare-netlify.sh
netlify deploy --prod --dir=netlify --no-build
```

`prepare-netlify.sh` otomatis membuat ulang file `.hex` dari `dist/`. `netlify init` sudah pernah dijalankan: skill Netlify terpasang di `.agents/skills` dan MCP server ditambahkan ke `opencode.jsonc`.

Logo: upload `logo.jpg` ke Roblox lalu isi `LOGO_ID`. Kalau kosong, loader menggambar ikon telur biru.

Kalau `loadstring` tidak tersedia di environment-mu, pakai Opsi A. Opsi A selalu paling aman karena tidak bergantung URL sama sekali.

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
│   ├── 61..67_page_*.lua         halaman Utama/Ambil/Tetas & Jual/Filter/Area/Log
│   ├── 70_dashboard.lua          update dashboard
│   ├── 71_loops.lua              loop ambil/tetas/jual/event
│   └── 99_start.lua              start + error notice
├── loader.lua            loader UI ClipperHub (hex + auto loadstring)
├── loader-auto.lua       auto loader satu baris, tanpa UI
├── netlify/              folder publish (script + hex + logo + status)
│   └── BikeForEggsMobile_v5_2.hex  source tersamar untuk loader
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
