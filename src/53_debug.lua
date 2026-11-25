    --[[ ===================== 12b. DEBUG DATA (SEMUA AREA) ===================== ]]
    local function debugCategoryOf(e, i)
        if not e then return nil end
        local m = e.m
        if m then
            -- PetDisplayName adalah kategori asli (Embercrest, Grizzlite, ...).
            -- Prioritaskan ini, jangan kalah oleh fallback name "Egg".
            local pet = m:GetAttribute("PetDisplayName")
            if type(pet) == "string" and pet ~= "" and pet ~= "Egg" then return string.lower(pet) end
            local disp = m:GetAttribute("DisplayName")
            if type(disp) == "string" and disp ~= "" then
                local clean = disp:gsub("%s*[Ee]gg%s*$", "")
                clean = clean:gsub("^%s+", ""):gsub("%s+$", "")
                if clean ~= "" and clean ~= "Egg" then return string.lower(clean) end
            end
            local model = m:GetAttribute("PetModelName")
            if type(model) == "string" and model ~= "" then return string.lower(model) end
        end
        if e.uid and uidCategory[e.uid] then return uidCategory[e.uid] end
        local n = i and i.name
        if n and n ~= "" and not n:find("Egg #", 1, true) and n ~= "Egg" and n ~= "egg" then
            return string.lower(n)
        end
        return nil
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
            pcall(refreshRuntimeSnapshot, false)
        end

        local found, checked = 0, 0
        local limit = verbose and 12 or 6
        for _, e in ipairs(eggs) do
            local i = e.info or eggInfoCached(e.m)
            local uid = e.uid
            local cat = debugCategoryOf(e, i)
            if cat and uid then uidCategory[uid] = cat end
            local ai = eggAreaIndex(e)
            local areaName = (AREAS[ai] and AREAS[ai][1]) or AREAS[state.area][1]
            if probeRecord(uid, cat, areaName, verbose, e.m and e.m.Name or nil) then found = found + 1 end
            checked = checked + 1
            if checked >= limit then break end
        end

        clearInfoCache()
        galleryDirty = true
        gallerySig = ""
        if verbose then
            log(string.format("PROBE selesai: %d egg dicek, %d record ketemu. %s",
                checked, found, debugSummary()))
            if galleryRefresh then pcall(galleryRefresh, true) end
        end
        return found
    end

    local function debugDumpAll()
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
