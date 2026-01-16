--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "PAC3 Flag"
MODULE.description = "Adds a flag to PAC3."
MODULE.author = "Riggs"

function MODULE:PrePACConfigApply(client)
    if ( client:GetCharacter() ) then
        return client:GetCharacter():HasFlags("P")
    end

    return false
end

function MODULE:PrePACEditorOpen(client)
    if ( client:GetCharacter() ) then
        return client:GetCharacter():HasFlags("P")
    end

    return false
end

function MODULE:pac_CanWearParts(client)
    if ( client:GetCharacter() ) then
        return client:GetCharacter():HasFlags("P")
    end

    return false
end

ax.flag:Create("P", {
    name = "PAC3 Permission",
    description = "Allows the use of PAC3.",
})
