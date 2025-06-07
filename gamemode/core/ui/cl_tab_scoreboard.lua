DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("parallax.title")
    title:SetText("SCOREBOARD")

    local scoreboard = self:Add("ax.scoreboard")
    scoreboard:Dock(FILL)
end

vgui.Register("ax.tab.scoreboard", PANEL, "EditablePanel")