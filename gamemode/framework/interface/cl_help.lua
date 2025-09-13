local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
end

vgui.Register("ax.tab.help", PANEL, "DPanel")

hook.Add("PopulateTabButtons", "ax.tab.help", function(buttons)
    buttons["help"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.help")
        end
    }
end)