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

AX_CONVAR_HOTRELOAD = AX_CONVAR_HOTRELOAD or CreateConVar("ax_hotreload", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Enable or disable hot-reloading of Parallax Framework components.")
AX_CONVAR_HOTRELOAD_TIME = AX_CONVAR_HOTRELOAD_TIME or CreateConVar("ax_hotreload_time", "60", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Time in seconds to use as a filter when hot-reloading. Set to 0 to disable filtering.")

local function OnHotReloadOnce()
    local timeFilter = AX_CONVAR_HOTRELOAD:GetBool() and AX_CONVAR_HOTRELOAD_TIME:GetInt() or nil
    if ( timeFilter ) then
        ax.util:PrintDebug("OnReloaded: Using time filter of " .. timeFilter .. " seconds for hot-reload optimization")
    end

    ax.util:IncludeDirectory("parallax/gamemode/localization", true, nil, timeFilter)
    ax.faction:Include("parallax/gamemode/factions", timeFilter)
    ax.class:Include("parallax/gamemode/classes", timeFilter)
    ax.item:Include("parallax/gamemode/items", timeFilter)
    ax.module:Include("parallax/gamemode/modules", timeFilter)
    ax.schema:Initialize(timeFilter)

    if ( CLIENT ) then
        ax.font:Load()
    end
end

local DEBOUNCE = 0.15
local NAME = "ax.reload.debounce." .. (SERVER and "sv" or CLIENT and "cl")
hook.Add("OnReloaded", NAME, function()
    local r = ax._reload or { pingAt = 0, armed = false, frame = -1 }
    local now = SysTime()

    if ( r.frame == FrameNumber() ) then
        ax.util:PrintDebug("OnReloaded: Already processed this frame, skipping")
        return
    end

    r.frame = FrameNumber()
    r.pingAt = now

    if ( r.armed ) then
        ax.util:PrintDebug("OnReloaded: Reload already armed, skipping re-arming")
        return
    end

    r.armed = true

    timer.Create(NAME, 0.05, 0, function()
        if ( SysTime() - r.pingAt >= DEBOUNCE ) then
            timer.Remove(NAME)
            r.armed = false
            OnHotReloadOnce()
        end
    end)
end)

function GM:CanBecomeFaction(factionTable, client)
    local whitelists = client:GetData("whitelists", {})
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
            entity:SetRelay("itemID", itemID)
            entity:SetRelay("itemClass", v.class)
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

function GM:ShowHelp(client)
    return false
end

function GM:ShowTeam(client)
    return false
end

function GM:ShowSpare1(client)
    return false
end

function GM:ShowSpare2(client)
    return false
end
