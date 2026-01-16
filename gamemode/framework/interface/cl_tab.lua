--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

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

    self.buttons = self:Add("ax.scroller.horizontal")
    self.buttons:SetSize(ScrW() - ax.util:ScreenScale(32), ax.util:ScreenScaleH(32))
    self.buttons:SetPos(ax.util:ScreenScale(16), -ax.util:ScreenScaleH(32))
    self.buttons.x = self.buttons:GetX()
    self.buttons.y = self.buttons:GetY()
    self.buttons.alpha = 0
    self.buttons:SetAlpha(0)
    self.buttons:SetZPos(2)

    self.subbuttons = self:Add("ax.scroller.horizontal")
    self.subbuttons:SetSize(ScrW() - ax.util:ScreenScale(64), ax.util:ScreenScaleH(32))
    self.subbuttons:SetPos(ax.util:ScreenScale(32), -ax.util:ScreenScaleH(32))
    self.subbuttons.x = self.subbuttons:GetX()
    self.subbuttons.y = self.subbuttons:GetY()
    self.subbuttons.alpha = 0
    self.subbuttons:SetAlpha(0)
    self.subbuttons:SetZPos(1)

    self:PopulateTabs()

    self:Open()
end

function PANEL:Open()
    self:Motion(ax.option:Get("tabFadeTime", 0.25), {
        Target = {alpha = 255},
        Easing = "OutQuad",
        Think = function(this)
            self:SetAlpha(this.alpha)
        end
    })

    self.buttons:Motion(ax.option:Get("tabFadeTime", 0.25), {
        Target = {x = ax.util:ScreenScale(16), y = ax.util:ScreenScaleH(16), alpha = 255},
        Easing = "OutQuad",
        Think = function(vars)
            self.buttons:SetPos(vars.x, vars.y)
            self.buttons:SetAlpha(vars.alpha)
        end
    })

    -- if the current tab has subbuttons, show them
    local currentPageIndex = self:GetCurrentPage()
    local hasSubbuttons = false
    for k, v in pairs(self.tabs) do
        if ( v.index == currentPageIndex ) then
            local tabKey = k
            for buttonKey, button in pairs(self.buttons.buttons or {}) do
                if ( button.tab == v ) then
                    tabKey = buttonKey
                    break
                end
            end

            -- If current tab is a section, find its parent tab
            if ( self.sectionParentMap[tabKey] ) then
                tabKey = self.sectionParentMap[tabKey]
            end

            local buttons = {}
            hook.Run("PopulateTabButtons", buttons)
            local tabData = buttons[tabKey]
            if ( istable(tabData) and istable(tabData.Sections) and table.Count(tabData.Sections) > 0 ) then
                hasSubbuttons = true
                break
            end
        end
    end

    if ( hasSubbuttons ) then
        self.subbuttons:Motion(ax.option:Get("tabFadeTime", 0.25), {
            Target = {y = ax.util:ScreenScaleH(16) + self.buttons:GetTall(), alpha = 255},
            Easing = "OutQuad",
            Think = function(vars)
                self.subbuttons:SetPos(self.subbuttons:GetX(), vars.y)
                self.subbuttons:SetAlpha(vars.alpha)
            end
        })

        return
    end

    self.subbuttons:Motion(ax.option:Get("tabFadeTime", 0.25), {
        Target = {y = ax.util:ScreenScaleH(16), alpha = 0},
        Easing = "OutQuad",
        Think = function(vars)
            self.subbuttons:SetY(vars.y)
            self.subbuttons:SetAlpha(vars.alpha)
        end
    })
end

