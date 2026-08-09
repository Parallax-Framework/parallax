--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Client-side HUD element registry and default framework elements.
-- Provides a configurable rendering pipeline so schemas and modules can add or
-- override HUD pieces without editing framework hooks directly.
-- @module ax.elements

ax.elements = ax.elements or {}
ax.elements.stored = ax.elements.stored or {}
ax.elements.sorted = ax.elements.sorted or {}
ax.elements.targetData = ax.elements.targetData or {}

local DEFAULT_TEXT_COLOR = Color(255, 255, 255)
local DEFAULT_SHADOW_COLOR = Color(0, 0, 0)
local TRACE_MINS = Vector(-4, -4, -4)
local TRACE_MAXS = Vector(4, 4, 4)

local function SortElements()
    ax.elements.sorted = {}

    for uniqueID, element in pairs(ax.elements.stored) do
        ax.elements.sorted[#ax.elements.sorted + 1] = {
            uniqueID = uniqueID,
            element = element,
        }
    end

    table.sort(ax.elements.sorted, function(a, b)
        local aOrder = tonumber(a.element.order) or 100
        local bOrder = tonumber(b.element.order) or 100

        if ( aOrder == bOrder ) then
            return a.uniqueID < b.uniqueID
        end

        return aOrder < bOrder
    end)
end

--- Registers a HUD element.
-- @realm client
-- @param uniqueID string Stable identifier for the element.
-- @param data table Element definition. Supports order, option, enabled, ShouldDraw, Think, Paint.
-- @return table|nil element The registered element, or nil when invalid.
function ax.elements:Register(uniqueID, data)
    if ( !isstring(uniqueID) or uniqueID == "" ) then return end
    if ( !istable(data) ) then return end

    data.uniqueID = uniqueID
    data.order = tonumber(data.order) or 100
    data.enabled = data.enabled != false

    self.stored[uniqueID] = data
    SortElements()

    return data
end

--- Removes a HUD element from the registry.
-- @realm client
-- @param uniqueID string Element identifier.
function ax.elements:Unregister(uniqueID)
    if ( !isstring(uniqueID) or uniqueID == "" ) then return end

    self.stored[uniqueID] = nil
    SortElements()
end

--- Gets a HUD element by identifier.
-- @realm client
-- @param uniqueID string Element identifier.
-- @return table|nil element The registered element.
function ax.elements:Get(uniqueID)
    return self.stored[uniqueID]
end

--- Gets all registered HUD elements.
-- @realm client
-- @return table elements Registry table keyed by unique identifier.
function ax.elements:GetAll()
    return self.stored
end

--- Changes the draw order of a registered element.
-- @realm client
-- @param uniqueID string Element identifier.
-- @param order number New draw order. Lower draws earlier.
function ax.elements:SetOrder(uniqueID, order)
    local element = self:Get(uniqueID)
    if ( !element ) then return end

    element.order = tonumber(order) or element.order or 100
    SortElements()
end

--- Returns whether an element is currently enabled.
-- @realm client
-- @param element table Element definition.
-- @param context table Paint context.
-- @return boolean bEnabled Whether the element should be considered for drawing.
function ax.elements:IsEnabled(element, context)
    if ( !istable(element) or element.enabled == false ) then return false end

    if ( isstring(element.option) and element.option != "" and ax.option:Get(element.option, true) == false ) then
        return false
    end

    if ( isfunction(element.ShouldDraw) and element:ShouldDraw(context) == false ) then
        return false
    end

    return true
end

--- Paints all registered HUD elements.
-- @realm client
function ax.elements:PaintHUD()
    if ( ax.option:Get("hud.elements.enabled", true) == false ) then return end

    local client = ax.client
    if ( !ax.util:IsValidPlayer(client) or !client:Alive() ) then return end

    local context = {
        client = client,
        width = ScrW(),
        height = ScrH(),
        frameTime = FrameTime(),
        curTime = CurTime(),
    }

    for i = 1, #self.sorted do
        local element = self.sorted[i].element
        if ( !self:IsEnabled(element, context) ) then continue end

        if ( isfunction(element.Think) ) then
            element:Think(context)
        end

        if ( isfunction(element.Paint) ) then
            element:Paint(context)
        end
    end
end

--- Builds the default interaction trace used by the TargetID element.
-- @realm client
-- @param client Player Local player.
-- @return table trace Hull trace result.
function ax.elements:GetTargetTrace(client)
    local distance = ax.option:Get("hud.targetid.distance", 96)
    distance = math.Clamp(tonumber(distance) or 96, 32, 512)

    return util.TraceHull({
        start = client:GetShootPos(),
        endpos = client:GetShootPos() + client:GetAimVector() * distance,
        filter = client,
        mins = TRACE_MINS,
        maxs = TRACE_MAXS,
        mask = MASK_SHOT,
    })
