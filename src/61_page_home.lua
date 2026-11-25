    --[[ ===================== 14. HOME PAGE ===================== ]]
    local pgHome = ui:page("home", "Utama", "🏠")
    pgHome:section("Status")
    local homeStatus = pgHome:card({
        {"Ambil", "-"},
        {"Tetas", "-"},
        {"Jual", "-"},
        {"Area", "-"},
        {"Base", "-"},
        {"Egg area", "-"},
        {"Kandidat", "-"},
    })

    pgHome:section("Kontrol Cepat")
    local homeSteal = pgHome:toggle("Ambil Egg Otomatis", state.steal, function(v) setFlag("steal", v) end)
    bind("steal", homeSteal)
    local homeBest = pgHome:toggle("Ambil Egg Terbaik", state.best, function(v) setFlag("best", v) end)
    bind("best", homeBest)
    local homeHatch = pgHome:toggle("Tetaskan Egg Otomatis", state.hatch, function(v) setFlag("hatch", v) end)
    bind("hatch", homeHatch)
    local homeSell = pgHome:toggle("Jual Pet Otomatis", state.sell, function(v) setFlag("sell", v) end)
    bind("sell", homeSell)

    pgHome:buttonRow({
        { text = "Ke Area", callback = function() tpArea(state.area) end },
        { text = "Ke Base", callback = tpBase },
        { text = "Ambil Satu", callback = manualSteal, variant = "primary" },
    })
    pgHome:note("Nyalakan Ambil Egg Otomatis, lalu atur rarity minimum di halaman Filter. Kalau tidak ada yang cocok, script mengambil egg apa adanya.")

