--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--[[
    Option System - Per-client preferences with optional server sync

    Examples:
    ax.option:Add("headbob", ax.type.bool, true, { category = "camera", subCategory = "view" })
    ax.option:Add("language", ax.type.array, "english", {
        bNetworked = true,
        category = "general",
        subCategory = "basic",
        populate = function() return { english = "English", german = "German", french = "French" } end
    })

    if CLIENT then
        print(ax.option:Get("headbob", true))
        ax.option:Set("headbob", false)  -- saves client-side; networks only if bNetworked=true
        ax.option:Sync()                 -- push all networked options now
    end

    if SERVER then
        -- Read a player's networked option
        local client = somePlayer
        print(ax.option:Get(client, "language", "english"))
    end
]]

-- Create the option store
local optionSpec = {
    name = "option",
    path = "parallax/options.json",
    authority = "client",
    net = {
        sync = "ax.option.sync",
        set = "ax.option.set",
        request = "option.request"
    },
    perPlayer = true,
    networkedFlagKey = "bNetworked"
}

ax.option = ax.util:CreateStore(optionSpec)
ax.option:_setupNetworking()

-- Load options on client startup
if ( CLIENT ) then
    ax.option:Load()
end
