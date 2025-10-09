--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("gamemode_sandbox")

AX_CLIENT_QUEUE = AX_CLIENT_QUEUE or {}

function GM:PlayerSwitchFlashlight(client, state)
    return true
end

function GM:PlayerDeathThink(client)
    if ( client:RateLimit("respawn", 5) and client:GetCharacter() ) then
        client:Spawn()
    end
end

function GM:DoPlayerDeath(client, attacker, damageInfo)
    client:ResetRateLimit("respawn")
    client:RateLimit("respawn", 5)

    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(client:GetModel())
    ragdoll:SetMaterial( client:GetMaterial() )
    ragdoll:SetSkin( client:GetSkin() )

    local materials = client:GetMaterials()
    for i = 1, #materials do
        ragdoll:SetSubMaterial(i - 1, materials[i])
    end

    ragdoll:SetPos(client:GetPos())
    ragdoll:SetAngles(client:GetAngles())
    ragdoll:Spawn()
    ragdoll:Activate()

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

    client:SetRelay("ax.ragdoll.index", ragdoll:EntIndex())
end

function GM:PlayerSpawn(client)
    client:RemoveAllItems()

    client:SetRelay("ax.ragdoll.index", -1)
    client:SetSlowWalkSpeed(70)
    client:SetWalkSpeed(90)
    client:SetCrouchedWalkSpeed(0.7)
    client:SetJumpPower(175)
    client:SetRunSpeed(200)

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
        client:SetSkin(character:GetData("skin", 0))

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

    timer.Create("ax.player.save." .. steamID64, 300, 1, function()
        if ( !IsValid(client) ) then return end

        client:Save()

        ax.util:PrintDebug("Auto-saved player " .. client:SteamName() .. ".")
    end)

    client:GetTable().axJoinTime = os.time()

    AX_CLIENT_QUEUE[steamID64] = true
    hook.Run("PlayerQueued", client)
end

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "Parallax.PlayerDisconnected", function(data)
    local name = data.name
    local reason = data.reason

    for k, v in player.Iterator() do
        v:ChatPrint(Color(220, 60, 60), "Player " .. name .. " has disconnected. (" .. reason .. ")")
    end
end)

function GM:StartCommand(client, userCmd)
    local steamID64 = client:SteamID64()
    if ( AX_CLIENT_QUEUE[steamID64] and !userCmd:IsForced() ) then
        AX_CLIENT_QUEUE[steamID64] = nil

        client:EnsurePlayer(function(ok)
            if ( !ok ) then
                ax.util:PrintError("Proceeding despite player DB ensure failure for " .. steamID64)
            end

            local query = mysql:Select("ax_players")
                query:Where("steamid64", steamID64)
                query:Callback(function(result, status)
                    if ( result == false or result[1] == nil ) then
                        ax.util:PrintError("Failed to load player data for " .. steamID64)
                        return
                    end

                    local data = result[1]
                    client:GetTable().axData = util.JSONToTable(data.data) or {}

                    client:SetPlayTime(tonumber(data.play_time) or 0)
                    client:SetLastJoin(tonumber(data.last_join) or os.time())
                    client:SetLastLeave(tonumber(data.last_leave) or 0)

                    ax.util:PrintDebug("Loaded player data for " .. steamID64)
                end)
            query:Execute()

            client:SetLastJoin(os.time(), true, client)

            ax.character:Restore(client, function(characters)
                hook.Run("PlayerReady", client)

                ax.inventory:Restore(client)
            end)
        end)

        client:SetNoDraw(true)
        client:SetNotSolid(true)
        client:SetMoveType(MOVETYPE_NONE)
        client:KillSilent()

        net.Start("ax.player.ready")
        net.Send(client)
    end
end

function GM:PlayerReady(client)
    client:Spawn()
    client:SyncRelay()
end

function GM:PlayerDisconnected(client)
    local invKeys = table.GetKeys(ax.inventory.instances)
    for i = 1, #invKeys do
        local inv = ax.inventory.instances[invKeys[i]]
        if ( !istable(inv) ) then continue end

        if ( inv:IsReceiver(client) ) then
            inv:RemoveReceiver(client)
        end
    end
end

function GM:OnDatabaseTablesCreated()
    ax.util:PrintDebug("Database tables created successfully.")
end

function GM:PlayerCanHearPlayersVoice(listener, speaker)
    return true, true
end

function GM:CanPlayerSuicide( client )
    return false
end

function GM:ShutDown() -- PlayerDisconnected isn't called on p2p/singleplayer
    if ( !game.IsDedicated() ) then
        for _, client in player.Iterator() do
            local joinTime = client:GetLastJoin() or os.time()
            local playtime = os.difftime(os.time(), joinTime)

            client:SetLastLeave(os.time())
            client:SetPlayTime(playtime)

            client:Save()
        end
    end

    local items = ents.FindByClass( "ax_item" )
    local output = {}
    for i = #items, 1, -1 do
        local item = items[i]

        output[ item:GetItemID() ] = {
            class = item:GetItemClass(),
            position = item:GetPos(),
            angles = item:GetAngles(),
            data = item:GetItemTable():GetData() or {}
        }
    end

    ax.data:Set("world_items", output, { scope = "map", human = true })
end

function GM:PlayerDisconnected(client)
    local joinTime = client:GetLastJoin() or os.time()
    local playtime = os.difftime(os.time(), joinTime)

    client:SetLastLeave(os.time())
    client:SetPlayTime(playtime)

    client:Save()

    local steamID64 = client:SteamID64()
    if ( timer.Exists("ax.player.save." .. steamID64) ) then
        timer.Remove("ax.player.save." .. steamID64)
    end

    AX_CLIENT_QUEUE[steamID64] = nil
end

function GM:GetFallDamage(client, speed)
    -- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/gamemode/player.lua#L756
    return ( speed - 526.5 ) * ( 100 / 396 ) -- the Source SDK value
end

function GM:OnPlayerItemPickup(client, entity, item)
    entity:EmitSound("items/itempickup.wav")
end

function GM:OnPlayerItemAction(client, item, action)
    if ( action == "drop" ) then
        client:EmitSound("Flesh.ImpactSoft")
    end
end

GM.SendDeathNotice = nil
