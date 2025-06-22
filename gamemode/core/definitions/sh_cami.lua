--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( !tobool(CAMI) ) then
    ax.util:PrintError("CAMI is not installed.")
    return
end

CAMI.RegisterPrivilege({
    Name = "Parallax - Toolgun",
    MinAccess = "admin"
})

CAMI.RegisterPrivilege({
    Name = "Parallax - Physgun",
    MinAccess = "admin"
})

CAMI.RegisterPrivilege({
    Name = "Parallax - Physgun Players",
    MinAccess = "admin"
})

CAMI.RegisterPrivilege({
    Name = "Parallax - Manage Flags",
    MinAccess = "admin"
})

CAMI.RegisterPrivilege({
    Name = "Parallax - Manage Config",
    MinAccess = "superadmin",
})