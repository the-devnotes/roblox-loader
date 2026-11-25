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
        if type(cat) ~= "string" or cat == "" or type(v) ~= "table" then return end
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
                    if type(cat) == "string" and cat ~= "" then uidCategory[uid] = string.lower(cat) end
                    local aid = v.AreaId or v.Area
                    if type(aid) == "string" then uidArea[uid] = aid end
                    local pr = tonumber(v.ProgressionOrder or v.OriginalImportNumber)
                    if pr and cat then categoryProg[string.lower(cat)] = pr end
                end
                indexSnapshot(v, (depth or 0) + 1, seen)
            end
        end
    end

    local snapEventConn = nil
    local unpackArgs = table.unpack or unpack

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
        local attempts = {
            {},
            { state.area },
            { AREAS[state.area][1] },
            { state.area, AREAS[state.area][1] },
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
        local rf = netRemote("Eggs: RequestRuntimeSnapshot")
        if not rf or not rf:IsA("RemoteFunction") then
            if verbose then log("RequestRuntimeSnapshot remote tidak ada.") end
            return false
        end
        local before = snapCount()
        local attempts = { {}, { state.area } }
        for _, args in ipairs(attempts) do
            local ok, res = pcall(function() return rf:InvokeServer(unpackArgs(args)) end)
            if ok and res then
                indexSnapshot(res, 0)
                if verbose then
                    log("Runtime snapshot: +" .. (snapCount() - before) .. " entri baru.")
                    log("RUNTIME RAW: " .. ser(res):sub(1, 900))
                end
                return true
            end
        end
        return false
    end

    -- Probe RequestEggRecord untuk satu egg/kategori. Di-cache supaya tidak spam server.
    local function probeRecord(uid, cat, areaName, verbose, fullUid)
        if not uid and not cat and not fullUid then return nil end
        local key = cat and ("cat:" .. string.lower(cat)) or ("uid:" .. tostring(fullUid or uid))
        if probeDone[key] and not verbose then return nil end
        probeDone[key] = true

        local rf = netRemote("Eggs: RequestEggRecord")
        if not rf or not rf:IsA("RemoteFunction") then
            if verbose then log("RequestEggRecord remote tidak ada.") end
            return nil
        end

        -- Server memakai Uid penuh "AreaEgg_<guid>", bukan guid saja.
        local ids = {}
        if fullUid then ids[#ids + 1] = fullUid end
        if uid then
            ids[#ids + 1] = "AreaEgg_" .. uid
            ids[#ids + 1] = uid
        end

        local attempts = {}
        for _, id in ipairs(ids) do
            attempts[#attempts + 1] = { id }
            if areaName then attempts[#attempts + 1] = { areaName, id } end
            attempts[#attempts + 1] = { state.area, id }
        end
        if cat then
            attempts[#attempts + 1] = { cat }
            if areaName then attempts[#attempts + 1] = { areaName, cat } end
            attempts[#attempts + 1] = { state.area, cat }
        end

        local seen = {}
        for _, args in ipairs(attempts) do
            local sig = table.concat(args, "|")
            if not seen[sig] then
                seen[sig] = true
                local ok, res = pcall(function() return rf:InvokeServer(unpackArgs(args)) end)
                if ok and res ~= nil then
                    if type(res) == "table" then indexSnapshot(res, 0) end
                    local gotCat = cat or (type(res) == "table" and (res.AssetCategory or res.DisplayName or res.Category))
                    applyCategoryMeta(gotCat, res)
                    if verbose then log("RECORD " .. sig .. ": " .. ser(res):sub(1, 700)) end
                    if type(res) == "table" and next(res) ~= nil then return res end
                end
            end
        end
        if verbose then log("RECORD tidak ada untuk " .. tostring(key)) end
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

