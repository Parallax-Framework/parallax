--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

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

    self.container = self:Add("ax.scroller.vertical")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    self.info = self:Add("EditablePanel")
    self.info:Dock(RIGHT)
    self.info:SetWide(0)
    self.info.Paint = function(this, width, height)
        ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 150))
    end

    local maxWeight = inventory:GetMaxWeight()
    local weight = inventory:GetWeight()

    self.weightProgress = self:Add("DProgress")
    self.weightProgress:SetFraction(weight / maxWeight)
    self.weightProgress:SetTall(ax.util:ScreenScale(12))
    self.weightProgress:Dock(TOP)
    self.weightProgress.Paint = function(this, width, height)
        ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 150))

        local fraction = this:GetFraction()
        ax.render.Draw(0, 0, 0, width * fraction, height, Color(100, 200, 175, 200))
    end

    local totalWeight = maxWeight * self.weightProgress:GetFraction()

    self.weightCounter = self.weightProgress:Add("ax.text")
    self.weightCounter:SetFont("ax.regular")

    local weightText = ax.localization:GetPhrase("invWeight")

    self.weightCounter:SetText(totalWeight .. weightText .. " / " .. maxWeight .. weightText, true)
    self.weightCounter:SetContentAlignment(5)
    self.weightCounter:Dock(FILL)

    self:PopulateItems()
end

function PANEL:InfoOpen()
    self.info:Motion(0.25, {
        Target = {wide = ax.util:ScreenScale(128), fraction = 1.0},
        Easing = "OutQuad",
        Think = function(this)
            self.info:SetWide(this.wide)
            self.info:DockMargin(ax.util:ScreenScale(16) * this.fraction, 0, 0, 0)
            -- Trigger layout update as info panel expands
            self:PerformLayout()
        end
    })
end

function PANEL:InfoClose()
    self.info:Motion(0.25, {
        Target = {wide = 0.0, fraction = 0.0},
        Easing = "OutQuad",
        Think = function(this)
            self.info:SetWide(this.wide)
            self.info:DockMargin(ax.util:ScreenScale(16) * this.fraction, 0, 0, 0)
            -- Trigger layout update as info panel collapses
            self:PerformLayout()
        end
    })
end

