-- [Script] | Lokasi: ServerScriptService
-- Loader simpel: daftar script -> deteksi game -> jalankan yang cocok.

local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")

-- Identitas hub / game
local LOGO_ASSET_ID = 128239981655294 -- AssetId gambar logo
local HUB_NAME = "Clipper Hub"        -- nama hub
local NAME_GAME = "Mendeteksi..."     -- diisi otomatis oleh auto()

-- Nama tampilan per game (opsional). Kalau tidak ada, pakai nama script-nya.
local DAFTAR_NAMA = {
	GameA = "Obby Legend",
	GameB = "Tycoon Sim",
	Universal = "Game Lain",
}

local sources = {} -- nama -> sumber
local cache = {}   -- nama -> kode (biar tidak fetch dua kali)

-- Pemetaan: GameId utama, PlaceId cadangan
local byGame = {
	[1234567890] = "GameA",
	[9876543210] = "GameB",
}

local byPlace = {
	[1111111111] = "GameA",
	[2222222222] = "GameB",
}

local function register(nama, sumber)
	sources[nama] = sumber
	cache[nama] = nil
end

local function run(nama, ...)
	local sumber = sources[nama]
	if not sumber then
		warn(("[%s] %s: belum didaftarkan"):format(HUB_NAME, nama))
		return false
	end

	-- Ambil kode. URL -> HTTP, selain itu -> ModuleScript di ReplicatedStorage.
	local kode = cache[nama]
	if not kode then
		local ok, hasil = pcall(function()
			if sumber:match("^https?://") then
				return HttpService:GetAsync(sumber)
			end
			return require(RS:WaitForChild(sumber, 5))
		end)

		if not ok or type(hasil) ~= "string" or hasil == "" then
			warn(("[%s] %s: gagal ambil script - %s"):format(HUB_NAME, nama, tostring(hasil)))
			return false
		end

		kode = hasil
		cache[nama] = kode
	end

	-- Compile + jalankan. Error satu script tidak menghentikan yang lain.
	local okLoad, chunk = pcall(loadstring, kode, nama)
	if not okLoad or not chunk then
		warn(("[%s] %s: gagal loadstring - %s"):format(HUB_NAME, nama, tostring(chunk)))
		return false
	end

	local okRun, err = pcall(chunk, ...)
	if not okRun then
		warn(("[%s] %s: error saat jalan - %s"):format(HUB_NAME, nama, tostring(err)))
		return false
	end

	return true
end

local function auto(ikutUniversal)
	local nama = byGame[game.GameId] or byPlace[game.PlaceId]

	-- NAME_GAME menyesuaikan game yang cocok di daftar (atau Universal).
	NAME_GAME = DAFTAR_NAMA[nama] or nama or DAFTAR_NAMA.Universal
	print(("[%s] %s | Logo AssetId: %d"):format(HUB_NAME, NAME_GAME, LOGO_ASSET_ID))

	if nama then
		print(("[%s] Game dikenal -> %s"):format(HUB_NAME, NAME_GAME))
		run(nama)
	else
		-- Game tidak dikenal: universal dipakai sebagai cadangan.
		print(("[%s] Game tidak dikenal -> %s"):format(HUB_NAME, NAME_GAME))
		ikutUniversal = true
	end

	if ikutUniversal then
		run("Universal")
	end
end

-- ============================================================
-- UI BAWAAN (biar tampilan semua script yang di-load konsisten)
-- ============================================================
local function ui(player, judul, tombol)
	if not player then return nil end

	local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	gui.Name = HUB_NAME .. "UI"
	gui.ResetOnSpawn = false

	local frame = Instance.new("Frame", gui)
	frame.Size = UDim2.fromScale(0.32, 0.34)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

	local logo = Instance.new("ImageLabel", frame)
	logo.Name = "Logo"
	logo.Size = UDim2.fromOffset(48, 48)
	logo.Position = UDim2.fromOffset(12, 12)
	logo.Image = "rbxassetid://" .. LOGO_ASSET_ID
	logo.BackgroundTransparency = 1

	local header = Instance.new("TextLabel", frame)
	header.Name = "Header"
	header.Size = UDim2.new(1, -72, 0, 24)
	header.Position = UDim2.fromOffset(68, 12)
	header.BackgroundTransparency = 1
	header.Text = judul or HUB_NAME
	header.Font = Enum.Font.GothamBold
	header.TextSize = 18
	header.TextColor3 = Color3.new(1, 1, 1)
	header.TextXAlignment = Enum.TextXAlignment.Left

	local sub = Instance.new("TextLabel", frame)
	sub.Name = "Subtitle"
	sub.Size = UDim2.new(1, -72, 0, 18)
	sub.Position = UDim2.fromOffset(68, 36)
	sub.BackgroundTransparency = 1
	sub.Text = NAME_GAME .. " | " .. HUB_NAME
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 12
	sub.TextColor3 = Color3.fromRGB(150, 150, 175)
	sub.TextXAlignment = Enum.TextXAlignment.Left

	local isi = Instance.new("Frame", frame)
	isi.Name = "Content"
	isi.Size = UDim2.new(1, -24, 1, -80)
	isi.Position = UDim2.fromOffset(12, 68)
	isi.BackgroundTransparency = 1
	Instance.new("UIListLayout", isi).Padding = UDim.new(0, 8)

	for _, item in ipairs(tombol or {}) do
		local b = Instance.new("TextButton", isi)
		b.Size = UDim2.new(1, 0, 0, 36)
		b.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
		b.Text = item[1]
		b.Font = Enum.Font.Gotham
		b.TextSize = 14
		b.TextColor3 = Color3.new(1, 1, 1)
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		if item[2] then
			b.MouseButton1Click:Connect(item[2])
		end
	end

	return gui, frame
end

-- Script yang di-load tinggal manggil shared.ClipperHub.ui(...)
shared.ClipperHub = {
	ui = ui,
	run = run,
	register = register,
	auto = auto,
}

-- ================= CONTOH =================
-- ModuleScript "GameA_Source" di ReplicatedStorage isinya:
-- return [[
--     local gui = shared.ClipperHub.ui(player, "Menu GameA", {
--         { "TOMBOL 1", function() print("klik") end },
--         { "TOMBOL 2", function() print("klik juga") end },
--     })
-- ]]
-- ModuleScript "Universal_Source" isinya:
-- return [[ print("Universal jalan") ]]

register("GameA", "GameA_Source")
register("GameB", "https://example.com/gameb.lua")
register("Universal", "Universal_Source")

auto(true) -- true = universal ikut jalan walaupun game dikenal
