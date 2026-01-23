--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

function PANEL:Init()
    hook.Run("PreMainMenuSplashCreated", self)

    local parent = self:GetParent()

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    self.title = self:Add("ax.text")
    self.title:SetFont("ax.huge.bold")
    self.title:SetText("Parallax Framework")
    self.title:SetTextColor(Color(200, 200, 240, 255))
    self.title.Paint = function(s, w, h)
        ax.render.DrawShadows(h, 0, h / 4, w, h / 2, Color(0, 0, 0, 50), nil, nil, ax.render.BLUR)
    end

    self.subtitle = self:Add("ax.text")
    self.subtitle:SetText("A new dimension of roleplay, built for you.")
    self.subtitle:SetTextColor(Color(160, 160, 200, 255))
    self.subtitle.Paint = function(s, w, h)
        ax.render.DrawShadows(h, 0, h / 4, w, h / 2, Color(0, 0, 0, 25), nil, nil, ax.render.BLUR)
    end

    self.buttons = self:Add("EditablePanel")

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
        playButton:Dock(LEFT)
        playButton:SetText("mainmenu.play")
        playButton.DoClick = function()
            parent:Remove()
        end
    end

    -- Create character button
    local allowCreate = hook.Run("ShouldCreateCreateButton", self)
    if ( allowCreate != false ) then
        local createButton = self.buttons:Add("ax.button")
        createButton:Dock(LEFT)
        createButton:SetText("mainmenu.create")
        createButton.DoClick = function()
            self:SlideLeft()
            parent.create:SlideToFront()
        end
    end

    -- Load character button
    local allowLoad = hook.Run("ShouldCreateLoadButton", self)
    if ( allowLoad != false ) then
        local loadButton = self.buttons:Add("ax.button")
        loadButton:Dock(LEFT)
        loadButton:SetText("mainmenu.load")
        loadButton.DoClick = function()
            self:SlideLeft()
            parent.load:SlideToFront()
        end
    end

    -- Options button
    local allowOptions = hook.Run("ShouldCreateOptionsButton", self)
    if ( allowOptions != false ) then
        local optionsButton = self.buttons:Add("ax.button")
        optionsButton:Dock(LEFT)
        optionsButton:SetText("mainmenu.options")
        optionsButton.DoClick = function()
            self:SlideLeft()
            parent.options:SlideToFront()
        end
    end

    -- Disconnect button
    local allowDisconnect = hook.Run("ShouldCreateDisconnectButton", self)
    if ( allowDisconnect != false ) then
        local disconnectButton = self.buttons:Add("ax.button")
        disconnectButton:Dock(LEFT)
        disconnectButton:SetText("mainmenu.disconnect")
        disconnectButton.DoClick = function()
            Derma_Query("Are you sure you want to disconnect?", "Disconnect",
                "Yes", function()
                    RunConsoleCommand("disconnect")
                end,
                "No", function() end
            )
        end
    end


    hook.Run("PostMainMenuSplashCreated", self)
end

hook.Add("ShouldCreateLoadButton", "ax.main.splash", function()
    local clientTable = ax.client:GetTable()
    return clientTable.axCharacters and clientTable.axCharacters[1] != nil
end)

function PANEL:PerformLayout()
    self.title:SetPos(ScrW() / 2 - self.title:GetWide() / 2, ScrH() / 8)
    self.subtitle:SetPos(ScrW() / 2 - self.subtitle:GetWide() / 2, ScrH() / 8 + self.title:GetTall())

    self.buttons:SetSize(ScrW() / 1.25, ax.util:ScreenScaleH(32))
    self.buttons:SetPos(ScrW() / 2 - self.buttons:GetWide() / 2, ScrH() - self.buttons:GetTall() - ax.util:ScreenScaleH(32))

    for _, button in pairs(self.buttons:GetChildren()) do
        button:SetWide(self.buttons:GetWide() / #self.buttons:GetChildren() - ax.util:ScreenScale(4))
        button:DockMargin(ax.util:ScreenScale(2), 0, ax.util:ScreenScale(2), 0)
    end
end

function PANEL:Paint(width, height)
    ax.util:DrawGradient("up", 0, 0, width, height, Color(50, 50, 50, 200))
    ax.util:DrawGradient("down", 0, 0, width, height, Color(0, 0, 0, 100))
end

vgui.Register("ax.main.splash", PANEL, "ax.transition")
