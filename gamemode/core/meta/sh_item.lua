--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- NOTE! InventoryID should always be updated when the item is moved to a: different inventory or dropped in the world.

local ITEM = ax.item.meta or {}
ITEM.__index = ITEM
ITEM.Category = ITEM.Category or "Miscellaneous"
ITEM.Data = ITEM.Data or {}
ITEM.Description = ITEM.Description or "An item that is undefined."
ITEM.Entity = ITEM.Entity or NULL
ITEM.ID = ITEM.ID or 0
ITEM.InventoryID = ITEM.InventoryID or 0
ITEM.IsBase = ITEM.IsBase or false
ITEM.Material = ITEM.Material or ""
ITEM.Model = ITEM.Model or Model("models/props_c17/oildrum001.mdl")
ITEM.Name = "Undefined"
ITEM.NoStack = ITEM.NoStack or false
ITEM.Skin = ITEM.Skin or 0
ITEM.UniqueID = ITEM.UniqueID or "undefined"
ITEM.Weight = ITEM.Weight or 0

--- Returns the unique identifier of the item.
-- @return string The unique identifier of the item
function ITEM:__tostring()
    return "item[" .. self:GetUniqueID() .. "][" .. self:GetID() .. "]"
end

function ITEM:GetUniqueID()
    return self.UniqueID
end

function ITEM:GetID()
    return self.ID
end

function ITEM:GetInventoryID()
    if ( IsValid(self:GetEntity()) ) then
        return 0
    end

    -- Always return the stored InventoryID if it's a valid number
    if ( isnumber(self.InventoryID) ) then
        return self.InventoryID
    end

    -- If InventoryID is not a number, try to find it
    for invID, invObject in pairs(ax.inventory.instances) do
        if ( invObject:HasItem(self:GetID()) ) then
            self.InventoryID = invID
            return invID
        end
    end

    ax.util:PrintWarning(tostring(self) .. " is not in an inventory or in the world! How??")
    return 0 -- Default to world
end

function ITEM:GetName()
    return self.Name
end

function ITEM:GetDescription()
    return self.Description
end

function ITEM:GetModel()
    return self.Model
end

function ITEM:GetMaterial()
    return self.Material
end

function ITEM:GetSkin()
    return self.Skin
end

function ITEM:GetWeight()
    return self.Weight
end

function ITEM:GetCategory()
    return self.Category
end

function ITEM:GetData()
    return self.Data
end

function ITEM:GetEntity()
    return self.Entity
end

function ITEM:IsNoStack()
    return self.NoStack
end

function ITEM:IsBase()
    return self.IsBase
end

function ITEM:GetHooks()
    return self.Hooks
end

function ITEM:GetInventory()
    return ax.inventory.instances[self.InventoryID]
end

function ITEM:SetName(name)
    if ( !isstring(name) ) then
        ax.util:PrintError("Attempted to set an item's name without a valid name!")
        return false, "Attempted to set an item's name without a valid name!"
    end

    self.Name = name
    return true
end

function ITEM:SetDescription(description)
    if ( !isstring(description) ) then
        ax.util:PrintError("Attempted to set an item's description without a valid description!")
        return false, "Attempted to set an item's description without a valid description!"
    end

    self.Description = description
    return true
end

function ITEM:SetModel(model)
    if ( !isstring(model) and !IsValid(model) ) then
        ax.util:PrintError("Attempted to set an item's model without a valid model!")
        return false, "Attempted to set an item's model without a valid model!"
    end

    self.Model = model
    return true
end

function ITEM:SetMaterial(material)
    if ( !isstring(material) ) then
        ax.util:PrintError("Attempted to set an item's material without a valid material!")
        return false, "Attempted to set an item's material without a valid material!"
    end

    self.Material = material
    return true
end

function ITEM:SetSkin(skin)
    if ( !isnumber(skin) ) then
        ax.util:PrintError("Attempted to set an item's skin without a valid skin!")
        return false, "Attempted to set an item's skin without a valid skin!"
    end

    self.Skin = skin
    return true
end

function ITEM:SetWeight(weight)
    if ( !isnumber(weight) ) then
        ax.util:PrintError("Attempted to set an item's weight without a valid weight!")
        return false, "Attempted to set an item's weight without a valid weight!"
    end

    self.Weight = weight
    return true
end

function ITEM:SetCategory(category)
    if ( !isstring(category) ) then
        ax.util:PrintError("Attempted to set an item's category without a valid category!")
        return false, "Attempted to set an item's category without a valid category!"
    end

    self.Category = category
    return true
end

