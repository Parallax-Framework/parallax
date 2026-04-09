--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

-- Helper function to get the appropriate store based on type string
local function GetStoreByType(storeType)
    if ( storeType == "config" ) then
        return ax.config
    elseif ( storeType == "option" ) then
        return ax.option
    end
    return nil
end

local STORE_TYPE_LABELS = {
    [ax.type.bool] = "store.type.bool",
    [ax.type.number] = "store.type.number",
    [ax.type.string] = "store.type.string",
    [ax.type.text] = "store.type.string",
    [ax.type.color] = "store.type.color",
    [ax.type.array] = "store.type.array"
}

local function GetLocalizedPhraseOrNil(phrase)
    if ( !isstring(phrase) or phrase == "" ) then
        return nil
    end

    local language = ax.localization and ax.localization.langs and ax.localization.langs[ax.localization:GetCurrentLanguage()]
    local fallback = ax.localization and ax.localization.langs and ax.localization.langs.en

    if ( istable(language) and isstring(language[phrase]) and language[phrase] != "" ) then
        return language[phrase]
    end

    if ( istable(fallback) and isstring(fallback[phrase]) and fallback[phrase] != "" ) then
        return fallback[phrase]
    end

    return nil
end

local function LooksLikePhraseKey(value)
    if ( !isstring(value) or value == "" ) then
        return false
    end

    return string.find(value, ".", 1, true) != nil and string.find(value, " ", 1, true) == nil
end

local function ResolveStoreString(value)
    if ( !isstring(value) or value == "" ) then
        return nil
    end

    local translated = GetLocalizedPhraseOrNil(value)
    if ( translated ) then
        return translated
    end

    if ( !LooksLikePhraseKey(value) ) then
        return value
    end

    return nil
end

local function ResolveStoreTitle(storeType, key)
    return GetLocalizedPhraseOrNil(storeType .. "." .. key) or tostring(key or ax.localization:GetPhrase("unknown"))
end

local function ResolveStoreDescription(storeType, key, data)
    local description = ResolveStoreString(data and data.description)
    if ( description and description != "" ) then
        return description
    end

    return GetLocalizedPhraseOrNil(storeType .. "." .. key .. ".help")
end

local function ResolveStoreTypeLabel(typeID, data)
    if ( data and data.keybind ) then
        return GetLocalizedPhraseOrNil("store.type.keybind") or "Keybind"
    end

    local phrase = STORE_TYPE_LABELS[typeID]
    if ( phrase ) then
        return GetLocalizedPhraseOrNil(phrase) or ax.type:Format(typeID)
    end

    return ax.type:Format(typeID)
end

local function FormatStoreValue(store, key, value)
    if ( !store or !store.registry ) then
        return ax.localization:GetPhrase("unknown")
    end

    local entry = store.registry[key]
    if ( !entry ) then
        return ax.localization:GetPhrase("unknown")
    end

    local data = entry.data or {}

    if ( data.keybind ) then
        local selected = tonumber(value) or (KEY_NONE or 0)
        if ( selected == (KEY_NONE or 0) ) then
            return ax.localization:GetPhrase("unknown")
        end

        local keyName = input.GetKeyName(selected)
        return isstring(keyName) and string.upper(keyName) or ax.localization:GetPhrase("unknown")
    end

    if ( entry.type == ax.type.bool ) then
        return tobool(value) and ax.localization:GetPhrase("store.enabled") or ax.localization:GetPhrase("store.disabled")
    elseif ( entry.type == ax.type.number ) then
        local numberValue = tonumber(value) or 0
        local decimals = math.max(tonumber(data.decimals) or 0, 0)

        if ( decimals > 0 ) then
            return string.format("%." .. decimals .. "f", numberValue)
        end

        return tostring(math.Round(numberValue))
    elseif ( entry.type == ax.type.string or entry.type == ax.type.text ) then
        local text = tostring(value or "")
        if ( text == "" ) then
            return ax.localization:GetPhrase("unknown")
        end

        return ax.util:CapTextWord(text, 48)
    elseif ( entry.type == ax.type.color ) then
        if ( !(IsColor(value) or (istable(value) and isnumber(value.r) and isnumber(value.g) and isnumber(value.b))) ) then
            return ax.localization:GetPhrase("unknown")
        end

        local alpha = tonumber(value.a) or 255
        if ( alpha < 255 ) then
            return string.format("#%02X%02X%02X%02X / %d", value.r, value.g, value.b, alpha, alpha)
        end

        return string.format("#%02X%02X%02X", value.r, value.g, value.b)
    elseif ( entry.type == ax.type.array ) then
        local choices = data.choices
        if ( !istable(choices) and isfunction(data.populate) ) then
            local ok, populated = ax.util:SafeCall(data.populate)
            if ( ok and istable(populated) ) then
                choices = populated
            end
        end

        local choiceLabel = istable(choices) and choices[value] or nil
        return ResolveStoreString(choiceLabel) or tostring(value or ax.localization:GetPhrase("unknown"))
    end

    return tostring(value or ax.localization:GetPhrase("unknown"))
end

local function GetStoreAccentColor(storeType)
    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()

    if ( storeType == "config" ) then
        return ax.theme:ScaleAlpha(glass.progress or glass.highlight, metrics.opacity)
    end

    return ax.theme:ScaleAlpha(glass.highlight or glass.progress, metrics.opacity)
end

local STORE_GRID_ITEM_HEIGHT = ax.util:ScreenScaleH(16)
local STORE_GRID_SPACING_X = ax.util:ScreenScale(2)
local STORE_GRID_SPACING_Y = ax.util:ScreenScaleH(4)

local function EnsureScrollStore(storeType)
    ax.gui = ax.gui or {}

    if ( storeType == "config" ) then
        ax.gui.storeLastConfigScroll = ax.gui.storeLastConfigScroll or {}
        return ax.gui.storeLastConfigScroll
    elseif ( storeType == "option" ) then
        ax.gui.storeLastOptionScroll = ax.gui.storeLastOptionScroll or {}
        return ax.gui.storeLastOptionScroll
    end

    return nil
end

