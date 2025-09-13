local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.huge.bold")
    title:SetText("SETTINGS")
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.tab.settings", PANEL, "DPanel")

hook.Add("PopulateTabButtons", "ax.tab.settings", function(buttons)
    buttons["settings"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.settings")
        end
    }
end)