--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Half-Life Alyx style notifications displayed above all VGUI.
-- Renders at the bottom-center in GM:PostRender so it always draws on top.
-- Animations are driven by ax.motion for smooth slide/fade and stacking.
-- @module ax.notification

ax.notification = ax.notification or {}

-- Server-side networking and API
if ( SERVER ) then
    util.AddNetworkString("ax.notification.push")

    --- Send a notification to one or more players.
    -- @realm server
    -- @tparam Player|Player[]|nil target Player entity, list of players, or nil for broadcast
    -- @tparam string text Message text
    -- @tparam[opt="generic"] string type Type: generic|info|success|warning|error
    -- @tparam[opt] number length Seconds to show (falls back to config default)
    function ax.notification:Send(target, text, type, length)
        local msg = tostring(text or "")
        if ( msg == "" ) then return end

        local plylist
        if ( target == nil ) then
            plylist = player.GetAll()
        elseif ( istable(target) ) then
            plylist = {}
            for i = 1, #target do
                local p = target[i]
                if ( ax.util:IsValidPlayer(p) ) then plylist[#plylist + 1] = p end
            end
        elseif ( ax.util:IsValidPlayer(target) ) then
            plylist = { target }
        else
            return
        end

        local t = type or "generic"
        local dur = tonumber(length) or (ax.config:Get("notificationDefaultLength", 5) or 5)

        net.Start("ax.notification.push")
            net.WriteString(msg)
            net.WriteString(t)
            net.WriteFloat(dur)
        net.Send(plylist)

        ax.util:PrintDebug("Notification sent to", #plylist, "players:", msg)
    end
end

-- Client-side implementation
if ( CLIENT ) then
    sound.Add({
        name = "parallax.ui.notification.in",
        channel = CHAN_AUTO,
        volume = 0.4,
        level = 60,
        pitch = {95, 105},
        sound = "parallax/ui/notification_in.wav"
    })

    sound.Add({
        name = "parallax.ui.notification.out",
        channel = CHAN_AUTO,
        volume = 0.4,
        level = 60,
        pitch = {95, 105},
        sound = "parallax/ui/notification_out.wav"
    })

    ax.notification.queue = {}
    ax.notification.active = {}

    -- style defaults (can be overridden by config where noted)
    ax.notification.maxVisible = math.max(1, math.floor(ScrH() / 64)) -- max toasts visible at once
    ax.notification.font = "ax.regular.bold"
    ax.notificationMaxWidthFraction = 0.5
    ax.notificationInTime = 0.25
    ax.notificationOutTime = 0.25
    ax.notificationEasing = "OutCubic"

    local function clamp(v, a, b) return math.min(math.max(v, a), b) end

    -- Use util helpers for wrapped text measurement
    local function getWrapped(text, font, maxW)
        return ax.util:GetWrappedText(text, font, maxW) or { tostring(text or "") }
    end

    -- easing helpers (cubic)
    local function EaseOutCubic(t)
        return 1 - math.pow(1 - t, 3)
    end

    local function EaseInCubic(t)
        return t * t * t
    end

    --- Add a new notification to the queue.
    -- @realm client
    -- @tparam string text The message to display.
    -- @tparam[opt="generic"] string type One of: generic, info, success, warning, error
    -- @tparam[opt=5] number length Seconds to remain visible (excluding animation).
    function ax.notification:Add(text, type, length)
        if ( !ax.option:Get("notificationEnabled", true) ) then return end

        ax.notification.paddingX = ax.util:ScreenScale(16)
        ax.notification.paddingY = ax.util:ScreenScaleH(2)
        ax.notification.spacing = ax.util:ScreenScaleH(2)

        table.insert(self.queue, {
            text = tostring(text or ""),
            type = type or "generic",
            length = tonumber(length) or (ax.option:Get("notificationDefaultLength", 5) or 5)
        })

        self:Next()
    end

    --- Promote queued items into active list respecting maxVisible.
    function ax.notification:Next()
        local maxVisible = self.maxVisible
        while ( #self.active < maxVisible ) and ( self.queue[ 1 ] != nil ) do
            local data = table.remove(self.queue, 1)
            self:Show(data)
        end
    end

    --- Create and animate a toast into view.
    -- @tparam table data
    function ax.notification:Show(data)
        local sw, sh = ScrW(), ScrH()
        local maxWFrac = 0.42 -- Use hardcoded value as intended
        local maxW = math.floor(sw * maxWFrac)

        surface.SetFont(self.font)
        local _, th = surface.GetTextSize("Hg")
        local lines = getWrapped(ax.chat:Format(data.text), self.font, maxW - (self.paddingX * 2))

        local maxLineW = 0
        for i = 1, #lines do
            local lw = surface.GetTextSize(lines[i])
            if ( lw > maxLineW ) then maxLineW = lw end
        end

        local w = clamp(maxLineW + self.paddingX * 2, 64, maxW)
        local h = clamp(#lines * th + self.paddingY * 2, th + self.paddingY * 2, math.floor(sh / 2))

        local p = vgui.Create("Panel")
        p:SetVisible(false)
        p.alpha = 255
        p.offset = 24
        p.stack = p.stack or 0

        local growTime = 0.25
        local waitTime = 0.5
        local slideTime = 0.5
        local outTime = 0.5
        local outFadeTime = 0.25

        local toast = {
            text = data.text,
            type = data.type,
            length = data.length,
            lines = lines,
            width = w,
            height = h,
            lineHeight = th,
            panel = p,
            startTime = CurTime(),
            closing = false,

            phase = "intro-grow",
            phaseStart = CurTime(),
            growTime = growTime,
            waitTime = waitTime,
            slideTime = slideTime,
            outTime = outTime,

            barFill = 0,
            coverW = w,
            textAlpha = 0,
            outFadeTime = outFadeTime
        }

        if ( ax.option:Get("notificationSounds", true) ) then
            ax.client:EmitSound("parallax.ui.notification.in")
        end

        p:Motion(0.25, {
            Easing = "OutQuad",
            Target = { stack = 0 }
        })

        table.insert(self.active, toast)
        self:Layout()
    end

    --- Recompute stacked y-offset targets for active toasts.
    function ax.notification:Layout()
        local y = 0
        for i = 1, #self.active do
            local t = self.active[i]
            local target = y
            y = y + t.height + self.spacing

            if ( IsValid(t.panel) ) then
                t.panel:Motion(0.25, {
                    Easing = "OutQuad",
                    Target = { stack = target }
                })
            end
        end
    end

    function ax.notification:Close(idx)
        local t = self.active[idx]
        if ( !t or !IsValid(t.panel) or t.closing ) then return end

        t.closing = true
        t.phase = "out-eat"
        t.phaseStart = CurTime()
        ax.client:EmitSound("parallax.ui.notification.out")
    end

    function ax.notification:Render()
        if ( !ax.option:Get("notificationEnabled", true) ) then return end
        if ( self.active[ 1 ] == nil ) then return end

        ax.notification.paddingX = ax.util:ScreenScale(16)
        ax.notification.paddingY = ax.util:ScreenScaleH(2)
        ax.notification.spacing = ax.util:ScreenScaleH(2)

        local sw, sh = ScrW(), ScrH()
        local notificationScale = ax.option:Get("notificationScale", 1.0)
        local position = ax.option:Get("notificationPosition", "bottomcenter")

        -- Calculate position based on user preference
        local baseX, baseY, anchorX, anchorY
        if ( position == "topright" ) then
            baseX = sw - self.paddingX
            baseY = ax.util:ScreenScaleH(32)
            anchorX = TEXT_ALIGN_RIGHT
            anchorY = 1 -- grow downward
        elseif ( position == "topleft" ) then
            baseX = self.paddingX
            baseY = ax.util:ScreenScaleH(32)
            anchorX = TEXT_ALIGN_LEFT
            anchorY = 1 -- grow downward
        elseif ( position == "topcenter" ) then
            baseX = sw / 2
            baseY = ax.util:ScreenScaleH(32)
            anchorX = TEXT_ALIGN_CENTER
            anchorY = 1 -- grow downward
        elseif ( position == "bottomright" ) then
            baseX = sw - self.paddingX
            baseY = sh - ax.util:ScreenScaleH(32)
            anchorX = TEXT_ALIGN_RIGHT
            anchorY = -1 -- grow upward
        elseif ( position == "bottomleft" ) then
            baseX = self.paddingX
            baseY = sh - ax.util:ScreenScaleH(32)
            anchorX = TEXT_ALIGN_LEFT
            anchorY = -1 -- grow upward
        else -- bottomcenter (default behavior)
            baseX = sw / 2
            baseY = sh - ax.util:ScreenScaleH(32)
            anchorX = TEXT_ALIGN_CENTER
            anchorY = -1 -- grow upward
        end

        surface.SetFont(self.font)

        for i = #self.active, 1, -1 do
            local t = self.active[i]
            local p = t.panel
            if ( !IsValid(p) ) then
                table.remove(self.active, i)
            else
                if ( t.phase == "visible" and (CurTime() - t.phaseStart) >= t.length and !t.closing ) then
                    self:Close(i)
                end

                local stack = p.stack or 0
                local offset = p.offset or 0

                local fullW, h = t.width * notificationScale, t.height * notificationScale

                -- Position based on anchor
                local x, y
                if ( anchorX == TEXT_ALIGN_RIGHT ) then
                    x = baseX - fullW
                elseif ( anchorX == TEXT_ALIGN_CENTER ) then
                    x = baseX - (fullW / 2)
                else -- TEXT_ALIGN_LEFT
                    x = baseX
                end

                if ( anchorY == 1 ) then -- growing downward
                    y = baseY + (stack + offset)
                else -- growing upward
                    y = baseY - (stack + offset + h)
                end

                -- Progress logic per-phase
                local now = CurTime()
                local elapsed = now - t.phaseStart

                if ( t.phase == "intro-grow" ) then
                    local pfrac = clamp(elapsed / t.growTime, 0, 1)
                    t.barFill = EaseOutCubic(pfrac)
                    t.textAlpha = 0
                    t.coverW = 0
                    if ( pfrac >= 1 ) then
                        t.phase = "intro-wait"
                        t.phaseStart = CurTime()
                    end
                elseif ( t.phase == "intro-wait" ) then
                    if ( elapsed >= t.waitTime ) then
                        t.phase = "intro-slide"
                        t.phaseStart = CurTime()
                    end
                elseif ( t.phase == "intro-slide" ) then
                    local pfrac = clamp(elapsed / t.slideTime, 0, 1)
                    t.barFill = 1 - EaseOutCubic(pfrac)
                    t.textAlpha = math.floor(EaseOutCubic(pfrac) * 255)
                    t.shrinkAnchorRight = true
                    if ( pfrac >= 1 ) then
                        t.phase = "visible"
                        t.phaseStart = CurTime()
                        t.barFill = 0
                        t.coverW = 0
                        t.textAlpha = 255
                        t.shrinkAnchorRight = false
                    end
                elseif ( t.phase == "visible" ) then
                    local _ = true
                elseif ( t.phase == "out-eat" ) then
                    local pfrac = clamp(elapsed / t.outTime, 0, 1)
                    local eatW = math.floor(EaseInCubic(pfrac) * fullW)
                    t.coverW = eatW
                    t.textAlpha = 255
                    if ( pfrac >= 1 ) then
                        t.phase = "out-wait"
                        t.phaseStart = CurTime()
                    end
                elseif ( t.phase == "out-wait" ) then
                    if ( elapsed >= t.waitTime ) then
                        t.phase = "out-reveal"
                        t.phaseStart = CurTime()
                        t.barFill = 1
                        t.coverW = 0
                        t.shrinkAnchorRight = true
                    end
                elseif ( t.phase == "out-reveal" ) then
                    local pfrac = clamp(elapsed / t.slideTime, 0, 1)
                    t.barFill = 1 - EaseOutCubic(pfrac)
                    t.textAlpha = 0
                    t.shrinkAnchorRight = true
                    if ( pfrac >= 1 ) then
                        t.phase = "done"
                        t.phaseStart = CurTime()
                        t.barFill = 0
                        t.coverW = 0
                        t.textAlpha = 0
                        t.shrinkAnchorRight = false
                    end
                end

                -- colored accent / foreground color (matte)
                local col = Color(32, 32, 32)

                -- draw text (render beneath matte foreground). It will be revealed as the foreground shrinks.
                local scaledPaddingX = self.paddingX * notificationScale
                local scaledPaddingY = self.paddingY * notificationScale
                local ty = y + scaledPaddingY
                local tx = x + scaledPaddingX
                local textA = clamp(t.textAlpha or 0, 0, 255)
                for k = 1, #t.lines do
                    local line = t.lines[k]
                    draw.SimpleText(line, self.font, tx, ty, Color(200, 200, 200, textA), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    ty = ty + (t.lineHeight * notificationScale)
                end

                -- draw the matte foreground rectangle driven by barFill (this is the element that shrinks to reveal)
                local fillW = math.floor(fullW * (t.barFill or 0))
                if ( fillW > 0 ) then
                    if ( t.shrinkAnchorRight ) then
                        -- draw anchored to the right so the left edge moves right as fillW decreases
                        ax.render.Draw(0, x + (fullW - fillW), y, fillW, h, col)
                    else
                        ax.render.Draw(0, x, y, fillW, h, col)
                    end
                end

                -- draw the outro matte cover (left portion) which hides the text; coverW==0 means fully revealed
                if ( t.coverW and t.coverW > 0 ) then
                    ax.render.Draw(0, x, y, t.coverW, h, col)
                end

                -- cleanup if done
                if ( t.phase == "done" ) then
                    if ( IsValid(p) ) then p:Remove() end
                    table.remove(self.active, i)
                    ax.notification:Layout()
                    ax.notification:Next()
                end
            end
        end
    end

    --- Clear all queued and active notifications.
    function ax.notification:Clear()
        self.queue = {}

        for i = #self.active, 1, -1 do
            local t = self.active[i]
            if ( t and IsValid(t.panel) ) then t.panel:Remove() end
            table.remove(self.active, i)
        end
    end

    -- Receive server-sent toasts
    net.Receive("ax.notification.push", function()
        local text = net.ReadString()
        local ntype = net.ReadString()
        local length = net.ReadFloat()

        ax.notification:Add(text, ntype, length)
    end)
end
