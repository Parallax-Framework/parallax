hook.Add("PopulateTabButtons", "ax.tab.config", function(buttons)
    buttons["config"] = {
        Populate = function(this, panel)
            local settings = panel:Add("ax.store")
            settings:SetType("config")
        end
    }
end)
