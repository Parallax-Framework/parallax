--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Clean up existing hook to prevent duplicates on reload
hook.Remove("PopulateTabButtons", "ax.tab.settings")

hook.Add("PopulateTabButtons", "ax.tab.settings", function(buttons)
    buttons["settings"] = {
        Populate = function(this, panel)
            local settings = panel:Add("ax.store")
            settings:SetType("option")
        end
    }
end)
