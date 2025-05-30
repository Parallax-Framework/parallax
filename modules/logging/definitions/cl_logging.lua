local MODULE = MODULE

ax.net:Hook("logging.send", function(payload)
    if ( !payload ) then return end

    ax.util:Print("[Logging] ", unpack(payload))
end)

function MODULE:Send(...)
    ax.util:Print("[Logging] ", ...)
end