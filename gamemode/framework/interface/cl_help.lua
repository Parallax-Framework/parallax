local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.huge.bold")
    title:SetText("HELP")
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.tab.help", PANEL, "DPanel")

hook.Add("PopulateTabButtons", "ax.tab.help", function(buttons)
    buttons["help"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.help")
        end
    }
end)