--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Toast-style notifications displayed above all VGUI.
-- Renders at the bottom-center in GM:PostRenderVGUI so it always draws on top.
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
        local dur = tonumber(length) or (ax.config:Get("notification.defaultLength", 5) or 5)

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
    ax.notification.queue = {}
    ax.notification.active = {}

    -- style defaults (can be overridden by config where noted)
    ax.notification.maxVisible = math.max(1, math.floor(ScrH() / 128)) -- max toasts visible at once
    ax.notification.paddingX = ScreenScale(4)
    ax.notification.paddingY = ScreenScaleH(4)
    ax.notification.spacing = ScreenScale(4)
    ax.notification.font = "ax.regular"
    ax.notification.maxWidthFrac = 0.5
    ax.notification.inTime = 0.25
    ax.notification.outTime = 0.25
    ax.notification.easing = "OutCubic"

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
        if ( !ax.config:Get("notification.enabled", true) ) then return end

        table.insert(self.queue, {
            text = tostring(text or ""),
            type = type or "generic",
            length = tonumber(length) or (ax.config:Get("notification.defaultLength", 5) or 5)
        })

        self:Next()
    end

    --- Promote queued items into active list respecting maxVisible.
    function ax.notification:Next()
        local maxVisible = self.maxVisible
        while (#self.active < maxVisible) and (#self.queue > 0) do
            local data = table.remove(self.queue, 1)
            self:Show(data)
        end
    end

    --- Create and animate a toast into view.
    -- @tparam table data
    function ax.notification:Show(data)
        local sw, sh = ScrW(), ScrH()
        local maxWFrac = (ax.config:Get("notification.maxWidthFrac", self.maxWidthFrac)) or self.maxWidthFrac
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
        local h = clamp(#lines * th + self.paddingY * 2, th + self.paddingY * 2, math.floor(sh * 0.5))

        local p = vgui.Create("Panel")
        p:SetVisible(false)
        p.alpha = 255
        p.offset = 24
        p.stack = p.stack or 0

        local growTime = 0.25
        local waitTime = 0.5
        local slideTime = 0.5
        local outTime = 0.5
        local outFadeTime = 0.12

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

            -- animation internal
            phase = "intro-grow", -- intro-grow -> intro-wait -> intro-slide -> visible -> out-eat -> done
            phaseStart = CurTime(),
            growTime = growTime,
            waitTime = waitTime,
            slideTime = slideTime,
            outTime = outTime,

            barFill = 0, -- 0..1 (for grow)
            coverW = w, -- pixels width of matte cover that hides text (starts full until reveal)
            textAlpha = 0, -- 0..255 (text appears under the bar)
            outFadeTime = outFadeTime
        }

        -- play configured sound immediately when the intro begins
        ax.client:EmitSound("parallax/ui/notification_in.wav", 60, math.random(95, 105), 0.4)

        -- animate stack/offset with motion to preserve previous behavior
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

    --- Begin fade-out and removal of a toast.
    -- @tparam number idx Active index
    function ax.notification:Close(idx)
        local t = self.active[idx]
        if ( !t or !IsValid(t.panel) or t.closing ) then return end

        -- start outro sequence: expand the matte cover to eat the text
        t.closing = true
        t.phase = "out-eat"
        t.phaseStart = CurTime()
        ax.client:EmitSound("parallax/ui/notification_out.wav", 60, math.random(95, 105), 0.4)
    end

    --- Draw the active notifications. Called in PostRenderVGUI.
    function ax.notification:Render()
        if ( !ax.config:Get("notification.enabled", true) ) then return end
        if ( #self.active == 0 ) then return end

        local sw, sh = ScrW(), ScrH()
        local baseY = sh - 24
        local cx = math.floor(sw * 0.5)

        surface.SetFont(self.font)

        for i = #self.active, 1, -1 do
            local t = self.active[i]
            local p = t.panel
            if ( !IsValid(p) ) then
                table.remove(self.active, i)
            else
                -- Auto-close if visible time elapsed and not already closing
                if ( t.phase == "visible" and (CurTime() - t.phaseStart) >= t.length and !t.closing ) then
                    self:Close(i)
                end

                local stack = p.stack or 0
                local offset = p.offset or 0

                local fullW, h = t.width, t.height
                local x = cx - math.floor(fullW / 2)
                local y = baseY - stack - offset - h

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
                local ty = y + self.paddingY
                local tx = x + self.paddingX
                local textA = clamp(t.textAlpha or 0, 0, 255)
                for k = 1, #t.lines do
                    local line = t.lines[k]
                    draw.SimpleText(line, self.font, tx, ty, Color(240, 240, 240, textA), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    ty = ty + t.lineHeight
                end

                -- draw the matte foreground rectangle driven by barFill (this is the element that shrinks to reveal)
                local fillW = math.floor(fullW * (t.barFill or 0))
                if ( fillW > 0 ) then
                    if ( t.shrinkAnchorRight ) then
                        -- draw anchored to the right so the left edge moves right as fillW decreases
                        draw.RoundedBox(0, x + (fullW - fillW), y, fillW, h, col)
                    else
                        draw.RoundedBox(0, x, y, fillW, h, col)
                    end
                end

                -- draw the outro matte cover (left portion) which hides the text; coverW==0 means fully revealed
                if ( t.coverW and t.coverW > 0 ) then
                    draw.RoundedBox(0, x, y, t.coverW, h, col)
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

    -- Draw above all VGUI
    function GM:PostRenderVGUI()
        ax.notification:Render()
    end

    -- Receive server-sent toasts
    net.Receive("ax.notification.push", function()
        local text = net.ReadString()
        local ntype = net.ReadString()
        local length = net.ReadFloat()

        ax.notification:Add(text, ntype, length)
    end)
end
