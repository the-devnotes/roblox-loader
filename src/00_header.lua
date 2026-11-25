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
    - Filter Best Egg diperbaiki: auto, fallback, dan aman kalau
      game tidak menyediakan data rarity/value.

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
    frame.Size = UDim2.fromOffset(nw, 156)
    frame.Position = UDim2.new(0.5, -nw / 2, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = frame
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(80, 86, 112); s.Thickness = 1.5; s.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 30)
    title.Position = UDim2.fromOffset(12, 10)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(240, 242, 250)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -24, 0, 58)
    desc.Position = UDim2.fromOffset(12, 42)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextWrapped = true
    desc.TextColor3 = Color3.fromRGB(170, 176, 196)
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 12
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Parent = frame

    local n = buttons and #buttons or 0
    if n > 0 then
        local bw = math.floor((nw - 24 - (n - 1) * 8) / n)
        for i, b in ipairs(buttons) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.fromOffset(bw, 32)
            btn.Position = UDim2.fromOffset(12 + (i - 1) * (bw + 8), 110)
            btn.BackgroundColor3 = (b.variant == "danger") and Color3.fromRGB(180, 60, 70) or Color3.fromRGB(50, 55, 75)
            btn.Text = b.text
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 12
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = true
            btn.Parent = frame
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
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

