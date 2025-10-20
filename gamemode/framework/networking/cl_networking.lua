--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Queue for character variable updates that arrive before character sync
local characterVarQueue = {}

net.Receive("ax.player.ready", function(len)
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

net.Receive("ax.character.create", function(len)
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

    local characterID = net.ReadUInt(32)
    if ( !isnumber(characterID) or characterID <= 0 ) then
        ax.util:PrintError("Invalid character ID received for creation.")
        return
    end

    -- Read the character list first before trying to access the character
    local clientData = ax.client:GetTable()
    clientData.axCharacters = {}

    local characters = net.ReadTable()
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
        net.Start("ax.character.load")
            net.WriteUInt(characterID, 32)
        net.SendToServer()

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

net.Receive("ax.character.load", function()
    local characterID = net.ReadUInt(32)
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

net.Receive("ax.character.sync", function()
    local client = net.ReadPlayer()
    if ( !IsValid(client) ) then return end

    local character = net.ReadTable()
    if ( !istable(character) ) then
        ax.util:PrintError("Invalid character data received from server")
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

net.Receive("ax.character.restore", function()
    local characters = net.ReadTable()
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

net.Receive("ax.character.delete", function()
    local id = net.ReadUInt(32)
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
        for i = #clientData.axCharacters, 1, -1 do
            if ( clientData.axCharacters[i].id == id ) then
                table.remove( clientData.axCharacters, i )
                break
            end
        end
    end

    hook.Run( "PlayerDeletedCharacter", id )

    ax.character.instances[ id ] = nil

    if ( IsValid( ax.gui.main ) and IsValid( ax.gui.main.load ) ) then
        ax.gui.main.load:PopulateCharacterList()
    end
end)

net.Receive("ax.character.var", function()
    local characterID = net.ReadUInt(32)
    local name = net.ReadString()
    local value = net.ReadType()

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

    ax.util:PrintDebug("Received character variable '" .. name .. "' update for character ID " .. characterID .. ": " .. tostring(value))
end)

net.Receive("ax.character.bot.sync", function()
    local characterID = net.ReadUInt(32)
    local botCharacter = net.ReadTable()

    -- Restore metatable for bot character
    botCharacter = setmetatable(botCharacter, ax.character.meta)

    -- Add to character instances so clients can find it
    ax.character.instances[characterID] = botCharacter

    -- Update the bot player's character reference if they exist
    local botPlayer = botCharacter:GetOwner()
    if ( IsValid(botPlayer) and botPlayer:IsBot() ) then
        botPlayer:GetTable().axCharacter = botCharacter
    end

    ax.util:PrintDebug("Received bot character sync: " .. (botCharacter:GetName() or "Unknown") .. " (ID: " .. characterID .. ")")
end)

net.Receive("ax.character.setnameprompt", function()
    local target = ax.character:Get(net.ReadUInt(32))
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

net.Receive("ax.player.var", function()
    local client = net.ReadPlayer()
    if ( !IsValid(client) ) then return end

    local key = net.ReadString()
    local value = net.ReadType()

    local clientTable = client:GetTable()
    if ( !istable(clientTable.axVars) ) then
        clientTable.axVars = {}
    end

    clientTable.axVars[key] = value
end)

net.Receive("ax.player.data", function()
    local client = net.ReadPlayer()
    if ( !IsValid(client) ) then return end

    local key, value = net.ReadString(), net.ReadType()

    local clientTable = client:GetTable()
    if ( !istable(clientTable.axVars) ) then
        clientTable.axVars = {}
    end

    if ( !istable(clientTable.axVars.data) ) then
        clientTable.axVars.data = {}
    end

    clientTable.axVars.data[key] = value
end)

net.Receive("ax.inventory.sync", function()
    local inventoryID = net.ReadUInt(32)
    local inventoryItems = net.ReadTable()
    local inventoryMaxWeight = net.ReadFloat()

    -- Convert the items into objects
    local items = {}
    for i = 1, #inventoryItems do
        local itemData = inventoryItems[i]
        if ( istable(itemData) and isnumber(itemData.id) ) then
            local itemObject = ax.item:Instance(itemData.id, itemData.class)
            itemObject.inventoryID = inventoryID
            itemObject.data = itemData.data or {}

            ax.item.instances[itemObject.id] = itemObject
            items[itemObject.id] = itemObject
            ax.util:PrintDebug(string.format("Synchronized item %d (%s) in inventory %d", itemObject.id, itemObject.class, inventoryID))
        else
            ax.util:PrintError("Invalid item data received for inventory sync.")
        end
    end

    ax.inventory.instances[inventoryID] = setmetatable({
        id = inventoryID,
        items = items,
        maxWeight = inventoryMaxWeight
    }, ax.inventory.meta)
end)

net.Receive("ax.inventory.receiver.add", function()
    local inventoryID = net.ReadUInt(32)
    local receiver = net.ReadPlayer()

    local inventory = ax.inventory.instances[inventoryID]
    if ( !istable(inventory) ) then return end

    inventory:AddReceiver(receiver)
end)

net.Receive("ax.inventory.receiver.remove", function()
    local inventory = net.ReadUInt(32)
    local receiver = net.ReadPlayer()

    inventory:RemoveReceiver(receiver)
end)

net.Receive("ax.inventory.item.add", function()
    local inventoryID = net.ReadUInt(32)
    local itemID = net.ReadUInt(32)
    local itemClass = net.ReadString()
    local itemData = net.ReadTable()

    local inventory = ax.inventory.instances[inventoryID]
    if ( !istable(inventory) ) then
        ax.util:PrintError("Invalid inventory ID received for item add.")
        return
    end

    local itemObject = ax.item:Instance(itemID, itemClass)
    itemObject.inventoryID = inventoryID
    itemObject.data = itemData or {}

    inventory.items[itemID] = itemObject
    ax.item.instances[itemID] = itemObject

    if ( IsValid(ax.gui.inventory) ) then
        ax.gui.inventory:PopulateItems()
    end
end)

net.Receive("ax.inventory.item.remove", function()
    local inventoryID = net.ReadUInt(32)
    local itemID = net.ReadUInt(32)

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

net.Receive("ax.relay.update", function()
    local index = net.ReadString()
    local name = net.ReadString()
    local value = net.ReadType()

    ax.relay.data[index] = ax.relay.data[index] or {}
    ax.relay.data[index][name] = value
end)

net.Receive("ax.relay.sync", function()
    local data = net.ReadTable()
    if ( !istable(data) ) then return end

    ax.relay.data = data
end)

net.Receive("ax.item.transfer", function()
    local itemID = net.ReadUInt(32)
    local fromInventoryID = net.ReadUInt(32)
    local toInventoryID = net.ReadUInt(32)

    local item = ax.item.instances[itemID]
    if ( !istable(item) ) then
        ax.util:PrintError("Item with ID " .. itemID .. " does not exist.")
        return
    end

    local fromInventory
    if ( fromInventoryID != 0 ) then
        fromInventory = ax.inventory.instances[fromInventoryID]
        if ( !istable(fromInventory) ) then
            ax.util:PrintError("From inventory with ID " .. fromInventoryID .. " does not exist.")
            return
        end
    end

    local toInventory = nil
    if ( toInventoryID != 0 ) then
        toInventory = ax.inventory.instances[toInventoryID]
        if ( !istable(toInventory) ) then
            ax.util:PrintError("To inventory with ID " .. toInventoryID .. " does not exist.")
            return
        end
    end

    -- Remove from the old inventory, if applicable
    if ( fromInventoryID != 0 ) then
        fromInventory.items[item.id] = nil
    end

    item.inventoryID = toInventoryID

    -- Add to the new inventory, if applicable
    if ( toInventoryID != 0 ) then
        toInventory.items[item.id] = item
    end

    ax.util:PrintDebug(string.format("Item %d transferred from inventory %d to inventory %d", item.id, fromInventoryID, toInventoryID))

    if ( IsValid(ax.gui.inventory) ) then
        ax.gui.inventory:PopulateItems()
    end
end)

net.Receive("ax.item.spawn", function()
    local itemID = net.ReadUInt(32)
    local itemClass = net.ReadString()
    local itemData = net.ReadTable()

    local item = ax.item.stored[itemClass]
    if ( !istable(item) ) then
        ax.util:PrintError("Invalid item class received for spawn: " .. itemClass)
        return
    end

    -- Create item instance
    local itemObject = ax.item:Instance(itemID, itemClass)
    itemObject.inventoryID = 0
    itemObject.data = itemData

    ax.item.instances[itemID] = itemObject
    ax.util:PrintDebug(string.format("Spawning item entity for item ID %d (%s)", itemID, itemClass))
end)
