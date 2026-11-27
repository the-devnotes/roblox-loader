-- [LocalScript] | Lokasi: StarterPlayer > StarterPlayerScripts (paste sebagai LocalScript)
--[[
    Bike For Eggs - Mobile UI v5 (Sidebar Edition)
    ------------------------------------------------------------
    - UI memakai BFEUI (mini library yang ditanam di file ini).
      Jadi tidak butuh HttpGet / library luar yang bisa mati.
    - Fitur dipisah per halaman lewat sidebar.
    - Tombol minimize (-) dan close (X).
    - Anti double-run: kalau script masih jalan, muncul peringatan
      "Script sudah berjalan!".
    - Debug: katalog client (Rarity/Value/Weight) + snapshot + probe egg.
    - Versi ringkas: ambil egg otomatis + pilih rarity minimum.
    - Filter aman: kalau rarity belum terbaca, egg tetap bisa diambil.
    - Galeri egg + halaman Info dipakai mode debug.
    - Tema ClipperHub: biru + hitam, ikon digambar tanpa emoji.

    File asli TIDAK diubah. Ini file baru: BikeForEggsMobile_v5.lua
]]

--[[ ===================== 1. ANTI DOUBLE-RUN ===================== ]]
local GUI_NAME = "BFE_Mobile_v5"
local G1
pcall(function() if getgenv then G1 = getgenv() end end)
G1 = G1 or _G
local G2 = _G

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local function envGet(key)
    if G1 and G1[key] ~= nil then return G1[key] end
    if G2 and G2[key] ~= nil then return G2[key] end
    return nil
end

local function envSet(key, value)
    if G1 then G1[key] = value end
    if G2 and G2 ~= G1 then G2[key] = value end
end

local function findExistingGui()
    local ok, gui = pcall(function()
        local parent = (gethui and gethui()) or game:GetService("CoreGui")
        return parent and parent:FindFirstChild(GUI_NAME)
    end)
    if ok and gui then return gui end
    local pg = lp:FindFirstChild("PlayerGui")
    return pg and pg:FindFirstChild(GUI_NAME)
end

local function simpleNotice(titleText, descText, buttons)
    -- Palet disamakan dengan C di ui_library.lua dan THEME di loader.lua.
    local CARD = Color3.fromRGB(14, 18, 28)
    local PANEL = Color3.fromRGB(24, 33, 52)
    local BLUE = Color3.fromRGB(48, 145, 255)
    local BLUE_DARK = Color3.fromRGB(18, 72, 150)
    local TEXT = Color3.fromRGB(232, 240, 255)
    local MUTED = Color3.fromRGB(140, 160, 192)
    local RED = Color3.fromRGB(255, 96, 112)

    local parent
    pcall(function() parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    local function findOld()
        local a = parent and parent:FindFirstChild("BFE_Notice")
        if a then return a end
        local pg = lp:FindFirstChild("PlayerGui")
        return pg and pg:FindFirstChild("BFE_Notice")
    end
    local old = findOld()
    if old then pcall(function() old:Destroy() end) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "BFE_Notice"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483647
    local ok = pcall(function() gui.Parent = parent end)
    if not ok or not gui.Parent then
        local pg = lp:FindFirstChild("PlayerGui")
        if pg then gui.Parent = pg else return end
    end

    local vp = workspace and workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
    local nw = math.min(340, (vp and vp.X or 360) - 24)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(nw, 178)
    frame.Position = UDim2.new(0.5, -nw / 2, 0, 20)
    frame.BackgroundColor3 = CARD
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 18); c.Parent = frame
    local s = Instance.new("UIStroke"); s.Color = BLUE; s.Thickness = 1.2; s.Transparency = 0.45; s.Parent = frame

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 4)
    accent.BackgroundColor3 = BLUE
    accent.BorderSizePixel = 0
    accent.Parent = frame

    -- Mark ClipperHub digambar, bukan emoji.
    local badge = Instance.new("Frame")
    badge.Size = UDim2.fromOffset(34, 34)
    badge.Position = UDim2.fromOffset(14, 16)
    badge.BackgroundColor3 = BLUE
    badge.BorderSizePixel = 0
    badge.Parent = frame
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 10); bc.Parent = badge
    local clip = Instance.new("Frame")
    clip.Size = UDim2.fromOffset(4, 9)
    clip.Position = UDim2.fromOffset(25, 2)
    clip.BackgroundColor3 = CARD
    clip.BorderSizePixel = 0
    clip.Rotation = 38
    clip.Parent = badge
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 2); cc.Parent = clip
    local letter = Instance.new("TextLabel")
    letter.Size = UDim2.fromOffset(34, 34)
    letter.BackgroundTransparency = 1
    letter.Text = "C"
    letter.TextColor3 = CARD
    letter.Font = Enum.Font.GothamBold
    letter.TextSize = 21
    letter.Parent = badge

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -62, 0, 30)
    title.Position = UDim2.fromOffset(58, 17)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = TEXT
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -28, 0, 58)
    desc.Position = UDim2.fromOffset(14, 62)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextWrapped = true
    desc.TextColor3 = MUTED
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 12
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Parent = frame

    local n = buttons and #buttons or 0
    if n > 0 then
        local bw = math.floor((nw - 28 - (n - 1) * 8) / n)
        for i, b in ipairs(buttons) do
            local danger = (b.variant == "danger")
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.fromOffset(bw, 34)
            btn.Position = UDim2.fromOffset(14 + (i - 1) * (bw + 8), 130)
            btn.BackgroundColor3 = danger and RED or PANEL
            btn.Text = b.text
            btn.TextColor3 = TEXT
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 12
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = true
            btn.Parent = frame
            local br = Instance.new("UICorner"); br.CornerRadius = UDim.new(0, 9); br.Parent = btn
            local bs = Instance.new("UIStroke"); bs.Color = danger and RED or BLUE; bs.Thickness = 1; bs.Transparency = 0.55; bs.Parent = btn
            btn.MouseButton1Click:Connect(function()
                pcall(function() gui:Destroy() end)
                if b.callback then pcall(b.callback) end
            end)
        end
    end
    task.delay(12, function() if gui.Parent then pcall(function() gui:Destroy() end) end end)
    return gui
end

local function showAlreadyNotice()
    simpleNotice(
        "Script sudah berjalan!",
        "UI Bike For Eggs masih aktif. Tutup jendela lama lewat tombol X, atau tekan Tutup Paksa kalau UI lama tidak bisa ditutup.",
        {
            { text = "OK", callback = function() end },
            { text = "Tutup Paksa", variant = "danger", callback = function()
                local old = findExistingGui()
                if old then pcall(function() old:Destroy() end) end
                envSet("BFE_V5_Running", nil)
                simpleNotice("Script lama ditutup", "Sekarang jalankan ulang script ini untuk membuka UI baru.", {
                    { text = "OK", callback = function() end },
                })
            end },
        }
    )
end

local existingGui = findExistingGui()
if envGet("BFE_V5_Running") == true and not existingGui then
    envSet("BFE_V5_Running", nil)
end
if envGet("BFE_V5_Running") == true or existingGui then
    showAlreadyNotice()
    return
end
