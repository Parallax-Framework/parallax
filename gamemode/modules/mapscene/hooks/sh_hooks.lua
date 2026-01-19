--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function HandleConfigChanged(key, oldValue, value)
    if ( !ax.mapscene ) then return end
    ax.mapscene:OnConfigChanged(key, oldValue, value)
end

hook.Add("OnConfigChanged", "ax.mapscene.ConfigChanged", HandleConfigChanged)
