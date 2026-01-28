--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Introductory Welcome Screen"
MODULE.description = "Handles the introductory welcome screen animations."
MODULE.author = "L7D, Riggs"

MODULE.data = nil
MODULE.stored = {}

ax.config:Add("intro.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "intro",
    description = "Allow the welcome intro to play for clients."
})

ax.config:Add("intro.location.show", ax.type.bool, true, {
    category = "interface",
    subCategory = "intro",
    description = "Show the main location line in the intro."
})

ax.config:Add("intro.location.text", ax.type.string, "Welcome to {map}", {
    category = "interface",
    subCategory = "intro",
    description = "Text for the main location line."
})

ax.config:Add("intro.framework.show", ax.type.bool, true, {
    category = "interface",
    subCategory = "intro",
    description = "Show the framework credits line."
})

ax.config:Add("intro.framework.template", ax.type.string, "Parallax Framework development by {author}", {
    category = "interface",
    subCategory = "intro",
    description = "Template for framework credits. Use {author} and {framework}."
})

ax.config:Add("intro.schema.show", ax.type.bool, true, {
    category = "interface",
    subCategory = "intro",
    description = "Show the schema credits line."
})

ax.config:Add("intro.schema.template", ax.type.string, "{schema} Schema development by {schema_author}", {
    category = "interface",
    subCategory = "intro",
    description = "Template for schema credits. Use {schema} and {schema_author}."
})

ax.config:Add("intro.text.color", ax.type.color, Color(255, 255, 255), {
    category = "interface",
    subCategory = "intro",
    description = "Base text color for the intro lines."
})

ax.config:Add("intro.font.title", ax.type.string, "ax.large", {
    category = "interface",
    subCategory = "intro",
    description = "Font for the main intro line."
})

ax.config:Add("intro.font.credits", ax.type.string, "ax.regular", {
    category = "interface",
    subCategory = "intro",
    description = "Font for the credits lines."
})

ax.option:Add("intro.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "intro",
    description = "Show the welcome intro on your client.",
    bNoNetworking = true
})

ax.option:Add("intro.hold.time", ax.type.number, 8, {
    category = "interface",
    subCategory = "intro",
    description = "How long each intro line stays on screen.",
    bNoNetworking = true,
    min = 1,
    max = 20,
    decimals = 1
})

ax.option:Add("intro.fade.speed", ax.type.number, 6, {
    category = "interface",
    subCategory = "intro",
    description = "Fade speed for intro lines (higher is faster).",
    bNoNetworking = true,
    min = 0,
    max = 20,
    decimals = 1
})

ax.option:Add("intro.fade.out.delay", ax.type.number, 1, {
    category = "interface",
    subCategory = "intro",
    description = "Seconds before the end to start fading out.",
    bNoNetworking = true,
    min = 0,
    max = 5,
    decimals = 1
})

ax.option:Add("intro.typewriter.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "intro",
    description = "Enable the typewriter effect.",
    bNoNetworking = true
})

ax.option:Add("intro.typewriter.delay", ax.type.number, 0.09, {
    category = "interface",
    subCategory = "intro",
    description = "Delay between each typed character.",
    bNoNetworking = true,
    min = 0,
    max = 1,
    decimals = 2
})

ax.option:Add("intro.sound.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "intro",
    description = "Play a sound for each typed character.",
    bNoNetworking = true
})

ax.option:Add("intro.sound.path", ax.type.string, "common/talk.wav", {
    category = "interface",
    subCategory = "intro",
    description = "Sound path used for the typewriter effect.",
    bNoNetworking = true
})

