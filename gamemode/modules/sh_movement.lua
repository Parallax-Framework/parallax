--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Movement"
MODULE.description = "Restricts player movement to a specific set of rules."
MODULE.author = "Riggs"

function MODULE:OnPlayerHitGround(client, inWater)
    local bunnyhopVelocityMultiplier = ax.config:Get("movement.bunnyhop.reduction", 0.5)
    local velocity = client:GetVelocity()
    local horizontalVelocity = Vector(velocity.x, velocity.y, 0)
    local reducedVelocity = -horizontalVelocity * bunnyhopVelocityMultiplier
    client:SetVelocity(reducedVelocity)
end
