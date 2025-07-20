--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local client = FindMetaTable("Player")

local steamName = steamName or client.Name
function client:Name()
    local character = self:GetCharacter()
    return character and character.name or steamName(self)
end

function client:SteamName()
    return steamName(self)
end

function client:GetCharacter()
    return self:GetTable().axCharacter
end