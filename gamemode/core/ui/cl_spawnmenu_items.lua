--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("DPanel")

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() * 0.8, ScrH() * 0.8)
    self:Center()
    self:SetTitle("Item Spawner")
    self:SetVisible(false)
    self:SetDeleteOnClose(false)
    self:ShowCloseButton(true)
    self:SetDraggable(true)
    self:MakePopup()

    -- Store reference for global access
    ax.gui.itemSpawnMenu = self

    -- Search and filter controls
    self:CreateSearchControls()

    -- Main content area
    self:CreateContentArea()

    -- Action buttons
    self:CreateActionButtons()

    -- Populate items
    self:PopulateItems()
end

function PANEL:CreateSearchControls()
    local searchPanel = self:Add("DPanel")
    searchPanel:Dock(TOP)
    searchPanel:SetHeight(40)
    searchPanel:DockMargin(5, 5, 5, 0)
    searchPanel.Paint = function(this, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
    end

    -- Search box
    self.searchBox = searchPanel:Add("DTextEntry")
    self.searchBox:Dock(LEFT)
    self.searchBox:SetWidth(200)
    self.searchBox:DockMargin(5, 5, 5, 5)
    self.searchBox:SetPlaceholderText("Search items...")
    self.searchBox.OnChange = function()
        self:FilterItems()
    end

    -- Category filter
    self.categoryFilter = searchPanel:Add("DComboBox")
    self.categoryFilter:Dock(LEFT)
    self.categoryFilter:SetWidth(150)
    self.categoryFilter:DockMargin(5, 5, 5, 5)
    self.categoryFilter:AddChoice("All Categories", "")
    self.categoryFilter.OnSelect = function()
        self:FilterItems()
    end

    -- Refresh button
    local refreshBtn = searchPanel:Add("DButton")
    refreshBtn:Dock(RIGHT)
    refreshBtn:SetWidth(80)
    refreshBtn:DockMargin(5, 5, 5, 5)
    refreshBtn:SetText("Refresh")
    refreshBtn.DoClick = function()
        self:PopulateItems()
    end
end

function PANEL:CreateContentArea()
    -- Create splitter for list and preview
    self.splitter = self:Add("DHorizontalDivider")
    self.splitter:Dock(FILL)
    self.splitter:DockMargin(5, 5, 5, 5)
    self.splitter:SetDividerWidth(4)
    self.splitter:SetLeftMin(300)
    self.splitter:SetRightMin(200)

    -- Item list (left side)
    self:CreateItemList()

    -- Item preview/info (right side)
    self:CreateItemPreview()

    self.splitter:SetLeft(self.itemListPanel)
    self.splitter:SetRight(self.previewPanel)
end

function PANEL:CreateItemList()
    self.itemListPanel = vgui.Create("DPanel")
    self.itemListPanel.Paint = function(this, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
    end

    -- Item scroll list
    self.itemList = self.itemListPanel:Add("DScrollPanel")
    self.itemList:Dock(FILL)
    self.itemList:DockMargin(5, 5, 5, 5)

    local vbar = self.itemList:GetVBar()
    vbar:SetWidth(12)
    vbar.Paint = function(this, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 100))
    end
    vbar.btnGrip.Paint = function(this, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 150))
    end
end

