--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.zones

ax.zones = ax.zones or {}
ax.zones.debug = ax.zones.debug or false

ax.net:Hook("zones.drawdebug", function(enabled)
    ax.zones.debug = enabled == true
end)

hook.Add("PostDrawOpaqueRenderables", "ax.zones.debug", function()
    if ( !ax.zones.debug ) then return end

    local client = ax.client
    if ( !ax.util:IsValidPlayer(client) ) then return end

    local eyePos = client:EyePos()

    for id, zone in pairs(ax.zones.stored) do
        local shouldDraw = false
        local center = Vector()

        -- Determine center and distance check
        if ( zone.type == "box" ) then
            center = (zone.mins + zone.maxs) / 2
            shouldDraw = center:DistToSqr(eyePos) < (2000 * 2000)
        elseif ( zone.type == "sphere" ) then
            center = zone.center
            shouldDraw = center:DistToSqr(eyePos) < (2000 * 2000)
        elseif ( zone.type == "pvs" or zone.type == "trace" ) then
            center = zone.origin
            shouldDraw = center:DistToSqr(eyePos) < (2000 * 2000)
        end

        if ( !shouldDraw ) then continue end

        -- Draw zone geometry
        local color = Color(0, 255, 0, 100)
        if ( zone.source == "static" ) then
            color = Color(0, 150, 255, 100)
        end

        if ( zone.type == "box" ) then
            render.DrawWireframeBox(center, Angle(0, 0, 0), zone.mins - center, zone.maxs - center, color, true)
        elseif ( zone.type == "sphere" ) then
            render.DrawWireframeSphere(center, zone.radius, 12, 12, color, true)
        elseif ( zone.type == "pvs" or zone.type == "trace" ) then
            -- Draw small sphere at origin
            render.DrawWireframeSphere(center, 32, 8, 8, color, true)
            if ( zone.radius ) then
                -- Draw radius indicator
                render.DrawWireframeSphere(center, zone.radius, 16, 16, Color(color.r, color.g, color.b, 50), true)
            end

            -- For trace zones, draw a different color indicator
            if ( zone.type == "trace" ) then
                -- Draw a small cross to indicate it's a trace zone
                local crossSize = 16
                render.DrawLine(center + Vector(crossSize, 0, 0), center - Vector(crossSize, 0, 0), Color(255, 255, 0, 200), true)
                render.DrawLine(center + Vector(0, crossSize, 0), center - Vector(0, crossSize, 0), Color(255, 255, 0, 200), true)
                render.DrawLine(center + Vector(0, 0, crossSize), center - Vector(0, 0, crossSize), Color(255, 255, 0, 200), true)
            end
        end

        -- Draw label
        local text = string.format("%s (#%d)", zone.name, zone.id)
        local screenPos = center:ToScreen()
        if ( screenPos.visible ) then
            draw.SimpleTextOutlined(
                text,
                "DermaDefault",
                screenPos.x,
                screenPos.y,
                color,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                1,
                Color(0, 0, 0, 200)
            )
        end
    end
end)
