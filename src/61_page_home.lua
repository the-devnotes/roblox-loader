    --[[ ===================== 14. HOME PAGE ===================== ]]
    local pgHome = ui:page("home", "Utama", "🏠")
    pgHome:section("Status")
    local homeStatus = pgHome:card({
        {"Steal", "-"},
        {"Hatch", "-"},
        {"Sell", "-"},
        {"Area", "-"},
        {"Base", "-"},
        {"Egg area", "-"},
        {"Kandidat", "-"},
    })

    pgHome:section("Kontrol Cepat")
    local homeSteal = pgHome:toggle("Auto Steal Egg", state.steal, function(v) setFlag("steal", v) end)
    bind("steal", homeSteal)
    local homeBest = pgHome:toggle("Pilih Egg Terbaik", state.best, function(v) setFlag("best", v) end)
    bind("best", homeBest)
    local homeHatch = pgHome:toggle("Auto Hatch", state.hatch, function(v) setFlag("hatch", v) end)
    bind("hatch", homeHatch)
    local homeSell = pgHome:toggle("Auto Sell Pets", state.sell, function(v) setFlag("sell", v) end)
    bind("sell", homeSell)

    pgHome:buttonRow({
        { text = "TP Area", callback = function() tpArea(state.area) end },
        { text = "TP Base", callback = tpBase },
        { text = "Ambil 1x", callback = manualSteal, variant = "primary" },
    })
    pgHome:note("Aktifkan Auto Steal lalu atur Best Egg di halaman Filter. Kalau filter terlalu ketat, script otomatis fallback (bisa dimatikan).")

