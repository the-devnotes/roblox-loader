    --[[ ===================== 17. FILTER PAGE ===================== ]]
    local function testFilter()
        task.spawn(function()
            clearInfoCache()
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
                ui:toast("Terbaik: " .. tostring(best.info.name))
            else
                ui:toast("Tidak ada yang cocok. Turunkan batas atau nyalakan 'Ambil Semua kalau Filter Kosong'.", "warn")
            end
        end)
    end

    local pgFilter = ui:page("filter", "Filter", "🎯")
    pgFilter:section("Pilihan Egg")
    local filterBest = pgFilter:toggle("Ambil Egg Terbaik", state.best, function(v) setFlag("best", v) end)
    bind("best", filterBest)

    pgFilter:dropdown("Urutkan", SORTS, state.sort, function(_, idx)
        state.sort = idx
        log("Urutan: " .. SORTS[idx])
        if updateHome then updateHome() end
    end)
    local areaDropFilter = pgFilter:dropdown("Area tujuan", AREA_NAMES, state.area, function(_, idx) setArea(idx, false, true) end)
    areaRefs[#areaRefs + 1] = areaDropFilter
    pgFilter:button("Cari Area Terbaik", function() pcall(pickBestArea, false) end)
    pgFilter:dropdown("Rarity Minimum", RARITY_NAMES, state.minRar, function(_, idx)
        state.minRar = idx
        log("Rarity minimum: " .. RARITY_NAMES[idx])
        if updateHome then updateHome() end
    end)
    pgFilter:dropdown("Progres Minimum", PROG_NAMES, state.minProg, function(_, idx)
        state.minProg = idx
        log("Progres minimum: " .. PROG_NAMES[idx])
        if updateHome then updateHome() end
    end)
    pgFilter:dropdown("Nilai Minimum", VALUE_NAMES, state.minVal, function(_, idx)
        state.minVal = idx
        log("Nilai minimum: " .. VALUE_NAMES[idx])
        if updateHome then updateHome() end
    end)

    local filterAll = pgFilter:toggle("Cari di Semua Area", state.allAreas, function(v) setFlag("allAreas", v) end)
    bind("allAreas", filterAll)
    local filterFallback = pgFilter:toggle("Ambil Semua kalau Filter Kosong", state.fallback, function(v) setFlag("fallback", v) end)
    bind("fallback", filterFallback)
    local filterStrict = pgFilter:toggle("Tolak Egg tanpa Data", state.strict, function(v) setFlag("strict", v) end)
    bind("strict", filterStrict)

    pgFilter:button("Cek Egg Terbaik", testFilter, { variant = "primary" })

    pgFilter:note("Kalau rarity/value suatu egg belum terbaca, egg itu tetap bisa diambil. Progres Minimum paling bisa diandalkan. 'Tolak Egg tanpa Data' hanya untuk mencoba filter ketat.")
    pgFilter:note("Urutan rekomendasi: egg event/night dulu, lalu rarity, progres, peluang, nilai, berat. Kalau rarity kosong, progres yang menentukan.")
    pgFilter:note("Area tujuan membatasi pencarian ke area itu (Cari di Semua Area otomatis mati). Tombol 'Cari Area Terbaik' memilih area yang egg-nya paling bagus.")

