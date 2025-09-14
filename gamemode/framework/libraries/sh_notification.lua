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
        local dur = tonumber(length) or (ax.config and ax.config.Get and ax.config:Get("notification.defaultLength", 5) or 5)

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
    ax.notification.queue = ax.notification.queue or {}
    ax.notification.active = ax.notification.active or {}

    -- style defaults (can be overridden by config where noted)
    ax.notification.maxVisible = math.max(1, math.floor(ScrH() / 128)) -- max toasts visible at once
    ax.notification.paddingX = ScreenScale(4)
    ax.notification.paddingY = ScreenScaleH(4)
    ax.notification.spacing = ScreenScale(4)
    ax.notification.corner = ScreenScale(2)
    ax.notification.shadow = ScreenScale(2)
    ax.notification.font = "ax.regular"
    ax.notification.maxWidthFrac = 0.42 -- 42% of screen width (can be overridden by config)
    ax.notification.inTime = 0.22
    ax.notification.outTime = 0.20
    ax.notification.easing = "OutCubic"

    ax.notification.colors = {
        generic = Color(32, 32, 32),
        info    = Color(0, 134, 255),
        success = Color(46, 204, 113),
        warning = Color(241, 196, 15),
        error   = Color(231, 76, 60)
    }

    local function clamp(v, a, b) return math.min(math.max(v, a), b) end

    -- Use util helpers for wrapped text measurement
    local function getWrapped(text, font, maxW)
        return ax.util:GetWrappedText(text, font, maxW) or { tostring(text or "") }
    end

    --- Add a new notification to the queue.
    -- @realm client
    -- @tparam string text The message to display.
    -- @tparam[opt="generic"] string type One of: generic, info, success, warning, error
    -- @tparam[opt=5] number length Seconds to remain visible (excluding animation).
    function ax.notification:Add(text, type, length)
        if ( ax.config and ax.config.Get and !ax.config:Get("notification.enabled", true) ) then return end

        table.insert(self.queue, {
            text = tostring(text or ""),
            type = type or "generic",
            length = tonumber(length) or (ax.config and ax.config.Get and ax.config:Get("notification.defaultLength", 5) or 5)
        })

        self:Next()
    end

    --- Promote queued items into active list respecting maxVisible.
    function ax.notification:Next()
        local maxVisible = (ax.config and ax.config.Get and ax.config:Get("notification.maxVisible", self.maxVisible)) or self.maxVisible
        while (#self.active < maxVisible) and (#self.queue > 0) do
            local data = table.remove(self.queue, 1)
            self:Show(data)
        end
    end

    --- Create and animate a toast into view.
    -- @tparam table data
    function ax.notification:Show(data)
        local sw, sh = ScrW(), ScrH()
        local maxWFrac = (ax.config and ax.config.Get and ax.config:Get("notification.maxWidthFrac", self.maxWidthFrac)) or self.maxWidthFrac
        local maxW = math.floor(sw * maxWFrac)

        surface.SetFont(self.font)
        local _, th = surface.GetTextSize("Hg")
        local lines = getWrapped(data.text, self.font, maxW - (self.paddingX * 2))

        local maxLineW = 0
        for i = 1, #lines do
            local lw = surface.GetTextSize(lines[i])
            if ( lw > maxLineW ) then maxLineW = lw end
        end

        local w = clamp(maxLineW + self.paddingX * 2, 64, maxW)
        local h = clamp(#lines * th + self.paddingY * 2, th + self.paddingY * 2, math.floor(sh * 0.5))

        local p = vgui.Create("Panel")
        p:SetVisible(false) -- property bag for ax.motion
        p.alpha = 0
        p.offset = 24 -- slide up from bottom
        p.stack = p.stack or 0

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
            closing = false
        }

        local easing = ax.config:Get("notification.easing", self.easing)
        local inTime = ax.config:Get("notification.inTime", self.inTime)

        -- play configured sound immediately when the intro begins
        local soundPath = ax.config:Get("notification.sound", "ui/hint.wav")
        local lp = LocalPlayer()
        if ( IsValid(lp) and lp.EmitSound ) then
            lp:EmitSound(soundPath)
        else
            surface.PlaySound(soundPath)
        end

        -- animate in
        p:Motion(inTime, {
            Easing = easing,
            Target = { alpha = 255, offset = 0 }
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
                t.panel:Motion(0.18, {
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

        t.closing = true
        local easing = ax.config:Get("notification.easing", self.easing)
        local outTime = ax.config:Get("notification.outTime", self.outTime)

        t.panel:Motion(outTime, {
            Easing = easing,
            Target = { alpha = 0, offset = 16 }
        })

        local panel = t.panel
        timer.Simple(outTime + 0.01, function()
            if ( !t ) then return end
            if ( IsValid(panel) ) then panel:Remove() end
            table.remove(self.active, idx)
            ax.notification:Layout()
            ax.notification:Next()
        end)
    end

    --- Draw the active notifications. Called in PostRenderVGUI.
    function ax.notification:Render()
        if ( ax.config and ax.config.Get and !ax.config:Get("notification.enabled", true) ) then return end
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
                if ( !t.closing and (CurTime() - t.startTime) >= t.length ) then
                    self:Close(i)
                end

                local alpha = clamp(p.alpha or 0, 0, 255)
                local stack = p.stack or 0
                local offset = p.offset or 0

                local w, h = t.width, t.height
                local x = cx - math.floor(w / 2)
                local y = baseY - stack - offset - h

                if ( self.shadow > 0 and alpha > 0 ) then
                    local sa = math.floor(alpha * 0.25)
                    draw.RoundedBox(self.corner, x + self.shadow, y + self.shadow, w, h, Color(0, 0, 0, sa))
                end

                draw.RoundedBox(self.corner, x, y, w, h, Color(18, 18, 18, math.floor(alpha * 0.92)))

                local col = self.colors[t.type] or self.colors.generic
                draw.RoundedBox(self.corner, x, y, ScreenScale(2), h, Color(col.r, col.g, col.b, alpha))

                local ty = y + self.paddingY
                local tx = x + self.paddingX
                for k = 1, #t.lines do
                    local line = t.lines[k]
                    draw.SimpleText(line, self.font, tx, ty, Color(240, 240, 240, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    ty = ty + t.lineHeight
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

--- Player:Notify - Convenience for sending a toast to this player.
-- @realm server
function ax.player.meta:Notify(text, type, length)
    if ( SERVER ) then
        ax.notification:Send(self, text, type, length)
    else
        ax.notification:Add(text, type, length)
    end
end
