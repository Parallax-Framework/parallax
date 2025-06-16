----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

ax.net:Hook("character.cache.all", function(data)
    if ( !istable(data) ) then
        ax.util:PrintError("Invalid data received for character cache!")
        return
    end

    if ( ax.config:Get("debug.developer", false) ) then
        print("Received character cache data:")
        PrintTable(data)
    end

    local client = ax.client
    local clientTable = client:GetTable()

    for k, v in pairs(data) do
        local character = ax.character:CreateObject(v.ID, v, client)
        local characterID = character:GetID()

        ax.character.stored = ax.character.stored or {}
        ax.character.stored[characterID] = character

        clientTable.axCharacters = clientTable.axCharacters or {}
        clientTable.axCharacters[characterID] = character
    end

    -- Rebuild the main menu
    if ( IsValid(ax.gui.mainmenu) ) then
        ax.gui.mainmenu:Remove()
        ax.gui.mainmenu = vgui.Create("ax.mainmenu")
    end

    ax.client:Notify("All characters cached!", NOTIFY_HINT)
end)

ax.net:Hook("character.cache", function(data)
    if ( !istable(data) ) then return end

    local client = ax.client
    local clientTable = client:GetTable()

    local character = ax.character:CreateObject(data.ID, data, client)
    local characterID = character:GetID()

    ax.character.stored = ax.character.stored or {}
    ax.character.stored[characterID] = character

    clientTable.axCharacters = clientTable.axCharacters or {}
    clientTable.axCharacters[characterID] = character
    clientTable.axCharacter = character

    ax.client:Notify("Character " .. characterID .. " cached!", NOTIFY_HINT)
end)

ax.net:Hook("character.create.failed", function(reason)
    if ( !reason ) then return end

    ax.client:Notify(reason)
end)

ax.net:Hook("character.create", function()
    -- Do something here...
end)

ax.net:Hook("character.delete", function(characterID)
    if ( !isnumber(characterID) ) then return end

    local character = ax.character.stored[characterID]
    if ( !character ) then return end

    ax.character.stored[characterID] = nil

    local client = ax.client
    local clientTable = client:GetTable()
    if ( clientTable.axCharacters ) then
        clientTable.axCharacters[characterID] = nil
    end

    clientTable.axCharacter = nil

    if ( IsValid(ax.gui.mainmenu) ) then
        ax.gui.mainmenu:Populate()
    end

    ax.notification:Add("Character " .. characterID .. " deleted!", 5, ax.config:Get("color.success"))
end)

ax.net:Hook("character.load.failed", function(reason)
    if ( !reason ) then return end

    ax.client:Notify(reason)
end)

ax.net:Hook("character.load", function(characterID)
    if ( characterID == 0 ) then return end

    if ( IsValid(ax.gui.mainmenu) ) then
        ax.gui.mainmenu:Remove()
    end

    local client = ax.client

    local character, reason = ax.character:CreateObject(characterID, ax.character.stored[characterID], client)
    if ( !character ) then
        ax.util:PrintError("Failed to load character ", characterID, ", ", reason, "!")
        return
    end

    local currentCharacter = client:GetCharacter()
    local clientTable = client:GetTable()

    ax.character.stored = ax.character.stored or {}
    ax.character.stored[characterID] = character

    clientTable.axCharacters = clientTable.axCharacters or {}
    clientTable.axCharacters[characterID] = character
    clientTable.axCharacter = character

    hook.Run("PlayerLoadedCharacter", character, currentCharacter)
end)

ax.net:Hook("character.variable.set", function(characterID, key, value)
    if ( !characterID or !key or !value ) then return end

    local character = ax.character:Get(characterID)
    if ( !character ) then return end

    character[key] = value
end)

