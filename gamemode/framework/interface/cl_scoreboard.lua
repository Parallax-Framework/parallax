local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
end

vgui.Register("ax.tab.scoreboard", PANEL, "DPanel")

hook.Add("PopulateTabButtons", "ax.tab.scoreboard", function(buttons)
    buttons["scoreboard"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.scoreboard")
        end
    }
end)