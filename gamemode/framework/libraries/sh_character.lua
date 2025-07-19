ax.character = ax.character or {}
ax.character.stored = ax.character.stored or {}

function ax.character:InstanceObject()
    local character = setmetatable({}, ax.meta.character)
    -- bloodycop6385 @ TODO: Uh, move to character variables?
    character.data = {}

    -- TOOD: Change to DB
    character.id = #ax.character.instances + 1

    ax.character.stored[character.id] = character

    return character
end

function ax.character:Get(id)
    if ( !isnumber(id) ) then
        ax.util:PrintError("Invalid character ID provided to ax.character:Get()")
        return nil
    end

    return ax.character.stored[id]
end