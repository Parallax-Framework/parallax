--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local width, height = 0, 0
local x, y = 0, 0
width, height = ax.util:ScreenScale(192), ax.util:ScreenScaleH(128)
x, y = ax.util:ScreenScale(8), ScrH() - height - ax.util:ScreenScaleH(8)

ax.option:Add("chatbox.width", ax.type.number, width, {
    description = "The width of the chat box.",
    category = "chatBox",
    subCategory = "size",
    min = 0,
    max = ScrW(),
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("chatbox.height", ax.type.number, height, {
    description = "The height of the chat box.",
    category = "chatBox",
    subCategory = "size",
    min = 0,
    max = ScrH(),
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("chatbox.x", ax.type.number, x, {
    description = "The X position of the chat box.",
    category = "chatBox",
    subCategory = "position",
    min = 0,
    max = ScrW(),
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("chatbox.y", ax.type.number, y, {
    description = "The Y position of the chat box.",
    category = "chatBox",
    subCategory = "position",
    min = 0,
    max = ScrH(),
    decimals = 0,
    bNoNetworking = true
})
