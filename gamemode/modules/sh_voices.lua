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
    ax.net:Hook("voices.play", function(entity, sounds, volume, pitch)
        entity = entity or ax.client
        entity:EmitQueuedSound(sounds, volume, pitch)
    end)
else
    local function PlayQueuedSound(entity, sounds, pitch, volume)
        ax.net:Start(nil, "voices.play", entity, sounds, volume or 80, pitch or 100)
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
        if ( !isstring(chatType) ) then return end

        local normalizedChatType = utf8.lower(chatType)
        print("[Voices] PlayerMessageSend:", speaker, "chatType=", chatType, "normalized=", normalizedChatType, "text=", text)

        local allowed = {}
        for k, v in pairs(allowedChatTypes) do
            allowed[k] = v
        end

        local isVoiceChatType = hook.Run("IsVoiceChatType", chatType)
        if ( !isVoiceChatType and normalizedChatType != chatType ) then
            isVoiceChatType = hook.Run("IsVoiceChatType", normalizedChatType)
        end

        print("[Voices] IsVoiceChatType=", tostring(isVoiceChatType))

        if ( isVoiceChatType ) then
            allowed[normalizedChatType] = true
        end

        local class = ax.voices:GetClass(speaker, normalizedChatType)
        if ( !allowed[normalizedChatType] and #class > 0 ) then
            allowed[normalizedChatType] = true
            print("[Voices] Allowing chat type via class match:", normalizedChatType)
        end

        if ( !allowed[normalizedChatType] ) then
            print("[Voices] Chat type not allowed:", normalizedChatType)
            return
        end

        print("[Voices] Classes for type:", normalizedChatType, "->", table.concat(class, ", "))
        for k, v in pairs(class) do
            print("[Voices] Processing class:", v)
            local texts = GetVoiceCommands(text, v)
            local isGlobal = false
            local completetext
            local sounds = {}
            texts = ExperimentalFormatting(texts)
            print("[Voices] Parsed tokens:", #texts)
            for k2, v2 in ipairs(texts) do
                if ( v2.path ) then
                    print("[Voices] Token has path:", v2.path, "text=", v2.text)
                    if ( v2.global ) then
                        isGlobal = true
                        ax.util:PrintDebug("Global voice line detected:", v2.path)
                    end

                    table.insert(sounds, v2.path)
                else
                    print("[Voices] Token has no path:", v2.text)
                end

                local volume = isGlobal and 180 or 70
                if ( normalizedChatType == "whisper" ) then
                    volume = 55
                elseif ( normalizedChatType == "yell" ) then
                    volume = 100
                end

                completetext = completetext and completetext .. " " .. v2.text or v2.text

                if ( k2 == #texts ) then
                    if ( table.IsEmpty(sounds) ) then break end

                    print("[Voices] Emitting sounds:", table.concat(sounds, ", "))
                    local _ = !isGlobal and speaker:EmitQueuedSound(sounds, volume) or PlayQueuedSound(nil, sounds, 100, volume)

                    local isRadio = hook.Run("IsRadioVoiceChatType", chatType)
                    local radioType = chatType
                    if ( !isRadio and normalizedChatType != chatType ) then
                        isRadio = hook.Run("IsRadioVoiceChatType", normalizedChatType)
                        radioType = normalizedChatType
                    end

                    local receivers = nil
                    if ( isRadio ) then
                        receivers = hook.Run("GetRadioVoiceChatReceivers", speaker, radioType) or {}
                    else
                        receivers = hook.Run("GetRadioVoiceChatReceivers", speaker, normalizedChatType)
                        if ( istable(receivers) ) then
                            isRadio = true
                            radioType = normalizedChatType
                        end
                    end

                    print("[Voices] IsRadioVoiceChatType=", tostring(isRadio), "radioType=", radioType)

                    if ( isRadio ) then
                        receivers = receivers or {}
                        print("[Voices] Radio receivers:", #receivers)
                        for _, receiver in ipairs(receivers) do
                            if ( receiver == speaker ) then continue end

                            volume = 50
                            PlayQueuedSound(receiver, sounds, 100, volume)
                        end
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
