--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Map scene library shared helpers.
-- @module ax.mapscene

ax.mapscene = ax.mapscene or {}
ax.mapscene.scenes = ax.mapscene.scenes or {}
ax.mapscene.version = ax.mapscene.version or 1

--- Returns all stored scenes.
-- @return table
function ax.mapscene:GetScenes()
    return self.scenes or {}
end

--- Returns the number of stored scenes.
-- @return number
function ax.mapscene:GetCount()
    return #self:GetScenes()
end

--- Check if a number is finite and non-NaN.
-- @param value any
-- @return boolean
function ax.mapscene:IsFiniteNumber(value)
    if ( !isnumber(value) ) then return false end
    if ( value != value ) then return false end
    if ( value == math.huge or value == -math.huge ) then return false end

    return true
end

--- Validate a Vector.
-- @param vec any
-- @return boolean
function ax.mapscene:IsValidVector(vec)
    if ( !isvector(vec) ) then return false end

    return self:IsFiniteNumber(vec.x) and self:IsFiniteNumber(vec.y) and self:IsFiniteNumber(vec.z)
end

--- Validate an Angle.
-- @param ang any
-- @return boolean
function ax.mapscene:IsValidAngle(ang)
    if ( !isangle(ang) ) then return false end

    return self:IsFiniteNumber(ang.p) and self:IsFiniteNumber(ang.y) and self:IsFiniteNumber(ang.r)
end

--- Normalize a name string.
-- @param name any
-- @return string|nil
function ax.mapscene:NormalizeName(name)
    if ( !isstring(name) ) then return nil end

    name = string.Trim(name)
    if ( name == "" ) then return nil end

    return name
end

--- Parse a tag list from a string.
-- @param tagString string
-- @return table
function ax.mapscene:ParseTags(tagString)
    if ( !isstring(tagString) or tagString == "" ) then return {} end

    local tags = {}
    for _, raw in ipairs(string.Explode(",", tagString)) do
        local tag = string.Trim(raw)
        if ( tag != "" ) then
            tags[#tags + 1] = tag
        end
    end

    return tags
end

--- Normalize tags to a cleaned list of unique, lowercase strings.
-- @param tags table
-- @return table
function ax.mapscene:NormalizeTags(tags)
    if ( !istable(tags) ) then return {} end

    local allowed = ax.config:Get("map.scene.tags.allowed", {})
    local allowedSet = {}

    if ( istable(allowed) and table.Count(allowed) > 0 ) then
        if ( allowed[1] != nil ) then
            for i = 1, #allowed do
                allowedSet[utf8.lower(tostring(allowed[i]))] = true
            end
        else
            for key in pairs(allowed) do
                allowedSet[utf8.lower(tostring(key))] = true
            end
        end
    end

    local unique = {}
    local out = {}
    for i = 1, #tags do
        local tag = utf8.lower(tostring(tags[i] or ""))
        tag = string.Trim(tag)
        if ( tag == "" ) then continue end
        if ( allowedSet and table.Count(allowedSet) > 0 and !allowedSet[tag] ) then continue end
        if ( !unique[tag] ) then
            unique[tag] = true
            out[#out + 1] = tag
        end
    end

    return out
end

--- Check if a scene entry is a paired scene.
-- @param scene table
-- @return boolean
function ax.mapscene:IsPair(scene)
    return istable(scene) and self:IsValidVector(scene.origin2) and self:IsValidAngle(scene.angles2)
end

--- Validate and sanitize a scene entry.
-- @param scene table
-- @return table|nil, string|nil
function ax.mapscene:SanitizeScene(scene)
    if ( !istable(scene) ) then
        return nil, "Scene is not a table"
    end

    local origin = scene.origin
    local angles = scene.angles
    local origin2 = scene.origin2
    local angles2 = scene.angles2

    if ( !self:IsValidVector(origin) ) then
        return nil, "Invalid origin"
    end

    if ( !self:IsValidAngle(angles) ) then
        return nil, "Invalid angles"
    end

    if ( (origin2 != nil or angles2 != nil) and (!self:IsValidVector(origin2) or !self:IsValidAngle(angles2)) ) then
        return nil, "Invalid paired origin/angles"
    end

    local name = self:NormalizeName(scene.name)
    local tags = self:NormalizeTags(scene.tags or {})

    local weight = tonumber(scene.weight or 1) or 1
    if ( weight < 0 ) then
        weight = 0
    end

    local cleaned = {
        name = name,
        origin = origin,
        angles = angles,
        origin2 = origin2,
        angles2 = angles2,
        tags = tags,
        weight = weight
    }

    return cleaned
end

--- Find a scene by name (case-insensitive).
-- @param name string
-- @return table|nil, number|nil
function ax.mapscene:FindByName(name)
    if ( !isstring(name) or name == "" ) then return nil end

    local look = utf8.lower(name)
    for i = 1, #self.scenes do
        local scene = self.scenes[i]
        if ( istable(scene) and isstring(scene.name) and utf8.lower(scene.name) == look ) then
            return scene, i
        end
    end

    return nil
end

--- Resolve a scene by index or name.
-- @param identifier any
-- @return table|nil, number|nil
function ax.mapscene:ResolveScene(identifier)
    if ( isnumber(identifier) ) then
        local scene = self.scenes[identifier]
        if ( istable(scene) ) then
            return scene, identifier
        end
    end

    if ( isstring(identifier) ) then
        return self:FindByName(identifier)
    end

    return nil
end

--- Pack a scene for JSON export (convert vectors/angles to tables).
-- @param scene table
-- @return table
function ax.mapscene:PackScene(scene)
    if ( !istable(scene) ) then return nil end

    local packed = {
        name = scene.name,
        origin = { x = scene.origin.x, y = scene.origin.y, z = scene.origin.z },
        angles = { p = scene.angles.p, y = scene.angles.y, r = scene.angles.r },
        weight = scene.weight,
        tags = scene.tags
    }

    if ( self:IsPair(scene) ) then
        packed.origin2 = { x = scene.origin2.x, y = scene.origin2.y, z = scene.origin2.z }
        packed.angles2 = { p = scene.angles2.p, y = scene.angles2.y, r = scene.angles2.r }
    end

    return packed
end

--- Unpack a scene from JSON export format.
-- @param data table
-- @return table|nil, string|nil
function ax.mapscene:UnpackScene(data)
    if ( !istable(data) ) then return nil, "Invalid data" end

    local origin = data.origin
    local angles = data.angles

    if ( !istable(origin) or !istable(angles) ) then
        return nil, "Missing origin/angles"
    end

    local scene = {
        name = self:NormalizeName(data.name),
        origin = Vector(origin.x or 0, origin.y or 0, origin.z or 0),
        angles = Angle(angles.p or 0, angles.y or 0, angles.r or 0),
        weight = data.weight,
        tags = data.tags or {}
    }

    if ( istable(data.origin2) and istable(data.angles2) ) then
        scene.origin2 = Vector(data.origin2.x or 0, data.origin2.y or 0, data.origin2.z or 0)
        scene.angles2 = Angle(data.angles2.p or 0, data.angles2.y or 0, data.angles2.r or 0)
    end

    return self:SanitizeScene(scene)
end

--- Handle config changes relevant to map scenes.
-- @param key string
-- @param oldValue any
-- @param value any
function ax.mapscene:OnConfigChanged(key, oldValue, value)
    if ( !isstring(key) ) then return end
    if ( !string.StartWith(key, "map.scene.") ) then return end

    if ( CLIENT ) then
        self:ResetState()
    elseif ( SERVER and key == "map.scene.scope" ) then
        self:Load()
        self:Sync(nil)
    end
end
