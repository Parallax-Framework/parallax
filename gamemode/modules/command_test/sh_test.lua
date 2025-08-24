--[[
    Test module for the ax.command system
    This demonstrates various command types and usage patterns
]]

local MODULE = MODULE

--[[
    Test command with string validation
]]
ax.command:Add("echo", {
    description = "Echo back a message",
    arguments = {
        { name = "message", type = ax.type.text }
    },
    OnRun = function(client, message)
        return "Echo: " .. message
    end
})

--[[
    Test command with number validation and ranges
]]
ax.command:Add("random", {
    description = "Generate a random number between min and max",
    arguments = {
        { name = "min", type = ax.type.number },
        { name = "max", type = ax.type.number }
    },
    OnRun = function(client, min, max)
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
ax.command:Add("toggle", {
    description = "Toggle a boolean setting",
    arguments = {
        { name = "enabled", type = ax.type.bool }
    },
    OnRun = function(client, enabled)
        return "Setting is now: " .. (enabled and "enabled" or "disabled")
    end
})

--[[
    Test command with choices validation
]]
ax.command:Add("color", {
    description = "Set your favorite color",
    arguments = {
        { name = "color", type = ax.type.string, choices = {
            ["red"] = true,
            ["blue"] = true,
            ["green"] = true,
            ["yellow"] = true
        }}
    },
    OnRun = function(client, color)
        return "Your favorite color is now: " .. color
    end
})

--[[
    Test admin-only command
]]
ax.command:Add("admin_test", {
    description = "Test admin-only command",
    adminOnly = true,
    OnRun = function(client)
        return "You are an admin!"
    end
})

--[[
    Test command with custom access control
]]
ax.command:Add("vip_command", {
    description = "VIP only command with custom access control",
    CanRun = function(caller)
        if ( !IsValid(caller) ) then
            return false, "Console cannot use VIP commands"
        end

        -- Example: Check if player has VIP flag (would be implemented elsewhere)
        -- For now, just allow everyone for testing
        return true
    end,
    OnRun = function(client)
        return "Welcome, VIP member!"
    end
})

MODULE.Name = "Command System Test"
MODULE.Description = "Testing module for the ax.command system"
