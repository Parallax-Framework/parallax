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

net.Receive("ax.character.namereset", function(len)
    Derma_StringRequest(
        "Character Name Reset",
        "Please enter a new name for your character:",
        "",
        function(text)
            net.Start("ax.character.namereset")
                net.WriteString(text)
            net.SendToServer()
        end)
end)

net.Receive("ax.character.descreset", function(len)
    Derma_StringRequest(
        "Character Description Reset",
        "Please enter a new description for your character:",
        "",
        function(text)
            net.Start("ax.character.descreset")
                net.WriteString(text)
            net.SendToServer()
        end)
end)

net.Receive("ax.character.cache.all", function(len)
    local data = net.ReadTable()

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

net.Receive("ax.character.cache", function()
    local data = net.ReadTable()
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

net.Receive("ax.character.create.failed", function(len)
    local reason = net.ReadString()
    if ( !reason ) then return end

    ax.client:Notify(reason)
end)

net.Receive("ax.character.create", function(len)
    -- Do something here...
end)

net.Receive("ax.character.delete", function(len)
    local characterID = net.ReadUInt(16)
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

net.Receive("ax.character.load.failed", function(len)
    local reason = net.ReadString()
    if ( !reason ) then return end

    ax.client:Notify(reason)
end)

net.Receive("ax.character.load", function(len)
    local characterID = net.ReadUInt(16)
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
    ax.character.stored = ax.character.stored or {}
    ax.character.stored[characterID] = character

    local clientTable = client:GetTable()
    clientTable.axCharacters = clientTable.axCharacters or {}
    clientTable.axCharacters[characterID] = character
    clientTable.axCharacter = character

    hook.Run("PlayerLoadedCharacter", character, currentCharacter)
end)

net.Receive("ax.character.variable.set", function(len)
    local characterID = net.ReadUInt(16)
    local key = net.ReadString()
    local value = net.ReadType()

    if ( !characterID or !key or !value ) then return end

    local character = ax.character:Get(characterID)
    if ( !character ) then return end

    character[key] = value
end)

net.Receive("ax.character.sync", function(len)
    local client = Entity(net.ReadUInt(16))
    if ( !IsValid(client) ) then print ("Invalid client for character sync!") return end

    local characterID = net.ReadUInt(16)
    if ( !characterID ) then return end

    local character = ax.character:CreateObject(characterID, net.ReadTable(), client)
    if ( !istable(character) ) then return end

    ax.character.stored = ax.character.stored or {}
    ax.character.stored[characterID] = character

    local clientTable = client:GetTable()
    clientTable.axCharacters = clientTable.axCharacters or {}
    clientTable.axCharacters[characterID] = character
    clientTable.axCharacter = character
end)

--[[-----------------------------------------------------------------------------
    Chat Networking
-----------------------------------------------------------------------------]]--

net.Receive("ax.chat.send", function(len)
    local data = net.ReadTable()
    if ( !istable(data) ) then return end

    local speaker = data.Speaker and Entity(data.Speaker) or nil
    local uniqueID = data.UniqueID
    local text = data.Text

    local chatData = ax.chat:Get(uniqueID)
    if ( istable(chatData) ) then
        chatData:OnChatAdd(speaker, text)
    end
end)

net.Receive("ax.chat.text", function(len)
    local data = net.ReadTable()
    if ( !istable(data) ) then return end

    chat.AddText(unpack(data))
end)

--[[-----------------------------------------------------------------------------
    Config Networking
-----------------------------------------------------------------------------]]--

net.Receive("ax.config.sync", function(len)
    local data = net.ReadTable()
    if ( !istable(data) ) then return end

    for key, value in pairs(data) do
        ax.config:Set(key, value)
    end
end)

net.Receive("ax.config.set", function(len)
    local key = net.ReadString()
    local value = net.ReadType()
    ax.config:Set(key, value)
end)

--[[-----------------------------------------------------------------------------
    Option Networking
-----------------------------------------------------------------------------]]--

net.Receive("ax.option.set", function(len)
    local key = net.ReadString()
    local value = net.ReadType()
    local stored = ax.option.stored[key]
    if ( !istable(stored) ) then return end

    ax.option:Set(key, value, true)
end)

--[[-----------------------------------------------------------------------------
    Inventory Networking
-----------------------------------------------------------------------------]]--

net.Receive("ax.inventory.cache", function(len)
    local data = net.ReadTable()
    if ( !istable(data) ) then return end

    local inventory = ax.inventory:CreateObject(data)
    if ( inventory ) then
        ax.inventory.stored[inventory:GetID()] = inventory

        local character = ax.character.stored[inventory.CharacterID]
        if ( character ) then
            local inventories = character:GetInventories()

            local found = false
            for i = 1, #inventories do
                if ( inventories[i] == inventory ) then
                    found = true
                    break
                end
            end

            if ( !found ) then
                table.insert(inventories, inventory)
            end

            character:SetInventories(inventories)
        end
    end
end)

net.Receive("ax.inventory.item.add", function(len)
    local inventoryID = net.ReadUInt(16)
    local itemID = net.ReadUInt(16)
    local uniqueID = net.ReadString()
    local data = net.ReadTable()
    local item = ax.item:Add(itemID, inventoryID, uniqueID, data)
    if ( !item ) then return end

    local inventory = ax.inventory:Get(inventoryID)
    if ( inventory ) then
        local items = inventory:GetItems()
        local found = false
        for i = 1, #items do
            if ( items[i] == itemID ) then
                found = true
                break
            end
        end

        if ( !found ) then
            table.insert(items, itemID)
        end
    end
end)

net.Receive("ax.inventory.item.remove", function(len)
    local inventoryID = net.ReadUInt(16)
    local itemID = net.ReadUInt(16)
    local inventory = ax.inventory:Get(inventoryID)
    if ( !inventory ) then return end

    local items = inventory:GetItems()
    local found = false
    for i = 1, #items do
        if ( items[i] == itemID ) then
            found = true
            break
        end
    end

    if ( found ) then
        table.RemoveByValue(items, itemID)
    end

    local item = ax.item:Get(itemID)
    if ( item ) then
        item:SetInventory(0)
    end
end)

net.Receive("ax.inventory.refresh", function(len)
    local inventoryID = net.ReadUInt(16)
    local panel = ax.gui.inventory
    if ( IsValid(panel) ) then
        panel:SetInventory(inventoryID)
    end
end)

net.Receive("ax.inventory.register", function(len)
    local data = net.ReadTable()
    if ( !istable(data) ) then return end

    local inventory = ax.inventory:CreateObject(data)
    if ( inventory ) then
        ax.inventory.stored[inventory.ID] = inventory
    end
end)

--[[-----------------------------------------------------------------------------
    Item Networking
-----------------------------------------------------------------------------]]--

net.Receive("ax.item.add", function(len)
    local itemID = net.ReadUInt(16)
    local inventoryID = net.ReadUInt(16)
    local uniqueID = net.ReadString()
    local data = net.ReadTable()
    ax.item:Add(itemID, inventoryID, uniqueID, data)
end)

net.Receive("ax.item.cache", function(len)
    local data = net.ReadTable()
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

net.Receive("ax.item.data", function(len)
    local itemID = net.ReadUInt(16)
    local key = net.ReadString()
    local value = net.ReadType()
    local item = ax.item:Get(itemID)
    if ( !item ) then return end

    item:SetData(key, value)
end)

net.Receive("ax.item.entity", function(len)
    local entity = net.ReadEntity()
    local itemID = net.ReadUInt(16)
    if ( !IsValid(entity) ) then return end

    local item = ax.item:Get(itemID)
    if ( !item ) then return end

    item:SetEntity(entity)
end)

--[[-----------------------------------------------------------------------------
    Currency Networking
-----------------------------------------------------------------------------]]--

net.Receive("ax.currency.give", function(len)
    local entity = net.ReadEntity()
    local amount = net.ReadUInt(32)
    if ( !IsValid(entity) ) then return end

    local phrase = ax.localization:GetPhrase("currency.pickup")
    phrase = string.format(phrase, amount .. ax.currency:GetSymbol())

    ax.client:Notify(phrase)
end)

--[[-----------------------------------------------------------------------------
    Miscellaneous Networking
-----------------------------------------------------------------------------]]--

net.Receive("ax.database.save", function(len)
    local data = net.ReadTable()
    ax.client:GetTable().axDatabase = data
end)

net.Receive("ax.gesture.play", function(len)
    local client = net.ReadPlayer()
    local name = net.ReadString()
    if ( !IsValid(client) ) then return end

    client:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, client:LookupSequence(name), 0, true)
end)

net.Receive("ax.splash", function(len)
    ax.gui.splash = vgui.Create("ax.splash")
end)

net.Receive("ax.mainmenu", function(len)
    ax.gui.mainmenu = vgui.Create("ax.mainmenu")
end)

net.Receive("ax.notification.send", function(len)
    local text = net.ReadString()
    local type = net.ReadUInt(3)
    local duration = net.ReadUInt(12)
    if ( !text ) then return end

    notification.AddLegacy(text, type, duration)
end)

net.Receive("ax.flag.list", function(len)
    local target = net.ReadPlayer()
    local character = target:GetCharacter()
    if ( !character ) then return end

    local hasFlags = net.ReadTable()
    local bGiving = net.ReadBool()
    if ( !IsValid(target) or !target:IsPlayer() ) then return end

    local query = {}
    query[#query + 1] = "Select which flag you want to " .. (bGiving and "give to " or "take from ") .. target:Name() .. "."
    query[#query + 1] = "Flag List"

    local flags = ax.flag:GetAll()
    local availableFlags = {}
    for key, data in pairs(flags) do
        if ( !isstring(key) or #key != 1 ) then continue end

        if ( bGiving and hasFlags[key] ) then continue
        elseif ( !bGiving and !hasFlags[key] ) then continue end

        query[#query + 1] = key
        query[#query + 1] = function()
            ax.command:Run(bGiving and "CharGiveFlags" or "CharTakeFlags", target, key)
        end

        availableFlags[#availableFlags + 1] = key
    end

    if ( availableFlags[1] == nil ) then
        ax.client:Notify("The target player " .. (bGiving and "already has all flags" or "doesn't have any flags") .. "!")
        return
    end

    query[#query + 1] = "Cancel"

    Derma_Query(unpack(query))
end)

-- TODO: This is a temporary solution, should be replaced with a more robust caption library.
local function GetCaptionDuration(...)
    local duration = 0
    for i = 1, select("#", ...) do
        local v = select(i, ...)
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
        local len_s, raw, delay_s, next_pos = string.match(caption,
            "<len:([%d%.]+)>(.-)<delay:([%d%.]+)>()",
            pos
        )
        if ( !len_s ) then break end

        local r, g, b = string.match(raw, "<clr:(%d+),(%d+),(%d+)>")
        local R = r and tonumber(r) or 255
        local G = g and tonumber(g) or 255
        local B = b and tonumber(b) or 255

        local text = raw
        text = string.gsub(text, "<clr:%d+,%d+,%d+>", "")
        text = string.gsub(text, "<I>", "")
        text = string.gsub(text, "<cr>", "\n")
        text = string.match(text, "^%s*(.-)%s*$")

        segments[#segments + 1] = {
            len   = tonumber(len_s),
            color = Color(R, G, B),
            text  = text,
            delay = tonumber(delay_s),
        }

        pos = next_pos
    end

    local rem = string.sub(caption, pos)
    local len_s, raw = string.match(rem, "<len:([%d%.]+)>(.*)")
    if ( len_s and string.match(raw, "%S") ) then
        local r, g, b = string.match(raw, "<clr:(%d+),(%d+),(%d+)>")
        local R = r and tonumber(r) or 255
        local G = g and tonumber(g) or 255
        local B = b and tonumber(b) or 255

        local text = raw
            :gsub("<clr:%d+,%d+,%d+>", "")
            :gsub("<I>", "")
            :gsub("<cr>", "\n")
            :match("^%s*(.-)%s*$")

        segments[#segments + 1] = {
            len   = tonumber(len_s),
            color = Color(R, G, B),
            text  = text,
            delay = nil,
        }
    end

    return segments
end

local function PrintQueue(data, idx)
    local segments, i

    if ( isstring(data) ) then
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
net.Receive("ax.caption", function(len)
    local arguments = net.ReadString()
    if ( !isstring(arguments) or arguments == "" ) then
        ax.util:PrintError("Invalid arguments for caption!")
        return
    end

    PrintQueue(arguments)

    gui.AddCaption(arguments, CAPTION_DURATION or GetCaptionDuration(arguments))
end)
