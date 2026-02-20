--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- TODO: Rewrite entire inventory interface, this is complete chaos.
-- TODO: Split into multiple files like "cl_inventory.lua" for main panel, "cl_inventory_item.lua" for item rows, "cl_inventory_info.lua" for info panel, etc.
-- TODO: Make this into a util function in case we want to use it for other things like weapon inspection or character preview in character menu, etc.
local function GetDesiredFov()
    local conVar = GetConVar("fov_desired")
    if ( conVar ) then
        return conVar:GetInt()
    end

    return 90
end

local PANEL = {}

local GLASS_PANEL_RADIUS = 10
local INVENTORY_PREVIEW_WIDTH = ax.util:ScreenScale(256)
local INVENTORY_INFO_HEIGHT = ax.util:ScreenScaleH(128)
local INVENTORY_CATEGORY_SPACING = ax.util:ScreenScaleH(4)
local INVENTORY_ACTIONS_WIDTH = ax.util:ScreenScale(128)
local INVENTORY_PREVIEW_TRANSITION_TIME = ax.option:Get("tabFadeTime", 0.25)
local INVENTORY_PREVIEW_TARGET_FOV = 45

local function DrawGlassPanel(x, y, w, h, radius, blur)
    ax.theme:DrawGlassPanel(x, y, w, h, {
        radius = radius,
        blur = blur,
        flags = ax.render.SHAPE_IOS
    })
end

function PANEL:Init()
    ax.gui.inventory = self

    self:Dock(FILL)
    self:InvalidateParent(true)

    local client = ax.client
    local character = client:GetCharacter()
    if ( !character ) then return end

    self.character = character

    local inventory = character:GetInventory()
    if ( !inventory ) then return end

    self.inventory = inventory

    self.listing = self:Add("EditablePanel")
    self.listing:Dock(FILL)
    self.listing:DockMargin(INVENTORY_PREVIEW_WIDTH, 0, 0, 0)
    self.listing.Paint = nil

    self.info = self:Add("EditablePanel")
    self.info:Dock(BOTTOM)
    self.info:DockMargin(INVENTORY_PREVIEW_WIDTH, 0, 0, 0)
    self.info:SetTall(0)
    self.info.Paint = function(this, width, height)
        DrawGlassPanel(0, 0, width, height, GLASS_PANEL_RADIUS, 1.0)
    end

    local maxWeight = inventory:GetMaxWeight()
    local weight = inventory:GetWeight()
    local safeMaxWeight = math.max(maxWeight, 0.001)

    self.infoExpandedHeight = INVENTORY_INFO_HEIGHT

    self.weightProgress = self.listing:Add("DProgress")
    self.weightProgress:SetFraction(weight / safeMaxWeight)
    self.weightProgress:SetTall(ax.util:ScreenScale(12))
    self.weightProgress:Dock(TOP)
    self.weightProgress:DockMargin(0, 0, 0, ax.util:ScreenScaleH(8))
    self.weightProgress.Paint = function(this, width, height)
        DrawGlassPanel(0, 0, width, height, GLASS_PANEL_RADIUS, 0.6)

        local fraction = this:GetFraction()
        local glass = ax.theme:GetGlass()
        ax.render.Draw(GLASS_PANEL_RADIUS, 0, 0, width * fraction, height, glass.progress, ax.render.SHAPE_IOS)
    end

    local totalWeight = maxWeight * self.weightProgress:GetFraction()

    self.weightCounter = self.weightProgress:Add("ax.text")
    self.weightCounter:SetFont("ax.regular")

    local weightText = ax.localization:GetPhrase("invWeight")

    self.weightCounter:SetText(totalWeight .. weightText .. " / " .. maxWeight .. weightText, true)
    self.weightCounter:SetContentAlignment(5)
    self.weightCounter:Dock(FILL)

    self.searchQuery = ""
    self.inventoryPage = 1
    self.collapsedCategories = {}

    self.searchEntry = self.listing:Add("ax.text.entry")
    self.searchEntry:Dock(TOP)
    self.searchEntry:SetZPos(-10)
    self.searchEntry:DockMargin(0, 0, 0, ax.util:ScreenScaleH(6))
    self.searchEntry:SetPlaceholderText("Search inventory...")
    self.searchEntry.OnValueChange = function(entry, value)
        if ( !ax.option:Get("inventory.search.live", true) ) then return end

        self.searchQuery = string.Trim(entry:GetValue() or value or "")
        self.inventoryPage = 1
        self:PopulateItems()
    end
    self.searchEntry.OnEnter = function(entry)
        self.searchQuery = string.Trim(entry:GetValue() or "")
        self.inventoryPage = 1
        self:PopulateItems()
    end

    self.pagination = self.listing:Add("EditablePanel")
    self.pagination:Dock(TOP)
    self.pagination:SetZPos(-9)
    self.pagination:SetTall(ax.util:ScreenScaleH(20))
    self.pagination:DockMargin(0, 0, 0, ax.util:ScreenScaleH(6))
    self.pagination.Paint = nil

    self.pagePrev = self.pagination:Add("ax.button")
    self.pagePrev:Dock(LEFT)
    self.pagePrev:SetWide(ax.util:ScreenScale(24))
    self.pagePrev:SetText("<", true)
    self.pagePrev.DoClick = function()
        self.inventoryPage = math.max((self.inventoryPage or 1) - 1, 1)
        self:PopulateItems()
    end

    self.pageNext = self.pagination:Add("ax.button")
    self.pageNext:Dock(RIGHT)
    self.pageNext:SetWide(ax.util:ScreenScale(24))
    self.pageNext:SetText(">", true)
    self.pageNext.DoClick = function()
        self.inventoryPage = (self.inventoryPage or 1) + 1
        self:PopulateItems()
    end

    self.pageCounter = self.pagination:Add("ax.text")
    self.pageCounter:Dock(FILL)
    self.pageCounter:SetFont("ax.small")
    self.pageCounter:SetContentAlignment(5)

    self.container = self.listing:Add("ax.scroller.vertical")
    self.container:Dock(FILL)
    self.container:SetZPos(0)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    self.previewActive = nil
    self.previewTransitioning = false
    self.previewState = {}

    self:PopulateItems()
