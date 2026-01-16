--[[
    Copyright 2022 DoopieWop

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local MODULE = MODULE

MODULE.name = "Voices"
MODULE.description = "Adds voice line functionality to characters."
MODULE.author = "DoopieWop, Riggs"

ax.voices = {}
ax.voices.stored = {}
ax.voices.classes = {}

function ax.voices:Add(class, key, text, path, global)
    if ( !key or !text or !path or string.len(key) == 0 or string.len(text) == 0 or string.len(path) == 0 ) then
        ax.util:PrintWarning("Voice line for class \"" .. tostring(class) .. "\" with key \"" .. tostring(key) .. "\" is missing text or path!\n")
        return
    end

    class = utf8.lower(class)
    key = utf8.lower(key)

    ax.voices.stored[class] = ax.voices.stored[class] or {}
    ax.voices.stored[class][key] = {
        text = text,
        path = path,
        global = global
    }
end

function ax.voices:Get(class, key)
    class = utf8.lower(class)
    key = utf8.lower(key)

    if ( ax.voices.stored[class] ) then
        return ax.voices.stored[class][key]
    end
end

function ax.voices:AddClass(class, condition)
    class = utf8.lower(class)

    ax.voices.classes[class] = {
        condition = condition
    }
end

function ax.voices:GetClass(client, chatType)
    local classes = {}

    for k, v in pairs(ax.voices.classes) do
        if ( v.condition(client, chatType) ) then
            classes[#classes + 1] = k
        end
    end

    return classes
end

if ( CLIENT ) then
    ax.net:Hook("ax.voices.play", function(entity, sounds, volume, pitch)
        entity = entity or ax.client
        entity:EmitQueuedSound(sounds, volume, pitch)
    end)
else
    util.AddNetworkString("ax.voices.play")

    local function PlayQueuedSound(entity, sounds, pitch, volume)
        ax.net:Start(nil, "ax.voices.play", entity, sounds, volume or 80, pitch or 100)
    end

    local function GetVoiceCommands(text, class)
        local strings = string.Explode(" ", text)
        local finaltable = {}
        local usedkeys = {}

        for k, v in ipairs(strings) do
            if ( usedkeys[k] ) then continue end

            v = string.Trim(v)

            local info = ax.voices:Get(class, v)
            if ( !info and !separator ) then
                local combiner
                local temp = {}

                for i = k, #strings do
                    combiner = combiner and combiner .. " " .. strings[i] or strings[i]

                    info = ax.voices:Get(class, combiner)

                    temp[i] = true

                    if ( info ) then
                        usedkeys = temp
                        break
                    end
                end
            end

            table.insert(finaltable, !info and {text = v} or table.Copy(info))
        end

        return finaltable
    end

    local function ExperimentalFormatting(stringtabl)
        local carry
        -- carry like in mathematical equations :)
        -- the point of the carry is to move question marks or exclamation marks to the end of the text
        for k, v in ipairs(stringtabl) do
            local before, after = stringtabl[k - 1] and k - 1, stringtabl[k + 1] and k + 1

            -- if we are not a voice command, check if we have someone before us, cuz if we do and they are a voice command than only they can have the carry symbol set
            if ( !v.path ) then
                if ( before and carry and stringtabl[before].path and string.sub(stringtabl[before].text, #stringtabl[before].text, #stringtabl[before].text) != "," ) then
                    local text = stringtabl[before].text
                    stringtabl[before].text = string.SetChar(text, #text, carry)
                    carry = nil
                end

                -- we only want voice commands to be corrected
                continue
            end

            -- if there is a string before us adjust the casing of our first letter according to the before's symbol
            if ( before ) then
                local sub = string.sub(stringtabl[before].text, #stringtabl[before].text, #stringtabl[before].text)
                local case = utf8.lower(string.sub(v.text, 1, 1))

                if ( sub == "!" or sub == "." or sub == "?" ) then
                    case = utf8.upper(string.sub(v.text, 1, 1))
                end

                v.text = string.SetChar(v.text, 1, case)
            end

            -- if there is a string after us adjust our symbol to their casing. if they are a vc always adjust to comma, if they are not, check if the message starts with a lower casing letter, indicating a conntinuation of the sentence
            if ( after ) then
                local firstletterafter = string.sub(stringtabl[after].text, 1, 1)
                local endsub = string.sub(v.text, #v.text, #v.text)

                if ( ( stringtabl[after].path or string.match(firstletterafter, "%l") ) and endsub == "!" or endsub == "." or endsub == "?" ) then
                    v.text = string.SetChar(v.text, #v.text, ",")
                    if stringtabl[after].path and endsub != "." then
                        carry = carry == nil and endsub or carry
                    end
                end
            end

            -- we are a vc so we can also set the carry to us
            if ( carry and !after ) then
                v.text = string.SetChar(v.text, #v.text, carry)
                carry = nil
                continue
            end
        end

        return stringtabl
    end

    local allowedChatTypes = {
        ["ic"] = true,
        ["whisper"] = true,
        ["yell"] = true,
    }

    function MODULE:PlayerMessageSend(speaker, chatType, text, formattedText)
        local allowed = {}
        for k, v in pairs(allowedChatTypes) do
            allowed[k] = v
        end

        for k, v in pairs(hook.Run("GetAdditionalVoiceChatTypes") or {}) do
            allowed[v] = true
        end

        if ( !allowed[chatType] ) then return end

        local class = ax.voices:GetClass(speaker, chatType)
        for k, v in pairs(class) do
            local texts = GetVoiceCommands(text, v)
            local isGlobal = false
            local completetext
            local sounds = {}
            texts = ExperimentalFormatting(texts)
            for k2, v2 in ipairs(texts) do
                if ( v2.path ) then
                    if ( v2.global ) then
                        isGlobal = true
                        ax.util:PrintDebug("Global voice line detected:", v2.path)
                    end

                    table.insert(sounds, v2.path)
                end

                local volume = isGlobal and 180 or 70
                if ( chatType == "whisper" ) then
                    volume = 55
                elseif ( chatType == "yell" ) then
                    volume = 100
                end

                completetext = completetext and completetext .. " " .. v2.text or v2.text

                if ( k2 == #texts ) then
                    if ( table.IsEmpty(sounds) ) then break end

                    local _ = !isGlobal and speaker:EmitQueuedSound(sounds, volume) or PlayQueuedSound(nil, sounds, 100, volume)

                    if ( hook.Run("IsRadioVoiceChatType", chatType) ) then
                        volume = 50
                        PlayQueuedSound(nil, sounds, 100, volume)
                    end

                    text = completetext

                    goto exit
                end
            end
        end

        ::exit::

        return text
    end
end
