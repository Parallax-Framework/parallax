--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:PlayerCanHearPlayersVoice(listener, speaker)
    local charSpeaker = speaker:GetCharacter()
    local charListener = listener:GetCharacter()

    if ( !charSpeaker or !charListener ) then return false end

    local speakerVoiceMode = speaker:GetRelay("voiceMode", 2) -- Default's to "Normal"
    if ( speakerVoiceMode == 1 ) then -- Whisper
        return ax.chat.classes.whisper:CanHear(speaker, listener), true
    elseif ( speakerVoiceMode == 3 ) then -- Yell
        return ax.chat.classes.yell:CanHear(speaker, listener), true
    end
end