--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:GetUserGroup(client)
    return client:GetUserGroup()
end

function MODULE:HasPermission(client, permission, callback)
    return CAMI.PlayerHasAccess(client, permission, callback)
end

--- Adds a group via code or future UI.
function MODULE:AddGroup(name, privilege)
    if ( self.Groups[name] ) then return false end

    self:RegisterGroup(name, privilege)

    return true
end

--- Removes a group and saves.
function MODULE:RemoveGroup(name)
    if ( !self.Groups[name] ) then return false end

    self.Groups[name] = nil
    self:SaveData()

    return true
end

--- Adds a permission manually.
function MODULE:AddPermission(name, access)
    if ( self.Permissions[name] ) then return false end

    self:RegisterPermission(name, access)

    return true
end

--- Removes a permission.
function MODULE:RemovePermission(name)
    if ( !self.Permissions[name] ) then return false end

    self.Permissions[name] = nil
    self:SaveData()

    return true
end