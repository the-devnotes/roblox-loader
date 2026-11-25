    --[[ ===================== 18. AREA PAGE ===================== ]]
    local pgArea = ui:page("area", "Area", "🗺️")
    pgArea:section("Pilih Area")
    local areaDrop = pgArea:dropdown("Area", AREA_NAMES, state.area, function(_, idx) setArea(idx, false, true) end)
    areaRefs[#areaRefs + 1] = areaDrop

    local autoAreaToggle = pgArea:toggle("Cari Area Terbaik Otomatis", state.autoArea, function(v) setFlag("autoArea", v) end)
    bind("autoArea", autoAreaToggle)
    areaAutoRef = autoAreaToggle

    pgArea:buttonRow({
        { text = "< Sebelumnya", callback = function() setArea(state.area - 1, false, true) end },
        { text = "Cari Area Terbaik", callback = function() pcall(pickBestArea, false) end, variant = "primary" },
        { text = "Berikutnya >", callback = function() setArea(state.area + 1, false, true) end },
    })
    pgArea:button("Ke Area", function() tpArea(state.area) end)

    pgArea:divider()
    pgArea:section("Base")
    pgArea:buttonRow({
        { text = "Ke Base", callback = tpBase },
        { text = "Jadikan Base di Sini", callback = function()
            if setBaseHere() then ui:toast("Base diset.") else ui:toast("Karakter belum siap.", "warn") end
        end },
    })
    pgArea:note("Base dipakai untuk kembali setelah mengambil egg. Kalau belum diset, script mencari posisinya sendiri.")

