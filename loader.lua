-- [LocalScript] | Lokasi: StarterPlayer > StarterPlayerScripts (paste sebagai LocalScript)
--[[
    ClipperHub Loader - Universal

    loader serbaguna: satu file untuk semua script.
    - Edit CONFIG di bawah untuk mengganti judul, sumber, atau perilaku.
    - Tambah entri di CONFIG.sources kalau punya beberapa URL cadangan.
    - Ikon digambar dari Frame (tanpa emoji, tanpa Asset ID) dan memakai
      palet yang sama dengan ui_library.lua di dalam script utama.
    - Payload disimpan ber-encode hex di balik gate redirect Netlify.
      Browser biasa di-redirect; Roblox dengan token mendapat hex, lalu
      loader mendekode dan menjalankannya lewat loadstring.
]]

local CONFIG = {
    title = "CLIPPERHUB",
    credit = "By ClipperHub",
    iconStyle = "clipperhub", -- dipakai kalau logoAssetId kosong
    logoAssetId = "102269948329032", -- Image ID logo.jpg; kosongkan untuk ikon digambar
    encoded = true,           -- true = isi sumber berupa hex, false = Lua polos
    autoStart = true,         -- false = panggil run(config) sendiri dari script lain
    showInfoButtons = true,   -- tombol Coba Lagi / Salin Info
    sources = {
        { label = "clipperhub", url = "https://bikeforeggs-loader.netlify.app/clipperhub.lua?k=ClipperHub-2026" },
        { label = "debug", url = "https://bikeforeggs-loader.netlify.app/clipperhub.lua?k=ClipperHub-Debug-2026" },
    },
}

