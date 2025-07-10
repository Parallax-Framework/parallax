--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

concommand.Add("ax_thirdperson_toggle", function()
    ax.option:Set("thirdperson", !ax.option:Get("thirdperson", false))
end, nil, ax.localization:GetPhrase("options.thirdperson.toggle"))

concommand.Add("ax_thirdperson_reset", function()
    ax.option:Set("thirdperson.position.x", ax.option:GetDefault("thirdperson.position.x"))
    ax.option:Set("thirdperson.position.y", ax.option:GetDefault("thirdperson.position.y"))
    ax.option:Set("thirdperson.position.z", ax.option:GetDefault("thirdperson.position.z"))
end, nil, ax.localization:GetPhrase("options.thirdperson.reset"))