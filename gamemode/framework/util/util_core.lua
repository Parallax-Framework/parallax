--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility helpers used across the Parallax framework (printing, file handling, text utilities, etc.).
-- @module ax.util

--- Converts between a JSON string and a Lua table safely.
-- Two modes depending on the inputs:
-- - When `bToJson` is true and `tInput` is a table, serialises the table to a JSON string via `util.TableToJSON` and returns it.
-- - Otherwise, if `tInput` is a string, parses it as JSON via `util.JSONToTable` (wrapped in pcall) and returns the resulting table, or nil on parse failure. If `tInput` is already a table it is returned unchanged — useful for APIs that accept either form.
-- Errors are reported through `PrintError` and never thrown.
-- @realm shared
-- @param tInput string|table The JSON string to parse, or a table to pass through (or serialise when `bToJson` is true).
-- @param bToJson boolean|nil When true and `tInput` is a table, converts it to a JSON string instead of parsing.
-- @return table|string|nil The parsed table, the serialised JSON string, or nil on failure.
-- @usage local tbl = ax.util:SafeParseTable('{"key":"value"}')
-- local json = ax.util:SafeParseTable({ key = "value" }, true)
function ax.util:SafeParseTable(tInput, bToJson)
    if ( bToJson == true and istable(tInput) ) then
        return util.TableToJSON(tInput)
    end

    if ( isstring(tInput) ) then
        local success, result = pcall(util.JSONToTable, tInput)
        if ( success ) then
            return result
        else
            self:PrintError("SafeParseTable: failed to parse JSON string:", result)
            return nil
        end
    elseif ( istable(tInput) ) then
        return tInput
    end

    return nil
end

--- Calls a function safely, capturing any Lua error without throwing.
-- NOTE: This definition is overwritten later in this file by a second, simpler SafeCall. See the authoritative definition below for the live behaviour.
-- This version prints the error via `PrintError` and unpacks all return values; the later version returns only the first return value.
-- @realm shared
-- @param fn function The function to call. Returns false immediately if not a function.
-- @param ... any Arguments forwarded to `fn`.
-- @return boolean True if the call succeeded without error.
-- @return any All values returned by `fn` when successful.
-- @usage local ok, a, b = ax.util:SafeCall(function() return 1, 2 end)
function ax.util:SafeCall(fn, ...)
    if ( !isfunction(fn) ) then return false end

    local results = { pcall(fn, ...) }
    local ok = results[1]

    if ( !ok ) then
        -- results[2] is the error message
        self:PrintError("SafeCall: function threw an error: ", results[2])
        return false
    end

    -- Remove the boolean success and return remaining values
    table.remove(results, 1)

    return true, table.unpack(results)
end

--- Converts a human-readable name into a lowercase, underscore-separated ID.
-- Applies three transformations in order:
-- 1. Spaces (including runs of whitespace) are replaced with underscores.
-- 2. CamelCase boundaries (lowercase letter followed by uppercase) get an underscore inserted between them, e.g. "MyModule" → "My_Module".
-- 3. Any character that is not a letter (A–Z, a–z) or underscore is stripped, so digits and punctuation are removed entirely.
-- 4. The result is lowercased.
-- @realm shared
-- @param name string The human-readable name to convert.
-- @return string A sanitised lowercase unique ID safe for use as a table key or module identifier.
-- @usage ax.util:NameToUniqueID("My Module")  -- "my_module"
-- ax.util:NameToUniqueID("MyModule")           -- "my_module"
-- ax.util:NameToUniqueID("Faction 01")         -- "faction_" (digits stripped)
function ax.util:NameToUniqueID(name)
    -- Replace spaces with underscores
    name = name:gsub("%s+", "_")

    -- CamcelCase to underscores
    name = name:gsub("([a-z])([A-Z])", "%1_%2")

    -- Remove everything not in A-Z, a-z, or underscore
    name = name:gsub("[^A-Za-z_]", "")

    -- Convert to lowercase
    return name:lower()
end

--- Converts an underscore-separated unique ID to PascalCase.
-- Each underscore followed by a lowercase letter triggers capitalisation of that letter and removal of the underscore. The very first character is also capitalised. Any character that is not alphanumeric is then stripped from the final result. Returns an empty string when `id` is not a string.
-- @realm shared
-- @param id string The unique ID to convert (e.g. produced by `NameToUniqueID`).
-- @return string The PascalCase equivalent with non-alphanumeric characters removed.
-- @usage ax.util:UniqueIDToCamel("my_module")       -- "MyModule"
-- ax.util:UniqueIDToCamel("item_type_id")           -- "ItemTypeId"
function ax.util:UniqueIDToCamel(id)
    if ( !isstring(id) ) then return "" end

    local result = id:gsub("_([a-z])", function(letter)
        return letter:upper()
    end)

    result = result:gsub("^([a-z])", function(letter)
        return letter:upper()
    end)

    result = result:gsub("[^A-Za-z]", "")

    return result
end