ax.localization:Register("en", {
    ["category.interface"] = "Interface",
    ["subcategory.intro"] = "Intro",
    ["config.intro.enabled"] = "Enable Intro",
    ["config.intro.enabled.help"] = "Allow the welcome intro to play for clients.",
    ["config.intro.location.show"] = "Show Location Line",
    ["config.intro.location.show.help"] = "Show the main location line in the intro.",
    ["config.intro.location.text"] = "Location Text",
    ["config.intro.location.text.help"] = "Text for the main location line.",
    ["config.intro.framework.show"] = "Show Framework Credits",
    ["config.intro.framework.show.help"] = "Show the framework credits line.",
    ["config.intro.framework.template"] = "Framework Credits Template",
    ["config.intro.framework.template.help"] = "Template for framework credits. Use {author} and {framework}.",
    ["config.intro.schema.show"] = "Show Schema Credits",
    ["config.intro.schema.show.help"] = "Show the schema credits line.",
    ["config.intro.schema.template"] = "Schema Credits Template",
    ["config.intro.schema.template.help"] = "Template for schema credits. Use {schema} and {schema_author}.",
    ["config.intro.text.color"] = "Intro Text Color",
    ["config.intro.text.color.help"] = "Base text color for the intro lines.",
    ["config.intro.font.title"] = "Title Font",
    ["config.intro.font.title.help"] = "Font for the main intro line.",
    ["config.intro.font.credits"] = "Credits Font",
    ["config.intro.font.credits.help"] = "Font for the credits lines.",
    ["option.intro.enabled"] = "Show Intro",
    ["option.intro.enabled.help"] = "Show the welcome intro on your client.",
    ["option.intro.hold.time"] = "Line Hold Time",
    ["option.intro.hold.time.help"] = "How long each intro line stays on screen.",
    ["option.intro.fade.speed"] = "Fade Speed",
    ["option.intro.fade.speed.help"] = "Fade speed for intro lines (higher is faster).",
    ["option.intro.fade.out.delay"] = "Fade Out Delay",
    ["option.intro.fade.out.delay.help"] = "Seconds before the end to start fading out.",
    ["option.intro.typewriter.enabled"] = "Typewriter Effect",
    ["option.intro.typewriter.enabled.help"] = "Enable the typewriter effect.",
    ["option.intro.typewriter.delay"] = "Typewriter Delay",
    ["option.intro.typewriter.delay.help"] = "Delay between each typed character.",
    ["option.intro.sound.enabled"] = "Typewriter Sound",
    ["option.intro.sound.enabled.help"] = "Play a sound for each typed character.",
    ["option.intro.sound.path"] = "Typewriter Sound Path",
    ["option.intro.sound.path.help"] = "Sound path used for the typewriter effect."
})

local function FormatTemplate(template, data)
    if ( !isstring(template) ) then return "" end

    local result = template
    for key, value in pairs(data or {}) do
        result = string.Replace(result, "{" .. key .. "}", tostring(value))
    end

    return result
end

local function GetIntroColor()
    local col = ax.config:Get("intro.text.color", Color(255, 255, 255))
    if ( !IsColor(col) ) then
        col = Color(255, 255, 255)
    end

    return col
end

--- Registers a line in the intro sequence.
-- @realm client
-- @param text any Text string or function returning a string
-- @param font string Font name
-- @param showingTime number How long the line stays visible
-- @param col Color Base color for the line
-- @param startX number Start X
-- @param startY number Start Y
-- @param xAlign number X alignment
-- @param yAlign number Y alignment
function MODULE:Register(text, font, showingTime, col, startX, startY, xAlign, yAlign)
    self.stored[#self.stored + 1] = {
        text = "",
        font = font,
        targetText = text,
        startX = startX,
        startY = startY,
        startTime = 0,
        showingTime = showingTime,
        a = 0,
        col = col,
        xAlign = xAlign,
        yAlign = yAlign,
        textSubCount = 1,
        textTime = 0,
        textTimeDelay = 0,
    }
end

local function ResetEntry(entry, startTime)
    entry.text = ""
    entry.textSubCount = 1
    entry.textTimeDelay = math.max(ax.option:Get("intro.typewriter.delay", 0.09), 0)
    entry.textTime = startTime + entry.textTimeDelay
    entry.a = 0
    entry.startTime = startTime
end

local function ShouldShowText(value)
    return isstring(value) and value != ""
end

function MODULE:ResetIntro()
    self.data = nil
    self.stored = {}
end

