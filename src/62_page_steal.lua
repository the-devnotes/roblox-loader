    --[[ ===================== 15. STEAL PAGE ===================== ]]
    local pgSteal = ui:page("steal", "Ambil", "🥚")
    pgSteal:section("Ambil Egg")
    local stealToggle = pgSteal:toggle("Ambil Egg Otomatis", state.steal, function(v) setFlag("steal", v) end)
    bind("steal", stealToggle)
    local bestToggle = pgSteal:toggle("Ambil Egg Terbaik", state.best, function(v) setFlag("best", v) end)
    bind("best", bestToggle)
    local bestDrop = pgSteal:dropdown("Cara ambil", {"Bergiliran", "Terbaik"}, state.best and 2 or 1, function(_, idx)
        setFlag("best", idx == 2)
    end)
    bind("best", { set = function(v) bestDrop:set(v and 2 or 1) end })

    local areaDropSteal = pgSteal:dropdown("Area tujuan", AREA_NAMES, state.area, function(_, idx) setArea(idx, false, true) end)
    areaRefs[#areaRefs + 1] = areaDropSteal
    pgSteal:button("Cari Area Terbaik", function() pcall(pickBestArea, false) end)

    pgSteal:stepper("Jeda setelah ambil", 0.2, 3.0, 0.1, state.stealDelay, function(v)
        state.stealDelay = v
    end, function(v) return string.format("%.1fs", v) end)

    pgSteal:button("Ambil Satu Sekarang", manualSteal, { variant = "primary" })
    pgSteal:note("Kalau 'Ambil Egg Terbaik' menyala, script memilih egg dengan skor tertinggi sesuai pengaturan di Filter. Kalau mati, egg diambil bergiliran.")

