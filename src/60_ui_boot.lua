    --[[ ===================== 13. UI BOOT ===================== ]]
    ui = BFEUI.new({
        title = "Bike For Eggs",
        subtitle = "Mobile - Sidebar Edition v5",
        icon = "🥚",
        onDestroy = function()
            running = false
            envSet("BFE_V5_Running", nil)
        end,
    })

    local function bind(key, widget)
        toggleRefs[key] = toggleRefs[key] or {}
        toggleRefs[key][#toggleRefs[key] + 1] = widget
    end
    local function setFlag(key, v)
        state[key] = v and true or false
        for _, w in ipairs(toggleRefs[key] or {}) do w:set(state[key]) end
        if key == "autoArea" and state.autoArea then
            state.allAreas = false
            for _, w in ipairs(toggleRefs.allAreas or {}) do w:set(false) end
            pcall(pickBestArea, false)
        end
        ui:setActive(state.steal)
        if updateHome then updateHome() end
    end

    local function tpBase()
        local b, src = basePos(true)
        if b then
            teleport(b)
            log("TP ke base (" .. tostring(src) .. ").")
        else
            ui:toast("Base belum diketahui. Tekan Set Base dulu.", "warn")
        end
    end

    local function manualSteal()
        if busy then
            ui:toast("Masih sibuk, tunggu sebentar.", "warn")
            return
        end
        busy = true
        task.spawn(function()
            local ok, err = pcall(stealOne, true)
            if not ok then log("ERROR manual steal: " .. tostring(err)) end
            busy = false
        end)
    end

