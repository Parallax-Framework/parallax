--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Command system for registering and executing chat/console commands.
-- Supports arguments, permissions, aliases, and CAMI integration.
-- Automatically handles networking between client and server.
-- @module ax.command

ax.command = ax.command or {}
ax.command.registry = {}
ax.command.prefixes = ax.command.prefixes or {"/", "!"}

-- Server-side networking setup
if ( SERVER ) then
    util.AddNetworkString("ax.command.run")
end

--- Register a command with the system.
-- Creates a new command with validation, permissions, and automatic CAMI integration.
-- @realm shared
-- @param name string The command name (will be normalized)
-- @param def table Command definition with OnRun, description, arguments, etc.
-- @usage ax.command:Add("test", { description = "Test command", OnRun = function(client) end })
function ax.command:Add(name, def)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("ax.command:Add - Invalid command name provided")
        return
    end

    if ( !istable(def) ) then
        ax.util:PrintError("ax.command:Add - Invalid command definition provided for \"" .. name .. "\"")
        return
    end

    def.displayName = def.displayName or ax.util:UniqueIDToName(name)

    name = ax.util:NameToUniqueID(name)

    -- Set defaults
    def.name = name
    def.description = def.description or "No description available."
    def.arguments = def.arguments or {}
    def.bAllowConsole = def.bAllowConsole != false -- Default true
    def.adminOnly = def.adminOnly or false
    def.superAdminOnly = def.superAdminOnly or false

    if ( !def.CanRun ) then
        CAMI.RegisterPrivilege({
            Name = "Command - " .. def.name,
            MinAccess = def.superAdminOnly and "superadmin" or (def.adminOnly and "admin" or "user"),
            Description = "Allows the user to run the command: " .. def.name
        })
    end

    -- Store the command
    self.registry[name] = def
    ax.util:PrintDebug("ax.command:Add - Command \"" .. name .. "\" registered successfully")

    -- Handle aliases
    if ( def.alias ) then
        local aliases = istable(def.alias) and def.alias or {def.alias}
        for _, alias in ipairs(aliases) do
            if ( isstring(alias) and alias != "" ) then
                local normalizedAlias = string.lower(alias)
                self.registry[normalizedAlias] = def
                ax.util:PrintDebug("ax.command:Add - Alias \"" .. normalizedAlias .. "\" registered for \"" .. name .. "\"")
            end
        end
    end
end

--- Get all registered commands.
-- Returns the complete registry of all commands and their definitions.
-- @realm shared
-- @return table Table containing all command definitions
-- @usage local allCommands = ax.command:GetAll()
function ax.command:GetAll()
    return self.registry
end

--- Find all commands matching a partial name or alias.
-- Performs case-insensitive search for commands starting with the partial string.
-- @realm shared
-- @param partial string The partial string to search for
-- @return table Table of matching commands {name = def}
-- @usage local matches = ax.command:FindAll("pm")
function ax.command:FindAll(partial)
    if ( !isstring(partial) or partial == "" ) then
        return {}
    end

    partial = string.lower(partial)

    local results = {}
    for name, def in pairs(self.registry) do
        if ( string.find(name, partial, 1, true) ) then
            -- Use the original command name, not the alias
            results[def.name] = def
        end
    end

    return results
end

--- Find the closest single possible command match.
-- Returns the best matching command when multiple partial matches exist.
-- @realm shared
-- @param partial string The partial command name to search for
-- @return table|nil The closest matching command definition or nil if not found
-- @usage local command = ax.command:FindClosest("test")
function ax.command:FindClosest(partial)
    local matches = self:FindAll(partial)
    local bestMatch = nil
    local bestLength = 0
    for name, def in pairs(matches) do
        if ( string.StartWith(name, partial) ) then
            local length = #name
            if ( length > bestLength ) then
                bestLength = length
                bestMatch = def
            end
        end
    end

    return bestMatch
end

--- Check if a caller has access to run a command.
-- Validates permissions through admin checks, custom functions, and CAMI integration.
-- @realm shared
-- @param caller Entity The player or console (nil) attempting to run the command
-- @param def table The command definition
-- @return boolean, string Whether access is granted and optional reason
-- @usage local canRun, reason = ax.command:HasAccess(client, def)
function ax.command:HasAccess(caller, def)
    if ( !istable(def) ) then
        return false, "Invalid command definition"
    end

    -- Console access check
    if ( !IsValid(caller) ) then
        if ( !def.bAllowConsole ) then
            return false, "This command cannot be run from console"
        end
    else
        -- Player access checks
        if ( def.superAdminOnly and !caller:IsSuperAdmin() ) then
            return false, "You must be a super administrator to use this command"
        end

        if ( def.adminOnly and !caller:IsAdmin() ) then
            return false, "You must be an administrator to use this command"
        end
    end

    -- Custom access check
    if ( isfunction(def.CanRun) ) then
        local canRun, reason = def.CanRun(caller)
        if ( canRun == false ) then
            return false, reason or "You do not have permission to use this command"
        end
    else
        local hasAccess, err = CAMI.PlayerHasAccess(caller, "Command - " .. def.name, nil)
        if ( hasAccess == false ) then
            return false, err or "You do not have permission to use this command"
        end
    end

    return true
