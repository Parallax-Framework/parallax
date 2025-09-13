ax.chat:Add("ic", {
    description = "Speak in-character",
    noCommand = true,
    OnRun = function(client, message)
        return Color(230, 230, 110, 255), client:Nick() .. " says, \"" .. ax.chat:Format(message) .. "\""
    end,
    CanHear = function(speaker, listener)
        return speaker:GetPos():Distance(listener:GetPos()) <= 400
    end
})

ax.chat:Add("looc", {
    description = "Speak local out-of-character",
    OnRun = function(client, message)
        return Color(110, 10, 10), "(LOOC) ", color_white, client:SteamName() .. ": " .. message
    end,
    CanHear = function(speaker, listener)
        return listener:GetCharacter() == nil or speaker:GetPos():Distance(listener:GetPos()) <= 600
    end
})

ax.chat:Add("ooc", {
    description = "Speak out-of-character",
    OnRun = function(client, message)
        return Color(110, 10, 10), "(OOC) ", color_white, client:SteamName() .. ": " .. message
    end,
    CanHear = function(speaker, listener)
        return true
    end
})

ax.chat:Add("me", {
    description = "Perform an action in third person",
    OnRun = function(client, message)
        return "* " .. client:Nick() .. " " .. ax.chat:Format(message)
    end,
    CanHear = function(speaker, listener)
        return speaker:GetPos():Distance(listener:GetPos()) <= 600
    end
})