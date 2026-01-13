--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.flag:Create("p", {
    name = "flag.p.name",
    description = "flag.p.description",
    OnTaken = function(this, character)
        local client = character:GetOwner()
        if ( IsValid(client) and client:HasWeapon("weapon_physgun") ) then
            client:StripWeapon("weapon_physgun")
            client:Notify("You have lost your permission to use the physgun.")
        end
    end,
    OnGiven = function(this, character)
        local client = character:GetOwner()
        if ( IsValid(client) and !client:HasWeapon("weapon_physgun") ) then
            client:Give("weapon_physgun")
            client:Notify("You have been granted permission to use the physgun.")
        end
    end
})

ax.flag:Create("t", {
    name = "flag.t.name",
    description = "flag.t.description",
    OnTaken = function(this, character)
        local client = character:GetOwner()
        if ( IsValid(client) and client:HasWeapon("gmod_tool") ) then
            client:StripWeapon("gmod_tool")
            client:Notify("You have lost your permission to use the toolgun.")
        end
    end,
    OnGiven = function(this, character)
        local client = character:GetOwner()
        if ( IsValid(client) and !client:HasWeapon("gmod_tool") ) then
            client:Give("gmod_tool")
            client:Notify("You have been granted permission to use the toolgun.")
        end
    end
})
