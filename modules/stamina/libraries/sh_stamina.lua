--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.stamina = ax.stamina or {}

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