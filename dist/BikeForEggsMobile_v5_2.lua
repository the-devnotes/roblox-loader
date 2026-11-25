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

--[[ ===================== 2. BOOT ===================== ]]
local function boot()
    envSet("BFE_V5_Running", true)

    local TweenService = game:GetService("TweenService")
    local UIS = game:GetService("UserInputService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    --[[ ===================== 3. BFEUI MINI LIBRARY ===================== ]]
    local C = {
        bg      = Color3.fromRGB(17, 19, 28),
        panel   = Color3.fromRGB(25, 28, 40),
        panel2  = Color3.fromRGB(33, 37, 53),
        panel3  = Color3.fromRGB(42, 47, 67),
        stroke  = Color3.fromRGB(58, 64, 90),
        text    = Color3.fromRGB(236, 239, 248),
        sub     = Color3.fromRGB(150, 157, 182),
        accent  = Color3.fromRGB(118, 170, 255),
        green   = Color3.fromRGB(54, 199, 118),
        red     = Color3.fromRGB(239, 90, 102),
        yellow  = Color3.fromRGB(247, 190, 74),
    }

    local function inst(cls, props, parent)
        local o = Instance.new(cls)
        if props then
            for k, v in pairs(props) do o[k] = v end
        end
        if parent ~= nil then o.Parent = parent end
        return o
    end

    local function corner(o, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 10)
        c.Parent = o
        return c
    end

    local function stroke(o, color, thickness, transparency)
        local s = Instance.new("UIStroke")
        s.Color = color or C.stroke
        s.Thickness = thickness or 1
        s.Transparency = transparency or 0
        s.Parent = o
        return s
    end

    local BFEUI = {}
    BFEUI.__index = BFEUI
    local Page = {}

    function BFEUI.new(cfg)
        cfg = cfg or {}
        local self = setmetatable({}, BFEUI)
        self.cfg = cfg
        self.pages = {}
        self.pageOrder = {}
        self.destroyed = false
        self.toasts = {}

        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(720, 420)
        local W = math.min(760, math.max(300, vp.X * 0.92), vp.X - 16)
        local H = math.min(560, math.max(300, vp.Y * 0.86), vp.Y - 56)
        self.width, self.height = W, H

        local gui = inst("ScreenGui", {
            Name = GUI_NAME,
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 200,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, nil)
        local parent
        pcall(function() parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        local ok = pcall(function() gui.Parent = parent end)
        if not ok or not gui.Parent then
            gui.Parent = lp:WaitForChild("PlayerGui")
        end
        self.gui = gui

        local win = inst("Frame", {
            Name = "Window",
            Size = UDim2.fromOffset(W, H),
            Position = UDim2.fromOffset(math.floor((vp.X - W) / 2), math.floor((vp.Y - H) / 2)),
            BackgroundColor3 = C.bg,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Active = true,
        }, gui)
        corner(win, 14)
        stroke(win, C.stroke, 1, 0.12)
        local winGrad = Instance.new("UIGradient")
        winGrad.Color = ColorSequence.new(C.bg, Color3.fromRGB(21, 23, 37))
        winGrad.Rotation = 90
        winGrad.Parent = win
        self.window = win

        local bar = inst("Frame", {
            Name = "TitleBar",
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = C.panel,
            BorderSizePixel = 0,
        }, win)
        local barGrad = Instance.new("UIGradient")
        barGrad.Color = ColorSequence.new(Color3.fromRGB(34, 38, 58), Color3.fromRGB(25, 28, 40))
        barGrad.Rotation = 90
        barGrad.Parent = bar

        inst("TextLabel", {
            Size = UDim2.fromOffset(34, 42),
            Position = UDim2.fromOffset(10, 0),
            BackgroundTransparency = 1,
            Text = cfg.icon or "🥚",
            TextColor3 = C.text,
            Font = Enum.Font.GothamBold,
            TextSize = 19,
        }, bar)

        inst("TextLabel", {
            Size = UDim2.new(1, -220, 0, 22),
            Position = UDim2.fromOffset(48, 4),
            BackgroundTransparency = 1,
            Text = cfg.title or "Bike For Eggs",
            TextColor3 = C.text,
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, bar)

        inst("TextLabel", {
            Size = UDim2.new(1, -220, 0, 14),
            Position = UDim2.fromOffset(48, 24),
            BackgroundTransparency = 1,
            Text = cfg.subtitle or "Mobile UI",
            TextColor3 = C.sub,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, bar)

        local function titleBtn(text, x, bg, cb)
            local b = inst("TextButton", {
                Size = UDim2.fromOffset(30, 30),
                Position = UDim2.new(1, x, 0.5, -15),
                BackgroundColor3 = bg,
                Text = text,
                TextColor3 = C.text,
                Font = Enum.Font.GothamBold,
                TextSize = 16,
                AutoButtonColor = true,
                BorderSizePixel = 0,
            }, bar)
            corner(b, 8)
            b.MouseButton1Click:Connect(function() pcall(cb) end)
            return b
        end
        titleBtn("-", -74, C.panel3, function() self:minimize() end)
        titleBtn("X", -38, C.red, function() self:destroy("close") end)

        local dragging, dragStart, startPos = false, nil, nil
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = win.Position
                local conn
                conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if conn then conn:Disconnect() end
                    end
                end)
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                local vp2 = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or vp
                local nx = math.clamp(startPos.X.Offset + d.X, -W + 90, vp2.X - 90)
                local ny = math.clamp(startPos.Y.Offset + d.Y, 0, vp2.Y - 44)
                win.Position = UDim2.fromOffset(nx, ny)
            end
        end)

        local body = inst("Frame", {
            Size = UDim2.new(1, 0, 1, -42),
            Position = UDim2.fromOffset(0, 42),
            BackgroundTransparency = 1,
        }, win)

        local sidebarW = math.clamp(math.floor(W * 0.28), 96, 150)
        local sidebar = inst("Frame", {
            Size = UDim2.new(0, sidebarW, 1, 0),
            BackgroundColor3 = C.panel,
            BorderSizePixel = 0,
        }, body)
        inst("Frame", {
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, -1, 0, 0),
            BackgroundColor3 = C.stroke,
            BorderSizePixel = 0,
        }, sidebar)

        local nav = inst("ScrollingFrame", {
            Size = UDim2.new(1, -8, 1, -12),
            Position = UDim2.fromOffset(4, 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = C.stroke,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, sidebar)
        inst("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, nav)

        local content = inst("Frame", {
            Size = UDim2.new(1, -sidebarW, 1, 0),
            Position = UDim2.fromOffset(sidebarW, 0),
            BackgroundTransparency = 1,
        }, body)
        self.nav, self.content = nav, content

        local float = inst("TextButton", {
            Name = "Float",
            Size = UDim2.fromOffset(52, 52),
            Position = UDim2.new(0, 12, 0.5, -26),
            BackgroundColor3 = C.panel,
            Text = "🥚",
            TextSize = 23,
            TextColor3 = C.text,
            AutoButtonColor = false,
            Visible = false,
            BorderSizePixel = 0,
        }, gui)
        corner(float, 26)
        stroke(float, C.stroke, 1.5, 0)
        local dot = inst("Frame", {
            Size = UDim2.fromOffset(12, 12),
            Position = UDim2.new(1, -15, 0, 2),
            BackgroundColor3 = C.green,
            BorderSizePixel = 0,
            Visible = false,
        }, float)
        corner(dot, 6)
        stroke(dot, C.bg, 2, 0)
        self.float, self.dot = float, dot

        local fDrag, fStart, fPos, fMoved = false, nil, nil, false
        float.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                fDrag, fStart, fPos, fMoved = true, input.Position, float.Position, false
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if fDrag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local d = input.Position - fStart
                if math.abs(d.X) + math.abs(d.Y) > 6 then fMoved = true end
                if fMoved then
                    float.Position = UDim2.fromOffset(fPos.X.Offset + d.X, fPos.Y.Offset + d.Y)
                end
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if fDrag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
                fDrag = false
            end
        end)
        float.MouseButton1Click:Connect(function()
            if fMoved then fMoved = false; return end
            self:show()
        end)

        gui.Destroying:Connect(function()
            envSet("BFE_V5_Running", nil)
            if not self.destroyed then
                self.destroyed = true
                if cfg.onDestroy then pcall(cfg.onDestroy, "external") end
            end
        end)

        return self
    end

    function BFEUI:page(id, label, icon)
        local navBtn = inst("TextButton", {
            Name = "Nav_" .. id,
            Size = UDim2.new(1, -8, 0, 40),
            BackgroundColor3 = C.panel2,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
        }, self.nav)
        corner(navBtn, 9)
        local navLabel = inst("TextLabel", {
            Size = UDim2.new(1, -14, 1, 0),
            Position = UDim2.fromOffset(11, 0),
            BackgroundTransparency = 1,
            Text = (icon and (icon .. "  ") or "") .. label,
            TextColor3 = C.sub,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, navBtn)
        local indicator = inst("Frame", {
            Size = UDim2.new(0, 3, 0, 18),
            Position = UDim2.new(0, 0, 0.5, -9),
            BackgroundColor3 = C.accent,
            BorderSizePixel = 0,
            Visible = false,
        }, navBtn)
        corner(indicator, 2)

        local scroll = inst("ScrollingFrame", {
            Name = "Page_" .. id,
            Size = UDim2.new(1, -14, 1, -12),
            Position = UDim2.fromOffset(7, 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = C.stroke,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
        }, self.content)
        inst("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, scroll)
        inst("UIPadding", {
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 12),
        }, scroll)

        local page = setmetatable({
            ui = self, id = id, title = label, icon = icon,
            nav = navBtn, navLabel = navLabel, indicator = indicator,
            scroll = scroll, count = 0,
        }, { __index = Page })
        self.pages[id] = page
        table.insert(self.pageOrder, page)
        navBtn.MouseButton1Click:Connect(function() self:showPage(id) end)
        if not self.current then self:showPage(id) end
        return page
    end

    function BFEUI:showPage(id)
        local page = self.pages[id]
        if not page then return end
        self.current = id
        for _, p in ipairs(self.pageOrder) do
            local sel = (p == page)
            p.scroll.Visible = sel
            p.nav.BackgroundTransparency = sel and 0 or 1
            p.nav.BackgroundColor3 = sel and C.panel3 or C.panel2
            p.navLabel.TextColor3 = sel and C.text or C.sub
            p.indicator.Visible = sel
        end
        if self.onPageShow then pcall(self.onPageShow, id) end
    end

    function BFEUI:minimize()
        self.window.Visible = false
        self.float.Visible = true
        self.minimized = true
    end

    function BFEUI:show()
        self.window.Visible = true
        self.float.Visible = false
        self.minimized = false
    end

    function BFEUI:setActive(v)
        self.dot.Visible = v and true or false
        self.float.BackgroundColor3 = v and Color3.fromRGB(28, 70, 48) or C.panel
    end

    function BFEUI:toast(text, kind)
        local color = (kind == "error" and C.red) or (kind == "warn" and C.yellow) or C.green
        local tw = math.min(360, self.width - 40)
        local f = inst("Frame", {
            Size = UDim2.fromOffset(tw, 40),
            Position = UDim2.new(0.5, -tw / 2, 1, -56),
            BackgroundColor3 = C.panel,
            BorderSizePixel = 0,
            ZIndex = 50,
        }, self.gui)
        corner(f, 10)
        stroke(f, color, 1.5, 0)
        inst("TextLabel", {
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.fromOffset(10, 0),
            BackgroundTransparency = 1,
            Text = tostring(text),
            TextColor3 = C.text,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 51,
        }, f)
        table.insert(self.toasts, f)
        for i, t in ipairs(self.toasts) do
            t.Position = UDim2.new(0.5, -tw / 2, 1, -20 - i * 46)
        end
        task.delay(3.2, function()
            if f.Parent then
                local tw2 = TweenService:Create(f, TweenInfo.new(0.22), { BackgroundTransparency = 1 })
                tw2:Play()
                task.wait(0.24)
                for i = #self.toasts, 1, -1 do
                    if self.toasts[i] == f then table.remove(self.toasts, i) end
                end
                for i, t in ipairs(self.toasts) do
                    t.Position = UDim2.new(0.5, -tw / 2, 1, -20 - i * 46)
                end
                pcall(function() f:Destroy() end)
            end
        end)
    end

    function BFEUI:destroy(reason)
        if self.destroyed then return end
        self.destroyed = true
        envSet("BFE_V5_Running", nil)
        if self.gui then pcall(function() self.gui:Destroy() end) end
        if self.cfg.onDestroy then pcall(self.cfg.onDestroy, reason or "destroy") end
    end

    --[[ ===================== 4. PAGE WIDGETS ===================== ]]
    Page.__index = Page

    function Page:_add(o)
        self.count = self.count + 1
        o.LayoutOrder = self.count
        o.Parent = self.scroll
        return o
    end

    function Page:section(text)
        return self:_add(inst("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = string.upper(tostring(text)),
            TextColor3 = C.accent,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, nil))
    end

    function Page:label(text, opts)
        opts = opts or {}
        return self:_add(inst("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = tostring(text),
            TextColor3 = opts.color or C.text,
            Font = opts.font or Enum.Font.Gotham,
            TextSize = opts.size or 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, nil))
    end

    function Page:note(text, color)
        local f = inst("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.panel,
            BorderSizePixel = 0,
        }, nil)
        corner(f, 9)
        stroke(f, color or C.stroke, 1, 0.35)
        inst("UIPadding", {
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
        }, f)
        local l = inst("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = tostring(text),
            TextColor3 = C.sub,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, f)
        self:_add(f)
        return l
    end

    function Page:divider()
        return self:_add(inst("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = C.stroke,
            BorderSizePixel = 0,
        }, nil))
    end

    function Page:space(h)
        return self:_add(inst("Frame", {
            Size = UDim2.new(1, 0, 0, h or 4),
            BackgroundTransparency = 1,
        }, nil))
    end

    function Page:frame(h)
        return self:_add(inst("Frame", {
            Size = UDim2.new(1, 0, 0, h or 100),
            BackgroundTransparency = 1,
        }, nil))
    end

    function Page:button(text, cb, opts)
        opts = opts or {}
        local variant = opts.variant
        local b = inst("TextButton", {
            Size = UDim2.new(1, 0, 0, opts.height or 42),
            BackgroundColor3 = variant == "danger" and C.red or variant == "primary" and C.accent or C.panel2,
            Text = tostring(text),
            TextColor3 = variant == "primary" and Color3.fromRGB(15, 20, 30) or C.text,
            Font = Enum.Font.GothamBold,
            TextSize = opts.size or 12,
            AutoButtonColor = true,
            BorderSizePixel = 0,
        }, nil)
        corner(b, 9)
        stroke(b, C.stroke, 1, variant and 0.55 or 0.25)
        b.MouseButton1Click:Connect(function()
            if cb then
                local ok, err = pcall(cb)
                if not ok then warn("[BFEUI] button: " .. tostring(err)) end
            end
        end)
        return self:_add(b)
    end

    function Page:buttonRow(items, h)
        local height = h or 42
        local f = inst("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
        }, nil)
        inst("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }, f)
        local n = #items
        for i, item in ipairs(items) do
            local b = inst("TextButton", {
                Size = UDim2.new(1 / n, -math.floor(6 * (n - 1) / n), 1, 0),
                BackgroundColor3 = item.variant == "danger" and C.red or item.variant == "primary" and C.accent or C.panel2,
                Text = tostring(item.text),
                TextColor3 = item.variant == "primary" and Color3.fromRGB(15, 20, 30) or C.text,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                AutoButtonColor = true,
                BorderSizePixel = 0,
                LayoutOrder = i,
            }, f)
            corner(b, 9)
            b.MouseButton1Click:Connect(function()
                if item.callback then
                    local ok, err = pcall(item.callback)
                    if not ok then warn("[BFEUI] row button: " .. tostring(err)) end
                end
            end)
        end
        self:_add(f)
        return f
    end

    function Page:toggle(text, initial, onChange)
        local row = inst("TextButton", {
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = C.panel2,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
        }, nil)
        corner(row, 9)
        inst("TextLabel", {
            Size = UDim2.new(1, -78, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            BackgroundTransparency = 1,
            Text = tostring(text),
            TextColor3 = C.text,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        local sw = inst("Frame", {
            Size = UDim2.fromOffset(48, 26),
            Position = UDim2.new(1, -60, 0.5, -13),
            BackgroundColor3 = C.panel3,
            BorderSizePixel = 0,
        }, row)
        corner(sw, 13)
        local knob = inst("Frame", {
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.new(0, 4, 0.5, -10),
            BackgroundColor3 = C.text,
            BorderSizePixel = 0,
        }, sw)
        corner(knob, 10)

        local on = initial and true or false
        local widget = {}
        local function render(animated)
            local targetBg = on and C.green or C.panel3
            local targetPos = on and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)
            if animated then
                TweenService:Create(sw, TweenInfo.new(0.14), { BackgroundColor3 = targetBg }):Play()
                TweenService:Create(knob, TweenInfo.new(0.14), { Position = targetPos }):Play()
            else
                sw.BackgroundColor3 = targetBg
                knob.Position = targetPos
            end
        end
        function widget:set(v)
            on = v and true or false
            render(true)
        end
        function widget:get() return on end
        row.MouseButton1Click:Connect(function()
            on = not on
            render(true)
            if onChange then
                local ok, err = pcall(onChange, on)
                if not ok then warn("[BFEUI] toggle: " .. tostring(err)) end
            end
        end)
        render(false)
        self:_add(row)
        return widget
    end

    function Page:dropdown(text, options, initial, onChange)
        local row = inst("TextButton", {
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = C.panel2,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
        }, nil)
        corner(row, 9)
        inst("TextLabel", {
            Size = UDim2.new(0.54, -10, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            BackgroundTransparency = 1,
            Text = tostring(text),
            TextColor3 = C.text,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        local valueLabel = inst("TextLabel", {
            Size = UDim2.new(0.46, -14, 1, 0),
            Position = UDim2.new(0.54, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = C.accent,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)

        local idx = math.clamp(initial or 1, 1, #options)
        local function render()
            valueLabel.Text = tostring(options[idx]) .. "  v"
        end
        render()

        local widget = {}
        function widget:get() return idx end
        function widget:value() return options[idx] end
        function widget:set(i)
            idx = math.clamp(i or 1, 1, #options)
            render()
        end
        function widget:setOptions(newOptions, newIndex)
            options = newOptions
            idx = math.clamp(newIndex or idx or 1, 1, #options)
            render()
        end
        row.MouseButton1Click:Connect(function()
            idx = (idx % #options) + 1
            render()
            if onChange then
                local ok, err = pcall(onChange, options[idx], idx)
                if not ok then warn("[BFEUI] dropdown: " .. tostring(err)) end
            end
        end)
        self:_add(row)
        return widget
    end

    function Page:stepper(text, minv, maxv, step, initial, onChange, fmt)
        local row = inst("Frame", {
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = C.panel2,
            BorderSizePixel = 0,
        }, nil)
        corner(row, 9)
        inst("TextLabel", {
            Size = UDim2.new(1, -140, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            BackgroundTransparency = 1,
            Text = tostring(text),
            TextColor3 = C.text,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)

        local function mkBtn(sym, x)
            local b = inst("TextButton", {
                Size = UDim2.fromOffset(30, 30),
                Position = UDim2.new(1, x, 0.5, -15),
                BackgroundColor3 = C.panel3,
                Text = sym,
                TextColor3 = C.text,
                Font = Enum.Font.GothamBold,
                TextSize = 16,
                BorderSizePixel = 0,
            }, row)
            corner(b, 8)
            return b
        end
        local minus = mkBtn("-", -130)
        local valueLabel = inst("TextLabel", {
            Size = UDim2.fromOffset(54, 30),
            Position = UDim2.new(1, -96, 0.5, -15),
            BackgroundColor3 = C.panel3,
            Text = "",
            TextColor3 = C.text,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            BorderSizePixel = 0,
        }, row)
        corner(valueLabel, 8)
        local plus = mkBtn("+", -38)

        local value = initial or minv
        local function snap(v)
            return math.clamp(math.floor((v / step) + 0.5) * step, minv, maxv)
        end
        local function render()
            valueLabel.Text = fmt and fmt(value) or tostring(value)
        end
        local function apply(v)
            value = snap(v)
            render()
            if onChange then
                local ok, err = pcall(onChange, value)
                if not ok then warn("[BFEUI] stepper: " .. tostring(err)) end
            end
        end
        minus.MouseButton1Click:Connect(function() apply(value - step) end)
        plus.MouseButton1Click:Connect(function() apply(value + step) end)
        render()
        self:_add(row)
        return {
            get = function() return value end,
            set = function(v) value = snap(v); render() end,
        }
    end

    function Page:card(rows)
        local f = inst("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.panel,
            BorderSizePixel = 0,
        }, nil)
        corner(f, 10)
        stroke(f, C.stroke, 1, 0.4)
        inst("UIPadding", {
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
        }, f)
        inst("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, f)

        local labels = {}
        for i, row in ipairs(rows or {}) do
            local r = inst("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                LayoutOrder = i,
            }, f)
            inst("TextLabel", {
                Size = UDim2.new(0.54, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = tostring(row[1]),
                TextColor3 = C.sub,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, r)
            local v = inst("TextLabel", {
                Size = UDim2.new(0.46, 0, 1, 0),
                Position = UDim2.new(0.54, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(row[2] or "-"),
                TextColor3 = C.text,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, r)
            labels[row[1]] = v
        end

        self:_add(f)
        return {
            frame = f,
            labels = labels,
            set = function(key, text, color)
                local l = labels[key]
                if l then
                    l.Text = tostring(text)
                    l.TextColor3 = color or C.text
                end
            end,
        }
    end

    --[[ ===================== 5. STATE & DATA ===================== ]]
    local AREAS = {
        {"Forest",         Vector3.new(597, 72, -316)},
        {"Lake",           Vector3.new(743, 72, -419)},
        {"Desert",         Vector3.new(950, 72, -311)},
        {"Jungle",         Vector3.new(1188, 71, -421)},
        {"Snow",           Vector3.new(1492, 78, -304)},
        {"Volcano",        Vector3.new(1874, 74, -415)},
        {"Abyss Ocean",    Vector3.new(2283, 77, -312)},
        {"Prehistoric",    Vector3.new(2809, 74, -417)},
        {"Cosmic",         Vector3.new(3393, 83, -312)},
        {"Royal Kingdom",  Vector3.new(4031, 83, -414)},
        {"Crystal Canyon", Vector3.new(4800, 83, -323)},
    }
    local AREA_NAMES = {}
    for i, a in ipairs(AREAS) do AREA_NAMES[i] = a[1] end

    local SORTS = {"Auto (terbaik)", "Rarity", "Value", "Progression", "Terdekat", "Berat (kg)"}
    local RARITY = {"common", "uncommon", "rare", "epic", "legendary", "mythic", "secret", "divine", "celestial", "godly", "transcendent", "cosmic", "eternal"}
    local RARITY_LABEL = {"Basic", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine", "Exclusive", "Exotic", "Superior", "Cosmic", "Eternal"}
    local RARITY_NAMES = {"Semua", "Uncommon+", "Rare+", "Epic+", "Legendary+", "Mythic+", "Secret+", "Divine+", "Exclusive+", "Exotic+", "Superior+", "Cosmic+", "Eternal+"}
    local RARITY_COLOR = {
        Color3.fromRGB(168, 176, 198),
        Color3.fromRGB(112, 205, 145),
        Color3.fromRGB(104, 168, 255),
        Color3.fromRGB(190, 130, 255),
        Color3.fromRGB(255, 182, 82),
        Color3.fromRGB(255, 104, 132),
        Color3.fromRGB(255, 82, 205),
        Color3.fromRGB(120, 232, 255),
        Color3.fromRGB(255, 232, 120),
        Color3.fromRGB(255, 152, 62),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(190, 120, 255),
        Color3.fromRGB(255, 240, 160),
    }
    -- Dipakai HANYA untuk field rarity eksplisit / feedback claim.
    local RARITY_ALIAS = {
        basic = 1, common = 1, starter = 1, normal = 1,
        uncommon = 2,
        rare = 3,
        ["super rare"] = 4, epic = 4, ["ultra rare"] = 4,
        legendary = 5, mythical = 6, mythic = 6,
        secret = 7, hidden = 7,
        divine = 8, heavenly = 8,
        celestial = 9, exclusive = 9,
        exotic = 10, godly = 10, ["god tier"] = 10, immortal = 10, rainbow = 10,
        superior = 11, transcendent = 11, transendent = 11,
        cosmic = 12,
        eternal = 13, brainrotgod = 13, ["brainrot god"] = 13, limited = 13,
        ultimate = 13, supreme = 13, fabled = 13,
    }
    local VALUE_STEPS = {0, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e12}
    local VALUE_NAMES = {"Semua", "1K+", "10K+", "100K+", "1M+", "10M+", "100M+", "1B+", "10B+", "1T+"}
    local PROG_STEPS = {0, 5, 10, 20, 30, 50, 75, 100, 150, 200, 300, 500}
    local PROG_NAMES = {"Semua", "5+", "10+", "20+", "30+", "50+", "75+", "100+", "150+", "200+", "300+", "500+"}

    local state = {
        steal = false, hatch = false, sell = false,
        area = 1, allAreas = false, autoArea = true,
        best = true,
        sort = 1,
        minRar = 1, minProg = 1, minVal = 1,
        galleryRar = 1,
        fallback = true, strict = false, probe = true, lite = true,
        stealDelay = 0.6, hatchDelay = 1.2, sellDelay = 1.2,
    }

    local running = true
    local ui
    local updateHome
    local galleryDirty = true
    local galleryRefresh = nil
    local gallerySig = ""
    local areaAutoRef = nil
    local lastCarry = nil
    local carryEventSeen = false
    local categoryRarity = {}
    local categoryProg = {}
    local categoryValue = {}
    local categoryWeight = {}
    local categoryChance = {}
    local categoryImage = {}
    local uidCategory = {}
    local uidArea = {}
    local assetUidHints = {} -- Uid asli dari StealTargetEvent (bukan nama model AreaEgg_)
    -- Katalog metadata dari ReplicatedStorage.Directory._Index (diisi oleh 42_catalog).
    local catalog = {
        at = -1e9, count = 0, err = 0, byKey = {}, entries = {}, keyCount = 0, rarRaw = nil, read = nil,
        rarityNumber = {}, rarityLabel = {},
        compactKey = function(s)
            if type(s) ~= "string" then return nil end
            local v = s:lower():gsub("^%s+", ""):gsub("%s+$", "")
            v = v:gsub(" egg$", "")
            v = v:gsub("[^%w]", "")
            if v == "" then return nil end
            return v
        end,
    }
    local probeDone = {}
    local probeAt = -1e9
    local toggleRefs = {}

    --[[ ===================== 6. LOG SYSTEM ===================== ]]
    local logs = {}
    -- Simpan banyak baris untuk Copy All, tapi tampilkan hanya sebagian agar
    -- TextLabel tidak berat di HP.
    local LOG_CAP = { store = 4000, line = 3000, ui = 300 }
    local logDirty = true
    local logScroll, logLabel
    local autoScroll = true

    local function log(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        local line = string.format("[%s] %s", os.date("%H:%M:%S"), table.concat(parts, " "))
        if #line > LOG_CAP.line then line = line:sub(1, LOG_CAP.line) .. "..." end
        logs[#logs + 1] = line
        if #logs > LOG_CAP.store then table.remove(logs, 1) end
        logDirty = true
    end

    local function refreshLogUI()
        if not logScroll or not logLabel then return end
        if #logs == 0 then
            logLabel.Text = "(belum ada log)"
        else
            local start = 1
            local hidden = #logs - LOG_CAP.ui
            if hidden > 0 then start = hidden + 1 end
            local view = {}
            if hidden > 0 then
                view[1] = "... " .. hidden .. " baris sebelumnya disembunyikan (Copy All untuk semua) ..."
            end
            for i = start, #logs do view[#view + 1] = logs[i] end
            logLabel.Text = table.concat(view, "\n")
        end
        if autoScroll then
            task.defer(function()
                if logScroll and logScroll.Parent then
                    local ok, size = pcall(function() return logScroll.AbsoluteCanvasSize.Y end)
                    if ok then
                        logScroll.CanvasPosition = Vector2.new(0, math.max(0, size - logScroll.AbsoluteSize.Y))
                    end
                end
            end)
        end
    end

    --[[ ===================== 7. HELPERS ===================== ]]
    local function getRoot()
        local char = lp.Character
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart")
    end

    local function teleport(pos)
        local r = getRoot()
        if r and pos then
            pcall(function() r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end)
        end
    end

    local function flat(v)
        return Vector3.new(v.X, 0, v.Z)
    end

    local function distXZ(a, b)
        return (flat(a) - flat(b)).Magnitude
    end

    local function fmtVal(n)
        n = tonumber(n) or 0
        if n >= 1e12 then return string.format("%.2fT", n / 1e12) end
        if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
        if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
        if n >= 1e3 then return string.format("%.2fK", n / 1e3) end
        return tostring(math.floor(n))
    end

    local function fmtKg(n)
        n = tonumber(n) or 0
        if n >= 1e6 then return fmtVal(n) .. " kg" end
        if n >= 1e3 then return string.format("%.2fK kg", n / 1e3) end
        if n >= 100 then return string.format("%.0f kg", n) end
        if n >= 1 then return string.format("%.1f kg", n) end
        return string.format("%.2f kg", n)
    end

    local SUFFIX = {
        k = 1e3, m = 1e6, b = 1e9, t = 1e12,
        qa = 1e15, qi = 1e18, sx = 1e21, sp = 1e24,
        oc = 1e27, no = 1e30, dc = 1e33,
    }

    -- Parsing rarity HANYA dari field yang jelas (Rarity, Tier, claim feedback, dll).
    -- "Cosmic" di nama area tidak boleh masuk lewat jalur ini.
    -- Taruh di helper (sebelum snapshot) supaya applyCategoryMeta bisa memanggilnya.
    local function rarityOf(value)
        if type(value) == "number" then
            if value >= 1 and value <= #RARITY then return math.floor(value) end
            return 0
        end
        if type(value) ~= "string" then return 0 end
        local s = value:lower():gsub("[%s_%-]+", "")
        if s == "" then return 0 end
        -- Urutan RarityNumber dari modul game diprioritaskan (Exclusive=7,
        -- BrainrotGod=6, dll.) sebelum alias statis.
        local rn = catalog and catalog.rarityNumber
        if rn and rn[s] then return rn[s] end
        local best = 0
        for word, idx in pairs(RARITY_ALIAS) do
            local w = word:gsub("[%s_%-]+", "")
            if s == w then
                if idx > best then best = idx end
            end
        end
        return best
    end

    local function parseValue(s)
        if type(s) == "number" then return s end
        s = tostring(s):lower():gsub(",", ""):gsub("%s+", "")
        local num, suf = s:match("([%d%.]+)([a-z]*)")
        local n = tonumber(num)
        if not n then return nil end
        return n * (SUFFIX[suf] or 1)
    end

    local function parseChance(s)
        if type(s) == "number" then return s end
        s = tostring(s):lower():gsub(",", "")
        local n = s:match("1%s*in%s*([%d%.]+)") or s:match("1/%s*([%d%.]+)")
        return tonumber(n)
    end

    local function ser(v, depth, seen)
        depth = depth or 0
        local tv = typeof(v)
        if tv ~= "table" then
            if tv == "string" then return '"' .. v .. '"' end
            return tostring(v)
        end
        if depth >= 3 then return "{...}" end
        seen = seen or {}
        if seen[v] then return "{cycle}" end
        seen[v] = true
        local parts, n = {}, 0
        for k, val in pairs(v) do
            n = n + 1
            if n > 14 then parts[#parts + 1] = "..."; break end
            parts[#parts + 1] = tostring(k) .. "=" .. ser(val, depth + 1, seen)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end

    -- Nama/kategori generik bukan identitas egg. Jangan dipakai sebagai kunci
    -- uidCategory maupun argumen RequestEggRecord (dulu selalu jadi "cat:egg").
    local function genericEggName(s)
        if type(s) ~= "string" then return true end
        local v = s:lower():gsub("^%s+", ""):gsub("%s+$", "")
        if v == "" or v == "egg" or v == "eggs" or v == "telur" then return true end
        if v:match("^egg%s*#?%s*%d*$") then return true end
        if v:match("^telur%s*#?%s*%d*$") then return true end
        return false
    end

    -- Urutan katalog egg bertema di game (dari dump): makin belakang makin tinggi.
    -- Dipakai hanya sebagai fallback kalau model tidak punya ProgressionOrder.
    local THEME_PROG = {
        penguin = 1, walrus = 2, bear = 3, tiger = 4, mammoth = 5,
        king = 6, yeti = 7, dragon = 8, snake = 9, cerberus = 10,
    }

    local GUID_PATTERN = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
    local function guidOf(s)
        if s == nil then return nil end
        s = tostring(s)
        local g = s:match(GUID_PATTERN)
        if g then return g end
        local tail = s:match("(%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x)$")
        return tail
    end

    --[[ ===================== 8. SNAPSHOT SERVER ===================== ]]
    local snapCache = {}
    local snapByName = {}
    local snapMeta = {}
    local snapAt = -1e9
    local snapLastErr = nil

    local function netRemote(name)
        local net = ReplicatedStorage:FindFirstChild("Network")
        if not net then return nil end
        return net:FindFirstChild(name, true)
    end

    -- Simpan data per kategori (AssetCategory / PetDisplayName) supaya egg tanpa
    -- atribut rarity/value/weight tetap bisa diisi dari snapshot / record server.
    local function applyCategoryMeta(cat, v)
        if type(cat) ~= "string" or cat == "" or genericEggName(cat) or type(v) ~= "table" then return end
        local key = string.lower(cat)

        local pr = tonumber(v.ProgressionOrder or v.OriginalImportNumber)
        if pr and pr > 0 and pr > (categoryProg[key] or 0) then categoryProg[key] = pr end

        local r = rarityOf(v.Rarity or v.Tier or v.Grade)
        if r > (categoryRarity[key] or 0) then categoryRarity[key] = r end

        local val = parseValue(v.Value or v.Money or v.PerSecond or v.Price or v.Worth or v.Income)
        if val and val > (categoryValue[key] or 0) then categoryValue[key] = val end

        local w = parseValue(v.Weight or v.Kg or v.Mass)
        if w and w > (categoryWeight[key] or 0) then categoryWeight[key] = w end

        local c = parseChance(v.Chance or v.Odds or v.Probability)
        if c and c > (categoryChance[key] or 0) then categoryChance[key] = c end

        local im = assetIdOf(v.Image or v.Icon or v.Texture or v.Thumbnail or v.AssetId)
        if im and not categoryImage[key] then categoryImage[key] = im end
    end

    local function indexSnapshot(t, depth, seen)
        if type(t) ~= "table" or (depth or 0) > 6 then return end
        seen = seen or {}
        if seen[t] then return end
        seen[t] = true
        for k, v in pairs(t) do
            if type(k) == "string" then
                local id = guidOf(k)
                if id and type(v) == "table" then snapCache[string.lower(id)] = v end
            end
            if type(v) == "table" then
                local anyCat = v.AssetCategory or v.Category or v.PetDisplayName or v.DisplayName
                applyCategoryMeta(anyCat, v)

                local uid
                for _, f in ipairs({"Id", "ID", "EggId", "EggID", "Uid", "UID", "Guid", "GUID", "id"}) do
                    local s = v[f]
                    if type(s) == "string" then
                        local id = guidOf(s)
                        if id then
                            snapCache[string.lower(id)] = v
                            uid = string.lower(id)
                        end
                    end
                end
                for _, f in ipairs({"DisplayName", "EggName", "Name"}) do
                    local s = v[f]
                    if type(s) == "string" and #s > 1 and #s < 48 then
                        snapByName[string.lower(s)] = v
                    end
                end
                if uid then
                    snapMeta[uid] = v
                    local cat = v.AssetCategory or v.Category or v.PetDisplayName or v.DisplayName
                    if type(cat) == "string" and cat ~= "" and not genericEggName(cat) then
                        uidCategory[uid] = string.lower(cat)
                    end
                    local aid = v.AreaId or v.Area
                    if type(aid) == "string" then uidArea[uid] = aid end
                    local pr = tonumber(v.ProgressionOrder or v.OriginalImportNumber)
                    if pr and cat and not genericEggName(cat) then categoryProg[string.lower(cat)] = pr end
                end
                indexSnapshot(v, (depth or 0) + 1, seen)
            end
        end
    end

    local snapEventConn = nil
    local unpackArgs = table.unpack or unpack
    local snapLogAt = -1e9

    local function argSig(args)
        local parts = {}
        for _, a in ipairs(args) do
            parts[#parts + 1] = type(a) == "table" and ("(" .. ser(a) .. ")") or tostring(a)
        end
        return table.concat(parts, "|")
    end

    local function noteSnap(msg, verbose)
        if verbose or os.clock() - snapLogAt > 30 then
            snapLogAt = os.clock()
            log(msg)
        end
    end

    local function snapCount()
        local n = 0
        for _ in pairs(snapCache) do n = n + 1 end
        return n
    end

    local function refreshSnapshot(verbose)
        local rf = netRemote("Eggs: RequestAreaEggSnapshot")
        if not rf then
            if verbose then log("Snapshot remote tidak ada (ReplicatedStorage.Network).") end
            return false
        end

        if rf:IsA("RemoteEvent") then
            if not snapEventConn then
                snapEventConn = rf.OnClientEvent:Connect(function(...)
                    for i = 1, select("#", ...) do
                        indexSnapshot((select(i, ...)), 0)
                    end
                    snapAt = os.clock()
                end)
            end
            pcall(function() rf:FireServer(state.area) end)
            task.wait(0.45)
            snapAt = os.clock()
            if verbose then log("Snapshot via RemoteEvent dikirim. Ter-index: " .. snapCount()) end
            return true
        end

        if not rf:IsA("RemoteFunction") then
            if verbose then log("Snapshot remote bukan RemoteFunction/RemoteEvent.") end
            return false
        end

        local before = snapCount()
        local areaName = AREAS[state.area][1]
        local attempts = {
            {},
            { state.area },
            { areaName },
            { { AreaId = areaName } },
            { { Area = areaName } },
            { { areaId = areaName } },
            { state.area, areaName },
        }
        local gotResult = false
        local lastErr, lastRes
        for _, args in ipairs(attempts) do
            local ok, res = pcall(function()
                return rf:InvokeServer(unpackArgs(args))
            end)
            if ok then
                gotResult = true
                if not lastRes or (type(lastRes) == "table" and next(lastRes) == nil and type(res) == "table" and next(res) ~= nil) then
                    lastRes = res
                end
                indexSnapshot(res, 0)
                noteSnap("SNAPSHOT RAW (" .. argSig(args) .. "): " .. ser(res):sub(1, 900), verbose)
                if snapCount() > before then break end
                if before > 0 and type(res) == "table" and next(res) ~= nil then break end
            else
                lastErr = tostring(res)
            end
        end

        if not gotResult then
            snapLastErr = lastErr
            if verbose then log("Snapshot error: " .. tostring(lastErr)) end
            return false
        end

        snapAt = os.clock()
        galleryDirty = true
        if verbose then
            log("Snapshot OK, " .. snapCount() .. " egg ter-index (area " .. AREAS[state.area][1] .. ").")
            log("Raw: " .. ser(lastRes):sub(1, 900))
            if lastErr then log("Catatan: " .. lastErr) end
        end
        return true
    end

    -- Runtime snapshot: cadangan kalau AreaEggSnapshot tidak membawa rarity/value.
    local function refreshRuntimeSnapshot(verbose)
        local before = snapCount()
        local areaName = AREAS[state.area][1]
        local attempts = {
            {},
            { state.area },
            { areaName },
            { { AreaId = areaName } },
            { { Area = areaName } },
        }
        -- Dua namespace snapshot: Eggs punya data egg, ActiveAssets punya data
        -- aset aktif (termasuk target steal). Coba keduanya.
        local any = false
        for _, remoteName in ipairs({
            "Eggs: RequestRuntimeSnapshot",
            "ActiveAssets: RequestRuntimeSnapshot",
            "ActiveAssets: RequestStealTarget",
            "Eggs: RequestAreaEggRareSpawnPresentations",
        }) do
            local rf = netRemote(remoteName)
            if rf and rf:IsA("RemoteFunction") then
                for _, args in ipairs(attempts) do
                    local ok, res = pcall(function() return rf:InvokeServer(unpackArgs(args)) end)
                    if ok and res then
                        any = true
                        indexSnapshot(res, 0)
                        noteSnap("RUNTIME RAW [" .. remoteName .. "] (" .. argSig(args) .. "): +"
                            .. (snapCount() - before) .. " entri | " .. ser(res):sub(1, 900), verbose)
                        break
                    end
                end
            elseif verbose then
                log(remoteName .. " remote tidak ada.")
            end
        end
        return any
    end

    -- Probe RequestEggRecord untuk satu egg/kategori. Di-cache supaya tidak spam server.
    -- UID diprioritaskan: dulu kuncinya "cat:egg" karena nama fallback, jadi argumen
    -- Uid tidak pernah terlihat di log.
    local recordLogAt, recordTryAuto, recordTryVerbose = -1e9, false, false
    local function noteRecord(msg, verbose)
        if verbose or os.clock() - recordLogAt > 25 then
            recordLogAt = os.clock()
            log(msg)
        end
    end

    local function probeRecord(uid, cat, areaName, verbose, fullUid)
        local realUid = fullUid or (uid and ("AreaEgg_" .. uid) or nil)
        local key = "uid:" .. tostring(realUid or uid or cat or "-")
        if probeDone[key] and not verbose then return nil end
        probeDone[key] = true

        local rf = netRemote("Eggs: RequestEggRecord")
        if not rf or not rf:IsA("RemoteFunction") then
            if verbose then log("RequestEggRecord remote tidak ada.") end
            return nil
        end

        -- Coba Uid penuh "AreaEgg_<guid>", guid saja, dan bentuk table.
        local ids = {}
        if realUid then ids[#ids + 1] = realUid end
        if uid then
            ids[#ids + 1] = "AreaEgg_" .. uid
            ids[#ids + 1] = uid
        end

        local attempts = {}
        for _, id in ipairs(ids) do
            attempts[#attempts + 1] = { id }
            attempts[#attempts + 1] = { { Uid = id } }
            attempts[#attempts + 1] = { { uid = id } }
            attempts[#attempts + 1] = { { Uuid = id } }
            attempts[#attempts + 1] = { { AssetUid = id } }
            attempts[#attempts + 1] = { { assetUid = id } }
            if areaName then attempts[#attempts + 1] = { areaName, id } end
            attempts[#attempts + 1] = { state.area, id }
        end
        attempts[#attempts + 1] = {}
        if cat and not genericEggName(cat) then
            attempts[#attempts + 1] = { cat }
            if areaName then attempts[#attempts + 1] = { areaName, cat } end
        end

        local sigs = {}
        for _, args in ipairs(attempts) do
            local sig = argSig(args)
            if not sigs[sig] then
                sigs[sig] = true
                local ok, res = pcall(function() return rf:InvokeServer(unpackArgs(args)) end)
                if ok and res ~= nil then
                    if type(res) == "table" then indexSnapshot(res, 0) end
                    local gotCat = (type(res) == "table" and (res.AssetCategory or res.PetDisplayName
                        or res.DisplayName or res.Category)) or cat
                    applyCategoryMeta(gotCat, res)
                    noteRecord("RECORD " .. sig .. ": " .. ser(res):sub(1, 700), verbose)
                    if type(res) == "table" and next(res) ~= nil then return res end
                end
            end
        end
        if (verbose and not recordTryVerbose) or (not verbose and not recordTryAuto) then
            if verbose then recordTryVerbose = true else recordTryAuto = true end
            local list = {}
            for s in pairs(sigs) do list[#list + 1] = s end
            noteRecord("RECORD coba " .. key .. ": " .. table.concat(list, " | "), verbose)
        end
        if verbose then log("RECORD tidak ada untuk " .. key) end
        return nil
    end

    local function debugSummary()
        local function count(t)
            local c = 0
            for _ in pairs(t) do c = c + 1 end
            return c
        end
        return string.format("cache=%d nama=%d kategori=%d rarity=%d value=%d weight=%d",
            snapCount(), count(snapByName), count(uidCategory),
            count(categoryRarity), count(categoryValue), count(categoryWeight))
    end

    --[[ ===================== 9. EGG INFO & FILTER ===================== ]]
    local function truthy(v)
        if v == nil or v == false then return false end
        if type(v) == "number" then return v ~= 0 end
        local s = tostring(v):lower():gsub("%s+", "")
        return s ~= "" and s ~= "false" and s ~= "0" and s ~= "none" and s ~= "no" and s ~= "null"
    end

    local function assetIdOf(s)
        if type(s) ~= "string" then return nil end
        local id = s:match("rbxassetid://(%d+)") or s:match("rbxthumb://[^%d]*(%d+)")
        if not id and s:match("^%d%d%d%d%d+$") then id = s end
        return id
    end

    local function scanKV(info, key, value)
        local kk = tostring(key):lower():gsub("[%s_%-]", "")
        if kk == "displayname" or kk == "name" or kk == "eggname"
            or kk == "assetcategory" or kk == "petdisplayname" or kk == "petname"
            or kk == "assetname" or kk == "category" then
            if type(value) == "string" and value ~= "" and #value < 48 then info.name = value end
        elseif kk:find("progression", 1, true) or kk:find("progorder", 1, true) or kk == "order" or kk == "level" or kk == "stage"
            or kk:find("importnumber", 1, true) then
            local n = tonumber(value)
            if n and n > info.prog then info.prog = n end
        elseif kk:find("chance", 1, true) or kk:find("odds", 1, true) or kk:find("probability", 1, true) or kk:find("luck", 1, true) then
            local n = parseChance(value) or tonumber(value)
            if n and n > info.chance then info.chance = n end
        elseif kk:find("weight", 1, true) or kk:find("mass", 1, true) or kk == "kg" then
            local n = parseValue(value)
            if n and n > info.weight then info.weight = n end
        elseif kk:find("image", 1, true) or kk:find("icon", 1, true) or kk:find("thumbnail", 1, true)
            or kk:find("texture", 1, true) or kk:find("decal", 1, true) or kk:find("assetid", 1, true) then
            local id = assetIdOf(value)
            if id then info.imageId = id end
        elseif kk:find("rarity", 1, true) or kk:find("tier", 1, true) or kk:find("grade", 1, true)
            or kk:find("quality", 1, true) or kk:find("class", 1, true) or kk == "rank" then
            if type(value) == "number" then
                info.rarNum = math.max(info.rarNum, value)
                if value >= 1 and value <= #RARITY then
                    info.rar = math.max(info.rar, math.floor(value))
                end
            else
                local r = rarityOf(value)
                if r > info.rar then info.rar = r end
            end
        elseif kk:find("event", 1, true) or kk:find("night", 1, true) or kk:find("limited", 1, true) or kk:find("special", 1, true) then
            if truthy(value) then info.event = true end
        elseif kk:find("value", 1, true) or kk:find("price", 1, true) or kk:find("worth", 1, true)
            or kk:find("income", 1, true) or kk:find("persecond", 1, true) or kk:find("psec", 1, true) then
            local n = parseValue(value)
            if n and n > info.val then info.val = n end
        end
    end

    local function scanTable(info, t, depth, seen)
        if type(t) ~= "table" or depth > 4 then return end
        seen = seen or {}
        if seen[t] then return end
        seen[t] = true
        for k, v in pairs(t) do
            if type(v) == "table" then
                scanTable(info, v, depth + 1, seen)
            else
                scanKV(info, k, v)
            end
        end
    end

    local function cleanEggName(s)
        s = tostring(s or "")
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        if s == "" then return "" end
        if s:find("^%x%x%x%x%x%x%x%x%-") then return "" end
        if s:find("AreaEgg", 1, true) and #s > 22 then return "" end
        if #s > 48 then return "" end
        return s
    end

    local function looksLikeStat(txt)
        local tl = tostring(txt):lower()
        return tl:find("value", 1, true) or tl:find("berat", 1, true) or tl:find("weight", 1, true)
            or tl:find("kg", 1, true) or tl:find("1 in", 1, true) or tl:find("1/", 1, true)
            or tl:find("rarity", 1, true) or tl:find("chance", 1, true) or tl:find("odds", 1, true)
            or tl:find("progression", 1, true) or tl:find("$", 1, true) or tl:find("coin", 1, true)
    end

    local function rarityFromText(txt)
        local tl = tostring(txt):lower():gsub("[%s_%-]+", "")
        if #tl > 32 then return 0 end
        local rn = catalog and catalog.rarityNumber
        if rn and rn[tl] then return rn[tl] end
        local best = 0
        for word, idx in pairs(RARITY_ALIAS) do
            local w = word:gsub("[%s_%-]+", "")
            if tl == w then
                if idx > best then best = idx end
            end
        end
        return best
    end

    local function eggInfo(m)
        local themedAttr = m:GetAttribute("OurThemedEgg")
        local petDisp = m:GetAttribute("PetDisplayName")
        local disp = m:GetAttribute("DisplayName")
        local modelName = m:GetAttribute("PetModelName")
        local theme = m:GetAttribute("EggTheme")

        -- Nama asli: PetDisplayName > DisplayName (tanpa "Egg") > PetModelName.
        -- "Egg"/"Egg #1" adalah fallback, bukan identitas untuk probe record.
        local function eggTitle()
            local v = cleanEggName(petDisp)
            if not genericEggName(v) then return v end
            v = cleanEggName(disp):gsub("%s*[Ee]gg%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if not genericEggName(v) then return v end
            v = cleanEggName(modelName)
            if not genericEggName(v) then return v end
            return ""
        end

        local info = {
            name = eggTitle(),
            theme = theme,
            prog = tonumber(m:GetAttribute("ProgressionOrder")) or 0,
            themed = truthy(themedAttr),
            event = false,
            weight = 0,
            imageId = nil,
            rar = 0, rarNum = 0, val = 0, chance = 0,
            texts = {}, attrs = {},
        }

        local function scanAttrs(obj, record)
            local ok, attrs = pcall(function() return obj:GetAttributes() end)
            if not ok or not attrs then return end
            for k, v in pairs(attrs) do
                if type(v) ~= "table" then
                    if record then info.attrs[#info.attrs + 1] = tostring(k) .. "=" .. tostring(v) end
                    scanKV(info, k, v)
                end
            end
        end

        scanAttrs(m, true)

        local scannedIds = {}
        local eggUid = guidOf(m.Name) and string.lower(guidOf(m.Name)) or nil
        local function applyMeta(key)
            local cat = uidCategory[key]
            if cat then
                if info.name == "" then info.name = cat end
                local r = categoryRarity[cat]
                if r and r > info.rar then info.rar = r end
                local p = categoryProg[cat]
                if p and p > info.prog then info.prog = p end
                local v = categoryValue[cat]
                if v and v > info.val then info.val = v end
                local w = categoryWeight[cat]
                if w and w > info.weight then info.weight = w end
                local c = categoryChance[cat]
                if c and c > info.chance then info.chance = c end
                local im = categoryImage[cat]
                if im and not info.imageId then info.imageId = im end
            end
            local aid = uidArea[key]
            if aid then info.areaId = aid end
        end
        local function tryId(name)
            local id = guidOf(name)
            if not id then return end
            local key = string.lower(id)
            if scannedIds[key] then return end
            scannedIds[key] = true
            local data = snapCache[key] or snapMeta[key]
            if data then scanTable(info, data, 0) end
            applyMeta(key)
        end
        tryId(m.Name)
        tryId(m:GetAttribute("UniqueId"))
        tryId(m:GetAttribute("Guid"))

        -- Slot/folder induk kadang menyimpan data egg (progression, rarity, dll).
        local anc = m.Parent
        for _ = 1, 3 do
            if not anc or anc == workspace then break end
            scanAttrs(anc, false)
            tryId(anc.Name)
            local okKids, kids = pcall(function() return anc:GetChildren() end)
            if okKids and kids then
                for _, k in ipairs(kids) do
                    if k ~= m then
                        local okv, isv = pcall(function() return k:IsA("ValueBase") end)
                        if okv and isv then scanKV(info, k.Name, k.Value) end
                    end
                end
            end
            anc = anc.Parent
        end

        local desc = m:GetDescendants()
        for _, d in ipairs(desc) do
            local ok, attrs = pcall(function() return d:GetAttributes() end)
            if ok and attrs then
                for k, v in pairs(attrs) do
                    local kk = tostring(k):lower()
                    if kk:find("rarity", 1, true) or kk:find("tier", 1, true) or kk:find("grade", 1, true)
                        or kk:find("progression", 1, true) or kk:find("chance", 1, true)
                        or kk:find("weight", 1, true) or kk:find("event", 1, true)
                        or kk:find("image", 1, true) or kk:find("icon", 1, true) or kk:find("texture", 1, true)
                        or kk:find("value", 1, true) or kk:find("price", 1, true) or kk:find("income", 1, true) then
                        scanKV(info, k, v)
                    end
                end
            end
        end

        local bestName = nil
        for _, d in ipairs(desc) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                local txt = d.Text
                if txt and txt ~= "" then
                    info.texts[#info.texts + 1] = d.Name .. "=" .. txt
                    local nl = d.Name:lower()
                    local tl = txt:lower()

                    if nl:find("rarity", 1, true) or nl:find("tier", 1, true) or nl:find("grade", 1, true) then
                        local r = rarityOf(txt)
                        if r > info.rar then info.rar = r end
                    end

                    if nl:find("chance", 1, true) or nl:find("odds", 1, true) or nl:find("luck", 1, true) or tl:find("1 in", 1, true) then
                        local c = parseChance(txt)
                        if c and c > info.chance then info.chance = c end
                    end
                    local kg = txt:match("([%d%.]+)%s*[kKmM]?%s*kg")
                    if kg then
                        local n = parseValue(kg)
                        if n and n > info.weight then info.weight = n end
                    elseif nl:find("weight", 1, true) or nl:find("mass", 1, true) then
                        local n = parseValue(txt)
                        if n and n > info.weight then info.weight = n end
                    end
                    if nl:find("value", 1, true) or nl:find("price", 1, true) or nl:find("worth", 1, true)
                        or nl:find("income", 1, true) or nl:find("second", 1, true)
                        or tl:find("value", 1, true) or tl:find("coins", 1, true) then
                        local v = parseValue(txt)
                        if v and v > info.val then info.val = v end
                    end
                    if nl:find("progression", 1, true) or nl:find("level", 1, true) or nl:find("stage", 1, true) then
                        local n = tonumber(txt:match("%d+"))
                        if n and n > info.prog then info.prog = n end
                    end
                    if nl:find("name", 1, true) or nl == "title" or nl:find("eggname", 1, true) then
                        if #txt > 1 and #txt < 40 and not looksLikeStat(txt) then bestName = bestName or txt end
                    end
                    if not info.event and #tl < 40 then
                        if tl:find("night", 1, true) or tl:find("event egg", 1, true)
                            or tl:find("limited", 1, true) or tl:find("spawn khusus", 1, true) then
                            info.event = true
                        end
                    end
                end
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                local id = assetIdOf(d.Image)
                if id and not info.imageId then info.imageId = id end
            elseif d:IsA("Decal") or d:IsA("Texture") then
                local id = assetIdOf(d.Texture)
                if id and not info.imageId then info.imageId = id end
            elseif d:IsA("ValueBase") then
                scanKV(info, d.Name, d.Value)
            end
        end

        if bestName then info.name = bestName end
        if genericEggName(info.name) then
            local th = cleanEggName(theme)
            if not genericEggName(th) then info.name = th end
        end
        if info.name == "" then
            info.name = "Egg" .. (info.prog > 0 and (" #" .. tostring(info.prog)) or "")
        end

        local nm = tostring(info.name):lower()
        if not info.event and (nm:find("night", 1, true) or nm:find("limited", 1, true)
            or nm:find("event", 1, true) or nm:find("special", 1, true)) then
            info.event = true
        end
        if info.rar == 0 then
            local r = rarityFromText(info.name)
            if r > 0 then info.rar = r end
        end
        if info.prog == 0 and type(info.theme) == "string" then
            info.prog = THEME_PROG[string.lower(info.theme)] or 0
        end

        -- Katalog client (ReplicatedStorage.Directory._Index) adalah sumber paling
        -- akurat untuk rarity/value/weight. Probe Record sudah terbukti selalu nil.
        local function applyCatalog(name)
            if type(name) ~= "string" or name == "" then return end
            local rawKey = string.lower(name)
            local cmpKey = catalog.compactKey(name)
            local e = catalog.byKey[rawKey] or catalog.byKey[cmpKey]
            if not e then
                for _, ent in ipairs(catalog.entries) do
                    if ent.keys and (ent.keys[rawKey] or ent.keys[cmpKey]) then
                        e = ent
                        break
                    end
                end
            end
            if not e then return end
            if info.name == "" and not genericEggName(e.name) then info.name = e.name end
            if e.rar > info.rar then info.rar = e.rar end
            if e.prog > info.prog then info.prog = e.prog end
            if e.val > info.val then info.val = e.val end
            if e.weight > info.weight then info.weight = e.weight end
            if e.chance > info.chance then info.chance = e.chance end
            if e.imageId and not info.imageId then info.imageId = e.imageId end
            if e.event then info.event = true end
        end
        applyCatalog(info.name)
        applyCatalog(petDisp)
        applyCatalog(disp)
        applyCatalog(modelName)
        applyCatalog(theme)
        applyCatalog(m.Name)

        local nd = snapByName[tostring(info.name):lower()]
        if not nd and disp then nd = snapByName[tostring(disp):lower()] end
        if not nd and theme then nd = snapByName[tostring(theme):lower()] end
        if nd then scanTable(info, nd, 0) end

        -- Dari atribut PetDisplayName/DisplayName kita tahu kategori egg-nya.
        -- Simpan supaya ClaimFeedback / Probe Record bisa mengisi rarity + value.
        if eggUid and not genericEggName(info.name) and not uidCategory[eggUid] then
            uidCategory[eggUid] = string.lower(info.name)
        end
        if eggUid then applyMeta(eggUid) end
        if info.name == "" then info.name = "Egg" .. (info.prog > 0 and (" #" .. tostring(info.prog)) or "") end
        if info.rar == 0 and info.name ~= "" then info.rar = rarityFromText(info.name) end

        return info
    end

    local infoCache = setmetatable({}, { __mode = "k" })
    local function eggInfoCached(m)
        local c = infoCache[m]
        if c and (os.clock() - c.at) < 4 then return c.info end
        local info = eggInfo(m)
        infoCache[m] = { at = os.clock(), info = info }
        return info
    end

    local function eggPos(m)
        local h = m:FindFirstChild("Hitbox", true)
        if h and h:IsA("BasePart") then return h.Position end
        local ok, cf = pcall(function() return m:GetPivot() end)
        if ok and cf then return cf.Position end
        local p = m:FindFirstChildWhichIsA("BasePart", true)
        return p and p.Position or nil
    end

    local function nearestArea(pos)
        local best, bd = 1, math.huge
        for i, a in ipairs(AREAS) do
            local d = distXZ(pos, a[2])
            if d < bd then best, bd = i, d end
        end
        return best, bd
    end

    -- Kumpulan model egg di-cache. Dulu areaEggs() menyusuri seluruh pohon
    -- AreaEggSlotsClient setiap dipanggil (home/gallery/steal/auto-area).
    local eggCache = { at = -1e9, folder = nil, all = {}, byModel = setmetatable({}, { __mode = "k" }), conns = {} }

    local function cachedEggEntry(m, pos)
        local e = eggCache.byModel[m]
        if not e then
            e = { m = m }
            eggCache.byModel[m] = e
        end
        local uid = guidOf(m.Name)
        e.pos = pos
        e.uid = uid and string.lower(uid) or nil
        e.areaId = m:GetAttribute("AreaId")
        return e
    end

    local function collectEggModels(container, out, depth)
        if not container or (depth or 0) > 6 then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Folder") then
                collectEggModels(child, out, depth + 1)
            elseif child:IsA("Model") then
                local isEgg = child.Name:find("AreaEgg", 1, true)
                    or child:FindFirstChild("Hitbox", true)
                    or child:GetAttribute("EggTheme")
                    or child:GetAttribute("ProgressionOrder")
                    or child:GetAttribute("DisplayName")
                if isEgg then
                    local pos = eggPos(child)
                    if pos then out[#out + 1] = cachedEggEntry(child, pos) end
                else
                    collectEggModels(child, out, depth + 1)
                end
            end
        end
    end

    local function rebuildEggCache(folder)
        if eggCache.folder ~= folder then
            for _, c in ipairs(eggCache.conns) do pcall(function() c:Disconnect() end) end
            eggCache.conns = {}
            eggCache.folder = folder
            eggCache.byModel = setmetatable({}, { __mode = "k" })
            pcall(function()
                eggCache.conns[#eggCache.conns + 1] = folder.DescendantAdded:Connect(function() eggCache.at = -1e9 end)
                eggCache.conns[#eggCache.conns + 1] = folder.DescendantRemoving:Connect(function() eggCache.at = -1e9 end)
            end)
        end
        local all = {}
        collectEggModels(folder, all, 0)
        eggCache.all = all
        eggCache.at = os.clock()
    end

    local function eggAreaIndex(e)
        local aid = e.areaId or (e.uid and uidArea[e.uid])
        if type(aid) == "string" then
            for i, a in ipairs(AREAS) do
                if string.lower(a[1]) == string.lower(aid) then return i, 0 end
            end
        end
        return nearestArea(e.pos)
    end

    local function areaEggs(forceAll)
        local folder = workspace:FindFirstChild("AreaEggSlotsClient")
        if not folder then return {} end
        if eggCache.folder ~= folder or os.clock() - eggCache.at > 1.5 then
            rebuildEggCache(folder)
        end
        local out = eggCache.all
        if forceAll or state.allAreas then return out end
        local filtered = {}
        for _, e in ipairs(out) do
            if eggAreaIndex(e) == state.area then filtered[#filtered + 1] = e end
        end
        return filtered
    end

    -- Reset cache info tanpa membuat table metatable baru tiap kali event masuk.
    local function clearInfoCache()
        infoCache = setmetatable({}, { __mode = "k" })
        for _, e in ipairs(eggCache.all) do e.info = nil end
    end

    local function passFilter(info)
        if state.strict then
            if state.minRar > 1 and (info.rar == 0 or info.rar < state.minRar) then return false end
            if state.minProg > 1 and (info.prog == 0 or info.prog < PROG_STEPS[state.minProg]) then return false end
            if state.minVal > 1 and (info.val == 0 or info.val < VALUE_STEPS[state.minVal]) then return false end
        else
            -- Data yang tidak tersedia TIDAK boleh membuat egg ditolak.
            if state.minRar > 1 and info.rar > 0 and info.rar < state.minRar then return false end
            if state.minProg > 1 and info.prog > 0 and info.prog < PROG_STEPS[state.minProg] then return false end
            if state.minVal > 1 and info.val > 0 and info.val < VALUE_STEPS[state.minVal] then return false end
        end
        return true
    end

    local function eggScore(e, sort, rootPos)
        local i = e.info or {}
        local d = rootPos and (e.pos - rootPos).Magnitude or 0
        local themed = i.themed and 1 or 0
        local event = i.event and 1 or 0
        local chance = i.chance or 0
        local val = i.val or 0
        local rar = i.rar or 0
        local prog = i.prog or 0
        local weight = i.weight or 0
        local chanceScore = chance > 0 and (1 / chance) or 0
        if sort == 1 then
            -- Auto: egg event/night dulu, lalu rarity, progression, chance, value, berat.
            return event * 1e21
                + rar * 1e18
                + prog * 1e12
                + chanceScore * 1e9
                + math.min(val, 1e9)
                + weight * 1e3
                + themed * 1e6
        elseif sort == 2 then
            return rar * 1e18 + event * 1e15 + prog * 1e9 + math.min(val, 1e9)
        elseif sort == 3 then
            return val * 1e6 + rar * 1e3 + prog + event * 1e12
        elseif sort == 4 then
            return prog * 1e12 + rar * 1e6 + math.min(val, 1e9) + event * 1e18
        elseif sort == 5 then
            return -d
        else
            return weight * 1e9 + math.min(val, 1e9) + rar * 1e3 + prog
        end
    end

    local lastFilterLog, lastFallbackLog, lastDataWarn = 0, 0, 0

    local function pickBest(eggs, silent)
        local r = getRoot()
        local rp = r and r.Position
        local filtered = {}
        local hasRar, hasVal, hasProg, hasAny = false, false, false, false
        for _, e in ipairs(eggs) do
            e.info = e.info or eggInfoCached(e.m)
            local i = e.info
            if i.rar > 0 then hasRar = true end
            if i.val > 0 then hasVal = true end
            if i.prog > 0 then hasProg = true end
            if i.rar > 0 or i.val > 0 or i.prog > 0 or i.chance > 0 or i.weight > 0 then hasAny = true end
            if passFilter(i) then filtered[#filtered + 1] = e end
        end

        if not silent and os.clock() - lastDataWarn > 15 then
            local miss = {}
            if state.minRar > 1 and not hasRar then miss[#miss + 1] = "rarity" end
            if state.minVal > 1 and not hasVal then miss[#miss + 1] = "value" end
            if not hasAny then
                lastDataWarn = os.clock()
                log("Data " .. AREAS[state.area][1] .. " belum terbaca (" .. #eggs .. " egg). Ambil 1 egg dulu supaya Claim Feedback/CarryState mengisi nama + rarity, lalu Muat Ulang galeri.")
            elseif #miss > 0 then
                lastDataWarn = os.clock()
                log("Data " .. table.concat(miss, "/") .. " tidak tersedia -> filter itu diabaikan. Pakai Min Progression.")
            end
        end

        local useList = filtered
        if #useList == 0 then
            if state.fallback then
                useList = eggs
                for _, e in ipairs(useList) do e.info = e.info or eggInfoCached(e.m) end
                if not silent and os.clock() - lastFallbackLog > 8 then
                    lastFallbackLog = os.clock()
                    local reason = state.strict and "Filter ketat menolak semua" or "Filter tidak menemukan kandidat"
                    log(reason .. " -> fallback ke semua egg.")
                end
            else
                if not silent and os.clock() - lastFilterLog > 8 then
                    lastFilterLog = os.clock()
                    log("Best Egg: tidak ada yang lolos filter. Turunkan Min / aktifkan Fallback.")
                end
                return nil, #filtered
            end
        end

        local best, bs, bd
        for _, e in ipairs(useList) do
            local s = eggScore(e, state.sort, rp)
            local d = rp and (e.pos - rp).Magnitude or 0
            if not bs or s > bs or (s == bs and d < (bd or math.huge)) then
                best, bs, bd = e, s, d
            end
        end
        return best, #filtered
    end

    --[[ ===================== 10. KATALOG REPLICATEDSTORAGE ===================== ]]
    -- Metadata egg (rarity/value/weight/progression) ada di module client:
    --   ReplicatedStorage.Directory._Index.<NamaPet>
    --   ReplicatedStorage.Directory.Rarity._Index.<NamaTier>
    -- Jadi tidak perlu menebak argumen RequestEggRecord yang selalu nil.
    -- Semua helper dibungkus blok `do` supaya tidak menambah local di boot
    -- (luac/Luau punya batas 200 local per function).
    do
        local function safeRequireModule(mod)
            local co = coroutine.create(function()
                return require(mod)
            end)
            local ok, res = coroutine.resume(co)
            if coroutine.status(co) == "suspended" then return false, "yield" end
            return ok, res
        end

        local function addCatalogKeys(out, s)
            if type(s) ~= "string" then return end
            s = s:gsub("^%s+", ""):gsub("%s+$", "")
            if s == "" or genericEggName(s) then return end
            local raw = string.lower(s)
            out[raw] = true
            local c = catalog.compactKey(s)
            if c then out[c] = true end
        end

        local function catalogInfoFromData(mod, data)
            local info = {
                name = tostring(mod.Name),
                theme = nil,
                prog = 0,
                themed = false,
                event = false,
                weight = 0,
                imageId = nil,
                rar = 0,
                rarNum = 0,
                val = 0,
                chance = 0,
                texts = {},
                attrs = {},
                source = "catalog",
            }
            pcall(scanTable, info, data, 0)
            if genericEggName(info.name) then info.name = tostring(mod.Name) end
            if info.rar == 0 then info.rar = rarityFromText(info.name) end

            local keys = {}
            addCatalogKeys(keys, mod.Name)
            addCatalogKeys(keys, info.name)
            for _, f in ipairs({ "PetDisplayName", "DisplayName", "Name", "AssetCategory", "Category", "_id" }) do
                -- Beberapa modul memakai registry dengan __index ketat; indeks
                -- field yang tidak ada harus di-pcall supaya tidak menggagalkan
                -- seluruh pembacaan katalog.
                local okF, v = pcall(function() return data[f] end)
                if okF and type(v) == "string" then addCatalogKeys(keys, v) end
            end
            info.keys = keys
            return info, keys
        end

        local function catalogDir()
            local rs = ReplicatedStorage
            return rs:FindFirstChild("Directory") or rs:FindFirstChild("Directory", true)
        end

        local function skipCatalogKey(k)
            return k == "BaseConfigs" or k == "Types" or k == "Interface" or k == "Schema"
                or k == "Private" or k == "_Index" or k == "Default"
        end

        local function storeCatalogEntry(name, data, verbose)
            local info, keys = catalogInfoFromData({ Name = name }, data)
            for _, k in pairs(keys) do
                if not catalog.byKey[k] then catalog.keyCount = catalog.keyCount + 1 end
                catalog.byKey[k] = info
            end
            catalog.entries[#catalog.entries + 1] = info
            return info, keys
        end

        -- Assets / BaseConfigs.Default sering berisi tabel keyed by nama pet,
        -- bukan ModuleScript per pet. Baca juga isinya supaya pet baru ikut masuk.
        local function readCatalogTables(verbose)
            local dir = catalogDir()
            if not dir then return 0 end
            local n = 0
            for _, modName in ipairs({ "Assets", "BaseConfigs.Default" }) do
                local mod = dir:FindFirstChild(modName, true)
                if mod and mod:IsA("ModuleScript") then
                    local ok, data = safeRequireModule(mod)
                    if ok and type(data) == "table" then
                        for k, v in pairs(data) do
                            if type(k) == "string" and type(v) == "table" and not skipCatalogKey(k) then
                                storeCatalogEntry(k, v, verbose)
                                n = n + 1
                            end
                        end
                        for key, v in pairs(data) do
                            if type(key) == "string" and type(v) == "table" and key == "_Index" then
                                for k, sub in pairs(v) do
                                    if type(k) == "string" and type(sub) == "table" and not skipCatalogKey(k) then
                                        storeCatalogEntry(k, sub, verbose)
                                        n = n + 1
                                    end
                                end
                            end
                        end
                        if verbose then
                            log("CATALOG TABLE " .. modName .. ": " .. ser(data):sub(1, 900))
                        end
                    end
                end
            end
            return n
        end

        local function readRarityModule(verbose)
            local dir = catalogDir()
            local mod = dir and dir:FindFirstChild("Rarity", true)
            if not mod or not mod:IsA("ModuleScript") then
                if verbose then log("Katalog rarity: module tidak ada.") end
                return
            end
            local ok, data = safeRequireModule(mod)
            catalog.rarRaw = ok and data or nil
            if verbose then
                log("RARITY MODULE: " .. (ok and ser(data):sub(1, 1200) or tostring(data)))
            end
            if not ok or type(data) ~= "table" then return end

            -- RarityNumber dari game adalah urutan resmi. Pakai itu, bukan tebakan
            -- common/uncommon/rare yang sebelumnya dipakai script.
            local rarities = data.Rarities
            if type(rarities) ~= "table" then return end
            catalog.rarityNumber = {}
            local maxNum = 0
            for k, v in pairs(rarities) do
                if type(v) == "table" then
                    local num = tonumber(v.RarityNumber)
                    if num and num > 0 then
                        local label = tostring(v.DisplayName or v._id or k)
                        catalog.rarityNumber[string.lower(k)] = num
                        catalog.rarityNumber[catalog.compactKey(k)] = num
                        catalog.rarityNumber[string.lower(label)] = num
                        catalog.rarityNumber[catalog.compactKey(label)] = num
                        catalog.rarityLabel[num] = label
                        if num > maxNum then maxNum = num end
                    end
                end
            end
            for i = #RARITY + 1, maxNum do
                RARITY[i] = "tier" .. i
                RARITY_COLOR[i] = RARITY_COLOR[#RARITY_COLOR] or Color3.fromRGB(255, 255, 255)
                RARITY_LABEL[i] = catalog.rarityLabel[i] or ("Tier " .. i)
                RARITY_NAMES[i] = (catalog.rarityLabel[i] or ("Tier " .. i)) .. "+"
            end
            if verbose then
                log("RARITY NUMBER: " .. maxNum .. " tier terdaftar.")
            end
        end

        local function applyCatalogToMaps()
            for key, e in pairs(catalog.byKey) do
                if e.rar > (categoryRarity[key] or 0) then categoryRarity[key] = e.rar end
                if e.prog > (categoryProg[key] or 0) then categoryProg[key] = e.prog end
                if e.val > (categoryValue[key] or 0) then categoryValue[key] = e.val end
                if e.weight > (categoryWeight[key] or 0) then categoryWeight[key] = e.weight end
                if e.chance > (categoryChance[key] or 0) then categoryChance[key] = e.chance end
                if e.imageId and not categoryImage[key] then categoryImage[key] = e.imageId end
            end
        end

        local function doReadCatalog(verbose)
            if not verbose and catalog.count > 0 and os.clock() - catalog.at < 45 then
                return catalog.count
            end

            local dir = catalogDir()
            local idx = dir and dir:FindFirstChild("_Index", true)
            if not idx then
                if verbose then log("Katalog tidak ada: ReplicatedStorage.Directory._Index.") end
                catalog.at = os.clock()
                return 0
            end

            local n, errN, tried = 0, 0, 0
            catalog.byKey = {}
            catalog.entries = {}
            catalog.keyCount = 0
            local okRarity, errRarity = pcall(readRarityModule, verbose)
            if not okRarity and verbose then log("RARITY error: " .. tostring(errRarity)) end

            local okTables, resTables = pcall(readCatalogTables, verbose)
            if okTables then
                n = n + resTables
            elseif verbose then
                log("CATALOG TABLE error: " .. tostring(resTables))
            end

            for _, mod in ipairs(idx:GetChildren()) do
                if mod:IsA("ModuleScript") then
                    tried = tried + 1
                    local ok, data = safeRequireModule(mod)
                    if verbose and tried <= 3 then
                        log("CATALOG " .. mod.Name .. " [" .. tostring(ok) .. "]: "
                            .. (ok and ser(data):sub(1, 700) or tostring(data)))
                    end
                    if ok and type(data) == "table" then
                        local okEntry, info, keys = pcall(catalogInfoFromData, mod, data)
                        if okEntry then
                            local added = 0
                            for _, k in pairs(keys) do
                                if not catalog.byKey[k] then catalog.keyCount = catalog.keyCount + 1 end
                                catalog.byKey[k] = info
                                added = added + 1
                            end
                            if verbose and tried <= 3 then
                                log("CATALOG KEYS " .. mod.Name .. ": +" .. added .. " " .. ser(keys))
                            end
                            info.keys = keys
                            catalog.entries[#catalog.entries + 1] = info
                            n = n + 1
                        else
                            errN = errN + 1
                        end
                    else
                        errN = errN + 1
                    end
                end
            end

            catalog.at = os.clock()
            catalog.count = n
            catalog.err = errN
            applyCatalogToMaps()
            galleryDirty = true
            gallerySig = ""

            if verbose then
                log("Katalog entri: " .. #catalog.entries)
                log(string.format("Katalog dibaca: %d modul, %d gagal dari %d dicoba, %d kunci.",
                    n, errN, tried, catalog.keyCount))
            end
            return n
        end

        catalog.read = function(verbose)
            local ok, res = pcall(doReadCatalog, verbose)
            if not ok then
                log("Katalog error: " .. tostring(res))
                return 0
            end
            return res
        end
    end
    --[[ ===================== 10. BASE & AREA ===================== ]]
    local savedBase = nil
    do
        local b = envGet("BFE_V5_Base")
        if typeof(b) == "Vector3" then savedBase = b end
    end
    local startBase = (function()
        local r = getRoot()
        return r and r.Position or nil
    end)()
    local baseCache = { at = -1e9, value = nil, src = nil }
    task.spawn(function()
        local t0 = os.clock()
        while running and not startBase and os.clock() - t0 < 60 do
            local r = getRoot()
            if r then startBase = r.Position; break end
            task.wait(0.5)
        end
    end)

    local function plotBase()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            if sign then
                for _, d in ipairs(sign:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text ~= "" then
                        local hit = d.Text:find(lp.Name, 1, true)
                        if not hit and lp.DisplayName and lp.DisplayName ~= "" then
                            hit = d.Text:find(lp.DisplayName, 1, true)
                        end
                        if hit then
                            local sp = plot:FindFirstChild("SpawnPoint")
                            if sp and sp:IsA("BasePart") then return sp.Position end
                            local ok, cf = pcall(function() return plot:GetPivot() end)
                            if ok and cf then return cf.Position end
                        end
                    end
                end
            end
        end
        return nil
    end

    local function basePos(force)
        local now = os.clock()
        if not force and baseCache.value and (now - baseCache.at) < 5 then
            return baseCache.value, baseCache.src
        end
        local value, src
        if savedBase then
            value, src = savedBase, "manual"
        else
            local folder = workspace:FindFirstChild("PlacedEggRenders")
            if folder then
                local prefix = tostring(lp.UserId) .. "_"
                local sum, n = Vector3.new(0, 0, 0), 0
                for _, m in ipairs(folder:GetChildren()) do
                    if tostring(m.Name):sub(1, #prefix) == prefix then
                        local pos = eggPos(m)
                        if pos then
                            sum = sum + pos
                            n = n + 1
                        end
                    end
                end
                if n > 0 then value, src = sum / n, "egg" end
            end
            if not value then
                local pb = plotBase()
                if pb then value, src = pb, "plot" end
            end
            if not value then value, src = startBase, "posisi awal" end
        end
        baseCache.at, baseCache.value, baseCache.src = now, value, src
        return value, src
    end

    local function setBaseHere()
        local r = getRoot()
        if not r then return false end
        savedBase = r.Position
        envSet("BFE_V5_Base", savedBase)
        baseCache.at = -1e9
        log("Base diset: " .. math.floor(r.Position.X) .. ", " .. math.floor(r.Position.Y) .. ", " .. math.floor(r.Position.Z))
        return true
    end

    local areaRefs = {}
    local function setArea(i, silent, manual)
        i = ((i - 1) % #AREAS) + 1
        state.area = i
        -- Dropdown area harus mengunci scope; "Semua Area" tidak boleh menimpa pilihan.
        state.allAreas = false
        if manual then state.autoArea = false end
        for _, w in ipairs(areaRefs) do w:set(i) end
        for _, w in ipairs(toggleRefs.allAreas or {}) do w:set(false) end
        if areaAutoRef then areaAutoRef:set(state.autoArea) end
        galleryDirty = true
        gallerySig = ""
        if not silent then log("Area dipilih: " .. AREAS[i][1]) end
        if updateHome then updateHome() end
        -- Auto area (silent) akan dibangun ulang oleh loop galeri; hindari
        -- 2x rebuild kartu 3D saat boot.
        if not silent and galleryRefresh then pcall(galleryRefresh, true) end
    end

    -- Pilih area yang berisi egg paling bagus (bukan selalu Forest).
    local function pickBestArea(silent)
        local all = areaEggs(true)
        if #all == 0 then return nil end
        local root = getRoot()
        local rp = root and root.Position
        local scoreByArea = {}
        for _, e in ipairs(all) do
            e.info = e.info or eggInfoCached(e.m)
            local ai = eggAreaIndex(e)
            local s = eggScore(e, state.sort, rp)
            if not scoreByArea[ai] or s > scoreByArea[ai] then scoreByArea[ai] = s end
        end
        local best, bs
        for ai, s in pairs(scoreByArea) do
            if not bs or s > bs then best, bs = ai, s end
        end
        if best and best ~= state.area then
            setArea(best, true)
            if not silent then log("Auto pilih area terbaik: " .. AREAS[best][1]) end
        end
        return best
    end

    local function tpArea(i)
        setArea(i)
        teleport(AREAS[state.area][2])
        log("Teleport ke area " .. AREAS[state.area][1])
    end

    --[[ ===================== 11. PROMPTS ===================== ]]
    local function promptPart(p)
        local o = p.Parent
        for _ = 1, 8 do
            if not o or o == workspace then return nil end
            if o:IsA("BasePart") then return o end
            o = o.Parent
        end
        return nil
    end

    -- Satu scan workspace saja untuk hatch/sell DAN SmartPromptPart.
    -- Dulu scanPrompts() dan smartParts() masing-masing memanggil GetDescendants().
    local promptCache = { at = -1e9, hatch = {}, sell = {}, smart = {} }
    local function scanPrompts()
        if os.clock() - promptCache.at < 2 then return end
        promptCache.at = os.clock()
        promptCache.hatch, promptCache.sell, promptCache.smart = {}, {}, {}
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled then
                local at = string.lower(d.ActionText or "")
                local target = nil
                if at:find("hatch", 1, true) then target = promptCache.hatch
                elseif at:find("sell", 1, true) then target = promptCache.sell end
                if target then
                    local part = promptPart(d)
                    if part then target[#target + 1] = { prompt = d, part = part } end
                end
            elseif d.Name == "SmartPromptPart" and d:IsA("BasePart") then
                promptCache.smart[#promptCache.smart + 1] = d
            end
        end
    end

    local function nearestPrompt(list)
        local r = getRoot()
        if not r then return nil end
        local best, bd
        for _, it in ipairs(list) do
            local d = (it.part.Position - r.Position).Magnitude
            if not bd or d < bd then best, bd = it, d end
        end
        return best
    end

    local function smartParts()
        scanPrompts()
        return promptCache.smart
    end

    local function carryPrompt()
        local r = getRoot()
        if not r then return nil end
        local best, bd
        for _, d in ipairs(smartParts()) do
            local p = d:FindFirstChild("CarryAreaEgg")
            if p and p:IsA("ProximityPrompt") and p.Enabled then
                local dist = (d.Position - r.Position).Magnitude
                if not bd or dist < bd then best, bd = p, dist end
            end
        end
        return best, bd
    end

    local function waitForCarryPrompt(timeout)
        local t0 = os.clock()
        while os.clock() - t0 < timeout do
            local p, d = carryPrompt()
            if p and (d or 9999) < 60 then return p, d end
            task.wait(0.1)
        end
        return carryPrompt()
    end

    local function firePrompt(p, maxDist)
        if not p then return false end
        pcall(function()
            p.HoldDuration = 0
            p.MaxActivationDistance = math.max(p.MaxActivationDistance, maxDist or 100)
        end)
        local ok = false
        if type(fireproximityprompt) == "function" then
            ok = pcall(fireproximityprompt, p)
        end
        if not ok then
            ok = pcall(function()
                p:InputHoldBegin()
                task.wait(0.05)
                p:InputHoldEnd()
            end)
        end
        return ok
    end

    --[[ ===================== 12. STEAL ===================== ]]
    local busy = false
    local stealIdx = 0
    local lastNoEggLog = 0
    local lastPromptLog = 0
    local lastSnapTry = -1e9
    local lastAutoAreaTry = -1e9

    local function nearestSmartPart()
        local r = getRoot()
        if not r then return nil end
        local best, bd
        for _, d in ipairs(smartParts()) do
            local dist = (d.Position - r.Position).Magnitude
            if not bd or dist < bd then best, bd = d, dist end
        end
        return best, bd
    end

    local function doSteal(e, manual)
        if not e then return false end
        local i = e.info or eggInfoCached(e.m)
        local targetUid = e.uid
        local targetArea = AREAS[state.area][1]
        -- Ambil posisi base SEBELUM mendekat, supaya kabur bisa langsung dilakukan.
        local b, baseSrc = basePos()

        local fired, anyPrompt, confirmed = false, false, false
        for attempt = 1, 3 do
            local pos = eggPos(e.m) or e.pos
            -- Dekatkan ke egg asli; jangan fire prompt dari jarak jauh (server menolak).
            teleport(pos + Vector3.new(0, 1, 2))
            task.wait(0.2)

            local p, pd = waitForCarryPrompt(attempt == 1 and 1.0 or 0.5)
            if not p then
                local sp = nearestSmartPart()
                if sp then
                    teleport(sp.Position)
                    task.wait(0.15)
                    p, pd = carryPrompt()
                end
            end
            if not p then break end

            anyPrompt = true
            if pd and pd > 12 then
                local part = p.Parent
                if part and part:IsA("BasePart") then
                    teleport(part.Position)
                    task.wait(0.1)
                end
            end

            local fireAt = os.clock()
            for _ = 1, 3 do
                if not p.Enabled then break end
                if firePrompt(p, 12) then fired = true end
                task.wait(0.1)
            end

            -- PENTING: kabur dulu dari penjaga, baru tunggu konfirmasi server.
            if b then teleport(b) end

            local gotConfirm = false
            local deadline = os.clock() + 0.8
            while os.clock() < deadline do
                task.wait(0.08)
                if carryEventSeen and lastCarry and lastCarry.at >= fireAt - 0.1 then
                    gotConfirm = true
                    break
                end
            end

            if gotConfirm then
                local uidOk = not targetUid or not lastCarry.uid
                    or lastCarry.uid == targetUid
                    or (uidCategory[lastCarry.uid] and uidCategory[targetUid]
                        and uidCategory[lastCarry.uid] == uidCategory[targetUid])
                local areaOk = not lastCarry.area
                    or string.lower(tostring(lastCarry.area)) == string.lower(targetArea)
                if uidOk and areaOk then
                    confirmed = true
                    break
                end
                if os.clock() - lastPromptLog > 4 then
                    lastPromptLog = os.clock()
                    log(string.format("Steal salah target: minta %s di %s, dapat %s di %s. Coba lagi.",
                        tostring(targetUid or i.name):sub(1, 12), targetArea,
                        tostring(lastCarry.uid or "?"):sub(1, 12), tostring(lastCarry.area or "?")))
                end
            elseif not carryEventSeen then
                -- Environment tanpa event CarryState: anggap prompt berhasil.
                confirmed = fired
                break
            elseif os.clock() - lastPromptLog > 4 then
                lastPromptLog = os.clock()
                log("Prompt terkirim, sudah kabur ke base dulu sambil tunggu konfirmasi CarryState.")
            end
        end

        if confirmed then
            log("Prompt CarryAreaEgg berhasil: " .. tostring(i.name) .. " @ " .. targetArea .. ".")
        elseif anyPrompt then
            log("Prompt ditemukan tapi gagal mengambil " .. tostring(i.name) .. ".")
        elseif os.clock() - lastPromptLog > 6 then
            lastPromptLog = os.clock()
            log("Prompt CarryAreaEgg tidak ditemukan (mungkin masih membawa egg).")
        end

        galleryDirty = true
        if b then
            teleport(b)
            log("Kembali ke base" .. (baseSrc and (" (" .. tostring(baseSrc) .. ")") or "") .. ".")
            task.wait(manual and 1.6 or 1.2)
        elseif confirmed then
            log("Base belum diketahui. Buka halaman Area lalu tekan Set Base.")
        end
        return confirmed
    end

    local function stealOne(manual)
        if state.autoArea and os.clock() - lastAutoAreaTry > 12 then
            lastAutoAreaTry = os.clock()
            pcall(pickBestArea, not manual)
        end
        local eggs = areaEggs()
        if #eggs == 0 then
            if os.clock() - lastNoEggLog > 6 then
                lastNoEggLog = os.clock()
                log("Tidak ada egg di AreaEggSlotsClient untuk area " .. AREAS[state.area][1] .. ".")
            end
            return false
        end

        local e
        if state.best then
            if os.clock() - snapAt > 6 and os.clock() - lastSnapTry > 3 then
                lastSnapTry = os.clock()
                if refreshSnapshot(false) then
                    clearInfoCache()
                end
            end
            e = pickBest(eggs)
            if not e then return false end
            local i = e.info
            log(string.format("[Best] %s | rar=%s prog=%s val=%s berat=%s chance=%s%s",
                tostring(i.name), tostring(i.rar), tostring(i.prog), fmtVal(i.val),
                fmtKg(i.weight),
                i.chance > 0 and ("1/" .. fmtVal(i.chance)) or "-",
                i.event and " EVENT" or (i.themed and " themed" or "")))
        else
            stealIdx = (stealIdx % #eggs) + 1
            e = eggs[stealIdx]
            log(string.format("[Rotasi] egg %d/%d %s", stealIdx, #eggs, tostring(e.m.Name):sub(1, 24)))
        end

        return doSteal(e, manual)
    end

    -- Dipakai tombol Steal di kartu halaman Egg.
    local function stealEgg(e)
        if not e then return end
        if busy then
            if ui then ui:toast("Masih sibuk, tunggu sebentar.", "warn") end
            return
        end

        -- Ambil entri terbaru supaya posisi egg tidak basi.
        local fresh
        for _, x in ipairs(areaEggs()) do
            if x.m == e.m or (e.m and x.m.Name == e.m.Name) then fresh = x; break end
        end
        if not fresh then
            if ui then ui:toast("Egg sudah tidak ada. Muat ulang galeri.", "warn") end
            galleryDirty = true
            return
        end
        e = fresh

        busy = true
        local i = e.info or eggInfoCached(e.m)
        if ui then ui:toast("Mengambil " .. tostring(i.name) .. "...") end
        task.spawn(function()
            local ok, err = pcall(doSteal, e, true)
            if not ok then log("ERROR steal egg: " .. tostring(err)) end
            busy = false
            galleryDirty = true
        end)
    end

    --[[ ===================== 12b. DEBUG DATA (SEMUA AREA) ===================== ]]
    local function debugCategoryOf(e, i)
        if not e then return nil end
        local function use(v)
            if type(v) ~= "string" or genericEggName(v) then return nil end
            v = v:gsub("%s*[Ee]gg%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if genericEggName(v) then return nil end
            return string.lower(v)
        end
        local m = e.m
        if m then
            -- Kategori asli: PetDisplayName > DisplayName > PetModelName > EggTheme.
            -- "Egg"/"Egg #n" dibuang supaya probe tidak berubah jadi "cat:egg".
            local c = use(m:GetAttribute("PetDisplayName"))
                or use(m:GetAttribute("DisplayName"))
                or use(m:GetAttribute("PetModelName"))
                or use(m:GetAttribute("EggTheme"))
            if c then return c end
        end
        if e.uid and uidCategory[e.uid] and not genericEggName(uidCategory[e.uid]) then
            return uidCategory[e.uid]
        end
        return use(i and i.name)
    end

    -- Probe RequestEggRecord untuk semua area. Dipanggil otomatis (terbatas) atau manual dari tombol.
    local function debugProbeAll(verbose)
        local eggs = areaEggs(true)
        if #eggs == 0 then
            if verbose then log("PROBE: tidak ada egg di AreaEggSlotsClient.") end
            return 0
        end

        if verbose or os.clock() - probeAt > 45 then
            probeAt = os.clock()
            pcall(catalog.read, verbose)
            pcall(refreshRuntimeSnapshot, false)
        end

        local found, checked = 0, 0
        local limit = verbose and 12 or 6
        for _, e in ipairs(eggs) do
            local i = e.info or eggInfoCached(e.m)
            local uid = e.uid
            local cat = debugCategoryOf(e, i)
            if cat and uid and not genericEggName(cat) then uidCategory[uid] = cat end
            local ai = eggAreaIndex(e)
            local areaName = (AREAS[ai] and AREAS[ai][1]) or AREAS[state.area][1]
            if probeRecord(uid, cat, areaName, verbose, e.m and e.m.Name or nil) then found = found + 1 end
            checked = checked + 1
            if checked >= limit then break end
        end

        -- Uid asli yang dikirim StealTargetEvent bukan "AreaEgg_<guid>"; coba itu juga.
        local hintN = 0
        for hint in pairs(assetUidHints) do
            hintN = hintN + 1
            if hintN > 3 then break end
            if probeRecord(guidOf(hint), nil, nil, verbose, hint) then found = found + 1 end
        end

        clearInfoCache()
        galleryDirty = true
        gallerySig = ""
        if verbose then
            log(string.format("PROBE selesai: %d egg dicek, %d record ketemu. %s",
                checked, found, debugSummary()))
            log("Uid asli dari event: " .. hintN)
            if galleryRefresh then pcall(galleryRefresh, true) end
        end
        return found
    end

    local function debugDumpAll()
        pcall(catalog.read, false)
        local eggs = areaEggs(true)
        log("== DEBUG SEMUA AREA: " .. #eggs .. " egg ==")
        for idx, e in ipairs(eggs) do
            if idx > 20 then log("... dipotong (20 pertama)"); break end
            local i = e.info or eggInfoCached(e.m)
            local ai = eggAreaIndex(e)
            log(string.format("#%d [%s] %s | uid=%s cat=%s rar=%s val=%s kg=%s prog=%s",
                idx, AREAS[ai][1], tostring(i.name),
                tostring(e.uid or "-"):sub(1, 12),
                tostring(debugCategoryOf(e, i) or "-"),
                tostring(i.rar), fmtVal(i.val), fmtKg(i.weight), tostring(i.prog)))
        end
        log("DEBUG CACHE: " .. debugSummary())
    end
    --[[ ===================== 13. UI BOOT ===================== ]]
    ui = BFEUI.new({
        title = "Bike For Eggs",
        subtitle = "Mobile - Sidebar Edition v5",
        icon = "🥚",
        onDestroy = function()
            running = false
            envSet("BFE_V5_Running", nil)
        end,
    })

    local function bind(key, widget)
        toggleRefs[key] = toggleRefs[key] or {}
        toggleRefs[key][#toggleRefs[key] + 1] = widget
    end
    local function setFlag(key, v)
        state[key] = v and true or false
        for _, w in ipairs(toggleRefs[key] or {}) do w:set(state[key]) end
        if key == "autoArea" and state.autoArea then
            state.allAreas = false
            for _, w in ipairs(toggleRefs.allAreas or {}) do w:set(false) end
            pcall(pickBestArea, false)
        end
        ui:setActive(state.steal)
        if updateHome then updateHome() end
    end

    local function tpBase()
        local b, src = basePos(true)
        if b then
            teleport(b)
            log("TP ke base (" .. tostring(src) .. ").")
        else
            ui:toast("Base belum diketahui. Tekan Set Base dulu.", "warn")
        end
    end

    local function manualSteal()
        if busy then
            ui:toast("Masih sibuk, tunggu sebentar.", "warn")
            return
        end
        busy = true
        task.spawn(function()
            local ok, err = pcall(stealOne, true)
            if not ok then log("ERROR manual steal: " .. tostring(err)) end
            busy = false
        end)
    end

    --[[ ===================== 14. HOME PAGE ===================== ]]
    local pgHome = ui:page("home", "Utama", "🏠")
    pgHome:section("Status")
    local homeStatus = pgHome:card({
        {"Steal", "-"},
        {"Hatch", "-"},
        {"Sell", "-"},
        {"Area", "-"},
        {"Base", "-"},
        {"Egg area", "-"},
        {"Kandidat", "-"},
    })

    pgHome:section("Kontrol Cepat")
    local homeSteal = pgHome:toggle("Auto Steal Egg", state.steal, function(v) setFlag("steal", v) end)
    bind("steal", homeSteal)
    local homeBest = pgHome:toggle("Pilih Egg Terbaik", state.best, function(v) setFlag("best", v) end)
    bind("best", homeBest)
    local homeHatch = pgHome:toggle("Auto Hatch", state.hatch, function(v) setFlag("hatch", v) end)
    bind("hatch", homeHatch)
    local homeSell = pgHome:toggle("Auto Sell Pets", state.sell, function(v) setFlag("sell", v) end)
    bind("sell", homeSell)

    pgHome:buttonRow({
        { text = "TP Area", callback = function() tpArea(state.area) end },
        { text = "TP Base", callback = tpBase },
        { text = "Ambil 1x", callback = manualSteal, variant = "primary" },
    })
    pgHome:note("Aktifkan Auto Steal lalu atur Best Egg di halaman Filter. Kalau filter terlalu ketat, script otomatis fallback (bisa dimatikan).")

    --[[ ===================== 15. STEAL PAGE ===================== ]]
    local pgSteal = ui:page("steal", "Steal", "🥚")
    pgSteal:section("Auto Steal")
    local stealToggle = pgSteal:toggle("Auto Steal Egg", state.steal, function(v) setFlag("steal", v) end)
    bind("steal", stealToggle)
    local bestToggle = pgSteal:toggle("Pilih Egg Terbaik (Best Egg)", state.best, function(v) setFlag("best", v) end)
    bind("best", bestToggle)
    local bestDrop = pgSteal:dropdown("Mode ambil", {"Bergiliran", "Terbaik (Best)"}, state.best and 2 or 1, function(_, idx)
        setFlag("best", idx == 2)
    end)
    bind("best", { set = function(v) bestDrop:set(v and 2 or 1) end })

    local areaDropSteal = pgSteal:dropdown("Area target", AREA_NAMES, state.area, function(_, idx) setArea(idx, false, true) end)
    areaRefs[#areaRefs + 1] = areaDropSteal
    pgSteal:button("Pilih Area Terbaik", function() pcall(pickBestArea, false) end)

    pgSteal:stepper("Jeda setelah steal", 0.2, 3.0, 0.1, state.stealDelay, function(v)
        state.stealDelay = v
    end, function(v) return string.format("%.1fs", v) end)

    pgSteal:button("Ambil 1x Sekarang", manualSteal, { variant = "primary" })
    pgSteal:note("Kalau 'Pilih Egg Terbaik' ON, script memilih egg dengan skor tertinggi sesuai halaman Filter. Kalau OFF, egg diambil bergiliran.")

    --[[ ===================== 16. AUTO PAGE ===================== ]]
    local pgAuto = ui:page("auto", "Auto", "⚙️")
    pgAuto:section("Auto Hatch")
    local hatchToggle = pgAuto:toggle("Auto Hatch", state.hatch, function(v) setFlag("hatch", v) end)
    bind("hatch", hatchToggle)
    pgAuto:stepper("Jeda hatch", 0.5, 5.0, 0.1, state.hatchDelay, function(v)
        state.hatchDelay = v
    end, function(v) return string.format("%.1fs", v) end)

    pgAuto:divider()
    pgAuto:section("Auto Sell")
    local sellToggle = pgAuto:toggle("Auto Sell Pets", state.sell, function(v) setFlag("sell", v) end)
    bind("sell", sellToggle)
    pgAuto:stepper("Jeda sell", 0.5, 5.0, 0.1, state.sellDelay, function(v)
        state.sellDelay = v
    end, function(v) return string.format("%.1fs", v) end)

    pgAuto:note("Hatch memakai prompt yang mengandung 'Hatch'. Sell memakai prompt yang mengandung 'Sell'. Prompt dicari ulang tiap 2 detik.")

    --[[ ===================== 17. FILTER PAGE ===================== ]]
    local function testFilter()
        task.spawn(function()
            if os.clock() - snapAt > 4 then
                if refreshSnapshot(false) then
                    clearInfoCache()
                end
            end
            local eggs = areaEggs()
            if #eggs == 0 then
                ui:toast("Tidak ada egg di area ini.", "warn")
                return
            end
            local r = getRoot()
            local rp = r and r.Position
            local rows = {}
            for _, e in ipairs(eggs) do
                e.info = e.info or eggInfoCached(e.m)
                rows[#rows + 1] = { e = e, s = eggScore(e, state.sort, rp) }
            end
            table.sort(rows, function(a, b) return a.s > b.s end)
            log("== TES FILTER: " .. #eggs .. " egg | urut " .. SORTS[state.sort] .. " ==")
            for idx = 1, math.min(8, #rows) do
                local e = rows[idx].e
                local i = e.info
                local pass = passFilter(i)
                log(string.format("#%d %s | rar=%s prog=%s val=%s berat=%s chance=%s%s | %s",
                    idx, tostring(i.name), tostring(i.rar), tostring(i.prog), fmtVal(i.val),
                    fmtKg(i.weight),
                    i.chance > 0 and ("1/" .. fmtVal(i.chance)) or "-",
                    i.event and " EVENT" or (i.themed and " themed" or ""),
                    pass and "LOLOS" or "TOLAK"))
            end
            local best = pickBest(eggs, true)
            if best then
                ui:toast("Best: " .. tostring(best.info.name))
            else
                ui:toast("Tidak ada kandidat. Cek filter / fallback.", "warn")
            end
        end)
    end

    local function scanInfo()
        task.spawn(function()
            local eggs = areaEggs()
            if #eggs == 0 then
                ui:toast("Tidak ada egg di area ini.", "warn")
                return
            end
            local r = getRoot()
            local rp = r and r.Position
            table.sort(eggs, function(a, b)
                local da = rp and (a.pos - rp).Magnitude or 0
                local db = rp and (b.pos - rp).Magnitude or 0
                return da < db
            end)
            log("== SCAN " .. math.min(#eggs, 6) .. " egg terdekat ==")
            for i = 1, math.min(#eggs, 6) do
                local info = eggInfo(eggs[i].m)
                log(string.format("#%d %s | rar=%s prog=%s val=%s berat=%s%s",
                    i, tostring(info.name), tostring(info.rar), tostring(info.prog),
                    fmtVal(info.val), fmtKg(info.weight), info.event and " EVENT" or (info.themed and " themed" or "")))
                log("   attr: " .. table.concat(info.attrs, ", "):sub(1, 300))
                log("   teks: " .. table.concat(info.texts, " | "):sub(1, 300))
            end
        end)
    end

    local pgFilter = ui:page("filter", "Filter", "🎯")
    pgFilter:section("Best Egg")
    local filterBest = pgFilter:toggle("Aktifkan Best Egg", state.best, function(v) setFlag("best", v) end)
    bind("best", filterBest)

    pgFilter:dropdown("Urutkan", SORTS, state.sort, function(_, idx)
        state.sort = idx
        log("Urut: " .. SORTS[idx])
        if updateHome then updateHome() end
    end)
    local areaDropFilter = pgFilter:dropdown("Area target", AREA_NAMES, state.area, function(_, idx) setArea(idx, false, true) end)
    areaRefs[#areaRefs + 1] = areaDropFilter
    pgFilter:button("Pilih Area Terbaik", function() pcall(pickBestArea, false) end)
    pgFilter:dropdown("Min Rarity", RARITY_NAMES, state.minRar, function(_, idx)
        state.minRar = idx
        log("Min Rarity: " .. RARITY_NAMES[idx])
        if updateHome then updateHome() end
    end)
    pgFilter:dropdown("Min Progression", PROG_NAMES, state.minProg, function(_, idx)
        state.minProg = idx
        log("Min Progression: " .. PROG_NAMES[idx])
        if updateHome then updateHome() end
    end)
    pgFilter:dropdown("Min Value", VALUE_NAMES, state.minVal, function(_, idx)
        state.minVal = idx
        log("Min Value: " .. VALUE_NAMES[idx])
        if updateHome then updateHome() end
    end)

    local filterAll = pgFilter:toggle("Semua Area", state.allAreas, function(v) setFlag("allAreas", v) end)
    bind("allAreas", filterAll)
    local filterFallback = pgFilter:toggle("Fallback kalau filter kosong", state.fallback, function(v) setFlag("fallback", v) end)
    bind("fallback", filterFallback)
    local filterStrict = pgFilter:toggle("Filter ketat (data kosong = tolak)", state.strict, function(v) setFlag("strict", v) end)
    bind("strict", filterStrict)

    pgFilter:button("Tes Pilih Terbaik Sekarang", testFilter, { variant = "primary" })
    pgFilter:buttonRow({
        { text = "Scan Info Egg", callback = scanInfo },
        { text = "Dump Snapshot", callback = function()
            task.spawn(function()
                local ok = refreshSnapshot(true)
                ui:toast(ok and "Snapshot masuk ke log." or "Snapshot gagal, cek log.", ok and nil or "warn")
            end)
        end },
    })

    pgFilter:note("Filter aman: kalau game tidak memberi data rarity/value untuk suatu egg, egg itu TIDAK otomatis ditolak. Pakai Min Progression untuk filter yang paling andal. Filter ketat hanya untuk debugging.")
    pgFilter:note("Urutan Auto: egg event/night dulu, lalu Rarity, Progression, Chance, Value, Berat. Kalau rarity tidak terbaca, Progression yang menentukan.")
    pgFilter:note("Dropdown Area target mengunci scope ke area itu (Semua Area otomatis OFF). Tombol 'Pilih Area Terbaik' mencari area dengan egg skor tertinggi.")

    --[[ ===================== 17b. EGG GALLERY PAGE ===================== ]]
    local function modelImageId(m, info)
        if info.imageId then return info.imageId end
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                local nm = tostring(d.Name):lower()
                if nm:find("egg", 1, true) or nm:find("icon", 1, true) or nm:find("image", 1, true)
                    or nm:find("thumb", 1, true) or nm:find("render", 1, true) then
                    local id = assetIdOf(d.Image)
                    if id then info.imageId = id; return id end
                end
            elseif d:IsA("Decal") or d:IsA("Texture") then
                local id = assetIdOf(d.Texture)
                if id then info.imageId = id; return id end
            end
        end
        return nil
    end

    local function buildEggPreview(parent, e, info)
        local box = inst("Frame", {
            Size = UDim2.fromOffset(96, 96),
            Position = UDim2.fromOffset(10, 10),
            BackgroundColor3 = Color3.fromRGB(13, 15, 23),
            BorderSizePixel = 0,
        }, parent)
        corner(box, 9)
        stroke(box, C.stroke, 1, 0.35)

        local img = modelImageId(e.m, info)
        if img then
            inst("ImageLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Image = "rbxassetid://" .. tostring(img),
                ScaleType = Enum.ScaleType.Fit,
            }, box)
            return
        end

        local vpf = inst("ViewportFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Ambient = Color3.fromRGB(160, 160, 180),
            LightColor = Color3.fromRGB(255, 255, 255),
            LightDirection = Vector3.new(-0.5, -1, -0.7),
        }, box)
        local world = inst("WorldModel", {}, vpf)
        local cam = inst("Camera", { FieldOfView = 40 }, vpf)
        vpf.CurrentCamera = cam

        local ok, clone = pcall(function() return e.m:Clone() end)
        if not ok or not clone then
            inst("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "🥚",
                TextSize = 40,
            }, box)
            return
        end

        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("ScreenGui")
                or d:IsA("ProximityPrompt") or d:IsA("ClickDetector")
                or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                pcall(function() d:Destroy() end)
            end
        end
        pcall(function() clone.Parent = world end)

        local okBox, boxCf, boxSize = pcall(function()
            local cf, size = clone:GetBoundingBox()
            return cf, size
        end)
        local size = (okBox and boxSize) or Vector3.new(4, 4, 4)
        if okBox and boxCf then
            pcall(function() clone:PivotTo(clone:GetPivot() - boxCf.Position) end)
        end
        local maxDim = math.max(size.X or 4, size.Y or 4, size.Z or 4, 1)
        local dist = maxDim * 2.0
        cam.CFrame = CFrame.lookAt(
            Vector3.new(dist * 0.55, (size.Y or 4) * 0.35, dist * 0.95),
            Vector3.new(0, 0, 0)
        )
    end

    local function makeEggCard(parent, e, idx)
        local i = e.info or eggInfoCached(e.m)
        local card = inst("Frame", {
            Name = "EggCard",
            Size = UDim2.new(1, 0, 0, 150),
            BackgroundColor3 = C.panel,
            BorderSizePixel = 0,
            LayoutOrder = idx,
        }, parent)
        corner(card, 10)
        stroke(card, i.event and C.yellow or C.stroke, 1, i.event and 0.1 or 0.4)

        buildEggPreview(card, e, i)

        inst("TextLabel", {
            Size = UDim2.new(1, -118, 0, 19),
            Position = UDim2.fromOffset(106, 7),
            BackgroundTransparency = 1,
            Text = tostring(i.name),
            TextColor3 = C.text,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)

        local rarText = "Rarity: " .. (RARITY_LABEL[i.rar] or "-")
        if i.event then rarText = rarText .. "  •  EVENT" end
        inst("TextLabel", {
            Size = UDim2.new(1, -118, 0, 15),
            Position = UDim2.fromOffset(106, 27),
            BackgroundTransparency = 1,
            Text = rarText,
            TextColor3 = i.event and C.yellow or (RARITY_COLOR[i.rar] or C.sub),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)

        local stats = string.format("Value: %s\nBerat: %s\nProg: %s\nChance: %s",
            i.val > 0 and fmtVal(i.val) or "-",
            i.weight > 0 and fmtKg(i.weight) or "-",
            i.prog > 0 and tostring(i.prog) or "-",
            i.chance > 0 and ("1 in " .. fmtVal(i.chance)) or "-")

        inst("TextLabel", {
            Size = UDim2.new(1, -118, 0, 58),
            Position = UDim2.fromOffset(106, 44),
            BackgroundTransparency = 1,
            Text = stats,
            TextColor3 = C.sub,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, card)

        local btn = inst("TextButton", {
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.fromOffset(10, 112),
            BackgroundColor3 = C.accent,
            Text = "Steal Egg Ini",
            TextColor3 = Color3.fromRGB(15, 20, 30),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            AutoButtonColor = true,
            BorderSizePixel = 0,
        }, card)
        corner(btn, 8)
        btn.MouseButton1Click:Connect(function() stealEgg(e) end)
    end

    local pgEgg = ui:page("egg", "Egg", "🖼️")
    pgEgg:section("Galeri Egg")
    local galleryInfo = pgEgg:label("Memuat data egg...", { size = 11, color = C.sub })

    local probeToggle = pgEgg:toggle("Auto Probe Record (debug)", state.probe, function(v) setFlag("probe", v) end)
    bind("probe", probeToggle)

    local eggStealToggle = pgEgg:toggle("Auto Steal Egg", state.steal, function(v) setFlag("steal", v) end)
    bind("steal", eggStealToggle)
    local eggBestToggle = pgEgg:toggle("Pilih Egg Terbaik", state.best, function(v) setFlag("best", v) end)
    bind("best", eggBestToggle)

    pgEgg:dropdown("Tampilkan Rarity", RARITY_NAMES, state.galleryRar, function(_, idx)
        state.galleryRar = idx
        gallerySig = ""
        galleryDirty = true
        if galleryRefresh then galleryRefresh(true) end
    end)

    pgEgg:buttonRow({
        { text = "Muat Ulang", callback = function()
            gallerySig = ""
            galleryDirty = true
            if galleryRefresh then galleryRefresh(true) end
        end },
        { text = "Dump 1 Egg", callback = function()
            local eggs = areaEggs()
            local e = eggs[1]
            if not e then ui:toast("Tidak ada egg di area ini.", "warn"); return end
            local uid = e.uid
            local inf = eggInfoCached(e.m)
            log("DUMP EGG " .. tostring(e.m.Name) .. " uid=" .. tostring(uid)
                .. " cat=" .. tostring(debugCategoryOf(e, inf) or "-"))
            log("ATTR: " .. table.concat(inf.attrs, ", "):sub(1, 900))
            local d = uid and (snapCache[uid] or snapMeta[uid])
            log("SNAPSHOT: " .. (d and ser(d):sub(1, 2200) or "tidak ada"))
        end },
        { text = "Steal Best", callback = manualSteal, variant = "primary" },
        { text = "TP Area", callback = function() tpArea(state.area) end },
    })

    pgEgg:button("Probe Record (semua area)", function()
        ui:toast("Probe record semua area...")
        task.spawn(function() debugProbeAll(true) end)
    end, { variant = "primary" })
    pgEgg:button("Baca Katalog (client)", function()
        ui:toast("Membaca katalog ReplicatedStorage...")
        task.spawn(function()
            local n = catalog.read(true)
            ui:toast("Katalog: " .. n .. " modul dibaca.", n > 0 and "ok" or "warn")
            if galleryRefresh then galleryRefresh(true) end
        end)
    end)
    pgEgg:button("Dump Semua Egg", function() debugDumpAll() end)

    local galleryBox = pgEgg:frame(120)
    galleryBox.BackgroundTransparency = 1
    galleryBox.Size = UDim2.new(1, 0, 0, 0)
    galleryBox.AutomaticSize = Enum.AutomaticSize.Y
    inst("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, galleryBox)

    local function refreshGallery(force)
        if not galleryBox or not running then return end
        local eggs = areaEggs()
        for _, e in ipairs(eggs) do
            e.info = eggInfoCached(e.m)
        end

        local sigParts = { tostring(state.area), tostring(#eggs) }
        for _, e in ipairs(eggs) do
            local i = e.info
            sigParts[#sigParts + 1] = table.concat({
                e.m.Name, tostring(i.rar), tostring(i.prog), tostring(i.val), tostring(i.weight),
            }, ":")
        end
        local sig = table.concat(sigParts, "|")
        if not force and sig == gallerySig then return end
        gallerySig = sig

        for _, c in ipairs(galleryBox:GetChildren()) do
            if c.Name == "EggCard" then pcall(function() c:Destroy() end) end
        end

        local r = getRoot()
        local rp = r and r.Position
        local list = {}
        for _, e in ipairs(eggs) do
            local i = e.info
            if state.galleryRar <= 1 or i.rar >= state.galleryRar then
                list[#list + 1] = e
            end
        end
        table.sort(list, function(a, b)
            local sa = eggScore(a, state.sort, rp)
            local sb = eggScore(b, state.sort, rp)
            if sa == sb then
                local da = rp and (a.pos - rp).Magnitude or 0
                local db = rp and (b.pos - rp).Magnitude or 0
                return da < db
            end
            return sa > sb
        end)

        local cardLimit = state.lite and 4 or 8
        local shown = math.min(#list, cardLimit)
        for idx = 1, shown do
            local ok, err = pcall(makeEggCard, galleryBox, list[idx], idx)
            if not ok then log("ERROR kartu egg: " .. tostring(err)) end
        end

        local txt = string.format("%s • %d egg terdeteksi, %d tampil",
            AREAS[state.area][1], #eggs, shown)
        if #eggs > 0 and shown == 0 then
            txt = txt .. " (filter rarity kosong)"
        end
        galleryInfo.Text = txt
        galleryDirty = false
    end
    galleryRefresh = function(force) return refreshGallery(force) end

    -- Jangan clone 3D preview saat boot. Kartu dibuat hanya saat halaman Egg dibuka.
    ui.onPageShow = function(id)
        if id == "egg" and galleryRefresh then pcall(galleryRefresh, false) end
    end
    galleryDirty = true

    --[[ ===================== 18. AREA PAGE ===================== ]]
    local pgArea = ui:page("area", "Area", "🗺️")
    pgArea:section("Pilih Area")
    local areaDrop = pgArea:dropdown("Area", AREA_NAMES, state.area, function(_, idx) setArea(idx, false, true) end)
    areaRefs[#areaRefs + 1] = areaDrop

    local autoAreaToggle = pgArea:toggle("Auto pilih area terbaik", state.autoArea, function(v) setFlag("autoArea", v) end)
    bind("autoArea", autoAreaToggle)
    areaAutoRef = autoAreaToggle

    pgArea:buttonRow({
        { text = "< Sebelumnya", callback = function() setArea(state.area - 1, false, true) end },
        { text = "Pilih Area Terbaik", callback = function() pcall(pickBestArea, false) end, variant = "primary" },
        { text = "Berikutnya >", callback = function() setArea(state.area + 1, false, true) end },
    })
    pgArea:button("Teleport ke area", function() tpArea(state.area) end)

    pgArea:divider()
    pgArea:section("Base")
    pgArea:buttonRow({
        { text = "TP ke Base", callback = tpBase },
        { text = "Set Base (di sini)", callback = function()
            if setBaseHere() then ui:toast("Base diset.") else ui:toast("Karakter belum siap.", "warn") end
        end },
    })
    pgArea:note("Base dipakai untuk kembali setelah mengambil egg. Kalau belum diset, script mencoba PlacedEggRenders / PlotSign / posisi awal.")

    --[[ ===================== 19. LOG PAGE ===================== ]]
    local pgLog = ui:page("log", "Log", "📜")
    pgLog:section("Log Aktivitas")
    local logFrame = pgLog:frame(math.max(200, math.floor(ui.height - 150)))
    logFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 18)
    logFrame.BackgroundTransparency = 0
    corner(logFrame, 10)
    stroke(logFrame, C.stroke, 1, 0.4)

    logScroll = inst("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.fromOffset(4, 4),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.stroke,
    }, logFrame)
    logLabel = inst("TextLabel", {
        Size = UDim2.new(1, -12, 0, 0),
        Position = UDim2.fromOffset(6, 6),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = "(belum ada log)",
        TextColor3 = Color3.fromRGB(185, 245, 195),
        Font = Enum.Font.Code,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, logScroll)

    local function copyLog()
        if #logs == 0 then
            ui:toast("Log masih kosong.", "warn")
            return
        end
        if type(setclipboard) == "function" then
            pcall(setclipboard, table.concat(logs, "\n"))
            ui:toast("Log disalin (" .. #logs .. " baris).")
        else
            ui:toast("setclipboard tidak tersedia di executor.", "warn")
        end
    end

    local function clearLog()
        logs = {}
        logDirty = true
        refreshLogUI()
        ui:toast("Log dibersihkan.")
    end

    pgLog:buttonRow({
        { text = "Copy All", callback = copyLog },
        { text = "Clear", callback = clearLog, variant = "danger" },
    })
    pgLog:toggle("Auto-scroll ke bawah", autoScroll, function(v)
        autoScroll = v
        if v then refreshLogUI() end
    end)
    pgLog:note("Disimpan 4000 baris (maks 3000 karakter/baris). Tampilan hanya 300 baris terakhir supaya ringan; Copy All mengambil semua.")

    --[[ ===================== 20. INFO PAGE ===================== ]]
    local executorName = "?"
    if type(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        if ok and name then executorName = tostring(name) end
    end

    local function copyDebug()
        local b, src = basePos()
        local text = table.concat({
            "Bike For Eggs - Mobile v5",
            "Player: " .. lp.Name .. " (" .. tostring(lp.UserId) .. ")",
            "Executor: " .. executorName,
            "Area: " .. AREAS[state.area][1] .. (state.allAreas and " + semua" or ""),
            "Steal: " .. tostring(state.steal) .. " | Best: " .. tostring(state.best) .. " | Sort: " .. SORTS[state.sort],
            "Filter: rar=" .. RARITY_NAMES[state.minRar] .. " prog=" .. PROG_NAMES[state.minProg] .. " val=" .. VALUE_NAMES[state.minVal],
            "Fallback: " .. tostring(state.fallback) .. " | Strict: " .. tostring(state.strict) .. " | Lite: " .. tostring(state.lite),
            "Base: " .. (b and (tostring(src) .. " @ " .. math.floor(b.X) .. "," .. math.floor(b.Z)) or "belum"),
            "Egg di area: " .. tostring(#areaEggs()),
        }, "\n")
        if type(setclipboard) == "function" then
            pcall(setclipboard, text)
            ui:toast("Info debug disalin.")
        else
            ui:toast("setclipboard tidak tersedia.", "warn")
        end
    end

    local pgInfo = ui:page("info", "Info", "ℹ️")
    pgInfo:section("Tentang")
    pgInfo:card({
        {"Versi", "v5.9"},
        {"UI", "BFEUI (embedded)"},
        {"Player", lp.Name},
        {"Executor", executorName},
    })
    pgInfo:note("UI ini memakai library mini BFEUI yang ditanam di script, jadi tidak bergantung pada HttpGet. Fitur dipisah per halaman lewat sidebar.")
    pgInfo:note("Halaman Egg menampilkan kartu egg: gambar (preview 3D), value, berat (kg), progression, rarity, dan tombol Steal khusus egg itu.")
    pgInfo:note("Metadata rarity/value/weight diambil dari katalog client ReplicatedStorage.Directory._Index (tombol 'Baca Katalog'). Snapshot + CarryState/ClaimFeedback tetap jadi cadangan.")

    pgInfo:section("Cara Pakai")
    pgInfo:note("1) Halaman Area: pilih area lalu Set Base. 2) Halaman Filter: atur urutan & filter Best Egg. 3) Halaman Steal: aktifkan Auto Steal. 4) Halaman Auto: aktifkan Hatch/Sell kalau perlu.")

    pgInfo:section("Performa")
    local liteToggle = pgInfo:toggle("Mode Ringan (4 kartu)", state.lite, function(v)
        setFlag("lite", v)
        galleryDirty = true
        gallerySig = ""
    end)
    bind("lite", liteToggle)
    pgInfo:note("Mode Ringan mengurangi kartu preview 3D dari 8 ke 4. Scan prompt dan data egg juga di-cache, jadi tidak mengulang GetDescendants tiap loop.")

    pgInfo:section("Kontrol")
    pgInfo:buttonRow({
        { text = "Minimize", callback = function() ui:minimize() end },
        { text = "Tutup UI", callback = function() ui:destroy("close") end, variant = "danger" },
    })
    pgInfo:button("Salin Info Debug", copyDebug)
    pgInfo:note("Anti double-run aktif. Kalau script dijalankan lagi saat UI masih hidup, akan muncul peringatan 'Script sudah berjalan!' dan script kedua berhenti.")

    --[[ ===================== 21. DASHBOARD UPDATE ===================== ]]
    local function refreshHome()
        if not homeStatus then return end
        if ui.current ~= "home" then return end
        if state.steal then
            homeStatus.set("Steal", state.best and "ON - Best" or "ON - Rotasi", C.green)
        else
            homeStatus.set("Steal", "OFF", C.sub)
        end
        homeStatus.set("Hatch", state.hatch and "ON" or "OFF", state.hatch and C.green or C.sub)
        homeStatus.set("Sell", state.sell and "ON" or "OFF", state.sell and C.green or C.sub)
        homeStatus.set("Area", AREAS[state.area][1] .. (state.allAreas and " (semua)" or ""), C.text)

        local b, src = basePos()
        if b then
            homeStatus.set("Base", tostring(src) .. " (" .. math.floor(b.X) .. "," .. math.floor(b.Z) .. ")", C.text)
        else
            homeStatus.set("Base", "belum diset", C.yellow)
        end

        local eggs = areaEggs()
        homeStatus.set("Egg area", tostring(#eggs), C.text)
        if #eggs > 0 then
            local best = pickBest(eggs, true)
            if best then
                local i = best.info
                homeStatus.set("Kandidat", tostring(i.name) .. " | " .. fmtVal(i.val) .. " | " .. fmtKg(i.weight), C.green)
            else
                homeStatus.set("Kandidat", "filter kosong", C.yellow)
            end
        else
            homeStatus.set("Kandidat", "tidak ada egg", C.sub)
        end
    end
    updateHome = refreshHome

    --[[ ===================== 22. BACKGROUND LOOPS ===================== ]]
    task.spawn(function()
        while running do
            task.wait(0.35)
            if logDirty and ui.current == "log" then
                logDirty = false
                refreshLogUI()
            end
        end
    end)

    task.spawn(function()
        while running do
            task.wait(0.8)
            if ui.current == "home" and updateHome then updateHome() end
        end
    end)

    task.spawn(function()
        while running do
            task.wait(1.5)
            if ui.current == "egg" and galleryRefresh then
                galleryDirty = false
                pcall(galleryRefresh, false)
            end
        end
    end)

    task.spawn(function()
        while running do
            task.wait(0.25)
            if state.steal and not busy then
                busy = true
                local ok, err = pcall(stealOne, false)
                if not ok then log("ERROR stealOne: " .. tostring(err)) end
                busy = false
                task.wait(math.max(0.2, state.stealDelay))
            end
        end
    end)

    task.spawn(function()
        while running do
            task.wait(0.4)
            if state.hatch then
                local ok, err = pcall(function()
                    scanPrompts()
                    local it = nearestPrompt(promptCache.hatch)
                    if it then firePrompt(it.prompt) end
                end)
                if not ok then log("ERROR hatch: " .. tostring(err)) end
                task.wait(math.max(0.5, state.hatchDelay))
            end
        end
    end)

    task.spawn(function()
        while running do
            task.wait(0.4)
            if state.sell then
                local ok, err = pcall(function()
                    scanPrompts()
                    local it = nearestPrompt(promptCache.sell)
                    if it then firePrompt(it.prompt) end
                end)
                if not ok then log("ERROR sell: " .. tostring(err)) end
                task.wait(math.max(0.5, state.sellDelay))
            end
        end
    end)

    task.spawn(function()
        local ok, net = pcall(function()
            return ReplicatedStorage:WaitForChild("Network", 10)
        end)
        if not ok or not net then return end

        local function walkEvent(t, fn, depth, seen, parentKey)
            if type(t) ~= "table" or (depth or 0) > 5 then return end
            seen = seen or {}
            if seen[t] then return end
            seen[t] = true
            fn(t, parentKey)
            for k, v in pairs(t) do
                if type(v) == "table" then walkEvent(v, fn, (depth or 0) + 1, seen, k) end
            end
        end

        local function vecOf(v)
            local tv = typeof(v)
            if tv == "CFrame" then return v.Position end
            if tv == "Vector3" then return v end
            if type(v) == "table" then
                if v.X then return Vector3.new(v.X, v.Y or 0, v.Z or 0) end
                if v[1] then return Vector3.new(v[1], v[2] or 0, v[3] or 0) end
            end
            return nil
        end

        local function matchEgg(pos, areaId)
            if not pos then return nil end
            local best, bd
            for _, e in ipairs(areaEggs(true)) do
                local ai = eggAreaIndex(e)
                if not areaId or string.lower(AREAS[ai][1]) == string.lower(areaId) then
                    local d = (e.pos - pos).Magnitude
                    if not bd or d < bd then best, bd = e, d end
                end
            end
            if best and (bd or 9999) < 15 then return best end
            return nil
        end

        local function readRarity(t)
            for _, k in ipairs({"Rarity", "rarity", "RARITY", "Tier", "Grade"}) do
                local r = rarityOf(t[k])
                if r > 0 then return r end
            end
            return 0
        end

        for _, name in ipairs({
            "Eggs: AreaEggCarryState",
            "Eggs: AreaEggClaimFeedback",
            "Eggs: AreaEggUpdated",
            "Eggs: AreaEggBatchUpdated",
            "Eggs: RuntimeOwnerUpdated",
            "ActiveAssets: RuntimeOwnerUpdated",
            "ActiveAssets: StealTargetEvent",
        }) do
            local re = net:FindFirstChild(name, true)
            if re and re:IsA("RemoteEvent") then
                local shown = 0
                re.OnClientEvent:Connect(function(...)
                    shown = shown + 1
                    local changed = false
                    for i = 1, select("#", ...) do
                        local v = select(i, ...)
                        if type(v) == "table" then
                            pcall(indexSnapshot, v, 0)
                            walkEvent(v, function(t, parentKey)
                                local rar = readRarity(t)
                                local cat = t.AssetCategory or t.Category or t.DisplayName or t.PetDisplayName

                                -- Eggs: RuntimeOwnerUpdated mengirim Records={Egg_<guid>={AssetCategory=...}}.
                                -- Ini kunci langsung ke model AreaEgg_<guid> di plot.
                                if type(parentKey) == "string" and string.sub(parentKey, 1, 4) == "Egg_" then
                                    local g = guidOf(parentKey)
                                    if g then
                                        local ukey = string.lower(g)
                                        if type(cat) == "string" and cat ~= "" then
                                            uidCategory[ukey] = string.lower(cat)
                                            changed = true
                                        end
                                        snapCache[ukey] = t
                                        snapMeta[ukey] = t
                                        if type(t.AreaId) == "string" then uidArea[ukey] = t.AreaId end
                                        if rar > 0 and type(cat) == "string" then
                                            categoryRarity[string.lower(cat)] = rar
                                        end
                                    end
                                end

                                -- AreaEggUpdated kadang mengirim Uid="AreaEgg_<guid>" langsung.
                                -- Ini paling akurat: tidak perlu menebak lewat posisi.
                                local areaUid = t.Uid or t.UID or t.EggUid
                                if type(areaUid) == "string" and string.find(areaUid, "AreaEgg", 1, true) then
                                    local g = guidOf(areaUid)
                                    if g then
                                        local ukey = string.lower(g)
                                        snapCache[ukey] = t
                                        snapMeta[ukey] = t
                                        if type(cat) == "string" and cat ~= "" then
                                            uidCategory[ukey] = string.lower(cat)
                                        end
                                        if type(t.AreaId) == "string" then uidArea[ukey] = t.AreaId end
                                        if rar > 0 and type(cat) == "string" then
                                            categoryRarity[string.lower(cat)] = rar
                                        end
                                        changed = true
                                    end
                                end

                                -- AreaEggUpdated juga bisa mengirim AssetCategory + BoundsCFrame
                                -- tanpa Uid. Cocokkan lewat posisi egg terdekat di area yang sama.
                                if type(cat) == "string" and cat ~= ""
                                    and string.find(name, "AreaEgg", 1, true) then
                                    local pos = vecOf(t.BoundsCFrame or t.CFrame or t.Position)
                                    local e = matchEgg(pos, t.AreaId)
                                    if e and e.uid then
                                        uidCategory[e.uid] = string.lower(cat)
                                        if type(t.AreaId) == "string" then uidArea[e.uid] = t.AreaId end
                                        if string.find(name, "AreaEggUpdated", 1, true) then
                                            snapCache[e.uid] = t
                                            snapMeta[e.uid] = t
                                        end
                                        if rar > 0 then categoryRarity[string.lower(cat)] = rar end
                                        changed = true
                                    end
                                end

                                if type(cat) == "string" and cat ~= "" then
                                    local key = string.lower(cat)
                                    if rar > 0 and (not categoryRarity[key] or rar > categoryRarity[key]) then
                                        categoryRarity[key] = rar
                                        changed = true
                                    end
                                    local pr = tonumber(t.ProgressionOrder or t.OriginalImportNumber)
                                    if pr and pr > 0 then categoryProg[key] = pr end
                                end
                                -- Feedback tidak punya Uid: cocokkan lewat posisi egg terdekat.
                                local p = t.Position
                                if type(p) == "table" and p.X and rar > 0 then
                                    local bestE, bd
                                    for _, e in ipairs(areaEggs(true)) do
                                        local d = (e.pos - Vector3.new(p.X, p.Y or 0, p.Z or 0)).Magnitude
                                        if not bd or d < bd then bestE, bd = e, d end
                                    end
                                    if bestE and bestE.uid and (bd or 9999) < 8 then
                                        uidCategory[bestE.uid] = type(cat) == "string" and string.lower(cat) or uidCategory[bestE.uid]
                                        if type(cat) == "string" then
                                            uidArea[bestE.uid] = AREAS[eggAreaIndex(bestE)][1]
                                            categoryRarity[string.lower(cat)] = rar
                                            changed = true
                                        end
                                    end
                                end
                                if string.find(name, "CarryState", 1, true)
                                    or string.find(name, "StealTarget", 1, true) then
                                    local uid = t.Uid or t.UID or t.EggUid or t.AssetUid
                                    if type(uid) == "string" and uid ~= "" then
                                        local ukey = string.lower(guidOf(uid) or uid)
                                        assetUidHints[ukey] = true
                                        if string.find(name, "CarryState", 1, true) then
                                            carryEventSeen = true
                                        end
                                        if string.find(name, "CarryState", 1, true)
                                            and truthy(t.IsCarrying) then
                                            lastCarry = {
                                                uid = ukey, area = t.AreaId,
                                                category = type(cat) == "string" and cat or nil,
                                                at = os.clock(),
                                            }
                                        end
                                        if type(cat) == "string" then uidCategory[ukey] = string.lower(cat) end
                                        if type(t.AreaId) == "string" then uidArea[ukey] = t.AreaId end
                                    end
                                end
                            end)
                        end
                    end
                    if changed then
                        clearInfoCache()
                        galleryDirty = true
                        gallerySig = ""
                    end
                    if shown > 4 or not running then return end
                    local t = {}
                    for i = 1, select("#", ...) do t[i] = ser((select(i, ...))) end
                    log("EVENT " .. name .. ": " .. table.concat(t, ", "):sub(1, 500))
                end)
            end
        end
    end)

    --[[ ===================== 23. START ===================== ]]
    ui:setActive(state.steal)
    log("Bike For Eggs v5 dimuat. Player: " .. lp.Name .. " | Area: " .. AREAS[state.area][1])
    refreshLogUI()
    logDirty = false
    updateHome()

    task.spawn(function()
        -- Beri game waktu selesai spawn sebelum kerja berat (snapshot/scan).
        task.wait(1.2)
        if not running or not refreshSnapshot(false) then return end
        clearInfoCache()
        galleryDirty = true
        gallerySig = ""
        if state.autoArea then pcall(pickBestArea, false) end
        if ui.current == "home" and updateHome then updateHome() end

        -- Probe debug ditunda supaya tidak bersamaan dengan snapshot + UI awal.
        if state.probe then
            task.spawn(function()
                task.wait(5)
                if not running then return end
                -- Baca katalog client sekali setelah UI tenang, bukan saat entry.
                pcall(catalog.read, false)
                pcall(debugProbeAll, false)
                if ui.current == "home" and updateHome then updateHome() end
            end)
        end
    end)
end

local ok, err = xpcall(boot, function(e)
    return tostring(e) .. "\n" .. debug.traceback("", 2)
end)

if not ok then
    envSet("BFE_V5_Running", nil)
    local old = findExistingGui()
    if old then pcall(function() old:Destroy() end) end
    warn("[BikeForEggs] Error: " .. tostring(err))
    simpleNotice("Script error", tostring(err):sub(1, 320), {
        { text = "Tutup", callback = function() end },
    })
end
