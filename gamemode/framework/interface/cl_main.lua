--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

-- Color scheme for the interface
local colors = {
    background = Color(15, 15, 20, 230),
    title = Color(220, 220, 240, 255),
    subtitle = Color(180, 180, 200, 255),
    buttonNormal = Color(40, 40, 60, 200),
    buttonHover = Color(60, 60, 90, 230),
    buttonText = Color(220, 220, 240, 255),
    accent = Color(100, 130, 255, 255),
    shadow = Color(0, 0, 0, 100)
}

-- Fonts
surface.CreateFont("Parallax.Title", {
    font = "Roboto",
    size = 72,
    weight = 700,
    antialias = true,
    shadow = true
})

surface.CreateFont("Parallax.Subtitle", {
    font = "Roboto",
    size = 28,
    weight = 400,
    antialias = true
})

surface.CreateFont("Parallax.Button", {
    font = "Roboto",
    size = 24,
    weight = 500,
    antialias = true
})

function PANEL:Init()
    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
    end

    ax.gui.main = self

    self.startTime = SysTime()

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
    self:SetAlpha(0)
    self:MakePopup()

    -- Create the main container
    self.container = vgui.Create("DPanel", self)
    self.container:SetSize(self:GetWide() - ScreenScale(256), self:GetTall() - ScreenScaleH(128))
    self.container:SetPos(ScreenScale(128), ScreenScaleH(64))
    self.container.Paint = function(this, width, height)
        draw.RoundedBox(0, 0, 0, width, height, colors.background)

        -- Fancy edge lighting effect
        surface.SetDrawColor(colors.accent.r, colors.accent.g, colors.accent.b, 20)
        surface.DrawOutlinedRect(1, 1, width - 2, height - 2, 2)
    end

    -- Create the title elements
    self.title = vgui.Create("DLabel", self.container)
    self.title:SetFont("Parallax.Title")
    self.title:SetText("Parallax Framework")
    self.title:SetTextColor(colors.title)
    self.title:SizeToContents()
    self.title:SetPos(self.container:GetWide() / 2 - self.title:GetWide() / 2, self.container:GetTall() * 0.1)

    self.subtitle = vgui.Create("DLabel", self.container)
    self.subtitle:SetFont("Parallax.Subtitle")
    self.subtitle:SetText("A new dimension of roleplay, built for you")
    self.subtitle:SetTextColor(colors.subtitle)
    self.subtitle:SizeToContents()
    self.subtitle:SetPos(self.container:GetWide() / 2 - self.subtitle:GetWide() / 2, self.title.y + self.title:GetTall() + 10)

    -- Create menu buttons
    self:CreateMenuButtons()

    -- Handle animations
    self:AnimateIn()
end

function PANEL:CreateMenuButtons()
    local buttonWidth = self.container:GetWide() / 2
    local buttonHeight = ScreenScaleH(24)
    local buttonSpacing = ScreenScaleH(8)
    local startY = ScreenScaleH(128)

    -- Create Character Button
    self.createButton = self:CreateButton("Create Character", buttonWidth, buttonHeight)
    self.createButton:SetPos(self.container:GetWide() / 2 - buttonWidth / 2, startY)
    self.createButton.DoClick = function()
        -- Add character creation logic
        print("Opening character creation...")

        net.Start("ax.character.create")
            net.WriteTable({
                name = "John Doe",
                description = "A new character",
            })
        net.SendToServer()

        self:Close()
    end

    -- Load Character Button
    self.loadButton = self:CreateButton("Load Character", buttonWidth, buttonHeight)
    self.loadButton:SetPos(self.container:GetWide() / 2 - buttonWidth / 2, startY + buttonHeight + buttonSpacing)
    self.loadButton.DoClick = function()
        local function loadChar( id )
            net.Start("ax.character.load")
                net.WriteUInt(id, 32)
            net.SendToServer()
        end

        loadChar(1)

        self:Close()
    end

    -- Options Button
    self.optionsButton = self:CreateButton("Options", buttonWidth, buttonHeight)
    self.optionsButton:SetPos(self.container:GetWide() / 2 - buttonWidth / 2, startY + (buttonHeight + buttonSpacing) * 2)
    self.optionsButton.DoClick = function()
        -- Add options menu logic
        print("Opening options menu...")

        self:Close()
    end

    -- Disconnect Button
    self.disconnectButton = self:CreateButton("Disconnect", buttonWidth, buttonHeight)
    self.disconnectButton:SetPos(self.container:GetWide() / 2 - buttonWidth / 2, startY + (buttonHeight + buttonSpacing) * 3)
    self.disconnectButton.DoClick = function()
        RunConsoleCommand("disconnect")
    end
