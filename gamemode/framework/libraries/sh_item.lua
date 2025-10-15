--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.item = ax.item or {}
ax.item.stored = ax.item.stored or {}
ax.item.instances = ax.item.instances or {}
ax.item.meta = ax.item.meta or {}

function ax.item:Initialize()
    self:Include("parallax/gamemode/items")
    self:Include(engine.ActiveGamemode() .. "/gamemode/items")

    -- Look through modules for items
    local _, modules = file.Find("parallax/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include("parallax/gamemode/modules/" .. modules[i] .. "/items")
    end

    -- Refresh item instances to update any changes made to item definitions
    self:RefreshItemInstances()
end

-- Refresh all existing item instances to reflect updated item definitions
function ax.item:RefreshItemInstances()
    local refreshedCount = 0
    local errorCount = 0

    for instanceID, itemInstance in pairs(self.instances) do
        if ( istable(itemInstance) and itemInstance.class ) then
            local storedItem = self.stored[itemInstance.class]
            if ( istable(storedItem) ) then
                -- Update the metatable to point to the refreshed stored item
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
        ax.util:PrintSuccess("Refreshed " .. refreshedCount .. " item instances with updated definitions")
    end

    if ( errorCount > 0 ) then
        ax.util:PrintWarning("Failed to refresh " .. errorCount .. " item instances due to missing definitions")
    end

    if ( refreshedCount == 0 and errorCount == 0 ) then
        ax.util:PrintDebug("No item instances found to refresh")
    end
end

function ax.item:Include(path)
    -- Load in three passes: bases first, then regular items, then directory-based items with inheritance
    self:LoadBasesFromDirectory(path .. "/base")
    self:LoadItemsFromDirectory(path)
    self:LoadItemsWithInheritance(path)
end

-- Helper function to create default drop action for items
local success, reason -- No idea why glualint is being weird about this
function ax.item:CreateDefaultDropAction()
    return {
        name = "Drop",
        icon = "icon16/arrow_down.png",
        order = 1,
        CanUse = function(this, client)
            return true
        end,
        OnRun = function(action, item, client)
            local inventoryID = 0
            for k, v in pairs(ax.character.instances) do
                if ( v:GetInventoryID() == item:GetInventoryID() ) then
                    inventoryID = v:GetInventoryID()
                    break
                end
            end

            if ( !inventoryID or inventoryID <= 0 ) then
                client:Notify("You cannot drop this item right now!")
                return false
            end

            success, reason = ax.item:Transfer(item, inventoryID, 0, function(_)
                if ( success ) then
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
                        tostring(reason or "Unknown Reason")
                    ))
                end
            end)

            if ( success == false ) then
                client:Notify(string.format("Failed to drop item: %s", reason or "Unknown Reason"))
            end

            return false
        end
    }
end

