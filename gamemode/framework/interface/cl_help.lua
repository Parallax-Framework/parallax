local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.tab.help", PANEL, "EditablePanel")

hook.Add("PopulateTabButtons", "ax.tab.help", function(buttons)
    buttons["help"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.help")
        end
    }
end)
