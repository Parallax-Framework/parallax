local CLASS = ax.class.meta or {}
CLASS.__index = CLASS

function CLASS:__tostring()
    return "class[" .. self:GetID() .. "][" .. self:GetUniqueID() .. "]"
end

function CLASS:__eq(other)
    return self.ID == other.ID
end

function CLASS:GetID()
    return self.ID
end

function CLASS:GetPlayer()
    return team.GetPlayers(self:GetID())
end

function CLASS:GetName()
    return self.Name or "Unknown Class"
end

function CLASS:GetUniqueID()
    return self.UniqueID or "unknown_class"
end

function CLASS:GetDescription()
    return self.Description or "No description available."
end

function CLASS:GetFaction()
    return ax.faction:Get(self.Faction)
end

function CLASS:GetIsDefault()
    return self.IsDefault or false
end