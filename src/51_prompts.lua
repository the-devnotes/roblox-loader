    --[[ ===================== 11. PROMPTS ===================== ]]
    local function promptPart(p)
        local o = p.Parent
        for _ = 1, 8 do
            if not o or o == workspace then return nil end
            if o:IsA("BasePart") then return o end
            o = o.Parent
        end
        return nil
    end

    -- Satu scan workspace saja untuk hatch/sell DAN SmartPromptPart.
    -- Dulu scanPrompts() dan smartParts() masing-masing memanggil GetDescendants().
    local promptCache = { at = -1e9, hatch = {}, sell = {}, smart = {} }
    local function scanPrompts()
        if os.clock() - promptCache.at < 2 then return end
        promptCache.at = os.clock()
        promptCache.hatch, promptCache.sell, promptCache.smart = {}, {}, {}
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled then
                local at = string.lower(d.ActionText or "")
                local target = nil
                if at:find("hatch", 1, true) then target = promptCache.hatch
                elseif at:find("sell", 1, true) then target = promptCache.sell end
                if target then
                    local part = promptPart(d)
                    if part then target[#target + 1] = { prompt = d, part = part } end
                end
            elseif d.Name == "SmartPromptPart" and d:IsA("BasePart") then
                promptCache.smart[#promptCache.smart + 1] = d
            end
        end
    end

    local function nearestPrompt(list)
        local r = getRoot()
        if not r then return nil end
        local best, bd
        for _, it in ipairs(list) do
            local d = (it.part.Position - r.Position).Magnitude
            if not bd or d < bd then best, bd = it, d end
        end
        return best
    end

    local function smartParts()
        scanPrompts()
        return promptCache.smart
    end

    local function carryPrompt()
        local r = getRoot()
        if not r then return nil end
        local best, bd
        for _, d in ipairs(smartParts()) do
            local p = d:FindFirstChild("CarryAreaEgg")
            if p and p:IsA("ProximityPrompt") and p.Enabled then
                local dist = (d.Position - r.Position).Magnitude
                if not bd or dist < bd then best, bd = p, dist end
            end
        end
        return best, bd
    end

    local function waitForCarryPrompt(timeout)
        local t0 = os.clock()
        while os.clock() - t0 < timeout do
            local p, d = carryPrompt()
            if p and (d or 9999) < 60 then return p, d end
            task.wait(0.1)
        end
        return carryPrompt()
    end

    local function firePrompt(p, maxDist)
        if not p then return false end
        pcall(function()
            p.HoldDuration = 0
            p.MaxActivationDistance = math.max(p.MaxActivationDistance, maxDist or 100)
        end)
        local ok = false
        if type(fireproximityprompt) == "function" then
            ok = pcall(fireproximityprompt, p)
        end
        if not ok then
            ok = pcall(function()
                p:InputHoldBegin()
                task.wait(0.05)
                p:InputHoldEnd()
            end)
        end
        return ok
    end

