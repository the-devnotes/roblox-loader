# TODO / handoff cepat

## v5.5 — optimasi first entry
- `scanPrompts()` sekarang mengisi hatch, sell, **dan** `SmartPromptPart` dalam satu `workspace:GetDescendants()` (dulu dua scan terpisah tiap 2 detik).
- `areaEggs()` memakai cache model + invalidiasi `DescendantAdded/Removing` dan TTL 1,5 detik, bukan menyusuri `AreaEggSlotsClient` tiap dipanggil.
- `clearInfoCache()` dipakai semua tempat, jadi tidak membuat table metatable baru berulang kali dan `e.info` ikut terhapus.
- Galeri tidak di-build saat boot; kartu 3D dibuat saat halaman Egg dibuka (`ui.onPageShow`). Mode Ringan membatasi 4 kartu.
- Snapshot ditunda 1,2 detik, probe debug ditunda 5 detik, dan auto-area tidak force rebuild galeri.

## v5.4 — sudah diperbaiki
Debug dataegg berlaku untuk **semua area**:
- `RequestRuntimeSnapshot` dan `RequestEggRecord` dipanggil dengan beberapa variasi argumen `(uid)`, `(area, uid)`, `(category)`, `(area, category)`.
- Hasilnya di-index ke `categoryRarity/Value/Weight/Chance/Image/Prog` dan dipakai `eggInfo()` lewat `uidCategory`.
- `PetDisplayName` / `DisplayName` dari model disimpan sebagai kategori, jadi egg tanpa atribut rarity ikut terisi.
- UI Egg: toggle **Auto Probe Record**, tombol **Probe Record (semua area)**, **Dump Semua Egg**, **Dump 1 Egg**.
- Rarity kosong ditampilkan `-`, bukan `?`.

## v5.3 — sudah diperbaiki
Steal egg paling belakang membuat penjaga mengambil egg karena script menunggu konfirmasi `CarryState` sambil masih berdiri di dekat egg. Sekarang setelah prompt dikirim, karakter **langsung teleport ke base**, lalu konfirmasi ditunggu di base. Kalau Uid/Area salah, script kembali ke egg untuk retry.

## Dari log user terbaru (18:38–18:40)
Yang sudah OK:
- `Auto pilih area terbaik: Crystal Canyon` → auto area tidak lagi nempel di Forest.
- `Prompt CarryAreaEgg berhasil: Grizzlite @ Crystal Canyon.` → konfirmasi Uid/Area jalan.
- `AreaEggClaimFeedback` mengirim `Rarity="Cosmic"`, `AssetCategory="Grizzlite"`.

Yang masih bermasalah:
- `[Best] Grizzlite | rar=0 prog=4 val=0 berat=0.00 kg` **sebelum** claim feedback masuk.
- Scan 5 egg terdekat: `rar=0 val=0 berat=0.00 kg` untuk Pebble/Copperfist/Rubyrazor.

## Penyebab sementara
`RequestAreaEggSnapshot` -> `Records` hanya berisi:
`Uid`, `NestId`, `DroppedAt`, `AssetColorSeed`, `Mutations`, `BoundsCFrame`, `NestScale`, `BottomCFrame`, `AssetScale`.
Tidak ada `Rarity`, `Value`, `Weight` di record itu.

`Rarity` baru muncul dari `AreaEggClaimFeedback` **setelah** egg diambil. `AssetCategory` muncul dari `AreaEggCarryState`.

## Langkah berikutnya
1. Coba remote `RS.Network.Eggs: RequestEggRecord` (RF). Probe argumen:
   - `(uid)`
   - `(areaName, uid)`
   - `(assetCategory)` mis. `"Grizzlite"`
   - `(areaName, assetCategory)`
   Log hasilnya (dibatasi 1–2 egg supaya tidak spam).
2. Kalau `RequestEggRecord` mengembalikan `rarity`/`money`/`perSecond`, simpan ke:
   - `categoryRarity[lower(category)]`
   - `categoryValue[lower(category)]`
   - `categoryWeight[lower(category)]`
   lalu pasang di `eggInfo()` melalui `applyMeta()`.
3. Alternatif: `RequestRuntimeSnapshot` mungkin punya data pet/asset dengan `rarity`, `money`, `perSecond` (terlihat di API dump pada `AssetTool.Configuration`). Index juga remote ini.
4. Minta user klik **Egg -> Dump 1 Egg** kalau masih butuh `ATTR:` + `SNAPSHOT:` mentah.

## Catatan penting
Jangan ubah `BikeForEggsMobile (4).lua`. Edit di `src/`, lalu jalankan `sh build.sh`, lalu paste/`loader.lua` dari `dist/`.
