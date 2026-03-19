--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

language.Add("spawnmenu.category.items", "Items")

hook.Add("PopulateItems", "AddItemContent", function(pnlContent, tree, browseNode)
    local Categorised = {}

    local ItemList = ax.item.stored
    if ( ItemList ) then
        for k, v in pairs(ItemList) do
            -- Use rawget to check only the item's own isBase property, not inherited from base
            if ( rawget(v, "isBase") == true ) then continue end

            if ( !v.model ) then continue end

            local Category = language.GetPhrase(v.category or "#spawnmenu.category.other")
            if ( !isstring(Category) ) then Category = tostring(Category) end

            Categorised[Category] = Categorised[Category] or {}

            table.insert(Categorised[Category], v)
        end
    end

    local CustomIcons = list.Get("ContentCategoryIcons")
    for CategoryName, v in SortedPairs(Categorised) do
        local node = tree:AddNode(CategoryName, CustomIcons[CategoryName] or "icon16/box.png")

        node.DoPopulate = function(self)
            if ( self.PropPanel ) then return end

            self.PropPanel = vgui.Create("ContentContainer", pnlContent)
            self.PropPanel:SetVisible(false)
            self.PropPanel:SetTriggerSpawnlistChange(false)

            for k, item in SortedPairsByMemberValue(v, "name") do
                spawnmenu.CreateContentIcon("axitem", self.PropPanel, {
                    nicename = item.name or item.class,
                    spawnname = item.class,
                    material = "entities/" .. item.class .. ".png",
                    admin = true
                })
            end
        end

        node.DoClick = function(self)
            self:DoPopulate()
            pnlContent:SwitchPanel(self.PropPanel)
        end
    end

    local FirstNode = tree:Root():GetChildNode(0)
    if ( IsValid(FirstNode) ) then
        FirstNode:InternalDoClick()
    end
end)

spawnmenu.AddCreationTab("#spawnmenu.category.items", function()
    local ctrl = vgui.Create("SpawnmenuContentPanel")
    ctrl:EnableSearch("items", "PopulateItems")
    ctrl:CallPopulateHook("PopulateItems")

    return ctrl
end, "icon16/box.png", 30)

spawnmenu.AddContentType("axitem", function(container, obj)
    if ( !obj.spawnname ) then return end

    local itemTable = ax.item.stored[obj.spawnname]
    local materialPath = obj.material or "entities/" .. obj.spawnname .. ".png"
    local useModelPreview = !ax.item:HasContentIconMaterial(materialPath)
    if ( istable(itemTable) and isfunction(itemTable.HasAppearanceOverrides) ) then
        useModelPreview = useModelPreview or itemTable:HasAppearanceOverrides()
    end

    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("axitem")
    icon:SetSpawnName(obj.spawnname)
    icon:SetName(obj.nicename or obj.spawnname)
    if ( useModelPreview ) then
        icon.m_MaterialName = materialPath
    else
        icon:SetMaterial(materialPath)
    end
    icon:SetAdminOnly(obj.admin or false)
    icon:SetColor(Color(255, 255, 255, 255))

    icon.DoClick = function(self)
        ax.net:Start("spawnmenu.spawn.item", obj.spawnname)

        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.OpenMenu = function(self)
        local menu = DermaMenu()

        menu:AddOption("Copy to Clipboard", function()
            SetClipboardText(obj.spawnname)
        end):SetIcon("icon16/page_copy.png")

        menu:AddOption("Give to Self", function()
            ax.command:Run("/CharGiveItem", ax.client:SteamID64(), obj.spawnname)
        end):SetIcon("icon16/brick_go.png")

        menu:Open()
    end

    icon.PaintOver = icon.Paint
    icon.Paint = nil

    local model = "models/props_junk/garbage_metalcan001a.mdl"
    if ( istable(itemTable) and isfunction(itemTable.GetModel) ) then
        model = itemTable:GetModel()
    elseif ( istable(itemTable) and itemTable.model ) then
        model = itemTable.model
    end

    local size = icon:GetTall() / 1.25

    local useModelPanel = useModelPreview or (istable(itemTable) and ax.item:NeedsSpawnIconRebuild(itemTable))
    local preview = icon:Add(useModelPanel and "DModelPanel" or "SpawnIcon")
    preview:SetSize(size, size)
    preview:Center()
    preview:SetMouseInputEnabled(false)
    preview:SetZPos(1)

    if ( useModelPanel ) then
        ax.item:ApplyAppearanceToModelPanel(itemTable, preview, model)
    else
        ax.item:ApplyAppearanceToIcon(itemTable, preview, model)
    end

    preview:SetVisible(useModelPreview)

    if ( IsValid(container) ) then
        container:Add(icon)
    end

    return icon
end)
