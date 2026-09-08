--- Validates a player's access to a dropped item before presenting or executing actions.
---@realm server
---@param client Player
---@param entity Entity
---@param item table
---@return boolean
function ax.item:CanInteractWorld(client, entity, item)
    if ( !ax.util:IsValidPlayer(client) or !client:Alive() or client:IsRagdolled() ) then return false end
    if ( !istable(client:GetCharacter()) ) then return false end
    if ( !IsValid(entity) or entity:GetClass() != "ax_item" ) then return false end
    if ( entity:GetItemTable() != item or item:GetInventoryID() != 0 or item:IsLocked() ) then return false end
    local entityData = entity:GetTable()
    if ( entityData.axTakeInProgress or entityData.axPickupPending or entityData.axItemRemoving ) then return false end

    local trace = util.TraceLine({
        start = client:GetShootPos(),
        endpos = client:GetShootPos() + client:GetAimVector() * 96,
        filter = client,
    })

    return trace.Entity == entity
end

--- Sends the available world actions, returning false when ordinary pickup should run instead.
---@realm server
---@param client Player
---@param entity Entity
---@return boolean
function ax.item:OpenWorldActions(client, entity)
    local item = entity:GetItemTable()
    if ( !istable(item) or !self:CanInteractWorld(client, entity, item) ) then return true end

    local context = { entity = entity, source = "world_menu" }
    local entries = {}
    for key, action in pairs(item:GetActions()) do
        if ( key == "take" or action.world != true ) then continue end
        if ( !item:CanInteract(client, key, true, context) ) then continue end
        entries[#entries + 1] = {
            key = key,
            name = tostring(action.name or key),
            icon = action.icon,
            order = tonumber(action.order) or 0,
        }
    end

    if ( #entries == 0 ) then return false end
    if ( !client:RateLimit("inventory.world.menu", 0.2) ) then return true end

    table.sort(entries, function(a, b)
        if ( a.order == b.order ) then return a.key < b.key end
        return a.order < b.order
    end)

    local canTake, reason = item:CanInteract(client, "take", true, context)
    ax.net:Start(client, "item.world.menu", entity, item.id, entries, canTake == true, reason)
    return true
end

--- Deletes a world item's persisted record before removing its entity and instance.
---@realm server
---@param item table
---@param callback? function
---@return boolean
function ax.item:RemoveWorldItem(item, callback)
    if ( item:GetInventoryID() != 0 or item:IsLocked() or self.instances[item.id] != item ) then
        if ( isfunction(callback) ) then callback(false) end
        return false
    end

    item:Lock()
    local query = mysql:Delete("ax_items")
    query:Where("id", item.id)
    query:Callback(function(result)
        if ( result == false ) then
            item:Unlock()
            if ( isfunction(callback) ) then callback(false) end
            return
        end

        if ( isfunction(item.Call) ) then item:Call("OnRemoved") end
        for _, entity in ipairs(ents.FindByClass("ax_item")) do
            if ( entity:GetItemID() != item.id ) then continue end
            entity:GetTable().axItemRemoving = true
            SafeRemoveEntity(entity)
        end

        local world = ax.inventory.instances[0]
        if ( istable(world) and istable(world.items) ) then world.items[item.id] = nil end
        self.instances[item.id] = nil
        ax.net:Start(nil, "inventory.item.remove", 0, item.id)
        if ( isfunction(callback) ) then callback(true) end
    end)
    query:Execute()
    return true
end
