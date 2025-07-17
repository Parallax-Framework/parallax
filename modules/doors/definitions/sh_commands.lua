--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Set all doors as unownable
ax.command:Register("DoorsSetAllUnownable", {
    Description = "Set all doors in the map as unownable",
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Doors", nil) ) then
            client:Notify("You don't have permission to manage doors!")
            return
        end

        local count = MODULE.doors:SetAllUnownable()
        client:Notify("Set " .. count .. " doors as unownable")

        -- Log the action
        ax.util:Print(client:Nick() .. " set all doors as unownable (" .. count .. " doors)")
    end
})

--- Set all doors as ownable
ax.command:Register("DoorsSetAllOwnable", {
    Description = "Set all doors in the map as ownable",
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Doors", nil) ) then
            client:Notify("You don't have permission to manage doors!")
            return
        end

        local count = MODULE.doors:SetAllOwnable()
        client:Notify("Set " .. count .. " doors as ownable")

        -- Log the action
        ax.util:Print(client:Nick() .. " set all doors as ownable (" .. count .. " doors)")
    end
})

--- Set nearby doors as unownable
ax.command:Register("DoorsSetNearbyUnownable", {
    Description = "Set nearby doors as unownable",
    Arguments = {
        {
            Type = ax.types.number,
            Optional = true,
            ErrorMsg = "Invalid distance value!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Doors", nil) ) then
            client:Notify("You don't have permission to manage doors!")
            return
        end

        local distance = arguments[1] or 128
        local pos = client:GetPos()
        local nearby = MODULE.doors:GetNearby(pos, distance)

        if ( #nearby == 0 ) then
            client:Notify("No doors found within " .. distance .. " units!")
            return
        end

        for i = 1, #nearby do
            MODULE.doors:SetOwnable(nearby[i], false)
        end

        client:Notify("Set " .. #nearby .. " nearby doors as unownable")
        ax.util:Print(client:Nick() .. " set " .. #nearby .. " nearby doors as unownable")
    end
})

--- Set nearby doors as ownable
ax.command:Register("DoorsSetNearbyOwnable", {
    Description = "Set nearby doors as ownable",
    Arguments = {
        {
            Type = ax.types.number,
            Optional = true,
            ErrorMsg = "Invalid distance value!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Doors", nil) ) then
            client:Notify("You don't have permission to manage doors!")
            return
        end

        local distance = arguments[1] or 128
        local pos = client:GetPos()
        local nearby = MODULE.doors:GetNearby(pos, distance)

        if ( #nearby == 0 ) then
            client:Notify("No doors found within " .. distance .. " units!")
            return
        end

        for i = 1, #nearby do
            MODULE.doors:SetOwnable(nearby[i], true)
        end

        client:Notify("Set " .. #nearby .. " nearby doors as ownable")
        ax.util:Print(client:Nick() .. " set " .. #nearby .. " nearby doors as ownable")
    end
})

--- List door information
ax.command:Register("DoorsInfo", {
    Description = "Display information about doors",
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Doors", nil) ) then
            client:Notify("You don't have permission to manage doors!")
            return
        end

        local totalDoors = 0
        local ownableDoors = 0
        local ownedDoors = 0

        for i, door in ipairs(ents.GetAll()) do
            if ( door:IsDoor() ) then
                totalDoors = totalDoors + 1

                if ( MODULE.doors:IsOwnable(door) ) then
                    ownableDoors = ownableDoors + 1

                    local owner = Entity(door:GetRelay("owner", 0))
                    if ( IsValid(owner) ) then
                        ownedDoors = ownedDoors + 1
                    end
                end
            end
        end

        client:Notify("Door Statistics:")
        client:Notify("  Total doors: " .. totalDoors)
        client:Notify("  Ownable doors: " .. ownableDoors)
        client:Notify("  Owned doors: " .. ownedDoors)
        client:Notify("  Unownable doors: " .. (totalDoors - ownableDoors))
    end
})