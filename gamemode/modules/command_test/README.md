# ax.command - Parallax Command System

A comprehensive command system for the Parallax Framework that handles chat/console commands, argument parsing, validation, access control, and networking.

## Features

- **Unified API**: Single system for both chat and console commands
- **Type Safety**: Strong argument validation with multiple types
- **Access Control**: Admin/SuperAdmin flags plus custom permission functions
- **Networking**: Automatic client → server command execution
- **Aliases**: Multiple names can map to the same command
- **Flexible Arguments**: Optional parameters, quoted strings, text capturing
- **Error Handling**: Friendly error messages with context

## Quick Start

### Basic Command Registration

```lua
ax.command:Add("hello", {
    description = "Say hello to someone",
    arguments = {
        { name = "target", type = "player" },
        { name = "message", type = ax.type.text, optional = true }
    },
    OnRun = function(caller, target, message)
        message = message or "Hello!"
        target:Notify("[" .. caller:Nick() .. "] " .. message)
        return "Message sent to " .. target:Nick()
    end
})
```

### Usage Examples

- Chat: `/hello player1 How are you?`
- Chat: `!hello "John Doe" Welcome to the server!`
- Console: `ax_command hello player1`

## API Reference

### ax.command:Add(name, definition)

Register a new command.

**Parameters:**
- `name` (string): Command name (normalized to lowercase)
- `definition` (table): Command configuration

**Definition Structure:**
```lua
{
    description = "Command description",
    alias = {"alt1", "alt2"}, -- Optional aliases
    adminOnly = false, -- Require admin status
    superAdminOnly = false, -- Require super admin status
    bAllowConsole = true, -- Allow console execution
    arguments = { -- Array of argument definitions
        {
            name = "argname",
            type = "string|text|number|bool|player",
            optional = false,
            -- Number-specific:
            min = 0, max = 100, decimals = 2,
            -- String-specific:
            choices = {["option1"] = true, ["option2"] = true}
        }
    },
    OnRun = function(caller, arg1, arg2, ...)
        -- Server execution handler
        return "Success message" -- Optional
    end,
    OnConsole = function(caller, arg1, arg2, ...)
        -- Optional console-specific handler
    end,
    CanRun = function(self, caller)
        -- Optional custom access check
        return true -- or false, "reason"
    end
}
```

### Argument Types

- **string**: Single word or quoted phrase
- **text**: Captures remaining text after previous arguments
- **number**: Numeric value with optional min/max/decimals
- **bool**: true/false, 1/0, yes/no
- **player**: Resolves by name, SteamID, or partial match

### ax.command:FindAll(partial)

Find commands by partial name match.

```lua
local matches = ax.command:FindAll("pm") -- Returns table of matching commands
```

### ax.command:HasAccess(caller, definition)

Check if caller can run a command.

```lua
local canRun, reason = ax.command:HasAccess(player, commandDef)
```

### ax.command:Parse(text)

Parse command text into name and arguments.

```lua
local name, rawArgs = ax.command:Parse("/pm player1 hello")
-- name = "pm", rawArgs = "player1 hello"
```

### ax.command:ExtractArgs(definition, rawArgs)

Extract and validate arguments from raw string.

```lua
local values, error = ax.command:ExtractArgs(commandDef, "player1 hello world")
```

### ax.command:Run(caller, name, rawArgs)

Execute a command (server-side).

```lua
local success, result = ax.command:Run(player, "pm", "player1 hello")
```

### ax.command:Send(text) [Client Only]

Send command to server for execution.

```lua
ax.command:Send("/pm player1 hello")
```

### ax.command:Help(name)

Generate help text for a command.

```lua
local helpText = ax.command:Help("pm")
-- Returns: "pm <target> <message> - Send a private message"
```

## Integration

### Chat Integration

Commands are automatically detected in chat when they start with configured prefixes (`/`, `!` by default).

```lua
-- Configure prefixes
ax.command.Prefixes = {"/", "!", "."}
```

### Console Integration

Use the `ax_command` console command:

```
ax_command help
ax_command pm player1 hello
```

### Custom Access Control

```lua
ax.command:Add("vip_only", {
    description = "VIP members only",
    CanRun = function(self, caller)
        if !IsValid(caller) then return false, "Console not allowed" end
        if !caller:GetVIPStatus() then return false, "VIP required" end
        return true
    end,
    OnRun = function(caller)
        return "Welcome, VIP!"
    end
})
```

## Error Handling

The system provides detailed error messages:

- Unknown commands
- Missing required arguments
- Invalid argument types
- Out-of-range values
- Player not found
- Access denied with reason

## Built-in Commands

- `help [command]` - List commands or show specific help
- `pm <player> <message>` - Private message (aliases: tell, whisper)
- `setgravity <scale>` - Admin gravity control (0.1-3.0)
- `god [player]` - Admin god mode toggle

## Advanced Examples

### Complex Argument Validation

```lua
ax.command:Add("spawn_money", {
    description = "Spawn money with validation",
    adminOnly = true,
    arguments = {
        { name = "amount", type = "number", min = 1, max = 10000 },
        { name = "target", type = "player", optional = true },
        { name = "reason", type = ax.type.text, optional = true }
    },
    OnRun = function(caller, amount, target, reason)
        target = target or caller
        reason = reason or "Admin spawn"

        target:AddMoney(amount)
        return string.format("Gave $%d to %s (%s)", amount, target:Nick(), reason)
    end
})
```

### Multi-Choice Arguments

```lua
ax.command:Add("weather", {
    description = "Change weather",
    adminOnly = true,
    arguments = {
        { name = "type", type = ax.type.string, choices = {
            ["sunny"] = true,
            ["rainy"] = true,
            ["stormy"] = true,
            ["foggy"] = true
        }}
    },
    OnRun = function(caller, weatherType)
        SetGlobalString("Weather", weatherType)
        return "Weather changed to " .. weatherType
    end
})
```

## Testing

Use the included test module (`modules/command_test/sh_test.lua`) to verify functionality:

- `/echo hello world` - Text argument test
- `/random 1 100` - Number validation test
- `/toggle true` - Boolean parsing test
- `/color red` - Choice validation test
- `/admin_test` - Access control test
