    --[[ ===================== 10. KATALOG REPLICATEDSTORAGE ===================== ]]
    -- Metadata egg (rarity/value/weight/progression) ada di module client:
    --   ReplicatedStorage.Directory._Index.<NamaPet>
    --   ReplicatedStorage.Directory.Rarity._Index.<NamaTier>
    -- Jadi tidak perlu menebak argumen RequestEggRecord yang selalu nil.
    -- Semua helper dibungkus blok `do` supaya tidak menambah local di boot
    -- (luac/Luau punya batas 200 local per function).
    do
        local function safeRequireModule(mod)
            local co = coroutine.create(function()
                return require(mod)
            end)
            local ok, res = coroutine.resume(co)
            if coroutine.status(co) == "suspended" then return false, "yield" end
            return ok, res
        end

        local function addCatalogKeys(out, s)
            if type(s) ~= "string" then return end
            s = s:gsub("^%s+", ""):gsub("%s+$", "")
            if s == "" or genericEggName(s) then return end
            local raw = string.lower(s)
            out[raw] = true
            local c = catalog.compactKey(s)
            if c then out[c] = true end
        end

        local function catalogInfoFromData(mod, data)
            local info = {
                name = tostring(mod.Name),
                theme = nil,
                prog = 0,
                themed = false,
                event = false,
                weight = 0,
                imageId = nil,
                rar = 0,
                rarNum = 0,
                val = 0,
                chance = 0,
                texts = {},
                attrs = {},
                source = "catalog",
            }
            pcall(scanTable, info, data, 0)
            if genericEggName(info.name) then info.name = tostring(mod.Name) end
            if info.rar == 0 then info.rar = rarityFromText(info.name) end

            local keys = {}
            addCatalogKeys(keys, mod.Name)
            addCatalogKeys(keys, info.name)
            for _, f in ipairs({ "PetDisplayName", "DisplayName", "Name", "AssetCategory", "Category" }) do
                local v = data[f]
                if type(v) == "string" then addCatalogKeys(keys, v) end
            end
            return info, keys
        end

        local function catalogDir()
            local rs = ReplicatedStorage
            return rs:FindFirstChild("Directory") or rs:FindFirstChild("Directory", true)
        end

        local function skipCatalogKey(k)
            return k == "BaseConfigs" or k == "Types" or k == "Interface" or k == "Schema"
                or k == "Private" or k == "_Index" or k == "Default"
        end

        local function storeCatalogEntry(name, data, verbose)
            local info, keys = catalogInfoFromData({ Name = name }, data)
            for _, k in pairs(keys) do catalog.byKey[k] = info end
            return info, keys
        end

        -- Assets / BaseConfigs.Default sering berisi tabel keyed by nama pet,
        -- bukan ModuleScript per pet. Baca juga isinya supaya pet baru ikut masuk.
        local function readCatalogTables(verbose)
            local dir = catalogDir()
            if not dir then return 0 end
            local n = 0
            for _, modName in ipairs({ "Assets", "BaseConfigs.Default" }) do
                local mod = dir:FindFirstChild(modName, true)
                if mod and mod:IsA("ModuleScript") then
                    local ok, data = safeRequireModule(mod)
                    if ok and type(data) == "table" then
                        for k, v in pairs(data) do
                            if type(k) == "string" and type(v) == "table" and not skipCatalogKey(k) then
                                storeCatalogEntry(k, v, verbose)
                                n = n + 1
                            end
                        end
                        for key, v in pairs(data) do
                            if type(key) == "string" and type(v) == "table" and key == "_Index" then
                                for k, sub in pairs(v) do
                                    if type(k) == "string" and type(sub) == "table" and not skipCatalogKey(k) then
                                        storeCatalogEntry(k, sub, verbose)
                                        n = n + 1
                                    end
                                end
                            end
                        end
                        if verbose then
                            log("CATALOG TABLE " .. modName .. ": " .. ser(data):sub(1, 900))
                        end
                    end
                end
            end
            return n
        end

        local function readRarityModule(verbose)
            local dir = catalogDir()
            local mod = dir and dir:FindFirstChild("Rarity", true)
            if not mod or not mod:IsA("ModuleScript") then
                if verbose then log("Katalog rarity: module tidak ada.") end
                return
            end
            local ok, data = safeRequireModule(mod)
            catalog.rarRaw = ok and data or nil
            if verbose then
                log("RARITY MODULE: " .. (ok and ser(data):sub(1, 1200) or tostring(data)))
            end
            if not ok or type(data) ~= "table" then return end

            -- RarityNumber dari game adalah urutan resmi. Pakai itu, bukan tebakan
            -- common/uncommon/rare yang sebelumnya dipakai script.
            local rarities = data.Rarities
            if type(rarities) ~= "table" then return end
            catalog.rarityNumber = {}
            local maxNum = 0
            for k, v in pairs(rarities) do
                if type(v) == "table" then
                    local num = tonumber(v.RarityNumber)
                    if num and num > 0 then
                        local label = tostring(v.DisplayName or v._id or k)
                        catalog.rarityNumber[string.lower(k)] = num
                        catalog.rarityNumber[catalog.compactKey(k)] = num
                        catalog.rarityNumber[string.lower(label)] = num
                        catalog.rarityNumber[catalog.compactKey(label)] = num
                        catalog.rarityLabel[num] = label
                        if num > maxNum then maxNum = num end
                    end
                end
            end
            for i = #RARITY + 1, maxNum do
                RARITY[i] = "tier" .. i
                RARITY_COLOR[i] = RARITY_COLOR[#RARITY_COLOR] or Color3.fromRGB(255, 255, 255)
                RARITY_LABEL[i] = catalog.rarityLabel[i] or ("Tier " .. i)
                RARITY_NAMES[i] = (catalog.rarityLabel[i] or ("Tier " .. i)) .. "+"
            end
            if verbose then
                log("RARITY NUMBER: " .. maxNum .. " tier terdaftar.")
            end
        end

        local function applyCatalogToMaps()
            for key, e in pairs(catalog.byKey) do
                if e.rar > (categoryRarity[key] or 0) then categoryRarity[key] = e.rar end
                if e.prog > (categoryProg[key] or 0) then categoryProg[key] = e.prog end
                if e.val > (categoryValue[key] or 0) then categoryValue[key] = e.val end
                if e.weight > (categoryWeight[key] or 0) then categoryWeight[key] = e.weight end
                if e.chance > (categoryChance[key] or 0) then categoryChance[key] = e.chance end
                if e.imageId and not categoryImage[key] then categoryImage[key] = e.imageId end
            end
        end

        local function doReadCatalog(verbose)
            if not verbose and catalog.count > 0 and os.clock() - catalog.at < 45 then
                return catalog.count
            end

            local dir = catalogDir()
            local idx = dir and dir:FindFirstChild("_Index", true)
            if not idx then
                if verbose then log("Katalog tidak ada: ReplicatedStorage.Directory._Index.") end
                catalog.at = os.clock()
                return 0
            end

            local n, errN, tried = 0, 0, 0
            catalog.byKey = {}
            local okRarity, errRarity = pcall(readRarityModule, verbose)
            if not okRarity and verbose then log("RARITY error: " .. tostring(errRarity)) end

            local okTables, resTables = pcall(readCatalogTables, verbose)
            if okTables then
                n = n + resTables
            elseif verbose then
                log("CATALOG TABLE error: " .. tostring(resTables))
            end

            for _, mod in ipairs(idx:GetChildren()) do
                if mod:IsA("ModuleScript") then
                    tried = tried + 1
                    local ok, data = safeRequireModule(mod)
                    if verbose and tried <= 3 then
                        log("CATALOG " .. mod.Name .. " [" .. tostring(ok) .. "]: "
                            .. (ok and ser(data):sub(1, 700) or tostring(data)))
                    end
                    if ok and type(data) == "table" then
                        local okEntry = pcall(function()
                            local info, keys = catalogInfoFromData(mod, data)
                            for _, k in pairs(keys) do catalog.byKey[k] = info end
                        end)
                        if okEntry then n = n + 1 else errN = errN + 1 end
                    else
                        errN = errN + 1
                    end
                end
            end

            catalog.at = os.clock()
            catalog.count = n
            catalog.err = errN
            applyCatalogToMaps()
            galleryDirty = true
            gallerySig = ""

            if verbose then
                local keyCount = 0
                for _ in pairs(catalog.byKey) do keyCount = keyCount + 1 end
                log(string.format("Katalog dibaca: %d modul, %d gagal dari %d dicoba, %d kunci.",
                    n, errN, tried, keyCount))
            end
            return n
        end

        catalog.read = function(verbose)
            local ok, res = pcall(doReadCatalog, verbose)
            if not ok then
                log("Katalog error: " .. tostring(res))
                return 0
            end
            return res
        end
    end
