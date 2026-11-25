-- [LocalScript] | Lokasi: StarterPlayer > StarterPlayerScripts (paste sebagai LocalScript)
--[[
    ClipperHub Loader - Universal

    Loader serbaguna: ganti daftar SOURCES untuk script apa pun.
    Tamp biru + hitam, ikon digambar pakai Frame (tanpa emoji).

    Kalau logo ClipperHub sudah di-upload ke Roblox, isi LOGO_ID dengan Asset ID-nya.
    Kalau dikosongkan, loader menggambar ikon telur biru sendiri.
]]
local APP_TITLE = "CLIPPERHUB"
local APP_SUBTITLE = "UNIVERSAL LOADER"
local CREDIT = "By ClipperHub"
local LOGO_ID = "" -- contoh: "123456789"

-- Sumber dicoba berurutan. Tambah/hapus baris sesuai script yang dimuat.
local SOURCES = {
    { label = "netlify.app", url = "https://bikeforeggs-loader.netlify.app/BikeForEggsMobile_v5_2.lua" },
    -- { label = "raw.githubusercontent.com", url = "https://raw.githubusercontent.com/USER/REPO/main/dist/script.lua" },
    -- { label = "gist.githubusercontent.com", url = "https://gist.githubusercontent.com/USER/ID/raw/script.lua" },
}

local sources = {}
for _, s in ipairs(SOURCES) do
    if type(s.url) == "string" and s.url ~= "" then
        sources[#sources + 1] = s
    end
end

local function scriptName(url)
    local name = tostring(url):match("([^/]+)$") or "script.lua"
    return (name:gsub("%?.*$", ""))
end

local DISPLAY_NAME = sources[1] and scriptName(sources[1].url) or "script.lua"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local BLUE = Color3.fromRGB(48, 145, 255)
local BLUE_DARK = Color3.fromRGB(18, 72, 150)
local BLACK = Color3.fromRGB(7, 9, 14)
local CARD = Color3.fromRGB(14, 18, 28)
local LINE = Color3.fromRGB(33, 52, 82)
local TEXT = Color3.fromRGB(232, 240, 255)
local MUTED = Color3.fromRGB(140, 160, 192)
local OK = Color3.fromRGB(72, 220, 152)
local ERR = Color3.fromRGB(255, 96, 112)

local lp = Players.LocalPlayer
local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(360, 640)
local cardW = math.min(340, viewport.X - 28)

local gui = Instance.new("ScreenGui")
gui.Name = "BFE_Loader_v6"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
pcall(function()
    local g = (type(getgenv) == "function" and getgenv()) or _G
    local s = g.syn
    if s and type(s.protect_gui) == "function" then s.protect_gui(gui) end
end)
gui.Parent = lp:WaitForChild("PlayerGui")

local function inst(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 10)
    c.Parent = o
    return c
end

local function stroke(o, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = o
    return s
end

-- Latar hitam dengan cahaya biru di bagian atas.
inst("Frame", {
    Name = "Backdrop",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = BLACK,
    BorderSizePixel = 0,
}, gui)

local glow = inst("Frame", {
    Name = "Glow",
    Size = UDim2.new(1, 0, 0.42, 0),
    BackgroundColor3 = BLUE_DARK,
    BackgroundTransparency = 0.72,
    BorderSizePixel = 0,
}, gui)
local glowGrad = Instance.new("UIGradient")
glowGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, BLUE_DARK),
    ColorSequenceKeypoint.new(1, BLACK),
})
glowGrad.Parent = glow

-- Kartu utama.
local card = inst("Frame", {
    Name = "Card",
    Size = UDim2.fromOffset(cardW, 424),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = CARD,
    BorderSizePixel = 0,
}, gui)
corner(card, UDim.new(0, 18))
stroke(card, BLUE, 1.5, 0.55)

inst("Frame", {
    Name = "TopAccent",
    Size = UDim2.new(1, 0, 0, 4),
    BackgroundColor3 = BLUE,
    BorderSizePixel = 0,
}, card).Position = UDim2.fromOffset(0, 0)

