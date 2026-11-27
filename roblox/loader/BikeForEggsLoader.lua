-- Script | ServerScriptService

local VERSION = "9.5"
local HUB_NAME = "Clipper Hub"
local LOGO_ASSET_ID = 102269948329032

local NAME_GAME = "Mendeteksi..."

local DAFTAR_NAMA = {
    [10766620257] = "Bike For Egg!",
    Universal     = "Game Lain",
}

local REPO = "https://raw.githubusercontent.com/the-devnotes/BikeForEggs/main"
local SCRIPT_BFE = REPO .. "/dist/BikeForEggs_AllInOne.lua"

local games = {
    [10766620257] = SCRIPT_BFE,
}

local gamesByPlace = {
    [74023858073178] = SCRIPT_BFE,
}

local UNIVERSAL = SCRIPT_BFE

local universeId = game.GameId
local placeId    = game.PlaceId
local scriptURL  = games[universeId] or gamesByPlace[placeId]

if scriptURL then
    NAME_GAME = DAFTAR_NAMA[universeId] or DAFTAR_NAMA[placeId] or "Bike For Egg!"
else
    NAME_GAME = DAFTAR_NAMA.Universal
    scriptURL = UNIVERSAL
end

print(string.format(
    "[%s v%s] %s | PlaceId: %d | UniverseId: %d | Logo: rbxassetid://%d",
    HUB_NAME, VERSION, NAME_GAME, placeId, universeId, LOGO_ASSET_ID
))

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
    warn(string.format(
        "[%s] Gagal ambil script | PlaceId: %d | UniverseId: %d | Error: %s",
        HUB_NAME, placeId, universeId, tostring(err)
    ))
end
