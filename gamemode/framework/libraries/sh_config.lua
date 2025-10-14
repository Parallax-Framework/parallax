--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--[[
    Config System - Server-owned settings with optional client networking

    Examples:
    ax.config:Add("thirdperson", ax.type.bool, true, { description = "Enable third-person view.", bNetworked = true, category = "camera", subCategory = "thirdperson" })
    ax.config:Add("gravityScale", ax.type.number, 1, { min = 0.1, max = 3, decimals = 2, bNetworked = true, category = "gameplay", subCategory = "physics" })

    ax.config:Set("thirdperson", false)
    print(ax.config:Get("thirdperson", true))  -- server: source of truth; client: cached
]]

-- Create the config store
local configSpec = {
    name = "config",
    path = "parallax/config.json",
    authority = "server",
    net = {
        init = "ax.config.init",
        set = "ax.config.set"
    },
    perPlayer = false,
    networkedFlagKey = "bNetworked"
}

ax.config = ax.util:CreateStore(configSpec)
ax.config:_setupNetworking()

-- Load config on server startup
if ( SERVER ) then
    ax.config:Load()
end
