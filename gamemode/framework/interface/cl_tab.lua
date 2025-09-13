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
    if ( IsValid(ax.gui.tab) ) then
        ax.gui.tab:Remove()
    end

    ax.gui.tab = self

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

    self.tabs = {}

    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)

    self:MakePopup()

    self:Motion(ax.option:Get("tab.fade.time", 0.25), {
        Target = {alpha = 255},
        Easing = "OutQuad",
        Think = function(this)
            self:SetAlpha(this.alpha)
        end
    })

    self.buttons = self:Add("EditablePanel")
    self.buttons:SetSize(ScrW() / 4 - ScreenScale(32), ScrH() - ScreenScaleH(32))
    self.buttons:SetPos(-self.buttons:GetWide(), ScreenScaleH(16))

    self.buttons.x = self.buttons:GetX()
    self.buttons.y = self.buttons:GetY()

    self.buttons.alpha = 0
    self.buttons:SetAlpha(0)
    self.buttons:Motion(ax.option:Get("tab.fade.time", 0.25), {
        Target = {x = ScreenScale(16), y = ScreenScaleH(16), alpha = 255},
        Easing = "OutQuad",
        Think = function(vars)
            self.buttons:SetPos(vars.x, vars.y)
            self.buttons:SetAlpha(vars.alpha)
        end
    })

    local buttonSizeable = self.buttons:Add("EditablePanel")

    local buttons = {}
    hook.Run("PopulateTabButtons", buttons)
    for k, v in SortedPairs(buttons) do
        local button = buttonSizeable:Add("ax.button")
        button:Dock(TOP)
        button:DockMargin(0, 8, 0, 8)
        button:SetText(k)

        button.DoClick = function()
            ax.gui.tabLast = k

            self:TransitionToPage(button.tab.index, ax.option:Get("tab.fade.time", 0.25))
        end

        local tab = self:CreatePage()
        tab:SetXOffset(self.buttons:GetWide() + ScreenScale(32))
        tab:SetYOffset(ScreenScaleH(16))
        tab:SetWidthOffset(-self.buttons:GetWide() - ScreenScale(16) * 3)
        tab:SetHeightOffset(-ScreenScaleH(32))
        self.tabs[k] = tab
        button.tab = tab

        if ( istable(v) ) then
            if ( isfunction(v.Populate) ) then
                v:Populate(tab)
            end

            if ( v.OnClose ) then
                self:CallOnRemove("ax.tab." .. v.name, function()
                    v.OnClose()
                end)
            end
        elseif ( isfunction(v) ) then
            v(tab)
        end
    end

    buttonSizeable.Think = function(this)
        local totalHeight = 0
        local children = this:GetChildren()
        for i = 1, #children do
            local v = children[i]
            if ( IsValid(v) and v:IsVisible() ) then
                totalHeight = totalHeight + v:GetTall() + 16
            end
        end

        this:SetSize(self.buttons:GetWide(), totalHeight)
        this:CenterVertical()
    end

    if ( ax.gui.tabLast and buttons[ax.gui.tabLast] ) then
        self:TransitionToPage(self.tabs[ax.gui.tabLast].index, ax.option:Get("tab.fade.time", 0.25))
    else
        for k, v in SortedPairs(buttons) do
            self:TransitionToPage(self.tabs[k].index, ax.option:Get("tab.fade.time", 0.25))
            break
        end
    end

    self:SetGradientLeftTarget(1)
    self:SetGradientRightTarget(1)
    self:SetGradientTopTarget(1)
    self:SetGradientBottomTarget(1)
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

    local fadeDuration = ax.option:Get("tab.fade.time", 0.25)

    self:AlphaTo(0, fadeDuration, 0, function()
        self:Remove()

        if ( callback ) then
            callback()
        end
    end)

    self.buttons:Motion(fadeDuration, {
        Target = {x = -self.buttons:GetWide() * 2, y = ScreenScaleH(16), alpha = 0},
        Easing = "OutQuad",
        Think = function(this)
            self.buttons:SetPos(this.x, this.y)
            self.buttons:SetAlpha(this.alpha)
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

    local currentPageIndex = self:GetCurrentPage()
    local currentPage = self.pages[currentPageIndex]
    if ( IsValid(currentPage) ) then
        currentPage:SlideRight(fadeDuration)
    end
end

function PANEL:OnKeyCodePressed(keyCode)
    if ( keyCode == KEY_TAB or keyCode == KEY_ESCAPE ) then
        self:Close()

        return true
    end

    return false
end

function PANEL:Think()
    local bHoldingTab = input.IsKeyDown(KEY_TAB)
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
    ax.util:DrawPanelBlur(self, 3 * fraction, 1 * fraction, 180 * fraction)

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

vgui.Register("ax.tab", PANEL, "ax.transition.pages")

if ( IsValid(ax.gui.tab) ) then
    ax.gui.tab:Remove()
end

ax.gui.tabLast = nil