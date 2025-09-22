--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function ents.FindInCube(center, radius)
    if ( !isvector(center) ) then
        return error("Invalid argument: 'center' must be a Vector")
    end

    if ( !isnumber(radius) or radius <= 0 ) then
        return error("Invalid argument: 'radius' must be a positive number")
    end

    local rvec = Vector(radius, radius, radius)
    return ents.FindInBox(center - rvec, center + rvec)
end