local function RestoreStoredScroll(scroller, storeType, category)
    if ( storeType != "config" and storeType != "option" ) then return end
    if ( !IsValid(scroller) ) then return end
    if ( !isstring(category) or category == "" ) then return end

    local scrollStore = EnsureScrollStore(storeType)
    if ( !istable(scrollStore) ) then return end

    local scrollTarget = tonumber(scrollStore[category] or 0) or 0

    scroller.ScrollTarget = math.max(scrollTarget, 0)
    scroller.ScrollLerp = scroller.ScrollTarget
    scroller:InvalidateLayout(true)
end

local function AttachScrollTracking(scroller, storeType, category)
    if ( storeType != "config" and storeType != "option" ) then return end
    if ( !IsValid(scroller) ) then return end
    if ( !isstring(category) or category == "" ) then return end

    local originalThink = scroller.Think
    scroller.Think = function(this)
        if ( originalThink ) then
            originalThink(this)
        end

        local scrollStore = EnsureScrollStore(storeType)
        if ( !istable(scrollStore) ) then return end

        scrollStore[category] = tonumber(this.ScrollTarget or 0) or 0
    end
end

local function GetStoreColumnCount()
    return math.max(math.floor(tonumber(ax.option:Get("store.columns", 3)) or 3), 1)
end

local function CalculateStoreGridHeight(itemCount, columnCount)
    local rowCount = math.max(math.ceil(math.max(itemCount, 1) / columnCount), 1)
    return (rowCount * STORE_GRID_ITEM_HEIGHT) + (math.max(rowCount - 1, 0) * STORE_GRID_SPACING_Y)
end

function PANEL:Init()
    self:Dock(FILL)
    self:InvalidateParent(true)

    self.categories = self:Add("ax.scroller.vertical")
    self.categories:Dock(LEFT)
    self.categories:SetSize(ax.util:ScreenScale(32), ScrH() - ax.util:ScreenScaleH(64))

    self.container = self:Add("EditablePanel")
    self.container:Dock(FILL)
    self.container:DockMargin(0, ax.util:ScreenScaleH(16) + self.categories:GetTall(), 0, 0)
    self.container.Paint = nil
end

function PANEL:SetType(type)
    if ( !type or type == "" ) then
        ax.util:PrintError("ax.store: Invalid type '" .. tostring(type) .. "'")
        return
    end

    local store = GetStoreByType(type)
    if ( !store ) then
        ax.util:PrintError("ax.store: Unknown type '" .. tostring(type) .. "'")
        return
    end

    self.categories:Clear()
    self.container:Clear()

    local categories = store:GetAllCategories()
    categories = table.Copy(categories)
    table.sort(categories, function(a, b) return a < b end)

    local categoryButtons = {}

    for k, v in SortedPairsByValue(categories) do
        local button = self.categories:Add("ax.button")
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, ax.util:ScreenScaleH(2))
        button:SetText("category." .. v)

        -- ["general"] = "General",
        -- ["category.general"] = "General",
        -- ["subcategory.general"] = "General",

        self.categories:SetWide(math.max(self.categories:GetWide(), button:GetWide() + ax.util:ScreenScale(16)))

        local tab = self:CreatePage()

        local scroller = tab:Add("ax.scroller.vertical")
        scroller:Dock(FILL)
        tab.storeScroller = scroller
        AttachScrollTracking(scroller, type, v)

        button.tab = tab
        button.tab.index = tab.index
        button.category = v  -- Store the category name for reference

        -- Store button reference for later use
        categoryButtons[v] = button

        button.DoClick = function()
            -- Track last selected category per store type
            if ( type == "config" ) then
                ax.gui.storeLastConfig = v
            elseif ( type == "option" ) then
                ax.gui.storeLastOption = v
            end

            self:TransitionToPage(button.tab.index, ax.option:Get("tabFadeTime", 0.25))
            self:Populate(tab, scroller, type, v)
            RestoreStoredScroll(scroller, type, v)
        end
    end

    -- Store reference for later use
    self.categoryButtons = categoryButtons

    -- Adjust all pages now that we know the final width of categories
    for k, v in ipairs(self:GetPages()) do
        v:SetXOffset(self.categories:GetWide() + ax.util:ScreenScale(2))
        v:SetWidthOffset(-self.categories:GetWide() - ax.util:ScreenScale(2))
    end

    -- Determine which category to show initially
    local targetCategory = nil
    local targetButton = nil

    -- Check for last selected category for this store type
    if ( type == "config" and ax.gui.storeLastConfig and self.categoryButtons[ax.gui.storeLastConfig] ) then
        targetCategory = ax.gui.storeLastConfig
        targetButton = self.categoryButtons[ax.gui.storeLastConfig]
    elseif ( type == "option" and ax.gui.storeLastOption and self.categoryButtons[ax.gui.storeLastOption] ) then
        targetCategory = ax.gui.storeLastOption
        targetButton = self.categoryButtons[ax.gui.storeLastOption]
    end

    -- Default to first category if no saved preference or saved category doesn't exist
    if ( !targetCategory or !targetButton ) then
        targetCategory = categories[1]
        targetButton = self.categoryButtons[targetCategory]
    end

    -- Show the target page
    if ( targetButton and targetButton.tab ) then
        self:TransitionToPage(targetButton.tab.index, 0, true)

        local targetScroller = targetButton.tab.storeScroller
        if ( !IsValid(targetScroller) ) then
            for _, child in ipairs(targetButton.tab:GetChildren()) do
                if ( IsValid(child) and child:GetClassName() == "ax.scroller.vertical" ) then
                    targetScroller = child
                    break
                end
            end
        end

        self:Populate(targetButton.tab, targetScroller, type, targetCategory)
        RestoreStoredScroll(targetScroller, type, targetCategory)
    end
end

