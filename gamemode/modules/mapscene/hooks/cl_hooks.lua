--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:ShouldDrawHealthHUD()
    if ( ax.mapscene:ShouldRenderMapScene(ax.client) ) then
        return false
    end
end

function MODULE:ShouldDrawArmorHUD()
    if ( ax.mapscene:ShouldRenderMapScene(ax.client) ) then
        return false
    end
end

function MODULE:ShouldDrawVoiceChatIcon()
    if ( ax.mapscene:ShouldRenderMapScene(ax.client) ) then
        return false
    end
end

function MODULE:PreDrawViewModel(viewModel, client, weapon)
    if ( ax.mapscene:ShouldRenderMapScene(client) ) then
        return true
    end
end

ax.viewstack:RegisterModifier("mapscene", function(client, patch)
    if ( !ax.mapscene ) then return end

    return ax.mapscene:ApplyView(client, patch)
end, 999)
