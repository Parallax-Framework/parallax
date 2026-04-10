--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Minimal stacked notifications rendered above all VGUI.
-- @module ax.notification

ax.notification = ax.notification or {}

ax.notification.enums = {}
ax.notification.enums.ERROR = 1
ax.notification.enums.WARNING = 2
ax.notification.enums.INFO = 3
ax.notification.enums.SUCCESS = 4


if ( SERVER ) then
    --- Send a notification to one or more players.
    -- @realm server
    -- @tparam Player|Player[]|nil target Player entity, list of players, or nil for broadcast
    -- @tparam string text Message text
    -- @tparam[opt="info"] string type Type: error|warning|info|success
    -- @tparam[opt] number length Seconds to show (falls back to config default)
    function ax.notification:Send(target, text, type, length)
        local message = tostring(text or "")
        if ( message == "" ) then return end

        local players
        if ( target == nil ) then
            players = player.GetAll()
        elseif ( istable(target) ) then
            players = {}
            for i = 1, #target do
                local client = target[i]
                if ( ax.util:IsValidPlayer(client) ) then
                    players[#players + 1] = client
                end
            end
        elseif ( ax.util:IsValidPlayer(target) ) then
            players = { target }
        else
            return
        end

        local duration = tonumber(length) or (ax.config:Get("notification.length.default", 5) or 5)
        ax.net:Start(players, "notification.push", message, type or self.enums.INFO, duration)

        ax.util:PrintDebug("Notification sent to", #players, "players:", message)
    end
end

if ( CLIENT ) then
    ax.notification.active = ax.notification.active or {}
    ax.notification.font = "ax.small.bold"
    ax.notification.sounds = {
        [ax.notification.enums.ERROR] = "parallax/ui/notifications/error.wav",
        [ax.notification.enums.WARNING] = "parallax/ui/notifications/hint.wav",
        [ax.notification.enums.INFO] = "parallax/ui/notifications/generic.wav",
        [ax.notification.enums.SUCCESS] = "parallax/ui/notifications/generic.wav",
    }

    ax.notification.enums.STATE_HIDDEN = 1
    ax.notification.enums.STATE_VISIBLE = 2
    ax.notification.enums.STATE_EXITING = 3


    ax.notification.style = {
        width = 340,
        minHeight = 44,
        padding = 12,
        accentWidth = 5,
        accentGap = 10,
        gap = 8,
        lineSpacing = 3,
        radius = 6,
        marginTop = 24,
        marginRight = 24,
        maxVisible = 5,
        enterTime = 0.22,
        exitTime = 0.18,
        slideDistance = 22,
        reflowSpeed = 14,
        backgroundColor = Color(18, 18, 22, 235),
        textColor = Color(245, 245, 245, 255),
    }

    ax.notification.typeColors = {
        [ax.notification.enums.ERROR] = Color(220, 70, 70),
        [ax.notification.enums.WARNING] = Color(230, 170, 60),
        [ax.notification.enums.INFO] = Color(80, 150, 230),
        [ax.notification.enums.SUCCESS] = Color(70, 180, 110),
    }

    local function Clamp(value, minValue, maxValue)
        return math.min(math.max(value, minValue), maxValue)
    end

    local function LerpFrame(speed, current, target)
        local fraction = Clamp(FrameTime() * speed, 0, 1)
        return Lerp(fraction, current, target)
    end

    local function EaseOutCubic(value)
        return 1 - math.pow(1 - value, 3)
    end

    local function EaseInCubic(value)
        return value * value * value
    end

    local function NormalizeType(notificationType)
        if ( notificationType == "error" ) then return ax.notification.enums.ERROR end
        if ( notificationType == "warning" ) then return ax.notification.enums.WARNING end
        if ( notificationType == "success" ) then return ax.notification.enums.SUCCESS end
        return ax.notification.enums.INFO
    end

    local function PlayNotificationSound(notificationType)
        if ( !ax.option:Get("notification.sounds", true) ) then
            return
        end

        local soundPath = ax.notification.sounds[notificationType] or ax.notification.sounds[ax.notification.enums.INFO]
        if ( !isstring(soundPath) or soundPath == "" ) then
            return
        end

        pcall(surface.PlaySound, soundPath)
    end

    local function BuildLayout(notification, scale)
        local style = ax.notification.style
        local width = math.floor(style.width * scale)
        local minHeight = math.floor(style.minHeight * scale)
        local padding = math.floor(style.padding * scale)
        local accentWidth = math.max(1, math.floor(style.accentWidth * scale))
        local accentGap = math.floor(style.accentGap * scale)
        local lineSpacing = math.floor(style.lineSpacing * scale)

        local contentWidth = width - (padding * 2) - accentWidth - accentGap
        contentWidth = math.max(contentWidth, 60)

        surface.SetFont(ax.notification.font)
        local _, lineHeight = surface.GetTextSize("Hg")
        local formattedMessage = ax.chat:Format(notification.message)
        local lines = ax.util:GetWrappedText(formattedMessage, ax.notification.font, contentWidth) or { formattedMessage }

        local textHeight = lineHeight * #lines
        if ( #lines > 1 ) then
            textHeight = textHeight + (lineSpacing * (#lines - 1))
        end

        local height = math.max(minHeight, textHeight + (padding * 2))

        notification.lines = lines
        notification.lineHeight = lineHeight
        notification.textHeight = textHeight
        notification.width = width
        notification.height = height
        notification.padding = padding
        notification.accentWidth = accentWidth
        notification.accentGap = accentGap
        notification.lineSpacing = lineSpacing
        notification.radius = math.max(0, math.floor(style.radius * scale))
        notification.accentColor = ax.notification.typeColors[notification.type] or ax.notification.typeColors[ax.notification.enums.INFO]
    end

    local function StartExit(notification)
        if ( notification.state == ax.notification.enums.STATE_HIDDEN ) then return end

        notification.state = ax.notification.enums.STATE_EXITING
        notification.exitStartTime = CurTime()
    end

    local function PruneOverflow()
        local maxVisible = ax.notification.style.maxVisible
        while ( #ax.notification.active > maxVisible ) do
            table.remove(ax.notification.active, #ax.notification.active)
        end
    end

    --- Add a new notification.
    -- @realm client
    -- @tparam string text Message text
    -- @tparam[opt="info"] string type Type: error|warning|info|success
    -- @tparam[opt] number length Seconds to remain visible
    function ax.notification:Add(text, type, length)
        if ( !ax.option:Get("notification.enabled", true) ) then return end

        local message = tostring(text or "")
        if ( message == "" ) then return end

        local duration = tonumber(length) or (ax.option:Get("notification.length.default", 5) or 5)
        local now = CurTime()

        local notification = {
            message = message,
            type = NormalizeType(type),
            startTime = now,
            duration = math.max(0.1, duration),
            state = ax.notification.enums.STATE_ENTERING,
            y = 0,
            targetY = 0,
        }

        table.insert(self.active, 1, notification)
        PlayNotificationSound(notification.type)
        PruneOverflow()
    end

    --- Clear all active notifications.
    function ax.notification:Clear()
        self.active = {}
    end

    --- Render stacked notifications.
    function ax.notification:Render()
        if ( !ax.option:Get("notification.enabled", true) ) then return end
        if ( #self.active == 0 ) then return end

        local style = self.style
        local scale = Clamp(ax.option:Get("notification.scale", 1), 0.5, 2)
        local position = tostring(ax.option:Get("notification.position", "topright") or "topright")
        if ( position != "topright" and position != "topcenter" ) then
            position = "topright"
        end

        local baseX
        if ( position == "topcenter" ) then
            baseX = ScrW() * 0.5
        else
            baseX = ScrW() - math.floor(style.marginRight * scale)
        end

        local baseY = math.floor(style.marginTop * scale)
        local backgroundColor = style.backgroundColor
        local textColor = style.textColor

        local stackY = 0
        local now = CurTime()

        for i = 1, #self.active do
            local notification = self.active[i]
            BuildLayout(notification, scale)

            notification.targetY = stackY
            notification.y = LerpFrame(style.reflowSpeed, notification.y or stackY, notification.targetY)

            if ( notification.state != ax.notification.enums.STATE_EXITING and (now - notification.startTime) >= notification.duration ) then
                StartExit(notification)
            end

            local lifeTime = now - notification.startTime
            local alpha = 255
            local slideOffset = 0

            if ( notification.state == ax.notification.enums.STATE_ENTERING ) then
                local fraction = Clamp(lifeTime / style.enterTime, 0, 1)
                local eased = EaseOutCubic(fraction)
                alpha = math.floor(255 * eased)
                slideOffset = (1 - eased) * (style.slideDistance * scale)

                if ( fraction >= 1 ) then
                    notification.state = ax.notification.enums.STATE_VISIBLE
                    alpha = 255
                    slideOffset = 0
                end
            elseif ( notification.state == ax.notification.enums.STATE_EXITING ) then
                local exitElapsed = now - (notification.exitStartTime or now)
                local fraction = Clamp(exitElapsed / style.exitTime, 0, 1)
                local eased = EaseInCubic(fraction)
                alpha = math.floor(255 * (1 - eased))
                slideOffset = eased * (style.slideDistance * scale)

                if ( fraction >= 1 ) then
                    notification.state = ax.notification.enums.STATE_DONE
                end
            end

            notification.alpha = alpha
            notification.slideOffset = slideOffset

            stackY = stackY + notification.height + math.floor(style.gap * scale)
        end

        for i = #self.active, 1, -1 do
            if ( self.active[i].state == ax.notification.enums.STATE_DONE ) then
                table.remove(self.active, i)
            end
        end

        for i = #self.active, 1, -1 do
            local notification = self.active[i]
            local alpha = Clamp(notification.alpha or 255, 0, 255)
            if ( alpha <= 0 ) then continue end

            local width = notification.width
            local height = notification.height
            local y = baseY + notification.y

            local x
            if ( position == "topcenter" ) then
                x = baseX - (width * 0.5) + (notification.slideOffset or 0)
            else
                x = baseX - width + (notification.slideOffset or 0)
            end

            local drawBackground = Color(backgroundColor.r, backgroundColor.g, backgroundColor.b, math.floor((backgroundColor.a or 255) * (alpha / 255)))
            local drawText = Color(textColor.r, textColor.g, textColor.b, alpha)
            local accentColor = notification.accentColor
            local drawAccent = Color(accentColor.r, accentColor.g, accentColor.b, alpha)

            ax.render.Draw(notification.radius, x, y, width, height, drawBackground)
            ax.render.Draw(0, x, y, notification.accentWidth, height, drawAccent)

            local textX = x + notification.padding + notification.accentWidth + notification.accentGap
            local textY

            if ( #notification.lines == 1 ) then
                textY = y + ((height - notification.lineHeight) * 0.5)
            else
                textY = y + notification.padding
            end

            for lineIndex = 1, #notification.lines do
                draw.SimpleText(notification.lines[lineIndex], self.font, textX, textY, drawText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                textY = textY + notification.lineHeight + notification.lineSpacing
            end
        end
    end

    ax.net:Hook("notification.push", function(text, notificationType, length)
        ax.notification:Add(text, notificationType, length)
    end)
end