--- Converts an underscore-separated unique ID back into a human-readable name.
-- Applies three transformations in order:
-- 1. Underscores are replaced with spaces.
-- 2. Spaces are inserted at CamelCase boundaries (e.g. from an ID that was produced by merging camel-cased words).
-- 3. The first letter of each word is capitalised and the rest are lowercased.
-- Useful for displaying stored IDs in UI labels without extra formatting logic.
-- @realm shared
-- @param id string The unique ID to convert.
-- @return string A title-cased, space-separated name.
-- @usage ax.util:UniqueIDToName("my_module")      -- "My Module"
-- ax.util:UniqueIDToName("player_health_max")     -- "Player Health Max"
function ax.util:UniqueIDToName(id)
    -- Replace underscores with spaces
    local name = id:gsub("_", " ")

    -- Insert spaces before uppercase letters (for camelCase or PascalCase)
    name = name:gsub("([a-z])([A-Z])", "%1 %2")

    -- Capitalize the first letter of each word
    name = name:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)

    return name
end

--- Converts a key/value map into a sorted array of entry objects.
-- Each entry in the returned array is a table `{ key = k, value = v }`.
-- The default sort order is case-insensitive lexicographic by key; when two keys are equal after lowercasing, the original (case-sensitive) key string is used as a tiebreaker so the order is stable and predictable.
-- Provide a custom `comparator(a, b)` (where `a` and `b` are entry tables) to override the sort. Returns an empty table if `entries` is not a table.
-- @realm shared
-- @param entries table The key/value map to convert and sort.
-- @param comparator function|nil Optional sort function receiving two entry tables. Should return true when `a` should come before `b`.
-- @return table Sorted array of `{ key, value }` entry tables.
-- @usage local sorted = ax.util:GetSortedEntries(ax.faction:GetAll())
-- for _, entry in ipairs(sorted) do print(entry.key, entry.value.name) end
function ax.util:GetSortedEntries(entries, comparator)
    local sorted = {}

    if ( !istable(entries) ) then
        return sorted
    end

    for key, value in pairs(entries) do
        sorted[#sorted + 1] = {
            key = key,
            value = value
        }
    end

    table.sort(sorted, comparator or function(a, b)
        local keyA = string.lower(tostring(a.key))
        local keyB = string.lower(tostring(b.key))

        if ( keyA == keyB ) then
            return tostring(a.key) < tostring(b.key)
        end

        return keyA < keyB
    end)

    return sorted
end

local stored = {}

--- Returns a cached `IMaterial`, creating it on first use.
-- Materials are cached by a compound key of `path` and `parameters` so that the same path with different parameter strings produces distinct cache entries. `parameters` defaults to `""` — callers that omit it get a different cache slot from those that pass an empty string explicitly only if they use a different string value.
-- Prints an error and returns false when `path` is nil/false.
-- @realm shared
-- @param path string The material path (e.g. `"sprites/glow"`).
-- @param parameters string|nil Optional parameter string forwarded to `Material()` (e.g. `"nocull noclamp smooth"`).
-- @return IMaterial|false The cached or newly created material, or false on invalid path.
-- @usage local mat = ax.util:GetMaterial("sprites/glow", "nocull")
-- local icon = ax.util:GetMaterial("vgui/icon_item")
function ax.util:GetMaterial(path, parameters)
    if ( !tostring(path) ) then
        ax.util:PrintError("Attempted to get a material with no path", path, parameters)
        return false
    end

    parameters = tostring(parameters or "")
    local uniqueID = Format("material.%s.%s", path, parameters)

    if ( stored[uniqueID] ) then
        return stored[uniqueID]
    end

    local mat = Material(path, parameters)
    stored[uniqueID] = mat

    return mat
end

