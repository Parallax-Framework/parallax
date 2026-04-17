--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Item management system for creating, storing, and managing game items.
-- Supports item inheritance, base items, actions, and instance management.
-- Includes automatic loading from framework, schema, and module directories.
-- @module ax.item

ax.item = ax.item or {}
ax.item.stored = ax.item.stored or {}
ax.item.instances = ax.item.instances or {}
ax.item.actions = ax.item.actions or {}
ax.item.meta = ax.item.meta or {}

local function ShouldSkipItemFile(filePath, fileName, timeFilter, label)
    if ( !isnumber(timeFilter) or timeFilter <= 0 ) then
        return false
    end

    local fileTime = file.Time(filePath, "LUA")
    local currentTime = os.time()
    if ( fileTime and (currentTime - fileTime) > timeFilter ) then
        ax.util:PrintDebug("Skipping unchanged " .. label .. " (modified " .. (currentTime - fileTime) .. "s ago): " .. fileName)
        return true
    end

    return false
end

local function CreateItemDefinition(className, options)
    options = options or {}

    if ( istable(options.baseItem) ) then
        local baseItem = options.baseItem

        return setmetatable({
            class = className,
            base = options.baseName
        }, {
            __index = function(t, k)
                local value = rawget(t, k)
                if ( value != nil ) then return value end

                value = baseItem[k]
                if ( value != nil ) then return value end

                return ax.item.meta[k]
            end
        })
    end

    return setmetatable({
        class = className,
        isBase = options.isBase == true or nil
    }, ax.item.meta)
end

local function AddDefaultItemActions(itemTable)
    itemTable:AddAction("take", ax.item:CreateDefaultTakeAction())
    itemTable:AddAction("drop", ax.item:CreateDefaultDropAction())
end

local function RegisterLoadedItem(self, className, filePath, options)
    options = options or {}

    ITEM = CreateItemDefinition(className, options)
        if ( options.addDefaultActions != false ) then
            AddDefaultItemActions(ITEM)
        end

        ax.util:Include(filePath, "shared")

        local label = options.label or "Item"
        local annotation = options.annotation or ""
        ax.util:PrintDebug(string.format(
            "%s \"%s\"%s initialized successfully.",
            label,
            tostring(ITEM.name or className),
            annotation
        ))

        self.stored[className] = ITEM
    ITEM = nil
end

