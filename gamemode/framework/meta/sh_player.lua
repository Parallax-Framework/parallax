local Client = FindMetaTable("Player")

function Client:GetCharacter()
    return self:GetTable().axCharacter
end