end

--- Resolves the entity that should be used for display data.
-- @realm client
-- @param entity Entity Traced entity.
-- @return Entity entity Display entity.
function ax.elements:GetDisplayEntity(entity)
    return ax.util:GetPlayerFromAttachedRagdoll(entity) or entity
end

--- Gets the default display text for an entity.
-- @realm client
-- @param entity Entity Display entity.
-- @return string|nil text Display text.
-- @return Color|nil color Display color.
-- @return boolean|nil bShouldFlash Whether the text should softly flash.
function ax.elements:GetEntityDisplayText(entity)
    local target = entity

    local ragdollOwner = ax.util:GetPlayerFromAttachedRagdoll(entity)
    if ( ax.util:IsValidPlayer(ragdollOwner) ) then
        target = ragdollOwner
    end

    if ( ax.util:IsValidPlayer(target) ) then
        local name = target:Nick()
        local color = team.GetColor(target:Team())
        local bShouldFlash = false

        local returnName, returnColor, returnShouldFlash = hook.Run("GetPlayerDisplayName", target, name)
        if ( returnName != nil and isstring(returnName) ) then
            name = returnName
        end

        if ( returnColor != nil and IsColor(returnColor) ) then
            color = returnColor
        end

        if ( returnShouldFlash == true ) then
            bShouldFlash = true
        end

        return name, color, bShouldFlash
    elseif ( entity:GetClass() == "ax_item" ) then
        local itemTable = entity:GetItemTable()
        if ( itemTable ) then
            return itemTable:GetName()
        end
    elseif ( entity.GetDisplayName ) then
        return entity:GetDisplayName()
    end
end

--- Gets the default description for a TargetID entity.
-- @realm client
-- @param entity Entity Display entity.
-- @return string|nil description Description text.
function ax.elements:GetEntityDisplayDescription(entity)
    local target = self:GetDisplayEntity(entity)
    local itemTable = target.GetItemTable and target:GetItemTable() or nil

    if ( itemTable and itemTable:GetDescription() ) then
        return itemTable:GetDescription()
    elseif ( target.GetCharacter and target:GetCharacter() ) then
        local targetChar = target:GetCharacter()
        local localChar = ax.util:IsValidPlayer(ax.client) and ax.client:GetCharacter() or nil
        if ( istable(localChar) and ax.recognition ) then
            return ax.recognition:GetDisplayDescription(localChar, targetChar:GetID())
        end
    elseif ( target.GetDisplayDescription ) then
        return target:GetDisplayDescription()
    end
end

