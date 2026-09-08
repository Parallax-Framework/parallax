ax.net:Hook("item.world.action", function(client, entity, itemID, action)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    local delay = math.max(tonumber(ax.config:Get("inventory.action.rate_limit", 0.1)) or 0.1, 0)
    if ( !client:RateLimit("inventory.action", delay) ) then return end
    if ( !isnumber(itemID) or !isstring(action) or #action == 0 or #action > 128 ) then return end
    if ( !IsValid(entity) or entity:GetClass() != "ax_item" or entity:GetItemID() != itemID ) then return end

    local item = entity:GetItemTable()
    if ( !istable(item) or !ax.item:CanInteractWorld(client, entity, item) ) then return end
    ax.item:RunAction(client, item, action, { entity = entity, source = "world_menu" })
end)
