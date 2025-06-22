--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Custom function based hooks.
-- @module ax.hooks

ax.hooks = {}
ax.hooks.stored = {}

--- Registers a new hook type.
-- @realm shared
-- @string name The name of the hook type.
function ax.hooks:Register(name)
    self.stored[name] = true
    hook.Run("OnHookRegistered", name)
end

--- Unregisters a hook type.
-- @realm shared
-- @string name The name of the hook type.
-- @internal
function ax.hooks:UnRegister(name)
    self.stored[name] = nil
    hook.Run("OnHookUnRegistered", name)
end

hook.axCall = hook.axCall or hook.Call

function hook.Call(name, gm, ...)
    for k, v in pairs(ax.hooks.stored) do
        local tab = _G[k]
        if ( !tab ) then continue end

        local fn = tab[name]
        if ( !fn ) then continue end

        local a, b, c, d, e, f = fn(tab, ...)

        if ( a != nil ) then
            return a, b, c, d, e, f
        end
    end

    for k, v in pairs(ax.module.stored) do
        for k2, v2 in pairs(v) do
            if ( isfunction(v2) and k2 == name ) then
                local a, b, c, d, e, f = v2(v, ...)

                if ( a != nil ) then
                    return a, b, c, d, e, f
                end
            end
        end
    end

    return hook.axCall(name, gm, ...)
end