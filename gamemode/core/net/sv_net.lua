--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--[[-----------------------------------------------------------------------------
    Character Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("character.load", function(client, characterID)
    ax.character:Load(client, characterID)
end)

ax.net:Hook("character.delete", function(client, characterID)
    local character = ax.character:Get(characterID)
    if ( !character ) then return end

    local bResult = hook.Run("PrePlayerDeletedCharacter", client, characterID)
    if ( bResult == false ) then return end

    ax.character:Delete(characterID)

    hook.Run("PostPlayerDeletedCharacter", client, characterID)
end)

ax.net:Hook("character.create", function(client, payload)
    if ( !istable(payload) ) then
        ax.net:Start(client, "character.create.failed", "Invalid payload!")
        return
    end

    local canCreate, reason = hook.Run("PrePlayerCreatedCharacter", client, payload)
    if ( canCreate == false ) then
        ax.net:Start(client, "character.create.failed", reason or "Failed to create character!")
        return
    end

    for k, v in pairs(ax.character.variables) do
        if ( v.Editable != true ) then continue end

        -- This is a bit of a hack, but it works for now.
        if ( v.Type == ax.types.string or v.Type == ax.types.text ) then
            payload[k] = string.Trim(payload[k] or "")
        end

        if ( isfunction(v.OnValidate) ) then
            local validate, reasonString = v:OnValidate(nil, payload, client)
            if ( !validate ) then
                ax.net:Start(client, "character.create.failed", reasonString or "Failed to validate character!")
                return
            end
        end
    end

    ax.character:Create(client, payload, function(success, result)
        if ( !success ) then
            ax.util:PrintError("Failed to create character: " .. result)
            ax.net:Start(client, "character.create.failed", result or "Failed to create character!")
            return
        end

        ax.character:Load(client, result:GetID())

        ax.net:Start(client, "character.create")

        hook.Run("PostPlayerCreatedCharacter", client, result, payload)
    end)
end)

--[[-----------------------------------------------------------------------------
    Chat Networking
-----------------------------------------------------------------------------]]--

-- None

--[[-----------------------------------------------------------------------------
    Config Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("config.reset", function(client, key)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Config", nil) ) then return end

    local stored = ax.config.stored[key]
    if ( !istable(stored) ) then return end

    local bResult = hook.Run("PrePlayerConfigReset", client, key)
    if ( bResult == false ) then return end

    ax.config:Reset(key)

    hook.Run("PostPlayerConfigReset", client, key)
end)

ax.net:Hook("config.set", function(client, key, value)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Config", nil) ) then return end

    local stored = ax.config.stored[key]
    if ( !istable(stored) ) then return end

    if ( value == nil ) then return end

    local oldValue = ax.config:Get(key)

    local bResult = hook.Run("PrePlayerConfigChanged", client, key, value, oldValue)
    if ( bResult == false ) then return end

    ax.config:Set(key, value)

    hook.Run("PostPlayerConfigChanged", client, key, value, oldValue)
end)

--[[-----------------------------------------------------------------------------
    Option Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("option.set", function(client, key, value)
    local bResult = hook.Run("PreOptionChanged", client, key, value)
    if ( bResult == false ) then return false end

    ax.option:Set(client, key, value, true)

    hook.Run("PostOptionChanged", client, key, value)
end)

ax.net:Hook("option.sync", function(client, data)
    if ( !IsValid(client) or !istable(data) ) then return end

    for k, v in pairs(ax.option.stored) do
        local stored = ax.option.stored[k]
        if ( !istable(stored) ) then
            ax.util:PrintError("Option \"" .. k .. "\" does not exist!")
            continue
        end

        if ( stored.NoNetworking ) then continue end

        if ( data[k] != nil ) then
            if ( ax.util:DetectType(data[k]) != stored.Type ) then
                ax.util:PrintError("Option \"" .. k .. "\" is not of type \"" .. stored.Type .. "\"!")
                continue
            end

            local cliIndex = client:EntIndex()
            if ( !istable(ax.option.clients[cliIndex]) ) then
                ax.option.clients[cliIndex] = {}
            end

            ax.option.clients[cliIndex][k] = data[k]
        end
    end
end)

--[[-----------------------------------------------------------------------------
    Inventory Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("inventory.cache", function(client, inventoryID)
    if ( !inventoryID ) then return end

    ax.inventory:Cache(client, inventoryID)
end)

--[[-----------------------------------------------------------------------------
    Item Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("item.entity", function(client, itemID, entity)
    if ( !IsValid(entity) ) then return end

    local item = ax.item:Get(itemID)
    if ( !item ) then return end

    item:SetEntity(entity)
end)

ax.net:Hook("item.perform", function(client, itemID, actionName)
    if ( !itemID or !actionName ) then return end

    local item = ax.item:Get(itemID)
    if ( !item or item:GetOwner() != client:GetCharacterID() ) then return end

    ax.item:PerformAction(itemID, actionName)
end)

ax.net:Hook("item.spawn", function(client, uniqueID)
    if ( !isstring(uniqueID) or !istable(ax.item.stored[uniqueID]) ) then return end

    local pos = client:GetEyeTrace().HitPos + vector_up

    ax.item:Spawn(nil, uniqueID, pos, nil, function(entity)
        if ( IsValid(entity) ) then
            client:Notify("Spawned item: " .. uniqueID)
        else
            client:Notify("Failed to spawn item.")
        end
    end)
end)

--[[-----------------------------------------------------------------------------
    Currency Networking
-----------------------------------------------------------------------------]]--

-- None

--[[-----------------------------------------------------------------------------
    Miscellaneous Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("client.voice.start", function(client, speaker)
    hook.Run("PlayerStartVoice", speaker)
end)

ax.net:Hook("client.voice.end", function(client, prevSpeaker)
    hook.Run("PlayerEndVoice", prevSpeaker)
end)

ax.net:Hook("client.chatbox.text.changed", function(client, text)
    if ( !IsValid(client) or !text ) then return end

    hook.Run("PlayerChatTextChanged", client, text)
end, true)

ax.net:Hook("client.chatbox.type.changed", function(client, newType, oldType)
    if ( !IsValid(client) or !newType or !oldType ) then return end

    hook.Run("PlayerChatTypeChanged", client, newType, oldType)
end, true)

ax.net:Hook("command.run", function(client, command, arguments)
    ax.command:Run(client, command, arguments)
end)