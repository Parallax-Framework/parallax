--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

-- Usergroup management data
if (SERVER) then
    MODULE.CustomUsergroups = MODULE.CustomUsergroups or {}
    MODULE.PlayerUsergroups = MODULE.PlayerUsergroups or {}
    MODULE.TempUsergroups = MODULE.TempUsergroups or {}

    --- Deletes a usergroup
    -- @param name string - Group name
    -- @param admin Player - Admin who deleted the group
    function MODULE:DeleteUsergroup(name, admin)
        local usergroup = self.CustomUsergroups[name]
        if (!usergroup) then return false end

        -- Move all players with this group to user
        for _, ply in player.Iterator() do
            if (ply:GetUserGroup() == name) then
                self:SetPlayerUsergroup(ply, "user", 0, "Group deleted", admin)
            end
        end

        -- Remove from systems
        CAMI.UnregisterUsergroup(name, "Parallax")
        self.CustomUsergroups[name] = nil
        self.Groups[name] = nil

        self:SaveData()
        self:LogAction(admin, "deleted usergroup", nil, "Deleted usergroup: " .. name)

        -- Broadcast to all admins
        self:BroadcastUsergroupUpdate()

        return true
    end

    --- Sets a player's usergroup with optional duration
    -- @param player Player - Target player
    -- @param groupName string - Group name
    -- @param duration number - Duration in minutes (0 = permanent)
    -- @param reason string - Reason for change
    -- @param admin Player - Admin who made the change
    function MODULE:SetPlayerUsergroup(player, groupName, duration, reason, admin)
        local oldGroup = player:GetUserGroup()
        local steamID = player:SteamID64()

        -- Clear any existing temp usergroup
        if (self.TempUsergroups[steamID]) then
            timer.Remove("TempUsergroup_" .. steamID)
            self.TempUsergroups[steamID] = nil
        end

        -- Set the usergroup
        player:SetUserGroup(groupName)

        -- Store permanent usergroup change
        self.PlayerUsergroups[steamID] = {
            group = groupName,
            setBy = IsValid(admin) and admin:SteamID64() or "Console",
            setByName = IsValid(admin) and admin:SteamName() or "Console",
            reason = reason or "No reason provided",
            timestamp = os.time()
        }

        -- Handle temporary usergroup
        if (duration and duration > 0) then
            self.TempUsergroups[steamID] = {
                originalGroup = oldGroup,
                tempGroup = groupName,
                expires = os.time() + (duration * 60),
                reason = reason,
                setBy = IsValid(admin) and admin:SteamID64() or "Console"
            }

            -- Create timer to revert
            timer.Create("TempUsergroup_" .. steamID, duration * 60, 1, function()
                if (IsValid(player)) then
                    player:SetUserGroup(oldGroup)
                    self:LogAction(nil, "temp usergroup expired", player, "Reverted from " .. groupName .. " to " .. oldGroup)
                    ax.notification:Send(player, "Your temporary usergroup has expired. Reverted to " .. oldGroup)
                end
                self.TempUsergroups[steamID] = nil
            end)
        end

        -- Signal CAMI
        CAMI.SignalUserGroupChanged(player, oldGroup, groupName, "Parallax")

        self:SaveData()
        self:LogAction(admin, "set usergroup", player, "Changed from " .. oldGroup .. " to " .. groupName .. " - " .. reason, duration)

        -- Broadcast usergroup update
        net.Start("ax.admin.group.update")
            net.WriteString(steamID)
            net.WriteString(groupName)
            net.WriteTable(self.Groups)
        net.Broadcast()
    end

    --- Creates a new usergroup
    -- @param name string - Group name
    -- @param inherits string - Group to inherit from
    -- @param level number - Hierarchy level
    -- @param color Color - Group color
    -- @param immunity number - Immunity level
    -- @param admin Player - Admin who created the group
    function MODULE:CreateUsergroup(name, inherits, level, color, immunity, admin)
        local usergroup = {
            Name = name,
            Inherits = inherits or "user",
            Level = level or 1,
            Color = color or Color(255, 255, 255),
            Immunity = immunity or 0,
            Custom = true,
            Creator = IsValid(admin) and admin:SteamID64() or "Console",
            Created = os.time()
        }

        -- Register with CAMI
        CAMI.RegisterUsergroup({
            Name = name,
            Inherits = inherits or "user"
        }, "Parallax")

        -- Store in our system
        self.CustomUsergroups[name] = usergroup
        self.Groups[name] = usergroup

        self:SaveData()
        self:LogAction(admin, "created usergroup", nil, "Created usergroup: " .. name)

        -- Broadcast to all admins
        self:BroadcastUsergroupUpdate()
    end

    --- Edits an existing usergroup
    -- @param name string - Group name
    -- @param data table - New data
    -- @param admin Player - Admin who edited the group
    function MODULE:EditUsergroup(name, data, admin)
        local usergroup = self.CustomUsergroups[name] or self.Groups[name]
        if (!usergroup) then return false end

        -- Update data
        if (data.Inherits) then usergroup.Inherits = data.Inherits end
        if (data.Level) then usergroup.Level = data.Level end
        if (data.Color) then usergroup.Color = data.Color end
        if (data.Immunity) then usergroup.Immunity = data.Immunity end

        -- Update CAMI registration
        CAMI.RegisterUsergroup({
            Name = name,
            Inherits = usergroup.Inherits
        }, "Parallax")

        self:SaveData()
        self:LogAction(admin, "edited usergroup", nil, "Edited usergroup: " .. name)

        -- Broadcast to all admins
        self:BroadcastUsergroupUpdate()

        return true
    end
end


--- Checks if an admin can assign a specific usergroup
-- @param admin Player - Admin player
-- @param groupName string - Group name to check
-- @return boolean - Can assign
function MODULE:CanAssignGroup(admin, groupName)
    if (!IsValid(admin)) then return true end

    local adminGroup = self.Groups[admin:GetUserGroup()]
    local targetGroup = self.Groups[groupName]

    if (!adminGroup or !targetGroup) then return false end

    -- Admins can only assign groups at or below their level
    return adminGroup.Level >= targetGroup.Level
end

--- Broadcasts usergroup updates to all clients
function MODULE:BroadcastUsergroupUpdate()
    if (!SERVER) then return end

    net.Start("ax.admin.group.update")
        net.WriteString("")
        net.WriteString("")
        net.WriteTable(self.Groups)
    net.Broadcast()
end

--- Gets all custom usergroups
-- @return table - Custom usergroups
function MODULE:GetCustomUsergroups()
    return self.CustomUsergroups or {}
end

--- Gets temporary usergroups
-- @return table - Temporary usergroups
function MODULE:GetTempUsergroups()
    return self.TempUsergroups or {}
end