--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.data = ax.data or {}
ax.data.stored = ax.data.stored or {}

file.CreateDir("parallax")

function ax.data:Set(key, value, bGlobal, bMap)
    local path = "parallax/"
    if ( !bGlobal and SCHEMA and SCHEMA.Folder ) then
        path = path .. SCHEMA.Folder .. "/"
    end

    if ( !bMap ) then
        path = path .. game.GetMap() .. "/"
    end

    file.CreateDir(path)
    file.Write(path .. key .. ".json", util.TableToJSON({value}))

    self.stored[key] = value

    return path
end

function ax.data:Get(key, fallback, bGlobal, bMap, bRefresh)
    local stored = self.stored[key]
    if ( !bRefresh and stored != nil ) then
        return stored
    end

    local path = "parallax/"
    if ( !bGlobal and SCHEMA and SCHEMA.Folder ) then
        path = path .. SCHEMA.Folder .. "/"
    end

    if ( !bMap ) then
        path = path .. game.GetMap() .. "/"
    end

    local data = file.Read(path .. key .. ".json", "DATA")
    if ( data != nil ) then
        data = util.JSONToTable(data)

        self.stored[key] = data[1]
        return data[1]
    end

    return fallback
end

ax.data = ax.data