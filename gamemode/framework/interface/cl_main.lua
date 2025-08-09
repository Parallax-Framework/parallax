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

    self.splash = self:Add("ax.main.splash")
    self.splash:StartAtBottom()

    self.create = self:Add("ax.main.create")
    self.create:StartAtBottom()

    self.load = self:Add("ax.main.load")
    self.load:StartAtBottom()

    self.options = self:Add("ax.main.options")
    self.options:StartAtBottom()

    self.splash:SlideToFront()
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