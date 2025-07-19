-- Credits @ https://github.com/NebulousCloud/helix/blob/master/gamemode/core/libs/sh_plugin.lua#L340-L364

AX_HOOKS_CACHE = AX_HOOKS_CACHE or {}

hook.axCall = hook.axCall or hook.Call
function hook.Call(name, gm, ...)
    local cache = AX_HOOKS_CACHE[name]

    if ( cache ) then
        for k, v in pairs(cache) do
            local a, b, c, d, e, f = v(k, ...)
            if ( a != nil ) then
                return a, b, c, d, e, f
            end
        end
    end

    if ( SCHEMA and SCHEMA[name] ) then
        local a, b, c, d, e, f = SCHEMA[name](Schema, ...)
        if ( a != nil ) then
            return a, b, c, d, e, f
        end
    end

    return hook.axCall(name, gm, ...)
end