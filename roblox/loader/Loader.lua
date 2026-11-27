-- Script | ServerScriptService

local VERSION = "9.5"
local HUB_NAME = "Clipper Hub"
local LOGO_ASSET_ID = 102269948329032

local REPO = "https://raw.githubusercontent.com/the-devnotes/BikeForEggs/main"
local URL = REPO .. "/dist/BikeForEggs_AllInOne.lua"

local games = {
	[10766620257] = URL,
}

local byPlace = {
	[74023858073178] = URL,
}

local id = game.GameId
local place = game.PlaceId
local sumber = games[id] or byPlace[place] or URL
local nama = (id == 10766620257 or place == 74023858073178) and "Bike For Egg!" or "Game Lain"

print(("[%s v%s] %s | PlaceId: %d | UniverseId: %d | Logo: rbxassetid://%d")
	:format(HUB_NAME, VERSION, nama, place, id, LOGO_ASSET_ID))

local ok, kode = pcall(function()
	return game:GetService("HttpService"):GetAsync(sumber)
end)

if not ok or type(kode) ~= "string" or kode == "" then
	warn(("[%s] Gagal ambil script: %s"):format(HUB_NAME, tostring(kode)))
	return
end

local okLoad, fn = pcall(loadstring, kode, nama)
if not okLoad or not fn then
	warn(("[%s] Gagal loadstring: %s"):format(HUB_NAME, tostring(fn)))
	return
end

local okRun, err = pcall(fn)
if not okRun then
	warn(("[%s] Error: %s"):format(HUB_NAME, tostring(err)))
end
