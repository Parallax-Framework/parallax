--- Class library
-- @module ax.class

ax.class = {}
ax.class.stored = {}
ax.class.instances = {}

ax.class.meta = {
    GetName = function(self)
        return self.Name or "Unknown Class"
    end,
    GetDescription = function(self)
        return self.Description or "No description available."
    end,
    GetID = function(self)
        return self.ID or 0
    end,
    GetUniqueID = function(self)
        return self.UniqueID or "unknown_class"
    end,
    GetIsDefault = function(self)
        return self.IsDefault or false
    end,
    GetFaction = function(self)
        return self.Faction
    end,

    __tostring = function(self)
        return "class[" .. self:GetUniqueID() .. "][" .. self:GetID() .. "]"
    end,
    __eq = function(self, other)
        if ( isstring(other) ) then
            return self:GetUniqueID() == other
        end

        if ( isnumber(other) ) then
            return self:GetID() == other
        end

        if ( type(other) == "Player" ) then
            return self:GetID() == other:GetID()
        end

        return false
    end,
}

ax.class.meta.__index = ax.class.meta

local default = {
    Name = "Unknown",
    Description = "No description available.",
    IsDefault = false,
    CanSwitchTo = nil,
    OnSwitch = nil
}

function ax.class:Register(classData)
    local CLASS = setmetatable(classData, { __index = ax.class.meta })
    if ( !isnumber(CLASS.Faction) ) then
        ax.util:PrintError("Attempted to register a class without a valid faction!")
        return false
    end

    local faction = ax.faction:Get(CLASS.Faction)
    if ( faction == nil or !istable(faction) ) then
        ax.util:PrintError("Attempted to register a class for an invalid faction!")
        return false
    end

    for k, v in pairs(default) do
        if ( CLASS[k] == nil ) then
            CLASS[k] = v
        end
    end

    local bResult = hook.Run("PreClassRegistered", CLASS)
    if ( bResult == false ) then return false end

    local uniqueID = string.lower(string.gsub(CLASS.Name, "%s+", "_")) .. "_" .. CLASS.Faction
    for k, v in pairs(self.instances) do
        if ( v.UniqueID == uniqueID ) then
            ax.util:PrintError("Attempted to register a class that already exists!")
            return false, "Attempted to register a class that already exists!"
        end
    end

    CLASS.UniqueID = CLASS.UniqueID or uniqueID

    self.stored[CLASS.UniqueID] = CLASS

    for k, v in ipairs(self.instances) do
        if ( v.UniqueID == CLASS.UniqueID ) then
            table.remove(self.instances, k)
            break
        end
    end

    table.insert(self.instances, CLASS)
    CLASS.ID = table.Count(self.instances)
    self.stored[CLASS.UniqueID] = CLASS

    hook.Run("PostClassRegistered", CLASS)

    return CLASS.ID
end

function ax.class:Get(identifier)
    if ( identifier == nil ) then
        ax.util:PrintError("Attempted to get a faction with an invalid identifier!")
        return false
    end

    if ( tonumber(identifier) ) then
        identifier = tonumber(identifier)

        for k, v in ipairs(self.instances) do
            if ( v:GetID() == identifier ) then
                return v
            end
        end

        return nil
    end

    if ( self.stored[identifier] ) then
        return self.stored[identifier]
    end

    for k, v in ipairs(self.instances) do
        if ( ax.util:FindString(v.Name, identifier) or ax.util:FindString(v.UniqueID, identifier) ) then
            return v
        end
    end

    return nil
end

function ax.class:CanSwitchTo(client, classID)
    local class = self:Get(classID)
    if ( !class ) then return false end

    local hookRun = hook.Run("CanPlayerJoinClass", client, class)
    if ( hookRun == false ) then return false end

    if ( isfunction(class.CanSwitchTo) and !class:CanSwitchTo(client) ) then
        return false
    end

    if ( !class.IsDefault ) then
        return false
    end

    return true
end

function ax.class:OnSwitch(client, classID)
    local class = self:Get(classID)
    if ( !class ) then return false end

    local hookRun = hook.Run("CanPlayerJoinClass", client, classID)
    if ( hookRun != nil and hookRun == false ) then return false end

    if ( isfunction(class.OnSwitch) ) then
        class:OnSwitch(client)
    end

    return true
end

function ax.class:GetAll()
    return self.instances
end