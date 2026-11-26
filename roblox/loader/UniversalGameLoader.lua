-- [LocalScript] | Lokasi: StarterPlayer > StarterPlayerScripts
-- Universal Game Loader: layar loading + hub teleport. Copy ke game mana pun, lalu edit CONFIG.Games.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local CONFIG = {
	Title = "UNIVERSAL LOADER",
	Subtitle = "Pilih game untuk masuk",
	LoadingTime = 1.6,    -- durasi loading (detik)
	TeleportCooldown = 3, -- jeda antar teleport (detik)
	ToggleKey = Enum.KeyCode.M,

	-- Daftar game. Ganti PlaceId dengan placeId game kamu.
	Games = {
		{ Name = "Hub Utama", PlaceId = game.PlaceId, Desc = "Kembali ke tempat ini" },
		{ Name = "Contoh Game", PlaceId = 1234567890, Desc = "Ganti PlaceId ini dengan game kamu" },
	},
}

local player = Players.LocalPlayer
if not player then return end

local playerGui = player:WaitForChild("PlayerGui")
local ready = false

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

-- ============================================================
-- GUI UTAMA
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalGameLoader"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- ---------- Loading screen ----------
local loading = Instance.new("Frame")
loading.Name = "LoadingScreen"
loading.Size = UDim2.fromScale(1, 1)
loading.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
loading.Parent = screenGui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.fromScale(0.86, 0.10)
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.40)
title.BackgroundTransparency = 1
title.Text = CONFIG.Title
title.Font = Enum.Font.GothamBold
title.TextSize = 38
title.TextColor3 = Color3.fromRGB(235, 235, 255)
title.Parent = loading

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.fromScale(0.86, 0.06)
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.48)
subtitle.BackgroundTransparency = 1
subtitle.Text = CONFIG.Subtitle
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 16
subtitle.TextColor3 = Color3.fromRGB(160, 170, 200)
subtitle.Parent = loading

local barBg = Instance.new("Frame")
barBg.Name = "ProgressBar"
barBg.Size = UDim2.fromScale(0.5, 0.022)
barBg.AnchorPoint = Vector2.new(0.5, 0.5)
barBg.Position = UDim2.fromScale(0.5, 0.56)
barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
barBg.BorderSizePixel = 0
barBg.Parent = loading
corner(barBg, 6)

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBg
corner(barFill, 6)

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.fromScale(0.86, 0.05)
status.AnchorPoint = Vector2.new(0.5, 0.5)
status.Position = UDim2.fromScale(0.5, 0.62)
status.BackgroundTransparency = 1
status.Text = "Memuat... 0%"
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(140, 150, 180)
status.Parent = loading

-- ---------- Hub ----------
local hub = Instance.new("Frame")
hub.Name = "Hub"
hub.Size = UDim2.fromScale(0.74, 0.70)
hub.AnchorPoint = Vector2.new(0.5, 0.5)
hub.Position = UDim2.fromScale(0.5, 0.5)
hub.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
hub.BackgroundTransparency = 0.05
hub.Visible = false
hub.Parent = screenGui
corner(hub, 16)
stroke(hub, Color3.fromRGB(55, 55, 78), 1)

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.fromScale(1, 0.12)
topBar.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
topBar.BackgroundTransparency = 0.15
topBar.BorderSizePixel = 0
topBar.Parent = hub
corner(topBar, 16)

local hubTitle = Instance.new("TextLabel")
hubTitle.Size = UDim2.fromScale(0.85, 1)
hubTitle.Position = UDim2.fromScale(0.03, 0)
hubTitle.BackgroundTransparency = 1
hubTitle.Text = CONFIG.Title
hubTitle.Font = Enum.Font.GothamBold
hubTitle.TextSize = 22
hubTitle.TextColor3 = Color3.fromRGB(240, 240, 255)
hubTitle.TextXAlignment = Enum.TextXAlignment.Left
hubTitle.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromScale(0.055, 0.62)
closeButton.Position = UDim2.fromScale(0.915, 0.19)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 65, 75)
closeButton.Text = "×"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 24
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Parent = topBar
corner(closeButton, 8)

local search = Instance.new("TextBox")
search.Name = "Search"
search.Size = UDim2.fromScale(0.94, 0.09)
search.Position = UDim2.fromScale(0.03, 0.14)
search.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
search.BorderSizePixel = 0
search.PlaceholderText = "Cari game..."
search.Text = ""
search.Font = Enum.Font.Gotham
search.TextSize = 16
search.TextColor3 = Color3.new(1, 1, 1)
search.PlaceholderColor3 = Color3.fromRGB(120, 120, 145)
search.TextXAlignment = Enum.TextXAlignment.Left
search.ClearTextOnFocus = false
search.Parent = hub
corner(search, 8)
local searchPad = Instance.new("UIPadding")
searchPad.PaddingLeft = UDim.new(0, 12)
searchPad.Parent = search

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "GameList"
scroll.Size = UDim2.fromScale(0.94, 0.63)
scroll.Position = UDim2.fromScale(0.03, 0.25)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = hub

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scroll

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.Size = UDim2.fromScale(0.94, 0.06)
toast.Position = UDim2.fromScale(0.03, 0.91)
toast.BackgroundTransparency = 1
toast.Text = ""
toast.Font = Enum.Font.Gotham
toast.TextSize = 14
toast.TextColor3 = Color3.fromRGB(255, 210, 120)
toast.TextXAlignment = Enum.TextXAlignment.Left
toast.Visible = false
toast.Parent = hub

