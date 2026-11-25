# TODO / handoff cepat

## v5.9d — hubungkan event ke katalog
- Log membuktikan `Eggs: RuntimeOwnerUpdated` mengirim `Records={Egg_<guid>={AssetCategory="Eternal Lunar Dragon", ...}}` dan `AreaEggUpdated` mengirim `AssetCategory` + `BoundsCFrame` tanpa Uid.
- `walkEvent()` sekarang meneruskan parent key. Record `Egg_<guid>` dipetakan langsung ke `uidCategory[guid]` + `snapCache[guid]`, sehingga `eggInfo()` bisa mencari kategori itu di katalog `_Index`.
- `AreaEggUpdated` dicocokkan ke egg terdekat (maks 15 stud) memakai `BoundsCFrame`/`Position` + `AreaId`.
- `catalogInfoFromData()` sekarang menyimpan `info.keys` dan modul juga masuk ke `catalog.entries`; `applyCatalog()` punya fallback scan kalau `catalog.byKey` hanya berisi 1 kunci (bug yang masih terlihat di log).
- Indeks field modul dengan `__index` ketat sekarang di-`pcall`, jadi `CATALOG TABLE error` tidak lagi menggagalkan pembacaan `Assets`.

## v5.9c — kapasitas log
- `MAX_LOG` 250 → `LOG_CAP.store = 4000`, panjang baris 420 → 3000 karakter.
- UI Log hanya merender 300 baris terakhir + penanda "... N baris sebelumnya disembunyikan ..." supaya tetap ringan di HP.
- `Copy All` tetap mengambil seluruh isi buffer (4000 baris).

## v5.9b — RarityNumber asli dari log user
- Log `RARITY MODULE: {Rarities={Exclusive={RarityNumber=7,...}, BrainrotGod={RarityNumber=6,...}}}` membuktikan urutan rarity game ada di field `RarityNumber`, bukan tebakan `common/uncommon/...`.
- `readRarityModule()` sekarang membangun `catalog.rarityNumber` dari `data.Rarities` (kunci, `_id`, `DisplayName`) dan memperpanjang `RARITY`/`RARITY_LABEL`/`RARITY_NAMES` sampai `RarityNumber` maksimal.
- `rarityOf()` dan `rarityFromText()` memprioritaskan `catalog.rarityNumber` sebelum `RARITY_ALIAS`.
- `catalog.read()` sekarang dibungkus `pcall`, tiap modul dicoba dengan `pcall`, dan ada log `CATALOG <n> [true/false]` untuk 3 modul pertama + `Katalog dibaca: ...`.
- Hook event ditambah: `AreaEggUpdated`, `AreaEggBatchUpdated`, `RuntimeOwnerUpdated` (Eggs & ActiveAssets). Probe snapshot ditambah `ActiveAssets: RequestStealTarget` dan `Eggs: RequestAreaEggRareSpawnPresentations`.

## v5.9 — katalog client sebagai sumber metadata utama
- Dump membuktikan `ReplicatedStorage.Directory._Index` berisi ModuleScript per pet (`Penguin`, `FennecFox`, `Ice Dragon`, …) dan `ReplicatedStorage.Directory.Rarity._Index` berisi tier (`Basic`, `Rare`, `Mythical`, `Exclusive`, `Secret`, …). Modul ini bisa di-`require()` dari client, jadi tidak perlu menebak argumen `RequestEggRecord`.
- File baru `src/42_catalog.lua` membaca `_Index`, `Directory.Assets`, dan `BaseConfigs.Default`, lalu mengisi `catalog.byKey` + `categoryRarity/Prog/Value/Weight/Chance/Image`.
- `eggInfo()` (41) sekarang menggabungkan katalog memakai `PetDisplayName`, `DisplayName`, `PetModelName`, `EggTheme`, dan `m.Name`. `scanKV()` juga mengenali `OriginalImportNumber`.
- Rarity label diselaraskan: `Basic / Uncommon / Rare / Epic / Legendary / Mythic / Secret / Divine / Exclusive / Exotic / Superior / Cosmic / Eternal`. Alias ditambah: `mythical`, `exotic`, `superior`, `brainrotgod`, `limited`, `rainbow`.
- Tombol baru **Egg -> Baca Katalog (client)**. Probe otomatis juga memanggil katalog sekali setelah ±5 detik, bukan saat first entry.
- Helper katalog dibungkus `do ... end` dan disimpan sebagai field `catalog.read` supaya tidak menambah local di `boot()` (batas luac 200 local/function).
- Perlu dicek di game: apakah `RARITY MODULE:` dan `CATALOG <nama>:` memperlihatkan struktur asli. Kalau tier order beda, tinggal sesuaikan `RARITY_ALIAS`.