function PANEL:PopulateTabs()
    self.buttonMap = {}
    self.sectionParentMap = {}

    local pendingSectionKey
    local pendingParentButton

    local buttons = {}
    hook.Run("PopulateTabButtons", buttons)
    for k, v in SortedPairs(buttons) do
        local button = self.buttons:Add("ax.button.flat")
        button:Dock(LEFT)
        button:SetText(ax.localization:GetPhrase("tab." .. k))

        button:SetUpdateSizeOnHover(true)
        button:SetSizeToContentsMotion(true)

        self.buttons:SetTall(math.max(self.buttons:GetTall(), button:GetTall()))
        self.buttons:SetY(self.buttons:GetY())
        self.subbuttons:SetTall(math.max(self.subbuttons:GetTall(), button:GetTall()))
        self.subbuttons:SetY(self.subbuttons:GetY())

        -- TODO: add a toggle option for ax.button
        button.Paint = function(this, width, height)
            if ( ax.gui.tabLast == k ) then
                ax.render.Draw(0, 0, 0, width, height, color_white)

                if ( this:GetTextColor() != color_black ) then
                    this:SetTextColor(color_black)
                end
            else
                if ( this:GetTextColor() != color_white ) then
                    this:SetTextColor(color_white)
                end
            end
        end

        local tab = self:CreatePage()
        tab:SetXOffset(ax.util:ScreenScale(32))
        tab:SetYOffset(self.buttons:GetTall() + ax.util:ScreenScaleH(32))
        tab:SetWidthOffset(-ax.util:ScreenScale(32) * 2)
        tab:SetHeightOffset(-self.buttons:GetTall() - ax.util:ScreenScaleH(64))
        tab.key = k
        self.tabs[k] = tab
        self.buttonMap[k] = button

        button.tab = tab

        if ( istable(v) ) then
            if ( isfunction(v.Populate) ) then
                v:Populate(tab)
            end

            if ( istable(v.Sections) and table.Count(v.Sections) > 0 ) then
                tab:SetYOffset(self.buttons:GetTall() + self.subbuttons:GetTall() + ax.util:ScreenScaleH(32))
                tab:SetHeightOffset(-self.buttons:GetTall() - self.subbuttons:GetTall() - ax.util:ScreenScaleH(64))

                for sectionKey, section in pairs(v.Sections) do
                    self.sectionParentMap[sectionKey] = k

                    local subTab = self:CreatePage()
                    subTab:SetXOffset(ax.util:ScreenScale(32))
                    subTab:SetYOffset(self.buttons:GetTall() + self.subbuttons:GetTall() + ax.util:ScreenScaleH(32))
                    subTab:SetWidthOffset(-ax.util:ScreenScale(32) * 2)
                    subTab:SetHeightOffset(-self.buttons:GetTall() - self.subbuttons:GetTall() - ax.util:ScreenScaleH(64))
                    subTab.key = sectionKey
                    self.tabs[sectionKey] = subTab

                    if ( ax.gui.tabLast == sectionKey ) then
                        pendingSectionKey = sectionKey
                        pendingParentButton = button
                    end
                end
            end

            if ( v.OnClose ) then
                self:CallOnRemove("ax.tab." .. v.name, function()
                    v.OnClose()
                end)
            end
        elseif ( isfunction(v) ) then
            v(tab)
        end

        button.DoClick = function()
            ax.gui.tabLast = k
            self:TransitionToPage(button.tab.index, ax.option:Get("tabFadeTime", 0.25))

            if ( istable(v) and istable(v.Sections) and table.Count(v.Sections) > 0 ) then
                for _, subbutton in pairs(self.subbuttons.buttons or {}) do
                    subbutton:Remove()
                end

                -- Add buttons for each section
                for sectionKey, sectionData in pairs(v.Sections) do
                    local subbutton = self.subbuttons:Add("ax.button.flat")
                    subbutton:Dock(LEFT)
                    subbutton:SetText(ax.localization:GetPhrase("tab." .. k .. "." .. sectionKey))

                    subbutton:SetUpdateSizeOnHover(true)
                    subbutton:SetSizeToContentsMotion(true)

                    -- TODO: add a toggle option for ax.button
                    subbutton.Paint = function(this, width, height)
                        if ( ax.gui.tabLast == sectionKey ) then
                            ax.render.Draw(0, 0, 0, width, height, color_white)

                            if ( this:GetTextColor() != color_black ) then
                                this:SetTextColor(color_black)
                            end
                        else
                            if ( this:GetTextColor() != color_white ) then
                                this:SetTextColor(color_white)
                            end
                        end
                    end

                    subbutton.DoClick = function()
                        ax.gui.tabLast = sectionKey
                        self:TransitionToPage(self.tabs[sectionKey].index, ax.option:Get("tabFadeTime", 0.25))
                    end

                    self.subbuttons.buttons = self.subbuttons.buttons or {}
                    self.subbuttons.buttons[sectionKey] = subbutton
                end

                -- Populate each sub tab
                for sectionKey, section in pairs(v.Sections) do
                    if ( isfunction(section.Populate) ) then
                        section:Populate(self.tabs[sectionKey])
                    end
                end

                -- Motion below the main buttons
                self.subbuttons:Motion(ax.option:Get("tabFadeTime", 0.25), {
                    Target = {y = ax.util:ScreenScaleH(16) + self.buttons:GetTall(), alpha = 255},
                    Easing = "OutQuad",
                    Think = function(this)
                        self.subbuttons:SetPos(self.subbuttons:GetX(), this.y)
                        self.subbuttons:SetAlpha(this.alpha)
                    end
                })
            else
                -- Hide subbuttons
                self.subbuttons:Motion(ax.option:Get("tabFadeTime", 0.25), {
                    Target = {y = self.buttons:GetY(), alpha = 0},
                    Easing = "OutQuad",
                    Think = function(this)
                        self.subbuttons:SetPos(self.subbuttons:GetX(), this.y)
                        self.subbuttons:SetAlpha(this.alpha)
                    end
                })
            end
        end

        -- if this was our last tab, run doclick
        if ( ax.gui.tabLast == k ) then
            button:DoClick()
        end

        self.buttons:AddPanel(button)
    end

    if ( pendingSectionKey and IsValid(pendingParentButton) ) then
        pendingParentButton:DoClick()

        local subbutton = self.subbuttons.buttons and self.subbuttons.buttons[pendingSectionKey]
        if ( IsValid(subbutton) ) then
            subbutton:DoClick()
        end

        self.restoredLastTab = true
    end

    if ( !self.restoredLastTab and ax.gui.tabLast and self.tabs[ax.gui.tabLast] ) then
        self.tabs[ax.gui.tabLast]:StartAtBottom()
        self:TransitionToPage(self.tabs[ax.gui.tabLast].index, ax.option:Get("tabFadeTime", 0.25), true)
    else
        for k, v in SortedPairs(self.tabs) do
            if ( k == ax.gui.tabLast ) then
                v:StartAtBottom()
                self:TransitionToPage(v.index, ax.option:Get("tabFadeTime", 0.25), true)
                break
            end
        end
    end

    self:SetGradientLeftTarget(1)
    self:SetGradientRightTarget(1)
    self:SetGradientTopTarget(1)
    self:SetGradientBottomTarget(1)
