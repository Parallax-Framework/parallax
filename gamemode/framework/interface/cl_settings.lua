local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
end

vgui.Register("ax.tab.settings", PANEL, "DPanel")

hook.Add("PopulateTabButtons", "ax.tab.settings", function(buttons)
    buttons["settings"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.settings")
        end
    }
end)