if ( CLIENT ) then
    --- Draws a blurred, optionally rounded rectangle on the screen.
    -- Thin wrapper around `ax.render.Draw` using `ax.render.BLUR` mode.
    -- The blur is rendered over whatever is already on screen at that region, making it useful for frosted-glass UI elements. Alpha on `color` controls the overall opacity of the blur overlay.
    -- @realm client
    -- @param r number Corner roundness in pixels (0 for a sharp rectangle).
    -- @param x number Left edge of the rectangle in screen pixels.
    -- @param y number Top edge of the rectangle in screen pixels.
    -- @param width number Width of the rectangle in pixels.
    -- @param height number Height of the rectangle in pixels.
    -- @param color Color Color applied over the blur; alpha controls opacity.
    -- @usage ax.util:DrawBlur(8, 10, 10, 200, 100, Color(255, 255, 255, 180))
    function ax.util:DrawBlur(r, x, y, width, height, color)
        ax.render.Draw(r, x, y, width, height, color, ax.render.BLUR)
    end

    --- Resolves a short gradient direction name to a GMod vgui material path.
    -- Accepted short names and their aliases (case-insensitive):
    -- - `"left"` / `"l"` / `1`  → `"vgui/gradient-l"`
    -- - `"right"` / `"r"` / `2` → `"vgui/gradient-r"`
    -- - `"top"` / `"up"` / `"u"` / `3` → `"vgui/gradient-u"`
    -- - `"bottom"` / `"down"` / `"d"` / `4` → `"vgui/gradient-d"`
    -- Any unrecognised string is returned as-is, allowing full material paths to be passed through without translation. An empty or non-string `name` defaults to `"vgui/gradient-l"`.
    -- @realm client
    -- @param name string A direction alias or a full material path.
    -- @return string The resolved material path.
    -- @usage ax.util:GetGradientPath("right")          -- "vgui/gradient-r"
    -- ax.util:GetGradientPath("vgui/my_gradient")      -- "vgui/my_gradient"
    function ax.util:GetGradientPath(name)
        if ( !isstring(name) or name == "" ) then return "vgui/gradient-l" end

        local lname = utf8.lower(name)
        if ( lname == "left" or lname == "l" or lname == 1 ) then return "vgui/gradient-l" end
        if ( lname == "right" or lname == "r" or lname == 2 ) then return "vgui/gradient-r" end
        if ( lname == "top" or lname == "up" or lname == "u" or lname == 3 ) then return "vgui/gradient-u" end
        if ( lname == "bottom" or lname == "down" or lname == "d" or lname == 4 ) then return "vgui/gradient-d" end

        -- If it looks like a material path, return it as-is
        return tostring(name)
    end

    --- Returns a cached gradient `IMaterial` by direction name or path.
    -- Resolves `name` to a path via `GetGradientPath`, then fetches or creates the material via `GetMaterial`. Subsequent calls with the same name are served from the material cache at no extra cost.
    -- @realm client
    -- @param name string A direction alias (`"left"`, `"right"`, etc.) or a full material path. See `GetGradientPath` for all accepted values.
    -- @return IMaterial The corresponding gradient material.
    -- @usage local mat = ax.util:GetGradient("bottom")
    function ax.util:GetGradient(name)
        local path = self:GetGradientPath(name)
        return self:GetMaterial(path)
    end

    --- Draws a gradient material tinted with a color on the screen.
    -- Resolves the gradient via `GetGradient(name)`, then draws it using `ax.render.DrawMaterial` with optional corner rounding and tint color. When `color` is omitted, an opaque white tint is used (no tinting).
    -- @realm client
    -- @param r number Corner roundness in pixels (0 for a sharp rectangle).
    -- @param name string A direction alias (`"left"`, `"right"`, etc.) or a full material path. See `GetGradientPath` for all accepted aliases.
    -- @param x number Left edge of the draw area in screen pixels.
    -- @param y number Top edge of the draw area in screen pixels.
    -- @param w number Width of the draw area in pixels.
    -- @param h number Height of the draw area in pixels.
    -- @param color Color|nil Optional tint applied to the gradient texture. Alpha controls overall opacity. Defaults to `Color(255, 255, 255, 255)`.
    -- @usage ax.util:DrawGradient(0, "left", 0, 0, 200, 400, Color(0, 0, 0, 200))
    -- ax.util:DrawGradient(4, "right", ScrW() - 64, 0, 64, ScrH())
    function ax.util:DrawGradient(r, name, x, y, w, h, color)
        local mat = self:GetGradient(name)
        if ( !mat ) then return end

        color = color or Color(255, 255, 255, 255)

        ax.render.DrawMaterial(r, x, y, w, h, color, mat)
    end
end

--- Calls a function safely, capturing any Lua error without throwing.
-- This is the authoritative definition — it overwrites the earlier one in this file. Uses `pcall` to protect the call; if `fn` is not a function it returns `false, "Not a function"` immediately. On error the error message string is returned as the second value. On success the first return value of `fn` is returned; additional return values from `fn` are silently discarded.
-- Unlike the overwritten version above, errors are NOT printed automatically — check the returned boolean and handle the error message yourself.
-- @realm shared
-- @param fn function The function to call.
-- @param ... any Arguments forwarded to `fn`.
-- @return boolean True if the call succeeded without error.
-- @return any The first return value of `fn` on success, or the error message string on failure.
-- @usage local ok, result = ax.util:SafeCall(function() return 123 end)
-- local ok, err = ax.util:SafeCall(maybeNilFn, arg1, arg2)
-- if ( !ok ) then ax.util:PrintError(err) end
function ax.util:SafeCall(fn, ...)
    if ( !isfunction(fn) ) then
        return false, "Not a function"
    end

    local ok, result = pcall(fn, ...)
    return ok, result
end

--- Clamps a number to a range, then rounds it to a given precision.
-- Clamping is applied first, so the rounded result is always within `[min, max]`. When `decimals` is 0 or omitted, `math.Round` is used (nearest integer). For positive `decimals`, the number is scaled by `10^decimals`, rounded, then scaled back, preserving that many decimal places. `min` and `max` are both optional; pass nil to skip either bound.
-- Non-numeric input for `n` is treated as 0.
-- @realm shared
-- @param n number The number to clamp and round.
-- @param min number|nil Lower bound (inclusive). Skipped when nil.
-- @param max number|nil Upper bound (inclusive). Skipped when nil.
-- @param decimals number|nil Number of decimal places to preserve (default 0).
-- @return number The clamped and rounded result.
-- @usage ax.util:ClampRound(3.14159, 0, 10, 2)  -- 3.14
-- ax.util:ClampRound(150, 0, 100)                -- 100
-- ax.util:ClampRound(4.6)                        -- 5
function ax.util:ClampRound(n, min, max, decimals)
    local num = tonumber(n) or 0

    if ( min and num < min ) then num = min end
    if ( max and num > max ) then num = max end

    if ( decimals and decimals > 0 ) then
        local mult = 10 ^ decimals
        num = math.Round(num * mult) / mult
    else
        num = math.Round(num)
    end

    return num
end

