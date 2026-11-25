--[[
    Optional loader untuk GitHub raw.
    Ganti USER/REPO/BRANCH sebelum dipakai.
    Kalau loader gagal, copy isi dist/BikeForEggsMobile.lua langsung ke LocalScript.
]]
local USER = "danu-dev"
local REPO = "roblox"
local BRANCH = "main"
local URL = "https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/dist/BikeForEggsMobile.lua"

local src
local ok = pcall(function()
    if game.HttpGet then
        src = game:HttpGet(URL, true)
    else
        src = game:GetService("HttpService"):GetAsync(URL, true)
    end
end)

if not ok or type(src) ~= "string" or src == "" then
    warn("[BikeForEggs] Gagal memuat dari GitHub. Paste isi dist/BikeForEggsMobile.lua ke LocalScript instead.")
    return
end

if src:find("404: Not Found", 1, true) or src:find("<title>404", 1, true) then
    warn("[BikeForEggs] Raw URL 404. Kemungkinan repo masih PRIVATE / salah branch. Buka repo > Settings > General > Change visibility > Public. Atau paste dist/BikeForEggsMobile.lua langsung.")
    return
end

if type(loadstring) ~= "function" then
    warn("[BikeForEggs] loadstring tidak tersedia di environment ini. Paste isi dist/BikeForEggsMobile.lua langsung ke LocalScript.")
    return
end

local fn, err = loadstring(src)
if not fn then
    warn("[BikeForEggs] loadstring error: " .. tostring(err))
    return
end

fn()
