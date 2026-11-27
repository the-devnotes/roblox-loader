    --[[ ===================== 22. BACKGROUND LOOPS ===================== ]]
    task.spawn(function()
        while running do
            task.wait(0.35)
            if logDirty and ui.current == "log" then
                logDirty = false
                refreshLogUI()
            end
        end
    end)

    task.spawn(function()
        while running do
            task.wait(0.8)
            if ui.current == "home" and updateHome then updateHome() end
        end
    end)

    task.spawn(function()
        while running do
            task.wait(1.5)
            if ui.current == "egg" and galleryRefresh then
                galleryDirty = false
                pcall(galleryRefresh, false)
            end
        end
    end)

    task.spawn(function()
        while running do
            task.wait(0.25)
            if state.steal and not busy then
                busy = true
                local ok, err = pcall(stealOne, false)
                if not ok then log("ERROR stealOne: " .. tostring(err)) end
                busy = false
                task.wait(math.max(0.2, state.stealDelay))
            end
        end
    end)

    task.spawn(function()
        while running do
            task.wait(0.4)
            if state.hatch then
                local ok, err = pcall(function()
                    scanPrompts()
                    local it = nearestPrompt(promptCache.hatch)
                    if it then firePrompt(it.prompt) end
                end)
                if not ok then log("ERROR hatch: " .. tostring(err)) end
                task.wait(math.max(0.5, state.hatchDelay))
            end
        end
    end)

    task.spawn(function()
        while running do
            task.wait(0.4)
            if state.sell then
                local ok, err = pcall(function()
                    scanPrompts()
                    local it = nearestPrompt(promptCache.sell)
                    if it then firePrompt(it.prompt) end
                end)
                if not ok then log("ERROR sell: " .. tostring(err)) end
                task.wait(math.max(0.5, state.sellDelay))
            end
        end
    end)

    task.spawn(function()
        local ok, net = pcall(function()
            return ReplicatedStorage:WaitForChild("Network", 10)
        end)
        if not ok or not net then return end

        local function walkEvent(t, fn, depth, seen, parentKey)
            if type(t) ~= "table" or (depth or 0) > 5 then return end
            seen = seen or {}
            if seen[t] then return end
            seen[t] = true
            fn(t, parentKey)
            for k, v in pairs(t) do
                if type(v) == "table" then walkEvent(v, fn, (depth or 0) + 1, seen, k) end
            end
        end

        local function vecOf(v)
            local tv = typeof(v)
            if tv == "CFrame" then return v.Position end
            if tv == "Vector3" then return v end
            if type(v) == "table" then
                if v.X then return Vector3.new(v.X, v.Y or 0, v.Z or 0) end
                if v[1] then return Vector3.new(v[1], v[2] or 0, v[3] or 0) end
            end
            return nil
        end

        local function matchEgg(pos, areaId)
            if not pos then return nil end
            local best, bd
            for _, e in ipairs(areaEggs(true)) do
                local ai = eggAreaIndex(e)
                if not areaId or string.lower(AREAS[ai][1]) == string.lower(areaId) then
                    local d = (e.pos - pos).Magnitude
                    if not bd or d < bd then best, bd = e, d end
                end
            end
            if best and (bd or 9999) < 15 then return best end
            return nil
        end

        local function readRarity(t)
            for _, k in ipairs({"Rarity", "rarity", "RARITY", "Tier", "Grade"}) do
                local r = rarityOf(t[k])
                if r > 0 then return r end
            end
            return 0
        end

        for _, name in ipairs({
            "Eggs: AreaEggCarryState",
            "Eggs: AreaEggClaimFeedback",
            "Eggs: AreaEggUpdated",
            "Eggs: AreaEggBatchUpdated",
            "Eggs: RuntimeOwnerUpdated",
            "ActiveAssets: RuntimeOwnerUpdated",
            "ActiveAssets: StealTargetEvent",
        }) do
            local re = net:FindFirstChild(name, true)
            if re and re:IsA("RemoteEvent") then
                local shown = 0
                re.OnClientEvent:Connect(function(...)
                    shown = shown + 1
                    local changed = false
                    for i = 1, select("#", ...) do
                        local v = select(i, ...)
                        if type(v) == "table" then
                            pcall(indexSnapshot, v, 0)
                            walkEvent(v, function(t, parentKey)
                                local rar = readRarity(t)
                                local cat = t.AssetCategory or t.Category or t.DisplayName or t.PetDisplayName

                                -- Eggs: RuntimeOwnerUpdated mengirim Records={Egg_<guid>={AssetCategory=...}}.
                                -- Ini kunci langsung ke model AreaEgg_<guid> di plot.
                                if type(parentKey) == "string" and string.sub(parentKey, 1, 4) == "Egg_" then
                                    local g = guidOf(parentKey)
                                    if g then
                                        local ukey = string.lower(g)
                                        if type(cat) == "string" and cat ~= "" then
                                            uidCategory[ukey] = string.lower(cat)
                                            changed = true
                                        end
                                        snapCache[ukey] = t
                                        snapMeta[ukey] = t
                                        if type(t.AreaId) == "string" then uidArea[ukey] = t.AreaId end
                                        if rar > 0 and type(cat) == "string" then
                                            categoryRarity[string.lower(cat)] = rar
                                        end
                                    end
                                end

                                -- AreaEggUpdated kadang mengirim Uid="AreaEgg_<guid>" langsung.
                                -- Ini paling akurat: tidak perlu menebak lewat posisi.
                                local areaUid = t.Uid or t.UID or t.EggUid
                                if type(areaUid) == "string" and string.find(areaUid, "AreaEgg", 1, true) then
                                    local g = guidOf(areaUid)
                                    if g then
                                        local ukey = string.lower(g)
                                        snapCache[ukey] = t
                                        snapMeta[ukey] = t
                                        if type(cat) == "string" and cat ~= "" then
                                            uidCategory[ukey] = string.lower(cat)
                                        end
                                        if type(t.AreaId) == "string" then uidArea[ukey] = t.AreaId end
                                        if rar > 0 and type(cat) == "string" then
                                            categoryRarity[string.lower(cat)] = rar
                                        end
                                        changed = true
                                    end
                                end

                                -- AreaEggUpdated juga bisa mengirim AssetCategory + BoundsCFrame
                                -- tanpa Uid. Cocokkan lewat posisi egg terdekat di area yang sama.
                                if type(cat) == "string" and cat ~= ""
                                    and string.find(name, "AreaEgg", 1, true) then
                                    local pos = vecOf(t.BoundsCFrame or t.CFrame or t.Position)
                                    local e = matchEgg(pos, t.AreaId)
                                    if e and e.uid then
                                        uidCategory[e.uid] = string.lower(cat)
                                        if type(t.AreaId) == "string" then uidArea[e.uid] = t.AreaId end
                                        if string.find(name, "AreaEggUpdated", 1, true) then
                                            snapCache[e.uid] = t
                                            snapMeta[e.uid] = t
                                        end
                                        if rar > 0 then categoryRarity[string.lower(cat)] = rar end
                                        changed = true
                                    end
                                end

                                if type(cat) == "string" and cat ~= "" then
                                    local key = string.lower(cat)
                                    if rar > 0 and (not categoryRarity[key] or rar > categoryRarity[key]) then
                                        categoryRarity[key] = rar
                                        changed = true
                                    end
                                    local pr = tonumber(t.ProgressionOrder or t.OriginalImportNumber)
                                    if pr and pr > 0 then categoryProg[key] = pr end
                                end
                                -- Feedback tidak punya Uid: cocokkan lewat posisi egg terdekat.
                                local p = t.Position
                                if type(p) == "table" and p.X and rar > 0 then
                                    local bestE, bd
                                    for _, e in ipairs(areaEggs(true)) do
                                        local d = (e.pos - Vector3.new(p.X, p.Y or 0, p.Z or 0)).Magnitude
                                        if not bd or d < bd then bestE, bd = e, d end
                                    end
                                    if bestE and bestE.uid and (bd or 9999) < 8 then
                                        uidCategory[bestE.uid] = type(cat) == "string" and string.lower(cat) or uidCategory[bestE.uid]
                                        if type(cat) == "string" then
                                            uidArea[bestE.uid] = AREAS[eggAreaIndex(bestE)][1]
                                            categoryRarity[string.lower(cat)] = rar
                                            changed = true
                                        end
                                    end
                                end
                                if string.find(name, "CarryState", 1, true)
                                    or string.find(name, "StealTarget", 1, true) then
                                    local uid = t.Uid or t.UID or t.EggUid or t.AssetUid
                                    if type(uid) == "string" and uid ~= "" then
                                        local ukey = string.lower(guidOf(uid) or uid)
                                        assetUidHints[ukey] = true
                                        if string.find(name, "CarryState", 1, true) then
                                            carryEventSeen = true
                                        end
                                        if string.find(name, "CarryState", 1, true)
                                            and truthy(t.IsCarrying) then
                                            lastCarry = {
                                                uid = ukey, area = t.AreaId,
                                                category = type(cat) == "string" and cat or nil,
                                                at = os.clock(),
                                            }
                                        end
                                        if type(cat) == "string" then uidCategory[ukey] = string.lower(cat) end
                                        if type(t.AreaId) == "string" then uidArea[ukey] = t.AreaId end
                                    end
                                end
                            end)
                        end
                    end
                    if changed then
                        clearInfoCache()
                        galleryDirty = true
                        gallerySig = ""
                    end
                    if shown > 4 or not running then return end
                    local t = {}
                    for i = 1, select("#", ...) do t[i] = ser((select(i, ...))) end
                    log("EVENT " .. name .. ": " .. table.concat(t, ", "):sub(1, 500))
                end)
            end
        end
    end)

