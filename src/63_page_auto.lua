    --[[ ===================== 16. AUTO PAGE ===================== ]]
    local pgAuto = ui:page("auto", "Auto", "⚙️")
    pgAuto:section("Auto Hatch")
    local hatchToggle = pgAuto:toggle("Auto Hatch", state.hatch, function(v) setFlag("hatch", v) end)
    bind("hatch", hatchToggle)
    pgAuto:stepper("Jeda hatch", 0.5, 5.0, 0.1, state.hatchDelay, function(v)
        state.hatchDelay = v
    end, function(v) return string.format("%.1fs", v) end)

    pgAuto:divider()
    pgAuto:section("Auto Sell")
    local sellToggle = pgAuto:toggle("Auto Sell Pets", state.sell, function(v) setFlag("sell", v) end)
    bind("sell", sellToggle)
    pgAuto:stepper("Jeda sell", 0.5, 5.0, 0.1, state.sellDelay, function(v)
        state.sellDelay = v
    end, function(v) return string.format("%.1fs", v) end)

    pgAuto:note("Hatch memakai prompt yang mengandung 'Hatch'. Sell memakai prompt yang mengandung 'Sell'. Prompt dicari ulang tiap 2 detik.")

