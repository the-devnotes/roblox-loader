    --[[ ===================== 9. EGG INFO & FILTER ===================== ]]
    local function truthy(v)
        if v == nil or v == false then return false end
        if type(v) == "number" then return v ~= 0 end
        local s = tostring(v):lower():gsub("%s+", "")
        return s ~= "" and s ~= "false" and s ~= "0" and s ~= "none" and s ~= "no" and s ~= "null"
    end

    local function assetIdOf(s)
        if type(s) ~= "string" then return nil end
        local id = s:match("rbxassetid://(%d+)") or s:match("rbxthumb://[^%d]*(%d+)")
        if not id and s:match("^%d%d%d%d%d+$") then id = s end
        return id
    end

    -- Parsing rarity HANYA dari field yang jelas (Rarity, Tier, claim feedback, dll).
    -- "Cosmic" di nama area tidak boleh masuk lewat jalur ini.
    local function rarityOf(value)
        if type(value) == "number" then
            if value >= 1 and value <= #RARITY then return math.floor(value) end
            return 0
        end
        if type(value) ~= "string" then return 0 end
        local s = value:lower():gsub("[%s_%-]+", "")
        if s == "" then return 0 end
        local best = 0
        for word, idx in pairs(RARITY_ALIAS) do
            local w = word:gsub("[%s_%-]+", "")
            if s == w then
                if idx > best then best = idx end
            end
        end
        return best
    end

    local function scanKV(info, key, value)
        local kk = tostring(key):lower():gsub("[%s_%-]", "")
        if kk == "displayname" or kk == "name" or kk == "eggname"
            or kk == "assetcategory" or kk == "petdisplayname" or kk == "petname"
            or kk == "assetname" or kk == "category" then
            if type(value) == "string" and value ~= "" and #value < 48 then info.name = value end
        elseif kk:find("progression", 1, true) or kk:find("progorder", 1, true) or kk == "order" or kk == "level" or kk == "stage" then
            local n = tonumber(value)
            if n and n > info.prog then info.prog = n end
        elseif kk:find("chance", 1, true) or kk:find("odds", 1, true) or kk:find("probability", 1, true) or kk:find("luck", 1, true) then
            local n = parseChance(value) or tonumber(value)
            if n and n > info.chance then info.chance = n end
        elseif kk:find("weight", 1, true) or kk:find("mass", 1, true) or kk == "kg" then
            local n = parseValue(value)
            if n and n > info.weight then info.weight = n end
        elseif kk:find("image", 1, true) or kk:find("icon", 1, true) or kk:find("thumbnail", 1, true)
            or kk:find("texture", 1, true) or kk:find("decal", 1, true) or kk:find("assetid", 1, true) then
            local id = assetIdOf(value)
            if id then info.imageId = id end
        elseif kk:find("rarity", 1, true) or kk:find("tier", 1, true) or kk:find("grade", 1, true)
            or kk:find("quality", 1, true) or kk:find("class", 1, true) or kk == "rank" then
            if type(value) == "number" then
                info.rarNum = math.max(info.rarNum, value)
                if value >= 1 and value <= #RARITY then
                    info.rar = math.max(info.rar, math.floor(value))
                end
            else
                local r = rarityOf(value)
                if r > info.rar then info.rar = r end
            end
        elseif kk:find("event", 1, true) or kk:find("night", 1, true) or kk:find("limited", 1, true) or kk:find("special", 1, true) then
            if truthy(value) then info.event = true end
        elseif kk:find("value", 1, true) or kk:find("price", 1, true) or kk:find("worth", 1, true)
            or kk:find("income", 1, true) or kk:find("persecond", 1, true) or kk:find("psec", 1, true) then
            local n = parseValue(value)
            if n and n > info.val then info.val = n end
        end
    end

    local function scanTable(info, t, depth, seen)
        if type(t) ~= "table" or depth > 4 then return end
        seen = seen or {}
        if seen[t] then return end
        seen[t] = true
        for k, v in pairs(t) do
            if type(v) == "table" then
                scanTable(info, v, depth + 1, seen)
            else
                scanKV(info, k, v)
            end
        end
    end

    local function cleanEggName(s)
        s = tostring(s or "")
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        if s == "" then return "" end
        if s:find("^%x%x%x%x%x%x%x%x%-") then return "" end
        if s:find("AreaEgg", 1, true) and #s > 22 then return "" end
        if #s > 48 then return "" end
        return s
    end

    local function looksLikeStat(txt)
        local tl = tostring(txt):lower()
        return tl:find("value", 1, true) or tl:find("berat", 1, true) or tl:find("weight", 1, true)
            or tl:find("kg", 1, true) or tl:find("1 in", 1, true) or tl:find("1/", 1, true)
            or tl:find("rarity", 1, true) or tl:find("chance", 1, true) or tl:find("odds", 1, true)
            or tl:find("progression", 1, true) or tl:find("$", 1, true) or tl:find("coin", 1, true)
    end

    local function rarityFromText(txt)
        local tl = tostring(txt):lower():gsub("[%s_%-]+", "")
        if #tl > 32 then return 0 end
        local best = 0
        for word, idx in pairs(RARITY_ALIAS) do
            local w = word:gsub("[%s_%-]+", "")
            if tl == w then
                if idx > best then best = idx end
            end
        end
        return best
    end

    local function eggInfo(m)
        local themedAttr = m:GetAttribute("OurThemedEgg")
        local disp = m:GetAttribute("DisplayName")
        local theme = m:GetAttribute("EggTheme")
        local info = {
            name = cleanEggName(disp),
            theme = theme,
            prog = tonumber(m:GetAttribute("ProgressionOrder")) or 0,
            themed = truthy(themedAttr),
            event = false,
            weight = 0,
            imageId = nil,
            rar = 0, rarNum = 0, val = 0, chance = 0,
            texts = {}, attrs = {},
        }

        local function scanAttrs(obj, record)
            local ok, attrs = pcall(function() return obj:GetAttributes() end)
            if not ok or not attrs then return end
            for k, v in pairs(attrs) do
                if type(v) ~= "table" then
                    if record then info.attrs[#info.attrs + 1] = tostring(k) .. "=" .. tostring(v) end
                    scanKV(info, k, v)
                end
            end
        end

        scanAttrs(m, true)

        local scannedIds = {}
        local eggUid = guidOf(m.Name) and string.lower(guidOf(m.Name)) or nil
        local function applyMeta(key)
            local cat = uidCategory[key]
            if cat then
                if info.name == "" then info.name = cat end
                local r = categoryRarity[cat]
                if r and r > info.rar then info.rar = r end
                local p = categoryProg[cat]
                if p and p > info.prog then info.prog = p end
                local v = categoryValue[cat]
                if v and v > info.val then info.val = v end
                local w = categoryWeight[cat]
                if w and w > info.weight then info.weight = w end
                local c = categoryChance[cat]
                if c and c > info.chance then info.chance = c end
                local im = categoryImage[cat]
                if im and not info.imageId then info.imageId = im end
            end
            local aid = uidArea[key]
            if aid then info.areaId = aid end
        end
        local function tryId(name)
            local id = guidOf(name)
            if not id then return end
            local key = string.lower(id)
            if scannedIds[key] then return end
            scannedIds[key] = true
            local data = snapCache[key] or snapMeta[key]
            if data then scanTable(info, data, 0) end
            applyMeta(key)
        end
        tryId(m.Name)
        tryId(m:GetAttribute("UniqueId"))
        tryId(m:GetAttribute("Guid"))

        -- Slot/folder induk kadang menyimpan data egg (progression, rarity, dll).
        local anc = m.Parent
        for _ = 1, 3 do
            if not anc or anc == workspace then break end
            scanAttrs(anc, false)
            tryId(anc.Name)
            local okKids, kids = pcall(function() return anc:GetChildren() end)
            if okKids and kids then
                for _, k in ipairs(kids) do
                    if k ~= m then
                        local okv, isv = pcall(function() return k:IsA("ValueBase") end)
                        if okv and isv then scanKV(info, k.Name, k.Value) end
                    end
                end
            end
            anc = anc.Parent
        end

        local desc = m:GetDescendants()
        for _, d in ipairs(desc) do
            local ok, attrs = pcall(function() return d:GetAttributes() end)
            if ok and attrs then
                for k, v in pairs(attrs) do
                    local kk = tostring(k):lower()
                    if kk:find("rarity", 1, true) or kk:find("tier", 1, true) or kk:find("grade", 1, true)
                        or kk:find("progression", 1, true) or kk:find("chance", 1, true)
                        or kk:find("weight", 1, true) or kk:find("event", 1, true)
                        or kk:find("image", 1, true) or kk:find("icon", 1, true) or kk:find("texture", 1, true)
                        or kk:find("value", 1, true) or kk:find("price", 1, true) or kk:find("income", 1, true) then
                        scanKV(info, k, v)
                    end
                end
            end
        end

        local bestName = nil
        for _, d in ipairs(desc) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                local txt = d.Text
                if txt and txt ~= "" then
                    info.texts[#info.texts + 1] = d.Name .. "=" .. txt
                    local nl = d.Name:lower()
                    local tl = txt:lower()

                    if nl:find("rarity", 1, true) or nl:find("tier", 1, true) or nl:find("grade", 1, true) then
                        local r = rarityOf(txt)
                        if r > info.rar then info.rar = r end
                    end

                    if nl:find("chance", 1, true) or nl:find("odds", 1, true) or nl:find("luck", 1, true) or tl:find("1 in", 1, true) then
                        local c = parseChance(txt)
                        if c and c > info.chance then info.chance = c end
                    end
                    local kg = txt:match("([%d%.]+)%s*[kKmM]?%s*kg")
                    if kg then
                        local n = parseValue(kg)
                        if n and n > info.weight then info.weight = n end
                    elseif nl:find("weight", 1, true) or nl:find("mass", 1, true) then
                        local n = parseValue(txt)
                        if n and n > info.weight then info.weight = n end
                    end
                    if nl:find("value", 1, true) or nl:find("price", 1, true) or nl:find("worth", 1, true)
                        or nl:find("income", 1, true) or nl:find("second", 1, true)
                        or tl:find("value", 1, true) or tl:find("coins", 1, true) then
                        local v = parseValue(txt)
                        if v and v > info.val then info.val = v end
                    end
                    if nl:find("progression", 1, true) or nl:find("level", 1, true) or nl:find("stage", 1, true) then
                        local n = tonumber(txt:match("%d+"))
                        if n and n > info.prog then info.prog = n end
                    end
                    if nl:find("name", 1, true) or nl == "title" or nl:find("eggname", 1, true) then
                        if #txt > 1 and #txt < 40 and not looksLikeStat(txt) then bestName = bestName or txt end
                    end
                    if not info.event and #tl < 40 then
                        if tl:find("night", 1, true) or tl:find("event egg", 1, true)
                            or tl:find("limited", 1, true) or tl:find("spawn khusus", 1, true) then
                            info.event = true
                        end
                    end
                end
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                local id = assetIdOf(d.Image)
                if id and not info.imageId then info.imageId = id end
            elseif d:IsA("Decal") or d:IsA("Texture") then
                local id = assetIdOf(d.Texture)
                if id and not info.imageId then info.imageId = id end
            elseif d:IsA("ValueBase") then
                scanKV(info, d.Name, d.Value)
            end
        end

        if bestName then info.name = bestName end
        if info.name == "" then
            local th = cleanEggName(theme)
            if th ~= "" then info.name = th end
        end
        if info.name == "" then
            info.name = "Egg" .. (info.prog > 0 and (" #" .. tostring(info.prog)) or "")
        end

        local nm = tostring(info.name):lower()
        if not info.event and (nm:find("night", 1, true) or nm:find("limited", 1, true)
            or nm:find("event", 1, true) or nm:find("special", 1, true)) then
            info.event = true
        end
        if info.rar == 0 then
            local r = rarityFromText(info.name)
            if r > 0 then info.rar = r end
        end

        local nd = snapByName[tostring(info.name):lower()]
        if not nd and disp then nd = snapByName[tostring(disp):lower()] end
        if not nd and theme then nd = snapByName[tostring(theme):lower()] end
        if nd then scanTable(info, nd, 0) end

        -- Dari atribut PetDisplayName/DisplayName kita tahu kategori egg-nya.
        -- Simpan supaya ClaimFeedback / Probe Record bisa mengisi rarity + value.
        if eggUid and info.name ~= "" and not uidCategory[eggUid] then
            uidCategory[eggUid] = string.lower(info.name)
        end
        if eggUid then applyMeta(eggUid) end
        if info.name == "" then info.name = "Egg" .. (info.prog > 0 and (" #" .. tostring(info.prog)) or "") end
        if info.rar == 0 and info.name ~= "" then info.rar = rarityFromText(info.name) end

        return info
    end

    local infoCache = setmetatable({}, { __mode = "k" })
    local function eggInfoCached(m)
        local c = infoCache[m]
        if c and (os.clock() - c.at) < 4 then return c.info end
        local info = eggInfo(m)
        infoCache[m] = { at = os.clock(), info = info }
        return info
    end

    local function eggPos(m)
        local h = m:FindFirstChild("Hitbox", true)
        if h and h:IsA("BasePart") then return h.Position end
        local ok, cf = pcall(function() return m:GetPivot() end)
        if ok and cf then return cf.Position end
        local p = m:FindFirstChildWhichIsA("BasePart", true)
        return p and p.Position or nil
    end

    local function nearestArea(pos)
        local best, bd = 1, math.huge
        for i, a in ipairs(AREAS) do
            local d = distXZ(pos, a[2])
            if d < bd then best, bd = i, d end
        end
        return best, bd
    end

    -- Kumpulan model egg di-cache. Dulu areaEggs() menyusuri seluruh pohon
    -- AreaEggSlotsClient setiap dipanggil (home/gallery/steal/auto-area).
    local eggCache = { at = -1e9, folder = nil, all = {}, byModel = setmetatable({}, { __mode = "k" }), conns = {} }

    local function cachedEggEntry(m, pos)
        local e = eggCache.byModel[m]
        if not e then
            e = { m = m }
            eggCache.byModel[m] = e
        end
        local uid = guidOf(m.Name)
        e.pos = pos
        e.uid = uid and string.lower(uid) or nil
        e.areaId = m:GetAttribute("AreaId")
        return e
    end

    local function collectEggModels(container, out, depth)
        if not container or (depth or 0) > 6 then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Folder") then
                collectEggModels(child, out, depth + 1)
            elseif child:IsA("Model") then
                local isEgg = child.Name:find("AreaEgg", 1, true)
                    or child:FindFirstChild("Hitbox", true)
                    or child:GetAttribute("EggTheme")
                    or child:GetAttribute("ProgressionOrder")
                    or child:GetAttribute("DisplayName")
                if isEgg then
                    local pos = eggPos(child)
                    if pos then out[#out + 1] = cachedEggEntry(child, pos) end
                else
                    collectEggModels(child, out, depth + 1)
                end
            end
        end
    end

    local function rebuildEggCache(folder)
        if eggCache.folder ~= folder then
            for _, c in ipairs(eggCache.conns) do pcall(function() c:Disconnect() end) end
            eggCache.conns = {}
            eggCache.folder = folder
            eggCache.byModel = setmetatable({}, { __mode = "k" })
            pcall(function()
                eggCache.conns[#eggCache.conns + 1] = folder.DescendantAdded:Connect(function() eggCache.at = -1e9 end)
                eggCache.conns[#eggCache.conns + 1] = folder.DescendantRemoving:Connect(function() eggCache.at = -1e9 end)
            end)
        end
        local all = {}
        collectEggModels(folder, all, 0)
        eggCache.all = all
        eggCache.at = os.clock()
    end

    local function eggAreaIndex(e)
        local aid = e.areaId or (e.uid and uidArea[e.uid])
        if type(aid) == "string" then
            for i, a in ipairs(AREAS) do
                if string.lower(a[1]) == string.lower(aid) then return i, 0 end
            end
        end
        return nearestArea(e.pos)
    end

    local function areaEggs(forceAll)
        local folder = workspace:FindFirstChild("AreaEggSlotsClient")
        if not folder then return {} end
        if eggCache.folder ~= folder or os.clock() - eggCache.at > 1.5 then
            rebuildEggCache(folder)
        end
        local out = eggCache.all
        if forceAll or state.allAreas then return out end
        local filtered = {}
        for _, e in ipairs(out) do
            if eggAreaIndex(e) == state.area then filtered[#filtered + 1] = e end
        end
        return filtered
    end

    -- Reset cache info tanpa membuat table metatable baru tiap kali event masuk.
    local function clearInfoCache()
        infoCache = setmetatable({}, { __mode = "k" })
        for _, e in ipairs(eggCache.all) do e.info = nil end
    end

    local function passFilter(info)
        if state.strict then
            if state.minRar > 1 and (info.rar == 0 or info.rar < state.minRar) then return false end
            if state.minProg > 1 and (info.prog == 0 or info.prog < PROG_STEPS[state.minProg]) then return false end
            if state.minVal > 1 and (info.val == 0 or info.val < VALUE_STEPS[state.minVal]) then return false end
        else
            -- Data yang tidak tersedia TIDAK boleh membuat egg ditolak.
            if state.minRar > 1 and info.rar > 0 and info.rar < state.minRar then return false end
            if state.minProg > 1 and info.prog > 0 and info.prog < PROG_STEPS[state.minProg] then return false end
            if state.minVal > 1 and info.val > 0 and info.val < VALUE_STEPS[state.minVal] then return false end
        end
        return true
    end

    local function eggScore(e, sort, rootPos)
        local i = e.info or {}
        local d = rootPos and (e.pos - rootPos).Magnitude or 0
        local themed = i.themed and 1 or 0
        local event = i.event and 1 or 0
        local chance = i.chance or 0
        local val = i.val or 0
        local rar = i.rar or 0
        local prog = i.prog or 0
        local weight = i.weight or 0
        local chanceScore = chance > 0 and (1 / chance) or 0
        if sort == 1 then
            -- Auto: egg event/night dulu, lalu rarity, progression, chance, value, berat.
            return event * 1e21
                + rar * 1e18
                + prog * 1e12
                + chanceScore * 1e9
                + math.min(val, 1e9)
                + weight * 1e3
                + themed * 1e6
        elseif sort == 2 then
            return rar * 1e18 + event * 1e15 + prog * 1e9 + math.min(val, 1e9)
        elseif sort == 3 then
            return val * 1e6 + rar * 1e3 + prog + event * 1e12
        elseif sort == 4 then
            return prog * 1e12 + rar * 1e6 + math.min(val, 1e9) + event * 1e18
        elseif sort == 5 then
            return -d
        else
            return weight * 1e9 + math.min(val, 1e9) + rar * 1e3 + prog
        end
    end

    local lastFilterLog, lastFallbackLog, lastDataWarn = 0, 0, 0

    local function pickBest(eggs, silent)
        local r = getRoot()
        local rp = r and r.Position
        local filtered = {}
        local hasRar, hasVal, hasProg, hasAny = false, false, false, false
        for _, e in ipairs(eggs) do
            e.info = e.info or eggInfoCached(e.m)
            local i = e.info
            if i.rar > 0 then hasRar = true end
            if i.val > 0 then hasVal = true end
            if i.prog > 0 then hasProg = true end
            if i.rar > 0 or i.val > 0 or i.prog > 0 or i.chance > 0 or i.weight > 0 then hasAny = true end
            if passFilter(i) then filtered[#filtered + 1] = e end
        end

        if not silent and os.clock() - lastDataWarn > 15 then
            local miss = {}
            if state.minRar > 1 and not hasRar then miss[#miss + 1] = "rarity" end
            if state.minVal > 1 and not hasVal then miss[#miss + 1] = "value" end
            if not hasAny then
                lastDataWarn = os.clock()
                log("Data " .. AREAS[state.area][1] .. " belum terbaca (" .. #eggs .. " egg). Ambil 1 egg dulu supaya Claim Feedback/CarryState mengisi nama + rarity, lalu Muat Ulang galeri.")
            elseif #miss > 0 then
                lastDataWarn = os.clock()
                log("Data " .. table.concat(miss, "/") .. " tidak tersedia -> filter itu diabaikan. Pakai Min Progression.")
            end
        end

        local useList = filtered
        if #useList == 0 then
            if state.fallback then
                useList = eggs
                for _, e in ipairs(useList) do e.info = e.info or eggInfoCached(e.m) end
                if not silent and os.clock() - lastFallbackLog > 8 then
                    lastFallbackLog = os.clock()
                    local reason = state.strict and "Filter ketat menolak semua" or "Filter tidak menemukan kandidat"
                    log(reason .. " -> fallback ke semua egg.")
                end
            else
                if not silent and os.clock() - lastFilterLog > 8 then
                    lastFilterLog = os.clock()
                    log("Best Egg: tidak ada yang lolos filter. Turunkan Min / aktifkan Fallback.")
                end
                return nil, #filtered
            end
        end

        local best, bs, bd
        for _, e in ipairs(useList) do
            local s = eggScore(e, state.sort, rp)
            local d = rp and (e.pos - rp).Magnitude or 0
            if not bs or s > bs or (s == bs and d < (bd or math.huge)) then
                best, bs, bd = e, s, d
            end
        end
        return best, #filtered
    end

