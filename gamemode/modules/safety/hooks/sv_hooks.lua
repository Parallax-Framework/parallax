--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:KeyPress(client, key)
    if ( key == IN_RELOAD ) then
        timer.Create("ax.weapon.raise." .. client:SteamID64(), ax.config:Get("weapon.raise.time", 0.25), 1, function()
            if ( ax.util:IsValidPlayer(client) ) then
                client:ToggleWeaponRaise()
            end
        end)
    end
end

function MODULE:KeyRelease(client, key)
    if ( key == IN_RELOAD ) then
        timer.Remove("ax.weapon.raise." .. client:SteamID64())
    end
end

function MODULE:PlayerSwitchWeapon(client, oldWeapon, newWeapon)
    timer.Simple(0, function()
        if ( ax.util:IsValidPlayer(client) and IsValid(newWeapon) ) then
            client:SetWeaponRaised(false)
        end
    end)
end
