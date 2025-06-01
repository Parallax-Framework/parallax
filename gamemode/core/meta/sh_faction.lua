local FACTION = ax.faction.meta or {}
FACTION.__index = FACTION

local defaultModels = {
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

function FACTION:__tostring()
    return "faction[" .. self:GetID() .. "][" .. self:GetUniqueID() .. "]"
end

function FACTION:__eq(other)
    return self.ID == other.ID
end

function FACTION:GetID()
    return self.ID
end

function FACTION:GetPlayer()
    return team.GetPlayers(self:GetID())
end

function FACTION:GetName()
    return self.Name or "Unknown Faction"
end

function FACTION:GetUniqueID()
    return self.UniqueID or "unknown_faction"
end

function FACTION:GetDescription()
    return self.Description or "No description available."
end

function FACTION:GetColor()
    return self.Color or ax.color:Get("white")
end

function FACTION:GetModels()
    return self.Models or defaultModels
end

function FACTION:GetClasses()
    local classes = {}
    for k, v in ipairs(ax.class.instances) do
        if ( v.Faction == self:GetID() ) then
            table.insert(classes, v)
        end
    end

    return classes
end