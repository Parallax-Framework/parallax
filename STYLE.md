
# Parallax Lua Formatting & Documentation Style (OLDS)

A strict Lua coding and documentation standard tailored for Garry's Mod and the Parallax framework. It merges **K&R-style formatting**, **colon-method notation**, and **LDOC-compliant documentation** with additional conventions to promote readability, maintainability, and consistency.

---

## ✅ Code Formatting Rules

### 1. Function Declaration
- Use colon notation (`:`) for object methods.
- Structure:
  ```lua
  function ax.util:FunctionName(arg1, arg2)
      -- logic
  end
  ```

### 2. Spacing
- Use **spaces inside parentheses** and around operators:
  ```lua
  if ( condition ) then return end
  local value = 10 + 5
  ```
- No extra spaces between function arguments:
  ```lua
  ax.util:PrintMessage(client, "Text")
  ```

### 3. Logical Separation
- Add blank lines between logical blocks for readability.
- Group related functions inside tables/modules.

### 4. Constants & Locals
- Use `local` for scoped values.
- Global namespaces should be lowercase (e.g., `ax.util`).

### 5. Colon Method Notation
- Always use colon (`:`) for methods expecting `self`.

---

## ✅ Documentation Rules (LDOC)

Each **global function** must include:
- Short description of purpose
- `@realm` — `server`, `client`, or `shared`
- `@param` for each argument with argument name, type and description
- `@return` values (if any)
- `@usage` — example of function usage

### Example:
```lua
--- Sends a chat message to the player.
-- @realm shared
-- @param client Player The player receiving the message.
-- @param ... any Message parts.
-- @usage ax.util:SendChatText(ply, "Hello", Color(255, 255, 255), " world!")
function ax.util:SendChatText(client, ...)
    -- implementation
end
```

### Tables and Constants
- Use `@table`, `@field`, and `@usage` for global tables.

### Style Consistency
- Documentation must exactly match function behavior.
- Optional: Use `@see` for related utilities.

---

## 🧩 Optional Enhancements
- Include subsystem sections (e.g., `Chat Utilities`, `Type Handling`, etc.)
- Group related files by module purpose.

---

**Enforcement**: This style guide applies to all pull requests and code contributions to ax.
