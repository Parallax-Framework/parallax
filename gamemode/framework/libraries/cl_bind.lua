ax.bind = ax.bind or {}
ax.bind.stored = ax.bind.stored or {}
ax.bind.activeButtons = 0

--- Register a key bind.
-- Triggers when all buttons in `keys` are held and one of them is pressed.
-- @tparam string uclass Unique identifier for this binding.
-- @tparam number keys Bitmask of KEY* constants representing the keys to bind.
-- @tparam function callback Function called as callback(client, key) when fired.
-- @treturn boolean True if the bind was registered; false otherwise.
function ax.bind:Bind( keys, callbackPressed, callbackReleased )
    if ( !isnumber( keys ) or keys <= 0 ) then
        ax.util:PrintError( "Invalid keys provided to ax.bind:Bind()" )
        return false
    end

    if ( istable( self.stored[keys] ) ) then
        ax.util:PrintWarning( "Overwriting existing bind for keys '" .. tostring(keys) .. "'" )
    end

    if ( !isnumber( keys ) or keys <= 0 ) then
        ax.util:PrintError( "Invalid keys provided to ax.bind:Bind()" )
        return false
    end

    if ( !isfunction( callback ) ) then
        ax.util:PrintError( "Invalid callback provided to ax.bind:Bind()" )
        return false
    end

    self.stored[keys] = { callbackPressed = callbackPressed, callbackReleased = callbackReleased }
    return true
end

hook.Add( "PlayerButtonDown" , "ax.bind", function(client, key)
    local buttons = bit.bor( ax.bind.activeButtons, key )
    ax.bind.activeButtons = buttons

    local bind = ax.bind.stored[ buttons ]
    if ( bind and isfunction( bind.callbackPressed ) ) then
        bind:callbackPressed()
    end
end)

hook.Add( "PlayerButtonUp", "ax.bind", function(client, key)
    local bind = ax.bind.stored[ ax.bind.activeButtons ]
    if ( bind and isfunction( bind.callbackReleased ) ) then
        bind:callbackReleased()
    end

    local buttons = bit.band( ax.bind.activeButtons, bit.bnot( key ) )
    ax.bind.activeButtons = buttons
end)
