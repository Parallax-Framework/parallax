ax.bind = ax.bind or {}
ax.bind.stored = ax.bind.stored or {}
ax.bind.activeButtons = 0


--- Register a key bind.
-- Triggers when all buttons in `keys` are held and one of them is pressed.
-- @tparam string uclass Unique identifier for this binding.
-- @tparam number keys Bitmask of IN_* constants (e.g. bit.bor(IN_FORWARD, IN_SPEED)).
-- @tparam function callback Function called as callback(client, key) when fired.
-- @treturn boolean True if the bind was registered; false otherwise.
function ax.bind:Bind(uclass, keys, callback)
    if ( !isstring( uclass ) or uclass == "" ) then
        ax.util:PrintError( "Invalid uclass provided to ax.bind:Bind()" )
        return false
    end

    if ( istable( self.stored[uclass] ) ) then
        ax.util:PrintWarning( "Overwriting existing bind for class '" .. tostring(uclass) .. "'" )
    end

    if ( !isnumber( keys ) or keys <= 0 ) then
        ax.util:PrintError( "Invalid keys provided to ax.bind:Bind()" )
        return false
    end

    if ( !isfunction( callback ) ) then
        ax.util:PrintError( "Invalid callback provided to ax.bind:Bind()" )
        return false
    end

    self.stored[uclass] = {
        keys = keys,
        key = keys, -- legacy alias for hooks that read `bind.key`
        callback = callback
    }

    return true
end

hook.Add( "PlayerButtonDown" , "ax.bind", function(client, key)
    local buttons = bit.bor(ax.bind.activeButtons, key)
    ax.bind.activeButtons = buttons

    for name, bind in pairs(ax.bind.stored) do
        if ( bind.keys == bit.band(bind.keys, ax.bind.activeButtons) ) then
            bind.callback(client, key)
        end
    end
end)

hook.Add( "PlayerButtonUp" , "ax.bind", function(client, key)
    local buttons = bit.band(ax.bind.activeButtons, bit.bnot(key))
    ax.bind.activeButtons = buttons
end)
