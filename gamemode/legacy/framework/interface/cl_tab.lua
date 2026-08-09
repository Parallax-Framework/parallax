--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

-- Layout constants
local SIDEBAR_WIDTH = ax.util:ScreenScale(72)
local SIDEBAR_GAP = ax.util:ScreenScale(2)
local PADDING_X = ax.util:ScreenScale(24)
local PADDING_Y = ax.util:ScreenScaleH(24)
local BODY_GAP = ax.util:ScreenScaleH(8)
local SIDEBAR_BUTTON_GAP = ax.util:ScreenScaleH(2)
local SIDEBAR_PADDING = ax.util:ScreenScale(4)

--- Sorts section keys by sort order, then by name alphabetically.
local function GetSortedSectionKeys(sections)
    local keys = table.GetKeys(sections or {})

    table.sort(keys, function(a, b)
        local dataA = sections[a]
        local dataB = sections[b]
        local sortA = (istable(dataA) and isnumber(dataA.sort)) and dataA.sort or math.huge
        local sortB = (istable(dataB) and isnumber(dataB.sort)) and dataB.sort or math.huge

        if ( sortA != sortB ) then
            return sortA < sortB
        end

        local nameA = istable(dataA) and dataA.name or a
        local nameB = istable(dataB) and dataB.name or b

        nameA = string.lower(tostring(nameA or a))
        nameB = string.lower(tostring(nameB or b))

        if ( nameA == nameB ) then
            return tostring(a) < tostring(b)
        end

        return nameA < nameB
    end)

    return keys
end

--- Collects tab button registration data from hooks.
local function PopulateTabButtonTable()
    local buttons = {}

    hook.Run("PopulateTabButtons", buttons)
    hook.Run("PostPopulateTabButtons", buttons)

    return buttons
end

-- Backdrop animation accessors
AccessorFunc(PANEL, "backgroundBlur", "BackgroundBlur", FORCE_NUMBER)
AccessorFunc(PANEL, "backgroundAlpha", "BackgroundAlpha", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientLeft", "GradientLeft", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientRight", "GradientRight", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientTop", "GradientTop", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientBottom", "GradientBottom", FORCE_NUMBER)

