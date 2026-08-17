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

--- Hook families registered through `ax.hook:Register`, mapping the global table name (`"SCHEMA"`, `"MYSCHEMA"`) to the `AttachHooks` identifier it is attached under.
---@realm shared
---@type table<string, string>
ax.hook.registered = ax.hook.registered or {}

-- SCHEMA is attached by ax.schema:Initialize under its own identifier, so it is seeded here to keep a manual ax.hook:Register("SCHEMA") a no-op instead of a second attachment that would dispatch every schema hook twice.
ax.hook.registered.SCHEMA = ax.hook.registered.SCHEMA or "schema"

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

--- Registers a global table as a hook family, so every `<NAME>:HookName(...)` method declared on it is dispatched exactly like `SCHEMA:HookName` and `MODULE:HookName` - the global is created when it does not exist yet, and registering a name that is already registered is a no-op (which is why `ax.hook:Register("SCHEMA")` from schema code is harmless).
---@realm shared
---@param name string The global table name to register, e.g. `"MYSCHEMA"`.
---@return table|nil family The registered table, or nil when `name` is not a non-empty string.
function ax.hook:Register(name)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("ax.hook:Register expected a non-empty string name.\n")
        return nil
    end

    if ( self.registered[name] != nil ) then
        return _G[name]
    end

    local family = _G[name]
    if ( !istable(family) ) then
        family = {}
        _G[name] = family
    end

    local identifier = "registered." .. name
    self.registered[name] = identifier

    self:AttachHooks(family, identifier)

    return family
end

--- Re-attaches every family registered through `ax.hook:Register` so methods declared after the `Register` call are picked up as well, since `AttachHooks` only sees the functions present at the moment it runs; `ax.schema:Initialize` calls this once loading has finished, which is what makes the register-then-declare order work.
---@realm shared
function ax.hook:RefreshRegistered()
    for name, identifier in pairs(self.registered) do
        local family = _G[name]
        if ( !istable(family) ) then
            self:DetachHooks(identifier)
            self.registered[name] = nil
            continue
        end

        self:AttachHooks(family, identifier)
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
