local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.huge.bold")
    title:SetText("CONFIG")
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.tab.config", PANEL, "DPanel")

hook.Add("PopulateTabButtons", "ax.tab.config", function(buttons)
    buttons["config"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.config")
        end
    }
end)