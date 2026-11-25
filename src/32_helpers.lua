    --[[ ===================== 7. HELPERS ===================== ]]
    local function getRoot()
        local char = lp.Character
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart")
    end

    local function teleport(pos)
        local r = getRoot()
        if r and pos then
            pcall(function() r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end)
        end
    end

    local function flat(v)
        return Vector3.new(v.X, 0, v.Z)
    end

    local function distXZ(a, b)
        return (flat(a) - flat(b)).Magnitude
    end

    local function fmtVal(n)
        n = tonumber(n) or 0
        if n >= 1e12 then return string.format("%.2fT", n / 1e12) end
        if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
        if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
        if n >= 1e3 then return string.format("%.2fK", n / 1e3) end
        return tostring(math.floor(n))
    end

    local function fmtKg(n)
        n = tonumber(n) or 0
        if n >= 1e6 then return fmtVal(n) .. " kg" end
        if n >= 1e3 then return string.format("%.2fK kg", n / 1e3) end
        if n >= 100 then return string.format("%.0f kg", n) end
        if n >= 1 then return string.format("%.1f kg", n) end
        return string.format("%.2f kg", n)
    end

    local SUFFIX = {
        k = 1e3, m = 1e6, b = 1e9, t = 1e12,
        qa = 1e15, qi = 1e18, sx = 1e21, sp = 1e24,
        oc = 1e27, no = 1e30, dc = 1e33,
    }

    local function parseValue(s)
        if type(s) == "number" then return s end
        s = tostring(s):lower():gsub(",", ""):gsub("%s+", "")
        local num, suf = s:match("([%d%.]+)([a-z]*)")
        local n = tonumber(num)
        if not n then return nil end
        return n * (SUFFIX[suf] or 1)
    end

    local function parseChance(s)
        if type(s) == "number" then return s end
        s = tostring(s):lower():gsub(",", "")
        local n = s:match("1%s*in%s*([%d%.]+)") or s:match("1/%s*([%d%.]+)")
        return tonumber(n)
    end

    local function ser(v, depth, seen)
        depth = depth or 0
        local tv = typeof(v)
        if tv ~= "table" then
            if tv == "string" then return '"' .. v .. '"' end
            return tostring(v)
        end
        if depth >= 3 then return "{...}" end
        seen = seen or {}
        if seen[v] then return "{cycle}" end
        seen[v] = true
        local parts, n = {}, 0
        for k, val in pairs(v) do
            n = n + 1
            if n > 14 then parts[#parts + 1] = "..."; break end
            parts[#parts + 1] = tostring(k) .. "=" .. ser(val, depth + 1, seen)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end

    local GUID_PATTERN = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
    local function guidOf(s)
        if s == nil then return nil end
        s = tostring(s)
        local g = s:match(GUID_PATTERN)
        if g then return g end
        local tail = s:match("(%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x)$")
        return tail
    end

