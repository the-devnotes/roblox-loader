# BFE Mobile v5 — handoff (25 Nov 2026)

## File utama
- `/storage/emulated/0/Download/Lainnya/BikeForEggsMobile_v5.lua` — satu-satunya file yang diubah. Versi tampil `v5.2`.
- `BikeForEggsMobile (4).lua` dan `BikeForEggsMobile_V2.lua` **jangan disentuh**.
- Mock test: `/data/data/com.termux/files/usr/tmp/opencode/bfe_mock.lua` (jalankan `lua bfe_mock.lua`).
- Cek syntax: `luac -p BikeForEggsMobile_v5.lua`.

## Temuan dari API log
`https://dumperai.netlify.app/api/log/place_74023858073178`
- Remote penting: `RS.Network.Eggs: RequestAreaEggSnapshot` (RF), `RequestEggRecord` (RF), `RequestAreaEggCarry` (RF), `AreaEggCarryState` (RE), `AreaEggClaimFeedback` (RE), `AreaEggUpdated/BatchUpdated/Removed` (RE).
- `workspace.AreaEggSlotsClient` berisi model `AreaEgg_<uuid>`. **Mayoritas model tidak punya attribute apa pun** (cuma `_lemonadeUniqueId`); hanya egg Crystal Canyon baru yang punya `AreaId`, `DisplayName`, `PetDisplayName`, `ProgressionOrder`. Inilah sebabnya dulu muncul `Egg | rar=0 prog=0 val=0`.
- `AreaEggCarryState` payload: `{Uid="AreaEgg_...", AssetCategory="Chicken"|"Grizzlite"|..., AreaId="Forest"|..., IsCarrying=true, ...}`.
- `AreaEggClaimFeedback` payload: `{Rarity="Cosmic"|"Mythic"|"Legendary", Position=Vector3, AssetCategory="Grizzlite", DisplayName="Grizzlite", Color=...}`.
- `Prompt CarryAreaEgg` ada di `workspace.SmartPromptPart`, `ActionText="Steal"`, `HoldDuration=1.2`, `MaxActivationDistance=8` (server likely validasi jarak; versi lama memaksa 100 → banyak steal gagal).
- Rarity nyata di game termasuk **Cosmic** dan **Eternal** (tidak ada di dropdown lama). `cosmic` tidak boleh dipetakan dari teks area "Cosmic".

## Yang sudah diperbaiki di v5.2
1. **Area dropdown benar-benar mengunci scope**
   - `setArea()` sekarang memaksa `state.allAreas=false`, menyinkronkan semua dropdown area (Steal/Filter/Area) dan toggle "Semua Area".
   - `areaEggs()` memakai `AreaId` attribute / `uidArea` dulu, baru fallback nearest-area.
   - Dropdown "Mode ambil" = `{Bergiliran, Terbaik (Best)}` ditambahkan di halaman Steal; toggle Best lama tetap tersinkron.
   - Toggle **Auto pilih area terbaik** (default ON) + tombol **Pilih Area Terbaik** di Steal/Filter/Area. Auto area dievaluasi ulang tiap ~12 detik saat steal.
2. **Data egg tidak lagi selalu `?`**
   - Snapshot di-index juga lewat `snapMeta` (Uid → record), `uidCategory` (`AssetCategory`/`DisplayName`), `uidArea`, `categoryProg`.
   - `scanKV` kini membaca `AssetCategory`, `Category`, `PetDisplayName`, `PetName`, `Category`, `Rarity`, `Weight`, `Image/Icon/Texture`.
   - Event `CarryState` mencatat Uid → category/area; event `ClaimFeedback` mengisi `categoryRarity` (Cosmic=12, Eternal=13). Feedback tanpa Uid juga dicocokkan lewat `Position` ke egg terdekat.
   - `eggInfo()` menggabungkan attribute + snapshot + cache feedback. Info cache di-reset setelah feedback baru.
   - Rarity dari teks sekarang **exact token**, bukan substring, supaya nama area "Cosmic" tidak jadi rarity.
3. **Steal lebih bisa dipercaya**
   - Teleport ke `eggPos` asli + 2 studs (bukan posisi basi dari kartu).
   - `MaxActivationDistance` untuk carry dibatasi 12 (bukan 100).
   - Setelah fire, script menunggu `AreaEggCarryState`; Uid/Area harus cocok dengan target. Kalau salah target / tanpa konfirmasi → retry sampai 3x dan **tidak langsung balik ke base**.
   - Fallback untuk environment tanpa event (mock): tetap menganggap prompt fired sebagai sukses.
4. **UI**
   - Halaman Egg: kartu berisi preview 3D/gambar, Rarity berwarna, Value, Berat kg, Prog, Chance, tombol `Steal Egg Ini`.
   - Tombol `Dump 1 Egg` di halaman Egg mencetak attribute + snapshot mentah untuk debugging lanjutan.
   - Min Rarity sekarang sampai `Eternal+`; urutan Auto: event → rarity → progression → chance → value → berat.

## Validasi lokal
- `luac -p` OK.
- Mock: boot, anti double-run, minimize/close, Best Egg, Min Progression filter, 3 kartu egg, tombol Steal per kartu, claim feedback Cosmic masuk ke kartu Grizzlite, dropdown area bisa diklik — semua lolos.
- **Belum diuji di Roblox asli.** Perlu test user lagi.

## Kalau masih bermasalah, langkah berikutnya
1. Minta log `Dump 1 Egg` dari halaman Egg (isi `SNAPSHOT:` dan `ATTR:`). Itu akan menunjukkan apakah `AssetCategory` benar-benar ada di Records.
2. Kalau snapshot tidak punya `AssetCategory`, coba invoke `Eggs: RequestEggRecord` dengan `(uid)` / `(area, uid)` / `(slug)` lalu log hasilnya — remote ini ada di daftar API.
3. Kalau steal masih gagal walau Uid cocok, cek apakah server butuh `RequestAreaEggCarry` RF dipanggil, bukan hanya `fireproximityprompt`. Remote itu tersedia.
4. Perhatikan `AreaEggRemoved` / `AreaEggBatchUpdated`: bisa dipakai untuk menghapus egg yang sudah diambil dari galeri tanpa wait 4 detik.