--- Scales a 0–1 progress fraction by a smoothness percentage.
-- This is a low-level helper used by `ApproachNumber`, `ApproachVector`, and `ApproachAngle`. `smooth` is expressed as a percentage (0–100): a value of 100 leaves the fraction unchanged; lower values compress it toward 0, making transitions feel slower or more eased. The result is always clamped to [0, 1] regardless of input.
-- `linear` is accepted for signature compatibility but does not currently alter the calculation — the distinction between linear and non-linear movement is handled at the `ApproachNumber` level.
-- @realm shared
-- @param fraction number The raw progress fraction, expected in [0, 1].
-- @param smooth number Smoothness multiplier as a percentage (0–100). Defaults to 100 (no scaling) when nil or non-numeric.
-- @param linear boolean|nil Reserved for future use; has no effect currently.
-- @return number The scaled and clamped fraction in [0, 1].
-- @usage local t = ax.util:ApproachFraction(0.5, 80) -- 0.4
function ax.util:ApproachFraction(fraction, smooth, linear)
    local frac = tonumber(fraction) or 0
    local smoothValue = tonumber(smooth) or 100

    frac = math.Clamp(frac, 0, 1)
    smoothValue = math.Clamp(smoothValue, 0, 100)

    frac = frac * (smoothValue * 0.01)

    return math.Clamp(frac, 0, 1)
end

--- Interpolates a number from `start` to `finish` using a progress fraction.
-- The fraction is first passed through `ApproachFraction` using `opts.smooth` (default 100, i.e. no compression). The transition mode then determines how the adjusted fraction maps to the final value:
-- - `"lerp"` (default): standard linear interpolation via `Lerp`.
-- - `"smoothstep"`: applies a cubic ease-in/ease-out curve (`t² × (3 − 2t)`) before lerping, producing a gentle S-curve acceleration/deceleration.
-- - `"linear"` or `opts.linear = true`: uses `math.Approach`, which moves at a constant step-size per call rather than lerping, useful for physics-style clamped movement.
-- @realm shared
-- @param fraction number Progress fraction in [0, 1].
-- @param start number The value at fraction = 0.
-- @param finish number The value at fraction = 1.
-- @param opts table|nil Optional settings table: `smooth` number (0–100) smoothness percent passed to `ApproachFraction`; `linear` boolean when true forces the `"linear"` transition mode; `transition` string `"lerp"` | `"smoothstep"` | `"linear"`.
-- @return number The interpolated value between `start` and `finish`.
-- @usage local v = ax.util:ApproachNumber(0.5, 0, 100)                  -- 50
-- local v = ax.util:ApproachNumber(0.5, 0, 100, { transition = "smoothstep" })
function ax.util:ApproachNumber(fraction, start, finish, opts)
    local smooth = opts and opts.smooth or 100
    local bLinear = opts and opts.linear or false
    local transition = opts and opts.transition or "lerp"

    local t = self:ApproachFraction(fraction, smooth, bLinear)

    if ( transition == "smoothstep" ) then
        t = t * t * (3 - 2 * t)
    end

    if ( transition == "linear" or bLinear ) then
        return math.Approach(start, finish, t * math.abs(finish - start))
    end

    return Lerp(t, start, finish)
end

--- Interpolates a Vector component-wise from `startVec` to `finishVec`.
-- Delegates to `ApproachNumber` independently for X, Y, and Z and assembles the results into a new `Vector`. All transition modes and smoothness options supported by `ApproachNumber` work here too. Useful for smoothly animating world positions or velocities over time in a `Think` hook.
-- @realm shared
-- @param fraction number Progress fraction in [0, 1].
-- @param startVec Vector The starting vector (fraction = 0).
-- @param finishVec Vector The target vector (fraction = 1).
-- @param opts table|nil Options forwarded to `ApproachNumber` (smooth, linear, transition).
-- @return Vector The interpolated vector.
-- @usage local pos = ax.util:ApproachVector(fraction, startPos, endPos, { smooth = 80 })
function ax.util:ApproachVector(fraction, startVec, finishVec, opts)
    return Vector(
        self:ApproachNumber(fraction, startVec.x, finishVec.x, opts),
        self:ApproachNumber(fraction, startVec.y, finishVec.y, opts),
        self:ApproachNumber(fraction, startVec.z, finishVec.z, opts)
    )
end

--- Interpolates an Angle component-wise from `startAng` to `finishAng`.
-- Delegates to `ApproachNumber` independently for pitch (p), yaw (y), and roll (r) and assembles the results into a new `Angle`. Note that raw lerping of angles can wrap unexpectedly near 180°/−180° boundaries; for large yaw sweeps, normalise the angles before calling this function.
-- @realm shared
-- @param fraction number Progress fraction in [0, 1].
-- @param startAng Angle The starting angle (fraction = 0).
-- @param finishAng Angle The target angle (fraction = 1).
-- @param opts table|nil Options forwarded to `ApproachNumber` (smooth, linear, transition).
-- @return Angle The interpolated angle.
-- @usage local ang = ax.util:ApproachAngle(fraction, eyeAng, targetAng)
function ax.util:ApproachAngle(fraction, startAng, finishAng, opts)
    return Angle(
        self:ApproachNumber(fraction, startAng.p, finishAng.p, opts),
        self:ApproachNumber(fraction, startAng.y, finishAng.y, opts),
        self:ApproachNumber(fraction, startAng.r, finishAng.r, opts)
    )
