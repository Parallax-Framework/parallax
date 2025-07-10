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
    if ( button == KEY_F1 and IsFirstTimePredicted() and CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil) ) then
        MODULE:CreateAdminMenu()
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

-- Context menu integration
function MODULE:OnContextMenuOpen()
    if ( !CAMI.PlayerHasAccess(ax.client, "Parallax - Admin Menu", nil) ) then
        return
    end

    local adminPanel = ax.gui.adminContext
    if ( IsValid(adminPanel) ) then
        adminPanel:SetPos(adminPanel.lastPos.x or 0, adminPanel.lastPos.y or 0)
        adminPanel:SetVisible(true)
        adminPanel:MakePopup()
    else
        -- Add admin options to context menu
        adminPanel = vgui.Create("DFrame")
        adminPanel:SetSize(200, 300)
        adminPanel:SetTitle("Quick Admin Menu")
        adminPanel:SetDeleteOnClose(true)
        adminPanel:SetDraggable(true)
        adminPanel:SetScreenLock(true)
        adminPanel:MakePopup()

        local adminBtn = vgui.Create("DButton", adminPanel)
        adminBtn:Dock(TOP)
        adminBtn:SetSize(200, 30)
        adminBtn:SetText("Admin Menu")
        adminBtn.DoClick = function()
            MODULE:CreateAdminMenu()
        end

        local noclipBtn = vgui.Create("DButton", adminPanel)
        noclipBtn:Dock(TOP)
        noclipBtn:SetSize(200, 30)
        noclipBtn:SetText("Toggle Noclip")
        noclipBtn.DoClick = function()
            ax.command:Run("ToggleNoclip")
        end

        local godmodeBtn = vgui.Create("DButton", adminPanel)
        godmodeBtn:Dock(TOP)
        godmodeBtn:SetSize(200, 30)
        godmodeBtn:SetText("Toggle Godmode")
        godmodeBtn.DoClick = function()
            ax.command:Run("ToggleGodmode")
        end

        adminPanel:InvalidateLayout(true)
        adminPanel:SizeToChildren(false, true)
        adminPanel:Center()
        adminPanel.lastPos = { x = adminPanel:GetX(), y = adminPanel:GetY() }

        ax.gui.adminContext = adminPanel
    end
end

function MODULE:OnContextMenuClose()
    local adminPanel = ax.gui.adminContext
    if ( IsValid(adminPanel) ) then
        adminPanel:SetVisible(false)
        adminPanel.lastPos = { x = adminPanel:GetX(), y = adminPanel:GetY() }
    end
end