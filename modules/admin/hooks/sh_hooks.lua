--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Post-initialization hook for the admin module
function MODULE:PostInitializeSchema()
    -- Register default groups
    for _, group in ipairs(self.DefaultGroups) do
        self:RegisterGroup(group.name, group.level, group.color, group.immunity, group.inherits)
    end

    -- Register default permissions
    for _, perm in ipairs(self.DefaultPermissions) do
        self:RegisterPermission(perm.name, perm.level)
    end

    -- Load persistent data
    if ( SERVER ) then
        self:LoadData()
    end

    ax.util:Print("Admin System initialized with " .. #self.DefaultGroups .. " groups and " .. #self.DefaultPermissions .. " permissions.")
end

hook.Add("CAMI.PlayerHasAccess", "Parallax.Admin.CheckObserver", function(client, privilegeName, callback, targetPly, extraInfoTbl)
    local privilegeData = MODULE.Permissions[privilegeName]
    if ( privilegeData ) then
        local group = client:GetUserGroup()
        local groupData = MODULE.Groups[group]
        if ( groupData and groupData.Level >= privilegeData.Level ) then
            if ( callback ) then
                callback(true)
            end

            return true
        else
            if ( callback ) then
                callback(false)
            end

            return false
        end
    end
end)