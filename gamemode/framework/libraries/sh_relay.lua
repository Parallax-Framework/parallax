ax.relay = ax.relay or {}
ax.relay.data = ax.relay.data or {}

local ENTITY = FindMetaTable("Entity")
function ENTITY:SetRelay( name, value, bNoNetworking, recipients )
    if ( !isstring( name ) ) then
        ax.util:PrintError("Invalid 'name' argument provided to method Entity:SetRelay()")
        return
    end

    local index = tostring( self:EntIndex() )
    if ( self:IsPlayer() ) then
        index = self:SteamID64()
    end

    ax.relay.data[index] = ax.relay.data[index] or {}
    ax.relay.data[index][name] = value

    if ( !bNoNetworking and SERVER ) then
        net.Start( "ax.relay.update" )
            net.WriteString( index )
            net.WriteString( name )
            net.WriteType( value )
        if ( recipients ) then
            net.Send( recipients )
        else
            net.Broadcast()
        end
    end
end

function ENTITY:GetRelay( name, fallback )
    if ( !isstring( name ) ) then return fallback end

    local index = tostring( self:EntIndex() )
    if ( self:IsPlayer() ) then
        index = self:SteamID64()
    end

    ax.relay.data[index] = ax.relay.data[index] or {}
    return ax.relay.data[index][name] != nil and ax.relay.data[index][name] or fallback
end

hook.Add( "OnEntityRemoved", "ax.relay.cleanup", function( ent )
    local index = tostring( ent:EntIndex() )
    if ( ent:IsPlayer() ) then
        index = ent:SteamID64()
    end

    ax.relay.data[index] = nil
end )
