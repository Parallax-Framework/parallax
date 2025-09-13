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

function GM:InitPostEntity()
    ax.database:Connect() -- TODO: Allow schemas to connect to their own databases
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

    client:SetNWInt("ax.ragdoll.index", ragdoll:EntIndex())
end

function GM:PlayerSpawn(client)
    client:SetNWInt("ax.ragdoll.index", -1)
    client:SetSlowWalkSpeed(75)
    client:SetWalkSpeed(100)
    client:SetCrouchedWalkSpeed(0.75)
    client:SetJumpPower(175)
    client:SetRunSpeed(220)

    hook.Run("PlayerLoadout", client)
end

function GM:PlayerLoadout(client)
    BaseClass.PlayerLoadout(self, client)

    client:Give("weapon_fists")

    local character = client:GetCharacter()
    if ( character ) then
        client:SetModel(character:GetModel())
        client:SetSkin( character:GetData( "skin", 0 ) )
        local bodyGroups = character:GetData("bodygroups", {})
        for k, v in pairs(bodyGroups) do
            client:SetBodygroup(k, v)
        end

        local materials = character:GetData("materials", {})
        for k, v in pairs(materials) do
            client:SetSubMaterial(k - 1, v)
        end
    end

    client:SetupHands()

    hook.Run("PostPlayerLoadout", client)
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

        client:LoadData( function( data )
            if ( !IsValid( client) ) then return end

            ax.character:Restore(client, function(characters)
                hook.Run("PlayerReady", client)

                ax.inventory:Restore(client, function(success)
                    if ( success ) then
                        ax.util:PrintDebug(Color(60, 220, 120), "Inventories restored successfully.")
                    else
                        ax.util:PrintDebug(Color(220, 60, 60), "Failed to restore inventories.")
                    end
                end)
            end)
        end )

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
end

function GM:PlayerSay(client, text, teamChat)
    if ( text == "" ) then return end

    -- Check if this is a command
    local isCommand = false
    for k, v in ipairs(ax.command.prefixes) do
        if ( string.StartsWith(text, v) ) then
            isCommand = true
            break
        end
    end

    if ( isCommand ) then
        local name, rawArgs = ax.command:Parse(text)
        if ( name and name != "" and ax.command.registry[name] ) then
            local ok, result = ax.command:Run(client, name, rawArgs)

            if ( !ok ) then
                client:Notify(result or "Unknown error", "error")
            elseif ( result and result != "" ) then
                client:Notify(tostring(result))
            end
        else
            client:Notify(tostring(name) .. " is not a valid command.", "warning")
        end

        return ""
    end

    -- Format regular chat messages
    if ( hook.Run("ShouldFormatMessage", client, text) != false ) then
        text = ax.chat:Format(text)
    end

    return text
end

function GM:PlayerDisconnected(client)
    local invKeys = table.GetKeys(ax.inventory.instances)
    for i = 1, #invKeys do
        local inv = ax.inventory.instances[invKeys[i]]
        if ( !istable(inv) ) then continue end

        if ( inv:IsReceiver(client) ) then
            inv:RemoveReceiver(client)

            net.Start("ax.inventory.receiver.remove")
                net.WriteUInt(inv.id, 32)
                net.WritePlayer(client)
            net.Broadcast()
        end
    end
end

function GM:OnDatabaseTablesCreated()
    ax.util:PrintDebug("Database tables created successfully.")
end

function GM:PlayerCanHearPlayersVoice(listener, speaker)
    return true, true
end
