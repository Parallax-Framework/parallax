--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.chatbox = ax.chatbox or {}
ax.chatbox.recommendations = ax.chatbox.recommendations or {}

local COMMAND_MATCH_CACHE_VERSION = 2
local function findCommand(panel, input)
    if ( !isstring(input) or input == "" ) then
        return nil
    end

    if ( panel.commandClosestCacheVersion != COMMAND_MATCH_CACHE_VERSION ) then
        panel.commandClosestCache = {}
        panel.commandClosestCacheVersion = COMMAND_MATCH_CACHE_VERSION
    end

    local key = ax.chatbox.util:Lower(string.Trim(input))
    local cached = panel.commandClosestCache[key]

    if ( cached != nil ) then
        return cached == false and nil or cached
    end

    local result = nil

    local registry = ax.command and ax.command.GetAll and ax.command:GetAll() or nil
    if ( istable(registry) ) then
        local prefixMatch = nil
        local prefixLength = nil
        local prefixName = nil

        for name, def in pairs(registry) do
            if ( !isstring(name) or !istable(def) ) then
                continue
            end

            local loweredName = util:Lower(name)

            if ( loweredName == key ) then
                result = def
                break
            end

            if ( string.StartWith(loweredName, key) ) then
                local length = #loweredName
                if (
                    !prefixMatch
                    or length < prefixLength
                    or (length == prefixLength and loweredName < prefixName)
                ) then
                    prefixMatch = def
                    prefixLength = length
                    prefixName = loweredName
                end
            end
        end

        result = result or prefixMatch
    end

    if ( !result and ax.command and ax.command.FindAll ) then
        local matches = ax.command:FindAll(key)
        local fallback = nil
        local fallbackName = nil
        local fallbackLength = nil

        for name, def in pairs(matches) do
            if ( !isstring(name) or !istable(def) ) then
                continue
            end

            local loweredName = util:Lower(name)
            local length = #loweredName

            if (
                !fallback
                or length < fallbackLength
                or (length == fallbackLength and loweredName < fallbackName)
            ) then
                fallback = def
                fallbackName = loweredName
                fallbackLength = length
            end
        end

        result = fallback
    end

    panel.commandClosestCache[key] = result or false

    return result
end

