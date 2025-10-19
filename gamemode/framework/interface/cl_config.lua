-- Clean up existing hook to prevent duplicates on reload
hook.Remove("PopulateTabButtons", "ax.tab.config")

hook.Add("PopulateTabButtons", "ax.tab.config", function(buttons)
    buttons["config"] = {
        Populate = function(this, panel)
            local settings = panel:Add("ax.store")
            settings:SetType("config")
        end
    }
end)
