--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local title

local PANEL = {}

function PANEL:Init()
    hook.Run("PreMainMenuCreateCreated", self)

    self.payload = {}
    self.tabs = {}

    local vars = self:GetVars()
    for k, v in pairs(vars) do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end

        if ( isfunction(v.canPopulate) ) then
            local canPop, err = pcall(function()
                return v:canPopulate(self.payload, ax.client)
            end)

            if ( !canPop ) then
                ax.util:PrintWarning(("Failed to check canPopulate for character var '%s': %s"):format(tostring(k), tostring(err)))
                continue
            end

            if ( !err ) then
                continue
            end
        end

        if ( v.default != nil and self.payload[k] == nil ) then
            self.payload[k] = v.default
        end
    end

    self:StartAtBottom()
    self:ClearVars()

    hook.Run("PostMainMenuCreateCreated", self)
end

function PANEL:OnSlideStart()
    -- Build only the first available category dynamically based on current payload.
    local categories = self:GetOrderedCategories()
    if ( #categories == 0 ) then return end

    local firstCategory = categories[1]
    local tab = self:CreateOrGetCategoryTab(firstCategory, 1)
    if ( IsValid(tab) ) then
        tab:SlideToFront(0)
        self:PopulateVars(firstCategory)
    end
end

function PANEL:GetVars()
    local vars = table.Copy(ax.character.vars)
    local sortOrder = 0
    for k, v in pairs(vars) do
        v.category = v.category or "01_appearance"
        v.sortOrder = v.sortOrder or sortOrder
        sortOrder = sortOrder + 2
    end

    return vars
end

function PANEL:NavigateToNextTab(currentTab)
    local categories = self:GetOrderedCategories()
    if ( #categories == 0 ) then return end

    local currentCategory = currentTab.category
    local currentIndex
    for i, name in ipairs(categories) do
        if ( name == currentCategory ) then
            currentIndex = i
            break
        end
    end

    if ( !currentIndex ) then return end

    if ( currentIndex == #categories ) then
        net.Start("ax.character.create")
            net.WriteTable(self.payload)
        net.SendToServer()
        return
    end

    local nextCategory = categories[currentIndex + 1]
    local nextTab = self:CreateOrGetCategoryTab(nextCategory, currentIndex + 1)
    if ( !IsValid(nextTab) ) then return end

    currentTab:SlideLeft()
    nextTab:SlideToFront()
    self:ClearVars(nextCategory)
    self:PopulateVars(nextCategory)
end

function PANEL:NavigateToPreviousTab(currentTab)
    local categories = self:GetOrderedCategories()
    if ( #categories == 0 ) then return end

    local currentCategory = currentTab.category
    local currentIndex
    for i, name in ipairs(categories) do
        if ( name == currentCategory ) then currentIndex = i break end
    end

    if ( !currentIndex ) then return end

    if ( currentIndex == 1 ) then
        self:SlideDown(nil, function()
            self:ClearVars()
        end)
        self:GetParent().splash:SlideToFront()
        return
    end

    local prevCategory = categories[currentIndex - 1]
    local prevTab = self:CreateOrGetCategoryTab(prevCategory, currentIndex - 1)
    if ( !IsValid(prevTab) ) then return end

    currentTab:SlideRight()
    prevTab:SlideToFront()
    self:ClearVars(prevCategory)
    self:PopulateVars(prevCategory)
end

-- Returns a sorted list of category names that are currently eligible for population
function PANEL:GetOrderedCategories()
    local vars = self:GetVars()
    local categories = {}
    local categoryOrder = {}

    for k, v in SortedPairsByMemberValue(vars, "category") do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end

        local category = v.category or "01_appearance"

        local canUse = true
        if ( isfunction(v.canPopulate) ) then
            local ok, res = pcall(function()
                return v:canPopulate(self.payload, ax.client)
            end)

            if ( !ok or !res ) then
                if ( !ok ) then
                    ax.util:PrintWarning(("Failed to check canPopulate for character var '%s': %s"):format(tostring(k), tostring(res)))
                end
                canUse = false
            end
        end

        if ( canUse ) then
            categories[category] = true
            categoryOrder[category] = math.min(categoryOrder[category] or v.sortOrder, v.sortOrder)
        end
    end

    local catList = {}
    for name, _ in pairs(categories) do
        local baseOrder = categoryOrder[name] or 0
        local prefix = string.match(name, "^(%d+)[_%-]")
        local orderKey = baseOrder
        if ( prefix ) then
            orderKey = tonumber(prefix) * 100000 + baseOrder
        end
        table.insert(catList, { name = name, order = orderKey })
    end

    table.sort(catList, function(a, b)
        if ( a.order == b.order ) then return a.name < b.name end
        return a.order < b.order
    end)

    local ordered = {}
    for _, info in ipairs(catList) do table.insert(ordered, info.name) end

    -- Update indices on existing tabs for consistent navigation
    for i, name in ipairs(ordered) do
        local tab = self.tabs[name]
        if ( IsValid(tab) ) then tab.index = i end
    end

    return ordered
end

-- Creates a tab for a category if it does not yet exist (or returns existing one)
function PANEL:CreateOrGetCategoryTab(category, index)
    local tab = self.tabs[category]
    if ( IsValid(tab) ) then
        tab.index = index or tab.index or 1
        return tab
    end

    tab = self:CreatePage(category)
    tab.category = category
    tab.index = index or tab.index or 1
    tab:StartAtRight()
    tab:CreateNavigation(tab, "back", function()
        self:NavigateToPreviousTab(tab)
    end, "next", function()
        self:NavigateToNextTab(tab)
    end)

    tab.container = tab:Add("EditablePanel")
    tab.container:Dock(FILL)
    tab.container:DockMargin(ax.util:ScreenScale(32), ax.util:ScreenScaleH(32), ax.util:ScreenScale(32), ax.util:ScreenScaleH(32))
    tab.container:InvalidateParent(true)

    self.tabs[category] = tab

    title = tab:Add("ax.text")
    title:SetFont("ax.huge.bold")
    local displayText = ax.localisation:GetPhrase("mainmenu.category." .. category)
    title:SetText(utf8.upper(displayText))
    title:Dock(TOP)
    title:DockMargin(ax.util:ScreenScale(32), ax.util:ScreenScaleH(32), 0, 0)

    return tab
end

function PANEL:GetContainer(category)
    category = category or "01_appearance"

    local container = self.tabs[category]
    if ( !IsValid(container) ) then return end

    container = container.container
    if ( !IsValid(container) ) then return end

    return container
end

function PANEL:ClearVars(category)
    if ( !category ) then
        for k, v in pairs(self.tabs) do
            self:ClearVars(k)
        end

        return
    end

    local container = self:GetContainer(category)
    if ( !IsValid(container) ) then return end

    container:Clear()
end

function PANEL:PopulateVars(category)
    local vars = self:GetVars()

    category = category or "01_appearance"

    local container = self:GetContainer(category)
    if ( !IsValid(container) ) then return end

    for k, v in SortedPairsByMemberValue(vars, "sortOrder") do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end
        if ( (v.category or "01_appearance") != category ) then continue end

        if ( isfunction(v.canPopulate) ) then
            local canPop, err = pcall(function()
                return v:canPopulate(self.payload, ax.client)
            end)

            if ( !canPop ) then
                ax.util:PrintWarning(("Failed to check canPopulate for character var '%s': %s"):format(tostring(k), tostring(err)))
                continue
            end

            if ( !err ) then
                continue
            end
        end

        if ( isfunction(v.populate) ) then
            local ok, err = pcall(function()
                v:populate(container, self.payload)
            end)

            if ( !ok ) then
                ax.util:PrintWarning(("Failed to populate character var '%s': %s"):format(tostring(k), tostring(err)))
            end

            continue
        end

        if ( v.fieldType == ax.type.string ) then
            local option = container:Add("ax.text")
            option:SetFont("ax.regular.bold")
            option:SetText(utf8.upper(ax.util:UniqueIDToName(k)))
            option:SetZPos(v.sortOrder - 1)
            option:Dock(TOP)

            local entry = container:Add("ax.text.entry")
            entry:SetPlaceholderText(v.default)
            entry:SetZPos(v.sortOrder)
            entry:Dock(TOP)
            entry:DockMargin(0, 0, 0, ax.util:ScreenScaleH(16))

            entry.OnValueChange = function(this)
                self.payload[k] = this:GetText()

                if ( self.OnPayloadChanged ) then
                    self:OnPayloadChanged(self.payload)
                end

                hook.Run("OnPayloadChanged", self.payload)
            end

            if ( isfunction(v.populatePost) ) then
                v:populatePost(container, self.payload, option, entry)
            end
        elseif ( v.fieldType == ax.type.number ) then
            local option = container:Add("ax.text")
            option:SetFont("ax.regular.bold")
            option:SetText(utf8.upper(ax.util:UniqueIDToName(k)))
            option:SetZPos(v.sortOrder - 1)
            option:Dock(TOP)

            local slider = container:Add("DNumSlider")
            slider:SetDecimals(v.decimals or 0)
            slider:SetMin(v.min or 0)
            slider:SetMax(v.max or 100)
            slider:SetValue(v.default)
            slider:SetZPos(v.sortOrder)
            slider:Dock(TOP)
            slider:DockMargin(0, 0, 0, ax.util:ScreenScaleH(16))

            slider.OnValueChanged = function(this, value)
                self.payload[k] = value

                if ( self.OnPayloadChanged ) then
                    self:OnPayloadChanged(self.payload)
                end

                hook.Run("OnPayloadChanged", self.payload)
            end

            if ( isfunction(v.populatePost) ) then
                v:populatePost(container, self.payload, option, slider)
            end
        end
    end

    if ( self.OnPopulateVars ) then
        self:OnPopulateVars(container, category, self.payload)
    end

    hook.Run("OnCharacterPopulateVars", container, category, self.payload)
end

function PANEL:OnPopulateVars(container, category, payload)
    local targetCategory = category or "01_appearance"
    for k, v in pairs(self:GetVars()) do
        if ( v.field == "model" ) then
            targetCategory = v.category or "01_appearance"
            break
        end
    end

    if ( ax.util:FindString(category, targetCategory) ) then
        self.miscModel = container:Add("DModelPanel")
        self.miscModel:SetModel(payload.model or "models/player.mdl")
        self.miscModel:SetWide(0)
        self.miscModel:SetFOV(ax.util:ScreenScale(12))
        self.miscModel:Dock(LEFT)
        self.miscModel:DockMargin(0, 0, 0, 0)
        self.miscModel:SetZPos(-1)

        self.miscModel.LayoutEntity = function(this, entity)
            this:RunAnimation()
            entity:SetAngles(Angle(0, 90, 0))
        end

        local entity = self.miscModel:GetEntity()
        if ( IsValid(entity) ) then
            entity:SetSkin(payload.skin or 0)
        end
    end
end

function PANEL:OnPayloadChanged(payload)
    if ( IsValid(self.miscModel) ) then
        if ( payload.model and self.miscModel:GetModel() != payload.model ) then
            self.miscModel:SetModel(payload.model)
            if ( self.miscModel:GetWide() == 0 ) then
                self.miscModel:Motion(1, {
                    Target = {
                        width = self.miscModel:GetParent():GetWide() / 4,
                        rightPadding = ax.util:ScreenScale(32)
                    },
                    Easing = "OutQuad",
                    Think = function(this)
                        self.miscModel:SetWide(this.width)
                        self.miscModel:DockMargin(0, 0, this.rightPadding, 0)
                    end
                })
            end
        end

        self.miscModel:GetEntity():SetSkin(payload.skin or 0)
    end
end

function PANEL:Paint(width, height)
    ax.util:DrawGradient("down", 0, 0, width, height, Color(0, 0, 0, 200))
end

vgui.Register("ax.main.create", PANEL, "ax.transition.pages")
