----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function GM:CanDrive(client, entity)
    return false
end

function GM:CanPlayerJoinFaction(client, factionID)
    return true
end

function GM:PrePlayerHandsPickup(client, ent)
    return true
end

function GM:PrePlayerHandsPush(client, ent)
    return true
end

function GM:PlayerGetToolgun(client)
    local character = client:GetCharacter()
    return CAMI.PlayerHasAccess(client, "Parallax - Toolgun", nil) or character and character:HasFlag("t")
end

function GM:PlayerGetPhysgun(client)
    local character = client:GetCharacter()
    return CAMI.PlayerHasAccess(client, "Parallax - Physgun", nil) or character and character:HasFlag("p")
end

function GM:PlayerCanCreateCharacter(client, character)
    return true
end

function GM:PlayerCanDeleteCharacter(client, character)
    return true
end

function GM:PlayerCanLoadCharacter(client, character, currentCharacter)
    return true
end

function GM:CanPlayerTakeItem(client, item)
    return true
end

function GM:ItemCanBeDestroyed(item, damageInfo)
    return true
end

function GM:GetPlayerPainSound(client)
end

function GM:GetPlayerDeathSound(client)
end

function GM:PreOptionChanged(client, key, value)
    local stored = ax.option.stored[key]
    if ( ax.util:DetectType(value) != stored.Type ) then
        ax.util:PrintError("Attempted to set option \"" .. key .. "\" with invalid type!")
        return false
    end

    if ( isnumber(value) ) then
        if ( isnumber(stored.Min) and value < stored.Min ) then
            ax.util:PrintError("Option \"" .. key .. "\" is below minimum value!")
            return false
        end

        if ( isnumber(stored.Max) and value > stored.Max ) then
            ax.util:PrintError("Option \"" .. key .. "\" is above maximum value!")
            return false
        end
    end

    return true
end

function GM:PostOptionChanged(client, key, value)
end

function GM:PlayerCanHearChat(client, listener, uniqueID, text)
    local chatData = ax.chat:Get(uniqueID)
    if ( !istable(chatData) ) then return false end

    local canHear = chatData.CanHear
    if ( isbool(canHear) ) then
        return canHear
    elseif ( isnumber(canHear) ) then
        return client:GetPos():DistToSqr(listener:GetPos()) <= canHear ^ 2
    elseif ( isfunction(canHear) ) then
        return canHear(chatData, client, listener, text)
    end

    return true
end

function GM:PreConfigChanged(key, value, oldValue)
end

function GM:PostConfigChanged(key, value, oldValue, client)
end

function GM:SetupMove(client, mv, cmd)
end

local KEY_SHOOT = IN_ATTACK + IN_ATTACK2
function GM:StartCommand(client, cmd)
    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) or !weapon:IsWeapon() ) then return end

    if ( !client:GetRelay("canShoot", true) or !weapon.FireWhenLowered and !client:IsWeaponRaised() ) then
        cmd:RemoveKey(KEY_SHOOT)
    end
end

function GM:KeyPress(client, key)
    if ( SERVER and key == IN_RELOAD ) then
        timer.Create("ax.weapon.raise." .. client:SteamID64(), ax.config:Get("weapon.raise.time", 1), 1, function()
            if ( IsValid(client) ) then
                client:ToggleWeaponRaise()
            end
        end)
    end
end

function GM:KeyRelease(client, key)
    if ( SERVER and key == IN_RELOAD ) then
        timer.Remove("ax.weapon.raise." .. client:SteamID64())
    end
end

function GM:PlayerSwitchWeapon(client, hOldWeapon, hNewWeapon)
    if ( SERVER ) then
        timer.Simple(0.1, function()
            if ( IsValid(client) and IsValid(hNewWeapon) ) then
                client:SetWeaponRaised(false)
            end
        end)
    end
end

function GM:PreSpawnClientRagdoll(client)
end

function GM:GetGameDescription()
    return "Parallax: " .. (SCHEMA and SCHEMA.Name or "Unknown")
end

function GM:CanTool(client, trace, toolname, tool, button)
    if ( !hook.Run("PlayerGetToolgun", client) ) then
        return false
    end

    return true
end

function GM:PhysgunPickup(client, ent)
    if ( !hook.Run("PlayerGetPhysgun", client) ) then
        return false
    end

    if ( CAMI.PlayerHasAccess(client, "Parallax - Physgun Players", nil) and ent:IsPlayer() ) then
        if ( ent == client ) then
            return false
        end

        if ( ent:Team() == TEAM_SPECTATOR or ent:Team() == TEAM_UNASSIGNED ) then
            return false
        end

        ent:SetMoveType(MOVETYPE_NOCLIP)

        return true
    end

    if ( !IsValid(ent) or ent:EntIndex() <= 0 ) then
        return false
    end

    return true
end

function GM:PhysgunDrop(client, ent)
    if ( !hook.Run("PlayerGetPhysgun", client) ) then
        return false
    end

    if ( !IsValid(ent) or ent:EntIndex() <= 0 ) then
        return false
    end

    if ( ent:IsPlayer() ) then
        ent:SetMoveType(MOVETYPE_WALK)
        return true
    end

    local physicsObject = ent:GetPhysicsObject()
    if ( IsValid(physicsObject) and physicsObject:IsMoveable() ) then
        physicsObject:EnableMotion(true)
        return true
    end

    return false
end

function GM:ShouldCollide(ent1, ent2)
    if ( ent1:GetClass() == "ax_item" ) then
        local itemDef = ax.item:Get(ent1:GetUniqueID())

        if ( !itemDef ) then return end

        if ( ent2:GetClass() == "ax_item" and itemDef.bNoItemsCollision ) then
            return false
        end

        if ( itemDef.ShouldEntityCollide ) then
            return itemDef:ShouldEntityCollide(ent1, ent2)
        end

        return true
    end
end