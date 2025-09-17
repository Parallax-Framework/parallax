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
    ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 100))
    ax.util:DrawGradient("left", 0, 0, width / 2, height, Color(30, 30, 30, 200))
    ax.util:DrawGradient("left", 0, 0, width / 3, height, Color(0, 0, 0, 200))
end

vgui.Register("ax.main", PANEL, "EditablePanel")

if ( IsValid(ax.gui.main) ) then
    ax.gui.main:Remove()

    timer.Simple(0, function()
        vgui.Create("ax.main")
    end)
end

concommand.Add("ax_menu", function()
    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
        return
    end

    vgui.Create("ax.main")
end)