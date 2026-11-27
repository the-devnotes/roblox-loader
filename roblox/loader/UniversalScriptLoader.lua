-- [Script] | Lokasi: ServerScriptService
-- Loader script universal: satu file, banyak script, deteksi game otomatis.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Loader = {}

local REGISTRY = {} -- nama -> sumber (URL / "local:Nama" / Instance)
local CACHE = {}    -- nama -> kode string (fetch hanya sekali)

local UNIVERSAL_DEFAULT = "Universal"

-- Cek sekali di awal biar pesannya jelas kalau setting belum aktif.
if not ServerScriptService.LoadStringEnabled then
	warn("[Loader] LoadStringEnabled masih false - aktifkan di Properties > ServerScriptService.")
end

local function gagal(nama, pesan)
	warn(("[Loader] %s: %s"):format(tostring(nama), tostring(pesan)))
end

-- ============================================================
-- PEMETAAN GAME
-- GameId = utama, PlaceId = cadangan
-- ============================================================
local REPO = "https://raw.githubusercontent.com/the-devnotes/BikeForEggs/main"
local SCRIPT_BFE = REPO .. "/dist/BikeForEggs_AllInOne.lua"

-- Bike For Egg! -> https://www.roblox.com/games/74023858073178/Bike-For-Egg
local BY_GAME_ID = {
	[10766620257] = "BikeForEgg", -- UniverseId
}

local BY_PLACE_ID = {
	[74023858073178] = "BikeForEgg", -- PlaceId
}

-- ============================================================
-- REGISTER
-- ============================================================
function Loader.register(nama, sumber)
	if type(nama) ~= "string" or nama == "" then
		gagal("register", "nama harus string tidak kosong")
		return false
	end
	if sumber == nil then
		gagal(nama, "sumber tidak boleh nil")
		return false
	end

	if REGISTRY[nama] then
		warn(("[Loader] %s: didaftarkan ulang, sumber ditimpa"):format(nama))
	end

	REGISTRY[nama] = sumber
	CACHE[nama] = nil -- buang cache lama kalau sumber diganti
	return true
end

-- ============================================================
-- AMBIL SUMBER LOKAL
-- ModuleScript -> return string / table.Source
-- StringValue  -> .Value
-- Script/LocalScript -> .Source
-- ============================================================
local function dariObjek(nama, obj)
	if not obj then
		return nil, "objek lokal tidak ditemukan"
	end

	if obj:IsA("ModuleScript") then
		local ok, modul = pcall(require, obj)
		if not ok then
			return nil, "gagal require ModuleScript: " .. tostring(modul)
		end
		if type(modul) == "string" then
			return modul
		end
		if type(modul) == "table" and type(modul.Source) == "string" then
			return modul.Source
		end
		return nil, "ModuleScript harus return string (atau table dengan field Source)"
	elseif obj:IsA("StringValue") then
		if obj.Value == "" then
			return nil, "StringValue kosong"
		end
		return obj.Value
	elseif obj:IsA("Script") or obj:IsA("LocalScript") then
		return obj.Source
	end

	return nil, "tipe lokal '" .. obj.ClassName .. "' tidak didukung"
end

local function fetch(nama, sumber)
	-- Instance langsung dipakai
	if typeof(sumber) == "Instance" then
		return dariObjek(nama, sumber)
	end

	if type(sumber) ~= "string" then
		return nil, "sumber harus string URL / 'local:Nama' / Instance"
	end

	-- Sumber dari URL
	if sumber:match("^https?://") then
		local ok, isi = pcall(function()
			return HttpService:GetAsync(sumber)
		end)
		if not ok then
			return nil, "gagal fetch HTTP: " .. tostring(isi)
		end
		if type(isi) ~= "string" then
			return nil, "hasil fetch bukan string"
		end
		if isi == "" then
			return nil, "hasil fetch kosong"
		end
		return isi
	end

	-- Sumber lokal dari script itu sendiri atau ReplicatedStorage
	local kunci = sumber:match("^local:(.+)$") or sumber
	local obj = script:FindFirstChild(kunci) or ReplicatedStorage:FindFirstChild(kunci)
	if not obj then
		return nil, ("objek lokal '%s' tidak ditemukan"):format(kunci)
	end
	return dariObjek(nama, obj)
