--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

-- Bind F1 to admin menu
function MODULE:PlayerButtonDown(client, button)
    if ( !IsFirstTimePredicted() ) then return end

    if ( button == KEY_F4 and CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil) ) then
        MODULE:CreateAdminMenu()
    elseif ( button == KEY_F3 and ax.config:Get("admin.tickets.enabled", true) ) then
        MODULE:CreateTicketMenu()
    end
end

-- Admin chat colors
function MODULE:GetNameColor(client)
    if ( !IsValid(client) ) then return end

    local color = MODULE:GetGroupColor(client)
    if ( color ) then
        return color
    end
end