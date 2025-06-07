-- Inventory management library.
-- @module ax.inventory

ax.inventory = ax.inventory or {}
ax.inventory.meta = ax.inventory.meta or {}
ax.inventory.stored = ax.inventory.stored or {}

-- Create an inventory object
function ax.inventory:CreateObject(data)
    if ( !data or !istable(data) ) then
        ax.util:PrintError("Invalid data passed to CreateObject")
        return
    end

    local inventory = setmetatable({}, self.meta)

    inventory.ID = tonumber(data.ID or data.id or 0)
    inventory.CharacterID = tonumber(data.CharacterID or data.character_id or 0)
    inventory.Name = data.Name or data.name or "Inventory"
    inventory.MaxWeight = tonumber(data.MaxWeight or data.max_weight) or ax.config:Get("inventory.max.weight", 20)
    inventory.Items = ax.util:SafeParseTable(data.Items or data.items)
    inventory.Data = ax.util:SafeParseTable(data.Data or data.data)
    inventory.Receivers = ax.util:SafeParseTable(data.Receivers or data.receivers)

    self.stored[inventory.ID] = inventory

    return inventory
end

function ax.inventory:Get(id)
    return tonumber(id) and self.stored[id] or nil
end

function ax.inventory:GetAll()
    return self.stored
end

function ax.inventory:GetByCharacterID(characterID)
    local inventories = {}

    for _, inv in pairs(self.stored) do
        if ( inv:GetOwner() == characterID ) then
            table.insert(inventories, inv)
        end
    end

    return inventories
end