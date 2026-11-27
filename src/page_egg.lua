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

    local pgEgg = ui:page("egg", "Egg", "gallery")
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

