-- https://github.com/SuperiorServers/dash/blob/master/lua/dash/extensions/player.lua

local PLAYER, ENTITY = FindMetaTable 'Player', FindMetaTable 'Entity'
local GetTable = ENTITY.GetTable

function player.GetStaff()
    return table.Filter(player.Iterator(), PLAYER.IsAdmin)
end

function PLAYER:__index(key)
    -- ENTITY.GetTable may be nil in some environments (clientside in modern GMod)
    -- so guard against it to avoid 'attempt to index a nil value'.
    local val = PLAYER[key] or ENTITY[key]
    if val != nil then return val end

    if ( isfunction(GetTable) ) then
        local tbl = GetTable(self)
        if ( istable(tbl) ) then
            return tbl[key]
        end
    end

    return nil
end

function PLAYER:Timer(name, time, reps, callback, failure)
    name = self:SteamID64() .. '-' .. name
    timer.Create(name, time, reps, function()
        if IsValid(self) then
            callback(self)
        else
            if (failure) then
                failure()
            end

            timer.Remove(name)
        end
    end)
end

function PLAYER:RemoveTimer(name)
    timer.Remove(self:SteamID64() .. '-' .. name)
end

if ( CLIENT ) then return end

-- Fix for https://github.com/Facepunch/garrysmod-issues/issues/2447
local telequeue = {}
local setpos = ENTITY.SetPos
function PLAYER:SetPos(pos)
    telequeue[self] = pos
end

hook.Add('FinishMove', 'SetPos.FinishMove', function(pl)
    if telequeue[pl] then
        setpos(pl, telequeue[pl])
        telequeue[pl] = nil
        return true
    end
end)
