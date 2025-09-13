local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.huge.bold")
    title:SetText("SCOREBOARD")
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.tab.scoreboard", PANEL, "DPanel")

hook.Add("PopulateTabButtons", "ax.tab.scoreboard", function(buttons)
    buttons["scoreboard"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.scoreboard")
        end
    }
end)