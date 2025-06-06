local time = CurTime()
function GM:PlayerInitialSpawn(client)
    if ( client:IsBot() ) then
        local factionBot = math.random(#ax.faction.instances)

        local models = {}
        for k, v in ipairs(ax.faction:Get(factionBot):GetModels()) do
            if ( istable(v) ) then
                table.insert(models, v[1])
            else
                table.insert(models, v)
            end
        end

        client:SetModel(models[math.random(#models)])
        client:SetTeam(factionBot)
        return
    end

    time = CurTime()
    ax.util:Print("Starting to load player " .. client:SteamName() .. " (" .. client:SteamID64() .. ")")
end

function GM:PlayerReady(client)
    client:SetTeam(0)
    client:SetModel("models/player/kleiner.mdl")

    client:KillSilent()

    local activeGamemode = engine.ActiveGamemode()
    if ( activeGamemode == "parallax" ) then
        -- Sometimes people might forget to actually set their startup gamemode to their schema rather than the actual framework... so we check for that
        ax.util:PrintError("You are running Parallax without a schema! Please set your startup gamemode to your schema (e.g. 'parallax-skeleton' instead of 'parallax').")
        ax.net:Start(client, "splash")
        return
    end

    ax.character:CacheAll(client, function()
        ax.util:SendChatText(nil, Color(25, 75, 150), client:SteamName() .. " has joined the server.")
        ax.net:Start(client, "splash")

        client:SetNoDraw(true)
        client:SetNotSolid(true)
        client:SetMoveType(MOVETYPE_NONE)

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
    end
end

function GM:PlayerSpawn(client)
    hook.Run("PlayerLoadout", client)
end

function GM:PlayerLoadout(client)
    client:StripAmmo()
    client:StripWeapons()

    if ( hook.Run("PlayerGetToolgun", client) ) then client:Give("gmod_tool") end
    if ( hook.Run("PlayerGetPhysgun", client) ) then client:Give("weapon_physgun") end

    client:Give("ax_hands")
    client:SelectWeapon("ax_hands")

    client:SetWalkSpeed(ax.config:Get("speed.walk", 80))
    client:SetRunSpeed(ax.config:Get("speed.run", 180))
    client:SetJumpPower(ax.config:Get("jump.power", 160))

    client:SetupHands()

    local character = client:GetCharacter()
    if ( character ) then
        -- Restore the character's bodygroups
        local groups = character:GetData("groups", {})
        for name, value in pairs(groups) do
            local id = client:FindBodygroupByName(name)
            if ( id == -1 ) then continue end

            client:SetBodygroup(id, value)
        end
    end

    hook.Run("PostPlayerLoadout", client)

    return true
end

function GM:PostPlayerLoadout(client)
end

function GM:PrePlayerLoadedCharacter(client, character, previousCharacter)
    if ( !client:Alive() or !previousCharacter ) then return end

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
    previousCharacter:SetData("last_ang", client:GetAngles())
    previousCharacter:SetPlayTime(previousCharacter:GetPlayTime() + (os.time() - previousCharacter:GetLastPlayed()))
    previousCharacter:SetLastPlayed(os.time())
end

function GM:PostPlayerLoadedCharacter(client, character, previousCharacter)
    if ( !client:Alive() or !character ) then return end

    -- Restore character state
    local lastPos = character:GetData("last_pos")
    local lastAng = character:GetData("last_ang")
    if ( lastPos and lastAng ) then
        client:SetPos(lastPos)
        client:SetAngles(lastAng)
    end

    client:SetHealth(character:GetData("health", 100))

    -- And now wipe it
    character:SetData("last_pos", nil)
    character:SetData("last_ang", nil)
    character:SetData("health", nil)

    hook.Run("PostPlayerLoadedCharacter", client, character, previousCharacter)
end

function GM:PlayerDeathThink(client)
    if ( client:Team() == 0 ) then
        return
    end

    local respawnTime = ax.config:Get("time.respawn", 60)
    if ( respawnTime <= 0 ) then
        client:Spawn()
    end

    -- TODO: uh, some happy day this should be replaced
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
    if ( ax.sqloo == nil ) then
        ax.database:Initialize()
    end

    ax.module:LoadFolder("parallax/modules")
    ax.item:LoadFolder("parallax/gamemode/items")
    ax.schema:Initialize()

    if ( game.IsDedicated() ) then
        -- Production (dedicated server)
        RunConsoleCommand("sv_allowupload", "0")
        RunConsoleCommand("sv_allowdownload", "0")
        RunConsoleCommand("net_maxfilesize", "64")
        RunConsoleCommand("sv_kickerrornum", "1")
        RunConsoleCommand("sv_maxrate", "30000")
        RunConsoleCommand("sv_minrate", "5000")
        RunConsoleCommand("sv_maxcmdrate", "66")
        RunConsoleCommand("sv_maxupdaterate", "66")
        RunConsoleCommand("sv_mincmdrate", "30")
        RunConsoleCommand("sv_allowcslua", "0")
    else
        -- Development (listen server)
        RunConsoleCommand("sv_allowupload", "0")
        RunConsoleCommand("sv_allowdownload", "0")
        RunConsoleCommand("net_maxfilesize", "128")
        RunConsoleCommand("sv_kickerrornum", "0")
        RunConsoleCommand("sv_maxrate", "60000")
        RunConsoleCommand("sv_minrate", "10000")
        RunConsoleCommand("sv_maxcmdrate", "100")
        RunConsoleCommand("sv_maxupdaterate", "100")
        RunConsoleCommand("sv_mincmdrate", "30")
        RunConsoleCommand("sv_allowcslua", "1")
    end
end

local _reloaded = false
function GM:OnReloaded()
    if ( _reloaded ) then return end
    _reloaded = true

    if ( ax.sqloo == nil ) then
        ax.database:Initialize()
    end

    ax.module:LoadFolder("parallax/modules")
    ax.item:LoadFolder("parallax/gamemode/items")
    ax.schema:Initialize()

    ax.config:Synchronize()
end

function GM:DatabaseConnected()
    hook.Run("LoadData")
end

function GM:DatabaseConnectionFailed()
    ax.util:PrintError("Database connection failed, falling back to SQLite.")
    ax.database:Fallback()
end

function GM:DatabaseFallback(reason)
    ax.database:LoadTables()
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
    if ( speed > 100 ) then
        ax.util:Print("I would ragdoll the player... but missing function!")
        -- TODO: Implement this in the future
        -- client:Ragdoll()
    end

    return speed / 8
end

function GM:PostPlayerLoadedCharacter(client, character, previousCharacter)
    -- Restore the bodygroups of the character
    local groups = character:GetData("groups", {})
    for name, value in pairs(groups) do
        local id = client:FindBodygroupByName(name)
        if ( id == -1 ) then continue end

        client:SetBodygroup(id, value)
    end

    local classData = character:GetClassData()
    if ( istable(classData) and isfunction(classData.OnLoaded) ) then
        classData:OnLoaded(client, character)
    end

    local skin = character:GetSkin()
    if ( isnumber(skin) ) then
        client:SetSkin(skin)
    end
end

local nextThink = CurTime() + 1
local nextSave = CurTime() + ax.config:Get("save.interval", 300)
local playerVoiceListeners = {}
function GM:Think()
    if ( CurTime() >= nextThink ) then
        nextThink = CurTime() + 1

        for _, client in player.Iterator() do
            if ( !client:Alive() ) then continue end
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
    ax.util:Print("Shutting down Parallax...")
    ax.shutDown = true

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

local painSounds = {
    Sound("vo/npc/male01/pain01.wav"),
    Sound("vo/npc/male01/pain02.wav"),
    Sound("vo/npc/male01/pain03.wav"),
    Sound("vo/npc/male01/pain04.wav"),
    Sound("vo/npc/male01/pain05.wav"),
    Sound("vo/npc/male01/pain06.wav")
}

local drownSounds = {
    Sound("player/pl_drown1.wav"),
    Sound("player/pl_drown2.wav"),
    Sound("player/pl_drown3.wav"),
}

function GM:GetPlayerPainSound(client, attacker, healthRemaining, damageTaken)
    local character = client:GetCharacter()
    if ( !character ) then return end

    if ( client:Health() <= 0 ) then return end

    local factionData = character:GetFactionData()
    if ( client:IsOnFire() ) then
        if ( factionData and factionData.FirePainSounds and factionData.FirePainSounds[1] != nil ) then
            local sound = factionData.FirePainSounds[math.random(#factionData.FirePainSounds)]
            if ( sound and sound != "" ) then
                return sound
            end
        end

        return Sound("ambient/fire/fire_small1.wav")
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

        return drownSounds[math.random(#drownSounds)]
    end

    if ( damageTaken > 0 ) then
        if ( factionData and factionData.PainSounds and factionData.PainSounds[1] != nil ) then
            local sound = factionData.PainSounds[math.random(#factionData.PainSounds)]
            if ( isstring(sound) and sound != "" ) then
                return sound
            end
        end

        return painSounds[math.random(#painSounds)]
    end
end

function GM:DoPlayerDeath(client, attacker, dmgInfo)
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
            -- don't use file exists, a soundscript could be used.

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

local function IsAdmin(_, client)
    return client:IsAdmin()
end

GM.PlayerSpawnEffect = IsAdmin
GM.PlayerSpawnNPC = IsAdmin
GM.PlayerSpawnObject = IsAdmin
GM.PlayerSpawnProp = IsAdmin
GM.PlayerSpawnRagdoll = IsAdmin
GM.PlayerSpawnSENT = IsAdmin
GM.PlayerSpawnSWEP = IsAdmin
GM.PlayerGiveSWEP = IsAdmin
GM.PlayerSpawnVehicle = IsAdmin