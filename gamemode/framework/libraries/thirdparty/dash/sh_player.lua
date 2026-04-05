-- https://github.com/SuperiorServers/dash/blob/master/lua/dash/extensions/player.lua

local ENTITY = FindMetaTable("Entity")
local GetTable = ENTITY.GetTable

function player.GetStaff()
    local staff = {}

    for _, v in player.Iterator() do
        if v:IsAdmin() then
            staff[#staff + 1] = v
        end
    end

    return staff
end

function ax.player.meta:__index(key)
    local val = ax.player.meta[key] or ENTITY[key]
    if ( val != nil ) then return val end

    if ( isfunction(GetTable) ) then
        local tbl = GetTable(self)
        if ( istable(tbl) ) then
            return tbl[key]
        end
    end

    return nil
end

function ax.player.meta:Timer(name, time, reps, callback, failure)
    name = self:SteamID64() .. "-" .. name
    timer.Create(name, time, reps, function()
        if ax.util:IsValidPlayer(self) then
            callback(self)
        else
            if (failure) then
                failure()
            end

            timer.Remove(name)
        end
    end)
end

function ax.player.meta:RemoveTimer(name)
    timer.Remove(self:SteamID64() .. "-" .. name)
end

if ( CLIENT ) then return end

-- Fix for https://github.com/Facepunch/garrysmod-issues/issues/2447
local telequeue = {}
local setpos = ENTITY.SetPos
function ax.player.meta:SetPos(pos)
    telequeue[self] = pos
end

hook.Add("FinishMove", "SetPos.FinishMove", function(pl)
    if ( telequeue[pl] ) then
        setpos(pl, telequeue[pl])
        telequeue[pl] = nil
        return true
    end
end)
