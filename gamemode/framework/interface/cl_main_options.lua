local PANEL = {}

function PANEL:Init()
    local parent = self:GetParent()

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    self:CreateNavigation(self, "back", function()
        self:SlideDown()
        parent.splash:SlideToFront()
    end)

    local settings = self:Add("ax.store")
    settings:SetType("option")
    settings:DockMargin(ax.util:ScreenScale(32), ax.util:ScreenScaleH(32), ax.util:ScreenScale(32), ax.util:ScreenScaleH(32))

    for _, tab in ipairs(settings:GetPages()) do
        tab:DockPadding(0, 0, ax.util:ScreenScale(64), 0)
    end
end

vgui.Register("ax.main.options", PANEL, "ax.transition")
