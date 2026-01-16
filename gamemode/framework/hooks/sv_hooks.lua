--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("gamemode_sandbox")

AX_CLIENT_QUEUE = AX_CLIENT_QUEUE or {}

function GM:PlayerDeathThink(client)
    if ( !IsValid(client) ) then return end

    if ( client:RateLimit("respawn", 30) and client:GetCharacter() ) then
        client:Spawn()
    end
end

function GM:DoPlayerDeath(client, attacker, damageInfo)
    client:SetDSP(31)
    client:SetDSP(35)

    client:ResetRateLimit("respawn")
    client:RateLimit("respawn", 30)

    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(client:GetModel())
    ragdoll:SetMaterial(client:GetMaterial())
    ragdoll:SetSkin(client:GetSkin())

    local materials = client:GetMaterials()
    for i = 1, #materials do
        ragdoll:SetSubMaterial(i - 1, materials[i])
    end

    local bodyGroups = {}
    for i = 0, client:GetNumBodyGroups() - 1 do
        bodyGroups[i] = client:GetBodygroup(i)
    end

    for i = 0, #bodyGroups do
        ragdoll:SetBodygroup(i, bodyGroups[i])
    end

    ragdoll:SetPos(client:GetPos())
    ragdoll:SetAngles(client:GetAngles())
    ragdoll:Spawn()
    ragdoll:SetSequence(client:GetSequence())
    ragdoll:Activate()

    client:SetRelay("ragdoll.index", ragdoll:EntIndex())

    if ( IsValid(ragdoll) ) then
        local physicsObject = ragdoll:GetPhysicsObject()
        if ( IsValid(physicsObject) ) then
            physicsObject:SetVelocity(client:GetVelocity())
        end

        local velocity = client:GetVelocity()
        for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
            physicsObject = ragdoll:GetPhysicsObjectNum(i)
            if ( IsValid(physicsObject) ) then
                physicsObject:SetVelocity(velocity)

                local index = ragdoll:TranslatePhysBoneToBone(i)
                if ( index != -1 ) then
                    local pos, ang = client:GetBonePosition(index)

                    physicsObject:SetPos(pos)
                    physicsObject:SetAngles(ang)
                end
            end
        end

        hook.Run("OnRagdollCreated", client, ragdoll, attacker, damageInfo)

        SafeRemoveEntityDelayed(ragdoll, 300)
    end

    local factionData = client:GetFactionData()
    if ( factionData and factionData.OnDeath ) then
        factionData:OnDeath(client, attacker, damageInfo)
    end

    local classData = client:GetClassData()
    if ( classData and classData.OnDeath ) then
        classData:OnDeath(client, attacker, damageInfo)
    end
end

function GM:PlayerDeathSound(client)
    local deathSound = hook.Run("GetPlayerDeathSound", client)
    if ( deathSound ) then
        client:EmitSound(deathSound, 80, 100, 1, CHAN_STATIC)
    end

    return true
end

function GM:PlayerHurt(client, attacker, healthRemaining, damageInfo)
    if ( healthRemaining <= 0 ) then return end

    local painSound = hook.Run("GetPlayerPainSound", client, attacker, healthRemaining, damageInfo)
    if ( painSound ) then
        client:EmitSound(painSound, 80, 100, 1, CHAN_STATIC)
    end
end

