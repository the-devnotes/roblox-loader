    --[[ ===================== 6. LOG SYSTEM ===================== ]]
    local logs = {}
    -- Simpan banyak baris untuk Copy All, tapi tampilkan hanya sebagian agar
    -- TextLabel tidak berat di HP.
    local LOG_CAP = { store = 4000, line = 3000, ui = 300 }
    local logDirty = true
    local logScroll, logLabel
    local autoScroll = true

    local function log(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        local line = string.format("[%s] %s", os.date("%H:%M:%S"), table.concat(parts, " "))
        if #line > LOG_CAP.line then line = line:sub(1, LOG_CAP.line) .. "..." end
        logs[#logs + 1] = line
        if #logs > LOG_CAP.store then table.remove(logs, 1) end
        logDirty = true
    end

    local function refreshLogUI()
        if not logScroll or not logLabel then return end
        if #logs == 0 then
            logLabel.Text = "(belum ada log)"
        else
            local start = 1
            local hidden = #logs - LOG_CAP.ui
            if hidden > 0 then start = hidden + 1 end
            local view = {}
            if hidden > 0 then
                view[1] = "... " .. hidden .. " baris sebelumnya disembunyikan (Salin Semua untuk semua) ..."
            end
            for i = start, #logs do view[#view + 1] = logs[i] end
            logLabel.Text = table.concat(view, "\n")
        end
        if autoScroll then
            task.defer(function()
                if logScroll and logScroll.Parent then
                    local ok, size = pcall(function() return logScroll.AbsoluteCanvasSize.Y end)
                    if ok then
                        logScroll.CanvasPosition = Vector2.new(0, math.max(0, size - logScroll.AbsoluteSize.Y))
                    end
                end
            end)
        end
    end

