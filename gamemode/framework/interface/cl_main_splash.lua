local PANEL = {}

function PANEL:Init()
    local parent = self:GetParent()

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    self.title = self:Add("DLabel")
    self.title:SetFont("ax.huge.bold")
    self.title:SetText("Parallax Framework")
    self.title:SetTextColor(Color(200, 200, 240, 255))
    self.title:SizeToContents()

    self.subtitle = self:Add("DLabel")
    self.subtitle:SetFont("ax.regular")
    self.subtitle:SetText("A new dimension of roleplay, built for you.")
    self.subtitle:SetTextColor(Color(160, 160, 200, 255))
    self.subtitle:SizeToContents()

    self.buttons = self:Add("ax.scroller.vertical")

    -- Allow for buttons to be created by other scripts
    local buttons = {}
    hook.Run("CreateMainMenuButtons", self, buttons)

    for _, button in ipairs(buttons) do
        self.buttons:AddItem(button)
    end

    -- Now create our own buttons
    local createButton = self.buttons:Add("ax.button")
    createButton:Dock(TOP)
    createButton:SetText("create")
    createButton.DoClick = function()
        self:SlideLeft()
        parent.create:SlideToFront()
    end

    local loadButton = self.buttons:Add("ax.button")
    loadButton:Dock(TOP)
    loadButton:SetText("load")
    loadButton.DoClick = function()
        self:SlideLeft()
        parent.load:SlideToFront()
    end

    local optionsButton = self.buttons:Add("ax.button")
    optionsButton:Dock(TOP)
    optionsButton:SetText("options")
    optionsButton.DoClick = function()
        self:SlideLeft()
        parent.options:SlideToFront()
    end

    local disconnectButton = self.buttons:Add("ax.button")
    disconnectButton:Dock(TOP)
    disconnectButton:SetText("disconnect")
    disconnectButton.DoClick = function()
        Derma_Query("Are you sure you want to disconnect?", "Disconnect",
            "Yes", function()
                RunConsoleCommand("disconnect")
            end,
            "No", function() end
        )
    end

    local closeButton = self.buttons:Add("ax.button")
    closeButton:Dock(TOP)
    closeButton:SetText("close (temporary)")
    closeButton.DoClick = function()
        parent:Remove()
    end

    -- Now we need to add docking to the bottom of each button
    for _, button in ipairs(self.buttons:GetCanvas():GetChildren()) do
        if ( IsValid(button) and button.SetTall ) then
            button:DockMargin(0, 0, 0, ScreenScaleH(8))
        end
    end
end

function PANEL:PerformLayout()
    self.title:SetPos(ScreenScale(32), ScrH() / 3)
    self.subtitle:SetPos(ScreenScale(32), ScrH() / 3 + self.title:GetTall())

    self.buttons:SetPos(ScreenScale(32), ScrH() / 3 + self.title:GetTall() + self.subtitle:GetTall() + ScreenScaleH(16))
    self.buttons:SetSize(ScrW() / 6, ScrH() / 3)
end

vgui.Register("ax.main.splash", PANEL, "ax.transition")