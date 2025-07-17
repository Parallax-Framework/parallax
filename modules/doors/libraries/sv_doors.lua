--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Door library for server-side door management
-- @module MODULE.doors

MODULE.doors = {}

--- Sets a door as ownable
-- @param door The door entity
-- @param ownable Boolean if the door should be ownable
function MODULE.doors:SetOwnable(door, ownable)
    if ( !IsValid(door) or !door:IsDoor() ) then return false end
    
    door:SetRelay("unownable", !ownable)
    
    -- If setting as unownable, remove current owner
    if ( !ownable ) then
        door:SetRelay("owner", 0)
        door:SetRelay("locked", false)
        door:Fire("Unlock")
    end
    
    -- Apply to child/master doors
    local child = door:GetChildDoor()
    if ( IsValid(child) ) then
        child:SetRelay("unownable", !ownable)
        if ( !ownable ) then
            child:SetRelay("owner", 0)
            child:SetRelay("locked", false)
            child:Fire("Unlock")
        end
    end
    
    local master = door:GetMasterDoor()
    if ( IsValid(master) ) then
        master:SetRelay("unownable", !ownable)
        if ( !ownable ) then
            master:SetRelay("owner", 0)
            master:SetRelay("locked", false)
            master:Fire("Unlock")
        end
    end
    
    return true
end

--- Checks if a door is ownable
-- @param door The door entity
-- @return Boolean if the door is ownable
function MODULE.doors:IsOwnable(door)
    if ( !IsValid(door) or !door:IsDoor() ) then return false end
    
    -- Check if explicitly set as unownable
    if ( door:GetRelay("unownable", false) ) then
        return false
    end
    
    -- Check default config
    if ( ax.config:Get("door.defaultUnownable", false) ) then
        return false
    end
    
    return true
end

--- Sets all doors in the map as unownable
function MODULE.doors:SetAllUnownable()
    local count = 0
    
    for i, door in ipairs(ents.GetAll()) do
        if ( door:IsDoor() ) then
            self:SetOwnable(door, false)
            count = count + 1
        end
    end
    
    return count
end

--- Sets all doors in the map as ownable
function MODULE.doors:SetAllOwnable()
    local count = 0
    
    for i, door in ipairs(ents.GetAll()) do
        if ( door:IsDoor() ) then
            self:SetOwnable(door, true)
            count = count + 1
        end
    end
    
    return count
end

--- Gets nearby doors to a position
-- @param pos The position to check
-- @param distance The maximum distance
-- @return Table of nearby doors
function MODULE.doors:GetNearby(pos, distance)
    local nearby = {}
    distance = distance or 128
    
    for i, door in ipairs(ents.GetAll()) do
        if ( door:IsDoor() and pos:Distance(door:GetPos()) <= distance ) then
            nearby[#nearby + 1] = door
        end
    end
    
    return nearby
end

