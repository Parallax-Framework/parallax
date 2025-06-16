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

local PLAYER = FindMetaTable("Player")

--- Gets the character associated with the player.
-- @treturn table|nil The character object if it exists, or nil.
function PLAYER:GetCharacter()
    return self:GetTable().axCharacter
end

PLAYER.GetChar = PLAYER.GetCharacter

--- Gets all characters associated with the player.
-- @treturn table A table of all characters associated with the player.
function PLAYER:GetCharacters()
    return self:GetTable().axCharacters or {}
end

PLAYER.GetChars = PLAYER.GetCharacters

--- Gets the ID of the character associated with the player.
-- @treturn number|nil The character ID if it exists, or nil.
function PLAYER:GetCharacterID()
    local character = self:GetCharacter()
    if ( character ) then
        return character:GetID()
    end

    return nil
end

PLAYER.GetCharID = PLAYER.GetCharacterID

PLAYER.SteamName = PLAYER.SteamName or PLAYER.Name

--- Gets the player's name, prioritizing the character's name if available.
-- @treturn string The player's name or the character's name.
function PLAYER:Name()
    local character = self:GetCharacter()
    if ( character ) then
        return character:GetName()
    end

    return self:SteamName()
end

PLAYER.Nick = PLAYER.Name

--- Sends a chat message to the player.
-- @realm shared
-- @param ... The message components to send.
function PLAYER:ChatText(...)
    local arguments = {ax.color:Get("text"), ...}

    if ( SERVER ) then
        ax.net:Start(self, "chat.text", arguments)
    else
        chat.AddText(unpack(arguments))
    end
end

PLAYER.ChatPrint = PLAYER.ChatText

--- Displays a caption to the player.
-- @realm shared
-- @param arguments The caption arguments.
function PLAYER:Caption(arguments)
    if ( SERVER ) then
        ax.net:Start(self, "caption", arguments)
    else
        gui.AddCaption(arguments)
    end
end

--- Plays a gesture animation on the player.
-- @realm shared
-- @string name The name of the gesture to play.
function PLAYER:GesturePlay(name)
    if ( SERVER ) then
        ax.net:Start(self, "gesture.play", name)
    else
        self:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, self:LookupSequence(name), 0, true)
    end
end

--- Gets the position where the player is aiming to drop an item.
-- @realm shared
-- @tparam[opt=64] number offset The offset distance for the drop position.
-- @treturn Vector The position where the item will be dropped.
function PLAYER:GetDropPosition(offset)
    if ( offset == nil ) then offset = 64 end

    local trace = util.TraceLine({
        start = self:GetShootPos(),
        endpos = self:GetShootPos() + self:GetAimVector() * offset,
        filter = self
    })

    return trace.HitPos + trace.HitNormal
end

--- Checks if the player has a specific whitelist.
-- @realm shared
-- @tparam string identifier The identifier of the whitelist.
-- @treturn boolean Whether the player has the whitelist.
function PLAYER:HasWhitelist(identifier)
    local whitelists = self:GetData("whitelists_" .. SCHEMA.Folder, {}) or {}
    local whitelist = whitelists[identifier]

    return whitelist != nil and whitelist != false
end

--- Sends a notification to the player.
-- @realm shared
-- @tparam string text The notification text.
-- @tparam[opt] number iType The type of notification (e.g., NOTIFY_GENERIC).
-- @tparam[opt=3] number duration The duration of the notification in seconds.
function PLAYER:Notify(text, iType, duration)
    if ( !text or text == "" ) then return end

    if ( !iType and string.EndsWith(text, "!") ) then
        iType = NOTIFY_ERROR
    elseif ( !iType and string.EndsWith(text, "?") ) then
        iType = NOTIFY_HINT
    else
        iType = iType or NOTIFY_GENERIC
    end

    duration = duration or 3

    ax.notification:Send(self, text, iType, duration)
end

ax.alwaysRaised = ax.alwaysRaised or {}
ax.alwaysRaised["gmod_tool"] = true
ax.alwaysRaised["gmod_camera"] = true
ax.alwaysRaised["weapon_physgun"] = true

--- Checks if the player's weapon is raised.
-- @realm shared
-- @treturn boolean Whether the player's weapon is raised.
function PLAYER:IsWeaponRaised()
    if ( ax.config:Get("weapon.raise.alwaysraised", false) ) then return true end

    local weapon = self:GetActiveWeapon()
    if ( IsValid(weapon) and ( ax.alwaysRaised[weapon:GetClass()] or weapon.AlwaysRaised ) ) then return true end

    return self:GetRelay("bWeaponRaised", false)
end

if ( CLIENT ) then
    --- Checks if the player is in darkness.
    -- @realm client
    -- @tparam[opt=0.5] number factor The light level threshold.
    -- @treturn boolean Whether the player is in darkness.
    function PLAYER:InDarkness(factor)
        if ( !isnumber(factor) ) then factor = 0.5 end

        local lightLevel = render.GetLightColor(self:GetPos()):Length()
        return lightLevel < factor
    end
end

local developers = {
    ["76561197963057641"] = true,
    ["76561198373309941"] = true,
}

--- Checks if the player is a developer.
-- @realm shared
-- @treturn boolean Whether the player is a developer.
function PLAYER:IsDeveloper()
    return hook.Run("IsPlayerDeveloper", self) or developers[self:SteamID64()] or false
end

--- Checks if the player is running.
-- @realm shared
-- @treturn boolean Whether the player is running.
function PLAYER:IsRunning()
    if ( !IsValid(self) ) then return false end

    local velocity = self:GetVelocity()
    local speed = velocity:Length()

    return speed > self:GetWalkSpeed() * 1.2
end

--- Checks if the player's model is female.
-- @realm shared
-- @treturn boolean Whether the player's model is female.
function PLAYER:IsFemale()
    local model = string.lower(self:GetModel())
    if ( !isstring(model) or model == "" ) then return false end

    if ( ax.util:FindString(model, "female") or ax.util:FindString(model, "alyx") or ax.util:FindString(model, "mossman") ) then
        return true
    end

    return false
end

--- Gets the faction data associated with the player.
-- @realm shared
-- @treturn table|nil The faction data if found, or nil.
function PLAYER:GetFactionData()
    local character = self:GetCharacter()
    if ( !character ) then return end

    return character:GetFactionData()
end

--- Gets the class data associated with the player.
-- @realm shared
-- @treturn table|nil The class data if found, or nil.
function PLAYER:GetClassData()
    local character = self:GetCharacter()
    if ( !character ) then return end

    return character:GetClassData()
end

--- Gets a specific inventory by name.
-- @realm shared
-- @tparam string name The name of the inventory.
-- @treturn table|nil The inventory if found, or nil.
function PLAYER:GetInventory(name)
    local character = self:GetCharacter()
    if ( !character ) then return end

    return character:GetInventory(name)
end

--- Gets a specific inventory by ID.
-- @realm shared
-- @tparam number id The ID of the inventory.
-- @treturn table|nil The inventory if found, or nil.
function PLAYER:GetInventoryByID(id)
    local character = self:GetCharacter()
    if ( !character ) then return end

    return character:GetInventoryByID(id)
end