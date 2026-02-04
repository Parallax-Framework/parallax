--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function GM:Initialize()
    ax.util:IncludeDirectory("parallax/gamemode/localization", true)
    ax.faction:Include("parallax/gamemode/factions")
    ax.class:Include("parallax/gamemode/classes")
    ax.rank:Include("parallax/gamemode/ranks")
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
    ax.rank:Include("parallax/gamemode/ranks", timeFilter)
    ax.item:Include("parallax/gamemode/items", timeFilter)
    ax.module:Include("parallax/gamemode/modules", timeFilter)
    ax.schema:Initialize(timeFilter)

    if ( CLIENT ) then
        ax.font:Load()
    end
end

concommand.Add("ax_hotreload_now", function(client, command, arguments)
    if ( ax.util:IsValidPlayer(client) and !client:IsSuperAdmin() ) then
        ax.util:PrintDebug("ax_hotreload_now: Permission denied for ", client)
        return
    end

    OnHotReloadOnce()
end)

concommand.Add("ax", function(client, cmd, args)
    if ( !istable(args) or args[1] == nil or string.Trim(args[1]) == "" ) then
        if ( CLIENT ) then
            MsgC(Color(255, 100, 100), "ax: No command specified.\n")
        else
            ax.util:PrintWarning("ax: No command specified.")
        end
        return
    end

    local def = ax.command:Find(args[1], false, true)
    if ( def == nil ) then
        if ( CLIENT ) then
            MsgC(Color(255, 100, 100), "ax: Command \"" .. args[1] .. "\" not found.\n")
        else
            ax.util:PrintWarning("ax: Command \"" .. args[1] .. "\" not found.")
        end
        return
    end

    if ( SERVER ) then
        local rawArgs = table.concat(args, " ", 2)
        local ok, result = ax.command:Run(client, def.name, rawArgs)
        if ( !ok ) then
            ax.util:PrintWarning("ax: " .. tostring(result or "Unknown error"))
        elseif ( isstring(result) and result != "" ) then
            ax.util:PrintWarning(tostring(result))
        end
        return
    end

    ax.command:Send("/" .. table.concat(args, " ", 1))
end, function()
    local commands = {}
    for commandName, commandTable in pairs(ax.command.registry) do
        if ( ax.command:HasAccess(ax.client, commandTable) != true ) then continue end

        commands[#commands + 1] = "ax " .. ax.command:Help(commandName)
    end

    table.sort(commands)

    return commands
end)

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

function GM:CanPlayerBecomeFaction(factionTable, client)
    local whitelists = client:GetData("whitelists", {})
    if ( !factionTable.isDefault and !whitelists[factionTable.id] ) then
        return false, "You are not whitelisted for this faction."
    end

    return true, nil
end

function GM:CanPlayerBecomeClass(classTable, client)
    return true, nil
end

function GM:CanPlayerLoadCharacter(client, character, previousCharacter)
    return true
end

function GM:InitPostEntity()
    if ( SERVER ) then
        local yaml = ax.database.server or {}
        ax.database:Connect(yaml.adapter, yaml.hostname, yaml.username, yaml.password, yaml.database, yaml.port)

        local groundItems = ax.data:Get("world_items", {}, { scope = "map", human = true })
        for itemID, v in pairs(groundItems) do
            local itemObject = ax.item:Instance(itemID, v.class)
            if ( itemObject ) then
                itemObject.invID = 0
                itemObject.data = v.data or {}
                ax.item.instances[itemID] = itemObject
            end

            local entity = ents.Create("ax_item")
            entity:SetItemID(itemID)
            entity:SetItemClass(v.class)
            entity:SetPos(v.position)
            entity:SetAngles(v.angles)
            entity:Spawn()
            entity:Activate()

            ax.net:Start(nil, "item.spawn", itemID, v.class, v.data or {})
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

local HITGROUP_NAMES = {
    [HITGROUP_HEAD]     = "head",
    [HITGROUP_CHEST]    = "chest",
    [HITGROUP_STOMACH]  = "stomach",
    [HITGROUP_GEAR]     = "gear",
    [HITGROUP_LEFTARM]  = "leftarm",
    [HITGROUP_RIGHTARM] = "rightarm",
    [HITGROUP_LEFTLEG]  = "leftleg",
    [HITGROUP_RIGHTLEG] = "rightleg"
}

local function resolveMultiplier(map, hitGroup)
    if ( !istable(map) ) then return nil end

    -- Numeric lookup first
    local m = map[hitGroup]
    if ( m != nil ) then return m end

    -- String lookup by canonical name
    local name = HITGROUP_NAMES[hitGroup]
    if ( name ) then
        m = map[name]
        if ( m != nil ) then return m end
    end

    -- Fallbacks
    return map["default"] or map["*"] or map["all"]
end

function GM:ScalePlayerDamage(client, hitGroup, damageInfo)
    local character = ax.util:IsValidPlayer(client) and client:GetCharacter() or nil
    if ( !character ) then return end

    local scale = 1.0

    -- Faction-defined scaling
    local factionData = character:GetFactionData()
    if ( factionData and factionData.scaleHitGroups ) then
        local m = resolveMultiplier(factionData.scaleHitGroups, hitGroup)
        if ( m != nil ) then
            scale = scale * math.Clamp(tonumber(m) or 1.0, 0.0, 5.0)
        end
    end

    -- Class-defined scaling
    local classData = character:GetClassData()
    if ( classData and classData.scaleHitGroups ) then
        local m = resolveMultiplier(classData.scaleHitGroups, hitGroup)
        if ( m != nil ) then
            scale = scale * math.Clamp(tonumber(m) or 1.0, 0.0, 5.0)
        end
    end

    if ( scale != 1.0 ) then
        damageInfo:ScaleDamage(scale)
    end
end

function GM:SetupMove(client, moveData)
    local character = ax.util:IsValidPlayer(client) and client:GetCharacter() or nil
    if ( !character ) then return end

    local inventory = character:GetInventory()
    if ( !inventory ) then return end

    local currentWeight = inventory:GetWeight()
    if ( currentWeight <= 0 ) then return end

    local maxWeight = inventory:GetMaxWeight()
    if ( maxWeight <= 0 ) then return end

    local weightRatio = currentWeight / maxWeight
    if ( weightRatio <= 0 ) then return end

    local speedMultiplier = 1.0 - math.min(weightRatio, 1.0) / 10
    moveData:SetMaxClientSpeed(moveData:GetMaxClientSpeed() * speedMultiplier)
end
