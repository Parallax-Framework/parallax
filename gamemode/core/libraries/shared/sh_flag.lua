ax.flag = ax.flag or {}
ax.flag.stored = {}

function ax.flag:Register(flag, description, callback)
    if ( !isstring(flag) or #flag != 1 ) then
        ax.util:PrintError("Attempted to register a flag without a flag character!")
        return false
    end

    if ( self.stored[flag] ) then
        ax.util:PrintError("Attempted to register a flag that already exists!")
        return false
    end

    self.stored[flag] = {
        description = description or "No description provided",
        callback = callback or nil
    }

    return true
end

function ax.flag:Get(flag)
    return self.stored[flag]
end