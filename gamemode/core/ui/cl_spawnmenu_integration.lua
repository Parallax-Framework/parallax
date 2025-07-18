--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Integration with GMod's spawnmenu system

-- Add Parallax items to the spawnmenu content browser
hook.Add("PopulateContent", "ax.spawnmenu.items", function(pnlContent, tree, node)
    if ( !CAMI.PlayerHasAccess(ax.client, "Parallax - Manage Items", nil) ) then
        return
    end

    -- Create Parallax items node
    local ParallaxNode = tree:AddNode("Parallax Items", "icon16/box.png")
    ParallaxNode.DoPopulate = function(self)
        -- Clear existing
        if ( IsValid(self.PropPanel) ) then
            self.PropPanel:Clear(true)
        end

        -- Get categories
        local categories = {}
        for uniqueID, itemDef in pairs(ax.item.stored) do
            if ( itemDef.IsBase ) then continue end

            local category = itemDef:GetCategory() or "Miscellaneous"
            if ( !categories[category] ) then
                categories[category] = {}
            end

            table.insert(categories[category], {
                uniqueID = uniqueID,
                def = itemDef
            })
        end

        -- Create category nodes
        for categoryName, items in pairs(categories) do
            local catNode = self:AddNode(categoryName, "icon16/folder.png")
            catNode.DoPopulate = function(catSelf)
                if ( IsValid(catSelf.PropPanel) ) then
                    catSelf.PropPanel:Clear(true)
                end

                self.PropPanel = vgui.Create("ContentContainer", pnlContent)
                self.PropPanel:SetVisible(false)
                self.PropPanel:SetTriggerSpawnlistChange(false)

                -- Sort items by name
                table.sort(items, function(a, b)
                    return a.def:GetName() < b.def:GetName()
                end)

                -- Add items to spawn list
                for _, itemData in ipairs(items) do
                    local uniqueID = itemData.uniqueID
                    local itemDef = itemData.def

                    local icon = spawnmenu.CreateContentIcon("entity", self.PropPanel, {
                        nicename = itemDef:GetName(),
                        spawnname = "ax_item",
                        material = "entities/ax_item.png",
                        admin = true
                    })

                    if ( IsValid(icon) ) then
                        icon.DoClick = function()
                            RunConsoleCommand("ax_item_spawn", uniqueID, "1")
                        end

                        icon.DoRightClick = function()
                            local menu = DermaMenu()

                            menu:AddOption("Spawn in World", function()
                                RunConsoleCommand("ax_item_spawn", uniqueID, "1")
                            end):SetIcon("icon16/world.png")

                            menu:AddOption("Give to Self", function()
                                RunConsoleCommand("ax_item_give", uniqueID, "", "1")
                            end):SetIcon("icon16/user.png")

                            menu:AddOption("Copy Unique ID", function()
                                SetClipboardText(uniqueID)
                                ax.client:Notify("Copied to clipboard: " .. uniqueID)
                            end):SetIcon("icon16/page_copy.png")

                            menu:AddSeparator()

                            menu:AddOption("Open Item Spawner", function()
                                ax.OpenItemSpawnMenu()
                            end):SetIcon("icon16/application_view_list.png")

                            menu:Open()
                        end

                        icon:SetTooltip(itemDef:GetName() .. "\n" .. (itemDef:GetDescription() or ""))
                    end
                end

                pnlContent:SwitchPanel(self.PropPanel)
            end

            catNode.Icon:SetImage("icon16/folder.png")
        end
    end

    ParallaxNode.Icon:SetImage("icon16/box.png")
end)

-- Add Parallax Items tab to the creation menu using spawnmenu.AddCreationTab
hook.Add("AddTabsToSpawnMenu", "ax.spawnmenu.items", function()
    if ( !CAMI.PlayerHasAccess(ax.client, "Parallax - Manage Items", nil) ) then
        return
    end

    spawnmenu.AddCreationTab("Parallax Items", function()
        local panel = vgui.Create("ax.spawnmenu.items.tab")
        return panel
    end, "icon16/box.png", 150, "Parallax Item Spawner")
end)