end

--- Returns true if `client` is a player entity.
-- Checks the Lua type string via `type()` rather than `IsValid()`, so it is safe to call on any value including nil, non-entity tables, or invalid entities (which would make `IsValid()` error). Use this instead of `IsValid(client) and client:IsPlayer()` when you don't yet know whether the value is even an entity.
-- @realm shared
-- @param client any The value to test.
-- @return boolean True if `client` has Lua type `"Player"`.
-- @usage if ( ax.util:IsValidPlayer(client) ) then
--     client:ChatPrint("hello")
-- end
function ax.util:IsValidPlayer(client)
    return type(client) == "Player"
end

--- Returns the world position and angle of an entity's head.
-- Checks for the `"eyes"` attachment first; if found and valid, its position and angle are returned. Falls back to the `ValveBiped.Bip01_Head1` bone when the attachment is absent or returns no data. Returns nil for both values when neither source is available (e.g. a prop with no skeleton).
-- A debug axis overlay is drawn at the resolved position for 0.1 seconds — this is intentional for development use.
-- @realm shared
-- @param entity Entity The entity to inspect (player, NPC, or ragdoll).
-- @return Vector|nil World position of the head, or nil when not found.
-- @return Angle|nil World angle at the head, or nil when not found.
-- @usage local headPos, headAng = ax.util:GetHeadTransform(entity)
-- if ( headPos ) then -- render something at head level end
function ax.util:GetHeadTransform(entity)
    if ( !IsValid(entity) ) then return end

    local eyeAttachment = entity:LookupAttachment("eyes")
    if ( isnumber(eyeAttachment) and eyeAttachment > 0 ) then
        local eyeData = entity:GetAttachment(eyeAttachment)
        if ( eyeData and eyeData.Pos ) then
            debugoverlay.Axis(eyeData.Pos, eyeData.Ang, 16, 0.1, false)
            return eyeData.Pos, eyeData.Ang
        end
    end

    local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")
    if ( !isnumber(headBone) ) then return end

    local bonePos, boneAng = entity:GetBonePosition(headBone)
    if ( bonePos and boneAng ) then
        debugoverlay.Axis(bonePos, boneAng, 16, 0.1, false)
        return bonePos, boneAng
    end

    return nil
end

