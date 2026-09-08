--- Opens a server-filtered action menu for a dropped item.
---@realm client
---@param entity Entity
---@param itemID number
---@param entries table
---@param canTake boolean
---@param reason? string
function ax.item:ShowWorldActions(entity, itemID, entries, canTake, reason)
    if ( !IsValid(entity) or entity:GetItemID() != itemID ) then return end
    local menu = DermaMenu()
    local function RunAction(key)
        ax.net:Start("item.world.action", entity, itemID, key)
    end

    local pickup = menu:AddOption("Pick up", function() RunAction("take") end)
    pickup:SetEnabled(canTake)
    if ( isstring(reason) ) then pickup:SetTooltip(reason) end
    for i = 1, #entries do
        local entry = entries[i]
        local option = menu:AddOption(entry.name, function() RunAction(entry.key) end)
        if ( isstring(entry.icon) ) then option:SetIcon(entry.icon) end
    end

    local baseThink = menu.Think
    menu.Think = function(panel)
        if ( isfunction(baseThink) ) then baseThink(panel) end
        local client = LocalPlayer()
        if ( !IsValid(entity) or !IsValid(client) or !client:Alive() or client:IsRagdolled() ) then
            panel:Remove()
            return
        end

        local trace = util.TraceLine({
            start = client:GetShootPos(),
            endpos = client:GetShootPos() + client:GetAimVector() * 96,
            filter = client,
        })
        if ( entity:GetItemID() != itemID or trace.Entity != entity ) then panel:Remove() end
    end
    menu:Open(ScrW() / 2, ScrH() / 2)
end

ax.net:Hook("item.world.menu", function(entity, itemID, entries, canTake, reason)
    ax.item:ShowWorldActions(entity, itemID, entries, canTake, reason)
end)
