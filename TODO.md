# TODO / handoff cepat

## State final

### Script utama
- Fokus: ambil egg otomatis + pilih rarity minimum.
- File pasteable: `dist/BikeForEggsMobile_v5_2.lua`.
- Source dipisah per bagian di `src/`, digabung `build.sh`.
- File asli `/storage/emulated/0/Download/Lainnya/BikeForEggsMobile (4).lua` tidak pernah diubah.
- `BikeForEggsMobile_v5.lua` di folder `Lainnya` disinkron dari `dist/`.
- Halaman: Utama, Ambil, Tetas & Jual, Filter, Area, Log.
- `state.fallback = true`, `state.strict = false`.
- Log: 4000 baris, maks 3000 karakter/baris, tampil 300 terakhir.
- Anti-double-run: `"Script sudah berjalan!"`.
- Penamaan UI deskriptif, tanpa jargon ganda.

### Loader ClipperHub
- `loader.lua` satu-satunya loader: biru + hitam, ikon digambar, `By ClipperHub`, tanpa subjudul, auto-jalan.
- `ENCODED = true`; sumber: `https://bikeforeggs-loader.netlify.app/clipperhub.lua?k=ClipperHub-2026`.
- Gate memakai `public/_redirects`: query `k` benar → rewrite 200 ke payload hex; selain itu → 302 ke `/`.
- Tidak ada file `.lua` statis di `public/`; source polos tidak terekspos lewat URL statis.
- Edge function tidak dipakai: CLI gagal bundling karena Deno tidak bisa jalan di Termux/android-arm64.
- Catatan jujur: token bisa dispoof dengan `curl`. Ini gate, bukan enkripsi.
- `loader-auto.lua` sudah dihapus; contoh one-liner ada di README.
- `LOGO_ID` masih kosong. Isi dengan Asset ID `logo.jpg` kalau mau logo asli; kalau kosong, ikon telur biru dipakai.

### Netlify
- Project: `bikeforeggs-loader`, ID `3c1e05d6-93c9-453a-857a-2d4f4c68702e`.
- Team: `YE` / `danzsukargb`.
- URL: https://bikeforeggs-loader.netlify.app
- `netlify.toml`: `publish = "public"`, build command `sh prepare-netlify.sh`.
- `prepare-netlify.sh`: build → payload hex → `_redirects` → salin logo ke `public/`.
- `deploy-netlify.sh`: prepare + `netlify deploy --prod --dir=public --no-build`.
- Token default `ClipperHub-2026`, bisa diubah lewat `CLIPPERHUB_TOKEN`. Kalau diubah, update query `k=` di `loader.lua`.
- `index.html` sengaja dihapus; root akan 404 sampai web baru dibuat.

## Cara deploy ulang

```sh
cd /storage/emulated/0/Download/BikeForEggs
sh deploy-netlify.sh
```

Verifikasi cepat:

```sh
# browser biasa -> 302 ke /
curl -sSI https://bikeforeggs-loader.netlify.app/clipperhub.lua

# token benar -> hex
curl -sS \
  "https://bikeforeggs-loader.netlify.app/clipperhub.lua?k=ClipperHub-2026" \
  | python3 -c "import sys; print(bytes.fromhex(sys.stdin.read()).decode()[:80])"

# source polos -> 404
curl -sSI https://bikeforeggs-loader.netlify.app/BikeForEggsMobile_v5_2.lua
```

## Catatan environment

- Node Termux pernah rusak karena `libc++` lama; sudah diperbaiki dengan upgrade ke `30`.
- `node v26.13.1`, `npm 12.2.3`, `netlify-cli 27.20.1`.
- Login Netlify sudah tersimpan untuk `arsab201@gmail.com`.
- `netlify init` sudah memasang skill di `.agents/skills` dan MCP server di `opencode.jsonc`.

## Kalau lanjut bikin web

- Taruh file web di `public/`.
- Jangan menaruh source Lua polos di sana.
- Aturan `_redirects` masih mengarah ke `/`, jadi halaman baru otomatis jadi tujuan redirect.
