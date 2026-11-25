    --[[ ===================== 23. START ===================== ]]
    ui:setActive(state.steal)
    log("Bike For Eggs v5 dimuat. Player: " .. lp.Name .. " | Area: " .. AREAS[state.area][1])
    refreshLogUI()
    logDirty = false
    updateHome()

    task.spawn(function()
        -- Beri game waktu selesai spawn sebelum kerja berat (snapshot/scan).
        task.wait(1.2)
        if not running or not refreshSnapshot(false) then return end
        clearInfoCache()
        galleryDirty = true
        gallerySig = ""
        if state.autoArea then pcall(pickBestArea, false) end
        if ui.current == "home" and updateHome then updateHome() end

        -- Probe debug ditunda supaya tidak bersamaan dengan snapshot + UI awal.
        if state.probe then
            task.spawn(function()
                task.wait(5)
                if not running then return end
                pcall(debugProbeAll, false)
                if ui.current == "home" and updateHome then updateHome() end
            end)
        end
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
