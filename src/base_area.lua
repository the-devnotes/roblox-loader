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

