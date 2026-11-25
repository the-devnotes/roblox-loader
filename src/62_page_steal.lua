    --[[ ===================== 15. STEAL PAGE ===================== ]]
    local pgSteal = ui:page("steal", "Steal", "🥚")
    pgSteal:section("Auto Steal")
    local stealToggle = pgSteal:toggle("Auto Steal Egg", state.steal, function(v) setFlag("steal", v) end)
    bind("steal", stealToggle)
    local bestToggle = pgSteal:toggle("Pilih Egg Terbaik (Best Egg)", state.best, function(v) setFlag("best", v) end)
    bind("best", bestToggle)
    local bestDrop = pgSteal:dropdown("Mode ambil", {"Bergiliran", "Terbaik (Best)"}, state.best and 2 or 1, function(_, idx)
        setFlag("best", idx == 2)
    end)
    bind("best", { set = function(v) bestDrop:set(v and 2 or 1) end })

    local areaDropSteal = pgSteal:dropdown("Area target", AREA_NAMES, state.area, function(_, idx) setArea(idx, false, true) end)
    areaRefs[#areaRefs + 1] = areaDropSteal
    pgSteal:button("Pilih Area Terbaik", function() pcall(pickBestArea, false) end)

    pgSteal:stepper("Jeda setelah steal", 0.2, 3.0, 0.1, state.stealDelay, function(v)
        state.stealDelay = v
    end, function(v) return string.format("%.1fs", v) end)

    pgSteal:button("Ambil 1x Sekarang", manualSteal, { variant = "primary" })
    pgSteal:note("Kalau 'Pilih Egg Terbaik' ON, script memilih egg dengan skor tertinggi sesuai halaman Filter. Kalau OFF, egg diambil bergiliran.")