end

function PANEL:CreateButton(text, btnWidth, btnHeight)
    -- Create a reusable button component
    local button = self:Add("DButton")
    button:SetSize(btnWidth, btnHeight)
    button:SetText("")

    -- Initial opacity for animation
    button:SetAlpha(0)

    local textColor = colors.buttonText
    local hovered = false
    local animationProgress = 0

    -- Store the button's animation data
    button.animData = {
        progress = 0,
        target = 0
    }

    button.Paint = function(this, w, h)
        -- Background
        animationProgress = Lerp(FrameTime() * 10, animationProgress, hovered and 1 or 0)
        local bgColor = colors.buttonNormal:Lerp(colors.buttonHover, animationProgress)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)

        -- Accent line at bottom
        surface.SetDrawColor(colors.accent.r, colors.accent.g, colors.accent.b, 150 + 105 * animationProgress)
        surface.DrawRect(0, h - 3, w * animationProgress, 3)

        -- Text
        draw.SimpleText(text, "Parallax.Button", w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    button.OnCursorEntered = function()
        hovered = true
        -- Use the motion system to animate additional effects if needed
        ax.motion:AnimateProperty(button, "animData.target", 0, 1, 0.3, "outQuad")
        surface.PlaySound("ui/buttonrollover.wav")
    end

    button.OnCursorExited = function()
        hovered = false
        ax.motion:AnimateProperty(button, "animData.target", 1, 0, 0.5, "outQuad")
    end

    button.OnMousePressed = function(this, code)
        if ( code == MOUSE_LEFT ) then
            -- Animate button press
            ax.motion:AnimateProperty(button, "animData.scale", 1, 0.95, 0.1, "outQuad", 0, function()
                ax.motion:AnimateProperty(button, "animData.scale", 0.95, 1, 0.2, "outQuad")
            end)

            this:DoClick()
        end

        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    return button
end

function PANEL:AnimateIn()
    self:AlphaTo(255, 0.5, 0, function()
        -- Animate title and subtitle
        self.title:SetPos(self.title.x, self.title.y - 30)
        self.title:MoveTo(self.title.x, self.title.y + 30, 0.8, 0, 0.5)

        -- Create background particle effects
        if ( !self.particleSystem ) then
            self.particleSystem, self.particleSystemID = ax.motion:CreateParticleSystem(self, 30, 2, 5)
        end

        self.subtitle:SetAlpha(0)
        self.subtitle:AlphaTo(255, 0.8, 0.3)

        -- Animate buttons sequentially
        local buttons = {self.createButton, self.loadButton, self.optionsButton, self.disconnectButton}
        for i, button in ipairs(buttons) do
            timer.Simple(0.2 + (i-1) * 0.1, function()
                if ( IsValid(button) ) then
                    button:AlphaTo(255, 0.5, 0)
                    button:MoveToFront()
                end
            end)
        end
    end)
end

function PANEL:Close()
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    -- Use motion library for closing animation
    ax.motion:AnimateProperty(self, "animData.scale", 1, 1.05, 0.3, "outQuad")

    -- Clean up particle system if it exists
    if ( self.particleSystem ) then
        timer.Simple(0.2, function()
            ax.motion:DestroyParticleSystem(self.particleSystemID)
        end)
    end

    self:AlphaTo(0, 0.5, 0, function()
        self:Remove()
    end)
end

function PANEL:Paint(width, height)
    Derma_DrawBackgroundBlur(self, self.startTime)
end

vgui.Register("ax.main", PANEL, "EditablePanel")

if ( IsValid(ax.gui.main) ) then
    vgui.Create("ax.main")
end

concommand.Add("ax_menu", function()
    vgui.Create("ax.main")
end)