--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE or ax.admin or {}
ax.admin = MODULE

local CAMI_SOURCE = "Parallax"

MODULE.usergroups = MODULE.usergroups or {}
MODULE.usergroupOrder = MODULE.usergroupOrder or {}

local function NormalizeID(uniqueID)
    if ( !isstring(uniqueID) ) then return nil end

    uniqueID = string.Trim(uniqueID)
    if ( uniqueID == "" ) then return nil end

    return string.lower(uniqueID)
end

local function GetSteamIDFrom64(steamID64)
    if ( !isstring(steamID64) or steamID64 == "" or !isfunction(util.SteamIDFrom64) ) then
        return steamID64
    end

    local bSuccess, steamID = pcall(util.SteamIDFrom64, steamID64)
    if ( bSuccess and isstring(steamID) and steamID != "" ) then
        return steamID
    end

    return steamID64
end

local function NotifyCallback(callback, ok, result, err)
    if ( isfunction(callback) ) then
        callback(ok, result, err)
    end
end

--- Registers a Parallax usergroup and mirrors it to CAMI when available.
---@realm shared
---@param uniqueID string Stable lower-case usergroup identifier
---@param data table Usergroup metadata
---@return table|nil usergroup Registered usergroup data
function MODULE:RegisterUsergroup(uniqueID, data)
    uniqueID = NormalizeID(uniqueID)
    if ( !uniqueID ) then return nil end

    data = istable(data) and table.Copy(data) or {}

    local existing = self.usergroups[uniqueID]
    local usergroup = existing or {}
    usergroup.uniqueID = uniqueID
    usergroup.name = isstring(data.name) and data.name != "" and data.name or ax.util:UniqueIDToName(uniqueID)
    usergroup.description = isstring(data.description) and data.description or ""
    usergroup.level = math.floor(tonumber(data.level) or tonumber(usergroup.level) or 0)
    usergroup.immunity = math.floor(tonumber(data.immunity) or tonumber(data.level) or tonumber(usergroup.immunity) or usergroup.level)
    usergroup.inherits = NormalizeID(data.inherits) or NormalizeID(usergroup.inherits)
    usergroup.bProtected = data.bProtected == true or usergroup.bProtected == true
    usergroup.bHidden = data.bHidden == true or usergroup.bHidden == true
    usergroup.bDefault = data.bDefault == true or usergroup.bDefault == true
    usergroup.color = data.color or usergroup.color

    if ( uniqueID == "user" ) then
        usergroup.inherits = nil
    elseif ( !usergroup.inherits or usergroup.inherits == uniqueID ) then
        usergroup.inherits = "user"
    end

    self.usergroups[uniqueID] = usergroup

    if ( !existing ) then
        self.usergroupOrder[#self.usergroupOrder + 1] = uniqueID
    end

    if ( istable(CAMI) and isfunction(CAMI.RegisterUsergroup) ) then
        CAMI.RegisterUsergroup({
            Name = uniqueID,
            Inherits = usergroup.inherits or uniqueID,
        }, CAMI_SOURCE)
    end

    return usergroup
end

--- Returns a registered usergroup by identifier.
---@realm shared
---@param uniqueID string Usergroup identifier
---@return table|nil usergroup Usergroup data
function MODULE:GetUsergroup(uniqueID)
    uniqueID = NormalizeID(uniqueID)
    if ( !uniqueID ) then return nil end

    return self.usergroups[uniqueID]
end

--- Returns all registered usergroups.
---@realm shared
---@return table usergroups Usergroup registry keyed by unique ID
function MODULE:GetUsergroups()
    return self.usergroups
end

--- Returns all registered usergroups sorted by level then name.
---@realm shared
---@return table usergroups Sorted usergroup array
function MODULE:GetSortedUsergroups()
    local usergroups = {}

    for uniqueID, usergroup in pairs(self.usergroups or {}) do
        if ( istable(usergroup) ) then
            usergroups[#usergroups + 1] = usergroup
        end
    end

    table.sort(usergroups, function(a, b)
        local levelA = tonumber(a.level) or 0
        local levelB = tonumber(b.level) or 0
        if ( levelA != levelB ) then
            return levelA < levelB
        end

        return tostring(a.uniqueID or "") < tostring(b.uniqueID or "")
    end)

    return usergroups
end

--- Normalizes a usergroup identifier, accepting exact names and unambiguous partial matches.
---@realm shared
---@param uniqueID string Usergroup identifier, display name, or partial match
---@return string|nil uniqueID Normalized identifier
---@return table|nil usergroup Usergroup data
---@return string|nil err Failure reason
function MODULE:NormalizeUsergroup(uniqueID)
    uniqueID = NormalizeID(uniqueID)
    if ( !uniqueID ) then
        return nil, nil, "Invalid usergroup."
    end

    local exact = self.usergroups[uniqueID]
    if ( istable(exact) ) then
        return uniqueID, exact
    end

    for storedID, usergroup in pairs(self.usergroups or {}) do
        if ( istable(usergroup) and string.lower(tostring(usergroup.name or "")) == uniqueID ) then
            return storedID, usergroup
        end
    end

    local matches = {}
    for storedID, usergroup in pairs(self.usergroups or {}) do
        local groupName = string.lower(tostring(usergroup.name or ""))
        if ( string.find(storedID, uniqueID, 1, true) or string.find(groupName, uniqueID, 1, true) ) then
            matches[#matches + 1] = storedID
        end
    end

    if ( #matches == 1 ) then
        local matchedID = matches[1]
        return matchedID, self.usergroups[matchedID]
    elseif ( #matches > 1 ) then
        table.sort(matches)
        return nil, nil, "Ambiguous usergroup. Matches: " .. table.concat(matches, ", ")
    end

    return nil, nil, "Unknown usergroup."
end

--- Returns whether a usergroup exists.
---@realm shared
---@param uniqueID string Usergroup identifier
---@return boolean exists Whether the usergroup exists
function MODULE:IsUsergroup(uniqueID)
    local normalizedID = self:NormalizeUsergroup(uniqueID)
    return normalizedID != nil
end

--- Returns a usergroup's access level.
---@realm shared
---@param uniqueID string Usergroup identifier
---@return number level Usergroup access level
function MODULE:GetUsergroupLevel(uniqueID)
    local _, usergroup = self:NormalizeUsergroup(uniqueID)
    if ( !istable(usergroup) ) then return 0 end

    return tonumber(usergroup.level) or 0
end

--- Returns a usergroup's target immunity value.
---@realm shared
---@param uniqueID string Usergroup identifier
---@return number immunity Usergroup immunity value
function MODULE:GetUsergroupImmunity(uniqueID)
    local _, usergroup = self:NormalizeUsergroup(uniqueID)
    if ( !istable(usergroup) ) then return 0 end

    return tonumber(usergroup.immunity) or tonumber(usergroup.level) or 0
end

--- Returns whether a usergroup inherits from another usergroup.
---@realm shared
---@param uniqueID string Child usergroup identifier
---@param parentID string Parent usergroup identifier
---@return boolean inherits Whether the child inherits from the parent
function MODULE:UsergroupInherits(uniqueID, parentID)
    local childID = self:NormalizeUsergroup(uniqueID)
    local normalizedParentID = self:NormalizeUsergroup(parentID)
    if ( !childID or !normalizedParentID ) then return false end
    if ( childID == normalizedParentID ) then return true end

    local visited = {}
    local currentID = childID

    while ( currentID and !visited[currentID] ) do
        visited[currentID] = true

        local usergroup = self.usergroups[currentID]
        if ( !istable(usergroup) ) then return false end

        currentID = usergroup.inherits
        if ( currentID == normalizedParentID ) then return true end
    end

    return false
end

--- Normalizes a SteamID or SteamID64 into SteamID64 form.
---@realm shared
---@param identifier string SteamID or SteamID64
---@return string|nil steamID64 Normalized SteamID64
function MODULE:NormalizeSteamID64(identifier)
    identifier = string.Trim(tostring(identifier or ""))
    if ( identifier == "" ) then return nil end

    if ( ax.type:Sanitise(ax.type.steamid64, identifier) ) then
        return identifier
    end

    if ( ax.type:Sanitise(ax.type.steamid, identifier) and isfunction(util.SteamIDTo64) ) then
        local steamID64 = util.SteamIDTo64(identifier)
        if ( ax.type:Sanitise(ax.type.steamid64, steamID64) ) then
            return steamID64
        end
    end

    return nil
end

--- Returns the best known Parallax usergroup for a player.
---@realm shared
---@param client Player Target player
---@return string usergroup Usergroup identifier
function MODULE:GetPlayerUsergroup(client)
    if ( !ax.util:IsValidPlayer(client) ) then return "user" end
    if ( client:IsListenServerHost() ) then return "superadmin" end

    local storedGroup = isfunction(client.GetUsergroup) and client:GetUsergroup() or nil
    local runtimeGroup = isfunction(client.GetUserGroup) and client:GetUserGroup() or nil
    local storedID = self:NormalizeUsergroup(storedGroup)
    local runtimeID = self:NormalizeUsergroup(runtimeGroup)

    if ( runtimeID and self:GetUsergroupLevel(runtimeID) > self:GetUsergroupLevel(storedID) ) then
        return runtimeID
    end

    return storedID or runtimeID or "user"
end

--- Returns a player's access level.
---@realm shared
---@param client Player Target player
---@return number level Player access level
function MODULE:GetPlayerUsergroupLevel(client)
    return self:GetUsergroupLevel(self:GetPlayerUsergroup(client))
end

--- Returns a player's target immunity value.
---@realm shared
---@param client Player Target player
---@return number immunity Player immunity value
function MODULE:GetPlayerUsergroupImmunity(client)
    return self:GetUsergroupImmunity(self:GetPlayerUsergroup(client))
end

--- Applies a player's stored usergroup to Garry's Mod runtime state.
---@realm server
---@param client Player Target player
---@param usergroup? string|nil Optional usergroup override
---@return string usergroup Applied usergroup
function MODULE:SyncPlayerUsergroup(client, usergroup)
    if ( !SERVER or !ax.util:IsValidPlayer(client) ) then return "user" end

    local normalizedID = self:NormalizeUsergroup(usergroup or self:GetPlayerUsergroup(client)) or "user"
    if ( client:IsListenServerHost() ) then
        normalizedID = "superadmin"
    end

    if ( isfunction(client.SetUserGroup) ) then
        client:SetUserGroup(normalizedID)
    end

    return normalizedID
end

--- Checks whether a player can use a CAMI privilege with a local fallback.
---@realm shared
---@param client Player|nil Player to check; console always passes
---@param privilege string CAMI privilege name
---@param fallback string Fallback access level: user, admin, or superadmin
---@return boolean allowed Whether access is granted
function MODULE:CanAccessPrivilege(client, privilege, fallback)
    if ( !ax.util:IsValidPlayer(client) ) then return true end

    fallback = fallback or "admin"

    if ( istable(CAMI) and isfunction(CAMI.PlayerHasAccess) ) then
        local hasAccess = CAMI.PlayerHasAccess(client, privilege, nil, nil, {
            Fallback = fallback,
        })

        if ( hasAccess == true ) then
            return true
        end
    end

    if ( fallback == "superadmin" ) then
        return client:IsSuperAdmin()
    elseif ( fallback == "admin" ) then
        return client:IsAdmin()
    end

    return true
end

--- Checks whether an actor can target a player for usergroup management.
---@realm server
---@param actor Player|nil Actor player; console always passes
---@param target Player Target player
---@return boolean allowed Whether targeting is allowed
---@return string|nil reason Failure reason
function MODULE:CanTarget(actor, target)
    if ( !ax.util:IsValidPlayer(target) ) then
        return false, "You must specify a valid target player."
    end

    if ( !ax.util:IsValidPlayer(actor) ) then
        return true
    end

    if ( actor == target ) then
        return false, "You cannot manage your own usergroup. Use the server console for self changes."
    end

    if ( target:IsListenServerHost() ) then
        return false, "The listen server host usergroup is protected."
    end

    if ( self:GetPlayerUsergroupImmunity(actor) <= self:GetPlayerUsergroupImmunity(target) ) then
        return false, "You cannot manage a player with equal or higher immunity."
    end

    return true
end

--- Checks whether an actor can assign a usergroup.
---@realm server
---@param actor Player|nil Actor player; console always passes
---@param usergroup string Usergroup identifier
---@return boolean allowed Whether assignment is allowed
---@return string|nil reason Failure reason
function MODULE:CanAssignUsergroup(actor, usergroup)
    local normalizedID, group, err = self:NormalizeUsergroup(usergroup)
    if ( !normalizedID or !istable(group) ) then
        return false, err or "Unknown usergroup."
    end

    if ( !ax.util:IsValidPlayer(actor) ) then
        return true
    end

    if ( self:GetPlayerUsergroupLevel(actor) < (tonumber(group.level) or 0) ) then
        return false, "You cannot assign a usergroup above your own access level."
    end

    return true
end

--- Checks whether an actor can change a target player to a usergroup.
---@realm server
---@param actor Player|nil Actor player; console always passes
---@param target Player Target player
---@param usergroup string Desired usergroup
---@return boolean allowed Whether management is allowed
---@return string|nil reason Failure reason
---@return string|nil uniqueID Normalized usergroup identifier
---@return table|nil group Usergroup data
function MODULE:CanManageUsergroup(actor, target, usergroup)
    local normalizedID, group, err = self:NormalizeUsergroup(usergroup)
    if ( !normalizedID or !istable(group) ) then
        return false, err or "Unknown usergroup."
    end

    local canAssign, assignReason = self:CanAssignUsergroup(actor, normalizedID)
    if ( !canAssign ) then
        return false, assignReason
    end

    if ( ax.util:IsValidPlayer(target) and target:IsListenServerHost() and normalizedID != "superadmin" ) then
        return false, "The listen server host must remain superadmin."
    end

    local canTarget, targetReason = self:CanTarget(actor, target)
    if ( !canTarget ) then
        return false, targetReason
    end

    local hookResult, hookReason = hook.Run("CanPlayerManageUsergroup", actor, target, normalizedID, group)
    if ( hookResult == false ) then
        return false, hookReason or "You cannot manage that usergroup."
    end

    return true, nil, normalizedID, group
end

--- Sets an online player's usergroup through the authoritative admin API.
---@realm server
---@param actor Player|nil Actor player; console may be nil
---@param target Player Target player
---@param usergroup string Desired usergroup
---@param callback? function|nil Optional callback receiving (ok, result, err)
---@return boolean ok Whether the change started/succeeded
---@return string|nil err Failure reason when ok is false
function MODULE:SetPlayerUsergroup(actor, target, usergroup, callback)
    if ( !SERVER ) then return false, "Usergroups can only be changed on the server." end

    local canManage, reason, normalizedID = self:CanManageUsergroup(actor, target, usergroup)
    if ( !canManage ) then
        NotifyCallback(callback, false, nil, reason)
        return false, reason
    end

    local oldGroup = self:GetPlayerUsergroup(target)
    if ( oldGroup == normalizedID ) then
        local already = target:SteamName() .. " is already in the " .. normalizedID .. " usergroup."
        NotifyCallback(callback, false, nil, already)
        return false, already
    end

    if ( isfunction(target.SetUsergroup) ) then
        target:SetUsergroup(normalizedID, {
            bNoDBUpdate = true,
        })
    else
        ax.player:SetVar(target, "usergroup", normalizedID, {
            bNoDBUpdate = true,
        })
    end

    self:SyncPlayerUsergroup(target, normalizedID)

    if ( isfunction(target.Save) ) then
        target:Save()
    end

    if ( istable(CAMI) and isfunction(CAMI.SignalUserGroupChanged) ) then
        CAMI.SignalUserGroupChanged(target, oldGroup, normalizedID, CAMI_SOURCE)
    end

    hook.Run("PlayerUsergroupChanged", target, oldGroup, normalizedID, actor)
    hook.Run("OnPlayerUsergroupChanged", target, oldGroup, normalizedID, actor)

    local result = {
        target = target,
        old = oldGroup,
        new = normalizedID,
    }

    NotifyCallback(callback, true, result)
    return true
end

--- Sets an offline player's persisted usergroup by SteamID64.
---@realm server
---@param actor Player|nil Actor player; console may be nil
---@param identifier string SteamID or SteamID64
---@param usergroup string Desired usergroup
---@param callback? function|nil Optional callback receiving (ok, result, err)
---@return boolean ok Whether the request was accepted
---@return string|nil err Failure reason when request validation fails
function MODULE:SetSteamIDUsergroup(actor, identifier, usergroup, callback)
    if ( !SERVER ) then return false, "Usergroups can only be changed on the server." end

    local steamID64 = self:NormalizeSteamID64(identifier)
    if ( !steamID64 ) then
        NotifyCallback(callback, false, nil, "Invalid SteamID64 or SteamID.")
        return false, "Invalid SteamID64 or SteamID."
    end

    local onlineTarget = player.GetBySteamID64(steamID64)
    if ( ax.util:IsValidPlayer(onlineTarget) ) then
        return self:SetPlayerUsergroup(actor, onlineTarget, usergroup, callback)
    end

    local normalizedID, group, err = self:NormalizeUsergroup(usergroup)
    if ( !normalizedID or !istable(group) ) then
        NotifyCallback(callback, false, nil, err or "Unknown usergroup.")
        return false, err or "Unknown usergroup."
    end

    if ( ax.util:IsValidPlayer(actor) and actor:SteamID64() == steamID64 ) then
        NotifyCallback(callback, false, nil, "You cannot manage your own offline usergroup. Use the server console for self changes.")
        return false, "You cannot manage your own offline usergroup."
    end

    local query = mysql:Select("ax_players")
        query:Where("steamid64", steamID64)
        query:Callback(function(result)
            if ( result == false ) then
                NotifyCallback(callback, false, nil, "Failed to query player data.")
                return
            end

            local row = istable(result) and result[1] or nil
            if ( !istable(row) ) then
                NotifyCallback(callback, false, nil, "No player data exists for that SteamID64.")
                return
            end

            local oldGroup = self:NormalizeUsergroup(row.usergroup) or "user"

            if ( ax.util:IsValidPlayer(actor) ) then
                if ( self:GetPlayerUsergroupImmunity(actor) <= self:GetUsergroupImmunity(oldGroup) ) then
                    NotifyCallback(callback, false, nil, "You cannot manage an offline player with equal or higher immunity.")
                    return
                end

                if ( self:GetPlayerUsergroupLevel(actor) < (tonumber(group.level) or 0) ) then
                    NotifyCallback(callback, false, nil, "You cannot assign a usergroup above your own access level.")
                    return
                end
            end

            if ( oldGroup == normalizedID ) then
                NotifyCallback(callback, false, nil, "That SteamID64 is already in the " .. normalizedID .. " usergroup.")
                return
            end

            local update = mysql:Update("ax_players")
                update:Where("steamid64", steamID64)
                update:Update("usergroup", normalizedID)
                update:Callback(function(updateResult, status)
                    if ( status == false or updateResult == false ) then
                        NotifyCallback(callback, false, nil, "Failed to update player usergroup.")
                        return
                    end

                    if ( istable(CAMI) and isfunction(CAMI.SignalSteamIDUserGroupChanged) ) then
                        CAMI.SignalSteamIDUserGroupChanged(GetSteamIDFrom64(steamID64), oldGroup, normalizedID, CAMI_SOURCE)
                    end

                    hook.Run("SteamIDUsergroupChanged", steamID64, oldGroup, normalizedID, actor)
                    hook.Run("OnSteamIDUsergroupChanged", steamID64, oldGroup, normalizedID, actor)

                    NotifyCallback(callback, true, {
                        steamid64 = steamID64,
                        old = oldGroup,
                        new = normalizedID,
                    })
                end)
            update:Execute()
        end)
    query:Execute()

    return true
end

MODULE:RegisterUsergroup("user", {
    name = "User",
    description = "Default player access.",
    level = 0,
    immunity = 0,
    color = Color(94, 196, 110),
    bProtected = true,
    bDefault = true,
})

MODULE:RegisterUsergroup("operator", {
    name = "Operator",
    description = "Trusted support staff with limited elevated access.",
    level = 25,
    immunity = 25,
    inherits = "user",
    color = Color(128, 164, 226),
})

MODULE:RegisterUsergroup("admin", {
    name = "Admin",
    description = "General administrator access.",
    level = 50,
    immunity = 50,
    inherits = "operator",
    color = Color(226, 124, 96),
})

MODULE:RegisterUsergroup("superadmin", {
    name = "Super Admin",
    description = "Highest built-in administrator access.",
    level = 100,
    immunity = 100,
    inherits = "admin",
    color = Color(203, 109, 255),
    bProtected = true,
})

if ( SERVER ) then
    concommand.Add("ax_player_set_usergroup", function(client, command, arguments)
        if ( ax.util:IsValidPlayer(client) and !MODULE:CanAccessPrivilege(client, "Parallax - Manage Usergroups", "superadmin") ) then
            client:Notify("You do not have permission to use this command.", "error")
            return
        end

        if ( !istable(arguments) or #arguments < 2 ) then
            local usage = "Usage: ax_player_set_usergroup <player> <usergroup>"
            if ( ax.util:IsValidPlayer(client) ) then
                client:Notify(usage, "info")
            else
                ax.util:Print(usage)
            end

            return
        end

        local target = ax.util:FindPlayer(arguments[1])
        if ( !ax.util:IsValidPlayer(target) ) then
            local message = "You must specify a valid online player. Use /PlySetUsergroupID for offline changes."
            if ( ax.util:IsValidPlayer(client) ) then
                client:Notify(message, "error")
            else
                ax.util:PrintWarning(message)
            end

            return
        end

        MODULE:SetPlayerUsergroup(client, target, arguments[2], function(ok, result, err)
            if ( !ok ) then
                if ( ax.util:IsValidPlayer(client) ) then
                    client:Notify(err or "Failed to set usergroup.", "error")
                else
                    ax.util:PrintWarning(err or "Failed to set usergroup.")
                end

                return
            end

            local actorName = ax.util:IsValidPlayer(client) and client:SteamName() or "Console"
            local message = Format("Set %s's usergroup from %s to %s.", target:SteamName(), result.old, result.new)

            target:Notify(Format("Your usergroup has been set to %s by %s.", result.new, actorName), "info")

            if ( ax.util:IsValidPlayer(client) ) then
                client:Notify(message, "success")
            else
                ax.util:Print(message)
            end
        end)
    end)
end