function PANEL:PopulateItems()
    local character = self.character
    local inventory = self.inventory

    if ( !character or !inventory ) then return end

    -- Check if current info panel should be closed due to inventory changes
    if ( self.stack and istable(self.stack) ) then
        local stackStillExists = false
        for _, stackedItem in pairs(self.stack.stackedItems or {}) do
            for itemId, invItem in pairs(inventory:GetItems()) do
                if ( invItem.id == stackedItem.id ) then
                    stackStillExists = true
                    break
                end
            end
            if ( stackStillExists ) then break end
        end

        if ( !stackStillExists ) then
            self:InfoClose()
            self.stack = nil
        end
    end

    self.container:Clear()

    -- Initialize grid items storage for responsive layout
    self.gridItems = {}

    local weightText = ax.localization:GetPhrase("invWeight")
    self.weightProgress:SetFraction(inventory:GetWeight() / inventory:GetMaxWeight())
    self.weightCounter:SetText(math.Round(inventory:GetWeight(), 2) .. weightText .. " / " .. inventory:GetMaxWeight() .. weightText, true)

    -- TODO: Sort categories alphabetically
    -- TODO: Sort items within categories alphabetically
    -- TODO: Allow pressing categories to collapse/expand them
    -- TODO: Implement search/filter functionality
    -- TODO: Support drag-and-drop for item management (e.g., moving to hotbar, equipping)
    -- TODO: Add pagination for large inventories

    -- Grid layout configuration
    local gridColumns = ax.option:Get("inventoryColumns", 4)
    local containerWidth = self.container:GetWide()
    local itemWidth = containerWidth / gridColumns
    local itemHeight = ax.util:ScreenScaleH(32)
    local categoryHeight = ax.util:ScreenScaleH(24) -- use ScreenScaleH?

    local currentY = 0

    -- Organize items by category first, with stacking support
    local categorizedItems = {}
    for k, v in pairs(inventory:GetItems()) do
        if ( !ax.item.stored[v.class] ) then
            ax.util:PrintDebug("Item class '" .. tostring(v.class) .. "' not found in registry, skipping...")
            continue
        end

        -- Ensure category is a string and normalize it
        local category = tostring(v.category or "Miscellaneous")

        if ( !categorizedItems[category] ) then
            categorizedItems[category] = {}
        end

        -- Check if item should stack with existing items
        local itemClass = v.class
        local itemTemplate = ax.item.stored[itemClass]
        local shouldStack = itemTemplate.shouldStack or false
        local maxStack = itemTemplate.maxStack or 1

        if ( shouldStack ) then
            -- Look for existing stack of the same class
            local foundStack = false
            for i, existingStack in ipairs(categorizedItems[category]) do
                if ( existingStack.class == itemClass and existingStack.stackCount < maxStack ) then
                    -- Add to existing stack
                    existingStack.stackCount = existingStack.stackCount + 1
                    existingStack.stackedItems[ #existingStack.stackedItems + 1 ] = v
                    foundStack = true
                    break
                end
            end

            if ( !foundStack ) then
                -- Create new stack
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
            -- Non-stackable item, add individually
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

    -- Sort categories alphabetically with more robust sorting
    local sortedCategories = {}
    for categoryName, stacks in pairs(categorizedItems) do
        sortedCategories[ #sortedCategories + 1 ] = categoryName
    end

    -- Use case-insensitive sorting for consistency
    table.sort(sortedCategories, function(a, b)
        return utf8.lower(tostring(a)) < utf8.lower(tostring(b))
    end)

    -- Store the sorted category order for PerformLayout
    self.sortedCategoryOrder = sortedCategories

    -- Create grid layout for each category in sorted order
    for i = 1, #sortedCategories do
        local categoryName = sortedCategories[i]
        local stacks = categorizedItems[categoryName]
        -- Add category header
        local categoryPanel = self.container:Add("ax.text")

        -- Use user preference for italic styling
        local useItalic = ax.option:Get("inventoryCategoriesItalic", false)
        local categoryFont = useItalic and "ax.huge.italic.bold" or "ax.huge.bold"

        categoryPanel:SetFont(categoryFont)
        categoryPanel:SetText(utf8.upper(categoryName), true)
        categoryPanel:SetPos(0, currentY)
        categoryPanel:SetSize(containerWidth, categoryHeight)

        -- Store category data for responsive layout
        self.gridItems[categoryName] = {
            header = categoryPanel,
            items = {}
        }

        currentY = currentY + categoryHeight

        -- Create grid for stacks in this category
        local currentColumn = 0
        local currentRow = 0

        for _, stack in ipairs(stacks) do
            local itemX = currentColumn * itemWidth
            local itemY = currentY + (currentRow * itemHeight)

            local representativeItem = stack.representativeItem

            local item = self.container:Add("ax.button.flat")
            item:SetFont("ax.small")
            item:SetFontDefault("ax.small")
            item:SetFontHovered("ax.regular.bold")

            -- Display stack count in item name if stacked
            local displayName = representativeItem:GetName() or tostring(representativeItem)
            if ( stack.stackCount > 1 ) then
                displayName = displayName .. " (x" .. stack.stackCount .. ")"
            end

            item:SetText(displayName, true)
            item:SetContentAlignment(4)
            item:SetTextInset(itemHeight + ax.util:ScreenScale(2), 0)
            item:SetPos(itemX, itemY)
            item:SetSize(itemWidth, itemHeight)

            item.DoClick = function()
                self:InfoOpen()
                self.info:Clear()
                self:PopulateInfo(stack)
            end

            -- Store item reference for responsive layout
            table.insert(self.gridItems[categoryName].items, item)

            local icon = item:Add("SpawnIcon")
            icon:SetWide(itemHeight)
            icon:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
            icon:SetModel(representativeItem:GetModel() or "models/props_junk/wood_crate001a.mdl")
            icon:SetMouseInputEnabled(false)
            icon:Dock(LEFT)

            -- Move to next position in grid
            currentColumn = currentColumn + 1
            if ( currentColumn >= gridColumns ) then
                currentColumn = 0
                currentRow = currentRow + 1
            end
        end

        -- Update currentY for next category (account for the rows we used)
        local rowsUsed = math.ceil(#stacks / gridColumns)
        currentY = currentY + (rowsUsed * itemHeight)
    end
end

function PANEL:PopulateInfo(stack)
    if ( !istable(stack) ) then return end

    local representativeItem = stack.representativeItem
    if ( !istable(representativeItem) ) then return end

    self.stack = stack

    local icon = self.info:Add("DModelPanel")
    icon:Dock(TOP)
    icon:DockMargin(0, 0, 0, ax.util:ScreenScaleH(8))
    icon:SetTall(ax.util:ScreenScaleH(128))
    icon:SetModel(representativeItem:GetModel() or "models/props_junk/wood_crate001a.mdl")
    icon:SetMouseInputEnabled(false)
    icon.PerformLayout = function(this, width, height)
        local entity = this:GetEntity()
        if ( !IsValid(entity) ) then return end

        local center = entity:OBBCenter()
        local size = entity:OBBMaxs() - entity:OBBMins()
        local camPos = center + Vector(size.x, size.y, size.z / 4) * 8
        this:SetCamPos(camPos)
        this:SetLookAt(center)
        this:SetFOV(15)
    end

    local title = self.info:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.large.bold")
    local titleText = representativeItem:GetName() or "Unknown Item"
    if ( stack.stackCount > 1 ) then
        titleText = titleText .. " x" .. stack.stackCount
    end
    title:SetText(titleText, true)
    title:SetContentAlignment(5)

    -- Add stack information
    if ( stack.shouldStack ) then
        local stackInfo = self.info:Add("ax.text")
        stackInfo:Dock(TOP)
        stackInfo:SetFont("ax.small.italic")
        stackInfo:SetText("Stack: " .. stack.stackCount .. " / " .. stack.maxStack, true)
        stackInfo:SetContentAlignment(5)
        stackInfo:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    end

    local description = representativeItem:GetDescription() or "No description available."
    local descriptionWrapped = ax.util:GetWrappedText(description, "ax.regular", ax.util:ScreenScale(128) - ax.util:ScreenScale(16))

    for _ = 1, #descriptionWrapped do
        local line = descriptionWrapped[_]
        local descLine = self.info:Add("ax.text")
        descLine:Dock(TOP)
        descLine:SetFont("ax.regular")
        descLine:SetText(line, true)
        descLine:SetContentAlignment(5)
    end

    -- Get actions from representative item
    local actions = representativeItem:GetActions() or {}
    if ( table.IsEmpty(actions) ) then
        local noActions = self.info:Add("ax.text")
        noActions:Dock(BOTTOM)
        noActions:SetFont("ax.regular.italic")
        noActions:SetText("No actions available for this item.", true)
        noActions:SizeToContentsY()
        noActions:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
        noActions:SetContentAlignment(5)

        return
    end

    for k, v in pairs(actions) do
        local actionButton = self.info:Add("ax.button.flat")
        actionButton:Dock(BOTTOM)
        actionButton:SetFont("ax.small")
        actionButton:SetFontDefault("ax.small")
        actionButton:SetFontHovered("ax.small.italic")
        actionButton:SetText(v.name or k, true)
        actionButton:SetContentAlignment(5)
        actionButton:SetIcon(v.icon)

        actionButton.DoClick = function()
            -- Use a random item from the stack for the action
            local itemToUse
            -- Iterate through stacked items to find one that can perform the action and if we have it in the inventory still
            for _, stackedItem in pairs(stack.stackedItems) do
                -- Get the item template to check for actions
                local itemTemplate = ax.item.stored[stackedItem.class]
                if ( itemTemplate and itemTemplate.actions and itemTemplate.actions[k] ) then
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

            net.Start("ax.inventory.item.action")
                net.WriteUInt(itemToUse.id, 32)
                net.WriteString(k)
            net.SendToServer()

            -- Don't update local stack here - wait for server to confirm the action
            -- and trigger inventory refresh through proper networking
        end

        if ( k == "drop" and stack.stackCount > 1 ) then
            actionButton.DoRightClick = function()
                Derma_StringRequest(
                    "Drop Item",
                    "Enter the quantity to drop (max " .. stack.stackCount .. "):",
                    tostring(stack.stackCount),
                    function(text)
                        local quantity = tonumber(text) or 1
                        quantity = math.Clamp(quantity, 1, stack.stackCount)

                        for i = 1, quantity do
                            timer.Simple(i * 0.1, function()
                                if ( !IsValid(self) ) then return end
                                if ( !istable(stack) or #stack.stackedItems < i ) then return end
                                local item = stack.stackedItems[i]
                                if ( !istable(item) ) then return end

                                net.Start("ax.inventory.item.action")
                                    net.WriteUInt(item.id, 32)
                                    net.WriteString("drop")
                                net.SendToServer()
                            end)
                        end

                        -- Close info panel immediately for user feedback
                        -- Server will handle the actual inventory updates
                        self:InfoClose()
                    end,
                    nil
                )
            end
        end
    end
end

function PANEL:PerformLayout(width, height)
    if ( !self.gridItems or !self.sortedCategoryOrder ) then return end

    -- Recalculate grid layout based on current container width
    local gridColumns = ax.option:Get("inventoryColumns", 4)
    local containerWidth = self.container:GetWide()
    local itemWidth = containerWidth / gridColumns
    local itemHeight = ax.util:ScreenScaleH(32)
    local categoryHeight = ax.util:ScreenScaleH(24)

    local currentY = 0

    -- Use the same sorted order as PopulateItems
    for _ = 1, #self.sortedCategoryOrder do
        local categoryName = self.sortedCategoryOrder[_]
        local categoryData = self.gridItems[categoryName]
        if ( !categoryData ) then continue end
        -- Reposition category header
        local categoryPanel = categoryData.header
        if ( IsValid(categoryPanel) ) then
            categoryPanel:SetPos(0, currentY)
            categoryPanel:SetSize(containerWidth, categoryHeight)

            -- Update font based on user preference
            local useItalic = ax.option:Get("inventoryCategoriesItalic", false)
            local categoryFont = useItalic and "ax.huge.italic.bold" or "ax.huge.bold"
            categoryPanel:SetFont(categoryFont)
        end

        currentY = currentY + categoryHeight

        -- Reposition items in grid
        local currentColumn = 0
        local currentRow = 0

        for i = 1, #categoryData.items do
            local item = categoryData.items[i]
            if ( IsValid(item) ) then
                local itemX = currentColumn * itemWidth
                local itemY = currentY + (currentRow * itemHeight)

                item:SetPos(itemX, itemY)
                item:SetSize(itemWidth, itemHeight)

                -- Update text inset for new size
                item:SetTextInset(itemHeight + ax.util:ScreenScale(2), 0)

                -- Update icon size
                local icon = item:GetChildren()[1]
                if ( IsValid(icon) ) then
                    icon:SetWide(itemHeight)
                end
            end

            currentColumn = currentColumn + 1
            if ( currentColumn >= gridColumns ) then
                currentColumn = 0
                currentRow = currentRow + 1
            end
        end

        -- Update currentY for next category
        local rowsUsed = math.ceil(#categoryData.items / gridColumns)
        currentY = currentY + (rowsUsed * itemHeight)
    end
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.tab.inventory", PANEL, "EditablePanel")

-- Clean up existing hook to prevent duplicates on reload
hook.Remove("PopulateTabButtons", "ax.tab.inventory")

hook.Add("PopulateTabButtons", "ax.tab.inventory", function(buttons)
    buttons["inventory"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.inventory")
        end
    }
end)
