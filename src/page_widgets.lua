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
        corner(f, 12)
        stroke(f, color or C.accent, 1, 0.55)
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
        corner(b, 12)
        stroke(b, variant == "primary" and C.accent or C.stroke, 1, variant and 0.45 or 0.25)
        if variant == "primary" then
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new(C.accent2, C.accent)
            g.Rotation = 90
            g.Parent = b
        end
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
            corner(b, 12)
            if item.variant == "primary" then
                local g = Instance.new("UIGradient")
                g.Color = ColorSequence.new(C.accent2, C.accent)
                g.Rotation = 90
                g.Parent = b
            end
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
        corner(row, 12)
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
            local targetBg = on and C.accent or C.panel3
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
        corner(row, 12)
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
        corner(row, 12)
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
        corner(f, 12)
        stroke(f, C.accent, 1, 0.72)
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