-- First pass: Load base items from base/ directory
function ax.item:LoadBasesFromDirectory(basePath)
    local baseFiles, _ = file.Find(basePath .. "/*.lua", "LUA")
    if ( !baseFiles or #baseFiles == 0 ) then
        ax.util:PrintDebug("No base items found in " .. basePath)
        return
    end

    for i = 1, #baseFiles do
        local fileName = baseFiles[i]
        local itemName = self:ExtractItemName(fileName)

        ITEM = setmetatable({ class = itemName, isBase = true }, ax.item.meta)
            ITEM:AddAction("drop", self:CreateDefaultDropAction())
            ax.util:Include(basePath .. "/" .. fileName, "shared")
            ax.util:PrintSuccess("Item base \"" .. tostring(ITEM.name or itemName) .. "\" initialized successfully.")
            ax.item.stored[itemName] = ITEM
        ITEM = nil
    end
end

-- Second pass: Load regular items from root directory
function ax.item:LoadItemsFromDirectory(path)
    local files, _ = file.Find(path .. "/*.lua", "LUA")
    if ( !files or #files == 0 ) then
        return
    end

    for i = 1, #files do
        local fileName = files[i]
        local itemName = self:ExtractItemName(fileName)

        ITEM = setmetatable({ class = itemName }, ax.item.meta)
            ITEM:AddAction("drop", self:CreateDefaultDropAction())
            ax.util:Include(path .. "/" .. fileName, "shared")
            ax.util:PrintSuccess("Item \"" .. tostring(ITEM.name or itemName) .. "\" initialized successfully.")
            ax.item.stored[itemName] = ITEM
        ITEM = nil
    end
end

-- Third pass: Load items from subdirectories that correspond to base items
function ax.item:LoadItemsWithInheritance(path)
    local _, directories = file.Find(path .. "/*", "LUA")
    if ( !directories or #directories == 0 ) then
        return
    end

    for i = 1, #directories do
        local dirName = directories[i]

        -- Skip the base directory as it's already processed
        if ( dirName == "base" ) then continue end

        -- Check if there's a corresponding base item
        local baseItem = ax.item.stored[dirName]
        if ( !istable(baseItem) or !baseItem.isBase ) then
            -- No base found, treat as regular directory recursion
            self:LoadItemsFromDirectory(path .. "/" .. dirName)
            continue
        end

        -- Load items in this directory with the base item as parent
        self:LoadItemsWithBase(path .. "/" .. dirName, dirName, baseItem)
    end
end

-- Load items from a directory with a specific base item inheritance
function ax.item:LoadItemsWithBase(dirPath, baseName, baseItem)
    local subFiles, _ = file.Find(dirPath .. "/*.lua", "LUA")
    if ( !subFiles or #subFiles == 0 ) then
        return
    end

    for j = 1, #subFiles do
        local fileName = subFiles[j]
        local itemName = self:ExtractItemName(fileName)

        -- Create item with base item inheritance
        ITEM = setmetatable({ class = itemName, base = baseName }, {
            __index = function(t, k)
                -- First check the item itself
                local val = rawget(t, k)
                if ( val != nil ) then return val end

                -- Then check the base item
                if ( baseItem[k] != nil ) then return baseItem[k] end

                -- Finally check the item meta
                return ax.item.meta[k]
            end
        })

        ax.util:Include(dirPath .. "/" .. fileName, "shared")
        ax.util:PrintSuccess("Item \"" .. tostring(ITEM.name or itemName) .. "\" (base: " .. baseName .. ") initialized successfully.")
        ax.item.stored[itemName] = ITEM
        ITEM = nil
    end
end

-- Helper function to extract clean item name from filename
function ax.item:ExtractItemName(fileName)
    local itemName = string.StripExtension(fileName)
    local prefix = string.sub(itemName, 1, 3)
    if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
        itemName = string.sub(itemName, 4)
    end

    return itemName
end

function ax.item:Get(identifier)
    if ( isstring(identifier) ) then
        return self.stored[identifier]
    elseif ( isnumber(identifier) ) then
        return self.instances[identifier]
    end

    return nil
end

function ax.item:Instance(id, class)
    if ( !isnumber(id) or id <= 0 ) then
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

if ( SERVER ) then
    function ax.item:Transfer(item, fromInventory, toInventory, callback)
        if ( !istable(item) ) then
            return false, "Invalid item provided."
        end

        ax.util:PrintDebug(string.format("Transferring item %s from inventory %s to inventory %s", item.id, tostring(fromInventory), tostring(toInventory)))

        local fromInventoryID = 0
        if ( istable(fromInventory) ) then
            fromInventoryID = fromInventory.id
        elseif ( isnumber(fromInventory) and fromInventory > 0 ) then
            fromInventoryID = fromInventory
            fromInventory = ax.inventory.instances[fromInventoryID]

            if ( !istable(fromInventory) ) then
                return false, "From inventory with ID " .. fromInventoryID .. " does not exist."
            end
        end

        local toInventoryID = 0
        if ( istable(toInventory) ) then
            toInventoryID = toInventory.id
        elseif ( isnumber(toInventory) and toInventory > 0 ) then
            toInventoryID = toInventory
            toInventory = ax.inventory.instances[toInventoryID]

            if ( !istable(toInventory) ) then
                return false, "To inventory with ID " .. toInventoryID .. " does not exist."
            end
        end

        if ( fromInventory == toInventory ) then
            return false, "Source and destination inventories cannot be the same."
        end

        -- TODO: Turn this check into a hook so inventories can have custom rules in terms of what they can accept. That way we can also handle weight checks there too.
        if ( toInventory != 0 and toInventory:GetWeight() + item:GetWeight() > toInventory:GetMaxWeight() ) then
            return false, "The destination inventory cannot hold this item."
        end

        if ( istable(fromInventory) ) then
            fromInventoryID = fromInventory.id
        elseif ( fromInventory == 0 or fromInventory == nil ) then
            fromInventoryID = 0
        end

        local dropPos
        if ( fromInventoryID != 0 and toInventoryID == 0 ) then
            local owner = fromInventory:GetOwner()
            if ( istable(owner) and IsValid(owner:GetOwner()) ) then
                local trace = {}
                trace.start = owner:GetOwner():GetShootPos()
                trace.endpos = trace.start + (owner:GetOwner():GetAimVector() * 96)
                trace.filter = owner:GetOwner()
                trace = util.TraceLine(trace)

                dropPos = trace.HitPos + trace.HitNormal * 16
            end

            if ( !isvector(dropPos) ) then
                return false, "Failed to determine drop position."
            end
        end

        local query = mysql:Update("ax_items")
            query:Update("inventory_id", toInventoryID)
            query:Where("id", item.id)
            query:Callback(function(result, status)
                if ( result == false ) then
                    ax.util:PrintError("Failed to update item in database during transfer.")
                    return false, "A database error occurred."
                end

                if ( istable(toInventory) and toInventoryID != 0 ) then
                    toInventory.items[item.id] = item
                    item.inventoryID = toInventoryID  -- Update the item's inventory reference
                elseif ( toInventoryID == 0 ) then
                    item.inventoryID = 0  -- Item is now in world inventory
                end

                if ( fromInventory != 0 ) then
                    fromInventory.items[item.id] = nil
                end

                ax.util:PrintDebug(string.format("Transferred item %s from inventory %s to inventory %s", item.id, tostring(fromInventoryID), tostring(toInventoryID)))

                net.Start("ax.item.transfer")
                    net.WriteUInt(item.id, 32)
                    net.WriteUInt(fromInventoryID, 32)
                    net.WriteUInt(toInventoryID, 32)
                if ( toInventoryID == 0 ) then
                    net.Broadcast()

                    local itemEntity = ents.Create("ax_item")
                    if ( !IsValid(itemEntity) ) then
                        ax.util:PrintError("Failed to create item entity during transfer to world inventory.")
                        return false, "Failed to create item entity."
                    end

                    itemEntity:SetRelay("itemID", item.id)
                    itemEntity:SetRelay("itemClass", item.class)
                    itemEntity:SetPos(dropPos or vector_origin)
                    itemEntity:Spawn()
                    itemEntity:Activate()

                    ax.util:PrintDebug("Broadcasting to all clients (world inventory)")
                else
                    net.Send(toInventory:GetReceivers())

                    ax.util:PrintDebug("Sending to inventory receivers only")
                    for k, v in pairs(toInventory:GetReceivers()) do
                        ax.util:PrintDebug(" - Sent to: " .. tostring(v))
                    end
                end

                if ( isfunction(callback) ) then
                    callback(true)
                end

                return true
            end)
        query:Execute()

        return true
    end

    function ax.item:Spawn(class, pos, ang, callback, data)
        local item = ax.item.stored[class]
        if ( !istable(item) ) then
            ax.util:PrintError("Invalid item provided to ax.item:Spawn() (" .. tostring(class) .. ")")
            return false
        end

        data = data or {}

        local query = mysql:Insert("ax_items")
            query:Insert("class", class)
            query:Insert("inventory_id", 0)
            query:Insert("data", util.TableToJSON(data))
            query:Callback(function(result, status, lastID)
                if ( result == false ) then
                    ax.util:PrintError("Failed to insert item into database for world spawn.")
                    return false
                end

                local itemObject = ax.item:Instance(lastID, class)

                local entity = ents.Create("ax_item")
                entity:SetRelay("itemID", lastID)
                entity:SetRelay("itemClass", class)
                entity:SetPos(pos)
                entity:SetAngles(ang)
                entity:Spawn()
                entity:Activate()

                net.Start("ax.item.spawn")
                    net.WriteUInt(lastID, 32)
                    net.WriteString(class)
                    net.WriteTable(data or {})
                net.Broadcast()

                if ( isfunction(callback) ) then
                    callback(entity, itemObject)
                end

                return true
            end)
        query:Execute()
    end
end

-- TODO: Turn these into chat commands? Idk
concommand.Add("ax_item_create", function(client, command, args, argStr)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command!")
        return
    end

    local class = args[1]
    local inventoryID = tonumber(args[2]) or 0

    if ( !class or class == "" ) then
        ax.util:PrintError("You must provide an item class.")

        ax.util:Print(Color(0, 255, 0), "Available item classes:")
        for k, v in pairs(ax.item.stored) do
            ax.util:Print(Color(0, 255, 0), "- " .. k)
        end

        return
    end

    if ( inventoryID <= 0 ) then
        ax.util:PrintError("You must provide a valid inventory ID.")

        ax.util:Print(Color(0, 255, 0), "Available inventory IDs:")
        for k, v in pairs(ax.inventory.instances) do
            ax.util:Print(Color(0, 255, 0), "- " .. k)
        end

        return
    end

    local inventory = ax.inventory.instances[inventoryID]
    if ( !istable(inventory) ) then
        ax.util:PrintError("Inventory with ID " .. inventoryID .. " does not exist.")
        return
    end

    local item = ax.item.stored[class]
    if ( !istable(item) ) then
        ax.util:PrintError("Item with class " .. class .. " does not exist.")
        return
    end

    inventory:AddItem(class)
end)

concommand.Add("ax_item_list", function(client, command, args, argStr)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command!")
        return
    end

    ax.util:Print(Color(0, 255, 0), "Available item classes:")
    for k, v in pairs(ax.item.stored) do
        ax.util:Print(Color(0, 255, 0), "- " .. k)
    end
end)

concommand.Add("ax_item_spawn", function(client, command, args, argStr)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command!")
        return
    end

    if ( CLIENT ) then return end

    local class = args[1]
    if ( !class or class == "" ) then
        ax.util:PrintError("You must provide an item class.")
        return
    end

    local trace = client:GetEyeTrace()
    local pos = trace.HitPos + trace.HitNormal * 16
    local ang = trace.HitNormal:Angle()

    ax.item:Spawn(class, pos, ang)
end)
