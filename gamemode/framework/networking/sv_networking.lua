--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.net:Hook("player.actionbar.stop", function(client, bCancelled)
    local clientTable = client:GetTable()
    if ( !istable(clientTable.axActionBar) ) then return end

    ax.net:Start(client, "player.actionbar.stop", bCancelled)

    if ( bCancelled and isfunction(clientTable.axActionBar.onCancel) ) then
        clientTable.axActionBar.onCancel()
        clientTable.axActionBar.onCancel = nil
    elseif ( !bCancelled and isfunction(clientTable.axActionBar.onComplete) ) then
        clientTable.axActionBar.onComplete()
        clientTable.axActionBar.onComplete = nil
    end

    timer.Remove("ax.player." .. client:SteamID64() .. ".entityAction")
    clientTable.axActionBar = nil
end)

ax.net:Hook("voice.start", function(client, speaker)
    if ( !IsValid(speaker) ) then return end
    if ( !speaker:RateLimit("voice.start", 0.3) ) then return end

    hook.Run("PlayerStartVoice", speaker)
end)

ax.net:Hook("voice.end", function(client, speaker)
    if ( !IsValid(speaker) ) then return end
    if ( !speaker:RateLimit("voice.start", 0.3) ) then return end

    hook.Run("PlayerEndVoice", speaker)
end)

ax.net:Hook("chat.message", function(client, output)
    if ( !client:RateLimit("chat.send", 0.5) ) then return end

    hook.Run("PlayerSay", client, output)

    client:SetRelay("chatText", "")
    client:SetRelay("chatType", "")
end)


ax.net:Hook("chat.text.changed", function(client, text, chatType)
    if ( !client:RateLimit("chat.text.changed", 0.01) ) then return end

    text = string.gsub(text, "[^%w%s%p]", "")
    text = string.Trim(text)
    text = string.gsub(text, "<.->", "")

    client:SetRelay("chatText", text)
    client:SetRelay("chatType", chatType)

    hook.Run("ChatboxOnTextChanged", text, chatType)
end)


ax.net:Hook("item.transfer", function(client, itemID, targetInventoryID)
    local character = client:GetCharacter()
    if ( !character ) then return end

    if ( !client:RateLimit("item.transfer", 0.1) ) then return end

    if ( !isnumber(itemID) or itemID < 1 ) then
        ax.util:Error("Invalid payload received for item transfer.")
        return
    end

    local item = ax.item.instances[itemID]
    if ( !istable(item) ) then
        ax.util:PrintError("Item with ID " .. itemID .. " does not exist.")
        return
    end

    local itemInventory = ax.inventory.instances[item:GetInventoryID()]
    if ( !istable(itemInventory) or !itemInventory:IsReceiver( client ) ) then
        ax.util:PrintError("Player " .. client:SteamID() .. " attempted to transfer item ID " .. itemID .. " which they do not possess.")
        return
    end

    if ( !isnumber(targetInventoryID) or targetInventoryID < 1 ) then
        ax.util:Error("Invalid payload received for item transfer.")
        return
    end

    local targetInventory = ax.inventory.instances[targetInventoryID]
    if ( !istable(targetInventory) ) then
        ax.util:PrintError("Target inventory with ID " .. targetInventoryID .. " does not exist.")
        return
    end

    ax.item:Transfer(item, client:GetCharacter():GetInventory():GetID(), targetInventoryID, function() print("Item transferred") end)
end)

