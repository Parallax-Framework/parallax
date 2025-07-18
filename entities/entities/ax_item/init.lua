--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:SetItem(itemID, uniqueID, data)
    local itemDef = ax.item:Get(uniqueID)
    if ( !istable(itemDef) ) then
        ax.util:PrintError("Attempted to set item with an invalid item definition for entity " .. self:EntIndex() .. "!")
        return
    end

    self:SetModel(Model(itemDef.Model))
    self:SetSkin(isfunction(itemDef.GetSkin) and itemDef:GetSkin(self) or (itemDef.Skin or 0))
    self:SetColor(isfunction(itemDef.GetColor) and itemDef:GetColor(self) or (itemDef.Color or ax.color:Get("white")))
    self:SetMaterial(isfunction(itemDef.GetMaterial) and itemDef:GetMaterial(self) or (itemDef.Material or ""))
    self:SetModelScale(isfunction(itemDef.GetScale) and itemDef:GetScale(self) or (itemDef.Scale or 1))
    self:SetHealth(itemDef.Health or 25)

    -- Reinitialize physics due to model change
    self:PhysicsInit(SOLID_VPHYSICS)
    self:PhysWake()

    if ( itemDef.Bodygroups ) then
        for k, v in pairs(itemDef.Bodygroups) do
            local idx = isstring(k) and self:FindBodygroupByName(k) or k
            if ( idx and idx >= 0 ) then self:SetBodygroup(idx, v) end
        end
    end

    if ( itemDef.SubMaterials ) then
        for k, v in pairs(itemDef.SubMaterials) do
            self:SetSubMaterial(k - 1, v)
        end
    end

    self:SetUniqueID(uniqueID)

    if ( !itemID or itemID == 0 ) then
        -- Create new world item instance
        ax.database:Insert("ax_items", {
            unique_id = uniqueID,
            inventory_id = 0,
            data = util.TableToJSON(data or {})
        }, function(newItemID)
            if ( !IsValid(self) or !newItemID ) then return end

            self:SetItemID(newItemID)

            -- Create item instance
            local item = ax.item:CreateObject(newItemID, uniqueID, data or {})
            if ( item ) then
                item:SetEntity(self)
                item:SetInventoryID(0)
                ax.item.instances[newItemID] = item

                self:SetData(item:GetData() or {})

                -- Network to clients
                net.Start("ax.item.entity")
                    net.WriteEntity(self)
                    net.WriteUInt(newItemID, 16)
                net.Broadcast()
            end
        end)
    else
        self:SetItemID(itemID)

        local item = ax.item:Get(itemID)
        if ( item ) then
            item:SetEntity(self)
            item:SetInventoryID(0)
            self:SetData(item:GetData() or {})
        end

        -- Network to clients
        net.Start("ax.item.entity")
            net.WriteEntity(self)
            net.WriteUInt(itemID, 16)
        net.Broadcast()
    end

    -- Call item spawn hook
    if ( itemDef.OnSpawned ) then
        itemDef:OnSpawned(self)
    end

    hook.Run("OnItemEntitySpawned", self, itemID, uniqueID)
end

function ENT:GetData()
    return self:GetTable().axItemData or {}
end

function ENT:SetData(data)
    if ( !istable(data) ) then
        data = {}
    end

    self:GetTable().axItemData = data

    -- Update item instance data
    local item = ax.item:Get(self:GetItemID())
    if ( item ) then
        item.Data = data

        -- Update database
        ax.database:Update("ax_items", {
            data = util.TableToJSON(data)
        }, "id = " .. self:GetItemID())
    end
end

function ENT:Use(client)
    if ( !IsValid(client) or !client:IsPlayer() ) then return end
    if ( self:OnCooldown("take") ) then return end

    local character = client:GetCharacter()
    if ( !character ) then
        client:Notify("You must have a character to pick up items.")
        return
    end

    local inventory = character:GetInventory()
    if ( !inventory ) then
        client:Notify("You don't have an inventory.")
        return
    end

    local itemInst = ax.item:Get(self:GetItemID())
    if ( !itemInst ) then
        ax.util:PrintError("Item instance not found for entity " .. self:EntIndex())
        return
    end

    -- Check if inventory can fit the item
    if ( !inventory:CanFitItem(itemInst:GetUniqueID(), 1) ) then
        client:Notify("Your inventory is too full to take this item.")
        return
    end

    if ( hook.Run("PrePlayerTakeItem", client, itemInst, self) == false ) then return end

    -- Set cooldown to prevent spam
    self:SetCooldown("take", 1)

    -- Perform take action
    ax.item:PerformAction(itemInst:GetID(), "Take")
end

function ENT:OnTakeDamage(dmg)
    local item = ax.item:Get(self:GetItemID())
    if ( !item ) then return end

    self:SetHealth(self:Health() - dmg:GetDamage())

    if ( self:Health() <= 0 and hook.Run("PreItemDestroy", self, dmg) != false ) then
        self:EmitSound("physics/cardboard/cardboard_box_break" .. math.random(1, 3) .. ".wav")

        local position = self:LocalToWorld(self:OBBCenter())
        local effect = EffectData()
        effect:SetStart(position)
        effect:SetOrigin(position)
        effect:SetScale(3)
        util.Effect("GlassImpact", effect)

        local itemDef = ax.item:Get(self:GetUniqueID())
        if ( itemDef and itemDef.OnDestroyed ) then
            itemDef:OnDestroyed(self)
        end

        hook.Run("PostItemDestroyed", self, dmg)

        SafeRemoveEntity(self)
    end
end

function ENT:OnRemove()
    if ( ax.ShutDown ) then return end
    if ( self:OnCooldown("take") ) then return end

    local itemID = self:GetItemID()
    if ( !itemID or itemID == 0 ) then return end

    local item = ax.item:Get(itemID)
    if ( item ) then
        -- Call item remove hook
        if ( item.OnRemoved ) then
            item:OnRemoved(self)
        end

        -- Remove from instances
        ax.item.instances[itemID] = nil
    end

    -- Remove from database
    ax.database:Delete("ax_items", {
        id = itemID
    })

    hook.Run("OnItemEntityRemoved", self, itemID)
end

function ENT:Think()
    -- Auto-remove if item definition no longer exists
    local itemDef = ax.item:Get(self:GetUniqueID())
    if ( !itemDef ) then
        SafeRemoveEntity(self)
        return
    end

    -- Call item think hook
    if ( itemDef.Think ) then
        itemDef:Think(self)
    end

    self:NextThink(CurTime() + 1)
    return true
end

function ENT:StartTouch(entity)
    local itemDef = ax.item:Get(self:GetUniqueID())
    if ( itemDef and itemDef.StartTouch ) then
        itemDef:StartTouch(self, entity)
    end
end

function ENT:EndTouch(entity)
    local itemDef = ax.item:Get(self:GetUniqueID())
    if ( itemDef and itemDef.EndTouch ) then
        itemDef:EndTouch(self, entity)
    end
end

function ENT:Touch(entity)
    local itemDef = ax.item:Get(self:GetUniqueID())
    if ( itemDef and itemDef.Touch ) then
        itemDef:Touch(self, entity)
    end
end

-- Utility function to check if entity is on cooldown
function ENT:OnCooldown(name)
    local cooldowns = self:GetTable().axCooldowns or {}
    return cooldowns[name] and cooldowns[name] > CurTime()
end

-- Utility function to set cooldown
function ENT:SetCooldown(name, duration)
    local cooldowns = self:GetTable().axCooldowns or {}
    cooldowns[name] = CurTime() + duration
    self:GetTable().axCooldowns = cooldowns
end
