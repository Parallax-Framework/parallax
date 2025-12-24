-- https://github.com/SuperiorServers/dash/blob/master/lua/dash/extensions/player.lua

local PLAYER, ENTITY = FindMetaTable 'Player', FindMetaTable 'Entity'
local GetTable = ENTITY.GetTable

function player.Find(info)
    info = tostring(info)
    for k, v in player.Iterator() do
        if (info == v:SteamID()) or (info == v:SteamID64()) or (string.find(string.lower(v:Name()), string.lower(info), 1, true) != nil) then
            return v
        end
    end
end

function player.GetStaff()
    return table.Filter(player.Iterator(), PLAYER.IsAdmin)
end

function PLAYER:__index(key)
    return PLAYER[key] or ENTITY[key] or GetTable(self)[key]
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
