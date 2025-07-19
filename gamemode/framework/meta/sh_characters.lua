local character = ax.meta.character or {}
character.__index = character

character.id = 0
character.data = {}

function character:GetData(key)
    return self.data[key]
end

function character:SetData(key, value)
    self.data[key] = value
end

ax.meta.character = character