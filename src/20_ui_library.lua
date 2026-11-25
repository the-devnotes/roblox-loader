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

