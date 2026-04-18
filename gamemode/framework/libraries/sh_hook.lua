--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Hook attachment system that registers every function member of a table as its own
-- `hook.Add` handler. Replaces the previous `hook.Call` hijack used to dispatch
-- `SCHEMA:HookName` and `MODULE:HookName` methods.
-- @module ax.hook

ax.hook = ax.hook or {}
ax.hook.attached = ax.hook.attached or {}

--- Attach every function member of the given table as an individual `hook.Add` handler.
-- Any existing attachment under the same identifier is removed first, so this is safe
-- to call again on hot reload.
-- @realm shared
-- @param tbl table The table whose functions should be registered as hooks (e.g. `SCHEMA`, a `MODULE` table).
-- @param identifier string A unique identifier used to namespace the underlying hook names.
function ax.hook:AttachHooks(tbl, identifier)
    if ( !istable(tbl) ) then
        ax.util:PrintError("ax.hook:AttachHooks expected a table, got " .. type(tbl) .. ".\n")
        return
    end

    if ( !isstring(identifier) or identifier == "" ) then
        ax.util:PrintError("ax.hook:AttachHooks expected a non-empty string identifier.\n")
        return
    end

    self:DetachHooks(identifier)

    local events = {}
    self.attached[identifier] = events

    for event, func in pairs(tbl) do
        if ( !isfunction(func) ) then continue end

        local hookName = "ax.hook." .. identifier .. "." .. event
        events[#events + 1] = { event = event, hookName = hookName }

        hook.Add(event, hookName, function(...)
            local resolved = tbl[event]
            if ( !isfunction(resolved) ) then return end

            return resolved(tbl, ...)
        end)
    end
end

--- Detach all hooks previously attached under the given identifier.
-- @realm shared
-- @param identifier string The identifier passed to `ax.hook:AttachHooks`.
function ax.hook:DetachHooks(identifier)
    local events = self.attached[identifier]
    if ( !events ) then return end

    for i = 1, #events do
        hook.Remove(events[i].event, events[i].hookName)
    end

    self.attached[identifier] = nil
end
