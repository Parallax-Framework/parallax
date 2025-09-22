ax.flag = ax.flag or {}
ax.flag.stored = ax.flag.stored or {}

function ax.flag:Create( letter, flagData )
    if ( !isstring(letter) or #letter > 1 ) then
        ax.util:PrintError("Invalid flag letter provided to ax.flag:Create()")
        return
    end

    self.stored[ letter ] = flagData
end

function ax.flag:GetAll()
    return self.stored
end

function ax.flag:Get( letter )
    if ( !isstring( letter ) or #letter > 1 ) then
        ax.util:PrintError("Invalid flag letter provided to ax.flag:Get()")
        return
    end

    return self.stored[ letter ]
end
