local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
end

vgui.Register("ax.tab.inventory", PANEL, "DPanel")

hook.Add("PopulateTabButtons", "ax.tab.inventory", function(buttons)
    buttons["inventory"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.inventory")
        end
    }
end)