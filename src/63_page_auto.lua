    --[[ ===================== 16. AUTO PAGE ===================== ]]
    local pgAuto = ui:page("auto", "Tetas & Jual", "⚙️")
    pgAuto:section("Tetaskan Egg")
    local hatchToggle = pgAuto:toggle("Tetaskan Egg Otomatis", state.hatch, function(v) setFlag("hatch", v) end)
    bind("hatch", hatchToggle)
    pgAuto:stepper("Jeda tetas", 0.5, 5.0, 0.1, state.hatchDelay, function(v)
        state.hatchDelay = v
    end, function(v) return string.format("%.1fs", v) end)

    pgAuto:divider()
    pgAuto:section("Jual Pet")
    local sellToggle = pgAuto:toggle("Jual Pet Otomatis", state.sell, function(v) setFlag("sell", v) end)
    bind("sell", sellToggle)
    pgAuto:stepper("Jeda jual", 0.5, 5.0, 0.1, state.sellDelay, function(v)
        state.sellDelay = v
    end, function(v) return string.format("%.1fs", v) end)

    pgAuto:note("Tetas memakai prompt bertuliskan 'Hatch'. Jual memakai prompt 'Sell'. Prompt dicek ulang tiap 2 detik.")

