--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local time = CurTime()
function GM:PlayerInitialSpawn(client)
    time = CurTime()
    ax.util:Print("Starting to load player " .. client:SteamName() .. " (" .. client:SteamID64() .. ")")

    if ( client:IsBot() ) then
        timer.Simple(1, function()
            if ( !IsValid(client) ) then return end

            ax.util:SendChatText(nil, ax.color:Get("cyan.dark"), client:SteamName() .. " has joined the server.")

            local factionBot = math.random(#ax.faction.instances)

            local models = {}
            local factionModels = ax.faction:Get(factionBot):GetModels()
            for i = 1, #factionModels do
                local v = factionModels[i]
                if ( istable(v) ) then
                    models[#models + 1] =  v[1]
                else
                    models[#models + 1] = v
                end
            end

            client:SetModel(models[math.random(#models)])
            client:SetTeam(factionBot)

            local characterID = math.random(100000, 999999)
            local character = ax.character:CreateObject(characterID, {
                name = client:SteamName(),
                model = client:GetModel(),
                faction = factionBot,
                schema = engine.ActiveGamemode(),
                steamid = client:SteamID64()
            }, client)
            if ( character ) then
                ax.character.stored[characterID] = character

                local clientTable = client:GetTable()
                clientTable.axCharacters = clientTable.axCharacters or {}
                clientTable.axCharacters[characterID] = character
                clientTable.axCharacter = character

                net.Start("ax.character.cache")
                    net.WriteTable(character)
                net.Send(client)

                ax.character:Sync(client, characterID)

                hook.Run("PostPlayerCreatedCharacter", client, character, nil)
            end
        end)
    end
end

function GM:PlayerReady(client)
    client:SetTeam(0)
    client:SetModel("models/player/kleiner.mdl")

    client:KillSilent()

    print("Player " .. client:SteamName() .. " (" .. client:SteamID64() .. ") is ready.")

    local activeGamemode = engine.ActiveGamemode()
    if ( activeGamemode == "parallax" ) then
        -- Sometimes people might forget to actually set their startup gamemode to their schema rather than the actual framework... so we check for that
        ax.util:PrintError("You are running Parallax without a schema! Please set your startup gamemode to your schema (e.g. 'parallax-skeleton' instead of 'parallax').")
        ax.util:SendChatText(nil, ax.color:Get("red.soft"), "You are running Parallax without a schema! Please set your startup gamemode to your schema (e.g. 'parallax-skeleton' instead of 'parallax').")

        net.Start("ax.splash")
        net.Send(client)

        return
    end

    ax.character:CacheAll(client, function()
        ax.util:SendChatText(nil, ax.color:Get("cyan.dark"), client:SteamName() .. " has joined the server.")

        net.Start("ax.splash")
        net.Send(client)

        client:SetNoDraw(true)
        client:SetNotSolid(true)
        client:SetMoveType(MOVETYPE_NONE)

        ax.character:SyncAll(client) -- Probably a bad idea, might need to recreate the entire character system too...

        hook.Run("PostPlayerInitialSpawn", client)

        ax.util:Print("Finished loading player " .. client:SteamName() .. " (" .. client:SteamID64() .. ") in " .. math.Round(CurTime() - time, 2) .. " seconds.")
        time = CurTime()
    end)
end

function GM:PostPlayerInitialSpawn(client)
    if ( !IsValid(client) or client:IsBot() ) then return end

    ax.database:LoadRow("ax_players", "steamid", client:SteamID64(), function(data)
        local clientTable = client:GetTable()
        clientTable.axDatabase = data or {}

        client:SetDBVar("name", client:SteamName())
        client:SetDBVar("ip", client:IPAddress())
        client:SetDBVar("last_played", os.time())
        client:SetDBVar("data", data != nil and data.data or "[]")
        client:SaveDB()

        ax.util:Print("Loaded player " .. client:SteamName() .. " (" .. client:SteamID64() .. ") in " .. math.Round(CurTime() - time, 2) .. " seconds.")
        time = CurTime()

        ax.config:Synchronize(client)

        hook.Run("PostPlayerReady", client)
    end)
end

function GM:PlayerDisconnected(client)
    if ( !client:IsBot() ) then
        client:SetDBVar("play_time", client:GetDBVar("play_time", 0) + (os.time() - client:GetDBVar("last_played", 0)))
        client:SetDBVar("last_played", os.time())
        client:SaveDB()

        local character = client:GetCharacter()
        if ( character ) then
            character:SetData("last_pos", client:GetPos())
            character:SetData("last_ang", client:GetAngles())
            character:SetData("health", client:Health())
            character:SetPlayTime(character:GetPlayTime() + (os.time() - character:GetLastPlayed()))
            character:SetLastPlayed(os.time())
        end

        local clientOptions = ax.option.clients[client:EntIndex()]
        if ( istable(clientOptions) ) then
            clientOptions = nil
        end
    end

    ax.util:SendChatText(nil, ax.color:Get("maroon.soft"), client:SteamName() .. " has left the server.")
end

function GM:PlayerSpawn(client)
    local character = client:GetCharacter()
    if ( !character ) then return end

    hook.Run("PlayerLoadout", client)
end

function GM:PlayerLoadout(client)
    client:RemoveAllItems()

    if ( hook.Run("PlayerGetToolgun", client) == true ) then client:Give("gmod_tool") end
    if ( hook.Run("PlayerGetPhysgun", client) == true ) then client:Give("weapon_physgun") end

    client:Give("ax_hands")
    client:SelectWeapon("ax_hands")

    client:SetWalkSpeed(ax.config:Get("speed.walk", 80))
    client:SetRunSpeed(ax.config:Get("speed.run", 180))
    client:SetJumpPower(ax.config:Get("jump.power", 160))

    client:SetupHands()

    local character = client:GetCharacter()

    -- Restore the character's skin
    client:SetSkin(character:GetSkin() or 0)

    -- Restore the character's bodygroups
    local groups = character:GetData("groups", {})
    for name, value in pairs(groups) do
        local id = client:FindBodygroupByName(name)
        if ( id == -1 ) then continue end

        client:SetBodygroup(id, value)
    end

    -- Handle faction loadout
    local factionData = character:GetFactionData()
    if ( istable(factionData) ) then
        if ( factionData.Weapons and istable(factionData.Weapons) ) then
            for _, weapon in ipairs(factionData.Weapons) do
                if ( !client:HasWeapon(weapon) ) then
                    client:Give(weapon)
                end
            end
        end

        if ( isfunction(factionData.OnLoadout) ) then
            factionData:OnLoadout(client)
        end
    end

    -- Handle class loadout
    local classData = character:GetClassData()
    if ( istable(classData) ) then
        if ( classData.Weapons and istable(classData.Weapons) ) then
            for _, weapon in ipairs(classData.Weapons) do
                if ( !client:HasWeapon(weapon) ) then
                    client:Give(weapon)
                end
            end
        end

        if ( isfunction(classData.OnLoadout) ) then
            classData:OnLoadout(client)
        end
    end

    hook.Run("PostPlayerLoadout", client)

    return true
end

function GM:PostPlayerLoadout(client)
    -- Empty, let modules and schemas use this hook to add additional loadout items or modify the player's state
end

function GM:PrePlayerCreatedCharacter(client, payload)
    local maxCharacters = ax.config:Get("characters.maxCount")
    if ( table.Count(client:GetCharacters()) >= maxCharacters ) then
        return false, "You have reached the maximum number of characters! (" .. maxCharacters .. ")"
    end

    return true
end

function GM:PrePlayerLoadedCharacter(client, character, previousCharacter)
    if ( client:OnCooldown("character.switch") ) then
        return false, "You are on cooldown for switching characters!"
    end

    if ( client:GetCharacter() and !client:Alive() ) then
        return false, "You cannot switch characters while being dead!"
    end

    if ( previousCharacter ) then
        previousCharacter:SetData("health", client:Health())

        local groups = {}
        for i = 0, client:GetNumBodyGroups() - 1 do
            local name = client:GetBodygroupName(i)
            if ( name and name != "" ) then
                groups[name] = client:GetBodygroup(i)
            end
        end

        previousCharacter:SetData("groups", groups)
        previousCharacter:SetData("last_pos", client:GetPos())
        previousCharacter:SetData("last_ang", client:EyeAngles())
        previousCharacter:SetPlayTime(previousCharacter:GetPlayTime() + (os.time() - previousCharacter:GetLastPlayed()))
        previousCharacter:SetLastPlayed(os.time())
    end
end

function GM:PostPlayerCreatedCharacter(client, character)
    ax.character:ApplyDefaultFlags(character)
end

function GM:PostPlayerLoadedCharacter(client, character, previousCharacter)
    if ( !character ) then return end

    -- Restore character state
    local lastPos = character:GetData("last_pos")
    local lastAng = character:GetData("last_ang")
    if ( isvector(lastPos) and isangle(lastAng) and ax.config:Get("characters.restorepos", true) ) then
        client:SetPos(lastPos)
        client:SetEyeAngles(lastAng)
    end

    client:SetHealth(character:GetData("health", 100))

    -- And now wipe it
    character:SetData("last_pos", nil)
    character:SetData("last_ang", nil)
    character:SetData("health", nil)

    -- Restore the bodygroups of the character
    local groups = character:GetData("groups", {})
    for name, value in pairs(groups) do
        local id = client:FindBodygroupByName(name)
        if ( id == -1 ) then continue end

        client:SetBodygroup(id, value)
    end

    client:SetSkin(character:GetSkin())

    local classData = character:GetClassData()
    if ( istable(classData) and isfunction(classData.OnCharacterLoaded) ) then
        classData:OnCharacterLoaded(client)
    end

    client:SetCooldown("character.switch", 10)

    ax.character:ApplyDefaultFlags(character)
end

function GM:PlayerDeathThink(client)
    if ( client:Team() == 0 ) then
        -- If the player is in the main menu, we don't want to do anything
        return true
    end

    local respawnTime = ax.config:Get("time.respawn", 60)
    if ( respawnTime <= 0 ) then
        client:Spawn()
    end

    if ( client:GetRelay("respawnTime", CurTime()) < CurTime() or client:IsBot() ) then
        client:Spawn()
    end
end

function GM:PlayerSay(client, text, teamChat)
    if ( string.sub(text, 1, 3) == ".//" ) then
        -- Check if it's a way of using local out of character chat using .// prefix
        local message = string.Explode(" ", string.sub(text, 4))
        table.remove(message, 1)

        ax.command:Run(client, "looc", message)
    elseif ( string.sub(text, 1, 1) == "/" ) then
        -- This is a command, so we need to parse it
        local arguments = string.Explode(" ", string.sub(text, 2))
        local command = arguments[1]
        table.remove(arguments, 1)

        ax.command:Run(client, command, arguments)
    else
        -- Everything else is a normal chat message
        ax.chat:SendSpeaker(client, "ic", text)
    end

    return ""
end

function GM:PlayerUseSpawnSaver(client)
    return false
end

function GM:Initialize()
    ax.item:LoadFolder("parallax/gamemode/items")
    ax.module:LoadFolder("parallax/modules")
    ax.schema:Initialize()

    if ( game.IsDedicated() ) then
        -- Production (dedicated server)
        RunConsoleCommand("net_maxfilesize", "64")
        RunConsoleCommand("sv_maxrate", "30000")
        RunConsoleCommand("sv_minrate", "5000")
        RunConsoleCommand("sv_maxcmdrate", "66")
        RunConsoleCommand("sv_maxupdaterate", "66")
        RunConsoleCommand("sv_mincmdrate", "30")
        RunConsoleCommand("sv_allowcslua", "0")
    else
        -- Development (listen server)
        RunConsoleCommand("net_maxfilesize", "128")
        RunConsoleCommand("sv_maxrate", "60000")
        RunConsoleCommand("sv_minrate", "10000")
        RunConsoleCommand("sv_maxcmdrate", "100")
        RunConsoleCommand("sv_maxupdaterate", "100")
        RunConsoleCommand("sv_mincmdrate", "30")
        RunConsoleCommand("sv_allowcslua", "1")
    end

    ax.util:VerifyVersion()
end

local _reloaded = false
function GM:OnReloaded()
    if ( _reloaded ) then return end
    _reloaded = true

    ax.item:LoadFolder("parallax/gamemode/items")
    ax.module:LoadFolder("parallax/modules")
    ax.schema:Initialize()

    ax.util:Print("Core reloaded in " .. math.Round(SysTime() - GM.RefreshTimeStart, 2) .. " seconds.")

    ax.config:Synchronize()
    ax.util:VerifyVersion()
end

function GM:DatabaseConnected()
    hook.Run("LoadData")
end

local retryCount = 0
local maxRetries = 5

function GM:DatabaseConnectionFailed()
    if ( retryCount < maxRetries ) then
        retryCount = retryCount + 1
        ax.util:PrintWarning("Database connection failed, retrying... (" .. retryCount .. "/" .. maxRetries .. ")")

        timer.Simple(2, function()
            ax.database:Initialize()
        end)
    else
        ax.util:PrintError("Database connection failed after " .. maxRetries .. " retries, falling back to SQLite.")
        ax.database:Fallback()
    end
end

function GM:DatabaseFallback(reason)
    hook.Run("LoadData")
end

function GM:SetupPlayerVisibility(client, viewEntity)
    if ( client:Team() == 0 ) then
        AddOriginToPVS(ax.config:Get("mainmenu.pos", vector_origin))
    end
end

function GM:PlayerSwitchFlashlight(client, bEnabled)
    return true
end

function GM:GetFallDamage(client, speed)
    local damage = speed / 8

    -- Only ragdoll if the player won't die from fall damage
    if ( speed > 100 and client:Health() > damage ) then
        client:SetRagdolled(true, 5)
    end

    return damage
end

local nextThink = CurTime() + 1
local nextSave = CurTime() + ax.config:Get("save.interval", 300)
local playerVoiceListeners = {}
function GM:Think()
    if ( CurTime() >= nextThink ) then
        nextThink = CurTime() + 1

        for _, client in player.Iterator() do
            if ( !IsValid(client) or !client:Alive() ) then continue end
            if ( client:Team() == 0 ) then continue end

            -- Voice chat listeners
            local voiceListeners = {}

            for _, listener in player.Iterator() do
                if ( listener == client ) then continue end
                if ( listener:EyePos():DistToSqr(client:EyePos()) > ax.config:Get("voice.distance", 384) ^ 2 ) then continue end

                voiceListeners[listener] = true
            end

            -- Overwrite the voice listeners if the config is disabled
            if ( ax.config:Get("voice", true) ) then
                playerVoiceListeners[client] = voiceListeners
            else
                playerVoiceListeners = {}
            end
        end
    end

    if ( CurTime() >= nextSave ) then
        nextSave = CurTime() + ax.config:Get("save.interval", 300)
        hook.Run("SaveData")
    end
end

function GM:ShutDown()
    ax.util:Print("Shutting down ax...")
    ax.ShutDown = true

    hook.Run("SaveData")
end

function GM:PlayerCanHearPlayersVoice(listener, talker)
    if ( !playerVoiceListeners[listener] ) then return false end
    if ( !playerVoiceListeners[listener][talker] ) then return false end

    return true, true
end

function GM:CanPlayerSuicide(client)
    return false
end

function GM:PlayerDeathSound(client)
    return true
end

function GM:PlayerHurt(client, attacker, healthRemaining, damageTaken)
    local painSound = hook.Run("GetPlayerPainSound", client, attacker, healthRemaining, damageTaken)
    if ( painSound and painSound != "" and !client:InObserver() ) then
        client:EmitSound(painSound, 75, 100, 1, CHAN_VOICE)
    end
end

function GM:GetPlayerPainSound(client, attacker, healthRemaining, damageTaken)
    local character = client:GetCharacter()
    if ( !character ) then return end

    if ( client:Health() <= 0 ) then return end

    local factionData = character:GetFactionData()
    if ( client:IsOnFire() and factionData and factionData.FirePainSounds and factionData.FirePainSounds[1] != nil  ) then
        local sound = factionData.FirePainSounds[math.random(#factionData.FirePainSounds)]
        if ( sound and sound != "" ) then
            return sound
        end
    end

    if ( client:WaterLevel() >= 3 ) then
        if ( client:IsOnFire() ) then
            client:Extinguish()
        end

        if ( factionData and factionData.DrownSounds and factionData.DrownSounds[1] != nil ) then
            local sound = factionData.DrownSounds[math.random(#factionData.DrownSounds)]
            if ( sound and sound != "" ) then
                return sound
            end
        end
    end

    if ( damageTaken > 0 and factionData and factionData.PainSounds and factionData.PainSounds[1] != nil ) then
        local sound = factionData.PainSounds[math.random(#factionData.PainSounds)]
        if ( sound and sound != "" ) then
            return sound
        end
    end
end

function GM:DoPlayerDeath(client, attacker, dmgInfo)
    -- Remove any existing ragdoll before creating a new one
    local existingRagdoll = client:GetRelay("ragdoll")
    if ( IsValid(existingRagdoll) ) then
        existingRagdoll:Remove()
        client:SetRelay("ragdoll", nil)
    end

    if ( hook.Run("PreSpawnClientRagdoll", client, attacker, dmgInfo ) != false ) then
        local ragdoll = client:CreateRagdoll()

        hook.Run("PostSpawnClientRagdoll", client, ragdoll, attacker, dmgInfo)
    end
end

function GM:PlayerDeath(client, inflictor, attacker)
    local character = client:GetCharacter()
    if ( character ) then
        local clientRagdoll = client:GetRelay("ragdoll")
        if ( IsValid(clientRagdoll) and hook.Run("ShouldRemoveRagdollOnDeath", client) != false ) then
            clientRagdoll:Remove()
        end

        local deathSound = hook.Run("GetPlayerDeathSound", client, inflictor, attacker)
        if ( deathSound and deathSound != "" and !client:InObserver() ) then
            client:EmitSound(deathSound, 75, 100, 1, CHAN_VOICE)
        end

        client:SetRelay("respawnTime", CurTime() + ax.config:Get("time.respawn", 60))
    end
end

local deathSounds = {
    Sound("vo/npc/male01/pain07.wav"),
    Sound("vo/npc/male01/pain08.wav"),
    Sound("vo/npc/male01/pain09.wav")
}

function GM:GetPlayerDeathSound(client, inflictor, attacker)
    local factionData = client:GetFactionData()
    if ( factionData and factionData.DeathSounds and factionData.DeathSounds[1] != nil ) then
        local sound = factionData.DeathSounds[math.random(#factionData.DeathSounds)]
        if ( sound and sound != "" ) then
            return sound
        end
    end

    return deathSounds[math.random(#deathSounds)]
end

function GM:PostPlayerDropItem(client, item, entity)
    if ( !item or !IsValid(entity) ) then return end

    entity:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 4) .. ".wav", 75, math.random(90, 110), 1, CHAN_ITEM)
end

function GM:PostPlayerTakeItem(client, item, entity)
    if ( !item or !IsValid(entity) ) then return end

    entity:EmitSound("physics/body/body_medium_impact_soft" .. math.random(5, 7) .. ".wav", 75, math.random(90, 110), 1, CHAN_ITEM)
end

function GM:PrePlayerConfigChanged(client, key, value, oldValue)
end

function GM:ShowHelp(client)
    return false
end

function GM:OnEntityCreated(entity)
    timer.Simple(0.1, function()
        if ( !IsValid(entity) ) then return end

        if ( entity:IsDoor() ) then
            entity:SetRelay("locked", entity:IsLocked())

            local master = entity:GetMasterDoor()
            if ( IsValid(master) ) then
                entity:SetRelay("master", master:EntIndex())
            end
        end
    end)
end

gameevent.Listen("OnRequestFullUpdate")
hook.Add("OnRequestFullUpdate", "ax.OnRequestFullUpdate", function(data)
    if ( !istable(data) or !isnumber(data.userid) ) then return end

    local client = Player(data.userid)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    if ( clientTable.axReady ) then return end

    clientTable.axReady = true

    timer.Simple(0, function()
        if ( !IsValid(client) ) then return end
        hook.Run("PlayerReady", client)
    end)
end)

local function IsAdmin(_, client)
    return client:IsAdmin()
end

GM.PlayerSpawnEffect = IsAdmin
GM.PlayerSpawnObject = IsAdmin
GM.PlayerSpawnProp = IsAdmin
GM.PlayerSpawnRagdoll = IsAdmin
GM.PlayerSpawnSENT = IsAdmin
GM.PlayerSpawnSWEP = IsAdmin
GM.PlayerGiveSWEP = IsAdmin
GM.PlayerSpawnVehicle = IsAdmin

function GM:PlayerSpawnNPC(client, npc_type, weapon)
    local character = client:GetCharacter()
    if ( !character ) then return end

    return character:HasFlag("n") or client:IsAdmin()
end
