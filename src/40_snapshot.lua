    --[[ ===================== 8. SNAPSHOT SERVER ===================== ]]
    local snapCache = {}
    local snapByName = {}
    local snapMeta = {}
    local snapAt = -1e9
    local snapLastErr = nil

    local function netRemote(name)
        local net = ReplicatedStorage:FindFirstChild("Network")
        if not net then return nil end
        return net:FindFirstChild(name, true)
    end

    -- Simpan data per kategori (AssetCategory / PetDisplayName) supaya egg tanpa
    -- atribut rarity/value/weight tetap bisa diisi dari snapshot / record server.
    local function applyCategoryMeta(cat, v)
        if type(cat) ~= "string" or cat == "" or genericEggName(cat) or type(v) ~= "table" then return end
        local key = string.lower(cat)

        local pr = tonumber(v.ProgressionOrder or v.OriginalImportNumber)
        if pr and pr > 0 and pr > (categoryProg[key] or 0) then categoryProg[key] = pr end

        local r = rarityOf(v.Rarity or v.Tier or v.Grade)
        if r > (categoryRarity[key] or 0) then categoryRarity[key] = r end

        local val = parseValue(v.Value or v.Money or v.PerSecond or v.Price or v.Worth or v.Income)
        if val and val > (categoryValue[key] or 0) then categoryValue[key] = val end

        local w = parseValue(v.Weight or v.Kg or v.Mass)
        if w and w > (categoryWeight[key] or 0) then categoryWeight[key] = w end

        local c = parseChance(v.Chance or v.Odds or v.Probability)
        if c and c > (categoryChance[key] or 0) then categoryChance[key] = c end

        local im = assetIdOf(v.Image or v.Icon or v.Texture or v.Thumbnail or v.AssetId)
        if im and not categoryImage[key] then categoryImage[key] = im end
    end

    local function indexSnapshot(t, depth, seen)
        if type(t) ~= "table" or (depth or 0) > 6 then return end
        seen = seen or {}
        if seen[t] then return end
        seen[t] = true
        for k, v in pairs(t) do
            if type(k) == "string" then
                local id = guidOf(k)
                if id and type(v) == "table" then snapCache[string.lower(id)] = v end
            end
            if type(v) == "table" then
                local anyCat = v.AssetCategory or v.Category or v.PetDisplayName or v.DisplayName
                applyCategoryMeta(anyCat, v)

                local uid
                for _, f in ipairs({"Id", "ID", "EggId", "EggID", "Uid", "UID", "Guid", "GUID", "id"}) do
                    local s = v[f]
                    if type(s) == "string" then
                        local id = guidOf(s)
                        if id then
                            snapCache[string.lower(id)] = v
                            uid = string.lower(id)
                        end
                    end
                end
                for _, f in ipairs({"DisplayName", "EggName", "Name"}) do
                    local s = v[f]
                    if type(s) == "string" and #s > 1 and #s < 48 then
                        snapByName[string.lower(s)] = v
                    end
                end
                if uid then
                    snapMeta[uid] = v
                    local cat = v.AssetCategory or v.Category or v.PetDisplayName or v.DisplayName
                    if type(cat) == "string" and cat ~= "" and not genericEggName(cat) then
                        uidCategory[uid] = string.lower(cat)
                    end
                    local aid = v.AreaId or v.Area
                    if type(aid) == "string" then uidArea[uid] = aid end
                    local pr = tonumber(v.ProgressionOrder or v.OriginalImportNumber)
                    if pr and cat and not genericEggName(cat) then categoryProg[string.lower(cat)] = pr end
                end
                indexSnapshot(v, (depth or 0) + 1, seen)
            end
        end
    end

    local snapEventConn = nil
    local unpackArgs = table.unpack or unpack
    local snapLogAt = -1e9

    local function argSig(args)
        local parts = {}
        for _, a in ipairs(args) do
            parts[#parts + 1] = type(a) == "table" and ("(" .. ser(a) .. ")") or tostring(a)
        end
        return table.concat(parts, "|")
    end

    local function noteSnap(msg, verbose)
        if verbose or os.clock() - snapLogAt > 30 then
            snapLogAt = os.clock()
            log(msg)
        end
    end

    local function snapCount()
        local n = 0
        for _ in pairs(snapCache) do n = n + 1 end
        return n
    end

    local function refreshSnapshot(verbose)
        local rf = netRemote("Eggs: RequestAreaEggSnapshot")
        if not rf then
            if verbose then log("Snapshot remote tidak ada (ReplicatedStorage.Network).") end
            return false
        end

        if rf:IsA("RemoteEvent") then
            if not snapEventConn then
                snapEventConn = rf.OnClientEvent:Connect(function(...)
                    for i = 1, select("#", ...) do
                        indexSnapshot((select(i, ...)), 0)
                    end
                    snapAt = os.clock()
                end)
            end
            pcall(function() rf:FireServer(state.area) end)
            task.wait(0.45)
            snapAt = os.clock()
            if verbose then log("Snapshot via RemoteEvent dikirim. Ter-index: " .. snapCount()) end
            return true
        end

        if not rf:IsA("RemoteFunction") then
            if verbose then log("Snapshot remote bukan RemoteFunction/RemoteEvent.") end
            return false
        end

        local before = snapCount()
        local areaName = AREAS[state.area][1]
        local attempts = {
            {},
            { state.area },
            { areaName },
            { { AreaId = areaName } },
            { { Area = areaName } },
            { { areaId = areaName } },
            { state.area, areaName },
        }
        local gotResult = false
        local lastErr, lastRes
        for _, args in ipairs(attempts) do
            local ok, res = pcall(function()
                return rf:InvokeServer(unpackArgs(args))
            end)
            if ok then
                gotResult = true
                if not lastRes or (type(lastRes) == "table" and next(lastRes) == nil and type(res) == "table" and next(res) ~= nil) then
                    lastRes = res
                end
                indexSnapshot(res, 0)
                noteSnap("SNAPSHOT RAW (" .. argSig(args) .. "): " .. ser(res):sub(1, 900), verbose)
                if snapCount() > before then break end
                if before > 0 and type(res) == "table" and next(res) ~= nil then break end
            else
                lastErr = tostring(res)
            end
        end

        if not gotResult then
            snapLastErr = lastErr
            if verbose then log("Snapshot error: " .. tostring(lastErr)) end
            return false
        end

        snapAt = os.clock()
        galleryDirty = true
        if verbose then
            log("Snapshot OK, " .. snapCount() .. " egg ter-index (area " .. AREAS[state.area][1] .. ").")
            log("Raw: " .. ser(lastRes):sub(1, 900))
            if lastErr then log("Catatan: " .. lastErr) end
        end
        return true
    end

    -- Runtime snapshot: cadangan kalau AreaEggSnapshot tidak membawa rarity/value.
    local function refreshRuntimeSnapshot(verbose)
        local before = snapCount()
        local areaName = AREAS[state.area][1]
        local attempts = {
            {},
            { state.area },
            { areaName },
            { { AreaId = areaName } },
            { { Area = areaName } },
        }
        -- Dua namespace snapshot: Eggs punya data egg, ActiveAssets punya data
        -- aset aktif (termasuk target steal). Coba keduanya.
        local any = false
        for _, remoteName in ipairs({
            "Eggs: RequestRuntimeSnapshot",
            "ActiveAssets: RequestRuntimeSnapshot",
            "ActiveAssets: RequestStealTarget",
            "Eggs: RequestAreaEggRareSpawnPresentations",
        }) do
            local rf = netRemote(remoteName)
            if rf and rf:IsA("RemoteFunction") then
                for _, args in ipairs(attempts) do
                    local ok, res = pcall(function() return rf:InvokeServer(unpackArgs(args)) end)
                    if ok and res then
                        any = true
                        indexSnapshot(res, 0)
                        noteSnap("RUNTIME RAW [" .. remoteName .. "] (" .. argSig(args) .. "): +"
                            .. (snapCount() - before) .. " entri | " .. ser(res):sub(1, 900), verbose)
                        break
                    end
                end
            elseif verbose then
                log(remoteName .. " remote tidak ada.")
            end
        end
        return any
    end

    -- Probe RequestEggRecord untuk satu egg/kategori. Di-cache supaya tidak spam server.
    -- UID diprioritaskan: dulu kuncinya "cat:egg" karena nama fallback, jadi argumen
    -- Uid tidak pernah terlihat di log.
    local recordLogAt, recordTryAuto, recordTryVerbose = -1e9, false, false
    local function noteRecord(msg, verbose)
        if verbose or os.clock() - recordLogAt > 25 then
            recordLogAt = os.clock()
            log(msg)
        end
    end

    local function probeRecord(uid, cat, areaName, verbose, fullUid)
        local realUid = fullUid or (uid and ("AreaEgg_" .. uid) or nil)
        local key = "uid:" .. tostring(realUid or uid or cat or "-")
        if probeDone[key] and not verbose then return nil end
        probeDone[key] = true

        local rf = netRemote("Eggs: RequestEggRecord")
        if not rf or not rf:IsA("RemoteFunction") then
            if verbose then log("RequestEggRecord remote tidak ada.") end
            return nil
        end

        -- Coba Uid penuh "AreaEgg_<guid>", guid saja, dan bentuk table.
        local ids = {}
        if realUid then ids[#ids + 1] = realUid end
        if uid then
            ids[#ids + 1] = "AreaEgg_" .. uid
            ids[#ids + 1] = uid
        end

        local attempts = {}
        for _, id in ipairs(ids) do
            attempts[#attempts + 1] = { id }
            attempts[#attempts + 1] = { { Uid = id } }
            attempts[#attempts + 1] = { { uid = id } }
            attempts[#attempts + 1] = { { Uuid = id } }
            attempts[#attempts + 1] = { { AssetUid = id } }
            attempts[#attempts + 1] = { { assetUid = id } }
            if areaName then attempts[#attempts + 1] = { areaName, id } end
            attempts[#attempts + 1] = { state.area, id }
        end
        attempts[#attempts + 1] = {}
        if cat and not genericEggName(cat) then
            attempts[#attempts + 1] = { cat }
            if areaName then attempts[#attempts + 1] = { areaName, cat } end
        end

        local sigs = {}
        for _, args in ipairs(attempts) do
            local sig = argSig(args)
            if not sigs[sig] then
                sigs[sig] = true
                local ok, res = pcall(function() return rf:InvokeServer(unpackArgs(args)) end)
                if ok and res ~= nil then
                    if type(res) == "table" then indexSnapshot(res, 0) end
                    local gotCat = (type(res) == "table" and (res.AssetCategory or res.PetDisplayName
                        or res.DisplayName or res.Category)) or cat
                    applyCategoryMeta(gotCat, res)
                    noteRecord("RECORD " .. sig .. ": " .. ser(res):sub(1, 700), verbose)
                    if type(res) == "table" and next(res) ~= nil then return res end
                end
            end
        end
        if (verbose and not recordTryVerbose) or (not verbose and not recordTryAuto) then
            if verbose then recordTryVerbose = true else recordTryAuto = true end
            local list = {}
            for s in pairs(sigs) do list[#list + 1] = s end
            noteRecord("RECORD coba " .. key .. ": " .. table.concat(list, " | "), verbose)
        end
        if verbose then log("RECORD tidak ada untuk " .. key) end
        return nil
    end

    local function debugSummary()
        local function count(t)
            local c = 0
            for _ in pairs(t) do c = c + 1 end
            return c
        end
        return string.format("cache=%d nama=%d kategori=%d rarity=%d value=%d weight=%d",
            snapCount(), count(snapByName), count(uidCategory),
            count(categoryRarity), count(categoryValue), count(categoryWeight))
    end

