local PANEL = {}

function PANEL:Init()
    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
    end

    ax.gui.main = self

    self.startTime = SysTime()

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()

    -- we are temporarily using ax.transition to showcase the new transition panel and since we dont have much of the UI done yet
    self.splash = self:Add("ax.main.splash")
    self.create = self:Add("ax.main.create")
    self.load = self:Add("ax.main.load")
    self.options = self:Add("ax.main.options")

    self.splash:SlideToFront() -- this will make this specific panel the active one, rest will be hidden
end

function PANEL:Paint(width, height)
    Derma_DrawBackgroundBlur(self, self.startTime)
end

vgui.Register("ax.main", PANEL, "EditablePanel")

if ( IsValid(ax.gui.main) ) then
    ax.gui.main:Remove()

    timer.Simple(0, function()
        vgui.Create("ax.main")
    end)
end

concommand.Add("ax_menu", function()
    vgui.Create("ax.main")
end)