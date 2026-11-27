    --[[ ===================== 21. DASHBOARD UPDATE ===================== ]]
    local function refreshHome()
        if not homeStatus then return end
        if ui.current ~= "home" then return end
        if state.steal then
            homeStatus.set("Ambil", state.best and "Aktif - Terbaik" or "Aktif - Bergiliran", C.green)
        else
            homeStatus.set("Ambil", "Mati", C.sub)
        end
        homeStatus.set("Tetas", state.hatch and "Aktif" or "Mati", state.hatch and C.green or C.sub)
        homeStatus.set("Jual", state.sell and "Aktif" or "Mati", state.sell and C.green or C.sub)
        homeStatus.set("Area", AREAS[state.area][1] .. (state.allAreas and " (semua)" or ""), C.text)

        local b, src = basePos()
        if b then
            homeStatus.set("Base", tostring(src) .. " (" .. math.floor(b.X) .. "," .. math.floor(b.Z) .. ")", C.text)
        else
            homeStatus.set("Base", "belum diset", C.yellow)
        end

        local eggs = areaEggs()
        homeStatus.set("Egg area", tostring(#eggs), C.text)
        if #eggs > 0 then
            local best = pickBest(eggs, true)
            if best then
                local i = best.info
                homeStatus.set("Kandidat", tostring(i.name) .. " | " .. fmtVal(i.val) .. " | " .. fmtKg(i.weight), C.green)
            else
                homeStatus.set("Kandidat", "filter kosong", C.yellow)
            end
        else
            homeStatus.set("Kandidat", "tidak ada egg", C.sub)
        end
    end
    updateHome = refreshHome

