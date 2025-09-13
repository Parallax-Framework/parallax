local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
end

vgui.Register("ax.tab.config", PANEL, "DPanel")

hook.Add("PopulateTabButtons", "ax.tab.config", function(buttons)
    buttons["config"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.config")
        end
    }
end)