--[[--
Physical representation of connected player.

`Player`s are a type of `Entity`. They are a physical representation of a `Character` - and can possess at most one `Character`
object at a time that you can interface with.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Player) for all other methods that the `Player` class has.
]]
-- @classmod Player

local PLAYER = FindMetaTable("Player")

function PLAYER:GetCharacter()
    return self:GetTable().axCharacter
end

PLAYER.GetChar = PLAYER.GetCharacter

function PLAYER:GetCharacters()
    return self:GetTable().axCharacters or {}
end

PLAYER.GetChars = PLAYER.GetCharacters

function PLAYER:GetCharacterID()
    local character = self:GetCharacter()
    if ( character ) then
        return character:GetID()
    end

    return nil
end

PLAYER.GetCharID = PLAYER.GetCharacterID

PLAYER.SteamName = PLAYER.SteamName or PLAYER.Name

function PLAYER:Name()
    local character = self:GetCharacter()
    if ( character ) then
        return character:GetName()
    end

    return self:SteamName()
end

PLAYER.Nick = PLAYER.Name

function PLAYER:ChatText(...)
    local arguments = {ax.color:Get("text"), ...}

    if ( SERVER ) then
        ax.net:Start(self, "chat.text", arguments)
    else
        chat.AddText(unpack(arguments))
    end
end

PLAYER.ChatPrint = PLAYER.ChatText

--- Plays a gesture animation on the player.
-- @realm shared
-- @string name The name of the gesture to play
-- @usage player:GesturePlay("taunt_laugh")
function PLAYER:GesturePlay(name)
    if ( SERVER ) then
        ax.net:Start(self, "gesture.play", name)
    else
        self:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, self:LookupSequence(name), 0, true)
    end
end

function PLAYER:GetDropPosition(offset)
    if ( offset == nil ) then offset = 64 end

    local trace = util.TraceLine({
        start = self:GetShootPos(),
        endpos = self:GetShootPos() + self:GetAimVector() * offset,
        filter = self
    })

    return trace.HitPos + trace.HitNormal
end

function PLAYER:HasWhitelist(identifier)
    if ( bSchema == nil ) then bSchema = true end

    local whitelists = self:GetData("whitelists_" .. SCHEMA.Folder, {}) or {}
    local whitelist = whitelists[identifier]

    return whitelist != nil and whitelist != false
end

function PLAYER:Notify(text, iType, length)
    if ( !text or text == "" ) then return end

    if ( !iType and string.EndsWith(text, "!") ) then
        iType = NOTIFY_ERROR
    elseif ( !iType and string.EndsWith(text, "?") ) then
        iType = NOTIFY_HINT
    else
        iType = iType or NOTIFY_GENERIC
    end

    duration = duration or 3

    ax.notification:Send(self, text, iType, length)
end

ax.alwaysRaised = ax.alwaysRaised or {}
ax.alwaysRaised["gmod_tool"] = true
ax.alwaysRaised["gmod_camera"] = true
ax.alwaysRaised["weapon_physgun"] = true

function PLAYER:IsWeaponRaised()
    if ( ax.config:Get("weapon.raise.alwaysraised", false) ) then return true end

    local weapon = self:GetActiveWeapon()
    if ( IsValid(weapon) and ( ax.alwaysRaised[weapon:GetClass()] or weapon.AlwaysRaised ) ) then return true end

    return self:GetRelay("bWeaponRaised", false)
end

if ( CLIENT ) then
    function PLAYER:InDarkness(factor)
        if ( !isnumber(factor) ) then factor = 0.5 end

        local lightLevel = render.GetLightColor(self:GetPos()):Length()
        return lightLevel < factor
    end
end

local developers = {
    ["76561197963057641"] = true
}

function PLAYER:IsDeveloper()
    return hook.Run("IsPlayerDeveloper", self) or developers[self:SteamID64()] or false
end

--- Checks if the player's model is female.
-- @realm shared
-- @return boolean Returns true if the player's model has "female", "alyx", or "mossman" in its name (animations module: if "citizen_female" is used for the model).
function PLAYER:IsFemale()
    local model = string.lower(self:GetModel())
    if ( !isstring(model) or model == "" ) then return false end

    if ( ax.util:FindString(model, "female") or ax.util:FindString(model, "alyx") or ax.util:FindString(model, "mossman") ) then
        return true
    end

    return false
end

--- Checks if the player is running.
-- @realm shared
-- @return boolean Returns true if the player is running (i.e., moving faster than walking speed).

function PLAYER:IsRunning()
    if ( !IsValid(self) ) then return false end

    local velocity = self:GetVelocity()
    local speed = velocity:Length()

    return speed > self:GetWalkSpeed() * 1.2
end