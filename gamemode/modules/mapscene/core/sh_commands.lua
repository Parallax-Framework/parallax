--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Map scene commands.
-- @module ax.mapscene

local function BuildSceneFromClient(client, name, weight, tagString)
    local tags = ax.mapscene:ParseTags(tagString or "")
    local cleanedTags = ax.mapscene:NormalizeTags(tags)

    return {
        name = ax.mapscene:NormalizeName(name),
        origin = client:EyePos(),
        angles = client:EyeAngles(),
        weight = weight,
        tags = cleanedTags
    }
end

ax.command:Add("MapSceneAdd", {
    description = "Add a map scene at your eye position.",
    adminOnly = true,
    arguments = {
        { name = "name", type = ax.type.string, optional = true },
        { name = "pair", type = ax.type.bool, optional = true },
        { name = "weight", type = ax.type.number, optional = true },
        { name = "tags", type = ax.type.text, optional = true },
    },
    OnRun = function(def, client, name, bPair, weight, tags)
        if ( !IsValid(client) ) then return "Client required" end

        local scene = BuildSceneFromClient(client, name, weight, tags)
        local ok, err = ax.mapscene:HandlePairCapture(client, scene, tobool(bPair))

        if ( !ok ) then
            return err or "Failed to add map scene"
        end

        return err or "Map scene added"
    end
})

ax.command:Add("MapSceneRemove", {
    description = "Remove map scenes near your position.",
    adminOnly = true,
    arguments = {
        { name = "radius", type = ax.type.number, optional = true },
    },
    OnRun = function(def, client, radius)
        if ( !IsValid(client) ) then return "Client required" end

        local removed = ax.mapscene:RemoveScenesNear(client:GetPos(), radius or 280)
        return "Removed " .. tostring(removed) .. " map scenes."
    end
})

ax.command:Add("MapScenePreview", {
    description = "Preview a specific scene by index or name (use \"off\" to clear).",
    adminOnly = true,
    arguments = {
        { name = "identifier", type = ax.type.string, optional = true },
    },
    OnRun = function(def, client, identifier)
        if ( !IsValid(client) ) then return "Client required" end

        if ( isstring(identifier) ) then
            identifier = utf8.lower(string.Trim(identifier))
        end

        if ( !identifier or identifier == "" or identifier == "off" ) then
            ax.mapscene:SendPreview(client, nil)
            return "Map scene preview cleared."
        end

        local id = tonumber(identifier) or identifier
        local scene = ax.mapscene:ResolveScene(id)
        if ( !scene ) then
            return "Scene not found."
        end

        ax.mapscene:SendPreview(client, id)
        return "Map scene preview set."
    end
})

ax.command:Add("MapSceneExport", {
    description = "Export map scenes as JSON.",
    adminOnly = true,
    OnRun = function(def, client)
        local json = ax.mapscene:ExportToJSON()
        if ( !json ) then
            return "Failed to export map scenes."
        end

        if ( IsValid(client) ) then
            ax.net:Start(client, "mapscene.export", json)
            return "Exported map scenes to your console."
        end

        print(json)
        return "Exported map scenes to server console."
    end
})

ax.command:Add("MapSceneImport", {
    description = "Import map scenes from JSON (replaces existing scenes).",
    adminOnly = true,
    arguments = {
        { name = "json", type = ax.type.text },
    },
    OnRun = function(def, client, json)
        local ok, err = ax.mapscene:ImportFromJSON(json)
        if ( !ok ) then
            return err or "Failed to import map scenes."
        end

        return "Map scenes imported."
    end
})
