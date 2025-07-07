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

util.AddNetworkString("ax.character.load")
net.Receive("ax.character.load", function(len, client)
    local characterID = net.ReadUInt(16)
    ax.character:Load(client, characterID)
end)

util.AddNetworkString("ax.character.delete")
net.Receive("ax.character.delete", function(len, client)
    local characterID = net.ReadUInt(16)
    local character = ax.character:Get(characterID)
    if ( !character ) then return end

    local bResult = hook.Run("PrePlayerDeletedCharacter", client, characterID)
    if ( bResult == false ) then return end

    ax.character:Delete(characterID)

    hook.Run("PostPlayerDeletedCharacter", client, characterID)
end)

util.AddNetworkString("ax.character.create")
net.Receive("ax.character.create", function(len, client)
    local payload = net.ReadTable()
    if ( !istable(payload) ) then
        net.Start("ax.character.create.failed")
            net.WriteString("Invalid payload!")
        net.Send(client)

        return
    end

    local canCreate, reason = hook.Run("PrePlayerCreatedCharacter", client, payload)
    if ( canCreate == false ) then
        net.Start("ax.character.create.failed")
            net.WriteString(reason or "Failed to create character!")
        net.Send(client)

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
                net.Start("ax.character.create.failed")
                    net.WriteString(reasonString or "Failed to validate character!")
                net.Send(client)
                return
            end
        end
    end

    ax.character:Create(client, payload, function(success, result)
        if ( !success ) then
            ax.util:PrintError("Failed to create character: " .. result)
            net.Start("ax.character.create.failed")
                net.WriteString(result or "Failed to create character!")
            net.Send(client)

            return
        end

        ax.character:Load(client, result:GetID())

        net.Start("ax.character.create")
        net.Send(client)

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

util.AddNetworkString("ax.config.reset")
net.Receive("ax.config.reset", function(len, client)
    local key = net.ReadString()
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Config", nil) ) then return end

    local stored = ax.config.stored[key]
    if ( !istable(stored) ) then return end

    local bResult = hook.Run("PrePlayerConfigReset", client, key)
    if ( bResult == false ) then return end

    ax.config:Reset(key)

    hook.Run("PostPlayerConfigReset", client, key)
end)

util.AddNetworkString("ax.config.set")
net.Receive("ax.config.set", function(len, client)
    local key = net.ReadString()
    local value = net.ReadType()
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

util.AddNetworkString("ax.option.set")
net.Receive("ax.option.set", function(len, client)
    local key = net.ReadString()
    local value = net.ReadType()
    local bResult = hook.Run("PreOptionChanged", client, key, value)
    if ( bResult == false ) then return false end

    ax.option:Set(client, key, value, true)

    hook.Run("PostOptionChanged", client, key, value)
end)

util.AddNetworkString("ax.option.sync")
net.Receive("ax.option.sync", function(len, client)
    local data = net.ReadTable()
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

util.AddNetworkString("ax.inventory.cache")
net.Receive("ax.inventory.cache", function(len, client)
    local inventoryID = net.ReadUInt(16)
    if ( !inventoryID ) then return end

    ax.inventory:Cache(client, inventoryID)
end)

--[[-----------------------------------------------------------------------------
    Item Networking
-----------------------------------------------------------------------------]]--

util.AddNetworkString("ax.item.perform")
net.Receive("ax.item.perform", function(len, client)
    local itemID = net.ReadUInt(16)
    local actionName = net.ReadString()
    if ( !itemID or !actionName ) then return end

    local item = ax.item:Get(itemID)
    if ( !item or item:GetOwner() != client:GetCharacterID() ) then return end

    ax.item:PerformAction(itemID, actionName)
end)

util.AddNetworkString("ax.item.spawn")
net.Receive("ax.item.spawn", function(len, client)
    local uniqueID = net.ReadString()
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

util.AddNetworkString("ax.caption")
util.AddNetworkString("ax.character.cache")
util.AddNetworkString("ax.character.cache.all")
util.AddNetworkString("ax.character.create")
util.AddNetworkString("ax.character.create.failed")
util.AddNetworkString("ax.character.delete")
util.AddNetworkString("ax.character.load")
util.AddNetworkString("ax.character.load.failed")
util.AddNetworkString("ax.character.variable.set")
util.AddNetworkString("ax.chat.send")
util.AddNetworkString("ax.chat.text")
util.AddNetworkString("ax.config.set")
util.AddNetworkString("ax.config.sync")
util.AddNetworkString("ax.currency.give")
util.AddNetworkString("ax.database.save")
util.AddNetworkString("ax.flag.list")
util.AddNetworkString("ax.gesture.play")
util.AddNetworkString("ax.inventory.cache")
util.AddNetworkString("ax.inventory.item.add")
util.AddNetworkString("ax.inventory.item.remove")
util.AddNetworkString("ax.inventory.refresh")
util.AddNetworkString("ax.inventory.register")
util.AddNetworkString("ax.item.add")
util.AddNetworkString("ax.item.cache")
util.AddNetworkString("ax.item.data")
util.AddNetworkString("ax.item.entity")
util.AddNetworkString("ax.mainmenu")
util.AddNetworkString("ax.notification.send")
util.AddNetworkString("ax.option.set")
util.AddNetworkString("ax.splash")

util.AddNetworkString("ax.client.voice.start")
net.Receive("ax.client.voice.start", function(len, client)
    local speaker = net.ReadPlayer()
    hook.Run("PlayerStartVoice", speaker)
end)

util.AddNetworkString("ax.client.voice.end")
net.Receive("ax.client.voice.end", function(len, client)
    local prevSpeaker = net.ReadPlayer()
    hook.Run("PlayerEndVoice", prevSpeaker)
end)

util.AddNetworkString("ax.client.chatbox.text.changed")
net.Receive("ax.client.chatbox.text.changed", function(len, client)
    local text = net.ReadString()
    if ( !IsValid(client) or !isstring(text) ) then return end

    hook.Run("PlayerChatTextChanged", client, text)
end)

util.AddNetworkString("ax.client.chatbox.type.changed")
net.Receive("ax.client.chatbox.type.changed", function(len, client)
    local newType = net.ReadString()
    local oldType = net.ReadString()
    if ( !IsValid(client) or !isstring(newType) or !isstring(oldType) ) then return end

    hook.Run("PlayerChatTypeChanged", client, newType, oldType)
end)

util.AddNetworkString("ax.command.run")
net.Receive("ax.command.run", function(len, client)
    local command = net.ReadString()
    local arguments = net.ReadTable()
    ax.command:Run(client, command, arguments)
end)