local function LoadItemDefinitionsFromDirectory(self, directory, timeFilter, options, buildDefinition)
    local files = file.Find(directory .. "/*.lua", "LUA")
    if ( !files or #files == 0 ) then
        if ( isstring(options.emptyMessagePrefix) and options.emptyMessagePrefix != "" ) then
            ax.util:PrintDebug(options.emptyMessagePrefix .. directory)
        end

        return false
    end

    for i = 1, #files do
        local fileName = files[i]
        local filePath = directory .. "/" .. fileName

        if ( ShouldSkipItemFile(filePath, fileName, timeFilter, options.skipLabel or "item file") ) then
            continue
        end

        local className, definitionOptions = buildDefinition(fileName, filePath)
        if ( isstring(className) and className != "" ) then
            RegisterLoadedItem(self, className, filePath, definitionOptions)
        end
    end

    return true
end

function ax.item:GetActionsForClass(class)
    if ( !isstring(class) or class == "" ) then return {} end

    local merged = {}
    local stored = self.stored[class]
    if ( istable(stored) and isstring(stored.base) and stored.base != "" ) then
        local baseActions = self:GetActionsForClass(stored.base)
        if ( istable(baseActions) ) then
            for k, v in pairs(baseActions) do
                merged[k] = v
            end
        end
    end

    local classActions = self.actions[class]
    if ( istable(classActions) ) then
        for k, v in pairs(classActions) do
            merged[k] = v
        end
    end

    return merged
end

function ax.item:Initialize()
    self:Include("parallax/gamemode/items")
    self:Include(engine.ActiveGamemode() .. "/gamemode/items")

    local _, modules = file.Find("parallax/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include("parallax/gamemode/modules/" .. modules[i] .. "/items")
    end

    self:RefreshItemInstances()
end

function ax.item:RefreshItemInstances()
    local refreshedCount = 0
    local errorCount = 0

    for instanceID, itemInstance in pairs(self.instances) do
        if ( istable(itemInstance) and itemInstance.class ) then
            local storedItem = self.stored[itemInstance.class]
            if ( istable(storedItem) ) then
                if ( rawget(itemInstance, "actions") ) then
                    itemInstance.actions = nil
                end

                setmetatable(itemInstance, {
                    __index = storedItem,
                    __tostring = storedItem.__tostring
                })

                refreshedCount = refreshedCount + 1
                ax.util:PrintDebug("Refreshed item instance ID " .. instanceID .. " (class: " .. itemInstance.class .. ")")
            else
                ax.util:PrintWarning("Item instance ID " .. instanceID .. " references unknown class: " .. tostring(itemInstance.class))
                errorCount = errorCount + 1
            end
        end
    end

    if ( refreshedCount > 0 ) then
        ax.util:PrintDebug("Refreshed " .. refreshedCount .. " item instances with updated definitions")
    end

    if ( errorCount > 0 ) then
        ax.util:PrintWarning("Failed to refresh " .. errorCount .. " item instances due to missing definitions")
    end

    if ( refreshedCount == 0 and errorCount == 0 ) then
        ax.util:PrintDebug("No item instances found to refresh")
    end
end

function ax.item:Include(path, timeFilter)
    self:LoadBasesFromDirectory(path .. "/base", timeFilter)
    self:LoadItemsFromDirectory(path, timeFilter)
    self:LoadItemsWithInheritance(path, timeFilter)

    pcall(function()
        self:RefreshItemInstances()
    end)
end

function ax.item:CreateDefaultDropAction()
    return {
        name = "Drop",
        icon = "parallax/icons/caret-down-circle.png",
        order = 1000,
        CanUse = function(action, client, item)
            return true
        end,
        OnRun = function(action, client, item)
            local inventoryID = 0
            for _, character in pairs(ax.character.instances) do
                if ( character:GetInventoryID() == item:GetInventoryID() ) then
                    inventoryID = character:GetInventoryID()
                    break
                end
            end

            if ( !inventoryID or inventoryID <= 0 ) then
                client:Notify("You cannot drop this item right now!")
                return false
            end

            local transferSuccess, transferReason = ax.item:Transfer(item, inventoryID, 0, function(asyncSuccess, asyncReason)
                if ( asyncSuccess ) then
                    ax.util:PrintDebug(color_success, string.format(
                        "Player %s dropped item %s from inventory %s to world inventory.",
                        tostring(client),
                        tostring(item.id),
                        tostring(inventoryID)
                    ))
                else
                    ax.util:PrintWarning(string.format(
                        "Player %s failed to drop item %s from inventory %s to world inventory, due to %s.",
                        tostring(client),
                        tostring(item.id),
                        tostring(inventoryID),
                        tostring(asyncReason or "Unknown Reason")
                    ))
                end
            end)

            if ( transferSuccess == false ) then
                client:Notify(string.format("Failed to drop item: %s", transferReason or "Unknown Reason"))
            end

            return false
        end
    }
end

function ax.item:CreateDefaultTakeAction()
    return {
        name = "Take",
        icon = "parallax/icons/hand-up.png",
        order = 0,
        CanUse = function(action, client, item, context)
            if ( !ax.util:IsValidPlayer(client) ) then
                return false, "Invalid player."
            end

            local inventoryID = item:GetInventoryID()
            if ( inventoryID == nil and istable(context) and IsValid(context.entity) ) then
                inventoryID = 0
            end

            if ( inventoryID != 0 ) then
                return false, "This item is not in the world."
            end

            local entity = istable(context) and context.entity or nil
            if ( !IsValid(entity) or entity:GetClass() != "ax_item" or entity:GetItemID() != item:GetID() ) then
                return false, "You cannot pick up this item right now."
            end

            if ( entity:GetTable().axTakeInProgress ) then
                return false, "This item is already being picked up."
            end

            local character = client:GetCharacter()
            if ( !istable(character) ) then
                return false, "You need an active character to pick this up."
            end

            local inventory = character:GetInventory()
            if ( !istable(inventory) ) then
                return false, "You do not have a valid inventory."
            end

            if ( math.Round(inventory:GetWeight() + item:GetWeight(), 2) > inventory:GetMaxWeight() ) then
                return false, "Your inventory cannot hold this item."
            end

            return true
        end,
        OnRun = function(action, client, item, context)
            local entity = context.entity or nil
            local character = client:GetCharacter()
            local inventory = character:GetInventory()
            entity:GetTable().axTakeInProgress = true

            local transferOk, transferReason = ax.item:Transfer(item, 0, inventory, function(didTransfer, asyncReason)
                if ( didTransfer ) then
                    ax.util:PrintDebug(color_success, string.format(
                        "Player %s picked up item %s from world inventory to inventory %s.",
                        tostring(client),
                        tostring(item.id),
                        tostring(inventory.id)
                    ))

                    if ( IsValid(entity) ) then
                        hook.Run("OnPlayerItemTake", client, entity, item)
                        SafeRemoveEntity(entity)
                    else
                        hook.Run("OnPlayerItemTake", client, nil, item)
                    end
                else
                    ax.util:PrintWarning(string.format(
                        "Player %s failed to pick up item %s from world inventory to inventory %s, due to %s.",
                        tostring(client),
                        tostring(item.id),
                        tostring(inventory.id),
                        tostring(asyncReason or "Unknown Reason")
                    ))

                    if ( IsValid(entity) ) then
                        entity:GetTable().axTakeInProgress = nil
                    end
                end
            end)

            if ( transferOk == false ) then
                entity:GetTable().axTakeInProgress = nil
                client:Notify(transferReason or "You cannot pick up this item.")
            end

            return false
        end
    }
end

function ax.item:LoadBasesFromDirectory(basePath, timeFilter)
    return LoadItemDefinitionsFromDirectory(self, basePath, timeFilter, {
        emptyMessagePrefix = "No base items found in ",
        skipLabel = "item base file"
    }, function(fileName)
        return self:ExtractItemName(fileName), {
            isBase = true,
            addDefaultActions = true,
            label = "Item base"
        }
    end)
end

function ax.item:LoadItemsFromDirectory(path, timeFilter, prefix)
    return LoadItemDefinitionsFromDirectory(self, path, timeFilter, {
        skipLabel = "item file"
    }, function(fileName)
        local itemName = self:ExtractItemName(fileName)
        if ( isstring(prefix) and prefix != "" ) then
            itemName = prefix .. itemName
        end

        return itemName, {
            addDefaultActions = true,
            label = "Item"
        }
    end)
end

function ax.item:LoadItemsWithInheritance(path, timeFilter)
    local _, directories = file.Find(path .. "/*", "LUA")
    if ( !directories or #directories == 0 ) then
        return
    end

    for i = 1, #directories do
        local dirName = directories[i]
        if ( dirName == "base" ) then continue end

        local baseItem = self.stored[dirName]
        if ( !istable(baseItem) or !baseItem.isBase ) then
            self:LoadItemsFromDirectory(path .. "/" .. dirName, timeFilter, dirName .. "_")
            continue
        end

        self:LoadItemsWithBase(path .. "/" .. dirName, dirName, baseItem, timeFilter)
    end
end

function ax.item:LoadItemsWithBase(dirPath, baseName, baseItem, timeFilter)
    return LoadItemDefinitionsFromDirectory(self, dirPath, timeFilter, {
        skipLabel = "item file"
    }, function(fileName)
        local fullItemName = baseName .. "_" .. self:ExtractItemName(fileName)

        return fullItemName, {
            baseName = baseName,
            baseItem = baseItem,
            addDefaultActions = false,
            label = "Item",
            annotation = " (base: " .. baseName .. ")"
        }
    end)
end

function ax.item:ExtractItemName(fileName)
    local itemName = string.StripExtension(fileName)
    local prefix = string.sub(itemName, 1, 3)
    if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
        itemName = string.sub(itemName, 4)
    end

    return itemName
end

--- Registers an item definition programmatically without requiring a file.
-- @realm shared
-- @param className string The unique class identifier for the item
-- @param baseName string|nil The base item class to inherit from
-- @param bIsBase boolean Whether this item is a base item
-- @param bAddDefaultActions boolean Whether to add default take/drop actions (default true)
-- @return table The item definition table, or nil on failure
function ax.item:Register(className, baseName, bIsBase, bAddDefaultActions)
    if ( !isstring(className) or className == "" ) then
        ErrorNoHalt("[ax.item] Register called with invalid className\n")
        return nil
    end

    local itemTable = ax.item:Get(className)
    if ( !istable(itemTable) or rawget(itemTable, "isBase") == true ) then
        if ( isstring(baseName) and baseName != "" ) then
            local baseItem = ax.item.stored[baseName]
            if ( istable(baseItem) ) then
                itemTable = setmetatable({ class = className, base = baseName }, {
                    __index = function(t, k)
                        local value = rawget(t, k)
                        if ( value != nil ) then return value end

                        value = baseItem[k]
                        if ( value != nil ) then return value end

                        return ax.item.meta[k]
                    end
                })
            else
                ErrorNoHalt(string.format("[ax.item] Register: base item \"%s\" not found for class \"%s\"\n", baseName, className))
                itemTable = setmetatable({ class = className }, ax.item.meta)
            end
        else
            itemTable = setmetatable({ class = className, isBase = bIsBase == true or nil }, ax.item.meta)
        end
    end

    if ( bAddDefaultActions != false ) then
        itemTable:AddAction("take", ax.item:CreateDefaultTakeAction())
        itemTable:AddAction("drop", ax.item:CreateDefaultDropAction())
    end

    ax.item.stored[className] = itemTable

    ax.util:PrintDebug(string.format("Item \"%s\" registered programmatically.", tostring(itemTable.name or className)))

    return itemTable
end

function ax.item:Get(identifier)
    if ( isstring(identifier) ) then
        return self.stored[identifier]
    elseif ( isnumber(identifier) ) then
        return self.instances[identifier]
    end

    return nil
end

function ax.item:FindByIdentifier(identifier)
    if ( !isstring(identifier) ) then
        return nil, "Invalid item identifier"
    end

    identifier = string.Trim(identifier)
    if ( identifier == "" ) then
        return nil, "Invalid item identifier"
    end

    local exact = self:Get(identifier)
    if ( istable(exact) and rawget(exact, "isBase") != true ) then
        return exact.class, exact
    end

    local lower = ( utf8 and utf8.lower ) or string.lower
    local loweredIdentifier = lower(identifier)

    for class, item in pairs(self.stored) do
        if ( !istable(item) or rawget(item, "isBase") == true ) then continue end

        if ( lower(class) == loweredIdentifier ) then
            return class, item
        end
    end

    for class, item in pairs(self.stored) do
        if ( !istable(item) or rawget(item, "isBase") == true ) then continue end

        local itemName = item.name or class
        if ( isstring(itemName) and lower(itemName) == loweredIdentifier ) then
            return class, item
        end
    end

    local matches = {}
    for class, item in pairs(self.stored) do
        if ( !istable(item) or rawget(item, "isBase") == true ) then continue end

        local itemName = item.name or class
        if ( ax.util:FindString(class, identifier) or ( isstring(itemName) and ax.util:FindString(itemName, identifier) ) ) then
            matches[#matches + 1] = {
                class = class,
                item = item
            }
        end
    end

    if ( #matches == 1 ) then
        return matches[1].class, matches[1].item
    elseif ( #matches > 1 ) then
        return nil, "Multiple items matched that identifier"
    end

    return nil, "Item not found"
end

function ax.item:Instance(id, class)
    if ( !isnumber(id) or id == 0 ) then
        return nil
    end

    if ( !isstring(class) or class == "" ) then
        return nil
    end

    local item = self.stored[class]
    if ( !istable(item) ) then
        return nil
    end

    if ( self.instances[id] and self.instances[id].class == class ) then
        return self.instances[id]
    end

    local itemObject = setmetatable({
        id = id,
        class = class
    }, {
        __index = item,
        __tostring = item.__tostring
    })

    self.instances[id] = itemObject

    return itemObject
end

if ( CLIENT ) then
    function ax.item:HasContentIconMaterial(materialPath)
        if ( !isstring(materialPath) or materialPath == "" ) then
            return false
        end

        self.contentIconMaterialCache = self.contentIconMaterialCache or {}
        if ( self.contentIconMaterialCache[materialPath] != nil ) then
            return self.contentIconMaterialCache[materialPath]
        end

        local material = Material(materialPath)
        local isValid = material != nil and !material:IsError()

        if ( !isValid ) then
            local fallbackPath = string.Replace(materialPath, "entities/", "VGUI/entities/")
            fallbackPath = string.Replace(fallbackPath, ".png", "")

            local fallbackMaterial = Material(fallbackPath)
            isValid = fallbackMaterial != nil and !fallbackMaterial:IsError()
        end

        self.contentIconMaterialCache[materialPath] = isValid

        return isValid
    end

    function ax.item:GetSpawnIconBodygroupString(itemTable)
        local bodygroups = istable(itemTable) and isfunction(itemTable.GetBodygroups) and itemTable:GetBodygroups() or nil
        if ( !istable(bodygroups) ) then
            return "000000000"
        end

        local digits = {"0", "0", "0", "0", "0", "0", "0", "0", "0"}
        for groupID, value in pairs(bodygroups) do
            local numericIndex = tonumber(groupID)
            if ( numericIndex == nil ) then
                continue
            end

            numericIndex = math.floor(numericIndex)
            if ( numericIndex < 0 or numericIndex >= #digits ) then
                continue
            end

            digits[numericIndex + 1] = tostring(math.Clamp(math.floor(tonumber(value) or 0), 0, 9))
        end

        return table.concat(digits)
    end

    function ax.item:NeedsSpawnIconRebuild(itemTable)
        if ( !istable(itemTable) or !isfunction(itemTable.HasAppearanceOverrides) ) then
            return false
        end

        if ( !itemTable:HasAppearanceOverrides() ) then
            return false
        end

        if ( isfunction(itemTable.GetMaterial) and itemTable:GetMaterial() != "" ) then
            return true
        end

        if ( isfunction(itemTable.GetColor) ) then
            local color = itemTable:GetColor()
            if ( color.r != 255 or color.g != 255 or color.b != 255 or color.a != 255 ) then
                return true
            end
        end

        local bodygroups = isfunction(itemTable.GetBodygroups) and itemTable:GetBodygroups() or nil
        if ( istable(bodygroups) ) then
            for groupID in pairs(bodygroups) do
                if ( tonumber(groupID) == nil ) then
                    return true
                end
            end
        end

        return false
    end

    function ax.item:ApplyAppearanceToIcon(itemTable, icon, model)
        if ( !istable(itemTable) or !IsValid(icon) ) then
            return false
        end

        if ( !isfunction(icon.SetModel) ) then
            return false
        end

        model = model or (isfunction(itemTable.GetModel) and itemTable:GetModel()) or "models/props_junk/wood_crate001a.mdl"
        icon:SetModel(model, itemTable.GetSkin and itemTable:GetSkin() or 0, self:GetSpawnIconBodygroupString(itemTable))

        return true
    end

    function ax.item:ApplyAppearanceToModelPanel(itemTable, panel, model)
        if ( !istable(itemTable) or !IsValid(panel) ) then
            return false
        end

        if ( !isfunction(panel.SetModel) or !isfunction(panel.GetEntity) ) then
            return false
        end

        model = model or (isfunction(itemTable.GetModel) and itemTable:GetModel()) or "models/props_junk/wood_crate001a.mdl"
        panel:SetModel(model)

        local entity = panel:GetEntity()
        if ( !IsValid(entity) ) then
            return false
        end

        entity:SetIK(false)

        if ( isfunction(itemTable.ApplyAppearance) ) then
            itemTable:ApplyAppearance(entity)
        end

        local color = isfunction(itemTable.GetColor) and itemTable:GetColor() or color_white
        local mins, maxs = entity:GetRenderBounds()
        local center = (mins + maxs) * 0.5
        local extents = maxs - mins
        local radius = math.max(extents.x, extents.y, extents.z, 1)

        panel:SetAmbientLight(Color(255, 255, 255))
        panel:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))
        panel:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
        panel:SetColor(color)
        panel:SetFOV(35)
        panel:SetCamPos(center + Vector(radius * 1.6, radius * 1.6, radius * 0.8))
        panel:SetLookAt(center)
        panel.LayoutEntity = function(this, previewEntity)
            previewEntity:SetAngles(Angle(0, 35, 0))
        end

        return true
    end
end
