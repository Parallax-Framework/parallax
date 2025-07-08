--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

ax.command:Register("ChangeVoiceMode", {
    Description = "Change your voice chat mode.",
    AdminOnly = false,
    Arguments = {
        {
            Type = ax.types.number,
            ErrorMsg = "You must provide a valid player to take a flag from!"
        }
    },
    Callback = function(info, client, arguments)
        local char = client:GetCharacter()
        if ( !char ) then
            client:Notify("You must have a character to change your voice mode!")
            return
        end

        local mode = arguments[1]
        for k = 1, #MODULE.Modes do
            local v = MODULE.Modes[k]
            if ( k == mode or ax.util:FindString(v, mode) ) then
                client:SetRelay("voiceMode", k)
                client:Notify("Your voice chat mode has been changed to " .. v .. ".")

                return
            end
        end

        client:Notify("Invalid voice chat mode! Valid modes are: " .. table.concat(MODULE.Modes, ", ") .. ".")
    end
})