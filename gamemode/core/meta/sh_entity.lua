----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local ENTITY = FindMetaTable("Entity")

local CHAIR_CACHE = {}
for _, v in ipairs(list.Get("Vehicles")) do
    if ( v.Category == "Chairs" ) then
        CHAIR_CACHE[v.Model] = true
    end
end

--- Returns `true` if this entity is a chair.
-- @realm shared
-- @treturn bool Whether or not this entity is a chair.
function ENTITY:IsChair()
    return CHAIR_CACHE[self:GetModel()]
end

--- Returns `true` if this entity is a door. Internally, this checks to see if the entity's class has `door` in its name.
-- @realm shared
-- @treturn bool Whether or not the entity is a door.
function ENTITY:IsDoor()
    local class = self:GetClass()
    return (class and string.match(class, "door") != nil)
end

--- Inherits the bodygroups of the given entity.
-- @realm shared
-- @tparam Entity entity The entity to inherit bodygroups from.
function ENTITY:InheritBodygroups(entity)
    for i = 0, (entity:GetNumBodyGroups() - 1) do
        self:SetBodygroup(i, entity:GetBodygroup(i))
    end
end

--- Inherits the materials of the given entity.
-- @realm shared
-- @tparam Entity entity The entity to inherit materials from.
function ENTITY:InheritMaterials(entity)
    self:SetMaterial(entity:GetMaterial())

    for k, v in ipairs(entity:GetMaterials()) do
        self:SetSubMaterial(k - 1, entity:GetSubMaterial(k - 1))
    end
end

--- Resets all bodygroups this entity's model has to their defaults (`0`).
-- @realm shared
function ENTITY:ResetBodygroups()
    for i = 0, (self:GetNumBodyGroups() - 1) do
        self:SetBodygroup(i, 0)
    end
end

--- Resets all bone manipulations this entity's model has to their defaults.
-- @realm shared
function ENTITY:ResetBoneMatrix()
    for i = 0, self:GetBoneCount() - 1 do
        self:ManipulateBoneScale(i, Vector(1, 1, 1))
        self:ManipulateBoneAngles(i, angle_zero)
        self:ManipulateBonePosition(i, vector_origin)
    end
end

--- Sets the bodygroup of this entity's model by its name.
-- @realm shared
-- @string name Name of the bodygroup.
-- @number value Value to set the bodygroup to.
function ENTITY:SetBodygroupName(name, value)
    local index = self:FindBodygroupByName(name)
    if ( index > -1 ) then
        self:SetBodygroup(index, value)
    end
end

--- Returns the bodygroup value of this entity's model by its name.
-- @realm shared
-- @string name Name of the bodygroup.
-- @treturn number Value of the bodygroup.
function ENTITY:GetBodygroupByName(name)
    local index = self:FindBodygroupByName(name)
    if ( index > -1 ) then
        return self:GetBodygroup(index)
    end

    return -1
end

--- Returns `true` if the given entity is a button or door and is locked.
-- @realm shared
-- @treturn bool Whether or not this entity is locked; `false` if this entity cannot be locked at all.
function ENTITY:IsLocked()
    if ( SERVER ) then
        if ( self:IsVehicle() ) then
            return self:GetInternalVariable("VehicleLocked")
        else
            return self:GetInternalVariable("m_bLocked")
        end
    else
        return self:GetRelay("locked", false)
    end

    return false
end

--- Gets whether the entity has a spawn effect.
-- @realm shared
-- @treturn bool Whether the entity has a spawn effect.
function ENTITY:GetSpawnEffect()
    return self:GetTable()["ax.m_bSpawnEffect"] or false
end

--- Sets the model of the entity, with hooks for pre- and post-model setting.
-- @realm shared
-- @string model The model to set for the entity.
function ENTITY:SetModel(model)
    local canSet = hook.Run("PreEntitySetModel", self, model)
    if ( canSet == false ) then return end

    self:SetModelInternal(model)

    hook.Run("PostEntitySetModel", self, model)
end

--- Sets a cooldown for a specific action on the entity.
-- @realm shared
-- @string action The action to set the cooldown for.
-- @number cooldown The cooldown duration in seconds.
function ENTITY:SetCooldown(action, cooldown)
    if ( !isstring(action) or !isnumber(cooldown) ) then return end

    local selfTable = self:GetTable()
    selfTable["ax.cooldown." .. action] = CurTime() + cooldown
end

--- Checks if a specific action is on cooldown for the entity.
-- @realm shared
-- @string action The action to check.
-- @treturn bool Whether the action is on cooldown.
function ENTITY:OnCooldown(action)
    if ( !isstring(action) ) then return false end

    local selfTable = self:GetTable()
    local cooldown = selfTable["ax.cooldown." .. action]

    if ( !isnumber(cooldown) or cooldown <= CurTime() ) then
        selfTable["ax.cooldown." .. action] = nil
        return false
    end

    return true
end