local function getVoiceClasses(panel, chatType)
    if ( !ax.voices or !ax.voices.GetClass ) then
        if ( !panel.warnedVoiceUnavailable ) then
            panel.warnedVoiceUnavailable = true
            ax.util:PrintWarning("[CHATBOX] Voice recommendations unavailable: voices module is not loaded.")
        end

        return {}
    end

    if ( !IsValid(ax.client) ) then
        return {}
    end

    local key = ax.chatbox.util:Lower(chatType)
    if ( key == "" ) then
        key = ax.chatbox.util.constants.CHAT_TYPE_DEFAULT
    end

    local cache = panel.voiceClassCache[key]
    local now = CurTime()

    if ( cache and cache.expires > now ) then
        return cache.classes
    end

    local raw = ax.voices:GetClass(ax.client, key) or {}
    local out = {}
    local seen = {}

    for i = 1, #raw do
        local class = ax.chatbox.util:Lower(raw[i])
        if ( class == "" or seen[class] or !istable(ax.voices.stored[class]) ) then
            continue
        end

        seen[class] = true
        out[#out + 1] = class
    end

    panel.voiceClassCache[key] = {
        classes = out,
        expires = now + 0.25
    }

    return out
end

local function getVoiceEntries(panel, class)
    class = ax.chatbox.util:Lower(class)
    if ( class == "" or !ax.voices or !istable(ax.voices.stored) ) then
        return {}
    end

    local source = ax.voices.stored[class]
    if ( !istable(source) ) then
        return {}
    end

    local cached = panel.voiceEntryCache[class]
    if ( cached and cached.source == source and istable(cached.entries) ) then
        return cached.entries
    end

    local entries = {}

    for key, data in pairs(source) do
        local name = isstring(key) and key or tostring(key)
        local description = istable(data) and isstring(data.text) and data.text or ""

        entries[#entries + 1] = {
            name = name,
            displayName = name,
            description = description,
            searchName = ax.chatbox.util:Lower(name),
            searchDescription = ax.chatbox.util:Lower(description)
        }
    end

    table.sort(entries, function(a, b)
        return ax.chatbox.util:Lower(a.displayName) < ax.chatbox.util:Lower(b.displayName)
    end)

    panel.voiceEntryCache[class] = {
        source = source,
        entries = entries
    }

    return entries
end

local function getCommandArguments(commandData)
    if ( !istable(commandData) or !istable(commandData.arguments) ) then
        return {}
    end

    return commandData.arguments
end

local function getCommandName(commandData)
    if ( !istable(commandData) ) then
        return ""
    end

    if ( isstring(commandData.name) and commandData.name != "" ) then
        return commandData.name
    end

    if ( isstring(commandData.displayName) and commandData.displayName != "" ) then
        return commandData.displayName
    end

    return ""
end

local function getArgumentName(argDef, index)
    if ( istable(argDef) and isstring(argDef.name) and argDef.name != "" ) then
        return argDef.name
    end

    return "arg" .. tostring(index)
end

local function getArgumentTypeName(argDef)
    if ( !istable(argDef) ) then
        return "Unknown"
    end

    if ( argDef.type == ax.type.text ) then
        return "Text"
    end

    if ( ax.type and ax.type.Format ) then
        local formatted = ax.type:Format(argDef.type)
        if ( isstring(formatted) and formatted != "" and formatted != "Unknown" ) then
            return formatted
        end
    end

    if ( isnumber(argDef.type) and ax.type and isstring(ax.type[argDef.type]) and ax.util and ax.util.UniqueIDToName ) then
        return ax.util:UniqueIDToName(ax.type[argDef.type])
    end

    return "Unknown"
end

local function getArgumentChoiceList(argDef)
    if ( !istable(argDef) or !istable(argDef.choices) ) then
        return {}
    end

    local output = {}

    for key, value in pairs(argDef.choices) do
        local candidate = nil

        if ( isstring(key) ) then
            candidate = key
        elseif ( isstring(value) ) then
            candidate = value
        end

        if ( candidate and candidate != "" ) then
            output[#output + 1] = candidate
        end
    end

    table.sort(output, function(a, b)
        return ax.chatbox.util:Lower(a) < ax.chatbox.util:Lower(b)
    end)

    return output
end

local function tokenizeArgumentText(text)
    if ( !isstring(text) or text == "" ) then
        return {}
    end

    if ( ax.util and ax.util.TokenizeString ) then
        return ax.util:TokenizeString(text)
    end

    return string.Explode(" ", string.Trim(text), false)
end

function ax.chatbox.recommendations:BuildArgumentUsageToken(argDef, index)
    local token = getArgumentName(argDef, index) .. ":" .. getArgumentTypeName(argDef)

    if ( istable(argDef) and argDef.type == ax.type.text ) then
        token = token .. "..."
    end

    if ( istable(argDef) and argDef.optional ) then
        return "[" .. token .. "]"
    end

    return "<" .. token .. ">"
end

function ax.chatbox.recommendations:BuildArgumentDescriptor(argDef, index)
    local parts = {
        getArgumentTypeName(argDef),
        istable(argDef) and argDef.optional and "optional" or "required"
    }

    if ( istable(argDef) and argDef.type == ax.type.number ) then
        if ( isnumber(argDef.min) ) then
            parts[#parts + 1] = "min " .. tostring(argDef.min)
        end

        if ( isnumber(argDef.max) ) then
            parts[#parts + 1] = "max " .. tostring(argDef.max)
        end

        if ( isnumber(argDef.decimals) ) then
            parts[#parts + 1] = "decimals " .. tostring(math.max(0, math.floor(argDef.decimals)))
        end
    elseif ( istable(argDef) and argDef.type == ax.type.bool ) then
        parts[#parts + 1] = "true/false"
    elseif ( istable(argDef) and argDef.type == ax.type.text ) then
        parts[#parts + 1] = "rest of message"
    end

    local choices = getArgumentChoiceList(argDef)
    if ( #choices > 0 ) then
        local maxVisible = math.min(4, #choices)
        local shown = {}

        for i = 1, maxVisible do
            shown[#shown + 1] = choices[i]
        end

        parts[#parts + 1] = "choices: " .. table.concat(shown, ", ") .. (#choices > maxVisible and ", ..." or "")
    end

    return getArgumentName(argDef, index) .. " (" .. table.concat(parts, ", ") .. ")"
end

function ax.chatbox.recommendations:GetActiveArgumentIndex(arguments, argsText, trailing)
    if ( !istable(arguments) or #arguments < 1 ) then
        return 0
    end

    local tokens = tokenizeArgumentText(argsText)
    local tokenCount = #tokens
    local tokenIndex = 1

    for i = 1, #arguments do
        local argDef = arguments[i]
        local hasValue = tokenIndex <= tokenCount

        if ( !hasValue ) then
            return i
        end

        if ( istable(argDef) and argDef.type == ax.type.text ) then
            if ( trailing and i < #arguments ) then
                return i + 1
            end

            if ( trailing and i >= #arguments ) then
                return #arguments + 1
            end

            return i
        end

        tokenIndex = tokenIndex + 1
    end

    return #arguments + 1
end

function ax.chatbox.recommendations:BuildCommandArgumentHintText(commandData, argsText, trailing)
    local commandName = getCommandName(commandData)
    if ( commandName == "" ) then
        return nil
    end

    local arguments = getCommandArguments(commandData)
    if ( #arguments < 1 ) then
        return ax.chatbox.util:GetPhrase("chatbox.recommendations.arguments.none", "Usage: /%s (no arguments).", commandName)
    end

    local usageParts = {}

    for i = 1, #arguments do
        usageParts[#usageParts + 1] = self:BuildArgumentUsageToken(arguments[i], i)
    end

    local usage = ax.chatbox.util:GetPhrase("chatbox.recommendations.arguments.usage", "Usage: /%s %s", commandName, table.concat(usageParts, " "))
    local activeIndex = self:GetActiveArgumentIndex(arguments, argsText or "", trailing == true)

    if ( activeIndex > #arguments ) then
        return usage .. " | " .. ax.chatbox.util:GetPhrase("chatbox.recommendations.arguments.complete", "All arguments are filled.")
    end

    return usage .. " | " .. util:GetPhrase(
        "chatbox.recommendations.arguments.next",
        "Next: %s",
        self:BuildArgumentDescriptor(arguments[activeIndex], activeIndex)
    )
end

function ax.chatbox.recommendations:UpdateCommandHint(panel, context)
    if ( !IsValid(panel.recommendations) or !IsValid(panel.recommendations.hint) ) then
        return false
    end

    local text = nil
    if ( context and context.commandData ) then
        text = self:BuildCommandArgumentHintText(
            context.commandData,
            context.commandArgs,
            context.commandTrailing
        )
    end

    if ( isstring(text) and text != "" ) then
        local glass = ax.theme:GetGlass()
        panel.recommendations.hint:SetText(text, true, true)
        panel.recommendations.hint:SetTextColor(glass.textMuted)
        panel.recommendations.hint:SetVisible(true)
        return true
    end

    panel.recommendations.hint:SetVisible(false)
    return false
end

function ax.chatbox.recommendations:GetDebounce()
    local value = tonumber(ax.config:Get("chatbox.recommendations.debounce", ax.chatbox.util.constants.RECOMMEND_DEBOUNCE_DEFAULT)) or ax.chatbox.util.constants.RECOMMEND_DEBOUNCE_DEFAULT
    return math.max(0, value)
end

function ax.chatbox.recommendations:GetAnimationDuration()
    local value = tonumber(ax.config:Get("chatbox.recommendations.animation_duration", ax.chatbox.util.constants.RECOMMEND_ANIM_DEFAULT)) or ax.chatbox.util.constants.RECOMMEND_ANIM_DEFAULT
    return math.Clamp(value, 0, 1)
end

function ax.chatbox.recommendations:GetCommandLimit()
    local value = tonumber(ax.config:Get("chatbox.recommendations.command_limit", ax.chatbox.util.constants.RECOMMEND_COMMAND_LIMIT_DEFAULT)) or ax.chatbox.util.constants.RECOMMEND_COMMAND_LIMIT_DEFAULT
    return math.max(1, math.floor(value))
end

function ax.chatbox.recommendations:GetVoiceLimit()
    local value = tonumber(ax.config:Get("chatbox.recommendations.voice_limit", ax.chatbox.util.constants.RECOMMEND_VOICE_LIMIT_DEFAULT)) or ax.chatbox.util.constants.RECOMMEND_VOICE_LIMIT_DEFAULT
    return math.max(1, math.floor(value))
end

function ax.chatbox.recommendations:GetLoocPrefix()
    local value = ax.config:Get("chatbox.looc_prefix", ax.chatbox.util.constants.LOOC_PREFIX_DEFAULT)
    if ( !isstring(value) or value == "" ) then
        return ax.chatbox.util.constants.LOOC_PREFIX_DEFAULT
    end

    return value
end

function ax.chatbox.recommendations:GetChatTypeHistoryLimit()
    local value = tonumber(ax.config:Get("chatbox.chat_type_history", ax.chatbox.util.constants.CHAT_TYPE_HISTORY_LIMIT)) or ax.chatbox.util.constants.CHAT_TYPE_HISTORY_LIMIT
    return math.max(4, math.floor(value))
end

function ax.chatbox.recommendations:SetChatType(panel, nextType)
    local old = panel.chatTypeState.current or ax.chatbox.util.constants.CHAT_TYPE_DEFAULT
    nextType = ax.chatbox.util:Lower(nextType)

    if ( nextType == "" ) then
        nextType = ax.chatbox.util.constants.CHAT_TYPE_DEFAULT
    end

    panel.chatTypeState.previous = old
    panel.chatTypeState.current = nextType

    local changed = old != nextType
    if ( changed ) then
        local history = panel.chatTypeState.history
        history[#history + 1] = nextType

        local limit = self:GetChatTypeHistoryLimit()
        while ( #history > limit ) do
            table.remove(history, 1)
        end
    end

    return old, nextType, changed
end

function ax.chatbox.recommendations:GetCommandRecommendations(panel, query)
    local key = ax.chatbox.util:Lower(string.Trim(query or ""))
    local limit = self:GetCommandLimit()

    local cached = panel.commandRecommendCache[key]
    if ( cached and cached.limit == limit ) then
        return util:CopyRecommendations(cached.items), cached.truncated == true
    end

    if ( !ax.command or !ax.command.GetAll or !ax.command.FindAll ) then
        return {}, false
    end

    local raw = key == "" and ax.command:GetAll() or ax.command:FindAll(key)
    local list = {}
    local seen = {}

    for _, data in pairs(raw) do
        if ( !istable(data) or !isstring(data.name) or data.name == "" or seen[data.name] ) then
            continue
        end

        seen[data.name] = true
        list[#list + 1] = data
    end

    table.sort(list, function(a, b)
        return util:Lower(a.displayName or a.name) < util:Lower(b.displayName or b.name)
    end)

    local output = {}
    local truncated = false

    for i = 1, #list do
        if ( #output >= limit ) then
            truncated = true
            break
        end

        local data = list[i]
        output[#output + 1] = {
            name = data.name,
            displayName = data.displayName or data.name,
            description = data.description,
            isVoice = false
        }
    end

    panel.commandRecommendCache[key] = {
        limit = limit,
        items = ax.chatbox.util:CopyRecommendations(output),
        truncated = truncated
    }

    return output, truncated
end

function ax.chatbox.recommendations:GetVoiceRecommendations(panel, query)
    local classes = getVoiceClasses(panel, panel.chatTypeState.current or ax.chatbox.util.constants.CHAT_TYPE_DEFAULT)
    if ( #classes < 1 ) then
        return {}, false
    end

    local limit = self:GetVoiceLimit()
    local search = ax.chatbox.util:Lower(string.Trim(query or ""))
    local output = {}
    local truncated = false

    for i = 1, #classes do
        local entries = getVoiceEntries(panel, classes[i])

        for j = 1, #entries do
            local entry = entries[j]
            local match = search == ""
                or string.find(entry.searchName, search, 1, true)
                or string.find(entry.searchDescription, search, 1, true)

            if ( !match ) then
                continue
            end

            if ( #output >= limit ) then
                truncated = true
                break
            end

            output[#output + 1] = {
                name = entry.name,
                displayName = entry.displayName,
                description = entry.description,
                isVoice = true
            }
        end

        if ( truncated ) then
            break
        end
    end

    return output, truncated
end

function ax.chatbox.recommendations:GetRecommendations(panel, query, kind)
    if ( kind == ax.chatbox.util.constants.RECOMMEND_TYPE_COMMANDS ) then
        return self:GetCommandRecommendations(panel, query)
    end

    if ( kind == ax.chatbox.util.constants.RECOMMEND_TYPE_VOICES ) then
        return self:GetVoiceRecommendations(panel, query)
    end

    return {}, false
end

function ax.chatbox.recommendations:ResolveContext(panel, text)
    local context = {
        chatType = ax.chatbox.util.constants.CHAT_TYPE_DEFAULT,
        recommendType = nil,
        recommendQuery = nil,
        selectDisplay = nil,
        chatDisplay = nil,
        commandData = nil,
        commandArgs = "",
        commandTrailing = false
    }

    if ( !isstring(text) ) then
        return context
    end

    local loocPrefix = self:GetLoocPrefix()
    if ( loocPrefix != "" and string.sub(text, 1, #loocPrefix) == loocPrefix ) then
        local data = findCommand(panel, "looc")
        if ( data ) then
            context.chatType = ax.chatbox.util:Lower(data.name)
            context.chatDisplay = data.displayName
        end

        return context
    end

    if ( string.sub(text, 1, 1) == "/" ) then
        local command, args, trailing = ax.chatbox.util:ParseCommandText(text)
        context.recommendType = ax.chatbox.util.constants.RECOMMEND_TYPE_COMMANDS
        context.recommendQuery = command

        if ( command == "" ) then
            return context
        end

        local data = findCommand(panel, command)
        if ( !data ) then
            return context
        end

        local chatClass = data.chatClass
        local chatType = chatClass and chatClass.key or data.name

        context.chatType = ax.chatbox.util:Lower(chatType)
        context.chatDisplay = chatClass and (chatClass.displayName or data.displayName) or data.displayName
        context.selectDisplay = data.displayName
        context.commandData = data
        context.commandArgs = args
        context.commandTrailing = trailing == true

        local supportsVoice = data.chatCommand or chatClass
        local canVoice = #getVoiceClasses(panel, context.chatType) > 0
        if ( supportsVoice and canVoice ) then
            context.recommendType = ax.chatbox.util.constants.RECOMMEND_TYPE_VOICES
            context.recommendQuery = ax.chatbox.util:ExtractVoiceSearchText(args, trailing)
        end

        return context
    end

    if ( #getVoiceClasses(panel, context.chatType) > 0 ) then
        context.recommendType = ax.chatbox.util.constants.RECOMMEND_TYPE_VOICES
        context.recommendQuery = ax.chatbox.util:ExtractVoiceSearchText(text, ax.chatbox.util:HasTrailingSpace(text))
    end

    return context
end

function ax.chatbox.recommendations:CreateRow(panel, index)
    local row = panel.recommendations:Add("DPanel")

    row:Dock(TOP)
    row:SetMouseInputEnabled(true)
    row:SetCursor("hand")
    row.rowIndex = index

    row.OnMousePressed = function(this, mouseCode)
        if ( mouseCode == MOUSE_LEFT and isnumber(this.rowIndex) ) then
            self:ApplyIndex(panel, this.rowIndex, false)
        end
    end

    row.Paint = function(this, width, height)
        if ( panel.recommendations.indexSelect != this.rowIndex ) then
            return
        end

        local glass = ax.theme:GetGlass()
        ax.render.Draw(0, 0, 0, width, height, glass.highlight or Color(90, 140, 200, 120))
    end

    row.title = row:Add("ax.text")
    row.title:Dock(LEFT)
    row.title:DockMargin(8, 0, 8, 0)
    row.title:SetFont("ax.small")

    row.description = row:Add("ax.text")
    row.description:Dock(RIGHT)
    row.description:DockMargin(8, 0, 8, 0)
    row.description:SetFont("ax.small")

    return row
end

function ax.chatbox.recommendations:HideRow(row)
    if ( !IsValid(row) ) then
        return
    end

    row:SetVisible(false)
    row:Dock(NODOCK)
    row.rowIndex = nil
end

function ax.chatbox.recommendations:Hide(panel)
    if ( !IsValid(panel.recommendations) ) then
        return
    end

    panel.recommendations.items = {}
    panel.recommendations.maxSelection = 0
    panel.recommendations.indexSelect = 0
    panel.recommendations.cycleState = ax.chatbox.util.constants.RECOMMEND_CYCLE_IDLE
    panel.recommendations.kind = nil

    if ( IsValid(panel.recommendations.notice) ) then
        panel.recommendations.notice:SetVisible(false)
    end

    if ( IsValid(panel.recommendations.hint) ) then
        panel.recommendations.hint:SetVisible(false)
    end

    for i = 1, #panel.recommendations.rows do
        self:HideRow(panel.recommendations.rows[i])
    end

    panel.recommendations:AlphaTo(ax.chatbox.util.constants.RECOMMEND_ALPHA_HIDDEN, self:GetAnimationDuration(), 0, function()
        if ( IsValid(panel.recommendations) ) then
            panel.recommendations:SetVisible(false)
        end
    end)
end

function ax.chatbox.recommendations:Render(panel, items, kind, truncated, context)
    items = istable(items) and items or {}

    local hasHint = self:UpdateCommandHint(panel, context)
    if ( #items < 1 and !hasHint ) then
        self:Hide(panel)
        return
    end

    panel.recommendations.items = items
    panel.recommendations.maxSelection = #items
    panel.recommendations.kind = kind
    panel.recommendations.truncated = truncated == true
    panel.recommendations.cycleState = ax.chatbox.util.constants.RECOMMEND_CYCLE_IDLE

    if ( panel.recommendations.indexSelect > panel.recommendations.maxSelection ) then
        panel.recommendations.indexSelect = 0
    end

    local noDesc = ax.chatbox.util:GetPhrase("chatbox.recommendations.no_description", "No description provided.")
    local glass = ax.theme:GetGlass()

    for i = 1, #items do
        local row = panel.recommendations.rows[i]
        if ( !IsValid(row) ) then
            row = self:CreateRow(panel, i)
            panel.recommendations.rows[i] = row
        end

        local item = items[i]
        row:SetVisible(true)
        row:Dock(TOP)
        row:SetZPos(i)
        row.rowIndex = i

        row.title:SetText(item.displayName or item.name or "", true)
        row.title:SetTextColor(glass.text)

        local description = isstring(item.description) and item.description != "" and item.description or noDesc
        row.description:SetText(description, true)
        row.description:SetTextColor(glass.textMuted)

        row:SetTall(math.max(row.title:GetTall(), row.description:GetTall()) + ScreenScale(ax.chatbox.util.constants.INNER_PADDING_SCALE))
    end

    for i = #items + 1, #panel.recommendations.rows do
        self:HideRow(panel.recommendations.rows[i])
    end

    if ( IsValid(panel.recommendations.notice) ) then
        if ( truncated ) then
            local limit = kind == ax.chatbox.util.constants.RECOMMEND_TYPE_VOICES and self:GetVoiceLimit() or self:GetCommandLimit()
            panel.recommendations.notice:SetText(ax.chatbox.util:GetPhrase("chatbox.recommendations.truncated", "Showing first %d results.", limit), true)
            panel.recommendations.notice:SetTextColor(glass.textMuted)
            panel.recommendations.notice:SetVisible(true)
        else
            panel.recommendations.notice:SetVisible(false)
        end
    end

    panel.recommendations:SetVisible(true)
    panel.recommendations:AlphaTo(ax.chatbox.util.constants.RECOMMEND_ALPHA_VISIBLE, self:GetAnimationDuration(), 0)
end

function ax.chatbox.recommendations:UpdateFromContext(panel, context)
    if ( !context or !context.recommendType ) then
        self:Hide(panel)
        return
    end

    local items, truncated = self:GetRecommendations(panel, context.recommendQuery or "", context.recommendType)
    self:Render(panel, items, context.recommendType, truncated, context)

    if ( context.commandData and isstring(context.commandData.name) and context.commandData.name != "" ) then
        self:Select(panel, context.commandData.name)
    elseif ( context.selectDisplay and context.selectDisplay != "" ) then
        self:Select(panel, context.selectDisplay)
    end
end

function ax.chatbox.recommendations:ProcessText(panel, text)
    local context = self:ResolveContext(panel, text)
    local oldType, newType, changed = self:SetChatType(panel, context.chatType)

    if ( context.chatDisplay ) then
        ax.chatbox.currentType = context.chatDisplay
    elseif ( newType == ax.chatbox.util.constants.CHAT_TYPE_DEFAULT ) then
        ax.chatbox.currentType = nil
    end

    self:UpdateFromContext(panel, context)

    hook.Run("ChatboxOnTextChanged", text, newType)

    if ( changed ) then
        hook.Run("ChatboxOnChatTypeChanged", newType, oldType)
    end
end

function ax.chatbox.recommendations:CancelDebounce(panel)
    timer.Remove(panel.recommendTimerID)
end

function ax.chatbox.recommendations:QueueUpdate(panel, text)
    self:CancelDebounce(panel)

    local delay = self:GetDebounce()
    if ( delay <= 0 ) then
        self:ProcessText(panel, text)
        return
    end

    timer.Create(panel.recommendTimerID, delay, 1, function()
        if ( !IsValid(panel) or !IsValid(panel.entry) ) then return end
        if ( panel.entryLockCount and panel.entryLockCount > 0 ) then return end
        self:ProcessText(panel, panel.entry:GetValue() or "")
    end)
end

function ax.chatbox.recommendations:ApplyIndex(panel, index, fromCycle)
    local item = panel.recommendations.items[index]
    if ( !item ) then
        return
    end

    panel.recommendations.indexSelect = index
    panel.recommendations.cycleState = fromCycle and ax.chatbox.util.constants.RECOMMEND_CYCLE_ACTIVE or ax.chatbox.util.constants.RECOMMEND_CYCLE_IDLE

    if ( item.isVoice ) then
        local text = panel.entry:GetText() or ""
        if ( string.sub(text, 1, 1) == "/" ) then
            panel.entry:SetText(ax.chatbox.util:InsertVoiceInCommandText(text, item.name))
        else
            panel.entry:SetText(ax.chatbox.util:InsertVoiceInRegularText(text, item.name))
        end
    else
        panel.entry:SetText("/" .. item.name)
    end

    panel.entry:RequestFocus()
    panel.entry:SetCaretPos(#panel.entry:GetText())
    panel.recommendations:ScrollToChild(panel.recommendations.rows[index])

    -- Apply immediate context refresh so selected command hints stay in sync
    -- even when recommendation debounce is enabled.
    self:CancelDebounce(panel)
    self:ProcessText(panel, panel.entry:GetText() or "")

    surface.PlaySound("ui/buttonrollover.wav")
end

function ax.chatbox.recommendations:Cycle(panel)
    if ( !panel.recommendations:IsVisible() ) then
        return
    end

    if ( panel.recommendations:GetAlpha() <= ax.chatbox.util.constants.RECOMMEND_ALPHA_HIDDEN ) then
        return
    end

    if ( !panel.recommendations.items or #panel.recommendations.items < 1 ) then
        return
    end

    local index = panel.recommendations.indexSelect or 0
    if ( panel.recommendations.cycleState == ax.chatbox.util.constants.RECOMMEND_CYCLE_IDLE ) then
        index = 1
        panel.recommendations.cycleState = ax.chatbox.util.constants.RECOMMEND_CYCLE_ACTIVE
    else
        index = index + 1
    end

    local max = panel.recommendations.maxSelection or #panel.recommendations.items
    local wrap = ax.config:Get("chatbox.recommendations.wrap_cycle", true) != false

    if ( index > max ) then
        index = wrap and 1 or max
    end

    self:ApplyIndex(panel, index, true)
end

function ax.chatbox.recommendations:Select(panel, identifier)
    if ( !panel.recommendations.items or #panel.recommendations.items < 1 ) then
        return
    end

    for i = 1, #panel.recommendations.items do
        local item = panel.recommendations.items[i]
        if ( item.displayName == identifier or item.name == identifier ) then
            panel.recommendations.indexSelect = i
            panel.recommendations.cycleState = ax.chatbox.util.constants.RECOMMEND_CYCLE_IDLE
            panel.recommendations:ScrollToChild(panel.recommendations.rows[i])
            return
        end
    end
end

function ax.chatbox.recommendations:Populate(panel, text, kind)
    if ( text == nil ) then
        self:Hide(panel)
        return
    end

    local items, truncated = self:GetRecommendations(panel, text, kind)
    self:Render(panel, items, kind, truncated)
end