end

--- Extract and validate arguments from raw input string.
-- Parses command arguments according to type definitions and validates them.
-- @realm shared
-- @param def table Command definition containing argument specifications
-- @param raw string Raw argument string from user input
-- @return table|nil, string Parsed values or nil with error message
-- @usage local values, err = ax.command:ExtractArgs(def, "player1 hello world")
function ax.command:ExtractArgs(def, raw)
    raw = raw or ""

    -- Tokenize the input, respecting quoted strings
    local tokens = ax.util:TokenizeString(raw)
    local values = {}
    local tokenIndex = 1

    for i, argDef in ipairs(def.arguments) do
        local value = nil
        local hasValue = tokenIndex <= #tokens

        -- Handle optional arguments
        if ( !hasValue ) then
            if ( !argDef.optional ) then
                return nil, "Missing required argument: " .. argDef.name
            else
                break -- Skip remaining optional arguments
            end
        end

        -- Handle ax.type.text type - consumes rest of line
        if ( argDef.type == ax.type.text ) then
            local remaining = {}
            for j = tokenIndex, #tokens do
                remaining[ #remaining + 1 ] = tokens[j]
            end

            value = table.concat(remaining, " ")
            tokenIndex = #tokens + 1
        else
            value = tokens[tokenIndex]
            tokenIndex = tokenIndex + 1
        end

        -- Type coercion and validation
        local convertedValue, err = self:ConvertArgument(value, argDef)
        if ( err ) then
            return nil, "Invalid argument '" .. argDef.name .. "': " .. err
        end

        values[i] = convertedValue
    end

    return values
end

--[[
    Parse command text into name and raw arguments.
    @realm shared
    @param string text The full command text
    @return string|nil, string Command name and raw arguments
    @usage local name, rawArgs = ax.command:Parse("/pm player1 hello")
]]
function ax.command:Parse(text)
    if ( !isstring(text) or text == "" ) then
        return nil, ""
    end

    text = string.Trim(text)

    -- Strip common prefixes
    for _, prefix in ipairs(self.prefixes) do
        if ( string.StartWith(text, prefix) ) then
            text = string.sub(text, #prefix + 1)
            break
        end
    end

    text = string.Trim(text)

    -- Split first word from rest
    local spacePos = string.find(text, " ")
    if ( spacePos ) then
        local name = string.lower(string.sub(text, 1, spacePos - 1))
        local rawArgs = string.Trim(string.sub(text, spacePos + 1))
        return name, rawArgs
    else
        return string.lower(text), ""
    end
end

--[[
    Run a command with the given caller and arguments.
    @realm server
    @param Entity caller The player or console attempting to run the command
    @param string name The command name
    @param string rawArgs Raw argument string
    @return bool, string Success status and result/error message
    @usage local ok, result = ax.command:Run(client, "pm", "player1 hello")
]]
function ax.command:Run(caller, name, rawArgs)
    if ( !isstring(name) or name == "" ) then
        return false, "Invalid command name"
    end

    name = string.lower(name)

    local def = self.registry[name]
    if ( !def ) then
        return false, "Unknown command: " .. name
    end

    -- Access check
    local hasAccess, reason = self:HasAccess(caller, def)
    if ( !hasAccess ) then
        return false, reason
    end

    -- Extract arguments
    local values, err = self:ExtractArgs(def, rawArgs)
    if ( err ) then
        return false, err
    end

    -- Run the appropriate handler
    local handler = nil
    if ( !IsValid(caller) and def.OnConsole ) then
        handler = def.OnConsole
    elseif ( def.OnRun ) then
        handler = def.OnRun
    else
        return false, "Command has no handler defined"
    end

    -- Execute the command
    local success, result = pcall(handler, caller, unpack(values or {}))
    if ( !success ) then
        ax.util:PrintError("ax.command:Run - Error executing command \"" .. name .. "\": " .. tostring(result))
        return false, "Command execution failed"
    end

    return true, result
end

--[[
    Send a command from client to server for execution.
    @realm client
    @param string text The full command text
    @usage ax.command:Send("/pm player1 hello")
]]
function ax.command:Send(text)
    if ( SERVER ) then
        ax.util:PrintError("ax.command:Send - Cannot send from server")
        return
    end

    local name, rawArgs = self:Parse(text)
    if ( !name or name == "" ) then
        ax.util:PrintError("ax.command:Send - Invalid command format")
        return
    end

    -- Basic client-side validation
    local def = self.registry[name]
    if ( !def ) then
        ax.util:PrintError("ax.command:Send - Unknown command: " .. name)
        return
    end

    -- Send to server
    net.Start("ax.command.run")
        net.WriteString(name)
        net.WriteString(rawArgs)
    net.SendToServer()
end

--[[
    Generate a help string for a command.
    @realm shared
    @param string name The command name
    @return string Help text
    @usage local help = ax.command:Help("pm")
]]
function ax.command:Help(name)
    if ( !isstring(name) ) then
        return "Invalid command name"
    end

    local def = self.registry[string.lower(name)]
    if ( !def ) then
        return "Unknown command: " .. name
    end

    local parts = {def.name}

    for _, argDef in ipairs(def.arguments) do
        local argStr = argDef.name
        if ( argDef.optional ) then
            argStr = "[" .. argStr .. "]"
        else
            argStr = "<" .. argStr .. ">"
        end
        parts[ #parts + 1 ] = argStr
    end

    local usage = table.concat(parts, " ")
    return usage .. " - " .. def.description
end

-- Server-side network receiver
if ( SERVER ) then
    net.Receive("ax.command.run", function(len, caller)
        if ( !IsValid(caller) ) then return end

        local name = net.ReadString()
        local rawArgs = net.ReadString()

        local ok, result = ax.command:Run(caller, name, rawArgs)
        if ( !ok ) then
            caller:Notify(result or "Unknown error", "error")
        elseif ( result and result != "" ) then
            caller:Notify(tostring(result))
        end
    end)
end

-- Internal helper functions

--[[
    Convert and validate a single argument value.
    @realm shared
    @param string value The raw string value
    @param table argDef The argument definition
    @return any|nil, string Converted value or nil with error
]]
function ax.command:ConvertArgument(value, argDef)
    if ( argDef.type == ax.type.string or argDef.type == ax.type.text ) then
        if ( argDef.choices and !argDef.choices[value] ) then
            local validChoices = table.GetKeys(argDef.choices)
            return nil, "must be one of: " .. table.concat(validChoices, ", ")
        end

        return value
    elseif ( argDef.type == ax.type.number ) then
        local num = tonumber(value)
        if ( !num ) then
            return nil, "must be a number"
        end

        if ( argDef.min and num < argDef.min ) then
            return nil, "must be at least " .. argDef.min
        end

        if ( argDef.max and num > argDef.max ) then
            return nil, "must be at most " .. argDef.max
        end

        if ( argDef.decimals ) then
            num = math.Round(num, argDef.decimals)
        end

        return num
    elseif ( argDef.type == ax.type.bool ) then
        local lower = string.lower(value)
        if ( lower == "true" or lower == "1" or lower == "yes" ) then
            return true
        elseif ( lower == "false" or lower == "0" or lower == "no" ) then
            return false
        else
            return nil, "must be true/false, 1/0, or yes/no"
        end

    elseif ( argDef.type == ax.type.player ) then
        local foundPlayer = ax.util:FindPlayer(value)
        if ( !IsValid(foundPlayer) ) then
            return nil, "player not found or ambiguous match"
        end

        return foundPlayer
    elseif ( argDef.type == ax.type.character ) then
        local foundChar = ax.util:FindCharacter(value)
        if ( !foundChar ) then
            return nil, "character not found or ambiguous match"
        end

        return foundChar
    else
        return nil, "unknown argument type: " .. argDef.type
    end
end

-- Console command integration for server
if ( SERVER ) then
    concommand.Add("ax_command", function(caller, cmd, args, argStr)
        if ( !argStr or argStr == "" ) then
            if ( IsValid(caller) ) then
                caller:Notify("Usage: ax_command <command> [arguments]", "info")
            else
                print("Usage: ax_command <command> [arguments]")
            end
            return
        end

        local name, rawArgs = ax.command:Parse(argStr)
        if ( !name or name == "" ) then
            local msg = "Invalid command format"
            if ( IsValid(caller) ) then
                caller:Notify(msg, "error")
            else
                print(msg)
            end
            return
        end

        local ok, result = ax.command:Run(caller, name, rawArgs)

        if ( !ok ) then
            local msg = "" .. (result or "Unknown error")
            if ( IsValid(caller) ) then
                caller:Notify(msg, "error")
            else
                print(msg)
            end
        elseif ( result and result != "" ) then
            local msg = tostring(result)
            if ( IsValid(caller) ) then
                caller:Notify(msg)
            else
                print(msg)
            end
        end
    end)
end
