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
        local button = self.categories:Add("ax.button.flat")
        button:Dock(TOP)
        button:SetText(ax.localization:GetPhrase("category." .. v))

        -- ["general"] = "General",
        -- ["category.general"] = "General",
        -- ["subcategory.general"] = "General",

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
        local subCat = entry.data.subCategory or ax.localization:GetPhrase("subcategory.general")
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

    self.reset = self:Add("ax.button.flat.icon")
    self.reset:SetIcon("parallax/icons/eraser.png")
    self.reset:SetIconAlign("center")
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
    self:SetText( "just type set ahadhahdawdhuahduahd" )

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
    self:SetText(ax.localization:GetPhrase(self.type .. "." .. key))

    if ( self.UpdateDisplay ) then
        self:UpdateDisplay()
    end
end

function PANEL:PerformLayout(width, height)
    self.reset:SetSize(height / 1.5, height / 1.5)
    local textWidth = ax.util:GetTextWidth(self:GetFont(), self:GetText())
    self.reset:SetPos(textWidth + ax.util:ScreenScale(16), (height - self.reset:GetTall()) / 2)

    local store = self:GetStore()
    if ( store and isfunction(store.GetDefault) and isfunction(store.Get) ) then
        local default = store:GetDefault(self.key)
        local value = store:Get(self.key)

        self.reset:SetVisible(value != default)
    end
end

function PANEL:PaintAdditional(width, height)
    local store = self:GetStore()
    if ( !store or !isfunction(store.GetDefault) or !isfunction(store.Get) ) then return end

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
    value = value == true and  ax.localization:GetPhrase("store.enabled") or ax.localization:GetPhrase("store.disabled")
    self.value:SetText(string.format("<%s>", value))
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
    self.slider.Think = function(this)
        this.Label:SetTextColor(self:GetTextColor())
        this.TextArea:SetFont(self:GetFont())
        this.TextArea:SetTextColor(self:GetTextColor())

        local store = self:GetStore()
        if ( self.deferredUpdate and !this:IsEditing() and this.ValueChangedDeferred ) then
            if ( store ) then
                store:Set(self.key, this.ValueChangedDeferred)
                this.ValueChangedDeferred = nil
                self.pendingValue = nil
                self.pendingTime = nil
            end

            return
        end

        if ( self.pendingValue != nil and self.pendingTime and !this:IsEditing() and self.debounceTime and self.debounceTime > 0 and (CurTime() - self.pendingTime) >= self.debounceTime ) then
            if ( store ) then
                store:Set(self.key, self.pendingValue)
            end

            self.pendingValue = nil
            self.pendingTime = nil
        end
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

vgui.Register("ax.store.number", PANEL, "ax.store.base")

-- String store element
PANEL = {}

DEFINE_BASECLASS("ax.store.base")

function PANEL:Init()
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
