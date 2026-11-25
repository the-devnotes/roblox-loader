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

