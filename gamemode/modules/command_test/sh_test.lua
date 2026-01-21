--[[
    Test module for the ax.command system
    This demonstrates various command types and usage patterns
]]

local MODULE = MODULE

--[[
    Test command with string validation
]]
ax.command:Add("Echo", {
    description = "Echo back a message",
    arguments = {
        { name = "message", type = ax.type.text }
    },
    OnRun = function(def, client, message)
        return "Echo: " .. message
    end
})

--[[
    Test command with number validation and ranges
]]
ax.command:Add("Random", {
    description = "Generate a random number between min and max",
    arguments = {
        { name = "min", type = ax.type.number },
        { name = "max", type = ax.type.number }
    },
    OnRun = function(def, client, min, max)
        if ( min > max ) then
            return "Minimum value cannot be greater than maximum"
        end

        local result = math.random(min, max)
        return "Random number: " .. result
    end
})

--[[
    Test command with boolean validation
]]
ax.command:Add("Toggle", {
    description = "Toggle a boolean setting",
    arguments = {
        { name = "enabled", type = ax.type.bool }
    },
    OnRun = function(def, client, enabled)
        return "Setting is now: " .. (enabled and "enabled" or "disabled")
    end
})

--[[
    Test command with choices validation
]]
ax.command:Add("Color", {
    description = "Set your favorite color",
    arguments = {
        { name = "color", type = ax.type.string, choices = {
            ["red"] = true,
            ["blue"] = true,
            ["green"] = true,
            ["yellow"] = true
        }}
    },
    OnRun = function(def, client, color)
        return "Your favorite color is now: " .. color
    end
})

--[[
    Test admin-only command
]]
ax.command:Add("AdminTest", {
    description = "Test admin-only command",
    adminOnly = true,
    OnRun = function(def, client)
        return "You are an admin!"
    end
})

--[[
    Test command with custom access control
]]
ax.command:Add("VipCommand", {
    description = "VIP only command with custom access control",
    CanRun = function(self, caller)
        if ( !ax.util:IsValidPlayer(caller) ) then
            return false, "Console cannot use VIP commands"
        end

        -- Example: Check if player has VIP flag (would be implemented elsewhere)
        -- For now, just allow everyone for testing
        return true
    end,
    OnRun = function(def, client)
        return "Welcome, VIP member!"
    end
})

MODULE.name = "Command System Test"
MODULE.description = "Testing module for the ax.command system"