function ITEM:SetData(key, value)
    if ( !isstring(key) or key == "" ) then
        ax.util:PrintError("Invalid key provided to ITEM:SetData")
        return false
    end

    if ( !istable(self.Data) ) then
        self.Data = {}
    end

    self.Data[key] = value

    -- On client, just update locally
    if ( CLIENT ) then
        return true
    end

    -- On server, update database and network
    if ( SERVER ) then
        ax.database:Update("ax_items", {
            data = util.TableToJSON(self.Data)
        }, "id = " .. self.ID)

        -- Network to clients
        local inventory = ax.inventory:Get(self.InventoryID)
        if ( inventory ) then
            local character = inventory:GetCharacter()
            if ( character ) then
                local client = character:GetPlayer()
                if ( IsValid(client) ) then
                    net.Start("ax.item.data")
                        net.WriteUInt(self.ID, 16)
                        net.WriteString(key)
                        net.WriteType(value)
                    net.Send(client)
                end
            end
        end
    end

    return true
end

function ITEM:GetData(key, default)
    if ( !istable(self.Data) ) then
        return default
    end

    if ( !isstring(key) or key == "" ) then
        return self.Data
    end

    local value = self.Data[key]
    if ( value == nil ) then
        return default
    end

    return value
end

function ITEM:SetEntity(entity)
    if ( !IsValid(entity) ) then
        ax.util:PrintError("Attempted to set an item's entity without a valid entity!")
        return false, "Attempted to set an item's entity without a valid entity!"
    end

    self.Entity = entity
    return true
end

function ITEM:SetInventoryID(inventoryID)
    -- Enhanced validation with better error messages
    if ( inventoryID == nil ) then
        ax.util:PrintError("Attempted to set an item's InventoryID with nil value for item " .. tostring(self))
        return false, "InventoryID cannot be nil"
    end

    -- Try to convert to number if it's a string representation of a number
    if ( isstring(inventoryID) ) then
        local numID = tonumber(inventoryID)
        if ( numID ) then
            inventoryID = numID
        else
            ax.util:PrintError("Attempted to set an item's InventoryID with non-numeric string: " .. tostring(inventoryID) .. " for item " .. tostring(self))
            return false, "InventoryID must be a valid number"
        end
    end

    if ( !isnumber(inventoryID) or inventoryID < 0 ) then
        ax.util:PrintError("Attempted to set an item's InventoryID without a valid number! Got: " .. tostring(inventoryID) .. " (type: " .. type(inventoryID) .. ") for item " .. tostring(self))
        return false, "InventoryID must be a number >= 0"
    end

    self.InventoryID = inventoryID
    return true
end

function ITEM:SetNoStack(noStack)
    if ( !isbool(noStack) ) then
        ax.util:PrintError("Attempted to set an item's no stack status without a valid boolean!")
        return false, "Attempted to set an item's no stack status without a valid boolean!"
    end

    self.NoStack = noStack
    return true
end

function ITEM:SetIsBase(isBase)
    if ( !isbool(isBase) ) then
        ax.util:PrintError("Attempted to set an item's base status without a valid boolean!")
        return false, "Attempted to set an item's base status without a valid boolean!"
    end

    self.IsBase = isBase
    return true
end

function ITEM:SetHooks(hooks)
    if ( !istable(hooks) ) then
        ax.util:PrintError("Attempted to set an item's hooks without a valid table!")
        return false, "Attempted to set an item's hooks without a valid table!"
    end

    self.Hooks = hooks
    return true
end

function ITEM:SetID(id)
    if ( !isnumber(id) or id < 0 ) then
        ax.util:PrintError("Attempted to set an item's ID without a valid number!")
        return false, "Attempted to set an item's ID without a valid number!"
    end

    self.ID = id
    return true
end

function ITEM:SetUniqueID(uniqueID)
    if ( !isstring(uniqueID) or uniqueID == "" ) then
        ax.util:PrintError("Attempted to set an item's UniqueID without a valid string!")
        return false, "Attempted to set an item's UniqueID without a valid string!"
    end

    self.UniqueID = uniqueID
    return true
end

function ITEM:Register()
    local bResult = hook.Run("PreItemRegistered", self)
    if ( bResult == false ) then
        ax.util:PrintError("Attempted to register a faction that was blocked by a hook!")
        return false, "Attempted to register a faction that was blocked by a hook!"
    end

    hook.Run("PostItemRegistered", self)

    -- Register the item in the stored items table
    ax.item.stored[self.UniqueID] = self
end

function ITEM:Hook(name, func)
    if ( !isstring(name) or !isfunction(func) ) then return end

    if ( !istable(self.Hooks) ) then
        self.Hooks = {}
    end

    if ( !istable(self.Hooks[name]) ) then
        self.Hooks[name] = {}
    end

    table.insert(self.Hooks[name], func)
end

function ITEM:GetActions()
    if ( !self.Actions ) then
        self.Actions = {}
        self:AddDefaultActions()
    end
    return self.Actions
