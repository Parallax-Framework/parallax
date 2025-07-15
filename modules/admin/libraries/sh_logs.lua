--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

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
    if ( self.AdminLogs[1000] != nil ) then
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

        if ( filter.action and !ax.util:FindString(log.action, filter.action) ) then
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