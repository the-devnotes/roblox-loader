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

