    --[[ ===================== 20. INFO PAGE ===================== ]]
    local executorName = "?"
    if type(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        if ok and name then executorName = tostring(name) end
    end

    local function copyDebug()
        local b, src = basePos()
        local text = table.concat({
            "Bike For Eggs - Mobile v5",
            "Player: " .. lp.Name .. " (" .. tostring(lp.UserId) .. ")",
            "Executor: " .. executorName,
            "Area: " .. AREAS[state.area][1] .. (state.allAreas and " + semua" or ""),
            "Steal: " .. tostring(state.steal) .. " | Best: " .. tostring(state.best) .. " | Sort: " .. SORTS[state.sort],
            "Filter: rar=" .. RARITY_NAMES[state.minRar] .. " prog=" .. PROG_NAMES[state.minProg] .. " val=" .. VALUE_NAMES[state.minVal],
            "Fallback: " .. tostring(state.fallback) .. " | Strict: " .. tostring(state.strict) .. " | Lite: " .. tostring(state.lite),
            "Base: " .. (b and (tostring(src) .. " @ " .. math.floor(b.X) .. "," .. math.floor(b.Z)) or "belum"),
            "Egg di area: " .. tostring(#areaEggs()),
        }, "\n")
        if type(setclipboard) == "function" then
            pcall(setclipboard, text)
            ui:toast("Info debug disalin.")
        else
            ui:toast("setclipboard tidak tersedia.", "warn")
        end
    end

    local pgInfo = ui:page("info", "Info", "ℹ️")
    pgInfo:section("Tentang")
    pgInfo:card({
        {"Versi", "v5.8"},
        {"UI", "BFEUI (embedded)"},
        {"Player", lp.Name},
        {"Executor", executorName},
    })
    pgInfo:note("UI ini memakai library mini BFEUI yang ditanam di script, jadi tidak bergantung pada HttpGet. Fitur dipisah per halaman lewat sidebar.")
    pgInfo:note("Halaman Egg menampilkan kartu egg: gambar (preview 3D), value, berat (kg), progression, rarity, dan tombol Steal khusus egg itu.")
    pgInfo:note("Nama/rarity egg yang tidak punya attribute diisi dari snapshot server + event CarryState/ClaimFeedback setelah egg pertama diambil. Klik 'Dump 1 Egg' untuk data mentah.")

    pgInfo:section("Cara Pakai")
    pgInfo:note("1) Halaman Area: pilih area lalu Set Base. 2) Halaman Filter: atur urutan & filter Best Egg. 3) Halaman Steal: aktifkan Auto Steal. 4) Halaman Auto: aktifkan Hatch/Sell kalau perlu.")

    pgInfo:section("Performa")
    local liteToggle = pgInfo:toggle("Mode Ringan (4 kartu)", state.lite, function(v)
        setFlag("lite", v)
        galleryDirty = true
        gallerySig = ""
    end)
    bind("lite", liteToggle)
    pgInfo:note("Mode Ringan mengurangi kartu preview 3D dari 8 ke 4. Scan prompt dan data egg juga di-cache, jadi tidak mengulang GetDescendants tiap loop.")

    pgInfo:section("Kontrol")
    pgInfo:buttonRow({
        { text = "Minimize", callback = function() ui:minimize() end },
        { text = "Tutup UI", callback = function() ui:destroy("close") end, variant = "danger" },
    })
    pgInfo:button("Salin Info Debug", copyDebug)
    pgInfo:note("Anti double-run aktif. Kalau script dijalankan lagi saat UI masih hidup, akan muncul peringatan 'Script sudah berjalan!' dan script kedua berhenti.")