--- Draws centered text with a soft shadow.
-- @realm client
-- @param text string Text to draw.
-- @param font string Font name.
-- @param x number Screen X.
-- @param y number Screen Y.
-- @param color Color Text color.
-- @param alpha number Text alpha.
-- @param shadowAlpha number Shadow alpha.
function ax.elements:DrawText(text, font, x, y, color, alpha, shadowAlpha)
    draw.SimpleText(text, font, x + 1, y + 1, ColorAlpha(DEFAULT_SHADOW_COLOR, shadowAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(text, font, x, y, ColorAlpha(color, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

--- Draws wrapped centered lines and returns the updated line count.
-- @realm client
-- @param text string Text to wrap and draw.
-- @param font string Font name.
-- @param x number Screen X.
-- @param y number Starting Y.
-- @param color Color Text color.
-- @param alpha number Base alpha.
-- @param lineCount number Current line count.
-- @param maxWidth number Maximum wrapped width.
-- @param lineSpacing number Vertical line spacing.
-- @return number lineCount Updated line count.
function ax.elements:DrawWrappedLines(text, font, x, y, color, alpha, lineCount, maxWidth, lineSpacing)
    if ( !isstring(text) or text == "" ) then return lineCount end

    local segments = string.Explode("\n", text)
    for i = 1, #segments do
        local segment = segments[i]
        local wrapped = ax.util:GetWrappedText(segment, font, maxWidth)

        for j = 1, #wrapped do
            local line = wrapped[j]
            lineCount = lineCount + 1

            local yPos = y + lineSpacing * lineCount
            self:DrawText(line, font, x, yPos, color, alpha / 2, alpha / 4)
        end
    end

    return lineCount
end

--- Creates a simple TargetID line drawing context.
-- Modules and schemas can use this to add tooltip lines without managing fonts,
-- wrapping, shadows, alpha, or line counters manually.
-- @realm client
-- @param x number Screen X.
-- @param y number Screen Y.
-- @param alpha number Current TargetID alpha.
-- @param data table|nil Optional overrides: font, maxWidth, lineSpacing, lines.
-- @return table context TargetID drawing context.
function ax.elements:CreateTargetContext(x, y, alpha, data)
    data = istable(data) and data or {}

    return {
        x = x,
        y = y,
        alpha = alpha,
        lineCount = tonumber(data.lineCount) or 0,
        font = data.font or ax.option:Get("hud.targetid.description_font", "ax.small"),
        maxWidth = data.maxWidth or ax.util:ScreenScale(ax.option:Get("hud.targetid.max_width", 128)),
        lineSpacing = data.lineSpacing or ax.util:ScreenScaleH(ax.option:Get("hud.targetid.line_spacing", 6)),
        lines = istable(data.lines) and data.lines or {},
    }
end

--- Adds one line to a TargetID context.
-- @realm client
-- @param context table TargetID context from CreateTargetContext.
-- @param text string Text to draw. Empty text is ignored.
-- @param color Color|nil Text color.
-- @param data table|nil Optional overrides: font, maxWidth, bNoWrap.
-- @return table context The same context for chaining.
-- @usage ax.elements:AddTargetLine(context, "Locked", Color(200, 80, 80))
function ax.elements:AddTargetLine(context, text, color, data)
    if ( !istable(context) ) then return context end
    if ( !isstring(text) or text == "" ) then return context end

    data = istable(data) and data or {}

    context.lines[#context.lines + 1] = {
        text = text,
        color = IsColor(color) and color or DEFAULT_TEXT_COLOR,
        font = data.font,
        maxWidth = data.maxWidth,
        bNoWrap = data.bNoWrap == true,
    }

    return context
end

--- Adds multiple TargetID lines from simple tables.
-- Each line supports text, color, font, maxWidth, and bNoWrap.
-- @realm client
-- @param context table TargetID context from CreateTargetContext.
-- @param lines table Array of line definitions.
-- @return table context The same context for chaining.
function ax.elements:AddTargetLines(context, lines)
    if ( !istable(context) or !istable(lines) ) then return context end

    for i = 1, #lines do
        local line = lines[i]
        if ( isstring(line) ) then
            self:AddTargetLine(context, line)
        elseif ( istable(line) ) then
            self:AddTargetLine(context, line.text, line.color, line)
        end
    end

    return context
end

--- Builds TargetID line definitions from a hook result.
-- Use this from modules/schemas when you want to provide tooltip lines without
-- handling any drawing yourself:
-- ```lua
-- function MODULE:GetTargetIDLines(entity)
--     if ( !entity:IsDoor() ) then return end
--
--     return {
--         { text = "Locked", color = Color(200, 80, 80) },
--         { text = "Owned by you", color = Color(100, 200, 100) },
--     }
-- end
-- ```
-- @realm client
-- @param entity Entity Display entity.
-- @return table|nil lines Array of line definitions.
function GM:GetTargetIDLines(entity)
end

--- Adds lines returned from the GetTargetIDLines hook to a context.
-- @realm client
-- @param context table TargetID context from CreateTargetContext.
-- @param entity Entity Display entity.
-- @return table context The same context for chaining.
function ax.elements:AddHookedTargetLines(context, entity)
    if ( !istable(context) or !IsValid(entity) ) then return context end

    local lines = hook.Run("GetTargetIDLines", entity)
    if ( isstring(lines) ) then
        self:AddTargetLine(context, lines)
    elseif ( istable(lines) ) then
        self:AddTargetLines(context, lines)
    end

    return context
end

--- Draws all queued TargetID lines and returns the updated line count.
-- @realm client
-- @param context table TargetID context from CreateTargetContext.
-- @return number lineCount Final line count.
function ax.elements:DrawTargetLines(context)
    if ( !istable(context) ) then return 0 end

    for i = 1, #context.lines do
        local line = context.lines[i]
        local font = line.font or context.font
        local maxWidth = line.maxWidth or context.maxWidth

        if ( line.bNoWrap ) then
            context.lineCount = context.lineCount + 1
            local yPos = context.y + context.lineSpacing * context.lineCount
            self:DrawText(line.text, font, context.x, yPos, line.color, context.alpha / 2, context.alpha / 4)
        else
            context.lineCount = self:DrawWrappedLines(line.text, font, context.x, context.y, line.color, context.alpha, context.lineCount, maxWidth, context.lineSpacing)
        end
    end

    return context.lineCount
end

--- Draws default TargetID extra lines for descriptions and entity extras.
-- @realm client
-- @param entity Entity Display entity.
-- @param x number Screen X.
-- @param y number Screen Y.
-- @param alpha number Current alpha.
function ax.elements:PaintTargetIDExtra(entity, x, y, alpha)
    local target = self:GetDisplayEntity(entity)
    local context = self:CreateTargetContext(x, y, alpha)

    if ( ax.option:Get("hud.targetid.show_descriptions", true) ) then
        local desc = self:GetEntityDisplayDescription(target)
        self:AddTargetLine(context, desc)
    end

    if ( ax.option:Get("hud.targetid.show_extras", true) and target.GetDisplayDescriptionExtras ) then
        local extras = target:GetDisplayDescriptionExtras()
        if ( istable(extras) ) then
            self:AddTargetLines(context, extras)
        end
    end

    self:AddHookedTargetLines(context, target)

    self:DrawTargetLines(context)
end

--- Paints the default TargetID HUD element.
-- @realm client
-- @param context table Paint context.
function ax.elements:PaintTargetID(context)
    local client = context.client
    local trace = self:GetTargetTrace(client)
    local target = trace.Entity

    if ( IsValid(target) ) then
        local entIndex = target:EntIndex()
        self.targetData[entIndex] = self.targetData[entIndex] or {
            lastSeen = 0,
            alpha = 0,
        }

        self.targetData[entIndex].lastSeen = context.curTime
    end

    local visibleDelay = ax.option:Get("hud.targetid.visible_delay", 0.1)
    local fadeInSpeed = ax.option:Get("hud.targetid.fade_speed_in", 10)
    local fadeOutSpeed = ax.option:Get("hud.targetid.fade_speed_out", 10)
    local positionSpeed = ax.option:Get("hud.targetid.position_speed", 20)
    local font = ax.option:Get("hud.targetid.font", "ax.small.bold")

    for entIndex, data in pairs(self.targetData) do
        local ent = Entity(entIndex)
        if ( !IsValid(ent) ) then
            self.targetData[entIndex] = nil
            continue
        end

        local timeSinceSeen = context.curTime - data.lastSeen
        if ( timeSinceSeen < visibleDelay ) then
            data.alpha = ax.ease:Lerp("InOutQuad", context.frameTime * fadeInSpeed, data.alpha, 255)
        else
            data.alpha = ax.ease:Lerp("OutQuad", context.frameTime * fadeOutSpeed, data.alpha, 0)
        end

        if ( data.alpha <= 1 ) then
            data.x = nil
            data.y = nil
            continue
        end

        local displayEntity = self:GetDisplayEntity(ent)
        local displayText, displayColor, bShouldFlash = hook.Run("GetEntityDisplayText", displayEntity)
        if ( !isstring(displayText) or displayText == "" ) then continue end

        local pos = ent:LocalToWorld(ent:OBBCenter())
        local ragdollOwner = ax.util:GetPlayerFromAttachedRagdoll(ent)
        if ( ax.util:IsValidPlayer(ent) or ax.util:IsValidPlayer(ragdollOwner) ) then
            pos = pos + Vector(0, 0, ax.option:Get("hud.targetid.player_offset", 16))
        end

        local screenPos = pos:ToScreen()
        local x = screenPos.x
        local y = screenPos.y

        data.x = ax.ease:Lerp("InOutQuad", context.frameTime * positionSpeed, data.x or x, x)
        data.y = ax.ease:Lerp("InOutQuad", context.frameTime * positionSpeed, data.y or y, y)

        if ( !IsColor(displayColor) ) then
            displayColor = DEFAULT_TEXT_COLOR
        end

        local nameColor = displayColor
        if ( bShouldFlash ) then
            local flashFraction = 0.5 + 0.5 * math.sin(context.curTime * ax.option:Get("hud.targetid.flash_speed", 0.75))
            nameColor = Color(
                ax.ease:Lerp("Linear", flashFraction, displayColor.r, 255),
                ax.ease:Lerp("Linear", flashFraction, displayColor.g, 255),
                ax.ease:Lerp("Linear", flashFraction, displayColor.b, 255)
            )
        end

        self:DrawText(displayText, font, data.x, data.y, nameColor, data.alpha, data.alpha / 2)
        self:PaintTargetIDExtra(displayEntity, data.x, data.y, data.alpha)
    end
end

ax.elements:Register("targetID", {
    order = 100,
    option = "hud.targetid.enabled",
    Paint = function(self, context)
        ax.elements:PaintTargetID(context)
    end,
})