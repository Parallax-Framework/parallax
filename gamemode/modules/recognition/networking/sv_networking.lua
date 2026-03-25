--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Server-side net receivers for the recognition module.
-- @module ax.recognition (net, server)

--- Client requests an introduction: they send the entity index of the target and a chosen alias.
-- The server validates proximity using the IC hear distance, then delegates to Introduce().
ax.net:Hook("recognition.introduce_request", function(client, targetIndex, alias)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    if ( !isnumber(targetIndex) or !isstring(alias) ) then
        ax.util:PrintWarning("[Recognition] Malformed introduce_request from " .. client:SteamName())
        return
    end

    local target = Entity(targetIndex)
    if ( !IsValid(target) or !ax.util:IsValidPlayer(target) ) then
        client:Notify(ax.localization:GetPhrase("recognition.notify.invalid_target"), "error")
        return
    end

    if ( target == client ) then
        client:Notify(ax.localization:GetPhrase("recognition.notify.self_introduce"), "error")
        return
    end

    -- Validate proximity: must be within IC chat hear distance.
    local icChat = ax.chat.registry["ic"]
    if ( istable(icChat) and !icChat:CanHear(client, target) ) then
        client:Notify(ax.localization:GetPhrase("recognition.notify.too_far"), "error")
        return
    end

    ax.recognition:Introduce(client, target, alias)
end)

--- Client requests to forget (remove) their familiarity record for a character.
-- The targetID is validated to belong to the client's own familiarity data.
ax.net:Hook("recognition.forget_request", function(client, targetID)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    local char = client:GetCharacter()
    if ( !char ) then return end

    local strKey = tostring(tonumber(targetID) or "")
    if ( strKey == "" ) then
        ax.util:PrintWarning("[Recognition] Malformed forget_request from " .. client:SteamName())
        return
    end

    local familiarity = ax.character:GetVar(char, "familiarity")
    if ( !istable(familiarity) ) then return end

    ax.recognition:NormalizeFamiliarity(familiarity)

    -- Remove both key forms to handle pre-migration data.
    local numKey = tonumber(strKey)
    if ( !familiarity[strKey] and !familiarity[numKey] ) then return end

    familiarity[strKey] = nil
    familiarity[numKey] = nil

    -- Persist the removal and notify the client to refresh.
    local query = mysql:Update("ax_characters")
        query:Where("id", char:GetID())
        query:Update("familiarity", util.TableToJSON(familiarity))
        query:Callback(function(result)
            if ( result == false ) then
                ax.util:PrintError("[Recognition] Failed to persist forget for char " .. char:GetID())
            end
        end)
    query:Execute()

    ax.net:Start(client, "recognition.forget_confirm", strKey)

    ax.util:PrintDebug("[Recognition] " .. client:Nick() .. " forgot char " .. strKey)
end)

--- Admin client requests a direct familiarity override.
-- Validated against the CAMI "Parallax - Recognition" privilege server-side.
ax.net:Hook("recognition.admin_set", function(client, charID, targetID, score)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    if ( !isnumber(charID) or !isnumber(targetID) or !isnumber(score) ) then
        ax.util:PrintWarning("[Recognition] Malformed admin_set from " .. client:SteamName())
        return
    end

    ax.recognition:AdminSetFamiliarity(client, charID, targetID, score)
end)
