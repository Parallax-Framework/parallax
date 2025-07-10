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

--- Logs an admin action
-- @param admin Player - The admin who performed the action
-- @param action string - The action performed
-- @param target Player - The target of the action (optional)
-- @param reason string - Reason for the action (optional)
-- @param duration number - Duration of the action (optional)
function MODULE:LogAction(admin, action, target, reason, duration)
    if ( !ax.config:Get("admin.logging") ) then
        return
    end

    local logEntry = {
        timestamp = os.time(),
        admin = IsValid(admin) and admin:SteamID64() or "Console",
        adminName = IsValid(admin) and admin:SteamName() or "Console",
        action = action,
        target = IsValid(target) and target:SteamID64() or nil,
        targetName = IsValid(target) and target:SteamName() or nil,
        reason = reason or "No reason provided",
        duration = duration or 0
    }

    table.insert(self.AdminLogs, logEntry)

    -- Keep only last 1000 log entries
    if ( #self.AdminLogs > 1000 ) then
        table.remove(self.AdminLogs, 1)
    end

    -- Print to console
    local logMessage = string.format("[ADMIN] %s %s", logEntry.adminName, action)
    if ( IsValid(target) ) then
        logMessage = logMessage .. " " .. target:SteamName()
    end

    if ( reason and reason != "" ) then
        logMessage = logMessage .. " - Reason: " .. reason
    end

    if ( duration and duration > 0 ) then
        logMessage = logMessage .. " - Duration: " .. duration .. "s"
    end

    ax.util:Print(logMessage)

    -- Save logs
    if ( SERVER ) then
        self:SaveData()
    end
end

--- Gets admin logs with optional filtering
-- @param filter table - Filter options
-- @return table - Filtered log entries
function MODULE:GetLogs(filter)
    local logs = self.AdminLogs
    if ( !filter ) then
        return logs
    end

    local filtered = {}
    for _, log in ipairs(logs) do
        local include = true

        if ( filter.admin and log.admin != filter.admin ) then
            include = false
        end

        if ( filter.action and !string.find(log.action, filter.action) ) then
            include = false
        end

        if ( filter.target and log.target != filter.target ) then
            include = false
        end

        if ( filter.after and log.timestamp < filter.after ) then
            include = false
        end

        if ( filter.before and log.timestamp > filter.before ) then
            include = false
        end

        if ( include ) then
            table.insert(filtered, log)
        end
    end

    return filtered
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