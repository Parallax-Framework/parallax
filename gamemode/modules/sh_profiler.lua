--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Profiler"
MODULE.description = "Lightweight profiling for timers, hooks, and net receivers"
MODULE.author = "Riggs"

-- Shared lightweight profiler for timers, hooks, and net receivers
-- Logs callbacks that exceed a configurable threshold (ms)
-- Enable via developer 1 or ax.config "debug.profiler.enabled"

ax.profiler = ax.profiler or {}

local function isEnabled()
    local dev = GetConVar and GetConVar("developer")
    local devEnabled = dev and dev:GetBool() or false

    -- Config may not be available immediately on client; fall back to dev
    local cfgEnabled = false
    if ( ax and ax.config and ax.config.Get ) then
        cfgEnabled = ax.config:Get("debug.profiler.enabled", false) or false
    end

    return devEnabled or cfgEnabled
end

-- Threshold in milliseconds
local function threshold()
    if ( ax and ax.config and ax.config.Get ) then
        return ax.config:Get("debug.profiler.threshold", 8) -- default 8ms
    end

    return 8
end

-- Recent event log (rolling)
ax.profiler.recent = ax.profiler.recent or {}
ax.profiler.maxRecent = 128

function ax.profiler:Record(kind, name, dt)
    local item = { kind = kind, name = tostring(name), ms = math.floor(dt * 1000), ts = SysTime() }
    local list = self.recent
    list[#list + 1] = item
    if (#list > self.maxRecent) then
        table.remove(list, 1)
    end

    ax.util:PrintWarning("Profiler[", kind, "] ", name, " took ", item.ms, "ms")
end

-- Add config keys on server to allow toggling
ax.config:Add("debug.profiler.enabled", ax.type.bool, false, {
    description = "Enable lightweight profiler (developer mode also enables)",
    category = "debug",
    subCategory = "profiler",
    bNetworked = false
})

ax.config:Add("debug.profiler.threshold", ax.type.number, 8, {
    description = "Profiler callback threshold in milliseconds",
    min = 1,
    max = 50,
    decimals = 0,
    category = "debug",
    subCategory = "profiler",
    bNetworked = false
})

ax.localisation:Register("en", {
    ["category.debug"] = "Debug",
    ["subCategory.profiler"] = "Profiler",
    ["config.debug.profiler.enabled"] = "Enable Profiler",
    ["config.debug.profiler.threshold"] = "Profiler Threshold (ms)"
})

-- Wrap timer.Create
if ( !ax.profiler._origTimerCreate ) then
    ax.profiler._origTimerCreate = timer.Create
    function timer.Create(name, interval, reps, func)
        if ( !isfunction(func) ) then
            return ax.profiler._origTimerCreate(name, interval, reps, func)
        end

        local function wrapped(...)
            if ( !isEnabled() ) then
                return func(...)
            end

            local t0 = SysTime()
            local ok, res = pcall(func, ...)
            local dt = SysTime() - t0
            if ( ok and dt * 1000 >= threshold() ) then
                ax.profiler:Record("timer", name, dt)
            end
            if ( !ok ) then
                ax.util:PrintError("Profiler[timer] ", name, " error: ", tostring(res))
            end
            return res
        end

        return ax.profiler._origTimerCreate(name, interval, reps, wrapped)
    end
end

-- Wrap hook.Add
if ( !ax.profiler._origHookAdd ) then
    ax.profiler._origHookAdd = hook.Add
    function hook.Add(event, id, func)
        if ( !isfunction(func) ) then
            return ax.profiler._origHookAdd(event, id, func)
        end

        local function wrapped(...)
            if ( !isEnabled() ) then
                return func(...)
            end

            local t0 = SysTime()
            local ok, a, b, c, d, e, f = pcall(func, ...)
            local dt = SysTime() - t0
            if ( ok and dt * 1000 >= threshold() ) then
                ax.profiler:Record("hook:" .. tostring(event), id or "(nil)", dt)
            end
            if ( !ok ) then
                ax.util:PrintError("Profiler[hook] ", tostring(event), "/", tostring(id), " error: ", tostring(a))
            end
            return a, b, c, d, e, f
        end

        return ax.profiler._origHookAdd(event, id, wrapped)
    end
end

-- Wrap net.Receive
if ( !ax.profiler._origNetReceive ) then
    ax.profiler._origNetReceive = net.Receive
    function net.Receive(channel, func)
        if ( !isfunction(func) ) then
            return ax.profiler._origNetReceive(channel, func)
        end

        local function wrapped(len, ply)
            if ( !isEnabled() ) then
                return func(len, ply)
            end

            local t0 = SysTime()
            local ok, res = pcall(func, len, ply)
            local dt = SysTime() - t0
            if ( ok and dt * 1000 >= threshold() ) then
                local who = (SERVER and IsValid(ply)) and ply:Nick() or "client"
                ax.profiler:Record("net:" .. tostring(channel), who, dt)
            end
            if ( !ok ) then
                ax.util:PrintError("Profiler[net] ", tostring(channel), " error: ", tostring(res))
            end
            return res
        end

        return ax.profiler._origNetReceive(channel, wrapped)
    end
end

--- Wrap existing hooks for specific events at runtime.
-- Useful for catching handlers registered before the profiler loaded.
-- @realm shared
-- @param events table Array of event names to wrap (e.g., {"HUDPaint", "PostRenderVGUI", "Think"})
function ax.profiler:WrapExistingHooks(events)
    if ( !istable(events) ) then return end

    self._wrappedHooks = self._wrappedHooks or {}

    local hooks = hook.GetTable()
    for i = 1, #events do
        local ev = events[i]
        local map = hooks[ev]
        if ( !istable(map) ) then continue end

        self._wrappedHooks[ev] = self._wrappedHooks[ev] or {}

        for id, fn in pairs(map) do
            if ( !isfunction(fn) ) then continue end
            if ( self._wrappedHooks[ev][id] ) then continue end

            local info = debug.getinfo(fn)
            local src = info and (info.short_src or info.source or "unknown") or "unknown"
            local line = info and (info.linedefined or 0) or 0
            local label = tostring(id) .. " @ " .. src .. ":" .. tostring(line)

            local function wrapped(...)
                if ( !isEnabled() ) then
                    return fn(...)
                end

                local t0 = SysTime()
                local ok, a, b, c, d, e, f = pcall(fn, ...)
                local dt = SysTime() - t0
                if ( ok and dt * 1000 >= threshold() ) then
                    ax.profiler:Record("hook:" .. tostring(ev), label, dt)
                end
                if ( !ok ) then
                    ax.util:PrintError("Profiler[hook] ", tostring(ev), " / ", label, " error: ", tostring(a))
                end
                return a, b, c, d, e, f
            end

            -- Overwrite the hook with our wrapped version
            hook.Add(ev, id, wrapped)
            self._wrappedHooks[ev][id] = true
        end
    end
end

-- Auto-wrap common heavy events when profiler is enabled (post-load)
timer.Simple(0, function()
    if ( isEnabled() ) then
        ax.profiler:WrapExistingHooks({ "HUDPaint", "PostRenderVGUI", "Think", "Tick" })
    end
end)
