    --[[ ===================== 12. STEAL ===================== ]]
    local busy = false
    local stealIdx = 0
    local lastNoEggLog = 0
    local lastPromptLog = 0
    local lastSnapTry = -1e9
    local lastAutoAreaTry = -1e9

    local function nearestSmartPart()
        local r = getRoot()
        if not r then return nil end
        local best, bd
        for _, d in ipairs(smartParts()) do
            local dist = (d.Position - r.Position).Magnitude
            if not bd or dist < bd then best, bd = d, dist end
        end
        return best, bd
    end

    local function doSteal(e, manual)
        if not e then return false end
        local i = e.info or eggInfoCached(e.m)
        local targetUid = e.uid
        local targetArea = AREAS[state.area][1]
        -- Ambil posisi base SEBELUM mendekat, supaya kabur bisa langsung dilakukan.
        local b, baseSrc = basePos()

        local fired, anyPrompt, confirmed = false, false, false
        for attempt = 1, 3 do
            local pos = eggPos(e.m) or e.pos
            -- Dekatkan ke egg asli; jangan fire prompt dari jarak jauh (server menolak).
            teleport(pos + Vector3.new(0, 1, 2))
            task.wait(0.2)

            local p, pd = waitForCarryPrompt(attempt == 1 and 1.0 or 0.5)
            if not p then
                local sp = nearestSmartPart()
                if sp then
                    teleport(sp.Position)
                    task.wait(0.15)
                    p, pd = carryPrompt()
                end
            end
            if not p then break end

            anyPrompt = true
            if pd and pd > 12 then
                local part = p.Parent
                if part and part:IsA("BasePart") then
                    teleport(part.Position)
                    task.wait(0.1)
                end
            end

            local fireAt = os.clock()
            for _ = 1, 3 do
                if not p.Enabled then break end
                if firePrompt(p, 12) then fired = true end
                task.wait(0.1)
            end

            -- PENTING: kabur dulu dari penjaga, baru tunggu konfirmasi server.
            if b then teleport(b) end

            local gotConfirm = false
            local deadline = os.clock() + 0.8
            while os.clock() < deadline do
                task.wait(0.08)
                if carryEventSeen and lastCarry and lastCarry.at >= fireAt - 0.1 then
                    gotConfirm = true
                    break
                end
            end

            if gotConfirm then
                local uidOk = not targetUid or not lastCarry.uid
                    or lastCarry.uid == targetUid
                    or (uidCategory[lastCarry.uid] and uidCategory[targetUid]
                        and uidCategory[lastCarry.uid] == uidCategory[targetUid])
                local areaOk = not lastCarry.area
                    or string.lower(tostring(lastCarry.area)) == string.lower(targetArea)
                if uidOk and areaOk then
                    confirmed = true
                    break
                end
                if os.clock() - lastPromptLog > 4 then
                    lastPromptLog = os.clock()
                    log(string.format("Steal salah target: minta %s di %s, dapat %s di %s. Coba lagi.",
                        tostring(targetUid or i.name):sub(1, 12), targetArea,
                        tostring(lastCarry.uid or "?"):sub(1, 12), tostring(lastCarry.area or "?")))
                end
            elseif not carryEventSeen then
                -- Environment tanpa event CarryState: anggap prompt berhasil.
                confirmed = fired
                break
            elseif os.clock() - lastPromptLog > 4 then
                lastPromptLog = os.clock()
                log("Prompt terkirim, sudah kabur ke base dulu sambil tunggu konfirmasi CarryState.")
            end
        end

        if confirmed then
            log("Prompt CarryAreaEgg berhasil: " .. tostring(i.name) .. " @ " .. targetArea .. ".")
        elseif anyPrompt then
            log("Prompt ditemukan tapi gagal mengambil " .. tostring(i.name) .. ".")
        elseif os.clock() - lastPromptLog > 6 then
            lastPromptLog = os.clock()
            log("Prompt CarryAreaEgg tidak ditemukan (mungkin masih membawa egg).")
        end

        galleryDirty = true
        if b then
            teleport(b)
            log("Kembali ke base" .. (baseSrc and (" (" .. tostring(baseSrc) .. ")") or "") .. ".")
            task.wait(manual and 1.6 or 1.2)
        elseif confirmed then
            log("Base belum diketahui. Buka halaman Area lalu tekan Set Base.")
        end
        return confirmed
    end

    local function stealOne(manual)
        if state.autoArea and os.clock() - lastAutoAreaTry > 12 then
            lastAutoAreaTry = os.clock()
            pcall(pickBestArea, not manual)
        end
        local eggs = areaEggs()
        if #eggs == 0 then
            if os.clock() - lastNoEggLog > 6 then
                lastNoEggLog = os.clock()
                log("Tidak ada egg di AreaEggSlotsClient untuk area " .. AREAS[state.area][1] .. ".")
            end
            return false
        end

        local e
        if state.best then
            if os.clock() - snapAt > 6 and os.clock() - lastSnapTry > 3 then
                lastSnapTry = os.clock()
                if refreshSnapshot(false) then
                    infoCache = setmetatable({}, { __mode = "k" })
                end
            end
            e = pickBest(eggs)
            if not e then return false end
            local i = e.info
            log(string.format("[Best] %s | rar=%s prog=%s val=%s berat=%s chance=%s%s",
                tostring(i.name), tostring(i.rar), tostring(i.prog), fmtVal(i.val),
                fmtKg(i.weight),
                i.chance > 0 and ("1/" .. fmtVal(i.chance)) or "-",
                i.event and " EVENT" or (i.themed and " themed" or "")))
        else
            stealIdx = (stealIdx % #eggs) + 1
            e = eggs[stealIdx]
            log(string.format("[Rotasi] egg %d/%d %s", stealIdx, #eggs, tostring(e.m.Name):sub(1, 24)))
        end

        return doSteal(e, manual)
    end

    -- Dipakai tombol Steal di kartu halaman Egg.
    local function stealEgg(e)
        if not e then return end
        if busy then
            if ui then ui:toast("Masih sibuk, tunggu sebentar.", "warn") end
            return
        end

        -- Ambil entri terbaru supaya posisi egg tidak basi.
        local fresh
        for _, x in ipairs(areaEggs()) do
            if x.m == e.m or (e.m and x.m.Name == e.m.Name) then fresh = x; break end
        end
        if not fresh then
            if ui then ui:toast("Egg sudah tidak ada. Muat ulang galeri.", "warn") end
            galleryDirty = true
            return
        end
        e = fresh

        busy = true
        local i = e.info or eggInfoCached(e.m)
        if ui then ui:toast("Mengambil " .. tostring(i.name) .. "...") end
        task.spawn(function()
            local ok, err = pcall(doSteal, e, true)
            if not ok then log("ERROR steal egg: " .. tostring(err)) end
            busy = false
            galleryDirty = true
        end)
    end

