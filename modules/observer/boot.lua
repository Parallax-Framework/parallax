--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Observer"
MODULE.Author = "Riggs"
MODULE.Description = "Provides a system for observer mode."

local meta = FindMetaTable("Player")
function meta:InObserver()
    return self:GetMoveType() == MOVETYPE_NOCLIP and CAMI.PlayerHasAccess(self, "Parallax - Observer", nil) and self:GetNoDraw()
end

CAMI.RegisterPrivilege({
    Name = "Parallax - Observer",
    MinAccess = "admin"
})