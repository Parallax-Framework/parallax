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
    -- Play button (only show if we have a character)
    local allowPlay = hook.Run("ShouldCreatePlayButton", self)
    if ( ax.client.axCharacter and allowPlay != false ) then
        local playButton = self.buttons:Add("ax.button")
        playButton:Dock(TOP)
        playButton:SetText("play")
        playButton.DoClick = function()
            parent:Remove()
        end
    end

    -- Create character button
    local allowCreate = hook.Run("ShouldCreateCreateButton", self)
    if ( allowCreate != false ) then
        local createButton = self.buttons:Add("ax.button")
        createButton:Dock(TOP)
        createButton:SetText("create")
        createButton.DoClick = function()
            self:SlideLeft()
            parent.create:SlideToFront()
        end
    end

    -- Load character button
    local allowLoad = hook.Run("ShouldCreateLoadButton", self)
    if ( allowLoad != false ) then
        local loadButton = self.buttons:Add("ax.button")
        loadButton:Dock(TOP)
        loadButton:SetText("load")
        loadButton.DoClick = function()
            self:SlideLeft()
            parent.load:SlideToFront()
        end
    end

    -- Options button
    local allowOptions = hook.Run("ShouldCreateOptionsButton", self)
    if ( allowOptions != false ) then
        local optionsButton = self.buttons:Add("ax.button")
        optionsButton:Dock(TOP)
        optionsButton:SetText("options")
        optionsButton.DoClick = function()
            self:SlideLeft()
            parent.options:SlideToFront()
        end
    end

    -- Disconnect button
    local allowDisconnect = hook.Run("ShouldCreateDisconnectButton", self)
    if ( allowDisconnect != false ) then
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
    end

    -- Now we need to add docking to the bottom of each button
    for _, button in ipairs(self.buttons:GetCanvas():GetChildren()) do
        if ( IsValid(button) and button.SetTall ) then
            button:DockMargin(0, 0, 0, ax.util:UIScreenScaleH(8))
        end
    end
end

function PANEL:PerformLayout()
    self.title:SetPos(ax.util:UIScreenScale(32), ScrH() / 3)
    self.subtitle:SetPos(ax.util:UIScreenScale(32), ScrH() / 3 + self.title:GetTall())

    self.buttons:SetPos(ax.util:UIScreenScale(32), ScrH() / 3 + self.title:GetTall() + self.subtitle:GetTall() + ax.util:UIScreenScaleH(16))
    self.buttons:SetSize(ScrW() / 6, ScrH() / 3)
end

vgui.Register("ax.main.splash", PANEL, "ax.transition")
