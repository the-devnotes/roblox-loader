    --[[ ===================== 3. BFEUI MINI LIBRARY ===================== ]]
    --[[
        Palet dan ikon disamakan dengan loader.lua (ClipperHub).
        Kalau mengubah warna di sini, ubah juga THEME di loader.lua.
    ]]
    local C = {
        bg      = Color3.fromRGB(7, 9, 14),      -- BLACK
        panel   = Color3.fromRGB(14, 18, 28),    -- CARD
        panel2  = Color3.fromRGB(18, 24, 38),
        panel3  = Color3.fromRGB(24, 33, 52),
        stroke  = Color3.fromRGB(33, 52, 82),    -- LINE
        text    = Color3.fromRGB(232, 240, 255), -- TEXT
        sub     = Color3.fromRGB(140, 160, 192), -- MUTED
        accent  = Color3.fromRGB(48, 145, 255),  -- BLUE
        accent2 = Color3.fromRGB(18, 72, 150),   -- BLUE_DARK
        green   = Color3.fromRGB(72, 220, 152),
        red     = Color3.fromRGB(255, 96, 112),
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

    -- Ikon digambar dari Frame + UICorner. Tanpa emoji dan tanpa Asset ID.
    -- Dipakai ulang oleh title bar, tombol mengambang, dan sidebar.
    local function drawIcon(parent, name, size, color, knock)
        local s = size or 20
        local accent = color or C.accent
        local cut = knock or C.panel
        local u = s / 24

        local holder = inst("Frame", {
            Name = "Icon_" .. tostring(name or "dot"),
            Size = UDim2.fromOffset(s, s),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, parent)

        local painted = {}
        local function part(x, y, w, h, col, radius, rotation, isPaint)
            local f = inst("Frame", {
                Size = UDim2.fromOffset(w * u, h * u),
                Position = UDim2.fromOffset(x * u, y * u),
                BackgroundColor3 = col,
                BorderSizePixel = 0,
                Rotation = rotation or 0,
            }, holder)
            corner(f, (radius or 0) * u)
            if isPaint then painted[#painted + 1] = f end
            return f
        end
        local function ring(x, y, d, thickness, col)
            part(x, y, d, d, col, d / 2, nil, true)
            local inner = d - thickness * 2
            part(x + thickness, y + thickness, inner, inner, cut, inner / 2, nil, false)
        end

        local label
        if name == "clipperhub" or name == "brand" then
            part(1, 1, 22, 22, accent, 6, nil, true)          -- tile
            part(17, 1, 3, 7, cut, 1.5, 38, false)            -- klip
            label = inst("TextLabel", {
                Size = UDim2.fromOffset(s, s),
                BackgroundTransparency = 1,
                Text = "C",
                TextColor3 = cut,
                Font = Enum.Font.GothamBold,
                TextSize = 15 * u,
            }, holder)
        elseif name == "egg" then
            part(7, 3, 10, 18, accent, 5, nil, true)
            part(9, 6, 2, 6, cut, 1, -20, false)
        elseif name == "home" then
            part(5, 4, 14, 14, accent, 2, 45, true)
            part(7, 13, 10, 8, accent, 2, nil, true)
            part(10, 15, 4, 7, cut, 2, nil, false)
        elseif name == "gear" then
            ring(4, 4, 16, 4, accent)
            part(10, 10, 4, 4, accent, 2, nil, true)
            part(11, 1, 2, 4, accent, 1, nil, true)
            part(11, 19, 2, 4, accent, 1, nil, true)
            part(1, 11, 4, 2, accent, 1, nil, true)
            part(19, 11, 4, 2, accent, 1, nil, true)
        elseif name == "target" then
            ring(2, 2, 20, 3, accent)
            ring(7, 7, 10, 3, accent)
            part(10, 10, 4, 4, accent, 2, nil, true)
        elseif name == "map" then
            part(3, 5, 6, 14, accent, 2, -8, true)
            part(9, 4, 6, 15, accent, 2, 6, true)
            part(15, 5, 6, 14, accent, 2, -5, true)
        elseif name == "log" then
            part(4, 4, 4, 4, accent, 2, nil, true)
            part(10, 5, 10, 2, accent, 1, nil, true)
            part(4, 11, 4, 4, accent, 2, nil, true)
            part(10, 12, 10, 2, accent, 1, nil, true)
            part(4, 18, 4, 4, accent, 2, nil, true)
            part(10, 19, 10, 2, accent, 1, nil, true)
        elseif name == "gallery" then
            part(4, 4, 16, 16, accent, 5, nil, true)
            part(7, 7, 8, 8, cut, 4, nil, false)
        elseif name == "info" then
            part(5, 9, 14, 4, accent, 2, nil, true)
            part(8, 5, 8, 8, accent, 3, nil, true)
            part(8, 16, 8, 4, accent, 2, nil, true)
        else
            part(8, 8, 8, 8, accent, 4, nil, true)
        end

        local function setIconColor(col)
            for _, f in ipairs(painted) do
                pcall(function() f.BackgroundColor3 = col end)
            end
            if label then pcall(function() label.TextColor3 = col end) end
        end

        return {
            object = holder,
            setColor = setIconColor,
        }
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
        corner(win, 16)
        stroke(win, C.accent, 1.2, 0.55)
        local winGrad = Instance.new("UIGradient")
        winGrad.Color = ColorSequence.new(C.bg, Color3.fromRGB(12, 17, 28))
        winGrad.Rotation = 90
        winGrad.Parent = win
        self.window = win

        -- Cahaya biru lembut di bagian atas window.
        local topGlow = inst("Frame", {
            Size = UDim2.new(1, 0, 0, 96),
            BackgroundColor3 = C.accent2,
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
        }, win)
        local glowGrad = Instance.new("UIGradient")
        glowGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.accent2),
            ColorSequenceKeypoint.new(1, C.bg),
        })
        glowGrad.Rotation = 90
        glowGrad.Parent = topGlow

        local bar = inst("Frame", {
            Name = "TitleBar",
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = C.panel,
            BorderSizePixel = 0,
        }, win)
        local barGrad = Instance.new("UIGradient")
        barGrad.Color = ColorSequence.new(C.panel2, C.panel)
        barGrad.Rotation = 90
        barGrad.Parent = bar
        inst("Frame", {
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = C.accent,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
        }, bar)

        local logoId = tostring(cfg.logoAssetId or "")
        if logoId ~= "" then
            inst("ImageLabel", {
                Name = "BrandLogo",
                Size = UDim2.fromOffset(24, 24),
                Position = UDim2.fromOffset(10, 10),
                Image = "rbxassetid://" .. logoId,
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
            }, bar)
        else
            local brandIcon = drawIcon(bar, cfg.icon or "clipperhub", 24)
            brandIcon.object.Position = UDim2.fromOffset(10, 10)
        end

        inst("TextLabel", {
            Size = UDim2.new(1, -220, 0, 22),
            Position = UDim2.fromOffset(44, 4),
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
            Position = UDim2.fromOffset(44, 25),
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
            stroke(b, C.stroke, 1, 0.3)
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
            Size = UDim2.new(1, 0, 1, -44),
            Position = UDim2.fromOffset(0, 44),
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
            BackgroundColor3 = C.accent,
            BackgroundTransparency = 0.72,
            BorderSizePixel = 0,
        }, sidebar)

        local nav = inst("ScrollingFrame", {
            Size = UDim2.new(1, -8, 1, -12),
            Position = UDim2.fromOffset(4, 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = C.accent2,
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

        local float
        if logoId ~= "" then
            -- Mode logo: cuma gambar penuh, tanpa kotak / stroke / titik.
            float = inst("ImageButton", {
                Name = "Float",
                Size = UDim2.fromOffset(52, 52),
                Position = UDim2.new(0, 12, 0.5, -26),
                Image = "rbxassetid://" .. logoId,
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Visible = false,
            }, gui)
            corner(float, 10) -- border radius 10 (rentang 5-15)
            self.dot = nil
        else
            float = inst("TextButton", {
                Name = "Float",
                Size = UDim2.fromOffset(52, 52),
                Position = UDim2.new(0, 12, 0.5, -26),
                BackgroundColor3 = C.panel2,
                Text = "",
                AutoButtonColor = false,
                Visible = false,
                BorderSizePixel = 0,
            }, gui)
            corner(float, 16)
            stroke(float, C.accent, 1.5, 0.35)
            local floatIcon = drawIcon(float, "clipperhub", 28)
            floatIcon.object.Position = UDim2.fromScale(0.5, 0.5)
            floatIcon.object.AnchorPoint = Vector2.new(0.5, 0.5)
            local dot = inst("Frame", {
                Size = UDim2.fromOffset(12, 12),
                Position = UDim2.new(1, -15, 0, 2),
                BackgroundColor3 = C.green,
                BorderSizePixel = 0,
                Visible = false,
            }, float)
            corner(dot, 6)
            stroke(dot, C.bg, 2, 0)
            self.dot = dot
        end
        self.float = float

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

    function BFEUI:page(id, label, iconName)
        local navBtn = inst("TextButton", {
            Name = "Nav_" .. id,
            Size = UDim2.new(1, -8, 0, 40),
            BackgroundColor3 = C.panel2,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
        }, self.nav)
        corner(navBtn, 10)
        local navGrad = Instance.new("UIGradient")
        navGrad.Color = ColorSequence.new(C.accent2, C.accent)
        navGrad.Rotation = 90
        navGrad.Enabled = false
        navGrad.Parent = navBtn

        local iconObj = drawIcon(navBtn, iconName or "dot", 16)
        iconObj.object.Position = UDim2.fromOffset(11, 12)

        local navLabel = inst("TextLabel", {
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.fromOffset(34, 0),
            BackgroundTransparency = 1,
            Text = tostring(label),
            TextColor3 = C.sub,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, navBtn)
        local indicator = inst("Frame", {
            Size = UDim2.new(0, 3, 0, 20),
            Position = UDim2.new(0, 0, 0.5, -10),
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
            ScrollBarImageColor3 = C.accent2,
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
            ui = self, id = id, title = label, icon = iconName,
            nav = navBtn, navLabel = navLabel, navGrad = navGrad,
            iconObj = iconObj, setIconColor = iconObj.setColor, indicator = indicator,
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
            p.nav.BackgroundColor3 = sel and C.accent2 or C.panel2
            pcall(function() p.navGrad.Enabled = sel end)
            p.navLabel.TextColor3 = sel and C.text or C.sub
            if p.setIconColor then pcall(p.setIconColor, sel and C.text or C.sub) end
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
        if self.dot then
            self.dot.Visible = v and true or false
            self.float.BackgroundColor3 = v and C.accent2 or C.panel2
        end
        -- Mode logo sengaja tidak diubah supaya gambarnya tetap polos.
    end

    function BFEUI:toast(text, kind)
        local color = (kind == "error" and C.red) or (kind == "warn" and C.yellow) or C.accent
        local tw = math.min(360, self.width - 40)
        local f = inst("Frame", {
            Size = UDim2.fromOffset(tw, 42),
            Position = UDim2.new(0.5, -tw / 2, 1, -56),
            BackgroundColor3 = C.panel2,
            BorderSizePixel = 0,
            ZIndex = 50,
        }, self.gui)
        corner(f, 12)
        stroke(f, color, 1.2, 0.25)
        local edge = inst("Frame", {
            Size = UDim2.fromOffset(3, 42),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = 51,
        }, f)
        corner(edge, 2)
        inst("TextLabel", {
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.fromOffset(12, 0),
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
