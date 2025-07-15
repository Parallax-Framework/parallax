--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local gradientLeft = ax.util:GetMaterial("vgui/gradient-l")
local gradientRight = ax.util:GetMaterial("vgui/gradient-r")
local gradientTop = ax.util:GetMaterial("vgui/gradient-u")
local gradientBottom = ax.util:GetMaterial("vgui/gradient-d")

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

AccessorFunc(PANEL, "gradientLeft", "GradientLeft", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientRight", "GradientRight", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientTop", "GradientTop", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientBottom", "GradientBottom", FORCE_NUMBER)

AccessorFunc(PANEL, "gradientLeftTarget", "GradientLeftTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientRightTarget", "GradientRightTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientTopTarget", "GradientTopTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientBottomTarget", "GradientBottomTarget", FORCE_NUMBER)

AccessorFunc(PANEL, "anchorTime", "AnchorTime", FORCE_NUMBER)
AccessorFunc(PANEL, "anchorEnabled", "AnchorEnabled", FORCE_BOOL)

function PANEL:Init()
    if ( IsValid(ax.gui.info) ) then
        ax.gui.info:Remove()
    end

    ax.gui.info = self

    local client = ax.client
    if ( IsValid(client) and client:IsTyping() ) then
        chat.Close()
    end

    CloseDermaMenus()

    if ( system.IsWindows() ) then
        system.FlashWindow()
    end

    self.alpha = 0
    self:SetAlpha(0)
    self.closing = false

    self.gradientLeft = 0
    self.gradientRight = 0
    self.gradientTop = 0
    self.gradientBottom = 0

    self.gradientLeftTarget = 0
    self.gradientRightTarget = 0
    self.gradientTopTarget = 0
    self.gradientBottomTarget = 0

    self.anchorTime = CurTime() + ax.option:Get("tab.anchor.time", 0.4)
    self.anchorEnabled = true

    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:MakePopup()

    self:Motion(ax.option:Get("tab.fade.time", 0.2), {
        Target = {alpha = 255},
        Easing = "OutQuad",
        Think = function(this)
            self:SetAlpha(this.alpha)
        end
    })

    self.container = self:Add("EditablePanel")
    self.container:SetSize(self:GetWide() - ScreenScale(32), self:GetTall() - ScreenScaleH(32))
    self.container:SetPos(ScreenScale(16), -self:GetTall())

    self.container.x = self.container:GetX()
    self.container.y = self.container:GetY()

    self.container.alpha = 0
    self.container:SetAlpha(0)
    self.container:Motion(ax.option:Get("tab.fade.time", 0.2), {
        Target = {x = ScreenScale(16), y = ScreenScaleH(16), alpha = 255},
        Easing = "OutQuad",
        Think = function(this)
            self.container:SetAlpha(this.alpha)
        end
    })

    self:SetGradientLeftTarget(1)
    self:SetGradientRightTarget(1)
    self:SetGradientTopTarget(1)
    self:SetGradientBottomTarget(1)

    self:Populate()
end

-- TODO: Add functionality and more options.
local quickMenuOptions = {"Description", "Drop Money"}

function PANEL:Populate()
    local client = ax.client
    local character = client:GetCharacter()
    local factionData = character:GetFactionData()

    local title = self.container:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.huge.bold")
    title:SetText("CHARACTER INFO")

    local model = self.container:Add("DModelPanel")
    model:Dock(LEFT)
    model:DockMargin(ScreenScale(128), ScreenScaleH(32), ScreenScale(16), ScreenScaleH(32))
    model:SetWide(ScreenScale(128))
    model:SetModel(ax.client:GetModel())
    model:SetFOV(35)
    model.LayoutEntity = function() end -- Prevents the model from rotating

    local info = self.container:Add("EditablePanel")
    info:Dock(RIGHT)
    info:DockMargin(ScreenScale(16), ScreenScaleH(32), ScreenScale(16), ScreenScaleH(32))
    info:SetWide(ScreenScale(256))

    -- Date and Time
    local dateTime = info:Add("ax.text")
    dateTime:Dock(TOP)
    dateTime:SetFont("ax.massive.bold")
    dateTime:SetText(os.date("%d/%m/%Y, %A, %H:%M"), true)
    dateTime:SetExpensiveShadow(2, ax.color:Get("shadow"))
    dateTime.Think = function(this)
        this:SetText(os.date("%d/%m/%Y, %A, %H:%M"), true)
    end

    -- Character Name
    local characterName = info:Add("ax.text")
    characterName:Dock(TOP)
    characterName:DockMargin(0, ScreenScaleH(16), 0, 0)
    characterName:SetFont("ax.massive.bold")
    characterName:SetText(character:GetName() or "Unknown Character", true)
    characterName:SetExpensiveShadow(2, ax.color:Get("shadow"))

    -- Faction
    local faction = info:Add("ax.text")
    faction:Dock(TOP)
    faction:SetFont("ax.large")
    faction:SetText(factionData.Name or "No Faction", true)
    faction:SetTextColor(factionData.Color or ax.color:Get("maroon.soft"))
    faction:SetExpensiveShadow(2, ax.color:Get("shadow"))

    -- Money
    local money = info:Add("ax.text")
    money:Dock(TOP)
    money:SetFont("ax.large", true)
    money:SetText(ax.currency:Format(character:GetMoney() or 0))
    money:SetExpensiveShadow(2, ax.color:Get("shadow"))

    -- Quick Menu Label
    local quickMenuLabel = info:Add("ax.text")
    quickMenuLabel:Dock(TOP)
    quickMenuLabel:DockMargin(0, ScreenScaleH(16), 0, 0)
    quickMenuLabel:SetFont("ax.massive.bold")
    quickMenuLabel:SetText("SELECT A QUICK MENU OPTION", true)
    quickMenuLabel:SetExpensiveShadow(2, ax.color:Get("shadow"))

    -- Quick Menu Options
    local layout = info:Add("DIconLayout")
    layout:Dock(TOP)
    layout:DockMargin(0, 0, 0, ScreenScaleH(16))

    for i, option in ipairs(quickMenuOptions) do
        local optionButton = layout:Add("ax.button.flat")
        optionButton:SetText(option)

        optionButton.DoClick = function()
        end
    end
end

function PANEL:Close(callback)
    if ( self.closing ) then
        return
    end

    self.closing = true

    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    self:SetGradientLeftTarget(0)
    self:SetGradientRightTarget(0)
    self:SetGradientTopTarget(0)
    self:SetGradientBottomTarget(0)

    local fadeDuration = ax.option:Get("tab.fade.time", 0.2)

    self:AlphaTo(0, fadeDuration, 0, function()
        self:Remove()

        if ( callback ) then
            callback()
        end
    end)

    self.container:Motion(fadeDuration, {
        Target = {x = ScreenScale(16), y = self:GetTall(), alpha = 0},
        Easing = "OutQuad",
        Think = function(this)
            self.container:SetAlpha(this.alpha)
            self.container:SetPos(this.x, this.y)
        end
    })

    self:Motion(fadeDuration, {
        Target = {alpha = 0},
        Easing = "OutQuad",
        Think = function(this)
            self:SetAlpha(this.alpha)
        end,
        OnComplete = function()
            if ( callback ) then
                callback()
            end

            self:Remove()
        end
    })
end

function PANEL:OnKeyCodePressed(keyCode)
    if ( keyCode == KEY_F1 or keyCode == KEY_ESCAPE ) then
        self:Close()

        return true
    end

    return false
end

function PANEL:Think()
    local bHoldingTab = input.IsKeyDown(KEY_F1)
    if ( bHoldingTab and ( self.anchorTime < CurTime() ) and self.anchorEnabled ) then
        self.anchorEnabled = false
    end

    if ( ( !bHoldingTab and !self.anchorEnabled ) or gui.IsGameUIVisible() ) then
        self:Close()
    end
end

function PANEL:Paint(width, height)
    local ft = FrameTime()
    local time = ft * 5

    local performanceAnimations = ax.option:Get("performance.animations", true)
    if ( !performanceAnimations ) then
        time = 1
    end

    local fraction = self:GetAlpha() / 255
    ax.util:DrawBlur(self, 1 * fraction, 0.5 * fraction, 255 * fraction)

    self:SetGradientLeft(Lerp(time, self:GetGradientLeft(), self:GetGradientLeftTarget()))
    self:SetGradientRight(Lerp(time, self:GetGradientRight(), self:GetGradientRightTarget()))
    self:SetGradientTop(Lerp(time, self:GetGradientTop(), self:GetGradientTopTarget()))
    self:SetGradientBottom(Lerp(time, self:GetGradientBottom(), self:GetGradientBottomTarget()))

    surface.SetDrawColor(0, 0, 0, 255 * self:GetGradientLeft())
    surface.SetMaterial(gradientLeft)
    surface.DrawTexturedRect(0, 0, width / 2, height)

    surface.SetDrawColor(0, 0, 0, 255 * self:GetGradientRight())
    surface.SetMaterial(gradientRight)
    surface.DrawTexturedRect(width / 2, 0, width / 2, height)

    surface.SetDrawColor(0, 0, 0, 255 * self:GetGradientTop())
    surface.SetMaterial(gradientTop)
    surface.DrawTexturedRect(0, 0, width, height / 2)

    surface.SetDrawColor(0, 0, 0, 255 * self:GetGradientBottom())
    surface.SetMaterial(gradientBottom)
    surface.DrawTexturedRect(0, height / 2, width, height / 2)
end

vgui.Register("ax.info", PANEL, "EditablePanel")

if ( IsValid(ax.gui.info) ) then
    ax.gui.info:Remove()
end