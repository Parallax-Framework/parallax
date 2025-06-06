--- Faction library
-- @module ax.faction

ax.faction = ax.faction or {}
ax.faction.stored = {}
ax.faction.instances = {}
ax.faction.meta = ax.faction.meta or {}

function ax.faction:Register(factionData)
    local FACTION = setmetatable(factionData, self.meta)

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
    FACTION.ID = #self.instances + 1

    table.insert(self.instances, FACTION)

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
        if ( identifier < 1 or identifier > #self.instances ) then
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

    if ( isnumber(oldFactionID) ) then
        local oldFaction = self:Get(oldFactionID)
        if ( oldFaction ) then
            if ( oldFaction.ID == faction.ID ) then return false end

            if ( isfunction(oldFaction.CanLeave) and !oldFaction:CanLeave(client) ) then
                return false, "You cannot leave this faction."
            end
        end
    end

    local hookRun = hook.Run("CanPlayerJoinFaction", client, factionID)
    if ( hookRun != nil and hookRun == false ) then return false end

    if ( isfunction(faction.CanSwitchTo) and !faction:CanSwitchTo(client) ) then
        return false, "You cannot switch to this faction."
    end

    if ( !faction.IsDefault and !client:HasWhitelist(faction.UniqueID) ) then
        return false, "You do not have permission to join this faction."
    end

    return true
end

function ax.faction:GetAll()
    return self.instances
end