function GM:GetPlayerDeathSound(client)
    local deathSound = "vo/npc/male01/pain07.wav"
    local character = client:GetCharacter()
    if ( character ) then
        local classData = character:GetClassData()
        if ( classData and classData.deathSound ) then
            deathSound = classData.deathSound
        else
            local factionData = character:GetFactionData()
            if ( factionData and factionData.deathSound ) then
                deathSound = factionData.deathSound
            end
        end
    end

    if ( istable(deathSound) ) then
        deathSound = deathSound[math.random(#deathSound)]
    elseif ( isfunction(deathSound) ) then
        deathSound = deathSound(client)
    else
        deathSound = tostring(deathSound)
    end

    return deathSound
end

function GM:GetPlayerPainSound(client, attacker, healthRemaining, damageInfo)
    local painSound = "vo/npc/male01/pain0" .. math.random(1, 6) .. ".wav"
    local character = client:GetCharacter()
    if ( character ) then
        local classData = character:GetClassData()
        if ( classData and classData.painSound ) then
            painSound = classData.painSound
        else
            local factionData = character:GetFactionData()
            if ( factionData and factionData.painSound ) then
                painSound = factionData.painSound
            end
        end
    end

    if ( istable(painSound) ) then
        painSound = painSound[math.random(#painSound)]
    elseif ( isfunction(painSound) ) then
        painSound = painSound(client, attacker, healthRemaining, damageInfo)
    else
        painSound = tostring(painSound)
    end

    return painSound
end

function GM:PlayerSpawn(client)
    client:RemoveAllItems()

    client:SetRelay("ragdoll.index", -1)
    client:SetSlowWalkSpeed(ax.config:Get("speed.walk.slow"))
    client:SetWalkSpeed(ax.config:Get("speed.walk"))
    client:SetCrouchedWalkSpeed(ax.config:Get("speed.walk.crouched"))
    client:SetJumpPower(ax.config:Get("jump.power"))
    client:SetRunSpeed(ax.config:Get("speed.run"))

    local factionData = client:GetFactionData()
    if ( factionData and factionData.OnSpawn ) then
        factionData:OnSpawn(client)
    end

    local classData = client:GetClassData()
    if ( classData and classData.OnSpawn ) then
        classData:OnSpawn(client)
    end

    hook.Run("PostPlayerSpawn", client)
    hook.Run("PlayerLoadout", client)
end

function GM:PlayerLoadout(client)
    BaseClass.PlayerLoadout(self, client)

    client:Give("ax_hands")

    for i = 1, 32 do
        client:SetBodygroup(i, 0)
        client:SetSubMaterial(i - 1, "")
    end

    local character = client:GetCharacter()
    if ( character ) then
        client:SetModel(character:GetModel())
        client:SetSkin(character:GetSkin())

        local bodyGroups = character:GetData("bodygroups", {})
        for k, v in pairs(bodyGroups) do
            client:SetBodygroup(client:FindBodygroupByName(k), v)
        end

        local materials = character:GetData("materials", {})
        for k, v in pairs(materials) do
            client:SetSubMaterial(k - 1, v)
        end

        if ( character:HasFlags("p") ) then
            client:Give("weapon_physgun")
        end

        if ( character:HasFlags("t") ) then
            client:Give("gmod_tool")
        end
    end

    client:SelectWeapon("ax_hands")
    client:SetDSP(1)

    local factionData = client:GetFactionData()
    if ( factionData and factionData.OnLoadout ) then
        factionData:OnLoadout(client)
    end

    local classData = client:GetClassData()
    if ( classData and classData.OnLoadout ) then
        classData:OnLoadout(client)
    end

    hook.Run("PostPlayerLoadout", client)

    client:SetupHands()
end

function GM:PlayerSetHandsModel(client, ent)
    local simplemodel = player_manager.TranslateToPlayerModelName(client:GetModel())
    local info = player_manager.TranslatePlayerHands(simplemodel)
    if ( info ) then
        ent:SetModel(info.model)
        ent:SetSkin(info.skin)
        ent:SetBodyGroups(info.body)
    end
end

function GM:DatabaseConnected()
    ax.database:CreateTables()

    timer.Create("ax.database.think", 1, 0, function()
        mysql:Think()
    end)
end

function GM:PlayerInitialSpawn(client)
    local steamID64 = client:SteamID64()
    ax.util:PrintDebug("Client " .. steamID64 .. " has connected, waiting for full update request...")

    for k, v in player.Iterator() do
        v:ChatPrint(Color(60, 220, 120), "Player " .. client:SteamName() .. " has joined the server.")
    end

    -- Handle bot character creation automatically
    if ( client:IsBot() ) then
        if ( ax.config:Get("bot.support", true) ) then
            ax.util:PrintDebug("Bot detected: " .. client:SteamName() .. ", creating character automatically...")

            -- Small delay to ensure faction system is ready
            timer.Simple(0.1, function()
                if ( IsValid(client) ) then
                    ax.util:CreateBotCharacter(client)
                end
            end)
        else
            ax.util:PrintDebug("Bot detected but bot support is disabled: " .. client:SteamName())
        end

        return -- Skip normal player initialization for bots
    end

    timer.Create("ax.player.save." .. steamID64, 300, 1, function()
        if ( !IsValid(client) ) then return end

        client:Save()

        ax.util:PrintDebug("Auto-saved player " .. client:SteamName() .. ".")
    end)

    client:GetTable().axJoinTime = os.time()

    AX_CLIENT_QUEUE[steamID64] = true
    hook.Run("PlayerQueued", client)
end

function GM:PlayerDisconnected(client)
    local steamID64 = client:SteamID64()

    -- Clean up bot characters from memory
    if ( client:IsBot() ) then
        local character = client:GetCharacter()
        if ( character and character.isBot ) then
            ax.character.instances[character.id] = nil
            ax.util:PrintDebug("Cleaned up temporary bot character: " .. (character:GetName() or "Unknown"))
        end
    end

    -- Clean up timers and other player data
    timer.Remove("ax.player.save." .. steamID64)

    if ( client:GetTable().axJoinTime ) then
        client:GetTable().axJoinTime = nil
    end
end

gameevent.Listen("player_disconnect")

-- Clean up existing hook to prevent duplicates on reload
hook.Remove("player_disconnect", "Parallax.PlayerDisconnected")

hook.Add("player_disconnect", "Parallax.PlayerDisconnected", function(data)
    local name = data.name
    local reason = data.reason

    local client = Player(data.userid)
    local clientTable = client:GetTable()

    if ( !istable( clientTable.axCharacters ) ) then clientTable.axCharacters = {} end
    local characters = clientTable.axCharacters or {}
    if ( characters[1] != nil ) then
        for i = 1, #characters do
            local character = characters[i]
            ax.character.instances[character.id] = nil

            ax.net:Start(nil, "character.invalidate", character.id)
        end
    end

    for k, v in player.Iterator() do
        v:ChatPrint(Color(220, 60, 60), "Player " .. name .. " has disconnected. (" .. reason .. ")")
    end
end)

function GM:StartCommand(client, userCmd)
    local steamID64 = client:SteamID64()
    if ( AX_CLIENT_QUEUE[steamID64] and !userCmd:IsForced() ) then
        AX_CLIENT_QUEUE[steamID64] = nil

        ax.util:PrintDebug("Client " .. steamID64 .. " has sent full update request, initializing player...")

        client:EnsurePlayer(function(ok)
            if ( !ok ) then
                ax.util:PrintError("Proceeding despite player DB ensure failure for " .. steamID64)
            end

            ax.util:PrintDebug("Ensured player " .. steamID64 .. " is valid.")

            local query = mysql:Select("ax_players")
                query:Where("steamid64", steamID64)
                query:Callback(function(result, status)
                    if ( result == false or result[1] == nil ) then
                        ax.util:PrintError("Failed to load player data for " .. steamID64)
                        return
                    end

                    local data = result[1]
                    for k, v in pairs(ax.player.vars) do
                        local field = v.field
                        local var = data[field] or v.default

                        if ( v.field == "data" ) then
                            var = util.JSONToTable(var) or v.default or {}
                        end

                        ax.player:SetVar(client, k, var)
                    end

                    client:SetNameVar(client:SteamName()) -- Update the steam name in db
                    client:SetLastJoin(os.time())
                    client:Save()

                    ax.util:PrintDebug("Loaded player data for " .. steamID64)
                end)
            query:Execute()

            ax.character:Restore(client, function(characters)
                hook.Run("PlayerReady", client)

                ax.inventory:Restore(client)
                ax.relay:Sync(client)

                -- Sync all existing active characters from other players
                for _, otherClient in player.Iterator() do
                    if ( !IsValid(otherClient) or otherClient == client ) then continue end

                    local otherCharacter = otherClient:GetCharacter()
                    if ( !istable(otherCharacter) ) then continue end

                    ax.character:Sync(otherClient, otherCharacter, client)
                end

                -- Sync all world items (invID = 0) to the newly joined player
                for itemID, item in pairs(ax.item.instances) do
                    if ( !istable(item) or item.invID != 0 ) then continue end

                    ax.net:Start(client, "inventory.item.add", 0, item.id, item.class, item.data or {})
                end
            end)
        end)

        client:SetNoDraw(true)
        client:SetNotSolid(true)
        client:SetMoveType(MOVETYPE_NONE)
        client:KillSilent()

        ax.net:Start(client, "player.ready")
    end
end

function GM:PlayerReady(client)
    client:Spawn()
    client:SyncRelay()
end

function GM:OnDatabaseTablesCreated()
    ax.util:PrintDebug("Database tables created successfully.")
end

local voiceDistance
local function CalcPlayerCanHearPlayersVoice(listener)
    if ( !IsValid(listener) ) then return end
    if ( !listener:GetCharacter() ) then return end

    local dist = ax.config:Get("voice.distance", 512)
    voiceDistance = dist * dist

    local listenerTable = listener:GetTable()

    listenerTable.axVoiceHear = listenerTable.axVoiceHear or {}
    listenerTable.axVoiceHearDynamic = listenerTable.axVoiceHearDynamic or {}

    for _, speaker in player.Iterator() do
        if ( !IsValid(speaker) or !speaker:GetCharacter() or speaker == listener ) then
            continue
        end

        if ( !speaker:Alive() ) then
            listenerTable.axVoiceHear[speaker] = false
            continue
        end

        local canHear, isDynamic = hook.Run("PlayerCanHearPlayersVoice", listener, speaker)
        listenerTable.axVoiceHear[speaker] = canHear == true or nil
        if ( canHear == true ) then
            listenerTable.axVoiceHearDynamic[speaker] = isDynamic == true or false
        else
            listenerTable.axVoiceHearDynamic[speaker] = nil
        end
    end
end

function GM:PlayerCanHearPlayersVoice(listener, speaker)
    local config = ax.config:Get("voice.distance", 512)
    if ( voiceDistance == nil ) then
        voiceDistance = config * config
    elseif ( voiceDistance != config * config ) then
        voiceDistance = config * config
    end

    local listenerTable = listener:GetTable()
    if ( listenerTable.axVoiceHear and listenerTable.axVoiceHear[speaker] != nil ) then
        return listenerTable.axVoiceHear[speaker], listenerTable.axVoiceHearDynamic and listenerTable.axVoiceHearDynamic[speaker] or false
    end

    local distSqr = listener:EyePos():DistToSqr(speaker:EyePos())
    if ( distSqr <= voiceDistance ) then
        return true, true
    end

    return false
end

function GM:Think()
    for k, v in player.Iterator() do
        hook.Run("PlayerThink", v)
    end
end

function GM:PlayerThink(client)
    local clientTable = client:GetTable()
    if ( !clientTable.axNextHear or clientTable.axNextHear < CurTime() ) then
        CalcPlayerCanHearPlayersVoice(client)
        clientTable.axNextHear = CurTime() + 0.33
    end
end

function GM:CanPlayerSuicide(client)
    ax.util:PrintDebug("Player " .. client:SteamID64() .. " attempted suicide.")
    return false
end

function GM:ShutDown()
    -- PlayerDisconnected isn't called on p2p/singleplayer
    if ( !game.IsDedicated() ) then
        for _, client in player.Iterator() do
            hook.Run("PlayerDisconnected", client)
        end
    end

    local items = ents.FindByClass("ax_item")
    local output = {}
    for i = #items, 1, -1 do
        local item = items[i]

        output[item:GetItemID()] = {
            class = item:GetItemClass(),
            position = item:GetPos(),
            angles = item:GetAngles(),
            data = item:GetItemTable():GetData() or {}
        }
    end

    ax.data:Set("world_items", output, {
        scope = "map", human = true
    })
end

function GM:PlayerDisconnected(client)
    local joinTime = client:GetLastJoin() or os.time()
    local playtime = os.difftime(os.time(), joinTime)

    client:SetLastLeave(os.time())
    client:SetPlayTime(playtime)
    client:Save()

    for id, inv in pairs(ax.inventory.instances) do
        if ( inv:IsReceiver(client) ) then
            inv:RemoveReceiver(client)
        end
    end

    local steamID64 = client:SteamID64()
    if ( timer.Exists("ax.player.save." .. steamID64) ) then
        timer.Remove("ax.player.save." .. steamID64)
    end

    AX_CLIENT_QUEUE[steamID64] = nil
end

function GM:GetGameDescription()
    local schema = SCHEMA or {}
    if ( schema.name ) then
        return schema.name
    end

    return "Parallax Framework"
end

function GM:GetFallDamage(client, speed)
    -- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/gamemode/player.lua#L756
    return ( speed - 526.5 ) * ( 100 / 396 ) -- the Source SDK value
end

function GM:OnPlayerItemPickup(client, entity, item)
    -- Item transfers are async (DB-backed). Under heavy spam, the entity may be
    -- removed before the callback fires, so defensively handle invalid ents.
    if ( IsValid(entity) ) then
        entity:EmitSound("items/itempickup.wav")
    elseif ( IsValid(client) ) then
        client:EmitSound("items/itempickup.wav")
    end
end

function GM:OnPlayerItemAction(client, item, action)
    if ( action == "drop" ) then
        client:EmitSound("Flesh.ImpactSoft")
    end
end

function GM:ShouldSendDeathNotice(attacker, inflictor, victim, flags)
    return false
end

GM.SendDeathNoticeUnaltered = GM.SendDeathNoticeUnaltered or GM.SendDeathNotice
function GM:SendDeathNotice(attacker, inflictor, victim, flags)
    if ( hook.Run("ShouldSendDeathNotice", attacker, inflictor, victim, flags) == false ) then
        return
    end

    return self:SendDeathNoticeUnaltered(attacker, inflictor, victim, flags)
end

local whitelistProp = {
    ["bodygroups"] = true,
    ["collision"] = true,
    ["remover"] = true,
    ["skin"] = true
}

local adminProp = {
    ["extinguish"] = true,
    ["ignite"] = true,
}

function GM:CanProperty(client, prop)
    if ( whitelistProp[prop] ) then return true end
    if ( client:IsAdmin() and adminProp[prop] ) then return true end

    return client:IsSuperAdmin()
end

local bannedTools = {
    ["balloon"] = true,
    ["duplicator"] = true,
    ["dynamite"] = true,
    ["emitter"] = true,
    ["eyeposer"] = true,
    ["faceposer"] = true,
    ["fingerposer"] = true,
    ["inflator"] = true,
    ["paint"] = true,
    ["physprop"] = true,
    ["thruster"] = true,
    ["wheel"] = true,
    ["trails"] = true
}

local dupeBannedTools = {
    ["adv_duplicator"] = true,
    ["duplicator"] = true,
    ["spawner"] = true,
    ["weld"] = true,
    ["weld_ez"] = true
}

local adminWorldRemoveWhitelist = {
    ["ax_item"] = true,
    ["prop_physics"] = true,
    ["prop_ragdoll"] = true
}

function GM:CanTool(client, tr, tool)
    if ( !client:IsAdmin() and tool == "spawner" ) then return false end

    if ( bannedTools[tool] ) then
        ax.util:Print(client, " attempted to use banned tool ", tool)
        return false
    end

    local ent = tr.Entity
    if ( IsValid(ent) ) then
        if ( ent.axOnlyRemover ) then
            if ( tool == "remover" ) then
                return client:IsAdmin() or client:IsSuperAdmin()
            else
                ax.util:Print(client, " attempted to use tool ", tool, " on an entity that only allows remover.")
                return false
            end
        end

        if ( ent.axNoDupe and dupeBannedTools[tool] ) then
            ax.util:Print(client, " attempted to use tool ", tool, " on a no-dupe entity.")
            return false
        end

        if ( tool == "remover" and client:IsAdmin() and !client:IsSuperAdmin() ) then
            local owner = ent.CPPIGetOwner and ent:CPPIGetOwner() or nil
            if ( !owner and !adminWorldRemoveWhitelist[ent:GetClass()] ) then
                client:Notify("You can not remove this entity.")
                return false
            end
        end

        if ( string.StartsWith(ent:GetClass(), "ax_") and tool != "remover" and !client:IsSuperAdmin() ) then
            return false
        end
    end

    ax.util:Print(client, " used tool ", tool)

    return true
end