--[[-----------------------------------------------------------------------------
    Chat Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("chat.send", function(data)
    if ( !istable(data) ) then return end

    local speaker = data.Speaker and Entity(data.Speaker) or nil
    local uniqueID = data.UniqueID
    local text = data.Text

    local chatData = ax.chat:Get(uniqueID)
    if ( istable(chatData) ) then
        chatData:OnChatAdd(speaker, text)
    end
end)

ax.net:Hook("chat.text", function(data)
    if ( !istable(data) ) then return end

    chat.AddText(unpack(data))
end)

--[[-----------------------------------------------------------------------------
    Config Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("config.sync", function(data)
    if ( !istable(data) ) then return end

    for key, value in pairs(data) do
        ax.config:Set(key, value)
    end
end)

ax.net:Hook("config.set", function(key, value)
    ax.config:Set(key, value)
end)

--[[-----------------------------------------------------------------------------
    Option Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("option.set", function(key, value)
    local stored = ax.option.stored[key]
    if ( !istable(stored) ) then return end

    ax.option:Set(key, value, true)
end)

--[[-----------------------------------------------------------------------------
    Inventory Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("inventory.cache", function(data)
    if ( !istable(data) ) then return end

    local inventory = ax.inventory:CreateObject(data)
    if ( inventory ) then
        ax.inventory.stored[inventory:GetID()] = inventory

        local character = ax.character.stored[inventory.CharacterID]
        if ( character ) then
            local inventories = character:GetInventories()
            if ( !table.HasValue(inventories, inventory) ) then
                table.insert(inventories, inventory)
            end

            character:SetInventories(inventories)
        end
    end
end)

ax.net:Hook("inventory.item.add", function(inventoryID, itemID, uniqueID, data)
    local item = ax.item:Add(itemID, inventoryID, uniqueID, data)
    if ( !item ) then return end

    local inventory = ax.inventory:Get(inventoryID)
    if ( inventory ) then
        local items = inventory:GetItems()
        if ( !table.HasValue(items, itemID) ) then
            table.insert(items, itemID)
        end
    end
end)

ax.net:Hook("inventory.item.remove", function(inventoryID, itemID)
    local inventory = ax.inventory:Get(inventoryID)
    if ( !inventory ) then return end

    local items = inventory:GetItems()
    if ( table.HasValue(items, itemID) ) then
        table.RemoveByValue(items, itemID)
    end

    local item = ax.item:Get(itemID)
    if ( item ) then
        item:SetInventory(0)
    end
end)

ax.net:Hook("inventory.refresh", function(inventoryID)
    local panel = ax.gui.inventory
    if ( IsValid(panel) ) then
        panel:SetInventory(inventoryID)
    end
end)

ax.net:Hook("inventory.register", function(data)
    if ( !istable(data) ) then return end

    local inventory = ax.inventory:CreateObject(data)
    if ( inventory ) then
        ax.inventory.stored[inventory.ID] = inventory
    end
end)

--[[-----------------------------------------------------------------------------
    Item Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("item.add", function(itemID, inventoryID, uniqueID, data)
    ax.item:Add(itemID, inventoryID, uniqueID, data)
end)

ax.net:Hook("item.cache", function(data)
    if ( !istable(data) ) then return end

    for k, v in pairs(data) do
        local item = ax.item:CreateObject(v)
        if ( item ) then
            ax.item.instances[item.ID] = item

            if ( item.OnCache ) then
                item:OnCache()
            end
        end
    end
end)

ax.net:Hook("item.data", function(itemID, key, value)
    local item = ax.item:Get(itemID)
    if ( !item ) then return end

    item:SetData(key, value)
end)

ax.net:Hook("item.entity", function(entity, itemID)
    if ( !IsValid(entity) ) then return end

    local item = ax.item:Get(itemID)
    if ( !item ) then return end

    item:SetEntity(entity)
end)

--[[-----------------------------------------------------------------------------
    Currency Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("currency.give", function(entity, amount)
    if ( !IsValid(entity) ) then return end

    local phrase = ax.localization:GetPhrase("currency.pickup")
    phrase = string.format(phrase, amount .. ax.currency:GetSymbol())

    ax.client:Notify(phrase)
end)

--[[-----------------------------------------------------------------------------
    Miscellaneous Networking
-----------------------------------------------------------------------------]]--

ax.net:Hook("database.save", function(data)
    ax.client:GetTable().axDatabase = data
end)

ax.net:Hook("gesture.play", function(client, name)
    if ( !IsValid(client) ) then return end

    client:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, client:LookupSequence(name), 0, true)
end)

ax.net:Hook("splash", function()
    ax.gui.splash = vgui.Create("ax.splash")
end)

ax.net:Hook("mainmenu", function()
    ax.gui.mainmenu = vgui.Create("ax.mainmenu")
end)

ax.net:Hook("notification.send", function(text, type, duration)
    if ( !text ) then return end

    notification.AddLegacy(text, type, duration)
end)

ax.net:Hook("flag.list", function(target, hasFlags)
    if ( !IsValid(target) or !target:IsPlayer() ) then return end

    local query = {}
    table.insert(query, "Select which flag you want to give to " .. target:Name() .. ".")
    table.insert(query, "Flag List")

    local flags = ax.flag:GetAll()
    local availableFlags = {}
    for key, data in pairs(flags) do
        if ( !isstring(key) or #key != 1 ) then continue end
        if ( hasFlags[key] ) then continue end

        table.insert(query, key)
        table.insert(query, function()
            ax.command:Run("CharGiveFlags", target, key)
        end)

        table.insert(availableFlags, key)
    end

    if ( #availableFlags == 0 ) then
        ax.client:Notify("The target player already has all flags, so you cannot give them any more!")
        return
    end

    table.insert(query, "Cancel")

    Derma_Query(unpack(query))
end)

-- TODO: This is a temporary solution, should be replaced with a more robust caption library.
local function GetCaptionDuration(...)
    local duration = 0
    for _, v in ipairs({...}) do
        if ( isstring(v) ) then
            for _ in string.gmatch(v, "%S+") do
                duration = duration + 0.5
            end
        end
    end

    return duration
end

local function ConvertCaptionToChatArguments(caption)
    local segments = {}
    local pos = 1

    while true do
        local len_s, raw, delay_s, next_pos = caption:match(
            "<len:([%d%.]+)>(.-)<delay:([%d%.]+)>()",
            pos
        )
        if ( !len_s ) then break end

        local r, g, b = raw:match("<clr:(%d+),(%d+),(%d+)>")
        local R = r and tonumber(r) or 255
        local G = g and tonumber(g) or 255
        local B = b and tonumber(b) or 255

        local text = raw
            :gsub("<clr:%d+,%d+,%d+>", "")
            :gsub("<I>", "")
            :gsub("<cr>", "\n")
            :match("^%s*(.-)%s*$")

        table.insert(segments, {
            len   = tonumber(len_s),
            color = Color(R, G, B),
            text  = text,
            delay = tonumber(delay_s),
        })

        pos = next_pos
    end

    local rem = caption:sub(pos)
    local len_s, raw = rem:match("<len:([%d%.]+)>(.*)")
    if ( len_s and raw:match("%S") ) then
        local r, g, b = raw:match("<clr:(%d+),(%d+),(%d+)>")
        local R = r and tonumber(r) or 255
        local G = g and tonumber(g) or 255
        local B = b and tonumber(b) or 255

        local text = raw
            :gsub("<clr:%d+,%d+,%d+>", "")
            :gsub("<I>", "")
            :gsub("<cr>", "\n")
            :match("^%s*(.-)%s*$")

        table.insert(segments, {
            len   = tonumber(len_s),
            color = Color(R, G, B),
            text  = text,
            delay = nil,
        })
    end

    return segments
end

local function PrintQueue(data, idx)
    local segments, i

    if ( type(data) == "string" ) then
        segments = ConvertCaptionToChatArguments(data)
        i = 1
    else
        segments = data
        i = idx
    end

    local seg = segments[i]
    if ( !seg ) then return end

    chat.AddText(seg.color, seg.text)

    if ( seg.delay ) then
        timer.Simple(seg.delay, function()
            PrintQueue(segments, i + 1)
        end)
    end
end

-- hook becomes trivial:
ax.net:Hook("caption", function(arguments)
    if ( !isstring(arguments) or arguments == "" ) then
        ax.util:PrintError("Invalid arguments for caption!")
        return
    end

    PrintQueue(arguments)

    gui.AddCaption(arguments, CAPTION_DURATION or GetCaptionDuration(arguments))
end)