-- Create simplified spawnmenu tab version
local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    -- Quick spawn area
    local quickPanel = self:Add("DPanel")
    quickPanel:Dock(TOP)
    quickPanel:SetHeight(60)
    quickPanel:DockMargin(5, 5, 5, 0)
    quickPanel.Paint = function(this, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
    end

    local quickLabel = quickPanel:Add("DLabel")
    quickLabel:Dock(LEFT)
    quickLabel:SetWidth(120)
    quickLabel:DockMargin(10, 5, 5, 5)
    quickLabel:SetText("Quick Actions:")
    quickLabel:SetFont("DermaDefaultBold")
    quickLabel:SetContentAlignment(5)

    local openSpawnerBtn = quickPanel:Add("DButton")
    openSpawnerBtn:Dock(LEFT)
    openSpawnerBtn:SetWidth(150)
    openSpawnerBtn:DockMargin(5, 10, 5, 10)
    openSpawnerBtn:SetText("Open Full Item Spawner")
    openSpawnerBtn.DoClick = function()
        ax.OpenItemSpawnMenu()
    end

    -- Search functionality
    local searchPanel = self:Add("DPanel")
    searchPanel:Dock(TOP)
    searchPanel:SetHeight(30)
    searchPanel:DockMargin(5, 5, 5, 5)
    searchPanel.Paint = function(this, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
    end

    self.searchBox = searchPanel:Add("DTextEntry")
    self.searchBox:Dock(FILL)
    self.searchBox:DockMargin(5, 5, 5, 5)
    self.searchBox:SetPlaceholderText("Search items...")
    self.searchBox.OnChange = function()
        self:FilterCategories()
    end

    -- Item categories
    self.categoryList = self:Add("DCategoryList")
    self.categoryList:Dock(FILL)
    self.categoryList:DockMargin(5, 5, 5, 5)

    self:PopulateCategories()
end

function PANEL:PopulateCategories()
    self.categoryList:Clear()

    -- Get categories
    local categories = {}
    for uniqueID, itemDef in pairs(ax.item.stored) do
        if ( itemDef.IsBase ) then continue end

        local category = itemDef:GetCategory() or "Miscellaneous"
        if ( !categories[category] ) then
            categories[category] = {}
        end

        table.insert(categories[category], {
            uniqueID = uniqueID,
            def = itemDef
        })
    end

    -- Store all categories for filtering
    self.allCategories = categories

    self:CreateCategoryPanels()
end

function PANEL:CreateCategoryPanels()
    if ( !self.allCategories ) then return end

    local searchText = string.lower(self.searchBox and self.searchBox:GetValue() or "")

    -- Create categories
    for categoryName, items in pairs(self.allCategories) do
        -- Filter items by search
        local filteredItems = {}
        for _, itemData in ipairs(items) do
            local itemDef = itemData.def
            local uniqueID = itemData.uniqueID

            if ( searchText == "" ) then
                table.insert(filteredItems, itemData)
            else
                local name = string.lower(itemDef:GetName())
                local id = string.lower(uniqueID)
                local description = string.lower(itemDef:GetDescription() or "")

                if ( string.find(name, searchText, 1, true) or
                     string.find(id, searchText, 1, true) or
                     string.find(description, searchText, 1, true) ) then
                    table.insert(filteredItems, itemData)
                end
            end
        end

        -- Only create category if it has items after filtering
        if ( #filteredItems > 0 ) then
            local category = self.categoryList:Add(categoryName .. " (" .. #filteredItems .. ")")

            -- Sort items
            table.sort(filteredItems, function(a, b)
                return a.def:GetName() < b.def:GetName()
            end)

            -- Add first 15 items to category (to prevent lag)
            for i = 1, math.min(#filteredItems, 15) do
                local itemData = filteredItems[i]
                local uniqueID = itemData.uniqueID
                local itemDef = itemData.def

                local item = category:Add("DButton")
                item:SetText(itemDef:GetName())
                item:SetHeight(25)
                item:SetTooltip(itemDef:GetDescription() or "No description")

                item.DoClick = function()
                    RunConsoleCommand("ax_item_spawn", uniqueID, "1")
                    ax.client:Notify("Spawned " .. itemDef:GetName())
                end

                item.DoRightClick = function()
                    local menu = DermaMenu()

                    menu:AddOption("Spawn in World", function()
                        RunConsoleCommand("ax_item_spawn", uniqueID, "1")
                        ax.client:Notify("Spawned " .. itemDef:GetName())
                    end):SetIcon("icon16/world.png")

                    menu:AddOption("Give to Self", function()
                        RunConsoleCommand("ax_item_give", uniqueID, "", "1")
                        ax.client:Notify("Gave " .. itemDef:GetName() .. " to yourself")
                    end):SetIcon("icon16/user.png")

                    menu:AddSeparator()

                    local giveMenu = menu:AddSubMenu("Give to Player")
                    giveMenu:SetIcon("icon16/group.png")

                    for _, ply in ipairs(player.GetAll()) do
                        giveMenu:AddOption(ply:Name(), function()
                            RunConsoleCommand("ax_item_give", uniqueID, ply:Name(), "1")
                            ax.client:Notify("Gave " .. itemDef:GetName() .. " to " .. ply:Name())
                        end):SetIcon("icon16/user.png")
                    end

                    menu:AddSeparator()

                    menu:AddOption("Copy Unique ID", function()
                        SetClipboardText(uniqueID)
                        ax.client:Notify("Copied to clipboard: " .. uniqueID)
                    end):SetIcon("icon16/page_copy.png")

                    menu:Open()
                end
            end

            if ( #filteredItems > 15 ) then
                local moreBtn = category:Add("DButton")
                moreBtn:SetText("... and " .. (#filteredItems - 15) .. " more (open full spawner)")
                moreBtn:SetHeight(25)
                moreBtn.DoClick = function()
                    ax.OpenItemSpawnMenu()
                end
            end
        end
    end
end

function PANEL:FilterCategories()
    self.categoryList:Clear()
    self:CreateCategoryPanels()
end

vgui.Register("ax.spawnmenu.items.tab", PANEL, "DPanel")

-- Register the content type for Parallax items
spawnmenu.AddContentType("parallax_items", function(container, obj)
    if ( !obj.material ) then obj.material = "entities/ax_item.png" end
    if ( !obj.nicename ) then obj.nicename = obj.name or "Unknown Item" end
    if ( !obj.spawnname ) then obj.spawnname = "ax_item" end

    local icon = spawnmenu.CreateContentIcon(obj.type or "entity", container, obj)

    if ( IsValid(icon) ) then
        icon.DoClick = function()
            RunConsoleCommand("ax_item_spawn", obj.uniqueID or "", "1")
        end

        icon.DoRightClick = function()
            local menu = DermaMenu()

            menu:AddOption("Spawn in World", function()
                RunConsoleCommand("ax_item_spawn", obj.uniqueID or "", "1")
            end):SetIcon("icon16/world.png")

            menu:AddOption("Give to Self", function()
                RunConsoleCommand("ax_item_give", obj.uniqueID or "", "", "1")
            end):SetIcon("icon16/user.png")

            menu:AddOption("Copy Unique ID", function()
                SetClipboardText(obj.uniqueID or "")
                LocalPlayer():Notify("Copied to clipboard: " .. (obj.uniqueID or ""))
            end):SetIcon("icon16/page_copy.png")

            menu:Open()
        end
    end

    return icon
end)