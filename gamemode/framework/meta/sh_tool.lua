-- Adapted and borrowed from Helix.
-- https://github.com/NebulousCloud/helix/blob/master/gamemode/core/meta/sh_tool.lua

ax.tool = ax.tool or {}
ax.tool.meta = ax.tool.meta or {}

local TOOL = ax.tool.meta or {}

--- Creates and returns a new tool object instance from this metatable.
-- Replicated from the Sandbox tool base (`stool.lua`).
-- Initialises all standard fields with their defaults: `Mode`, `SWEP`, `Owner`, `ClientConVar`, `ServerConVar`, `Objects`, `Stage`, `Message`, `LastMessage`, and `AllowedCVar`.
-- Callers should override fields on the returned object as needed before use.
-- @realm shared
-- @return table A new tool instance with default field values.
-- code replicated from gamemodes/sandbox/entities/weapons/gmod_tool/stool.lua
function TOOL:Create()
    local object = {}

    setmetatable(object, self)
    self.__index = self

    object.Mode = nil
    object.SWEP = nil
    object.Owner = nil
    object.ClientConVar = {}
    object.ServerConVar = {}
    object.Objects = {}
    object.Stage = 0
    object.Message = "start"
    object.LastMessage = 0
    object.AllowedCVar = 0

    return object
end

--- Creates the console variables required by this tool.
-- On the client, iterates `self.ClientConVar` and calls `CreateClientConVar` for each entry prefixed with `"<mode>_"`.
-- On the server, creates the `"toolmode_allow_<mode>"` convar (with `FCVAR_NOTIFY`) which controls whether this tool mode is permitted on the server.
-- This is called automatically during tool registration.
-- @realm shared
function TOOL:CreateConVars()
    local mode = self:GetMode()

    if ( CLIENT ) then
        for cvar, default in pairs(self.ClientConVar) do
            CreateClientConVar(mode .. "_" .. cvar, default, true, true)
        end

        return
    end

    -- Note: I changed this from replicated because replicated convars don't work when they're created via Lua.
    if ( SERVER ) then
        self.AllowedCVar = CreateConVar("toolmode_allow_" .. mode, 1, FCVAR_NOTIFY)
    end
end

--- Returns the string value of a server-side convar for this tool.
-- Reads the convar named `"<mode>_<property>"` via `GetConVarString`.
-- Useful for reading server-authoritative settings from within shared or client code.
-- @realm shared
-- @param property string The convar suffix (the part after `"<mode>_"`).
-- @return string The string value of the convar.
function TOOL:GetServerInfo(property)
    local mode = self:GetMode()
    return GetConVarString(mode .. "_" .. property)
end

--- Returns the full client convar table for this tool, with prefixed keys.
-- Iterates `self.ClientConVar` and builds a new table keyed by `"<mode>_<k>"` with the corresponding default values.
-- Useful for syncing all tool convars at once.
-- @realm shared
-- @return table A table of `{ ["<mode>_<cvar>"] = defaultValue }` entries.
function TOOL:BuildConVarList()
    local mode = self:GetMode()
    local convars = {}

    for k, v in pairs(self.ClientConVar) do
        convars[mode .. "_" .. k] = v
    end

    return convars
end

--- Returns the string value of a client-side convar for this tool.
-- Reads the convar named `"<mode>_<property>"` from the owning player via `Player:GetInfo`.
-- This reflects the client's locally set value.
-- @realm shared
-- @param property string The convar suffix (the part after `"<mode>_"`).
-- @return string The string value of the client convar.
function TOOL:GetClientInfo(property)
    return self:GetOwner():GetInfo(self:GetMode() .. "_" .. property)
end

--- Returns the numeric value of a client-side convar for this tool.
-- Reads the convar named `"<mode>_<property>"` from the owning player via `Player:GetInfoNum`.
-- Falls back to `default` (converted to number, or 0) when the convar is unset or non-numeric.
-- @realm shared
-- @param property string The convar suffix (the part after `"<mode>_"`).
-- @param default number|nil The fallback value when the convar is unset. Defaults to 0.
-- @return number The numeric value of the client convar.
function TOOL:GetClientNumber(property, default)
    return self:GetOwner():GetInfoNum(self:GetMode() .. "_" .. property, tonumber(default) or 0)
end

