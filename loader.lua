--[[
    Optional loader untuk GitHub raw.
    Ganti USER/REPO/BRANCH sebelum dipakai.
    Kalau loader gagal, copy isi dist/BikeForEggsMobile_v5_2.lua langsung ke LocalScript.
]]
local USER = "danu-dev"
local REPO = "roblox"
local BRANCH = "main"
local URL = "https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/dist/BikeForEggsMobile_v5_2.lua"

-- Backup: gist publik dengan isi yang sama (dipakai kalau raw repo belum terpropagasi).
local FALLBACK = "https://gist.githubusercontent.com/danu-dev/5919ac4fe9d4291c2aee8bfdfe0b06a1/raw/7e9c83746ebb8f2bcada1fa78817dd7e769bc23f/BikeForEggsMobile_v5_2.lua"

local function fetch(url)
    local body
    local ok = pcall(function()
        if game.HttpGet then
            body = game:HttpGet(url, true)
        else
            body = game:GetService("HttpService"):GetAsync(url, true)
        end
    end)
    if not ok or type(body) ~= "string" or body == "" then return nil end
    if body:find("404: Not Found", 1, true) or body:find("<title>404", 1, true) then return nil end
    return body
end

local src = fetch(URL) or fetch(FALLBACK)
if not src then
    warn("[BikeForEggs] Raw repo DAN gist keduanya 404 / gagal. Cek verifikasi email GitHub akun danu-dev, atau paste isi dist/BikeForEggsMobile_v5_2.lua langsung ke LocalScript.")
    return
end

if type(loadstring) ~= "function" then
    warn("[BikeForEggs] loadstring tidak tersedia di environment ini. Paste isi dist/BikeForEggsMobile_v5_2.lua langsung ke LocalScript.")
    return
end

local fn, err = loadstring(src)
if not fn then
    warn("[BikeForEggs] loadstring error: " .. tostring(err))
    return
end

fn()
