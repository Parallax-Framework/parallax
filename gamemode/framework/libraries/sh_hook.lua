--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Hook system for registering and managing custom hook types, internally handles Schema and Module hooks.
-- @module ax.hook

ax.hook = ax.hook or {}
ax.hook.stored = ax.hook.stored or {}

--- Registers a new hook type.
-- @realm shared
-- @string name The name of the hook type.
function ax.hook:Register(name)
    _G[name] = _G[name] or {}
    self.stored[name] = true
    hook.Run("OnHookRegistered", name)
end

--- Unregisters a hook type.
-- @realm shared
-- @string name The name of the hook type.
-- @internal
function ax.hook:UnRegister(name)
    self.stored[name] = nil
    hook.Run("OnHookUnRegistered", name)
end

hook.axCall = hook.axCall or hook.Call

local function _profilerEnabled()
    local dev = GetConVar and GetConVar("developer")
    local devEnabled = dev and dev:GetBool() or false
    local cfgEnabled = false
    if ( ax and ax.config and ax.config.Get ) then
        cfgEnabled = ax.config:Get("debug.profiler.enabled", false) or false
    end
    return devEnabled or cfgEnabled
end

local function _profThreshold()
    if ( ax and ax.config and ax.config.Get ) then
        return ax.config:Get("debug.profiler.thresholdMs", 8)
    end
    return 8
end

function hook.Call(name, gm, ...)
    local doProfile = _profilerEnabled()

    -- Dispatch to custom hook tables registered via ax.hook
    for k, v in pairs(ax.hook.stored) do
        local tab = _G[k]
        if ( !tab ) then continue end

        local fn = tab[name]
        if ( !fn ) then continue end

        local a, b, c, d, e, f
        if ( doProfile ) then
            local t1 = SysTime()
            a, b, c, d, e, f = fn(tab, ...)
            local dtSec = SysTime() - t1
            if ( dtSec * 1000 >= _profThreshold() and ax and ax.profiler and ax.profiler.Record ) then
                ax.profiler:Record("hook:" .. tostring(name), "ax.hook:" .. tostring(k), dtSec)
            end
        else
            a, b, c, d, e, f = fn(tab, ...)
        end

        if ( a != nil ) then
            return a, b, c, d, e, f
        end
    end

    -- Dispatch to module methods (MODULE:HookName) registered in ax.module.stored
    for moduleName, moduleTable in pairs(ax.module.stored) do
        for methodName, method in pairs(moduleTable) do
            if ( isfunction(method) and methodName == name ) then
                local a, b, c, d, e, f
                if ( doProfile ) then
                    local t1 = SysTime()
                    a, b, c, d, e, f = method(moduleTable, ...)
                    local dtSec = SysTime() - t1
                    if ( dtSec * 1000 >= _profThreshold() and ax and ax.profiler and ax.profiler.Record ) then
                        ax.profiler:Record("hook:" .. tostring(name), "module:" .. tostring(moduleName), dtSec)
                    end
                else
                    a, b, c, d, e, f = method(moduleTable, ...)
                end

                if ( a != nil ) then
                    return a, b, c, d, e, f
                end
            end
        end
    end

    -- Fallback to gamemode
    local a, b, c, d, e, f
    if ( doProfile ) then
        local t1 = SysTime()
        a, b, c, d, e, f = hook.axCall(name, gm, ...)
        local dtSec = SysTime() - t1
        if ( dtSec * 1000 >= _profThreshold() and ax and ax.profiler and ax.profiler.Record ) then
            ax.profiler:Record("hook:" .. tostring(name), "gamemode", dtSec)
        end
    else
        a, b, c, d, e, f = hook.axCall(name, gm, ...)
    end
    return a, b, c, d, e, f
end
