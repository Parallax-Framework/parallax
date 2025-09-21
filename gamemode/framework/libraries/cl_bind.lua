ax.bind = ax.bind or {}
ax.bind.stored = ax.bind.stored or {}
ax.bind.activeButtons = 0

ax.bind.stored[ "test" ] = {
    key = bit.bor(KEY_H, KEY_S),
    callback = function(client, key)
        print("H + S pressed")
    end
}

hook.Add( "PlayerButtonDown" , "ax.bind", function(client, key)
    local buttons = bit.bor(ax.bind.activeButtons, key)
    ax.bind.activeButtons = buttons

    for name, bind in pairs(ax.bind.stored) do
        if ( bind.key == bit.band(bind.key, ax.bind.activeButtons) ) then
            bind.callback(client, key)
        end
    end
end)

hook.Add( "PlayerButtonUp" , "ax.bind", function(client, key)
    local buttons = bit.band(ax.bind.activeButtons, bit.bnot(key))
    ax.bind.activeButtons = buttons
end)
