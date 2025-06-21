--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PLAYER = FindMetaTable("Player")

--- Gets a specific data value associated with the player.
-- @realm client
-- @tparam string key The key of the data to retrieve.
-- @param default The default value to return if the key does not exist.
-- @return The value associated with the key, or the default value.
function PLAYER:GetData(key, default)
    local tbl = self:GetTable()
    local axDatabase = tbl.axDatabase
    if ( !axDatabase ) then
        Parallax.Util:PrintError("Player does not have a database connection, unable to get data.")
        return default
    end

    local data = axDatabase.data or {}
    if ( isstring(data) ) then
        data = util.JSONToTable(data) or {}
    else
        data = data or {}
    end

    return data[key] != nil and data[key] or default
end