end

-- ============================================================
-- RUN
-- ============================================================
function Loader.run(nama, ...)
	local sumber = REGISTRY[nama]
	if sumber == nil then
		gagal(nama, "belum didaftarkan lewat register()")
		return false
	end

	-- CACHE: kalau sudah pernah di-fetch, pakai lagi yang lama.
	local kode = CACHE[nama]
	if kode == nil then
		local pesan
		kode, pesan = fetch(nama, sumber)
		if kode == nil then
			gagal(nama, pesan)
			return false
		end
		CACHE[nama] = kode
	end

	-- loadstring bisa error kalau LoadStringEnabled false, jadi tetap di-pcall.
	local okLoad, chunk, loadErr = pcall(loadstring, kode, "=Loader:" .. tostring(nama))
	if not okLoad then
		gagal(nama, "loadstring tidak tersedia: " .. tostring(chunk))
		return false
	end
	if not chunk then
		gagal(nama, "gagal loadstring: " .. tostring(loadErr))
		return false
	end

	local ok, err = pcall(chunk, ...)
	if not ok then
		gagal(nama, "error saat dijalankan: " .. tostring(err))
		return false
	end

	return true
end

-- ============================================================
-- DETEKSI GAME
-- ============================================================
function Loader.detect()
	local gameId = game.GameId
	local placeId = game.PlaceId
	local nama = BY_GAME_ID[gameId] or BY_PLACE_ID[placeId]
	return nama, gameId, placeId
end

-- ============================================================
-- AUTO
-- options.includeUniversal : bool, jalankan universal juga saat game dikenal
-- options.universalName    : ganti nama script universal
-- options.args             : tabel argumen yang dilempar ke script
-- ============================================================
function Loader.auto(options)
	options = options or {}
	if type(options) == "boolean" then
		options = { includeUniversal = options }
	end

	local args = type(options.args) == "table" and options.args or {}
	local universalName = options.universalName or UNIVERSAL_DEFAULT
	local includeUniversal = options.includeUniversal == true

	local nama, gameId, placeId = Loader.detect()
	local sukses = true
	local hasil = {}

	if nama then
		print(("[Loader] Game dikenal: GameId=%d PlaceId=%d -> %s"):format(gameId, placeId, nama))
		local ok = Loader.run(nama, table.unpack(args))
		sukses = sukses and ok
		hasil[nama] = ok
	else
		-- Game tidak dikenal: script universal WAJIB jalan sebagai cadangan.
		print(("[Loader] Game belum dikenal: GameId=%d PlaceId=%d -> pakai '%s'"):format(gameId, placeId, universalName))
		includeUniversal = true
	end

	if includeUniversal then
		local ok = Loader.run(universalName, table.unpack(args))
		sukses = sukses and ok
		hasil[universalName] = ok
	end

	return sukses, hasil
end

-- ============================================================
-- UTIL
-- ============================================================
function Loader.clearCache(nama)
	if nama then
		CACHE[nama] = nil
	else
		table.clear(CACHE)
	end
end

-- ============================================================
-- DAFTAR SUMBER
-- ============================================================
-- "local:Nama" = ModuleScript di ReplicatedStorage.
-- URL https://... diambil lewat HttpService:GetAsync.
Loader.register("BikeForEgg", SCRIPT_BFE)             -- URL repo BikeForEggs
Loader.register("Universal", "local:Universal_Source") -- cadangan

-- Jalankan otomatis. Game dikenal -> script itu saja.
-- Game tidak dikenal -> Universal dipakai.
-- Pakai includeUniversal = true kalau mau keduanya jalan.
local sukses, hasil = Loader.auto({ includeUniversal = false })
print("[Loader] Selesai. Sukses:", sukses, "Detail:", hasil)

return Loader
