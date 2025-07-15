--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Registers a permission
-- @param name string - Permission name
-- @param level number - Minimum access level required for this permission
function MODULE:RegisterPermission(name, level)
    local permission = {
        Name = name,
        Level = level
    }

    CAMI.RegisterPrivilege(permission)
    self.Permissions[name] = permission

    if ( SERVER ) then
        self:SaveData()
    end
end

--- Checks if a player has immunity over another player
-- @param admin Player - The admin player
-- @param target Player - The target player
-- @return boolean - True if admin has immunity over target
function MODULE:HasImmunity(admin, target)
    if ( !ax.config:Get("admin.immunity") ) then
        return true
    end

    if ( !IsValid(admin) or !IsValid(target) ) then
        return false
    end

    if ( admin == target ) then
        return true
    end

    local adminGroup = self.Groups[admin:GetUserGroup()]
    local targetGroup = self.Groups[target:GetUserGroup()]

    if ( !adminGroup or !targetGroup ) then
        return true
    end

    return adminGroup.Immunity >= targetGroup.Immunity
end

--- Checks if a player can target another player based on hierarchy
-- @param admin Player - The admin player
-- @param target Player - The target player
-- @return boolean - True if admin can target
function MODULE:CanTarget(admin, target)
    if ( !ax.config:Get("admin.hierarchy") ) then
        return true
    end

    if ( !IsValid(admin) or !IsValid(target) ) then
        return false
    end

    if ( admin == target ) then
        return true
    end

    local adminGroup = self.Groups[admin:GetUserGroup()]
    local targetGroup = self.Groups[target:GetUserGroup()]

    if ( !adminGroup or !targetGroup ) then
        return true
    end

    return adminGroup.Level >= targetGroup.Level
end