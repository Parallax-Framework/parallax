--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Default colors
ax.color:Register("black", color_black)
ax.color:Register("blue", Color(0, 0, 255, 255))
ax.color:Register("blue.soft", Color(100, 100, 255, 255))
ax.color:Register("brown", Color(165, 40, 40, 255))
ax.color:Register("brown.soft", Color(200, 100, 100, 255))
ax.color:Register("cyan", Color(0, 255, 255, 255))
ax.color:Register("cyan.soft", Color(100, 255, 255, 255))
ax.color:Register("dark.gray", Color(170, 170, 170, 255))
ax.color:Register("dark.gray.soft", Color(190, 190, 190, 255))
ax.color:Register("gray", Color(130, 130, 130, 255))
ax.color:Register("gray.soft", Color(170, 170, 170, 255))
ax.color:Register("green", Color(0, 255, 0, 255))
ax.color:Register("green.soft", Color(100, 255, 100, 255))
ax.color:Register("light.gray", Color(210, 210, 210, 255))
ax.color:Register("light.gray.soft", Color(230, 230, 230, 255))
ax.color:Register("lime", Color(0, 255, 0, 255))
ax.color:Register("lime.soft", Color(100, 255, 100, 255))
ax.color:Register("maroon", Color(130, 0, 0, 255))
ax.color:Register("maroon.soft", Color(180, 100, 100, 255))
ax.color:Register("navy", Color(0, 0, 130, 255))
ax.color:Register("navy.soft", Color(100, 100, 180, 255))
ax.color:Register("olive", Color(130, 130, 0, 255))
ax.color:Register("olive.soft", Color(180, 180, 100, 255))
ax.color:Register("orange", Color(255, 165, 0, 255))
ax.color:Register("orange.soft", Color(255, 200, 100, 255))
ax.color:Register("pink", Color(255, 190, 205, 255))
ax.color:Register("pink.soft", Color(255, 210, 220, 255))
ax.color:Register("purple", Color(130, 0, 130, 255))
ax.color:Register("purple.soft", Color(180, 100, 180, 255))
ax.color:Register("red", Color(255, 0, 0, 255))
ax.color:Register("red.soft", Color(255, 100, 100, 255))
ax.color:Register("silver", Color(190, 190, 190, 255))
ax.color:Register("silver.soft", Color(220, 220, 220, 255))
ax.color:Register("white", color_white)
ax.color:Register("yellow", Color(255, 255, 0, 255))
ax.color:Register("yellow.soft", Color(255, 255, 100, 255))

-- Framework colors
ax.color:Register("background", color_black)
ax.color:Register("background.transparent", Color(0, 0, 0, 255 / 2))
ax.color:Register("background.notification", Color(50, 50, 50, 200))
ax.color:Register("background.slider", Color(200, 200, 200, 100))
ax.color:Register("chat", Color(230, 230, 110, 255))
ax.color:Register("chat.action", color_white)
ax.color:Register("chat.ooc", Color(200, 25, 0, 255))
ax.color:Register("chat.whisper", Color(70, 110, 230, 255))
ax.color:Register("chat.yell", Color(230, 110, 70, 255))
ax.color:Register("foreground", Color(50, 50, 50, 255))
ax.color:Register("foreground.transparent", Color(50, 50, 50, 255 / 2))
ax.color:Register("options.shadow", Color(0, 0, 0, 150))
ax.color:Register("text", Color(200, 200, 200, 255))
ax.color:Register("text.light", color_white)