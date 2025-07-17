--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Initialize door system
function MODULE:Initialize()
    -- Set up all doors based on default config
    if ( ax.config:Get("door.defaultUnownable", false) ) then
        timer.Simple(1, function()
            MODULE.doors:SetAllUnownable()
            ax.util:Print("Set all doors as unownable by default")
        end)
    end
end

--- Handle entity spawning
function MODULE:OnEntityCreated(ent)
    if ( !IsValid(ent) or !ent:IsDoor() ) then return end
    
    -- Apply default unownable setting to new doors
    if ( ax.config:Get("door.defaultUnownable", false) ) then
        timer.Simple(0.1, function()
            if ( IsValid(ent) ) then
                ent:SetRelay("unownable", true)
            end
        end)
    end
end

