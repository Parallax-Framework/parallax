--- Faction library
-- @module ax.faction

local DEFAULT_MODELS = {
    Model("models/player/group01/female_01.mdl"),
    Model("models/player/group01/female_02.mdl"),
    Model("models/player/group01/female_03.mdl"),
    Model("models/player/group01/female_04.mdl"),
    Model("models/player/group01/female_05.mdl"),
    Model("models/player/group01/female_06.mdl"),
    Model("models/player/group01/male_01.mdl"),
    Model("models/player/group01/male_02.mdl"),
    Model("models/player/group01/male_03.mdl"),
    Model("models/player/group01/male_04.mdl"),
    Model("models/player/group01/male_05.mdl"),
    Model("models/player/group01/male_06.mdl"),
    Model("models/player/group01/male_07.mdl"),
    Model("models/player/group01/male_08.mdl"),
    Model("models/player/group01/male_09.mdl")
}

ax.faction = ax.faction or {}
ax.faction.stored = {}
ax.faction.instances = {}

ax.faction.meta = {
    GetName = function(self)
        return self.Name or "Unknown Faction"
    end,
    GetDescription = function(self)
        return self.Description or "No description available."
    end,
    GetModels = function(self)
        return self.Models or DEFAULT_MODELS
    end,
    GetColor = function(self)
        return self.Color or ax.color:Get("white")
    end,
    GetID = function(self)
        return self.ID or 0
    end,
    GetUniqueID = function(self)
        return self.UniqueID or "unknown_faction"
    end,
    GetIsDefault = function(self)
        return self.IsDefault or false
    end,
    GetClasses = function(self)
        local classes = {}
        for k, v in ipairs(ax.class:GetAll()) do
            if ( v.Faction == self.ID ) then
                classes[#classes + 1] = v
            end
        end

        return classes
    end,

    __tostring = function(self)
        return "faction[" .. self:GetUniqueID() .. "][" .. self:GetID() .. "]"
    end,
    __eq = function(self, other)
        if ( isstring(other) ) then
            return self:GetUniqueID() == other
        end

        if ( isnumber(other) ) then
            return self:Get() == other
        end

        if ( type(other) == "Player" ) then
            return self:Get() == other:GetFaction()
        end

        return false
    end,
}

ax.faction.meta.__index = ax.faction.meta

local default = {
    Name = "Unknown Faction",
    Description = "No description available.",
    Models = DEFAULT_MODELS,
    IsDefault = false,
    Color = ax.color:Get("white"),
    Classes = {},
}

function ax.faction:Register(factionData)
    local FACTION = setmetatable(factionData, { __index = ax.faction.meta })

    for k, v in pairs(default) do
        if ( FACTION[k] == nil ) then
            FACTION[k] = v
        end
    end

    local bResult = hook.Run("PreFactionRegistered", FACTION)
    if ( bResult == false ) then
        ax.util:PrintError("Attempted to register a faction that was blocked by a hook!")
        return false, "Attempted to register a faction that was blocked by a hook!"
    end

    local uniqueID = string.lower(string.gsub(FACTION.Name, "%s+", "_"))
    for k, v in ipairs(self.instances) do
        if ( v.UniqueID == uniqueID ) then
            return false, "Attempted to register a faction that already exists!"
        end
    end

    FACTION.UniqueID = FACTION.UniqueID or uniqueID

    table.insert(self.instances, FACTION)
    FACTION.ID = table.Count(self.instances)
    self.stored[FACTION.UniqueID] = FACTION

    team.SetUp(FACTION.ID, FACTION.Name, FACTION.Color, false)
    hook.Run("PostFactionRegistered", FACTION)

    return FACTION.ID
end

function ax.faction:Get(identifier)
    if ( identifier == nil ) then
        return false, "Attempted to get a faction without an identifier!"
    end

    if ( isnumber(identifier) ) then
        if ( identifier < 1 ) then
            ax.util:PrintError("Attempted to get a faction with an invalid ID!")
            return false, "Attempted to get a faction with an invalid ID!"
        end

        return self.instances[identifier]
    elseif ( isstring(identifier) ) then
        if ( self.stored[identifier] ) then
            return self.stored[identifier]
        end

        for k, v in ipairs(self.instances) do
            if ( ax.util:FindString(v.Name, identifier) or ax.util:FindString(v.UniqueID, identifier) ) then
                return v
            end
        end
    end

    return nil
end

function ax.faction:CanSwitchTo(client, factionID, oldFactionID)
    if ( !IsValid(client) ) then
        ax.util:PrintError("Attempted to check if a player can switch to a faction without a client!")
        return false, "Attempted to check if a player can switch to a faction without a client!"
    end

    local faction = self:Get(factionID)
    if ( !faction ) then
        return false, "Faction does not exist."
    end

    if ( oldFactionID ) then
        local oldFaction = self:Get(oldFactionID)
        if ( oldFaction ) then
            if ( oldFaction.ID == faction.ID ) then return false end

            if ( oldFaction.CanLeave and !oldFaction:CanLeave(client) ) then
                return false, "You cannot leave this faction."
            end
        end
    end

    local hookRun = hook.Run("CanPlayerJoinFaction", client, factionID)
    if ( hookRun != nil and hookRun == false ) then return false end

    if ( faction.CanSwitchTo and !faction:CanSwitchTo(client) ) then
        return false, "You cannot switch to this faction."
    end

    if ( !faction.IsDefault and !client:HasWhitelist(faction.UniqueID) ) then
        return false, "You do not have permission to join this faction."
    end

    if ( isfunction(faction.OnSwitch) ) then
        faction:OnSwitch(client)
    end

    return true
end

function ax.faction:GetAll()
    return self.instances
end