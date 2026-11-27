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