end

function PANEL:Close(callback)
    if ( self.closing ) then return end

    self.closing = true

    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    self:SetGradientLeftTarget(0)
    self:SetGradientRightTarget(0)
    self:SetGradientTopTarget(0)
    self:SetGradientBottomTarget(0)

    local fadeDuration = ax.option:Get("tabFadeTime", 0.25)

    self:AlphaTo(0, fadeDuration, 0, function()
        self:Remove()

        if ( callback ) then
            callback()
        end
    end)

    self.buttons:Motion(fadeDuration, {
        Target = {x = ax.util:ScreenScale(16), y = -self.buttons:GetTall() - ax.util:ScreenScaleH(16), alpha = 0},
        Easing = "OutQuad",
        Think = function(this)
            self.buttons:SetPos(this.x, this.y)
            self.buttons:SetAlpha(this.alpha)
        end
    })

    self.subbuttons:Motion(fadeDuration, {
        Target = {y = -self.subbuttons:GetTall() - ax.util:ScreenScaleH(16), alpha = 0},
        Easing = "OutQuad",
        Think = function(this)
            self.subbuttons:SetY(this.y)
            self.subbuttons:SetAlpha(this.alpha)
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
        currentPage:SlideDown(fadeDuration)
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
    ax.util:DrawBlur(0, 0, 0, width, height, Color(255, 255, 255, 150 * fraction))

    self:SetGradientLeft(Lerp(time, self:GetGradientLeft(), self:GetGradientLeftTarget()))
    self:SetGradientRight(Lerp(time, self:GetGradientRight(), self:GetGradientRightTarget()))
    self:SetGradientTop(Lerp(time, self:GetGradientTop(), self:GetGradientTopTarget()))
    self:SetGradientBottom(Lerp(time, self:GetGradientBottom(), self:GetGradientBottomTarget()))

    ax.util:DrawGradient("left", 0, 0, width, height, Color(0, 0, 0, 100 * self:GetGradientLeft()))
    ax.util:DrawGradient("right", 0, 0, width, height, Color(0, 0, 0, 100 * self:GetGradientRight()))
    ax.util:DrawGradient("top", 0, 0, width, height, Color(0, 0, 0, 100 * self:GetGradientTop()))
    ax.util:DrawGradient("bottom", 0, 0, width, height, Color(0, 0, 0, 100 * self:GetGradientBottom()))
end

vgui.Register("ax.tab", PANEL, "ax.transition.pages")

if ( IsValid(ax.gui.tab) ) then
    ax.gui.tab:Remove()
end

ax.gui.tabLast = nil