## v5.8 — sumber data cadangan
- Log user memastikan `RequestEggRecord` mengembalikan nil untuk semua `AreaEgg_<guid>` (semua format argumen). Remote itu bukan sumber data egg di plot; kemungkinan untuk aset aktif/pet yang sudah dimiliki.
- `refreshRuntimeSnapshot()` sekarang memanggil dua namespace: `Eggs: RequestRuntimeSnapshot` dan `ActiveAssets: RequestRuntimeSnapshot`, dengan log `RUNTIME RAW [<remote>] (...)`.
- Hook pasif `ActiveAssets: StealTargetEvent` ditambahkan. Uid asli dari event ini disimpan di `assetUidHints` dan ikut diprobe (maks 3). `carryEventSeen`/`lastCarry` tetap HANYA diubah oleh `AreaEggCarryState` supaya alur steal tidak berubah.
- Fallback progression untuk egg bertema: `THEME_PROG` (penguin=1 … cerberus=10) dari urutan katalog di dump, dipakai hanya kalau model tidak punya `ProgressionOrder`.
- `probeRecord` juga mencoba `{Uuid=...}`, `{AssetUid=...}`, `{assetUid=...}`.

## v5.7 — probe & identitas egg
- Log API dumper tidak berisi argumen pemanggilan remote: `_lemonadeUniqueId` pada semua instance adalah marker alat dump, bukan argumen game. Jadi format argumen masih harus dilihat dari log `RECORD ...` / `SNAPSHOT RAW ...` di game.
- `Egg`/`egg`/`Egg #n` sekarang dianggap nama generik (`genericEggName()` di `32_helpers.lua`). Tidak disimpan ke `uidCategory`, tidak dipakai sebagai kategori probe. Probe sekarang UID-first (`uid:AreaEgg_<guid>`), bukan `cat:egg`.
- `eggInfo()` mengambil nama dari `PetDisplayName` > `DisplayName` (buang suffix "Egg") > `PetModelName` > `EggTheme`.
- `probeRecord()` mencoba argumen string Uid, table `{Uid=...}` / `{uid=...}`, `(area, uid)`, tanpa argumen, dan kategori hanya kalau tidak generik. Log `RECORD coba ...` + `RECORD <args>: <raw>` keluar walaupun auto probe (dithrottle 25 detik).
- `RequestAreaEggSnapshot` / `RequestRuntimeSnapshot` diberi variasi argumen `{AreaId=...}`, `{Area=...}`, `{areaId=...}` dan log `SNAPSHOT RAW (...)` / `RUNTIME RAW (...)` (dithrottle 30 detik) untuk melacak kenapa `cache=1`.

## v5.6 — perbaikan dari log user
- `attempt to call a nil value` di mode Best: `applyCategoryMeta()` (file 40) memanggil `rarityOf()` yang dulu didefinisikan di file 41. Di Luau, local yang dibuat belakangan tidak terlihat dari fungsi sebelumnya, jadi jadi global nil. `rarityOf()` sekarang pindah ke `32_helpers.lua` (sebelum snapshot).
- `RequestEggRecord` sebelumnya dikirimi guid saja; server butuh Uid penuh `AreaEgg_<guid>`. Probe sekarang mencoba `m.Name`, `"AreaEgg_"..uid`, dan guid, dengan/tanpa area.
- `debugCategoryOf()` sekarang mengutamakan `PetDisplayName`, lalu `DisplayName` (buang suffix "Egg"), lalu `PetModelName`, bukan fallback `Egg`/`bear`.
- Probe mencatat balasan apa pun (termasuk table kosong) dan log `RECORD` menampilkan argumen yang dipakai.

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
