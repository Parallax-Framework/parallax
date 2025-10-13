--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.option:Add("performanceAnimations", ax.type.bool, true, { category = "performance", description = "Enable or disable interface animations." })
ax.option:Add("inventoryCategoriesItalic", ax.type.bool, true, { category = "interface", description = "Display inventory categories in italic style." })
ax.option:Add("keybindTest", ax.type.number, 0, { keybind = true, category = "controls", description = "Test keybind option." })
