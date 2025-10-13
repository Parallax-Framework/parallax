--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function GM:Initialize()
    ax.util:IncludeDirectory("parallax/gamemode/localization", true)
    ax.faction:Include("parallax/gamemode/factions")
    ax.class:Include("parallax/gamemode/classes")
    ax.item:Include("parallax/gamemode/items")
    ax.module:Include("parallax/gamemode/modules")
    ax.schema:Initialize()

    if ( CLIENT ) then
        ax.font:Load()
    end
end

local reloaded = false
function GM:OnReloaded()
    if ( reloaded ) then return end
    reloaded = true

    ax.util:IncludeDirectory("parallax/gamemode/localization", true)
    ax.faction:Include("parallax/gamemode/factions")
    ax.class:Include("parallax/gamemode/classes")
    ax.item:Include("parallax/gamemode/items")
    ax.module:Include("parallax/gamemode/modules")
    ax.schema:Initialize()

    if ( CLIENT ) then
        ax.font:Load()
    end
end

function GM:CanBecomeFaction(factionTable, client)
    local whitelists = client:GetData("whitelists", {})
    print("Checking faction:", factionTable.id, "isDefault:", factionTable.isDefault)
    if ( !factionTable.isDefault and !whitelists[factionTable.id] ) then
        return false, "You are not whitelisted for this faction."
    end

    return true, nil
end

function GM:CanBecomeClass(classTable, client)
    return true, nil
end

function GM:CanLoadCharacter(client, character)
    return true
end

function GM:InitPostEntity()
    if ( SERVER ) then
        ax.database:Connect() -- TODO: Allow schemas to connect to their own databases

        local groundItems = ax.data:Get("world_items", {}, { scope = "map", human = true })
        for itemID, v in pairs(groundItems) do
            ax.item:Instance(itemID, v.class)

            local entity = ents.Create("ax_item")
            entity:SetItemID(itemID)
            entity:SetItemClass(v.class)
            entity:SetPos(v.position)
            entity:SetAngles(v.angles)
            entity:Spawn()
            entity:Activate()

            net.Start("ax.item.spawn")
                net.WriteUInt(itemID, 32)
                net.WriteString(v.class)
                net.WriteTable(v.data or {})
            net.Broadcast()
        end
    else
        ax.joinTime = os.time()
    end
end

function GM:CanPlayerInteractItem( client, item, action )
end
