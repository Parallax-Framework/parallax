--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Advanced panel animation handler using easing for custom fields.
-- Supports delays, per-field animation isolation, and cancelation.
-- @module ax.motion

ax.motion = ax.motion or {}
ax.motion.active = ax.motion.active or {}

--- Starts a property animation on a panel.
-- @tparam Panel panel The target panel.
-- @tparam number duration Duration in seconds.
-- @tparam table data Contains Target, Easing, optional Delay, Think, OnComplete.
function ax.motion:Motion(panel, duration, data)
    if ( !IsValid(panel) or !istable(data) or !istable(data.Target) ) then return end

    if ( !ax.option:Get("performance.animations") ) then
        -- if animations are disabled, set target values immediately
        for key, target in pairs(data.Target) do
            panel[key] = target
        end

        -- call think if provided, because it might include logic that needs to run
        if ( data.Think ) then
            data.Think(panel)
        end

        -- call onComplete if provided
        if ( data.OnComplete ) then
            data.OnComplete(panel)
        end

        return
    end

    local easing = data.Easing or "OutQuad"
    local delay = data.Delay or 0
    local now = SysTime()
    local origin = {}
    local current = {}

    -- capture starting values, cancel overlapping anims
    for key, target in pairs(data.Target) do
        origin[key] = panel[key] or 0
        current[key] = origin[key]
    end

    -- remove any existing anims on this panel that share any key
    for i = #self.active, 1, -1 do
        local a = self.active[i]
        if ( a.panel == panel ) then
            for key in pairs(data.Target) do
                if ( a.target[key] ) then
                    table.remove(self.active, i)
                    break
                end
            end
        end
    end

    -- push new grouped animation
    table.insert(self.active, {
        panel = panel,
        duration = duration,
        delay = delay,
        start = now,
        origin = origin,
        target = data.Target,
        current = current,
        easing = easing,
        think = isfunction(data.Think) and data.Think or nil,
        onComplete = isfunction(data.OnComplete) and data.OnComplete or nil,
    })
end

--- Cancels a specific animation on a panel.
-- @tparam Panel panel The panel whose animation to cancel.
-- @tparam string key The custom property key to cancel.
function ax.motion:Cancel(panel, key)
    for i = #self.active, 1, -1 do
        local a = self.active[i]
        if ( a.panel == panel and a.target[key] ) then
            a.target[key] = nil
            a.origin[key] = nil
            a.current[key] = nil

            if ( !next(a.target) ) then
                table.remove(self.active, i)
            end
        end
    end
end

--- Cancels all animations on a panel.
-- @tparam Panel panel The panel to cancel all animations for.
function ax.motion:CancelAll(panel)
    for i = #self.active, 1, -1 do
        if ( self.active[i].panel == panel ) then
            table.remove(self.active, i)
        end
    end
end

hook.Add("Think", "ax.motion.Update", function()
    local now = SysTime()

    for i = #ax.motion.active, 1, -1 do
        local a = ax.motion.active[i]
        if ( !IsValid(a.panel) ) then
            table.remove(ax.motion.active, i)
        elseif ( now >= a.start + a.delay ) then
            local t = (now - a.start - a.delay) / a.duration
            if ( t < 0 ) then
                t = 0
            elseif ( t > 1 ) then
                t = 1
            end

            -- update every key
            for key, target in pairs(a.target) do
                local o = a.origin[key]
                local v = ax.ease:Lerp(a.easing, t, o, target)
                a.current[key] = v
                a.panel[key]   = v
            end

            -- frame callback
            if ( a.think ) then
                a.think(a.current)
            end

            -- completion
            if ( t >= 1 ) then
                -- ensure final values
                for key, target in pairs(a.target) do
                    a.panel[key] = target
                end

                if ( a.onComplete ) then
                    a.onComplete(a.panel)
                end

                table.remove(ax.motion.active, i)
            end
        end
    end
end)

-- Add Animate method to all panels.
do
    local PANEL = FindMetaTable("Panel")

    --- Animate custom properties with easing.
    -- @tparam number duration Duration in seconds.
    -- @tparam table data Table with Target, Easing, Delay, Think, OnComplete.
    function PANEL:Motion(duration, data)
        ax.motion:Motion(self, duration, data)
    end

    --- Cancel a specific animation on this panel.
    -- @tparam string key The property key to cancel.
    function PANEL:CancelAnimation(key)
        ax.motion:Cancel(self, key)
    end

    --- Cancel all animations on this panel.
    function PANEL:CancelAllAnimations()
        ax.motion:CancelAll(self)
    end
end