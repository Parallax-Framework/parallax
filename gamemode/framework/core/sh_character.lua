--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.character:RegisterVar("name", {
    field = "name",
    fieldType = ax.type.string,
    Default = "",
    Validate = function(self, character, value)
        if ( !isstring(value) or value == "" ) then
            return false, "Name cannot be empty"
        end

        if ( string.len(value) > 32 ) then
            return false, "Name cannot exceed 32 characters"
        end

        return true
    end
})

ax.character:RegisterVar("description", {
    field = "description",
    fieldType = ax.type.string,
    Default = "",
    Validate = function(self, character, value)
        if ( !isstring(value) or value == "" ) then
            return false, "Description cannot be empty"
        end

        if ( string.len(value) > 256 ) then
            return false, "Description cannot exceed 256 characters"
        end

        return true
    end
})

ax.character:RegisterVar("faction", {
    field = "faction",
    fieldType = ax.type.number,
    Default = 0,
    Validate = function(self, character, value)
        if ( !isnumber(value) or value <= 0 ) then
            return false, "Faction cannot be empty"
        end

        return true
    end
})

ax.character:RegisterVar("creationTime", {
    field = "creationTime",
    fieldType = ax.type.number,
    Default = 0,
})

ax.character:RegisterVar("invID", {
    field = "inv_id",
    fieldType = ax.type.number,
    Default = 0,
    Validate = function(self, character, value)
        if ( !isnumber(value) or value <= 0 ) then
            return false, "Inventory ID must be a positive number"
        end

        return true
    end,
})

ax.character:RegisterVar("vars", {
    field = "vars",
    fieldType = ax.type.string,
    Default = "[]",
})