end

function PANEL:SetPreviewActive(active)
    active = tobool(active)
    self.previewState = self.previewState or {}
    local state = self.previewState
    local currentBlend = state.blend
    local targetBlend = active and 1 or 0

    if ( currentBlend == nil ) then
        currentBlend = (self.previewActive == true) and 1 or 0
    end

    if ( self.previewTransitioning and state.transitionStartTime and state.transitionDuration ) then
        local duration = math.max(state.transitionDuration, 0.001)
        local frac = math.Clamp((CurTime() - state.transitionStartTime) / duration, 0, 1)
        currentBlend = Lerp(frac, state.transitionStartBlend or currentBlend, state.transitionTargetBlend or currentBlend)
    end

    if ( !self.previewTransitioning and math.abs(currentBlend - targetBlend) <= 0.001 and (self.previewActive == true) == active ) then
        return
    end

    state.blend = currentBlend
    state.transitionStartBlend = currentBlend
    state.transitionTargetBlend = targetBlend
    state.transitionStartTime = CurTime()
    state.transitionDuration = INVENTORY_PREVIEW_TRANSITION_TIME

    self.previewActive = active
    self.previewTransitioning = math.abs(currentBlend - targetBlend) > 0.001
    self:ApplyInventoryGradients(active)
end

function PANEL:GetPreviewActive()
    return self.previewActive == true
end

function PANEL:IsPreviewViewActive()
    return self.previewActive == true or self.previewTransitioning == true
end

function PANEL:ApplyInventoryGradients(active)
    local tab = ax.gui.tab
    if ( !IsValid(tab) ) then return end

    if ( active ) then
        tab:SetBackgroundBlurTarget(0)
        tab:SetBackgroundAlphaTarget(0.25) -- keep some tint so it doesn't look weird
        tab:SetGradientLeftTarget(0)
        tab:SetGradientTopTarget(0)
        tab:SetGradientBottomTarget(0)
    else
        tab:SetBackgroundBlurTarget(1)
        tab:SetBackgroundAlphaTarget(1)
        tab:SetGradientLeftTarget(1)
        tab:SetGradientTopTarget(1)
        tab:SetGradientBottomTarget(1)
    end
