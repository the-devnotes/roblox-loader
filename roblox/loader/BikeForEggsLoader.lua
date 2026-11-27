-- [Script] | Lokasi: ServerScriptService
--[[
    Clipper Hub Loader - Bike For Eggs

    Struktur mengikuti contoh kamu persis:
    VERSION, HUB_NAME, games[GameId] = URL, deteksi game, fallback universal.

    Satu-satunya yang beda: kode diambil pakai HttpService:GetAsync (API resmi
    Roblox), bukan game:HttpGet (global executor).
]]

-- ============================================================
-- 1. IDENTITAS
-- ============================================================
local VERSION       = "9.5"
local HUB_NAME      = "Clipper Hub"
local LOGO_ASSET_ID = 102269948329032

-- Nama tampilan. Diisi otomatis dari games / universal.
local NAME_GAME = "Mendeteksi..."

-- ============================================================
-- 2. DAFTAR GAME YANG DIDUKUNG
-- ============================================================
-- Sumber di repo Bike For Eggs kamu (private).
-- Raw GitHub hanya bisa dibaca Roblox kalau repo-nya PUBLIC.
local REPO = "https://raw.githubusercontent.com/the-devnotes/BikeForEggs/main"
local SCRIPT_BFE = REPO .. "/dist/BikeForEggs_AllInOne.lua"

-- Format: [UniverseId / game.GameId] = "URL script"
-- PlaceId juga didukung lewat lookup kedua di bawah.
local games = {
    -- Ganti 0 dengan GameId Bike For Eggs asli (cek: print(game.GameId)).
    [0] = SCRIPT_BFE,

    -- Contoh dari loader kamu (bukan Bike For Eggs, jangan dipakai kalau bukan):
    -- [87689849729828] = SCRIPT_BFE,
    -- [74023858073178] = SCRIPT_BFE,
}

local gamesByPlace = {
    -- [PlaceId] = SCRIPT_BFE,
}

-- Dipakai kalau GameId/PlaceId tidak ada di daftar.
local UNIVERSAL = SCRIPT_BFE

-- ============================================================
-- 3. DETEKSI GAME (JANGAN DIUBAH)
-- ============================================================
local universeId = game.GameId
local placeId    = game.PlaceId
local scriptURL  = games[universeId] or gamesByPlace[placeId]

if scriptURL then
    NAME_GAME = "Bike For Eggs"
else
    NAME_GAME = "Game Lain"
    scriptURL = UNIVERSAL
end

-- ============================================================
-- 4. PRINT INFO
-- ============================================================
print(string.format(
    "[%s v%s] %s | PlaceId: %d | UniverseId: %d | Logo: rbxassetid://%d",
    HUB_NAME, VERSION, NAME_GAME, placeId, universeId, LOGO_ASSET_ID
))

-- ============================================================
-- 5. LOAD SCRIPT
-- ============================================================
local HttpService = game:GetService("HttpService")
local cache = {}

local function ambil(url)
    if cache[url] then return cache[url] end

    local ok, isi = pcall(function()
        return HttpService:GetAsync(url)
    end)

    if not ok or type(isi) ~= "string" or isi == "" then
        return nil, tostring(isi)
    end

    cache[url] = isi
    return isi
end

local kode, err = ambil(scriptURL)

if kode then
    print(string.format("[%s] Game supported! UniverseId: %d", HUB_NAME, universeId))
    print(string.format("[%s] Loading script...", HUB_NAME))

    local okLoad, fn = pcall(loadstring, kode, NAME_GAME)
    if not okLoad or not fn then
        warn(string.format("[%s] Gagal loadstring: %s", HUB_NAME, tostring(fn)))
        return
    end

    local okRun, errRun = pcall(fn)
    if not okRun then
        warn(string.format("[%s] Error saat jalan: %s", HUB_NAME, tostring(errRun)))
    end
else
    local msg = string.format(
        "\n[%s] Gagal ambil script dari repo!\nPlaceId: %d\nUniverseId: %d\nError: %s\n" ..
        "Catatan: repo the-devnotes/BikeForEggs masih private -> raw URL 404.\n" ..
        "Buat public, atau pakai dist/BikeForEggs_AllInOne.lua (hex, tanpa URL).",
        HUB_NAME, placeId, universeId, tostring(err)
    )
    warn(msg)
    print(msg)
end