local toggle = Instance.new("TextButton")
toggle.Name = "OpenLoader"
toggle.Size = UDim2.fromOffset(48, 48)
toggle.Position = UDim2.new(0, 12, 0, 12)
toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
toggle.Text = "☰"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 22
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Visible = false
toggle.Parent = screenGui
corner(toggle, 24)
stroke(toggle, Color3.fromRGB(70, 70, 95), 1)

-- ============================================================
-- LOGIKA
-- ============================================================
local toastToken = 0
local function showToast(message)
	toastToken += 1
	local token = toastToken
	toast.Text = message
	toast.TextTransparency = 0
	toast.Visible = true

	task.delay(2.5, function()
		if toastToken ~= token then return end
		local fade = TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		toast.Visible = false
	end)
end

local teleportBusy = false
local function teleportTo(entry)
	if teleportBusy then
		showToast("Tunggu sebentar...")
		return
	end

	local placeId = entry and entry.PlaceId
	if typeof(placeId) ~= "number" or placeId <= 0 then
		showToast("PlaceId tidak valid")
		return
	end

	teleportBusy = true
	showToast("Memindahkan ke " .. tostring(entry.Name) .. "...")

	local ok, err = pcall(function()
		TeleportService:Teleport(placeId, player)
	end)

	if not ok then
		teleportBusy = false
		showToast("Gagal teleport: " .. tostring(err))
		return
	end

	task.delay(CONFIG.TeleportCooldown, function()
		teleportBusy = false
	end)
end

local cards = {}

local function clearCards()
	for _, card in ipairs(cards) do
		card:Destroy()
	end
	table.clear(cards)
end

local function createCard(entry)
	local card = Instance.new("TextButton")
	card.Size = UDim2.new(1, -10, 0, 66)
	card.BackgroundColor3 = Color3.fromRGB(32, 32, 46)
	card.BorderSizePixel = 0
	card.AutoButtonColor = true
	card.Text = ""
	corner(card, 10)
	stroke(card, Color3.fromRGB(60, 60, 84), 1)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -24, 0, 26)
	nameLabel.Position = UDim2.new(0, 12, 0, 7)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = tostring(entry.Name or "Tanpa nama")
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 17
	nameLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -24, 0, 18)
	descLabel.Position = UDim2.new(0, 12, 0, 33)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = tostring(entry.Desc or "")
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 13
	descLabel.TextColor3 = Color3.fromRGB(170, 170, 195)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = card

	local idLabel = Instance.new("TextLabel")
	idLabel.Size = UDim2.new(1, -24, 0, 14)
	idLabel.Position = UDim2.new(0, 12, 0, 50)
	idLabel.BackgroundTransparency = 1
	idLabel.Text = "PlaceId: " .. tostring(entry.PlaceId)
	idLabel.Font = Enum.Font.Gotham
	idLabel.TextSize = 11
	idLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
	idLabel.TextXAlignment = Enum.TextXAlignment.Left
	idLabel.Parent = card

	card.MouseButton1Click:Connect(function()
		teleportTo(entry)
	end)

	return card
end

local function refresh(query)
	clearCards()
	query = string.lower(query or "")

	local count = 0
	for _, entry in ipairs(CONFIG.Games) do
		local name = string.lower(tostring(entry.Name or ""))
		local desc = string.lower(tostring(entry.Desc or ""))
		local cocok = query == ""
			or string.find(name, query, 1, true) ~= nil
			or string.find(desc, query, 1, true) ~= nil

		if cocok then
			count += 1
			local card = createCard(entry)
			card.Parent = scroll
			table.insert(cards, card)
		end
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, count * 74 + 8)
	if count == 0 then
		showToast("Tidak ada game yang cocok")
	end
end

search:GetPropertyChangedSignal("Text"):Connect(function()
	refresh(search.Text)
end)

closeButton.MouseButton1Click:Connect(function()
	hub.Visible = false
	toggle.Visible = true
end)

toggle.MouseButton1Click:Connect(function()
	hub.Visible = true
	toggle.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not ready then return end
	if input.KeyCode == CONFIG.ToggleKey then
		hub.Visible = not hub.Visible
		toggle.Visible = not hub.Visible
	end
end)

refresh("")

-- ============================================================
-- URUTAN LOADING
-- ============================================================
task.spawn(function()
	local barInfo = TweenInfo.new(CONFIG.LoadingTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local barTween = TweenService:Create(barFill, barInfo, { Size = UDim2.fromScale(1, 1) })
	barTween:Play()

	local steps = 10
	for i = 1, steps do
		status.Text = "Memuat... " .. tostring(i * 10) .. "%"
		task.wait(CONFIG.LoadingTime / steps)
	end
	barTween.Completed:Wait()
	status.Text = "Siap!"

	task.wait(0.2)

	local fadeInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(loading, fadeInfo, { BackgroundTransparency = 1 }):Play()
	for _, obj in ipairs(loading:GetDescendants()) do
		if obj:IsA("TextLabel") then
			TweenService:Create(obj, fadeInfo, { TextTransparency = 1 }):Play()
		elseif obj:IsA("Frame") then
			TweenService:Create(obj, fadeInfo, { BackgroundTransparency = 1 }):Play()
		end
	end

	task.wait(0.35)
	loading:Destroy()
	ready = true
	hub.Visible = true
end)