--- Splits a string into tokens, preserving quoted multi-word segments.
-- Iterates the string character-by-character. Space characters split tokens unless the parser is inside a quoted region (`"`). Backslash (`\`) escapes the next character, so `\"` includes a literal quote in the current token without ending or starting a quoted region. Empty tokens (consecutive spaces) are skipped. Useful for parsing console-style commands where arguments can contain spaces when wrapped in double quotes.
-- @realm shared
-- @param str string The input string to tokenise.
-- @return table An ordered array of token strings.
-- @usage ax.util:TokenizeString('kick "John Doe" "bad behaviour"')
-- -- { "kick", "John Doe", "bad behaviour" }
-- ax.util:TokenizeString('set volume 0.5')
-- -- { "set", "volume", "0.5" }
function ax.util:TokenizeString(str)
    if ( !isstring(str) or str == "" ) then
        return {}
    end

    local tokens = {}
    local current = ""
    local inQuotes = false
    local escapeNext = false

    for i = 1, #str do
        local char = string.sub(str, i, i)

        if ( escapeNext ) then
            current = current .. char
            escapeNext = false
        elseif ( char == "\\" ) then
            escapeNext = true
        elseif ( char == "\"" ) then
            inQuotes = !inQuotes
        elseif ( char == " " and !inQuotes ) then
            if ( current != "" ) then
                tokens[ #tokens + 1 ] = current
                current = ""
            end
        else
            current = current .. char
        end
    end

    -- Add final token if exists
    if ( current != "" ) then
        tokens[ #tokens + 1 ] = current
    end

    return tokens
end

--- Sanitises an arbitrary string so it is safe to use in file names and paths.
-- Any character that is not alphanumeric (`A–Z`, `a–z`, `0–9`), a hyphen (`-`), underscore (`_`), or period (`.`) is replaced with an underscore.
-- The value is coerced to string via `tostring` before processing. Returns `""` when `key` is nil or false.
-- @realm shared
-- @param key any The value to sanitise (coerced to string).
-- @return string A filesystem-safe string.
-- @usage ax.util:SanitizeKey("Player:Test")      -- "Player_Test"
-- ax.util:SanitizeKey("config/sub dir/file")     -- "config_sub_dir_file"
-- ax.util:SanitizeKey("my.setting_key-v2")       -- "my.setting_key-v2"
function ax.util:SanitizeKey(key)
    if ( !key ) then return "" end

    -- Replace any path unfriendly characters with underscore
    return string.gsub(tostring(key), "[^%w%-_.]", "_")
end

--- Returns the active gamemode's folder name, used as a data namespace.
-- Calls `engine.ActiveGamemode()` to read the folder name of the gamemode currently running (e.g. `"parallax"` or `"parallax-militaryrp"`). Falls back to the literal string `"parallax"` if the engine API is unavailable.
-- This value is used by functions like `BuildDataPath` to scope persisted data files per-gamemode so derived gamemodes don't collide with each other.
-- @realm shared
-- @return string The active gamemode folder name, or `"parallax"` as a safe fallback.
-- @usage local project = ax.util:GetProjectName() -- e.g. "parallax-militaryrp"
function ax.util:GetProjectName()
    -- Try to detect active gamemode folder; fall back to 'parallax'
    if ( engine and engine.ActiveGamemode ) then
        return engine.ActiveGamemode() or "parallax"
    end

    return "parallax"
end

--- Returns the server's network address, IP, and port as separate values.
-- Calls `game.GetIPAddress()` first. On the server side, falls back to the `sv_ip` convar if the primary call returns an empty string. Parses the resulting `"ip:port"` string into its components; the port defaults to 0 when not present in the string. Returns three nils when no address can be determined, and logs a debug message.
-- @realm shared
-- @return string|nil The full `"ip:port"` address string, or nil on failure.
-- @return string|nil The IP portion only (may be `"0.0.0.0"` on listen servers before a map is fully loaded).
-- @return number|nil The port number, or 0 when absent from the address.
-- @usage local full, ip, port = ax.util:GetServerAddress()
-- if ( full ) then print("Server running at " .. full) end
function ax.util:GetServerAddress()
    local addr = nil

    if ( game and game.GetIPAddress ) then
        addr = game.GetIPAddress() or ""
    end

    -- Fallbacks if game.GetIPAddress isn't available or is empty
    if ( (addr == "" or addr == nil) and SERVER and GetConVar ) then
        -- sv_ip is rarely set, but try it as a best-effort fallback
        local svip = GetConVar("sv_ip")
        if ( svip ) then
            addr = svip:GetString() or ""
        end
    end

    if ( addr == "" or !isstring(addr) ) then
        self:PrintDebug("GetServerAddress: no address detected")
        return nil, nil, nil
    end

    -- Parse "ip:port" (port optional)
    local ip, port = string.match(addr, "^([^:]+):?(%d*)$")
    port = tonumber(port) or 0

    return addr, ip, port
end

--- Returns the surface data table for a named physics surface material.
-- Looks up the internal surface index with `util.GetSurfaceIndex`, then retrieves the data table via `util.GetSurfaceData`. Returns nil when the name is not registered (index 0) or when `surfaceName` is nil/false.
-- Surface names are defined in `scripts/surfaceproperties.txt` and its includes (e.g. `"concrete"`, `"metal"`, `"wood"`).
-- @realm shared
-- @param surfaceName string The physics surface material name to look up.
-- @return table|nil The surface data table, or nil if the name is unknown.
-- @usage local data = ax.util:GetSurfaceDataViaName("metal")
-- if ( data ) then print(data.jumpfactor) end
function ax.util:GetSurfaceDataViaName(surfaceName)
    if ( !surfaceName ) then return nil end

    local idx = util.GetSurfaceIndex(surfaceName)
    if ( idx == 0 ) then return nil end

    return util.GetSurfaceData(idx)
end

--- Returns the surface data table for the surface hit by a trace result.
-- Reads `tr.SurfaceProps` (the internal physics surface index stored in every trace result) and forwards it to `util.GetSurfaceData`. Returns nil when the trace missed (`tr.Hit` is false), when `tr` is nil, or when `SurfaceProps` is 0 (no valid surface). Pair with `util.TraceLine` or `util.TraceEntity` to get the trace result.
-- @realm shared
-- @param tr table A trace result table as returned by `util.TraceLine` or similar. Must have `Hit` and `SurfaceProps` fields.
-- @return table|nil The surface data table, or nil if the trace missed or has no valid surface properties.
-- @usage local tr = util.TraceLine({ start = eyePos, endpos = eyePos + eyeDir * 256, filter = client })
-- local data = ax.util:GetSurfaceDataViaTrace(tr)
-- if ( data ) then print(data.material) end
function ax.util:GetSurfaceDataViaTrace(tr)
    if ( !tr or !tr.Hit ) then return nil end
    if ( !tr.SurfaceProps or tr.SurfaceProps == 0 ) then return nil end

    return util.GetSurfaceData(tr.SurfaceProps)
end

if ( CLIENT ) then
    --- Scales a pixel value by the player's UI scale preference.
    -- Reads the `interface.scale` option (default 1.0) and multiplies `value` by it. Use this for any hardcoded pixel dimension that should respect the user's interface scale setting (panel sizes, font sizes, offsets, etc.).
    -- @realm client
    -- @param value number The base pixel value to scale.
    -- @return number The value multiplied by the current UI scale factor.
    -- @usage local w = ax.util:Scale(200)  -- 200 at 1.0x, 240 at 1.2x
    function ax.util:Scale(value)
        local uiScale = ax.option:Get("interface.scale", 1.0)
        return value * uiScale
    end

    --- Applies GMod's `ScreenScale` then multiplies by the player's UI scale.
    -- `ScreenScale` converts a value designed for a 640-wide reference display to the current screen width. This function additionally applies the `interface.scale` option on top, so sizes remain consistent across both different resolutions and different user scale preferences.
    -- Prefer this over raw `ScreenScale` for all UI element sizing.
    -- @realm client
    -- @param value number The reference value (as if the screen were 640 px wide).
    -- @return number The resolution- and scale-adjusted pixel value.
    -- @usage local padding = ax.util:ScreenScale(8)
    function ax.util:ScreenScale(value)
        return self:Scale(ScreenScale(value))
    end

    --- Applies GMod's `ScreenScaleH` then multiplies by the player's UI scale.
    -- The height-based equivalent of `ScreenScale` — scales a reference value relative to screen height (480 px reference) rather than width. Multiply by the `interface.scale` option afterward for consistent vertical sizing.
    -- @realm client
    -- @param value number The reference value (as if the screen were 480 px tall).
    -- @return number The resolution- and scale-adjusted pixel value.
    -- @usage local rowHeight = ax.util:ScreenScaleH(16)
    function ax.util:ScreenScaleH(value)
        return self:Scale(ScreenScaleH(value))
    end
end

--- Pads a number with leading zeroes to a minimum digit count.
-- Uses `string.format` with `%0Xd` under the hood. The result is always a
-- string. If the number already has more digits than `digits`, it is returned
-- without truncation — `digits` is a minimum, not a fixed width.
-- @realm shared
-- @param num number The integer to pad.
-- @param digits number The minimum number of digits in the output string.
-- @return string The zero-padded number as a string.
-- @usage ax.util:PadNumber(7, 3)    -- "007"
-- ax.util:PadNumber(1234, 3)        -- "1234" (already wider, not truncated)
-- ax.util:PadNumber(0, 2)           -- "00"
function ax.util:PadNumber(num, digits)
    return string.format("%0" .. tostring(digits) .. "d", num)
end

--- Returns true when `target` falls within `client`'s crosshair cone.
-- Uses the dot product of `client`'s aim vector and the normalised direction
-- to `target`'s eye position (or world centre for non-player entities). The
-- dot product is compared against `range` as a threshold: a value of `1.0`
-- means the target must be directly on-axis; `0.9` (default) allows roughly
-- ±26°; `0.0` accepts any direction in front of the player. A lower `range`
-- value produces a wider acceptance cone.
-- Returns nil (falsy) when either `client` or `target` is not a valid player.
-- @realm shared
-- @param client Player The player whose aim vector is used.
-- @param target Entity The entity to test against the crosshair cone.
-- @param range number|nil Dot-product threshold in [0, 1]. Higher values
--   require tighter aim. Defaults to 0.9.
-- @return boolean|nil True if `target` is within the crosshair cone, nil if
--   either argument is not a valid player.
-- @usage -- Is Entity(2) roughly in Entity(1)'s sights?
-- ax.util:FindInCrosshair(Entity(1), Entity(2))         -- default 0.9
-- -- Wider cone (accepts targets up to ~60° off-axis):
-- ax.util:FindInCrosshair(Entity(1), Entity(2), 0.5)
-- -- Very tight aim required (almost pixel-perfect):
-- ax.util:FindInCrosshair(Entity(1), Entity(2), 0.99)
function ax.util:FindInCrosshair(client, target, range)
    if ( !ax.util:IsValidPlayer(client) and !ax.util:IsValidPlayer(target) ) then return end

    if ( !range ) then
        range = 0.9
    end

    range = math.Clamp(range, 0, 1)

    local origin, originVector = client:EyePos(), client:GetAimVector()

    local targetOrigin = target.EyePos and target:EyePos() or target:WorldSpaceCenter()
    local direction = targetOrigin - origin

    if ( originVector:Dot(direction:GetNormalized()) > range ) then return true end

    return false
end

--- Asserts a condition, printing an error message when it is false.
-- Unlike Lua's built-in `assert`, this does NOT throw — execution continues
-- after the call. The error is printed via `PrintError` (which uses
-- `ErrorNoHaltWithStack`, so a stack trace is included in the output).
-- When `condition` is falsy, returns `false` followed by any extra arguments.
-- When `condition` is truthy, returns it unchanged followed by extra arguments.
-- Use this for precondition checks where you want to log the failure clearly
-- but still allow the caller to handle it gracefully.
-- @realm shared
-- @param condition any The value to test. Falsy (false/nil) triggers the error.
-- @param errorMessage string|nil The message to print on failure.
--   Defaults to `"Assertion failed"`.
-- @param ... any Extra values appended to the error output and forwarded as
--   additional return values.
-- @return boolean|any `condition` (or false on failure), followed by `...`.
-- @usage local ok = ax.util:Assert(istable(data), "Expected table, got", type(data))
-- if ( !ok ) then return end
function ax.util:Assert(condition, errorMessage, ...)
    errorMessage = errorMessage or "Assertion failed"
    if ( !condition ) then
        ax.util:PrintError(errorMessage, ...)
        return false, ...
    end

    return condition, ...
end

--- Returns the player whose death ragdoll is the given entity.
-- Iterates all connected players and checks whether any has a `ragdoll.index`
-- relay value matching the entity's index. This relay is set by the framework
-- when a player's death ragdoll is created. Returns nil when the entity is not
-- a `prop_ragdoll`, is invalid, or no player has that ragdoll index.
-- @realm shared
-- @param entity Entity The entity to test, expected to be a `prop_ragdoll`.
-- @return Player|nil The player who owns this ragdoll, or nil if not found.
-- @usage local owner = ax.util:GetPlayerFromAttachedRagdoll(ent)
-- if ( owner ) then print(owner:Nick() .. "'s ragdoll") end
function ax.util:GetPlayerFromAttachedRagdoll(entity)
    if ( !IsValid(entity) or entity:GetClass() != "prop_ragdoll" ) then
        return nil
    end

    local entIndex = entity:EntIndex()
    for _, client in ipairs(player.GetAll()) do
        if ( !ax.util:IsValidPlayer(client) ) then
            continue
        end

        if ( client:GetRelay("ragdoll.index", -1) == entIndex ) then
            return client
        end
    end

    return nil
end

--- Asserts a condition, printing a debug message when it is false.
-- Behaves identically to `Assert` except the failure message is routed through
-- `PrintDebug` instead of `PrintError`. This means the output is only visible
-- when the `developer` convar is ≥ 1 AND `ax_debug_realm` is set to match the
-- current realm — making it suitable for internal consistency checks that
-- should be silent in production but informative during development.
-- @realm shared
-- @param condition any The value to test. Falsy (false/nil) triggers the debug
--   message.
-- @param errorMessage string|nil The message to print on failure.
--   Defaults to `"Assertion failed"`.
-- @param ... any Extra values appended to the debug output and forwarded as
--   additional return values.
-- @return boolean|any `condition` (or false on failure), followed by `...`.
-- @usage ax.util:AssertDebug(self.registry[key], "Key not in registry:", key)
function ax.util:AssertDebug(condition, errorMessage, ...)
    errorMessage = errorMessage or "Assertion failed"
    if ( !condition ) then
        ax.util:PrintDebug("[DEBUG-ASSERT] ", errorMessage, ...)
        return false, ...
    end

    return condition, ...
end

if ( CLIENT ) then
    --- Draws a smooth arc or full circle outline using polygons.
    -- Generates vertices along the arc from `startAngle` to `endAngle` (both
    -- in degrees) and draws them as a polygon using `surface.DrawPoly`. The
    -- arc is not filled — it is an open polyline. For a filled circle, use
    -- `DrawSlice` instead. `segments` controls smoothness; 64 is a good
    -- default for most sizes. Call `surface.SetDrawColor` before this function
    -- to set the line colour.
    -- @realm client
    -- @param x number Center X of the arc in screen pixels.
    -- @param y number Center Y of the arc in screen pixels.
    -- @param radius number Radius of the arc in pixels.
    -- @param segments number|nil Number of polygon segments (default: 64).
    --   Higher values produce a smoother curve.
    -- @param startAngle number|nil Starting angle in degrees (default: 0).
    --   0 is the 3-o'clock position; angles increase clockwise.
    -- @param endAngle number|nil Ending angle in degrees (default: 360, full
    --   circle). Set to less than 360 for a partial arc.
    -- @usage surface.SetDrawColor(255, 255, 255, 200)
    -- ax.util:DrawCircle(ScrW() / 2, ScrH() / 2, 64) -- full circle
    -- ax.util:DrawCircle(100, 100, 32, 32, 0, 180)    -- half-circle arc
    function ax.util:DrawCircle(x, y, radius, segments, startAngle, endAngle)
        segments = segments or 64
        startAngle = math.rad(startAngle or 0)
        endAngle = math.rad(endAngle or 360)

        local angleStep = (endAngle - startAngle) / segments

        draw.NoTexture()

        local vertices = {}
        for i = 0, segments do
            local angle = startAngle + (angleStep * i)
            local px = x + math.cos(angle) * radius
            local py = y + math.sin(angle) * radius

            vertices[#vertices + 1] = {
                x = px,
                y = py
            }
        end

        if ( vertices[1] != nil ) then
            surface.DrawPoly(vertices)
        end
    end


    --- Draws a filled pie slice, useful for circular progress indicators.
    -- Constructs a polygon with the centre point as vertex 0 and arc vertices
    -- fanning out from `startAngle` to `endAngle`. An internal –90° offset is
    -- applied so that 0° corresponds to the top of the circle (12-o'clock
    -- position), making it intuitive for progress bars that start at the top.
    -- Uses a fixed 64-segment resolution. The slice is filled solid with
    -- `color`.
    -- @realm client
    -- @param x number Center X of the slice in screen pixels.
    -- @param y number Center Y of the slice in screen pixels.
    -- @param radius number Radius of the slice in pixels.
    -- @param startAngle number Starting angle in degrees. 0 = top (12 o'clock).
    -- @param endAngle number Ending angle in degrees. 360 = full circle.
    -- @param color table Color table with `r`, `g`, `b`, `a` fields.
    -- @usage -- Draw a 75% progress indicator
    -- ax.util:DrawSlice(200, 200, 48, 0, 270, Color(100, 200, 255, 200))
    function ax.util:DrawSlice(x, y, radius, startAngle, endAngle, color)
        local segments = 64
        startAngle = math.rad(startAngle - 90) -- Offset to start at top
        endAngle = math.rad(endAngle - 90)

        local angleStep = (endAngle - startAngle) / segments

        surface.SetDrawColor(color.r, color.g, color.b, color.a)
        draw.NoTexture()

        local vertices = {{ x = x, y = y }}

        for i = 0, segments do
            local angle = startAngle + (angleStep * i)
            local px = x + math.cos(angle) * radius
            local py = y + math.sin(angle) * radius

            vertices[#vertices + 1] = { x = px, y = py }
        end

        if ( vertices[3] != nil ) then
            surface.DrawPoly(vertices)
        end
    end
end
