--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

AX_CLIENT_QUEUE = AX_CLIENT_QUEUE or {}

function GM:PlayerDeathThink(client)
    local character = client:GetCharacter()
    if ( !character ) then return true end

    return false
end

function GM:DatabaseConnected()
    ax.database:CreateTables()
end

function GM:PlayerInitialSpawn(client)
    client:SetNoDraw(true)
    client:SetNotSolid(true)
    client:SetMoveType(MOVETYPE_NONE)

    ax.util:PrintDebug("Client " .. client:SteamID64() .. " has connected, waiting for full update request...")

    AX_CLIENT_QUEUE[client:SteamID64()] = true
    hook.Run("PlayerQueued", client)
end

function GM:StartCommand(client, userCmd)
    if ( AX_CLIENT_QUEUE[client:SteamID64()] ) then
        AX_CLIENT_QUEUE[client:SteamID64()] = nil

        ax.util:PrintDebug("Client " .. client:SteamID64() .. " requested full update, sending character cache...")

        local query = mysql:Select("ax_characters")
            query:Where("steamid", client:SteamID64())
            query:Callback(function(result, status)
                if ( result == false ) then
                    ax.util:PrintError("Failed to fetch characters for " .. client:SteamID64() .. ": " .. (result and result.error or "Unknown error"))
                    return
                end

                if ( result[1] == nil ) then
                    ax.util:PrintDebug("No characters found for " .. client:SteamID64())
                    return
                end

                local characters = {}

                for i = 1, #result do
                    local charData = result[i]
                    local character = setmetatable({}, ax.meta.character)

                    for k, v in pairs(charData) do
                        if ( k == "vars" ) then
                            character.vars = util.JSONToTable(v) or {}
                        else
                            character[k] = v
                        end

                        for vK, vV in pairs(ax.character.vars) do
                            if ( k == vV.field ) then
                                character[vK] = v
                            end
                        end
                    end

                    ax.character.instances[character.id] = character
                    characters[#characters + 1] = character
                end

                client:GetTable().axCharacters = characters

                net.Start("ax.character.cache")
                    net.WriteTable(characters)
                net.Send(client)

                ax.util:PrintDebug("Sent character cache to " .. client:SteamID64())

                net.Start("ax.player.ready")
                net.Send(client)

                hook.Run("PlayerReady", client, characters)
            end)
        query:Execute()
    end
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