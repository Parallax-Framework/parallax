--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Registers a usergroup with additional properties
-- @param name string - Group name
-- @param level number - Hierarchy level
-- @param color Color - Group color
-- @param immunity number - Immunity level (0-100)
function MODULE:RegisterGroup(name, level, color, immunity)
    local group = {
        Name = name,
        Level = level or 0,
        Color = color or Color(255, 255, 255),
        Immunity = immunity or 0
    }

    CAMI.RegisterUsergroup(group, "Parallax")
    self.Groups[name] = group

    if ( SERVER ) then
        self:SaveData()
    end
end

--- Gets all groups
-- @return table - All registered groups
function MODULE:GetGroups()
    return self.Groups
end

--- Gets all permissions
-- @return table - All registered permissions
function MODULE:GetPermissions()
    return self.Permissions
end

--- Gets a group by name
-- @param name string - Group name
-- @return table - Group data
function MODULE:GetGroup(name)
    return self.Groups[name]
end

--- Gets a permission by name
-- @param name string - Permission name
-- @return table - Permission data
function MODULE:GetPermission(name)
    return self.Permissions[name]
end

--- Gets the group color for a player
-- @param client Player - The player
-- @return Color - Group color
function MODULE:GetGroupColor(client)
    if ( !IsValid(client) ) then
        return Color(255, 255, 255)
    end

    local group = self.Groups[client:GetUserGroup()]
    return group and group.Color or Color(255, 255, 255)
end

--- Gets the group level for a player
-- @param client Player - The player
-- @return number - Group level
function MODULE:GetGroupLevel(client)
    if ( !IsValid(client) ) then
        return 0
    end

    local group = self.Groups[client:GetUserGroup()]
    return group and group.Level or 0
end