end

function PANEL:BuildPreviewView(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    if ( client:InVehicle() ) then return end
    if ( !self:IsPreviewViewActive() ) then return end

    local defaultOrigin = client:EyePos()
    local defaultAngles = client:EyeAngles()
    local defaultFov = GetDesiredFov()

    local head = client:LookupBone("ValveBiped.Bip01_Head1")
    local headPos = defaultOrigin

    if ( head ) then
        local bonePos = client:GetBonePosition(head)
        if ( isvector(bonePos) and bonePos != vector_origin ) then
            headPos = bonePos
        end
    end

    local baseAngles = Angle(0, defaultAngles.y, 0)
    local previewLookAt = headPos - baseAngles:Right() * 18 + Vector(0, 0, -2)
    local previewOffset = baseAngles:Forward() * 64 + baseAngles:Right() * 32 - Vector(0, 0, 8)
    local previewOrigin = previewLookAt + previewOffset
    local previewAngles = (previewLookAt - previewOrigin):Angle()

    local state = self.previewState or {}
    self.previewState = state

    local blend = state.blend
    if ( blend == nil ) then
        blend = self.previewActive and 1 or 0
    end

    if ( self.previewTransitioning ) then
        local startTime = state.transitionStartTime or CurTime()
        local duration = math.max(state.transitionDuration or INVENTORY_PREVIEW_TRANSITION_TIME, 0.001)
        local frac = math.Clamp((CurTime() - startTime) / duration, 0, 1)
        local startBlend = state.transitionStartBlend or blend
        local targetBlend = state.transitionTargetBlend

        if ( targetBlend == nil ) then
            targetBlend = self.previewActive and 1 or 0
        end

        blend = Lerp(frac, startBlend, targetBlend)

        if ( frac >= 1 ) then
            blend = targetBlend
            self.previewTransitioning = false
            state.transitionStartBlend = nil
            state.transitionTargetBlend = nil
            state.transitionStartTime = nil
            state.transitionDuration = nil
        end
    else
        blend = self.previewActive and 1 or 0
    end

    state.blend = math.Clamp(blend, 0, 1)
    state.origin = LerpVector(state.blend, defaultOrigin, previewOrigin)
    state.angles = LerpAngle(state.blend, defaultAngles, previewAngles)
    state.fov = Lerp(state.blend, defaultFov, INVENTORY_PREVIEW_TARGET_FOV)

    return {
        origin = state.origin,
        angles = state.angles,
        fov = state.fov,
        drawviewer = state.blend > 0.5
    }
end

function PANEL:InfoOpen()
    self.info:Motion(0.25, {
        Target = {tall = self.infoExpandedHeight or INVENTORY_INFO_HEIGHT, fraction = 1.0},
        Easing = "OutQuad",
        Think = function(this)
            self.info:SetTall(this.tall)
            self.info:DockMargin(INVENTORY_PREVIEW_WIDTH, ax.util:ScreenScaleH(10) * (1 - this.fraction), 0, 0)
        end
    })
end

function PANEL:InfoClose()
    self.info:Motion(0.25, {
        Target = {tall = 0.0, fraction = 0.0},
        Easing = "OutQuad",
        Think = function(this)
            self.info:SetTall(this.tall)
            self.info:DockMargin(INVENTORY_PREVIEW_WIDTH, ax.util:ScreenScaleH(10) * (1 - this.fraction), 0, 0)
        end
    })
end

function PANEL:GetLiveStackItems(stack)
    if ( !istable(stack) ) then return {} end
    if ( !istable(self.inventory) ) then return {} end

    local inventoryItems = self.inventory:GetItems() or {}
    local inventoryLookup = {}
    for _, invItem in pairs(inventoryItems) do
        if ( istable(invItem) and isnumber(invItem.id) ) then
            inventoryLookup[invItem.id] = invItem
        end
    end

    local liveItems = {}
    local seen = {}
    for _, stackedItem in ipairs(stack.stackedItems or {}) do
        local liveItem = istable(stackedItem) and inventoryLookup[stackedItem.id] or nil
        if ( istable(liveItem) and !seen[liveItem.id] ) then
            liveItems[#liveItems + 1] = liveItem
            seen[liveItem.id] = true
        end
    end

    if ( liveItems[1] == nil and isstring(stack.class) and stack.class != "" ) then
        for _, invItem in pairs(inventoryItems) do
            if ( istable(invItem) and invItem.class == stack.class and !seen[invItem.id] ) then
                liveItems[#liveItems + 1] = invItem
                seen[invItem.id] = true

                if ( isnumber(stack.maxStack) and #liveItems >= stack.maxStack ) then
                    break
                end
            end
        end
    end

    return liveItems
end

function PANEL:ResolveLiveStack(stack)
    if ( !istable(stack) ) then return nil end

    local liveItems = self:GetLiveStackItems(stack)
    if ( liveItems[1] == nil ) then
        return nil
    end

    local representativeItem = liveItems[1]
    local itemTemplate = ax.item.stored[representativeItem.class] or {}

    return {
        class = representativeItem.class,
        category = tostring(representativeItem.category or stack.category or "Miscellaneous"),
        stackCount = #liveItems,
        stackedItems = liveItems,
        representativeItem = representativeItem,
        shouldStack = stack.shouldStack == nil and (itemTemplate.shouldStack or false) or stack.shouldStack,
        maxStack = stack.maxStack or itemTemplate.maxStack or 1
    }
end

function PANEL:PopulateItems()
    local character = self.character
    local inventory = character and character:GetInventory() or self.inventory

    if ( !character or !inventory ) then return end
    self.inventory = inventory

    -- Check if current info panel should be closed due to inventory changes
    if ( self.stack and istable(self.stack) ) then
        local liveStack = self:ResolveLiveStack(self.stack)
        if ( !istable(liveStack) ) then
            self:InfoClose()
            self.stack = nil
        else
            self.stack = liveStack
        end
    end

    self.container:Clear()

    local weightText = ax.localization:GetPhrase("inventory.weight.abbreviation")
    local maxWeight = math.max(inventory:GetMaxWeight(), 0.001)
    self.weightProgress:SetFraction(inventory:GetWeight() / maxWeight)
    self.weightCounter:SetText(math.Round(inventory:GetWeight(), 2) .. weightText .. " / " .. inventory:GetMaxWeight() .. weightText, true)

    if ( IsValid(self.searchEntry) and ax.option:Get("inventory.search.live", true) ) then
        self.searchQuery = string.Trim(self.searchEntry:GetValue() or "")
    end

    local categorySortMode = ax.option:Get("inventory.sort.categories", "alphabetical")
    local itemSortMode = ax.option:Get("inventory.sort.items", "alphabetical")
    local collapsibleCategories = ax.option:Get("inventory.categories.collapsible", true)

    local maxPageSize = math.max(math.floor(tonumber(ax.config:Get("inventory.pagination.max_page_size", 64)) or 64), 1)
    local defaultPageSize = math.Clamp(math.floor(tonumber(ax.config:Get("inventory.pagination.default_page_size", 24)) or 24), 1, maxPageSize)
    local pageSize = math.Clamp(math.floor(tonumber(ax.option:Get("inventory.pagination.page_size", defaultPageSize)) or defaultPageSize), 1, maxPageSize)
    local searchQuery = utf8.lower(string.Trim(self.searchQuery or ""))

    -- Organize items by category first, with stacking support.
    local categorizedItems = {}
    local categoryOrder = {}
    for _, v in pairs(inventory:GetItems()) do
        if ( !ax.item.stored[v.class] ) then
            ax.util:PrintDebug("Item class '" .. tostring(v.class) .. "' not found in registry, skipping...")
            continue
        end

        -- Ensure category is a string and normalize it.
        local category = tostring(v.category or "Miscellaneous")

        if ( !categorizedItems[category] ) then
            categorizedItems[category] = {}
            categoryOrder[#categoryOrder + 1] = category
        end

        -- Check if item should stack with existing items.
        local itemClass = v.class
        local itemTemplate = ax.item.stored[itemClass]
        local shouldStack = itemTemplate.shouldStack or false
        local maxStack = itemTemplate.maxStack or 1

        if ( shouldStack ) then
            -- Look for existing stack of the same class.
            local foundStack = false
            for i, existingStack in ipairs(categorizedItems[category]) do
                if ( existingStack.class == itemClass and existingStack.stackCount < maxStack ) then
                    -- Add to existing stack.
                    existingStack.stackCount = existingStack.stackCount + 1
                    existingStack.stackedItems[ #existingStack.stackedItems + 1 ] = v
                    foundStack = true
                    break
                end
            end

            if ( !foundStack ) then
                -- Create new stack.
                categorizedItems[category][ #categorizedItems[category] + 1 ] = {
                    class = itemClass,
                    category = category,
                    stackCount = 1,
                    stackedItems = {v},
                    representativeItem = v, -- Use first item as display representative
                    shouldStack = shouldStack,
                    maxStack = maxStack
                }
            end
        else
            -- Non-stackable item, add individually.
            categorizedItems[category][ #categorizedItems[category] + 1 ] = {
                class = itemClass,
                category = category,
                stackCount = 1,
                stackedItems = {v},
                representativeItem = v,
                shouldStack = false,
                maxStack = 1
            }
        end
    end

    local sortedCategories = {}
    if ( categorySortMode == "manual" ) then
        for i = 1, #categoryOrder do
            sortedCategories[#sortedCategories + 1] = categoryOrder[i]
        end
    else
        for categoryName in pairs(categorizedItems) do
            sortedCategories[ #sortedCategories + 1 ] = categoryName
        end

        table.sort(sortedCategories, function(a, b)
            return utf8.lower(tostring(a)) < utf8.lower(tostring(b))
        end)
    end

    for i = 1, #sortedCategories do
        local categoryName = sortedCategories[i]
        local stacks = categorizedItems[categoryName] or {}

        table.sort(stacks, function(a, b)
            local representativeA = a.representativeItem
            local representativeB = b.representativeItem

            local nameA = utf8.lower(tostring((istable(representativeA) and representativeA:GetName()) or a.class or ""))
            local nameB = utf8.lower(tostring((istable(representativeB) and representativeB:GetName()) or b.class or ""))

            if ( itemSortMode == "weight" ) then
                local weightA = (istable(representativeA) and tonumber(representativeA:GetWeight())) or 0
                local weightB = (istable(representativeB) and tonumber(representativeB:GetWeight())) or 0
                if ( weightA == weightB ) then
                    return nameA < nameB
                end

                return weightA < weightB
            elseif ( itemSortMode == "class" ) then
                local classA = utf8.lower(tostring(a.class or ""))
                local classB = utf8.lower(tostring(b.class or ""))
                if ( classA == classB ) then
                    return nameA < nameB
                end

                return classA < classB
            end

            return nameA < nameB
        end)
    end

    local filteredStacks = {}
    for i = 1, #sortedCategories do
        local categoryName = sortedCategories[i]
        local stacks = categorizedItems[categoryName] or {}

        for _, stack in ipairs(stacks) do
            local representativeItem = stack.representativeItem
            if ( !istable(representativeItem) ) then
                continue
            end

            local displayName = utf8.lower(tostring(representativeItem:GetName() or ""))
            local className = utf8.lower(tostring(stack.class or ""))
            local category = utf8.lower(tostring(categoryName or ""))
            local description = utf8.lower(tostring(representativeItem:GetDescription() or ""))

            if (
                searchQuery == ""
                or string.find(displayName, searchQuery, 1, true)
            ) then
                filteredStacks[#filteredStacks + 1] = {
                    category = categoryName,
                    stack = stack
                }
            end
        end
    end

    local totalStacks = #filteredStacks
    local pageCount = math.max(math.ceil(math.max(totalStacks, 1) / pageSize), 1)
    self.inventoryPage = math.Clamp(tonumber(self.inventoryPage) or 1, 1, pageCount)

    local startIndex = ((self.inventoryPage - 1) * pageSize) + 1
    local endIndex = math.min(startIndex + pageSize - 1, totalStacks)

    if ( IsValid(self.pageCounter) ) then
        local shownStacks = totalStacks > 0 and (endIndex - startIndex + 1) or 0
        self.pageCounter:SetText("Page " .. self.inventoryPage .. " / " .. pageCount .. " (" .. shownStacks .. " of " .. totalStacks .. ")", true)
    end

    if ( IsValid(self.pagePrev) ) then
        self.pagePrev:SetEnabled(self.inventoryPage > 1)
    end

    if ( IsValid(self.pageNext) ) then
        self.pageNext:SetEnabled(self.inventoryPage < pageCount)
    end

    if ( IsValid(self.pagination) ) then
        self.pagination:SetVisible(totalStacks > 0)
    end

    if ( totalStacks < 1 ) then
        local emptyText = self.container:Add("ax.text")
        emptyText:Dock(TOP)
        emptyText:SetFont("ax.regular.italic")
        emptyText:SetText(searchQuery != "" and "No inventory items match your search." or "No items in inventory.", true)
        emptyText:SetContentAlignment(4)
        return
    end

    local pageCategories = {}
    local pageCategoryStacks = {}
    for i = startIndex, endIndex do
        local pageEntry = filteredStacks[i]
        if ( !istable(pageEntry) ) then
            continue
        end

        local categoryName = pageEntry.category
        if ( !pageCategoryStacks[categoryName] ) then
            pageCategoryStacks[categoryName] = {}
            pageCategories[#pageCategories + 1] = categoryName
        end

        pageCategoryStacks[categoryName][#pageCategoryStacks[categoryName] + 1] = pageEntry.stack
    end

    for i = 1, #pageCategories do
        local categoryName = pageCategories[i]
        local stacks = pageCategoryStacks[categoryName] or {}
        local isCollapsed = collapsibleCategories and self.collapsedCategories[categoryName] == true

        local categoryPanel = self.container:Add("ax.text")

        local useItalic = ax.option:Get("inventory.categories.italic", false)
        local categoryFont = useItalic and "ax.huge.bold.italic" or "ax.huge.bold"

        categoryPanel:SetFont(categoryFont)
        local collapsePrefix = collapsibleCategories and (isCollapsed and "[+] " or "[-] ") or ""
        categoryPanel:SetText(collapsePrefix .. utf8.upper(categoryName), true)
        categoryPanel:Dock(TOP)
        categoryPanel:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))

        if ( collapsibleCategories ) then
            categoryPanel:SetMouseInputEnabled(true)
            categoryPanel:SetCursor("hand")
            categoryPanel.OnMousePressed = function()
                self.collapsedCategories[categoryName] = !isCollapsed
                self:PopulateItems()
            end
        end

        if ( !isCollapsed ) then
            for _, stack in ipairs(stacks) do
                local representativeItem = stack.representativeItem

                local item = self.container:Add("ax.button")
                item:SetFont("ax.small")
                item:SetFontDefault("ax.small")
                item:SetFontHovered("ax.small.bold")
                item:Dock(TOP)
                item:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
                item.isInventoryRow = true

                local displayName = representativeItem:GetName() or tostring(representativeItem)
                item:SetText(displayName, true)
                item:SetContentAlignment(4)
                item:SetTextInset(item:GetTall() + ax.util:ScreenScale(8), 0)

                item.DoClick = function()
                    self:InfoOpen()
                    self.info:Clear()
                    self:PopulateInfo(stack)
                end

                local icon = item:Add("SpawnIcon")
                icon:SetWide(item:GetTall() - 16)
                icon:DockMargin(8, 8, 8, 8)
                icon:SetModel(representativeItem:GetModel() or "models/props_junk/wood_crate001a.mdl")
                icon:SetMouseInputEnabled(false)
                icon:Dock(LEFT)

                if ( stack.stackCount > 1 ) then
                    local stackLabel = item:Add("ax.text")
                    stackLabel:Dock(RIGHT)
                    stackLabel:DockMargin(0, 0, ax.util:ScreenScale(8), 0)
                    stackLabel:SetFont("ax.small.italic")
                    stackLabel:SetText("x" .. stack.stackCount, true)
                    stackLabel:SetContentAlignment(6)
                end
            end
        end

        local spacer = self.container:Add("Panel")
        spacer:Dock(TOP)
        spacer:SetTall(INVENTORY_CATEGORY_SPACING)
    end
end

function PANEL:PopulateInfo(stack)
    if ( !istable(stack) ) then return end

    local representativeItem = stack.representativeItem
    if ( !istable(representativeItem) ) then return end

    self.stack = stack

    local header = self.info:Add("EditablePanel")
    header:Dock(TOP)
    header:DockMargin(ax.util:ScreenScale(16), ax.util:ScreenScaleH(16), ax.util:ScreenScale(8), 0)

    local title = header:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.large.bold")
    local titleText = representativeItem:GetName() or "Unknown Item"
    if ( stack.stackCount > 1 ) then
        titleText = titleText .. " x" .. stack.stackCount
    end
    title:SetText(titleText, true)
    title:SetContentAlignment(4)

    -- Add stack information
    if ( stack.shouldStack ) then
        local stackInfo = header:Add("ax.text")
        stackInfo:Dock(TOP)
        stackInfo:SetFont("ax.small.italic")
        stackInfo:SetText("Stack: " .. stack.stackCount .. " / " .. stack.maxStack, true)
        stackInfo:SetContentAlignment(4)

        header:SetTall(title:GetTall() + stackInfo:GetTall() + ax.util:ScreenScaleH(4))
    else
        header:SetTall(title:GetTall())
    end

    local content = self.info:Add("EditablePanel")
    content:Dock(FILL)
    content:DockMargin(ax.util:ScreenScale(16), 0, ax.util:ScreenScale(8), ax.util:ScreenScaleH(8))
    content.Paint = nil

    local body = content:Add("ax.scroller.vertical")
    body:Dock(FILL)
    body:GetVBar():SetWide(0)
    body.Paint = nil

    local description = representativeItem:GetDescription() or "No description available."
    local availableWidth = math.max(self:GetWide() - INVENTORY_PREVIEW_WIDTH - INVENTORY_ACTIONS_WIDTH - ax.util:ScreenScale(48), ax.util:ScreenScale(120))
    local descriptionWrapped = ax.util:GetWrappedText(description, "ax.regular", availableWidth)

    for _ = 1, #descriptionWrapped do
        local line = descriptionWrapped[_]
        local descLine = body:Add("ax.text")
        descLine:Dock(TOP)
        descLine:SetFont("ax.regular")
        descLine:SetText(line, true)
        descLine:SetContentAlignment(4)
    end

    local actionsPanel = self.info:Add("ax.scroller.vertical")
    actionsPanel:Dock(RIGHT)
    actionsPanel:SetZPos(-99)
    actionsPanel:SetWide(INVENTORY_ACTIONS_WIDTH)
    actionsPanel:DockMargin(ax.util:ScreenScale(8), ax.util:ScreenScaleH(16), ax.util:ScreenScale(8), ax.util:ScreenScaleH(8))
    actionsPanel:GetVBar():SetWide(0)
    actionsPanel.Paint = nil

    local actionsHeader = actionsPanel:Add("ax.text")
    actionsHeader:Dock(TOP)
    actionsHeader:SetFont("ax.small.italic")
    actionsHeader:SetText("ACTIONS", true)
    actionsHeader:SetContentAlignment(4)

    -- Get actions from representative item
    local actions = representativeItem:GetActions() or {}
    if ( table.IsEmpty(actions) ) then
        local noActions = actionsPanel:Add("ax.text")
        noActions:Dock(TOP)
        noActions:SetFont("ax.regular.italic")
        noActions:SetText("No actions available for this item.", true)
        noActions:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
        noActions:SetContentAlignment(4)

        return
    end

    for k, v in pairs(actions) do
        if ( representativeItem:CanInteract(ax.client, k, true) == false ) then
            continue
        end

        local actionButton = actionsPanel:Add("ax.button.icon")
        actionButton:Dock(TOP)
        actionButton:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
        actionButton:SetFont("ax.small")
        actionButton:SetFontDefault("ax.small")
        actionButton:SetFontHovered("ax.small.italic")
        actionButton:SetText(v.name or k, true)
        actionButton:SetContentAlignment(4)
        actionButton:SetIcon(v.icon)

        actionButton.DoClick = function()
            local liveStack = self:ResolveLiveStack(stack)
            if ( !istable(liveStack) ) then
                ax.util:PrintError("No valid items in this stack remain.")
                self:InfoClose()
                return
            end

            -- Use a random item from the stack for the action
            local itemToUse
            -- Iterate through stacked items to find one that can perform the action and if we have it in the inventory still
            for _, stackedItem in ipairs(liveStack.stackedItems or {}) do
                -- Get the item template to check for actions
                local itemTemplate = ax.item.stored[stackedItem.class]
                if ( itemTemplate and itemTemplate:GetActions()[k] ) then
                    -- Check if we still have this item in inventory
                    local hasItem = false
                    for itemId, invItem in pairs(self.inventory:GetItems()) do
                        if ( invItem.id == stackedItem.id ) then
                            hasItem = true
                            break
                        end
                    end

                    if ( hasItem ) then
                        itemToUse = stackedItem
                        break
                    end
                end
            end

            if ( !istable(itemToUse) ) then
                ax.util:PrintError("No valid item in stack can perform action '" .. k .. "'.")
                return
            end

            ax.net:Start("inventory.item.action", itemToUse.id, k)

            -- Don't update local stack here - wait for server to confirm the action
            -- and trigger inventory refresh through proper networking
        end

        if ( k == "drop" and stack.stackCount > 1 ) then
            local function DropStackQuantity(quantity)
                local liveStack = self:ResolveLiveStack(stack)
                if ( !istable(liveStack) ) then
                    ax.util:PrintError("No valid items in this stack remain.")
                    self:InfoClose()
                    return
                end

                quantity = math.floor(tonumber(quantity) or 1)
                quantity = math.Clamp(quantity, 1, liveStack.stackCount)

                for i = 1, quantity do
                    timer.Simple(i * 0.1, function()
                        if ( !IsValid(self) ) then return end
                        if ( !istable(liveStack) or #liveStack.stackedItems < i ) then return end
                        local item = liveStack.stackedItems[i]
                        if ( !istable(item) ) then return end

                        ax.net:Start("inventory.item.action", item.id, "drop")
                    end)
                end

                -- Close info panel immediately for user feedback.
                -- Server will handle the actual inventory updates.
                self:InfoClose()
            end

            actionButton.DoRightClick = function()
                if ( !ax.option:Get("inventory.actions.confirm_bulk_drop", true) ) then
                    DropStackQuantity(stack.stackCount)
                    return
                end

                Derma_StringRequest(
                    "Drop Item",
                    "Enter the quantity to drop (max " .. stack.stackCount .. "):",
                    tostring(stack.stackCount),
                    function(text)
                        DropStackQuantity(text)
                    end,
                    nil
                )
            end
        end
    end
end

vgui.Register("ax.tab.inventory", PANEL, "EditablePanel")

ax.viewstack:RegisterModifier("inventory", function(client, patch)
    local panel = ax.gui.inventory
    if ( !IsValid(panel) ) then
        return
    end

    if ( !panel:IsPreviewViewActive() ) then
        return
    end

    return panel:BuildPreviewView(client)
end, 900)

hook.Add("PopulateTabButtons", "ax.tab.inventory", function(buttons)
    buttons["inventory"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.inventory")
        end,
        OnOpen = function(this, panel)
            if ( !IsValid(ax.gui.inventory) ) then return end
            ax.gui.inventory:SetPreviewActive(true)

            -- Delay gradient application to ensure tab is fully initialized
            timer.Simple(0, function()
                if ( !IsValid(ax.gui.inventory) ) then return end
                ax.gui.inventory:ApplyInventoryGradients(true)
            end)
        end,
        OnClose = function(this, panel)
            if ( !IsValid(ax.gui.inventory) ) then return end
            ax.gui.inventory:SetPreviewActive(false)
        end,
    }
end)

hook.Add("OnTabMenuClosing", "ax.tab.inventory.previewfade", function()
    if ( !IsValid(ax.gui.inventory) ) then return end

    ax.gui.inventory:SetPreviewActive(false)
end)

hook.Add("OnTabMenuOpened", "ax.tab.inventory.applygradients", function(activeTab)
    if ( activeTab == "inventory" and IsValid(ax.gui.inventory) ) then
        timer.Simple(0, function()
            if ( !IsValid(ax.gui.inventory) ) then return end
            ax.gui.inventory:ApplyInventoryGradients(true)
        end)
    end
end)
