    --[[ ===================== 6. LOG SYSTEM ===================== ]]
    local logs = {}
    local MAX_LOG = 250
    local logDirty = true
    local logScroll, logLabel
    local autoScroll = true

    local function log(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        local line = string.format("[%s] %s", os.date("%H:%M:%S"), table.concat(parts, " "))
        if #line > 420 then line = line:sub(1, 420) .. "..." end
        logs[#logs + 1] = line
        if #logs > MAX_LOG then table.remove(logs, 1) end
        logDirty = true
    end

    local function refreshLogUI()
        if not logScroll or not logLabel then return end
        logLabel.Text = (#logs == 0) and "(belum ada log)" or table.concat(logs, "\n")
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

