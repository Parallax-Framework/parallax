----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- ax.stamina
-- Cross-realm stamina library.
-- Server handles regeneration/consumption; client reads synced relay.

local MODULE = MODULE
MODULE.Name = "Stamina"
MODULE.Author = "Riggs"
MODULE.Description = "Stamina library."

ax.stamina = ax.stamina or {}

ax.config:Register("stamina.drain", {
    Name = "config.stamina.drain",
    Description = "config.stamina.drain.help",
    Category = "config.stamina",
    Type = ax.types.number,
    Default = 5,
    Min = 0,
    Max = 100,
    Decimals = 1
})

ax.config:Register("stamina", {
    Name = "config.stamina",
    Description = "config.stamina.help",
    Category = "config.stamina",
    Type = ax.types.bool,
    Default = true
})

ax.config:Register("stamina.max", {
    Name = "config.stamina.max",
    Description = "config.stamina.max.help",
    Category = "config.stamina",
    Type = ax.types.number,
    Default = 100,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("stamina.regen", {
    Name = "config.stamina.regen",
    Description = "config.stamina.regen.help",
    Category = "config.stamina",
    Type = ax.types.number,
    Default = 2,
    Min = 0,
    Max = 100,
    Decimals = 1
})

ax.config:Register("stamina.tick", {
    Name = "config.stamina.tick",
    Description = "config.stamina.tick.help",
    Category = "config.stamina",
    Type = ax.types.number,
    Default = 0.1,
    Min = 0,
    Max = 1,
    Decimals = 2
})

if ( SERVER ) then
    --- Initializes a stamina object for a player
    -- @param client Player
    -- @param max number
    function ax.stamina:Initialize(client, max)
        max = max or ax.config:Get("stamina.max", 100)

        client:SetRelay("stamina", {
            max = max,
            current = max,
            regenRate = 5,
            regenDelay = 1.0,
            lastUsed = 0
        })
    end

    --- Consumes stamina from a player
    -- @param client Player
    -- @param amount number
    -- @return boolean
    function ax.stamina:Consume(client, amount)
        local st = client:GetRelay("stamina")
        if ( !istable(st) ) then return false end

        st.current = math.Clamp(st.current - amount, 0, st.max)
        st.lastUsed = CurTime()

        client:SetRelay("stamina", st)
        return true
    end

    --- Checks if player has enough stamina
    -- @param client Player
    -- @param amount number
    -- @return boolean
    function ax.stamina:CanConsume(client, amount)
        local st = client:GetRelay("stamina")
        return st and st.current >= amount
    end

    --- Adds stamina to a player
    -- @param client Player
    -- @param amount number
    -- @return boolean
    function ax.stamina:Add(client, amount)
        local st = client:GetRelay("stamina")
        if ( !istable(st) ) then return false end

        st.current = math.Clamp(st.current + amount, 0, st.max)
        client:SetRelay("stamina", st)
        return true
    end

    --- Gets current stamina
    -- @param client Player
    -- @return number
    function ax.stamina:Get(client)
        local st = client:GetRelay("stamina")
        return istable(st) and st.current or 0
    end

    --- Sets current stamina
    -- @param client Player
    -- @param value number
    function ax.stamina:Set(client, value)
        local st = client:GetRelay("stamina")
        if ( !istable(st) or st.current == value ) then return end

        st.current = math.Clamp(value, 0, st.max)
        client:SetRelay("stamina", st)
    end
end

if ( CLIENT ) then
    local deLocalization = {}
    deLocalization["config.stamina"] = "Ausdauer"
    deLocalization["config.stamina.drain"] = "Ausdauerabflussrate"
    deLocalization["config.stamina.drain.help"] = "Die Rate, mit der die Ausdauer des Spielers abfließt."
    deLocalization["config.stamina.help"] = "Aktivieren oder deaktivieren Sie die Ausdauer."
    deLocalization["config.stamina.max"] = "Maximale Ausdauer"
    deLocalization["config.stamina.max.help"] = "Die maximale Menge an Ausdauer, die der Spieler haben kann. Spieler müssen sich neu spawn, um dies anzuwenden."
    deLocalization["config.stamina.regen"] = "Ausdauerregenerationsrate"
    deLocalization["config.stamina.regen.help"] = "Die Rate, mit der die Ausdauer des Spielers regeneriert wird."
    deLocalization["config.stamina.tick"] = "Ausdauer-Tickrate"
    deLocalization["config.stamina.tick.help"] = "Die Rate, mit der die Ausdauer des Spielers aktualisiert wird."

    local enLocalization = {}
    enLocalization["config.stamina"] = "Stamina"
    enLocalization["config.stamina.drain"] = "Stamina Drain Rate"
    enLocalization["config.stamina.drain.help"] = "The rate at which the player's stamina drains."
    enLocalization["config.stamina.help"] = "Enable or disable stamina."
    enLocalization["config.stamina.max"] = "Max Stamina"
    enLocalization["config.stamina.max.help"] = "The maximum amount of stamina the player can have, players need to respawn to apply this."
    enLocalization["config.stamina.regen"] = "Stamina Regen Rate"
    enLocalization["config.stamina.regen.help"] = "The rate at which the player's stamina regenerates."
    enLocalization["config.stamina.tick"] = "Stamina Tick Rate"
    enLocalization["config.stamina.tick.help"] = "The rate at which the player's stamina is updated."

    local ruLocalization = {}
    ruLocalization["config.stamina"] = "Выносливость"
    ruLocalization["config.stamina.drain"] = "Скорость поглощения выносливости"
    ruLocalization["config.stamina.drain.help"] = "Скорость с которой поглащается выносливость игрока."
    ruLocalization["config.stamina.help"] = "Должна ли выносливость быть включена?"
    ruLocalization["config.stamina.max"] = "Максимальная выносливость"
    ruLocalization["config.stamina.max.help"] = "Максимальное кол-во выносливости которое может иметь игрок, для принятия эффекта игрок должен перевозродиться."
    ruLocalization["config.stamina.regen"] = "Скорость восстановления выносливости"
    ruLocalization["config.stamina.regen.help"] = "Скорость с которой восстанавливается выносливость игрока."
    ruLocalization["config.stamina.tick"] = "Интервал обновления выносливости"
    ruLocalization["config.stamina.tick.help"] = "Интервал, с которым обновляется выносливость игрока."

    ax.localization:Register("de", deLocalization)
    ax.localization:Register("en", enLocalization)
    ax.localization:Register("ru", ruLocalization)

    --- Gets the local player's stamina from relay
    -- @return number
    function ax.stamina:Get()
        return ax.client:GetRelay("stamina").current
    end

    --- Gets the local player's stamina as a fraction [0–1]
    -- @return number
    function ax.stamina:GetFraction()
        local max = ax.client:GetRelay("stamina").max
        return self:Get() / max
    end
end