-- Sinkronkan dengan C di src/ui_library.lua.
local THEME = {
    black    = Color3.fromRGB(7, 9, 14),
    card     = Color3.fromRGB(14, 18, 28),
    panel    = Color3.fromRGB(24, 33, 52),
    line     = Color3.fromRGB(33, 52, 82),
    text     = Color3.fromRGB(232, 240, 255),
    muted    = Color3.fromRGB(140, 160, 192),
    blue     = Color3.fromRGB(48, 145, 255),
    blueDark = Color3.fromRGB(18, 72, 150),
    ok       = Color3.fromRGB(72, 220, 152),
    err      = Color3.fromRGB(255, 96, 112),
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

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

-- Ikon digambar dengan bentuk yang sama seperti di ui_library.lua.
local function drawIcon(parent, style, size, accent, cut)
    local s = size or 24
    local u = s / 24
    local holder = inst("Frame", {
        Name = "Icon_" .. tostring(style or "dot"),
        Size = UDim2.fromOffset(s, s),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, parent)
    local function part(x, y, w, h, col, radius, rotation)
        local f = inst("Frame", {
            Size = UDim2.fromOffset(w * u, h * u),
            Position = UDim2.fromOffset(x * u, y * u),
            BackgroundColor3 = col,
            BorderSizePixel = 0,
            Rotation = rotation or 0,
        }, holder)
        corner(f, UDim.new(0, (radius or 0) * u))
        return f
    end

    if style == "egg" then
        part(7, 3, 10, 18, accent, 5)
        part(9, 6, 2, 6, cut, 1, -20)
    else
        part(1, 1, 22, 22, accent, 6)
        part(17, 1, 3, 7, cut, 1.5, 38)
        inst("TextLabel", {
            Size = UDim2.fromOffset(s, s),
            BackgroundTransparency = 1,
            Text = "C",
            TextColor3 = cut,
            Font = Enum.Font.GothamBold,
            TextSize = 15 * u,
        }, holder)
    end
    return holder
end

local function run(cfg)
    cfg = cfg or {}
    local sources = {}
    for _, s in ipairs(cfg.sources or {}) do
        if type(s.url) == "string" and s.url ~= "" then
            sources[#sources + 1] = {
                label = s.label or tostring(s.url):match("([^/]+)$") or "script",
                url = s.url,
            }
        end
    end

    local function decode(body)
        if not cfg.encoded then return body end
        local clean = tostring(body):gsub("%s+", "")
        return clean:gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end)
    end

    local function scriptName(url)
        local name = tostring(url):match("([^/]+)$") or "script.lua"
        name = name:gsub("%?.*$", "")
        return name:gsub("%.hex$", ".lua")
    end

    local displayName = cfg.name or (sources[1] and scriptName(sources[1].url) or "script.lua")
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

    -- Latar hitam dengan cahaya biru di bagian atas.
    inst("Frame", {
        Name = "Backdrop",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = THEME.black,
        BorderSizePixel = 0,
    }, gui)
    local glow = inst("Frame", {
        Name = "Glow",
        Size = UDim2.new(1, 0, 0.42, 0),
        BackgroundColor3 = THEME.blueDark,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
    }, gui)
    local glowGrad = Instance.new("UIGradient")
    glowGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.blueDark),
        ColorSequenceKeypoint.new(1, THEME.black),
    })
    glowGrad.Parent = glow

    local card = inst("Frame", {
        Name = "Card",
        Size = UDim2.fromOffset(cardW, 424),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = THEME.card,
        BorderSizePixel = 0,
    }, gui)
    corner(card, UDim.new(0, 18))
    stroke(card, THEME.blue, 1.5, 0.5)

    inst("Frame", {
        Name = "TopAccent",
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = THEME.blue,
        BorderSizePixel = 0,
    }, card)

    local logoBox = inst("Frame", {
        Name = "Logo",
        Size = UDim2.new(1, 0, 0, 118),
        Position = UDim2.fromOffset(0, 22),
        BackgroundTransparency = 1,
    }, card)
    local logoGlow = inst("Frame", {
        Name = "LogoGlow",
        Size = UDim2.fromOffset(108, 108),
        Position = UDim2.fromScale(0.5, 0.42),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = THEME.blueDark,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
    }, logoBox)
    corner(logoGlow, UDim.new(0, 26))
    local logoIcon
    if tostring(cfg.logoAssetId or "") ~= "" then
        logoIcon = inst("ImageLabel", {
            Name = "LogoImage",
            Size = UDim2.fromOffset(110, 100),
            Position = UDim2.fromScale(0.5, 0.42),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = "rbxassetid://" .. tostring(cfg.logoAssetId),
            ScaleType = Enum.ScaleType.Fit,
            BackgroundTransparency = 1,
        }, logoBox)
    else
        logoIcon = drawIcon(logoBox, cfg.iconStyle or "clipperhub", 88, THEME.blue, THEME.card)
        logoIcon.Position = UDim2.fromScale(0.5, 0.42)
        logoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    inst("TextLabel", {
        Name = "Brand",
        Size = UDim2.new(1, -24, 0, 26),
        Position = UDim2.fromOffset(12, 116),
        BackgroundTransparency = 1,
        Text = tostring(cfg.title or "CLIPPERHUB"),
        TextColor3 = THEME.text,
        Font = Enum.Font.GothamBold,
        TextSize = 19,
    }, logoBox)

    -- Status: titik berwarna dipakai sebagai ikon, bukan emoji.
    local statusDot = inst("Frame", {
        Name = "StatusIcon",
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.fromOffset(24, 166),
        BackgroundColor3 = THEME.blue,
        BorderSizePixel = 0,
    }, card)
    corner(statusDot, UDim.new(0.5, 0))

    local statusLabel = inst("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, -72, 0, 24),
        Position = UDim2.fromOffset(44, 160),
        BackgroundTransparency = 1,
        Text = "Menyiapkan loader",
        TextColor3 = THEME.text,
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
        TextColor3 = THEME.muted,
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
        BackgroundColor3 = THEME.line,
        BorderSizePixel = 0,
    }, card)
    corner(bar, UDim.new(0, 3))
    local fill = inst("Frame", {
        Name = "Fill",
        Size = UDim2.fromOffset(0, 6),
        BackgroundColor3 = THEME.blue,
        BorderSizePixel = 0,
    }, bar)
    corner(fill, UDim.new(0, 3))

    inst("TextLabel", {
        Name = "Version",
        Size = UDim2.new(1, -48, 0, 18),
        Position = UDim2.fromOffset(24, 250),
        BackgroundTransparency = 1,
        Text = "Muat: " .. displayName,
        TextColor3 = THEME.muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    inst("TextLabel", {
        Name = "Credit",
        Size = UDim2.new(1, -48, 0, 18),
        Position = UDim2.fromOffset(24, 282),
        BackgroundTransparency = 1,
        Text = tostring(cfg.credit or "By ClipperHub"),
        TextColor3 = THEME.blue,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    local function makeButton(text, x, w, cb)
        local b = inst("TextButton", {
            Name = text,
            Size = UDim2.fromOffset(w, 34),
            Position = UDim2.fromOffset(x, 360),
            BackgroundColor3 = THEME.blueDark,
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = THEME.text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            AutoButtonColor = false,
        }, card)
        corner(b, UDim.new(0, 9))
        stroke(b, THEME.blue, 1, 0.45)
        b.MouseButton1Click:Connect(cb)
        return b
    end

    local lastError = ""
    local busy = false
    local start

    local function setStatus(text, color, detail)
        statusLabel.Text = text
        statusDot.BackgroundColor3 = color or THEME.blue
        detailLabel.Text = detail or ""
    end

    local function setProgress(frac)
        local target = UDim2.fromOffset(math.floor(barW * math.clamp(frac, 0, 1)), 6)
        TweenService:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = target,
        }):Play()
    end

    local function fail(message, detail)
        busy = false
        lastError = message .. (detail and ("\n" .. detail) or "")
        setStatus(message, THEME.err, detail)
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
        local msg = "Loader " .. tostring(cfg.title or "ClipperHub")
        for _, s in ipairs(sources) do msg = msg .. "\n" .. s.label .. ": " .. s.url end
        if lastError ~= "" then msg = msg .. "\nError: " .. lastError end
        if type(setclipboard) == "function" then
            pcall(setclipboard, msg)
            statusLabel.Text = "Info disalin"
        else
            setStatus("setclipboard tidak tersedia", THEME.err, "Salin manual URL di atas atau paste script langsung.")
        end
    end

    if cfg.showInfoButtons ~= false then
        makeButton("Coba Lagi", 24, math.floor(cardW / 2) - 30, function()
            if not busy then task.spawn(function() start() end) end
        end)
        makeButton("Salin Info", math.floor(cardW / 2) - 6, math.floor(cardW / 2) - 18, copyInfo)
    end

    start = function()
        if busy then return end
        busy = true
        lastError = ""

        setStatus("Menyiapkan loader", THEME.blue, "")
        setProgress(0.12)
        task.wait(0.25)

        local src
        if type(cfg.script) == "string" and cfg.script ~= "" then
            -- Sumber bawaan: tidak perlu HttpGet (dipakai build all-in-one).
            setStatus("Membaca script bawaan", THEME.blue, displayName)
            setProgress(0.45)
            src = cfg.script
        else
            if #sources == 0 then
                fail("Tidak ada sumber", "Isi CONFIG.sources dengan URL script yang valid.")
                return
            end
            for i, s in ipairs(sources) do
                setStatus(i == 1 and "Menghubungi penyimpanan" or "Mencoba sumber lain", THEME.blue, s.label)
                setProgress(0.2 + ((i - 1) * 0.22))
                src = fetch(s.url)
                if src then break end
            end
        end

        if not src then
            fail("Gagal memuat script", "Semua sumber tidak bisa diambil. Coba lagi, atau paste isi script langsung ke LocalScript.")
            return
        end

        local okDecode, decoded = pcall(decode, src)
        if not okDecode or type(decoded) ~= "string" or decoded == "" then
            fail("Gagal mendekode script", "Isi sumber bukan hex yang valid. Cek CONFIG.encoded dan URL di loader.")
            return
        end
        src = decoded

        setStatus("Script diterima", THEME.ok, #src .. " karakter")
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

        setStatus("Menjalankan script", THEME.ok, "")
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

    if cfg.autoStart ~= false then
        task.spawn(function()
            task.wait(0.35)
            start()
        end)
    end

    return { gui = gui, start = start }
end

-- Jalankan dengan CONFIG bawaan. Untuk script lain: edit CONFIG, atau panggil
-- run({ title = ..., sources = { ... } }) dari file Anda sendiri.
run(CONFIG)
