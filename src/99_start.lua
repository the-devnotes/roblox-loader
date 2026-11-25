    --[[ ===================== 23. START ===================== ]]
    ui:setActive(state.steal)
    log("Bike For Eggs v5 dimuat. Player: " .. lp.Name .. " | Area: " .. AREAS[state.area][1])
    refreshLogUI()
    logDirty = false
    updateHome()

    task.spawn(function()
        -- Beri game waktu selesai spawn sebelum cari area terbaik.
        task.wait(1.2)
        if not running then return end
        if state.autoArea then pcall(pickBestArea, false) end
        if ui.current == "home" and updateHome then updateHome() end
    end)
end

local ok, err = xpcall(boot, function(e)
    return tostring(e) .. "\n" .. debug.traceback("", 2)
end)

if not ok then
    envSet("BFE_V5_Running", nil)
    local old = findExistingGui()
    if old then pcall(function() old:Destroy() end) end
    warn("[BikeForEggs] Error: " .. tostring(err))
    simpleNotice("Script error", tostring(err):sub(1, 320), {
        { text = "Tutup", callback = function() end },
    })
end
