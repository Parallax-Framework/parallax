--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

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

function PANEL:Init()
    self:Dock(FILL)
    self:InvalidateParent(true)

    self.categories = self:Add("ax.scroller.vertical")
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
        local button = self.categories:Add("ax.button.flat")
        button:Dock(TOP)
        button:SetText(ax.util:UniqueIDToName(ax.localization:GetPhrase(v)), true)

        self.categories:SetWide(math.max(self.categories:GetWide(), button:GetWide() + ax.util:ScreenScale(16)))

        local tab = self:CreatePage()

        local scroller = tab:Add("ax.scroller.vertical")
        scroller:Dock(FILL)

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
        end
    end

    -- Store reference for later use
    self.categoryButtons = categoryButtons

    -- Adjust all pages now that we know the final width of categories
    for k, v in ipairs(self:GetPages()) do
        v:SetXOffset(self.categories:GetWide() + ax.util:ScreenScale(32))
        v:SetWidthOffset(-self.categories:GetWide() - ax.util:ScreenScale(32))
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
        self:Populate(targetButton.tab, targetButton.tab:GetChildren()[1], type, targetCategory)
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
            subCategoryLabel:SetFont("ax.huge.italic.bold")
            subCategoryLabel:SetText(utf8.upper(ax.util:UniqueIDToName(ax.localization:GetPhrase(subCat))), true)
            subCategoryLabel:Dock(TOP)
        end

        -- Add entries for this subcategory
        for key, entry in SortedPairs(entries) do
            if ( entry.type == ax.type.bool ) then
                local btn = scroller:Add("ax.store.bool")
                btn:Dock(TOP)
                btn:SetType(type)
                btn:SetKey(key)
            elseif ( entry.type == ax.type.number ) then
                if ( entry.data.keybind ) then
                    -- TODO: Kill this drilla
                    continue
                end

                local btn = scroller:Add("ax.store.number")
                btn:Dock(TOP)
                btn:SetType(type)
                btn:SetKey(key)
            elseif ( entry.type == ax.type.string ) then
                local btn = scroller:Add("ax.store.string")
                btn:Dock(TOP)
                btn:SetType(type)
                btn:SetKey(key)
            else
                local label = scroller:Add("ax.text")
                label:Dock(TOP)
                label:SetFont("ax.large.italic")
                label:SetText(string.format("Unsupported type '%s' for key: %s", ax.type:Format(entry.type), tostring(key)), true)
                label:SetContentAlignment(5)
                label:SetTextColor(Color(200, 200, 200))
            end
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

    self:SetContentAlignment(4)
    self:SetText("unknown")
    self:SetTextInset(ax.util:ScreenScale(8), 0)

    self.reset = self:Add("ax.button.flat")
    self.reset:SetText("R")
    self.reset.DoClick = function()
        local store = self:GetStore()
        if ( !store ) then
            self:HandleError("Unknown type")
            return
        end

        local default = store:GetDefault(self.key)

        store:Set(self.key, default)

        if ( self.UpdateDisplay ) then
            self:UpdateDisplay()
        end
    end
end

function PANEL:HandleError(message)
    self:SetText("unknown")
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
    self:SetText(ax.util:UniqueIDToName(self.key))

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
    self:SetText(ax.util:UniqueIDToName(key))

    if ( self.UpdateDisplay ) then
        self:UpdateDisplay()
    end
end

function PANEL:PerformLayout(width, height)
    self.reset:SetSize(height / 1.5, height / 1.5)
    local textWidth = ax.util:GetTextWidth(self:GetFont(), self:GetText())
    self.reset:SetPos(textWidth + ax.util:ScreenScale(16), (height - self.reset:GetTall()) / 2)

    local store = self:GetStore()
    if ( store ) then
        local default = store:GetDefault(self.key)
        local value = store:Get(self.key)

        self.reset:SetVisible(value != default)
    end
end

function PANEL:PaintAdditional(width, height)
    local store = self:GetStore()
    if ( !store ) then return end

    local default = store:GetDefault(self.key)
    local value = store:Get(self.key)

    if ( value == default ) then return end
    ax.util:DrawGradient("left", 0, 0, width / 3, height, ColorAlpha(self:GetTextColor(), 100))
end

function PANEL:UpdateDisplay()
    -- Override in child panels
end

vgui.Register("ax.store.base", PANEL, "ax.button.flat")

-- Boolean store element
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

function PANEL:Init()
    BaseClass.Init(self)
    self.elementType = "bool"

    self.value = self:Add("ax.text")
    self.value:Dock(RIGHT)
    self.value:DockMargin(0, 0, ax.util:ScreenScale(8), 0)
    self.value:SetText("unknown")
    self.value:SetFont("ax.large")
    self.value:SetWide(ax.util:ScreenScale(192))
    self.value:SetContentAlignment(6)
    self.value.Think = function(this)
        this:SetTextColor(self:GetTextColor())
        this:SetFont(self:GetFont())
    end
end

function PANEL:UpdateDisplay()
    local store = self:GetStore()
    if ( !store ) then
        self.value:SetText("unknown")
        return
    end

    local value = store:Get(self.key)
    self.value:SetText(string.format("<%s>", value and "Enabled" or "Disabled"), true)
end

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

    store:Set(self.key, !current)
    self:UpdateDisplay()
end

function PANEL:SetKey(key)
    BaseClass.SetKey(self, key)
    self.bInitializing = false
end

vgui.Register("ax.store.bool", PANEL, "ax.store.base")

-- Number store element
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

function PANEL:Init()
    BaseClass.Init(self)
    self.elementType = "number"

    self.slider = self:Add("DNumSlider")
    self.slider:Dock(RIGHT)
    self.slider:DockMargin(0, 0, ax.util:ScreenScale(8), 0)
    self.slider:SetWide(ax.util:ScreenScale(192))
    self.slider:SetMinMax(0, 100)
    self.slider:SetDecimals(0)
    self.slider:SetValue(0)
    self.slider.OnValueChanged = function(this, value)
        if ( self.bInitializing ) then return end
        local store = self:GetStore()
        if ( store ) then
            store:Set(self.key, value)
        end
    end
    self.slider.Think = function(this)
        this.Label:SetTextColor(self:GetTextColor())
        this.TextArea:SetFont(self:GetFont())
        this.TextArea:SetTextColor(self:GetTextColor())
    end
end

function PANEL:SetKey(key)
    BaseClass.SetKey(self, key)

    local store = self:GetStore()
    if ( !store or store:Get(key) == nil ) then return end

    local data = store:GetData(key)
    self.slider:SetMinMax(data.min or 0, data.max or 100)
    self.slider:SetDecimals(data.decimals or 0)
    self.slider:SetValue(store:Get(key))

    self.bInitializing = false
end

vgui.Register("ax.store.number", PANEL, "ax.store.base")

-- String store element
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

function PANEL:Init()
    BaseClass.Init(self)
    self.elementType = "string"

    self.entry = self:Add("ax.text.entry")
    self.entry:Dock(RIGHT)
    self.entry:DockMargin(0, ax.util:ScreenScale(4), ax.util:ScreenScale(8), ax.util:ScreenScale(4))
    self.entry:SetWide(ax.util:ScreenScale(192))
    self.entry:SetText("unknown")
    self.entry.OnValueChanged = function(this, value)
        if ( self.bInitializing ) then return end
        local store = self:GetStore()
        if ( store ) then
            store:Set(self.key, value)
        end
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

vgui.Register("ax.store.string", PANEL, "ax.store.base")