--- Builds and optionally starts the intro sequence.
-- @realm client
-- @param bStart boolean Whether to start immediately
function MODULE:InitializeIntro(bStart)
    self.stored = {}

    local scrW, scrH = ScrW(), ScrH()
    local x, y = scrW - ax.util:ScreenScale(64), scrH / 2
    local holdTime = ax.option:Get("intro.hold.time", 8)
    local titleFont = ax.config:Get("intro.font.title", "ax.large")
    local creditsFont = ax.config:Get("intro.font.credits", "ax.regular")
    local baseColor = GetIntroColor()

    if ( ax.config:Get("intro.location.show", true) ) then
        local locationText = FormatTemplate(ax.config:Get("intro.location.text"), {
            map = game.GetMap() or "Unknown"
        })

        if ( ShouldShowText(locationText) ) then
            locationText = ax.chat:Format(locationText)

            self:Register(locationText, titleFont, holdTime, baseColor, x, y, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    if ( ax.config:Get("intro.framework.show", true) ) then
        local frameworkCredits = FormatTemplate(ax.config:Get("intro.framework.template"), {
            author = GAMEMODE.Author or "Unknown",
            framework = GAMEMODE.Name or "Parallax Framework"
        })

        if ( ShouldShowText(frameworkCredits) ) then
            frameworkCredits = ax.chat:Format(frameworkCredits)

            x, y = ax.util:ScreenScale(32), scrH - ax.util:ScreenScaleH(32)
            self:Register(frameworkCredits, creditsFont, holdTime, baseColor, x, y, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        end
    end

    if ( ax.config:Get("intro.schema.show", true) ) then
        local schemaName = ( SCHEMA and SCHEMA.name ) or "Schema"
        local schemaAuthor = ( SCHEMA and SCHEMA.author ) or "Unknown"
        local schemaCredits = FormatTemplate(ax.config:Get("intro.schema.template"), {
            schema = schemaName,
            schema_author = schemaAuthor
        })

        if ( ShouldShowText(schemaCredits) ) then
            schemaCredits = ax.chat:Format(schemaCredits)

            x, y = scrW - ax.util:ScreenScale(32), scrH - ax.util:ScreenScaleH(32)
            self:Register(schemaCredits, creditsFont, holdTime, baseColor, x, y, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        end
    end

    if ( bStart == false ) then return end

    if ( #self.stored == 0 ) then
        self.data = nil
        return
    end

    local startTime = CurTime()
    self.data = {
        initStartTime = startTime,
        runID = 1
    }

    ResetEntry(self.stored[1], startTime)
end

function MODULE:OnSchemaLoaded()
    self:InitializeIntro(true)
end

function MODULE:PlayerLoadedCharacter(client, character, currentChar)
    if ( client != ax.client ) then return end

    self:InitializeIntro(true)
end

local function ShouldDrawIntro(client)
    if ( !ax.util:IsValidPlayer(client) or !client:GetCharacter() ) then return false end
    if ( !ax.config:Get("intro.enabled", true) or !ax.option:Get("intro.enabled", true) ) then return false end
    if ( hook.Run("ShouldDrawWelcomeIntro", client) == false ) then return false end

    return true
end

function MODULE:HUDPaintCurvy()
    if ( !self.data or !self.stored ) then return end

    local client = ax.client
    if ( !ShouldDrawIntro(client) ) then return end

    local data = self.data
    local runningData = self.stored[ data.runID ]
    if ( !runningData ) then return end

    local curTime = CurTime()
    local fadeOutDelay = math.max(ax.option:Get("intro.fade.out.delay", 1), 0)
    local fadeSpeed = math.max(ax.option:Get("intro.fade.speed", 6), 0)
    local lerpSpeed = math.Clamp(FrameTime() * fadeSpeed, 0, 1)

    if ( runningData.startTime + runningData.showingTime - fadeOutDelay <= curTime ) then
        if ( math.Round( runningData.a ) <= 0 ) then
            data.runID = data.runID + 1
            runningData = self.stored[data.runID]

            if ( !runningData ) then
                self.data = nil
                return
            end

            ResetEntry(runningData, curTime)
        else
            runningData.a = Lerp(lerpSpeed, runningData.a, 0)
        end
    else
        runningData.a = Lerp(lerpSpeed, runningData.a, 255)
    end

    local targetText = isfunction(runningData.targetText) and runningData.targetText() or runningData.targetText or ""
    if ( !isstring(targetText) ) then
        targetText = tostring(targetText)
    end

    if ( !ax.option:Get("intro.typewriter.enabled", true) ) then
        runningData.text = targetText
    elseif ( runningData.textTime <= curTime and string.len(runningData.text) < string.len(targetText) ) then
        local text = targetText:sub(runningData.textSubCount, runningData.textSubCount)

        runningData.text = runningData.text .. text
        runningData.textSubCount = runningData.textSubCount + 1
        runningData.textTime = curTime + runningData.textTimeDelay

        if ( ax.option:Get("intro.sound.enabled", true) ) then
            local soundPath = ax.option:Get("intro.sound.path", "common/talk.wav")
            if ( isstring(soundPath) and soundPath != "" ) then
                surface.PlaySound(soundPath)
            end
        end
    end

    local col = runningData.col or Color(255, 255, 255, 255)
    draw.SimpleText(runningData.text, runningData.font, runningData.startX, runningData.startY, Color(col.r, col.g, col.b, runningData.a), runningData.xAlign or 1, runningData.yAlign or 1)
end