ax.net:Hook("inventory.item.action", function(client, itemID, action)
    if ( !client:RateLimit("inventory.action", 0.1) ) then return end

    if ( !isnumber(itemID) or itemID < 1 or !isstring(action) or #action < 1 ) then
        ax.util:Error("Invalid payload received for item action.")
        return
    end

    local item = ax.item.instances[itemID]
    if ( !istable(item) ) then
        local validIDs = {}
        for id in pairs(ax.item.instances) do
            table.insert(validIDs, id)
        end

        table.sort(validIDs)

        ax.util:PrintError(string.format(
            "Item with ID %d does not exist. Player: %s (%s), Action: '%s', Valid IDs: [%s], Total items: %d",
            itemID,
            client:Nick(),
            client:SteamID(),
            action,
            table.concat(validIDs, ", "),
            table.Count(ax.item.instances)
        ))

        return
    end

    local actionTable = item.actions[action]
    if ( !istable( item.actions[action] ) ) then
        ax.util:PrintError("Item with ID " .. itemID .. " does not have action '" .. action .. "'.")
        return
    end

    if ( !item:CanInteract(client, action) ) then return end

    local bRemoveAfter = actionTable:OnRun(item, client)
    if ( bRemoveAfter == true ) then
        local inventory = ax.inventory.instances[item.invID]
        if ( istable(inventory) ) then
            inventory:RemoveItem(item.id)
        else
            ax.util:PrintError("Failed to remove item ID " .. item.id .. " after action '" .. action .. "' because its inventory does not exist.")
        end
    end

    local soundVar = "sound_" .. utf8.lower(action)
    if ( actionTable[soundVar] ) then
        client:EmitSound(Sound(actionTable[soundVar]))
    end

    hook.Run("OnPlayerItemAction", client, item, action)
end)

ax.net:Hook("character.create", function(client, payload)
    if ( !istable(payload) ) then
        ax.util:Error("Invalid payload received for character creation.")
        return
    end

    local try, catch = hook.Run("CanCreateCharacter", client, payload)
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 ) then
            client:Notify(catch, "error")
            ax.util:Error("Character creation failed for " .. client:SteamID64() .. ": " .. catch)
        end

        return
    end

    local vars = {}
    for k, v in pairs(ax.character.vars) do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end

        -- Only include variables that can be populated during character creation
        local canPop = ax.character:CanPopulateVar(k, payload, client)
        if ( canPop ) then
            vars[k] = payload[k] != nil and payload[k] or NULL
        end
    end

    local newPayload = {}
    for k, v in pairs(vars) do
        local var = ax.character.vars[k]
        if ( !var ) then
            ax.util:PrintError("Invalid character variable '" .. k .. "' provided in payload.")
            return
        end

        -- Check if this variable can be populated during character creation (server-side validation)
        local canPop, reason = ax.character:CanPopulateVar(k, payload, client)
        if ( !canPop ) then
            ax.util:PrintError(("Client '%s' attempted to send data for restricted character variable '%s': %s"):format(client:SteamID64(), tostring(k), reason or "Unknown reason"))
            client:Notify(reason or "Invalid character data submitted.")
            return
        end

        if ( var.validate ) then
            local result, err = var:validate(v, payload, client)
            if ( !result ) then
                client:Notify(err or "Invalid character data submitted.")
                ax.util:PrintWarning(("Validation failed for character variable '%s' from client '%s': %s"):format(tostring(k), client:SteamID64(), tostring(err)))
                return
            end

            newPayload[k] = v
        else
            ax.util:PrintWarning(("Character variable '%s' does not have a validation function. Accepting raw data from client '%s'."):format(tostring(k), client:SteamID64()))
            newPayload[k] = v
        end
    end

    newPayload.steamID64 = client:SteamID64()
    newPayload.schema = engine.ActiveGamemode()

    ax.util:PrintDebug("Creating character for " .. client:SteamID64() .. " with payload: " .. util.TableToJSON(newPayload))

    ax.character:Create(newPayload, function(character, inventory)
        inventory:AddReceiver( client )

        if ( !client:GetCharacter() ) then
            client:SetNoDraw(false)
            client:SetNotSolid(false)
            client:SetMoveType(MOVETYPE_WALK)
        end

        local clientData = client:GetTable()

        clientData.axCharacters = clientData.axCharacters or {}
        clientData.axCharacters[#clientData.axCharacters + 1] = character

        ax.inventory.instances[inventory.id] = inventory
        ax.character.instances[character.id] = character

        ax.inventory:Sync(inventory)
        ax.character:Sync(client, character)

        ax.net:Start(client, "character.create", character.id, clientData.axCharacters)

        ax.util:PrintSuccess("Character created for " .. client:SteamID64() .. ": " .. character:GetName())

        client:Notify("You have successfully created a new character!", "success")

        local faction = ax.faction:Get( character:GetFaction() )
        if ( istable( faction ) and isfunction( faction.OnCharacterCreated ) ) then
            faction:OnCharacterCreated( client, character )
        end

        hook.Run("PlayerCreatedCharacter", client, character)
    end)
end)

ax.net:Hook("character.load", function(client, charID)
    if ( !isnumber(charID) or charID < 1 ) then
        ax.util:Error("Invalid character ID received for loading.")
        return
    end

    local character = ax.character.instances[charID]
    if ( !character ) then
        ax.util:PrintError("Character with ID " .. charID .. " does not exist.")
        return
    end

    if ( character:GetSteamID64() != client:SteamID64() ) then
        ax.util:PrintError("Character ID " .. charID .. " does not belong to " .. client:SteamID64())
        return
    end

    local prevChar = client:GetCharacter()
    if ( prevChar ) then
        if ( prevChar.id == charID ) then
            ax.util:PrintDebug("Character " .. charID .. " is already loaded for " .. client:SteamID64())
            return
        end

        if ( ax.inventory.instances[1] != nil ) then
            for i = 1, #ax.inventory.instances do
                local inventory = ax.inventory.instances[ i ]
                if ( istable(inventory) and inventory:IsReceiver( client ) ) then
                    inventory:RemoveReceiver( client )
                end
            end
        end

        prevChar.player = nil
        ax.character:Sync(client, prevChar)
        hook.Run("PlayerUnloadedCharacter", client, prevChar)
    end

    local try, catch = hook.Run("CanPlayerLoadCharacter", client, character)
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 ) then
            client:Notify(catch, "error")
        end

        return
    end

    ax.character:Load(client, character)
end)

