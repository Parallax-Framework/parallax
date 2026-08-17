--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local player = ax.player.meta or FindMetaTable("Player")

player.BanInternal = player.BanInternal or player.Ban
player.IsAdminInternal = player.IsAdminInternal or player.IsAdmin
player.IsSuperAdminInternal = player.IsSuperAdminInternal or player.IsSuperAdmin

local function HasUsergroupAccess(client, usergroup)
    if ( !ax.util:IsValidPlayer(client) ) then return false end
    if ( !istable(ax.admin) or !isfunction(ax.admin.GetPlayerUsergroup) or !isfunction(ax.admin.UsergroupInherits) ) then return nil end

    local playerUsergroup = ax.admin:GetPlayerUsergroup(client)
    if ( !isstring(playerUsergroup) or playerUsergroup == "" ) then return nil end

    return ax.admin:UsergroupInherits(playerUsergroup, usergroup)
end

--- Returns whether this player has administrator access through Parallax usergroups. Overrides Garry's Mod's native Player:IsAdmin so custom usergroups inheriting from `admin` are supported.
---@realm shared
---@return boolean isAdmin Whether the player is an administrator
function player:IsAdmin()
    local hasAccess = HasUsergroupAccess(self, "admin")
    if ( hasAccess != nil ) then return hasAccess end

    if ( isfunction(self.IsAdminInternal) ) then
        return self:IsAdminInternal()
    end

    return false
end

--- Returns whether this player has super administrator access through Parallax usergroups. Overrides Garry's Mod's native Player:IsSuperAdmin so custom usergroups inheriting from `superadmin` are supported.
---@realm shared
---@return boolean isSuperAdmin Whether the player is a super administrator
function player:IsSuperAdmin()
    local hasAccess = HasUsergroupAccess(self, "superadmin")
    if ( hasAccess != nil ) then return hasAccess end

    if ( isfunction(self.IsSuperAdminInternal) ) then
        return self:IsSuperAdminInternal()
    end

    return false
end

if ( SERVER ) then
    --- Creates a Parallax-managed ban for this player. Overrides Garry's Mod's native Player:Ban so every ban is persisted in ax_bans.
    ---@realm server
    ---@param minutes number Ban duration in minutes. Use 0 for permanent.
    ---@param bKick boolean Whether to kick the player after creating the ban.
    ---@param reason? string Optional ban reason.
    ---@param admin? Player|nil Optional admin responsible for the ban.
    ---@param callback? function|nil Optional callback receiving (ok, banData, err).
    function player:Ban(minutes, bKick, reason, admin, callback)
        if ( !ax.util:IsValidPlayer(self) ) then return false end

        local banModule = ax.admin
        if ( !istable(banModule) or !isfunction(banModule.CreateBan) ) then
            ax.util:PrintError("[ADMIN] Player:Ban called before the ban module was ready.\n")
            return false
        end

        banModule:CreateBan(self, admin, minutes, reason, callback, {
            bKick = bKick == true
        })

        return true
    end
end
