--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Queue for character variable updates that arrive before character sync
local characterVarQueue = {}

ax.net:Hook("player.ready", function()
    local clientTable = LocalPlayer():GetTable()
    if ( clientTable.axReady ) then return end

    clientTable.axReady = true

    vgui.Create("ax.main")

    -- Run any queued EnsurePlayer callbacks
    local client = LocalPlayer()
    local t = client:GetTable()
    if ( istable(t.axEnsureCallbacks) ) then
        for i = 1, #t.axEnsureCallbacks do
            local cb = t.axEnsureCallbacks[i]
            if ( isfunction(cb) ) then
                pcall(cb, true)
            end
        end

        t.axEnsureCallbacks = nil
    end
end)

ax.net:Hook("character.create", function(characterID, characters)
    local client = ax.client
    if ( !IsValid(client) ) then
        ax.util:PrintError("Invalid client received for character creation.")
        return
    end

    local clientTable = client:GetTable()
    if ( !istable(clientTable) ) then
        ax.util:PrintError("Invalid client table for character creation.")
        return
    end

    if ( !isnumber(characterID) or characterID <= 0 ) then
        ax.util:PrintError("Invalid character ID received for creation.")
        return
    end

    -- Read the character list first before trying to access the character
    local clientData = ax.client:GetTable()
    clientData.axCharacters = {}

    for i = 1, #characters do
        local charData = characters[i]
        local character = setmetatable(charData, ax.character.meta)
        ax.character.instances[character.id] = character
        clientData.axCharacters[#clientData.axCharacters + 1] = character

        -- Process any queued variable updates for this character
        if ( characterVarQueue[character.id] ) then
            if ( !istable(character.vars) ) then
                character.vars = {}
            end

            for varName, varValue in pairs(characterVarQueue[character.id]) do
                character.vars[varName] = varValue
            end

            characterVarQueue[character.id] = nil
        end
    end

    -- Now we can safely get the character
    local character = ax.character:Get(characterID)
    if ( !istable(character) ) then
        ax.util:PrintError("Character with ID " .. characterID .. " not found.")
        return
    end

    local main = ax.gui.main
    if ( !clientTable.axCharacter ) then
        ax.net:Start("character.load", characterID)

        if ( IsValid(main) ) then
            main:Remove()
        end
    else
        if ( IsValid(main) ) then
            main.create:SlideDown(nil, function()
                main.create:ClearVars()
            end)
            main.splash:SlideToFront()
        end
    end

    hook.Run("PlayerCreatedCharacter", client, character)
end)

ax.net:Hook("character.load", function(characterID)
    local client = ax.client
    if ( !IsValid(client) ) then return end

    local character = ax.character:Get(characterID)
    if ( !istable(character) ) then
        ax.util:PrintError("Character with ID " .. characterID .. " not found.")
        return
    end

    local clientData = client:GetTable()
    clientData.axCharacterPrevious = clientData.axCharacter
    clientData.axCharacter = character

    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
    end

    client:ScreenFade(SCREENFADE.IN, color_black, 4, 1)

    hook.Run("PlayerLoadedCharacter", client, character, clientData.axCharacterPrevious)
end)

ax.net:Hook("character.sync", function(client, character)
    if ( !IsValid(client) ) then return end

    -- Assume we are trying to kick the player off of their character
    if ( character == nil or !istable(character) ) then
        client:GetTable().axCharacter = nil
        return
    end

    client:GetTable().axCharacter = character

    ax.character.instances[character.id] = setmetatable(character, ax.character.meta)

    -- Process any queued variable updates for this character
    if ( characterVarQueue[character.id] ) then
        if ( !istable(character.vars) ) then
            character.vars = {}
        end

        for varName, varValue in pairs(characterVarQueue[character.id]) do
            character.vars[varName] = varValue
        end

        characterVarQueue[character.id] = nil
    end
end)

ax.net:Hook("character.restore", function(characters)
    if ( !istable(characters) ) then
        ax.util:PrintError("Invalid characters table received from server")
        return
    end

    local clientData = ax.client:GetTable()
    clientData.axCharacters = {}

    for i = 1, #characters do
        local charData = characters[i]
        local character = setmetatable(charData, ax.character.meta)
        ax.character.instances[character.id] = character
        clientData.axCharacters[ #clientData.axCharacters + 1 ] = character

        -- Process any queued variable updates for this character
        if ( characterVarQueue[character.id] ) then
            if ( !istable(character.vars) ) then
                character.vars = {}
            end

            for varName, varValue in pairs(characterVarQueue[character.id]) do
                character.vars[varName] = varValue
            end

            characterVarQueue[character.id] = nil
        end
    end

    hook.Run("OnCharactersRestored", characters)
end)

ax.net:Hook("character.delete", function(id)
    if ( !isnumber( id ) or id < 1 ) then return end

    local character = ax.character.instances[ id ]
    if ( !istable( character ) ) then
        ax.util:PrintError( "Character with ID " .. id .. " does not exist." )
        return
    end

    local clientData = ax.client:GetTable()
    if ( clientData.axCharacter and clientData.axCharacter.id == id ) then
        clientData.axCharacter = nil
    end

    if ( istable( clientData.axCharacters ) ) then
        for i = 1, #clientData.axCharacters do
            if ( clientData.axCharacters[i].id == id ) then
                table.remove( clientData.axCharacters, i )
                break
            end
        end
    end

    local invID = character:GetInventoryID()
    local inventory = ax.inventory.instances[ invID ]
    if ( istable( inventory ) ) then
        for itemID in pairs( inventory.items ) do
            ax.item.instances[ itemID ] = nil
        end
    end

    ax.inventory.instances[ invID ] = nil

    hook.Run( "PlayerDeletedCharacter", id )

    ax.character.instances[ id ] = nil

    if ( IsValid( ax.gui.main ) and IsValid( ax.gui.main.load ) ) then
        ax.gui.main.load:PopulateCharacterList()
    end
end)

ax.net:Hook("character.var", function(characterID, name, value)
    local character = ax.character:Get(characterID)
    if ( !character ) then
        -- Queue the var update until the character is synced
        characterVarQueue[characterID] = characterVarQueue[characterID] or {}
        characterVarQueue[characterID][name] = value
        ax.util:PrintDebug("Queued character variable '" .. name .. "' update for character ID " .. characterID .. ": " .. tostring(value))
        return
    end

    if ( !istable(character.vars) ) then
        character.vars = {}
    end

    character.vars[name] = value

    hook.Run("CharacterVarChanged", character, name, value)
end)

ax.net:Hook("character.data", function(characterID, key, value)

    local character = ax.character:Get(characterID)
    if ( !character ) then return end -- TODO: make characterVarQueue for data? idk

    if ( !istable(character.vars) ) then
        character.vars = {}
    end

    if ( !istable(character.vars.data) ) then
        character.vars.data = {}
    end

    character.vars.data[key] = value

    hook.Run("CharacterDataChanged", character, key, value)
end)

ax.net:Hook("character.bot.sync", function(characterID, botCharacter)

    -- Restore metatable for bot character
    botCharacter = setmetatable(botCharacter, ax.character.meta)

    -- Add to character instances so clients can find it
    ax.character.instances[characterID] = botCharacter

    -- Update the bot player's character reference if they exist
    local botPlayer = botCharacter:GetOwner()
    if ( IsValid(botPlayer) and botPlayer:IsBot() ) then
        botPlayer:GetTable().axCharacter = botCharacter
    end
end)

ax.net:Hook("character.setnameprompt", function(targetID)
    local target = ax.character:Get(targetID)
    if ( !istable(target) ) then
        ax.util:PrintError("Character not found for name prompt.")
        return
    end

    Derma_StringRequest("Set Character Name", "Enter a new name for your character:", target:GetName() or "", function(text)
        text = string.Trim(text)
        if ( text == "" ) then return end

        ax.command:Send("/CharSetName \"" .. target:GetName() .. "\" \"" .. text .. "\"")
    end, nil, "Set Name")
end)

ax.net:Hook("player.var", function(client, key, value)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    if ( !istable(clientTable.axVars) ) then
        clientTable.axVars = {}
    end

    clientTable.axVars[key] = value
end)

ax.net:Hook("player.data", function(client, key, value)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    if ( !istable(clientTable.axVars) ) then
        clientTable.axVars = {}
    end

    if ( !istable(clientTable.axVars.data) ) then
        clientTable.axVars.data = {}
    end

    clientTable.axVars.data[key] = value
end)

ax.net:Hook("inventory.sync", function(inventoryID, inventoryItems, inventoryMaxWeight, inventoryReceivers)

    -- Convert the items into objects
    local items = {}
    for i = 1, #inventoryItems do
        local itemData = inventoryItems[i]
        if ( istable(itemData) and isnumber(itemData.id) ) then
            local itemObject = ax.item:Instance(itemData.id, itemData.class)
            itemObject.invID = inventoryID
            itemObject.data = itemData.data or {}

            ax.item.instances[itemObject.id] = itemObject
            items[itemObject.id] = itemObject
        else
            ax.util:PrintError("Invalid item data received for inventory sync.")
        end
    end

    ax.inventory.instances[inventoryID] = setmetatable({
        id = inventoryID,
        items = items,
        maxWeight = inventoryMaxWeight,
        receivers = inventoryReceivers
    }, ax.inventory.meta)
end)

ax.net:Hook("inventory.receiver.add", function(inventory, receiver)
    if ( !istable(inventory) ) then
        ax.util:PrintError("Invalid inventory data received for receiver addition.")
        return
    end

    inventory = setmetatable(inventory, ax.inventory.meta)

    if ( table.Count(inventory.items) != 0 ) then
        for itemID, item in pairs(inventory.items) do
            local itemObject = ax.item:Instance(itemID, item.class)
            if ( !istable(itemObject) ) then
                itemObject = setmetatable(item, ax.item.meta)
            end

            itemObject.invID = inventory.id
            itemObject.data = item.data or itemObject.data or {}

            ax.item.instances[itemID] = itemObject
            inventory.items[itemID] = itemObject
        end
    end

    ax.inventory.instances[inventory.id] = inventory
    inventory:AddReceiver(receiver)
end)

ax.net:Hook("inventory.receiver.remove", function(inventoryID, receiver)
    local inventory = ax.inventory.instances[inventoryID]
    if ( !istable(inventory) ) then
        ax.util:PrintError("Invalid inventory ID received for receiver removal: " .. tostring(inventoryID))
        return
    end

    if ( table.Count(inventory.items) != 0 ) then
        for itemID in pairs(inventory.items) do
            ax.item.instances[itemID] = nil
        end
    end

    inventory:RemoveReceiver(receiver)
    ax.inventory.instances[inventoryID] = nil
end)

ax.net:Hook("inventory.item.add", function(inventoryID, itemID, itemClass, itemData)

    -- If inventory 0 (world) isn't tracked clientside, still create the item instance so it exists clientside
    local inventory = ax.inventory.instances[inventoryID]
    if ( !istable(inventory) ) then
        if ( inventoryID == 0 ) then
            local itemObject = ax.item:Instance(itemID, itemClass)
            itemObject.invID = 0
            itemObject.data = itemData or {}

            ax.item.instances[itemID] = itemObject
            ax.util:PrintDebug("Added world item instance clientside (inventory 0): " .. tostring(itemID))
            return
        end

        ax.util:PrintError("Invalid inventory ID received for item add: " .. tostring(inventoryID))
        return
    end

    local itemObject = ax.item:Instance(itemID, itemClass)
    itemObject.invID = inventoryID
    itemObject.data = itemData or {}

    inventory.items[itemID] = itemObject
    ax.item.instances[itemID] = itemObject

    if ( IsValid(ax.gui.inventory) ) then
        ax.gui.inventory:PopulateItems()
    end
end)

ax.net:Hook("inventory.item.remove", function(inventoryID, itemID)

    local inv = ax.inventory.instances[inventoryID]
    if ( !istable(inv) ) then
        ax.util:PrintError("Invalid inventory ID received for item remove.")
        return
    end

    for invItemID in pairs(inv.items) do
        if ( invItemID == itemID ) then
            inv.items[invItemID] = nil
            ax.item.instances[invItemID] = nil
            break
        end
    end

    if ( IsValid(ax.gui.inventory) ) then
        ax.gui.inventory:PopulateItems()
    end
end)

ax.net:Hook("relay.update", function(index, name, value)

    ax.relay.data[index] = ax.relay.data[index] or {}
    ax.relay.data[index][name] = value

    if ( AX_WATCHER and AX_WATCHER:GetBool() and AX_WATCHER_LEVEL and AX_WATCHER_LEVEL:GetInt() > 0 ) then
        ax.util:Print(Color(0, 255, 255), "Relay data updated: [" .. index .. "][" .. name .. "] = " .. tostring(value))
    end
end)

ax.net:Hook("relay.sync", function(data)
    if ( !istable(data) ) then return end

    ax.relay.data = data
end)

ax.net:Hook("item.transfer", function(itemID, fromInventoryID, toInventoryID)

    local item = ax.item.instances[itemID]
    if ( !istable(item) ) then
        ax.util:PrintError("Item with ID " .. itemID .. " does not exist.\n" ..
            "  Transfer Details:\n" ..
            "    Item ID: " .. itemID .. "\n" ..
            "    From Inventory ID: " .. fromInventoryID .. "\n" ..
            "    To Inventory ID: " .. toInventoryID .. "\n" ..
            "  Known Item Instances: " .. table.Count(ax.item.instances) .. "\n" ..
            "  Available Item IDs: " .. table.concat(table.GetKeys(ax.item.instances), ", "))
        return
    end

    local fromInventory
    if ( fromInventoryID != 0 ) then
        fromInventory = ax.inventory.instances[fromInventoryID]
        if ( !istable(fromInventory) ) then
            ax.util:PrintWarning("From inventory with ID " .. fromInventoryID .. " does not exist.")
            return
        end
    end

    local toInventory = nil
    if ( toInventoryID != 0 ) then
        toInventory = ax.inventory.instances[toInventoryID]
        if ( !istable(toInventory) ) then
            ax.util:PrintWarning("To inventory with ID " .. toInventoryID .. " does not exist.")
            return
        end
    end

    -- Remove from the old inventory, if applicable
    if ( fromInventoryID != 0 and fromInventory and fromInventory:IsReceiver(ax.client) ) then
        fromInventory.items[item.id] = nil
    end

    item.invID = toInventoryID

    -- Add to the new inventory, if applicable
    if ( toInventoryID != 0 ) then
        toInventory.items[item.id] = item
    end

    if ( IsValid(ax.gui.inventory) ) then
        ax.gui.inventory:PopulateItems()
    end
end)

ax.net:Hook("item.spawn", function(itemID, itemClass, itemData)

    local item = ax.item.stored[itemClass]
    if ( !istable(item) ) then
        ax.util:PrintError("Invalid item class received for spawn: " .. itemClass)
        return
    end

    -- Create item instance
    local itemObject = ax.item:Instance(itemID, itemClass)
    itemObject.invID = 0
    itemObject.data = itemData

    ax.item.instances[itemID] = itemObject
end)

ax.net:Hook("chat.message", function(speaker, chatType, text, data)

    local chatClass = ax.chat.registry[chatType]
    if ( !istable(chatClass) ) then
        ax.util:PrintError("ax.chat.message - Invalid chat type \"" .. tostring(chatType) .. "\"")
        return
    end

    if ( hook.Run("ShouldFormatMessage", speaker, chatType, text, data) != false ) then
        text = ax.chat:Format(text)
    end

    if ( isfunction(chatClass.OnRun) ) then
        local packaged = { chatClass:OnRun(speaker, text, data) }
        if ( ax.client != speaker and isfunction(chatClass.OnFormatForListener) ) then
            packaged = { chatClass:OnFormatForListener(speaker, ax.client, text, data) }
        end

        ax.client:ChatPrint(unpack(packaged))
    end
end)

ax.net:Hook("character.invalidate", function(id)
    if ( !isnumber(id) or id < 1 ) then return end

    local character = ax.character.instances[id]
    if ( !istable(character) ) then
        ax.util:PrintError("Character with ID " .. id .. " does not exist.")
        return
    end

    local invID = character:GetInventoryID()
    local inventory = ax.inventory.instances[ invID ]
    if ( istable(inventory) ) then
        for itemID in pairs(inventory.items) do
            ax.item.instances[itemID] = nil
        end
    end

    ax.inventory.instances[invID] = nil
    ax.character.instances[id] = nil
end)

ax.net:Hook("player.actionbar.start", function(label, duration)
    ax.actionBar:Start(label, duration)
end)

ax.net:Hook("player.actionbar.stop", function(cancelled)
    ax.actionBar:Stop(cancelled)
end)
