--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

gameevent.Listen("OnRequestFullUpdate")
hook.Add("OnRequestFullUpdate", "ax.OnRequestFullUpdate", function(data)
    if ( !istable(data) or !isnumber(data.userid) ) then return end

    local client = Player(data.userid)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    if ( clientTable.axReady ) then return end

    clientTable.axReady = true

    timer.Simple(0, function()
        if ( !IsValid(client) ) then return end

        hook.Run("PlayerReady", client)
    end)
end)

function GM:PlayerDeathThink(client)
    local character = client:GetCharacter()
    if ( !character ) then return true end

end

function GM:PlayerReady(client)
    net.Start("ax.player.ready")
    net.Send(client)

    local inventory = setmetatable({
        id = #ax.inventory.instances + 1,
    }, ax.meta.inventory)

    local character = setmetatable({
        steamid = client:SteamID64(),
        name = "John Doe",
        id_inv = inventory.id,
    }, ax.meta.character)

    ax.inventory.instances[inventory.id] = inventory

    local curTime = math.floor(os.time())

    local query = mysql:Insert("ax_characters")
        query:Insert("schema", engine.ActiveGamemode())
        query:Callback(function(result)
            print(result)
            if ( result == false ) then
                ax.util:PrintError("Failed to create character for " .. client:SteamID64() .. ": " .. (result and result.error or "Unknown error"))
                return
            end

            character.id = result.lastInsertId
            ax.character.instances[character.id] = character

            -- Set the character on the client
            client:GetTable().axCharacter = character

            net.Start("ax.character.sync")
                net.WritePlayer(client)
                net.WriteTable(character)
            net.Broadcast()
        end)
    query:Execute()
end

function GM:PlayerSay(client, text, teamChat)
    if ( text == "" ) then return end

    --[[
    local firstWord = string.Explode("%s+", text, true)[1]
    if ( firstWord[1] == "/" ) then
        firstWord = string.sub(text, 2)
    end

    local cmd = ax.command:Get(firstWord)
    print(firstWord)
    if ( istable(cmd) ) then
        if ( ax.command:CanRun(firstWord, client) ) then
            local args = ax.command:ParseArguments(string.sub(text, #firstWord + 2))

            PrintTable(args)

            hook.Run("RunCommand", firstWord, client, args)
        else
            ax.util:PrintError("You do not have permission to run this command.")
        end

        return ""
    end
    ]]

    -- a bloody mess

    if ( hook.Run("ShouldFormatMessage", client, text) == false ) then
        return text
    end

    text = ax.chat:Format(text)
    return text
end

function GM:DatabaseConnected()
    ax.database:CreateTables()

    ax.util:PrintDebug("Database connected and tables created. (module: " .. mysql.module .. ")")
end