ax.net:Hook("character.delete", function(client, id)
    if ( !isnumber(id) or id < 1 ) then return end

    local character = ax.character.instances[id]
    if ( !istable(character) ) then
        ax.util:PrintError("Character with ID " .. id .. " does not exist.")
        return
    end

    if ( character:GetSteamID64() != client:SteamID64() ) then
        ax.util:PrintError("Character ID " .. id .. " does not belong to " .. client:SteamID64())
        return
    end

    local try, catch = hook.Run("CanPlayerDeleteCharacter", client, character)
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 ) then
            client:Notify(catch, "error")
        end

        return
    end

    ax.character:Delete(id, function(bSuccess)
        if ( bSuccess ) then
            local clientData = client:GetTable()
            local clientCharacters = clientData.axCharacters or {}
            if ( istable(clientData.axCharacters) ) then
                for i = #clientCharacters, 1, -1 do
                    if ( clientCharacters[i].id == id ) then
                        table.remove(clientCharacters, i)
                        break
                    end
                end
            end

            if ( clientData.axCharacter and clientData.axCharacter.id == id ) then
                clientData.axCharacter = nil
                client:SetNoDraw(true)
                client:SetNotSolid(true)
                client:SetMoveType(MOVETYPE_NONE)
                client:KillSilent()

                client:SendLua([[vgui.Create("ax.main")]])
            end

            ax.net:Start(client, "character.delete", id)

            hook.Run("PlayerDeletedCharacter", client, id)

            ax.character.instances[id] = nil
        end
    end)
end)

ax.net:Hook("spawnmenu.spawn.item", function(client, itemClass)
    -- TODO: Use CAMI to handle permissions
    if ( !IsValid(client) or !client:IsSuperAdmin() ) then
        ax.util:PrintWarning(string.format("Player %s attempted to spawn an item without permission", tostring(client)))
        return
    end

    if ( !ax.item.stored[itemClass] ) then
        client:Notify("Invalid item class: " .. tostring(itemClass))
        ax.util:PrintWarning(string.format("Player %s attempted to spawn invalid item class: %s", tostring(client), tostring(itemClass)))
        return
    end

    local item = ax.item.stored[itemClass]
    if ( rawget(item, "isBase") == true ) then -- Use rawget to check only the item's own isBase property, not inherited from base
        client:Notify("Cannot spawn base items")
        return
    end

    local trace = client:GetEyeTrace()
    local pos = trace.HitPos + trace.HitNormal * 16
    local ang = trace.HitNormal:Angle()

    ax.item:Spawn(itemClass, pos, ang, function(entity, itemInstance)
        if ( IsValid(entity) and istable(itemInstance) ) then
            ax.util:PrintSuccess(string.format(
                "Player %s spawned item %s (class: %s) at %s",
                tostring(client),
                tostring(itemInstance.name or itemClass),
                tostring(itemClass),
                tostring(pos)
            ))

            -- Notify the player
            -- client:Notify(string.format("Spawned %s", itemInstance.name or itemClass)) -- Commented out to reduce spam
        else
            ax.util:PrintError(string.format(
                "Failed to spawn item %s for player %s",
                tostring(itemClass),
                tostring(client)
            ))

            client:Notify("Failed to spawn item")
        end
    end, {})
end)

ax.net:Hook("command.run", function(caller, name, rawArgs)
    if ( !IsValid(caller) ) then return end

    local ok, result = ax.command:Run(caller, name, rawArgs)
    if ( !ok ) then
        caller:Notify(result or "Unknown error")
    elseif ( result and result != "" ) then
        caller:Notify(tostring(result))
    end
end)
