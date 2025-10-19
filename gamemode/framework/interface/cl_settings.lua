-- Clean up existing hook to prevent duplicates on reload
hook.Remove("PopulateTabButtons", "ax.tab.settings")

hook.Add("PopulateTabButtons", "ax.tab.settings", function(buttons)
    buttons["settings"] = {
        Populate = function(this, panel)
            local settings = panel:Add("ax.store")
            settings:SetType("option")
        end
    }
end)
