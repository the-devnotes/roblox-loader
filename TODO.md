# TODO / handoff cepat

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
