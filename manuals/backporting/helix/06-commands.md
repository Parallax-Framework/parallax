# Commands

Chat and console commands have the same purpose in both frameworks — a registered name, a permission check, an arguments parser, and a callback. The registration call is similar. What changes is the shape of the `arguments` table, the signature of `OnRun`, and how casing is handled.

## Table of Contents
- [Registration API](#registration-api)
- [Command Name Casing](#command-name-casing)
- [Arguments: The Big Change](#arguments-the-big-change)
- [Argument Types](#argument-types)
- [Permission Checks](#permission-checks)
- [OnRun Signature](#onrun-signature)
- [A Full Worked Example](#a-full-worked-example)
- [Handling Optional Arguments](#handling-optional-arguments)
- [Choice Restrictions](#choice-restrictions)
- [Running Commands Programmatically](#running-commands-programmatically)
- [Pitfalls](#pitfalls)

---

## Registration API

| | Helix | Parallax |
|---|---|---|
| Register | `ix.command.Add("Name", data)` | `ax.command:Add("name", def)` |
| Registry | `ix.command.list[lowerName]` | `ax.command.registry[name]` |
| Lookup | `ix.command.FindAll(id, ...)` | `ax.command:Find(look)` / `:FindAll(partial)` |
| Run | `ix.command.Run(client, cmd, args)` | `ax.command:Run(caller, name, args)` |
| Parse text | `ix.command.Parse(client, text, realCmd, args)` | `ax.command:Parse(text)` |
| Access check | `ix.command.HasAccess(client, cmd)` | `ax.command:HasAccess(caller, def)` |

The function names are mostly parallel. The two key call-site changes are dot → colon, and casing.

---

## Command Name Casing

Helix commands are registered with PascalCase names by convention: `ix.command.Add("CharSlap", ...)`, `ix.command.Add("PM", ...)`. The name is lowercased internally for lookup (`ix.command.list.charslap`) but the original casing is stored on the command for display.

Parallax normalizes everything to lowercase. You pass `"charslap"` or `"CharSlap"`; both produce a registered command keyed by `"charslap"`. For the display name, set `displayName` explicitly:

```lua
ax.command:Add("charslap", {
    displayName = "CharSlap",   -- what users see in /help output
    description = "Slap a character.",
    -- ...
})
```

If you omit `displayName`, Parallax generates a reasonable default by calling `ax.util:UniqueIDToName(name)` — `"charslap"` becomes `"Charslap"` (first letter capitalized). Good enough for most commands.

---

## Arguments: The Big Change

Helix describes command arguments with a flat list of type constants, using `bit.bor` to combine flags:

```lua
-- Helix
ix.command.Add("CharSetMoney", {
    description = "Set a character's money.",
    adminOnly   = true,
    arguments   = {
        ix.type.character,
        ix.type.number,
        bit.bor(ix.type.string, ix.type.optional),
    },
    argumentNames = { "target", "amount", "reason" },
    OnRun = function(self, client, target, amount, reason)
        -- target is the character object
        -- amount is a number
        -- reason is a string or nil
        target:SetMoney(amount)
    end,
})
```

Parallax uses a list of argument *descriptor tables*, one per argument:

```lua
-- Parallax
ax.command:Add("charsetmoney", {
    displayName = "CharSetMoney",
    description = "Set a character's money.",
    adminOnly   = true,
    arguments   = {
        { name = "target", type = ax.type.character },
        { name = "amount", type = ax.type.number, min = 0 },
        { name = "reason", type = ax.type.string,  optional = true },
    },
    OnRun = function(self, client, args)
        local target = args[1]
        local amount = args[2]
        local reason = args[3]
        target:SetMoney(amount)
    end,
})
```

What changed:

- Each argument is a table with `type` (required), `name`, and per-type modifiers.
- `optional = true` replaces the `bit.bor(type, ix.type.optional)` bitmask.
- `ix.type.optional` does not exist in Parallax.
- `argumentNames` goes away — put the name inside each argument descriptor.
- `OnRun` receives `(self, caller, args)` — a single args table — instead of spread positional arguments.

### Per-argument modifiers

| Modifier | Applies to | Meaning |
|---|---|---|
| `optional` | any | Argument may be missing. Later args must also be optional. |
| `min`, `max` | `ax.type.number` | Numeric bounds (inclusive). |
| `decimals` | `ax.type.number` | Round to N decimal places. |
| `choices` | `ax.type.string`, `ax.type.text` | Map of valid values; parser rejects input not in this map. |

---

## Argument Types

All Parallax type constants cover the Helix equivalents with the same bitmask values:

| Helix | Parallax |
|---|---|
| `ix.type.string` | `ax.type.string` |
| `ix.type.text` | `ax.type.text` — consumes remainder of input |
| `ix.type.number` | `ax.type.number` |
| `ix.type.bool` | `ax.type.bool` |
| `ix.type.player` | `ax.type.player` |
| `ix.type.character` | `ax.type.character` |
| `ix.type.steamid` | `ax.type.steamid` |
| `ix.type.steamid64` | `ax.type.steamid64` |

`text` behaves the same in both: it consumes the rest of the input as a single string (so an unquoted phrase can be the last argument).

---

## Permission Checks

Both frameworks use CAMI-compatible permission hooks and both accept `adminOnly` / `superAdminOnly` booleans as shortcuts:

```lua
-- Both frameworks
adminOnly = true            -- Requires admin
superAdminOnly = true       -- Requires superadmin
```

For custom checks:

```lua
-- Helix
OnCheckAccess = function(client)
    return client:GetCharacter():HasFlag("x")
end

-- Parallax
CanRun = function(caller)
    return caller:GetCharacter():HasFlag("x")
end
```

CAMI privilege registration is automatic. The privilege name differs:

| Framework | Privilege name for `/charslap` |
|---|---|
| Helix | `Helix - CharSlap` |
| Parallax | `Command - charslap` |

If your server uses ULX / sam / serverguard with hand-tuned privileges that reference the Helix names, migrate those entries to the Parallax naming.

---

## OnRun Signature

The first two arguments are the same in both frameworks: `self` (the command def) and `client` (the caller).

Helix spreads the parsed arguments as positional params:
```lua
OnRun = function(self, client, target, amount, reason)
    -- ...
end
```

Parallax packs them into a single `args` table:
```lua
OnRun = function(self, caller, args)
    local target = args[1]
    local amount = args[2]
    local reason = args[3]
end
```

The reason for the change: Parallax commands can be invoked programmatically with partial args or from console without a player, and a uniform args shape is easier to validate defensively.

If you prefer positional destructuring, do it at the top of the function:

```lua
OnRun = function(self, caller, args)
    local target, amount, reason = args[1], args[2], args[3]
    -- ...
end
```

---

## A Full Worked Example

A whisper command that supports an optional duration.

**Helix (`plugins/whisper.lua`):**
```lua
ix.command.Add("Whisper", {
    description = "Send a private whispered message to someone nearby.",
    arguments = {
        ix.type.player,
        ix.type.text,
    },
    OnRun = function(self, client, target, message)
        if ( client:GetPos():Distance(target:GetPos()) > 100 ) then
            return "@toofar"
        end

        client:ConCommand("")  -- clear chat
        target:ChatPrint(client:Name() .. " whispers: " .. message)
        client:ChatPrint("You whisper to " .. target:Name() .. ": " .. message)
    end,
})
```

**Parallax (`<your-schema>/gamemode/modules/whisper/boot.lua`):**
```lua
MODULE.name = "Whisper"

ax.command:Add("whisper", {
    displayName = "Whisper",
    description = "Send a private whispered message to someone nearby.",
    arguments = {
        { name = "target",  type = ax.type.player },
        { name = "message", type = ax.type.text },
    },
    OnRun = function(self, caller, args)
        local target  = args[1]
        local message = args[2]

        if ( !IsValid(target) ) then
            caller:Notify("Target not found.")
            return
        end

        if ( caller:GetPos():Distance(target:GetPos()) > 100 ) then
            caller:Notify("You are too far away.")
            return
        end

        target:ChatPrint(caller:Name() .. " whispers: " .. message)
        caller:ChatPrint("You whisper to " .. target:Name() .. ": " .. message)
    end,
})

return MODULE
```

Changes from the port:

- `ix.command.Add` → `ax.command:Add`.
- Name lowercased; `displayName` added.
- Arguments converted to descriptor tables with names.
- `OnRun` signature uses `args` table.
- Return-a-language-key error style (`"@toofar"`) replaced with an explicit `caller:Notify(...)`. Parallax does support phrase lookups via `ax.localization:GetPhrase("toofar")`, but `Notify` handles the display in the same line.

---

## Handling Optional Arguments

```lua
-- Helix
arguments = {
    ix.type.player,
    bit.bor(ix.type.number, ix.type.optional),
},
OnRun = function(self, client, target, amount)
    amount = amount or 1
    -- ...
end

-- Parallax
arguments = {
    { name = "target", type = ax.type.player },
    { name = "amount", type = ax.type.number, optional = true },
},
OnRun = function(self, caller, args)
    local target = args[1]
    local amount = args[2] or 1
    -- ...
end
```

Optional arguments must always come after required ones — this is true in both frameworks.

---

## Choice Restrictions

Parallax supports a built-in "one of these values" check that Helix does not:

```lua
arguments = {
    { name   = "difficulty",
      type   = ax.type.string,
      choices = {
        easy   = true,
        medium = true,
        hard   = true,
      },
    },
},
```

Input that doesn't match a key in `choices` is rejected before `OnRun` fires, and the user sees a message listing valid choices. When porting Helix commands that manually checked the first arg against a list of valid strings, move that into `choices`.

---

## Running Commands Programmatically

Both frameworks let you run a command from code:

```lua
-- Helix
ix.command.Run(client, "CharSetMoney", { targetName, "500" })

-- Parallax
ax.command:Run(caller, "charsetmoney", { targetName, "500" })
```

The raw-args form is a list of strings; the parser type-converts them as if they had been typed in chat. If you already have typed values (a player entity, a number), you can pass them directly as elements of the args table too — Parallax's converter short-circuits when the value is already the right type.

---

## Pitfalls

- **Forgetting the outer args table.** If `OnRun` is still trying to unpack positional arguments, the port is incomplete. All command bodies go through the same `args[N]` pattern.
- **`ix.type.optional` as a constant.** Does not exist; Parallax uses `optional = true` inside the descriptor.
- **Uppercase names in `ax.command:Run`.** Pass lowercase; uppercase is accepted but gets normalized.
- **Relying on Helix's `@language_key` return.** The return value from Helix's `OnRun` was displayed to the caller as a notification. Parallax's `OnRun` return value is ignored; call `caller:Notify(...)` or `ax.util:Notify(caller, ...)` explicitly.
- **CAMI privilege name changes.** If a non-Parallax admin mod has pre-configured permissions under the `Helix -` prefix, re-grant them under `Command -` or your server's command permissions won't carry over.
- **Console-only commands.** Helix had `command.bAllowConsole = false` (default false? inconsistent). Parallax defaults `bAllowConsole = true`; set it to `false` explicitly if your command requires a player caller.
- **`argumentNames` ignored.** Parallax will not error if you include `argumentNames = {...}`; it just ignores the field because names are on each arg descriptor instead. But auto-generated syntax help will look wrong if the two disagree.

---

**Next:** [`07-hooks.md`](07-hooks.md)
