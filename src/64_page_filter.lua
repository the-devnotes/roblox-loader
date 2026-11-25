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

