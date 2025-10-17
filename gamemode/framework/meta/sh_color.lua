local color = FindMetaTable( "Color" )

function color:IsDark()
    return self:GetBlackness() > 0.5
end