end

function ITEM:AddAction(def)
    assert(isstring(def.Name) and isfunction(def.OnRun), "ITEM:AddAction requires def.Name (string) and def.OnRun (function)")

    local id = def.ID or def.id or def.Name:gsub("%s+", "")
    self:GetActions()[id] = def
end

function ITEM:RemoveAction(actionID)
    if ( self.Actions ) then
        self.Actions[actionID] = nil
    end
end

function ITEM:RunAction(actionID, client)
    local action = self:GetActions()[actionID]
    if ( action and isfunction(action.OnRun) ) then
        action:OnRun(self, client)
    end
end

function ITEM:CanRunAction(actionID, client)
    local action = self:GetActions()[actionID]
    if ( action and isfunction(action.OnCanRun) ) then
        return action:OnCanRun(self, client)
    end

    return false
end

function ITEM:AddDefaultActions()
    self:AddAction({
        Name = "Drop",
        Icon = "icon16/package_go.png",
        OnCanRun = function(this, item, client)
            return !IsValid(item:GetEntity()) and item:GetInventoryID() > 0
        end,
        OnRun = function(this, item, client)
            if ( !IsValid(client) ) then
                ax.util:PrintError("Invalid client for drop action")
                return
            end

            local pos = client:GetDropPosition()
            if ( !pos ) then
                ax.util:PrintError("Invalid drop position")
                return
            end

            local prevent = hook.Run("PrePlayerDropItem", client, item, pos)
            if ( prevent == false ) then return end

            ax.util:PrintSuccess("Starting drop action for item " .. item:GetID())

            -- Debug: Check what GetInventoryID() is actually returning
            local fromInventoryID = item:GetInventoryID()
            ax.util:PrintSuccess("item:GetInventoryID() returned: " .. tostring(fromInventoryID) .. " (type: " .. type(fromInventoryID) .. ")")
            ax.util:PrintSuccess("item.InventoryID raw value: " .. tostring(item.InventoryID) .. " (type: " .. type(item.InventoryID) .. ")")

            if ( !isnumber(fromInventoryID) ) then
                ax.util:PrintError("Invalid inventory ID for drop action: " .. tostring(fromInventoryID) .. " (type: " .. type(fromInventoryID) .. ")")

                -- Try to force it to a number
                if ( istable(fromInventoryID) and fromInventoryID.GetID ) then
                    fromInventoryID = fromInventoryID:GetID()
                    ax.util:PrintSuccess("Extracted ID from inventory object: " .. tostring(fromInventoryID))
                else
                    return
                end
            end

            -- First transfer the item to world (inventory 0)
            ax.item:Transfer(item:GetID(), fromInventoryID, 0, function(success)
                if ( success ) then
                    ax.util:PrintSuccess("Item transferred to world, spawning entity")

                    -- Then spawn the physical entity
                    ax.item:Spawn(item:GetID(), item:GetUniqueID(), pos, Angle(0, math.random(0, 360), 0), function(entity)
                        if ( IsValid(entity) ) then
                            ax.util:PrintSuccess("Item entity spawned successfully")
                            hook.Run("PostPlayerDropItem", client, item, entity)
                        else
                            ax.util:PrintError("Failed to spawn item entity")
                        end
                    end, item:GetData())
                else
                    ax.util:PrintError("Failed to transfer item to world")
                    client:Notify("Failed to drop item.")
                end
            end)
        end
    })

    self:AddAction({
        Name = "Take",
        Icon = "icon16/package_add.png",
        OnCanRun = function(this, item, client)
            return IsValid(item:GetEntity()) and item:GetInventoryID() == 0
        end,
        OnRun = function(this, item, client)
            if ( !IsValid(client) ) then return end

            local character = client:GetCharacter()
            if ( !character ) then
                client:Notify("You must have a character to take items.")
                return
            end

            local inventory = character:GetInventory()
            if ( !inventory ) then
                client:Notify("You don't have an inventory.")
                return
            end

            local entity = item:GetEntity()
            if ( !IsValid(entity) ) then return end

            local weight = item:GetWeight()
            if ( inventory:GetWeight() + weight > inventory:GetMaxWeight() ) then
                client:Notify("You cannot take this item, it is too heavy!")
                return
            end

            local prevent = hook.Run("PrePlayerTakeItem", client, item, entity)
            if ( prevent == false ) then return end

            ax.item:Transfer(item:GetID(), 0, inventory:GetID(), function(success)
                if ( success ) then
                    if ( item.OnTaken ) then
                        item:OnTaken(entity)
                    end

                    hook.Run("PostPlayerTakeItem", client, item, entity)
                    SafeRemoveEntity(entity)
                else
                    client:Notify("Failed to transfer item to inventory.")
                end
            end)
        end
    })
end