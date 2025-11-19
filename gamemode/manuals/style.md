
# Parallax Lua Formatting & Documentation Style (OLDS)

A strict Lua coding and documentation standard tailored for Garry's Mod and the Parallax framework. It merges **K&R-style formatting**, **colon-method notation**, and **LDOC-compliant documentation** with additional conventions to promote readability, maintainability, and consistency.

---

## ✅ Code Formatting Rules

### 1. Function Declaration
* Use colon notation (`:`) for object methods.
* Structure:
  ```lua
  function ax.util:FunctionName(arg1, arg2)
      -- logic
  end
  ```

### 2. Spacing
* Use **spaces inside parentheses** and around operators:
  ```lua
  if ( condition ) then return end
  local value = 10 + 5
  ```
* No extra spaces between function arguments:
  ```lua
  ax.util:PrintMessage(client, "Text")
  ```

### 3. Logical Separation
* Add blank lines between logical blocks for readability.
* Group related functions inside tables/modules.

### 4. Constants & Locals
* Use `local` for scoped values.
* Global namespaces should be lowercase (e.g., `ax.util`).

### 5. Colon Method Notation
* Always use colon (`:`) for methods expecting `self`.

### 6. Comments
* Use `--` for single-line comments.
* Use `--[[ ... ]]` for multi-line comments.
* Place comments above the line they describe, not at the end.

### 7. Control Structures
* Use `then` on the same line as `if`, `for`, and `while` statements.
* Use `end` on a new line.
* Example:
  ```lua
  if ( condition ) then
      -- logic
  else
      -- alternative logic
  end
  ```

### 8. Tables and Arrays
* Use `:` for method calls on tables.
* Use `[]` for array indexing.
* Example:
  ```lua
  local myTable = { key = "value" }
  print(myTable:key())
  print(myTable["key"])
  ```

### 9. String Concatenation
* Use `..` for string concatenation.
* Example:
  ```lua
  local message = "Hello" .. " " .. "World"
  ```

### 10. Function Calls
* Use parentheses for function calls, even if no arguments are passed.
* Example:
  ```lua
  ax.util:PrintMessage(client, "Hello World")
  ```

### 11. Error Handling
* Use `ErrorNoHalt` for critical errors.
* Example:
  ```lua
  if ( !success ) then
      ErrorNoHalt("An error occurred: " .. errorMessage)
  end
  ```

### 12. Indentation
* Use **4 spaces** for indentation.
* Do not use tabs.
* Ensure consistent indentation across all files.
* If you are using VSCode, and you have indentation problems, press CTRL+SHIFT+P and press "Convert Indentation to Spaces"

```lua
function ax.util:ExampleFunction()
    local value = 10
    if ( value > 5 ) then
        print("Value is greater than 5")
    end
end
```

```lua
local value2 = 20
local value1 = 10
local unknown = 30
if ( value1 < value2 ) then
    print("Value1 is less than Value2")
end

if ( unknown > value2 ) then
    print("Unknown is greater than Value2")
else
    print("Unknown is not greater than Value2")
end
```

### 13. File Naming
* Use lowercase with underscores for file names (e.g., `chat_util.lua`).
* Use descriptive names that reflect the file's purpose.

---

## ✅ Documentation Rules (LDOC)

Each **global function** must include:
* Short description of purpose
* `@realm` — `server`, `client`, or `shared`
* `@param` for each argument with argument name, type and description
* `@return` values (if any)
* `@usage` — example of function usage

### Example:
```lua
--- Sends a chat message to the player.
-- @realm shared
-- @param client Player The player receiving the message.
-- @param ... any Message parts.
-- @usage ax.util:SendChatText(client, "Hello", Color(255, 255, 255), " world!")
function ax.util:SendChatText(client, ...)
    -- implementation
end
```

### Tables and Constants
* Use `@table`, `@field`, and `@usage` for global tables.

### Style Consistency
* Documentation must exactly match function behavior.
* Optional: Use `@see` for related utilities.

---

## 🧩 Optional Enhancements
* Include subsystem sections (e.g., `Chat Utilities`, `Type Handling`, etc.)
* Group related files by module purpose.

---

**Enforcement**: This style guide applies to all pull requests and code contributions to ax.