--- Returns whether this tool mode is allowed to be used on the server.
-- On the client, always returns true (enforcement happens server-side).
-- On the server, reads the `"toolmode_allow_<mode>"` convar created by `CreateConVars`; returns its boolean value.
-- @realm shared
-- @return boolean True if the tool is allowed, false if disabled by the server.
function TOOL:Allowed()
    if ( CLIENT ) then
        return true
    end

    return self.AllowedCVar:GetBool()
end

--- Called when the tool is first initialised.
-- Empty by default; override this in a tool definition to run setup logic when the tool object is created.
-- Equivalent to the `Init` stub in the Sandbox tool base.
-- @realm shared
function TOOL:Init()
end

--- Returns the mode string identifying this tool.
-- The mode string is the tool's registered name (e.g. `"axis"`, `"weld"`).
-- It is used as the prefix for all convar names associated with this tool.
-- @realm shared
-- @return string The tool mode identifier string.
function TOOL:GetMode()
    return self.Mode
end

--- Returns the SWEP (scripted weapon) that this tool is attached to.
-- The SWEP is the `gmod_tool` weapon entity in the player's hand.
-- Access the owning player via `GetOwner()` rather than reading `SWEP.Owner` directly.
-- @realm shared
-- @return table The SWEP entity table.
function TOOL:GetSWEP()
    return self.SWEP
end

--- Returns the player entity that owns this tool.
-- Reads `SWEP.Owner` first, falling back to `self.Owner` when the SWEP reference is unavailable.
-- This is the player who has the `gmod_tool` weapon equipped.
-- @realm shared
-- @return Player The owning player entity.
function TOOL:GetOwner()
    return self:GetSWEP().Owner or self.Owner
end

--- Returns the weapon entity that holds this tool.
-- Reads `SWEP.Weapon` first, falling back to `self.Weapon`.
-- Equivalent to the `gmod_tool` weapon entity rather than the owning player.
-- @realm shared
-- @return Entity The weapon entity.
function TOOL:GetWeapon()
    return self:GetSWEP().Weapon or self.Weapon
end

--- Called when the player left-clicks while this tool is active.
-- Returns false by default (no action taken).
-- Override in a tool definition to implement the primary tool interaction (e.g. placing, welding, constraining).
-- @realm shared
-- @return boolean True if the click was handled, false otherwise.
function TOOL:LeftClick()
    return false
end

--- Called when the player right-clicks while this tool is active.
-- Returns false by default (no action taken).
-- Override in a tool definition to implement the secondary tool interaction.
-- @realm shared
-- @return boolean True if the click was handled, false otherwise.
function TOOL:RightClick()
    return false
end

--- Called when the player presses the reload key while this tool is active.
-- Clears all stored objects via `ClearObjects`.
-- Override to add additional reset behaviour, but ensure `ClearObjects` is still called to maintain consistent state.
-- @realm shared
function TOOL:Reload()
    self:ClearObjects()
end

--- Called when the tool is deployed (the player selects it).
-- Releases any ghost entity via `ReleaseGhostEntity`.
-- Override to show a preview ghost or run setup logic when the player switches to this tool.
-- @realm shared
function TOOL:Deploy()
    self:ReleaseGhostEntity()
    return
end

--- Called when the tool is holstered (the player switches away from it).
-- Releases any ghost entity via `ReleaseGhostEntity`.
-- Override to clean up any visual state or timers created during `Deploy`.
-- @realm shared
function TOOL:Holster()
    self:ReleaseGhostEntity()
    return
end

--- Called every frame while this tool is active.
-- Releases any ghost entity by default.
-- Override to implement per-frame ghost preview updates; call `ReleaseGhostEntity` only when no ghost should be shown.
-- @realm shared
function TOOL:Think()
    self:ReleaseGhostEntity()
end

--- Validates that all stored tool objects are still valid entities.
-- Iterates `self.Objects` and calls `ClearObjects` if any entry's `Ent` field is neither a valid entity nor the world.
-- This prevents operations on stale entity references (e.g. when a prop is deleted mid-interaction).
-- Checks the objects before any action is taken
-- This is to make sure that the entities haven't been removed
-- @realm shared
function TOOL:CheckObjects()
    for _, v in pairs(self.Objects) do
        if ( !v.Ent:IsWorld() and !v.Ent:IsValid() ) then
            self:ClearObjects()
        end
    end
end

ax.tool.meta = TOOL
