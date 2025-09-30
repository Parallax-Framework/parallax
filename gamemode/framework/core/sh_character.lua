--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.character:RegisterVar("steamID64", {
    field = "steamid64",
    fieldType = ax.type.steamid64,
    default = ""
})

ax.character:RegisterVar("schema", {
    field = "schema",
    fieldType = ax.type.string,
    default = "parallax"
})

ax.character:RegisterVar("inventory", {
    field = "inventory",
    fieldType = ax.type.number,
    default = 0,
    bNoGetter = true
})

ax.character:RegisterVar("faction", {
    field = "faction",
    fieldType = ax.type.number,
    default = 0,
    hide = true,
    validate = function(this, value)
        if ( !isnumber(value) or value <= 0 ) then
            return false, "Invalid faction ID"
        end

        if ( ax.faction:Get(value) == nil ) then
            return false, "Faction does not exist"
        end

        return true
    end,
    changed = function(character, value, isNetworked, recipients)
        local client = character:GetOwner()
        if ( IsValid(client) ) then
            client:SetTeam(value)
        end
    end
})

ax.character:RegisterVar("class", {
    field = "class",
    fieldType = ax.type.number,
    default = 0,
    hide = true,
    validate = function(this, value)
        if ( !isnumber(value) or value < 0 ) then
            return false, "Invalid class ID"
        end

        if ( ax.class:Get(value) == nil ) then
            return false, "Class does not exist"
        end

        return true
    end
})

ax.character:RegisterVar("name", {
    field = "name",
    fieldType = ax.type.string,
    default = "Unnamed Character",
    validate = function(this, value)
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
    default = "This is a character description.",
    validate = function(this, value)
        if ( !isstring(value) or value == "" ) then
            return false, "Description cannot be empty"
        end

        if ( string.len(value) > 256 ) then
            return false, "Description cannot exceed 256 characters"
        end

        return true
    end,
    populatePost = function(this, container, payload, option, entry)
        entry:SetTall(entry:GetTall() * 2)
        entry:SetMultiline(true)
    end
})

ax.character:RegisterVar("model", {
    field = "model",
    fieldType = ax.type.string,
    default = "models/player.mdl",
    validate = function(this, value)
        if ( !isstring(value) or value == "" ) then
            return false, "Model cannot be empty"
        end

        if ( !util.IsValidModel(value) ) then
            return false, "Invalid model"
        end

        return true
    end,
    populate = function(this, container, payload)
        local option = container:Add("ax.text")
        option:SetFont("ax.regular.bold")
        option:SetText(string.upper(ax.util:UniqueIDToName(this.key)))
        option:Dock(TOP)
        option:SetZPos(1)

        local layout = container:Add("DIconLayout")
        layout:Dock(TOP)
        layout:SetZPos(2)
        layout:SetStretchHeight(true)

        local factionID = payload.faction
        if ( !factionID or ax.faction:Get(factionID) == nil ) then
            ax.util:PrintError("Invalid faction ID provided to ax.character:RegisterVar()")
            return
        end

        local size = math.min(container:GetWide() / 8, 128)
        for k, v in pairs(ax.faction:Get(factionID):GetModels()) do
            if ( istable( v ) ) then v = v[ 1 ] end

            local modelButton = layout:Add("SpawnIcon")
            modelButton:SetModel(v)
            modelButton:SetSize(size, size)
            modelButton:SetTooltip(v)

            modelButton.DoClick = function()
                payload.model = v
            end

            modelButton.PaintOver = function(this, width, height)
                if ( payload.model == v ) then
                    surface.SetDrawColor(0, 150, 255, 100)
                    surface.DrawRect(0, 0, width, height)
                end
            end
        end

        layout:SizeToChildren(layout:GetStretchWidth(), layout:GetStretchHeight())
    end,
    changed = function(character, value, isNetworked, recipients)
        local client = character:GetOwner()
        if ( IsValid(client) and client:GetModel() != value ) then
            client:SetModel(value)
        end
    end
})

ax.character:RegisterVar("creationTime", {
    field = "creation_time",
    fieldType = ax.type.number,
    default = 0,
})

ax.character:RegisterVar("lastPlayed", {
    field = "last_played",
    fieldType = ax.type.number,
    default = 0,
})

ax.character:RegisterVar("data", {
    field = "data",
    fieldType = ax.type.text,
    default = "[]",
    bNoGetter = true,
    bNoSetter = true
})