-- Logo: pakai gambar kalau LOGO_ID diisi, kalau tidak gambar ikon telur.
local logoBox = inst("Frame", {
    Name = "Logo",
    Size = UDim2.new(1, 0, 0, 118),
    Position = UDim2.fromOffset(0, 22),
    BackgroundTransparency = 1,
}, card)

if LOGO_ID ~= "" then
    inst("ImageLabel", {
        Name = "LogoImage",
        Size = UDim2.fromOffset(110, 100),
        Position = UDim2.fromScale(0.5, 0.42),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://" .. LOGO_ID,
        ScaleType = Enum.ScaleType.Fit,
        BackgroundTransparency = 1,
    }, logoBox)
else
    local egg = inst("Frame", {
        Name = "EggIcon",
        Size = UDim2.fromOffset(86, 104),
        Position = UDim2.fromScale(0.5, 0.42),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = BLUE,
        BorderSizePixel = 0,
        Rotation = 0,
    }, logoBox)
    corner(egg, UDim.new(0.5, 0))
    inst("Frame", {
        Name = "EggInner",
        Size = UDim2.new(0.86, 0, 0.86, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CARD,
        BorderSizePixel = 0,
    }, egg)
    corner(egg.EggInner, UDim.new(0.5, 0))
    local shine = inst("Frame", {
        Name = "Shine",
        Size = UDim2.fromOffset(16, 34),
        Position = UDim2.fromOffset(24, 22),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        Rotation = -24,
    }, egg)
    corner(shine, UDim.new(0.5, 0))
end

inst("TextLabel", {
    Name = "Brand",
    Size = UDim2.new(1, -24, 0, 26),
    Position = UDim2.fromOffset(12, 116),
    BackgroundTransparency = 1,
    Text = APP_TITLE,
    TextColor3 = TEXT,
    Font = Enum.Font.GothamBold,
    TextSize = 19,
}, logoBox)

inst("TextLabel", {
    Name = "SubBrand",
    Size = UDim2.new(1, -24, 0, 16),
    Position = UDim2.fromOffset(12, 142),
    BackgroundTransparency = 1,
    Text = APP_SUBTITLE,
    TextColor3 = BLUE,
    Font = Enum.Font.GothamSemibold,
    TextSize = 10,
}, logoBox).TextTransparency = 0.1

-- Status: titik berwarna dipakai sebagai ikon, bukan emoji.
local statusDot = inst("Frame", {
    Name = "StatusIcon",
    Size = UDim2.fromOffset(10, 10),
    Position = UDim2.fromOffset(24, 166),
    BackgroundColor3 = BLUE,
    BorderSizePixel = 0,
}, card)
corner(statusDot, UDim.new(0.5, 0))

local statusLabel = inst("TextLabel", {
    Name = "Status",
    Size = UDim2.new(1, -72, 0, 24),
    Position = UDim2.fromOffset(44, 160),
    BackgroundTransparency = 1,
    Text = "Menyiapkan loader",
    TextColor3 = TEXT,
    Font = Enum.Font.GothamSemibold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, card)

local detailLabel = inst("TextLabel", {
    Name = "Detail",
    Size = UDim2.new(1, -48, 0, 32),
    Position = UDim2.fromOffset(24, 184),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = MUTED,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
}, card)

-- Bar progres.
local barW = cardW - 48
local bar = inst("Frame", {
    Name = "ProgressBar",
    Size = UDim2.fromOffset(barW, 6),
    Position = UDim2.fromOffset(24, 232),
    BackgroundColor3 = LINE,
    BorderSizePixel = 0,
}, card)
corner(bar, UDim.new(0, 3))
local fill = inst("Frame", {
    Name = "Fill",
    Size = UDim2.fromOffset(0, 6),
    BackgroundColor3 = BLUE,
    BorderSizePixel = 0,
}, bar)
corner(fill, UDim.new(0, 3))

inst("TextLabel", {
    Name = "Version",
    Size = UDim2.new(1, -48, 0, 18),
    Position = UDim2.fromOffset(24, 250),
    BackgroundTransparency = 1,
    Text = "Muat: " .. DISPLAY_NAME,
    TextColor3 = MUTED,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, card)

inst("TextLabel", {
    Name = "Credit",
    Size = UDim2.new(1, -48, 0, 18),
    Position = UDim2.fromOffset(24, 282),
    BackgroundTransparency = 1,
    Text = CREDIT,
    TextColor3 = BLUE,
    Font = Enum.Font.GothamSemibold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, card)

-- Tombol.
local function makeButton(text, x, w, cb)
    local b = inst("TextButton", {
        Name = text,
        Size = UDim2.fromOffset(w, 34),
        Position = UDim2.fromOffset(x, 360),
        BackgroundColor3 = BLUE_DARK,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = TEXT,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        AutoButtonColor = false,
    }, card)
    corner(b, UDim.new(0, 8))
    stroke(b, BLUE, 1, 0.45)
    b.MouseButton1Click:Connect(cb)
    return b
end

local lastError = ""
local busy = false
local start

local function setStatus(text, color, detail)
    statusLabel.Text = text
    statusDot.BackgroundColor3 = color or BLUE
    detailLabel.Text = detail or ""
end

local function setProgress(frac)
    local target = UDim2.fromOffset(math.floor(barW * math.clamp(frac, 0, 1)), 6)
    local tween = TweenService:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = target,
    })
    tween:Play()
end

local function fail(message, detail)
    busy = false
    lastError = message .. (detail and ("\n" .. detail) or "")
    setStatus(message, ERR, detail)
end

local function fetch(url)
    local body
    local ok = pcall(function()
        if type(game.HttpGet) == "function" then
            body = game:HttpGet(url, true)
        else
            body = HttpService:GetAsync(url, true)
        end
    end)
    if not ok or type(body) ~= "string" or body == "" then return nil end
    if body:find("404: Not Found", 1, true) or body:find("<title>404", 1, true) then return nil end
    return body
end

local function copyInfo()
    local msg = "Loader Bike For Eggs"
    for _, s in ipairs(sources) do msg = msg .. "\n" .. s.label .. ": " .. s.url end
    if lastError ~= "" then msg = msg .. "\nError: " .. lastError end
    if type(setclipboard) == "function" then
        pcall(setclipboard, msg)
        statusLabel.Text = "Info disalin"
    else
        setStatus("setclipboard tidak tersedia", ERR, "Salin manual URL di atas atau paste script langsung.")
    end
end

makeButton("Coba Lagi", 24, math.floor(cardW / 2) - 30, function()
    if not busy then task.spawn(function() start() end) end
end)
makeButton("Salin Info", math.floor(cardW / 2) - 6, math.floor(cardW / 2) - 18, copyInfo)

start = function()
    if busy then return end
    busy = true
    lastError = ""

    setStatus("Menyiapkan loader", BLUE, "")
    setProgress(0.12)
    task.wait(0.25)

    local src
    for i, s in ipairs(sources) do
        setStatus(i == 1 and "Menghubungi penyimpanan" or "Mencoba sumber lain", BLUE, s.label)
        setProgress(0.2 + ((i - 1) * 0.22))
        src = fetch(s.url)
        if src then break end
    end

    if not src then
        fail("Gagal memuat script", "Semua sumber tidak bisa diambil. Coba lagi, atau paste isi script langsung ke LocalScript.")
        return
    end

    setStatus("Script diterima", OK, #src .. " karakter")
    setProgress(0.9)
    task.wait(0.15)

    if type(loadstring) ~= "function" then
        fail("loadstring tidak tersedia", "Environment ini tidak mengizinkan loadstring. Paste isi script langsung ke LocalScript.")
        return
    end

    local fn, err = loadstring(src)
    if not fn then
        fail("Script rusak", tostring(err))
        return
    end

    setStatus("Menjalankan script", OK, "")
    setProgress(1)
    task.wait(0.2)

    local okRun, errRun = pcall(fn)
    if not okRun then
        fail("Script berhenti dengan error", tostring(errRun))
        return
    end

    task.wait(0.45)
    gui:Destroy()
end

task.spawn(function()
    task.wait(0.35)
    start()
end)
