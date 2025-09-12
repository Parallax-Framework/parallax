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

    self:Motion(ax.option:Get("tab.fade.time", 0.2), {
        Target = {alpha = 255},
        Easing = "OutQuad",
        Think = function(this)
            self:SetAlpha(this.alpha)
        end
    })

    self.buttons = self:Add("EditablePanel")
    self.buttons:SetSize(ScrW() / 4 - ScreenScale(16), ScrH() - ScreenScaleH(32))
    self.buttons:SetPos(-self.buttons:GetWide(), ScreenScaleH(16))

    self.buttons.x = self.buttons:GetX()
    self.buttons.y = self.buttons:GetY()

    self.buttons.alpha = 0
    self.buttons:SetAlpha(0)
    self.buttons:Motion(ax.option:Get("tab.fade.time", 0.2), {
        Target = {x = ScreenScale(8), y = ScreenScaleH(16), alpha = 255},
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

            self:Populate(v, button.tab)
        end

        local tab = self:CreatePage()
        tab:SetXOffset(self.buttons:GetWide() + ScreenScale(16))
        tab:SetYOffset(ScreenScaleH(16))
        tab:SetWidthOffset(-self.buttons:GetWide() - ScreenScale(16) * 2)
        tab:SetHeightOffset(-ScreenScaleH(32))
        self.tabs[k] = tab
        button.tab = tab
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
        self:Populate(buttons[ax.gui.tabLast], self.tabs[ax.gui.tabLast])
    else
        for k, v in SortedPairs(buttons) do
            self:Populate(v, self.tabs[k])
            break
        end
    end

    self:SetGradientLeftTarget(1)
    self:SetGradientRightTarget(1)
    self:SetGradientTopTarget(1)
    self:SetGradientBottomTarget(1)
end

function PANEL:Populate(data, tab)
    if ( !data ) then return end

    if ( istable(data) ) then
        if ( isfunction(data.Populate) ) then
            self:TransitionToPage(tab.index)
            data:Populate(tab)
        end

        if ( data.OnClose ) then
            self:CallOnRemove("ax.tab." .. data.name, function()
                data.OnClose()
            end)
        end
    elseif ( isfunction(data) ) then
        data(tab)
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

hook.Add("PopulateTabButtons", "ax.tab.help", function(buttons)
    buttons["help"] = {
        Populate = function(this, panel)
            panel.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(100, 0, 0, 50))

                draw.SimpleText("Welcome to Parallax Framework!", "ax.huge", w / 2, ScreenScaleH(32), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                draw.SimpleText("This is a basic help page. More content will be added in the future.", "ax.regular", w / 2, ScreenScaleH(80), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    }
    buttons["config"] = {
        Populate = function(this, panel)
            panel.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(100, 0, 0, 50))

                draw.SimpleText("Configuration", "ax.huge", w / 2, ScreenScaleH(32), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                draw.SimpleText("This is a basic configuration page. More content will be added in the future.", "ax.regular", w / 2, ScreenScaleH(80), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    }
    buttons["inventory"] = {
        Populate = function(this, panel)
            panel.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(100, 0, 0, 50))

                draw.SimpleText("Inventory", "ax.huge", w / 2, ScreenScaleH(32), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                draw.SimpleText("This is a basic inventory page. More content will be added in the future.", "ax.regular", w / 2, ScreenScaleH(80), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    }
    buttons["scoreboard"] = {
        Populate = function(this, panel)
            panel.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(100, 0, 0, 50))

                draw.SimpleText("Scoreboard", "ax.huge", w / 2, ScreenScaleH(32), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                draw.SimpleText("This is a basic scoreboard page. More content will be added in the future.", "ax.regular", w / 2, ScreenScaleH(80), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    }
    buttons["settings"] = {
        Populate = function(this, panel)
            panel.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(100, 0, 0, 50))

                draw.SimpleText("Settings", "ax.huge", w / 2, ScreenScaleH(32), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                draw.SimpleText("This is a basic settings page. More content will be added in the future.", "ax.regular", w / 2, ScreenScaleH(80), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    }
end)