function PANEL:CreateItemPreview()
    self.previewPanel = vgui.Create("DPanel")
    self.previewPanel.Paint = function(this, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
    end

    -- Preview content
    self.previewContent = self.previewPanel:Add("DScrollPanel")
    self.previewContent:Dock(FILL)
    self.previewContent:DockMargin(5, 5, 5, 5)

    -- Default message
    self.noSelectionLabel = self.previewContent:Add("DLabel")
    self.noSelectionLabel:SetText("Select an item to view details")
    self.noSelectionLabel:SetFont("DermaLarge")
    self.noSelectionLabel:SetTextColor(Color(150, 150, 150))
    self.noSelectionLabel:SizeToContents()
    self.noSelectionLabel:Center()
end

function PANEL:CreateActionButtons()
    local buttonPanel = self:Add("DPanel")
    buttonPanel:Dock(BOTTOM)
    buttonPanel:SetHeight(50)
    buttonPanel:DockMargin(5, 0, 5, 5)
    buttonPanel.Paint = function(this, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
    end

    -- Spawn in world button
    self.spawnWorldBtn = buttonPanel:Add("DButton")
    self.spawnWorldBtn:Dock(LEFT)
    self.spawnWorldBtn:SetWidth(120)
    self.spawnWorldBtn:DockMargin(5, 5, 5, 5)
    self.spawnWorldBtn:SetText("Spawn in World")
    self.spawnWorldBtn:SetEnabled(false)
    self.spawnWorldBtn.DoClick = function()
        self:SpawnInWorld()
    end

    -- Give to self button
    self.giveToSelfBtn = buttonPanel:Add("DButton")
    self.giveToSelfBtn:Dock(LEFT)
    self.giveToSelfBtn:SetWidth(120)
    self.giveToSelfBtn:DockMargin(5, 5, 5, 5)
    self.giveToSelfBtn:SetText("Give to Self")
    self.giveToSelfBtn:SetEnabled(false)
    self.giveToSelfBtn.DoClick = function()
        self:GiveToSelf()
    end

    -- Give to player button
    self.giveToPlayerBtn = buttonPanel:Add("DButton")
    self.giveToPlayerBtn:Dock(LEFT)
    self.giveToPlayerBtn:SetWidth(120)
    self.giveToPlayerBtn:DockMargin(5, 5, 5, 5)
    self.giveToPlayerBtn:SetText("Give to Player")
    self.giveToPlayerBtn:SetEnabled(false)
    self.giveToPlayerBtn.DoClick = function()
        self:GiveToPlayer()
    end

    -- Copy ID button
    self.copyIdBtn = buttonPanel:Add("DButton")
    self.copyIdBtn:Dock(LEFT)
    self.copyIdBtn:SetWidth(100)
    self.copyIdBtn:DockMargin(5, 5, 5, 5)
    self.copyIdBtn:SetText("Copy ID")
    self.copyIdBtn:SetEnabled(false)
    self.copyIdBtn.DoClick = function()
        self:CopyUniqueID()
    end

    -- Amount input
    local amountLabel = buttonPanel:Add("DLabel")
    amountLabel:Dock(RIGHT)
    amountLabel:SetWidth(60)
    amountLabel:DockMargin(5, 5, 0, 5)
    amountLabel:SetText("Amount:")
    amountLabel:SetContentAlignment(6)

    self.amountEntry = buttonPanel:Add("DNumberWang")
    self.amountEntry:Dock(RIGHT)
    self.amountEntry:SetWidth(60)
    self.amountEntry:DockMargin(5, 5, 5, 5)
    self.amountEntry:SetValue(1)
    self.amountEntry:SetMin(1)
    self.amountEntry:SetMax(999)
end

function PANEL:PopulateItems()
    -- Clear existing items
    self.itemList:Clear()

    -- Clear category filter
    self.categoryFilter:Clear()
    self.categoryFilter:AddChoice("All Categories", "")

    -- Get all items and categories
    local items = {}
    local categories = {}

    for uniqueID, itemDef in pairs(ax.item.stored) do
        if ( itemDef.IsBase ) then continue end

        table.insert(items, {
            uniqueID = uniqueID,
            def = itemDef
        })

        local category = itemDef:GetCategory() or "Miscellaneous"
        if ( !categories[category] ) then
            categories[category] = true
            self.categoryFilter:AddChoice(category, category)
        end
    end

    -- Sort items by name
    table.sort(items, function(a, b)
        return a.def:GetName() < b.def:GetName()
    end)

    -- Store for filtering
    self.allItems = items

    -- Display items
    self:FilterItems()
end

function PANEL:FilterItems()
    if ( !self.allItems ) then return end

    self.itemList:Clear()

    local searchText = string.lower(self.searchBox:GetValue() or "")
    local selectedCategory = ""

    -- Get selected category properly
    local selectedID = self.categoryFilter:GetSelectedID()
    if ( selectedID ) then
        selectedCategory = self.categoryFilter:GetOptionTextByID(selectedID) or ""
    end

    for _, itemData in ipairs(self.allItems) do
        local itemDef = itemData.def
        local uniqueID = itemData.uniqueID

        -- Filter by search text
        if ( searchText != "" ) then
            local name = string.lower(itemDef:GetName())
            local id = string.lower(uniqueID)
            local description = string.lower(itemDef:GetDescription() or "")

            if ( !string.find(name, searchText, 1, true) and
                 !string.find(id, searchText, 1, true) and
                 !string.find(description, searchText, 1, true) ) then
                continue
            end
        end

        -- Filter by category
        if ( selectedCategory != "" and selectedCategory != "All Categories" ) then
            local itemCategory = itemDef:GetCategory() or "Miscellaneous"
            if ( itemCategory != selectedCategory ) then
                continue
            end
        end

        -- Create item entry
        self:CreateItemEntry(uniqueID, itemDef)
    end
end

function PANEL:CreateItemEntry(uniqueID, itemDef)
    local entry = self.itemList:Add("DPanel")
    entry:Dock(TOP)
    entry:SetHeight(60)
    entry:DockMargin(2, 2, 2, 2)

    local isSelected = self.selectedItem == uniqueID

    entry.Paint = function(this, w, h)
        local bgColor = Color(60, 60, 60, 100)
        if ( this:IsHovered() ) then
            bgColor = Color(80, 80, 80, 150)
        end
        if ( isSelected ) then
            bgColor = Color(100, 150, 200, 150)
        end
        draw.RoundedBox(4, 0, 0, w, h, bgColor)

        -- Draw border for selected
        if ( isSelected ) then
            draw.RoundedBox(4, 0, 0, w, h, Color(150, 200, 255, 50))
        end
    end

    -- Model icon
    local icon = entry:Add("DModelPanel")
    icon:Dock(LEFT)
    icon:SetWidth(50)
    icon:DockMargin(5, 5, 5, 5)
    icon:SetModel(itemDef:GetModel())
    icon:SetMouseInputEnabled(false)

    -- Position the camera for the model
    local entity = icon:GetEntity()
    if ( IsValid(entity) ) then
        local pos = entity:GetPos()
        local mins, maxs = entity:GetRenderBounds()
        local size = 0
        size = math.max(size, math.abs(mins.x) + math.abs(maxs.x))
        size = math.max(size, math.abs(mins.y) + math.abs(maxs.y))
        size = math.max(size, math.abs(mins.z) + math.abs(maxs.z))

        icon:SetCamPos(pos + Vector(size, size, size))
        icon:SetLookAt(pos)
        icon:SetFOV(45)
    end

    -- Item info
    local infoPanel = entry:Add("DPanel")
    infoPanel:Dock(FILL)
    infoPanel:DockMargin(5, 5, 5, 5)
    infoPanel.Paint = nil

    local nameLabel = infoPanel:Add("DLabel")
    nameLabel:Dock(TOP)
    nameLabel:SetFont("DermaDefaultBold")
    nameLabel:SetText(itemDef:GetName())
    nameLabel:SetTextColor(Color(255, 255, 255))
    nameLabel:SizeToContents()

    local idLabel = infoPanel:Add("DLabel")
    idLabel:Dock(TOP)
    idLabel:SetFont("DermaDefault")
    idLabel:SetText("ID: " .. uniqueID)
    idLabel:SetTextColor(Color(150, 150, 150))
    idLabel:SizeToContents()

    local categoryLabel = infoPanel:Add("DLabel")
    categoryLabel:Dock(TOP)
    categoryLabel:SetFont("DermaDefault")
    categoryLabel:SetText("Category: " .. itemDef:GetCategory())
    categoryLabel:SetTextColor(Color(150, 150, 150))
    categoryLabel:SizeToContents()

    -- Click to select
    entry.OnMousePressed = function(this, key)
        if ( key == MOUSE_LEFT ) then
            self:SelectItem(uniqueID, itemDef)
        end
    end

    -- Store reference
    entry.uniqueID = uniqueID
    entry.itemDef = itemDef
end

function PANEL:SelectItem(uniqueID, itemDef)
    self.selectedItem = uniqueID
    self.selectedItemDef = itemDef

    -- Update preview
    self:UpdatePreview(uniqueID, itemDef)

    -- Enable buttons
    self.spawnWorldBtn:SetEnabled(true)
    self.giveToSelfBtn:SetEnabled(true)
    self.giveToPlayerBtn:SetEnabled(true)
    self.copyIdBtn:SetEnabled(true)

    -- Update entry visuals
    for _, child in ipairs(self.itemList:GetChildren()) do
        if ( child.uniqueID ) then
            child:InvalidateLayout(true)
        end
    end
end

function PANEL:UpdatePreview(uniqueID, itemDef)
    self.previewContent:Clear()

    -- Hide no selection label
    self.noSelectionLabel:SetVisible(false)

    -- Item model preview
    local modelPreview = self.previewContent:Add("DModelPanel")
    modelPreview:Dock(TOP)
    modelPreview:SetHeight(200)
    modelPreview:DockMargin(5, 5, 5, 5)
    modelPreview:SetModel(itemDef:GetModel())

    local entity = modelPreview:GetEntity()
    if ( IsValid(entity) ) then
        local pos = entity:GetPos()
        local mins, maxs = entity:GetRenderBounds()
        local size = 0
        size = math.max(size, math.abs(mins.x) + math.abs(maxs.x))
        size = math.max(size, math.abs(mins.y) + math.abs(maxs.y))
        size = math.max(size, math.abs(mins.z) + math.abs(maxs.z))

        modelPreview:SetCamPos(pos + Vector(size * 1.5, size * 1.5, size * 1.5))
        modelPreview:SetLookAt(pos)
        modelPreview:SetFOV(45)
    end

    -- Item details
    local detailsPanel = self.previewContent:Add("DPanel")
    detailsPanel:Dock(FILL)
    detailsPanel:DockMargin(5, 5, 5, 5)
    detailsPanel.Paint = nil

    -- Name
    local nameLabel = detailsPanel:Add("DLabel")
    nameLabel:Dock(TOP)
    nameLabel:SetFont("DermaLarge")
    nameLabel:SetText(itemDef:GetName())
    nameLabel:SetTextColor(Color(255, 255, 255))
    nameLabel:SizeToContents()
    nameLabel:DockMargin(0, 0, 0, 5)

    -- Unique ID
    local idLabel = detailsPanel:Add("DLabel")
    idLabel:Dock(TOP)
    idLabel:SetFont("DermaDefaultBold")
    idLabel:SetText("Unique ID: " .. uniqueID)
    idLabel:SetTextColor(Color(200, 200, 200))
    idLabel:SizeToContents()
    idLabel:DockMargin(0, 0, 0, 5)

    -- Category
    local categoryLabel = detailsPanel:Add("DLabel")
    categoryLabel:Dock(TOP)
    categoryLabel:SetFont("DermaDefault")
    categoryLabel:SetText("Category: " .. itemDef:GetCategory())
    categoryLabel:SetTextColor(Color(150, 150, 150))
    categoryLabel:SizeToContents()
    categoryLabel:DockMargin(0, 0, 0, 5)

    -- Weight
    local weightLabel = detailsPanel:Add("DLabel")
    weightLabel:Dock(TOP)
    weightLabel:SetFont("DermaDefault")
    weightLabel:SetText("Weight: " .. itemDef:GetWeight() .. " kg")
    weightLabel:SetTextColor(Color(150, 150, 150))
    weightLabel:SizeToContents()
    weightLabel:DockMargin(0, 0, 0, 10)

    -- Description
    local descLabel = detailsPanel:Add("DLabel")
    descLabel:Dock(TOP)
    descLabel:SetFont("DermaDefaultBold")
    descLabel:SetText("Description:")
    descLabel:SetTextColor(Color(200, 200, 200))
    descLabel:SizeToContents()
    descLabel:DockMargin(0, 0, 0, 5)

    local description = itemDef:GetDescription() or "No description available."
    local descText = detailsPanel:Add("DLabel")
    descText:Dock(TOP)
    descText:SetFont("DermaDefault")
    descText:SetText(description)
    descText:SetTextColor(Color(255, 255, 255))
    descText:SetWrap(true)
    descText:SetAutoStretchVertical(true)
    descText:DockMargin(0, 0, 0, 10)

    -- Model path
    local modelLabel = detailsPanel:Add("DLabel")
    modelLabel:Dock(TOP)
    modelLabel:SetFont("DermaDefault")
    modelLabel:SetText("Model: " .. itemDef:GetModel())
    modelLabel:SetTextColor(Color(150, 150, 150))
    modelLabel:SizeToContents()
    modelLabel:DockMargin(0, 0, 0, 5)

    -- Material (if any)
    if ( itemDef:GetMaterial() and itemDef:GetMaterial() != "" ) then
        local materialLabel = detailsPanel:Add("DLabel")
        materialLabel:Dock(TOP)
        materialLabel:SetFont("DermaDefault")
        materialLabel:SetText("Material: " .. itemDef:GetMaterial())
        materialLabel:SetTextColor(Color(150, 150, 150))
        materialLabel:SizeToContents()
        materialLabel:DockMargin(0, 0, 0, 5)
    end
end

function PANEL:SpawnInWorld()
    if ( !self.selectedItem ) then return end

    local amount = self.amountEntry:GetValue()
    local uniqueID = self.selectedItem

    -- Send spawn command to server
    RunConsoleCommand("ax_item_spawn", uniqueID, tostring(amount))

    ax.client:Notify("Spawned " .. amount .. " " .. self.selectedItemDef:GetName() .. "(s) in the world.")
end

function PANEL:GiveToSelf()
    if ( !self.selectedItem ) then return end

    local amount = self.amountEntry:GetValue()
    local uniqueID = self.selectedItem

    -- Send give command to server
    RunConsoleCommand("ax_item_give", uniqueID, "", tostring(amount))

    ax.client:Notify("Gave " .. amount .. " " .. self.selectedItemDef:GetName() .. "(s) to yourself.")
end

function PANEL:GiveToPlayer()
    if ( !self.selectedItem ) then return end

    local amount = self.amountEntry:GetValue()
    local uniqueID = self.selectedItem

    -- Create player selection menu
    local playerMenu = DermaMenu()

    for _, ply in ipairs(player.GetAll()) do
        playerMenu:AddOption(ply:Name(), function()
            RunConsoleCommand("ax_item_give", uniqueID, ply:Name(), tostring(amount))
            ax.client:Notify("Gave " .. amount .. " " .. self.selectedItemDef:GetName() .. "(s) to " .. ply:Name() .. ".")
        end)
    end

    playerMenu:Open()
end

function PANEL:CopyUniqueID()
    if ( !self.selectedItem ) then return end

    SetClipboardText(self.selectedItem)
    ax.client:Notify("Copied unique ID to clipboard: " .. self.selectedItem)
end

function PANEL:OnKeyCodePressed(key)
    if ( key == KEY_ESCAPE ) then
        self:SetVisible(false)
        return true
    end

    return false
end

vgui.Register("ax.spawnmenu.items", PANEL, "DFrame")

-- Global function to open the item spawn menu
function ax.OpenItemSpawnMenu()
    if ( !CAMI.PlayerHasAccess(ax.client, "Parallax - Manage Items", nil) ) then
        ax.client:Notify("You don't have permission to use the item spawn menu!")
        return
    end

    if ( IsValid(ax.gui.itemSpawnMenu) ) then
        ax.gui.itemSpawnMenu:SetVisible(true)
        ax.gui.itemSpawnMenu:MakePopup()
    else
        ax.gui.itemSpawnMenu = vgui.Create("ax.spawnmenu.items")
    end
end

-- Console command to open the menu
concommand.Add("ax_item_menu", function()
    ax.OpenItemSpawnMenu()
end)

-- Add to spawnmenu if it exists
hook.Add("PopulateToolMenu", "ax.spawnmenu.items", function()
    spawnmenu.AddToolMenuOption("Utilities", "Parallax", "ItemSpawner", "Item Spawner", "", "", function(panel)
        panel:ClearControls()

        panel:Help("Parallax Item Spawner")
        panel:Help("Spawn items in the world or give them to players.")

        panel:Button("Open Item Spawner", "ax_item_menu")
    end)
end)
