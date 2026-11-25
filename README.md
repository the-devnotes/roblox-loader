# Bike For Eggs — Mobile v5 (clean source)

Folder ini siap dipush ke GitHub. Script asli di `../Lainnya/BikeForEggsMobile_v5.lua` **tidak diubah**; folder ini hanya memisahkan kodenya supaya enak dibaca/dikelola.

## Cara pakai di Roblox

### Opsi A — paling aman (disarankan)
1. Buka `dist/BikeForEggsMobile_v5_2.lua`.
2. Copy seluruh isinya.
3. Paste ke satu `LocalScript` (misal di `StarterPlayerScripts`).
4. Jalankan. Script ini **standalone**: BFEUI sudah ditanam, tidak butuh `HttpGet` / module luar.

### Opsi B — Loader ClipperHub
1. Paste `loader.lua` ke satu `LocalScript`.
2. Loader langsung jalan otomatis: UI biru + hitam, ikon digambar tanpa emoji, tanda `By ClipperHub`, tanpa subjudul.
3. Loader mengambil payload hex dari Netlify, mendekode, lalu menjalankan dengan `loadstring`.

URL yang dipakai loader:

```
https://bikeforeggs-loader.netlify.app/clipperhub.lua?k=ClipperHub-2026
```

Kalau URL itu dibuka di browser biasa (tanpa token), request di-redirect ke `/`. Hanya request dengan query `k` yang benar yang mendapat isi hex lewat rewrite `_redirects`. Tidak ada file `.lua` statis yang ikut dipublish, jadi source polos tidak bisa dibuka langsung.

Versi minimal tanpa UI, kalau mau satu baris:

```lua
loadstring((game:HttpGet("https://bikeforeggs-loader.netlify.app/clipperhub.lua?k=ClipperHub-2026"):gsub("%s+", ""):gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end)))()
```

Catatan jujur: ini penyamaran + gate sederhana, bukan enkripsi. Token bisa dipalsukan dengan `curl` kalau nilainya diketahui. Tidak mungkin menyembunyikan kode sepenuhnya selama Roblox harus mengunduh source untuk `loadstring`.

## Netlify

- Project: `bikeforeggs-loader`
- Team: `YE` (`danzsukargb`)
- URL: https://bikeforeggs-loader.netlify.app
- Project ID: `3c1e05d6-93c9-453a-857a-2d4f4c68702e`
- `publish = "public"` — isinya `logo.jpg`, payload hex, dan `_redirects`
- `public/_redirects` — aturan gate: token → payload, selain itu → `/`

Deploy ulang:

```sh
sh deploy-netlify.sh
```

Atau manual:

```sh
sh prepare-netlify.sh
netlify deploy --prod --dir=public --no-build
```

`prepare-netlify.sh` menjalankan `build.sh`, membuat payload hex, menulis `_redirects`, lalu menyiapkan folder `public/`. Token bisa diganti lewat env:

```sh
CLIPPERHUB_TOKEN=token-baru sh deploy-netlify.sh
```

Kalau token diganti, jangan lupa ganti juga query `k=` di `loader.lua`.

Logo: upload `logo.jpg` ke Roblox lalu isi `LOGO_ID` di `loader.lua`. Kalau kosong, loader menggambar ikon telur biru.

## Strukturfolder

```
BikeForEggs/
├── build.sh              # gabungkan src/ -> dist/ + luac -p
├── dist/
│   └── BikeForEggsMobile_v5_2.lua   # HASIL GABUNGAN — dipaste ke Roblox
├── src/                  # source bersih, dipisah per bagian
│   ├── 00_header.lua             anti double-run + notice
│   ├── 10_boot_start.lua         boot + services
│   ├── 20_ui_library.lua         BFEUI mini library
│   ├── 21_page_widgets.lua       widget dropdown/toggle/button/card
│   ├── 30_state.lua              state + konstanta area/rarity
│   ├── 31_log.lua                log system
│   ├── 32_helpers.lua            parse/format/guid/ser
│   ├── 41_egg_data.lua           eggInfo, score, filter
│   ├── 50_base_area.lua          base + setArea + pickBestArea
│   ├── 51_prompts.lua            scan proximity prompt
│   ├── 52_steal.lua              ambil egg + konfirmasi CarryState
│   ├── 60_ui_boot.lua            init UI + sidebar
│   ├── 61..67_page_*.lua         Utama/Ambil/Tetas & Jual/Filter/Area/Log
│   ├── 70_dashboard.lua          update dashboard
│   ├── 71_loops.lua              loop ambil/tetas/jual/event
│   └── 99_start.lua              start + error notice
├── loader.lua            loader UI ClipperHub (auto + hex)
├── netlify.toml          publish = public
├── public/               folder publish statis (generated)
│   ├── _redirects                  gate token + redirect browser
│   ├── a3f9c2e1d7.txt              payload hex
│   └── logo.jpg
├── prepare-netlify.sh    build + payload + _redirects + copy aset
├── deploy-netlify.sh     prepare + netlify deploy
├── TODO.md               handoff ringkas
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

## Fokus versi ringkas

- Ambil egg otomatis + pilih rarity minimum.
- Halaman: Utama, Ambil, Tetas & Jual, Filter, Area, Log.
- `fallback = true`, `strict = false`: egg tanpa data tetap bisa diambil.
- Log: 4000 baris, tampil 300 baris terakhir.
- Anti-double-run: `"Script sudah berjalan!"`.
