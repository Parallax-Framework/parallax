--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

function PANEL:Init()
    ax.gui.admin = self

    self:Dock(FILL)
    self:InvalidateParent(true)
end

vgui.Register("ax.tab.admin", PANEL, "EditablePanel")

hook.Add("PopulateTabButtons", "ax.tab.admin", function(buttons)
    if ( !ax.client:IsAdmin() ) then return end -- TODO: Replace with proper permission check

    buttons["admin"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.admin")
        end,
        Sections = {
            ["activity"] = {
                Populate = function(this, panel)
                    panel:Add("ax.tab.admin.activity")
                end
            }
        }
    }
end)
