local PANEL = {}

function PANEL:Init()
    local parent = self:GetParent()

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    local navigation = self:Add("EditablePanel")
    navigation:Dock(BOTTOM)
    navigation:DockMargin(ScreenScale(32), 0, ScreenScale(32), ScreenScaleH(32))

    local backButton = navigation:Add("ax.button.flat")
    backButton:Dock(LEFT)
    backButton:SetText("back")
    backButton.DoClick = function()
        self:SlideDown()
        parent.splash:SlideToFront()
    end

    local nextButton = navigation:Add("ax.button.flat")
    nextButton:Dock(RIGHT)
    nextButton:SetText("next")
    nextButton.DoClick = function()
        net.Start("ax.character.load")
            net.WriteUInt(1, 32)
        net.SendToServer()

        parent:Remove()
    end

    navigation:SetTall(backButton:GetTall())
end

vgui.Register("ax.main.load", PANEL, "ax.transition")