function PANEL:Populate(tab, scroller, type, category)
    if ( tab.populated ) then return end
    tab.populated = true

    if ( !scroller or !IsValid(scroller) ) then return end
    if ( !type or type == "" ) then return end
    if ( !category or category == "" ) then return end

    local store = GetStoreByType(type)
    if ( !store ) then
        ax.util:PrintError("ax.store: Unknown type '" .. tostring(type) .. "'")
        return
    end

    local rows = store:GetAllByCategory(category)

    if ( table.IsEmpty(rows) ) then
        local label = scroller:Add("ax.text")
        label:Dock(FILL)
        label:SetFont("ax.large.italic")
        label:SetText(string.format("No %s found in category: %s", type, category), true)
        label:SetContentAlignment(5)
        label:SetTextColor(Color(200, 200, 200))
        return
    end

    -- Group entries by subcategory for proper organization
    local groupedEntries = {}
    local hasSubCategories = false

    for key, entry in pairs(rows) do
        local subCat = entry.data.subCategory or "general"
        if ( entry.data.subCategory ) then
            hasSubCategories = true
        end

        if ( !groupedEntries[subCat] ) then
            groupedEntries[subCat] = {}
        end

        groupedEntries[subCat][key] = entry
    end

    -- Sort subcategories alphabetically, but put "general" first if it exists
    local sortedSubCategories = {}
    for subCat, _ in pairs(groupedEntries) do
        table.insert(sortedSubCategories, subCat)
    end

    table.sort(sortedSubCategories, function(a, b)
        if ( a == "general" ) then return true end
        if ( b == "general" ) then return false end
        return a < b
    end)

    -- Only show subcategory headers if there are actual subcategories (not just "general")
    local showSubCategoryHeaders = hasSubCategories and table.Count(groupedEntries) > 1

    for _, subCat in ipairs(sortedSubCategories) do
        local entries = groupedEntries[subCat]

        -- Add subcategory header (except for "general" when there's only one subcategory)
        if ( showSubCategoryHeaders and subCat != "general" ) then
            local subCategoryLabel = scroller:Add("ax.text")
            subCategoryLabel:SetFont("ax.huge.bold.italic")
            subCategoryLabel:SetText(utf8.upper(ax.localization:GetPhrase("subcategory." .. subCat)), true)
            subCategoryLabel:Dock(TOP)
        end

        -- Separate valid entries from unsupported ones
        local validEntries = {}
        local unsupportedEntries = {}

        for key, entry in SortedPairs(entries) do
            local panelName = nil

            if ( entry.type == ax.type.bool ) then
                panelName = "ax.store.bool"
            elseif ( entry.type == ax.type.number ) then
                panelName = entry.data.keybind and "ax.store.keybind" or "ax.store.number"
            elseif ( entry.type == ax.type.string ) then
                panelName = "ax.store.string"
            elseif ( entry.type == ax.type.color ) then
                panelName = "ax.store.color"
            elseif ( entry.type == ax.type.array ) then
                panelName = entry.data.segmented and "ax.store.segmented" or "ax.store.array"
            end

            if ( panelName ) then
                validEntries[#validEntries + 1] = {key = key, panelName = panelName}
            else
                unsupportedEntries[#unsupportedEntries + 1] = {key = key, entry = entry}
            end
        end

        -- Build grid for valid entries
        if ( #validEntries > 0 ) then
            local columnCount = GetStoreColumnCount()
            local entryCount = #validEntries

            local grid = scroller:Add("DIconLayout")
            grid:Dock(TOP)
            grid:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
            grid:SetSpaceX(STORE_GRID_SPACING_X)
            grid:SetSpaceY(STORE_GRID_SPACING_Y)
            grid:SetTall(CalculateStoreGridHeight(entryCount, columnCount))
            grid.Paint = nil

            grid.PerformLayout = function(this, w, h)
                local cols = math.max(columnCount, 1)
                local totalSpacing = math.max(cols - 1, 0) * STORE_GRID_SPACING_X
                local itemW = math.max(math.floor((w - totalSpacing) / cols), 1)
                this:SetTall(CalculateStoreGridHeight(entryCount, cols))

                local col = 0
                local row = 0
                for _, child in ipairs(this:GetChildren()) do
                    if ( !IsValid(child) ) then continue end
                    child:SetPos(col * (itemW + STORE_GRID_SPACING_X), row * (STORE_GRID_ITEM_HEIGHT + STORE_GRID_SPACING_Y))
                    child:SetSize(itemW, STORE_GRID_ITEM_HEIGHT)
                    col = col + 1
                    if ( col >= cols ) then
                        col = 0
                        row = row + 1
                    end
                end
            end

            for _, e in ipairs(validEntries) do
                local btn = grid:Add(e.panelName)
                btn:SetSize(64, STORE_GRID_ITEM_HEIGHT)
                btn:SetType(type)
                btn:SetKey(e.key)
            end
        end

        -- Add unsupported-type labels directly below the grid
        for _, u in ipairs(unsupportedEntries) do
            local label = scroller:Add("ax.text")
            label:Dock(TOP)
            label:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
            label:SetFont("ax.large.italic")
            label:SetText(string.format("Unsupported type '%s' for key: %s", ax.type:Format(u.entry.type), tostring(u.key)), true)
            label:SetContentAlignment(5)
            label:SetTextColor(Color(200, 200, 200))
        end

        -- Add spacing between subcategories (except for the last one)
        if ( showSubCategoryHeaders and subCat != sortedSubCategories[#sortedSubCategories] ) then
            local spacer = scroller:Add("EditablePanel")
            spacer:Dock(TOP)
            spacer:SetTall(ax.util:ScreenScale(8))
            spacer.Paint = nil
        end
    end
end

function PANEL:PerformLayout(width, height)
    -- Reflow internal pages when the store resizes (e.g. sidebar appearing)
    local pages = self:GetPages()
    if ( !pages ) then return end

    for i = 1, #pages do
        if ( IsValid(pages[i]) ) then
            pages[i]:ReflowFromOffsets()
        end
    end
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.store", PANEL, "ax.transition.pages")

-- Base panel for store elements
PANEL = {}

function PANEL:GetStore()
    return GetStoreByType(self.type)
end

function PANEL:Init()
    self.type = "unknown"
    self.key = "unknown"
    self.bInitializing = true
    self.bTooltipVisible = false
    self.tooltipTargets = {}

    self:SetContentAlignment(4)
    self:SetText("unknown")
    self:SetTextInset(ax.util:ScreenScale(4), 0)
    self:SetFont("ax.small")
    self:SetFontDefault("ax.small")
    self:SetFontHovered("ax.small")
    self:SetAxTooltip(function(panel)
        return panel:GetTooltipPayload()
    end)
end

function PANEL:DoRightClick()
    local store = self:GetStore()
    if ( !store ) then return end

    local default = store:GetDefault(self.key)
    store:Set(self.key, default)

    if ( self.UpdateDisplay ) then
        self:UpdateDisplay()
    end
end

function PANEL:HandleError(message)
    self:SetText(ax.localization:GetPhrase("unknown"), true)
    self.type = "unknown"
    ax.util:PrintError(string.format("ax.store.%s: %s for key '%s'", self.elementType or "base", message, tostring(self.key)))
end

function PANEL:SetType(type)
    if ( !type or type == "" ) then
        self:HandleError("Invalid type")
        return
    end

    local store = GetStoreByType(type)
    if ( !store ) then
        self:HandleError("Unknown type '" .. tostring(type) .. "'")
        return
    end

    self.type = type
    self:SetText(ax.localization:GetPhrase("unknown"), true)

    if ( self.UpdateDisplay ) then
        self:UpdateDisplay()
    end
end

function PANEL:SetKey(key)
    if ( !key or key == "" ) then
        self.key = "unknown"
        self:HandleError("Invalid key")
        return
    end

    local store = self:GetStore()
    if ( !store ) then
        self:HandleError("Unknown type")
        return
    end

    if ( store:Get(key) == nil ) then
        self:HandleError("Key '" .. tostring(key) .. "' does not exist in " .. self.type .. " store")
        return
    end

    self.key = key
    self:SetText(self.type .. "." .. key)

    if ( self.UpdateDisplay ) then
        self:UpdateDisplay()
    end
end

function PANEL:PerformLayout(width, height)
    for _, child in ipairs(self:GetChildren()) do
        if ( IsValid(child) and child:GetDock() == RIGHT ) then
            child:SetWide(math.Round(width * 0.33))
        end
    end
end

function PANEL:PaintAdditional(width, height)
    local store = self:GetStore()
    if ( !store or !isfunction(store.GetDefault) or !isfunction(store.Get) ) then return end

    local default = store:GetDefault(self.key)
    local value = store:Get(self.key)

    if ( value == default ) then return end
    ax.util:DrawGradient(8, "left", 0, 0, width / 3, height, ColorAlpha(self:GetTextColor(), 100))
end

function PANEL:RegisterTooltipTarget(panel)
    if ( !IsValid(panel) ) then return end

    self.tooltipTargets[#self.tooltipTargets + 1] = panel
end

function PANEL:IsTooltipHot()
    if ( self:IsHovered() ) then
        return true
    end

    for i = 1, #self.tooltipTargets do
        local panel = self.tooltipTargets[i]
        if ( IsValid(panel) and panel:IsHovered() ) then
            return true
        end
    end

    return false
end

function PANEL:GetTooltipPayload()
    local store = self:GetStore()
    if ( !store or !store.registry ) then
        return false
    end

    local entry = store.registry[self.key]
    if ( !entry ) then
        return false
    end

    local defaultValue = FormatStoreValue(store, self.key, store:GetDefault(self.key))

    return {
        title = ResolveStoreTitle(self.type, self.key),
        description = ResolveStoreDescription(self.type, self.key, entry.data or {}),
        badge = ResolveStoreTypeLabel(entry.type, entry.data or {}),
        meta = string.format("%s %s", GetLocalizedPhraseOrNil("store.default") or "Default", defaultValue),
        footer = self.type .. "." .. self.key,
        accentColor = GetStoreAccentColor(self.type)
    }
end

function PANEL:OnThink()
    local tooltipData = self.GetAxTooltip and self:GetAxTooltip() or nil
    if ( tooltipData == nil ) then return end

    local active = self:IsTooltipHot()
    if ( active and !self.bTooltipVisible ) then
        self.bTooltipVisible = true
        self:ShowAxTooltip()
    elseif ( !active and self.bTooltipVisible ) then
        self.bTooltipVisible = false
        self:HideAxTooltip()
    end
end

function PANEL:OnRemove()
    self.bTooltipVisible = false
    self:HideAxTooltip(true)
end

function PANEL:UpdateDisplay()
    -- Override in child panels
end

function PANEL:Paint(width, height)
    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()
    local radius = height * 0.45

    local color = ax.theme:ScaleAlpha(glass.button, metrics.opacity)
    if ( self.inertia > 0.8 ) then
        color = ax.theme:ScaleAlpha(glass.buttonActive, metrics.opacity)
    elseif ( self.inertia > 0.25 ) then
        color = ax.theme:ScaleAlpha(glass.buttonHover, metrics.opacity)
    end

    if ( !self:IsEnabled() ) then
        color = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a)
    end

    ax.render().Rect(0, 0, width, height)
        :Rad(radius)
        :Color(color)
        :Flags(ax.render.SHAPE_IOS)
        :Draw()

    ax.render.DrawOutlined(radius, 0, 0, width, height,
        ax.theme:ScaleAlpha(glass.buttonBorder, metrics.borderOpacity), 1, ax.render.SHAPE_IOS)

    if ( self.PaintAdditional ) then
        self:PaintAdditional(width, height)
    end
end

vgui.Register("ax.store.base", PANEL, "ax.button")

-- Boolean store element
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

function PANEL:Init()
    self.elementType = "bool"
    self.toggleBlend = 0
end

function PANEL:OnThink()
    BaseClass.OnThink(self)

    local store = self:GetStore()
    local target = (store and store:Get(self.key) == true) and 1 or 0

    if ( !ax.option:Get("performance.animations", true) ) then
        self.toggleBlend = target
        return
    end

    self.toggleBlend = ax.ease:Lerp("Linear", FrameTime() * 10, self.toggleBlend or 0, target)
end

function PANEL:Paint(width, height)
    BaseClass.Paint(self, width, height)

    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()
    local blend = self.toggleBlend or 0

    local pad = ax.util:ScreenScale(8)
    local toggleH = math.Round(height * 0.52)
    local toggleW = math.Round(toggleH * 1.85)
    local toggleX = width - toggleW - pad
    local toggleY = math.Round((height - toggleH) * 0.5)
    local r = toggleH * 0.5

    local offColor = ax.theme:ScaleAlpha(glass.button, metrics.opacity)
    local onColor = ax.theme:ScaleAlpha(glass.progress, metrics.opacity)
    local trackColor = Color(
        Lerp(blend, offColor.r, onColor.r),
        Lerp(blend, offColor.g, onColor.g),
        Lerp(blend, offColor.b, onColor.b),
        Lerp(blend, offColor.a, onColor.a)
    )

    ax.render.Draw(r, toggleX, toggleY, toggleW, toggleH, trackColor, ax.render.SHAPE_IOS)
    ax.render.DrawOutlined(r, toggleX, toggleY, toggleW, toggleH,
        ax.theme:ScaleAlpha(glass.buttonBorder, metrics.borderOpacity), 1, ax.render.SHAPE_IOS)

    local knobPad = math.max(math.Round(toggleH * 0.1), 2)
    local knobSize = toggleH - knobPad * 2
    local knobOffX = toggleX + knobPad
    local knobOnX = toggleX + toggleW - knobSize - knobPad

    ax.render.Draw(knobSize * 0.5, Lerp(blend, knobOffX, knobOnX), toggleY + knobPad,
        knobSize, knobSize, color_white, ax.render.SHAPE_IOS)
end

function PANEL:UpdateDisplay() end

function PANEL:DoClick()
    self:Toggle()
end

function PANEL:Toggle()
    local store = self:GetStore()
    if ( !store ) then
        self:HandleError("Unknown type")
        return
    end

    local current = store:Get(self.key)
    if ( current == nil ) then
        self:HandleError("Key does not exist in store")
        return
    end

    local newValue = !current
    store:Set(self.key, newValue)

    if ( !ax.option:Get("performance.animations", true) ) then
        self.toggleBlend = newValue == true and 1 or 0
    end
end

function PANEL:SetKey(key)
    BaseClass.SetKey(self, key)

    local store = self:GetStore()
    if ( store ) then
        self.toggleBlend = store:Get(key) == true and 1 or 0
    end

    self.bInitializing = false
end

vgui.Register("ax.store.bool", PANEL, "ax.store.base")

-- Custom slider widget (replaces DNumSlider)
local SLIDER = {}

function SLIDER:Init()
    self.minVal = 0
    self.maxVal = 100
    self.decimals = 0
    self.value = 0
    self.displayValue = 0
    self.displayFraction = 0
    self.dragging = false
    self.ValueChangedDeferred = nil

    -- Compat stubs so the number panel's Think can call Label/TextArea methods
    -- without needing to know whether we are a DNumSlider or this custom panel.
    self.Label = {SetTextColor = function() end}
    self.TextArea = {
        _textColor = nil,
        _font = nil,
        SetFont = function(this, font) this._font = font end,
        SetTextColor = function(this, col) this._textColor = col end,
        IsEditing = function() return false end,
    }

    self:SetMouseInputEnabled(true)
    self:SetCursor("hand")
end

function SLIDER:SetMinMax(min, max)
    self.minVal = tonumber(min) or 0
    self.maxVal = tonumber(max) or 100
end

function SLIDER:SetDecimals(d)
    self.decimals = tonumber(d) or 0
end

function SLIDER:RoundToDecimals(val)
    if ( self.decimals > 0 ) then return math.Round(val, self.decimals) end
    return math.Round(val)
end

function SLIDER:SetValue(val)
    self.value = self:RoundToDecimals(math.Clamp(tonumber(val) or 0, self.minVal, self.maxVal))

    if ( !self.dragging ) then
        self.displayValue = self.value
        self.displayFraction = self:GetFraction()
    end
end

function SLIDER:GetValue()
    return self.value
end

function SLIDER:IsEditing()
    return false
end

function SLIDER:GetFraction()
    local range = self.maxVal - self.minVal
    if ( range == 0 ) then return 0 end
    return math.Clamp((self.value - self.minVal) / range, 0, 1)
end

function SLIDER:Think()
    local targetFraction = self:GetFraction()
    local targetValue = self.value
    local speed = self.dragging and 26 or 14
    local lerpFactor = math.Clamp(FrameTime() * speed, 0, 1)

    self.displayFraction = ax.ease:Lerp("Linear", lerpFactor, self.displayFraction or 0, targetFraction)
    self.displayValue = ax.ease:Lerp("Linear", lerpFactor, self.displayValue or targetValue, targetValue)
end

function SLIDER:GetTrackBounds()
    local h = self:GetTall()
    local knobR = math.max(math.Round(h * 0.3), 4)

    -- Measure the widest possible value string so the text column never clips
    local decimals = self.decimals or 0
    local worstCase = decimals > 0
        and string.format("%." .. decimals .. "f", self.maxVal)
        or tostring(math.Round(self.maxVal))
    surface.SetFont("ax.small")
    local measuredW = select(1, surface.GetTextSize(worstCase))
    local valueTextW = measuredW + ax.util:ScreenScale(3)

    local gapAfterTrack = ax.util:ScreenScale(3)
    local trackX = knobR
    local trackW = math.max(self:GetWide() - valueTextW - gapAfterTrack - knobR * 2, 4)
    return trackX, trackW, knobR, valueTextW, gapAfterTrack
end

function SLIDER:ValueFromCursor()
    local mx = self:CursorPos()
    local trackX, trackW, knobR = self:GetTrackBounds()
    local frac = math.Clamp((mx - trackX) / trackW, 0, 1)
    return self:RoundToDecimals(self.minVal + frac * (self.maxVal - self.minVal))
end

function SLIDER:OnMousePressed(mouseCode)
    if ( mouseCode != MOUSE_LEFT ) then return end
    self.dragging = true
    self:MouseCapture(true)
    local newVal = self:ValueFromCursor()
    if ( newVal != self.value ) then
        self:SetValue(newVal)
        if ( self.OnValueChanged ) then self:OnValueChanged(newVal) end
    end
end

function SLIDER:OnMouseReleased(mouseCode)
    if ( mouseCode != MOUSE_LEFT ) then return end
    self.dragging = false
    self:MouseCapture(false)
end

function SLIDER:OnCursorMoved()
    if ( !self.dragging ) then return end
    local newVal = self:ValueFromCursor()
    if ( newVal != self.value ) then
        self:SetValue(newVal)
        if ( self.OnValueChanged ) then self:OnValueChanged(newVal) end
    end
end

function SLIDER:Paint(w, h)
    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()

    local trackX, trackW, knobR, valueTextW, gapAfterTrack = self:GetTrackBounds()
    local trackH = math.max(math.Round(h * 0.22), 3)
    local cy = math.Round(h * 0.5)
    local trackY = cy - math.Round(trackH * 0.5)
    local trackR = trackH * 0.5
    local frac = self.displayFraction or self:GetFraction()
    local knobX = math.Round(trackX + frac * trackW)
    local knobSize = knobR * 2
    local glowR = math.Round(knobR * 1.65)
    local progressColor = ax.theme:ScaleAlpha(glass.progress, metrics.opacity)

    -- Background track — clearly visible groove
    local bgTrack = glass.panel or glass.button
    ax.render.Draw(trackR, trackX, trackY, trackW, trackH,
        Color(bgTrack.r, bgTrack.g, bgTrack.b, 180), ax.render.SHAPE_IOS)

    -- Track border so the full extent is obvious
    ax.render.DrawOutlined(trackR, trackX, trackY, trackW, trackH,
        ax.theme:ScaleAlpha(glass.buttonBorder, metrics.borderOpacity), 1, ax.render.SHAPE_IOS)

    -- Filled / progress portion
    if ( frac > 0 ) then
        local fillW = math.max(math.Round(frac * trackW), trackH)
        ax.render.Draw(trackR, trackX, trackY, fillW, trackH,
            progressColor, ax.render.SHAPE_IOS)
    end

    -- Glow halo around knob
    ax.render.Draw(glowR, knobX - glowR, cy - glowR, glowR * 2, glowR * 2,
        Color(progressColor.r, progressColor.g, progressColor.b, 50), ax.render.SHAPE_IOS)

    -- Knob
    ax.render.Draw(knobR, knobX - knobR, cy - knobR, knobSize, knobSize,
        color_white, ax.render.SHAPE_IOS)

    -- Knob border
    ax.render.DrawOutlined(knobR, knobX - knobR, cy - knobR, knobSize, knobSize,
        Color(progressColor.r, progressColor.g, progressColor.b, 160), 1, ax.render.SHAPE_IOS)

    -- Value label (right of track)
    local decimals = self.decimals or 0
    local displayValue = self.displayValue or self.value
    local valStr = decimals > 0
        and string.format("%." .. decimals .. "f", displayValue)
        or tostring(math.Round(displayValue))

    local textColor = (self.TextArea and self.TextArea._textColor) or glass.textMuted or glass.text
    local font = (self.TextArea and self.TextArea._font) or "ax.small"
    local textX = math.Round(trackX + trackW + knobR + gapAfterTrack + valueTextW * 0.5)
    draw.SimpleText(valStr, font, textX, cy, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

vgui.Register("ax.store.slider", SLIDER, "EditablePanel")

-- Number store element
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

function PANEL:Init()
    self.elementType = "number"

    self.slider = self:Add("ax.store.slider")
    self.slider:Dock(RIGHT)
    self.slider:DockMargin(0, 0, ax.util:ScreenScale(8), 0)
    self.slider:SetWide(ax.util:ScreenScale(128))
    self.slider:SetMinMax(0, 100)
    self.slider:SetDecimals(0)
    self.slider:SetValue(0)
    self.slider.OnValueChanged = function(this, value)
        if ( self.bInitializing ) then return end
        self.pendingValue = value
        self.pendingTime = CurTime()

        if ( self.deferredUpdate or this:IsEditing() ) then
            self.slider.ValueChangedDeferred = value
            return
        end

        if ( self.debounceTime and self.debounceTime > 0 ) then
            return
        end

        local store = self:GetStore()
        if ( store ) then
            store:Set(self.key, value)
            self.pendingValue = nil
            self.pendingTime = nil
        end
    end
    self.Think = function()
        if ( !IsValid(self.slider) ) then return end

        self.slider.Label:SetTextColor(self:GetTextColor())
        self.slider.TextArea:SetFont(self:GetFont())
        self.slider.TextArea:SetTextColor(self:GetTextColor())

        local store = self:GetStore()
        if ( self.deferredUpdate and !self.slider:IsEditing() and self.slider.ValueChangedDeferred ) then
            if ( store ) then
                store:Set(self.key, self.slider.ValueChangedDeferred)
                self.slider.ValueChangedDeferred = nil
                self.pendingValue = nil
                self.pendingTime = nil
            end

            return
        end

        if ( self.pendingValue != nil and self.pendingTime and !self.slider:IsEditing() and self.debounceTime and self.debounceTime > 0 and (CurTime() - self.pendingTime) >= self.debounceTime ) then
            if ( store ) then
                store:Set(self.key, self.pendingValue)
            end

            self.pendingValue = nil
            self.pendingTime = nil
        end
    end

    self:RegisterTooltipTarget(self.slider)
end

function PANEL:SetKey(key)
    BaseClass.SetKey(self, key)

    local store = self:GetStore()
    if ( !store or store:Get(key) == nil ) then return end

    local data = store:GetData(key)
    self.slider:SetMinMax(data.min or 0, data.max or 100)
    self.slider:SetDecimals(data.decimals or 0)
    self.slider:SetValue(store:Get(key))

    self.deferredUpdate = data.deferredUpdate
    if ( self.deferredUpdate == nil ) then
        self.deferredUpdate = false
    end

    self.debounceTime = data.debounceTime
    if ( self.debounceTime == nil ) then
        self.debounceTime = 0.2
    end

    self.bInitializing = false
end

function PANEL:UpdateDisplay()
    local store = self:GetStore()
    if ( !store ) then
        self.slider:SetValue(0)
        return
    end

    local value = store:Get(self.key)
    self.slider:SetValue(value)
end

function PANEL:OnRemove()
    BaseClass.OnRemove(self)

    if ( self.bInitializing ) then return end

    local store = self:GetStore()
    if ( !store ) then return end

    local deferredValue = self.slider and self.slider.ValueChangedDeferred or nil
    if ( deferredValue != nil ) then
        store:Set(self.key, deferredValue)
        self.slider.ValueChangedDeferred = nil
    elseif ( self.pendingValue != nil ) then
        store:Set(self.key, self.pendingValue)
    end

    self.pendingValue = nil
    self.pendingTime = nil
end

vgui.Register("ax.store.number", PANEL, "ax.store.base")

-- Keybind store element
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

function PANEL:Init()
    self.elementType = "keybind"
    self.bSuppressOnChange = false

    self.binder = self:Add("DBinder")
    self.binder:Dock(RIGHT)
    self.binder:DockMargin(0, ax.util:ScreenScale(4), ax.util:ScreenScale(8), ax.util:ScreenScale(4))
    self.binder:SetWide(ax.util:ScreenScale(128))
    self.binder:SetSelectedNumber(KEY_NONE or 0)
    self.binder.OnChange = function(this, value)
        if ( self.bInitializing or self.bSuppressOnChange ) then return end

        local store = self:GetStore()
        if ( store ) then
            store:Set(self.key, value)
        end
    end

    self:RegisterTooltipTarget(self.binder)
end

function PANEL:SetBinderValue(value)
    value = tonumber(value) or (KEY_NONE or 0)

    if ( self.binder:GetSelectedNumber() == value ) then return end

    self.bSuppressOnChange = true
    self.binder:SetSelectedNumber(value)
    self.bSuppressOnChange = false
end

function PANEL:SetKey(key)
    BaseClass.SetKey(self, key)

    local store = self:GetStore()
    if ( !store or store:Get(key) == nil ) then return end

    local default = store:GetDefault(key)
    if ( default != nil ) then
        self.binder:SetDefaultNumber(default)
    end

    self:SetBinderValue(store:Get(key))
    self.bInitializing = false
end

function PANEL:UpdateDisplay()
    local store = self:GetStore()
    if ( !store ) then
        self:SetBinderValue(KEY_NONE or 0)
        return
    end

    self:SetBinderValue(store:Get(self.key))
end

vgui.Register("ax.store.keybind", PANEL, "ax.store.base")

-- String store element
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

function PANEL:Init()
    self.elementType = "string"

    self.entry = self:Add("ax.text.entry")
    self.entry:Dock(RIGHT)
    self.entry:DockMargin(0, ax.util:ScreenScale(4), ax.util:ScreenScale(8), ax.util:ScreenScale(4))
    self.entry:SetWide(ax.util:ScreenScale(128))
    self.entry:SetText("unknown")
    self.entry:SetUpdateOnType(false)
    self.entry.OnValueChange = function(this, value)
        if ( self.bInitializing ) then return end

        local store = self:GetStore()
        if ( store ) then
            store:Set(self.key, value)
        end
    end
    self.entry.OnLoseFocus = function(this)
        self:CommitCurrentText()
    end

    self:RegisterTooltipTarget(self.entry)
end

function PANEL:CommitCurrentText()
    if ( self.bInitializing or !IsValid(self.entry) ) then return end

    local store = self:GetStore()
    if ( store ) then
        store:Set(self.key, self.entry:GetText())
    end
end

function PANEL:UpdateDisplay()
    local store = self:GetStore()
    if ( !store ) then
        self.entry:SetText("unknown")
        return
    end

    self.entry:SetText(store:Get(self.key) or "unknown")
end

function PANEL:SetKey(key)
    BaseClass.SetKey(self, key)
    self.bInitializing = false
end

function PANEL:OnRemove()
    BaseClass.OnRemove(self)
    self:CommitCurrentText()
end

vgui.Register("ax.store.string", PANEL, "ax.store.base")

-- Colour store element
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

local STORE_FALLBACK_COLOR = Color(100, 100, 100)
function PANEL:Init()
    self.elementType = "color"

    self.colorPanel = self:Add("ax.button")
    self.colorPanel:SetText("")
    self.colorPanel:Dock(RIGHT)
    self.colorPanel:DockMargin(0, ax.util:ScreenScale(4), ax.util:ScreenScale(8), ax.util:ScreenScale(4))
    self.colorPanel:SetWide(ax.util:ScreenScale(64))
    self.colorPanel.Paint = function(this, width, height)
        local glass = ax.theme:GetGlass()
        local metrics = ax.theme:GetMetrics()
        local r = height * 0.45
        local store = self:GetStore()
        local color = (store and store:Get(self.key)) or STORE_FALLBACK_COLOR

        ax.render.Draw(r, 0, 0, width, height, color, ax.render.SHAPE_IOS)
        ax.render.DrawOutlined(r, 0, 0, width, height,
            ax.theme:ScaleAlpha(glass.buttonBorder, metrics.borderOpacity), 1, ax.render.SHAPE_IOS)

        -- Inner shadow for very light colors so the pill edge is readable
        if ( IsColor(color) and (color.r + color.g + color.b) > 600 ) then
            ax.render.DrawOutlined(r, 1, 1, width - 2, height - 2, Color(0, 0, 0, 50), 1, ax.render.SHAPE_IOS)
        end
    end

    self.colorPanel.DoClick = function(this)
        local store = self:GetStore()
        if ( !store ) then
            self:HandleError("Unknown type")
            return
        end

        if ( IsValid(self.colorPicker) ) then
            self.colorPicker:Remove()
            self.colorPicker = nil
        end

        local currentColor = store:Get(self.key) or color_white

        self.colorPicker = vgui.Create("DColorMixer")
        self.colorPicker:SetPos(math.min(ScrW() - 256, gui.MouseX()), math.min(ScrH() - 256, gui.MouseY()))
        self.colorPicker:SetColor(currentColor)
        self.colorPicker:MakePopup()
        self.colorPicker:MoveToFront()
        self.colorPicker.ValueChanged = function(this, newColor)
            store:Set(self.key, newColor)
        end

        local function removePicker()
            if ( IsValid(self.colorPicker) ) then
                self.colorPicker:Remove()
                self.colorPicker = nil
            end
        end

        self.removeColorPicker = removePicker
        self.colorPanel.OnRemoved = removePicker
    end

    self:RegisterTooltipTarget(self.colorPanel)
end

function PANEL:SetKey(key)
    BaseClass.SetKey(self, key)
    self.bInitializing = false
end

function PANEL:OnRemove()
    if ( isfunction(self.removeColorPicker) ) then
        self.removeColorPicker()
    end

    BaseClass.OnRemove(self)
end

vgui.Register("ax.store.color", PANEL, "ax.store.base")

-- Array store element (combobox dropdown — use ax.store.segmented for pill UI)
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

function PANEL:Init()
    self.elementType = "array"

    self.combo = self:Add("ax.combobox")
    self.combo:Dock(RIGHT)
    self.combo:DockMargin(0, ax.util:ScreenScale(3), ax.util:ScreenScale(8), ax.util:ScreenScale(3))
    self.combo:SetWide(ax.util:ScreenScale(128))
    self.combo:SetSortItems(true)
    self.combo.OnSelect = function(this, index, value, data)
        if ( self.bInitializing ) then return end
        local store = self:GetStore()
        if ( store ) then
            store:Set(self.key, data)
        end
    end

    self:RegisterTooltipTarget(self.combo)
end

function PANEL:SetKey(key)
    BaseClass.SetKey(self, key)

    local store = self:GetStore()
    if ( !store or store:Get(key) == nil ) then return end

    local data = store:GetData(key)
    self.combo:Clear()

    if ( data.choices and istable(data.choices) ) then
        for choiceKey, choiceLabel in pairs(data.choices) do
            self.combo:AddChoice(choiceLabel, choiceKey)
        end
    end

    local entry = store.registry[key]
    self.combo:SetValue(entry.data.choices[store:Get(key)] or "unknown")
    self.bInitializing = false
end

function PANEL:UpdateDisplay()
    local store = self:GetStore()
    if ( !store ) then
        self.combo:SetValue("unknown")
        return
    end

    local value = store:Get(self.key)
    local entry = store.registry[self.key]
    self.combo:SetValue((entry and entry.data.choices[value]) or "unknown")
end

vgui.Register("ax.store.array", PANEL, "ax.store.base")

-- Segmented store element (pill segmented button — declare with data.segmented = true on an array option/config)
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

function PANEL:Init()
    self.elementType = "segmented"
    self.selectedKey = nil
    self.segmentChoices = {}

    self.segmentPanel = self:Add("EditablePanel")
    self.segmentPanel:Dock(RIGHT)
    self.segmentPanel:DockMargin(0, ax.util:ScreenScale(3), ax.util:ScreenScale(8), ax.util:ScreenScale(3))
    self.segmentPanel:SetWide(ax.util:ScreenScale(128))
    self.segmentPanel.PLACEHOLDER = true -- real width set in SetKey once choices are known
    self.segmentPanel.Paint = function(this, w, h)
        local glass = ax.theme:GetGlass()
        local metrics = ax.theme:GetMetrics()
        local r = h * 0.45
        ax.render().Rect(0, 0, w, h)
            :Rad(r)
            :Color(ax.theme:ScaleAlpha(glass.panel, metrics.opacity))
            :Flags(ax.render.SHAPE_IOS)
            :Draw()
        ax.render.DrawOutlined(r, 0, 0, w, h,
            ax.theme:ScaleAlpha(glass.buttonBorder, metrics.borderOpacity), 1, ax.render.SHAPE_IOS)
    end

    self:RegisterTooltipTarget(self.segmentPanel)
end

function PANEL:RebuildSegments()
    self.segmentPanel:Clear()

    local choices = self.segmentChoices
    local count = #choices
    if ( count == 0 ) then return end

    local segPad = 2

    for _, choice in ipairs(choices) do
        local seg = self.segmentPanel:Add("ax.button")
        seg:SetText(ResolveStoreString(choice.label) or tostring(choice.label), true)
        seg:SetFont("ax.small")
        seg:SetFontDefault("ax.small")
        seg:SetFontHovered("ax.small.bold")
        seg:SetContentAlignment(5)
        seg.choiceKey = choice.key

        seg.Paint = function(this, w, h)
            if ( self.selectedKey == this.choiceKey ) then
                local glass = ax.theme:GetGlass()
                local metrics = ax.theme:GetMetrics()
                ax.render.Draw(h * 0.4, 0, 0, w, h,
                    ax.theme:ScaleAlpha(glass.progress, metrics.opacity), ax.render.SHAPE_IOS)
            end
        end

        seg.DoClick = function()
            if ( self.bInitializing ) then return end
            self.selectedKey = choice.key
            local store = self:GetStore()
            if ( store ) then
                store:Set(self.key, choice.key)
            end
        end
    end

    function self.segmentPanel:PerformLayout(w, h)
        local children = self:GetChildren()
        local n = #children
        if ( n == 0 ) then return end
        local segW = math.floor((w - segPad * (n + 1)) / n)
        for i, child in ipairs(children) do
            if ( IsValid(child) ) then
                child:SetPos(segPad + (i - 1) * (segW + segPad), segPad)
                child:SetSize(segW, h - segPad * 2)
            end
        end
    end
end

function PANEL:SetKey(key)
    BaseClass.SetKey(self, key)

    local store = self:GetStore()
    if ( !store or store:Get(key) == nil ) then return end

    local data = store:GetData(key)
    self.selectedKey = store:Get(key)
    self.segmentChoices = {}

    local choices = data.choices
    if ( !istable(choices) and isfunction(data.populate) ) then
        local ok, populated = ax.util:SafeCall(data.populate)
        if ( ok and istable(populated) ) then
            choices = populated
        end
    end

    if ( istable(choices) ) then
        for choiceKey, choiceLabel in SortedPairs(choices) do
            self.segmentChoices[#self.segmentChoices + 1] = {key = choiceKey, label = choiceLabel}
        end
    end

    local count = #self.segmentChoices
    if ( count > 0 ) then
        self.segmentPanel:SetWide(ax.util:ScreenScale(math.Clamp(count * 52, 64, 240)))
    end

    self:RebuildSegments()
    self.bInitializing = false
end

function PANEL:UpdateDisplay()
    local store = self:GetStore()
    if ( !store ) then return end
    self.selectedKey = store:Get(self.key)
end

vgui.Register("ax.store.segmented", PANEL, "ax.store.base")
