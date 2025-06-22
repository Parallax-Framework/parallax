--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.flag:Register("t", "flag.toolgun", function(info, char, has)
    local client = char:GetPlayer()
    if ( !IsValid(client) ) then return end

    if ( has ) then
        client:Give("gmod_tool")
    else
        local wep = client:GetActiveWeapon()
        if ( IsValid(wep) and wep:GetClass() == "gmod_tool" ) then
            client:SelectWeapon("ax_hands")
        end

        client:StripWeapon("gmod_tool")
    end
end)

ax.flag:Register("p", "flag.physgun", function(info, char, has)
    local client = char:GetPlayer()
    if ( !IsValid(client) ) then return end

    if ( has ) then
        client:Give("weapon_physgun")
    else
        local wep = client:GetActiveWeapon()
        if ( IsValid(wep) and wep:GetClass() == "weapon_physgun" ) then
            client:SelectWeapon("ax_hands")
        end

        client:StripWeapon("weapon_physgun")
    end
end)

ax.flag:Register("s", "flag.spawnmenu", nil)
ax.flag:Register("n", "flag.npc", nil)