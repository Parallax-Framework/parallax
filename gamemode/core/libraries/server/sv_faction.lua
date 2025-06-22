--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Faction library
-- @module ax.faction

function ax.faction:Join(client, factionID, bBypass)
    local faction = self:Get(factionID)
    if ( faction == nil or !istable(faction) ) then
        ax.Util:PrintError("Attempted to join an invalid faction!")
        return false
    end

    if ( !bBypass and !self:CanSwitchTo(client, factionID) ) then
        return false
    end

    local oldFaction = self:Get(client:Team())
    if ( oldFaction.OnLeave ) then
        oldFaction:OnLeave(client)
    end

    client:SetTeam(faction:GetID())

    if ( faction.OnJoin ) then
        faction:OnJoin(client)
    end

    hook.Run("PlayerJoinedFaction", client, factionID, oldFaction.GetID and oldFaction:GetID())
    return true
end

ax.faction = ax.faction