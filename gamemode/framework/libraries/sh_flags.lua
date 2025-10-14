--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Flag management system for characters, if they have flag, they can do something. Can be used for permissions or other things.
-- @module ax.flag

ax.flag = ax.flag or {}
ax.flag.stored = ax.flag.stored or {}

function ax.flag:Create(letter, flagData)
    if ( !isstring(letter) or #letter > 1 ) then
        ax.util:PrintError("Invalid flag letter provided to ax.flag:Create()")
        return
    end

    self.stored[letter] = flagData
end

function ax.flag:GetAll()
    return self.stored
end

function ax.flag:Get(letter)
    if ( !isstring(letter) or #letter > 1 ) then
        ax.util:PrintError("Invalid flag letter provided to ax.flag:Get()")
        return
    end

    return self.stored[letter]
end
