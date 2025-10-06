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

    self.weightProgress = self:Add("DProgress")
    self.weightProgress:SetFraction(inventory:GetWeight() / inventory:GetMaxWeight())
    self.weightProgress:SetTall(ScreenScale(12))
    self.weightProgress:Dock(TOP)
    self.weightProgress.Paint = function(this, width, height)
        ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 150))

        local fraction = this:GetFraction()
        ax.render.Draw(0, 0, 0, width * fraction, height, Color(100, 200, 175, 200))
    end

    local maxWeight = inventory:GetMaxWeight()
    local weight = math.Round(maxWeight * self.weightProgress:GetFraction(), 2)

    self.weightCounter = self.weightProgress:Add("ax.text")
    self.weightCounter:SetFont("ax.regular")
    self.weightCounter:SetText(weight .. "kg / " .. maxWeight .. "kg", true)
    self.weightCounter:SetContentAlignment(5)
    self.weightCounter:Dock(FILL)

    self:PopulateItems()
end

function PANEL:InfoOpen()
    self.info:Motion(0.25, {
        Target = {wide = ScreenScale(128), fraction = 1.0},
        Easing = "OutQuad",
        Think = function(this)
            self.info:SetWide(this.wide)
            self.info:DockMargin(ScreenScale(16) * this.fraction, 0, 0, 0)
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
            self.info:DockMargin(ScreenScale(16) * this.fraction, 0, 0, 0)
            -- Trigger layout update as info panel collapses
            self:PerformLayout()
        end
    })
end

function PANEL:PopulateItems()
    local character = self.character
    local inventory = self.inventory

    if ( !character or !inventory ) then return end

    self.container:Clear()
    
    -- Initialize grid items storage for responsive layout
    self.gridItems = {}

    self.weightProgress:SetFraction(inventory:GetWeight() / inventory:GetMaxWeight())
    self.weightCounter:SetText(math.Round(inventory:GetWeight(), 2) .. "kg / " .. inventory:GetMaxWeight() .. "kg", true)

    -- TODO: Sort categories alphabetically
    -- TODO: Sort items within categories alphabetically
    -- TODO: Allow pressing categories to collapse/expand them
    -- TODO: Implement search/filter functionality
    -- TODO: Support drag-and-drop for item management (e.g., moving to hotbar, equipping)
    -- TODO: Add pagination for large inventories

    -- Grid layout configuration
    local gridColumns = 4
    local containerWidth = self.container:GetWide()
    local itemWidth = containerWidth / gridColumns
    local itemHeight = ScreenScaleH(32)
    local categoryHeight = ScreenScale(24) -- use ScreenScaleH?

    local currentY = 0
    local categoryCache = {}-- not used

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
        return string.lower(tostring(a)) < string.lower(tostring(b))
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
        categoryPanel:SetText(string.upper(categoryName), true)
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

        for i, stack in ipairs(stacks) do
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
            item:SetTextInset(itemHeight + ScreenScale(2), 0)
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
            icon:DockMargin(0, 0, ScreenScale(4), 0)
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
    icon:DockMargin(0, 0, 0, ScreenScaleH(8))
    icon:SetTall(ScreenScaleH(128))
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
        stackInfo:DockMargin(0, 0, 0, ScreenScaleH(4))
    end

    local description = representativeItem:GetDescription() or "No description available."
    local descriptionWrapped = ax.util:GetWrappedText(description, "ax.regular", ScreenScale(128) - ScreenScale(16))

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
        noActions:DockMargin(0, 0, 0, ScreenScaleH(4))
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
                if ( stackedItem.actions and stackedItem.actions[k] and self.inventory:HasItem(stackedItem.id) ) then
                    itemToUse = stackedItem
                    break
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

            -- Update the stack table
            for i = #stack.stackedItems, 1, -1 do
                if ( stack.stackedItems[i].id == itemToUse.id ) then
                    table.remove(stack.stackedItems, i)
                    stack.stackCount = stack.stackCount - 1
                    break
                end
            end

            -- If we used the last item in the stack, close info panel
            if ( stack.stackCount < 1 or self.inventory:HasItem(itemToUse.class) == false ) then
                self:InfoClose()
            end
        end

        if ( k == "drop" and stack.stackCount > 1 ) then
            actionButton.DoRightClick = function()
                local itemToUse = stack.stackedItems[1] -- not used
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
                                if ( !istable(stack) or #stack.stackedItems < 1 ) then return end
                                local item = stack.stackedItems[1]
                                if ( !istable(item) ) then return end

                                net.Start("ax.inventory.item.action")
                                    net.WriteUInt(item.id, 32)
                                    net.WriteString("drop")
                                net.SendToServer()
                            end)

                            -- Remove from local stack immediately for responsiveness
                            table.remove(stack.stackedItems, 1)
                        end

                        -- If dropping entire stack, close info panel
                        if ( quantity >= stack.stackCount ) then
                            self:InfoClose()
                        end
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
    local gridColumns = 4
    local containerWidth = self.container:GetWide()
    local itemWidth = containerWidth / gridColumns
    local itemHeight = ScreenScaleH(32)
    local categoryHeight = ScreenScale(24)
    
    local currentY = 0
    
    -- Use the same sorted order as PopulateItems
    for _, categoryName in ipairs(self.sortedCategoryOrder) do
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
                item:SetTextInset(itemHeight + ScreenScale(2), 0)

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

hook.Add("PopulateTabButtons", "ax.tab.inventory", function(buttons)
    buttons["inventory"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.inventory")
        end
    }
end)
