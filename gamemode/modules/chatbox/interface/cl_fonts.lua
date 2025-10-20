--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:LoadFonts()
    surface.CreateFont("ax.chatbox.text", {
        font = "Inter", size = ax.util:ScreenScaleH(8), weight = 500,
        antialias = true, extended = true
    })

    surface.CreateFont("ax.chatbox.text.bold", {
        font = "Inter", size = ax.util:ScreenScaleH(8), weight = 900,
        antialias = true, extended = true
    })

    surface.CreateFont("ax.chatbox.text.italic", {
        font = "Inter", size = ax.util:ScreenScaleH(8), weight = 500, italic = true,
        antialias = true, extended = true
    })
end
