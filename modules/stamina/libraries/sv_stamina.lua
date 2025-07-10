--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.stamina = ax.stamina or {}

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