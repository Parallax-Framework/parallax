--- Faction library
-- @module ax.faction

function ax.faction:Join(client, factionID, bBypass)
    local faction = self:Get(factionID)
    if ( faction == nil or !istable(faction) ) then
        ax.util:PrintError("Attempted to join an invalid faction!")
        return false
    end

    if ( !bBypass and !self:CanSwitchTo(client, factionID) ) then
        return false
    end

    local oldFaction = self:Get(client:Team())
    if ( istable(oldFaction) and isfunction(oldFaction.OnLeave) ) then
        oldFaction:OnLeave(client)
    end

    client:SetTeam(faction:GetID())

    if ( isfunction(faction.OnJoin) ) then
        faction:OnJoin(client)
    end

    hook.Run("PlayerJoinedFaction", client, factionID, oldFaction.GetID and oldFaction:GetID())
    return true
end