AccessorFunc(PANEL, "backgroundBlurTarget", "BackgroundBlurTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "backgroundAlphaTarget", "BackgroundAlphaTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientLeftTarget", "GradientLeftTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientRightTarget", "GradientRightTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientTopTarget", "GradientTopTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientBottomTarget", "GradientBottomTarget", FORCE_NUMBER)

function PANEL:Init()
    if ( IsValid(ax.gui.tab) ) then
        ax.gui.tab:Remove()
    end

    ax.gui.tab = self

    local client = ax.client
    if ( ax.util:IsValidPlayer(client) and client:IsTyping() ) then
        chat.Close()
    end

    CloseDermaMenus()

    if ( system.IsWindows() ) then
        system.FlashWindow()
    end

    -- Visual state
    self.alpha = 0
    self:SetAlpha(0)
    self.opening = true
    self.closing = false

    -- Backdrop values
    self.backgroundBlur = 0
    self.backgroundAlpha = 0
    self.gradientLeft = 0
    self.gradientRight = 0
    self.gradientTop = 0
    self.gradientBottom = 0

    self.backgroundBlurTarget = 0
    self.backgroundAlphaTarget = 0
    self.gradientLeftTarget = 0
    self.gradientRightTarget = 0
    self.gradientTopTarget = 0
    self.gradientBottomTarget = 0

    -- TAB anchor
    self.anchorTime = CurTime() + ax.option:Get("tab.anchor.time", 0.4)
    self.bAnchorEnabled = true

    -- State
    self.state = {
        activeTab = nil,
        activeSection = nil,
        tabOrder = {},
    }

    self.tabs = {}
    self.tabButtons = {}
    self.buttonMap = {}
    self.sectionPages = {}
    self.innerPages = {}
    self.sectionButtonMap = {}
    self.sectionParentMap = {}
    self.bSidebarVisible = false

    -- Fullscreen overlay
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:MakePopup()

    self:CreateTopBar()
    self:CreateSidebar()
    self:CreateContent()
    self:PopulateTabs()
    self:RestoreLastTab()
    self:Open()
end

function PANEL:CreateTopBar()
    local topBarHeight = ax.util:ScreenScaleH(24)

    self.topBar = self:Add("EditablePanel")
    self.topBar:SetSize(ScrW() - PADDING_X * 2, topBarHeight)
    self.topBar:SetPos(PADDING_X, -topBarHeight)
    self.topBar:SetZPos(10)
    self.topBar:SetAlpha(0)
    self.topBar.Paint = nil
    self.topBarHeight = topBarHeight

    -- Motion starting values
    self.topBar.topBarY = -topBarHeight
    self.topBar.topBarAlpha = 0

    self.tabScroller = self.topBar:Add("ax.scroller.horizontal")
    self.tabScroller:Dock(FILL)

    -- Characters button (always visible, right side)
    local characters = self.topBar:Add("ax.button")
    characters:Dock(RIGHT)
    characters:DockMargin(ax.util:ScreenScale(4), 0, 0, 0)
    characters:SetText("tab.characters")
    characters:SetWide(characters:GetWide() * 1.25)
    characters.DoClick = function()
        ax.client:EmitSound("ax.gui.menu.close")
        self:Close(function()
            ax.gui.main = vgui.Create("ax.main")
        end)
    end
end

function PANEL:CreateSidebar()
    self.sidebar = self:Add("EditablePanel")
    self.sidebar:SetPos(PADDING_X, self:GetBodyY())
    self.sidebar:SetSize(0, self:GetBodyHeight())
    self.sidebar:SetZPos(5)
    self.sidebar:SetVisible(false)
    self.sidebar.sidebarWidth = 0

    self.sidebar.Paint = nil

    self.sidebarScroller = self.sidebar:Add("DScrollPanel")
    self.sidebarScroller:Dock(FILL)
    self.sidebarScroller:DockPadding(SIDEBAR_PADDING, SIDEBAR_PADDING, SIDEBAR_PADDING, SIDEBAR_PADDING)
    self.sidebarScroller:GetVBar():SetWide(0)
    self.sidebarScroller.Paint = nil
end

function PANEL:CreateContent()
    self.content = vgui.Create("ax.transition.pages", self)
    self.content:SetZPos(1)
    self.content.Paint = function() end

    self:UpdateContentBounds()
end

function PANEL:GetBodyY()
    return PADDING_Y + (self.topBarHeight or 0) + BODY_GAP
end

function PANEL:GetBodyHeight()
    return ScrH() - self:GetBodyY() - PADDING_Y
end

function PANEL:UpdateContentBounds()
    local sidebarWidth = 0
    if ( IsValid(self.sidebar) and self.sidebar:IsVisible() ) then
        sidebarWidth = self.sidebar:GetWide() or 0
    end

    local x = PADDING_X + (sidebarWidth > 1 and sidebarWidth + SIDEBAR_GAP or 0)
    local y = self:GetBodyY()
    local w = ScrW() - x - PADDING_X
    local h = self:GetBodyHeight()

    self.content:SetPos(x, y)
    self.content:SetSize(w, h)

    self:ReflowAllPages()
end

function PANEL:ReflowAllPages()
    if ( !IsValid(self.content) ) then return end

    local pages = self.content.pages
    if ( !pages ) then return end

    for i = 1, #pages do
        local page = pages[i]
        if ( !IsValid(page) ) then continue end

        page:ReflowFromOffsets()

        -- Also reflow inner pages for tabs with sections
        local tabKey = page.key
        local innerPages = tabKey and self.innerPages[tabKey]
        if ( IsValid(innerPages) ) then
            innerPages:SetSize(page:GetWide(), page:GetTall())

            local subPages = innerPages.pages
            if ( subPages ) then
                for j = 1, #subPages do
                    if ( IsValid(subPages[j]) ) then
                        subPages[j]:ReflowFromOffsets()
                    end
                end
            end
        end
    end
end

function PANEL:PopulateTabs()
    local buttons = PopulateTabButtonTable()
    self.tabButtons = buttons

    local tabOrder = {}
    for k in SortedPairs(buttons) do
        tabOrder[#tabOrder + 1] = k
    end
    self.state.tabOrder = tabOrder

    for i = 1, #tabOrder do
        local k = tabOrder[i]
        local v = buttons[k]

        -- Create top bar button
        local button = self.tabScroller:Add("ax.button")
        button:Dock(LEFT)
        button:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
        button:SetText("tab." .. k)
        button:SetWide(button:GetWide() * 1.25)
        button.bActive = false
        button.tabKey = k

        -- Active tab underline indicator
        button.PaintAdditional = function(this, width, height)
            if ( !this.bActive ) then return end

            local glass = ax.theme:GetGlass()
            local metrics = ax.theme:GetMetrics()
            local barHeight = math.max(2, ax.util:ScreenScaleH(2))
            surface.SetDrawColor(ax.theme:ScaleAlpha(glass.progress, metrics.opacity))
            surface.DrawRect(0, height - barHeight, width, barHeight)
        end

        button.DoClick = function()
            self:SwitchTab(k)
        end

        self.tabScroller:AddPanel(button)
        self.buttonMap[k] = button

        -- Adjust top bar height to match tallest button
        if ( button:GetTall() > self.topBarHeight ) then
            self.topBarHeight = button:GetTall()
            self.topBar:SetTall(self.topBarHeight)
        end

        -- Create content page
        local page = self.content:CreatePage()
        page.key = k
        self.tabs[k] = page

        if ( istable(v) ) then
            if ( isfunction(v.Populate) ) then
                v:Populate(page)
            end

            -- Create inner transition pages for tabs with sections
            if ( istable(v.Sections) and table.Count(v.Sections) > 0 ) then
                local innerPages = vgui.Create("ax.transition.pages", page)
                innerPages:SetSize(page:GetWide(), page:GetTall())
                innerPages:SetPos(0, 0)
                innerPages.Paint = function() end
                self.innerPages[k] = innerPages

                local sortedKeys = GetSortedSectionKeys(v.Sections)
                for j = 1, #sortedKeys do
                    local sectionKey = sortedKeys[j]
                    self.sectionParentMap[sectionKey] = k

                    local subPage = innerPages:CreatePage()
                    subPage.key = sectionKey
                    self.sectionPages[sectionKey] = subPage
                end
            end
        elseif ( isfunction(v) ) then
            v(page)
        end
    end

    -- Update sidebar and content positions after top bar height is finalized
    if ( IsValid(self.sidebar) ) then
        self.sidebar:SetPos(PADDING_X, self:GetBodyY())
        self.sidebar:SetTall(self:GetBodyHeight())
    end

    self:UpdateContentBounds()
end

--- Switches to a main tab by key.
function PANEL:SwitchTab(tabKey)
    if ( !tabKey or self.state.activeTab == tabKey ) then return end
    if ( self.closing ) then return end

    local fadeTime = ax.option:Get("tabFadeTime", 0.25)

    if ( !self.opening ) then
        ax.client:EmitSound("ax.gui.menu.switch")
    end

    -- Close active section and tab
    self:CloseActiveSection()
    self:CloseActiveTab()

    -- Update state
    self.state.activeTab = tabKey
    ax.gui.tabLast = tabKey

    -- Update top bar button active states
    for k, btn in pairs(self.buttonMap) do
        if ( IsValid(btn) ) then
            btn.bActive = (k == tabKey)
        end
    end

    -- Transition to the tab's content page
    local page = self.tabs[tabKey]
    if ( IsValid(page) and page.index ) then
        self.content:TransitionToPage(page.index, fadeTime)
    end

    -- Fire tab OnOpen lifecycle hook
    local tabData = self.tabButtons[tabKey]
    if ( istable(tabData) and isfunction(tabData.OnOpen) ) then
        tabData:OnOpen(page, self.buttonMap[tabKey])
    end

    -- Handle sidebar visibility based on whether this tab has sections
    local hasSections = istable(tabData) and istable(tabData.Sections) and table.Count(tabData.Sections) > 0
    if ( hasSections ) then
        self:ShowSidebar(tabKey, tabData.Sections, fadeTime)

        -- Auto-select the first section
        local sortedKeys = GetSortedSectionKeys(tabData.Sections)
        if ( sortedKeys[1] ) then
            self:SwitchSection(sortedKeys[1])
        end
    elseif ( self.bSidebarVisible ) then
        self:HideSidebar(fadeTime)
    end
end

--- Switches to a section within the current tab.
function PANEL:SwitchSection(sectionKey)
    if ( !sectionKey or self.state.activeSection == sectionKey ) then return end
    if ( self.closing ) then return end

    local fadeTime = ax.option:Get("tabFadeTime", 0.25)
    local parentKey = self.sectionParentMap[sectionKey]
    if ( !parentKey ) then return end

    -- Only play sound when explicitly switching sections (not auto-selecting first)
    if ( !self.opening and self.state.activeSection ) then
        ax.client:EmitSound("ax.gui.menu.switch")
    end

    self:CloseActiveSection()

    -- Update state
    self.state.activeSection = sectionKey
    ax.gui.tabLast = sectionKey

    -- Update sidebar button active states
    for k, btn in pairs(self.sectionButtonMap) do
        if ( IsValid(btn) ) then
            btn.bActive = (k == sectionKey)
        end
    end

    -- Lazy populate section content on first access
    local subPage = self.sectionPages[sectionKey]
    local tabData = self.tabButtons[parentKey]
    if ( IsValid(subPage) and !subPage.bPopulated and istable(tabData) and istable(tabData.Sections) ) then
        local sectionData = tabData.Sections[sectionKey]
        if ( istable(sectionData) and isfunction(sectionData.Populate) ) then
            sectionData:Populate(subPage)
            subPage.bPopulated = true
        end
    end

    -- Transition inner page
    local innerPages = self.innerPages[parentKey]
    if ( IsValid(innerPages) and IsValid(subPage) and subPage.index ) then
        innerPages:TransitionToPage(subPage.index, fadeTime)
    end

    -- Fire section OnOpen lifecycle hook
    if ( istable(tabData) and istable(tabData.Sections) ) then
        local sectionData = tabData.Sections[sectionKey]
        if ( istable(sectionData) and isfunction(sectionData.OnOpen) ) then
            sectionData:OnOpen(subPage, self.sectionButtonMap[sectionKey])
        end
    end
end

function PANEL:CloseActiveTab()
    local activeTab = self.state.activeTab
    if ( !activeTab ) then return end

    local tabData = self.tabButtons[activeTab]
    if ( istable(tabData) and isfunction(tabData.OnClose) ) then
        tabData:OnClose(self.tabs[activeTab], self.buttonMap[activeTab])
    end
end

function PANEL:CloseActiveSection()
    local activeSection = self.state.activeSection
    if ( !activeSection ) then return end

    local parentKey = self.sectionParentMap[activeSection]
    if ( !parentKey ) then return end

    local tabData = self.tabButtons[parentKey]
    if ( istable(tabData) and istable(tabData.Sections) ) then
        local sectionData = tabData.Sections[activeSection]
        if ( istable(sectionData) and isfunction(sectionData.OnClose) ) then
            sectionData:OnClose(self.sectionPages[activeSection], self.sectionButtonMap[activeSection])
        end
    end

    self.state.activeSection = nil
end

--- Shows the sidebar with section buttons for the given tab.
function PANEL:ShowSidebar(tabKey, sections, fadeTime)
    -- Clear old section buttons
    for _, btn in pairs(self.sectionButtonMap) do
        if ( IsValid(btn) ) then
            btn:Remove()
        end
    end
    self.sectionButtonMap = {}

    -- Create section buttons
    local sortedKeys = GetSortedSectionKeys(sections)
    for i = 1, #sortedKeys do
        local sectionKey = sortedKeys[i]

        local button = self.sidebarScroller:Add("ax.button")
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, SIDEBAR_BUTTON_GAP)
        button:SetText("tab." .. tabKey .. "." .. sectionKey)
        button.bActive = false
        button.sectionKey = sectionKey

        -- Active section left accent indicator
        button.PaintAdditional = function(this, width, height)
            if ( !this.bActive ) then return end

            local glass = ax.theme:GetGlass()
            local metrics = ax.theme:GetMetrics()
            local barWidth = math.max(2, ax.util:ScreenScale(2))
            surface.SetDrawColor(ax.theme:ScaleAlpha(glass.progress, metrics.opacity))
            surface.DrawRect(0, 0, barWidth, height)
        end

        button.DoClick = function()
            self:SwitchSection(sectionKey)
        end

        self.sectionButtonMap[sectionKey] = button
    end

    -- Animate sidebar in (only if not already visible)
    if ( !self.bSidebarVisible ) then
        self.bSidebarVisible = true
        self.sidebar:SetVisible(true)
        self.sidebar:SetWide(0)
        self.sidebar.sidebarWidth = 0

        self.sidebar:Motion(fadeTime or ax.option:Get("tabFadeTime", 0.25), {
            Target = {sidebarWidth = SIDEBAR_WIDTH},
            Easing = "OutQuad",
            Think = function(vars)
                self.sidebar:SetWide(vars.sidebarWidth)
                self:UpdateContentBounds()
            end,
            OnComplete = function()
                self:UpdateContentBounds()
            end
        })
    end
end

--- Hides the sidebar with an animation.
function PANEL:HideSidebar(fadeTime)
    if ( !self.bSidebarVisible ) then return end

    self.bSidebarVisible = false

    -- Remove section buttons before clearing the map
    for _, btn in pairs(self.sectionButtonMap) do
        if ( IsValid(btn) ) then
            btn:Remove()
        end
    end
    self.sectionButtonMap = {}

    self.sidebar:Motion(fadeTime or ax.option:Get("tabFadeTime", 0.25), {
        Target = {sidebarWidth = 0},
        Easing = "OutQuad",
        Think = function(vars)
            self.sidebar:SetWide(vars.sidebarWidth)
            self:UpdateContentBounds()
        end,
        OnComplete = function()
            -- Guard against race condition if ShowSidebar was called during animation
            if ( !self.bSidebarVisible ) then
                self.sidebar:SetVisible(false)
            end

            self:UpdateContentBounds()
        end
    })
end

--- Restores the last active tab/section, or selects the first tab.
function PANEL:RestoreLastTab()
    local lastKey = ax.gui.tabLast
    if ( !lastKey ) then
        return self:SelectFirstTab()
    end

    -- Case 1: lastKey is a main tab key
    if ( self.tabButtons[lastKey] ) then
        self:SwitchTab(lastKey)
        return true
    end

    -- Case 2: lastKey is a section key — switch to parent tab, then section
    local parentKey = self.sectionParentMap[lastKey]
    if ( parentKey and self.tabButtons[parentKey] ) then
        self:SwitchTab(parentKey)
        self:SwitchSection(lastKey)
        return true
    end

    return self:SelectFirstTab()
end

--- Selects the first available tab.
function PANEL:SelectFirstTab()
    local firstKey = self.state.tabOrder[1]
    if ( firstKey ) then
        self:SwitchTab(firstKey)
        return true
    end

    return false
end

--- Returns the tab/section data table for a given key.
function PANEL:GetTabButtonData(key)
    if ( !istable(self.tabButtons) or !key ) then
        return nil
    end

    local tabData = self.tabButtons[key]
    if ( tabData != nil ) then
        return tabData
    end

    local parentKey = self.sectionParentMap and self.sectionParentMap[key]
    local parentData = parentKey and self.tabButtons[parentKey]
    if ( istable(parentData) and istable(parentData.Sections) ) then
        return parentData.Sections[key]
    end

    return nil
end

--- Returns the button panel for a given tab or section key.
function PANEL:GetTabButtonPanel(key)
    local parentKey = self.sectionParentMap and self.sectionParentMap[key]
    if ( parentKey ) then
        return self.sectionButtonMap[key]
    end

    return self.buttonMap and self.buttonMap[key]
end

function PANEL:Open()
    local fadeTime = ax.option:Get("tabFadeTime", 0.25)

    -- Ensure topBar starts offscreen with correct height
    self.topBar.topBarY = -self.topBarHeight
    self.topBar.topBarAlpha = 0
    self.topBar:SetPos(PADDING_X, -self.topBarHeight)
    self.topBar:SetAlpha(0)

    -- Fade in self
    self:Motion(fadeTime, {
        Target = {alpha = 255},
        Easing = "OutQuad",
        Think = function(vars)
            self:SetAlpha(vars.alpha)
        end,
        OnComplete = function()
            self.opening = false
        end
    })

    -- Slide top bar down
    self.topBar:Motion(fadeTime, {
        Target = {topBarY = PADDING_Y, topBarAlpha = 255},
        Easing = "OutQuad",
        Think = function(vars)
            self.topBar:SetPos(PADDING_X, vars.topBarY)
            self.topBar:SetAlpha(vars.topBarAlpha)
        end
    })

    -- Set backdrop animation targets
    self:SetBackgroundBlurTarget(1)
    self:SetBackgroundAlphaTarget(1)
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

    local fadeTime = ax.option:Get("tabFadeTime", 0.25)
    hook.Run("OnTabMenuClosing", self, fadeTime)

    -- Set backdrop animation targets to 0
    self:SetBackgroundBlurTarget(0)
    self:SetBackgroundAlphaTarget(0)
    self:SetGradientLeftTarget(0)
    self:SetGradientRightTarget(0)
    self:SetGradientTopTarget(0)
    self:SetGradientBottomTarget(0)

    -- Fade out and remove
    self:Motion(fadeTime, {
        Target = {alpha = 0},
        Easing = "OutQuad",
        Think = function(vars)
            self:SetAlpha(vars.alpha)
        end,
        OnComplete = function()
            self:Remove()

            if ( isfunction(callback) ) then
                callback()
            end
        end
    })

    -- Slide top bar up
    self.topBar:Motion(fadeTime, {
        Target = {topBarY = -self.topBarHeight - PADDING_Y, topBarAlpha = 0},
        Easing = "OutQuad",
        Think = function(vars)
            self.topBar:SetPos(PADDING_X, vars.topBarY)
            self.topBar:SetAlpha(vars.topBarAlpha)
        end
    })

    -- Slide current content page down
    local currentPageIndex = self.content:GetCurrentPage()
    local currentPage = self.content.pages and self.content.pages[currentPageIndex]
    if ( IsValid(currentPage) ) then
        currentPage:SlideDown(fadeTime)
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
    if ( bHoldingTab and ( self.anchorTime < CurTime() ) and self.bAnchorEnabled ) then
        self.bAnchorEnabled = false
    end

    if ( ( !bHoldingTab and !self.bAnchorEnabled ) or gui.IsGameUIVisible() ) then
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

    self:SetBackgroundBlur(ax.ease:Lerp("Linear", time, self:GetBackgroundBlur(), self:GetBackgroundBlurTarget()))
    self:SetBackgroundAlpha(ax.ease:Lerp("Linear", time, self:GetBackgroundAlpha(), self:GetBackgroundAlphaTarget()))

    if ( math.Round(self:GetBackgroundBlur()) > 0 ) then
        ax.render().Rect(0, 0, width, height)
            :Rad(0)
            :Flags(ax.render.SHAPE_IOS)
            :Blur(1.4 * self:GetBackgroundBlur())
            :Draw()
    end

    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()
    local scaledTabBackdrop = ax.theme:ScaleAlpha(glass.tabBackdrop, metrics.opacity)
    ax.render.Draw(0, 0, 0, width, height, ColorAlpha(scaledTabBackdrop, 50 * self:GetBackgroundAlpha()))

    self:SetGradientLeft(ax.ease:Lerp("Linear", time, self:GetGradientLeft(), self:GetGradientLeftTarget()))
    self:SetGradientRight(ax.ease:Lerp("Linear", time, self:GetGradientRight(), self:GetGradientRightTarget()))
    self:SetGradientTop(ax.ease:Lerp("Linear", time, self:GetGradientTop(), self:GetGradientTopTarget()))
    self:SetGradientBottom(ax.ease:Lerp("Linear", time, self:GetGradientBottom(), self:GetGradientBottomTarget()))

    local scaledGradLeft = ax.theme:ScaleAlpha(glass.gradientLeft, metrics.gradientOpacity)
    local scaledGradRight = ax.theme:ScaleAlpha(glass.gradientRight, metrics.gradientOpacity)
    local scaledGradTop = ax.theme:ScaleAlpha(glass.gradientTop, metrics.gradientOpacity)
    local scaledGradBottom = ax.theme:ScaleAlpha(glass.gradientBottom, metrics.gradientOpacity)
    ax.theme:DrawGlassGradients(0, 0, width, height, {
        left = ColorAlpha(scaledGradLeft, 50 * self:GetGradientLeft()),
        right = ColorAlpha(scaledGradRight, 50 * self:GetGradientRight()),
        top = ColorAlpha(scaledGradTop, 50 * self:GetGradientTop()),
        bottom = ColorAlpha(scaledGradBottom, 50 * self:GetGradientBottom())
    })
end

vgui.Register("ax.tab", PANEL, "EditablePanel")

if ( IsValid(ax.gui.tab) ) then
    ax.gui.tab:Remove()
end

ax.gui.tabLast = nil
